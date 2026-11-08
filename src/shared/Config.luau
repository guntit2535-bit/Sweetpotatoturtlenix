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
	Zones = {
		{ Key = "Backyard", Inner = 150, Outer = 330 },
		{ Key = "TownMarket", Inner = 330, Outer = 510 },
		{ Key = "Forest", Inner = 510, Outer = 690 },
		{ Key = "SnowMountain", Inner = 690, Outer = 870 },
		{ Key = "SkyIslands", Inner = 870, Outer = 1050 },
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
}

-- Training (tasks 1.15 / 1.16); costs and gains come from the economy pick (task 1.6).
Config.Weights = { Levels = 25 }
Config.Treadmill = { Levels = 25 }
Config.Rebirth = { Max = 25 }

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
