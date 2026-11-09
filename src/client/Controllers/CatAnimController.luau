--!strict
-- Animates every cat near the camera (A6, V5i): each frame the clip named by the cat's "Anim" attribute
-- (shared/CatAnims: idle, walk, struggle, carried, sleep, showcase) poses its rig (shared/CatModel). Client only:
-- nothing replicates and no animation assets are needed. Each cat gets its own time offset.
--
-- Two kinds of rig (the model's "Rig" attribute):
--   "anchored" (every cat on the ground): all blocks anchored, no joints. Each bone's blocks are moved here with
--     one workspace:BulkMoveTo per frame, from the Root's CFrame and the rest offsets read when the cat arrived.
--     Moving a block costs ~3 us (Studio PC, V5i), so a frame moves at most PartBudget blocks, nearest cats first:
--     cats within Config.CatAnim.Near every frame, up to Mid every MidSeconds if the budget allows; off-screen and
--     farther cats keep their last pose (phones: a smaller budget).
--   "joints" (a carried cat, CatModel.joinRig): Motor6D.Transform per bone.
-- StreamingEnabled: a cat is used once its bones have all arrived (the "Bones" attribute); a carried cat is read
-- again when its Rig changes.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatAnims = require(Shared:WaitForChild("CatAnims"))
local CatModel = require(Shared:WaitForChild("CatModel"))
local Config = require(Shared:WaitForChild("Config"))

type Bone = {
	name: string,
	parent: string,
	rel: CFrame, -- the joint in its parent's joint space (rest)
	parts: { BasePart },
	offsets: { CFrame }, -- each part in its joint's space (rest)
}

type Rig = {
	model: Model,
	kind: string, -- "anchored" | "joints" | "" (not read yet)
	root: BasePart?,
	scale: number,
	bones: { Bone }, -- anchored: parents first
	motors: { [string]: Motor6D }, -- joints
	offset: number,
	nextPose: number, -- anchored: when this cat is posed again
	count: number, -- anchored: how many blocks a pose moves
	nextScan: number,
	conn: RBXScriptConnection?,
}

local CatAnimController = {}

local rigs: { [Model]: Rig } = {}
local pose = CatAnims.blank()
local angles = CFrame.Angles
local phone = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local moveParts: { BasePart } = {}
local moveCFrames: { CFrame } = {}
local world: { [string]: CFrame } = {}

local tf: { [string]: CFrame } = {}

-- bone -> its transform for this pose (same angles for both kinds of rig), into tf
local function transforms(scale: number)
	tf.Body = CFrame.new(0, pose.bodyY * scale, 0) * angles(pose.bodyPitch, pose.bodyYaw, pose.bodyRoll)
	tf.Head = angles(pose.headPitch, pose.headYaw, pose.headRoll)
	tf.Tail1 = angles(pose.tail1Pitch, pose.tail1Yaw, 0)
	tf.Tail2 = angles(pose.tail2Pitch, pose.tail2Yaw, 0)
	tf.LegFL = angles(pose.legFL, 0, 0)
	tf.LegFR = angles(pose.legFR, 0, 0)
	tf.LegBL = angles(pose.legBL, 0, 0)
	tf.LegBR = angles(pose.legBR, 0, 0)
	tf.WingL = angles(0, 0, -pose.wing)
	tf.WingR = angles(0, 0, pose.wing)
	tf.Fx = angles(0, pose.fxYaw, 0)
end

local function read(rig: Rig, now: number)
	rig.nextScan = now + Config.CatAnim.RescanSeconds
	local model = rig.model
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	rig.root = if root and root:IsA("BasePart") then root else nil
	rig.kind = ""
	table.clear(rig.bones)
	table.clear(rig.motors)
	if not rig.root then
		return
	end
	local want = model:GetAttribute("Bones")
	local kind = model:GetAttribute("Rig")
	if kind == "joints" then
		local count = 0
		for _, d in model:GetDescendants() do
			if d:IsA("Motor6D") then
				rig.motors[d.Name] = d
				count += 1
			end
		end
		if count > 0 and (type(want) ~= "number" or count >= want) then
			rig.kind = "joints"
		end
		return
	end
	-- anchored: the rest offsets as the cat is now (the server's pose)
	local rootCf = (rig.root :: BasePart).CFrame
	local jointAt: { [string]: CFrame } = { Root = rootCf }
	local count = 0
	for _, name in CatModel.Bones do
		local b = model:FindFirstChild(name)
		local j = b and b:FindFirstChild("Joint")
		if b and j and j:IsA("BasePart") then
			count += 1
			local jc = j.CFrame
			jointAt[name] = jc
			local parentName = CatModel.Parent[name] or "Root"
			if not jointAt[parentName] then
				parentName = if jointAt.Body then "Body" else "Root"
			end
			local bone: Bone = {
				name = name,
				parent = parentName,
				rel = jointAt[parentName]:ToObjectSpace(jc),
				parts = {},
				offsets = {},
			}
			for _, p in b:GetChildren() do
				if p:IsA("BasePart") and p ~= j then
					table.insert(bone.parts, p)
					table.insert(bone.offsets, jc:ToObjectSpace(p.CFrame))
				end
			end
			table.insert(rig.bones, bone)
		end
	end
	if count > 0 and (type(want) ~= "number" or count >= want) then
		rig.kind = "anchored"
		rig.scale = model:GetScale()
		rig.count = 0
		for _, bone in rig.bones do
			rig.count += #bone.parts
		end
	end
end

local function register(inst: Instance)
	if not inst:IsA("Model") or rigs[inst] then
		return
	end
	rigs[inst] = {
		model = inst,
		kind = "",
		root = nil,
		scale = 1,
		bones = {},
		motors = {},
		offset = math.random() * 100,
		nextPose = 0,
		count = 0,
		nextScan = 0,
		conn = nil,
	}
	local rig = rigs[inst]
	-- a carried cat changes Rig: read it again
	rig.conn = inst:GetAttributeChangedSignal("Rig"):Connect(function()
		rig.kind = ""
		rig.nextScan = 0
	end)
end

local function unregister(inst: Instance)
	if inst:IsA("Model") then
		local rig = rigs[inst]
		if rig and rig.conn then
			rig.conn:Disconnect()
		end
		rigs[inst] = nil
	end
end

local function poseAnchored(rig: Rig, now: number)
	local clip = rig.model:GetAttribute("Anim")
	CatAnims.pose(if type(clip) == "string" then clip else "idle", now + rig.offset, pose)
	transforms(rig.scale)
	world.Root = (rig.root :: BasePart).CFrame
	for _, bone in rig.bones do
		local w = world[bone.parent] * bone.rel * (tf[bone.name] or CFrame.identity)
		world[bone.name] = w
		local offsets = bone.offsets
		for i, p in bone.parts do
			table.insert(moveParts, p)
			table.insert(moveCFrames, w * offsets[i])
		end
	end
	table.clear(world)
end

type Due = { rig: Rig, dist: number }
local due: { Due } = {}
local function nearer(a: Due, b: Due): boolean
	return a.dist < b.dist
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local cfg = Config.CatAnim
	local range = if phone then cfg.PhoneRange else cfg.Range
	local budget = if phone then cfg.PhonePartBudget else cfg.PartBudget
	local now = os.clock()
	table.clear(moveParts)
	table.clear(moveCFrames)
	table.clear(due)
	for model, rig in rigs do
		if not model.Parent then
			unregister(model)
			continue
		end
		if rig.kind == "" or not (rig.root and rig.root.Parent) then
			if now < rig.nextScan then
				continue
			end
			read(rig, now)
			if rig.kind == "" then
				continue
			end
		end
		local root = rig.root :: BasePart
		local pos = root.Position
		local scale = if rig.kind == "anchored" then rig.scale else model:GetScale()
		local dist = (pos - eye).Magnitude / math.max(1, scale)
		if dist > range then
			continue
		end
		if rig.kind == "joints" then
			-- a carried cat: Motor6D transforms (cheap, few of them)
			local clip = model:GetAttribute("Anim")
			CatAnims.pose(if type(clip) == "string" then clip else "idle", now + rig.offset, pose)
			transforms(scale)
			for name, motor in rig.motors do
				local t = tf[name]
				if t then
					motor.Transform = t
				end
			end
			continue
		end
		if now < rig.nextPose or dist > cfg.Mid then
			continue -- far ground cats hold their last pose (nobody sees it at that distance)
		end
		if dist > cfg.Near then
			local _, onScreen = camera:WorldToViewportPoint(pos)
			if not onScreen then
				continue
			end
		end
		table.insert(due, { rig = rig, dist = dist })
	end
	-- nearest first, until the frame's budget of moved blocks is used (the rest keep their last pose)
	table.sort(due, nearer)
	for _, d in due do
		if #moveParts > 0 and #moveParts + d.rig.count > budget then
			break
		end
		d.rig.nextPose = now + (if d.dist < cfg.Near then 0 else cfg.MidSeconds)
		poseAnchored(d.rig, now)
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function CatAnimController.Start(_self: any)
	CatAnims.FxSpin = Config.CatAnim.FxSpin
	for _, inst in CollectionService:GetTagged(CatModel.Tag) do
		register(inst)
	end
	CollectionService:GetInstanceAddedSignal(CatModel.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(CatModel.Tag):Connect(unregister)
	-- the average time this takes a frame, every second on the player ("CatAnimMs" attribute: phone checks, V5i)
	local spent, frames, since = 0, 0, os.clock()
	-- PreSimulation, after the animation step: a carried cat sits inside the character, whose Animator would reset
	-- its Motor6D transforms (checked in Studio, V5i)
	RunService.PreSimulation:Connect(function()
		local t = os.clock()
		step()
		spent += os.clock() - t
		frames += 1
		if t - since >= 1 then
			game:GetService("Players").LocalPlayer:SetAttribute("CatAnimMs", math.floor(spent / frames * 1e5) / 100)
			spent, frames, since = 0, 0, t
		end
	end)
end

return CatAnimController
