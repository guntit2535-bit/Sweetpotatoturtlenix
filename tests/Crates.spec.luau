--!strict
-- Crates (task 2.6): odds as in the blueprint, sum to 100, no Secret, and rolls follow the odds.
-- Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Crates = Shared.require("Crates")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Crates: {message}`)
	end
end

local blueprint = {
	Paper = { Basic = 75, Rare = 22, Epic = 3 },
	Wood = { Basic = 40, Rare = 40, Epic = 17, Legendary = 3 },
	Gold = { Rare = 50, Epic = 38, Legendary = 12 },
	Diamond = { Epic = 62, Legendary = 37.5, Mythical = 0.5 },
}
check(#Config.Crates.List == 4, "4 crates")
for key, want in blueprint do
	local c = Crates.get(key)
	check(c ~= nil, `{key} exists`)
	if c then
		local sum = 0
		for tier, p in c.Odds do
			sum += p
			check(want[tier] == p, `{key} {tier} = {want[tier]}%`)
			check(tier ~= "Secret", `{key} has no Secret`)
		end
		check(math.abs(sum - 100) < 1e-9, `{key} odds sum to 100`)
	end
	-- 20,000 even rolls land on the odds within 1%
	local counts: { [number]: number } = {}
	local n = 20000
	for i = 0, n - 1 do
		local tier = Crates.roll(key, (i + 0.5) / n)
		counts[tier] = (counts[tier] or 0) + 1
	end
	for _, o in Crates.odds(key) do
		local got = (counts[o.tier] or 0) / n * 100
		check(math.abs(got - o.percent) < 1, `{key} tier {o.tier}: {got}% vs {o.percent}%`)
	end
end

if failures > 0 then
	error(`Crates: {failures} failure(s)`)
end
print("PASS Crates")
