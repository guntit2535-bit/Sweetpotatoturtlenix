--!strict
-- Player arm poses (task 2.22, shared/PlayerPoses) give finite angles in a sane range.
-- Run by scripts/check.luau (lune). Fails by raising an error.

local PlayerPoses = require("../src/shared/PlayerPoses")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL PlayerPoses: {message}`)
	end
end

local function finite(x: number): boolean
	return x == x and x ~= math.huge and x ~= -math.huge
end

for _, kind in PlayerPoses.Kinds do
	check(PlayerPoses.has(kind), `{kind} exists`)
	for i = 0, 600 do
		local a = PlayerPoses.arms(kind, i * 0.01)
		for k, v in a :: any do
			check(finite(v), `{kind} {k} finite at {i}`)
			check(math.abs(v) <= math.pi, `{kind} {k} within pi`)
		end
	end
end

-- carry lifts both arms over the head; reel holds the rod arm out in front
local c = PlayerPoses.arms("carry", 1.3)
check(c.rx > 2.5 and c.lx > 2.5, "carry arms are up")
local r = PlayerPoses.arms("reel", 0.7)
check(r.rx > 0.3 and r.rx < 1.6 and (r.re or 0) > 0.8, "reel rod arm in front, elbow bent")
check(r.crank ~= nil, "reel turns a crank (V2)")
check(not PlayerPoses.has("dance"), "unknown pose")

-- R6: the curl bends the elbows and the arms take turns (one up while the other is down)
local up = PlayerPoses.arms("curl", PlayerPoses.CurlRep * 0.5)
check(up.re ~= nil and up.le ~= nil, "curl bends the elbows")
check((up.re :: number) > 2 and (up.le :: number) < 0.3, "right arm up while the left is down")
local later = PlayerPoses.arms("curl", PlayerPoses.CurlRep)
check((later.le :: number) > 2 and (later.re :: number) < 0.3, "then the left arm is up")
check(PlayerPoses.arms("carry", 1).re == nil, "carry leaves the elbows alone")
check(PlayerPoses.kindOf(nil, nil, "weights") == "curl", "lifting curls")
check(PlayerPoses.kindOf(nil, nil, "treadmill") == nil, "the treadmill runs (no pose)")
check(PlayerPoses.kindOf(nil, 3, "weights") == "reel", "fishing wins over lifting")

check(PlayerPoses.kindOf("Kitty", 12) == "carry", "carrying wins over fishing")
check(PlayerPoses.kindOf(nil, 12) == "reel", "fishing reels")
check(PlayerPoses.kindOf(nil, nil) == nil, "no pose")

if failures > 0 then
	error(`PlayerPoses: {failures} failure(s)`)
end
print("PlayerPoses: ok")
