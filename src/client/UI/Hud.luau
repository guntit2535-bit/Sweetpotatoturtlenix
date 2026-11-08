--!strict
-- The HUD's left column of big buttons (blueprint §16: Shop, x2 Speed, My Cats, Trade). Controllers add
-- their own button: Hud.leftButton("MyCats", "MyCatsButton", Kit.Colors.yellow, 3, onClick).
-- R9 cute-cat look (art/source/gpt_ui/01_hud): square jelly buttons with cat ears, the icon on top
-- (Config.UIIcons[name], a white paw until it is uploaded) and the label under it. Phones get a smaller column.

local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Kit)

local Hud = {}

local column: Frame? = nil
local labels: { [TextButton]: string } = {}

local SIZE = Vector2.new(104, 88)

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
	f.Size = UDim2.fromOffset(SIZE.X + 8, 4 * (SIZE.Y + 22))
	f.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 22) -- room for the ears
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = f
	-- phones: a smaller column
	local scale = Instance.new("UIScale")
	scale.Parent = f
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = math.clamp(h / 800, 0.5, 1)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	Lang.changed:Connect(function()
		for face, key in labels do
			Kit.setButtonText(face, Lang.text(key))
		end
	end)
	column = f
	return f
end

function Hud.leftButton(name: string, textKey: string, color: Color3, order: number, onClick: () -> ()): TextButton
	local col = getColumn()
	local face = Kit.button(col, name, color, UDim2.fromOffset(SIZE.X, SIZE.Y), UDim2.new())
	local holder = face.Parent :: Frame
	holder.LayoutOrder = order
	-- cat ears in the button's colour, the icon on top, the label underneath
	local h, s, v = color:ToHSV()
	Kit.ears(holder, 30, { 0.24, 0.76 }, color, Color3.fromHSV(h, s * 0.45, math.min(1, v * 1.1)))
	Kit.icon(face, name, 46, UDim2.new(0.5, -23, 0, 5))
	local label = face:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.new(1, -10, 0, 30)
	label.Position = UDim2.new(0, 5, 1, -33)
	Kit.setButtonText(face, Lang.text(textKey))
	labels[face] = textKey
	face.Activated:Connect(onClick)
	return face
end

return Hud
