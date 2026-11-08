--!strict
-- Reward rules (tasks 2.10 - 2.16). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Rewards = Shared.require("Rewards")
local Config = Shared.require("Config")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Rewards: {message}`)
	end
end

check(Rewards.day(0) == 0 and Rewards.day(86399) == 0 and Rewards.day(86400) == 1, "UTC days")
check(Rewards.money({ Base = 500, Seconds = 120 }, 0) == 500, "money base")
check(Rewards.money({ Base = 500, Seconds = 120 }, 100) == 12000, "money follows income")
check(Rewards.offline(60, 100) == 0, "a minute away gives nothing")
check(Rewards.offline(3600, 100) == 3600 * 100 * Config.Offline.Share, "an hour away at half rate")
check(Rewards.offline(30 * 3600, 100) == Config.Offline.MaxHours * 3600 * 100 * Config.Offline.Share, "capped at 8 hours")

for seed = 1, 50 do
	local q = Rewards.pickQuests(seed)
	check(#q == Config.Quests.PerDay, "3 quests")
	local seen = {}
	for _, x in q do
		check(not seen[x.Kind], "distinct kinds")
		seen[x.Kind] = true
		check(Rewards.questKind(x.Kind) ~= nil and x.Progress == 0 and not x.Claimed, "fresh quest")
	end
end
local a, b = Rewards.pickQuests(77), Rewards.pickQuests(77)
check(a[1].Kind == b[1].Kind and a[3].Kind == b[3].Kind, "same seed, same quests")

local mask = 0
check(not Rewards.claimed(mask, 3), "nothing claimed")
mask = Rewards.mark(mask, 3)
mask = Rewards.mark(mask, 3)
mask = Rewards.mark(mask, 1)
check(Rewards.claimed(mask, 3) and Rewards.claimed(mask, 1) and not Rewards.claimed(mask, 2), "bits")
check(mask == 5, "marking twice changes nothing")
check(#Config.Login == 7, "7-day login cycle")

if failures > 0 then
	error(`Rewards: {failures} failure(s)`)
end
print("PASS Rewards")
