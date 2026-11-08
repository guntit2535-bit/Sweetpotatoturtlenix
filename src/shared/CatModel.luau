--!strict
-- Builds a blocky, rigged cat Model from a look (A6, style A like the map). The 400 cats (task 1.5) are
-- looks made from 3 base shapes x fur colours x patterns x accessories; higher tiers add effects.
--
-- Rig ("bones"): an anchored, invisible Root; every bone is a sub-model with an invisible "Joint" part
-- at its pivot, its parts welded to that Joint, and a Motor6D named after the bone inside the Joint:
--   Root > Body > Head
--               > Tail1 > Tail2
--               > LegFL, LegFR, LegBL, LegBR
--               > WingL, WingR        (only cats with wings)
-- The client animates the Motor6D.Transform values (CatAnimController + shared/CatAnims); moving the
-- cat = PivotTo on the model (the anchored Root carries everything).
-- Front = -Z (the face), feet on y = 0 of the given CFrame. Parts are not solid and not touchable; only
-- Root can be hit by queries (fishing, clicks).
--
--   local cat = CatModel.build(look, CFrame.new(x, 0, z), 1.5)   -- 1.5 = size multiplier
--
-- Colours in a look are hex strings ("ffb347") so the cat data stays plain data.

local CollectionService = game:GetService("CollectionService")

export type Look = {
	shape: string, -- "Loaf" | "Slim" | "Fluffy"
	fur: string,
	second: string, -- muzzle, chest, tail tip (and paws with "socks" / "tuxedo")
	pattern: string?, -- "solid" | "tabby" | "patches" | "socks" | "tuxedo" | "spots"
	patternColor: string?,
	patternColor2: string?,
	eyes: string?, -- eye colour (default near-black)
	accessory: string?, -- "bow" | "collar" | "scarf" | "hat" | "flowers" | "crown" | "wings" | "halo"
	accessoryColor: string?,
	aura: string?, -- "sparkle" | "gold" | "glow" | "rainbow"
}

type Shape = {
	w: number, -- body width
	h: number, -- body height
	d: number, -- body length
	leg: number, -- leg height
	head: number, -- head cube size
	tail: number, -- tail thickness
	cheeks: boolean,
}

local SHAPES: { [string]: Shape } = {
	Loaf = { w = 3.6, h = 2.8, d = 4.6, leg = 0.9, head = 3.4, tail = 0.7, cheeks = false },
	Slim = { w = 3.0, h = 2.5, d = 5.2, leg = 1.5, head = 3.0, tail = 0.6, cheeks = false },
	Fluffy = { w = 4.2, h = 3.2, d = 4.8, leg = 0.8, head = 3.6, tail = 1.2, cheeks = true },
}

local CatModel = {}

CatModel.Shapes = { "Loaf", "Slim", "Fluffy" }
CatModel.BaseScale = 0.8 -- a Basic cat is about 5.5 studs tall with its ears
CatModel.Tag = "Cat" -- CollectionService tag on every cat model (the client animates tagged cats)
CatModel.Bones = { "Body", "Head", "Tail1", "Tail2", "LegFL", "LegFR", "LegBL", "LegBR", "WingL", "WingR" }

local hex = Color3.fromHex
local PINK = hex("ff9fb8")
local INK = hex("2a2433")
local WHITE = Color3.new(1, 1, 1)
local GOLD = hex("ffcc33")

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

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, name: string?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	setup(p, color)
	p.Name = name or "Part"
	p.Parent = parent
	return p
end

local function wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	setup(p, color)
	p.Parent = parent
	return p
end

-- A triangle seen from the front (two wedges back to back), centred on cf, w wide, h high, t thick.
local function triangle(parent: Instance, cf: CFrame, w: number, h: number, t: number, color: Color3)
	wedge(parent, Vector3.new(t, h, w / 2), cf * CFrame.new(-w / 4, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), color)
	wedge(parent, Vector3.new(t, h, w / 2), cf * CFrame.new(w / 4, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), color)
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

function CatModel.build(look: Look, at: CFrame, size: number?): Model
	local s = SHAPES[look.shape] or SHAPES.Loaf
	local fur = hex(look.fur)
	local second = hex(look.second)
	local pattern = look.pattern or "solid"
	local pc = if look.patternColor then hex(look.patternColor) else fur:Lerp(INK, 0.35)
	local pc2 = if look.patternColor2 then hex(look.patternColor2) else pc
	local eyes = if look.eyes then hex(look.eyes) else INK
	local acc = if look.accessoryColor then hex(look.accessoryColor) else hex("ff5a6e")
	local accessory = look.accessory
	local hasWings = accessory == "wings" or look.aura == "rainbow"

	local m = Instance.new("Model")
	m.Name = "Cat"
	-- built at the origin, moved and scaled at the end
	local o = CFrame.new()
	local bodyY = s.leg + s.h / 2
	local hs = s.head
	local headY = s.leg + s.h + hs * 0.18
	local headZ = -s.d / 2 + hs * 0.2
	local front = headZ - hs / 2 -- z of the face
	local topY = headY + hs * 0.45
	local t = s.tail
	local tailBase = o * CFrame.new(0, s.leg + s.h * 0.75, s.d / 2 + 0.55)

	local root = part(m, Vector3.new(s.w, s.leg + s.h + hs * 0.7, s.d + hs * 0.4), o * CFrame.new(0, (s.leg + s.h + hs * 0.7) / 2, -hs * 0.2), WHITE, "Root")
	root.Transparency = 1
	root.CanQuery = true
	root.CastShadow = false
	m.PrimaryPart = root

	-- bones: name -> { model, joint cframe, parent bone }
	local bones: { [string]: Model } = {}
	local jointAt: { [string]: CFrame } = {}
	local parentOf: { [string]: string } = {}
	local function bone(name: string, cf: CFrame, parentName: string): Model
		local b = Instance.new("Model")
		b.Name = name
		b.Parent = m
		bones[name] = b
		jointAt[name] = cf
		parentOf[name] = parentName
		return b
	end
	local B = bone("Body", o * CFrame.new(0, bodyY, 0), "Root")
	local H = bone("Head", o * CFrame.new(0, s.leg + s.h - 0.3, headZ + hs * 0.3), "Body")
	local T1 = bone("Tail1", o * CFrame.new(0, s.leg + s.h * 0.75, s.d / 2 - 0.1), "Body")
	local T2 = bone("Tail2", tailBase * CFrame.new(0, 0.45, 0.5), "Tail1")

	-- body
	local body = part(B, Vector3.new(s.w, s.h, s.d), o * CFrame.new(0, bodyY, 0), fur, "Body")
	part(B, Vector3.new(s.w * 0.55, s.h * 0.5, 0.2), o * CFrame.new(0, s.leg + s.h * 0.35, -s.d / 2 - 0.05), second)

	-- legs (hips at the bottom of the body)
	local pawColor = if pattern == "socks" or pattern == "tuxedo" then second else fur
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local lx, lz = x * (s.w / 2 - 0.6), z * (s.d / 2 - 0.8)
			local name = "Leg" .. (if z < 0 then "F" else "B") .. (if x < 0 then "L" else "R")
			local L = bone(name, o * CFrame.new(lx, s.leg + 0.3, lz), "Body")
			part(L, Vector3.new(0.95, s.leg + 0.3, 0.95), o * CFrame.new(lx, (s.leg + 0.3) / 2, lz), fur)
			part(L, Vector3.new(1.05, 0.45, 1.15), o * CFrame.new(lx, 0.22, lz - 0.08), pawColor)
		end
	end

	-- tail in two pieces
	part(T1, Vector3.new(t, t, 1.6), tailBase * CFrame.Angles(math.rad(35), 0, 0), fur)
	part(T2, Vector3.new(t, 2.2, t), tailBase * CFrame.new(0, 1.35, 0.55) * CFrame.Angles(math.rad(-12), 0, 0), fur)
	part(T2, Vector3.new(t + 0.08, 0.8, t + 0.08), tailBase * CFrame.new(0, 2.55, 0.8) * CFrame.Angles(math.rad(-12), 0, 0), second)

	-- head and face
	local head = part(H, Vector3.new(hs, hs * 0.9, hs), o * CFrame.new(0, headY, headZ), fur, "Head")
	if s.cheeks then
		for _, x in { -1, 1 } do
			part(H, Vector3.new(0.7, hs * 0.45, hs * 0.6), o * CFrame.new(x * (hs / 2 + 0.25), headY - hs * 0.2, headZ - 0.1), second)
		end
	end
	for _, x in { -1, 1 } do
		local ear = o * CFrame.new(x * hs * 0.3, headY + hs * 0.45 + 0.55, headZ + 0.2)
		triangle(H, ear, hs * 0.36, 1.2, 0.6, fur)
		triangle(H, ear * CFrame.new(0, -0.15, -0.32), hs * 0.2, 0.75, 0.1, PINK)
	end
	part(H, Vector3.new(hs * 0.56, hs * 0.32, 0.25), o * CFrame.new(0, headY - hs * 0.24, front - 0.1), second)
	part(H, Vector3.new(0.5, 0.35, 0.2), o * CFrame.new(0, headY - hs * 0.13, front - 0.25), PINK)
	for _, x in { -1, 1 } do
		part(H, Vector3.new(0.38, 0.12, 0.1), o * CFrame.new(x * 0.18, headY - hs * 0.3, front - 0.24) * CFrame.Angles(0, 0, x * 0.5), INK) -- a smiling "w"
		local eye = o * CFrame.new(x * hs * 0.24, headY + hs * 0.06, front - 0.06)
		part(H, Vector3.new(hs * 0.2, hs * 0.26, 0.15), eye, eyes, "Eye")
		part(H, Vector3.new(hs * 0.08, hs * 0.08, 0.1), eye * CFrame.new(hs * 0.04, hs * 0.06, -0.06), WHITE)
		local blush = part(H, Vector3.new(hs * 0.16, hs * 0.08, 0.1), o * CFrame.new(x * hs * 0.37, headY - hs * 0.17, front - 0.06), PINK)
		blush.Transparency = 0.25
	end

	-- patterns
	if pattern == "tabby" then
		for _, z in { -0.25, 0.05, 0.35 } do
			part(B, Vector3.new(s.w + 0.1, s.h * 0.55, 0.42), o * CFrame.new(0, s.leg + s.h * 0.75 + 0.03, z * s.d), pc)
		end
		for _, x in { -0.28, 0, 0.28 } do
			part(H, Vector3.new(0.28, hs * 0.22, 0.1), o * CFrame.new(x * hs * 0.6, headY + hs * 0.33, front - 0.06), pc)
		end
	elseif pattern == "patches" then
		part(B, Vector3.new(s.w * 0.55, s.h * 0.55, s.d * 0.4), o * CFrame.new(-s.w * 0.24, s.leg + s.h * 0.75, s.d * 0.18), pc)
		part(B, Vector3.new(s.w * 0.45, s.h * 0.5, s.d * 0.32), o * CFrame.new(s.w * 0.29, s.leg + s.h * 0.77, -s.d * 0.12), pc2)
		part(H, Vector3.new(hs * 0.45, hs * 0.4, hs * 0.55), o * CFrame.new(hs * 0.29, headY + hs * 0.27, headZ + 0.05), pc)
	elseif pattern == "spots" then
		for _, p in { { -0.3, 0.25 }, { 0.25, -0.1 }, { 0.05, 0.38 }, { -0.15, -0.3 } } do
			part(B, Vector3.new(0.9, 0.2, 0.9), o * CFrame.new(p[1] * s.w, s.leg + s.h + 0.05, p[2] * s.d), pc)
		end
	elseif pattern == "tuxedo" then
		part(B, Vector3.new(s.w * 0.7, 0.2, s.d * 0.8), o * CFrame.new(0, s.leg - 0.05, 0), second)
	end

	-- accessories
	if accessory == "bow" then
		local bow = o * CFrame.new(-hs * 0.3, topY + 0.2, headZ - 0.3)
		part(H, Vector3.new(0.9, 0.8, 0.4), bow * CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, 0, 0.3), acc)
		part(H, Vector3.new(0.9, 0.8, 0.4), bow * CFrame.new(0.5, 0, 0) * CFrame.Angles(0, 0, -0.3), acc)
		part(H, Vector3.new(0.4, 0.4, 0.45), bow, acc:Lerp(WHITE, 0.3))
	elseif accessory == "collar" or accessory == "scarf" then
		local neck = o * CFrame.new(0, s.leg + s.h - 0.15, headZ + hs * 0.25)
		part(H, Vector3.new(hs * 0.9, 0.45, hs * 0.65), neck, acc)
		if accessory == "collar" then
			local bell = part(H, Vector3.new(0.55, 0.55, 0.55), neck * CFrame.new(0, -0.35, -hs * 0.33), GOLD)
			bell.Shape = Enum.PartType.Ball
		else
			part(H, Vector3.new(0.7, 1.4, 0.3), neck * CFrame.new(hs * 0.25, -0.75, -hs * 0.34) * CFrame.Angles(0, 0, 0.2), acc)
		end
	elseif accessory == "hat" then
		part(H, Vector3.new(hs * 0.65, 0.22, hs * 0.65), o * CFrame.new(0, topY + 0.1, headZ), INK)
		part(H, Vector3.new(hs * 0.4, 1.1, hs * 0.4), o * CFrame.new(0, topY + 0.75, headZ), INK)
		part(H, Vector3.new(hs * 0.42, 0.25, hs * 0.42), o * CFrame.new(0, topY + 0.45, headZ), acc)
	elseif accessory == "flowers" then
		for i = 0, 4 do
			local a = math.rad(-70 + i * 35)
			local f = part(H, Vector3.new(0.6, 0.6, 0.6), o * CFrame.new(math.sin(a) * hs * 0.45, topY + 0.1, headZ - math.cos(a) * hs * 0.3), if i % 2 == 0 then acc else hex("ffe066"))
			f.Shape = Enum.PartType.Ball
		end
	elseif accessory == "crown" then
		local c = o * CFrame.new(0, topY + 0.25, headZ)
		part(H, Vector3.new(hs * 0.5, 0.35, hs * 0.5), c, GOLD)
		for _, p in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			part(H, Vector3.new(0.3, 0.7, 0.3), c * CFrame.new(p[1] * hs * 0.21, 0.45, p[2] * hs * 0.21), GOLD)
		end
		part(H, Vector3.new(0.35, 0.35, 0.1), c * CFrame.new(0, 0.05, -hs * 0.26), hex("ff4d6d"))
	end
	if hasWings then
		local wingColor = if accessory == "wings" then acc else WHITE
		for _, x in { -1, 1 } do
			local rootCf = o * CFrame.new(x * (s.w / 2 + 0.1), s.leg + s.h * 0.9, -0.2)
			local Wb = bone(if x < 0 then "WingL" else "WingR", rootCf, "Body")
			local w = rootCf * CFrame.new(x * 0.1, 0, 0) * CFrame.Angles(0, 0, x * -0.5)
			wedge(Wb, Vector3.new(0.25, 1.8, 2.6), w * CFrame.new(x * 0.7, 0.6, 0) * CFrame.Angles(0, math.pi, 0), wingColor)
			part(Wb, Vector3.new(0.25, 0.7, 2.6), w * CFrame.new(x * 0.7, -0.6, 0), wingColor)
		end
	end
	if accessory == "halo" or look.aura == "rainbow" then
		local ringY = topY + 1.6
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			local seg = part(H, Vector3.new(0.75, 0.2, 0.3), o * CFrame.new(math.cos(a) * hs * 0.36, ringY, headZ + math.sin(a) * hs * 0.36) * CFrame.Angles(0, -a + math.pi / 2, 0), GOLD)
			seg.Material = Enum.Material.Neon
		end
	end

	-- tier effects
	local aura = look.aura
	if aura == "sparkle" then
		sparkles(body, { hex("c49bff"), WHITE }, 4, 0.35)
	elseif aura == "gold" then
		sparkles(body, { GOLD, hex("fff2a8") }, 7, 0.45)
	elseif aura == "glow" then
		sparkles(body, { hex("ff7ad9"), hex("9a6bff") }, 12, 0.6)
		local l = Instance.new("PointLight")
		l.Color = hex("ff9ae6")
		l.Range = 10
		l.Brightness = 1
		l.Parent = head
	elseif aura == "rainbow" then
		sparkles(body, { hex("ff5a5a"), hex("ffd23f"), hex("5ad67a"), hex("4fb6ff"), hex("b06bff") }, 18, 0.7)
		local l = Instance.new("PointLight")
		l.Color = WHITE
		l.Range = 14
		l.Brightness = 1.2
		l.Parent = head
	end

	-- join the rig: a Joint part per bone, every bone part welded to it, a Motor6D to the parent bone
	local joints: { [string]: BasePart } = { Root = root }
	for name, b in bones do
		local j = part(b, Vector3.new(0.2, 0.2, 0.2), jointAt[name], WHITE, "Joint")
		j.Transparency = 1
		j.CastShadow = false
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
		j.Anchored = false
	end
	for _, name in CatModel.Bones do
		local j = joints[name]
		if j then
			local parentJoint = joints[parentOf[name]]
			local motor = Instance.new("Motor6D")
			motor.Name = name
			motor.Part0 = parentJoint
			motor.Part1 = j
			motor.C0 = parentJoint.CFrame:Inverse() * j.CFrame
			motor.C1 = CFrame.new()
			motor.Parent = j
		end
	end

	-- pivot at the feet, in the middle under the body
	root.PivotOffset = root.CFrame:Inverse()
	m:ScaleTo(CatModel.BaseScale * (size or 1))
	m:PivotTo(at)
	local motorCount = 0
	for _, d in m:GetDescendants() do
		if d:IsA("Motor6D") then
			motorCount += 1
		end
	end
	m:SetAttribute("Bones", motorCount) -- the client waits until this many joints have streamed in
	m:SetAttribute("Anim", "idle")
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- a cat streams in and out whole
	CollectionService:AddTag(m, CatModel.Tag)
	return m
end

return CatModel
