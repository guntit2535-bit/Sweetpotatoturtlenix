--!strict
-- Agreed values that must not drift, and the shape of the CLIENT PENDING values.
-- Run by scripts/check.luau (lune). Fails by raising an error.

local Config = require("../src/shared/Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Config: {message}`)
	end
end

check(Config.MaxPlayers == 8, "8 players per server (one pen each)")
check(Config.Language.Default == "en", "English is the default language")
check(Config.Data.StoreName == "Sweetpotato_PlayerData_v1", "the save key never changes")
check(type(Config.GroupId) == "number", "GroupId is a number (0 = not known yet)")
local zones = Config.World.Zones
check(#zones == 5, "5 zones")
check(zones[1].Inner == Config.World.LobbyRadius, "zone 1 starts at the lobby edge")
for i = 2, #zones do
	check(zones[i].Inner == zones[i - 1].Outer, `zone {i} starts where zone {i - 1} ends`)
end
check(Config.World.Pens.Count == Config.MaxPlayers, "one pen per player")
local mode = Config.Passes.Speed2x.Mode
check(mode == "pass" or mode == "timed", "x2 Speed mode is pass or timed")
check(Config.Passes.Speed2x.TimedMinutes > 0, "x2 Speed timed minutes > 0")
check(type(Config.Shoes.Enabled) == "boolean", "Shoes.Enabled is a boolean")

if failures > 0 then
	error(`Config: {failures} failure(s)`)
end
print("PASS Config")
