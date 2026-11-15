--!strict
-- The sell booth on the plaza (developer 2026-11-15: press E at the shopkeeper, a talk menu; it was "stand on the
-- green pad"). The menu is on the client (SellBoothController); it only asks here, with SellAtBooth(mode):
--   "this" -> the cat carried over the head (CarryService.sellCarried), else the cat held from the bag (a Tool)
--   "all"  -> every cat in the bag (not placed; locked cats are kept), PenService.sellCats
-- The server checks the player stands at the booth (Config.Market.SellRange of its shopkeeper's spot).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local CarryService = require(script.Parent.CarryService)
local PenService = require(script.Parent.PenService)

local BoothService = {}

-- The shopkeeper's spot behind the sell booth's counter (MapKit), else the booth's pivot.
local function boothPoint(): Vector3?
	local map = workspace:FindFirstChild("Map")
	local market = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Market")
	local booth = market and market:FindFirstChild("SellBooth")
	if not booth or not booth:IsA("Model") then
		return nil
	end
	local spot = booth:FindFirstChild("NpcSpot")
	return if spot and spot:IsA("BasePart") then spot.Position else booth:GetPivot().Position
end

local function atBooth(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local at = boothPoint()
	if not root or not root:IsA("BasePart") or not at then
		return false
	end
	local d = Vector3.new(root.Position.X - at.X, 0, root.Position.Z - at.Z).Magnitude
	return d <= Config.Market.SellRange and math.abs(root.Position.Y - at.Y) < 15
end

local function heldCatId(player: Player): string?
	local character = player.Character
	if not character then
		return nil
	end
	for _, t in character:GetChildren() do
		local id = if t:IsA("Tool") then t:GetAttribute("CatId") else nil
		if type(id) == "string" then
			return id
		end
	end
	return nil
end

local function onSell(player: Player, rawMode: unknown)
	local mode = Validate.oneOf(rawMode, { "this", "all" })
	if not mode or not atBooth(player) then
		return
	end
	if mode == "this" then
		if CarryService.sellCarried(player) then
			return
		end
		local id = heldCatId(player)
		if id then
			PenService.sellCats(player, { id })
		else
			Notify.send(player, "SellHoldOne", nil, "info")
		end
		return
	end
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local ids: { string } = {}
	for id, cat in data.Cats do
		if not cat.Placed and not cat.Locked then
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		Notify.send(player, "SellBagEmpty", nil, "info")
		return
	end
	PenService.sellCats(player, ids)
end

function BoothService:Init()
	Guard.onEvent("SellAtBooth", Config.Market.SellRate, onSell)
end

return BoothService
