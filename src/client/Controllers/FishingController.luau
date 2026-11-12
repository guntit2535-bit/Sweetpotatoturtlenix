--!strict
-- Fishing on this client (tasks 1.11 / 1.12): using the Rod picks the wild cat you are looking at (within
-- Config.Fishing.CastRange) and asks Cast; the server answers FishStart and decides everything after that.
-- The bar runs here in the same fixed ticks as on the server (shared/FishingBar.tick); each hold change goes to
-- the server with its tick, so the server takes the same steps a moment later. A FishState snapshot (the
-- server's confirmed tick) only corrects the bar when it disagrees: then this client replays its own inputs
-- from there (W1: no more jumping back on a phone's slow connection). Hold = left mouse button / Space / the
-- big HOLD button (phones; each touch is followed until it ends). FishEnd closes it: a "Caught!" card when you
-- won, a toast otherwise.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local FishingBar = require(Shared:WaitForChild("FishingBar"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)
local CatPortrait = require(script.Parent.Parent.UI.CatPortrait)
local ToastController = require(script.Parent.ToastController)

local FishingController = {}

local C = Kit.Colors
local BAR_H = 360
local player = Players.LocalPlayer

local castRemote: RemoteEvent
local holdRemote: RemoteEvent
local giveUpRemote: RemoteEvent

local gui: ScreenGui
local zoneFrame: Frame
local catIcon: Frame
local meterFill: Frame
local hint: TextLabel
local holdButton: TextButton
local giveUp: TextButton
local card: Frame

type Active = {
	id: string,
	bar: FishingBar.State,
	history: { [number]: { snap: { number }, hold: boolean } }, -- the state before each tick + the input used
	acc: number, -- real seconds not yet stepped
	hold: boolean, -- the last input sent to the server
	done: boolean, -- the meter is full or empty here: wait for FishEnd
}

local active: Active? = nil
local holdingMouse = false
local holdingKey = false
local holdTouches: { [InputObject]: boolean } = {} -- touches that began on the HOLD button

local function holding(): boolean
	return holdingMouse or holdingKey or next(holdTouches) ~= nil
end

local function clearInput()
	holdingMouse = false
	holdingKey = false
	table.clear(holdTouches)
end

-- Steps the bar in fixed ticks up to now; a hold change is sent with the tick it starts on.
local function run(a: Active, dt: number)
	a.acc = math.min(a.acc + dt, 0.5)
	while a.acc >= FishingBar.Fixed do
		a.acc -= FishingBar.Fixed
		if a.done then
			continue
		end
		local h = holding()
		if h ~= a.hold then
			a.hold = h
			holdRemote:FireServer(h, a.bar.tick)
		end
		a.history[a.bar.tick] = { snap = FishingBar.snapshot(a.bar), hold = h }
		if FishingBar.tick(a.bar, h) then
			a.done = true
		end
	end
end

-- The server's confirmed state at its tick: nothing to do when this client was there too; otherwise take it and
-- replay this client's own inputs from that tick to now.
local function reconcile(a: Active, snap: { number })
	local at = snap[9]
	if type(at) ~= "number" then
		FishingBar.apply(a.bar, snap)
		return
	end
	local mine = a.history[at]
	if not (mine and FishingBar.same(mine.snap, snap)) then
		-- counted for tests (Studio / phone): should stay 0 or near it
		gui:SetAttribute("Corrections", (tonumber(gui:GetAttribute("Corrections")) or 0) + 1)
		local now = a.bar.tick
		FishingBar.apply(a.bar, snap)
		a.done = false
		for k = at, now - 1 do
			local entry = a.history[k]
			local h = if entry then entry.hold else a.hold
			a.history[k] = { snap = FishingBar.snapshot(a.bar), hold = h }
			if FishingBar.tick(a.bar, h) then
				a.done = true
				break
			end
		end
	end
	for k in a.history do
		if k < at then
			a.history[k] = nil
		end
	end
end

-- The wild cat the player means: in range, the one closest to where the camera looks.
local function pickTarget(): Model?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not root:IsA("BasePart") or not camera then
		return nil
	end
	local look = camera.CFrame.LookVector
	local best: Model? = nil
	local bestScore = -math.huge
	for _, m in CollectionService:GetTagged("WildCat") do
		if m:IsA("Model") and m.Parent then
			local pos = m:GetPivot().Position
			local offset = pos - root.Position
			local dist = offset.Magnitude
			if dist <= Config.Fishing.CastRange then
				local fromCam = (pos - camera.CFrame.Position).Unit
				local score = look:Dot(fromCam) * 2 - dist / Config.Fishing.CastRange
				if score > bestScore then
					best = m
					bestScore = score
				end
			end
		end
	end
	return best
end

local function onRodUsed()
	if active then
		return
	end
	local target = pickTarget()
	if not target then
		ToastController.show("FishNoCat", nil, "info")
		return
	end
	local id = target:GetAttribute("WildId")
	if type(id) == "string" then
		castRemote:FireServer(id)
	end
end

local function hookTool(tool: Instance)
	if tool:IsA("Tool") and tool.Name == "Rod" and not tool:GetAttribute("FishHooked") then
		tool:SetAttribute("FishHooked", true)
		tool.Activated:Connect(onRodUsed)
		tool.Unequipped:Connect(function()
			if active then
				giveUpRemote:FireServer()
			end
		end)
	end
end

local function build()
	gui = Kit.screen("FishingGui", 5)
	gui.Enabled = false
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -190, 0.45, 0)
	panel.Size = UDim2.fromOffset(150, BAR_H + 60)
	panel.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = math.clamp(h / 640, 0.55, 1)
	end
	fit()

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(0, 50)
	bar.Size = UDim2.fromOffset(78, BAR_H)
	bar.BackgroundColor3 = Color3.fromHex("cfd6e6") -- R9 (mockup 10): a light bar, the green zone inside
	bar.ClipsDescendants = true
	bar.Parent = panel
	Kit.corner(bar, 16)
	Kit.stroke(bar, 4, nil, true)
	zoneFrame = Instance.new("Frame")
	zoneFrame.Name = "Zone"
	zoneFrame.AnchorPoint = Vector2.new(0, 0.5)
	zoneFrame.Size = UDim2.new(1, -10, 0, 80)
	zoneFrame.Position = UDim2.new(0, 5, 0.5, 0)
	zoneFrame.BackgroundColor3 = C.green
	zoneFrame.BackgroundTransparency = 0.1
	zoneFrame.Parent = bar
	Kit.corner(zoneFrame, 12)
	Kit.stroke(zoneFrame, 2, Color3.fromHex("1f7a2c"), true)
	-- W3 (revision 3 item 16): the cat is a red line across the bar (was a cat face)
	catIcon = Instance.new("Frame")
	catIcon.Name = "Cat"
	catIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	catIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	catIcon.Size = UDim2.new(1, 8, 0, 7)
	catIcon.BackgroundColor3 = Color3.fromHex("ff2b2b")
	catIcon.BorderSizePixel = 0
	catIcon.ZIndex = 3
	catIcon.Parent = bar
	Kit.corner(catIcon, 3)
	Kit.stroke(catIcon, 2, nil, true)

	local meter = Instance.new("Frame")
	meter.Name = "Meter"
	meter.Position = UDim2.fromOffset(94, 50)
	meter.Size = UDim2.fromOffset(32, BAR_H)
	meter.BackgroundColor3 = Color3.fromHex("cfd6e6")
	meter.ClipsDescendants = true
	meter.Parent = panel
	Kit.corner(meter, 12)
	Kit.stroke(meter, 4, nil, true)
	meterFill = Instance.new("Frame")
	meterFill.Name = "Fill"
	meterFill.AnchorPoint = Vector2.new(0, 1)
	meterFill.Position = UDim2.fromScale(0, 1)
	meterFill.Size = UDim2.fromScale(1, 0.3)
	meterFill.BackgroundColor3 = C.yellow
	meterFill.Parent = meter
	Kit.corner(meterFill, 10)

	giveUp = Kit.button(panel, "GiveUp", C.coral, UDim2.fromOffset(126, 40), UDim2.fromOffset(0, 0))
	giveUp.Activated:Connect(function()
		giveUpRemote:FireServer()
	end)

	hint = Kit.text(gui, "Hint", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.15, 0, 0, 70), 28, true)
	hint.TextScaled = true

	holdButton = Kit.button(gui, "Hold", C.green, UDim2.fromOffset(150, 150), UDim2.new(1, -170, 1, -190))
	local holdHolder = holdButton.Parent :: Frame
	local hs = Instance.new("UIScale")
	hs.Parent = holdHolder
	hs.Scale = if UserInputService.TouchEnabled then 1 else 0.7
	-- round: change the kit's corners (a second UICorner would be ignored)
	for _, part in { holdButton :: Instance, holdHolder:FindFirstChild("Lip") } do
		if part then
			for _, c in part:GetChildren() do
				if c:IsA("UICorner") then
					c.CornerRadius = UDim.new(0.5, 0)
				end
			end
		end
	end
	-- R9: a pink paw over the label
	Kit.paw(holdButton, 56, UDim2.new(0.5, -28, 0, 20), C.pink)
	local holdLabel = holdButton:FindFirstChild("Label") :: TextLabel
	holdLabel.Position = UDim2.new(0, 6, 1, -62)
	holdLabel.Size = UDim2.new(1, -12, 0, 44)
	-- W1: a touch that starts on the button holds until that finger lifts, even when it slides off the button
	-- (the old MouseLeave let go as soon as the finger moved a little). The mouse is handled by holdingMouse.
	holdButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			holdTouches[input] = true
		end
	end)

	-- the "Caught!" card
	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.58)
	card.Size = UDim2.fromOffset(340, 340)
	card.BackgroundColor3 = C.panel
	card.Visible = false
	card.Parent = Kit.screen("CaughtCard", 15)
	Kit.corner(card, 26)
	Kit.stroke(card, 4, nil, true)
	-- R9 (mockup 11): pink cat-ear banner, the cat's picture, then the details
	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0, 4)
	banner.Size = UDim2.fromOffset(230, 58)
	banner.BackgroundColor3 = C.pink
	banner.Parent = card
	Kit.corner(banner, 29)
	Kit.stroke(banner, 4, nil, true)
	Kit.ears(banner, 30, { 0.2, 0.8 }, C.pink, Color3.fromHex("ffd0e4"))
	local title = Kit.text(banner, "Title", UDim2.new(1, -20, 1, -8), UDim2.fromOffset(10, 4), 34, true)
	title.TextScaled = true
	title.Name = "Title"
	title.Parent = card
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0, 4)
	title.Size = UDim2.fromOffset(210, 46)
	title.ZIndex = 3
	local pic = Instance.new("Frame")
	pic.Name = "Picture"
	pic.AnchorPoint = Vector2.new(0.5, 0)
	pic.Position = UDim2.new(0.5, 0, 0, 44)
	pic.Size = UDim2.fromOffset(200, 170)
	pic.BackgroundColor3 = C.sky
	pic.Parent = card
	Kit.corner(pic, 20)
	Kit.stroke(pic, 3, nil, true)
	local pg = Instance.new("UIGradient")
	pg.Color = ColorSequence.new(Color3.fromHex("d6f2ff"), Color3.fromHex("62c0f5"))
	pg.Rotation = 90
	pg.Parent = pic
	local body = Kit.text(card, "Body", UDim2.new(1, -24, 0, 100), UDim2.fromOffset(12, 222), 22, true)
	body.TextWrapped = true
end

local function refreshTexts()
	hint.Text = Lang.text("FishHoldHint")
	Kit.setButtonText(holdButton, Lang.text("FishHold"))
	Kit.setButtonText(giveUp, Lang.text("FishGiveUp"))
end

local function draw()
	local s = active
	if not s then
		return
	end
	local b = s.bar
	zoneFrame.Size = UDim2.new(1, -10, b.params.zone, 0)
	zoneFrame.Position = UDim2.new(0, 5, 1 - b.zone, 0)
	catIcon.Position = UDim2.new(0.5, 0, 1 - b.cat, 0)
	meterFill.Size = UDim2.fromScale(1, b.meter)
	meterFill.BackgroundColor3 = if b.meter > 0.66 then C.green elseif b.meter > 0.33 then C.yellow else C.coral
	zoneFrame.BackgroundColor3 = if FishingBar.inside(b) then C.green else Color3.fromHex("8fd38f")
end

local function showCard(vars: { [string]: any })
	(card:FindFirstChild("Title") :: TextLabel).Text = Lang.text("CaughtTitle")
	local tier = vars.tier
	local tierText = if type(tier) == "string" then Lang.text("Tier" .. tier) else ""
	-- the cat's picture (R9)
	local pic = card:FindFirstChild("Picture") :: Frame
	local old = pic:FindFirstChild("Portrait")
	if old then
		old:Destroy()
	end
	local design = if type(vars.kind) == "string" then Cats.ById[vars.kind] else nil
	if design then
		local look = table.clone(design.Look) :: any
		look.mutation = if type(vars.mutation) == "string" and vars.mutation ~= "" then vars.mutation else nil
		CatPortrait.make(pic, look)
	end
	;(card:FindFirstChild("Body") :: TextLabel).Text = Lang.text("FishCaught", { name = vars.name, tier = tierText, kg = vars.kg })
		.. (if type(vars.mutation) == "string" and vars.mutation ~= "" then " · " .. Lang.text("Mut" .. vars.mutation) .. "!" else "")
	card.Visible = true
	local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = card
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.6, function()
		card.Visible = false
	end)
end

function FishingController.Start(_self: any)
	castRemote = Remotes.event("Cast")
	holdRemote = Remotes.event("FishHold")
	giveUpRemote = Remotes.event("FishGiveUp")
	build()
	refreshTexts()
	Lang.changed:Connect(refreshTexts)

	local function watch(container: Instance)
		for _, c in container:GetChildren() do
			hookTool(c)
		end
		container.ChildAdded:Connect(hookTool)
	end
	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(character)
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = true
		elseif input.KeyCode == Enum.KeyCode.Space then
			holdingKey = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = false
		elseif input.KeyCode == Enum.KeyCode.Space then
			holdingKey = false
		end
		holdTouches[input] = nil
	end)

	Remotes.event("FishStart").OnClientEvent:Connect(function(id: unknown, tier: unknown, snap: unknown, rod: unknown, easy: unknown)
		if type(id) ~= "string" or type(tier) ~= "number" or type(snap) ~= "table" then
			return
		end
		local bar = FishingBar.new(0, FishingBar.params(tier, if type(rod) == "number" then rod else 1, easy == true))
		FishingBar.apply(bar, snap :: { number })
		active = { id = id, bar = bar, history = {}, acc = 0, hold = false, done = false }
		clearInput()
		gui.Enabled = true
		draw()
	end)
	Remotes.event("FishState").OnClientEvent:Connect(function(id: unknown, snap: unknown)
		if active and id == active.id and type(snap) == "table" then
			reconcile(active, snap :: { number })
		end
	end)
	Remotes.event("FishEnd").OnClientEvent:Connect(function(key: unknown, vars: unknown, caught: unknown)
		active = nil
		clearInput()
		gui.Enabled = false
		if caught == true and type(vars) == "table" then
			showCard(vars :: any)
		elseif type(key) == "string" then
			ToastController.show(key, if type(vars) == "table" then vars :: any else nil, if key == "FishGaveUp" then "info" else "bad")
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if active then
			run(active, dt)
			draw()
		end
	end)
end

return FishingController
