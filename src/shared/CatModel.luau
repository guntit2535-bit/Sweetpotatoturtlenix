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
local FxMeshes = require(script.Parent.FxMeshes)

export type Look = {
	design: string,
	tint: string?, -- colour variant (shared/Cats)
	mutation: string?, -- "Gold" | "Rainbow" | "Glow" (task 2.9)
}

local CatModel = {}

CatModel.Tag = "Cat" -- CollectionService tag on every cat model (the client animates tagged cats)
CatModel.Bones = table.clone(CatShapes.Bones)
table.insert(CatModel.Bones, "FxStill") -- V5j: the effect's pieces on the ground (they do not spin)
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
	FxStill = "Root",
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

-- V5j effect pieces ------------------------------------------------------------------------------------------
local function fxSetup(p: BasePart, parent: Instance, color: Color3, neon: boolean, transparency: number)
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Transparency = transparency
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Name = "Fx"
	p.Parent = parent
end

-- every layer of a library kind at cf, scaled (x, y, z); glow layers only when the piece glows
local function fxLayers(parent: Instance, kind: string, cf: CFrame, scale: Vector3, color: Color3, emit: number): number
	local made = 0
	for _, layer in FxMeshes.layers(kind) or {} do
		if layer.transparency > 0 and emit < 0.4 then
			continue
		end
		local p = FxMeshes.part(layer)
		if p then
			p.Size = layer.size * scale
			p.CFrame = cf * CFrame.new(FxMeshes.offset(layer, scale))
			fxSetup(p, parent, FxMeshes.tint(layer, color), layer.glows and emit >= 1, layer.transparency)
			made += 1
		end
	end
	return made
end

local function disc(parent: Instance, cf: CFrame, radius: number, color: Color3, transparency: number)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.02, radius * 2, radius * 2)
	p.CFrame = cf
	fxSetup(p, parent, color, true, transparency)
end

local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's axis (X) turned to point up

local function light(c: Color3, k: number): Color3
	return c:Lerp(WHITE, k)
end

-- Builds the pieces; returns the Secret burst ("x,y,z,r,top,hex,hex": from the model's pivot, at size 1) when there is one.
local function buildFx(pieces: { CatShapes.FxPiece }, spin: Model, still: Model, origin: Vector3): string?
	local burst: string? = nil
	local R = FxMeshes.BuiltRadius
	for _, piece in pieces do
		local col = piece.colors[1] or WHITE
		local at = piece.at
		if piece.what == "I" then
			local out = if piece.out.Magnitude > 1e-3 then piece.out.Unit else Vector3.new(0, 0, -1)
			local cf = CFrame.lookAt(at, at + out)
			if fxLayers(spin, piece.kind, cf, Vector3.one * piece.s, col, piece.emit) == 0 then
				-- no meshes imported yet: a small glowing ball in its place
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Ball
				p.Size = Vector3.one * math.max(0.2, piece.s * 0.55)
				p.CFrame = cf
				fxSetup(p, spin, col, piece.emit >= 1, 0)
			end
		elseif piece.what == "G" then
			for k, d in { { 0.55, 0.84 }, { 0.8, 0.9 }, { 1, 0.93 } } do
				disc(still, CFrame.new(at + Vector3.new(0, 0.04 + k * 0.004, 0)) * UP, piece.r * d[1], light(col, 0.35), d[2])
			end
			local k = piece.r / R.GlowRing
			fxLayers(still, "GlowRing", CFrame.new(at + Vector3.new(0, 0.05, 0)), Vector3.new(k, 1, k), light(col, 0.5), 3)
		elseif piece.what == "M" then
			disc(still, CFrame.new(at + Vector3.new(0, 0.04, 0)) * UP, piece.r, col, 0.82)
			local k = piece.r / R.MagicCircle
			fxLayers(still, "MagicCircle", CFrame.new(at + Vector3.new(0, 0.05, 0)), Vector3.new(k, 1, k), col, 3)
		elseif piece.what == "R" then
			local k = piece.r / R.RingSeg
			local n = #piece.colors
			for i = 0, 11 do
				local c = piece.colors[math.floor(i * n / 12) + 1] or col
				fxLayers(spin, "RingSeg", CFrame.new(at) * CFrame.Angles(0, i * math.pi / 6, 0), Vector3.new(k, 1, k), light(c, 0.25), 3)
			end
		elseif piece.what == "W" then
			local face = CFrame.new(at) -- the wheel stands in the X / Y plane behind the cat
			disc(still, face * CFrame.Angles(0, math.pi / 2, 0), piece.r * 0.62, col, 0.75)
			local k = piece.r * 0.62 / R.GlowRing
			fxLayers(still, "GlowRing", face * CFrame.Angles(math.pi / 2, 0, 0), Vector3.new(k, 1, k), light(col, 0.3), 3)
			local ray = (FxMeshes.layers("WheelRay") or {})[1]
			-- the import turn puts the ray's thick end on +X: turn it inward
			local turn = if (Config.ItemModels :: any).Flip then CFrame.Angles(0, 0, math.pi) else CFrame.identity
			for i = 0, piece.n - 1 do
				local len = piece.r * 0.3 + (if i % 2 == 0 then 0.35 else 0)
				local c = piece.colors[i % math.max(1, #piece.colors) + 1] or col
				local p = if ray then FxMeshes.part(ray) else nil
				if ray and p then
					p.Size = Vector3.new(len, ray.size.Y, ray.size.Z)
					p.CFrame = face * CFrame.Angles(0, 0, i * 2 * math.pi / piece.n) * CFrame.new(piece.r * 0.7 + len / 2, 0, 0) * turn
					fxSetup(p, still, c, true, 0)
				end
			end
		elseif piece.what == "B" then
			local hexes = {}
			for _, c in piece.colors do
				table.insert(hexes, c:ToHex())
			end
			local rel = at - origin
			burst = string.format("%.2f,%.2f,%.2f,%.2f,%.2f,%s", rel.X, rel.Y, rel.Z, piece.r, piece.top - origin.Y, table.concat(hexes, ","))
		end
	end
	return burst
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
	local function addBone(name: string, at0: Vector3)
		local b = Instance.new("Model")
		b.Name = name
		b.Parent = m
		bones[name] = b
		local j = newPart(b, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at0), WHITE, "Joint")
		j.Transparency = 1
		j.CastShadow = false
	end
	for _, name in CatModel.Bones do
		local at0 = shape.bones[name]
		if at0 then
			addBone(name, at0)
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

	-- V5j: the effect round a Mythical / Secret cat, from the mesh library (Fx spins, FxStill stays on the ground)
	if #shape.fx > 0 then
		local pivot = shape.bones.Fx or shape.pivot
		if not bones.Fx then
			addBone("Fx", pivot)
		end
		addBone("FxStill", pivot)
		local burst = buildFx(shape.fx, bones.Fx, bones.FxStill, shape.pivot)
		if burst then
			m:SetAttribute("Burst", burst)
		end
		for _, piece in shape.fx do
			if piece.what == "I" and piece.colors[1] and #fxColors < 2 and not table.find(fxColors, piece.colors[1]) then
				table.insert(fxColors, piece.colors[1])
			end
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
