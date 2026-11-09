--!strict
-- Cat animation clips give finite, sensible joint angles (A6 rig, shared/CatAnims).
-- Run by scripts/check.luau (lune). Fails by raising an error.

local CatAnims = require("../src/shared/CatAnims")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL CatAnims: {message}`)
	end
end

local function finite(x: number): boolean
	return x == x and x ~= math.huge and x ~= -math.huge
end

-- every clip, over 6 seconds: finite numbers, angles inside +-1.6 rad, lift inside +-1 stud
for _, clip in CatAnims.Clips do
	check(CatAnims.has(clip), `{clip} exists`)
	for i = 0, 600 do
		local p = CatAnims.pose(clip, i * 0.01)
		for k, v in p :: any do
			check(finite(v), `{clip} {k} finite at {i}`)
			if k == "fxYaw" then
				check(v >= 0 and v < 2 * math.pi, `{clip} fxYaw one turn`)
			elseif k == "bodyY" then
				check(math.abs(v) <= 1, `{clip} bodyY within 1 stud`)
			else
				check(math.abs(v) <= 1.6, `{clip} {k} within 1.6 rad`)
			end
		end
	end
end

local function amplitude(clip: string, key: string): number
	local lo, hi = math.huge, -math.huge
	for i = 0, 400 do
		local v = (CatAnims.pose(clip, i * 0.01) :: any)[key]
		lo = math.min(lo, v)
		hi = math.max(hi, v)
	end
	return hi - lo
end

-- walk: diagonal legs move together, the two front legs move opposite
local w = CatAnims.pose("walk", 0.17)
check(w.legFL == w.legBR, "walk: FL and BR together")
check(w.legFL == -w.legFR, "walk: front legs opposite")
-- struggling is much wilder than standing
check(amplitude("struggle", "bodyRoll") > 4 * amplitude("idle", "bodyRoll"), "struggle wriggles more than idle")
check(amplitude("struggle", "tail1Yaw") > amplitude("idle", "tail1Yaw"), "struggle thrashes the tail")
-- sleeping lies low; carried front paws hang forward
check(CatAnims.pose("sleep", 1).bodyY < -0.4, "sleep lies low")
check(CatAnims.pose("carried", 1).legFL > 0, "carried front paws forward")
-- unknown clip falls back to idle, and a reused table is cleared
local reuse = CatAnims.pose("struggle", 0.3)
local again = CatAnims.pose("nope", 0.3, reuse)
check(again == reuse, "reuses the given table")
check(again.legFL == 0, "unknown clip -> idle (legs still)")

if failures > 0 then
	error(`CatAnims: {failures} failure(s)`)
end
print("PASS CatAnims")
