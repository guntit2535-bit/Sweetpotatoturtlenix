--!strict
-- Every number in the game lives here. Blueprint numbers (docs/BLUEPRINT.md) are starting values:
-- tune them here after playtests, never in services or controllers.
-- Sections are added by the task that first needs them (docs/PLAN.md).
-- Values marked CLIENT PENDING wait for the client's answer (CLAUDE.md "Waiting for the client").

local Config = {}

Config.GameName = "Sweetpotatoturtlenix"
Config.MaxPlayers = 8 -- one pen per player in the lobby (blueprint §1, §6)

-- The Roblox group that owns the game (created by the team, owner GUN2535551; transferred to the client
-- after approval + full payment). Experience: GameId 10775309921, start place 85516549821714.
Config.GroupId = 565190385

-- Map layout in studs (A2, built by tools/lib/BuildMap). The lobby sits at 0,0 (safe zone, no hitting);
-- 5 ring zones around it, from the inside out. 8 roads leave the plaza at 0, 45, 90 ... degrees and
-- cross every zone wall through a gate; the 8 pens sit between the roads.
Config.World = {
	GroundY = 0,
	LobbyRadius = 150, -- safe zone edge
	PlazaRadius = 46,
	Pens = { Count = 8, Ring = 100, Width = 40, Depth = 34 }, -- pen i at angle (i - 0.5) * 45 degrees
	Roads = { Count = 8, Width = 16 },
	GateWidth = 24,
	Tile = { Lobby = 20, Zones = 24 }, -- checkerboard grass tile sizes
	SkyCloudY = -60, -- the cloud sea under the Sky Islands
	ClusterSpacing = 80, -- studs between prop clusters along a lane (zones 1-4)
	-- 180-stud rings: at the start walk speed (16) the map edge is ~65 s from the plaza
	-- Gate: enter with Strength >= Strength x Rebirth.KgMult ^ rebirths (R4) OR Rebirths >= Rebirths. Odds: tier key -> weight (%).
	-- KgSkew overrides Config.KgSkew (lower = heavier cats). Cats: wild cats kept in the zone at once.
	Zones = {
		{ Key = "Backyard", Inner = 150, Outer = 330, Strength = 0, Rebirths = 0, Cats = 18, Odds = { Basic = 90, Rare = 10 } },
		{ Key = "TownMarket", Inner = 330, Outer = 510, Strength = 100, Rebirths = 1, Cats = 18, Odds = { Basic = 30, Rare = 60, Epic = 10 } },
		{ Key = "Forest", Inner = 510, Outer = 690, Strength = 1e4, Rebirths = 2, Cats = 18, Odds = { Rare = 35, Epic = 55, Legendary = 10 } },
		{ Key = "SnowMountain", Inner = 690, Outer = 870, Strength = 1e6, Rebirths = 4, Cats = 18, Odds = { Epic = 45, Legendary = 55 } },
		{ Key = "SkyIslands", Inner = 870, Outer = 1050, Strength = 1e7, Rebirths = 6, Cats = 18, Odds = { Epic = 20, Legendary = 80 }, KgSkew = 0.8 },
	},
	HideSpotsPerZone = { Min = 30, Max = 60 },
}

-- Debug commands (task 1.3). Studio always; live servers only for these user ids. Off at launch.
Config.Debug = {
	Enabled = true, -- set false in the launch checklist
	Admins = { 11657887907 }, -- the developer (GUN2535551)
	Prefix = "!",
}

-- Remotes (task 1.1). Every client -> server remote is rate limited per player (src/server/Util/Guard).
Config.Remotes = {
	WaitTimeout = 10, -- seconds a client waits for a remote the server has not created yet
	DefaultMaxCalls = 10, -- calls allowed per player per remote ...
	DefaultWindow = 1, -- ... in this many seconds
	MaxStringLength = 200, -- longest string a client may send
}

-- Settings window (task 1.1): language now; music / sound switches come with the sounds (2.23).
Config.Settings = {
	SetRate = { maxCalls = 4, window = 1 }, -- SetSetting calls per player
}

-- Saves (task 1.2). NEVER rename StoreName after launch: every player's progress would be lost.
Config.Data = {
	StoreName = "Sweetpotato_PlayerData_v1",
	StartMoney = 0,
	StartStrength = 1, -- kg: enough for the lightest Basic cats (1 kg)
	EconVersion = 1, -- R4: saves below this are converted once to the 99 Sx numbers (DataService)
	SaveTimeout = 15, -- seconds DataService.SaveAsync waits before giving up (autosave still runs)
	GetDataRate = { maxCalls = 2, window = 1 }, -- the client asks once on start
	-- Studio only: Workspace attribute FreshSave = true gives every player a new in-memory save that is
	-- never written (tests from zero without touching the developer's real save).
	FreshSaveAttribute = "FreshSave",
	LikeDaysKept = 2, -- likes given are remembered per pen owner for this many UTC days (task 1.9)
}

-- The player's pen (task 1.8).
Config.Pen = {
	StartSlots = 10,
	MaxSlots = 60,
	SellRate = { maxCalls = 4, window = 1 },
	LockRate = { maxCalls = 6, window = 1 },
	LikeCooldown = 2, -- seconds between Like prompts per player (any pen)
	WanderSpeed = 3, -- studs/s a pen cat walks (client side)
	RestSeconds = { 3, 9 }, -- a pen cat rests this long between walks
}

-- Cat tiers (blueprint §5; R4 option B, docs/economy.md): designs per tier, BASE weight range on a log ladder
-- (rolled min * (max / min) ^ (u ^ KgSkew)), money rate. A player sees and catches a cat at base kg x
-- Rebirth.KgMult ^ their rebirths (the world gets heavier every rebirth). Income of a cat = Rate x kg ^
-- Economy.IncomePower (x mutations / boosts). Basic-Legendary are one size; Mythical 1.3-2x and Secret 3-6x by
-- weight inside the tier (CatRules.size).
Config.Tiers = {
	{ Key = "Basic", Count = 150, MinKg = 1, MaxKg = 100, Rate = 0.5, Color = "9aa7bd" },
	{ Key = "Rare", Count = 110, MinKg = 100, MaxKg = 1e4, Rate = 0.8, Color = "3da5ff" },
	{ Key = "Epic", Count = 70, MinKg = 1e4, MaxKg = 1e6, Rate = 1.2, Color = "a46bff" },
	{ Key = "Legendary", Count = 45, MinKg = 1e6, MaxKg = 1e8, Rate = 2, Color = "ffb020" },
	{ Key = "Mythical", Count = 20, MinKg = 1e8, MaxKg = 1e9, Rate = 4, Color = "ff5fa2", SizeMin = 1.3, SizeMax = 2 },
	{ Key = "Secret", Count = 5, MinKg = 1e9, MaxKg = 1.18e9, Rate = 8, Color = "18c9b9", SizeMin = 3, SizeMax = 6 },
}
Config.KgSkew = 2 -- base kg = min * (max / min) ^ (u ^ KgSkew): heavy cats of a tier are rarer

-- Economy (R4 option B "normal", docs/economy.md; tools/sim/economy_sx.luau). Every Money, Strength, Speed and
-- kg value is capped at Max (99 Sx).
Config.Economy = {
	Max = 9.9e22, -- 99 Sx
	IncomePower = 0.6, -- a cat earns Rate x kg ^ 0.6 per second (heavier cats earn more, slower than their weight)
	SellSeconds = 120, -- selling a cat pays this many seconds of its income
	IncomeTick = 1, -- seconds between pen income ticks
}

-- Training (tasks 1.15 / 1.16, R4): one rep / step every Tick seconds; level L gives Gain * Growth^(L-1) (x the
-- rebirth multipliers); the next level costs Cost * CostGrowth^(L-1) * CostRebirth^rebirths money.
Config.Weights = { Levels = 25, Tick = 1, Gain = 1, Growth = 1.6, Cost = 30, CostGrowth = 1.78, CostRebirth = 3 }
Config.Treadmill = { Levels = 25, Tick = 1, Gain = 1, Growth = 1.6, Cost = 20, CostGrowth = 1.78, CostRebirth = 3 }
-- Standing within StandRadius of your own pen's weights / treadmill trains; the gym looks change every
-- LookEvery weights levels (dumbbell > barbell > bench > machine > giant barbell).
Config.Gym = {
	StandRadius = 3.6,
	LookEvery = 5,
	UpgradeRate = { maxCalls = 3, window = 1 },
	-- R2: stepping on the spot locks the player there (walk speed 0) until a jump (StopTraining)
	CheckEvery = 0.2, -- seconds between spot checks
	Slip = 3, -- studs past StandRadius before a locked player counts as pushed off
	Face = { Weights = 0, Treadmill = 0 }, -- extra turn (degrees) from the stand's facing
	StopRate = { maxCalls = 4, window = 1 },
}
-- Zone gates: a player inside a zone they may not enter yet is put back just outside it.
Config.Gates = { CheckEvery = 0.5, PushBack = 8 }
-- Walk speed from the Speed stat: Base + Bonus * ln(1 + S / Scale), at most Max (studs/s), where S = Speed /
-- Rebirth.SpeedMult ^ rebirths (R4: the stat grows to Sx, walking feels the same every life).
-- The Speed stat's part is capped at Max; shoes add on top; the x2 Speed pass doubles everything above
-- Base; Cap is the final limit.
Config.Walk = { Base = 16, Bonus = 9, Scale = 100, Max = 60, Cap = 120, LikeBuff = 2, LikeBuffSeconds = 300 }
-- Each rebirth (R4): money x1.5, Strength gain x3.95, Speed gain x3.95, every cat in the world x3.6 heavier.
Config.Rebirth = { Max = 25, MoneyMult = 1.5, StrengthMult = 3.95, SpeedMult = 3.95, KgMult = 3.6 }

-- Wild cats at the hiding spots (task 1.10).
Config.WildCats = {
	RespawnMin = 30, -- a caught or escaped cat comes back at another spot after 30-90 s (blueprint §1)
	RespawnMax = 90,
	SizeBySpot = { roof = 1, bush = 0.8, rock = 1, bridge = 0.6 }, -- smaller where the spot is low
	LabelRange = 70, -- studs: the tier / kg label shows this close
}

-- Fishing (task 1.11): the bar minigame, simulated on the server (shared/FishingBar), shown on the client.
-- Per tier: Zone = green zone size (share of the bar), CatSpeed = bar lengths per second, Change = seconds
-- between the cat's turns (min, max), Fill / Drain = meter per second inside / outside the zone.
Config.Fishing = {
	CastRange = 45, -- studs from the player to the cat
	KeepRange = 70, -- walking further than this away ends the session
	TickRate = 15, -- server steps per second
	SnapshotEvery = 0.2, -- seconds between the server's bar snapshots to the client
	StartMeter = 0.3,
	Lift = 2.6, -- zone acceleration up while holding (bar lengths / s^2)
	Gravity = 2.2, -- and down when released
	MaxVel = 1.4,
	Bounce = 0.35, -- zone speed kept when it hits an end
	CastRate = { maxCalls = 3, window = 1 },
	HoldRate = { maxCalls = 30, window = 1 },
	Tiers = {
		{ Zone = 0.34, CatSpeed = 0.35, Change = { 0.6, 1.4 }, Fill = 0.11, Drain = 0.07 }, -- Basic
		{ Zone = 0.31, CatSpeed = 0.45, Change = { 0.5, 1.2 }, Fill = 0.085, Drain = 0.07 }, -- Rare
		{ Zone = 0.28, CatSpeed = 0.48, Change = { 0.45, 1.1 }, Fill = 0.07, Drain = 0.07 }, -- Epic
		{ Zone = 0.25, CatSpeed = 0.5, Change = { 0.5, 1.2 }, Fill = 0.06, Drain = 0.07 }, -- Legendary
		{ Zone = 0.235, CatSpeed = 0.52, Change = { 0.45, 1.1 }, Fill = 0.058, Drain = 0.06 }, -- Mythical
		{ Zone = 0.225, CatSpeed = 0.55, Change = { 0.4, 1.0 }, Fill = 0.052, Drain = 0.058 }, -- Secret: hardest
	},
	RodZonePerLevel = 0.006, -- milestone 2: each rod level widens the zone ...
	RodFillPerLevel = 0.02, -- ... and fills the meter faster
}

-- Carrying a caught cat home (task 1.13) and the baseball bat (task 1.14).
Config.Carry = {
	HeadOffset = 2.6, -- studs above the root part (the cat rests on the raised hands, task 2.22)
	Scale = 0.7, -- a carried cat is shown at this share of its size ...
	MaxScale = 1.0, -- ... and never bigger than this model scale
	DeliverRadius = 22, -- studs from the pen centre
	CheckEvery = 0.25,
	DroppedSeconds = 60, -- a knocked-loose cat nobody catches goes back into hiding (blueprint §4)
}
Config.Bat = {
	Cooldown = 0.8,
	Range = 9, -- studs in front of the swinger
	Arc = 0.3, -- minimum dot product between the swinger's look and the target
	Knock = 120, -- carrier knocked far: horizontal speed ...
	KnockUp = 70, -- ... and up
	SmallKnock = 45, -- a player not carrying a cat is only pushed
	StunSeconds = 1.2,
	SwingRate = { maxCalls = 4, window = 1 },
}

-- Events (task 1.18, blueprint §10): a Mythical cat every 10-20 minutes, a Secret cat every 40 minutes,
-- at a random hiding spot anywhere on the map; nobody catching it within EscapeSeconds = it runs away.
Config.Events = {
	MythicalEvery = { 600, 1200 },
	SecretEvery = 2400,
	EscapeSeconds = 180,
	BeamHeight = 400,
}

-- Cat animation on the clients (shared/CatAnims clips on the CatModel rig).
-- R9: UI icons from the developer's GPT pictures (art/export/ui_icons, 512 px), uploaded to the group; 0 = not
-- uploaded yet (a white paw shows instead).
Config.UIIcons = {
	Shop = 0, -- P01
	Speed2x = 0, -- P02
	MyCats = 0, -- P03
	Trade = 0, -- P04
	Settings = 0, -- P05
	Rebirth = 0, -- P06
	Rewards = 0, -- P07
	Book = 0, -- P08
	Coin = 0, -- P09
	Strength = 0, -- P10
	Speed = 0, -- P11
	Event = 0, -- P12
}

-- R3: "+$X" popups over your own pen cats every income tick, and "+$total" by the money pill.
Config.IncomePopup = {
	Range = 80, -- only cats this close to the camera (studs)
	Rise = 2.5, -- studs the label floats up
	Seconds = 0.9, -- how long it shows
	Spread = 0.35, -- popups start at random times inside this many seconds (not all at once)
}
Config.CatAnim = {
	Range = 160, -- only cats this close to the camera are animated (studs)
	RescanSeconds = 1, -- a cat whose joints have not all streamed in yet is looked up again this often
}
-- Player arm poses (task 2.22, shared/PlayerPoses): carrying a cat and reeling, drawn by every client.
Config.PlayerAnim = {
	Range = 160, -- only players this close to the camera are posed (studs)
	Blend = 0.25, -- seconds to ease into / out of a pose
}

-- Languages: English is the default for every player, Thai is picked in Settings and saved.
Config.Language = {
	Default = "en",
}

-- Robux (milestone 2). Ids from the group's experience (created by the developer 2026-11-08, each checked with
-- GetProductInfo: name, on sale, group). Prices live in Creator Hub; the launch check fails while any id is 0.
Config.Passes = {
	-- CLIENT PENDING: permanent game pass ("pass") or a timed boost sold as a developer product
	-- ("timed"), and its price. Default until the client answers: permanent pass.
	Speed2x = {
		Id = 2075284120,
		Mode = "pass" :: "pass" | "timed",
		TimedMinutes = 15, -- used only when Mode = "timed"
		PriceRobux = 0, -- 0 = not decided; the client confirms every Robux price
	},
	Cash2x = { Id = 2075044202 },
	Strength2x = { Id = 2075884214 },
	Lucky = { Id = 2075734209 }, -- rare finds x2 (luck)
	VIP = { Id = 2075422198, Money = 0.10 }, -- VIP tag + 10% money
}

-- Developer products (milestone 2, blueprint §13). Ids from the group's experience (2026-11-08); the client
-- confirms every price. Money packs pay Seconds of the buyer's income (at least Base).
Config.Products = {
	ServerLuckMult = 2, -- server luck: everyone's luck x2 for 15 minutes
	LuckSeconds = 900, -- luck x3 and server luck last 15 minutes
	SlotsStep = 20, -- +20 pen slots per purchase (never past Config.Pen.MaxSlots)
	List = {
		{ Key = "Slots1", Id = 3729675464, Kind = "Slots" }, -- 1st +20 slots
		{ Key = "Slots2", Id = 3729675727, Kind = "Slots" }, -- 2nd, a higher price
		{ Key = "Slots3", Id = 3729675916, Kind = "Slots" }, -- 3rd, higher again
		{ Key = "CashS", Id = 3729676037, Kind = "Cash", Base = 5000, Seconds = 600 },
		{ Key = "CashM", Id = 3729676128, Kind = "Cash", Base = 25000, Seconds = 3600 },
		{ Key = "CashL", Id = 3729676205, Kind = "Cash", Base = 100000, Seconds = 4 * 3600 },
		{ Key = "CashXL", Id = 3729676288, Kind = "Cash", Base = 400000, Seconds = 12 * 3600 },
		{ Key = "Strength", Id = 3729676358, Kind = "Strength", Base = 10000, Seconds = 3600 }, -- an hour of lifting
		{ Key = "Luck3", Id = 3729676458, Kind = "Luck3" },
		{ Key = "ServerLuck", Id = 3729676540, Kind = "ServerLuck" },
		{ Key = "SummonMythical", Id = 3729676622, Kind = "Summon" },
		{ Key = "Starter", Id = 3729676699, Kind = "Starter", Money = 10000, Rod = 6, Treats = { "Luck", "Money" } },
	},
	ReceiptsKept = 100,
}

-- CLIENT PENDING: keep the 8 shoes next to the treadmill (both add speed), or drop the shoes.
-- Default until the client answers: keep them (blueprint §11). Each pair adds walk speed (studs/s).
Config.Shoes = {
	Enabled = true,
	List = {
		{ Key = "Sneakers", Cost = 1500, Speed = 2 },
		{ Key = "SportShoes", Cost = 6000, Speed = 4 },
		{ Key = "RunningShoes", Cost = 25000, Speed = 6 },
		{ Key = "BouncyBoots", Cost = 100000, Speed = 9 },
		{ Key = "RocketShoes", Cost = 400000, Speed = 12 },
		{ Key = "CloudSteppers", Cost = 1600000, Speed = 16 },
		{ Key = "LightningBoots", Cost = 6500000, Speed = 20 },
		{ Key = "CometKicks", Cost = 26000000, Speed = 25 },
	},
}

-- Rods (task 2.2): 25 tiers, 5 per material, bought in order; the best one owned is used.
-- Rod L costs Cost * CostGrowth^(L-2) (rod 1 is free). Fishing ease per level is in Config.Fishing.
Config.Rods = {
	Levels = 25,
	PerMaterial = 5,
	Materials = { "Wood", "Iron", "Gold", "Crystal", "Cosmic" },
	Colors = { "c98a4a", "a9b0bf", "f5bf2e", "7fe3ff", "9a6bff" },
	Cost = 400,
	CostGrowth = 2.15,
	LuckPerLevel = 0.04, -- +4% luck per level above 1
}

-- Pen expansion with money (task 2.4): +Step slots per purchase up to Config.Pen.MaxSlots.
Config.PenUpgrade = { Step = 5, Cost = 2000, CostGrowth = 2.1 }

-- Cat treats (task 2.5, blueprint §12): 10 minutes each; buying again adds 10 minutes. Price = the larger
-- of Base and IncomeSeconds of the player's current income.
Config.Treats = {
	Seconds = 600,
	List = {
		{ Key = "Luck", Name = "LuckyTreat", Mult = 1.5, Base = 1500, IncomeSeconds = 180 },
		{ Key = "Money", Name = "GoldenFish", Mult = 2, Base = 3000, IncomeSeconds = 300 },
		{ Key = "Easy", Name = "Catnip", Mult = 1, Base = 1000, IncomeSeconds = 120 },
	},
}
Config.Shop = { BuyRate = { maxCalls = 5, window = 1 } }

-- Mutations (task 2.9, blueprint §14): rolled once when a cat is caught or comes out of a crate, Basic-
-- Legendary only; Chance (%) x luck; Money multiplies the cat's income.
Config.Mutations = {
	List = {
		{ Key = "Glow", Chance = 0.5, Money = 10 },
		{ Key = "Rainbow", Chance = 1.5, Money = 5 },
		{ Key = "Gold", Chance = 4, Money = 2 },
	},
	MaxTier = 4,
}

-- Collection book (task 2.8): every full tier adds TierBonus to money, the whole book adds AllBonus.
Config.Book = { TierBonus = 0.05, AllBonus = 0.25 }

-- Rebirth (task 2.7): rebirth r + 1 needs Strength >= Strength * Growth^r.
Config.RebirthNeed = { Strength = 1.5e8, Growth = 4 } -- R4 option B

-- Extra systems (tasks 2.10 - 2.16). Money rewards = max(Base, Seconds of the player's income).
Config.Offline = { MaxHours = 8, Share = 0.5, MinSeconds = 120 } -- income while away, at half rate
Config.Login = { -- a 7-day cycle; missing a day does not reset it; day 7 is the big one
	{ Money = { Base = 500, Seconds = 120 } },
	{ Money = { Base = 1000, Seconds = 240 } },
	{ Treat = "Luck" },
	{ Money = { Base = 2500, Seconds = 480 } },
	{ Treat = "Money" },
	{ Money = { Base = 5000, Seconds = 900 } },
	{ Crate = "Gold", Money = { Base = 10000, Seconds = 1800 } },
}
Config.Playtime = { -- minutes played today -> gift (each once per UTC day)
	{ Minutes = 5, Money = { Base = 300, Seconds = 60 } },
	{ Minutes = 10, Treat = "Easy" },
	{ Minutes = 20, Money = { Base = 1000, Seconds = 180 } },
	{ Minutes = 30, Crate = "Wood" },
	{ Minutes = 45, Treat = "Luck" },
	{ Minutes = 60, Money = { Base = 4000, Seconds = 600 } },
	TickSeconds = 10,
}
Config.Quests = { -- 3 a day, picked from these kinds; Goal grows a little with rebirths
	PerDay = 3,
	Kinds = {
		{ Key = "Catch", Goal = 5, Money = { Base = 1500, Seconds = 300 } },
		{ Key = "CatchRare", Goal = 2, Money = { Base = 2500, Seconds = 420 } },
		{ Key = "Train", Goal = 300, Money = { Base = 1000, Seconds = 240 } }, -- seconds training
		{ Key = "Hit", Goal = 2, Money = { Base = 1500, Seconds = 300 } },
		{ Key = "Crate", Goal = 2, Money = { Base = 2000, Seconds = 300 } },
		{ Key = "Like", Goal = 1, Money = { Base = 800, Seconds = 180 } },
	},
}
Config.Codes = { -- gift codes (upper case); each player once. Add new ones here and publish.
	SWEETPOTATO = { Money = 5000, Treat = "Luck" },
	MEOW = { Money = 2000 },
}
Config.Group = { Money = 10000, Treat = "Luck", TreatSeconds = 1800 } -- joining Config.GroupId
Config.Leaderboards = {
	-- R4: Income is stored as log10(1 + income) x LogScale (OrderedDataStore holds integers up to ~9.2e18 only)
	Stores = { Income = "Sweetpotato_LB_Income_v2", Cats = "Sweetpotato_LB_Cats_v1" },
	LogScale = 1e6,
	WriteEvery = 120, -- seconds between a player's score writes
	ReadEvery = 120,
	Show = 10,
}
Config.Rewards = { ClaimRate = { maxCalls = 4, window = 1 }, CodeRate = { maxCalls = 2, window = 3 } }

-- Trading (task 2.17, blueprint §15): same server, up to 6 cats a side, both Ready -> 5 s -> swap.
Config.Trade = {
	MaxCats = 6,
	CountdownSeconds = 5,
	RequestSeconds = 20, -- an invite expires after this
	LogStore = "Sweetpotato_TradeLog_v1",
	Rate = { maxCalls = 8, window = 1 },
}

-- Cat crates (task 2.6, blueprint §12): bought with in-game money, odds (%) shown before buying, no
-- Secret. Costs set so a crate pays itself back in about 3 / 5 / 10 / 20 minutes of its average cat.
Config.Crates = {
	List = {
		{ Key = "Paper", Cost = 2000, Color = "e8d6ab", Odds = { Basic = 75, Rare = 22, Epic = 3 } },
		{ Key = "Wood", Cost = 25000, Color = "c98a4a", Odds = { Basic = 40, Rare = 40, Epic = 17, Legendary = 3 } },
		{ Key = "Gold", Cost = 150000, Color = "f5bf2e", Odds = { Rare = 50, Epic = 38, Legendary = 12 } },
		{ Key = "Diamond", Cost = 900000, Color = "7fe3ff", Odds = { Epic = 62, Legendary = 37.5, Mythical = 0.5 } },
	},
	BuyRate = { maxCalls = 2, window = 1 },
	RevealSeconds = 1.2,
	CostRebirth = 3, -- R4: crate prices x3 per rebirth (their cats are x3.6 heavier)
}

-- Sound (task 2.23). Ids picked by the developer (docs/Sweetpotato_Sounds.xlsx, 2026-11-08; each checked in Studio:
-- audio, loads in this game). 0 = silent. Never pick ids for them.
Config.Sounds = {
	-- UI
	click = 140323850218372, -- every button
	open = 140323850218372, -- a window opens
	error = 132281440773764, -- not enough money, locked, need Strength, pen full
	toast = 15524323710, -- small notices
	claim = 96102213526905, -- rewards, daily login, gifts, quests, codes
	buy = 133292918309565, -- shop purchases, upgrades, Robux purchases
	coins = 135483737426662, -- selling a cat, money rewards, offline income
	-- catching
	cast = 12222200, -- the rod swings out (anyone near)
	reel = 79404754846319, -- loop while your own minigame runs
	catch = 86740905540872, -- you won the minigame
	escape = 119036163643069, -- the cat got away
	meow = 134699420140804, -- hidden cats now and then (a hint), a caught cat
	-- carrying and the bat
	swing = 135315310485417, -- a bat swing (anyone near)
	bonk = 115569575216445, -- a bat hit lands
	drop = 90752223133261, -- a carried cat is knocked loose
	deliver = 135478009117226, -- a cat reaches your pen
	-- training and progress
	train = 132948338000932, -- each Strength / Speed gain (soft)
	rebirth = 74093722719233,
	like = 17520503095, -- a like given or received
	fanfare = 1846266840, -- a Mythical / Secret cat caught
	-- crates
	crate_shake = 9116529947,
	crate_reveal = 131140412621007,
	crate_rare = 118315466257318, -- Legendary or better
	-- events
	event_start = 119708787414764, -- a Mythical / Secret event or server luck starts
}
Config.SoundVolumes = { default = 0.5, reel = 0.3, train = 0.25, meow = 0.4, click = 0.4 }
Config.SoundRange = 90 -- 3D sounds fade out by this distance (studs)
Config.SoundMeow = { Every = { 8, 16 }, Range = 70 } -- a hidden cat near the camera meows every 8-16 s
Config.SoundTrainGap = 0.3 -- seconds between two training sounds
-- Music: Lobby in the lobby, Zones out in the zones, Mythical / Secret while that event is live.
Config.Music = { Lobby = 128349135892088, Zones = 115565653791292, Mythical = 1839444520, Secret = 78152030908975 }
Config.MusicVolume = 0.35
Config.MusicFade = 1.5 -- seconds of cross-fade

return Config
