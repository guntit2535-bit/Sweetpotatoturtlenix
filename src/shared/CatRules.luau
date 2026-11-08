--!strict
-- Rules for cats (task 1.5) and the economy formulas (task 1.6). Pure: random numbers are passed in
-- (the server rolls them), so tests/CatRules.spec.luau and tools/sim/economy.luau use the same maths.
--
--   CatRules.rollKg(tier, u)            weight in the tier's range (u in [0, 1))
--   CatRules.income(tier, kg)           money per second in the pen
--   CatRules.size(tier, kg)             model size multiplier (Mythical 1.3-2x, Secret 3-6x)
--   CatRules.pickTier(odds, u)          tier index from a zone's odds table
--   CatRules.weightsGain(level) / weightsCost(level), treadGain / treadCost, walkSpeed(speed, buff)
--   CatRules.zoneOpen(zone, strength, rebirths)

local Config = require(script.Parent.Config)

local CatRules = {}

function CatRules.tierIndex(key: string): number?
	for i, t in Config.Tiers do
		if t.Key == key then
			return i
		end
	end
	return nil
end

-- Weight in kg: heavy cats of a tier are rarer (skew > 1). Rounded to 0.1 kg below 100 kg, whole above.
function CatRules.rollKg(tier: number, u: number, skew: number?): number
	local t = Config.Tiers[tier]
	local s = skew or Config.KgSkew
	local kg = t.MinKg + (t.MaxKg - t.MinKg) * math.clamp(u, 0, 1) ^ s
	if kg < 100 then
		return math.max(t.MinKg, math.floor(kg * 10 + 0.5) / 10)
	end
	return math.floor(kg + 0.5)
end

-- Strength needed to reel the cat in: its weight (blueprint §2: a 50 kg cat needs 50 Strength).
function CatRules.strengthNeeded(kg: number): number
	return kg
end

-- Money per second in the pen (before rebirth / pass / mutation multipliers).
function CatRules.income(tier: number, kg: number): number
	return Config.Tiers[tier].Rate * kg
end

function CatRules.sellPrice(tier: number, kg: number): number
	return math.floor(CatRules.income(tier, kg) * Config.Economy.SellSeconds)
end

function CatRules.size(tier: number, kg: number): number
	local t = Config.Tiers[tier] :: any
	if not t.SizeMin then
		return 1
	end
	local f = math.clamp((kg - t.MinKg) / (t.MaxKg - t.MinKg), 0, 1)
	return t.SizeMin + (t.SizeMax - t.SizeMin) * f
end

-- Tier index from an odds table { Basic = 90, Rare = 10 } and u in [0, 1).
function CatRules.pickTier(odds: { [string]: number }, u: number): number
	local total = 0
	for i, t in Config.Tiers do
		total += odds[t.Key] or 0
		local _ = i
	end
	local at = math.clamp(u, 0, 0.999999) * total
	for i, t in Config.Tiers do
		at -= odds[t.Key] or 0
		if at < 0 then
			return i
		end
	end
	return 1
end

-- Training ------------------------------------------------------------------------------------------

function CatRules.weightsGain(level: number): number
	local w = Config.Weights
	return w.Gain * w.Growth ^ (level - 1)
end

-- Money to go from `level` to level + 1 (nil at the top).
function CatRules.weightsCost(level: number): number?
	local w = Config.Weights
	if level >= w.Levels then
		return nil
	end
	return math.floor(w.Cost * w.CostGrowth ^ (level - 1))
end

function CatRules.treadGain(level: number): number
	local t = Config.Treadmill
	return t.Gain * t.Growth ^ (level - 1)
end

function CatRules.treadCost(level: number): number?
	local t = Config.Treadmill
	if level >= t.Levels then
		return nil
	end
	return math.floor(t.Cost * t.CostGrowth ^ (level - 1))
end

-- Walk speed (studs/s) from the Speed stat; `buff` multiplies the part above the base (the like buff x2).
function CatRules.walkSpeed(speed: number, buff: number?): number
	local w = Config.Walk
	local bonus = w.Bonus * math.log(1 + math.max(0, speed) / w.Scale)
	return math.min(w.Max, w.Base + bonus * (buff or 1))
end

-- Rebirth multipliers (milestone 2): x1.5 money and strength per rebirth.
function CatRules.rebirthMoney(rebirths: number): number
	return Config.Rebirth.MoneyMult ^ rebirths
end

function CatRules.rebirthStrength(rebirths: number): number
	return Config.Rebirth.StrengthMult ^ rebirths
end

-- A zone opens with enough Strength or enough rebirths (blueprint §1).
function CatRules.zoneOpen(zone: number, strength: number, rebirths: number): boolean
	local z = Config.World.Zones[zone]
	return strength >= z.Strength or (z.Rebirths > 0 and rebirths >= z.Rebirths) or z.Strength <= 0
end

return CatRules
