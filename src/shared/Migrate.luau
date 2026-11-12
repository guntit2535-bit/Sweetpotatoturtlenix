--!strict
-- One-time save conversions (pure, tested by tests/Migrate.spec.luau). Called by DataService after sanitize.
--
--   Migrate.econ(data) -> true when it changed the save
--     R4 (2026-11-08): the numbers grew to 99 Sx (docs/economy.md, option B). A save with EconVersion 0 is
--     moved onto the new scale once, never wiped:
--       - every cat keeps its place inside its tier: old linear position -> the new log ladder, then x KgMult
--         per rebirth the player has;
--       - Strength follows the zone gates (old 1 / 10 / 60 / 300 / 1500 -> new 1 / 100 / 10K / 1M / 10M, log
--         steps in between, the last step's slope above), x KgMult per rebirth;
--       - Speed x Walk-scale change x SpeedMult per rebirth, so the walk speed stays the same;
--       - Money and levels stay as they are.

local Config = require(script.Parent.Config)
local CatRules = require(script.Parent.CatRules)

local Migrate = {}

-- The tier weight ranges before R4 (Basic .. Secret).
local OLD_TIERS = { { 1, 10 }, { 10, 60 }, { 60, 300 }, { 300, 1500 }, { 1500, 8000 }, { 10000, 50000 } }
-- Strength anchors: old value -> new value (no rebirth).
local ANCHORS = { { 1, 1 }, { 10, 100 }, { 60, 1e4 }, { 300, 1e6 }, { 1500, 1e7 } }
local OLD_WALK_SCALE = 10

local function mapStrength(old: number): number
	if old <= ANCHORS[1][1] then
		return math.max(0, old)
	end
	for i = 2, #ANCHORS do
		local a, b = ANCHORS[i - 1], ANCHORS[i]
		if old <= b[1] then
			local f = math.log(old / a[1]) / math.log(b[1] / a[1])
			return a[2] * (b[2] / a[2]) ^ f
		end
	end
	-- above the last anchor: keep the last step's slope (log-log)
	local a, b = ANCHORS[#ANCHORS - 1], ANCHORS[#ANCHORS]
	local slope = math.log(b[2] / a[2]) / math.log(b[1] / a[1])
	return b[2] * (old / b[1]) ^ slope
end
Migrate.mapStrength = mapStrength

-- The new base kg of a cat that weighed `kg` in `tier` before R4.
function Migrate.mapKg(tier: number, kg: number): number
	local o = OLD_TIERS[tier]
	local t = Config.Tiers[tier]
	if not o or not t then
		return kg
	end
	local f = math.clamp((kg - o[1]) / (o[2] - o[1]), 0, 1)
	return t.MinKg * (t.MaxKg / t.MinKg) ^ f
end

function Migrate.econ(data: any): boolean
	if (data.EconVersion or 0) >= Config.Data.EconVersion then
		return false
	end
	local r = data.Rebirths or 0
	local Cats = require(script.Parent.Cats) :: any
	for _, cat in data.Cats do
		local design = Cats.ById[cat.Kind]
		if design then
			cat.Kg = CatRules.kgFor(Migrate.mapKg(design.Tier, cat.Kg), r)
		end
	end
	data.Strength = CatRules.cap(mapStrength(data.Strength) * Config.Rebirth.KgMult ^ r)
	data.Speed = CatRules.cap(data.Speed * (Config.Walk.Scale / OLD_WALK_SCALE) * Config.Rebirth.SpeedMult ^ r)
	data.EconVersion = Config.Data.EconVersion
	return true
end

-- V4: a save without a tutorial step yet: a brand-new player starts the tutorial (1); anyone who already
-- had a cat (saves from before V4) has it marked done. Returns true when it changed the save.
function Migrate.tutorial(data: any): boolean
	if data.TutorialStep ~= 0 then
		return false
	end
	local played = (data.NextCatId or 1) > 1 or (data.Stats and data.Stats.Caught or 0) > 0
	data.TutorialStep = if played then Config.Tutorial.Done else 1
	return true
end

local function deepCopy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = deepCopy(x)
	end
	return out
end

-- A save from before the current Config.Data.ResetEpoch becomes a new player's save (the developer's reset of all
-- testers, 2026-11-13): every field back to `template`, in place (the same table), except the receipt list (never
-- grant a purchase twice). It is then marked with the epoch and the current EconVersion (nothing to convert).
-- A brand-new save goes through it once too (it is the template already). Returns true when it reset the save.
function Migrate.reset(data: any, template: any): boolean
	if (data.ResetEpoch or 0) >= Config.Data.ResetEpoch then
		return false
	end
	local receipts = data.ReceiptIds
	for k in data do
		data[k] = nil
	end
	for k, v in template do
		data[k] = deepCopy(v)
	end
	if type(receipts) == "table" then
		data.ReceiptIds = receipts
	end
	data.ResetEpoch = Config.Data.ResetEpoch
	data.EconVersion = Config.Data.EconVersion
	return true
end

return Migrate
