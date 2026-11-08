--!strict
-- The cat icon floating over every player who carries a cat (task 1.13, blueprint §3): everyone can see
-- whom to chase with a bat. Drawn on each client from the player attributes CarryingCat / CarryingTier
-- (CarryService); always on top so it shows through walls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Kit = require(script.Parent.Parent.UI.Kit)

local CarryIconController = {}

local icons: { [Player]: BillboardGui } = {}

local function catFace(parent: Instance, color: Color3)
	local face = Instance.new("Frame")
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.56)
	face.Size = UDim2.fromScale(0.72, 0.6)
	face.BackgroundColor3 = color
	face.ZIndex = 2
	face.Parent = parent
	Kit.corner(face, 10)
	Kit.stroke(face, 3, nil, true)
	for _, x in { 0.28, 0.72 } do
		local ear = Instance.new("Frame")
		ear.AnchorPoint = Vector2.new(0.5, 0.5)
		ear.Position = UDim2.fromScale(x, 0.06)
		ear.Size = UDim2.fromScale(0.26, 0.3)
		ear.SizeConstraint = Enum.SizeConstraint.RelativeXX
		ear.Rotation = 45
		ear.BackgroundColor3 = color
		ear.ZIndex = 1
		ear.Parent = face
		Kit.stroke(ear, 3, nil, true)
		local eye = Instance.new("Frame")
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(x, 0.45)
		eye.Size = UDim2.fromScale(0.13, 0.24)
		eye.BackgroundColor3 = Kit.Colors.ink
		eye.ZIndex = 3
		eye.Parent = face
		Kit.corner(eye, 4)
	end
	local nose = Instance.new("Frame")
	nose.AnchorPoint = Vector2.new(0.5, 0.5)
	nose.Position = UDim2.fromScale(0.5, 0.68)
	nose.Size = UDim2.fromScale(0.14, 0.1)
	nose.BackgroundColor3 = Color3.fromHex("ff8fb0")
	nose.ZIndex = 3
	nose.Parent = face
	Kit.corner(nose, 3)
end

local function refresh(player: Player)
	local old = icons[player]
	if old then
		old:Destroy()
		icons[player] = nil
	end
	local kind = player:GetAttribute("CarryingCat")
	local head = player.Character and player.Character:FindFirstChild("Head")
	if type(kind) ~= "string" or not head or not head:IsA("BasePart") then
		return
	end
	local tier = player:GetAttribute("CarryingTier")
	local t = Config.Tiers[if type(tier) == "number" then tier else 1]
	local gui = Instance.new("BillboardGui")
	gui.Name = "CarryIcon"
	gui.Adornee = head
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(64, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 10, 0)
	gui.LightInfluence = 0
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundColor3 = Color3.fromHex(t.Color)
	ring.Parent = gui
	Kit.corner(ring, 32)
	Kit.stroke(ring, 4, Kit.Colors.white, true)
	catFace(ring, Color3.fromHex("ffd9a8"))
	gui.Parent = head
	icons[player] = gui
end

local function hook(player: Player)
	player:GetAttributeChangedSignal("CarryingCat"):Connect(function()
		refresh(player)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		refresh(player)
	end)
	refresh(player)
end

function CarryIconController.Start(_self: any)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(p)
		icons[p] = nil
	end)
end

return CarryIconController
