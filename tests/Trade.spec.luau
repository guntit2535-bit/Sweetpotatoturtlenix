--!strict
-- Trading rules (task 2.17): offers, locks, room, and a swap that never duplicates or loses a cat.
-- Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Trade = Shared.require("Trade")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Trade: {message}`)
	end
end

local function player(n: number, prefix: string, locked: { [number]: boolean }?): any
	local d = { Cats = {}, NextCatId = n + 1, Book = {} }
	for i = 1, n do
		d.Cats[`k{i}`] = { Kind = `{prefix}{i}`, Kg = i, Locked = (locked or {})[i] == true, Got = 0 }
	end
	return d
end

local a = player(3, "a", { [3] = true })
local b = player(10, "b")

check(Trade.validOffer(a.Cats, { "k1", "k2" }), "own unlocked cats")
check(select(2, Trade.validOffer(a.Cats, { "k3" })) == "Locked", "locked cats can't be traded")
check(select(2, Trade.validOffer(a.Cats, { "k1", "k1" })) == "Bad", "no duplicates in an offer")
check(select(2, Trade.validOffer(a.Cats, { "k9" })) == "Gone", "not owned")
check(select(2, Trade.validOffer(b.Cats, { "k1", "k2", "k3", "k4", "k5", "k6", "k7" })) == "TooMany", "6 at most")
check(select(2, Trade.check(a.Cats, {}, 10, b.Cats, {}, 10)) == "Empty", "empty trade")
-- b has 10 of 10 slots: taking 2 for 1 does not fit
check(select(2, Trade.check(a.Cats, { "k1", "k2" }, 10, b.Cats, { "k1" }, 10)) == "NoRoom", "pen must have room")
check(Trade.check(a.Cats, { "k1", "k2" }, 10, b.Cats, { "k1", "k2" }, 10), "2 for 2 fits")

-- swap: every cat ends on exactly one side, nothing lost or copied
local before = {}
for _, c in a.Cats do
	before[c.Kind] = true
end
for _, c in b.Cats do
	before[c.Kind] = true
end
Trade.swap(a, { "k1", "k2" }, b, { "k4" })
local after: { [string]: number } = {}
local total = 0
for _, side in { a, b } do
	for _, c in side.Cats do
		after[c.Kind] = (after[c.Kind] or 0) + 1
		total += 1
	end
end
for kind in before do
	check(after[kind] == 1, `{kind} exists exactly once`)
end
check(total == 13, "13 cats in all")
local aKinds = {}
for _, c in a.Cats do
	aKinds[c.Kind] = true
end
check(aKinds.b4 and aKinds.a3 and not aKinds.a1, "a gave a1, a2 and got b4")
check(b.Book.a1 and b.Book.a2, "received cats are in the book")
-- ids stay unique on each side
for _, side in { a, b } do
	local n = 0
	for id in side.Cats do
		n += 1
		check(string.match(id, "^k%d+$") ~= nil, "id format")
	end
	check(side.NextCatId > n, "counter above the ids")
end

if failures > 0 then
	error(`Trade: {failures} failure(s)`)
end
print("PASS Trade")
