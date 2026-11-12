--!strict
-- The HUD's left column of big buttons (blueprint §16: Shop, x2 Speed, My Cats, Trade; W3: + Rebirth, Rewards). Controllers add
-- their own button: Hud.leftButton("MyCats", "MyCatsButton", Kit.Colors.yellow, 3, onClick).
-- R9 cute-cat look (art/source/gpt_ui/01_hud): square jelly buttons with cat ears, the icon on top
-- (Config.UIIcons[name], a white paw until it is uploaded) and the label under it. Phones get a smaller column.

local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Kit)

local Hud = {}

local column: Frame? = nil
local labels: { [TextButton]: string } = {}

-- W3 (revision 3 items 11 + 13): 30% smaller than R9's 104 x 88, two to a row, Rebirth and Rewards join the
-- column (middle left): Shop | x2 Speed, My Cats | Trade, Rebirth | Rewards.
local K = 0.7
local SIZE = Vector2.new(math.floor(104 * K), math.floor(88 * K))
local GAP = Vector2.new(10, 20) -- the row gap leaves room for the ears
local PER_ROW = 2
local ROWS = 3

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
	Kit.ears(holder, math.floor(30 * K), { 0.24, 0.76 }, color, Color3.fromHSV(h, s * 0.45, math.min(1, v * 1.1)))
	local icon = math.floor(46 * K)
	Kit.icon(face, name, icon, UDim2.new(0.5, -icon / 2, 0, 3))
	local label = face:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.new(1, -6, 0, math.floor(30 * K))
	label.Position = UDim2.new(0, 3, 1, -math.floor(30 * K) - 2)
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 17
	end
	Kit.setButtonText(face, Lang.text(textKey))
	labels[face] = textKey
	face.Activated:Connect(onClick)
	return face
end

return Hud
