--!strict
-- The HUD (task 1.17, blueprint §16), phone first:
--   left (middle)  a grid of small buttons: Shop | x2 Speed, My Cats | Trade, Rebirth | Rewards (UI/Hud, W3)
--   top-right      the Settings gear (SettingsController)
--   bottom-left    Strength, Speed and money, big (+ money per second) (W3)
--   bottom-centre the hotbar (Roblox's own: Bat + Rod)
--   bottom-right  the event countdown (workspace attributes from EventService, task 1.18)
-- Every number comes from the player's attributes (DataService / PenService).
-- R9 cute-cat look (art/source/gpt_ui/01_hud): cream panels with cat ears and navy outlines, icons from
-- Config.UIIcons (the drawn coin until it is uploaded).

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

local STAT_H = 52 -- W3: one bottom-left stat line (icon size and text height)
local strengthValue: TextLabel
local speedLabel: TextLabel
local moneyLabel: TextLabel
local incomeLabel: TextLabel
local eventFrame: Frame
local eventLabel: TextLabel

local function num(name: string): number
	local v = me:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

local function fitScale(parent: GuiObject, base: number)
	Kit.fit(parent, base, 0.6)
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

local function refresh()
	strengthValue.Text = Lang.text("KgValue", { kg = Format.short(num("Strength")) })
	speedLabel.Text = Format.short(num("Speed"))
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

	-- W3 (revision 3 item 10): Strength, Speed and money big at the bottom left, no panels: a big icon and a
	-- big outlined number per line (the old right-hand Strength panel with the gym levels is gone; the levels
	-- are on the gym's own upgrade boards)
	local gui = Kit.screen("HudStats", 2)
	local bl = Instance.new("Frame")
	bl.Name = "BottomLeft"
	bl.BackgroundTransparency = 1
	bl.AnchorPoint = Vector2.new(0, 1)
	bl.Position = UDim2.new(0, 12, 1, -10)
	bl.Size = UDim2.fromOffset(320, 3 * STAT_H + 24)
	bl.Parent = gui
	fitScale(bl, 720)
	local function statLine(name: string, row: number, color: Color3): TextLabel
		local line = Instance.new("Frame")
		line.Name = name
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, STAT_H)
		line.Position = UDim2.fromOffset(0, (row - 1) * STAT_H)
		line.Parent = bl
		local t = Kit.text(line, "Value", UDim2.new(1, -STAT_H - 8, 1, 0), UDim2.fromOffset(STAT_H + 6, 0), STAT_H - 10, true)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = color
		t.TextWrapped = false
		local stroke = t:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = 3.5
		end
		return t
	end
	strengthValue = statLine("Strength", 1, Color3.fromHex("ff7a7a"))
	Kit.icon(bl:FindFirstChild("Strength") :: Instance, "Strength", STAT_H, UDim2.new())
	speedLabel = statLine("Speed", 2, Color3.fromHex("8fdcff"))
	Kit.icon(bl:FindFirstChild("Speed") :: Instance, "Speed", STAT_H, UDim2.new())
	moneyLabel = statLine("Money", 3, Color3.fromHex("6dea6d"))
	coin(bl:FindFirstChild("Money") :: Instance, STAT_H - 6, UDim2.fromOffset(3, 3))
	incomeLabel = Kit.text(bl, "Income", UDim2.new(1, -STAT_H - 8, 0, 22), UDim2.fromOffset(STAT_H + 8, 3 * STAT_H), 20, true)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.TextColor3 = Color3.fromHex("b8ffb8")

	-- bottom-right: event countdown (W2: on touch screens top-right under the gear, clear of Roblox's jump button)
	local touch = game:GetService("UserInputService").TouchEnabled
	eventFrame = if touch
		then pill(gui, "Event", UDim2.fromOffset(250, 44), UDim2.new(1, -12, 0, 92), Vector2.new(1, 0))
		else pill(gui, "Event", UDim2.fromOffset(250, 44), UDim2.new(1, -12, 1, -12), Vector2.new(1, 1))
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
	-- W2 (revision 3 item 12): phones stay in landscape (turning either way), the layout is made for it; the place
	-- had Sensor, which let a phone turn the game to portrait
	pcall(function()
		(me:WaitForChild("PlayerGui") :: PlayerGui).ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
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
