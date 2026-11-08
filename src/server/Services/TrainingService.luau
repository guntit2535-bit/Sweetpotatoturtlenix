--!strict
-- Weights and treadmill (tasks 1.15 / 1.16, blueprint §8-9; Pet Storm Escape's treadmill). Standing at
-- your own pen's weights trains Strength, at its treadmill Speed, every Config.Weights.Tick seconds by the
-- level's gain (x the rebirth multiplier). Player attribute "Training" = "weights" | "treadmill" while it
-- happens (the client animates). Each piece has an Upgrade prompt (only for its pen's owner): the next
-- level costs money. The weights change look every 5 levels (Util/GymLooks).
-- R2: stepping on your own spot locks you there: the server snaps the character onto the spot facing the
-- machine, walk speed 0 and no turning, until a jump (the client asks StopTraining) or a push off the spot.
-- After that the spot only grabs you again once you have stepped off it.
-- R6: while lifting, the dumbbell of your weights level (mesh Dumbbell1..25) is welded into each hand; the
-- clients pose the two-hand curl (PlayerAnimController).
-- R7: while running, speed lines stream back from the runner, more and faster with the treadmill level
-- (Config.TreadmillFx; the client also speeds up the run animation).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Bonus = require(Shared.Bonus)
local CatRules = require(Shared.CatRules)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Format = require(Shared.Format)
local GymLooks = require(script.Parent.Parent.Util.GymLooks)
local ItemModels = require(Shared.ItemModels)
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
	local owner = ownerOf(index)
	local data = owner and DataService.GetData(owner)
	-- R5: a mesh look for every level (falls back to the 5 part-built weights looks)
	local treadmill = p and p:FindFirstChild("Treadmill")
	if treadmill and treadmill:IsA("Model") then
		GymLooks.applyLevel(treadmill, "Treadmill", if data then data.TreadLevel else 1)
	end
	local weights = p and p:FindFirstChild("Weights")
	if not weights or not weights:IsA("Model") then
		return
	end
	local level = if data then data.WeightsLevel else 1
	if not GymLooks.applyLevel(weights, "Weights", level) then
		GymLooks.apply(weights, lookFor(level))
	end
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
	local cost = if isWeights then CatRules.weightsCost(level, data.Rebirths) else CatRules.treadCost(level, data.Rebirths)
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
	refreshLook(index)
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

-- R6: a dumbbell in each hand while lifting (nothing when the meshes are not imported).
local HANDS = { { "RightHand", "Right Arm" }, { "LeftHand", "Left Arm" } }

local function dropDumbbells(player: Player)
	local character = player.Character
	local old = character and character:FindFirstChild("Dumbbells")
	if old then
		old:Destroy()
	end
end

local function holdDumbbells(player: Player)
	local character = player.Character
	local data = DataService.GetData(player)
	if not character or not data then
		return
	end
	local level = data.WeightsLevel
	local id = "Dumbbell" .. level
	local old = character:FindFirstChild("Dumbbells")
	if old and old:GetAttribute("Id") == id then
		return
	end
	dropDumbbells(player)
	if not ItemModels.has(id) then
		return
	end
	local scale = Config.ItemModels.DumbbellScale * (1 + 0.06 * (level - 1)) ^ (Config.ItemModels.WeightsGrowth - 1)
	local folder = Instance.new("Folder")
	folder.Name = "Dumbbells"
	folder:SetAttribute("Id", id)
	for _, names in HANDS do
		local hand = character:FindFirstChild(names[1]) or character:FindFirstChild(names[2])
		local model = ItemModels.build(id, scale)
		if hand and hand:IsA("BasePart") and model then
			-- the bar across the fist (along the hand's X), a little below the hand's middle
			local grip = if hand.Name == names[1] then -hand.Size.Y * 0.2 else -hand.Size.Y / 2
			model:PivotTo(hand.CFrame * CFrame.new(0, grip, 0))
			local w = Instance.new("WeldConstraint")
			w.Part0 = hand
			w.Part1 = model.PrimaryPart
			w.Parent = model
			model.Parent = folder
		elseif model then
			model:Destroy()
		end
	end
	folder.Parent = character
end

-- R7: speed sparkles on the belt: an invisible strip across the belt in front of the runner's feet (welded to
-- the root) sends sparkles sliding back along the belt under the runner, more and faster with each level, in
-- the treadmill family's colour (thin streaks were tried first: too faint from the camera behind).
local function dropLines(player: Player)
	local character = player.Character
	local old = character and character:FindFirstChild("SpeedLines")
	if old then
		old:Destroy()
	end
end

local function speedLines(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local data = DataService.GetData(player)
	if not character or not root or not root:IsA("BasePart") or not data then
		return
	end
	local level = data.TreadLevel
	local model = character:FindFirstChild("SpeedLines")
	if model and model:GetAttribute("Level") == level then
		return
	end
	if not model then
		local m = Instance.new("Model")
		m.Name = "SpeedLines"
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local feet = (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2
		for _, side in { 0 } do
			local pp = Instance.new("Part")
			pp.Name = "Strip"
			pp.Size = Vector3.new(2.6, 0.2, 0.2)
			pp.Transparency = 1
			pp.CanCollide = false
			pp.CanTouch = false
			pp.CanQuery = false
			pp.Massless = true
			pp.CFrame = root.CFrame * CFrame.new(side, -feet + 0.25, -1.6)
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = pp
			w.Parent = pp
			local e = Instance.new("ParticleEmitter")
			e.Name = "Lines"
			e.Enabled = false -- switched on below once fully set (the defaults live 5-10 s: a white haze)
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.EmissionDirection = Enum.NormalId.Back
			e.Shape = Enum.ParticleEmitterShape.Box
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.5) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime = NumberRange.new(0.45, 0.6)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-180, 180)
			e.SpreadAngle = Vector2.new(4, 4)
			e.LightEmission = 0.6
			e.Parent = pp
			pp.Parent = m
		end
		m.Parent = character
		model = m
	end
	local fx = Config.TreadmillFx
	local t = (level - 1) / math.max(Config.Treadmill.Levels - 1, 1)
	local rate = fx.LineRate[1] + (fx.LineRate[2] - fx.LineRate[1]) * t
	local v = fx.LineSpeed[1] + (fx.LineSpeed[2] - fx.LineSpeed[1]) * t
	local color = ColorSequence.new(Color3.fromHex(fx.Colors[math.clamp(math.floor((level - 1) / 5) + 1, 1, #fx.Colors)]))
	-- they fade out at the back end of the belt (the belt is 2.1 x level growth x scale behind the stand; the
	-- strip starts 1.6 ahead), never reaching the camera
	local travel = 2.1 * (1 + 0.02 * (level - 1)) * Config.ItemModels.TreadmillScale + 1.2
	for _, d in (model :: Instance):GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Rate = rate
			d.Speed = NumberRange.new(v * 0.85, v * 1.15)
			local life = math.max(0.35, travel / v) -- (very short lives showed as a white haze in Studio)
			d.Lifetime = NumberRange.new(life * 0.85, life)
			d.Enabled = true
			d.Color = color
		end
	end
	;(model :: Instance):SetAttribute("Level", level)
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
	if which == "Weights" then
		holdDumbbells(player)
	elseif which == "Treadmill" then
		speedLines(player)
	end
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
	dropDumbbells(player)
	dropLines(player)
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
					d.Strength = CatRules.cap(d.Strength + gain)
				end)
			elseif training == "Treadmill" then
				local gain = CatRules.treadGain(data.TreadLevel) * CatRules.rebirthSpeed(data.Rebirths)
				DataService.UpdateQuiet(player, function(d)
					d.Speed = CatRules.cap(d.Speed + gain)
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
		if locked[player] == "Weights" then
			holdDumbbells(player) -- no-op unless the weights level changed
		elseif locked[player] == "Treadmill" then
			speedLines(player) -- no-op unless the treadmill level changed
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
