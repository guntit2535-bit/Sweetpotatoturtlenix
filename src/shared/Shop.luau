--!strict
-- Prices of the in-game money shop (tasks 2.1 - 2.5), shared so the window shows exactly what the server
-- charges. Pure: tested by tests/Shop.spec.luau.
--   Shop.rodCost(level)          money for rod `level` (nil past the top; rod 1 is free)
--   Shop.shoeCost(pair)          money for shoe pair `pair` (1 .. 8)
--   Shop.penCost(buys)           money for the next pen expansion after `buys` expansions
--   Shop.treatCost(key, income)  money for a 10-minute treat at this income per second
--   Shop.rodMaterial(level)      material index 1 .. 5 and the number 1 .. 5 inside it

local Config = require(script.Parent.Config)

local Shop = {}

function Shop.rodCost(level: number): number?
	local r = Config.Rods
	if level < 2 or level > r.Levels then
		return nil
	end
	return math.floor(r.Cost * r.CostGrowth ^ (level - 2))
end

function Shop.rodMaterial(level: number): (number, number)
	local per = Config.Rods.PerMaterial
	return math.floor((level - 1) / per) + 1, (level - 1) % per + 1
end

function Shop.shoeCost(pair: number): number?
	local s = Config.Shoes.List[pair]
	return if s then s.Cost else nil
end

function Shop.penCost(buys: number): number
	local p = Config.PenUpgrade
	return math.floor(p.Cost * p.CostGrowth ^ buys)
end

function Shop.treatCost(key: string, income: number): number?
	for _, t in Config.Treats.List do
		if t.Key == key then
			return math.floor(math.max(t.Base, income * t.IncomeSeconds))
		end
	end
	return nil
end

return Shop
