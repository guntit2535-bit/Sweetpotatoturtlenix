--!strict
-- The save template only holds savable values, and sanitize repairs broken saves without losing
-- valid progress (task 1.2). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local DataTemplate = Shared.require("DataTemplate")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL DataTemplate: {message}`)
	end
end

-- 1. only strings, numbers, booleans and tables; arrays without gaps; no mixed tables
local function walk(value: any, path: string)
	local t = type(value)
	check(t == "string" or t == "number" or t == "boolean" or t == "table", `{path} has type {t}`)
	if t ~= "table" then
		return
	end
	local count, maxIndex, stringKeys = 0, 0, 0
	for k, v in value do
		count += 1
		if type(k) == "number" then
			maxIndex = math.max(maxIndex, k)
		else
			check(type(k) == "string", `{path} key type`)
			stringKeys += 1
		end
		walk(v, `{path}.{tostring(k)}`)
	end
	check(not (stringKeys > 0 and maxIndex > 0), `{path} is a mixed table`)
	check(maxIndex == 0 or maxIndex == count, `{path} array has gaps`)
end
walk(DataTemplate.Template, "Template")

local function copy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = copy(v)
	end
	return out
end

-- 2. a clean template needs no fixes
local clean = copy(DataTemplate.Template)
check(DataTemplate.sanitize(clean) == 0, "clean template needs no fixes")

-- 3. broken values are repaired, valid progress kept
local broken = copy(DataTemplate.Template)
broken.Money = -50
broken.Strength = 0 / 0
broken.WeightsLevel = 99
broken.PenSlots = 3
broken.Settings.Language = "fr"
broken.Cats = {
	k1 = { Kind = "cat001", Kg = 4.5, Locked = true, Got = 10 },
	k7 = { Kind = "cat050", Kg = 30, Got = 20 }, -- Locked missing
	bad = { Kind = 5, Kg = 1 },
	k2 = { Kind = "cat002", Kg = -1, Locked = false, Got = 0 },
}
broken.NextCatId = 2
local fixes = DataTemplate.sanitize(broken)
check(fixes > 0, "fixes counted")
check(broken.Money == 0, "negative money -> 0")
check(broken.Strength == Config.Data.StartStrength, "NaN strength -> start")
check(broken.WeightsLevel == Config.Weights.Levels, "level clamped to max")
check(broken.PenSlots == Config.Pen.StartSlots, "pen slots at least the start")
check(broken.Settings.Language == "en", "unknown language -> en")
check(broken.Cats.k1 ~= nil and broken.Cats.k1.Locked == true, "valid cat kept")
check(broken.Cats.k7 ~= nil and broken.Cats.k7.Locked == false, "missing Locked repaired")
check(broken.Cats.bad == nil and broken.Cats.k2 == nil, "broken cats removed")
check(broken.NextCatId == 8, "NextCatId moved past the highest id in use")

-- 4. new ids are unique and counted
local d = copy(DataTemplate.Template)
local a = DataTemplate.newCatId(d)
local b = DataTemplate.newCatId(d)
check(a ~= b and a == "k1" and b == "k2", "unique cat ids")
d.Cats[a] = { Kind = "cat001", Kg = 1, Locked = false, Got = 0 }
check(DataTemplate.catCount(d) == 1, "cat count")

if failures > 0 then
	error(`DataTemplate: {failures} failure(s)`)
end
print("PASS DataTemplate")
