--!strict
-- W5 (revision 3 item 9): how long the whole game takes, on the game's own rules.   lune run tools/sim/endgame.luau
-- Uses src/shared (Config, CatRules, Shop, Crates, Mutation) through tests/lib/Shared, so it plays the numbers the
-- game really uses; each option only changes a few Config values before the run.
--
-- The player (a free player who plays actively, no passes or Robux):
--   - goes for a cat every CATCH seconds in the best zone it may enter and can hold (walk + bar game); WIN of them
--     succeed; tries up to 6 cats per trip for one it can hold; a caught cat goes into the pen (the best ones stay)
--   - lifts weights LIFT of the remaining time; buys the next weights level, pen slots and rods when it can, and a
--     crate when the best one costs under CRATE_SHARE of its money (at most one a CRATE_GAP)
--   - rebirths as soon as Strength reaches the need (cats, pen slots and rods stay; money, Strength, levels reset)
-- "End game" = rebirth 25 (the last one). Also printed: when rod 25 and 60 pen slots are bought.
-- Real play is slower than this (other players take cats, bat hits, walking between zones, breaks): see W5 in
-- docs/economy.md for how the options were read.

local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local CatRules = Shared.require("CatRules")
local Shop = Shared.require("Shop")
local Crates = Shared.require("Crates")
local Mutation = Shared.require("Mutation")

local CATCH = 60
local WIN = 0.85
local LIFT = 0.5
local STEP = 5
local CRATE_SHARE = 0.25
local CRATE_GAP = 120
local LIMIT = 300 * 3600

local function lcg(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
end

local UNITS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
local function short(n: number): string
	if n < 1000 then
		return string.format("%.0f", n)
	end
	local i = math.min(#UNITS - 1, math.floor(math.log10(n) / 3))
	return string.format("%.1f%s", n / 10 ^ (i * 3), UNITS[i + 1])
end
local function clock(s: number?): string
	if not s then
		return "-"
	end
	return string.format("%dh%02d", s // 3600, (s % 3600) // 60)
end

type Result = { reb: { [number]: number }, inc: { [number]: number }, rod25: number?, pen60: number?, zones: { [number]: number }, money: number, crates: number }

local function run(seed: number): Result
	local rand = lcg(seed)
	local t, money, strength, wl, r = 0, 0, 0, 1, 0
	local rod, slots, penBuys = 1, Config.Pen.StartSlots, 0
	local pen: { number } = {} -- income per second of each cat (before the rebirth multiplier)
	local nextCatch, nextCrate = 0, 0
	local res: Result = { reb = {}, inc = {}, zones = { [1] = 0 }, money = 0, crates = 0 }
	local function addCat(inc: number)
		table.insert(pen, inc)
		table.sort(pen, function(a, b)
			return a > b
		end)
		while #pen > slots do
			table.remove(pen)
		end
	end
	while r < Config.Rebirth.Max and t < LIMIT do
		local luck = 1 + (rod - 1) * Config.Rods.LuckPerLevel
		-- income
		local inc = 0
		for _, v in pen do
			inc += v
		end
		inc *= CatRules.rebirthMoney(r)
		money = CatRules.cap(money + inc * STEP)
		-- shopping: weights first, then pen slots, then the next rod
		while true do
			local c = CatRules.weightsCost(wl, r)
			if c and money >= c then
				money -= c
				wl += 1
				continue
			end
			if slots < Config.Pen.MaxSlots and money >= Shop.penCost(penBuys) then
				money -= Shop.penCost(penBuys)
				penBuys += 1
				slots = math.min(Config.Pen.MaxSlots, slots + Config.PenUpgrade.Step)
				if slots >= Config.Pen.MaxSlots then
					res.pen60 = res.pen60 or t
				end
				continue
			end
			local rc = Shop.rodCost(rod + 1)
			if rc and money >= rc then
				money -= rc
				rod += 1
				if rod >= Config.Rods.Levels then
					res.rod25 = res.rod25 or t
				end
				continue
			end
			break
		end
		-- a crate now and then
		if t >= nextCrate then
			local best: string? = nil
			for _, cr in Config.Crates.List do
				if Crates.cost(cr.Key, r) <= money * CRATE_SHARE then
					best = cr.Key
				end
			end
			if best then
				money -= Crates.cost(best, r)
				local tier = Crates.roll(best, rand())
				local kg = CatRules.kgFor(CatRules.rollKg(tier, rand()), r)
				addCat(CatRules.income(tier, kg) * Mutation.money(Mutation.roll(tier, luck, rand())))
				res.crates += 1
				nextCrate = t + CRATE_GAP
			end
		end
		-- the best zone open
		local zone = 1
		for z = 2, #Config.World.Zones do
			if CatRules.zoneOpen(z, strength, r) then
				zone = z
				if not res.zones[z] then
					res.zones[z] = t
				end
			end
		end
		-- a catch
		if t >= nextCatch then
			nextCatch = t + CATCH
			if rand() < WIN then
				local zd = Config.World.Zones[zone] :: any
				for _ = 1, 6 do
					local tier = CatRules.pickTier(zd.Odds, rand())
					local kg = CatRules.kgFor(CatRules.rollKg(tier, rand(), zd.KgSkew), r)
					if CatRules.strengthNeeded(kg) <= strength then
						addCat(CatRules.income(tier, kg) * Mutation.money(Mutation.roll(tier, luck, rand())))
						break
					end
				end
			end
		end
		-- lifting
		strength = CatRules.cap(strength + CatRules.weightsGain(wl) * CatRules.rebirthStrength(r) * STEP * LIFT)
		-- rebirth
		local need = CatRules.rebirthNeed(r)
		if need and strength >= need then
			r += 1
			res.reb[r] = t
			res.inc[r] = inc -- income per second at the end of the life just finished
			money, strength, wl = 0, 0, 1
		end
		t += STEP
	end
	res.money = money
	return res
end

-- Options: a name and the Config changes it makes (restored after the run)
type Option = { name: string, set: { { any } } }
local OPTIONS: { Option } = {
	{ name = "Now", set = {} },
}
local extra = (...) :: any
local ok, opts = pcall(function()
	return require("./endgame_options")
end)
if ok and type(opts) == "table" then
	for _, o in opts do
		table.insert(OPTIONS, o)
	end
end
local _ = extra

for _, o in OPTIONS do
	local saved = {}
	for _, s in o.set do
		local tbl, key, value = s[1], s[2], s[3]
		table.insert(saved, { tbl, key, tbl[key] })
		tbl[key] = value
	end
	-- three seeds, the middle one shown
	local runs = {}
	for seed = 1, 3 do
		table.insert(runs, run(seed * 7919))
	end
	table.sort(runs, function(a, b)
		return (a.reb[Config.Rebirth.Max] or LIMIT) < (b.reb[Config.Rebirth.Max] or LIMIT)
	end)
	local m = runs[2]
	print(`== {o.name}`)
	print(`  zones (first life): 2 {clock(m.zones[2])} | 3 {clock(m.zones[3])} | 4 {clock(m.zones[4])} | 5 {clock(m.zones[5])}`)
	print(`  rebirth 1 {clock(m.reb[1])} | 5 {clock(m.reb[5])} | 10 {clock(m.reb[10])} | 15 {clock(m.reb[15])} | 20 {clock(m.reb[20])} | 25 {clock(m.reb[25])}`)
	-- crate prices in minutes of income at the end of lives 1 / 5 / 15 (the next life's prices)
	local mins = {}
	for _, k in { 1, 5, 15 } do
		local inc = m.inc[k]
		if inc and inc > 0 then
			local row = {}
			for _, cr in Config.Crates.List do
				table.insert(row, string.format("%.3g", Crates.cost(cr.Key, k - 1) / inc / 60))
			end
			table.insert(mins, `life {k} (income {short(inc)}/s): ` .. table.concat(row, "/"))
		end
	end
	print(`  crate prices in minutes of income (Paper/Wood/Gold/Diamond): {table.concat(mins, " | ")}`)
	print(`  rod 25 at {clock(m.rod25)} | 60 pen slots at {clock(m.pen60)} | crates bought {m.crates} | (fastest / slowest seed: {clock(runs[1].reb[25])} / {clock(runs[3].reb[25])})`)
	for i = #saved, 1, -1 do
		local s = saved[i]
		s[1][s[2]] = s[3]
	end
end
