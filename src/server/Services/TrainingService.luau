--!strict
-- Weights and treadmill (tasks 1.15 / 1.16, blueprint §8-9; Pet Storm Escape's treadmill). Standing at
-- your own pen's weights trains Strength, at its treadmill Speed, every Config.Weights.Tick seconds by the
-- level's gain (x the rebirth multiplier). Player attribute "Training" = "weights" | "treadmill" while it
-- happens (the client animates). Each piece has an Upgrade prompt (only for its pen's owner): the next
-- level costs money. The weights change look every 5 levels (Util/GymLooks).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local CatRules = require(Shared.CatRules)
local Format = require(Shared.Format)
local GymLooks = require(script.Parent.Parent.Util.GymLooks)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local PenService = require(script.Parent.PenService)

local TrainingService = {}

local lastUpgrade: { [Player]: number } = {}

local function pen(index: number): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	local m = pens and pens:FindFirstChild(`Pen{index}`)
	return if m and m:IsA("Model") then m else nil
end

local function standOf(index: number, which: string): BasePart?
	local p = pen(index)
	local model = p and p:FindFirstChild(which)
	local stand = model and model:FindFirstChild("Stand")
	return if stand and stand:IsA("BasePart") then stand else nil
end

local function ownerOf(index: number): Player?
	for _, player in Players:GetPlayers() do
		if PenService.penIndex(player) == index then
			return player
		end
	end
	return nil
end

local function lookFor(level: number): number
	return math.clamp(math.floor((level - 1) / Config.Gym.LookEvery) + 1, 1, GymLooks.Count)
end

local function refreshLook(index: number)
	local p = pen(index)
	local weights = p and p:FindFirstChild("Weights")
	if not weights or not weights:IsA("Model") then
		return
	end
	local owner = ownerOf(index)
	local data = owner and DataService.GetData(owner)
	GymLooks.apply(weights, lookFor(if data then data.WeightsLevel else 1))
end

local function upgrade(player: Player, index: number, which: string)
	local now = os.clock()
	if lastUpgrade[player] and now - lastUpgrade[player] < 0.3 then
		return
	end
	lastUpgrade[player] = now
	if PenService.penIndex(player) ~= index then
		Notify.send(player, "NotYourGym", nil, "bad")
		return
	end
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local isWeights = which == "Weights"
	local level = if isWeights then data.WeightsLevel else data.TreadLevel
	local cost = if isWeights then CatRules.weightsCost(level) else CatRules.treadCost(level)
	if not cost then
		return
	end
	if not DataService.SpendMoney(player, cost) then
		Notify.send(player, "NotEnoughMoney", { cost = Format.short(cost) }, "bad")
		return
	end
	DataService.Update(player, function(d)
		if isWeights then
			d.WeightsLevel += 1
		else
			d.TreadLevel += 1
		end
	end)
	Notify.send(player, if isWeights then "WeightsUp" else "TreadUp", { level = level + 1 }, "good")
	if isWeights then
		refreshLook(index)
	end
end

local function setupPrompts()
	for i = 1, Config.World.Pens.Count do
		for _, which in { "Weights", "Treadmill" } do
			local stand = standOf(i, which)
			if stand then
				local old = stand:FindFirstChild("UpgradePrompt")
				if old then
					old:Destroy()
				end
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "UpgradePrompt"
				prompt.ActionText = "Upgrade" -- the owner's client shows the cost in its language
				prompt.KeyboardKeyCode = Enum.KeyCode.F
				prompt.HoldDuration = 0.2
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt:SetAttribute("Which", which)
				prompt.Parent = stand
				prompt.Triggered:Connect(function(player)
					upgrade(player, i, which)
				end)
			end
		end
		refreshLook(i)
	end
end

local function tick()
	for _, player in Players:GetPlayers() do
		local index = PenService.penIndex(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local data = DataService.GetData(player)
		local training: string? = nil
		if index and root and root:IsA("BasePart") and data then
			local pos = Vector3.new(root.Position.X, 0, root.Position.Z)
			for _, which in { "Weights", "Treadmill" } do
				local stand = standOf(index, which)
				if stand then
					local s = Vector3.new(stand.Position.X, 0, stand.Position.Z)
					if (pos - s).Magnitude <= Config.Gym.StandRadius then
						training = which
					end
				end
			end
			if training == "Weights" then
				local gain = CatRules.weightsGain(data.WeightsLevel) * CatRules.rebirthStrength(data.Rebirths)
				DataService.UpdateQuiet(player, function(d)
					d.Strength += gain
				end)
			elseif training == "Treadmill" then
				local gain = CatRules.treadGain(data.TreadLevel)
				DataService.UpdateQuiet(player, function(d)
					d.Speed += gain
				end)
			end
		end
		local attr = if training == "Weights" then "weights" elseif training == "Treadmill" then "treadmill" else nil
		if player:GetAttribute("Training") ~= attr then
			player:SetAttribute("Training", attr)
		end
	end
end

function TrainingService:Start()
	setupPrompts()
	DataService.PlayerLoaded:Connect(function(player)
		task.wait(0.5) -- after PenService gave the pen
		local index = PenService.penIndex(player)
		if index then
			refreshLook(index)
		end
	end)
	DataService.Changed:Connect(function(player)
		local index = PenService.penIndex(player)
		if index then
			refreshLook(index) -- no-op unless the look band changed
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local index = PenService.penIndex(player)
		lastUpgrade[player] = nil
		if index then
			task.defer(refreshLook, index)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Weights.Tick)
			tick()
		end
	end)
end

return TrainingService
