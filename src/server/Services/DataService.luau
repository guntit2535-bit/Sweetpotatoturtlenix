--!strict
-- Loads, holds and saves player data with ProfileStore (task 1.2; based on Pet Storm Escape).
-- Other services read data with GetData() and change it only through the functions below, so the
-- leaderstats, the player attributes and the owner's client copy stay in sync.
--
-- What clients see:
--   - player attributes Money, Strength, Speed, WeightsLevel, TreadLevel, Rebirths, PenSlots, CatCount,
--     LikesReceived, Language (every client: HUD, pen signs);
--   - the owner's snapshot of the whole save (minus ReceiptIds) through PlayerData after changes, and
--     once on request with GetData().
-- Studio: Workspace attribute FreshSave = true -> every player gets a new in-memory save (ProfileStore
-- Mock) that is never written.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local Guard = require(script.Parent.Parent.Util.Guard)
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local DataTemplate = require(Shared.DataTemplate)
local Migrate = require(Shared.Migrate)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Text = require(Shared.Text)
local SettingsService = require(script.Parent.SettingsService)

type Data = DataTemplate.Data
type Profile = ProfileStore.Profile<Data>

-- NEVER RENAME Config.Data.StoreName: a new name starts every player from zero.
local PlayerStore = ProfileStore.New(Config.Data.StoreName, DataTemplate.Template)

local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local lastOnlineAtJoin: { [Player]: number } = {} -- LastOnline as loaded (offline income, task 2.10)
local loadedEvent = Instance.new("BindableEvent")
local changedEvent = Instance.new("BindableEvent")
local playerDataRemote: RemoteEvent

local DataService = {}

-- Fires (player) once the player's data is loaded and usable.
DataService.PlayerLoaded = loadedEvent.Event
-- Fires (player) at the end of a frame in which the data changed (not for UpdateQuiet).
DataService.Changed = changedEvent.Event

local function log(message: string)
	print(`[Sweetpotato] DataService: {message}`)
end

local function isFiniteNumber(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function profileKey(player: Player): string
	return `Player_{player.UserId}`
end

local function freshSave(): boolean
	return RunService:IsStudio() and workspace:GetAttribute(Config.Data.FreshSaveAttribute) == true
end

local function dataOf(player: Player): Data?
	local profile = profiles[player]
	if profile then
		return profile.Data :: Data
	end
	return nil
end

local function setAttr(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function refreshPublic(player: Player)
	local data = dataOf(player)
	if not data then
		return
	end
	setAttr(player, "Money", data.Money)
	setAttr(player, "Strength", data.Strength)
	setAttr(player, "Speed", data.Speed)
	setAttr(player, "WeightsLevel", data.WeightsLevel)
	setAttr(player, "TreadLevel", data.TreadLevel)
	setAttr(player, "Rebirths", data.Rebirths)
	setAttr(player, "PenSlots", data.PenSlots)
	setAttr(player, "CatCount", DataTemplate.catCount(data))
	setAttr(player, "LikesReceived", data.LikesReceived)
	setAttr(player, "Language", data.Settings.Language)
	setAttr(player, "MusicOn", data.Settings.Music)
	setAttr(player, "SfxOn", data.Settings.Sfx)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild(Text.StatMoney)
		if money and money:IsA("StringValue") then
			money.Value = Format.short(data.Money)
		end
		local strength = leaderstats:FindFirstChild(Text.StatStrength)
		if strength and strength:IsA("StringValue") then
			strength.Value = Format.short(data.Strength)
		end
	end
end

-- Everything the owner may see (no ReceiptIds). Remotes copy the tables when sent.
local function snapshot(data: Data): { [string]: any }
	local copy: { [string]: any } = {}
	for key, value in data :: any do
		if key ~= "ReceiptIds" then
			copy[key] = value
		end
	end
	return copy
end

-- Sends the snapshot once at the end of this frame, however many changes happen in it.
local function markChanged(player: Player)
	refreshPublic(player)
	if dirty[player] then
		return
	end
	dirty[player] = true
	task.defer(function()
		dirty[player] = nil
		local data = dataOf(player)
		if data and player.Parent == Players then
			playerDataRemote:FireClient(player, snapshot(data))
			changedEvent:Fire(player)
		end
	end)
end

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { Text.StatMoney, Text.StatStrength } do
		local v = Instance.new("StringValue")
		v.Name = name
		v.Parent = leaderstats
	end
	leaderstats.Parent = player
end

local function onPlayerAdded(player: Player)
	local params: any = {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}
	local store: any = if freshSave() then PlayerStore.Mock else PlayerStore
	local key = if freshSave() then `Fresh_{player.UserId}_{os.clock()}` else profileKey(player)
	local profile = store:StartSessionAsync(key, params)

	if profile == nil then
		-- The player left while loading, or the DataStore did not answer in time.
		if player.Parent == Players then
			player:Kick(Text.get("DataLoadFailed", Text.Default))
		end
		return
	end

	if not freshSave() then
		profile:AddUserId(player.UserId) -- GDPR
	end
	profile:Reconcile() -- fill in fields added to the template after this save was made
	lastOnlineAtJoin[player] = profile.Data.LastOnline
	local fixes = DataTemplate.sanitize(profile.Data)
	if fixes > 0 then
		log(`repaired {fixes} value(s) in {player.Name}'s save`)
	end
	if Migrate.econ(profile.Data) then
		log(`converted {player.Name}'s save to the 99 Sx numbers (R4)`)
	end
	Migrate.tutorial(profile.Data) -- V4: new players start the tutorial, old saves have it done

	profile.OnSave:Connect(function()
		profile.Data.LastOnline = os.time()
	end)
	profile.OnSessionEnd:Connect(function()
		local lang = Text.resolve(profile.Data.Settings.Language)
		profiles[player] = nil
		dirty[player] = nil
		if player.Parent == Players then
			player:Kick(Text.get("DataSessionEnded", lang))
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	createLeaderstats(player)
	markChanged(player)
	log(`loaded {player.Name}{if freshSave() then " (FreshSave: nothing is written)" else ""}`)
	loadedEvent:Fire(player)
end

local releaseHooks: { (player: Player, data: Data) -> () } = {}

-- `hook(player, data)` runs when a player leaves, just before the save is closed: the last chance
-- to change it (a carried cat goes back to hiding, task 1.13). Must not yield.
function DataService.OnRelease(hook: (player: Player, data: Data) -> ())
	table.insert(releaseHooks, hook)
end

local function onPlayerRemoving(player: Player)
	dirty[player] = nil
	local profile = profiles[player]
	if profile then
		for _, hook in releaseHooks do
			local ok, err = pcall(hook, player, profile.Data)
			if not ok then
				warn(`[Sweetpotato] DataService release hook failed: {err}`)
			end
		end
		profile.Data.LastOnline = os.time()
		profile:EndSession()
	end
end

-- Public API ------------------------------------------------------------------

-- The player's data, or nil while it is still loading. Read only: change it through the
-- functions below so attributes, leaderstats and the client copy stay in sync.
function DataService.GetData(player: Player): Data?
	return dataOf(player)
end

-- os.time() the player was last online before this session (0 on a first join), as loaded.
function DataService.LastOnlineAtJoin(player: Player): number
	return lastOnlineAtJoin[player] or 0
end

function DataService.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- Adds (or with a negative amount, removes) money; never below 0. False if not loaded / not finite.
-- R4: Money, Strength and Speed never pass Config.Economy.Max (99 Sx).
local function capStats(data: Data)
	local max = Config.Economy.Max
	if data.Money > max then
		data.Money = max
	end
	if data.Strength > max then
		data.Strength = max
	end
	if data.Speed > max then
		data.Speed = max
	end
end

function DataService.AddMoney(player: Player, amount: number): boolean
	local data = dataOf(player)
	if not data or not isFiniteNumber(amount) then
		return false
	end
	data.Money = math.max(0, math.floor(data.Money + amount))
	capStats(data)
	markChanged(player)
	return true
end

-- Pen income every tick: fractions are carried in MoneyFrac so nothing is lost. Only the attributes
-- and leaderstats are updated (no snapshot every second). False if not loaded.
function DataService.AddIncome(player: Player, amount: number): boolean
	local data = dataOf(player)
	if not data or not isFiniteNumber(amount) or amount < 0 then
		return false
	end
	data.MoneyFrac += amount
	local wholeAmount = math.floor(data.MoneyFrac)
	if wholeAmount > 0 then
		data.MoneyFrac -= wholeAmount
		data.Money += wholeAmount
		capStats(data)
		refreshPublic(player)
	end
	return true
end

-- Removes money only if the player has enough. Returns true if paid.
function DataService.SpendMoney(player: Player, amount: number): boolean
	local data = dataOf(player)
	if not data or not isFiniteNumber(amount) or amount < 0 then
		return false
	end
	local cost = math.ceil(amount)
	if data.Money < cost then
		return false
	end
	data.Money -= cost
	markChanged(player)
	return true
end

-- Changes the data with `change` (must not yield) and sends the new snapshot.
-- Returns false if the data is not loaded.
function DataService.Update(player: Player, change: (data: Data) -> ()): boolean
	local data = dataOf(player)
	if not data then
		return false
	end
	change(data)
	capStats(data)
	markChanged(player)
	return true
end

-- Like Update, but only the attributes / leaderstats follow (no snapshot, no Changed): for values that
-- change every second (Strength while lifting, Speed on the treadmill).
function DataService.UpdateQuiet(player: Player, change: (data: Data) -> ()): boolean
	local data = dataOf(player)
	if not data then
		return false
	end
	change(data)
	capStats(data)
	refreshPublic(player)
	return true
end

-- Saves now and yields until the save is done (true), or Config.Data.SaveTimeout passes / the data
-- is not loaded (false). Use before showing results that must not be lost (catches, purchases).
-- Even on false the change stays in the profile and is saved by autosave or on leave.
function DataService.SaveAsync(player: Player): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	if freshSave() then
		return true -- nothing is written in a FreshSave test
	end

	local thread = coroutine.running()
	local done = false
	local connection: { Disconnect: (self: any) -> () }? = nil

	local function finish(success: boolean)
		if done then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
		end
		task.spawn(thread, success)
	end

	connection = profile.OnAfterSave:Connect(function()
		finish(true)
	end)
	task.delay(Config.Data.SaveTimeout, function()
		if not done then
			warn(`[Sweetpotato] DataService: save timed out for {player.Name}`)
		end
		finish(false)
	end)

	profile:Save()
	return coroutine.yield() :: boolean
end

-- Service lifecycle -------------------------------------------------------------

function DataService:Init()
	playerDataRemote = Remotes.event("PlayerData")
	Guard.onInvoke("GetData", Config.Data.GetDataRate, function(player: Player): unknown
		local data = dataOf(player)
		return if data then snapshot(data) else nil
	end)
	-- the Settings window's changes are saved here
	SettingsService.onChanged = function(player: Player, key: string, value: any)
		if key == "Language" then
			DataService.Update(player, function(data)
				data.Settings.Language = value
			end)
		elseif key == "Music" or key == "Sfx" then
			DataService.Update(player, function(data)
				(data.Settings :: any)[key] = value
			end)
		end
	end

	ProfileStore.OnError:Connect(function(message: string, storeName: string, key: string)
		warn(`[Sweetpotato] ProfileStore error ({storeName} / {key}): {message}`)
	end)
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return DataService
