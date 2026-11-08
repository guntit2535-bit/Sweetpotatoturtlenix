--!strict
-- Animates every cat near the camera (A6): each frame the clip named by the cat's "Anim" attribute
-- (shared/CatAnims: idle, walk, struggle, carried, sleep, showcase) is turned into Motor6D.Transform values
-- on its rig (shared/CatModel). Client only: nothing replicates and no animation assets are needed.
-- Far cats (Config.CatAnim.Range) are skipped. Each cat gets its own time offset so they do not move in sync.
-- StreamingEnabled: a cat can arrive before its joints do, so a rig with missing motors (fewer than the
-- model's "Bones" attribute, or a motor that left) is looked up again every RescanSeconds.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatAnims = require(Shared:WaitForChild("CatAnims"))
local CatModel = require(Shared:WaitForChild("CatModel"))
local Config = require(Shared:WaitForChild("Config"))

type Rig = {
	model: Model,
	root: BasePart?,
	motors: { [string]: Motor6D },
	count: number,
	offset: number,
	nextScan: number,
}

local CatAnimController = {}

local rigs: { [Model]: Rig } = {}
local pose = CatAnims.blank()
local angles = CFrame.Angles

local function scan(rig: Rig, now: number)
	local model = rig.model
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	rig.root = if root and root:IsA("BasePart") then root else nil
	table.clear(rig.motors)
	rig.count = 0
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			rig.motors[d.Name] = d
			rig.count += 1
		end
	end
	rig.nextScan = now + Config.CatAnim.RescanSeconds
end

local function complete(rig: Rig): boolean
	local want = rig.model:GetAttribute("Bones")
	if not rig.root or not rig.root.Parent then
		return false
	end
	if type(want) == "number" and rig.count < want then
		return false
	end
	for _, m in rig.motors do
		if not m.Parent then
			return false
		end
	end
	return rig.count > 0
end

local function register(inst: Instance)
	if not inst:IsA("Model") or rigs[inst] then
		return
	end
	rigs[inst] = { model = inst, root = nil, motors = {}, count = 0, offset = math.random() * 100, nextScan = 0 }
end

local function unregister(inst: Instance)
	if inst:IsA("Model") then
		rigs[inst] = nil
	end
end

local function set(motors: { [string]: Motor6D }, name: string, cf: CFrame)
	local m = motors[name]
	if m then
		m.Transform = cf
	end
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local range = Config.CatAnim.Range
	local now = os.clock()
	for model, rig in rigs do
		if not model.Parent then
			rigs[model] = nil
			continue
		end
		if not complete(rig) then
			if now >= rig.nextScan then
				scan(rig, now)
			end
			if not complete(rig) then
				continue
			end
		end
		local root = rig.root :: BasePart
		local scale = model:GetScale()
		if (root.Position - eye).Magnitude > range * math.max(1, scale) then
			continue
		end
		local clip = model:GetAttribute("Anim")
		CatAnims.pose(if type(clip) == "string" then clip else "idle", now + rig.offset, pose)
		local m = rig.motors
		set(m, "Body", CFrame.new(0, pose.bodyY * scale, 0) * angles(pose.bodyPitch, pose.bodyYaw, pose.bodyRoll))
		set(m, "Head", angles(pose.headPitch, pose.headYaw, pose.headRoll))
		set(m, "Tail1", angles(pose.tail1Pitch, pose.tail1Yaw, 0))
		set(m, "Tail2", angles(pose.tail2Pitch, pose.tail2Yaw, 0))
		set(m, "LegFL", angles(pose.legFL, 0, 0))
		set(m, "LegFR", angles(pose.legFR, 0, 0))
		set(m, "LegBL", angles(pose.legBL, 0, 0))
		set(m, "LegBR", angles(pose.legBR, 0, 0))
		set(m, "WingL", angles(0, 0, -pose.wing))
		set(m, "WingR", angles(0, 0, pose.wing))
	end
end

function CatAnimController.Start(_self: any)
	for _, inst in CollectionService:GetTagged(CatModel.Tag) do
		register(inst)
	end
	CollectionService:GetInstanceAddedSignal(CatModel.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(CatModel.Tag):Connect(unregister)
	RunService.PreAnimation:Connect(step)
end

return CatAnimController
