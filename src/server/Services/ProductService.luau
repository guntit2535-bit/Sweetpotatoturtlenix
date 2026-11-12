--!strict
-- Developer products (task 2.19, blueprint §13; Pet Storm Escape's ProductService). The one ProcessReceipt:
--   - player not here / data not loaded / unknown product -> NotProcessedYet (Roblox asks again later)
--   - a receipt already in data.ReceiptIds -> PurchaseGranted (never granted twice)
--   - otherwise the grant and the receipt id go into the save in the same change, the save is written, and
--     only then PurchaseGranted (a failed save -> NotProcessedYet; the retry finds the receipt and confirms)
-- Products (Config.Products.List): +20 pen slots in 3 price steps, 4 cash packs by income, a strength pack,
-- luck x3 15 min, server luck 15 min (announced), summon a Mythical cat, a starter pack (once).
-- `!buy <Key>` runs the same grant path with a fake receipt (ids are 0 until the developer makes them).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Bonus = require(Shared.Bonus)
local CatRules = require(Shared.CatRules)
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Rewards = require(Shared.Rewards)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local EventService = require(script.Parent.EventService)
local PenService = require(script.Parent.PenService)
local ToolService = require(script.Parent.ToolService)

local ProductService = {}

local function product(id: number): any
	if id == 0 then
		return nil
	end
	for _, p in Config.Products.List do
		if p.Id == id then
			return p
		end
	end
	return nil
end

local function byKey(key: string): any
	for _, p in Config.Products.List do
		if p.Key == key then
			return p
		end
	end
	return nil
end

-- What the product does to the save (no yields). Returns a toast name key and anything to do after the save.
local function apply(player: Player, p: any, d: any): (string, (() -> ())?)
	local now = os.time()
	if p.Kind == "Slots" then
		d.SlotBuys += 1
		d.PenSlots = math.min(Config.Pen.MaxSlots, d.PenSlots + Config.Products.SlotsStep)
		return "ProductSlots", nil
	elseif p.Kind == "Cash" then
		d.Money += Rewards.money({ Base = p.Base, Seconds = p.Seconds }, PenService.incomeRate(player))
		return "Product" .. p.Key, nil
	elseif p.Kind == "Strength" then
		local perSecond = CatRules.weightsGain(d.WeightsLevel) * Bonus.strength(BonusCtx.of(player, d))
		d.Strength += math.max(p.Base, perSecond * p.Seconds)
		return "ProductStrength", nil
	elseif p.Kind == "Luck3" then
		d.Boosts.Luck3 = math.max(now, d.Boosts.Luck3 or 0) + Config.Products.LuckSeconds
		return "ProductLuck3", nil
	elseif p.Kind == "ServerLuck" then
		return "ProductServerLuck", function()
			local current = workspace:GetAttribute("ServerLuckUntil")
			local base = if type(current) == "number" and current > now then current else now
			workspace:SetAttribute("ServerLuckUntil", base + Config.Products.LuckSeconds)
			Notify.all("ServerLuckOn", { name = player.DisplayName }, "event")
		end
	elseif p.Kind == "Summon" then
		return "ProductSummonMythical", function()
			EventService.summon("Mythical")
		end
	elseif p.Kind == "TrainBoost" then
		-- W6: the step is kept even if bought out of order (never lose a purchase); it never goes down
		local key = if p.Stat == "Weights" then "BoostWeights" else "BoostTread"
		d[key] = math.clamp(math.max(d[key] or 0, p.Step), 0, Config.TrainBoost.Steps)
		return if p.Stat == "Weights" then "ProductTrainW" else "ProductTrainT", nil
	elseif p.Kind == "Starter" then
		d.StarterBought = true
		d.Money += p.Money
		d.RodLevel = math.max(d.RodLevel, p.Rod)
		for _, t in p.Treats do
			d.Boosts[t] = math.max(now, d.Boosts[t] or 0) + Config.Treats.Seconds
		end
		return "ProductStarter", function()
			ToolService.refreshRod(player)
		end
	end
	return "Bought", nil
end

-- The grant path shared by ProcessReceipt and `!buy`.
local function grant(player: Player, p: any, receiptId: string): Enum.ProductPurchaseDecision
	local d = DataService.GetData(player)
	if not d then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(d.ReceiptIds, receiptId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local nameKey: string = "Bought"
	local after: (() -> ())? = nil
	DataService.Update(player, function(x)
		nameKey, after = apply(player, p, x)
		table.insert(x.ReceiptIds, receiptId)
		while #x.ReceiptIds > Config.Products.ReceiptsKept do
			table.remove(x.ReceiptIds, 1)
		end
	end)
	if not DataService.SaveAsync(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if after then
		after()
	end
	Notify.send(player, "PurchaseThanks", { nameKey = nameKey }, "good")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ProductService:Init()
	MarketplaceService.ProcessReceipt = function(info): Enum.ProductPurchaseDecision
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local p = product(info.ProductId)
		if not player or not p or not DataService.IsLoaded(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, result = pcall(grant, player, p, info.PurchaseId)
		if not ok then
			warn(`[Sweetpotato] ProductService: grant failed: {result}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return result
	end
	DebugService.register("buy", "!buy <ProductKey>  run a product's grant with a fake receipt", function(player, args)
		local p = byKey(args[1] or "")
		if not p then
			return "usage: !buy CashS (Slots1..3, CashS/M/L/XL, Strength, Luck3, ServerLuck, SummonMythical, Starter, TrainW1..6, TrainT1..6)"
		end
		local decision = grant(player, p, `debug_{os.clock()}`)
		local d = DataService.GetData(player)
		return `{p.Key}: {decision.Name} | money {d and Format.short(d.Money)} slots {d and d.PenSlots}`
	end)
end

return ProductService
