--!strict
-- Building blocks for the map builder (style A "glossy blocks", docs/art_direction.md).
-- Every prop is made of anchored Parts at a ground CFrame (y = ground top, LookVector = the prop's
-- front) and returns the hiding spots it offers as { kind, pos } (kind: "roof" | "bush" | "rock" | "bridge").
-- Edit-time only: lives in ServerScriptService.Server.MapTools (never required by the running game);
-- run from the Command Bar / Studio MCP through BuildMap.

local Kit = {}

export type Spot = { kind: string, pos: Vector3 }
export type Opts = {
	mat: Enum.Material?,
	shape: Enum.PartType?,
	decor: boolean?, -- no collision, no queries (small decoration)
	t: number?, -- transparency
	name: string?,
	shadow: boolean?, -- false = no shadow
	refl: number?,
}

local hex = Color3.fromHex
local C = {
	Grass1 = hex("86dc5e"),
	Grass2 = hex("69c94c"),
	PenGrass = hex("9be56f"),
	Leaf = hex("4fbf3f"),
	Leaf2 = hex("78d957"),
	LeafDark = hex("3c9e38"),
	Trunk = hex("8a5a33"),
	Wood = hex("dc9e55"),
	WoodDark = hex("a8693a"),
	Cream = hex("fff3da"),
	White = hex("ffffff"),
	Stone = hex("d3d6df"),
	Stone2 = hex("b8bdcb"),
	Rock = hex("a9aebb"),
	RockDark = hex("8c91a0"),
	Moss = hex("8fd34c"),
	Water = hex("49bdfb"),
	WaterLight = hex("a6e9ff"),
	Red = hex("ef4b42"),
	RedDark = hex("c43a33"),
	Brick = hex("d9614b"),
	Yellow = hex("ffd23f"),
	Gold = hex("f5bf2e"),
	Blue = hex("3e8ef2"),
	Purple = hex("9a6bff"),
	Pink = hex("ff8fca"),
	PinkLight = hex("ffc3e4"),
	Orange = hex("ff9a3c"),
	Teal = hex("2fc7c0"),
	Navy = hex("2f3552"),
	Black = hex("2a2a36"),
	Snow = hex("f7fbff"),
	SnowShade = hex("dcecfa"),
	Ice = hex("62d2ff"),
	Window = hex("8fd6ff"),
	Lamp = hex("ffd773"),
}
Kit.Colors = C

Kit.RoofColors = { C.Red, C.Yellow, C.Purple, C.Blue, C.Orange, C.Teal, C.Pink, hex("6ccf4a") }
Kit.FlowerColors = { C.Pink, C.Yellow, hex("b58cff"), hex("ff6f8a"), C.White, C.Orange }
Kit.FruitColors = { C.Red, C.Yellow, C.Purple, C.Orange, hex("7bd04a") }

-- Created-part counter: the builder yields every so often so Studio stays responsive.
Kit.created = 0
local YIELD_EVERY = 400

local function bump()
	Kit.created += 1
	if Kit.created % YIELD_EVERY == 0 then
		task.wait()
	end
end

local function style(p: BasePart, color: Color3, o: Opts?)
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	if o then
		if o.mat then
			p.Material = o.mat
		end
		if o.decor then
			p.CanCollide = false
			p.CanQuery = false
		end
		if o.t then
			p.Transparency = o.t
		end
		if o.name then
			p.Name = o.name
		end
		if o.shadow == false then
			p.CastShadow = false
		end
		if o.refl then
			p.Reflectance = o.refl
		end
	end
end

function Kit.part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, o: Opts?): Part
	local p = Instance.new("Part")
	if o and o.shape then
		p.Shape = o.shape
	end
	p.Size = size
	p.CFrame = cf
	style(p, color, o)
	p.Parent = parent
	bump()
	return p
end
local P = Kit.part

-- Wedge: full height at +Z, thin edge at -Z (checked in Studio).
function Kit.wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, o: Opts?): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	style(p, color, o)
	p.Parent = parent
	bump()
	return p
end
local W = Kit.wedge

function Kit.ball(parent: Instance, d: number, pos: Vector3, color: Color3, o: Opts?): Part
	local opts: Opts = o or {}
	opts.shape = Enum.PartType.Ball
	return P(parent, Vector3.new(d, d, d), CFrame.new(pos), color, opts)
end
local B = Kit.ball

-- A flat disc (cylinder standing up). cf = the disc's centre.
function Kit.disc(parent: Instance, cf: CFrame, d: number, h: number, color: Color3, o: Opts?): Part
	local opts: Opts = o or {}
	opts.shape = Enum.PartType.Cylinder
	return P(parent, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), color, opts)
end
local D = Kit.disc

-- A vertical round post from its foot.
function Kit.pole(parent: Instance, foot: CFrame, d: number, h: number, color: Color3, o: Opts?): Part
	return D(parent, foot * CFrame.new(0, h / 2, 0), d, h, color, o)
end
local pole = Kit.pole

function Kit.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local M = Kit.model

local function pick<T>(rng: Random, list: { T }): T
	return list[rng:NextInteger(1, #list)]
end
Kit.pick = pick

-- Gable roof, ridge along local X. cf = centre of the roof's base (top of the walls).
function Kit.gable(parent: Instance, cf: CFrame, w: number, d: number, h: number, color: Color3, o: Opts?)
	local half = d / 2
	W(parent, Vector3.new(w, h, half), cf * CFrame.new(0, h / 2, -half / 2), color, o)
	W(parent, Vector3.new(w, h, half), cf * CFrame.new(0, h / 2, half / 2) * CFrame.Angles(0, math.pi, 0), color, o)
end
local gable = Kit.gable

local function at(cf: CFrame, x: number, y: number, z: number): CFrame
	return cf * CFrame.new(x, y, z)
end

----------------------------------------------------------------------------------------------------
-- Plants and rocks

function Kit.tree(parent: Instance, cf: CFrame, rng: Random, leaf: Color3?, leaf2: Color3?): Model
	local m = M(parent, "Tree")
	local h = rng:NextInteger(7, 10)
	local a = leaf or C.Leaf
	local b = leaf2 or C.Leaf2
	P(m, Vector3.new(3, h, 3), at(cf, 0, h / 2, 0), C.Trunk)
	P(m, Vector3.new(11, 7, 11), at(cf, 0, h + 3, 0), a)
	P(m, Vector3.new(7, 5, 7), at(cf, rng:NextNumber(-1, 1), h + 8.5, rng:NextNumber(-1, 1)), b)
	for _ = 1, 2 do
		local sx = if rng:NextNumber() < 0.5 then -1 else 1
		local sz = if rng:NextNumber() < 0.5 then -1 else 1
		P(m, Vector3.new(6, 5, 6), at(cf, 5 * sx, h + 1.5, 4 * sz), b, { decor = true })
	end
	return m
end

function Kit.blossom(parent: Instance, cf: CFrame, rng: Random): Model
	local m = Kit.tree(parent, cf, rng, C.Pink, C.PinkLight)
	m.Name = "BlossomTree"
	if rng:NextNumber() < 0.35 then
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(C.PinkLight)
		e.Size = NumberSequence.new(0.35)
		e.Rate = 2
		e.Lifetime = NumberRange.new(5, 7)
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(60, 60)
		e.Acceleration = Vector3.new(0.6, -1.2, 0)
		e.LightEmission = 0.2
		local first = m:FindFirstChildWhichIsA("BasePart")
		if first then
			e.Parent = m:GetChildren()[2]
		end
	end
	return m
end

function Kit.pine(parent: Instance, cf: CFrame, rng: Random, snowy: boolean): Model
	local m = M(parent, "Pine")
	local s = rng:NextNumber(0.85, 1.2)
	P(m, Vector3.new(2, 4, 2) * s, at(cf, 0, 2 * s, 0), C.Trunk)
	local tiers = { { 13, 4.5, 6 }, { 10, 4, 10 }, { 6.5, 3.5, 13.5 } }
	for _, t in tiers do
		P(m, Vector3.new(t[1], t[2], t[1]) * s, at(cf, 0, t[3] * s, 0), C.LeafDark)
		if snowy then
			P(m, Vector3.new(t[1] - 1, 0.8, t[1] - 1) * s, at(cf, 0, (t[3] + t[2] / 2 + 0.3) * s, 0), C.Snow, { decor = true })
		end
	end
	return m
end

function Kit.bush(parent: Instance, cf: CFrame, rng: Random, color: Color3?, extra: string?): (Model, Spot)
	local m = M(parent, "Bush")
	local c = color or C.Leaf
	B(m, 7.5, at(cf, 0, 3, 0).Position, c)
	for i = 1, 4 do
		local a = i * math.pi / 2 + rng:NextNumber(-0.3, 0.3)
		B(m, rng:NextNumber(4.5, 6), at(cf, math.cos(a) * 3.4, 2.3, math.sin(a) * 3.4).Position, if i % 2 == 0 then c else C.Leaf2)
	end
	if extra == "snow" then
		B(m, 5.5, at(cf, 0, 5.2, 0).Position, C.Snow, { decor = true })
	end
	for i = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local color2 = if extra == "berries" then C.Red else pick(rng, Kit.FlowerColors)
		B(m, 1.2, at(cf, math.cos(a) * 3.9, rng:NextNumber(2.5, 5), math.sin(a) * 3.9).Position, color2, { decor = true })
		local _ = i
	end
	return m, { kind = "bush", pos = at(cf, 0, 1.5, 0).Position }
end

function Kit.rock(parent: Instance, cf: CFrame, rng: Random, cap: string?): (Model, Spot)
	local m = M(parent, "Rock")
	local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	local base = cf * yaw
	local s = rng:NextNumber(0.9, 1.3)
	P(m, Vector3.new(8, 5.5, 6.5) * s, base * CFrame.new(0, 2.6 * s, 0) * CFrame.Angles(0.08, 0, 0.1), C.Rock)
	P(m, Vector3.new(4.5, 3.5, 4.5) * s, base * CFrame.new(3.5 * s, 1.6 * s, 2 * s) * CFrame.Angles(0, 0.6, -0.12), C.RockDark)
	if cap == "moss" then
		P(m, Vector3.new(7, 0.8, 5.5) * s, base * CFrame.new(0, 5.6 * s, 0) * CFrame.Angles(0.08, 0, 0.1), C.Moss, { decor = true })
	elseif cap == "snow" then
		P(m, Vector3.new(7.4, 1, 5.8) * s, base * CFrame.new(0, 5.7 * s, 0) * CFrame.Angles(0.08, 0, 0.1), C.Snow, { decor = true })
	end
	return m, { kind = "rock", pos = (cf * CFrame.new(0, 1, 6 * s)).Position }
end

function Kit.flowers(parent: Instance, cf: CFrame, rng: Random, n: number?)
	local m = M(parent, "Flowers")
	P(m, Vector3.new(6.5, 0.5, 6.5), at(cf, 0, 0.25, 0) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), C.Leaf2, { decor = true, shadow = false })
	for _ = 1, math.min(n or 5, 5) do
		local x, z = rng:NextNumber(-2.6, 2.6), rng:NextNumber(-2.6, 2.6)
		B(m, 1.3, at(cf, x, 0.9, z).Position, pick(rng, Kit.FlowerColors), { decor = true, shadow = false })
	end
end

function Kit.bamboo(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Bamboo")
	for _ = 1, rng:NextInteger(4, 5) do
		local x, z = rng:NextNumber(-4, 4), rng:NextNumber(-4, 4)
		local h = rng:NextNumber(14, 21)
		local foot = at(cf, x, 0, z)
		pole(m, foot, 1.2, h, hex("67c94a"))
		pole(m, foot * CFrame.new(0, h * 0.55, 0), 1.45, 0.5, hex("4f9f3a"), { decor = true })
		P(m, Vector3.new(3.6, 1.6, 3.6), foot * CFrame.new(0, h, 0) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), C.Leaf2, { decor = true })
	end
end

function Kit.crystals(parent: Instance, cf: CFrame, rng: Random, color: Color3, big: boolean?): (Model, Spot)
	local m = M(parent, "Crystals")
	local s = if big then 2.2 else 1
	if big then
		P(m, Vector3.new(9, 2.5, 8), at(cf, 0, 1.25, 0), C.Rock)
	end
	for i = 1, rng:NextInteger(3, 4) do
		local h = rng:NextNumber(4, 8) * s
		local w = rng:NextNumber(1.4, 2.2) * s
		local x, z = rng:NextNumber(-2.5, 2.5) * s, rng:NextNumber(-2, 2) * s
		local tilt = CFrame.Angles(rng:NextNumber(-0.35, 0.35), math.rad(45), rng:NextNumber(-0.35, 0.35))
		local foot = at(cf, x, if big then 1.5 else 0, z) * tilt
		P(m, Vector3.new(w, h, w), foot * CFrame.new(0, h / 2, 0), color, { mat = Enum.Material.Neon, t = 0.12 })
		-- pointed tip: a block turned 45 degrees on its edge
		P(m, Vector3.new(w * 0.72, w * 0.72, w), foot * CFrame.new(0, h, 0) * CFrame.Angles(0, 0, math.rad(45)), color, { mat = Enum.Material.Neon, t = 0.12, decor = true })
		local _ = i
	end
	return m, { kind = "rock", pos = (cf * CFrame.new(0, 1, 5 * s)).Position }
end

----------------------------------------------------------------------------------------------------
-- Small props

function Kit.fence(parent: Instance, a: Vector3, b: Vector3, color: Color3?)
	local m = M(parent, "Fence")
	local c = color or C.Wood
	local len = (b - a).Magnitude
	local dir = CFrame.lookAt(a, b)
	local n = math.max(1, math.floor(len / 3.5))
	for i = 0, n do
		local cfp = dir * CFrame.new(0, 2, -len * i / n)
		P(m, Vector3.new(1, 4, 1), cfp, c)
		P(m, Vector3.new(1.3, 0.5, 1.3), cfp * CFrame.new(0, 2.25, 0), C.White, { decor = true })
	end
	for _, y in { 1.4, 2.9 } do
		P(m, Vector3.new(0.4, 0.6, len), dir * CFrame.new(0, y, -len / 2), c)
	end
end

function Kit.lamp(parent: Instance, cf: CFrame, light: boolean?)
	local m = M(parent, "Lamp")
	pole(m, cf, 0.8, 9, C.WoodDark)
	P(m, Vector3.new(0.5, 0.5, 2.6), at(cf, 0, 8.6, -1.2), C.WoodDark, { decor = true })
	local l = P(m, Vector3.new(1.8, 2.2, 1.8), at(cf, 0, 7.2, -2.3), C.Lamp, { mat = Enum.Material.Neon, decor = true })
	P(m, Vector3.new(2.3, 0.5, 2.3), at(cf, 0, 8.5, -2.3), C.Navy, { decor = true })
	if light then
		local pl = Instance.new("PointLight")
		pl.Range = 16
		pl.Brightness = 1.2
		pl.Color = C.Lamp
		pl.Parent = l
	end
end

function Kit.crate(parent: Instance, cf: CFrame, rng: Random, fruit: Color3?)
	P(parent, Vector3.new(2.6, 1.6, 2.2), at(cf, 0, 0.8, 0), C.Wood)
	local c = fruit or pick(rng, Kit.FruitColors)
	for i = -1, 1 do
		B(parent, 1, at(cf, i * 0.8, 1.9, rng:NextNumber(-0.4, 0.4)).Position, c, { decor = true })
	end
end

function Kit.barrel(parent: Instance, cf: CFrame)
	pole(parent, cf, 2.6, 3.2, C.WoodDark)
	pole(parent, cf * CFrame.new(0, 0.6, 0), 2.75, 0.3, C.Navy, { decor = true })
	pole(parent, cf * CFrame.new(0, 2.3, 0), 2.75, 0.3, C.Navy, { decor = true })
end

function Kit.bench(parent: Instance, cf: CFrame)
	local m = M(parent, "Bench")
	P(m, Vector3.new(7, 0.6, 2.2), at(cf, 0, 1.8, 0), C.Wood)
	P(m, Vector3.new(7, 1.6, 0.5), at(cf, 0, 2.9, 1), C.Wood)
	for _, x in { -3, 3 } do
		P(m, Vector3.new(0.6, 1.8, 2), at(cf, x, 0.9, 0), C.Navy)
	end
end

function Kit.snowman(parent: Instance, cf: CFrame)
	local m = M(parent, "Snowman")
	B(m, 5, at(cf, 0, 2.4, 0).Position, C.Snow)
	B(m, 3.8, at(cf, 0, 6, 0).Position, C.Snow)
	B(m, 2.8, at(cf, 0, 8.7, 0).Position, C.Snow)
	pole(m, at(cf, 0, 9.8, 0), 2.4, 0.4, C.Navy)
	pole(m, at(cf, 0, 10.1, 0), 1.8, 1.6, C.Blue)
	B(m, 0.8, at(cf, 0, 11.9, 0).Position, C.White, { decor = true })
	pole(m, at(cf, 0, 7.4, 0), 3.4, 0.7, C.Red, { decor = true })
	P(m, Vector3.new(0.5, 0.5, 1.4), at(cf, 0, 8.7, -1.8), C.Orange, { decor = true })
	for _, x in { -0.55, 0.55 } do
		B(m, 0.4, at(cf, x, 9.2, -1.25).Position, C.Black, { decor = true })
	end
	for _, x in { -1, 1 } do
		P(m, Vector3.new(3, 0.3, 0.3), at(cf, x * 3, 6.6, 0) * CFrame.Angles(0, 0, x * 0.5), C.Trunk, { decor = true })
	end
end

function Kit.stoneLantern(parent: Instance, cf: CFrame)
	local m = M(parent, "StoneLantern")
	P(m, Vector3.new(2.6, 0.8, 2.6), at(cf, 0, 0.4, 0), C.Stone2)
	P(m, Vector3.new(1.2, 2.6, 1.2), at(cf, 0, 2.1, 0), C.Stone)
	P(m, Vector3.new(2.4, 2, 2.4), at(cf, 0, 4.4, 0), C.Stone)
	P(m, Vector3.new(1.7, 1.3, 2.5), at(cf, 0, 4.4, 0), C.Lamp, { mat = Enum.Material.Neon, decor = true })
	P(m, Vector3.new(3.4, 0.8, 3.4), at(cf, 0, 5.8, 0), C.Stone2)
	P(m, Vector3.new(1, 0.8, 1), at(cf, 0, 6.6, 0), C.Stone2, { decor = true })
end

function Kit.torii(parent: Instance, cf: CFrame): Model
	local m = M(parent, "RedGate")
	for _, x in { -5.5, 5.5 } do
		pole(m, at(cf, x, 0, 0), 1.7, 13, C.Red)
		pole(m, at(cf, x, 0, 0), 2.3, 1.2, C.Black, { decor = true })
	end
	P(m, Vector3.new(15, 1, 1.4), at(cf, 0, 10.8, 0), C.Red)
	P(m, Vector3.new(18, 1.3, 2.2), at(cf, 0, 13.4, 0), C.Black)
	P(m, Vector3.new(17, 0.9, 1.8), at(cf, 0, 12.4, 0), C.Red)
	for _, x in { -1, 1 } do
		W(m, Vector3.new(2.2, 0.9, 1.6), at(cf, x * 9.6, 14.2, 0) * CFrame.Angles(0, x * math.pi / 2, 0), C.Black, { decor = true })
	end
	P(m, Vector3.new(1.2, 2, 0.8), at(cf, 0, 11.7, 0), C.Black, { decor = true })
	return m
end

----------------------------------------------------------------------------------------------------
-- Buildings (each returns its roof spot)

function Kit.house(parent: Instance, cf: CFrame, rng: Random, roof: Color3?): (Model, Spot)
	local m = M(parent, "House")
	local w, d, h = 18, 14, 10
	local rc = roof or pick(rng, Kit.RoofColors)
	P(m, Vector3.new(w, h, d), at(cf, 0, h / 2, 0), C.Cream)
	P(m, Vector3.new(w + 0.4, 0.8, d + 0.4), at(cf, 0, 0.4, 0), C.Stone2, { decor = true })
	gable(m, at(cf, 0, h, 0), w + 3, d + 3, 7, rc)
	P(m, Vector3.new(2.6, 5, 2.6), at(cf, w / 4, h + 5, 2.5), C.Brick)
	P(m, Vector3.new(3, 0.6, 3), at(cf, w / 4, h + 7.7, 2.5), C.Stone, { decor = true })
	P(m, Vector3.new(4, 7, 0.5), at(cf, -2, 3.5, -d / 2 - 0.2), C.WoodDark)
	P(m, Vector3.new(4.8, 0.6, 1.4), at(cf, -2, 7.4, -d / 2 - 0.6), rc, { decor = true })
	for _, x in { 4.5 } do
		P(m, Vector3.new(4, 3.6, 0.4), at(cf, x, 5.8, -d / 2 - 0.2), C.Window, { refl = 0.15 })
		P(m, Vector3.new(4.6, 0.5, 0.6), at(cf, x, 3.8, -d / 2 - 0.3), C.WoodDark, { decor = true })
		P(m, Vector3.new(4.4, 1, 1.4), at(cf, x, 3.3, -d / 2 - 0.9), C.WoodDark, { decor = true })
		for i = -1, 1 do
			B(m, 1, at(cf, x + i * 1.3, 4.1, -d / 2 - 0.9).Position, pick(rng, Kit.FlowerColors), { decor = true, shadow = false })
		end
	end
	P(m, Vector3.new(0.9, 1.2, 0.9), at(cf, -4.7, 6.2, -d / 2 - 0.6), C.Lamp, { mat = Enum.Material.Neon, decor = true })
	P(m, Vector3.new(3.4, 3, 0.4), at(cf, -w / 2 - 0.2, 6, 0) * CFrame.Angles(0, math.pi / 2, 0), C.Window, { refl = 0.15 })
	return m, { kind = "roof", pos = at(cf, -w / 4, h + 7.6, 0).Position }
end

function Kit.shop(parent: Instance, cf: CFrame, rng: Random, color: Color3?): (Model, Spot)
	local m = M(parent, "Shop")
	local w, d, h = 16, 12, 12
	local c = color or pick(rng, Kit.RoofColors)
	P(m, Vector3.new(w, h, d), at(cf, 0, h / 2, 0), C.Cream)
	P(m, Vector3.new(w + 1, 1, d + 1), at(cf, 0, h + 0.5, 0), c)
	P(m, Vector3.new(w + 1, 1.2, 0.8), at(cf, 0, h + 1.6, -d / 2), c, { decor = true })
	P(m, Vector3.new(w + 1, 1.2, 0.8), at(cf, 0, h + 1.6, d / 2), c, { decor = true })
	P(m, Vector3.new(3, 4, 3), at(cf, -w / 4, h + 3, 2), C.Brick)
	P(m, Vector3.new(4, 6.5, 0.5), at(cf, -3, 3.25, -d / 2 - 0.2), C.WoodDark)
	P(m, Vector3.new(5, 3.4, 0.4), at(cf, 3.5, 4.5, -d / 2 - 0.2), C.Window, { refl = 0.15 })
	P(m, Vector3.new(3.2, 2.6, 0.4), at(cf, -3, 9, -d / 2 - 0.2), C.Window, { refl = 0.15 })
	P(m, Vector3.new(3.2, 2.6, 0.4), at(cf, 3.5, 9, -d / 2 - 0.2), C.Window, { refl = 0.15 })
	-- striped awning over the front
	for i = 0, 5 do
		local stripe = if i % 2 == 0 then c else C.White
		P(m, Vector3.new(w / 6, 0.4, 3.4), at(cf, -w / 2 + w / 12 + i * w / 6, 6.8, -d / 2 - 1.6) * CFrame.Angles(-0.35, 0, 0), stripe, { decor = true })
	end
	return m, { kind = "roof", pos = at(cf, 2, h + 1.6, 0).Position }
end

function Kit.stall(parent: Instance, cf: CFrame, rng: Random, color: Color3?)
	local m = M(parent, "Stall")
	local c = color or pick(rng, Kit.RoofColors)
	P(m, Vector3.new(10, 3, 4), at(cf, 0, 1.5, 0), C.Wood)
	P(m, Vector3.new(10.4, 0.4, 4.4), at(cf, 0, 3.1, 0), C.WoodDark, { decor = true })
	for _, x in { -4.7, 4.7 } do
		for _, z in { -1.8, 1.8 } do
			P(m, Vector3.new(0.6, 8.5, 0.6), at(cf, x, 4.25, z), C.WoodDark)
		end
	end
	for i = 0, 5 do
		local stripe = if i % 2 == 0 then c else C.White
		P(m, Vector3.new(11 / 6, 0.4, 6.5), at(cf, -5.5 + 11 / 12 + i * 11 / 6, 8.6, -0.6) * CFrame.Angles(-0.25, 0, 0), stripe)
	end
	for i = -1, 1 do
		Kit.crate(m, at(cf, i * 3, 3.3, -0.6), rng)
	end
	if rng:NextNumber() < 0.5 then
		-- fish on ice
		for i = -1, 1 do
			P(m, Vector3.new(0.6, 0.6, 1.8), at(cf, i * 1.2 + 1, 3.6, 1.2), C.Blue, { decor = true })
		end
	end
end

function Kit.pavilion(parent: Instance, cf: CFrame, post: Color3, roof: Color3, trim: Color3, floor: Color3): (Model, Spot)
	local m = M(parent, "Pavilion")
	local w, d = 16, 13
	P(m, Vector3.new(w, 2, d), at(cf, 0, 1, 0), floor)
	P(m, Vector3.new(6, 1, 3), at(cf, 0, 0.5, -d / 2 - 1.5), C.Stone)
	for _, x in { -w / 2 + 1, w / 2 - 1 } do
		for _, z in { -d / 2 + 1, d / 2 - 1 } do
			P(m, Vector3.new(1.3, 9, 1.3), at(cf, x, 6.5, z), post)
		end
	end
	P(m, Vector3.new(w, 1, d), at(cf, 0, 11.5, 0), trim)
	gable(m, at(cf, 0, 12, 0), w + 4, d + 4, 5.5, roof)
	for _, x in { -1, 1 } do
		P(m, Vector3.new(1.4, 1.4, 1.4), at(cf, x * (w / 2 + 1.6), 17, 0), trim, { decor = true })
		P(m, Vector3.new(1.4, 2, 1.4), at(cf, x * (w / 2 - 1), 9.6, -d / 2 - 0.2), C.Lamp, { mat = Enum.Material.Neon, decor = true })
	end
	P(m, Vector3.new(w + 4, 0.8, 0.8), at(cf, 0, 17.4, 0), trim, { decor = true })
	-- rails
	for _, x in { -1, 1 } do
		P(m, Vector3.new(0.5, 0.8, d - 2), at(cf, x * (w / 2 - 1), 3.6, 0), post, { decor = true })
	end
	return m, { kind = "roof", pos = at(cf, w / 4, 17.9, 0).Position }
end

function Kit.cabin(parent: Instance, cf: CFrame, rng: Random): (Model, Spot)
	local m = M(parent, "Cabin")
	local w, d, h = 16, 12, 9
	P(m, Vector3.new(w, h, d), at(cf, 0, h / 2, 0), C.Wood)
	for y = 1.5, h - 1, 2 do
		P(m, Vector3.new(w + 0.3, 0.4, d + 0.3), at(cf, 0, y, 0), C.WoodDark, { decor = true })
	end
	gable(m, at(cf, 0, h, 0), w + 3, d + 3, 6, C.Blue)
	gable(m, at(cf, 0, h + 0.9, 0), w + 3.4, d + 3.4, 6, C.Snow)
	P(m, Vector3.new(2.6, 6, 2.6), at(cf, w / 4, h + 5, 2.5), C.Brick)
	P(m, Vector3.new(3.2, 1, 3.2), at(cf, w / 4, h + 8.3, 2.5), C.Snow, { decor = true })
	P(m, Vector3.new(4, 6.5, 0.5), at(cf, -2.5, 3.25, -d / 2 - 0.2), C.WoodDark)
	P(m, Vector3.new(3.6, 3, 0.4), at(cf, 3.8, 5, -d / 2 - 0.2), C.Lamp, { mat = Enum.Material.Neon })
	P(m, Vector3.new(4.2, 0.6, 0.8), at(cf, 3.8, 3.2, -d / 2 - 0.4), C.Snow, { decor = true })
	P(m, Vector3.new(6, 1, 3), at(cf, -2.5, 0.5, -d / 2 - 1.5), C.Stone)
	-- log pile
	for i = 0, 2 do
		pole(m, at(cf, w / 2 + 2, 0.8 + i * 1.2, -2) * CFrame.Angles(math.pi / 2, 0, 0), 1.2, 4, C.Trunk, { decor = true })
		local _ = rng
	end
	return m, { kind = "roof", pos = at(cf, -w / 4, h + 7.7, 0).Position }
end

function Kit.doghouse(parent: Instance, cf: CFrame)
	local m = M(parent, "Doghouse")
	P(m, Vector3.new(5, 4, 5), at(cf, 0, 2, 0), C.White)
	gable(m, at(cf, 0, 4, 0), 6, 6, 2.6, C.Blue)
	P(m, Vector3.new(2.2, 2.6, 0.3), at(cf, 0, 1.3, -2.55), C.Black, { decor = true })
	D(m, at(cf, 0, 0.3, -4.5), 1.8, 0.6, C.Red, { decor = true })
end

function Kit.clothesline(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Clothesline")
	for _, x in { -6, 6 } do
		P(m, Vector3.new(0.6, 7, 0.6), at(cf, x, 3.5, 0), C.Wood)
	end
	P(m, Vector3.new(12, 0.15, 0.15), at(cf, 0, 6.6, 0), C.White, { decor = true })
	for i = -1, 1 do
		P(m, Vector3.new(2.6, 3, 0.2), at(cf, i * 3.6, 5, 0), pick(rng, { C.Yellow, C.Blue, C.Pink, C.White }), { decor = true })
	end
end

----------------------------------------------------------------------------------------------------
-- Water, bridges, cliffs

-- A short stream along local X with an arched bridge across it (along Z). style: "wood" | "stone" | "red".
function Kit.creek(parent: Instance, cf: CFrame, rng: Random, styleName: string, frozen: boolean?): (Model, Spot)
	local m = M(parent, "Creek")
	local water = if frozen then C.Ice else C.Water
	P(m, Vector3.new(56, 0.3, 12), at(cf, 0, 0.16, 0), water, { decor = true, refl = 0.12, t = if frozen then 0.05 else 0.08, shadow = false })
	for _, x in { -1, 1 } do
		D(m, at(cf, x * 28, 0.16, 0), 12, 0.3, water, { decor = true, shadow = false })
	end
	for i = 1, 6 do
		local x = rng:NextNumber(-30, 30)
		local z = if i % 2 == 0 then 7 else -7
		P(m, Vector3.new(rng:NextNumber(2, 3.5), rng:NextNumber(1, 2), rng:NextNumber(2, 3)), at(cf, x, 0.6, z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), C.Rock, { decor = true })
	end
	if not frozen then
		for _ = 1, 3 do
			D(m, at(cf, rng:NextNumber(-20, 20), 0.36, rng:NextNumber(-3, 3)), 2.2, 0.15, C.Leaf2, { decor = true, shadow = false })
		end
	end
	local deck = if styleName == "stone" then C.Stone else if styleName == "red" then C.Red else C.Wood
	local rail = if styleName == "stone" then C.Stone2 else if styleName == "red" then C.Red else C.Wood
	local bw = if styleName == "stone" then 9 else 7
	P(m, Vector3.new(bw, 1, 7), at(cf, 0, 3.2, 0), deck)
	for _, s in { -1, 1 } do
		P(m, Vector3.new(bw, 1, 7.5), at(cf, 0, 1.6, s * 6.8) * CFrame.Angles(s * 0.45, 0, 0), deck)
		if styleName == "stone" then
			P(m, Vector3.new(bw, 2.6, 3), at(cf, 0, 1.3, s * 9), C.Stone2)
		end
	end
	for _, x in { -1, 1 } do
		P(m, Vector3.new(0.6, 1, 7), at(cf, x * (bw / 2 - 0.3), 4.6, 0), rail, { decor = true })
		for _, s in { -1, 1 } do
			P(m, Vector3.new(0.6, 1, 7.5), at(cf, x * (bw / 2 - 0.3), 3, s * 6.8) * CFrame.Angles(s * 0.45, 0, 0), rail, { decor = true })
			P(m, Vector3.new(1, 4.4, 1), at(cf, x * (bw / 2 - 0.3), 2.2, s * 10), rail)
			P(m, Vector3.new(1.2, 0.6, 1.2), at(cf, x * (bw / 2 - 0.3), 4.6, s * 10), if styleName == "red" then C.Yellow else C.White, { decor = true })
		end
	end
	return m, { kind = "bridge", pos = at(cf, 0, 0.8, 0).Position }
end

function Kit.waterfall(parent: Instance, cf: CFrame, rng: Random, frozen: boolean?): (Model, Spot)
	local m = M(parent, "Waterfall")
	local top = if frozen then C.Snow else C.Moss
	P(m, Vector3.new(30, 16, 12), at(cf, 0, 8, 6), C.Rock)
	P(m, Vector3.new(30, 1, 12), at(cf, 0, 16.4, 6), top, { decor = true })
	P(m, Vector3.new(18, 9, 9), at(cf, -3, 20.5, 8), C.RockDark)
	P(m, Vector3.new(18, 1, 9), at(cf, -3, 25.4, 8), top, { decor = true })
	local water = if frozen then C.Ice else C.WaterLight
	for _, x in { -6, 5 } do
		P(m, Vector3.new(5, 16, 0.8), at(cf, x, 8.5, -0.3), water, { mat = if frozen then Enum.Material.Glass else Enum.Material.Neon, t = if frozen then 0.1 else 0.25, decor = true })
	end
	D(m, at(cf, 0, 0.16, -8), 24, 0.3, if frozen then C.Ice else C.Water, { decor = true, refl = 0.12, t = 0.05, shadow = false })
	if not frozen then
		for _, x in { -6, 5 } do
			local foam = B(m, 3.5, at(cf, x, 0.8, -1.5).Position, C.White, { decor = true, t = 0.2 })
			local e = Instance.new("ParticleEmitter")
			e.Color = ColorSequence.new(C.White)
			e.Size = NumberSequence.new(1.2, 2.5)
			e.Transparency = NumberSequence.new(0.3, 1)
			e.Rate = 8
			e.Lifetime = NumberRange.new(1, 1.6)
			e.Speed = NumberRange.new(3, 5)
			e.SpreadAngle = Vector2.new(50, 50)
			e.Parent = foam
		end
	else
		for _ = 1, 3 do
			Kit.crystals(m, at(cf, rng:NextNumber(-12, 12), 0, -10), rng, C.Ice)
		end
	end
	return m, { kind = "rock", pos = at(cf, 17, 1, 2).Position }
end

function Kit.mountain(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Mountain")
	local base = cf * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
	local tiers = { { 64, 22, 52 }, { 46, 18, 38 }, { 30, 16, 26 }, { 15, 12, 14 } }
	local y = 0
	for i, t in tiers do
		local c = if i <= 2 then C.Rock else C.Snow
		P(m, Vector3.new(t[1], t[2], t[3]), base * CFrame.new(0, y + t[2] / 2, 0), c)
		P(m, Vector3.new(t[1] - 4, 1.4, t[3] - 4), base * CFrame.new(0, y + t[2] + 0.7, 0), C.Snow, { decor = true })
		y += t[2]
	end
end

----------------------------------------------------------------------------------------------------
-- Lobby pieces

function Kit.fountain(parent: Instance, cf: CFrame, s: number)
	local m = M(parent, "Fountain")
	D(m, at(cf, 0, 0.9 * s, 0), 24 * s, 1.8 * s, C.Stone2)
	D(m, at(cf, 0, 1.9 * s, 0), 21 * s, 0.4 * s, C.Water, { refl = 0.15, t = 0.05 })
	D(m, at(cf, 0, 3.5 * s, 0), 4 * s, 5 * s, C.Stone)
	D(m, at(cf, 0, 6.3 * s, 0), 11 * s, 1 * s, C.Stone2)
	D(m, at(cf, 0, 6.85 * s, 0), 9.4 * s, 0.3 * s, C.Water, { refl = 0.15 })
	D(m, at(cf, 0, 8.4 * s, 0), 2 * s, 3 * s, C.Stone)
	D(m, at(cf, 0, 10 * s, 0), 5.5 * s, 0.8 * s, C.Stone2)
	local top = B(m, 2.2 * s, at(cf, 0, 10.8 * s, 0).Position, C.WaterLight, { mat = Enum.Material.Neon, t = 0.2, decor = true })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(C.WaterLight)
	e.Size = NumberSequence.new(0.8, 0.3)
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Rate = 25
	e.Lifetime = NumberRange.new(1.2, 1.6)
	e.Speed = NumberRange.new(8, 10)
	e.SpreadAngle = Vector2.new(25, 25)
	e.Acceleration = Vector3.new(0, -14, 0)
	e.Parent = top
	-- falling water from the two bowls
	for i = 0, 7 do
		local a = i * math.pi / 4
		P(m, Vector3.new(1.2, 3.8 * s, 0.4), at(cf, math.cos(a) * 5.2 * s, 4.6 * s, math.sin(a) * 5.2 * s) * CFrame.Angles(0, -a + math.pi / 2, 0), C.WaterLight, { mat = Enum.Material.Neon, t = 0.35, decor = true })
	end
	-- flower ring
	for i = 0, 11 do
		local a = i * math.pi / 6
		B(m, 1.6 * s, at(cf, math.cos(a) * 13 * s, 1.2 * s, math.sin(a) * 13 * s).Position, Kit.FlowerColors[i % #Kit.FlowerColors + 1], { decor = true })
	end
	return m
end

-- One player pen. cf = pen centre on the ground, LookVector toward the plaza (front = -Z).
function Kit.pen(parent: Instance, index: number, cf: CFrame, w: number, d: number, roof: Color3, rng: Random): Model
	local m = M(parent, `Pen{index}`)
	m:SetAttribute("Index", index)
	P(m, Vector3.new(w, 0.4, d), at(cf, 0, 0.2, 0), C.PenGrass, { name = "Floor" })
	local hw, hd = w / 2, d / 2
	local gap = 6
	local function fenceL(a: Vector3, b: Vector3)
		Kit.fence(m, (cf * CFrame.new(a)).Position, (cf * CFrame.new(b)).Position)
	end
	fenceL(Vector3.new(-hw, 0, -hd), Vector3.new(-gap, 0, -hd))
	fenceL(Vector3.new(gap, 0, -hd), Vector3.new(hw, 0, -hd))
	fenceL(Vector3.new(-hw, 0, -hd), Vector3.new(-hw, 0, hd))
	fenceL(Vector3.new(hw, 0, -hd), Vector3.new(hw, 0, hd))
	fenceL(Vector3.new(-hw, 0, hd), Vector3.new(hw, 0, hd))
	-- cat house at the back with cat-ear roof and a paw sign
	local house = M(m, "CatHouse")
	local hc = cf * CFrame.new(0, 0, hd - 6)
	P(house, Vector3.new(12, 7, 8), hc * CFrame.new(0, 3.9, 0), C.Cream)
	gable(house, hc * CFrame.new(0, 7.4, 0), 14, 10.5, 4.5, roof)
	for _, x in { -4.6, 4.6 } do
		W(house, Vector3.new(2.6, 3, 1.6), hc * CFrame.new(x, 12.2, -1.2), roof)
		W(house, Vector3.new(1.4, 1.8, 0.4), hc * CFrame.new(x, 11.9, -2.1), C.PinkLight, { decor = true })
	end
	P(house, Vector3.new(4.4, 4.6, 0.3), hc * CFrame.new(0, 2.7, -4.05), C.Black, { decor = true })
	local paw = hc * CFrame.new(0, 6.3, -4.1)
	B(house, 1.4, (paw * CFrame.new(0, -0.3, 0)).Position, C.Orange, { decor = true, shadow = false })
	for i = -1, 1 do
		B(house, 0.6, (paw * CFrame.new(i * 0.75, 0.75 - math.abs(i) * 0.2, 0)).Position, C.Orange, { decor = true, shadow = false })
	end
	D(m, cf * CFrame.new(-6, 0.7, hd - 9), 2.4, 0.6, C.Red, { decor = true })
	D(m, cf * CFrame.new(6, 0.6, hd - 10), 4, 0.4, C.Pink, { decor = true })
	-- name sign as an arch over the gate (text is added by the game: PenService)
	local sign = M(m, "Sign")
	local sc = cf * CFrame.new(0, 0, -hd - 0.8)
	for _, x in { -gap - 0.2, gap + 0.2 } do
		P(sign, Vector3.new(1, 11, 1), sc * CFrame.new(x, 5.5, 0), C.WoodDark)
		P(sign, Vector3.new(1.4, 0.6, 1.4), sc * CFrame.new(x, 11.3, 0), C.White, { decor = true })
	end
	P(sign, Vector3.new(14, 4.4, 0.8), sc * CFrame.new(0, 9, 0), C.WoodDark)
	P(sign, Vector3.new(13, 3.6, 0.4), sc * CFrame.new(0, 9, -0.45), C.Wood, { name = "Board" })
	-- training corner in front of the pen: treadmill on the left, dumbbell rack on the right
	local tm = M(m, "Treadmill")
	local tc = cf * CFrame.new(-12, 0, -hd - 8)
	P(tm, Vector3.new(5, 1.2, 10), tc * CFrame.new(0, 0.6, 0), C.Navy)
	P(tm, Vector3.new(4, 0.3, 8.6), tc * CFrame.new(0, 1.3, 0.3), C.Black, { name = "Belt" })
	for _, x in { -2.3, 2.3 } do
		P(tm, Vector3.new(0.5, 4, 0.5), tc * CFrame.new(x, 3, -4.4), C.Yellow)
	end
	P(tm, Vector3.new(5, 0.5, 0.5), tc * CFrame.new(0, 5, -4.4), C.Yellow)
	P(tm, Vector3.new(4, 1.8, 0.8), tc * CFrame.new(0, 4.6, -4.8) * CFrame.Angles(0.4, 0, 0), C.Navy)
	P(tm, Vector3.new(2.6, 1, 0.2), tc * CFrame.new(0, 4.75, -5.2) * CFrame.Angles(0.4, 0, 0), C.Teal, { mat = Enum.Material.Neon, decor = true })
	P(tm, Vector3.new(4, 1, 4), tc * CFrame.new(0, 2, 0.3), C.White, { name = "Stand", t = 1, decor = true })
	local wt = M(m, "Weights")
	local wc = cf * CFrame.new(12, 0, -hd - 8)
	P(wt, Vector3.new(7, 0.6, 3), wc * CFrame.new(0, 0.3, 2), C.Navy)
	for _, x in { -3.2, 3.2 } do
		P(wt, Vector3.new(0.6, 3.6, 0.6), wc * CFrame.new(x, 2.1, 2), C.Navy)
	end
	P(wt, Vector3.new(7, 0.5, 0.6), wc * CFrame.new(0, 3.7, 2), C.Navy)
	local plates = { C.Pink, C.Yellow, C.Blue }
	for i, c in plates do
		local y = 0.9 + i * 0.9
		local bar = wc * CFrame.new(0, y, 1.6)
		P(wt, Vector3.new(4, 0.35, 0.35), bar, C.Stone2, { decor = true })
		for _, x in { -1.7, 1.7 } do
			D(wt, bar * CFrame.new(x, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), 1.4, 0.7, c)
		end
	end
	P(wt, Vector3.new(4, 1, 4), wc * CFrame.new(0, 2, -2), C.White, { name = "Stand", t = 1, decor = true })
	-- invisible helpers for the game code
	P(m, Vector3.new(4, 1, 4), cf * CFrame.new(0, 0.9, -hd + 4), C.White, { name = "Spawn", t = 1, decor = true })
	P(m, Vector3.new(w - 6, 1, d - 16), cf * CFrame.new(0, 0.9, -3), C.White, { name = "Area", t = 1, decor = true })
	for _ = 1, 2 do
		Kit.flowers(m, cf * CFrame.new(rng:NextNumber(-hw + 3, -hw + 6), 0.4, rng:NextNumber(-4, 6)), rng, 4)
	end
	return m
end

----------------------------------------------------------------------------------------------------
-- Sky pieces

-- A floating island: top surface at cf.Y, checkerboard grass on top, rock hanging below.
function Kit.island(parent: Instance, cf: CFrame, size: number, rng: Random): Model
	local m = M(parent, "Island")
	local half = size / 2
	for ix = 0, 1 do
		for iz = 0, 1 do
			local c = if (ix + iz) % 2 == 0 then C.Grass1 else C.Grass2
			P(m, Vector3.new(half, 3, half), at(cf, (ix - 0.5) * half, -1.5, (iz - 0.5) * half), c, { name = "Ground" })
		end
	end
	local tiers = { { 0.92, 6 }, { 0.68, 8 }, { 0.42, 9 }, { 0.2, 8 } }
	local y = -3
	for i, t in tiers do
		local s = size * t[1]
		P(m, Vector3.new(s, t[2], s * rng:NextNumber(0.85, 1)), at(cf, rng:NextNumber(-2, 2), y - t[2] / 2, rng:NextNumber(-2, 2)), if i % 2 == 0 then C.RockDark else C.Rock)
		y -= t[2]
	end
	for _ = 1, 4 do
		local a = rng:NextNumber(0, math.pi * 2)
		P(m, Vector3.new(2.5, rng:NextNumber(3, 6), 2.5), at(cf, math.cos(a) * half * 0.9, -4, math.sin(a) * half * 0.9), C.Moss, { decor = true })
	end
	return m
end

function Kit.skyBridge(parent: Instance, a: Vector3, b: Vector3): Spot
	local m = M(parent, "RopeBridge")
	local len = (b - a).Magnitude
	local dir = CFrame.lookAt(a, b)
	P(m, Vector3.new(6, 0.7, len), dir * CFrame.new(0, -0.35, -len / 2), C.Wood)
	for i = 3, math.floor(len) - 3, 6 do
		P(m, Vector3.new(6.2, 0.2, 0.5), dir * CFrame.new(0, 0.05, -i), C.WoodDark, { decor = true, shadow = false })
	end
	for _, x in { -3.2, 3.2 } do
		P(m, Vector3.new(0.35, 0.35, len), dir * CFrame.new(x, 3, -len / 2), C.Gold, { decor = true })
		for _, z in { 0, len } do
			P(m, Vector3.new(1.4, 4.6, 1.4), dir * CFrame.new(x, 2.3, -z), C.White)
			P(m, Vector3.new(1.6, 0.8, 1.6), dir * CFrame.new(x, 4.9, -z), C.Gold, { decor = true })
		end
	end
	return { kind = "bridge", pos = (dir * CFrame.new(3, 0.8, 4)).Position }
end

function Kit.cloud(parent: Instance, pos: Vector3, s: number, rng: Random)
	local m = M(parent, "Cloud")
	for i = 1, 5 do
		local o = Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-0.3, 0.6), rng:NextNumber(-0.8, 0.8)) * s * 6
		B(m, s * rng:NextNumber(6, 10), pos + o, C.White, { decor = true, shadow = false })
		local _ = i
	end
end

-- A rainbow arc standing on a base point, facing `cf.LookVector`.
function Kit.rainbow(parent: Instance, cf: CFrame, radius: number)
	local m = M(parent, "Rainbow")
	local colors = { hex("ff5a5a"), hex("ff9f3c"), hex("ffe14d"), hex("62d65a"), hex("4fb6ff"), hex("7a6bff"), hex("c06bff") }
	local segs = 30
	for band, c in colors do
		local r = radius - (band - 1) * 4
		local arc = math.pi * r / segs + 0.6
		for i = 0, segs - 1 do
			local a = (i + 0.5) / segs * math.pi
			local cfs = cf * CFrame.new(math.cos(a) * r, math.sin(a) * r, 0) * CFrame.Angles(0, 0, a + math.pi / 2)
			P(m, Vector3.new(arc, 4, 1), cfs, c, { mat = Enum.Material.Neon, t = 0.35, decor = true, shadow = false })
		end
	end
end

return Kit
