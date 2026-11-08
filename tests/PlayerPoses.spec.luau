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
check(r.rx > 1 and r.rx < 1.6, "reel rod arm is in front")
check(not PlayerPoses.has("dance"), "unknown pose")

check(PlayerPoses.kindOf("Kitty", 12) == "carry", "carrying wins over fishing")
check(PlayerPoses.kindOf(nil, 12) == "reel", "fishing reels")
check(PlayerPoses.kindOf(nil, nil) == nil, "no pose")

if failures > 0 then
	error(`PlayerPoses: {failures} failure(s)`)
end
print("PlayerPoses: ok")
