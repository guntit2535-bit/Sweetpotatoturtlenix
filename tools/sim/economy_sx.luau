--!strict
-- R4 economy simulation (numbers up to 99 Sx):   lune run tools/sim/economy_sx.luau
-- A stand-alone model of the proposed curves (not Config yet). One player plays from a new save to rebirth 25:
--   - catches a cat every CATCH seconds in the best open zone it can hold (kg <= Strength), keeps the best in the pen
--     (slots 10 + 2 per rebirth, max 60), lifts the rest of the time (LIFT share), buys weights / treadmill levels
--     when affordable, rebirths as soon as Strength reaches the need.
--   - Cat kg per tier on a log ladder, rolled kg = min * (max / min) ^ (u ^ 2), x KgUp ^ rebirths (heavier world).
--   - Weights gain = 1 * Grow ^ (L - 1) * StrUp ^ rebirths; cost = Cost0 * CostGrow ^ (L - 1) * KgUp ^ rebirths.
--   - Income = Rate * kg * 1.5 ^ rebirths. Everything capped at 99 Sx.
-- Prints per option: when each zone first opens, time to rebirths 1 / 5 / 10 / 15 / 20 / 25, and the values then.

local CAP = 9.9e22 -- 99 Sx
local CATCH = 45
local LIFT = 0.6 -- share of time lifting between catches
local STEP = 5 -- seconds per sim step

local TIERS = { -- min kg, max kg, money per kg per second
	{ 1, 100, 0.5 },
	{ 100, 1e4, 0.8 },
	{ 1e4, 1e6, 1.2 },
	{ 1e6, 1e8, 2 },
}
local ZONES = { -- strength gate, odds per tier (Basic, Rare, Epic, Legendary)
	{ 0, { 90, 10, 0, 0 } },
	{ 100, { 30, 60, 10, 0 } },
	{ 1e4, { 0, 35, 55, 10 } },
	{ 1e6, { 0, 0, 45, 55 } },
	{ 1e7, { 0, 0, 20, 80 } },
}

local UNITS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
local function short(n: number): string
	if n < 1000 then
		return string.format("%.0f", n)
	end
	local i = math.min(#UNITS - 1, math.floor(math.log10(n) / 3))
	return string.format("%.1f%s", n / 10 ^ (i * 3), UNITS[i + 1])
end

local function clock(s: number): string
	return string.format("%dh%02d", s // 3600, (s % 3600) // 60)
end

local function lcg(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
end

type Opt = { name: string, Grow: number, Cost0: number, CostGrow: number, CostUp: number, KgUp: number, StrUp: number, Need0: number, NeedGrow: number }
local INCOME_POWER = 0.6 -- money per second = rate * kg ^ 0.6 (heavier cats earn more, but slower than their weight)

local function run(o: Opt)
	local rand = lcg(7)
	local t, money, strength, wl, r = 0, 0, 1, 1, 0
	local pen: { number } = {} -- kg x tier rate (before the money multiplier)
	local nextCatch = 0
	local opened: { [number]: number } = { [1] = 0 }
	local rebirthAt: { [number]: { t: number, s: number, m: number, inc: number } } = {}
	while r < 25 and t < 400 * 3600 do
		local up = o.KgUp ^ r
		-- open zones
		local zone = 1
		for z = 2, #ZONES do
			if strength >= ZONES[z][1] * up or r >= ({ 0, 1, 2, 4, 6 })[z] then
				zone = z
				if not opened[z] and r == 0 then
					opened[z] = t
				end
			end
		end
		-- income
		local inc = 0
		for _, v in pen do
			inc += v
		end
		inc *= 1.5 ^ r
		money = math.min(CAP, money + inc * STEP)
		-- buy weights levels
		while wl < 25 do
			local cost = o.Cost0 * o.CostGrow ^ (wl - 1) * o.CostUp ^ r
			if money < cost then
				break
			end
			money -= cost
			wl += 1
		end
		-- catch or lift
		if t >= nextCatch then
			nextCatch = t + CATCH
			local odds = ZONES[zone][2]
			for _ = 1, 6 do
				local u = rand() * 100
				local tier = 1
				for i, w in odds do
					u -= w
					if u < 0 then
						tier = i
						break
					end
				end
				local mn, mx, rate = TIERS[tier][1], TIERS[tier][2], TIERS[tier][3]
				local kg = mn * (mx / mn) ^ (rand() ^ 2) * up
				if kg <= strength then
					table.insert(pen, (kg ^ INCOME_POWER) * rate)
					table.sort(pen, function(a, b)
						return a > b
					end)
					while #pen > math.min(60, 10 + 2 * r) do
						table.remove(pen)
					end
					break
				end
			end
		end
		strength = math.min(CAP, strength + o.Grow ^ (wl - 1) * o.StrUp ^ r * STEP * LIFT)
		-- rebirth
		local need = o.Need0 * o.NeedGrow ^ r
		if strength >= need then
			r += 1
			rebirthAt[r] = { t = t, s = strength, m = money, inc = inc }
			money, strength, wl = 0, 1, 1
		end
		t += STEP
	end
	return opened, rebirthAt
end

local OPTIONS: { Opt } = {
	{ name = "A fast", Grow = 1.62, Cost0 = 20, CostGrow = 1.75, CostUp = 3.0, KgUp = 3.6, StrUp = 4.0, Need0 = 1e8, NeedGrow = 4.05 },
	{ name = "B normal", Grow = 1.6, Cost0 = 30, CostGrow = 1.78, CostUp = 3.0, KgUp = 3.6, StrUp = 3.95, Need0 = 1.5e8, NeedGrow = 4.0 },
	{ name = "C slow", Grow = 1.58, Cost0 = 45, CostGrow = 1.8, CostUp = 3.0, KgUp = 3.6, StrUp = 3.9, Need0 = 2e8, NeedGrow = 3.97 },
}

for _, o in OPTIONS do
	local opened, reb = run(o)
	print(`== {o.name}`)
	print(`  zones (first life): 2 {clock(opened[2] or 0)} | 3 {clock(opened[3] or 0)} | 4 {clock(opened[4] or 0)} | 5 {clock(opened[5] or 0)}`)
	for _, k in { 1, 5, 10, 15, 20, 25 } do
		local e = reb[k]
		if e then
			print(`  rebirth {k}: {clock(e.t)} | Strength {short(e.s)} | money {short(e.m)} | income {short(e.inc)}/s`)
		else
			print(`  rebirth {k}: not reached`)
		end
	end
end
