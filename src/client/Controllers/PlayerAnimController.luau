--!strict
-- Player arm poses (task 2.22): every client poses the arms of every player near the camera from the
-- attributes the server sets: "CarryingCat" -> both arms up holding the cat, "Fishing" -> reeling
-- (shared/PlayerPoses). Done each frame after the Animator, on the shoulder joints' Transform values, so the
-- legs keep walking and nothing has to be uploaded. Works for R15 and R6, and for both joint kinds Roblox uses
-- (Motor6D, and AnimationConstraint on the newer avatars): the pose is turned from the torso's axes into
-- each joint's own axes. The cast and bat swing are the default tool "Slash" (server, ToolAnim).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerPoses = require(Shared:WaitForChild("PlayerPoses"))

type Rig = { character: Model, right: Instance?, left: Instance?, weight: number, kind: string? }

local PlayerAnimController = {}

local rigs: { [Player]: Rig } = {}
local RIGHT = { RightShoulder = true, ["Right Shoulder"] = true }
local LEFT = { LeftShoulder = true, ["Left Shoulder"] = true }

local function scan(rig: Rig)
	rig.right, rig.left = nil, nil
	for _, d in rig.character:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			if RIGHT[d.Name] then
				rig.right = d
			elseif LEFT[d.Name] then
				rig.left = d
			end
		end
	end
end

local function rigOf(player: Player): Rig?
	local character = player.Character
	if not character then
		rigs[player] = nil
		return nil
	end
	local rig = rigs[player]
	if not rig or rig.character ~= character then
		rig = { character = character, weight = 0 }
		rigs[player] = rig
		scan(rig)
	elseif not (rig.right and rig.right.Parent and rig.left and rig.left.Parent) then
		scan(rig)
	end
	return rig
end

-- A rotation in the torso's axes, applied at the joint.
local function apply(joint: Instance?, x: number, z: number, weight: number)
	local r: CFrame
	if joint and joint:IsA("Motor6D") then
		r = joint.C0.Rotation
	elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
		r = joint.Attachment0.CFrame.Rotation
	else
		return
	end
	local target = r:Inverse() * CFrame.Angles(x, 0, z) * r
	local j = joint :: any
	j.Transform = (j.Transform :: CFrame):Lerp(target, weight)
end

local function step(dt: number)
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position
	local now = os.clock()
	local rate = dt / math.max(Config.PlayerAnim.Blend, 0.01)
	for _, player in Players:GetPlayers() do
		local kind = PlayerPoses.kindOf(player:GetAttribute("CarryingCat"), player:GetAttribute("Fishing"))
		local rig = if kind or rigs[player] then rigOf(player) else nil
		if rig then
			local root = rig.character.PrimaryPart
			local near = root ~= nil and eye ~= nil and (root.Position - eye).Magnitude < Config.PlayerAnim.Range
			if kind then
				rig.kind = kind
			end
			rig.weight = math.clamp(rig.weight + (if kind and near then rate else -rate), 0, 1)
			if rig.weight > 0 and rig.kind then
				local a = PlayerPoses.arms(rig.kind, now + player.UserId % 7)
				local w = rig.weight * rig.weight * (3 - 2 * rig.weight)
				apply(rig.right, a.rx, a.rz, w)
				apply(rig.left, a.lx, a.lz, w)
			elseif not kind then
				rigs[player] = nil
			end
		end
	end
end

function PlayerAnimController.Start(_self: any)
	RunService.PreSimulation:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		rigs[player] = nil
	end)
end

return PlayerAnimController
