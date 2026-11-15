--!strict
-- The plaza shopkeepers (developer 2026-11-15: "bacon" Roblox avatars in the two stalls, built by NpcService). Here,
-- on this client only, each one plays Roblox's idle animation, waves now and then, and turns a little toward this
-- player when they come near. Decoration: nothing is sent to the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local NpcController = {}

local me = Players.LocalPlayer
local NEAR = 40 -- studs: they look at a player this close
local MAX_TURN = math.rad(55)

type Npc = { root: BasePart, base: CFrame, yaw: number, wave: AnimationTrack?, nextWave: number }

local npcs: { [Model]: Npc } = {}

local function animation(id: number): Animation
	local a = Instance.new("Animation")
	a.AnimationId = `rbxassetid://{id}`
	return a
end

local function add(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local n: Npc = { root = root, base = root.CFrame, yaw = 0, wave = nil, nextWave = os.clock() + math.random() * 4 }
	pcall(function()
		local a = animator :: Animator
		local idle = a:LoadAnimation(animation(Config.Npc.IdleAnim))
		idle.Looped = true
		idle:Play()
		n.wave = a:LoadAnimation(animation(Config.Npc.WaveAnim))
	end)
	npcs[model] = n
end

local function scan()
	local map = workspace:FindFirstChild("Map")
	local lobby = map and map:FindFirstChild("Lobby")
	local market = lobby and lobby:FindFirstChild("Market")
	if not market then
		return
	end
	for _, m in market:GetDescendants() do
		if m:IsA("Model") and m.Name:sub(1, 11) == "Shopkeeper_" and not npcs[m] then
			add(m)
		end
	end
end

function NpcController.Start(_self: any)
	task.spawn(function()
		while true do
			scan()
			task.wait(2) -- (the market may stream in later)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		local character = me.Character
		local myRoot = character and character:FindFirstChild("HumanoidRootPart")
		for model, n in npcs do
			if not model.Parent or not n.root.Parent then
				npcs[model] = nil
				continue
			end
			-- turn toward this player when near (within MAX_TURN of the stall's facing), and wave now and then
			local want = 0
			local near = false
			if myRoot and myRoot:IsA("BasePart") then
				local rel = n.base:PointToObjectSpace(myRoot.Position)
				local flat = Vector3.new(rel.X, 0, rel.Z)
				if flat.Magnitude < NEAR and flat.Magnitude > 0.5 then
					want = math.clamp(math.atan2(-rel.X, -rel.Z), -MAX_TURN, MAX_TURN)
					near = true
				end
			end
			n.yaw += (want - n.yaw) * math.min(1, dt * 4)
			n.root.CFrame = n.base * CFrame.Angles(0, n.yaw, 0)
			if n.wave and now >= n.nextWave then
				n.wave:Play(0.2)
				n.nextWave = now + (if near then 5 else 9) + math.random() * 3
			end
		end
	end)
end

return NpcController
