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

local STAT_H = 52 -- W3: one bottom-left stat line (text height)
local STAT_ROW = 62 -- X1 (revision 4 item 5): rows spaced for the bigger icons
local STAT_ICON = 72 -- X1: icon size (was 52: too small to read on a phone)
local strengthValue: TextLabel
local speedLabel: TextLabel
local moneyLabel: TextLabel
local incomeLabel: TextLabel
local eventPills: { [string]: { frame: Frame, label: TextLabel } } = {} -- X1 (revision 4 item 7): Mythical + Secret

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

local EVENT_LIVE = { Mythical = Color3.fromHex("ff5fa2"), Secret = Color3.fromHex("18c9b9") }
local EVENT_WAIT = { Mythical = Color3.fromHex("6c4fc4"), Secret = Color3.fromHex("146f78") }

-- X1 (revision 4 item 7): each event has its own pill: "Secret in 32:10", or "Secret cat out! 2:41" while it is on
local function eventText(which: string): (string?, Color3)
	local now = workspace:GetServerTimeNow()
	local live = workspace:GetAttribute("LiveEvent")
	if live == which then
		local ends = workspace:GetAttribute("LiveEventEnds")
		local left = if type(ends) == "number" then ends - now else 0
		return Lang.text("EventLive", { event = Lang.text("Event" .. which), time = Format.clock(math.max(0, left)) }), EVENT_LIVE[which]
	end
	local at = workspace:GetAttribute(`Next{which}At`)
	if type(at) ~= "number" then
		return nil, EVENT_WAIT[which]
	end
	return Lang.text("EventNext", { event = Lang.text("Event" .. which), time = Format.clock(math.max(0, at - now)) }), EVENT_WAIT[which]
end

local function build()
	-- left column (My Cats is added by MyCatsController)
	local soon = function()
		ToastController.show("ComingSoon", nil, "info")
	end
	-- X3 (revision 4 item 13): no Shop button; the Shop is a stall on the plaza (MarketController)
	-- X1 (revision 4 item 23): the x2 Speed button only while the pass is sold
	local speed = if Config.Passes.Speed2x.Sold ~= false then Hud.leftButton("Speed2x", "Speed2xButton", C.sky, 2, StoreController.speedButton) else nil
	if speed then
		local button: TextButton = speed
		local holder = button.Parent :: Frame
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
				Kit.setButtonText(button, Lang.text(if d and d.SpeedPassOn == false then "SpeedOff" else "SpeedOn"))
				Kit.setButtonColor(button, if d and d.SpeedPassOn == false then C.grey else C.green)
			end
		end
		me:GetAttributeChangedSignal("PassSpeed"):Connect(speedText)
		require(script.Parent.Parent.PlayerData).changed:Connect(speedText)
		Lang.changed:Connect(speedText)
		speedText()
	end
	Hud.leftButton("Trade", "TradeButton", C.purple, 4, TradeController.toggle)
	-- 2026-11-15 (developer): a Robux shop button beside Rewards (the Shop window, Robux tab only)
	local robuxShop = Hud.leftButton("Shop", "RobuxShopButton", C.coral, 7, function()
		if ShopController.isRobuxOnly() then
			ShopController.toggle()
		else
			ShopController.open(true)
		end
	end)
	-- 2026-11-18 (revision list 6): a gold Robux coin on it (Config.UIIcons.RobuxCoin, our own picture), once uploaded
	local coin = (Config.UIIcons :: any).RobuxCoin
	local coinIcon = robuxShop:FindFirstChild("Icon")
	if type(coin) == "number" and coin > 0 and coinIcon and coinIcon:IsA("ImageLabel") then
		coinIcon.Image = `rbxassetid://{coin}`
	end

	-- W3 (revision 3 item 10): Strength, Speed and money big at the bottom left, no panels: a big icon and a
	-- big outlined number per line (the old right-hand Strength panel with the gym levels is gone; the levels
	-- are on the gym's own upgrade boards)
	local gui = Kit.screen("HudStats", 2)
	local bl = Instance.new("Frame")
	bl.Name = "BottomLeft"
	bl.BackgroundTransparency = 1
	bl.AnchorPoint = Vector2.new(0, 1)
	bl.Position = UDim2.new(0, 12, 1, -10)
	bl.Size = UDim2.fromOffset(340, 3 * STAT_ROW + 24)
	bl.Parent = gui
	fitScale(bl, 720)
	Kit.edge(gui, bl, "left") -- hugs the left edge of a phone (revision 3, after W2)
	local function statLine(name: string, row: number, color: Color3): TextLabel
		local line = Instance.new("Frame")
		line.Name = name
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, STAT_ROW)
		line.Position = UDim2.fromOffset(0, (row - 1) * STAT_ROW)
		line.Parent = bl
		local t = Kit.text(line, "Value", UDim2.new(1, -STAT_ICON - 6, 1, 0), UDim2.fromOffset(STAT_ICON + 4, 0), STAT_H - 10, true)
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
	local iconAt = UDim2.fromOffset(0, (STAT_ROW - STAT_ICON) / 2) -- centred on the row, a little over its edges
	Kit.icon(bl:FindFirstChild("Strength") :: Instance, "Strength", STAT_ICON, iconAt)
	speedLabel = statLine("Speed", 2, Color3.fromHex("8fdcff"))
	Kit.icon(bl:FindFirstChild("Speed") :: Instance, "Speed", STAT_ICON, iconAt)
	moneyLabel = statLine("Money", 3, Color3.fromHex("6dea6d"))
	coin(bl:FindFirstChild("Money") :: Instance, STAT_ICON - 6, iconAt + UDim2.fromOffset(3, 3))
	incomeLabel = Kit.text(bl, "Income", UDim2.new(1, -STAT_ICON - 6, 0, 22), UDim2.fromOffset(STAT_ICON + 6, 3 * STAT_ROW), 20, true)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.TextColor3 = Color3.fromHex("b8ffb8")

	-- bottom-right: event countdown (W2: on touch screens top-right under the gear, clear of Roblox's jump button)
	local touch = game:GetService("UserInputService").TouchEnabled
	-- X1: two pills stacked, Mythical then Secret (touch: under the gear going down; PC: bottom right going up)
	for i, which in { "Mythical", "Secret" } do
		local step = (i - 1) * 52 * Kit.scaleFor(720, 0.6) -- the pills shrink on small screens (fitScale), so the gap does too
		local f = if touch
			then pill(gui, which .. "Event", UDim2.fromOffset(250, 44), UDim2.new(1, -12, 0, 92 + step), Vector2.new(1, 0))
			else pill(gui, which .. "Event", UDim2.fromOffset(250, 44), UDim2.new(1, -12, 1, -12 - (2 - i) * 52 * Kit.scaleFor(720, 0.6)), Vector2.new(1, 1))
		f.BackgroundColor3 = EVENT_WAIT[which]
		fitScale(f, 720)
		if touch then
			Kit.edge(gui, f, "right")
		end
		if (Config.UIIcons :: any).Event > 0 then
			Kit.icon(f, "Event", 48, UDim2.fromOffset(-14, -6))
		end
		local label = Kit.text(f, "Text", UDim2.new(1, -44, 1, -6), UDim2.fromOffset(34, 3), 22, true)
		label.TextScaled = true
		f.Visible = false
		eventPills[which] = { frame = f, label = label }
	end
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
			for which, p in eventPills do
				local text, color = eventText(which)
				p.frame.Visible = text ~= nil
				p.frame.BackgroundColor3 = color
				if text then
					p.label.Text = text
				end
			end
			task.wait(0.5)
		end
	end)
end

return HudController
