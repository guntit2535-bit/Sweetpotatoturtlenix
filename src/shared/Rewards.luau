--!strict
-- Reward rules (tasks 2.10 - 2.16), pure so the window and the server agree and tests/Rewards.spec.luau can
-- check them:
--   Rewards.day(osTime) -> UTC day number
--   Rewards.money(spec, income) -> money for { Base, Seconds } at this income per second
--   Rewards.offline(awaySeconds, income) -> money for time away (Config.Offline)
--   Rewards.pickQuests(seed) -> today's quests (Config.Quests.PerDay distinct kinds)
--   Rewards.claimed(mask, i) / Rewards.mark(mask, i) -> playtime gift bits

local Config = require(script.Parent.Config)

local Rewards = {}

function Rewards.day(t: number): number
	return t // 86400
end

function Rewards.money(spec: { Base: number, Seconds: number }?, income: number): number
	if not spec then
		return 0
	end
	return math.floor(math.max(spec.Base, income * spec.Seconds))
end

function Rewards.offline(away: number, income: number): number
	local o = Config.Offline
	if away < o.MinSeconds then
		return 0
	end
	return math.floor(math.min(away, o.MaxHours * 3600) * income * o.Share)
end

-- Distinct quest kinds for the day, picked by a seed (the server uses the day and the player's id).
function Rewards.pickQuests(seed: number): { { Kind: string, Goal: number, Progress: number, Claimed: boolean } }
	local kinds = table.clone(Config.Quests.Kinds)
	local state = math.floor(math.abs(seed)) % 2147483648
	local out = {}
	for _ = 1, math.min(Config.Quests.PerDay, #kinds) do
		state = (state * 1103515245 + 12345) % 2147483648
		local i = state % #kinds + 1
		local k = table.remove(kinds, i)
		if k then
			table.insert(out, { Kind = k.Key, Goal = k.Goal, Progress = 0, Claimed = false })
		end
	end
	return out
end

function Rewards.questKind(key: string): any
	for _, k in Config.Quests.Kinds do
		if k.Key == key then
			return k
		end
	end
	return nil
end

function Rewards.claimed(mask: number, i: number): boolean
	return (mask // (2 ^ (i - 1))) % 2 == 1
end

function Rewards.mark(mask: number, i: number): number
	if Rewards.claimed(mask, i) then
		return mask
	end
	return mask + 2 ^ (i - 1)
end

return Rewards
