--!strict
-- Player arm poses (task 2.22): every client poses the arms of every player near the camera from the
-- attributes the server sets: "CarryingCat" -> both arms up holding the cat, "Fishing" -> reeling
-- (shared/PlayerPoses). Done each frame after the Animator, on the shoulder joints' Transform values, so the
-- legs keep walking and nothing has to be uploaded. Works for R15 and R6, and for both joint kinds Roblox uses
-- (Motor6D, and AnimationConstraint on the newer avatars): the pose is turned from the torso's axes into
-- each joint's own axes. The cast and bat swing are the default tool "Slash" (server, ToolAnim).
-- R6 task: "Training" = "weights" -> the two-hand curl, which also bends the elbows (R15 only: a rig without
-- elbows is left to TrainingController's cheer).
-- V2: reeling on R15 with the mesh rod: the left hand is placed on the rod's crank (the "Reel" attachment on
-- the rod's Handle) and follows it round its circle: a two-bone solve for the left shoulder and elbow.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerPoses = require(Shared:WaitForChild("PlayerPoses"))

type Rig = {
	character: Model,
	right: Instance?,
	left: Instance?,
	rightElbow: Instance?,
	leftElbow: Instance?,
	leftWrist: Instance?,
	weight: number,
	kind: string?,
}

local PlayerAnimController = {}

local rigs: { [Player]: Rig } = {}
local RIGHT = { RightShoulder = true, ["Right Shoulder"] = true }
local LEFT = { LeftShoulder = true, ["Left Shoulder"] = true }

local function scan(rig: Rig)
	rig.right, rig.left, rig.rightElbow, rig.leftElbow, rig.leftWrist = nil, nil, nil, nil, nil
	for _, d in rig.character:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			if RIGHT[d.Name] then
				rig.right = d
			elseif LEFT[d.Name] then
				rig.left = d
			elseif d.Name == "RightElbow" then
				rig.rightElbow = d
			elseif d.Name == "LeftElbow" then
				rig.leftElbow = d
			elseif d.Name == "LeftWrist" then
				rig.leftWrist = d
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

-- A joint's pivot in the world and the part it hangs from (Motor6D: Part0 * C0; AnimationConstraint: its
-- Attachment0), and the offsets used for the arm lengths.
local function pivot(joint: Instance?): (CFrame?, Vector3?, Vector3?)
	if joint and joint:IsA("Motor6D") and joint.Part0 then
		return joint.Part0.CFrame * joint.C0, joint.C0.Position, joint.C1.Position
	elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 and joint.Attachment1 then
		return joint.Attachment0.WorldCFrame, joint.Attachment0.Position, joint.Attachment1.Position
	end
	return nil, nil, nil
end

-- V2: the left arm's shoulder (x, z) and elbow angles that put the left hand on `target` (world). Works from the
-- rig's own rest arm (the bones as built: shoulder -> elbow -> wrist -> hand, which need not hang straight
-- down): hand = Rshoulder * (upper + Relbow * lower), Rshoulder = Angles(x, 0, z) in the torso's axes,
-- Relbow = Angles(e, 0, 0) in the upper arm's. Out of reach: the arm stretches towards it.
local function reachLeft(rig: Rig, target: Vector3): (number?, number?, number?)
	local s, _, sChild = pivot(rig.left) -- shoulder pivot (world); its offset in the upper arm
	local _, eParent, eChild = pivot(rig.leftElbow) -- elbow offset in the upper arm / in the lower arm
	local _, wParent = pivot(rig.leftWrist) -- wrist offset in the lower arm
	local joint = rig.left
	local torso: BasePart? = nil
	if joint and joint:IsA("Motor6D") then
		torso = joint.Part0
	elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
		local p = joint.Attachment0.Parent
		torso = if p and p:IsA("BasePart") then p else nil
	end
	if not s or not sChild or not eParent or not eChild or not wParent or not torso then
		return nil, nil, nil
	end
	local upper = eParent - sChild
	local lower = wParent - eChild
	lower += lower.Unit * 0.25 -- to the middle of the hand
	local d = torso.CFrame:VectorToObjectSpace(target - s.Position)
	-- the elbow: bisection on the reach (|upper + R(e) lower| shrinks as the elbow bends)
	local function reach(e: number): number
		return (upper + CFrame.Angles(e, 0, 0) * lower).Magnitude
	end
	local lo, hi = 0, 2.6
	local want = math.clamp(d.Magnitude, reach(hi), reach(lo))
	for _ = 1, 14 do
		local mid = (lo + hi) / 2
		if reach(mid) > want then
			lo = mid
		else
			hi = mid
		end
	end
	local e = (lo + hi) / 2
	local v = upper + CFrame.Angles(e, 0, 0) * lower
	d = d.Unit * v.Magnitude
	-- the shoulder: Rz first (v.x -> d.x), then Rx (the rest of the way)
	local r = math.sqrt(v.X * v.X + v.Y * v.Y)
	local phi = math.atan2(v.Y, v.X)
	local c = math.clamp(d.X / math.max(r, 1e-3), -1, 1)
	local z1, z2 = math.acos(c) - phi, -math.acos(c) - phi
	local function wrap(a: number): number
		return (a + math.pi) % (2 * math.pi) - math.pi
	end
	z1, z2 = wrap(z1), wrap(z2)
	local z = if math.abs(z1) < math.abs(z2) then z1 else z2
	local vz = CFrame.Angles(0, 0, z) * v
	local x = wrap(math.atan2(d.Z, d.Y) - math.atan2(vz.Z, vz.Y))
	return x, z, e
end

local function crankTarget(character: Model, angle: number): Vector3?
	local rod = character:FindFirstChild("Rod")
	local handle = rod and rod:FindFirstChild("Handle")
	local reel = handle and handle:FindFirstChild("Reel")
	if not handle or not handle:IsA("BasePart") or not reel or not reel:IsA("Attachment") then
		return nil
	end
	local r = reel:GetAttribute("Radius")
	local radius = if type(r) == "number" then r else 0.6
	return handle.CFrame:PointToWorldSpace(reel.Position + Vector3.new(0, math.cos(angle), math.sin(angle)) * radius)
end

local function step(dt: number)
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position
	local now = os.clock()
	local rate = dt / math.max(Config.PlayerAnim.Blend, 0.01)
	for _, player in Players:GetPlayers() do
		local kind = PlayerPoses.kindOf(player:GetAttribute("CarryingCat"), player:GetAttribute("Fishing"), player:GetAttribute("Training"))
		local rig = if kind or rigs[player] then rigOf(player) else nil
		if rig and kind == "curl" and not rig.rightElbow then
			kind = nil -- R6: no elbows, the cheer plays instead
		end
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
				local target = if a.crank and rig.leftElbow then crankTarget(rig.character, a.crank) else nil
				local lx, lz, le = nil, nil, nil
				if target then
					lx, lz, le = reachLeft(rig, target)
				end
				if lx and lz and le then
					apply(rig.left, lx, lz, w)
					apply(rig.leftElbow, le, 0, w)
				else
					apply(rig.left, a.lx, a.lz, w)
				end
				if a.re then
					apply(rig.rightElbow, a.re, 0, w)
				end
				if a.le then
					apply(rig.leftElbow, a.le, 0, w)
				end
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
