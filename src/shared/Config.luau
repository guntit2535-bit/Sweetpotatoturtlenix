--!strict
-- Every number in the game lives here. Blueprint numbers (docs/BLUEPRINT.md) are starting values:
-- tune them here after playtests, never in services or controllers.
-- Sections are added by the task that first needs them (docs/PLAN.md).
-- Values marked CLIENT PENDING wait for the client's answer (CLAUDE.md "Waiting for the client").

local Config = {}

Config.GameName = "Sweetpotatoturtlenix"
Config.MaxPlayers = 8 -- one pen per player in the lobby (blueprint §1, §6)

-- CLIENT PENDING: the Roblox group that owns the game. 0 = not known yet (group reward, pass checks).
Config.GroupId = 0

-- Debug commands (task 1.3). Studio always; live servers only for these user ids. Off at launch.
Config.Debug = {
	Enabled = true, -- set false in the launch checklist
	Admins = { 11657887907 }, -- the developer (GUN2535551)
	Prefix = "!",
}

-- Saves (task 1.2). NEVER rename StoreName after launch: every player's progress would be lost.
Config.Data = {
	StoreName = "Sweetpotato_PlayerData_v1",
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
