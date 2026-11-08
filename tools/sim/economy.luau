--!strict
-- Economy simulation (task 1.6):   lune run tools/sim/economy.luau
-- One player, no rebirth: catches a cat every CATCH_SECONDS in the best open zone (only cats their Strength
-- can hold), keeps the best cats in the pen, lifts weights when the next zone needs more Strength, and buys
-- the next weights level whenever affordable. Prints, for 3 cost options, when each zone opens and the pen
-- income on the way. Uses the game's own rules (src/shared/CatRules) and Config.

local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local CatRules = Shared.require("CatRules")

local CATCH_SECONDS = 45 -- walk out, find, fish, carry home
local HOURS = 6

local function lcg(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
end

local function fmt(seconds: number?): string
	if not seconds then
		return "-"
	end
	return string.format("%dh%02dm", seconds // 3600, (seconds % 3600) // 60)
end

local function run(costScale: number)
	local rand = lcg(42)
	local t, money, strength, level = 0, 0, Config.Data.StartStrength, 1
	local pen: { number } = {}
	local opened: { [number]: number } = { [1] = 0 }
	local incomeAt: { [number]: number } = {}
	local nextCatch = CATCH_SECONDS
	while t < HOURS * 3600 do
		-- best open zone
		local zone = 1
		for z = 2, #Config.World.Zones do
			if CatRules.zoneOpen(z, strength, 0) then
				zone = z
				opened[z] = opened[z] or t
			end
		end
		local nextZone = Config.World.Zones[zone + 1]
		local lifting = nextZone ~= nil and strength < nextZone.Strength and #pen >= Config.Pen.StartSlots
		-- income
		local income = 0
		for _, v in pen do
			income += v
		end
		money += income
		-- buy weights levels
		local cost = CatRules.weightsCost(level)
		while cost and money >= cost * costScale do
			money -= cost * costScale
			level += 1
			cost = CatRules.weightsCost(level)
		end
		if lifting then
			strength += CatRules.weightsGain(level)
		elseif t >= nextCatch then
			nextCatch = t + CATCH_SECONDS
			local z = Config.World.Zones[zone]
			for _ = 1, 5 do -- a few tries to find a cat they can hold
				local tier = CatRules.pickTier(z.Odds, rand())
				local kg = CatRules.rollKg(tier, rand(), (z :: any).KgSkew)
				if CatRules.strengthNeeded(kg) <= strength then
					table.insert(pen, CatRules.income(tier, kg))
					table.sort(pen, function(a, b)
						return a > b
					end)
					while #pen > Config.Pen.StartSlots do
						table.remove(pen)
					end
					break
				end
			end
			-- between catches they lift a little too
			strength += CatRules.weightsGain(level) * 10
		end
		for _, h in { 1, 3, 6 } do
			if t == h * 3600 - 1 then
				incomeAt[h] = income
			end
		end
		t += 1
	end
	return opened, incomeAt, level
end

print("Economy (no rebirth, 10 pen slots, a catch every " .. CATCH_SECONDS .. " s)")
print("option      | zone 2  | zone 3  | zone 4  | zone 5  | income 1h | 3h        | 6h        | weights Lv at 6h")
for _, opt in { { "A fast", 0.5 }, { "B normal", 1 }, { "C slow", 2 } } do
	local opened, income, level = run(opt[2] :: number)
	print(string.format("%-11s | %-7s | %-7s | %-7s | %-7s | %9.0f | %9.0f | %9.0f | %d",
		opt[1] :: string, fmt(opened[2]), fmt(opened[3]), fmt(opened[4]), fmt(opened[5]),
		income[1] or 0, income[3] or 0, income[6] or 0, level))
end
