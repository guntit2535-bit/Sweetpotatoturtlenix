--!strict
-- W4 (revision 3 item 5): pen slots are bought at a board in front of your own pen instead of the Shop's Pen tab
-- (the developer's picture 4: a dark board "Upgrade / Level / price button"). The board (UI/WorldBoard) is built
-- here, on this client only, next to your pen's sign (between the sign and the weights, facing the plaza):
--   PEN SLOTS · 25 -> 30 · [ Buy $9.8K ]   (MAX in red when the pen is full size)
-- Tap the button or use the prompt; the server checks and charges (BuyItem "Pen", ShopService).

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
local WorldBoard = require(script.Parent.Parent.UI.WorldBoard)

local PenBoardController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local buyRemote: RemoteEvent
local board: WorldBoard.Board? = nil
local boardPen: Model? = nil

-- your own pen (PenService sets OwnerId)
function PenBoardController.myPen(): Model?
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

local function refresh()
	local b = board
	if not b then
		return
	end
	local data = PlayerData.get() or {}
	local slots = data.PenSlots or Config.Pen.StartSlots
	local full = slots >= Config.Pen.MaxSlots
	b.title.Text = Lang.text("PenBoardTitle")
	b.line.Text = if full
		then Lang.text("PenBoardMax", { now = slots })
		else Lang.text("PenEffect", { now = slots, next = math.min(Config.Pen.MaxSlots, slots + Config.PenUpgrade.Step) })
	local cost = Shop.penCost(data.PenBuys or 0)
	Kit.setButtonText(b.button, if full then Lang.text("MaxShort") else Lang.text("Buy", { cost = Format.short(cost) }))
	Kit.setButtonColor(b.button, if full then C.coral else C.green)
	b.prompt.Enabled = not full
	b.prompt.ActionText = Lang.text("Buy", { cost = Format.short(cost) })
	b.prompt.ObjectText = Lang.text("PenBoardTitle")
end

local function buy()
	local data = PlayerData.get() or {}
	if (data.PenSlots or Config.Pen.StartSlots) < Config.Pen.MaxSlots then
		buyRemote:FireServer("Pen", 0)
	end
end

local function build(pen: Model)
	local pivot = pen:GetPivot()
	local look = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z).Unit
	local right = look:Cross(Vector3.yAxis)
	local floor = pen:FindFirstChild("Floor")
	local y = if floor and floor:IsA("BasePart") then floor.Position.Y + floor.Size.Y / 2 else 0.4
	local cfg = Config.PenBoard
	-- measured from the gate's sign (W7: the pen's centre moved back when the pens grew, the front did not)
	local sign = pen:FindFirstChild("Sign")
	local base = if sign and sign:IsA("Model") then sign:GetPivot().Position else pivot.Position
	local at = Vector3.new(base.X, y, base.Z) + look * cfg.Forward + right * cfg.Right
	local b = WorldBoard.make("PenUpgradeBoard", CFrame.lookAt(at, at + look))
	b.button.Activated:Connect(buy)
	b.prompt.Triggered:Connect(buy)
	board, boardPen = b, pen
	refresh()
end

local function check()
	local pen = PenBoardController.myPen()
	if pen ~= boardPen then
		if board then
			board.model:Destroy()
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
