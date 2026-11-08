--!strict
-- Pens (tasks 1.8 / 1.9; based on Pet Storm Escape's corral and HatchRush's pens).
--   - Each loaded player gets the lowest free pen (Workspace.Map.Lobby.Pens.Pen1..8), spawns at it, and
--     frees it on leave. The pen model gets attributes OwnerId / OwnerName / Likes (the client draws the sign).
--   - The owner's cats stand in Workspace.PenCats.Pen<i> (CatModel, attributes CatId / Kind / Kg / Tier /
--     PenIndex); each client walks them around the pen (PenCatsController).
--   - Income: every Config.Economy.IncomeTick the pen's cats pay straight into Money (no box to collect).
--     Player attribute "Income" = money per second.
--   - SellCat(id) / LockCat(id, locked) from the My Cats window; the server checks everything.
--   - Likes: the sign's ProximityPrompt; one like per pen owner per UTC day; the liker gets the speed buff
--     (attribute LikeBuffUntil, MovementService).
-- Other services: PenService.addCat(player, kind, kg) -> catId? (nil when the pen is full).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local CatModel = require(Shared.CatModel)
local Bonus = require(Shared.Bonus)
local CatRules = require(Shared.CatRules)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Commands = require(Shared.Commands)
local DataTemplate = require(Shared.DataTemplate)
local Format = require(Shared.Format)
local Mutation = require(Shared.Mutation)
local Validate = require(Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)

local PenService = {}

local penOf: { [Player]: number } = {}
local ownerOf: { [number]: Player } = {}
local incomeOf: { [Player]: number } = {}
local lastLike: { [Player]: number } = {}
local catsFolder: Folder

local function log(message: string)
	print(`[Sweetpotato] PenService: {message}`)
end

local function penModel(index: number): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	local m = pens and pens:FindFirstChild(`Pen{index}`)
	return if m and m:IsA("Model") then m else nil
end

local function penFolder(index: number): Folder
	local f = catsFolder:FindFirstChild(`Pen{index}`)
	if not f then
		local n = Instance.new("Folder")
		n.Name = `Pen{index}`
		n.Parent = catsFolder
		return n
	end
	return f :: Folder
end

-- A random standing spot inside the pen's Area part.
local function randomSpot(index: number): CFrame
	local pen = penModel(index)
	local area = pen and pen:FindFirstChild("Area")
	if not area or not area:IsA("BasePart") then
		return CFrame.new(0, 1, 0)
	end
	local s = area.Size
	local p = area.CFrame * CFrame.new((math.random() - 0.5) * s.X, -s.Y / 2, (math.random() - 0.5) * s.Z)
	return CFrame.new(p.Position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
end

local function catModel(index: number, id: string, cat: DataTemplate.Cat, owner: Player)
	local design = Cats.ById[cat.Kind]
	if not design then
		return
	end
	local look = table.clone(design.Look) :: any
	look.mutation = cat.Mutation
	local m = CatModel.build(look, randomSpot(index), CatRules.size(design.Tier, cat.Kg))
	m:SetAttribute("Mutation", cat.Mutation)
	m.Name = id
	m:SetAttribute("CatId", id)
	m:SetAttribute("Kind", cat.Kind)
	m:SetAttribute("Kg", cat.Kg)
	m:SetAttribute("Tier", design.Tier)
	m:SetAttribute("PenIndex", index)
	m:SetAttribute("OwnerId", owner.UserId)
	m.Parent = penFolder(index)
end

local function recountIncome(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local total = 0
	for _, cat in data.Cats do
		local design = Cats.ById[cat.Kind]
		if design then
			total += CatRules.income(design.Tier, cat.Kg) * Mutation.money(cat.Mutation)
		end
	end
	incomeOf[player] = total -- before multipliers (Bonus.money is applied every tick: boosts end on their own)
end

-- Rebuilds the cat models of a player's pen from the save.
local function refreshCats(player: Player)
	local index = penOf[player]
	local data = DataService.GetData(player)
	if not index or not data then
		return
	end
	local folder = penFolder(index)
	for _, m in folder:GetChildren() do
		if not data.Cats[m.Name] then
			m:Destroy()
		end
	end
	for id, cat in data.Cats do
		if not folder:FindFirstChild(id) then
			catModel(index, id, cat, player)
		end
	end
	recountIncome(player)
end

local function setSign(index: number, owner: Player?)
	local pen = penModel(index)
	if not pen then
		return
	end
	local data = owner and DataService.GetData(owner)
	pen:SetAttribute("OwnerId", if owner then owner.UserId else 0)
	pen:SetAttribute("OwnerName", if owner then owner.DisplayName else "")
	pen:SetAttribute("Likes", if data then data.LikesReceived else 0)
end

local function spawnAtPen(player: Player, character: Model)
	local index = penOf[player]
	local pen = index and penModel(index)
	local spawn = pen and pen:FindFirstChild("Spawn")
	if spawn and spawn:IsA("BasePart") then
		task.defer(function()
			character:PivotTo(spawn.CFrame * CFrame.new(0, 3, 0))
		end)
	end
end

local function assign(player: Player)
	for i = 1, Config.World.Pens.Count do
		if not ownerOf[i] and penModel(i) then
			ownerOf[i] = player
			penOf[player] = i
			setSign(i, player)
			refreshCats(player)
			if player.Character then
				spawnAtPen(player, player.Character)
			end
			log(`{player.Name} -> Pen{i}`)
			return
		end
	end
	warn(`[Sweetpotato] PenService: no free pen for {player.Name}`)
end

local function release(player: Player)
	local index = penOf[player]
	penOf[player] = nil
	incomeOf[player] = nil
	lastLike[player] = nil
	if index then
		ownerOf[index] = nil
		penFolder(index):ClearAllChildren()
		setSign(index, nil)
	end
end

-- Public -------------------------------------------------------------------------------------------

function PenService.penIndex(player: Player): number?
	return penOf[player]
end

function PenService.hasRoom(player: Player): boolean
	local data = DataService.GetData(player)
	return data ~= nil and DataTemplate.catCount(data) < data.PenSlots
end

-- Puts a new cat in the player's pen (saved with the next save). Returns its id, or nil when the pen is
-- full or the data is not loaded.
function PenService.addCat(player: Player, kind: string, kg: number, mutation: string?): string?
	if not Cats.ById[kind] or not PenService.hasRoom(player) then
		return nil
	end
	local id: string? = nil
	DataService.Update(player, function(data)
		local newId = DataTemplate.newCatId(data)
		data.Cats[newId] = { Kind = kind, Kg = kg, Locked = false, Got = os.time(), Mutation = if mutation ~= "" then mutation else nil }
		data.Book[kind] = true -- the collection book (task 2.8)
		data.Stats.Caught += 1
		id = newId
	end)
	refreshCats(player)
	return id
end

-- Remotes ------------------------------------------------------------------------------------------

local function onSell(player: Player, rawId: unknown)
	local id = Validate.id(rawId)
	local data = DataService.GetData(player)
	if not id or not data then
		return
	end
	local cat = data.Cats[id]
	if not cat then
		return
	end
	if cat.Locked then
		Notify.send(player, "CatIsLocked", nil, "bad")
		return
	end
	local design = Cats.ById[cat.Kind]
	local price = if design then math.floor(CatRules.sellPrice(design.Tier, cat.Kg) * Mutation.money(cat.Mutation) * Bonus.money(BonusCtx.of(player, data))) else 0
	DataService.Update(player, function(d)
		d.Cats[id] = nil
		d.Money += price
		d.Stats.Sold += 1
	end)
	refreshCats(player)
	Notify.send(player, "SoldCat", { name = if design then design.Name else "?", money = Format.short(price) }, "good")
end

local function onLock(player: Player, rawId: unknown, rawLocked: unknown)
	local id = Validate.id(rawId)
	local locked = Validate.boolean(rawLocked)
	local data = DataService.GetData(player)
	if not id or locked == nil or not data or not data.Cats[id] then
		return
	end
	DataService.Update(player, function(d)
		d.Cats[id].Locked = locked :: boolean
	end)
end

local function utcDay(): number
	return os.time() // 86400
end

local function onLike(player: Player, index: number)
	local now = os.clock()
	if lastLike[player] and now - lastLike[player] < Config.Pen.LikeCooldown then
		return
	end
	lastLike[player] = now
	local owner = ownerOf[index]
	local data = DataService.GetData(player)
	if not owner or not data then
		return
	end
	if owner == player then
		Notify.send(player, "LikeOwn", nil, "info")
		return
	end
	local key = tostring(owner.UserId)
	local today = utcDay()
	if data.LikesGiven[key] == today then
		Notify.send(player, "LikeAlready", nil, "bad")
		return
	end
	DataService.Update(player, function(d)
		d.LikesGiven[key] = today
		for k, day in d.LikesGiven do
			if today - day >= Config.Data.LikeDaysKept then
				d.LikesGiven[k] = nil
			end
		end
	end)
	DataService.Update(owner, function(d)
		d.LikesReceived += 1
	end)
	setSign(index, owner)
	player:SetAttribute("LikeBuffUntil", workspace:GetServerTimeNow() + Config.Walk.LikeBuffSeconds)
	Notify.send(player, "LikeDone", { name = owner.DisplayName }, "good")
	Notify.send(owner, "LikeGot", { name = player.DisplayName }, "good")
end

local function setupPrompts()
	for i = 1, Config.World.Pens.Count do
		local pen = penModel(i)
		local board = pen and pen:FindFirstChild("Sign") and pen.Sign:FindFirstChild("Board")
		if board and board:IsA("BasePart") then
			local old = board:FindFirstChild("LikePrompt")
			if old then
				old:Destroy()
			end
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "LikePrompt"
			prompt.ActionText = "Like" -- each client shows its own language (PenSignController)
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = board
			prompt.Triggered:Connect(function(player: Player)
				onLike(player, i)
			end)
		end
		setSign(i, nil)
	end
end

-- Lifecycle ----------------------------------------------------------------------------------------

function PenService:Init()
	local old = workspace:FindFirstChild("PenCats")
	if old then
		old:Destroy()
	end
	catsFolder = Instance.new("Folder")
	catsFolder.Name = "PenCats"
	catsFolder.Parent = workspace

	Guard.onEvent("SellCat", Config.Pen.SellRate, onSell)
	Guard.onEvent("LockCat", Config.Pen.LockRate, onLock)

	DebugService.register("givecat", "!givecat [tier 1-6 | catNNN] [kg]  put a cat in your pen", function(player, args)
		local kind = args[1]
		local tier = Commands.integer(kind)
		if tier then
			local list = Cats.ByTier[math.clamp(tier, 1, #Config.Tiers)]
			kind = list[math.random(1, #list)]
		elseif not kind or not Cats.ById[kind] then
			local list = Cats.ByTier[1]
			kind = list[math.random(1, #list)]
		end
		local design = Cats.ById[kind :: string]
		local kg = Commands.number(args[2]) or CatRules.rollKg(design.Tier, math.random())
		local id = PenService.addCat(player, kind :: string, kg)
		return if id then `{design.Name} ({design.TierKey}, {kg} kg) -> {id}` else "pen full or not loaded"
	end)
	DebugService.register("slots", "!slots N  set pen slots", function(player, args)
		local n = Commands.integer(args[1])
		if not n then
			return "usage: !slots N"
		end
		DataService.Update(player, function(d)
			d.PenSlots = math.clamp(n :: number, Config.Pen.StartSlots, Config.Pen.MaxSlots)
		end)
		return `slots = {n}`
	end)
end

function PenService:Start()
	setupPrompts()
	DataService.PlayerLoaded:Connect(assign)
	for _, player in Players:GetPlayers() do
		if DataService.IsLoaded(player) then
			assign(player)
		end
	end
	Players.PlayerRemoving:Connect(release)
	DataService.Changed:Connect(function(player: Player)
		local index = penOf[player]
		if index then
			setSign(index, player)
		end
		refreshCats(player) -- also recounts the income
	end)
	local function hookCharacter(player: Player)
		player.CharacterAdded:Connect(function(character)
			spawnAtPen(player, character)
		end)
	end
	Players.PlayerAdded:Connect(hookCharacter)
	for _, player in Players:GetPlayers() do
		hookCharacter(player)
	end
	-- income
	task.spawn(function()
		while true do
			task.wait(Config.Economy.IncomeTick)
			for player, base in incomeOf do
				if player.Parent == Players then
					local rate = base * Bonus.money(BonusCtx.of(player, DataService.GetData(player)))
					if player:GetAttribute("Income") ~= rate then
						player:SetAttribute("Income", rate)
					end
					if rate > 0 then
						DataService.AddIncome(player, rate * Config.Economy.IncomeTick)
					end
				end
			end
		end
	end)
end

return PenService
