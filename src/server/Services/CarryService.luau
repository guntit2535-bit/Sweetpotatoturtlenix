--!strict
-- Carrying a caught cat home (task 1.13, blueprint §3; HatchRush's carry over the head).
-- The winner of a fishing contest holds the cat over their head (welded to the HumanoidRootPart, so it
-- moves smoothly with them); player attributes CarryingCat (kind) / CarryingTier draw the floating icon on
-- every client. At their own pen the player gets a "Put in pen" button (X2, revision 4 item 16: was automatic):
-- the server sets the player attribute AtPen while they carry a cat there, the client asks with PutInPen, the
-- server checks again and puts it in (saved before the toast). Full pen = they keep carrying. A bat hit, dying or leaving drops the cat where they are (WildCatService.drop).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local CatModel = require(Shared.CatModel)
local CatRules = require(Shared.CatRules)
local Bonus = require(Shared.Bonus)
local Format = require(Shared.Format)
local Mutation = require(Shared.Mutation)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local PenService = require(script.Parent.PenService)
local WildCatService = require(script.Parent.WildCatService)

type Carry = { kind: string, kg: number, tier: number, model: Model, event: string?, mutation: string?, lastFullNote: number }

local CarryService = {}

local carrying: { [Player]: Carry } = {}
local deliveredEvent = Instance.new("BindableEvent")
local droppedEvent = Instance.new("BindableEvent")

-- Fires (player, kind, kg, event?) when a carried cat goes into its pen.
CarryService.Delivered = deliveredEvent.Event
-- Fires (player, wildId) when a carried cat is dropped (the new dropped wild cat).
CarryService.Dropped = droppedEvent.Event

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function CarryService.isCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

local function clear(player: Player)
	carrying[player] = nil
	player:SetAttribute("CarryingCat", nil)
	player:SetAttribute("CarryingTier", nil)
	player:SetAttribute("AtPen", nil)
	player:SetAttribute("AtBooth", nil)
end

-- The fishing winner takes the wild cat.
function CarryService.pickUp(player: Player, w: WildCatService.Wild, mutation: string?)
	local root = rootOf(player)
	if not root or carrying[player] then
		WildCatService.remove(w, "escaped")
		return
	end
	local model = WildCatService.take(w)
	model:SetAttribute("State", "carried")
	model:SetAttribute("Anim", "carried")
	model:SetAttribute("CarriedBy", player.UserId)
	-- smaller over the head so it does not cover the camera (a Secret cat is 3-6x on the ground)
	model:ScaleTo(math.min(model:GetScale() * Config.Carry.Scale, Config.Carry.MaxScale))
	local scale = model:GetScale()
	model:PivotTo(root.CFrame * CFrame.new(0, Config.Carry.HeadOffset + 0.6 * scale, 0.4))
	CatModel.joinRig(model) -- ground cats are anchored blocks; a carried one needs joints to ride along
	local modelRoot = model.PrimaryPart
	if modelRoot then
		modelRoot.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = modelRoot
		weld.Parent = modelRoot
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Massless = true
				d.CanCollide = false
			end
		end
	end
	model.Parent = player.Character
	carrying[player] = { kind = w.kind, kg = w.kg, tier = w.tier, model = model, event = w.event, mutation = mutation, lastFullNote = 0 }
	player:SetAttribute("CarryingCat", w.kind)
	player:SetAttribute("CarryingTier", w.tier)
	Notify.send(player, "CarryHint", nil, "info")
end

-- Drops the carried cat where the player is (bat hit / death / leaving). Returns the new dropped wild cat.
function CarryService.drop(player: Player): WildCatService.Wild?
	local c = carrying[player]
	if not c then
		return nil
	end
	local root = rootOf(player)
	local pos = if root then root.Position else c.model:GetPivot().Position
	clear(player)
	if c.model.Parent then
		c.model:Destroy()
	end
	local ray = workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -80, 0))
	local ground = if ray then ray.Position else pos - Vector3.new(0, 3, 0)
	-- which zone it fell in (dropped cats go back to hiding in that zone)
	local r = Vector3.new(ground.X, 0, ground.Z).Magnitude
	local zone = 0
	for i, z in Config.World.Zones do
		if r >= z.Inner and r < z.Outer then
			zone = i
		end
	end
	local w = WildCatService.drop(c.kind, c.kg, CFrame.new(ground) * CFrame.Angles(0, math.random() * math.pi * 2, 0), c.event, zone, c.mutation)
	droppedEvent:Fire(player, w.id)
	return w
end

-- Is `pos` at the player's own pen? Inside the pen's floor (any size) or within Config.Carry.DeliverMargin of its
-- fence, the gate side included. (2026-11-13: was "within DeliverRadius of the floor's centre", which the bigger pens
-- of W7 moved 24-28 studs back from the gate, so standing in the gate no longer delivered.)
local function atPen(player: Player, pos: Vector3): boolean
	local index = PenService.penIndex(player)
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	local pen = index and pens and pens:FindFirstChild(`Pen{index}`)
	local floor = pen and pen:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then
		return false
	end
	local rel = floor.CFrame:PointToObjectSpace(pos)
	local m = Config.Carry.DeliverMargin
	return math.abs(rel.X) <= floor.Size.X / 2 + m and math.abs(rel.Z) <= floor.Size.Z / 2 + m and math.abs(rel.Y) < 20
end

local function deliver(player: Player, c: Carry)
	if not PenService.hasRoom(player) then
		if os.clock() - c.lastFullNote > 1 then
			c.lastFullNote = os.clock()
			local data = DataService.GetData(player)
			Notify.send(player, "PenFull", { max = if data then data.PenSlots else Config.Pen.StartSlots }, "bad")
		end
		return
	end
	-- R4: c.kg is the base weight; the pen keeps it at this player's scale
	local data = DataService.GetData(player)
	local kg = CatRules.kgFor(c.kg, if data then data.Rebirths else 0)
	local id = PenService.addCat(player, c.kind, kg, c.mutation)
	if not id then
		return
	end
	clear(player)
	if c.model.Parent then
		c.model:Destroy()
	end
	deliveredEvent:Fire(player, c.kind, kg, c.event)
	task.spawn(function()
		DataService.SaveAsync(player) -- saved before the toast (save before you show)
		local design = Cats.ById[c.kind]
		Notify.send(player, "CatHome", { name = if design then design.Name else "?" }, "good")
	end)
end

-- X3 (revision 4 item 18): standing on the sell booth's pad on the plaza (BuildMap.market)?
local function atBooth(pos: Vector3): boolean
	local map = workspace:FindFirstChild("Map")
	local market = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Market")
	local booth = market and market:FindFirstChild("SellBooth")
	local pad = booth and booth:FindFirstChild("Pad")
	if not pad or not pad:IsA("BasePart") then
		return false
	end
	local d = Vector3.new(pos.X - pad.Position.X, 0, pos.Z - pad.Position.Z).Magnitude
	return d <= Config.Market.PadRange and math.abs(pos.Y - pad.Position.Y) < 12
end

-- What the carried cat sells for: the same as selling it from the pen (tier, this player's kg, mutation, money bonus).
local function carriedValue(player: Player, c: Carry): number
	local data = DataService.GetData(player)
	local design = Cats.ById[c.kind]
	if not data or not design then
		return 0
	end
	local kg = CatRules.kgFor(c.kg, data.Rebirths)
	return math.floor(CatRules.sellPrice(design.Tier, kg) * Mutation.money(c.mutation) * Bonus.money(BonusCtx.of(player, data)))
end

-- X3: SellCarried from the "Sell" button at the booth. Saved before the toast.
local function onSellCarried(player: Player)
	local c = carrying[player]
	local root = rootOf(player)
	if not c or not root or not atBooth(root.Position) then
		return
	end
	local value = carriedValue(player, c)
	DataService.Update(player, function(d)
		d.Money = CatRules.cap(d.Money + value)
		d.Stats.Sold += 1
	end)
	clear(player)
	if c.model.Parent then
		c.model:Destroy()
	end
	task.spawn(function()
		DataService.SaveAsync(player)
		local design = Cats.ById[c.kind]
		Notify.send(player, "SoldCat", { name = if design then design.Name else "?", money = Format.short(value) }, "good")
	end)
end

-- X2: the "Put in pen" button (the client only asks; carrying and the pen are checked here)
local function onPutInPen(player: Player)
	local c = carrying[player]
	local root = rootOf(player)
	if c and root and atPen(player, root.Position) then
		deliver(player, c)
	end
end

function CarryService:Init()
	local Guard = require(script.Parent.Parent.Util.Guard)
	Guard.onEvent("PutInPen", Config.Carry.PutRate, onPutInPen)
	Guard.onEvent("SellCarried", Config.Carry.PutRate, onSellCarried)
	local DebugService = require(script.Parent.DebugService)
	DebugService.register("drop", "!drop  drop the cat you carry (as if hit by a bat)", function(player)
		local w = CarryService.drop(player)
		return if w then `dropped as {w.id}` else "not carrying"
	end)
end

function CarryService:Start()
	Players.PlayerRemoving:Connect(function(player)
		CarryService.drop(player)
	end)
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					CarryService.drop(player)
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	task.spawn(function()
		while true do
			task.wait(Config.Carry.CheckEvery)
			for player, c in carrying do
				local root = rootOf(player)
				local here = root ~= nil and atPen(player, root.Position)
				if player:GetAttribute("AtPen") ~= (if here then true else nil) then
					player:SetAttribute("AtPen", if here then true else nil) -- shows the client's button
				end
				-- X3: at the sell booth the button shows what the cat sells for
				local booth = root ~= nil and atBooth(root.Position)
				local value = if booth then carriedValue(player, c) else nil
				if player:GetAttribute("AtBooth") ~= value then
					player:SetAttribute("AtBooth", value)
				end
			end
		end
	end)
end

return CarryService
