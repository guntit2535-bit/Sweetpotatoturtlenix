--!strict
-- Builds a rigged block cat Model (V5h) from its design's blocks (shared/CatShapes, made in Blender and approved
-- as the art/preview/cats_v1 sheets). One block = one Part; the LEGO studs are a look on the part (Config.Cats.Studs),
-- not extra parts.
--
-- Rig ("bones"): an anchored, invisible Root; every bone is a sub-model with an invisible "Joint" part at its
-- pivot and its blocks. Every part is anchored (attribute Rig = "anchored"): the client moves the blocks of nearby
-- cats to animate them. CatModel.joinRig (a carried cat) welds the blocks to their Joint and adds a Motor6D per bone
-- (Rig = "joints"). Bones:
--   Root > Body > Head
--               > Tail1 > Tail2
--               > LegFL, LegFR, LegBL, LegBR   (a mermaid / genie has no back legs: those bones are left out)
--               > WingL, WingR                 (only cats with wings)
--        > Fx                                  (Mythical / Secret: the things round the cat; it spins)
-- The client animates them (CatAnimController + shared/CatAnims); moving the cat = PivotTo on the model. Front = -Z (the face), feet on y = 0 of the given CFrame.
-- Parts are not solid and not touchable; only Root can be hit by queries (fishing, clicks).
--
--   local cat = CatModel.build(look, CFrame.new(x, 0, z), 1.5)   -- look = Cats.ById[id].Look (+ mutation)

local CollectionService = game:GetService("CollectionService")

local CatShapes = require(script.Parent.CatShapes)
local Config = require(script.Parent.Config)

export type Look = {
	design: string,
	tint: string?, -- colour variant (shared/Cats)
	mutation: string?, -- "Gold" | "Rainbow" | "Glow" (task 2.9)
}

local CatModel = {}

CatModel.Tag = "Cat" -- CollectionService tag on every cat model (the client animates tagged cats)
CatModel.Bones = CatShapes.Bones
CatModel.BaseScale = Config.Cats.BaseScale

local PARENT: { [string]: string } = { -- each bone hangs from this one
	Body = "Root",
	Head = "Body",
	Tail1 = "Body",
	Tail2 = "Tail1",
	LegFL = "Body",
	LegFR = "Body",
	LegBL = "Body",
	LegBR = "Body",
	WingL = "Body",
	WingR = "Body",
	Fx = "Root",
}

CatModel.Parent = PARENT

local hex = Color3.fromHex
local WHITE = Color3.new(1, 1, 1)
local GOLD = hex("ffcc33")
local GOLD_FUR = hex("f6c945")
local GOLD_DARK = hex("d9a520")
local RAINBOW = { hex("ff5a5a"), hex("ffd23f"), hex("5ad67a"), hex("4fb6ff"), hex("b06bff") }
local SURFACES = { "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }

local function setup(p: BasePart, color: Color3)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true -- unanchored when the rig is joined
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
end

local function newPart(parent: Instance, size: Vector3, cf: CFrame, color: Color3, name: string): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	setup(p, color)
	p.Name = name
	p.Parent = parent
	return p
end

-- A colour variant: the fur / pattern colour moved to the tint's hue, keeping its lightness.
local function tinted(c: Color3, target: Color3): Color3
	local _, s, v = c:ToHSV()
	local th, ts, tv = target:ToHSV()
	return Color3.fromHSV(th, math.clamp(s * 0.5 + ts * 0.6, 0, 0.9), math.clamp(v * 0.75 + tv * 0.25, 0.42, 1))
end
CatModel.tinted = tinted

local function studs(p: BasePart, which: string)
	local mode = Config.Cats.Studs
	if mode == "variant" and Config.Cats.StudsVariant ~= "" then
		p.MaterialVariant = Config.Cats.StudsVariant
	elseif mode == "surface" then
		p.Material = Enum.Material.Plastic -- Roblox draws the Studs surface on Plastic only
		if which == "top" then
			p.TopSurface = Enum.SurfaceType.Studs
		else
			for _, s in SURFACES do
				(p :: any)[s] = Enum.SurfaceType.Studs
			end
		end
	end
end

local function sparkles(parent: BasePart, colors: { Color3 }, rate: number, size: number)
	local e = Instance.new("ParticleEmitter")
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new(if #colors == 1 then 0 else (i - 1) / (#colors - 1), c))
	end
	if #keys == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	e.Color = ColorSequence.new(keys)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.LightEmission = 0.8
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(1, 2.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = parent
end

-- One block -> one Part (a cone = a few stepped cylinders, block style).
local function makePart(parent: Instance, spec: CatShapes.PartSpec, color: Color3): { BasePart }
	local kind = spec.kind
	local made: { BasePart } = {}
	if kind == "W" then
		local w = Instance.new("WedgePart")
		w.Size = spec.size
		w.CFrame = spec.cf
		setup(w, color)
		w.Name = "Wedge"
		w.Parent = parent
		table.insert(made, w)
	elseif kind == "K" then
		local n = Config.Cats.ConeSteps
		local h = spec.size.X
		local r1 = spec.size.Y / 2
		for k = 0, n - 1 do
			local t = (k + 0.5) / n
			local r = math.max(0.03, r1 + (spec.r2 - r1) * t)
			local p = newPart(parent, Vector3.new(h / n + 0.01, 2 * r, 2 * r), spec.cf * CFrame.new(-h / 2 + h * t, 0, 0), color, "Cone")
			p.Shape = Enum.PartType.Cylinder
			table.insert(made, p)
		end
	else
		local p = newPart(parent, spec.size, spec.cf, color, "Block")
		if kind == "S" then
			p.Shape = Enum.PartType.Ball
		elseif kind == "C" then
			p.Shape = Enum.PartType.Cylinder
		elseif kind == "E" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		elseif spec.studs then
			studs(p, spec.studs)
		end
		table.insert(made, p)
	end
	for _, p in made do
		if spec.neon then
			p.Material = Enum.Material.Neon
		end
		p.Transparency = spec.transparency
		local big = math.max(p.Size.X, p.Size.Y, p.Size.Z)
		p.CastShadow = big >= Config.Cats.ShadowMin and spec.transparency == 0 and not spec.neon
	end
	return made
end

-- The world box of a part spec (for the Root's size).
local function extent(spec: CatShapes.PartSpec): (Vector3, Vector3)
	local cf, h = spec.cf, spec.size / 2
	local x, y, z = cf.XVector, cf.YVector, cf.ZVector
	local e = Vector3.new(
		math.abs(x.X) * h.X + math.abs(y.X) * h.Y + math.abs(z.X) * h.Z,
		math.abs(x.Y) * h.X + math.abs(y.Y) * h.Y + math.abs(z.Y) * h.Z,
		math.abs(x.Z) * h.X + math.abs(y.Z) * h.Y + math.abs(z.Z) * h.Z
	)
	return cf.Position - e, cf.Position + e
end

function CatModel.build(look: Look, at: CFrame, size: number?): Model
	local shape = CatShapes.get(look.design)
	if not shape then
		warn(`[Sweetpotato] CatModel: unknown design {look.design}`)
		shape = CatShapes.get("Ginger Tabby") :: CatShapes.Shape
	end
	local mutation = look.mutation
	local target = if look.tint then hex(look.tint) else nil

	-- colours of this cat (variant tint, Gold / Glow mutation)
	local colors: { Color3 } = {}
	for i, p in shape.palette do
		local c = p.color
		if target and p.role ~= "-" then
			c = tinted(c, target)
		end
		if mutation == "Gold" and p.role == "f" then
			c = GOLD_FUR
		elseif mutation == "Gold" and p.role == "p" then
			c = GOLD_DARK
		elseif mutation == "Glow" and p.role == "f" then
			c = c:Lerp(WHITE, 0.15)
		end
		colors[i] = c
	end

	local m = Instance.new("Model")
	m.Name = "Cat"

	-- Root: an invisible box round the cat (not its effect), the part queries hit
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, spec in shape.parts do
		if spec.bone ~= "Fx" then
			local a, b = extent(spec)
			lo, hi = lo:Min(a), hi:Max(b)
		end
	end
	local root = newPart(m, hi - lo, CFrame.new((lo + hi) / 2), WHITE, "Root")
	root.Transparency = 1
	root.CanQuery = true
	root.CastShadow = false
	m.PrimaryPart = root

	-- bones: a sub-model with a Joint at the pivot
	local bones: { [string]: Model } = {}
	local joints: { [string]: BasePart } = { Root = root }
	for _, name in CatModel.Bones do
		local at0 = shape.bones[name]
		if at0 then
			local b = Instance.new("Model")
			b.Name = name
			b.Parent = m
			bones[name] = b
			local j = newPart(b, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at0), WHITE, "Joint")
			j.Transparency = 1
			j.CastShadow = false
			joints[name] = j
		end
	end

	local furParts: { BasePart } = {}
	local fxColors: { Color3 } = {}
	for _, spec in shape.parts do
		local b = bones[spec.bone] or bones.Body
		local made = makePart(b, spec, colors[spec.color] or WHITE)
		if shape.palette[spec.color] and shape.palette[spec.color].role == "f" then
			for _, p in made do
				table.insert(furParts, p)
			end
		end
		if spec.bone == "Fx" and spec.neon and #fxColors < 3 and not table.find(fxColors, colors[spec.color]) then
			table.insert(fxColors, colors[spec.color])
		end
	end

	-- the tier's glow: sparkles in the effect's colours and a soft light (Mythical / Secret)
	local tier = shape.tier
	if tier == "Mythical" or tier == "Secret" then
		if #fxColors == 0 then
			fxColors = { hex("ff9ae6"), WHITE }
		end
		sparkles(root, fxColors, if tier == "Secret" then 8 else 5, 0.45)
		local l = Instance.new("PointLight")
		l.Color = fxColors[1]
		l.Range = if tier == "Secret" then 14 else 10
		l.Brightness = 1
		l.Parent = root
	end

	-- mutations (task 2.9): Gold = golden fur + sparkles, Rainbow = rainbow sparkles, Glow = glowing fur
	if mutation == "Gold" then
		sparkles(root, { GOLD, hex("fff2a8") }, 6, 0.45)
	elseif mutation == "Rainbow" then
		sparkles(root, RAINBOW, 10, 0.55)
	elseif mutation == "Glow" then
		for _, p in furParts do
			p.Material = Enum.Material.Neon
		end
		local l = Instance.new("PointLight")
		l.Color = colors[1] or WHITE
		l.Range = 12
		l.Brightness = 1.4
		l.Parent = root
	end

	-- every part stays anchored: no joints, no physics (480 jointed cats cost ~40 ms of physics a frame in
	-- Studio). The client poses the blocks itself (CatAnimController); CatModel.joinRig makes a carried cat a
	-- jointed rig again.
	local boneCount = 0
	for _ in bones do
		boneCount += 1
	end

	-- pivot at the feet, under the middle of the body
	root.PivotOffset = root.CFrame:Inverse() * CFrame.new(shape.pivot)
	m:ScaleTo(CatModel.BaseScale * (size or 1))
	m:PivotTo(at)
	m:SetAttribute("Bones", boneCount) -- the client waits until this many bones have streamed in
	m:SetAttribute("Rig", "anchored")
	m:SetAttribute("Anim", "idle")
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- a cat streams in and out whole
	CollectionService:AddTag(m, CatModel.Tag)
	return m
end

-- A carried cat rides on its carrier's head (CarryService welds its Root to the character): its blocks are welded
-- to their bone's Joint and the bones joined with Motor6Ds named after them, so the client animates it with
-- Motor6D.Transform. Few cats are carried at a time, so their physics stays cheap.
function CatModel.joinRig(m: Model)
	if m:GetAttribute("Rig") == "joints" then
		return
	end
	local root = m.PrimaryPart :: BasePart
	local joints: { [string]: BasePart } = { Root = root }
	for _, name in CatModel.Bones do
		local b = m:FindFirstChild(name)
		local j = b and b:FindFirstChild("Joint")
		if b and j and j:IsA("BasePart") then
			joints[name] = j
			for _, p in b:GetChildren() do
				if p:IsA("BasePart") and p ~= j then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = j
					weld.Part1 = p
					weld.Parent = p
					p.Anchored = false
				end
			end
		end
	end
	for _, name in CatModel.Bones do
		local j = joints[name]
		if j then
			local parentJoint = joints[PARENT[name]] or joints.Body or root
			local motor = Instance.new("Motor6D")
			motor.Name = name
			motor.Part0 = parentJoint
			motor.Part1 = j
			motor.C0 = parentJoint.CFrame:Inverse() * j.CFrame
			motor.C1 = CFrame.new()
			motor.Parent = j
			j.Anchored = false
		end
	end
	m:SetAttribute("Rig", "joints")
end

return CatModel
