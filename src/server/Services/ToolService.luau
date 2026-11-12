--!strict
-- Gives every player the two hotbar tools on spawn (blueprint §4 / §16): the baseball bat and the fishing
-- rod, built from parts. The tools only show what the player holds: FishingService and BatService do the
-- work on the server (clients ask through Cast / Swing). Tool names stay English ("Bat", "Rod") because
-- the server finds the held tool by name.
-- R5: when the Blender meshes are imported (shared/ItemModels) the tools wear them: the bat, and the rod of the
-- player's best level (Rod1..Rod25) with the line's "Tip" attachment at the mesh's tip. The part-built look
-- stays as the fallback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemModels = require(ReplicatedStorage.Shared.ItemModels)
local Shop = require(ReplicatedStorage.Shared.Shop)
local DataService = require(script.Parent.DataService)

local ToolService = {}

local WOOD = Color3.fromHex("c98a4a")
local DARK = Color3.fromHex("6b4330")
local RED = Color3.fromHex("ef4b42")
local NAVY = Color3.fromHex("2f3552")

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.Parent = parent
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

-- R5: swaps a tool's look for the mesh `id` (welded to the Handle at the grip). Returns false when the mesh
-- is not imported (the tool keeps its parts).
local LOOK_PARTS = { "Barrel", "Tip", "Band", "Pole", "Reel", "TipPart", "Mesh", "Glass" }
local function dress(tool: Tool, id: string, scale: number): boolean
	local handle = tool:FindFirstChild("Handle")
	local model = ItemModels.build(id, scale)
	if not model or not handle or not handle:IsA("BasePart") then
		if model then
			model:Destroy()
		end
		return false
	end
	for _, name in LOOK_PARTS do
		local old = tool:FindFirstChild(name)
		if old and old ~= handle then
			old:Destroy()
		end
	end
	local root = model.PrimaryPart :: BasePart
	for _, c in model:GetChildren() do
		if c:IsA("BasePart") and c ~= root then
			local offset = root.CFrame:ToObjectSpace(c.CFrame)
			local w = c:FindFirstChildOfClass("WeldConstraint")
			if w then
				w:Destroy()
			end
			c.CFrame = handle.CFrame * offset
			c.Parent = tool
			weld(handle, c)
		end
	end
	model:Destroy()
	handle.Transparency = 1
	return true
end

-- W4 (revision 3 item 3): the hotbar shows the tool's picture instead of its name once the icon is uploaded
-- (Config.UIIcons.Rod / Bat, art/export/ui_icons/P13_rod.png, P14_bat.png); 0 = the name as before. The tools keep
-- their names "Rod" / "Bat" (the scripts find them by name).
local function iconOf(key: string): string
	local id = (Config.UIIcons :: any)[key]
	return if type(id) == "number" and id > 0 then `rbxassetid://{id}` else ""
end

-- The handle is the grip, its long side along Y; the rest is welded to it.
local function makeBat(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Bat"
	tool.TextureId = iconOf("Bat")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local handle = part(tool, "Handle", Vector3.new(0.5, 1.6, 0.5), CFrame.new(), NAVY, Enum.PartType.Block)
	local barrel = part(tool, "Barrel", Vector3.new(0.85, 3.4, 0.85), CFrame.new(0, 2.4, 0), WOOD)
	local tip = part(tool, "Tip", Vector3.new(1, 0.6, 1), CFrame.new(0, 4.3, 0), WOOD)
	local band = part(tool, "Band", Vector3.new(0.9, 0.3, 0.9), CFrame.new(0, 1.1, 0), RED)
	for _, p in { barrel, tip, band } do
		weld(handle, p)
	end
	tool.Grip = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	if dress(tool, "Bat", Config.ItemModels.BatScale) then
		tool.Grip = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(Config.ItemModels.BatGrip), 0, 0)
	end
	return tool
end

local function makeRod(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Rod"
	tool.TextureId = iconOf("Rod")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local handle = part(tool, "Handle", Vector3.new(0.45, 1.4, 0.45), CFrame.new(), DARK)
	local pole = part(tool, "Pole", Vector3.new(0.22, 6.5, 0.22), CFrame.new(0, 3.9, 0), WOOD)
	local reel = part(tool, "Reel", Vector3.new(0.5, 0.8, 0.8), CFrame.new(0.4, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), RED, Enum.PartType.Cylinder)
	local tipPart = part(tool, "TipPart", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 7.2, 0), RED, Enum.PartType.Ball)
	for _, p in { pole, reel, tipPart } do
		weld(handle, p)
	end
	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Parent = tipPart
	tool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(-60), 0, 0)
	return tool
end

-- The rod shows the best rod: its mesh (R5), else the pole and tip in the material's colour (task 2.2).
function ToolService.refreshRod(player: Player)
	local data = DataService.GetData(player)
	local level = if data then data.RodLevel else 1
	local m = Shop.rodMaterial(level)
	local color = Color3.fromHex(Config.Rods.Colors[m])
	for _, container in { player:FindFirstChild("Backpack"), player.Character } do
		local rod = container and container:FindFirstChild("Rod")
		if rod and rod:IsA("Tool") and rod:GetAttribute("Level") == level and rod:FindFirstChild("Mesh") then
			continue
		end
		if rod and rod:IsA("Tool") and dress(rod, "Rod" .. level, Config.ItemModels.RodScale) then
			local handle = rod:FindFirstChild("Handle") :: BasePart
			local old = handle:FindFirstChild("Tip")
			local tip = if old and old:IsA("Attachment") then old else Instance.new("Attachment")
			tip.Name = "Tip"
			-- the rod's tip in Blender (art/blender/items.py rod): (0, -0.9, length) from the base, grip 0.4 up
			tip.Position = ItemModels.point(Config.ItemModels.RodScale, 0, -0.9, 4.6 + 0.04 * level - 0.4)
			tip.Parent = handle
			-- V2: the crank of the reel (items.py rod: reel centre (-0.42, 0, 1.45), the knob 0.42 further out on a
			-- 0.53 circle round the reel's axis = the handle's X); the right hand turns it (PlayerAnimController)
			local oldReel = handle:FindFirstChild("Reel")
			local reel = if oldReel and oldReel:IsA("Attachment") then oldReel else Instance.new("Attachment")
			reel.Name = "Reel"
			reel.Position = ItemModels.point(Config.ItemModels.RodScale, -0.84, 0, 1.45 - 0.4)
			reel:SetAttribute("Radius", 0.53 * Config.ItemModels.RodScale)
			reel.Parent = handle
			rod.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(Config.ItemModels.RodGrip), 0, 0)
			rod:SetAttribute("Level", level)
		elseif rod then
			for _, name in { "Pole", "TipPart" } do
				local p = rod:FindFirstChild(name)
				if p and p:IsA("BasePart") then
					p.Color = color
					p.Material = if m >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic
				end
			end
			rod:SetAttribute("Level", level)
		end
	end
end

-- V2: while fishing (attribute "Fishing") an R15 player holds the rod in the LEFT hand so the right hand can
-- turn the reel: Roblox's RightGrip weld is switched off and a LeftGrip weld holds the handle at the left
-- hand's grip; back to normal when fishing ends or the rod is put away.
local function leftHand(player: Player, on: boolean)
	local character = player.Character
	local rod = character and character:FindFirstChild("Rod")
	local handle = rod and rod:FindFirstChild("Handle")
	local hand = character and character:FindFirstChild("LeftHand")
	local right = character and character:FindFirstChild("RightHand")
	local rightGrip = right and right:FindFirstChild("RightGrip")
	local old = hand and hand:FindFirstChild("LeftGrip")
	if old then
		old:Destroy()
	end
	if rightGrip and rightGrip:IsA("JointInstance") then
		rightGrip.Enabled = not on
	end
	if not on or not rod or not rod:IsA("Tool") or not handle or not handle:IsA("BasePart") or not hand or not hand:IsA("BasePart") then
		return
	end
	local at = hand:FindFirstChild("LeftGripAttachment")
	local w = Instance.new("Weld")
	w.Name = "LeftGrip"
	w.Part0 = hand
	w.Part1 = handle
	w.C0 = if at and at:IsA("Attachment") then at.CFrame else CFrame.new(0, -hand.Size.Y / 2, 0)
	w.C1 = rod.Grip
	w.Parent = hand
end

local function give(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	-- the hotbar follows the order tools arrive: 1 = rod, 2 = bat (developer, round 2)
	if not backpack:FindFirstChild("Rod") and not (player.Character and player.Character:FindFirstChild("Rod")) then
		makeRod().Parent = backpack
	end
	if not backpack:FindFirstChild("Bat") and not (player.Character and player.Character:FindFirstChild("Bat")) then
		makeBat().Parent = backpack
	end
	ToolService.refreshRod(player)
end

function ToolService:Start()
	local function hook(player: Player)
		player:GetAttributeChangedSignal("Fishing"):Connect(function()
			leftHand(player, player:GetAttribute("Fishing") ~= nil)
		end)
		player.CharacterAdded:Connect(function()
			task.defer(give, player)
		end)
		if player.Character then
			task.defer(give, player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	DataService.Changed:Connect(ToolService.refreshRod) -- R5: a no-op unless the best rod changed
end

return ToolService
