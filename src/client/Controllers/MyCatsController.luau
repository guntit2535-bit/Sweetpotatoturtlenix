--!strict
-- My Cats window (task 1.8; R9 grid from mockup 04): every cat in the pen as a card with its picture, tier,
-- weight and money per second, best first; tap a card to choose it, then Lock (favourite: cannot be sold or
-- traded) or Sell (tap twice: "Sure?") at the bottom. The client only
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
local CatPortrait = require(script.Parent.Parent.UI.CatPortrait)
local Hud = require(script.Parent.Parent.UI.Hud)
local BookController = require(script.Parent.BookController)

local MyCatsController = {}

local C = Kit.Colors
local window: Kit.Window
local list: ScrollingFrame
local countLabel: TextLabel
local emptyLabel: TextLabel
local sellRemote: RemoteEvent
local lockRemote: RemoteEvent
local armed: { [string]: number } = {} -- cat id -> os.clock() the Sell button was armed
local selected: string? = nil
local sellButton: TextButton
local lockButton: TextButton
local hint: TextLabel

local function tierColor(tier: number): Color3
	return Color3.fromHex(Config.Tiers[tier].Color)
end

local function lookFor(id: string): any
	local data = PlayerData.get()
	local cat = data and (data.Cats :: any)[id]
	local design = cat and Cats.ById[cat.Kind]
	if not design then
		return nil
	end
	local look = table.clone(design.Look) :: any
	look.mutation = if cat.Mutation and cat.Mutation ~= "" then cat.Mutation else nil
	return look
end

local function fillPortraits()
	CatPortrait.fillVisible(list, function(card)
		return lookFor(card.Name)
	end)
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
	local chosen: any = nil
	for i, r in rows do
		-- R9 card (mockup 04): picture, tier ribbon, weight, income, lock badge; tap to choose
		local card = Instance.new("Frame")
		card.Name = r.id
		card.LayoutOrder = i
		card.BackgroundColor3 = C.soft
		card.Parent = list
		Kit.corner(card, 18)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = if r.id == selected then 5 else 3
		stroke.Color = if r.id == selected then C.yellow else C.ink
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = card
		local box = Instance.new("Frame")
		box.Name = "Picture"
		box.Size = UDim2.new(1, -14, 0, 92)
		box.Position = UDim2.fromOffset(7, 7)
		box.BackgroundColor3 = C.sky
		box.Parent = card
		Kit.corner(box, 14)
		Kit.stroke(box, 2, nil, true)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromHex("d6f2ff"), Color3.fromHex("62c0f5"))
		g.Rotation = 90
		g.Parent = box
		local t = Config.Tiers[r.design.Tier]
		local ribbon = Instance.new("Frame")
		ribbon.Name = "Ribbon"
		ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
		ribbon.Position = UDim2.new(0.5, 0, 0, 100)
		ribbon.Size = UDim2.new(1, -24, 0, 24)
		ribbon.BackgroundColor3 = Color3.fromHex(t.Color)
		ribbon.Parent = card
		Kit.corner(ribbon, 8)
		Kit.stroke(ribbon, 2, nil, true)
		local tierText = Kit.text(ribbon, "Tier", UDim2.fromScale(1, 1), UDim2.new(), 16, true)
		tierText.Text = string.upper(Lang.text("Tier" .. t.Key))
		local kg = Kit.text(card, "Kg", UDim2.new(1, -8, 0, 24), UDim2.fromOffset(4, 114), 20, true)
		kg.Text = Lang.text("CatKg", { kg = Format.money(r.cat.Kg) })
		local inc = Instance.new("Frame")
		inc.Size = UDim2.new(1, -20, 0, 26)
		inc.Position = UDim2.fromOffset(10, 142)
		inc.BackgroundColor3 = C.panel
		inc.Parent = card
		Kit.corner(inc, 13)
		Kit.stroke(inc, 2, C.peach, true)
		local incText = Kit.text(inc, "Income", UDim2.fromScale(1, 1), UDim2.new(), 18, true)
		incText.TextColor3 = C.green
		incText.Text = "+" .. Format.money(r.income) .. "/s"
		if r.cat.Mutation and r.cat.Mutation ~= "" then
			local tag = Instance.new("Frame")
			tag.Size = UDim2.fromOffset(70, 22)
			tag.Position = UDim2.fromOffset(2, 2)
			tag.Rotation = -12
			tag.BackgroundColor3 = Color3.fromHex("f5bf2e")
			tag.Parent = card
			Kit.corner(tag, 6)
			Kit.stroke(tag, 2, nil, true)
			local mt = Kit.text(tag, "Mut", UDim2.fromScale(1, 1), UDim2.new(), 14, true)
			mt.Text = string.upper(Lang.text("Mut" .. r.cat.Mutation))
		end
		if r.cat.Locked then
			local lockBadge = Instance.new("Frame")
			lockBadge.Size = UDim2.fromOffset(26, 26)
			lockBadge.Position = UDim2.new(1, -30, 0, 4)
			lockBadge.BackgroundColor3 = C.yellow
			lockBadge.Parent = card
			Kit.corner(lockBadge, 13)
			Kit.stroke(lockBadge, 2, nil, true)
			local lk = Kit.text(lockBadge, "Lock", UDim2.fromScale(1, 1), UDim2.new(), 14, true)
			lk.Text = "L"
		end
		local tap = Instance.new("TextButton")
		tap.Name = "Tap"
		tap.BackgroundTransparency = 1
		tap.Text = ""
		tap.Size = UDim2.fromScale(1, 1)
		tap.ZIndex = 5
		tap.Parent = card
		tap.Activated:Connect(function()
			selected = if selected == r.id then nil else r.id
			redraw()
		end)
		if r.id == selected then
			chosen = r
		end
	end
	if selected and not chosen then
		selected = nil
	end
	-- the bottom bar: the chosen cat, Lock and Sell (tap twice)
	if chosen then
		local r = chosen
		hint.Text = `{r.design.Name} · {Lang.text("CatKg", { kg = Format.money(r.cat.Kg) })}`
		if r.cat.Mutation and r.cat.Mutation ~= "" then
			hint.Text = Lang.text("MutTag", { mutation = Lang.text("Mut" .. r.cat.Mutation), mult = Mutation.money(r.cat.Mutation) }) .. " · " .. hint.Text
		end
		local isArmed = armed[r.id] and os.clock() - armed[r.id] < 3
		Kit.setButtonText(sellButton, Lang.text(if isArmed then "SellSure" else "Sell"))
		Kit.setButtonColor(sellButton, if isArmed then C.coral else C.green)
		Kit.setButtonText(lockButton, Lang.text(if r.cat.Locked then "Locked" else "Lock"))
		Kit.setButtonColor(lockButton, if r.cat.Locked then C.purple else C.tab)
	else
		hint.Text = Lang.text("MyCatsTap")
		Kit.setButtonText(sellButton, Lang.text("Sell"))
		Kit.setButtonColor(sellButton, C.grey)
		Kit.setButtonText(lockButton, Lang.text("Lock"))
		Kit.setButtonColor(lockButton, C.grey)
	end
	task.defer(fillPortraits)
end

local function build()
	window = Kit.window({ name = "MyCatsWindow", width = 700, height = 560, color = C.yellow })
	countLabel = Kit.text(window.body, "Count", UDim2.fromOffset(160, 34), UDim2.fromOffset(0, 6), 24, true)
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	local book = Kit.button(window.body, "Book", C.purple, UDim2.fromOffset(150, 40), UDim2.new(1, -154, 0, 4))
	Kit.icon(book, "Book", 34, UDim2.fromOffset(4, 2))
	local bookLabel = book:FindFirstChild("Label") :: TextLabel
	bookLabel.Position = UDim2.fromOffset(40, 0)
	bookLabel.Size = UDim2.new(1, -46, 1, 0)
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
	list.Position = UDim2.fromOffset(0, 52)
	list.Size = UDim2.new(1, 0, 1, -122)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(150, 178)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.Parent = list
	list:GetPropertyChangedSignal("CanvasPosition"):Connect(fillPortraits)
	emptyLabel = Kit.text(window.body, "Empty", UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 140), 22)
	emptyLabel.TextColor3 = C.muted
	-- bottom bar
	sellButton = Kit.button(window.body, "Sell", C.grey, UDim2.fromOffset(150, 52), UDim2.new(0, 4, 1, -60))
	lockButton = Kit.button(window.body, "Lock", C.grey, UDim2.fromOffset(130, 52), UDim2.new(0, 166, 1, -60))
	hint = Kit.text(window.body, "Hint", UDim2.new(1, -312, 0, 52), UDim2.new(0, 308, 1, -62), 20)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextWrapped = true
	sellButton.Activated:Connect(function()
		local id = selected
		if not id then
			return
		end
		if armed[id] and os.clock() - armed[id] < 3 then
			armed[id] = nil
			sellRemote:FireServer(id)
		else
			armed[id] = os.clock()
			redraw()
			task.delay(3.1, redraw)
		end
	end)
	lockButton.Activated:Connect(function()
		local id = selected
		local data = PlayerData.get()
		local cat = id and data and (data.Cats :: any)[id]
		if cat then
			lockRemote:FireServer(id, not cat.Locked)
		end
	end)
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
