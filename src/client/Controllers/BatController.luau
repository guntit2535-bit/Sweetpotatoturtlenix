--!strict
-- The bat on this client (task 1.14): using it asks Swing (the server decides the hit), with the same
-- cooldown locally so the button does not spam. Knockback from the server: this client owns its character,
-- so it applies the push here (and tumbles for a moment after a big hit).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BatController = {}

local player = Players.LocalPlayer
local last = 0
local swingRemote: RemoteEvent

local function hookTool(tool: Instance)
	if tool:IsA("Tool") and tool.Name == "Bat" and not tool:GetAttribute("BatHooked") then
		tool:SetAttribute("BatHooked", true)
		tool.Activated:Connect(function()
			if os.clock() - last >= Config.Bat.Cooldown then
				last = os.clock()
				swingRemote:FireServer()
			end
		end)
	end
end

local function knock(velocity: unknown, stun: unknown)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if typeof(velocity) ~= "Vector3" or not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	-- W1: the walking Humanoid ate most of the push (a non-carrier moved ~1 stud). Now every hit turns the
	-- character into a free body (Physics state) for the stun, so it really flies and tumbles, then gets up.
	local seconds = math.clamp(if type(stun) == "number" then stun else 0, 0.3, 3)
	local v = velocity :: Vector3
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	local spin = Vector3.new(math.random(-8, 8), math.random(-4, 4), math.random(-8, 8))
	root.AssemblyLinearVelocity = v
	root.AssemblyAngularVelocity = spin
	-- the state change can eat the first frame's push: give it again on the next two frames
	for _ = 1, 2 do
		RunService.Heartbeat:Wait()
		root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(root.AssemblyLinearVelocity.Y, v.Y * 0.9), v.Z)
	end
	task.delay(seconds, function()
		humanoid.PlatformStand = false
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

function BatController.Start(_self: any)
	swingRemote = Remotes.event("Swing")
	Remotes.event("Knockback").OnClientEvent:Connect(knock)
	local function watch(container: Instance)
		for _, c in container:GetChildren() do
			hookTool(c)
		end
		container.ChildAdded:Connect(hookTool)
	end
	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(character)
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end
end

return BatController
