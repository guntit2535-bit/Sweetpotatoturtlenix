--!strict
-- Options for tools/sim/endgame.luau: each is the Config changes it makes (the run puts them back after).
-- X2 (revision 4 item 6): "Now" keeps the training levels through a rebirth; "Old" resets them as before.
local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local RB = Config.Rebirth

return {
	{ name = "Old: rebirth resets the levels", set = { { RB, "KeepLevels", false } } },
}
