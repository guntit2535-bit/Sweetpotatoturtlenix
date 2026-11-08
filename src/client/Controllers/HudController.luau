--!strict
-- The HUD (task 1.17, blueprint §16), phone first:
--   left    Shop, x2 Speed (big, softly blinking), My Cats (MyCatsController), Trade
--   right   Strength (kg) + weights and treadmill levels, under the Settings gear
--   bottom-left   Speed and money (+ money per second)
--   bottom-centre the hotbar (Roblox's own: Bat + Rod)
--   bottom-right  the event countdown (workspace attributes from EventService, task 1.18)
-- Every number comes from the player's attributes (DataService / PenService).
-- R9 cute-cat look (art/source/gpt_ui/01_hud): cream panels with cat ears and navy outlines, icons from
-- Config.UIIcons (the drawn coin / dumbbell until they are uploaded).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)
local Hud = require(script.Parent.Parent.UI.Hud)
local ShopController = require(script.Parent.ShopController)
local StoreController = require(script.Parent.StoreController)
local ToastController = require(script.Parent.ToastController)
local TradeController = require(script.Parent.TradeController)

local HudController = {}

local C = Kit.Colors
local me = Players.LocalPlayer

local strengthValue: TextLabel
local strengthTitle: TextLabel
local weightsLine: TextLabel
local treadLine: TextLabel
local speedLabel: TextLabel
local moneyLabel: TextLabel
local incomeLabel: TextLabel
local eventFrame: Frame
local eventLabel: TextLabel

local function num(name: string): number
	local v = me:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

local function fitScale(parent: Instance, base: number)
	local scale = Instance.new("UIScale")
	scale.Parent = parent
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = math.clamp(h / base, 0.6, 1)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end

local function pill(parent: Instance, name: string, size: UDim2, pos: UDim2, anchor: Vector2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = C.panel
	f.Parent = parent
	Kit.corner(f, 24)
	Kit.stroke(f, 3, nil, true)
	return f
end

local function coin(parent: Instance, size: number, pos: UDim2)
	if (Config.UIIcons :: any).Coin > 0 then
		Kit.icon(parent, "Coin", size + 6, pos - UDim2.fromOffset(3, 3))
		return
	end
	local c = Instance.new("Frame")
	c.Size = UDim2.fromOffset(size, size)
	c.Position = pos
	c.BackgroundColor3 = C.yellow
	c.Parent = parent
	Kit.corner(c, size)
	Kit.stroke(c, 3, nil, true)
	local inner = Instance.new("TextLabel")
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromScale(1, 1)
	inner.Font = Kit.Font
	inner.Text = "$"
	inner.TextColor3 = Color3.fromHex("c98a00")
	inner.TextScaled = true
	inner.Parent = c
end

local function dumbbell(parent: Instance, pos: UDim2)
	if (Config.UIIcons :: any).Strength > 0 then
		Kit.icon(parent, "Strength", 44, pos - UDim2.fromOffset(0, 10))
		return
	end
	local d = Instance.new("Frame")
	d.BackgroundTransparency = 1
	d.Size = UDim2.fromOffset(46, 24)
	d.Position = pos
	d.Parent = parent
	local barF = Instance.new("Frame")
	barF.AnchorPoint = Vector2.new(0.5, 0.5)
	barF.Position = UDim2.fromScale(0.5, 0.5)
	barF.Size = UDim2.new(1, -8, 0, 6)
	barF.BackgroundColor3 = C.grey
	barF.Parent = d
	Kit.stroke(barF, 2, nil, true)
	for _, x in { 0, 1 } do
		local w = Instance.new("Frame")
		w.AnchorPoint = Vector2.new(x, 0.5)
		w.Position = UDim2.fromScale(x, 0.5)
		w.Size = UDim2.fromOffset(12, 24)
		w.BackgroundColor3 = C.coral
		w.Parent = d
		Kit.corner(w, 4)
		Kit.stroke(w, 2, nil, true)
	end
end

local function refresh()
	strengthTitle.Text = Lang.text("StrengthLabel")
	strengthValue.Text = Lang.text("KgValue", { kg = Format.short(num("Strength")) })
	weightsLine.Text = Lang.text("WeightsLv", { level = math.max(1, num("WeightsLevel")), max = Config.Weights.Levels })
	treadLine.Text = Lang.text("TreadLv", { level = math.max(1, num("TreadLevel")), max = Config.Treadmill.Levels })
	speedLabel.Text = Lang.text("SpeedValue", { speed = Format.money(num("Speed")) })
	moneyLabel.Text = "$" .. Format.short(num("Money"))
	incomeLabel.Text = Lang.text("IncomeRate", { money = Format.money(num("Income")) })
end

local function eventText()
	local now = workspace:GetServerTimeNow()
	local live = workspace:GetAttribute("LiveEvent")
	if type(live) == "string" then
		local ends = workspace:GetAttribute("LiveEventEnds")
		local left = if type(ends) == "number" then ends - now else 0
		eventFrame.BackgroundColor3 = if live == "Secret" then Color3.fromHex("18c9b9") else Color3.fromHex("ff5fa2")
		return Lang.text("EventLive", { event = Lang.text("Event" .. live), time = Format.clock(math.max(0, left)) })
	end
	local m = workspace:GetAttribute("NextMythicalAt")
	local s = workspace:GetAttribute("NextSecretAt")
	if type(m) ~= "number" and type(s) ~= "number" then
		return nil
	end
	local which, at = "Mythical", (m :: number?) or math.huge
	if type(s) == "number" and s < at then
		which, at = "Secret", s
	end
	eventFrame.BackgroundColor3 = Color3.fromHex("6c4fc4")
	return Lang.text("EventNext", { event = Lang.text("Event" .. which), time = Format.clock(math.max(0, at - now)) })
end

local function build()
	-- left column (My Cats is added by MyCatsController)
	local soon = function()
		ToastController.show("ComingSoon", nil, "info")
	end
	Hud.leftButton("Shop", "ShopButton", C.coral, 1, ShopController.toggle)
	local speed = Hud.leftButton("Speed2x", "Speed2xButton", C.sky, 2, StoreController.speedButton)
	local holder = speed.Parent :: Frame
	local glow = Instance.new("UIStroke")
	glow.Thickness = 5
	glow.Color = C.yellow
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = holder:FindFirstChild("Lip")
	RunService.RenderStepped:Connect(function()
		if me:GetAttribute("PassSpeed") == true then
			glow.Transparency = 1
		else
			glow.Transparency = 0.35 + 0.35 * math.sin(os.clock() * 3)
		end
	end)
	local function speedText()
		if me:GetAttribute("PassSpeed") == true then
			local d = require(script.Parent.Parent.PlayerData).get()
			Kit.setButtonText(speed, Lang.text(if d and d.SpeedPassOn == false then "SpeedOff" else "SpeedOn"))
			Kit.setButtonColor(speed, if d and d.SpeedPassOn == false then C.grey else C.green)
		end
	end
	me:GetAttributeChangedSignal("PassSpeed"):Connect(speedText)
	require(script.Parent.Parent.PlayerData).changed:Connect(speedText)
	Lang.changed:Connect(speedText)
	speedText()
	Hud.leftButton("Trade", "TradeButton", C.purple, 4, TradeController.toggle)

	-- right: Strength panel under the gear
	local gui = Kit.screen("HudStats", 2)
	local right = Instance.new("Frame")
	right.Name = "Strength"
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -12, 0, 104)
	right.Size = UDim2.fromOffset(210, 160)
	right.BackgroundColor3 = C.panel
	right.Parent = gui
	Kit.corner(right, 22)
	Kit.stroke(right, 4, nil, true)
	Kit.ears(right, 30, { 0.22, 0.78 })
	fitScale(right, 720)
	dumbbell(right, UDim2.fromOffset(12, 12))
	strengthTitle = Kit.text(right, "Title", UDim2.new(1, -72, 0, 24), UDim2.fromOffset(66, 12), 20)
	strengthTitle.TextXAlignment = Enum.TextXAlignment.Left
	strengthTitle.TextColor3 = C.muted
	strengthValue = Kit.text(right, "Value", UDim2.new(1, -16, 0, 44), UDim2.fromOffset(8, 40), 38)
	strengthValue.TextScaled = true
	for i, nameKey in { "Weights", "Treadmill" } do
		local line = Instance.new("Frame")
		line.Name = nameKey .. "Pill"
		line.Size = UDim2.new(1, -20, 0, 26)
		line.Position = UDim2.fromOffset(10, 88 + (i - 1) * 32)
		line.BackgroundColor3 = C.soft
		line.Parent = right
		Kit.corner(line, 13)
		Kit.stroke(line, 2, C.peach, true)
		local t = Kit.text(line, nameKey, UDim2.new(1, -12, 1, 0), UDim2.fromOffset(6, 0), 18)
		if i == 1 then
			weightsLine = t
		else
			treadLine = t
		end
	end

	-- bottom-left: speed + money
	local bl = Instance.new("Frame")
	bl.Name = "BottomLeft"
	bl.BackgroundTransparency = 1
	bl.AnchorPoint = Vector2.new(0, 1)
	bl.Position = UDim2.new(0, 12, 1, -12)
	bl.Size = UDim2.fromOffset(250, 104)
	bl.Parent = gui
	fitScale(bl, 720)
	local sp = pill(bl, "Speed", UDim2.fromOffset(190, 40), UDim2.fromOffset(0, 0), Vector2.zero)
	Kit.icon(sp, "Speed", 40, UDim2.fromOffset(2, 0))
	speedLabel = Kit.text(sp, "Text", UDim2.new(1, -50, 1, 0), UDim2.fromOffset(44, 0), 22)
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.TextColor3 = Color3.fromHex("1f7ad6")
	local mo = pill(bl, "Money", UDim2.fromOffset(250, 54), UDim2.fromOffset(0, 48), Vector2.zero)
	coin(mo, 40, UDim2.fromOffset(7, 7))
	moneyLabel = Kit.text(mo, "Money", UDim2.new(0, 120, 1, 0), UDim2.fromOffset(54, 0), 30)
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.TextColor3 = Color3.fromHex("2f9a3a")
	incomeLabel = Kit.text(mo, "Income", UDim2.new(0, 80, 1, 0), UDim2.new(1, -88, 0, 0), 18)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Right
	incomeLabel.TextColor3 = Color3.fromHex("2f9a3a")

	-- bottom-right: event countdown
	eventFrame = pill(gui, "Event", UDim2.fromOffset(250, 44), UDim2.new(1, -12, 1, -12), Vector2.new(1, 1))
	eventFrame.BackgroundColor3 = Color3.fromHex("6c4fc4")
	fitScale(eventFrame, 720)
	if (Config.UIIcons :: any).Event > 0 then
		Kit.icon(eventFrame, "Event", 48, UDim2.fromOffset(-14, -6))
	end
	eventLabel = Kit.text(eventFrame, "Text", UDim2.new(1, -44, 1, -6), UDim2.fromOffset(34, 3), 22, true)
	eventLabel.TextScaled = true
	eventFrame.Visible = false
end

function HudController.Start(_self: any)
	build()
	refresh()
	for _, attr in { "Strength", "WeightsLevel", "TreadLevel", "Speed", "Money", "Income" } do
		me:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	Lang.changed:Connect(refresh)
	task.spawn(function()
		while true do
			local text = eventText()
			eventFrame.Visible = text ~= nil
			if text then
				eventLabel.Text = text
			end
			task.wait(0.5)
		end
	end)
end

return HudController
