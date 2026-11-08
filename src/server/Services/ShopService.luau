--!strict
-- The in-game money shop (tasks 2.1 - 2.5). BuyItem(category, id):
--   "Rod", level   -> the next rod only (RodLevel + 1); the held rod changes colour (ToolService)
--   "Shoes", pair  -> the next pair only (Config.Shoes.Enabled)
--   "Pen", 0       -> +Config.PenUpgrade.Step slots up to Config.Pen.MaxSlots
--   "Treat", key   -> Luck / Money / Easy for Config.Treats.Seconds (added to what is left)
-- Prices come from shared/Shop, so the window shows what is charged. Crates are CrateService (2.6).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Shop = require(Shared.Shop)
local Validate = require(Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local ToolService = require(script.Parent.ToolService)

local ShopService = {}

local function pay(player: Player, cost: number): boolean
	if DataService.SpendMoney(player, cost) then
		return true
	end
	Notify.send(player, "NotEnoughMoney", { cost = Format.short(cost) }, "bad")
	return false
end

local function onBuy(player: Player, rawCategory: unknown, rawId: unknown)
	local category = Validate.oneOf(rawCategory, { "Rod", "Shoes", "Pen", "Treat" })
	local data = DataService.GetData(player)
	if not category or not data then
		return
	end
	if category == "Rod" then
		local level = Validate.integer(rawId, 2, Config.Rods.Levels)
		if not level or level ~= data.RodLevel + 1 then
			return
		end
		local cost = Shop.rodCost(level) :: number
		if pay(player, cost) then
			DataService.Update(player, function(d)
				d.RodLevel = level :: number
			end)
			ToolService.refreshRod(player)
			local m, n = Shop.rodMaterial(level)
			Notify.send(player, "Bought", { nameKey = "RodName", nameVars = { materialKey = "Mat" .. Config.Rods.Materials[m], n = n } }, "good")
		end
	elseif category == "Shoes" then
		local pair = Validate.integer(rawId, 1, #Config.Shoes.List)
		if not Config.Shoes.Enabled or not pair or pair ~= data.Shoes + 1 then
			return
		end
		if pay(player, Shop.shoeCost(pair) :: number) then
			DataService.Update(player, function(d)
				d.Shoes = pair :: number
			end)
			Notify.send(player, "Bought", { nameKey = "Shoe" .. Config.Shoes.List[pair].Key }, "good")
		end
	elseif category == "Pen" then
		if data.PenSlots >= Config.Pen.MaxSlots then
			Notify.send(player, "PenMax", nil, "info")
			return
		end
		if pay(player, Shop.penCost(data.PenBuys)) then
			DataService.Update(player, function(d)
				d.PenBuys += 1
				d.PenSlots = math.min(Config.Pen.MaxSlots, d.PenSlots + Config.PenUpgrade.Step)
			end)
			Notify.send(player, "Bought", { nameKey = "PenItem", nameVars = { n = Config.PenUpgrade.Step } }, "good")
		end
	elseif category == "Treat" then
		local key = Validate.oneOf(rawId, { "Luck", "Money", "Easy" })
		if not key then
			return
		end
		local income = player:GetAttribute("Income")
		local cost = Shop.treatCost(key, if type(income) == "number" then income else 0) :: number
		if pay(player, cost) then
			local now = os.time()
			DataService.Update(player, function(d)
				d.Boosts[key] = math.max(now, d.Boosts[key] or 0) + Config.Treats.Seconds
			end)
			for _, t in Config.Treats.List do
				if t.Key == key then
					Notify.send(player, "Bought", { nameKey = "Treat" .. t.Name }, "good")
				end
			end
		end
	end
end

function ShopService:Init()
	Guard.onEvent("BuyItem", Config.Shop.BuyRate, onBuy)
end

return ShopService
