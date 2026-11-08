--!strict
-- Gives every player the two hotbar tools on spawn (blueprint §4 / §16): the baseball bat and the fishing
-- rod, built from parts. The tools only show what the player holds: FishingService and BatService do the
-- work on the server (clients ask through Cast / Swing). Tool names stay English ("Bat", "Rod") because
-- the server finds the held tool by name.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
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

-- The handle is the grip, its long side along Y; the rest is welded to it.
local function makeBat(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Bat"
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
	return tool
end

local function makeRod(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Rod"
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

-- The rod's pole and tip take the colour of the best rod's material (task 2.2).
function ToolService.refreshRod(player: Player)
	local data = DataService.GetData(player)
	local level = if data then data.RodLevel else 1
	local m = Shop.rodMaterial(level)
	local color = Color3.fromHex(Config.Rods.Colors[m])
	for _, container in { player:FindFirstChild("Backpack"), player.Character } do
		local rod = container and container:FindFirstChild("Rod")
		if rod then
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

local function give(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	if not backpack:FindFirstChild("Bat") and not (player.Character and player.Character:FindFirstChild("Bat")) then
		makeBat().Parent = backpack
	end
	if not backpack:FindFirstChild("Rod") and not (player.Character and player.Character:FindFirstChild("Rod")) then
		makeRod().Parent = backpack
	end
	ToolService.refreshRod(player)
end

function ToolService:Start()
	local function hook(player: Player)
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
end

return ToolService
