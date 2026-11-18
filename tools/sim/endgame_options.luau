--!strict
-- Options for tools/sim/endgame.luau: each is the Config changes it makes (the run puts them back after).
-- 2026-11-18 (client, revision list 6): 50 weights / treadmill levels and 50 rods, dearer at the end; heavier Secret
-- cats (5B-100B kg); fixed crate prices and an 8th crate with Secret (Legendary 40 / Mythical 50 / Secret 10).
local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local _W, _Rd, _C, _N = Config.Weights, Config.Rods, Config.Crates, Config.RebirthNeed

local CRATES = {
	{ Key = "Paper", Cost = 40e3, Color = "e8d6ab", Odds = { Basic = 75, Rare = 22, Epic = 3 } },
	{ Key = "Wood", Cost = 600e3, Color = "c98a4a", Odds = { Basic = 50, Rare = 38, Epic = 11, Legendary = 1 } },
	{ Key = "Iron", Cost = 3e8, Color = "b8c2d6", Odds = { Basic = 25, Rare = 45, Epic = 26, Legendary = 4 } },
	{ Key = "Gold", Cost = 3e10, Color = "f5bf2e", Odds = { Rare = 50, Epic = 38, Legendary = 12 } },
	{ Key = "Ruby", Cost = 3e12, Color = "ff4d6d", Odds = { Rare = 25, Epic = 50, Legendary = 24.7, Mythical = 0.3 } },
	{ Key = "Diamond", Cost = 3e13, Color = "7fe3ff", Odds = { Epic = 55, Legendary = 44.3, Mythical = 0.7 } },
	{ Key = "Cosmic", Cost = 3e15, Color = "6b4cff", Odds = { Epic = 35, Legendary = 63, Mythical = 2 } },
	{ Key = "Galaxy", Cost = 1e18, Color = "18c9b9", Odds = { Legendary = 40, Mythical = 50, Secret = 10 } },
}

-- w1 / w2: weights price growth for levels 1-25 / 26-50; g2: Strength growth for 26-50 (1.6 before); need: rebirth
-- need growth (4 now); r1 / r2: rod price growth for rods 2-25 / 26-50
local function opt(name: string, w1: number, w2: number, g2: number, need: number, r1: number, r2: number, sm: number?, crates: any?): any
	return {
		name = name,
		set = {
			{ Config.Rebirth, "StrengthMult", sm or 3.8 },
			{ W, "Levels", 50 },
			{ W, "Split", 25 },
			{ W, "Growth2", g2 },
			{ W, "CostGrowth", w1 },
			{ W, "CostGrowth2", w2 },
			{ W, "CostRebirth", 1 },
			{ Rd, "Levels", 50 },
			{ Rd, "Split", 24 },
			{ Rd, "CostGrowth", r1 },
			{ Rd, "CostGrowth2", r2 },
			{ N, "Growth", need },
			{ Config.Tiers[6], "MinKg", 5e9 },
			{ Config.Tiers[6], "MaxKg", 1e11 },
			{ C, "List", crates or CRATES },
			{ C, "CostRebirth", 1 },
		},
	}
end

-- (applied 2026-11-18: option W, now the Config; the sweep was T, U, V, W, X)
return {}
