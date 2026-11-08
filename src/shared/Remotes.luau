--!strict
-- Creates (server) or finds (client) RemoteEvents and RemoteFunctions in ReplicatedStorage.Remotes.
--
-- Every remote of the game is listed below and created by the server at start (Remotes.createAll in
-- init.server), so a client never waits for one that is made late (Tamer Academy lesson).
-- Server: client -> server handlers go through src/server/Util/Guard (type checks, rate limit, pcall).
-- Client: Remotes.event("SetSetting") waits until the server has created it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local FOLDER_NAME = "Remotes"
local IS_SERVER = RunService:IsServer()

local Remotes = {}

-- The full list (checked for duplicates by tests/Remotes.spec.luau). Add new remotes here.
Remotes.Events = {
	"SetSetting", -- client -> server: (key, value), task 1.1
	"PlayerData", -- server -> owner: data snapshot after changes, task 1.2
	"Notify", -- server -> client: (textKey, vars?, kind?) a toast, task 1.8
	"SellCat", -- client -> server: (catId), task 1.8
	"LockCat", -- client -> server: (catId, locked), task 1.8
	"Cast", -- client -> server: (wildId) start fishing a wild cat, task 1.11
	"FishHold", -- client -> server: (holding) the bar input, task 1.11
	"FishGiveUp", -- client -> server: stop fishing, task 1.11
	"FishStart", -- server -> client: (wildId, tier, snapshot, rodLevel), task 1.11
	"FishState", -- server -> client: (wildId, snapshot), task 1.11
	"FishEnd", -- server -> client: (textKey, vars, caught?), task 1.12
	"Swing", -- client -> server: bat swing, task 1.14
	"Knockback", -- server -> client: (velocity, stunSeconds), task 1.14
	"BuyItem", -- client -> server: (category, id), tasks 2.1 - 2.5
	"BuyCrate", -- client -> server: (crateKey), task 2.6
	"CrateResult", -- server -> client: (crateKey, kind, kg, mutation) after the save, task 2.6
	"Rebirth", -- client -> server: rebirth now, task 2.7
	"ClaimReward", -- client -> server: (kind "Login" | "Playtime" | "Quest" | "Group", index), tasks 2.11 - 2.16
	"RedeemCode", -- client -> server: (code), task 2.15
}
Remotes.Functions = {
	"GetData", -- client -> server: the owner's data snapshot, task 1.2
}

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	if IS_SERVER then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end

	local found = ReplicatedStorage:WaitForChild(FOLDER_NAME, Config.Remotes.WaitTimeout)
	assert(found and found:IsA("Folder"), `[Sweetpotato] ReplicatedStorage.{FOLDER_NAME} not found`)
	return found :: Folder
end

local function getRemote(name: string, className: string, create: () -> Instance): Instance
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		assert(existing.ClassName == className, `[Sweetpotato] remote {name} is a {existing.ClassName}, expected {className}`)
		return existing
	end

	if IS_SERVER then
		local remote = create()
		remote.Name = name
		remote.Parent = folder
		return remote
	end

	local found = folder:WaitForChild(name, Config.Remotes.WaitTimeout)
	assert(found, `[Sweetpotato] remote {name} not found`)
	assert(found.ClassName == className, `[Sweetpotato] remote {name} is a {found.ClassName}, expected {className}`)
	return found
end

function Remotes.event(name: string): RemoteEvent
	return getRemote(name, "RemoteEvent", function()
		return Instance.new("RemoteEvent")
	end) :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	return getRemote(name, "RemoteFunction", function()
		return Instance.new("RemoteFunction")
	end) :: RemoteFunction
end

-- Server only: create every listed remote (called first thing in init.server).
function Remotes.createAll()
	assert(IS_SERVER, "Remotes.createAll is server only")
	for _, name in Remotes.Events do
		Remotes.event(name)
	end
	for _, name in Remotes.Functions do
		Remotes.func(name)
	end
end

return Remotes
