--!strict
-- Options for tools/sim/endgame.luau: each is the Config changes it makes (the run puts them back after).
-- X3 (revision 4 item 9): 7 crates instead of 4, prices stepped from Paper to the top crate.
local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local C = Config.Crates

local function list(top: number, cosmic: boolean): { any }
	local l = {
		{ Key = "Paper", Cost = 40000, Color = "e8d6ab", Odds = { Basic = 75, Rare = 22, Epic = 3 } },
		{ Key = "Wood", Cost = 600e3, Color = "c98a4a", Odds = { Basic = 50, Rare = 38, Epic = 11, Legendary = 1 } },
		{ Key = "Iron", Cost = 8e6, Color = "b8c2d6", Odds = { Basic = 25, Rare = 45, Epic = 26, Legendary = 4 } },
		{ Key = "Gold", Cost = 75e6, Color = "f5bf2e", Odds = { Rare = 50, Epic = 38, Legendary = 12 } },
		{ Key = "Ruby", Cost = 300e6, Color = "ff4d6d", Odds = { Rare = 25, Epic = 50, Legendary = 24.7, Mythical = 0.3 } },
		{ Key = "Diamond", Cost = 900e6, Color = "7fe3ff", Odds = { Epic = 55, Legendary = 44.3, Mythical = 0.7 } },
		{ Key = "Cosmic", Cost = top, Color = "6b4cff", Odds = { Epic = 35, Legendary = 63, Mythical = 2 } },
	}
	if not cosmic then
		table.remove(l)
	end
	return l
end

return {
	{ name = "7 crates, Cosmic 3B", set = { { C, "List", list(3e9, true) } } },
	{ name = "7 crates, Cosmic 6B", set = { { C, "List", list(6e9, true) } } },
}
