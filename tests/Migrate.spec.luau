--!strict
-- R4 save conversion (src/shared/Migrate): old saves move onto the 99 Sx scale once, nothing is lost.
-- Run by scripts/check.luau (lune). Fails by raising an error.

local Shared = require("./lib/Shared")
local Config = Shared.require("Config")
local CatRules = Shared.require("CatRules")
local Cats = Shared.require("Cats")
local DataTemplate = Shared.require("DataTemplate")
local Migrate = Shared.require("Migrate")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Migrate: {message}`)
	end
end
local function copy(t: any): any
	local out = {}
	for k, v in t do
		out[k] = if type(v) == "table" then copy(v) else v
	end
	return out
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) <= math.max(1e-6, math.abs(b) * 1e-6)
end

-- Strength follows the gates
check(near(Migrate.mapStrength(1), 1) and near(Migrate.mapStrength(10), 100), "gate anchors 1 and 10")
check(near(Migrate.mapStrength(60), 1e4) and near(Migrate.mapStrength(1500), 1e7), "gate anchors 60 and 1500")
check(Migrate.mapStrength(30) > 100 and Migrate.mapStrength(30) < 1e4, "between anchors")
check(Migrate.mapStrength(3000) > 1e7, "above the last anchor keeps growing")

-- cats keep their place in the tier
local t1 = Config.Tiers[1]
check(near(Migrate.mapKg(1, 1), t1.MinKg) and near(Migrate.mapKg(1, 10), t1.MaxKg), "Basic ends map to the new ends")
check(near(Migrate.mapKg(6, 50000), Config.Tiers[6].MaxKg), "Secret top maps to the new top")

-- a whole save
local data = copy(DataTemplate.Template)
data.EconVersion = 0
data.Strength = 60
data.Speed = 100
data.Money = 12345
local kind = Cats.ByTier[2][1]
data.Cats.k1 = { Kind = kind, Kg = 60, Locked = true, Got = 1, Mutation = "Gold" }
check(Migrate.econ(data) == true, "converts an old save")
check(near(data.Strength, 1e4), "Strength 60 -> 10K (the old Forest gate -> the new one)")
check(data.Money == 12345, "money kept")
check(near(data.Speed, 100 * Config.Walk.Scale / 10), "Speed scaled to keep the walk speed")
check(near(CatRules.walkSpeed(data.Speed), Config.Walk.Base + Config.Walk.Bonus * math.log(1 + 100 / 10)), "same walk speed as before (the old formula at Speed 100)")
check(near(data.Cats.k1.Kg, Config.Tiers[2].MaxKg) and data.Cats.k1.Locked and data.Cats.k1.Mutation == "Gold", "cat kept, top of Rare")
check(data.EconVersion == Config.Data.EconVersion, "version set")
check(Migrate.econ(data) == false and near(data.Strength, 1e4), "runs only once")

-- rebirths: the player's world is heavier
local d2 = copy(DataTemplate.Template)
d2.EconVersion = 0
d2.Rebirths = 2
d2.Strength = 10
Migrate.econ(d2)
check(near(d2.Strength, 100 * Config.Rebirth.KgMult ^ 2), "x KgMult per rebirth")

-- V4: the tutorial step of a save that has none yet
local fresh = copy(DataTemplate.Template)
check(Migrate.tutorial(fresh) and fresh.TutorialStep == 1, "a new player starts the tutorial")
check(not Migrate.tutorial(fresh), "decided once")
local veteran = copy(DataTemplate.Template)
veteran.NextCatId = 5
check(Migrate.tutorial(veteran) and veteran.TutorialStep == Config.Tutorial.Done, "an old save has it done")
local caught = copy(DataTemplate.Template)
caught.Stats.Caught = 2
Migrate.tutorial(caught)
check(caught.TutorialStep == Config.Tutorial.Done, "anyone who caught a cat has it done")

-- the developer's reset of every tester (Config.Data.ResetEpoch)
local tester = copy(DataTemplate.Template)
tester.Money = 5e9
tester.Rebirths = 4
tester.NextCatId = 9
tester.Cats = { k1 = { Kind = "cat001", Kg = 5, Mutation = "", Locked = false } }
tester.ReceiptIds = { "r1", "r2" }
tester.BoostWeights = 3
tester.TutorialStep = Config.Tutorial.Done
local same = tester
check(Migrate.reset(tester, DataTemplate.Template), "an old save is reset")
check(tester == same, "in place (the same table)")
check(tester.Money == DataTemplate.Template.Money and tester.Rebirths == 0 and next(tester.Cats) == nil, "money, rebirths, cats back to new")
check(tester.BoostWeights == 0 and tester.TutorialStep == 0 and tester.NextCatId == 1, "boosts and tutorial back to new")
check(#tester.ReceiptIds == 2 and tester.ReceiptIds[1] == "r1", "the receipts are kept")
check(tester.ResetEpoch == Config.Data.ResetEpoch and tester.EconVersion == Config.Data.EconVersion, "marked: epoch and economy version")
check(tester.Settings ~= DataTemplate.Template.Settings and tester.Cats ~= DataTemplate.Template.Cats, "nested tables are copies, not the template's own")
check(not Migrate.reset(tester, DataTemplate.Template), "only once per epoch")
Migrate.tutorial(tester)
check(tester.TutorialStep == 1, "a reset player starts the tutorial")

if failures > 0 then
	error(`Migrate: {failures} failure(s)`)
end
print("PASS Migrate")
