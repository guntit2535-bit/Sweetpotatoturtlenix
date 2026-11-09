--!strict
-- The 400 cats (V5h, round 2): the 300 approved block-cat designs (50 per tier, docs/Sweetpotato_Cats.xlsx,
-- shared/CatDesigns) plus colour variants of the first designs of the lower tiers, so the tiers hold
-- Basic 100 / Rare 80 / Epic 70 / Legendary 50 / Mythical 50 / Secret 50 (Config.Tiers[i].Count).
-- A variant is the same design with its fur and pattern colours tinted (shared/CatModel) and a colour word
-- before its name ("Frost Ginger Tabby"). Names stay English in both languages, like zone names.
-- Ids run cat001..cat400 by tier: a tier's designs in table order, then its variants. Pure module: tested by
-- tests/Cats.spec.luau.
--
--   Cats.ById["cat001"] -> { Id, Tier = 1, TierKey = "Basic", Name = "Ginger Tabby", Look = { design = "Ginger Tabby" } }
--   Cats.ByTier[1] -> { "cat001", ... }

local CatDesigns = require(script.Parent.CatDesigns)
local Config = require(script.Parent.Config)

export type Look = {
	design: string, -- a name in shared/CatDesigns
	tint: string?, -- colour variants: the hex colour the fur and pattern are tinted towards
}

export type Cat = {
	Id: string,
	Tier: number,
	TierKey: string,
	Name: string,
	Look: Look,
}

local Cats = {}

Cats.List = {} :: { Cat }
Cats.ById = {} :: { [string]: Cat }
Cats.ByTier = {} :: { { string } }

-- colour words for the variants, in the order they are handed out
Cats.Tints = {
	{ "Frost", "7cc8ff" },
	{ "Rose", "ff86b0" },
	{ "Mint", "6fdcaa" },
	{ "Lemon", "ffd84a" },
	{ "Berry", "a874ff" },
	{ "Sunset", "ff8a4a" },
	{ "Ocean", "3f7fe8" },
	{ "Cocoa", "8a5a3a" },
	{ "Lilac", "c8a2ff" },
	{ "Cherry", "e8465a" },
}

local number = 0
local function add(tier: number, name: string, look: Look)
	number += 1
	local id = string.format("cat%03d", number)
	local cat: Cat = { Id = id, Tier = tier, TierKey = Config.Tiers[tier].Key, Name = name, Look = look }
	table.insert(Cats.List, cat)
	Cats.ById[id] = cat
	table.insert(Cats.ByTier[tier], id)
end

for tier, t in Config.Tiers do
	Cats.ByTier[tier] = {}
	local designs: { string } = (CatDesigns :: any)[t.Key]
	for _, name in designs do
		add(tier, name, { design = name })
	end
	for i = 1, t.Count - #designs do
		local name = designs[i]
		local k = ((i - 1) * 3) % #Cats.Tints
		local tint = Cats.Tints[k + 1]
		-- no "Lilac Lilac": skip a word that is already in the name
		while string.find(string.lower(name), string.lower(tint[1]), 1, true) do
			k = (k + 1) % #Cats.Tints
			tint = Cats.Tints[k + 1]
		end
		add(tier, `{tint[1]} {name}`, { design = name, tint = tint[2] })
	end
end

return Cats
