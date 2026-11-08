--!strict
-- Shop prices (tasks 2.1 - 2.5): rising, defined only where buyable. Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Shop = Shared.require("Shop")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Shop: {message}`)
	end
end

check(Shop.rodCost(1) == nil and Shop.rodCost(Config.Rods.Levels + 1) == nil, "rod 1 free, none past the top")
for level = 3, Config.Rods.Levels do
	check((Shop.rodCost(level) :: number) > (Shop.rodCost(level - 1) :: number), `rod {level} costs more`)
end
local m, n = Shop.rodMaterial(1)
check(m == 1 and n == 1, "rod 1 = Wood 1")
m, n = Shop.rodMaterial(25)
check(m == 5 and n == 5, "rod 25 = Cosmic 5")
m, n = Shop.rodMaterial(6)
check(m == 2 and n == 1, "rod 6 = Iron 1")
for pair = 2, #Config.Shoes.List do
	check((Shop.shoeCost(pair) :: number) > (Shop.shoeCost(pair - 1) :: number), `shoes {pair} cost more`)
end
check(Shop.penCost(1) > Shop.penCost(0), "pen expansions get dearer")
check(Shop.treatCost("Money", 0) == 3000, "treat base price")
check(Shop.treatCost("Money", 1000) == 300000, "treat follows income")
check(Shop.treatCost("Nope", 1) == nil, "unknown treat")
local steps = (Config.Pen.MaxSlots - Config.Pen.StartSlots) / Config.PenUpgrade.Step
check(steps == math.floor(steps), "pen steps land exactly on the max")

if failures > 0 then
	error(`Shop: {failures} failure(s)`)
end
print("PASS Shop")
