--!strict
-- Cat crate rules (task 2.6): the odds table shown before buying and the roll the server makes with a
-- number it draws itself. Pure: tested by tests/Crates.spec.luau (sums, no Secret, rolls follow the odds).
--   Crates.get(key) -> crate config or nil
--   Crates.odds(key) -> { { tier = index, percent = n } } in tier order (for the window)
--   Crates.roll(key, u) -> tier index

local Config = require(script.Parent.Config)
local CatRules = require(script.Parent.CatRules)

local Crates = {}

function Crates.get(key: string): any
	for _, c in Config.Crates.List do
		if c.Key == key then
			return c
		end
	end
	return nil
end

function Crates.odds(key: string): { { tier: number, percent: number } }
	local c = Crates.get(key)
	local out = {}
	if c then
		for i, t in Config.Tiers do
			local p = c.Odds[t.Key]
			if p and p > 0 then
				table.insert(out, { tier = i, percent = p })
			end
		end
	end
	return out
end

function Crates.roll(key: string, u: number): number
	local c = Crates.get(key)
	return CatRules.pickTier(if c then c.Odds else { Basic = 1 }, u)
end

return Crates
