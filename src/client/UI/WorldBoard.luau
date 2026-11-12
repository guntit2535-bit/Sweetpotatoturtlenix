--!strict
-- A dark sign board on two posts, standing in the world on this client only, with a title, a line and one big
-- button (a SurfaceGui in PlayerGui adorned to the board, so the button takes taps and clicks) plus a prompt
-- (E / tap when near). Used at your pen (pen slots, W4) and at your weights / treadmill (training boosts, W6).
--   local b = WorldBoard.make("PenUpgradeBoard", face)   -- face: the board's CFrame on the floor, front = LookVector
--   b.title.Text, b.line.Text, Kit.setButtonText(b.button, ..), b.prompt; b.model:Destroy() removes it all

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)

local WorldBoard = {}

local C = Kit.Colors
local DARK = Color3.fromHex("2b2d3a")
local WOOD = Color3.fromHex("6b4a32")

export type Board = {
	model: Model,
	title: TextLabel,
	line: TextLabel,
	button: TextButton,
	prompt: ProximityPrompt,
}

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.Parent = parent
	return p
end

-- `scale` 1 = the pen board (6.8 x 4.2 studs on posts 6 high)
function WorldBoard.make(name: string, face: CFrame, scale: number?): Board
	local s = scale or 1
	local m = Instance.new("Model")
	m.Name = name
	for _, x in { -2.6, 2.6 } do
		part(m, Vector3.new(0.6, 6, 0.6) * s, face * CFrame.new(x * s, 3 * s, 0.3 * s), WOOD, "Post")
	end
	local panel = part(m, Vector3.new(6.8, 4.2, 0.5) * s, face * CFrame.new(0, 6.6 * s, 0), DARK, "Board")
	part(m, Vector3.new(7.2, 0.4, 0.9) * s, face * CFrame.new(0, 8.85 * s, 0), WOOD, "Cap")
	m.PrimaryPart = panel
	m.Parent = workspace

	local gui = Instance.new("SurfaceGui")
	gui.Name = name .. "Gui"
	gui.Adornee = panel
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50 / s
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local title = Kit.text(gui, "Title", UDim2.new(1, -20, 0, 52), UDim2.fromOffset(10, 8), 42, true)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	local line = Kit.text(gui, "Level", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 62), 32, true)
	line.TextColor3 = Color3.fromHex("7dff7a")
	local button = Kit.button(gui, "Buy", C.green, UDim2.new(1, -60, 0, 64), UDim2.new(0, 30, 0, 118))
	local label = button:FindFirstChild("Label")
	local lim = label and label:FindFirstChildOfClass("UITextSizeConstraint")
	if lim then
		lim.MaxTextSize = 38
	end
	m.Destroying:Connect(function()
		gui:Destroy()
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = panel
	return { model = m, title = title, line = line, button = button, prompt = prompt }
end

return WorldBoard
