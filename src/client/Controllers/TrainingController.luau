--!strict
-- Training on this client (tasks 1.15 / 1.16): while the server says "Training" (weights / treadmill),
-- the character plays a default Roblox animation in place (cheer = lifting, run = treadmill) and every gain
-- floats up as "+0.1 kg" / "+0.2". The Upgrade prompts at your own pen show the next cost and level in your
-- language; prompts at other pens are hidden for you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Format = require(Shared:WaitForChild("Format"))
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
					local cost = if isWeights then CatRules.weightsCost(lv) else CatRules.treadCost(lv)
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

function TrainingController.Start(_self: any)
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
	for _, attr in { "WeightsLevel", "TreadLevel", "Money" } do
		me:GetAttributeChangedSignal(attr):Connect(refreshPrompts)
	end
	Lang.changed:Connect(refreshPrompts)
	task.spawn(function()
		while true do
			refreshPrompts()
			task.wait(2)
		end
	end)
	local _ = Config
end

return TrainingController
