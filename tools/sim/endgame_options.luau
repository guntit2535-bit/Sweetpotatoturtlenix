--!strict
-- Options for tools/sim/endgame.luau: each is the Config changes it makes (the run puts them back after).
-- Client 2026-11-15: the first rebirths easy, then slowly harder (Config.RebirthNeed.Early scales rebirth n's need).
local Shared = require("../../tests/lib/Shared")
local Config = Shared.require("Config")
local N = Config.RebirthNeed

return {
	{ name = "A easy (x0.003, 0.03, 0.2, 0.6)", set = { { N, "Early", { 0.003, 0.03, 0.2, 0.6 } } } },
	{ name = "B very easy (x0.001, 0.01, 0.08, 0.3, 0.7)", set = { { N, "Early", { 0.001, 0.01, 0.08, 0.3, 0.7 } } } },
	{ name = "C = A, end kept ~53h (Growth 4.02)", set = { { N, "Early", { 0.003, 0.03, 0.2, 0.6 } }, { N, "Growth", 4.02 } } },
}
