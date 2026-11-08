--!strict
-- The Shop window (tasks 2.1 - 2.5): tabs Rods / Shoes / Pen / Treats / Crates (crates: CrateController adds
-- its tab content through ShopController.setCratesBuilder). Prices come from shared/Shop (the same numbers
-- the server charges); the client only asks (BuyItem) and redraws from the save copy.

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

local ShopController = {}

local C = Kit.Colors
local TABS = { "Rods", "Shoes", "Pen", "Treats", "Crates", "Robux" }
local window: Kit.Window
local list: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local current = "Rods"
local buyRemote: RemoteEvent
local cratesBuilder: ((list: ScrollingFrame) -> ())? = nil
local robuxBuilder: ((list: ScrollingFrame) -> ())? = nil

local function card(order: number, title: string, line: string, color: Color3): Frame
	local row = Instance.new("Frame")
	row.Name = `Item{order}`
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -12, 0, 72)
	row.BackgroundColor3 = C.soft
	row.Parent = list
	Kit.corner(row, 14)
	Kit.stroke(row, 3, nil, true)
	local chip = Instance.new("Frame")
	chip.Size = UDim2.fromOffset(46, 46)
	chip.Position = UDim2.fromOffset(12, 13)
	chip.BackgroundColor3 = color
	chip.Parent = row
	Kit.corner(chip, 12)
	Kit.stroke(chip, 3, nil, true)
	local name = Kit.text(row, "Name", UDim2.new(1, -240, 0, 28), UDim2.fromOffset(70, 8), 22)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = title
	local info = Kit.text(row, "Info", UDim2.new(1, -240, 0, 22), UDim2.fromOffset(70, 40), 16)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextColor3 = C.muted
	info.TextTruncate = Enum.TextTruncate.AtEnd
	info.Text = line
	return row
end

-- A Buy button, or a grey label when owned / locked.
local function action(row: Frame, state: string, cost: number?, onBuy: () -> ())
	local text, color = "", C.grey
	if state == "buy" then
		text, color = Lang.text("Buy", { cost = Format.short(cost or 0) }), C.green
	elseif state == "inuse" then
		text, color = Lang.text("InUse"), C.purple
	elseif state == "owned" then
		text, color = Lang.text("Owned"), C.grey
	else
		text, color = Lang.text("BuyPrevious"), C.grey
	end
	local b = Kit.button(row, "Action", color, UDim2.fromOffset(150, 48), UDim2.new(1, -162, 0.5, -26))
	Kit.setButtonText(b, text)
	if state == "buy" then
		b.Activated:Connect(onBuy)
	end
end

local function drawRods(data: { [string]: any })
	local have = data.RodLevel or 1
	for level = 1, Config.Rods.Levels do
		local m, n = Shop.rodMaterial(level)
		local p = FishingBar.params(1, level)
		local base = FishingBar.params(1, 1)
		local zone = math.floor((p.zone / base.zone - 1) * 100 + 0.5)
		local fill = math.floor((p.fill / base.fill - 1) * 100 + 0.5)
		local luck = math.floor((level - 1) * Config.Rods.LuckPerLevel * 100 + 0.5)
		local row = card(level, Lang.text("RodName", { material = Lang.text("Mat" .. Config.Rods.Materials[m]), n = n }),
			Lang.text("RodEffect", { zone = zone, fill = fill, luck = luck }), Color3.fromHex(Config.Rods.Colors[m]))
		local state = if level == have then "inuse" elseif level < have then "owned" elseif level == have + 1 then "buy" else "locked"
		action(row, state, Shop.rodCost(level), function()
			buyRemote:FireServer("Rod", level)
		end)
	end
end

local function drawShoes(data: { [string]: any })
	local have = data.Shoes or 0
	for pair, s in Config.Shoes.List do
		local row = card(pair, Lang.text("Shoe" .. s.Key), Lang.text("ShoeEffect", { speed = s.Speed }), C.sky)
		local state = if pair == have then "inuse" elseif pair < have then "owned" elseif pair == have + 1 then "buy" else "locked"
		action(row, state, s.Cost, function()
			buyRemote:FireServer("Shoes", pair)
		end)
	end
end

local function drawPen(data: { [string]: any })
	local slots = data.PenSlots or Config.Pen.StartSlots
	local row = card(1, Lang.text("PenItem", { n = Config.PenUpgrade.Step }),
		if slots >= Config.Pen.MaxSlots then Lang.text("PenMax") else Lang.text("PenEffect", { now = slots, next = math.min(Config.Pen.MaxSlots, slots + Config.PenUpgrade.Step) }), C.yellow)
	action(row, if slots >= Config.Pen.MaxSlots then "owned" else "buy", Shop.penCost(data.PenBuys or 0), function()
		buyRemote:FireServer("Pen", 0)
	end)
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
		local ends = boosts[t.Key] or 0
		local left = ends - now
		local line = Lang.text("Treat" .. t.Name .. "Desc")
		if left > 0 then
			line ..= "  ·  " .. Lang.text("TreatLeft", { time = Format.clock(left) })
		end
		local row = card(i, Lang.text("Treat" .. t.Name), line, if t.Key == "Money" then C.yellow elseif t.Key == "Luck" then C.green else C.purple)
		action(row, "buy", Shop.treatCost(t.Key, income), function()
			buyRemote:FireServer("Treat", t.Key)
		end)
	end
end

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("ShopTitle")
	for tab, b in tabButtons do
		Kit.setButtonText(b, Lang.text("Tab" .. tab))
		Kit.setButtonColor(b, if tab == current then C.yellow else C.grey)
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local data = PlayerData.get() or {}
	if current == "Rods" then
		drawRods(data)
	elseif current == "Shoes" then
		drawShoes(data)
	elseif current == "Pen" then
		drawPen(data)
	elseif current == "Treats" then
		drawTreats(data)
	elseif current == "Crates" and cratesBuilder then
		cratesBuilder(list)
	elseif current == "Robux" and robuxBuilder then
		robuxBuilder(list)
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
		redraw()
		window.setOpen(true)
	end
end

local function build()
	window = Kit.window({ name = "ShopWindow", width = 690, height = 540, color = C.coral })
	local tabs = Instance.new("Frame")
	tabs.Name = "Tabs"
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 50)
	tabs.Parent = window.body
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabs
	for i, tab in TABS do
		if tab == "Shoes" and not Config.Shoes.Enabled then
			continue
		end
		local b = Kit.button(tabs, tab, C.grey, UDim2.fromOffset(100, 42), UDim2.new())
		;(b.Parent :: Frame).LayoutOrder = i
		b.Activated:Connect(function()
			current = tab
			redraw()
		end)
		tabButtons[tab] = b
	end
	list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 58)
	list.Size = UDim2.new(1, 0, 1, -58)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local l2 = Instance.new("UIListLayout")
	l2.Padding = UDim.new(0, 8)
	l2.SortOrder = Enum.SortOrder.LayoutOrder
	l2.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = list
end

function ShopController.Start(_self: any)
	buyRemote = Remotes.event("BuyItem")
	build()
	PlayerData.changed:Connect(ShopController.redraw)
	Lang.changed:Connect(ShopController.redraw)
end

return ShopController
