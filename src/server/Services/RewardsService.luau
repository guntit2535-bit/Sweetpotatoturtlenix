--!strict
-- Rewards (tasks 2.10 - 2.16; Tamer Academy's RewardsService / LoginService / CodeService / GroupChestService,
-- SKY PUTT's playtime gifts and quests), all claimed in one Rewards window:
--   offline income   on join: time away (max 8 h) x income x 50% (Config.Offline), with a toast
--   daily login      a 7-day cycle (Config.Login), one claim per UTC day; day 7 is the big one
--   playtime gifts   minutes played today (Config.Playtime), each gift once per UTC day
--   daily quests     3 a day (shared/Rewards.pickQuests), progress from Util/Progress, claim when done
--   gift codes       Config.Codes, each player once
--   group reward     members of Config.GroupId, once
-- Money rewards follow the player's income (shared/Rewards.money). Treats add their minutes; crates roll for
-- free into the pen (CrateService.give). Every claim is saved before its toast. Player attribute
-- "RewardsReady" = something can be claimed (the HUD button's "!").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Cats = require(Shared.Cats)
local Config = require(Shared.Config)
local Crates = require(Shared.Crates)
local Format = require(Shared.Format)
local Rewards = require(Shared.Rewards)
local Validate = require(Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local Progress = require(script.Parent.Parent.Util.Progress)
local CarryService = require(script.Parent.CarryService)
local CrateService = require(script.Parent.CrateService)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local PenService = require(script.Parent.PenService)

local RewardsService = {}

local function today(): number
	return Rewards.day(os.time())
end

-- New UTC day: playtime and quests start over.
local function rollDay(player: Player)
	local day = today()
	DataService.UpdateQuiet(player, function(d)
		if d.PlayDay ~= day then
			d.PlayDay = day
			d.PlaySeconds = 0
			d.PlayClaimed = 0
		end
		if d.QuestDay ~= day then
			d.QuestDay = day
			d.Quests = Rewards.pickQuests(day * 7919 + player.UserId)
		end
	end)
end

local function ready(player: Player): boolean
	local d = DataService.GetData(player)
	if not d then
		return false
	end
	if d.LoginDay ~= today() then
		return true
	end
	for i, g in ipairs(Config.Playtime) do
		if d.PlaySeconds >= g.Minutes * 60 and not Rewards.claimed(d.PlayClaimed, i) then
			return true
		end
	end
	for _, q in d.Quests do
		if q.Progress >= q.Goal and not q.Claimed then
			return true
		end
	end
	return false
end

local function refreshReady(player: Player)
	local r = ready(player)
	if player:GetAttribute("RewardsReady") ~= r then
		player:SetAttribute("RewardsReady", r)
	end
end

-- Gives a reward table { Money = spec | number, Treat = key, Crate = key }.
local function grant(player: Player, reward: any, treatSeconds: number?)
	local income = PenService.incomeRate(player)
	local money = if type(reward.Money) == "number" then reward.Money else Rewards.money(reward.Money, income)
	DataService.Update(player, function(d)
		if money > 0 then
			d.Money += money
		end
		if reward.Treat then
			d.Boosts[reward.Treat] = math.max(os.time(), d.Boosts[reward.Treat] or 0) + (treatSeconds or Config.Treats.Seconds)
		end
	end)
	if reward.Crate then
		if not CrateService.give(player, reward.Crate) then
			-- pen full: the crate's value in money instead
			local d = DataService.GetData(player)
			DataService.AddMoney(player, Crates.cost(reward.Crate, if d then d.Rebirths else 0))
		end
	end
	DataService.SaveAsync(player)
	if money > 0 then
		Notify.send(player, "RewardMoney", { money = Format.short(money) }, "good")
	end
	if reward.Treat then
		for _, t in Config.Treats.List do
			if t.Key == reward.Treat then
				Notify.send(player, "Bought", { nameKey = "Treat" .. t.Name }, "good")
			end
		end
	end
end

local function onClaim(player: Player, rawKind: unknown, rawIndex: unknown)
	local kind = Validate.oneOf(rawKind, { "Login", "Playtime", "Quest", "Group" })
	local d = DataService.GetData(player)
	if not kind or not d then
		return
	end
	rollDay(player)
	if kind == "Login" then
		if d.LoginDay == today() then
			return
		end
		local step = d.LoginStep
		DataService.Update(player, function(x)
			x.LoginDay = today()
			x.LoginStep = step % #Config.Login + 1
		end)
		grant(player, Config.Login[step])
	elseif kind == "Playtime" then
		local i = Validate.integer(rawIndex, 1, #Config.Playtime)
		local g = i and Config.Playtime[i]
		if not i or not g or Rewards.claimed(d.PlayClaimed, i) or d.PlaySeconds < g.Minutes * 60 then
			return
		end
		DataService.Update(player, function(x)
			x.PlayClaimed = Rewards.mark(x.PlayClaimed, i :: number)
		end)
		grant(player, g)
	elseif kind == "Quest" then
		local i = Validate.integer(rawIndex, 1, #d.Quests)
		local q = i and d.Quests[i]
		if not q or q.Claimed or q.Progress < q.Goal then
			return
		end
		DataService.Update(player, function(x)
			x.Quests[i :: number].Claimed = true
		end)
		local k = Rewards.questKind(q.Kind)
		grant(player, { Money = if k then k.Money else nil })
	elseif kind == "Group" then
		if d.GroupClaimed or Config.GroupId == 0 then
			return
		end
		local ok, member = pcall(function()
			return player:IsInGroupAsync(Config.GroupId)
		end)
		if not ok or not member then
			Notify.send(player, "GroupJoinFirst", nil, "info")
			return
		end
		DataService.Update(player, function(x)
			x.GroupClaimed = true
		end)
		grant(player, { Money = Config.Group.Money, Treat = Config.Group.Treat }, Config.Group.TreatSeconds)
	end
	refreshReady(player)
end

local function onCode(player: Player, raw: unknown)
	local text = Validate.string(raw, 30)
	local d = DataService.GetData(player)
	if not text or not d then
		return
	end
	local code = string.upper((string.gsub(text, "%s", "")))
	local reward = (Config.Codes :: any)[code]
	if not reward then
		Notify.send(player, "CodeBad", nil, "bad")
		return
	end
	if d.CodesUsed[code] then
		Notify.send(player, "CodeUsed", nil, "bad")
		return
	end
	DataService.Update(player, function(x)
		x.CodesUsed[code] = true
	end)
	grant(player, reward)
end

local function onProgress(player: Player, kind: string, amount: number)
	local d = DataService.GetData(player)
	if not d then
		return
	end
	rollDay(player)
	local changed = false
	for _, q in d.Quests do
		if q.Kind == kind and not q.Claimed and q.Progress < q.Goal then
			q.Progress = math.min(q.Goal, q.Progress + amount)
			changed = true
		end
	end
	if changed then
		DataService.Update(player, function() end)
		refreshReady(player)
	end
end

local function offline(player: Player)
	task.wait(2) -- the pen and its income are set up first
	local last = DataService.LastOnlineAtJoin(player)
	if last <= 0 or not DataService.IsLoaded(player) then
		return
	end
	local away = os.time() - last
	local money = Rewards.offline(away, PenService.incomeRate(player))
	if money > 0 then
		DataService.AddMoney(player, money)
		Notify.send(player, "OfflineIncome", { money = Format.short(money), min = math.floor(math.min(away, Config.Offline.MaxHours * 3600) / 60) }, "good")
	end
end

function RewardsService:Init()
	Guard.onEvent("ClaimReward", Config.Rewards.ClaimRate, onClaim)
	Guard.onEvent("RedeemCode", Config.Rewards.CodeRate, onCode)
	Progress.Added:Connect(onProgress)
	DebugService.register("playtime", "!playtime M  set today's minutes played", function(player, args)
		local m = tonumber(args[1])
		if not m then
			return "usage: !playtime 30"
		end
		DataService.Update(player, function(d)
			d.PlaySeconds = m * 60
		end)
		refreshReady(player)
		return `playtime = {m} min`
	end)
	DebugService.register("newday", "!newday  as if a new UTC day began (login, gifts, quests)", function(player)
		DataService.Update(player, function(d)
			d.LoginDay = 0
			d.PlayDay = 0
			d.QuestDay = 0
		end)
		rollDay(player)
		refreshReady(player)
		return "new day"
	end)
end

function RewardsService:Start()
	DataService.PlayerLoaded:Connect(function(player)
		rollDay(player)
		refreshReady(player)
		task.spawn(offline, player)
	end)
	CarryService.Delivered:Connect(function(player, kind)
		Progress.add(player, "Catch", 1)
		local design = Cats.ById[kind]
		if design and design.Tier >= 2 then
			Progress.add(player, "CatchRare", 1)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Playtime.TickSeconds)
			for _, player in Players:GetPlayers() do
				if DataService.IsLoaded(player) then
					rollDay(player)
					DataService.UpdateQuiet(player, function(d)
						d.PlaySeconds += Config.Playtime.TickSeconds
						player:SetAttribute("PlaySeconds", d.PlaySeconds)
					end)
					refreshReady(player)
				end
			end
		end
	end)
end

return RewardsService
