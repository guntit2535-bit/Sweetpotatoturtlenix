--!strict
-- W4 (revision 3 item 5): pen slots are bought at a board in front of your own pen instead of the Shop's Pen tab
-- (the developer's picture 4: a dark board "Upgrade / Level / price button"). The board is built here, on this
-- client only, next to your pen's sign (between the sign and the weights, facing the plaza):
--   PEN SLOTS · 25 -> 30 · [ Buy $9.8K ]   (MAX in red when the pen is full size)
-- Tap the button (SurfaceGui) or use the prompt; the server checks and charges (BuyItem "Pen", ShopService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Shop = require(Shared:WaitForChild("Shop"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)

local PenBoardController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local buyRemote: RemoteEvent
local board: Model? = nil
local boardPen: Model? = nil
local title: TextLabel
local level: TextLabel
local button: TextButton
local prompt: ProximityPrompt

local DARK = Color3.fromHex("2b2d3a")
local WOOD = Color3.fromHex("6b4a32")

local function myPen(): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if not pens then
		return nil
	end
	for _, p in pens:GetChildren() do
		if p:IsA("Model") and p:GetAttribute("OwnerId") == me.UserId then
			return p
		end
	end
	return nil
end

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, name: string?): Part
	local p = Instance.new("Part")
	p.Name = name or "Part"
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

local function refresh()
	if not board then
		return
	end
	local data = PlayerData.get() or {}
	local slots = data.PenSlots or Config.Pen.StartSlots
	local full = slots >= Config.Pen.MaxSlots
	title.Text = Lang.text("PenBoardTitle")
	level.Text = if full
		then Lang.text("PenBoardMax", { now = slots })
		else Lang.text("PenEffect", { now = slots, next = math.min(Config.Pen.MaxSlots, slots + Config.PenUpgrade.Step) })
	local cost = Shop.penCost(data.PenBuys or 0)
	Kit.setButtonText(button, if full then Lang.text("MaxShort") else Lang.text("Buy", { cost = Format.short(cost) }))
	Kit.setButtonColor(button, if full then C.coral else C.green)
	prompt.Enabled = not full
	prompt.ActionText = Lang.text("Buy", { cost = Format.short(cost) })
	prompt.ObjectText = Lang.text("PenBoardTitle")
end

local function buy()
	local data = PlayerData.get() or {}
	if (data.PenSlots or Config.Pen.StartSlots) < Config.Pen.MaxSlots then
		buyRemote:FireServer("Pen", 0)
	end
end

local function build(pen: Model)
	if board then
		board:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = "PenUpgradeBoard"
	local pivot = pen:GetPivot()
	local look = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z).Unit
	local right = look:Cross(Vector3.yAxis)
	local floor = pen:FindFirstChild("Floor")
	local y = if floor and floor:IsA("BasePart") then floor.Position.Y + floor.Size.Y / 2 else 0.4
	local cfg = Config.PenBoard
	local at = Vector3.new(pivot.Position.X, y, pivot.Position.Z) + look * cfg.Forward + right * cfg.Right
	local face = CFrame.lookAt(at, at + look) -- the board's front faces the plaza
	for _, x in { -2.6, 2.6 } do
		part(m, Vector3.new(0.6, 6, 0.6), face * CFrame.new(x, 3, 0.3), WOOD, "Post")
	end
	local panel = part(m, Vector3.new(6.8, 4.2, 0.5), face * CFrame.new(0, 6.6, 0), DARK, "Board")
	part(m, Vector3.new(7.2, 0.4, 0.9), face * CFrame.new(0, 8.85, 0), WOOD, "Cap")
	m.PrimaryPart = panel
	m.Parent = workspace

	-- the face: a SurfaceGui in PlayerGui (adorned to the board) so its button takes taps and clicks
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PenBoardGui"
	gui.Adornee = panel
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.ResetOnSpawn = false
	gui.Parent = me:WaitForChild("PlayerGui")
	title = Kit.text(gui, "Title", UDim2.new(1, -20, 0, 52), UDim2.fromOffset(10, 8), 42, true)
	title.TextColor3 = Color3.new(1, 1, 1)
	level = Kit.text(gui, "Level", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 62), 32, true)
	level.TextColor3 = Color3.fromHex("7dff7a")
	button = Kit.button(gui, "Buy", C.green, UDim2.new(1, -60, 0, 64), UDim2.new(0, 30, 0, 118))
	local label = button:FindFirstChild("Label")
	local lim = label and label:FindFirstChildOfClass("UITextSizeConstraint")
	if lim then
		lim.MaxTextSize = 38
	end
	button.Activated:Connect(buy)
	gui:GetPropertyChangedSignal("Adornee"):Connect(function()
		if not gui.Adornee then
			gui:Destroy()
		end
	end)
	m.Destroying:Connect(function()
		gui:Destroy()
	end)

	prompt = Instance.new("ProximityPrompt")
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Triggered:Connect(buy)
	prompt.Parent = panel

	board, boardPen = m, pen
	refresh()
end

local function check()
	local pen = myPen()
	if pen ~= boardPen then
		if board then
			board:Destroy()
			board, boardPen = nil, nil
		end
		if pen then
			build(pen)
		end
	end
end

function PenBoardController.Start(_self: any)
	buyRemote = Remotes.event("BuyItem")
	PlayerData.changed:Connect(refresh)
	Lang.changed:Connect(refresh)
	task.spawn(function()
		while true do
			check()
			task.wait(2)
		end
	end)
end

return PenBoardController
