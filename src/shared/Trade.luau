--!strict
-- Trade rules (task 2.17, blueprint §15), pure: tests/Trade.spec.luau.
--   Trade.validOffer(cats, ids) -> ok, reason   up to Config.Trade.MaxCats distinct owned, unlocked cats
--   Trade.check(aCats, aIds, aSlots, bCats, bIds, bSlots) -> ok, reason   both offers + room in both pens
--   Trade.swap(aData, aIds, bData, bIds)   moves the cats in one step (ids renumbered on the receiving
--   side from its own counter), so a cat is never in both saves and never lost.

local Config = require(script.Parent.Config)

local Trade = {}

local function count(t: { [string]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

function Trade.validOffer(cats: { [string]: any }, ids: { string }): (boolean, string?)
	if #ids > Config.Trade.MaxCats then
		return false, "TooMany"
	end
	local seen: { [string]: boolean } = {}
	for _, id in ids do
		if type(id) ~= "string" or seen[id] then
			return false, "Bad"
		end
		seen[id] = true
		local cat = cats[id]
		if not cat then
			return false, "Gone"
		end
		if cat.Locked then
			return false, "Locked"
		end
	end
	return true, nil
end

function Trade.check(aCats: { [string]: any }, aIds: { string }, aSlots: number, bCats: { [string]: any }, bIds: { string }, bSlots: number): (boolean, string?)
	local ok, why = Trade.validOffer(aCats, aIds)
	if not ok then
		return false, why
	end
	ok, why = Trade.validOffer(bCats, bIds)
	if not ok then
		return false, why
	end
	if #aIds == 0 and #bIds == 0 then
		return false, "Empty"
	end
	if count(aCats) - #aIds + #bIds > aSlots or count(bCats) - #bIds + #aIds > bSlots then
		return false, "NoRoom"
	end
	return true, nil
end

local function move(from: any, to: any, ids: { string }): { string }
	local moved = {}
	for _, id in ids do
		local cat = from.Cats[id]
		from.Cats[id] = nil
		local newId = `k{to.NextCatId}`
		to.NextCatId += 1
		cat.Locked = false
		to.Cats[newId] = cat
		if to.Book then
			to.Book[cat.Kind] = true
		end
		table.insert(moved, newId)
	end
	return moved
end

-- Call only after Trade.check passed, inside one server step (no yields).
function Trade.swap(aData: any, aIds: { string }, bData: any, bIds: { string })
	-- take both sides' cats out first, then give: nothing can be read half-done
	local aCats, bCats = {}, {}
	for _, id in aIds do
		aCats[id] = aData.Cats[id]
	end
	for _, id in bIds do
		bCats[id] = bData.Cats[id]
	end
	local temp = { Cats = {}, NextCatId = 0 }
	move(aData, temp, aIds)
	move(bData, temp, bIds)
	local aTemp, bTemp = {}, {}
	for i = 0, #aIds - 1 do
		table.insert(aTemp, `k{i}`)
	end
	for i = #aIds, #aIds + #bIds - 1 do
		table.insert(bTemp, `k{i}`)
	end
	move(temp, bData, aTemp)
	move(temp, aData, bTemp)
end

return Trade
