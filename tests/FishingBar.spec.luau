--!strict
-- The fishing bar (task 1.11): a good player catches a Basic cat, an idle player loses it, rarer cats are
-- harder, the same seed gives the same cat path (server and client agree). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local FishingBar = Shared.require("FishingBar")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL FishingBar: {message}`)
	end
end

local DT = 1 / 15

-- A player who holds whenever the zone is below the cat (a decent player).
local function play(tier: number, seed: number, skilled: boolean, rod: number?): (string?, number)
	local s = FishingBar.new(seed, FishingBar.params(tier, rod))
	for i = 1, 15 * 120 do
		local hold = if skilled then (s.zone < s.cat + 0.02 or s.vel < -0.4) else false
		local r = FishingBar.step(s, DT, hold)
		if r then
			return r, i * DT
		end
	end
	return nil, 120
end

-- skilled players catch Basic cats nearly always; idle players always lose
local wins, timeSum, idleLost = 0, 0, 0
for seed = 1, 50 do
	local r, t = play(1, seed, true)
	if r == "win" then
		wins += 1
		timeSum += t
	end
	if play(1, seed, false) == "lose" then
		idleLost += 1
	end
end
check(wins >= 45, `skilled player catches Basic cats ({wins}/50)`)
check(idleLost >= 45, `a player who never holds loses ({idleLost}/50)`)
print(string.format("  Basic: %d/50 caught, %.1f s on average", wins, timeSum / math.max(1, wins)))

-- rarer = harder for the same player
local function rate(tier: number, rod: number?): number
	local n = 0
	for seed = 1, 60 do
		if play(tier, seed, true, rod) == "win" then
			n += 1
		end
	end
	return n
end
local r1, r6 = rate(1), rate(6)
print(string.format("  skilled win rate: Basic %d/60, Secret %d/60, Secret with rod 25 %d/60", r1, r6, rate(6, 25)))
check(r6 < r1, "Secret harder than Basic")
check(rate(6, 25) >= r6, "a better rod helps")

-- params: smaller zone and faster cat for rarer tiers
for tier = 1, 5 do
	local a, b = FishingBar.params(tier), FishingBar.params(tier + 1)
	check(b.zone < a.zone and b.catSpeed > a.catSpeed, `tier {tier + 1} harder than {tier}`)
end

-- determinism + snapshots: a copy that applies a snapshot continues exactly the same
local a = FishingBar.new(777, FishingBar.params(3))
for _ = 1, 40 do
	FishingBar.step(a, DT, true)
end
local b = FishingBar.new(1, FishingBar.params(3))
FishingBar.apply(b, FishingBar.snapshot(a))
for i = 1, 60 do
	local hold = i % 3 == 0
	FishingBar.step(a, DT, hold)
	FishingBar.step(b, DT, hold)
end
check(a.cat == b.cat and a.zone == b.zone and a.meter == b.meter, "snapshot continues identically")

-- values stay inside the bar
local s = FishingBar.new(5, FishingBar.params(6))
for i = 1, 2000 do
	FishingBar.step(s, DT, i % 7 < 4)
	check(s.zone >= 0 and s.zone <= 1 and s.cat >= 0 and s.cat <= 1 and s.meter >= 0 and s.meter <= 1, "inside the bar")
end

if failures > 0 then
	error(`FishingBar: {failures} failure(s)`)
end
print("PASS FishingBar")
