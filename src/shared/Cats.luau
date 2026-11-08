--!strict
-- The 400 cat designs (task 1.5, blueprint §5): 150 Basic, 110 Rare, 70 Epic, 45 Legendary, 20 Mythical,
-- 5 Secret. Each design = a look for shared/CatModel (3 base shapes x fur colours x patterns x
-- accessories, higher tiers with effects) and an English name (kept in both languages, like zone names).
-- Built at load from fixed seeds, so every server and client gets the same 400 designs. Pure module:
-- tested by tests/Cats.spec.luau (counts, unique ids / names / looks).
--
--   Cats.ById["cat001"] -> { Id, Tier = 1, TierKey = "Basic", Name = "Ginger Mochi", Look = {...} }
--   Cats.ByTier[1] -> { "cat001", ... }

local Config = require(script.Parent.Config)

export type Look = {
	shape: string,
	fur: string,
	second: string,
	pattern: string?,
	patternColor: string?,
	patternColor2: string?,
	eyes: string?,
	accessory: string?,
	accessoryColor: string?,
	aura: string?,
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

-- A small deterministic random generator (the same numbers everywhere, Lune included).
local function lcg(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

local function pick<T>(rand: () -> number, list: { T }): T
	return list[math.floor(rand() * #list) + 1]
end

local SHAPES = { "Loaf", "Slim", "Fluffy" }

-- name word, fur, light colour (muzzle / chest)
type Fur = { string }
local NATURAL: { Fur } = {
	{ "Ginger", "f2a65a", "fff1dc" },
	{ "Grey", "9aa3b5", "ffffff" },
	{ "Snowy", "f7f3ea", "ffffff" },
	{ "Midnight", "3a3340", "ffffff" },
	{ "Cocoa", "8b5a3c", "f3d9bf" },
	{ "Cream", "f3d9a6", "fff7e8" },
	{ "Smoky", "6f7585", "e8ecf3" },
	{ "Peach", "f6b98f", "fff1e6" },
	{ "Silver", "c8cdd8", "ffffff" },
	{ "Caramel", "d08b4a", "fbe3c4" },
}
local RARE: { Fur } = {
	{ "Bluegrey", "7d93b8", "eef2fa" },
	{ "Chocolate", "6b4330", "e8c9a8" },
	{ "Lilac", "c3b1d9", "f7f2ff" },
	{ "Honey", "f1c46a", "fff6dc" },
	{ "Rusty", "c4633a", "fbe0cf" },
	{ "Ash", "8c8f99", "f2f2f5" },
}
local EPIC: { Fur } = {
	{ "Bubblegum", "ffb6d5", "fff2f8" },
	{ "Mint", "a8ecd0", "f2fff9" },
	{ "Lavender", "c9b6ff", "f6f2ff" },
	{ "Skyblue", "a9d8ff", "f2f9ff" },
	{ "Lemon", "fff09a", "fffbe0" },
	{ "Coral", "ff9f8a", "fff0eb" },
	{ "Peppermint", "e9fff4", "ffffff" },
}
local LEGENDARY: { Fur } = {
	{ "Golden", "f6c945", "fff3c4" },
	{ "Ruby", "e84a5f", "ffe1e6" },
	{ "Sapphire", "4a7fe8", "e3ecff" },
	{ "Emerald", "3fbf7f", "e2fff0" },
	{ "Amethyst", "9a5ad6", "f1e6ff" },
	{ "Pearl", "f5f0ff", "ffffff" },
	{ "Bronze", "c98a4a", "f7e3cc" },
}
local COSMIC: { Fur } = {
	{ "", "c9b6ff", "fff0ff" },
	{ "", "7fe0ff", "efffff" },
	{ "", "ff9ad9", "fff0fa" },
	{ "", "ffd77a", "fffbe6" },
	{ "", "9dffb0", "f0fff3" },
	{ "", "b3a1ff", "f3f0ff" },
	{ "", "ffb48a", "fff3ea" },
}
local GALAXY: { Fur } = {
	{ "", "2d2b45", "8fe8ff" },
	{ "", "1f3a5c", "ffd6f5" },
	{ "", "3d1f4f", "9dffe0" },
	{ "", "f7f2ff", "ffd77a" },
	{ "", "2a2a2a", "ff9ad9" },
}
local PATTERN_COLORS = { "3a3340", "f29b4a", "8b5a3c", "6f7585", "ffffff" }
local ACC_COLORS = { "ff5a6e", "3e8ef2", "2fc7c0", "ffcf3a", "9a6bff", "ff8fca", "4fc75a" }
local EYES = { "2a2433", "2b6fd6", "3a9b4a", "b0711f" }
local NAMES = {
	"Mochi", "Biscuit", "Pudding", "Noodle", "Peanut", "Muffin", "Pickles", "Sprout", "Dumpling", "Nugget",
	"Waffle", "Pebble", "Button", "Toffee", "Bean", "Cookie", "Tofu", "Maple", "Pumpkin", "Sushi",
	"Bubbles", "Clover", "Daisy", "Marble", "Pretzel", "Popcorn", "Sesame", "Taro", "Latte", "Mango",
	"Kiwi", "Olive", "Pepper", "Crumble", "Jelly", "Truffle", "Churro", "Pancake", "Cupcake", "Dango",
	"Whiskers", "Nibbles", "Snickerdoodle", "Fudge", "Gumdrop", "Marshmallow", "Pistachio", "Cinnamon",
	"Butterscotch", "Pip", "Bramble", "Acorn", "Puddle", "Sprinkle", "Tater", "Yam", "Turnip", "Wasabi",
}
local MYTHICAL_NAMES = {
	"Starlight", "Moonbeam", "Aurora", "Comet", "Nebula", "Sunflare", "Stardust", "Twilight", "Crystalwing",
	"Dreamcloud", "Lunar Paws", "Phoenix Kit", "Galewhisker", "Frostwing", "Bloomheart", "Skydancer",
	"Opal Spirit", "Thunderpaw", "Velvet Comet", "Prism",
}
local SECRET_NAMES = { "Galaxy Emperor", "Rainbow Sovereign", "Void Whisker", "Celestial Queen", "Sweetpotato King" }

local PATTERN_WORDS: { [string]: string } = {
	solid = "",
	tabby = "Tabby",
	patches = "Calico",
	socks = "Socks",
	tuxedo = "Tuxedo",
	spots = "Spotty",
}

local TIER_RULES = {
	-- furs, patterns, accessories (nil = none), aura
	{ furs = NATURAL, patterns = { "solid", "tabby", "patches", "socks", "tuxedo", "spots" }, accs = { false }, aura = nil },
	{ furs = RARE, patterns = { "tabby", "patches", "socks", "spots", "solid" }, accs = { "collar", "bow", "scarf", false }, aura = nil },
	{ furs = EPIC, patterns = { "solid", "spots", "tabby", "patches", "socks" }, accs = { "bow", "flowers", "hat", "scarf" }, aura = "sparkle" },
	{ furs = LEGENDARY, patterns = { "solid", "tabby", "spots", "socks" }, accs = { "crown", "hat" }, aura = "gold" },
	{ furs = COSMIC, patterns = { "spots", "solid", "tabby" }, accs = { "wings" }, aura = "glow" },
	{ furs = GALAXY, patterns = { "spots", "solid" }, accs = { "halo" }, aura = "rainbow" },
}
-- Rare cats use the natural furs and the Rare ones.
do
	local rare = {}
	for _, f in NATURAL do
		table.insert(rare, f)
	end
	for _, f in RARE do
		table.insert(rare, f)
	end
	TIER_RULES[2].furs = rare
end

local function lookKey(l: Look): string
	return table.concat({ l.shape, l.fur, l.second, l.pattern or "", l.patternColor or "", l.accessory or "", l.accessoryColor or "", l.eyes or "" }, "|")
end

local usedLooks: { [string]: boolean } = {}
local usedNames: { [string]: boolean } = {}
local number = 0

for tier, t in Config.Tiers do
	local rule = TIER_RULES[tier]
	local rand = lcg(7919 * tier + 17)
	Cats.ByTier[tier] = {}
	for i = 1, t.Count do
		local look: Look
		local fur: Fur
		local tries = 0
		repeat
			tries += 1
			fur = if tier >= 5 then rule.furs[(i - 1) % #rule.furs + 1] else pick(rand, rule.furs)
			local pattern = pick(rand, rule.patterns)
			local acc = pick(rand, rule.accs :: { any })
			look = {
				shape = SHAPES[(i + tries) % 3 + 1],
				fur = fur[2],
				second = fur[3],
				pattern = pattern,
				patternColor = if pattern == "solid" or pattern == "socks" or pattern == "tuxedo" then nil else pick(rand, PATTERN_COLORS),
				patternColor2 = if pattern == "patches" then pick(rand, PATTERN_COLORS) else nil,
				eyes = if tier >= 3 or rand() < 0.3 then pick(rand, EYES) else nil,
				accessory = if acc then acc :: string else nil,
				accessoryColor = if acc then pick(rand, ACC_COLORS) else nil,
				aura = rule.aura,
			}
			if pattern == "tuxedo" then
				look.fur = "3a3340"
				look.second = "ffffff"
			end
		until not usedLooks[lookKey(look)] or tries > 200
		usedLooks[lookKey(look)] = true

		local name: string
		if tier == 5 then
			name = MYTHICAL_NAMES[i]
		elseif tier == 6 then
			name = SECRET_NAMES[i]
		else
			local word = PATTERN_WORDS[look.pattern or "solid"]
			local first = if word ~= "" and rand() < 0.45 then word else fur[1]
			local n = 0
			repeat
				n += 1
				name = `{first} {pick(rand, NAMES)}`
				if n > 30 then
					first = fur[1] .. " " .. (if word ~= "" then word else "Little")
				end
			until not usedNames[name] or n > 200
		end
		usedNames[name] = true

		number += 1
		local id = string.format("cat%03d", number)
		local cat: Cat = { Id = id, Tier = tier, TierKey = t.Key, Name = name, Look = look }
		table.insert(Cats.List, cat)
		Cats.ById[id] = cat
		table.insert(Cats.ByTier[tier], id)
	end
end

return Cats
