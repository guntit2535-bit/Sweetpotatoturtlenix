--!strict
-- Trading cats (task 2.17, blueprint §15; Tamer Academy's TradeService without capsules). Same server only:
--   TradeRequest(userId) -> the other player gets TradeInvite (valid Config.Trade.RequestSeconds)
--   TradeRespond(fromUserId, accept) -> a session starts; both get TradeState
--   TradeSet(ids) -> my offer (up to 6 owned, unlocked cats); any change clears both Ready marks
--   TradeReady(on) -> both ready = a CountdownSeconds countdown; at its end the server re-checks everything
--     (shared/Trade.check: owned, unlocked, room in both pens) and swaps in one step (shared/Trade.swap), then
--     saves both and logs the trade (Config.Trade.LogStore). A failed check clears Ready and says why.
--   TradeCancel() / leaving / dying -> cancelled, nobody loses anything.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Trade = require(Shared.Trade)
local Validate = require(Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)

type Session = {
	a: Player,
	b: Player,
	offer: { [Player]: { string } },
	ready: { [Player]: boolean },
	ends: number?, -- server time the countdown ends
}

local TradeService = {}

local sessions: { [Player]: Session } = {}
local invites: { [Player]: { from: Player, at: number } } = {}
local stateRemote: RemoteEvent
local inviteRemote: RemoteEvent
local logStore: DataStore? = nil

local function other(s: Session, p: Player): Player
	return if s.a == p then s.b else s.a
end

local function catsInfo(player: Player, ids: { string }): { any }
	local d = DataService.GetData(player)
	local out = {}
	for _, id in ids do
		local c = d and d.Cats[id]
		if c then
			table.insert(out, { Id = id, Kind = c.Kind, Kg = c.Kg, Mutation = c.Mutation })
		end
	end
	return out
end

local function send(s: Session)
	for _, p in { s.a, s.b } do
		local o = other(s, p)
		stateRemote:FireClient(p, {
			partner = o.DisplayName,
			mine = s.offer[p],
			theirs = catsInfo(o, s.offer[o]),
			readyMine = s.ready[p] == true,
			readyTheirs = s.ready[o] == true,
			ends = s.ends,
		})
	end
end

local function finish(s: Session, key: string?)
	if sessions[s.a] == s then
		sessions[s.a] = nil
	end
	if sessions[s.b] == s then
		sessions[s.b] = nil
	end
	for _, p in { s.a, s.b } do
		if p.Parent == Players then
			stateRemote:FireClient(p, nil)
			if key then
				Notify.send(p, key, nil, if key == "TradeDone" then "good" else "info")
			end
		end
	end
end

local function complete(s: Session)
	local ad, bd = DataService.GetData(s.a), DataService.GetData(s.b)
	if not ad or not bd then
		finish(s, "TradeCancelled")
		return
	end
	local aIds, bIds = s.offer[s.a], s.offer[s.b]
	local ok, why = Trade.check(ad.Cats, aIds, ad.PenSlots, bd.Cats, bIds, bd.PenSlots)
	if not ok then
		s.ready = {}
		s.ends = nil
		for _, p in { s.a, s.b } do
			Notify.send(p, "TradeFail" .. (why or "Bad"), nil, "bad")
		end
		send(s)
		return
	end
	local summary = {
		at = os.time(),
		a = s.a.UserId,
		b = s.b.UserId,
		aGave = catsInfo(s.a, aIds),
		bGave = catsInfo(s.b, bIds),
	}
	-- one step, no yields: the cats leave one save and enter the other together
	Trade.swap(ad, aIds, bd, bIds)
	DataService.Update(s.a, function() end)
	DataService.Update(s.b, function() end)
	finish(s, "TradeDone")
	task.spawn(DataService.SaveAsync, s.a)
	task.spawn(DataService.SaveAsync, s.b)
	if logStore then
		task.spawn(function()
			pcall(function()
				(logStore :: DataStore):SetAsync(`{summary.at}_{summary.a}_{summary.b}`, HttpService:JSONEncode(summary))
			end)
		end)
	end
	print(`[Sweetpotato] TradeService: {s.a.Name} gave {#aIds}, {s.b.Name} gave {#bIds}`)
end

local function onRequest(player: Player, rawId: unknown)
	local id = Validate.integer(rawId, -1e15, 1e15) -- Studio test players have negative ids
	local target = id and Players:GetPlayerByUserId(id)
	if not target or target == player or not DataService.IsLoaded(player) then
		return
	end
	if sessions[target] or sessions[player] then
		Notify.send(player, "TradeBusy", { name = target.DisplayName }, "info")
		return
	end
	invites[target] = { from = player, at = os.clock() }
	inviteRemote:FireClient(target, player.UserId, player.DisplayName)
	Notify.send(player, "TradeSent", { name = target.DisplayName }, "info")
end

local function onRespond(player: Player, rawId: unknown, rawAccept: unknown)
	local id = Validate.integer(rawId, -1e15, 1e15) -- Studio test players have negative ids
	local accept = Validate.boolean(rawAccept)
	local inv = invites[player]
	invites[player] = nil
	if not inv or not id or inv.from.UserId ~= id or accept == nil then
		return
	end
	local from = inv.from
	if not accept or os.clock() - inv.at > Config.Trade.RequestSeconds or from.Parent ~= Players or sessions[from] or sessions[player] then
		return
	end
	local s: Session = { a = from, b = player, offer = { [from] = {}, [player] = {} }, ready = {}, ends = nil }
	sessions[from] = s
	sessions[player] = s
	send(s)
end

local function onSet(player: Player, raw: unknown)
	local s = sessions[player]
	local d = DataService.GetData(player)
	if not s or not d or type(raw) ~= "table" then
		return
	end
	local ids = {}
	for i, v in raw :: { any } do
		if type(i) ~= "number" or i > Config.Trade.MaxCats then
			return
		end
		local id = Validate.id(v)
		if not id then
			return
		end
		table.insert(ids, id)
	end
	if not Trade.validOffer(d.Cats, ids) then
		return
	end
	s.offer[player] = ids
	s.ready = {}
	s.ends = nil
	send(s)
end

local function onReady(player: Player, raw: unknown)
	local s = sessions[player]
	local on = Validate.boolean(raw)
	if not s or on == nil then
		return
	end
	s.ready[player] = on
	if s.ready[s.a] and s.ready[s.b] then
		s.ends = workspace:GetServerTimeNow() + Config.Trade.CountdownSeconds
	else
		s.ends = nil
	end
	send(s)
end

function TradeService:Init()
	stateRemote = Remotes.event("TradeState")
	inviteRemote = Remotes.event("TradeInvite")
	local rate = Config.Trade.Rate
	Guard.onEvent("TradeRequest", rate, onRequest)
	Guard.onEvent("TradeRespond", rate, onRespond)
	Guard.onEvent("TradeSet", rate, onSet)
	Guard.onEvent("TradeReady", rate, onReady)
	Guard.onEvent("TradeCancel", rate, function(player)
		local s = sessions[player]
		if s then
			finish(s, "TradeCancelled")
		end
	end)
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.Trade.LogStore)
	end)
	if ok then
		logStore = store
	end
end

function TradeService:Start()
	Players.PlayerRemoving:Connect(function(player)
		invites[player] = nil
		local s = sessions[player]
		if s then
			finish(s, "TradeCancelled")
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = workspace:GetServerTimeNow()
			local done: { Session } = {}
			for _, s in sessions do
				if s.ends and now >= s.ends and not table.find(done, s) then
					table.insert(done, s)
				end
			end
			for _, s in done do
				if sessions[s.a] == s then
					complete(s)
				end
			end
		end
	end)
end

return TradeService
