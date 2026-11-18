--!strict
-- A sign board on two posts, standing in the world on this client only, with a title, a line and one big button
-- (SurfaceGuis in PlayerGui adorned to the board, so the button takes taps and clicks) plus a prompt (E / tap when
-- near). Used at your pen (pen slots, W4) and at your weights / treadmill (training boosts, W6).
-- 2026-11-18 (revision list 6, look A): like the game's windows: a cream face in a dark outline, a pink title band
-- with two cat ears on top, wooden posts with LEGO studs and pink caps (was a dark board).
--   local b = WorldBoard.make("PenUpgradeBoard", face)   -- face: the board's CFrame on the floor, front = LookVector
--   b.title.Text, b.line.Text, Kit.setButtonText(b.button, ..), b.prompt; b.model:Destroy() removes it all

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)

local WorldBoard = {}

local C = Kit.Colors
local INK = C.ink
local CREAM = C.panel
local PINK = C.pink
local WOOD = Color3.fromHex("c98a4a")

export type Board = {
	model: Model,
	title: TextLabel,
	line: TextLabel,
	button: TextButton,
	prompt: ProximityPrompt,
}

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, name: string, studs: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = if studs then Enum.Material.Plastic else Enum.Material.SmoothPlastic
	p.TopSurface = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function surface(name: string, adornee: BasePart, s: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50 / s
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

-- `scale` 1 = the pen board (7 x 4.4 studs on posts 6 high)
function WorldBoard.make(name: string, face: CFrame, scale: number?): Board
	local s = scale or 1
	local m = Instance.new("Model")
	m.Name = name
	for _, x in { -2.6, 2.6 } do
		part(m, Vector3.new(0.7, 6, 0.7) * s, face * CFrame.new(x * s, 3 * s, 0.3 * s), WOOD, "Post", true)
		part(m, Vector3.new(1, 0.5, 1) * s, face * CFrame.new(x * s, 6.2 * s, 0.3 * s), PINK, "PostCap", true)
	end
	-- the outline, the cream face, the pink title band and two cat ears
	local back = part(m, Vector3.new(7, 4.4, 0.5) * s, face * CFrame.new(0, 6.7 * s, 0), INK, "Board")
	local body = part(m, Vector3.new(6.7, 4.1, 0.1) * s, face * CFrame.new(0, 6.7 * s, -0.26 * s), CREAM, "Face")
	local band = part(m, Vector3.new(6.7, 1.1, 0.12) * s, face * CFrame.new(0, 8.2 * s, -0.28 * s), PINK, "TitleBand")
	part(m, Vector3.new(6.7, 4.1, 0.1) * s, face * CFrame.new(0, 6.7 * s, 0.26 * s), WOOD, "BackFace") -- (seen from the pen)
	for _, x in { -2.7, 2.7 } do
		part(m, Vector3.new(1.2, 1.2, 0.45) * s, face * CFrame.new(x * s, 9.05 * s, 0) * CFrame.Angles(0, 0, math.rad(45)), PINK, "Ear")
	end
	m.PrimaryPart = back
	m.Parent = workspace

	local titleGui = surface(name .. "Title", band, s)
	local title = Kit.text(titleGui, "Title", UDim2.new(1, -24, 1, -8), UDim2.fromOffset(12, 4), 42, true)
	title.TextScaled = true
	local gui = surface(name .. "Gui", body, s)
	-- (the band covers the top 1.1 studs of the face: the line and the button sit below it)
	local line = Kit.text(gui, "Level", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 64), 32)
	line.TextColor3 = INK
	line.TextScaled = true
	local lineLimit = Instance.new("UITextSizeConstraint")
	lineLimit.MaxTextSize = 32
	lineLimit.Parent = line
	local button = Kit.button(gui, "Buy", C.green, UDim2.new(1, -70, 0, 62), UDim2.new(0, 35, 0, 116))
	local label = button:FindFirstChild("Label")
	local lim = label and label:FindFirstChildOfClass("UITextSizeConstraint")
	if lim then
		lim.MaxTextSize = 38
	end
	m.Destroying:Connect(function()
		gui:Destroy()
		titleGui:Destroy()
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = back
	return { model = m, title = title, line = line, button = button, prompt = prompt }
end

return WorldBoard
