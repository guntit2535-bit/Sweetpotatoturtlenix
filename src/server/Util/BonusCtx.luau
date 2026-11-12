--!strict
-- Builds a player's shared/Bonus context on the server from their save, their game passes (player
-- attributes "Pass<Name>" = true, set by PassService) and the server's luck (workspace attribute
-- ServerLuckUntil, os.time()).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bonus = require(ReplicatedStorage.Shared.Bonus)
local Book = require(ReplicatedStorage.Shared.Book)

local BonusCtx = {}

BonusCtx.PassNames = { "Speed", "Cash", "Strength", "Lucky", "VIP" }

-- Extra money share from the collection book (task 2.8).
BonusCtx.bookMoney = function(data: any): number
	return Book.money(data.Book or {})
end

function BonusCtx.of(player: Player, data: any): Bonus.Ctx
	local ctx = Bonus.ctx()
	ctx.now = os.time()
	if data then
		ctx.rebirths = data.Rebirths
		ctx.rodLevel = data.RodLevel
		ctx.shoes = data.Shoes
		ctx.boosts = data.Boosts
		ctx.speedPassOn = data.SpeedPassOn
		ctx.bookMoney = BonusCtx.bookMoney(data)
		ctx.boostWeights = data.BoostWeights or 0
		ctx.boostTread = data.BoostTread or 0
	end
	for _, name in BonusCtx.PassNames do
		ctx.passes[name] = player:GetAttribute(`Pass{name}`) == true
	end
	local serverLuck = workspace:GetAttribute("ServerLuckUntil")
	ctx.serverLuckUntil = if type(serverLuck) == "number" then serverLuck else 0
	local likeUntil = player:GetAttribute("LikeBuffUntil")
	ctx.likeBuff = type(likeUntil) == "number" and likeUntil > workspace:GetServerTimeNow()
	return ctx
end

return BonusCtx
