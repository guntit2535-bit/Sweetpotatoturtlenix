--!strict
-- The HUD's left column of big buttons (blueprint §16: Shop, x2 Speed, My Cats, Trade; W3: + Rebirth, Rewards). Controllers add
-- their own button: Hud.leftButton("MyCats", "MyCatsButton", Kit.Colors.yellow, 3, onClick).
-- X3 (revision 4 item 2, look 2A): open buttons, no jelly square and no ears: a big icon (Config.UIIcons[name], a
-- white paw until it is uploaded) with an outlined label under it; it sinks a little when pressed. Phones get a
-- smaller column.

local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Kit)

local Hud = {}

Hud.StatsHeight = 210 -- W2: the bottom-left stats block as drawn (HudController: 3 rows of 62 (X1) + the income line)

local column: Frame? = nil
local labels: { [TextButton]: string } = {}

-- W3: two to a row (middle left). X3: a 96 x 100 cell per button, the icon 84 px, the label under it.
local SIZE = Vector2.new(96, 100)
local ICON = 84
local GAP = Vector2.new(6, 10)
local PER_ROW = 2
local ROWS = 2 -- X1: Shop | My Cats, Trade | Rewards (x2 Speed gone, Rebirth on the right)

local function getColumn(): Frame
	if column then
		return column
	end
	local gui = Kit.screen("HudLeft", 2)
	local f = Instance.new("Frame")
	f.Name = "Column"
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0, 0.5)
	f.Position = UDim2.new(0, 14, 0.42, 0)
	f.Size = UDim2.fromOffset(PER_ROW * SIZE.X + (PER_ROW - 1) * GAP.X + 6, ROWS * SIZE.Y + ROWS * GAP.Y)
	f.Parent = gui
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(SIZE.X, SIZE.Y)
	layout.CellPadding = UDim2.fromOffset(GAP.X, GAP.Y)
	layout.FillDirectionMaxCells = PER_ROW
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = f
	-- phones: a smaller column, but never too small for a finger (W2); its bottom stays above the bottom-left stats
	-- (HudController: 180 px tall drawn, Kit.fit(720, 0.6), 10 from the bottom) and it never climbs above the middle
	Kit.fit(f, 720, 0.55, Kit.TouchMin)
	f.AnchorPoint = Vector2.new(0, 1)
	local function place()
		local h = gui.AbsoluteSize.Y -- the screen under Roblox's top bar
		if h <= 0 then
			h = 720
		end
		local statsTop = 10 + Hud.StatsHeight * Kit.scaleFor(720, 0.6) + 14
		local mine = f.Size.Y.Offset * Kit.scaleFor(720, 0.55, Kit.TouchMin)
		-- centred near 0.42 of the screen when there is room, otherwise pushed up just enough
		local bottom = math.max(statsTop, h * 0.58 - mine / 2)
		f.Position = UDim2.new(0, Kit.edgeX("left"), 1, -bottom) -- hugs the left edge (Kit.edge)
	end
	gui.ClipToDeviceSafeArea = false
	place()
	task.delay(0.5, place)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	Kit.insetsChanged:Connect(function()
		task.defer(place)
	end)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
	end
	Lang.changed:Connect(function()
		for face, key in labels do
			Kit.setButtonText(face, Lang.text(key))
		end
	end)
	column = f
	return f
end

-- `color` is kept for the callers (the old jelly look used it); X3's open buttons do not draw it.
function Hud.leftButton(name: string, textKey: string, color: Color3, order: number, onClick: () -> ()): TextButton
	local _ = color
	local col = getColumn()
	local face = Instance.new("TextButton")
	face.Name = name
	face.LayoutOrder = order
	face.BackgroundTransparency = 1
	face.AutoButtonColor = false
	face.Text = ""
	face.Size = UDim2.fromOffset(SIZE.X, SIZE.Y)
	face.Parent = col
	local icon = Kit.icon(face, name, ICON, UDim2.new(0.5, -ICON / 2, 0, -4))
	local label = Kit.text(face, "Label", UDim2.new(1, 12, 0, 28), UDim2.new(0, -6, 1, -24), 22, true)
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 24
	limit.Parent = label
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 3
	end
	-- press feedback: the icon sinks a little
	local press = Instance.new("UIScale")
	press.Parent = icon
	face.MouseButton1Down:Connect(function()
		press.Scale = 0.9
	end)
	for _, ev in { face.MouseButton1Up, face.MouseLeave } do
		ev:Connect(function()
			press.Scale = 1
		end)
	end
	Kit.setButtonText(face, Lang.text(textKey))
	labels[face] = textKey
	face.Activated:Connect(onClick)
	return face
end

-- X1 (revision 4 item 20): one big button on the right side (Rebirth): icon on the left, a big label, a glowing
-- outline the controller can pulse (holder.Glow). Touch screens: just under the two event pills (HudController,
-- under the Settings gear), above Roblox's jump button; PC: the middle of the right edge.
Hud.RightSize = Vector2.new(190, 76)
function Hud.rightButton(name: string, textKey: string, color: Color3, onClick: () -> ()): (TextButton, UIStroke)
	local gui = Kit.screen("HudRight", 2)
	gui.ClipToDeviceSafeArea = false
	local frame = Instance.new("Frame")
	frame.Name = name .. "Spot"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(Hud.RightSize.X, Hud.RightSize.Y + 6)
	frame.Parent = gui
	local scale = Kit.fit(frame, 720, 0.55, Kit.TouchMin)
	local touch = game:GetService("UserInputService").TouchEnabled
	local function place()
		if touch then
			-- the pills: top 92, 44 tall, 52 apart, scaled (HudController); 12 px below the second
			frame.AnchorPoint = Vector2.new(1, 0)
			frame.Position = UDim2.new(1, -Kit.edgeX("right"), 0, 92 + (52 + 44) * Kit.scaleFor(720, 0.6) + 12) -- the pills scale like fitScale
		else
			frame.AnchorPoint = Vector2.new(1, 0.5)
			frame.Position = UDim2.new(1, -Kit.edgeX("right"), 0.5, 0)
		end
	end
	place()
	task.delay(0.5, place)
	Kit.insetsChanged:Connect(function()
		task.defer(place)
	end)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			task.defer(place)
		end)
	end
	local face = Kit.button(frame, name, color, UDim2.fromOffset(Hud.RightSize.X, Hud.RightSize.Y), UDim2.new())
	local holder = face.Parent :: Frame
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Thickness = 5
	glow.Color = Kit.Colors.yellow
	glow.Transparency = 1
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = holder:FindFirstChild("Lip")
	local icon = 58
	Kit.icon(face, name, icon, UDim2.new(0, 6, 0.5, -icon / 2))
	local label = face:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.new(1, -icon - 14, 1, -8)
	label.Position = UDim2.fromOffset(icon + 8, 4)
	label.TextScaled = true
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 30
	limit.Parent = label
	Kit.setButtonText(face, Lang.text(textKey))
	face.Activated:Connect(onClick)
	return face, glow
end

return Hud
