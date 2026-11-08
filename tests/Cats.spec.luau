--!strict
-- The 400 cat designs and the cat / economy rules (tasks 1.5 / 1.6). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Cats = Shared.require("Cats")
local CatRules = Shared.require("CatRules")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Cats: {message}`)
	end
end

-- 400 designs with the blueprint counts, unique ids, names and looks
check(#Cats.List == 400, `400 designs (got {#Cats.List})`)
local wanted = { 150, 110, 70, 45, 20, 5 }
for tier, n in wanted do
	check(#Cats.ByTier[tier] == n, `tier {tier}: {n} designs`)
	check(Config.Tiers[tier].Count == n, `Config tier {tier} count`)
end
local names, looks = {}, {}
for _, cat in Cats.List do
	check(Cats.ById[cat.Id] == cat, `{cat.Id} indexed`)
	check(string.match(cat.Id, "^cat%d%d%d$") ~= nil, `{cat.Id} id format`)
	check(type(cat.Name) == "string" and #cat.Name > 0, `{cat.Id} has a name`)
	check(not names[cat.Name], `name "{cat.Name}" used twice`)
	names[cat.Name] = true
	local l = cat.Look
	local key = table.concat({ l.shape, l.fur, l.second, l.pattern or "", l.patternColor or "", l.accessory or "", l.accessoryColor or "", l.eyes or "" }, "|")
	check(not looks[key], `{cat.Id} look repeats another`)
	looks[key] = true
	check(table.find({ "Loaf", "Slim", "Fluffy" }, l.shape) ~= nil, `{cat.Id} shape`)
	check(string.match(l.fur, "^%x%x%x%x%x%x$") ~= nil, `{cat.Id} fur hex`)
end
-- higher tiers carry their effects
check(Cats.ById[Cats.ByTier[5][1]].Look.accessory == "wings", "Mythical has wings")
check(Cats.ById[Cats.ByTier[6][1]].Look.aura == "rainbow", "Secret has the rainbow aura")
check(Cats.ById[Cats.ByTier[1][1]].Look.aura == nil, "Basic has no aura")

-- weights stay in their tier's range; heavier = more income; sizes
for tier, t in Config.Tiers do
	for i = 0, 100 do
		local kg = CatRules.rollKg(tier, i / 100)
		check(kg >= t.MinKg and kg <= t.MaxKg, `tier {tier} kg {kg} in range`)
	end
	check(CatRules.income(tier, t.MaxKg) > CatRules.income(tier, t.MinKg), `tier {tier}: heavier earns more`)
end
local T = Config.Tiers
check(CatRules.size(1, 10) == 1 and CatRules.size(4, 1e7) == 1, "Basic-Legendary one size")
check(math.abs(CatRules.size(5, T[5].MinKg) - 1.3) < 1e-9 and math.abs(CatRules.size(5, T[5].MaxKg) - 2) < 1e-9, "Mythical 1.3-2x")
check(math.abs(CatRules.size(6, T[6].MinKg) - 3) < 1e-9 and math.abs(CatRules.size(6, T[6].MaxKg) - 6) < 1e-9, "Secret 3-6x")
-- R4: a rebirthed player's heavier cat keeps its size (the rebirth factor is taken out)
local mid = T[6].MinKg * (T[6].MaxKg / T[6].MinKg) ^ 0.5
check(math.abs(CatRules.size(6, mid * Config.Rebirth.KgMult ^ 7) - CatRules.size(6, mid)) < 1e-6, "Secret size ignores the rebirth factor")
-- R4: weights per player, the 99 Sx cap
check(CatRules.kgFor(50, 0) == 50, "no rebirth: base kg")
check(math.abs(CatRules.kgFor(1e6, 2) - 1e6 * Config.Rebirth.KgMult ^ 2) < 1, "x KgMult per rebirth")
check(CatRules.kgFor(T[6].MaxKg, 25) <= Config.Economy.Max and CatRules.kgFor(T[6].MaxKg, 25) > Config.Economy.Max * 0.9, "top Secret at 25 rebirths is about 99 Sx")
check(CatRules.cap(1e30) == Config.Economy.Max, "cap at 99 Sx")
check(CatRules.income(1, 100) > CatRules.income(1, 1) and CatRules.income(1, 100) < 100 * CatRules.income(1, 1), "income grows slower than weight")
check(math.abs((CatRules.weightsCost(5, 2) :: number) - (CatRules.weightsCost(5, 0) :: number) * Config.Weights.CostRebirth ^ 2) <= Config.Weights.CostRebirth ^ 2, "weights cost x CostRebirth per rebirth")
check(CatRules.walkSpeed(1000, nil, 3) < CatRules.walkSpeed(1000, nil, 0), "walking counts Speed relative to the current life")
check(CatRules.strengthNeeded(50) == 50, "a 50 kg cat needs 50 Strength")

-- zone odds pick only listed tiers
local seen = {}
for i = 0, 999 do
	seen[CatRules.pickTier(Config.World.Zones[1].Odds, i / 1000)] = true
end
check(seen[1] and seen[2] and not seen[3], "Backyard gives Basic and Rare only")

-- training: gains grow, costs grow, nothing past the top level
for level = 1, Config.Weights.Levels - 1 do
	check(CatRules.weightsGain(level + 1) > CatRules.weightsGain(level), "weights gain grows")
	local a, b = CatRules.weightsCost(level), CatRules.weightsCost(level + 1)
	check(a ~= nil and (b == nil or b > a), "weights cost grows")
end
check(CatRules.weightsCost(Config.Weights.Levels) == nil, "no level past the top")
check(CatRules.walkSpeed(0) == Config.Walk.Base, "walk speed starts at the base")
check(CatRules.walkSpeed(1e12) == Config.Walk.Max, "walk speed capped")
check(CatRules.walkSpeed(100, 2) > CatRules.walkSpeed(100), "like buff makes you faster")
check(CatRules.zoneOpen(1, 1, 0), "Backyard always open")
local g2 = Config.World.Zones[2].Strength
check(not CatRules.zoneOpen(2, g2 - 1, 0) and CatRules.zoneOpen(2, g2, 0) and CatRules.zoneOpen(2, 1, 1), "Market: its Strength or 1 rebirth")
check(not CatRules.zoneOpen(3, Config.World.Zones[3].Strength, 1) and CatRules.zoneOpen(3, Config.World.Zones[3].Strength * Config.Rebirth.KgMult, 1), "gates x KgMult per rebirth (R4)")

if failures > 0 then
	error(`Cats: {failures} failure(s)`)
end
print(`PASS Cats ({#Cats.List} designs)`)
