--!strict
-- The cat bag (developer 2026-11-15, revision item 5): a cat you bring home goes into your bag, not straight into the
-- pen. The bag is Roblox's backpack: one Tool per cat (after the rod and the bat). Hold one and tap your pen's floor
-- to put it there (PlaceCat); a placed cat stays where you put it and earns money (cats in the bag earn nothing,
-- developer). "Pick up" on a placed cat (BagController) puts it back into the bag (PickUpCat). Pen slots still count
-- every cat you own (bag + placed). Selling: My Cats, or holding a cat at the sell booth (SellCat, PenService).
-- Saved data: Cat.Placed, Cat.X / Cat.Z (studs from the middle of the pen's Area). The tools follow the save
-- (DataService.Changed), so selling, trading and crates need nothing here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local CatIcons = require(Shared.CatIcons)
local CatModel = require(Shared.CatModel)
local CatRules = require(Shared.CatRules)
local Format = require(Shared.Format)
local Validate = require(Shared.Validate)
local DataTemplate = require(Shared.DataTemplate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local PenService = require(script.Parent.PenService)

local BagService = {}

local placedEvent = Instance.new("BindableEvent")
-- Fires (player, catId) when a cat is put on the pen floor (TutorialService).
BagService.Placed = placedEvent.Event

local B = Config.Bag

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- The held cat: a small copy of the cat welded to the tool's handle while it is in the hand.
local function showHeld(tool: Tool, cat: DataTemplate.Cat)
	local handle = tool:FindFirstChild("Handle")
	local design = Cats.ById[cat.Kind]
	if not handle or not handle:IsA("BasePart") or not design or tool:FindFirstChild("Held") then
		return
	end
	local look = table.clone(design.Look) :: any
	look.mutation = cat.Mutation
	local size = math.min(CatRules.size(design.Tier, cat.Kg) * B.HeldScale, B.HeldMax)
	local m = CatModel.build(look, handle.CFrame * CFrame.new(B.HeldOffset[1], B.HeldOffset[2], B.HeldOffset[3]), size)
	m.Name = "Held"
	m:SetAttribute("Anim", "carried")
	CatModel.joinRig(m)
	local root = m.PrimaryPart
	if root then
		root.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = root
		weld.Parent = root
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Massless = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	m.Parent = tool
end

local function makeTool(id: string, cat: DataTemplate.Cat): Tool?
	local design = Cats.ById[cat.Kind]
	if not design then
		return nil
	end
	local tool = Instance.new("Tool")
	tool.Name = design.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = `{design.Name} · {Format.short(cat.Kg)} kg`
	local icon = CatIcons[cat.Kind]
	if icon then
		tool.TextureId = `rbxassetid://{icon}` -- the cat's picture in the hotbar (else its name shows)
	end
	tool:SetAttribute("CatId", id)
	tool:SetAttribute("Kind", cat.Kind)
	tool:SetAttribute("Kg", cat.Kg)
	tool:SetAttribute("Tier", design.Tier)
	tool:SetAttribute("Mutation", cat.Mutation)
	tool.Grip = CFrame.new(B.Grip[1], B.Grip[2], B.Grip[3])
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 0.6, 0.6)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Parent = tool
	tool.Equipped:Connect(function()
		showHeld(tool, cat)
	end)
	tool.Unequipped:Connect(function()
		local held = tool:FindFirstChild("Held")
		if held then
			held:Destroy()
		end
	end)
	return tool
end

-- The bag follows the save: one tool for every cat that is not placed, none for the rest.
local function sync(player: Player)
	local data = DataService.GetData(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	local have: { [string]: boolean } = {}
	for _, container in { backpack :: Instance, player.Character } do
		if not container then
			continue
		end
		for _, t in container:GetChildren() do
			local id = if t:IsA("Tool") then t:GetAttribute("CatId") else nil
			if type(id) == "string" then
				local cat = data.Cats[id]
				if not cat or cat.Placed or have[id] then
					t:Destroy()
				else
					have[id] = true
				end
			end
		end
	end
	local missing: { string } = {}
	for id, cat in data.Cats do
		if not cat.Placed and not have[id] then
			table.insert(missing, id)
		end
	end
	table.sort(missing, function(a, b)
		local ga, gb = data.Cats[a].Got, data.Cats[b].Got
		return if ga ~= gb then ga < gb else a < b
	end)
	for _, id in missing do
		local tool = makeTool(id, data.Cats[id])
		if tool then
			tool.Parent = backpack
		end
	end
end

-- Near enough to the own pen to place or pick up (flat distance from the Area's edge).
local function nearPen(player: Player, area: BasePart): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	local rel = area.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) <= area.Size.X / 2 + B.Reach and math.abs(rel.Z) <= area.Size.Z / 2 + B.Reach
end

local function onPlace(player: Player, rawId: unknown, rawX: unknown, rawZ: unknown)
	local id = Validate.id(rawId)
	local x = Validate.number(rawX, -1e5, 1e5)
	local z = Validate.number(rawZ, -1e5, 1e5)
	local data = DataService.GetData(player)
	local area = PenService.area(player)
	if not id or not x or not z or not data or not area then
		return
	end
	local cat = data.Cats[id]
	if not cat or cat.Placed or not nearPen(player, area) then
		return
	end
	local rel = area.CFrame:PointToObjectSpace(Vector3.new(x, area.Position.Y, z))
	local hx, hz = area.Size.X / 2 - B.Margin, area.Size.Z / 2 - B.Margin
	if math.abs(rel.X) > hx or math.abs(rel.Z) > hz then
		Notify.send(player, "PlaceOutside", nil, "bad")
		return
	end
	local px, pz = math.round(rel.X * 10) / 10, math.round(rel.Z * 10) / 10
	local ok = DataService.Update(player, function(d)
		local c = d.Cats[id]
		if c and not c.Placed then
			c.Placed = true
			c.X = px
			c.Z = pz
		end
	end)
	if not ok then
		return
	end
	PenService.refresh(player)
	sync(player)
	placedEvent:Fire(player, id)
	local design = Cats.ById[cat.Kind]
	Notify.send(player, "CatPlaced", { name = if design then design.Name else "?" }, "good")
end

local function onPickUp(player: Player, rawId: unknown)
	local id = Validate.id(rawId)
	local data = DataService.GetData(player)
	local area = PenService.area(player)
	if not id or not data or not area then
		return
	end
	local cat = data.Cats[id]
	if not cat or not cat.Placed or not nearPen(player, area) then
		return
	end
	local ok = DataService.Update(player, function(d)
		local c = d.Cats[id]
		if c then
			c.Placed = false
			c.X = nil
			c.Z = nil
		end
	end)
	if not ok then
		return
	end
	PenService.refresh(player)
	sync(player)
	-- straight into the hand, so it can be put down somewhere else at once
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if humanoid and backpack and player:GetAttribute("CarryingCat") == nil and player:GetAttribute("Fishing") == nil then
		for _, t in backpack:GetChildren() do
			if t:IsA("Tool") and t:GetAttribute("CatId") == id then
				humanoid:EquipTool(t)
				break
			end
		end
	end
end

function BagService:Init()
	Guard.onEvent("PlaceCat", B.Rate, onPlace)
	Guard.onEvent("PickUpCat", B.Rate, onPickUp)
end

function BagService:Start()
	DataService.Changed:Connect(sync)
	local function hook(player: Player)
		player.CharacterAdded:Connect(function()
			task.delay(B.RespawnDelay, sync, player) -- after the rod and the bat (ToolService): they keep slots 1-2
		end)
		if player.Character then
			task.delay(B.RespawnDelay, sync, player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	DataService.PlayerLoaded:Connect(function(player: Player)
		task.delay(B.RespawnDelay, sync, player)
	end)
end

return BagService
