--!strict
-- Small UI kit (task 1.1): bright chunky buttons with a dark outline and a lip, white windows with a
-- coloured header, one window open at a time, sized down to fit phones. The final look of the game's
-- UI is chosen in task 1.17; windows and buttons built with this kit pick it up from here.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Kit = {}

local hex = Color3.fromHex
Kit.Colors = {
	ink = hex("1f2a52"),
	panel = hex("ffffff"),
	soft = hex("eef7ff"),
	muted = hex("5a6688"),
	sky = hex("3db2ff"),
	yellow = hex("ffc93c"),
	green = hex("4fc75a"),
	coral = hex("ff5a4e"),
	purple = hex("9b6bff"),
	grey = hex("b9c2d6"),
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
	Kit.corner(lip, 14)
	Kit.stroke(lip, 3, nil, true)
	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 1, 0)
	face.BackgroundColor3 = color
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.Parent = holder
	Kit.corner(face, 14)
	Kit.stroke(face, 3, nil, true)
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
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromOffset(opts.width, opts.height)
	panel.BackgroundColor3 = C.panel
	panel.Active = true -- taps on the panel never reach the backdrop or the world
	panel.Parent = gui
	Kit.corner(panel, 22)
	Kit.stroke(panel, 4, nil, true)
	local scale = Instance.new("UIScale")
	scale.Parent = panel

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = opts.color or C.coral
	header.Parent = panel
	Kit.corner(header, 22)
	Kit.stroke(header, 4, nil, true)
	local title = Kit.text(header, "Title", UDim2.new(1, -120, 1, 0), UDim2.fromOffset(60, 0), 30, true)

	local close = Kit.button(header, "Close", C.coral, UDim2.fromOffset(46, 46), UDim2.new(1, -54, 0, 5))
	Kit.setButtonText(close, "X")

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(18, 70)
	body.Size = UDim2.new(1, -36, 1, -86)
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
