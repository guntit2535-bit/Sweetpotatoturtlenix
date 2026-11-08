--!strict
-- New-player tutorial (task V4, revision round 2; not in the blueprint). Saved step data.TutorialStep:
--   1 Welcome            -> the client's "Next" (ack)
--   2 Walk to the Backyard -> the server sees the player leave the lobby (Config.World.LobbyRadius)
--   3 Catch a cat        -> the server sees CarryingCat (a cat caught and carried)
--   4 Carry it home      -> CarryService.Delivered (a cat knocked loose sends the player back to 3)
--   5 Train at the weights -> a training tick (Progress "Train")
--   6 Open the Shop      -> the client's ack (nothing to win by faking it)
--   7 All done           -> the client's ack: Config.Tutorial.Reward money the first time only, then Done
-- Skip -> Done (no reward); Replay (Settings) -> 1. Player attribute "Tutorial" = the step while it runs.
-- Saves from before V4 are marked done by Migrate.tutorial (anyone who ever had a cat).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Guard = require(script.Parent.Parent.Util.Guard)
local Progress = require(script.Parent.Parent.Util.Progress)
local Validate = require(ReplicatedStorage.Shared.Validate)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)

local TutorialService = {}

local T = Config.Tutorial
local WELCOME, ZONE, CATCH, CARRY, TRAIN, SHOP, FINISH = 1, 2, 3, 4, 5, 6, 7
local ACKABLE = { [WELCOME] = true, [SHOP] = true, [FINISH] = true }

local lostSince: { [Player]: number } = {} -- step 4: when the carried cat was lost

local function stepOf(player: Player): number
	local data = DataService.GetData(player)
	return if data then data.TutorialStep else T.Done
end

local function show(player: Player)
	local step = stepOf(player)
	player:SetAttribute("Tutorial", if step >= 1 and step < T.Done then step else nil)
end

local function setStep(player: Player, step: number)
	DataService.Update(player, function(d)
		d.TutorialStep = step
	end)
	show(player)
end

local function advance(player: Player, from: number)
	if stepOf(player) == from then
		setStep(player, from + 1)
	end
end

local function finish(player: Player)
	local data = DataService.GetData(player)
	if data and not data.TutorialRewarded then
		DataService.Update(player, function(d)
			d.TutorialRewarded = true
		end)
		DataService.AddMoney(player, T.Reward)
	end
	setStep(player, T.Done)
end

local function onRemote(player: Player, rawAction: unknown, rawStep: unknown)
	local action = Validate.oneOf(rawAction, { "ack", "skip", "replay" })
	if action == "skip" then
		if stepOf(player) < T.Done then
			setStep(player, T.Done)
		end
	elseif action == "replay" then
		setStep(player, WELCOME)
	elseif action == "ack" then
		local step = Validate.integer(rawStep, 1, FINISH)
		if step and step == stepOf(player) and ACKABLE[step] then
			if step == FINISH then
				finish(player)
			else
				advance(player, step)
			end
		end
	end
end

local function poll()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local step = stepOf(player)
		if step < ZONE or step > CARRY then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local carrying = player:GetAttribute("CarryingCat") ~= nil
		if step == ZONE and root and root:IsA("BasePart") then
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude
			if flat > Config.World.LobbyRadius + 4 or carrying then
				setStep(player, if carrying then CARRY else CATCH)
			end
		elseif step == CATCH and carrying then
			advance(player, CATCH)
		elseif step == CARRY then
			if carrying then
				lostSince[player] = nil
			elseif not lostSince[player] then
				lostSince[player] = now
			elseif now - (lostSince[player] :: number) > 1.5 then
				lostSince[player] = nil
				setStep(player, CATCH) -- knocked loose: catch one again
			end
		end
	end
end

function TutorialService:Init()
	Guard.onEvent("Tutorial", T.Rate, onRemote)
	DebugService.register("tutorial", "!tutorial N  set the tutorial step (1-7, 99 = done)", function(player, args)
		local n = tonumber(args[1])
		if not n then
			return "usage: !tutorial N"
		end
		setStep(player, math.clamp(math.floor(n), 1, T.Done))
		return `tutorial step = {stepOf(player)}`
	end)
end

function TutorialService:Start()
	DataService.PlayerLoaded:Connect(show)
	for _, player in Players:GetPlayers() do
		if DataService.GetData(player) then
			show(player)
		end
	end
	CarryService.Delivered:Connect(function(player)
		local step = stepOf(player)
		if step == CARRY or step == CATCH then
			lostSince[player] = nil
			setStep(player, TRAIN)
		end
	end)
	Progress.Added:Connect(function(player, kind)
		if kind == "Train" then
			advance(player, TRAIN)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lostSince[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(T.CheckEvery)
			poll()
		end
	end)
end

return TutorialService
