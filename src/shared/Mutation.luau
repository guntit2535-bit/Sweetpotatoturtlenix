--!strict
-- Mutations (task 2.9): Gold x2, Rainbow x5, Glow x10 money, for Basic-Legendary cats only, rolled once by
-- the server with a number it draws (luck multiplies the chances). Pure: tested by tests/Mutation.spec.luau.
--   Mutation.roll(tier, luck, u) -> "" | "Gold" | "Rainbow" | "Glow"
--   Mutation.money(mutation) -> income multiplier (1 when none)

local Config = require(script.Parent.Config)

local Mutation = {}

function Mutation.roll(tier: number, luck: number, u: number): string
	if tier > Config.Mutations.MaxTier then
		return ""
	end
	local at = u * 100
	for _, m in Config.Mutations.List do -- rarest first
		local chance = m.Chance * math.max(1, luck)
		if at < chance then
			return m.Key
		end
		at -= chance
	end
	return ""
end

function Mutation.money(mutation: string?): number
	if not mutation or mutation == "" then
		return 1
	end
	for _, m in Config.Mutations.List do
		if m.Key == mutation then
			return m.Money
		end
	end
	return 1
end

return Mutation
