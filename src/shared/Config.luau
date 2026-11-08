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
	-- Gate: enter with Strength >= Strength OR Rebirths >= Rebirths. Odds: tier key -> weight (%).
	-- KgSkew overrides Config.KgSkew (lower = heavier cats). Cats: wild cats kept in the zone at once.
	Zones = {
		{ Key = "Backyard", Inner = 150, Outer = 330, Strength = 0, Rebirths = 0, Cats = 18, Odds = { Basic = 90, Rare = 10 } },
		{ Key = "TownMarket", Inner = 330, Outer = 510, Strength = 10, Rebirths = 1, Cats = 18, Odds = { Basic = 30, Rare = 60, Epic = 10 } },
		{ Key = "Forest", Inner = 510, Outer = 690, Strength = 60, Rebirths = 2, Cats = 18, Odds = { Rare = 35, Epic = 55, Legendary = 10 } },
		{ Key = "SnowMountain", Inner = 690, Outer = 870, Strength = 300, Rebirths = 4, Cats = 18, Odds = { Epic = 45, Legendary = 55 } },
		{ Key = "SkyIslands", Inner = 870, Outer = 1050, Strength = 1500, Rebirths = 6, Cats = 18, Odds = { Epic = 20, Legendary = 80 }, KgSkew = 0.8 },
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

-- Cat tiers (blueprint §5): designs per tier, weight range, money per second per kg, catch difficulty.
-- Income of a cat = Rate x kg (x mutations / boosts later). Basic-Legendary are one size; Mythical
-- 1.3-2x and Secret 3-6x by weight (CatRules.size).
Config.Tiers = {
	{ Key = "Basic", Count = 150, MinKg = 1, MaxKg = 10, Rate = 0.5, Color = "9aa7bd" },
	{ Key = "Rare", Count = 110, MinKg = 10, MaxKg = 60, Rate = 0.8, Color = "3da5ff" },
	{ Key = "Epic", Count = 70, MinKg = 60, MaxKg = 300, Rate = 1.2, Color = "a46bff" },
	{ Key = "Legendary", Count = 45, MinKg = 300, MaxKg = 1500, Rate = 2, Color = "ffb020" },
	{ Key = "Mythical", Count = 20, MinKg = 1500, MaxKg = 8000, Rate = 4, Color = "ff5fa2", SizeMin = 1.3, SizeMax = 2 },
	{ Key = "Secret", Count = 5, MinKg = 10000, MaxKg = 50000, Rate = 8, Color = "18c9b9", SizeMin = 3, SizeMax = 6 },
}
Config.KgSkew = 2 -- kg = min + (max - min) * u^KgSkew: heavy cats of a tier are rarer

-- Economy (task 1.6, option B "Normal" in docs/economy.md; tools/sim/economy.luau).
Config.Economy = {
	SellSeconds = 120, -- selling a cat pays this many seconds of its income
	IncomeTick = 1, -- seconds between pen income ticks
}

-- Training (tasks 1.15 / 1.16): one rep / step every Tick seconds; level L gives Gain * Growth^(L-1);
-- the next level costs Cost * CostGrowth^(L-1) money.
Config.Weights = { Levels = 25, Tick = 1, Gain = 0.1, Growth = 1.33, Cost = 100, CostGrowth = 2.5 }
Config.Treadmill = { Levels = 25, Tick = 1, Gain = 0.2, Growth = 1.4, Cost = 40, CostGrowth = 1.85 }
-- Walk speed from the Speed stat: Base + Bonus * ln(1 + Speed / Scale), at most Max (studs/s).
Config.Walk = { Base = 16, Bonus = 9, Scale = 10, Max = 60, LikeBuff = 2, LikeBuffSeconds = 300 }
Config.Rebirth = { Max = 25, MoneyMult = 1.5, StrengthMult = 1.5 }

-- Cat animation on the clients (shared/CatAnims clips on the CatModel rig).
Config.CatAnim = {
	Range = 160, -- only cats this close to the camera are animated (studs)
	RescanSeconds = 1, -- a cat whose joints have not all streamed in yet is looked up again this often
}

-- Languages: English is the default for every player, Thai is picked in Settings and saved.
Config.Language = {
	Default = "en",
}

-- Robux (milestone 2). Ids stay 0 until the developer creates them in the group's experience;
-- the launch check fails while any id is 0.
Config.Passes = {
	-- CLIENT PENDING: permanent game pass ("pass") or a timed boost sold as a developer product
	-- ("timed"), and its price. Default until the client answers: permanent pass.
	Speed2x = {
		Id = 0,
		Mode = "pass" :: "pass" | "timed",
		TimedMinutes = 15, -- used only when Mode = "timed"
		PriceRobux = 0, -- 0 = not decided; the client confirms every Robux price
	},
}

-- CLIENT PENDING: keep the 8 shoes next to the treadmill (both add speed), or drop the shoes.
-- Default until the client answers: keep them (blueprint §11).
Config.Shoes = {
	Enabled = true,
}

return Config
