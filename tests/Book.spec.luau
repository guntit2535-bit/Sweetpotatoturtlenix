--!strict
-- Collection book (task 2.8): progress per tier and the money bonus. Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Book = Shared.require("Book")
local Cats = Shared.require("Cats")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Book: {message}`)
	end
end

local empty = {}
local per, total = Book.progress(empty)
check(total == 0 and per[1] == 0, "empty book")
check(Book.money(empty) == 0, "no bonus")

local secret: { [string]: boolean } = {}
for _, id in Cats.ByTier[6] do
	secret[id] = true
end
per, total = Book.progress(secret)
check(per[6] == 50 and total == 50, "50 Secrets seen")
check(math.abs(Book.money(secret) - Config.Book.TierBonus) < 1e-9, "a full tier gives the tier bonus")

local all: { [string]: boolean } = {}
for _, cat in Cats.List do
	all[cat.Id] = true
end
check(math.abs(Book.money(all) - (6 * Config.Book.TierBonus + Config.Book.AllBonus)) < 1e-9, "the whole book")

if failures > 0 then
	error(`Book: {failures} failure(s)`)
end
print("PASS Book")
