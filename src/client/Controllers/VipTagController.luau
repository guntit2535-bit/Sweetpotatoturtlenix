--!strict
-- The VIP tag (task 2.18): a gold "VIP" label over every player who owns the VIP pass (attribute PassVIP),
-- seen by everyone. Drawn on each client.

local Players = game:GetService("Players")

local Kit = require(script.Parent.Parent.UI.Kit)

local VipTagController = {}

local function refresh(player: Player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild("VipTag")
	if player:GetAttribute("PassVIP") ~= true then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipTag"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(70, 28)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromHex("f5bf2e")
	f.Parent = gui
	Kit.corner(f, 10)
	Kit.stroke(f, 2, nil, true)
	local t = Kit.text(f, "Text", UDim2.fromScale(1, 1), UDim2.new(), 20, true)
	t.Text = "VIP"
	gui.Parent = head
end

local function hook(player: Player)
	player:GetAttributeChangedSignal("PassVIP"):Connect(function()
		refresh(player)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		refresh(player)
	end)
	refresh(player)
end

function VipTagController.Start(_self: any)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return VipTagController
