--!strict
-- The HUD's left column of big buttons (blueprint §16: Shop, x2 Speed, My Cats, Trade). Controllers add
-- their own button: Hud.leftButton("MyCats", "MyCatsButton", Kit.Colors.yellow, 3, onClick). Built on first
-- use; the full HUD (right panel, bottom bars, hotbar, countdown) is task 1.17.

local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Kit)

local Hud = {}

local column: Frame? = nil
local labels: { [TextButton]: string } = {}

local function getColumn(): Frame
	if column then
		return column
	end
	local gui = Kit.screen("HudLeft", 2)
	local f = Instance.new("Frame")
	f.Name = "Column"
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0, 0.5)
	f.Position = UDim2.new(0, 12, 0.46, 0)
	f.Size = UDim2.fromOffset(150, 330)
	f.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = f
	-- phones: a smaller column
	local scale = Instance.new("UIScale")
	scale.Parent = f
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = math.clamp(h / 720, 0.62, 1)
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
	local face = Kit.button(col, name, color, UDim2.fromOffset(150, 58), UDim2.new())
	local holder = face.Parent :: Frame
	holder.LayoutOrder = order
	Kit.setButtonText(face, Lang.text(textKey))
	labels[face] = textKey
	face.Activated:Connect(onClick)
	return face
end

return Hud
