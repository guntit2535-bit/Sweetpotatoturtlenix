--!strict
-- Mutations (task 2.9): rates at luck 1 and 2, no mutations above Legendary, money multipliers.
-- Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Mutation = Shared.require("Mutation")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Mutation: {message}`)
	end
end

local function rates(tier: number, luck: number): { [string]: number }
	local n = 100000
	local out: { [string]: number } = {}
	for i = 0, n - 1 do
		local m = Mutation.roll(tier, luck, (i + 0.5) / n)
		out[m] = (out[m] or 0) + 1
	end
	for k, v in out do
		out[k] = v / n * 100
	end
	return out
end

local r1 = rates(1, 1)
check(math.abs((r1.Gold or 0) - 4) < 0.05 and math.abs((r1.Rainbow or 0) - 1.5) < 0.05 and math.abs((r1.Glow or 0) - 0.5) < 0.05, "luck 1: 4 / 1.5 / 0.5 %")
local r2 = rates(4, 2)
check(math.abs((r2.Gold or 0) - 8) < 0.05 and math.abs((r2.Glow or 0) - 1) < 0.05, "luck 2 doubles the chances")
local r5 = rates(5, 10)
check((r5[""] or 0) == 100, "no mutations for Mythical")
check(rates(6, 10)[""] == 100, "no mutations for Secret")
check(Mutation.money("") == 1 and Mutation.money(nil) == 1, "none = x1")
check(Mutation.money("Gold") == 2 and Mutation.money("Rainbow") == 5 and Mutation.money("Glow") == 10, "x2 / x5 / x10")
print(string.format("  luck 1: Gold %.2f%% Rainbow %.2f%% Glow %.2f%%", r1.Gold or 0, r1.Rainbow or 0, r1.Glow or 0))

if failures > 0 then
	error(`Mutation: {failures} failure(s)`)
end
print("PASS Mutation")
