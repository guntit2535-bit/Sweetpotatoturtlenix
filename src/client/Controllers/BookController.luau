--!strict
-- The collection book (task 2.8): all 400 designs by tier; found cats show their fur colour and name,
-- unseen ones a black "???" silhouette card. The header shows the count and the permanent bonus. Opened from
-- the My Cats window (Book button).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Book = require(Shared:WaitForChild("Book"))
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)

local BookController = {}

local C = Kit.Colors
local window: Kit.Window
local list: ScrollingFrame
local header: TextLabel
local bonusLine: TextLabel
local tabButtons: { TextButton } = {}
local tier = 1

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("BookTitle")
	local data = PlayerData.get()
	local book = if data and data.Book then data.Book else {}
	local perTier, total = Book.progress(book)
	header.Text = Lang.text("BookProgress", { seen = total, total = #Cats.List })
	bonusLine.Text = Lang.text("BookBonus", { pct = Config.Book.TierBonus * 100, all = Config.Book.AllBonus * 100 })
	for i, b in tabButtons do
		local t = Config.Tiers[i]
		Kit.setButtonText(b, `{Lang.text("Tier" .. t.Key)} {perTier[i]}/{#Cats.ByTier[i]}`)
		Kit.setButtonColor(b, if i == tier then Color3.fromHex(t.Color) else C.grey)
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
		cell.BackgroundColor3 = if seen then C.soft else Color3.fromHex("2a2433")
		cell.Parent = list
		Kit.corner(cell, 10)
		Kit.stroke(cell, 2, nil, true)
		local face = Instance.new("Frame")
		face.AnchorPoint = Vector2.new(0.5, 0)
		face.Position = UDim2.new(0.5, 0, 0, 8)
		face.Size = UDim2.fromOffset(44, 36)
		face.BackgroundColor3 = if seen then Color3.fromHex(cat.Look.fur) else Color3.fromHex("0f0c16")
		face.Parent = cell
		Kit.corner(face, 8)
		for _, x in { 0.25, 0.75 } do
			local ear = Instance.new("Frame")
			ear.AnchorPoint = Vector2.new(0.5, 0.5)
			ear.Position = UDim2.fromScale(x, 0.02)
			ear.Size = UDim2.fromOffset(12, 12)
			ear.Rotation = 45
			ear.BackgroundColor3 = face.BackgroundColor3
			ear.ZIndex = 0
			ear.Parent = face
		end
		local name = Kit.text(cell, "Name", UDim2.new(1, -6, 0, 36), UDim2.new(0, 3, 0, 48), 13)
		name.TextWrapped = true
		name.Text = if seen then cat.Name else Lang.text("BookUnknown")
		name.TextColor3 = if seen then C.ink else C.grey
	end
end

local function build()
	window = Kit.window({ name = "BookWindow", width = 720, height = 560, color = C.purple })
	header = Kit.text(window.body, "Header", UDim2.new(0.5, 0, 0, 26), UDim2.new(), 22)
	header.TextXAlignment = Enum.TextXAlignment.Left
	bonusLine = Kit.text(window.body, "Bonus", UDim2.new(0.5, 0, 0, 26), UDim2.new(0.5, 0, 0, 0), 15)
	bonusLine.TextXAlignment = Enum.TextXAlignment.Right
	bonusLine.TextColor3 = C.muted
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromOffset(0, 32)
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
	list.Position = UDim2.fromOffset(0, 84)
	list.Size = UDim2.new(1, 0, 1, -84)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(100, 90)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = list
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
