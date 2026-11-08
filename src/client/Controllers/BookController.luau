--!strict
-- The collection book (task 2.8): all 400 designs by tier; found cats show their fur colour and name,
-- unseen ones a black "???" silhouette card. The header shows the count and the permanent bonus. Opened from
-- the My Cats window (Book button). R9 (mockup 05): real cat pictures, unseen cats as dark silhouettes,
-- a progress bar with a cat head riding the fill, the bonus on a gold ribbon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Book = require(Shared:WaitForChild("Book"))
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local CatPortrait = require(script.Parent.Parent.UI.CatPortrait)

local BookController = {}

local C = Kit.Colors
local window: Kit.Window
local list: ScrollingFrame
local header: TextLabel
local bonusLine: TextLabel
local tabButtons: { TextButton } = {}
local tier = 1
local seenNow: { [string]: boolean } = {}
local barFill: Frame
local barHead: Frame

local function fillPortraits()
	CatPortrait.fillVisible(list, function(card)
		local cat = Cats.ById[card.Name]
		return if cat then cat.Look else nil
	end, function(card)
		return not seenNow[card.Name]
	end)
end

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("BookTitle")
	local data = PlayerData.get()
	local book = if data and data.Book then data.Book else {}
	local perTier, total = Book.progress(book)
	header.Text = Lang.text("BookProgress", { seen = total, total = #Cats.List })
	local frac = total / math.max(1, #Cats.List)
	barFill.Size = UDim2.fromScale(frac, 1)
	barHead.Position = UDim2.new(frac, 0, 0.5, 0)
	seenNow = book
	bonusLine.Text = Lang.text("BookBonus", { pct = Config.Book.TierBonus * 100, all = Config.Book.AllBonus * 100 })
	for i, b in tabButtons do
		local t = Config.Tiers[i]
		Kit.setButtonText(b, `{Lang.text("Tier" .. t.Key)} {perTier[i]}/{#Cats.ByTier[i]}`)
		Kit.setButtonColor(b, if i == tier then C.yellow else C.tab)
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, id in Cats.ByTier[tier] do
		local cat = Cats.ById[id]
		local seen = book[id] == true
		local cell = Instance.new("Frame")
		cell.Name = id
		cell.LayoutOrder = i
		cell.BackgroundColor3 = C.soft
		cell.Parent = list
		Kit.corner(cell, 14)
		Kit.stroke(cell, 3, nil, true)
		local box = Instance.new("Frame")
		box.Name = "Picture"
		box.Size = UDim2.new(1, -10, 0, 78)
		box.Position = UDim2.fromOffset(5, 5)
		box.BackgroundColor3 = C.sky
		box.Parent = cell
		Kit.corner(box, 12)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromHex("d6f2ff"), Color3.fromHex("62c0f5"))
		g.Rotation = 90
		g.Parent = box
		local name = Kit.text(cell, "Name", UDim2.new(1, -6, 0, 30), UDim2.new(0, 3, 0, 84), 15, true)
		name.TextWrapped = true
		name.TextScaled = true
		name.Text = if seen then cat.Name else Lang.text("BookUnknown")
	end
	task.defer(fillPortraits)
end

local function build()
	window = Kit.window({ name = "BookWindow", width = 720, height = 580, color = C.purple })
	header = Kit.text(window.body, "Header", UDim2.fromOffset(170, 30), UDim2.fromOffset(0, 4), 22, true)
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	-- progress bar with a cat head riding the fill
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(180, 10)
	bar.Size = UDim2.new(1, -200, 0, 20)
	bar.BackgroundColor3 = Color3.fromHex("e2e2ea")
	bar.Parent = window.body
	Kit.corner(bar, 10)
	Kit.stroke(bar, 3, nil, true)
	barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = C.green
	barFill.Parent = bar
	Kit.corner(barFill, 10)
	barHead = Instance.new("Frame")
	barHead.AnchorPoint = Vector2.new(0.5, 0.5)
	barHead.Size = UDim2.fromOffset(30, 26)
	barHead.BackgroundColor3 = C.yellow
	barHead.Parent = bar
	Kit.corner(barHead, 7)
	Kit.stroke(barHead, 2, nil, true)
	Kit.ears(barHead, 12, { 0.25, 0.75 }, C.yellow, C.pink)
	-- the bonus on a gold ribbon at the bottom
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 1)
	ribbon.Position = UDim2.new(0.5, 0, 1, 0)
	ribbon.Size = UDim2.new(0.86, 0, 0, 40)
	ribbon.BackgroundColor3 = C.yellow
	ribbon.Parent = window.body
	Kit.corner(ribbon, 12)
	Kit.stroke(ribbon, 3, nil, true)
	bonusLine = Kit.text(ribbon, "Bonus", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 18, true)
	bonusLine.TextScaled = true
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromOffset(0, 40)
	tabs.Size = UDim2.new(1, 0, 0, 44)
	tabs.Parent = window.body
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 6)
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Parent = tabs
	for i = 1, #Config.Tiers do
		local b = Kit.button(tabs, `T{i}`, C.grey, UDim2.fromOffset(106, 38), UDim2.new())
		;(b.Parent :: Frame).LayoutOrder = i
		b.Activated:Connect(function()
			tier = i
			redraw()
		end)
		tabButtons[i] = b
	end
	list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 92)
	list.Size = UDim2.new(1, 0, 1, -140)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(122, 118)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = list
	list:GetPropertyChangedSignal("CanvasPosition"):Connect(fillPortraits)
end

function BookController.toggle()
	if window.isOpen() then
		window.setOpen(false)
	else
		redraw()
		window.setOpen(true)
	end
end

function BookController.Start(_self: any)
	build()
	PlayerData.changed:Connect(function()
		if window.isOpen() then
			redraw()
		end
	end)
	Lang.changed:Connect(redraw)
end

return BookController
