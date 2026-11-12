--!strict
-- Every multiplier in one place (milestone 2): money, Strength gain, walk speed, luck and fishing ease.
-- Pure: the caller builds the context (server: server/Util/BonusCtx; client: from attributes), so
-- tests/Bonus.spec.luau checks each rule alone and together.
--
--   Bonus.money(ctx)      rebirths x1.5 each, x2 Cash pass, VIP +10%, Golden Fish x2, book bonuses
--   Bonus.strength(ctx)   rebirths x3.8 each (W5), x2 Strength pass, x2 per weights boost step (W6)
--   Bonus.speedGain(ctx)  treadmill Speed per step: rebirths x SpeedMult each, x2 per treadmill boost step (W6)
--   Bonus.luck(ctx)       rod level, Lucky pass x2, Lucky Treat x1.5, luck x3 product, server luck
--   Bonus.easy(ctx)       Catnip active
--   Bonus.walk(speedStat, ctx)  walk speed in studs/s

local Config = require(script.Parent.Config)

export type Ctx = {
	now: number, -- os.time()
	rebirths: number,
	rodLevel: number,
	shoes: number, -- pairs owned (the best is worn)
	passes: { [string]: boolean }, -- Cash, Strength, Speed, Lucky, VIP
	speedPassOn: boolean, -- the x2 Speed button switch (when owned)
	boosts: { [string]: number }, -- Luck / Money / Easy / Luck3 -> os.time() it ends
	serverLuckUntil: number,
	likeBuff: boolean,
	bookMoney: number, -- extra money share from the collection book (0.05 = +5%)
	boostWeights: number, -- W6: training boost steps bought (0 .. Config.TrainBoost.Steps)
	boostTread: number,
}

local Bonus = {}

local function active(ctx: Ctx, key: string): boolean
	local ends = ctx.boosts[key]
	return type(ends) == "number" and ends > ctx.now
end

function Bonus.treat(key: string): any
	for _, t in Config.Treats.List do
		if t.Key == key then
			return t
		end
	end
	return nil
end

function Bonus.money(ctx: Ctx): number
	local m = Config.Rebirth.MoneyMult ^ ctx.rebirths
	if ctx.passes.Cash then
		m *= 2
	end
	if ctx.passes.VIP then
		m *= 1 + Config.Passes.VIP.Money
	end
	if active(ctx, "Money") then
		m *= Bonus.treat("Money").Mult
	end
	return m * (1 + ctx.bookMoney)
end

function Bonus.strength(ctx: Ctx): number
	local m = Config.Rebirth.StrengthMult ^ ctx.rebirths
	if ctx.passes.Strength then
		m *= 2
	end
	return m * Config.TrainBoost.Mult ^ ctx.boostWeights
end

-- W6: Speed gained per treadmill step (x the treadmill level's own gain): the rebirth factor x the boost steps.
function Bonus.speedGain(ctx: Ctx): number
	return Config.Rebirth.SpeedMult ^ ctx.rebirths * Config.TrainBoost.Mult ^ ctx.boostTread
end

function Bonus.luck(ctx: Ctx): number
	local m = 1 + math.max(0, ctx.rodLevel - 1) * Config.Rods.LuckPerLevel
	if ctx.passes.Lucky then
		m *= 2
	end
	if active(ctx, "Luck") then
		m *= Bonus.treat("Luck").Mult
	end
	if active(ctx, "Luck3") then
		m *= 3
	end
	if ctx.serverLuckUntil > ctx.now then
		m *= Config.Products.ServerLuckMult
	end
	return m
end

function Bonus.easy(ctx: Ctx): boolean
	return active(ctx, "Easy")
end

function Bonus.shoeSpeed(shoes: number): number
	if not Config.Shoes.Enabled or shoes <= 0 then
		return 0
	end
	local s = Config.Shoes.List[math.clamp(shoes, 1, #Config.Shoes.List)]
	return s.Speed
end

function Bonus.walk(speedStat: number, ctx: Ctx): number
	local w = Config.Walk
	-- R4: the Speed stat counts relative to the current life (it grows x SpeedMult per rebirth)
	local relative = math.max(0, speedStat) / Config.Rebirth.SpeedMult ^ ctx.rebirths
	local stat = math.min(w.Max - w.Base, w.Bonus * math.log(1 + relative / w.Scale))
	local above = stat + Bonus.shoeSpeed(ctx.shoes)
	if ctx.likeBuff then
		above *= w.LikeBuff
	end
	if ctx.passes.Speed and ctx.speedPassOn then
		above *= 2
	end
	return math.min(w.Cap, w.Base + above)
end

-- An empty context (tests, new players).
function Bonus.ctx(): Ctx
	return {
		now = 0,
		rebirths = 0,
		rodLevel = 1,
		shoes = 0,
		passes = {},
		speedPassOn = true,
		boosts = {},
		serverLuckUntil = 0,
		likeBuff = false,
		bookMoney = 0,
		boostWeights = 0,
		boostTread = 0,
	}
end

return Bonus
