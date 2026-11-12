--!strict
-- W6 (revision 3 item 17): a board beside your own weights and one beside your treadmill sells the next permanent
-- training boost step for Robux (x2 -> x4 -> x8 .. x64; products TrainW1-6 / TrainT1-6 in Config.Products):
--   x4 STRENGTH · Now x2 · forever · [ (Robux icon) 10 ]      (the price Roblox gives this player; MAX at x64)
-- The button opens Roblox's purchase prompt; ProductService grants it (saved before the thanks toast). A step whose
-- product id is still 0 says "Not on sale yet".

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local WorldBoard = require(script.Parent.Parent.UI.WorldBoard)
local PenBoardController = require(script.Parent.PenBoardController)

local TrainBoostController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local STATS = { { stat = "Weights", field = "BoostWeights", short = "W" }, { stat = "Treadmill", field = "BoostTread", short = "T" } }
local boards: { [string]: WorldBoard.Board } = {}
local boardPen: Model? = nil
local prices: { [number]: string } = {}

-- the product for the next step of `stat` (nil at the top)
local function nextProduct(stat: string, have: number): any
	for _, p in Config.Products.List do
		if p.Kind == "TrainBoost" and p.Stat == stat and p.Step == have + 1 then
			return p
		end
	end
	return nil
end

local refresh: () -> ()

local function price(id: number): string
	if prices[id] then
		return prices[id]
	end
	prices[id] = Format.robux("...")
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product)
		end)
		prices[id] = Format.robux(if ok and info and info.PriceInRobux then info.PriceInRobux else "?")
		refresh()
	end)
	return prices[id]
end

refresh = function()
	local data = PlayerData.get() or {}
	for _, s in STATS do
		local b = boards[s.stat]
		if b then
			local have = (data :: any)[s.field] or 0
			local now = Config.TrainBoost.Mult ^ have
			local p = nextProduct(s.stat, have)
			if not p then
				b.title.Text = Lang.text("TrainBoostTitle" .. s.short, { mult = now })
				b.line.Text = Lang.text("TrainBoostMax", { now = now })
				Kit.setButtonText(b.button, Lang.text("MaxShort"))
				Kit.setButtonColor(b.button, C.coral)
				b.prompt.Enabled = false
			else
				b.title.Text = Lang.text("TrainBoostTitle" .. s.short, { mult = now * Config.TrainBoost.Mult })
				b.line.Text = Lang.text("TrainBoostNow", { now = now })
				local text = if p.Id == 0 then Lang.text("NotOnSaleYet") else price(p.Id)
				Kit.setButtonText(b.button, text)
				Kit.setButtonColor(b.button, if p.Id == 0 then C.grey else C.green)
				b.prompt.Enabled = p.Id ~= 0
				b.prompt.ActionText = text
				b.prompt.ObjectText = b.title.Text
			end
		end
	end
end

local function buy(stat: string, field: string)
	local data = PlayerData.get() or {}
	local p = nextProduct(stat, (data :: any)[field] or 0)
	if p and p.Id ~= 0 then
		MarketplaceService:PromptProductPurchase(me, p.Id)
	end
end

local function build(pen: Model)
	local pivot = pen:GetPivot()
	local look = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z).Unit
	local right = look:Cross(Vector3.yAxis)
	for _, s in STATS do
		local station = pen:FindFirstChild(s.stat)
		local stand = station and station:FindFirstChild("Stand")
		if stand and stand:IsA("BasePart") then
			-- beside the training spot, on the side away from the pen's middle, facing the plaza
			local side = if (stand.Position - pivot.Position):Dot(right) >= 0 then right else -right
			local at = Vector3.new(stand.Position.X, stand.Position.Y - stand.Size.Y / 2 - 1.5, stand.Position.Z)
				+ side * Config.TrainBoostBoard.Side + look * Config.TrainBoostBoard.Forward
			local b = WorldBoard.make("TrainBoost" .. s.stat, CFrame.lookAt(at, at + look), Config.TrainBoostBoard.Scale)
			b.button.Activated:Connect(function()
				buy(s.stat, s.field)
			end)
			b.prompt.Triggered:Connect(function()
				buy(s.stat, s.field)
			end)
			boards[s.stat] = b
		end
	end
	boardPen = pen
	refresh()
end

local function check()
	local pen = PenBoardController.myPen()
	if pen ~= boardPen then
		for k, b in boards do
			b.model:Destroy()
			boards[k] = nil
		end
		boardPen = nil
		if pen then
			build(pen)
		end
	end
end

function TrainBoostController.Start(_self: any)
	PlayerData.changed:Connect(refresh)
	Lang.changed:Connect(refresh)
	task.spawn(function()
		while true do
			check()
			task.wait(2)
		end
	end)
end

return TrainBoostController
