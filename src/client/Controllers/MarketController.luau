--!strict
-- X3 (revision 4 items 13 + 18): the market on the plaza (BuildMap.market). Writes the two signs in the player's
-- language and opens the Shop window when the player steps onto the shop stall's glowing pad (once per visit: it
-- opens again only after stepping off and back on). Selling a carried cat at the sell booth is the action button
-- (ActionController + CarryService). The HUD has no Shop button any more.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Lang = require(script.Parent.Parent.Lang)
local ShopController = require(script.Parent.ShopController)

local MarketController = {}

local me = Players.LocalPlayer
local INK = Color3.fromHex("2b2d52")

local function market(): Instance?
	local map = workspace:FindFirstChild("Map")
	local lobby = map and map:FindFirstChild("Lobby")
	return lobby and lobby:FindFirstChild("Market")
end

-- The shop stall's pad (the tutorial points at it too).
function MarketController.shopPad(): BasePart?
	local m = market()
	local stall = m and m:FindFirstChild("ShopStall")
	local pad = stall and stall:FindFirstChild("Pad")
	return if pad and pad:IsA("BasePart") then pad else nil
end

local labels: { [TextLabel]: string } = {}

local function writeSign(model: Instance?, key: string)
	local board = model and model:FindFirstChild("SignBoard")
	if not board or not board:IsA("BasePart") or board:FindFirstChild("SignText") then
		return
	end
	local g = Instance.new("SurfaceGui")
	g.Name = "SignText"
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = Lang.text(key)
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = INK
	s.Parent = t
	labels[t] = key
end

function MarketController.Start(_self: any)
	Lang.changed:Connect(function()
		for t, key in labels do
			t.Text = Lang.text(key)
		end
	end)
	task.spawn(function()
		local wasOn = false
		while true do
			task.wait(Config.Market.CheckEvery)
			local m = market()
			if m then
				writeSign(m:FindFirstChild("ShopStall"), "ShopSign")
				writeSign(m:FindFirstChild("SellBooth"), "SellSign")
			end
			local pad = MarketController.shopPad()
			local character = me.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local on = false
			if pad and root and root:IsA("BasePart") then
				local d = Vector3.new(root.Position.X - pad.Position.X, 0, root.Position.Z - pad.Position.Z).Magnitude
				on = d <= Config.Market.PadRange and math.abs(root.Position.Y - pad.Position.Y) < 12
			end
			if on and not wasOn then
				local shop = me.PlayerGui:FindFirstChild("ShopWindow")
				if not (shop and shop:IsA("ScreenGui") and shop.Enabled) then
					ShopController.toggle()
				end
			end
			wasOn = on
		end
	end)
end

return MarketController
