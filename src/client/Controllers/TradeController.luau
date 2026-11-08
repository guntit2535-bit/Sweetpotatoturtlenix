--!strict
-- Trading on this client (task 2.17): the HUD's Trade button opens a list of the players in this server
-- (Ask); an invite pops up with Accept / No; during a trade the window shows both offers (6 slots each),
-- your cats to tap in or out, Ready, the 5 s countdown and Cancel. The server decides everything
-- (TradeService); this only draws its TradeState and asks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local CatPortrait = require(script.Parent.Parent.UI.CatPortrait)

local TradeController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local R: { [string]: RemoteEvent } = {}
local window: Kit.Window
local body: Frame
local state: any = nil
local invite: Frame
local inviteFrom = 0

local function clear()
	for _, c in body:GetChildren() do
		c:Destroy()
	end
end

-- R9 (mockup 08): a cat card with its picture (CatPortrait, filled for cards on screen) and a tier ribbon.
local function catChip(parent: Instance, kind: string, kg: number, mutation: string?, order: number, onClick: (() -> ())?): TextButton
	local design = Cats.ById[kind]
	local t = design and Config.Tiers[design.Tier]
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.AutoButtonColor = onClick ~= nil
	b.Text = ""
	b.BackgroundColor3 = C.soft
	b:SetAttribute("Kind", kind)
	b:SetAttribute("Mutation", mutation or "")
	b.Parent = parent
	Kit.corner(b, 12)
	Kit.stroke(b, 3, nil, true)
	local box = Instance.new("Frame")
	box.Name = "Picture"
	box.Size = UDim2.new(1, -8, 1, -30)
	box.Position = UDim2.fromOffset(4, 4)
	box.BackgroundColor3 = C.sky
	box.Parent = b
	Kit.corner(box, 10)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromHex("d6f2ff"), Color3.fromHex("62c0f5"))
	g.Rotation = 90
	g.Parent = box
	local ribbon = Instance.new("Frame")
	ribbon.Size = UDim2.new(1, -8, 0, 22)
	ribbon.Position = UDim2.new(0, 4, 1, -25)
	ribbon.BackgroundColor3 = if t then Color3.fromHex(t.Color) else C.grey
	ribbon.Parent = b
	Kit.corner(ribbon, 7)
	Kit.stroke(ribbon, 2, nil, true)
	local info = Kit.text(ribbon, "Info", UDim2.new(1, -4, 1, 0), UDim2.fromOffset(2, 0), 13, true)
	info.TextScaled = true
	info.Text = `{Format.money(kg)} kg` .. (if mutation and mutation ~= "" then " · " .. Lang.text("Mut" .. mutation) else "")
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local function lookOfCard(card: Instance): any
	local kind = card:GetAttribute("Kind")
	local design = if type(kind) == "string" then Cats.ById[kind] else nil
	if not design then
		return nil
	end
	local look = table.clone(design.Look) :: any
	local m = card:GetAttribute("Mutation")
	look.mutation = if type(m) == "string" and m ~= "" then m else nil
	return look
end

local function grid(parent: Instance, pos: UDim2, size: UDim2, cell: Vector2): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = C.soft
	f.Position = pos
	f.Size = size
	f.Parent = parent
	Kit.corner(f, 12)
	Kit.stroke(f, 2, nil, true)
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(cell.X, cell.Y)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = f
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.Parent = f
	return f
end

local function drawList()
	window.title.Text = Lang.text("TradeTitle")
	local others = {}
	for _, p in Players:GetPlayers() do
		if p ~= me then
			table.insert(others, p)
		end
	end
	if #others == 0 then
		local t = Kit.text(body, "None", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 120), 22)
		t.Text = Lang.text("TradeNoPlayers")
		t.TextColor3 = C.muted
		return
	end
	for i, p in others do
		local row = Instance.new("Frame")
		row.Position = UDim2.fromOffset(0, (i - 1) * 64)
		row.Size = UDim2.new(1, -8, 0, 56)
		row.BackgroundColor3 = C.soft
		row.Parent = body
		Kit.corner(row, 12)
		Kit.stroke(row, 2, nil, true)
		local n = Kit.text(row, "Name", UDim2.new(1, -170, 1, 0), UDim2.fromOffset(14, 0), 22)
		n.TextXAlignment = Enum.TextXAlignment.Left
		n.Text = p.DisplayName
		local b = Kit.button(row, "Ask", C.purple, UDim2.fromOffset(140, 42), UDim2.new(1, -150, 0.5, -24))
		Kit.setButtonText(b, Lang.text("TradeRequest"))
		b.Activated:Connect(function()
			R.TradeRequest:FireServer(p.UserId)
		end)
	end
end

local function drawTrade()
	local s = state
	window.title.Text = Lang.text("TradeWith", { name = s.partner })
	local data = PlayerData.get() or {}
	local myCats = data.Cats or {}
	local mine: { string } = s.mine or {}
	local mineSet: { [string]: boolean } = {}
	for _, id in mine do
		mineSet[id] = true
	end
	-- R9: a name pill over each side and a Ready pill under it
	local function sidePill(x: number, text: string, color: Color3, y: number, w: number): TextLabel
		local p = Instance.new("Frame")
		p.Size = UDim2.new(0.5, -6 - w, 0, 30)
		p.Position = UDim2.new(x, if x > 0 then 6 + w / 2 else w / 2, 0, y)
		p.BackgroundColor3 = color
		p.Parent = body
		Kit.corner(p, 15)
		Kit.stroke(p, 3, nil, true)
		local l = Kit.text(p, "Text", UDim2.new(1, -10, 1, 0), UDim2.fromOffset(5, 0), 20, true)
		l.TextScaled = true
		l.Text = text
		return l
	end
	sidePill(0, Lang.text("TradeYou"), C.green, 0, 40)
	sidePill(0.5, s.partner, C.purple, 0, 40)
	sidePill(0, Lang.text(if s.readyMine then "TradeReadyButton" else "TradeNotReadyState"), if s.readyMine then C.green else C.grey, 244, 90)
	sidePill(0.5, Lang.text(if s.readyTheirs then "TradeReadyButton" else "TradeNotReadyState"), if s.readyTheirs then C.green else C.grey, 244, 90)
	local left = grid(body, UDim2.fromOffset(0, 36), UDim2.new(0.5, -6, 0, 202), Vector2.new(92, 92))
	local right = grid(body, UDim2.new(0.5, 6, 0, 36), UDim2.new(0.5, -6, 0, 202), Vector2.new(92, 92))
	for i, id in mine do
		local c = myCats[id]
		if c then
			catChip(left, c.Kind, c.Kg, c.Mutation, i, function()
				local new = {}
				for _, x in mine do
					if x ~= id then
						table.insert(new, x)
					end
				end
				R.TradeSet:FireServer(new)
			end)
		end
	end
	for i, c in s.theirs or {} do
		catChip(right, c.Kind, c.Kg, c.Mutation, i, nil)
	end
	local hint = Kit.text(body, "Hint", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 280), 16)
	hint.Text = Lang.text("TradeMyCats")
	hint.TextColor3 = C.muted
	local pick = Instance.new("ScrollingFrame")
	pick.BackgroundColor3 = C.soft
	pick.Position = UDim2.fromOffset(0, 304)
	pick.Size = UDim2.new(1, 0, 0, 130)
	pick.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pick.CanvasSize = UDim2.new()
	pick.ScrollBarThickness = 6
	pick.Parent = body
	Kit.corner(pick, 12)
	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.fromOffset(92, 110)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.Parent = pick
	local order = 0
	for id, c in myCats do
		if not mineSet[id] and not c.Locked then
			order += 1
			catChip(pick, c.Kind, c.Kg, c.Mutation, order, function()
				if #mine < Config.Trade.MaxCats then
					local new = table.clone(mine)
					table.insert(new, id)
					R.TradeSet:FireServer(new)
				end
			end)
		end
	end
	task.defer(function()
		CatPortrait.fillVisible(left, lookOfCard)
		CatPortrait.fillVisible(right, lookOfCard)
		CatPortrait.fillVisible(pick, lookOfCard)
	end)
	pick:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		CatPortrait.fillVisible(pick, lookOfCard)
	end)
	local status = Kit.text(body, "Status", UDim2.new(1, -330, 0, 44), UDim2.new(0, 0, 1, -48), 22)
	status.TextXAlignment = Enum.TextXAlignment.Left
	if s.ends then
		local left2 = math.max(0, math.ceil(s.ends - workspace:GetServerTimeNow()))
		status.Text = Lang.text("TradeIn", { n = left2 })
		status.TextColor3 = Color3.fromHex("2f9a3a")
	else
		status.Text = Lang.text("TradeWaiting")
		status.TextColor3 = C.muted
	end
	local ready = Kit.button(body, "Ready", if s.readyMine then C.yellow else C.green, UDim2.fromOffset(150, 46), UDim2.new(1, -316, 1, -50))
	Kit.setButtonText(ready, Lang.text(if s.readyMine then "TradeNotReady" else "TradeReadyButton"))
	ready.Activated:Connect(function()
		R.TradeReady:FireServer(not s.readyMine)
	end)
	local cancel = Kit.button(body, "Cancel", C.coral, UDim2.fromOffset(150, 46), UDim2.new(1, -156, 1, -50))
	Kit.setButtonText(cancel, Lang.text("TradeCancelButton"))
	cancel.Activated:Connect(function()
		R.TradeCancel:FireServer()
	end)
end

local function redraw()
	if not window then
		return
	end
	clear()
	if state then
		drawTrade()
	else
		drawList()
	end
end

function TradeController.toggle()
	if window.isOpen() then
		window.setOpen(false)
		if state then
			R.TradeCancel:FireServer()
		end
	else
		redraw()
		window.setOpen(true)
	end
end

function TradeController.Start(_self: any)
	for _, n in { "TradeRequest", "TradeRespond", "TradeSet", "TradeReady", "TradeCancel" } do
		R[n] = Remotes.event(n)
	end
	window = Kit.window({ name = "TradeWindow", width = 660, height = 620, color = C.purple })
	body = window.body
	-- the invite popup
	local gui = Kit.screen("TradeInvite", 12)
	invite = Instance.new("Frame")
	invite.AnchorPoint = Vector2.new(0.5, 1)
	invite.Position = UDim2.new(0.5, 0, 1, -110)
	invite.Size = UDim2.fromOffset(420, 110)
	invite.BackgroundColor3 = C.panel
	invite.Visible = false
	invite.Parent = gui
	Kit.corner(invite, 22)
	Kit.stroke(invite, 4, nil, true)
	Kit.ears(invite, 36, { 0.15, 0.85 })
	local text = Kit.text(invite, "Text", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 6), 22)
	local yes = Kit.button(invite, "Yes", C.green, UDim2.fromOffset(150, 44), UDim2.new(0.5, -160, 1, -54))
	local no = Kit.button(invite, "No", C.coral, UDim2.fromOffset(150, 44), UDim2.new(0.5, 10, 1, -54))
	yes.Activated:Connect(function()
		invite.Visible = false
		R.TradeRespond:FireServer(inviteFrom, true)
	end)
	no.Activated:Connect(function()
		invite.Visible = false
		R.TradeRespond:FireServer(inviteFrom, false)
	end)
	Remotes.event("TradeInvite").OnClientEvent:Connect(function(fromId: unknown, name: unknown)
		if type(fromId) ~= "number" or type(name) ~= "string" then
			return
		end
		inviteFrom = fromId
		text.Text = Lang.text("TradeInvite", { name = name })
		Kit.setButtonText(yes, Lang.text("TradeAccept"))
		Kit.setButtonText(no, Lang.text("TradeDecline"))
		invite.Visible = true
		task.delay(Config.Trade.RequestSeconds, function()
			if inviteFrom == fromId then
				invite.Visible = false
			end
		end)
	end)
	Remotes.event("TradeState").OnClientEvent:Connect(function(s: unknown)
		state = if type(s) == "table" then s else nil
		if state and not window.isOpen() then
			window.setOpen(true)
		end
		redraw()
	end)
	PlayerData.changed:Connect(function()
		if window.isOpen() then
			redraw()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if state and state.ends and window.isOpen() then
				redraw()
			end
		end
	end)
end

return TradeController
