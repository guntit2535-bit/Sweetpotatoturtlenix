--!strict
-- Training on this client (tasks 1.15 / 1.16): while the server says "Training" (weights / treadmill),
-- the character plays a default Roblox animation in place (run = treadmill; lifting = the two-hand curl of
-- PlayerAnimController on R15, Roblox's cheer on R6) and every gain
-- floats up as "+0.1 kg" / "+0.2". The Upgrade prompts at your own pen show the next cost and level in your
-- language; prompts at other pens are hidden for you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local TrainingController = {}

local me = Players.LocalPlayer
-- Roblox's own default animations (usable by every game)
local ANIMS = {
	R15 = { weights = "rbxassetid://507770677", treadmill = "rbxassetid://913376220" },
	R6 = { weights = "rbxassetid://129423030", treadmill = "rbxassetid://180426354" },
}

local track: AnimationTrack? = nil
local lastStrength = 0
local lastSpeed = 0

local function stopTrack()
	if track then
		track:Stop(0.2)
		track = nil
	end
end

local function playFor(kind: string?)
	stopTrack()
	local character = me.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not kind or not humanoid or not animator then
		return
	end
	if kind == "weights" and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return -- R6 task: the curl pose (PlayerAnimController) with a dumbbell in each hand (server)
	end
	local set = if humanoid.RigType == Enum.HumanoidRigType.R6 then ANIMS.R6 else ANIMS.R15
	local anim = Instance.new("Animation")
	anim.AnimationId = (set :: any)[kind]
	local ok, t = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and t then
		t.Looped = true
		t.Priority = Enum.AnimationPriority.Action
		t:Play(0.2)
		track = t
		if kind == "treadmill" then
			-- R7: a higher treadmill level runs faster
			local level = me:GetAttribute("TreadLevel")
			local u = ((if type(level) == "number" then level else 1) - 1) / math.max(Config.Treadmill.Levels - 1, 1)
			local r = Config.TreadmillFx.RunSpeed
			t:AdjustSpeed(r[1] + (r[2] - r[1]) * math.clamp(u, 0, 1))
		end
	end
end

local function popup(text: string, color: Color3)
	local head = me.Character and me.Character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(140, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
	gui.LightInfluence = 0
	local label = Kit.text(gui, "Gain", UDim2.fromScale(1, 1), UDim2.new(), 30, true)
	label.TextColor3 = color
	label.Text = text
	gui.Parent = head
	TweenService:Create(gui, TweenInfo.new(1.1), { StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.1), { TextTransparency = 1 }):Play()
	task.delay(1.2, function()
		gui:Destroy()
	end)
end

local function myPen(): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if not pens then
		return nil
	end
	for _, p in pens:GetChildren() do
		if p:GetAttribute("OwnerId") == me.UserId then
			return p :: Model
		end
	end
	return nil
end

local function refreshPrompts()
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if not pens then
		return
	end
	local mine = myPen()
	for _, p in pens:GetChildren() do
		for _, which in { "Weights", "Treadmill" } do
			local model = p:FindFirstChild(which)
			local stand = model and model:FindFirstChild("Stand")
			local prompt = stand and stand:FindFirstChild("UpgradePrompt")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = p == mine
				if p == mine then
					local isWeights = which == "Weights"
					local level = me:GetAttribute(if isWeights then "WeightsLevel" else "TreadLevel")
					local lv = if type(level) == "number" then level else 1
					local rb = me:GetAttribute("Rebirths")
					local r = if type(rb) == "number" then rb else 0
					local cost = if isWeights then CatRules.weightsCost(lv, r) else CatRules.treadCost(lv, r)
					prompt.ObjectText = Lang.text(if isWeights then "WeightsName" else "TreadName", { level = lv })
					prompt.ActionText = if cost then Lang.text("TrainUpgrade", { cost = Format.short(cost) }) else Lang.text("TrainMax")
					if not cost then
						prompt.Enabled = false
					end
				end
			end
		end
	end
end

-- W3 (revision 3 item 6): a glowing green ring on the floor of your own pen's weights and treadmill spots, so new
-- players see where to stand to train (hidden on the spot you are training on). Client only, decoration.
local rings: { [string]: Model } = {}

local function makeRing(radius: number): Model
	local m = Instance.new("Model")
	m.Name = "TrainingRing"
	local n = Config.Gym.RingSegments
	local green = Color3.fromHex("4dff6a")
	local function part(name: string): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = green
		p.Parent = m
		return p
	end
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local seg = part("Seg")
		seg.Size = Vector3.new(0.75, 0.16, 2 * math.pi * radius / n * 1.08)
		seg.CFrame = CFrame.Angles(0, -a, 0) * CFrame.new(radius, 0, 0)
	end
	local fill = part("Fill")
	fill.Shape = Enum.PartType.Cylinder
	fill.Size = Vector3.new(0.06, radius * 2 - 0.4, radius * 2 - 0.4)
	fill.CFrame = CFrame.Angles(0, 0, math.pi / 2)
	m.PrimaryPart = fill
	return m
end

local function refreshRings()
	local mine = myPen()
	local training = me:GetAttribute("Training")
	for _, which in { "Weights", "Treadmill" } do
		local model = mine and mine:FindFirstChild(which)
		local stand = model and model:FindFirstChild("Stand")
		local show = stand and stand:IsA("BasePart") and training ~= string.lower(which)
		local ring = rings[which]
		if not show then
			if ring then
				ring.Parent = nil
			end
			continue
		end
		local s = stand :: BasePart
		if not ring then
			ring = makeRing(Config.Gym.StandRadius)
			rings[which] = ring
		end
		-- sit on whatever floor is under the spot (the lobby tiles, the treadmill belt)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { ring :: Model, me.Character :: any }
		local hit = workspace:Raycast(s.Position + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
		local y = if hit then hit.Position.Y else s.Position.Y - s.Size.Y / 2
		local r = ring :: Model
		r:PivotTo(CFrame.new(s.Position.X, y + 0.08, s.Position.Z) * CFrame.Angles(0, 0, math.pi / 2))
		r.Parent = workspace
	end
end

-- R2: while locked on a spot, a jump (Space, the phone's jump button) asks the server to let go; a hint says so.
local function setupJumpToStop()
	local stop = Remotes.event("StopTraining")
	local gui = Kit.screen("TrainingHint", 3)
	local hint = Kit.text(gui, "Hint", UDim2.fromOffset(320, 34), UDim2.new(0.5, -160, 1, -150), 22, true)
	hint.Visible = false
	local function refresh()
		hint.Visible = me:GetAttribute("Training") ~= nil
		hint.Text = Lang.text("TrainingJumpHint")
	end
	me:GetAttributeChangedSignal("Training"):Connect(refresh)
	Lang.changed:Connect(refresh)
	refresh()
	local last = 0
	game:GetService("UserInputService").JumpRequest:Connect(function()
		if me:GetAttribute("Training") ~= nil and os.clock() - last > 0.3 then
			last = os.clock()
			stop:FireServer()
		end
	end)
end

function TrainingController.Start(_self: any)
	setupJumpToStop()
	local s = me:GetAttribute("Strength")
	lastStrength = if type(s) == "number" then s else 0
	local v = me:GetAttribute("Speed")
	lastSpeed = if type(v) == "number" then v else 0
	me:GetAttributeChangedSignal("Training"):Connect(function()
		local t = me:GetAttribute("Training")
		playFor(if type(t) == "string" then t else nil)
	end)
	me.CharacterAdded:Connect(function()
		track = nil
	end)
	me:GetAttributeChangedSignal("TreadLevel"):Connect(function()
		if me:GetAttribute("Training") == "treadmill" then
			playFor("treadmill") -- R7: the new level's run speed
		end
	end)
	me:GetAttributeChangedSignal("Strength"):Connect(function()
		local now = me:GetAttribute("Strength")
		if type(now) == "number" then
			if me:GetAttribute("Training") == "weights" and now > lastStrength then
				popup(`+{Format.money(now - lastStrength)} kg`, Kit.Colors.yellow)
			end
			lastStrength = now
		end
	end)
	me:GetAttributeChangedSignal("Speed"):Connect(function()
		local now = me:GetAttribute("Speed")
		if type(now) == "number" then
			if me:GetAttribute("Training") == "treadmill" and now > lastSpeed then
				popup(`+{Format.money(now - lastSpeed)}`, Kit.Colors.sky)
			end
			lastSpeed = now
		end
	end)
	for _, attr in { "WeightsLevel", "TreadLevel", "Money", "Rebirths" } do
		me:GetAttributeChangedSignal(attr):Connect(refreshPrompts)
	end
	Lang.changed:Connect(refreshPrompts)
	task.spawn(function()
		while true do
			refreshPrompts()
			refreshRings()
			task.wait(2)
		end
	end)
	me:GetAttributeChangedSignal("Training"):Connect(refreshRings)
	-- the rings breathe so they catch the eye
	RunService.Heartbeat:Connect(function()
		local a = 0.15 + 0.15 * math.sin(os.clock() * 3)
		for _, ring in rings do
			for _, part in ring:GetChildren() do
				if part:IsA("BasePart") then
					part.Transparency = if part.Name == "Fill" then 0.45 + a else a
				end
			end
		end
	end)
end

return TrainingController
