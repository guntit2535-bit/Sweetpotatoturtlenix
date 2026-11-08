--!strict
-- Debug commands for testing (task 1.3; based on Pet Storm Escape). Typed in chat ("!money 500") by:
--   - anyone in Studio, or
--   - user ids in Config.Debug.Admins in live servers,
-- and only while Config.Debug.Enabled is true (switched off in the launch checklist).
--
-- Other services add their own commands in Init:
--   DebugService.register("mythical", "!mythical  spawn a Mythical event now", function(player, args)
--       ...
--       return "Mythical spawned"
--   end)
--
-- In Studio the same commands run from the Command Bar / Studio MCP against the running game:
--   game.ServerStorage.SweetpotatoDebug:Invoke("!money 500")          -- first player
--   game.ServerStorage.SweetpotatoDebug:Invoke("!data", userId)       -- a given player

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local Commands = require(ReplicatedStorage.Shared.Commands)
local DataTemplate = require(ReplicatedStorage.Shared.DataTemplate)
local DataService = require(script.Parent.DataService)

export type Handler = (player: Player, args: { string }) -> string

type Command = { help: string, handler: Handler }

local HOOK_NAME = "SweetpotatoDebug"

local commands: { [string]: Command } = {}

local DebugService = {}

local function log(message: string)
	print(`[Sweetpotato] debug: {message}`)
end

local function isAllowed(player: Player): boolean
	if not Config.Debug.Enabled then
		return false
	end
	return RunService:IsStudio() or table.find(Config.Debug.Admins, player.UserId) ~= nil
end

function DebugService.register(name: string, help: string, handler: Handler)
	assert(commands[name] == nil, `debug command {name} registered twice`)
	commands[name] = { help = help, handler = handler }
end

-- Runs one command line for `player`. Returns the result text (also printed), or nil when the
-- message is not a command or the player may not use commands.
function DebugService.run(player: Player, message: string): string?
	if not isAllowed(player) then
		return nil
	end
	local name, args = Commands.parse(message, Config.Debug.Prefix)
	if name == nil then
		return nil
	end
	local command = commands[name]
	if command == nil then
		local result = `unknown command "{name}" (try {Config.Debug.Prefix}help)`
		log(result)
		return result
	end
	local ok, result = pcall(command.handler, player, args)
	local text = if ok then result else `{name} failed: {result}`
	log(`{player.Name}: {text}`)
	return text
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function registerBasics()
	DebugService.register("help", "!help  list commands", function()
		local lines = {}
		for _, command in commands do
			table.insert(lines, command.help)
		end
		table.sort(lines)
		return "\n" .. table.concat(lines, "\n")
	end)

	DebugService.register("money", "!money N  add N money (20k, 3M; negative removes)", function(player, args)
		local amount = Commands.number(args[1])
		if amount == nil then
			return "usage: !money N"
		end
		if not DataService.AddMoney(player, amount) then
			return "data not loaded"
		end
		local data = DataService.GetData(player)
		return `money = {data and data.Money}`
	end)

	DebugService.register("strength", "!strength N  set Strength to N kg", function(player, args)
		local kg = Commands.number(args[1])
		if kg == nil or kg < Config.Data.StartStrength then
			return "usage: !strength N"
		end
		DataService.Update(player, function(data)
			data.Strength = kg
		end)
		return `strength = {kg}`
	end)

	DebugService.register("speed", "!speed N  set the Speed stat to N", function(player, args)
		local n = Commands.number(args[1])
		if n == nil or n < 0 then
			return "usage: !speed N"
		end
		DataService.Update(player, function(data)
			data.Speed = n
		end)
		return `speed = {n}`
	end)

	DebugService.register("level", "!level weights|treadmill N  set a training level", function(player, args)
		local which = args[1]
		local n = Commands.integer(args[2])
		if n == nil or (which ~= "weights" and which ~= "treadmill") then
			return "usage: !level weights|treadmill N"
		end
		local max = if which == "weights" then Config.Weights.Levels else Config.Treadmill.Levels
		n = math.clamp(n, 1, max)
		DataService.Update(player, function(data)
			if which == "weights" then
				data.WeightsLevel = n :: number
			else
				data.TreadLevel = n :: number
			end
		end)
		return `{which} level = {n}`
	end)

	DebugService.register("reset", "!reset  make this save a brand-new player (receipts kept)", function(player)
		local ok = DataService.Update(player, function(data)
			local receipts = data.ReceiptIds
			local fresh = deepCopy(DataTemplate.Template)
			local target = data :: any
			for key in target do
				target[key] = nil
			end
			for key, value in fresh do
				target[key] = value
			end
			target.ReceiptIds = receipts
		end)
		if not ok then
			return "data not loaded"
		end
		task.spawn(DataService.SaveAsync, player)
		return "data reset to a new player"
	end)

	DebugService.register("data", "!data  print this player's saved data as JSON", function(player)
		local data = DataService.GetData(player)
		if not data then
			return "data not loaded"
		end
		return HttpService:JSONEncode(data)
	end)

	DebugService.register("save", "!save  save now and wait for it", function(player)
		return if DataService.SaveAsync(player) then "saved" else "save failed or not loaded"
	end)
end

local function hookChat(player: Player)
	player.Chatted:Connect(function(message: string)
		DebugService.run(player, message)
	end)
end

function DebugService:Init()
	registerBasics()
end

function DebugService:Start()
	if not Config.Debug.Enabled then
		return
	end
	Players.PlayerAdded:Connect(hookChat)
	for _, player in Players:GetPlayers() do
		hookChat(player)
	end

	if RunService:IsStudio() then
		local hook = Instance.new("BindableFunction")
		hook.Name = HOOK_NAME
		hook.OnInvoke = function(message: unknown, userId: unknown): string?
			if type(message) ~= "string" then
				return "message must be a string"
			end
			local player = if type(userId) == "number"
				then Players:GetPlayerByUserId(userId)
				else Players:GetPlayers()[1]
			if player == nil then
				return "no player"
			end
			return DebugService.run(player, message)
		end
		hook.Parent = ServerStorage
	end
end

return DebugService
