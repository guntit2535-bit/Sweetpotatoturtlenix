--!strict
-- The collection book (task 2.8): which of the 400 designs a player has ever owned (data.Book), progress per
-- tier, and the permanent money bonus (Config.Book: each full tier, and the whole book). Pure: tested by
-- tests/Book.spec.luau.

local Config = require(script.Parent.Config)
local Cats = require(script.Parent.Cats)

local Book = {}

-- seen per tier and in total.
function Book.progress(book: { [string]: boolean }): ({ number }, number)
	local perTier = {}
	local total = 0
	for tier, list in Cats.ByTier do
		local n = 0
		for _, id in list do
			if book[id] then
				n += 1
			end
		end
		perTier[tier] = n
		total += n
	end
	return perTier, total
end

-- Extra money share: Config.Book.TierBonus per full tier, plus AllBonus for all 400.
function Book.money(book: { [string]: boolean }): number
	local perTier, total = Book.progress(book)
	local bonus = 0
	for tier, list in Cats.ByTier do
		if perTier[tier] == #list then
			bonus += Config.Book.TierBonus
		end
	end
	if total == #Cats.List then
		bonus += Config.Book.AllBonus
	end
	return bonus
end

return Book
