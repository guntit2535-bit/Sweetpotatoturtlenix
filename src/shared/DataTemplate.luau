--!strict
-- Shape and default values of a player's saved data (ProfileStore key Config.Data.StoreName).
-- New fields added to the template are filled in for old saves by Profile:Reconcile().
-- Saved data holds only strings, numbers, booleans and tables of them: no Instances, Vector3,
-- Color3, mixed tables or arrays with gaps (tests/DataTemplate.spec.luau). Cats are a map keyed by
-- unique string ids ("k1", "k2" ...) made from NextCatId, never an array, so a cat can never be
-- duplicated by a trade (milestone 2) or a lost index.
--
-- `sanitize` is pure (no Roblox APIs), so it is tested in Lune.

local Config = require(script.Parent.Config)

-- One owned cat (lives in the pen).
export type Cat = {
	Kind: string, -- cat design id from shared/Cats ("cat001" .. "cat400")
	Kg: number, -- its rolled weight (decides income and the Strength needed)
	Locked: boolean, -- favourite: cannot be sold or traded
	Got: number, -- os.time() it was caught (sort order in My Cats)
	Mutation: string?, -- "" / nil = none, "Gold" | "Rainbow" | "Glow" (task 2.9)
}

export type Quest = { Kind: string, Goal: number, Progress: number, Claimed: boolean }

export type Data = {
	Money: number,
	MoneyFrac: number, -- fraction of money carried between income ticks (< 1)
	Strength: number, -- kg, from the weights (task 1.15)
	Speed: number, -- from the treadmill (task 1.16); walk speed follows it
	WeightsLevel: number, -- 1 .. Config.Weights.Levels
	TreadLevel: number, -- 1 .. Config.Treadmill.Levels
	Rebirths: number, -- 0 .. Config.Rebirth.Max (milestone 2); zone gates read it
	NextCatId: number, -- next cat id is `k{NextCatId}`
	Cats: { [string]: Cat },
	PenSlots: number, -- Config.Pen.StartSlots .. MaxSlots
	LikesGiven: { [string]: number }, -- pen owner's UserId (string) -> UTC day number of the like (task 1.9)
	LikesReceived: number,
	Book: { [string]: boolean }, -- cat designs ever owned (collection book, task 2.8)
	LastOnline: number, -- os.time() at the last save
	RodLevel: number, -- best rod owned, 1 .. Config.Rods.Levels (task 2.2)
	Shoes: number, -- shoe pairs owned, 0 .. #Config.Shoes.List; the best is worn (task 2.3)
	PenBuys: number, -- pen expansions bought with money (task 2.4)
	Boosts: { [string]: number }, -- Luck / Money / Easy / Luck3 -> os.time() the boost ends (2.5, 2.19)
	SpeedPassOn: boolean, -- the x2 Speed button switch (task 2.18)
	LoginStep: number, -- next daily login reward 1 .. 7 (task 2.11)
	LoginDay: number, -- UTC day number of the last login claim
	PlayDay: number, -- UTC day of PlaySeconds (task 2.13)
	PlaySeconds: number, -- seconds played that day
	PlayClaimed: number, -- playtime gifts claimed that day (bit i-1 = gift i)
	QuestDay: number, -- UTC day of Quests (task 2.12)
	Quests: { Quest },
	CodesUsed: { [string]: boolean }, -- gift codes redeemed (task 2.15)
	GroupClaimed: boolean, -- the group reward (task 2.16)
	SlotBuys: number, -- +20 slot products bought (task 2.19)
	StarterBought: boolean, -- the starter pack (once)
	Settings: {
		Language: string, -- "en" (default) or "th"
	},
	ReceiptIds: { string }, -- processed developer product receipts, newest last (milestone 2)
	Stats: {
		Caught: number,
		Sold: number,
		Hits: number, -- bat hits that knocked a cat loose
	},
}

local DataTemplate = {}

DataTemplate.Template = {
	Money = Config.Data.StartMoney,
	MoneyFrac = 0,
	Strength = Config.Data.StartStrength,
	Speed = 0,
	WeightsLevel = 1,
	TreadLevel = 1,
	Rebirths = 0,
	NextCatId = 1,
	Cats = {},
	PenSlots = Config.Pen.StartSlots,
	LikesGiven = {},
	LikesReceived = 0,
	Book = {},
	LastOnline = 0,
	RodLevel = 1,
	Shoes = 0,
	PenBuys = 0,
	Boosts = { Luck = 0, Money = 0, Easy = 0, Luck3 = 0 },
	SpeedPassOn = true,
	LoginStep = 1,
	LoginDay = 0,
	PlayDay = 0,
	PlaySeconds = 0,
	PlayClaimed = 0,
	QuestDay = 0,
	Quests = {},
	CodesUsed = {},
	GroupClaimed = false,
	SlotBuys = 0,
	StarterBought = false,
	Settings = {
		Language = "en",
	},
	ReceiptIds = {},
	Stats = {
		Caught = 0,
		Sold = 0,
		Hits = 0,
	},
} :: Data

local function isFinite(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- A whole number in [min, max], or `fallback`.
local function whole(value: unknown, min: number, max: number, fallback: number): number
	if not isFinite(value) then
		return fallback
	end
	return math.clamp(math.floor(value :: number), min, max)
end

local function validCat(cat: unknown): boolean
	if type(cat) ~= "table" then
		return false
	end
	local c = cat :: { [string]: unknown }
	return type(c.Kind) == "string" and isFinite(c.Kg) and (c.Kg :: number) > 0
end

-- Repairs a loaded save after Reconcile: values that are no longer valid go back to defaults or the
-- nearest allowed value, broken cat entries are removed. Never removes valid progress.
-- Returns the number of fixes.
function DataTemplate.sanitize(data: Data): number
	local fixes = 0
	local function set(key: string, value: any)
		if (data :: any)[key] ~= value then
			(data :: any)[key] = value
			fixes += 1
		end
	end

	set("Money", whole(data.Money, 0, math.huge, 0))
	if not isFinite(data.MoneyFrac) or data.MoneyFrac < 0 or data.MoneyFrac >= 1 then
		set("MoneyFrac", 0)
	end
	if not isFinite(data.Strength) or data.Strength < Config.Data.StartStrength then
		set("Strength", Config.Data.StartStrength)
	end
	if not isFinite(data.Speed) or data.Speed < 0 then
		set("Speed", 0)
	end
	set("WeightsLevel", whole(data.WeightsLevel, 1, Config.Weights.Levels, 1))
	set("TreadLevel", whole(data.TreadLevel, 1, Config.Treadmill.Levels, 1))
	set("Rebirths", whole(data.Rebirths, 0, Config.Rebirth.Max, 0))
	set("PenSlots", whole(data.PenSlots, Config.Pen.StartSlots, Config.Pen.MaxSlots, Config.Pen.StartSlots))
	set("LikesReceived", whole(data.LikesReceived, 0, math.huge, 0))
	set("RodLevel", whole(data.RodLevel, 1, Config.Rods.Levels, 1))
	set("Shoes", whole(data.Shoes, 0, #Config.Shoes.List, 0))
	set("PenBuys", whole(data.PenBuys, 0, math.huge, 0))
	for key, ends in data.Boosts do
		if type(key) ~= "string" or not isFinite(ends) then
			data.Boosts[key] = nil
			fixes += 1
		end
	end
	set("LoginStep", whole(data.LoginStep, 1, #Config.Login, 1))
	for _, key in { "LoginDay", "PlayDay", "PlaySeconds", "PlayClaimed", "QuestDay" } do
		set(key, whole((data :: any)[key], 0, math.huge, 0))
	end
	set("SlotBuys", whole(data.SlotBuys, 0, math.huge, 0))
	if type(data.StarterBought) ~= "boolean" then
		set("StarterBought", false)
	end
	if type(data.GroupClaimed) ~= "boolean" then
		set("GroupClaimed", false)
	end
	local questsOk = #data.Quests <= Config.Quests.PerDay
	for _, q in data.Quests do
		if type(q) ~= "table" or type(q.Kind) ~= "string" or not isFinite(q.Goal) or not isFinite(q.Progress) or type(q.Claimed) ~= "boolean" then
			questsOk = false
		end
	end
	if not questsOk then
		data.Quests = {}
		data.QuestDay = 0
		fixes += 1
	end
	if type(data.SpeedPassOn) ~= "boolean" then
		set("SpeedPassOn", true)
	end

	-- cats: drop broken entries; keep NextCatId above every id in use
	local highest = 0
	for id, cat in data.Cats do
		if type(id) ~= "string" or not validCat(cat) then
			data.Cats[id] = nil
			fixes += 1
		else
			if type(cat.Locked) ~= "boolean" then
				cat.Locked = false
				fixes += 1
			end
			if cat.Mutation ~= nil and cat.Mutation ~= "" and cat.Mutation ~= "Gold" and cat.Mutation ~= "Rainbow" and cat.Mutation ~= "Glow" then
				cat.Mutation = nil
				fixes += 1
			end
			if not isFinite(cat.Got) then
				cat.Got = 0
				fixes += 1
			end
			local n = tonumber(string.match(id, "^k(%d+)$"))
			if n and n > highest then
				highest = n
			end
		end
	end
	set("NextCatId", math.max(whole(data.NextCatId, 1, math.huge, 1), highest + 1))

	for kind, seen in data.Book do
		if type(kind) ~= "string" or seen ~= true then
			data.Book[kind] = nil
			fixes += 1
		end
	end

	for owner, day in data.LikesGiven do
		if type(owner) ~= "string" or not isFinite(day) then
			data.LikesGiven[owner] = nil
			fixes += 1
		end
	end

	if data.Settings.Language ~= "en" and data.Settings.Language ~= "th" then
		data.Settings.Language = "en"
		fixes += 1
	end
	return fixes
end

-- A new unique cat id; bumps the counter (call inside DataService.Update).
function DataTemplate.newCatId(data: Data): string
	local id = `k{data.NextCatId}`
	data.NextCatId += 1
	return id
end

function DataTemplate.catCount(data: Data): number
	local n = 0
	for _ in data.Cats do
		n += 1
	end
	return n
end

return DataTemplate
