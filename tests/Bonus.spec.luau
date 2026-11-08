--!strict
-- Multipliers (milestone 2, shared/Bonus): each rule alone and together. Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Bonus = Shared.require("Bonus")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Bonus: {message}`)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

local c = Bonus.ctx()
c.now = 1000
check(near(Bonus.money(c), 1) and near(Bonus.strength(c), 1) and near(Bonus.luck(c), 1), "nothing = x1")
check(not Bonus.easy(c), "no Catnip")

c.rebirths = 2
check(near(Bonus.money(c), 2.25) and near(Bonus.strength(c), 2.25), "2 rebirths = x1.5^2")
c.passes.Cash = true
c.passes.VIP = true
check(near(Bonus.money(c), 2.25 * 2 * 1.1), "Cash x2 and VIP +10%")
c.boosts.Money = 1200
check(near(Bonus.money(c), 2.25 * 2 * 1.1 * 2), "Golden Fish x2 while active")
c.boosts.Money = 900
check(near(Bonus.money(c), 2.25 * 2 * 1.1), "Golden Fish over")
c.bookMoney = 0.05
check(near(Bonus.money(c), 2.25 * 2 * 1.1 * 1.05), "book bonus")

local l = Bonus.ctx()
l.now = 10
l.rodLevel = 6
check(near(Bonus.luck(l), 1 + 5 * Config.Rods.LuckPerLevel), "rod luck")
l.passes.Lucky = true
l.boosts.Luck = 20
l.boosts.Luck3 = 20
l.serverLuckUntil = 20
check(near(Bonus.luck(l), (1 + 5 * Config.Rods.LuckPerLevel) * 2 * 1.5 * 3 * Config.Products.ServerLuckMult), "all luck together")
l.boosts.Easy = 20
check(Bonus.easy(l), "Catnip active")

local w = Bonus.ctx()
check(Bonus.walk(0, w) == Config.Walk.Base, "walk base")
w.shoes = 1
check(near(Bonus.walk(0, w), Config.Walk.Base + Config.Shoes.List[1].Speed), "shoes add speed")
w.passes.Speed = true
w.speedPassOn = false
check(near(Bonus.walk(0, w), Config.Walk.Base + Config.Shoes.List[1].Speed), "x2 Speed switched off")
w.speedPassOn = true
check(near(Bonus.walk(0, w), Config.Walk.Base + 2 * Config.Shoes.List[1].Speed), "x2 Speed doubles the part above base")
w.shoes = 8
w.likeBuff = true
check(Bonus.walk(1e12, w) == Config.Walk.Cap, "capped")

if failures > 0 then
	error(`Bonus: {failures} failure(s)`)
end
print("PASS Bonus")
