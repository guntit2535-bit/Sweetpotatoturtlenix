--!strict
-- The Secret burst (V5j, developer 2026-11-09: "a spiral shoots up from the ground and vanishes every 3 s"): every
-- Config.CatFx.BurstEvery seconds, two ribbons of light (Roblox Trails behind two invisible movers) spiral up round
-- each Secret cat near the camera and fade. Client only, nothing replicates, no assets. The cat model carries the
-- spiral in its "Burst" attribute (shared/CatModel: "x,y,z,r,top,hex,hex" from its pivot at size 1).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatModel = require(Shared:WaitForChild("CatModel"))
local Config = require(Shared:WaitForChild("Config"))

type Burst = { x: number, y: number, z: number, r: number, top: number, colors: { Color3 } }
type Flight = {
	model: Model,
	burst: Burst,
	started: number,
	movers: { BasePart },
}

local CatFxController = {}

local nextAt: { [Model]: number } = {}
local flights: { Flight } = {}
local folder: Folder? = nil

local function parse(text: unknown): Burst?
	if type(text) ~= "string" then
		return nil
	end
	local f = string.split(text, ",")
	if #f < 6 then
		return nil
	end
	local colors = {}
	for i = 6, #f do
		local ok, c = pcall(Color3.fromHex, f[i])
		if ok then
			table.insert(colors, c)
		end
	end
	local n = function(i: number): number
		return tonumber(f[i]) or 0
	end
	return { x = n(1), y = n(2), z = n(3), r = n(4), top = n(5), colors = colors }
end

local function holder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "CatFx"
	f.Parent = workspace
	folder = f
	return f
end

local function mover(color: Color3, width: number): BasePart
	local cfg = Config.CatFx
	local p = Instance.new("Part")
	p.Name = "BurstMover"
	p.Size = Vector3.new(0.1, 0.1, 0.1)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = p
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color)
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	t.Lifetime = cfg.TrailSeconds
	t.LightEmission = 1
	t.LightInfluence = 0
	t.FaceCamera = true
	t.MinLength = 0.02
	t.Parent = p
	p.Parent = holder()
	return p
end

-- where mover k is at u (0 = on the ground, 1 = at the top) of the spiral, in world space
local function spiralPoint(model: Model, b: Burst, k: number, u: number): Vector3
	local scale = model:GetScale()
	local a = (k - 1) * math.pi + u * Config.CatFx.Turns * 2 * math.pi
	local rr = b.r * (1 - 0.25 * u)
	local local3 = Vector3.new(b.x + math.cos(a) * rr, b.y + (b.top - b.y) * u, b.z + math.sin(a) * rr)
	return model:GetPivot():PointToWorldSpace(local3 * scale)
end

local function launch(model: Model, b: Burst, now: number)
	local scale = model:GetScale()
	local movers = {}
	for k = 1, 2 do
		local p = mover(b.colors[k] or b.colors[1] or Color3.new(1, 1, 1), Config.CatFx.Width * math.max(1, scale * 0.6))
		p.CFrame = CFrame.new(spiralPoint(model, b, k, 0))
		table.insert(movers, p)
	end
	table.insert(flights, { model = model, burst = b, started = now, movers = movers })
end

local function step()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local cfg = Config.CatFx
	local now = os.clock()
	local eye = camera.CFrame.Position
	-- new bursts
	for _, inst in CollectionService:GetTagged(CatModel.Tag) do
		if not inst:IsA("Model") then
			continue
		end
		local text = inst:GetAttribute("Burst")
		if not text then
			continue
		end
		local due = nextAt[inst]
		if not due then
			nextAt[inst] = now + math.random() * cfg.BurstEvery -- not every Secret cat at once
			continue
		end
		if now < due then
			continue
		end
		nextAt[inst] = now + cfg.BurstEvery
		local root = inst.PrimaryPart
		if not root or (root.Position - eye).Magnitude > cfg.Range * math.max(1, inst:GetScale()) then
			continue
		end
		local b = parse(text)
		if b then
			launch(inst, b, now)
		end
	end
	-- flying ribbons
	for i = #flights, 1, -1 do
		local f = flights[i]
		local u = (now - f.started) / cfg.FlySeconds
		if u >= 1 + cfg.TrailSeconds / cfg.FlySeconds or not f.model.Parent then
			for _, p in f.movers do
				p:Destroy()
			end
			table.remove(flights, i)
			continue
		end
		if u <= 1 then
			local eased = 1 - (1 - u) ^ 2 -- fast out of the ground, slowing at the top
			for k, p in f.movers do
				p.CFrame = CFrame.new(spiralPoint(f.model, f.burst, k, eased))
			end
		end
	end
	for model in nextAt do
		if not model.Parent then
			nextAt[model] = nil
		end
	end
end

function CatFxController.Start(_self: any)
	RunService.Heartbeat:Connect(step)
end

return CatFxController
