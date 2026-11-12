--!strict
-- The Shop window (tasks 2.1 - 2.5; W4 = revision 3 items 4 + 5): tabs Rods / Shoes / Treats / Crates / Robux, each a
-- rail of tall cards swiped left / right (UI/ShopCard, look A). Crates and Robux fill their tab through
-- setCratesBuilder / setRobuxBuilder with ShopController.card. The Pen tab is gone: pen slots are bought at the
-- board in front of your pen (PenBoardController). Prices come from shared/Shop (the same numbers the server
-- charges); the client only asks (BuyItem) and redraws from the save copy. The window is wide and short so it
-- stays big on a phone (W2: 700 x 340 keeps ~0.8 scale on a 375 px tall screen).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FishingBar = require(Shared:WaitForChild("FishingBar"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Shop = require(Shared:WaitForChild("Shop"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local ItemPortrait = require(script.Parent.Parent.UI.ItemPortrait)
local ShopCard = require(script.Parent.Parent.UI.ShopCard)

local ShopController = {}

local C = Kit.Colors
local TABS = { "Rods", "Shoes", "Treats", "Crates", "Robux" }
local window: Kit.Window
local list: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local current = "Rods"
local buyRemote: RemoteEvent
local cratesBuilder: ((list: ScrollingFrame) -> ())? = nil
local robuxBuilder: ((list: ScrollingFrame) -> ())? = nil
local jumpNext = false -- show the next thing to buy when a tab is opened

export type CardOptions = ShopCard.Options

-- One card on the open tab's rail (used by CrateController / StoreController too).
function ShopController.card(rail: ScrollingFrame, order: number, o: CardOptions): Frame
	return ShopCard.make(rail, order, o)
end

-- A picture filler for ShopCard: the item's mesh (R5) seen from `view`.
local function mesh(id: string, view: Vector3?): (box: Frame) -> boolean
	return function(box: Frame): boolean
		return ItemPortrait.make(box, id, view) ~= nil
	end
end

-- The button of an item bought in order (rods, shoes).
local function ladderButton(state: string, cost: number?, onBuy: () -> ()): { text: string, color: Color3, onClick: (() -> ())? }
	if state == "buy" then
		return { text = Lang.text("Buy", { cost = Format.short(cost or 0) }), color = C.green, onClick = onBuy }
	elseif state == "inuse" then
		return { text = Lang.text("InUse"), color = C.purple }
	elseif state == "owned" then
		return { text = Lang.text("Owned"), color = C.grey }
	end
	return { text = Lang.text("BuyPreviousShort"), color = C.grey }
end

local function drawRods(data: { [string]: any }): number
	local have = data.RodLevel or 1
	local base = FishingBar.params(1, 1)
	for level = 1, Config.Rods.Levels do
		local m, n = Shop.rodMaterial(level)
		local p = FishingBar.params(1, level)
		local zone = math.floor((p.zone / base.zone - 1) * 100 + 0.5)
		local fill = math.floor((p.fill / base.fill - 1) * 100 + 0.5)
		local luck = math.floor((level - 1) * Config.Rods.LuckPerLevel * 100 + 0.5)
		local state = if level == have then "inuse" elseif level < have then "owned" elseif level == have + 1 then "buy" else "locked"
		ShopCard.make(list, level, {
			title = Lang.text("RodName", { material = Lang.text("Mat" .. Config.Rods.Materials[m]), n = n }),
			color = Color3.fromHex(Config.Rods.Colors[m]),
			lines = {
				{ Lang.text("StatZone", { n = zone }) },
				{ Lang.text("StatMeter", { n = fill }) },
				{ Lang.text("StatLuck", { n = luck }) },
			},
			picture = mesh("Rod" .. level, Vector3.new(1, 0.15, -0.3)),
			button = ladderButton(state, Shop.rodCost(level), function()
				buyRemote:FireServer("Rod", level)
			end),
			highlight = state == "inuse",
		})
	end
	return have
end

local function drawShoes(data: { [string]: any }): number
	local have = data.Shoes or 0
	for pair, s in Config.Shoes.List do
		local state = if pair == have then "inuse" elseif pair < have then "owned" elseif pair == have + 1 then "buy" else "locked"
		ShopCard.make(list, pair, {
			title = Lang.text("Shoe" .. s.Key),
			color = C.sky,
			lines = { { Lang.text("ShoeEffect", { speed = s.Speed }) } },
			picture = mesh("Shoe_" .. s.Key, Vector3.new(-1, 0.55, -0.6)),
			button = ladderButton(state, s.Cost, function()
				buyRemote:FireServer("Shoes", pair)
			end),
			highlight = state == "inuse",
		})
	end
	return math.max(1, have)
end

local function localIncome(): number
	local v = game:GetService("Players").LocalPlayer:GetAttribute("Income")
	return if type(v) == "number" then v else 0
end

local function drawTreats(data: { [string]: any })
	local income = localIncome()
	local boosts = data.Boosts or {}
	local now = workspace:GetServerTimeNow()
	for i, t in Config.Treats.List do
		local left = (boosts[t.Key] or 0) - now
		local lines: { ShopCard.Line } = { { Lang.text("Treat" .. t.Name .. "Desc") } }
		if left > 0 then
			table.insert(lines, { Lang.text("TreatLeft", { time = Format.clock(left) }), C.green })
		end
		ShopCard.make(list, i, {
			title = Lang.text("Treat" .. t.Name),
			color = if t.Key == "Money" then C.yellow elseif t.Key == "Luck" then C.green else C.purple,
			lines = lines,
			picture = mesh("Treat_" .. t.Name, Vector3.new(0.4, 0.35, -1)),
			button = { text = Lang.text("Buy", { cost = Format.short(Shop.treatCost(t.Key, income)) }), color = C.green, onClick = function()
				buyRemote:FireServer("Treat", t.Key)
			end },
		})
	end
end

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("ShopTitle")
	for tab, b in tabButtons do
		Kit.setButtonText(b, Lang.text("Tab" .. tab))
		Kit.setButtonColor(b, if tab == current then C.yellow else C.tab)
	end
	local keep = list.CanvasPosition
	ShopCard.clear(list)
	local data = PlayerData.get() or {}
	local first = 1 -- the card to show first: the one before the next thing to buy
	if current == "Rods" then
		first = drawRods(data)
	elseif current == "Shoes" then
		first = drawShoes(data)
	elseif current == "Treats" then
		drawTreats(data)
	elseif current == "Crates" and cratesBuilder then
		cratesBuilder(list)
	elseif current == "Robux" and robuxBuilder then
		robuxBuilder(list)
	end
	if jumpNext then
		jumpNext = false
		ShopCard.jumpTo(list, first)
	else
		list.CanvasPosition = keep
	end
end

function ShopController.setCratesBuilder(builder: (list: ScrollingFrame) -> ())
	cratesBuilder = builder
end

function ShopController.setRobuxBuilder(builder: (list: ScrollingFrame) -> ())
	robuxBuilder = builder
end

-- Opens the window on a tab (the x2 Speed button opens Robux).
function ShopController.openTab(tab: string)
	current = tab
	jumpNext = true
	redraw()
	window.setOpen(true)
end

function ShopController.redraw()
	if window and window.isOpen() then
		redraw()
	end
end

function ShopController.toggle()
	if window.isOpen() then
		window.setOpen(false)
	else
		jumpNext = true
		redraw()
		window.setOpen(true)
	end
end

local function build()
	window = Kit.window({ name = "ShopWindow", width = 700, height = 340, color = C.coral })
	-- R9 (mockup 02): the player's money in a pill at the top right of the window
	local moneyPill = Instance.new("Frame")
	moneyPill.Name = "Money"
	moneyPill.AnchorPoint = Vector2.new(1, 0)
	moneyPill.Position = UDim2.new(1, -58, 0, 14)
	moneyPill.Size = UDim2.fromOffset(118, 40)
	moneyPill.BackgroundColor3 = C.soft
	moneyPill.Parent = window.panel
	Kit.corner(moneyPill, 20)
	Kit.stroke(moneyPill, 3, nil, true)
	Kit.icon(moneyPill, "Coin", 34, UDim2.fromOffset(4, 3))
	local moneyText = Kit.text(moneyPill, "Value", UDim2.new(1, -46, 1, 0), UDim2.fromOffset(40, 0), 22, true)
	local me = game:GetService("Players").LocalPlayer
	local function showMoney()
		local m = me:GetAttribute("Money")
		moneyText.Text = "$" .. Format.short(if type(m) == "number" then m else 0)
	end
	showMoney()
	me:GetAttributeChangedSignal("Money"):Connect(showMoney)
	local tabs = Instance.new("Frame")
	tabs.Name = "Tabs"
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 40)
	tabs.Parent = window.body
	tabs.Position = UDim2.fromOffset(0, 4)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabs
	for i, tab in TABS do
		if tab == "Shoes" and not Config.Shoes.Enabled then
			continue
		end
		local b = Kit.button(tabs, tab, C.tab, UDim2.fromOffset(96, 36), UDim2.new())
		;(b.Parent :: Frame).LayoutOrder = i
		b.Activated:Connect(function()
			current = tab
			jumpNext = true
			redraw()
		end)
		tabButtons[tab] = b
	end
	list = ShopCard.rail(window.body, 48)
end

function ShopController.Start(_self: any)
	buyRemote = Remotes.event("BuyItem")
	build()
	-- W4: load the item textures early so the shop's pictures have their colours the first time
	task.spawn(function()
		local folder = ReplicatedStorage:FindFirstChild("ItemModels")
		if folder then
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ folder })
			end)
		end
	end)
	PlayerData.changed:Connect(ShopController.redraw)
	Lang.changed:Connect(ShopController.redraw)
end

return ShopController
