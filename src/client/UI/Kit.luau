--!strict
-- UI kit (task 1.1; R9 cute-cat look from the developer's GPT style board, art/source/gpt_ui/00_style_board):
-- cream windows with two cat ears, a pink cat-head title banner, a round pink close button and faint paw prints;
-- glossy jelly buttons with a darker lip and a tiny paw; navy outlines; one window open at a time, sized down
-- to fit phones. Every window and button in the game is built here, so the look lives in one place.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Kit = {}

local hex = Color3.fromHex
Kit.Colors = {
	ink = hex("2a2f4f"), -- every outline
	panel = hex("fff3da"), -- window cream
	soft = hex("fffaf1"), -- rows and cards on a window
	peach = hex("f6cfa6"), -- inner borders, faint paw prints
	muted = hex("8a7766"),
	sky = hex("5ec4ff"),
	yellow = hex("ffd23f"),
	green = hex("5bd65a"),
	coral = hex("ff5e7e"),
	pink = hex("ff7fb6"),
	purple = hex("b07cff"),
	grey = hex("a9aebd"),
	tab = hex("fbe8cc"), -- an unselected tab
	white = hex("ffffff"),
}
local C = Kit.Colors

Kit.Font = Enum.Font.FredokaOne

local playerGui: PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

function Kit.screen(name: string, order: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = order or 0
	gui.Parent = playerGui
	return gui
end

function Kit.corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

function Kit.stroke(parent: Instance, thickness: number, color: Color3?, border: boolean?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or C.ink
	s.ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
end

-- Outlined white text (headers, button labels) or plain ink text (outlined = false).
function Kit.text(parent: Instance, name: string, size: UDim2, pos: UDim2, textSize: number, outlined: boolean?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos
	t.Font = Kit.Font
	t.TextSize = textSize
	t.TextScaled = false
	t.TextWrapped = true
	t.TextColor3 = if outlined then C.white else C.ink
	if outlined then
		Kit.stroke(t, 2.5)
	end
	t.Parent = parent
	return t
end

local function lipColor(color: Color3): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.min(1, s * 1.1), v * 0.72)
end

-- A chunky button: coloured face, dark outline, a darker lip under it, outlined label "Label".
function Kit.button(parent: Instance, name: string, color: Color3, size: UDim2, pos: UDim2): TextButton
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Size = size
	holder.Position = pos
	holder.Parent = parent
	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.Size = UDim2.new(1, 0, 1, 0)
	lip.Position = UDim2.fromOffset(0, 5)
	lip.BackgroundColor3 = lipColor(color)
	lip.BorderSizePixel = 0
	lip.Parent = holder
	Kit.corner(lip, 16)
	Kit.stroke(lip, 3, nil, true)
	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 1, 0)
	face.BackgroundColor3 = color
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.Parent = holder
	Kit.corner(face, 16)
	Kit.stroke(face, 3, nil, true)
	-- jelly gloss along the top
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.new(1, -14, 0.32, 0)
	gloss.Position = UDim2.new(0, 7, 0, 4)
	gloss.BackgroundColor3 = C.white
	gloss.BackgroundTransparency = 0.6
	gloss.BorderSizePixel = 0
	gloss.Parent = face
	Kit.corner(gloss, 10)
	if size.X.Offset >= 90 then
		Kit.paw(face, 16, UDim2.new(1, -22, 0, 4), C.white, 0.15)
	end
	local label = Kit.text(face, "Label", UDim2.new(1, -12, 1, 0), UDim2.fromOffset(6, 0), 22, true)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 24
	limit.Parent = label
	-- press feedback: the face sinks onto its lip
	face.MouseButton1Down:Connect(function()
		face.Position = UDim2.fromOffset(0, 3)
	end)
	local function release()
		face.Position = UDim2.fromOffset(0, 0)
	end
	face.MouseButton1Up:Connect(release)
	face.MouseLeave:Connect(release)
	return face
end

function Kit.setButtonColor(face: TextButton, color: Color3)
	face.BackgroundColor3 = color
	local holder = face.Parent
	local lip = holder and holder:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = lipColor(color)
	end
end

function Kit.setButtonText(face: TextButton, text: string)
	local label = face:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- A paw print from frames: one pad and four toes (decoration, no image needed).
function Kit.paw(parent: Instance, size: number, pos: UDim2, color: Color3, transparency: number?): Frame
	local p = Instance.new("Frame")
	p.Name = "Paw"
	p.BackgroundTransparency = 1
	p.Size = UDim2.fromOffset(size, size)
	p.Position = pos
	p.Parent = parent
	local function dot(w: number, h: number, x: number, y: number)
		local d = Instance.new("Frame")
		d.Size = UDim2.fromScale(w, h)
		d.Position = UDim2.fromScale(x, y)
		d.BackgroundColor3 = color
		d.BackgroundTransparency = transparency or 0
		d.BorderSizePixel = 0
		d.Parent = p
		Kit.corner(d, size)
	end
	dot(0.5, 0.42, 0.25, 0.5)
	dot(0.22, 0.26, 0.04, 0.3)
	dot(0.22, 0.26, 0.26, 0.06)
	dot(0.22, 0.26, 0.52, 0.06)
	dot(0.22, 0.26, 0.74, 0.3)
	return p
end

-- A list row (R9, mockups 02 / 03): cream card with a navy outline, a sky-blue picture box on the left (`chip`,
-- holding a colour square until item pictures exist), a big outlined name and the description in a small
-- cream pill. Leave room on the right for a button (Kit.rowButton). Returns the row and the picture box.
function Kit.row(parent: Instance, order: number, title: string, line: string, chipColor: Color3?): (Frame, Frame)
	local row = Instance.new("Frame")
	row.Name = `Item{order}`
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -12, 0, 86)
	row.BackgroundColor3 = C.soft
	row.Parent = parent
	Kit.corner(row, 18)
	Kit.stroke(row, 3, nil, true)
	Kit.paw(row, 22, UDim2.new(1, -196, 0, 8), C.peach, 0.45)
	Kit.paw(row, 16, UDim2.new(1, -186, 1, -26), C.peach, 0.55)
	local chip = Instance.new("Frame")
	chip.Name = "Picture"
	chip.Size = UDim2.fromOffset(66, 66)
	chip.Position = UDim2.fromOffset(10, 10)
	chip.BackgroundColor3 = C.sky
	chip.Parent = row
	Kit.corner(chip, 14)
	Kit.stroke(chip, 3, nil, true)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(hex("bfeaff"), hex("4fb6f2"))
	g.Rotation = 90
	g.Parent = chip
	if chipColor then
		local sq = Instance.new("Frame")
		sq.Name = "Color"
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Position = UDim2.fromScale(0.5, 0.5)
		sq.Size = UDim2.fromScale(0.55, 0.55)
		sq.BackgroundColor3 = chipColor
		sq.Parent = chip
		Kit.corner(sq, 10)
		Kit.stroke(sq, 3, nil, true)
	end
	local name = Kit.text(row, "Name", UDim2.new(1, -260, 0, 32), UDim2.fromOffset(88, 8), 26, true)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Text = title
	local pill = Instance.new("Frame")
	pill.Name = "InfoPill"
	pill.Size = UDim2.new(1, -262, 0, 28)
	pill.Position = UDim2.fromOffset(86, 46)
	pill.BackgroundColor3 = C.panel
	pill.Parent = row
	Kit.corner(pill, 14)
	Kit.stroke(pill, 2, C.peach, true)
	local info = Kit.text(pill, "Info", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 16)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextTruncate = Enum.TextTruncate.AtEnd
	info.TextColor3 = C.ink
	info.Text = line
	return row, chip
end

-- The button on the right of a Kit.row.
function Kit.rowButton(row: Frame, text: string, color: Color3): TextButton
	local b = Kit.button(row, "Action", color, UDim2.fromOffset(156, 54), UDim2.new(1, -168, 0.5, -29))
	Kit.setButtonText(b, text)
	return b
end

-- A UI icon (Config.UIIcons[key], R9) as an ImageLabel, or a white paw while its id is still 0.
function Kit.icon(parent: Instance, key: string, size: number, pos: UDim2): GuiObject
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
	local id = Config.UIIcons and Config.UIIcons[key] or 0
	if type(id) == "number" and id > 0 then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(size, size)
		img.Position = pos
		img.Image = `rbxassetid://{id}`
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	end
	local paw = Kit.paw(parent, math.floor(size * 0.7), pos + UDim2.fromOffset(size * 0.15, size * 0.15), C.white, 0)
	paw.Name = "Icon"
	return paw
end

-- Two cat ears sticking up from the top edge of `parent` (cream with pink insides by default).
function Kit.ears(parent: Instance, size: number, xs: { number }, color: Color3?, inner: Color3?)
	for _, x in xs do
		local clip = Instance.new("Frame")
		clip.Name = "Ear"
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.AnchorPoint = Vector2.new(0.5, 1)
		clip.Position = UDim2.new(x, 0, 0, 3)
		clip.Size = UDim2.fromOffset(size * 1.5, size * 0.75 + 3)
		clip.Parent = parent
		for i, c in { color or C.panel, inner or C.pink } do
			local s = if i == 1 then size else size * 0.55
			local d = Instance.new("Frame")
			d.AnchorPoint = Vector2.new(0.5, 0.5)
			d.Position = UDim2.new(0.5, 0, 1, if i == 1 then 0 else -size * 0.12)
			d.Size = UDim2.fromOffset(s, s)
			d.Rotation = 45
			d.BackgroundColor3 = c
			d.BorderSizePixel = 0
			d.Parent = clip
			Kit.corner(d, math.floor(s * 0.22))
			if i == 1 then
				Kit.stroke(d, 3, nil, true)
			end
		end
	end
end

-- A gear drawn from frames (no image assets needed).
function Kit.gear(parent: Instance, size: number, color: Color3?): Frame
	local g = Instance.new("Frame")
	g.Name = "Gear"
	g.BackgroundTransparency = 1
	g.Size = UDim2.fromOffset(size, size)
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Parent = parent
	local c = color or C.white
	for i = 0, 3 do
		local tooth = Instance.new("Frame")
		tooth.AnchorPoint = Vector2.new(0.5, 0.5)
		tooth.Position = UDim2.fromScale(0.5, 0.5)
		tooth.Size = UDim2.new(0.26, 0, 1, 0)
		tooth.Rotation = i * 45
		tooth.BackgroundColor3 = c
		tooth.BorderSizePixel = 0
		tooth.Parent = g
		Kit.corner(tooth, 3)
		Kit.stroke(tooth, 2, nil, true)
	end
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(0.72, 0.72)
	ring.BackgroundColor3 = c
	ring.BorderSizePixel = 0
	ring.Parent = g
	Kit.corner(ring, size)
	Kit.stroke(ring, 2, nil, true)
	local hole = Instance.new("Frame")
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Position = UDim2.fromScale(0.5, 0.5)
	hole.Size = UDim2.fromScale(0.3, 0.3)
	hole.BackgroundColor3 = C.ink
	hole.BorderSizePixel = 0
	hole.Parent = g
	Kit.corner(hole, size)
	return g
end

----------------------------------------------------------------------------------------------------
-- Windows: one open at a time; tapping outside or the X closes it.

export type Window = {
	gui: ScreenGui,
	panel: Frame,
	body: Frame,
	title: TextLabel,
	setOpen: (open: boolean) -> (),
	isOpen: () -> boolean,
}

local openWindow: Window? = nil

export type WindowOptions = { name: string, width: number, height: number, color: Color3? }

function Kit.window(opts: WindowOptions): Window
	local gui = Kit.screen(opts.name, 10)
	gui.Enabled = false
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = C.ink
	backdrop.BackgroundTransparency = 0.55
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.Size = UDim2.fromOffset(opts.width, opts.height)
	panel.BackgroundColor3 = C.panel
	panel.Active = true -- taps on the panel never reach the backdrop or the world
	panel.Parent = gui
	Kit.corner(panel, 28)
	Kit.stroke(panel, 4, nil, true)
	local scale = Instance.new("UIScale")
	scale.Parent = panel

	-- cat ears on the top corners, a peach inner border and faint paw prints (under the body)
	Kit.ears(panel, 62, { 0.1, 0.9 })
	local deco = Instance.new("Frame")
	deco.Name = "Deco"
	deco.BackgroundTransparency = 1
	deco.Size = UDim2.new(1, -14, 1, -14)
	deco.Position = UDim2.fromOffset(7, 7)
	deco.ZIndex = 0
	deco.Parent = panel
	Kit.corner(deco, 22)
	Kit.stroke(deco, 3, C.peach, true)
	for i, at in { { 0.06, 0.12 }, { 0.9, 0.16 }, { 0.12, 0.86 }, { 0.84, 0.82 }, { 0.47, 0.9 } } do
		Kit.paw(deco, if i % 2 == 0 then 26 else 20, UDim2.fromScale(at[1], at[2]), C.peach, 0.35)
	end

	-- the pink cat-head title banner across the top edge (pink on every window in the cat look)
	local banner = Instance.new("Frame")
	banner.Name = "Header"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0, 4)
	banner.Size = UDim2.fromOffset(math.clamp(opts.width * 0.5, 220, 380), 58)
	banner.BackgroundColor3 = C.pink
	banner.Parent = panel
	Kit.corner(banner, 29)
	Kit.stroke(banner, 4, nil, true)
	Kit.ears(banner, 30, { 0.2, 0.8 }, C.pink, hex("ffd0e4"))
	local title = Kit.text(banner, "Title", UDim2.new(1, -40, 1, -8), UDim2.fromOffset(20, 4), 34, true)
	title.TextScaled = true
	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MaxTextSize = 36
	titleLimit.Parent = title

	local close = Kit.button(panel, "Close", C.coral, UDim2.fromOffset(54, 54), UDim2.new(1, -40, 0, -18))
	Kit.setButtonText(close, "X")
	for _, part in { close :: Instance, (close.Parent :: Instance):FindFirstChild("Lip") } do
		if part then
			for _, c in part:GetChildren() do
				if c:IsA("UICorner") then
					c.CornerRadius = UDim.new(0.5, 0)
				end
			end
		end
	end

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(18, 52)
	body.Size = UDim2.new(1, -36, 1, -68)
	body.Parent = panel

	local window: Window
	local function fit(): number
		local camera = workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		return math.min(1, (view.X - 24) / opts.width, (view.Y - 70) / (opts.height + 10))
	end
	local function setOpen(open: boolean)
		if open then
			if openWindow and openWindow ~= window then
				openWindow.setOpen(false)
			end
			openWindow = window
			gui.Enabled = true
			local target = fit()
			scale.Scale = target * 0.85
			TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
		else
			gui.Enabled = false
			if openWindow == window then
				openWindow = nil
			end
		end
	end
	window = {
		gui = gui,
		panel = panel,
		body = body,
		title = title,
		setOpen = setOpen,
		isOpen = function()
			return gui.Enabled
		end,
	}
	backdrop.Activated:Connect(function()
		setOpen(false)
	end)
	close.Activated:Connect(function()
		setOpen(false)
	end)
	return window
end

return Kit
