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

-- X3 (revision 4 item 9): 7 crates, prices rising, odds as agreed 2026-11-15
local blueprint = {
	Paper = { Basic = 75, Rare = 22, Epic = 3 },
	Wood = { Basic = 50, Rare = 38, Epic = 11, Legendary = 1 },
	Iron = { Basic = 25, Rare = 45, Epic = 26, Legendary = 4 },
	Gold = { Rare = 50, Epic = 38, Legendary = 12 },
	Ruby = { Rare = 25, Epic = 50, Legendary = 24.7, Mythical = 0.3 },
	Diamond = { Epic = 55, Legendary = 44.3, Mythical = 0.7 },
	Cosmic = { Epic = 35, Legendary = 63, Mythical = 2 },
}
check(#Config.Crates.List == 7, "7 crates")
for i = 2, #Config.Crates.List do
	check(Config.Crates.List[i].Cost > Config.Crates.List[i - 1].Cost, `crate {i} dearer than crate {i - 1}`)
end
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
