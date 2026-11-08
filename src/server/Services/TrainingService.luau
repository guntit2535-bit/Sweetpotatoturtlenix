--!strict
-- Weights and treadmill (tasks 1.15 / 1.16, blueprint §8-9; Pet Storm Escape's treadmill). Standing at
-- your own pen's weights trains Strength, at its treadmill Speed, every Config.Weights.Tick seconds by the
-- level's gain (x the rebirth multiplier). Player attribute "Training" = "weights" | "treadmill" while it
-- happens (the client animates). Each piece has an Upgrade prompt (only for its pen's owner): the next
-- level costs money. The weights change look every 5 levels (Util/GymLooks).
-- R2: stepping on your own spot locks you there: the server snaps the character onto the spot facing the
-- machine, walk speed 0 and no turning, until a jump (the client asks StopTraining) or a push off the spot.
-- After that the spot only grabs you again once you have stepped off it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Bonus = require(Shared.Bonus)
local CatRules = require(Shared.CatRules)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Format = require(Shared.Format)
local GymLooks = require(script.Parent.Parent.Util.GymLooks)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local Progress = require(script.Parent.Parent.Util.Progress)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local MovementService = require(script.Parent.MovementService)
local PenService = require(script.Parent.PenService)

local TrainingService = {}

local lastUpgrade: { [Player]: number } = {}
local locked: { [Player]: string } = {} -- "Weights" | "Treadmill"
local leaveFirst: { [Player]: boolean } = {} -- jumped off: must step off the spot before it locks again

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

local function bodyOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil, nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function attrOf(which: string?): string?
	return if which == "Weights" then "weights" elseif which == "Treadmill" then "treadmill" else nil
end

local function lockOn(player: Player, which: string, stand: BasePart, root: BasePart, humanoid: Humanoid)
	local look = stand.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local y = stand.Position.Y + stand.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2
	local pos = Vector3.new(stand.Position.X, y, stand.Position.Z)
	local turn = (Config.Gym.Face :: any)[which] or 0
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(pos, pos + flat.Unit) * CFrame.Angles(0, math.rad(turn), 0)
	humanoid.AutoRotate = false
	locked[player] = which
	MovementService.setFactor(player, "training", 0)
	player:SetAttribute("Training", attrOf(which))
end

local function unlock(player: Player, mustLeave: boolean)
	if not locked[player] then
		return
	end
	locked[player] = nil
	leaveFirst[player] = if mustLeave then true else nil
	MovementService.setFactor(player, "training", nil)
	local _, humanoid = bodyOf(player)
	if humanoid then
		humanoid.AutoRotate = true
	end
	player:SetAttribute("Training", nil)
end

-- Locks players who step on their own spot; lets go of anyone pushed off or dead.
local function checkSpots()
	for _, player in Players:GetPlayers() do
		local index = PenService.penIndex(player)
		local root, humanoid = bodyOf(player)
		if not index or not root or not humanoid then
			unlock(player, false)
			continue
		end
		local which = locked[player]
		if which then
			local stand = standOf(index, which)
			if not stand or flatDistance(root.Position, stand.Position) > Config.Gym.StandRadius + Config.Gym.Slip then
				unlock(player, true)
			end
			continue
		end
		local on: string? = nil
		local onStand: BasePart? = nil
		for _, w in { "Weights", "Treadmill" } do
			local stand = standOf(index, w)
			if stand and flatDistance(root.Position, stand.Position) <= Config.Gym.StandRadius then
				on, onStand = w, stand
			end
		end
		if leaveFirst[player] then
			if not on then
				leaveFirst[player] = nil
			end
		elseif on and onStand and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			lockOn(player, on, onStand, root, humanoid)
		end
	end
end

local function tick()
	for _, player in Players:GetPlayers() do
		local data = DataService.GetData(player)
		local training: string? = locked[player]
		if data then
			if training then
				Progress.add(player, "Train", Config.Weights.Tick)
			end
			if training == "Weights" then
				local gain = CatRules.weightsGain(data.WeightsLevel) * Bonus.strength(BonusCtx.of(player, data))
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
		local attr = attrOf(training)
		if player:GetAttribute("Training") ~= attr then
			player:SetAttribute("Training", attr)
		end
	end
end

function TrainingService:Init()
	Guard.onEvent("StopTraining", Config.Gym.StopRate, function(player)
		unlock(player, true)
	end)
	DebugService.register("train", "!train  show the weights / treadmill lock state (R2)", function(player)
		local index = PenService.penIndex(player)
		local root, humanoid = bodyOf(player)
		local parts = { `pen {index} locked {locked[player]} leaveFirst {leaveFirst[player]}` }
		if index and root and humanoid then
			for _, w in { "Weights", "Treadmill" } do
				local stand = standOf(index, w)
				table.insert(parts, `{w} {if stand then math.floor(flatDistance(root.Position, stand.Position) * 10) / 10 else "no stand"}`)
			end
			table.insert(parts, `state {humanoid:GetState().Name}`)
		end
		return table.concat(parts, " | ")
	end)
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
	local function hook(player: Player)
		player.CharacterAdded:Connect(function()
			locked[player] = nil
			leaveFirst[player] = nil
			MovementService.setFactor(player, "training", nil)
			player:SetAttribute("Training", nil)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	task.spawn(function()
		while true do
			task.wait(Config.Gym.CheckEvery)
			checkSpots()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local index = PenService.penIndex(player)
		lastUpgrade[player] = nil
		locked[player] = nil
		leaveFirst[player] = nil
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
