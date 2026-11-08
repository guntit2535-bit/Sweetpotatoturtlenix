--!strict
-- My Cats window (task 1.8): every cat in the pen with its tier, name, weight and money per second,
-- best first; Lock (favourite: cannot be sold or traded) and Sell (tap twice: "Sure?"). The client only
-- asks (SellCat / LockCat); the list redraws from the save copy the server sends back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cats = require(Shared:WaitForChild("Cats"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Mutation = require(Shared:WaitForChild("Mutation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local Hud = require(script.Parent.Parent.UI.Hud)
local BookController = require(script.Parent.BookController)

local MyCatsController = {}

local C = Kit.Colors
local ROW_H = 70
local window: Kit.Window
local list: ScrollingFrame
local countLabel: TextLabel
local emptyLabel: TextLabel
local sellRemote: RemoteEvent
local lockRemote: RemoteEvent
local armed: { [string]: number } = {} -- cat id -> os.clock() the Sell button was armed

local function tierColor(tier: number): Color3
	return Color3.fromHex(Config.Tiers[tier].Color)
end

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("MyCatsTitle")
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local data = PlayerData.get()
	local cats = if data then data.Cats else {}
	local rows = {}
	for id, cat in cats :: { [string]: any } do
		local design = Cats.ById[cat.Kind]
		if design then
			table.insert(rows, { id = id, cat = cat, design = design, income = CatRules.income(design.Tier, cat.Kg) * Mutation.money(cat.Mutation) })
		end
	end
	table.sort(rows, function(a, b)
		return a.income > b.income
	end)
	countLabel.Text = Lang.text("MyCatsCount", { count = #rows, max = if data then data.PenSlots else Config.Pen.StartSlots })
	emptyLabel.Visible = #rows == 0
	emptyLabel.Text = Lang.text("MyCatsEmpty")
	for i, r in rows do
		local row = Instance.new("Frame")
		row.Name = r.id
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, ROW_H)
		row.BackgroundColor3 = C.soft
		row.Parent = list
		Kit.corner(row, 14)
		Kit.stroke(row, 3, nil, true)
		local chip = Instance.new("Frame")
		chip.Size = UDim2.fromOffset(12, ROW_H - 20)
		chip.Position = UDim2.fromOffset(10, 10)
		chip.BackgroundColor3 = tierColor(r.design.Tier)
		chip.Parent = row
		Kit.corner(chip, 6)
		local name = Kit.text(row, "Name", UDim2.new(1, -250, 0, 30), UDim2.fromOffset(32, 6), 22)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Text = r.design.Name
		local info = Kit.text(row, "Info", UDim2.new(1, -250, 0, 24), UDim2.fromOffset(32, 38), 17)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextColor3 = C.muted
		info.Text = `{Lang.text("Tier" .. r.design.TierKey)} · {Lang.text("CatKg", { kg = Format.rate(r.cat.Kg) })} · {Lang.text("CatIncome", { money = Format.money(r.income) })}`
		if r.cat.Mutation and r.cat.Mutation ~= "" then
			info.Text = Lang.text("MutTag", { mutation = Lang.text("Mut" .. r.cat.Mutation), mult = Mutation.money(r.cat.Mutation) }) .. " · " .. info.Text
			info.TextColor3 = Color3.fromHex("c98a00")
		end
		local lock = Kit.button(row, "Lock", if r.cat.Locked then C.purple else C.grey, UDim2.fromOffset(96, 44), UDim2.new(1, -210, 0.5, -24))
		Kit.setButtonText(lock, Lang.text(if r.cat.Locked then "Locked" else "Lock"))
		lock.Activated:Connect(function()
			lockRemote:FireServer(r.id, not r.cat.Locked)
		end)
		local isArmed = armed[r.id] and os.clock() - armed[r.id] < 3
		local sell = Kit.button(row, "Sell", if isArmed then C.coral else C.green, UDim2.fromOffset(96, 44), UDim2.new(1, -106, 0.5, -24))
		Kit.setButtonText(sell, Lang.text(if isArmed then "SellSure" else "Sell"))
		sell.Activated:Connect(function()
			if armed[r.id] and os.clock() - armed[r.id] < 3 then
				armed[r.id] = nil
				sellRemote:FireServer(r.id)
			else
				armed[r.id] = os.clock()
				redraw()
				task.delay(3.1, redraw)
			end
		end)
	end
end

local function build()
	window = Kit.window({ name = "MyCatsWindow", width = 620, height = 520, color = C.yellow })
	countLabel = Kit.text(window.body, "Count", UDim2.new(1, 0, 0, 28), UDim2.new(), 22)
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	local book = Kit.button(window.body, "Book", C.purple, UDim2.fromOffset(120, 32), UDim2.new(1, -124, 0, -2))
	Kit.setButtonText(book, Lang.text("BookButton"))
	book.Activated:Connect(function()
		window.setOpen(false)
		BookController.toggle()
	end)
	Lang.changed:Connect(function()
		Kit.setButtonText(book, Lang.text("BookButton"))
	end)
	list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 36)
	list.Size = UDim2.new(1, 0, 1, -36)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = list
	emptyLabel = Kit.text(window.body, "Empty", UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 120), 22)
	emptyLabel.TextColor3 = C.muted
end

function MyCatsController.toggle()
	if window.isOpen() then
		window.setOpen(false)
	else
		redraw()
		window.setOpen(true)
	end
end

function MyCatsController.Start(_self: any)
	sellRemote = Remotes.event("SellCat")
	lockRemote = Remotes.event("LockCat")
	build()
	Hud.leftButton("MyCats", "MyCatsButton", C.yellow, 3, MyCatsController.toggle)
	PlayerData.changed:Connect(function()
		if window.isOpen() then
			redraw()
		end
	end)
	Lang.changed:Connect(redraw)
end

return MyCatsController
