--!strict
-- W5 options for tools/sim/endgame.luau: each is the Config changes it makes (the run puts them back after).
local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local RB, R, P, C = Config.Rebirth, Config.Rods, Config.PenUpgrade, Config.Crates

-- crate prices: the small crates stay within reach early in a life, the big ones cost minutes of income
local function crates(k: number, perRebirth: number): { { any } }
	local base = { 40000, 2.5e6, 75e6, 900e6 } -- B: x20 / x100 / x500 / x1000 today's
	local out: { { any } } = { { C, "CostRebirth", perRebirth } }
	for i, cr in C.List do
		table.insert(out, { cr, "Cost", base[i] * k })
	end
	return out
end

local function opt(name: string, str: number, rods: number, pen: number, k: number): any
	local set: { { any } } = { { RB, "StrengthMult", str }, { R, "CostGrowth", rods }, { P, "CostGrowth", pen } }
	for _, s in crates(k, 3.4) do
		table.insert(set, s)
	end
	return { name = name, set = set }
end

return {
	opt("A faster (~44 h)", 3.85, 5, 12, 0.5),
	opt("B (~53 h)", 3.8, 5.5, 14, 1),
	opt("C slower (~64 h)", 3.75, 6, 16, 3),
}
