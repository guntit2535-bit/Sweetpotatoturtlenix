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
	walk: boolean?, -- no collision, queries kept (players walk through it: bushes that hide cats, R1)
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
		if o.walk then
			p.CanCollide = false
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
	B(m, 7.5, at(cf, 0, 3, 0).Position, c, { walk = true })
	for i = 1, 4 do
		local a = i * math.pi / 2 + rng:NextNumber(-0.3, 0.3)
		B(m, rng:NextNumber(4.5, 6), at(cf, math.cos(a) * 3.4, 2.3, math.sin(a) * 3.4).Position, if i % 2 == 0 then c else C.Leaf2, { walk = true })
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
-- V3 water: glassy see-through water (Glass, a little reflection) over a darker bed, water that flows (Beams with
-- a built-in texture moving along them: no uploads), splashes and mist. Old saves of the map are swapped in place
-- by MapTools/Upgrade (same spots for hiding cats).
local WATER = hex("3aa9ec")
local WATER_DEEP = hex("2a6f9c")
local ICE = hex("c9efff")
local SAND = hex("ead9a8")
local FLOW_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"

local function waterSurface(parent: Instance, size: Vector3, cf: CFrame, frozen: boolean?, shape: Enum.PartType?): Part
	return P(parent, size, cf, if frozen then ICE else WATER, {
		mat = Enum.Material.Glass,
		t = if frozen then 0.12 else 0.32,
		refl = if frozen then 0.3 else 0.18,
		decor = true,
		shadow = false,
		shape = shape,
	})
end

local function waterDisc(parent: Instance, cf: CFrame, d: number, h: number, frozen: boolean?): Part
	local p = waterSurface(parent, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.pi / 2), frozen, Enum.PartType.Cylinder)
	return p
end

-- A flowing stream between two points (a Beam with a moving texture), on a small invisible anchor.
local function flow(parent: Instance, a: Vector3, b: Vector3, width0: number, width1: number, speed: number, color: Color3?)
	local anchor = P(parent, Vector3.new(0.2, 0.2, 0.2), CFrame.new(a), WATER, { decor = true, t = 1, shadow = false, name = "Flow" })
	local a0 = Instance.new("Attachment")
	a0.Parent = anchor
	local a1 = Instance.new("Attachment")
	a1.Parent = anchor -- (parent first: WorldPosition only means the world once it is attached)
	a1.WorldPosition = b
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Texture = FLOW_TEXTURE
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 2.5
	beam.TextureSpeed = speed
	beam.Color = ColorSequence.new(color or C.WaterLight)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.3) })
	beam.Width0 = width0
	beam.Width1 = width1
	beam.LightEmission = 0.7
	beam.LightInfluence = 0.6
	beam.FaceCamera = false
	beam.Segments = 8
	beam.Parent = anchor
	return beam
end

local function droplets(parent: BasePart, rate: number, size: number, speed: number, spread: number)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(C.White)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.3) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(speed * 0.7, speed)
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Acceleration = Vector3.new(0, -18, 0)
	e.LightEmission = 0.3
	e.Parent = parent
end

local function mist(parent: BasePart, rate: number, size: number)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(C.White)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	e.Rate = rate
	e.Lifetime = NumberRange.new(1.6, 2.4)
	e.Speed = NumberRange.new(1.5, 3)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, 1, 0)
	e.Parent = parent
end

function Kit.creek(parent: Instance, cf: CFrame, rng: Random, styleName: string, frozen: boolean?): (Model, Spot)
	local m = M(parent, "Creek")
	-- a winding path along local X (the bridge crosses it at x = 0, where it runs straight)
	local phase = rng:NextNumber(0, math.pi * 2)
	local amp = rng:NextNumber(2.5, 4)
	local pts = {}
	for i = 0, 10 do
		local x = -32 + i * 6.4
		local z = amp * math.sin(x / 19 + phase) * math.clamp(math.abs(x) / 10, 0, 1)
		table.insert(pts, Vector3.new(x, 0, z))
	end
	local bank = if frozen then C.Snow else SAND
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local mid = (a + b) / 2
		local len = (b - a).Magnitude + 1.6
		local seg = cf * CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0)
		local wide = 10.5 + math.sin(i * 1.7 + phase) * 1.2
		P(m, Vector3.new(len, 0.12, wide + 1), seg * CFrame.new(0, 0.07, 0), if frozen then C.SnowShade else WATER_DEEP, { decor = true, shadow = false })
		waterSurface(m, Vector3.new(len, 0.26, wide), seg * CFrame.new(0, 0.2, 0), frozen)
		for _, s in { -1, 1 } do
			P(m, Vector3.new(len, 0.34, 2.2), seg * CFrame.new(0, 0.18, s * (wide / 2 + 0.9)), bank, { decor = true, shadow = false })
		end
		if not frozen then
			flow(m, (cf * CFrame.new(a + Vector3.new(0, 0.36, 0))).Position, (cf * CFrame.new(b + Vector3.new(0, 0.36, 0))).Position, wide * 0.55, wide * 0.55, 0.9, C.WaterLight)
		end
	end
	-- round pools at both ends
	for _, e in { pts[1], pts[#pts] } do
		P(m, Vector3.new(0.12, 14, 14), cf * CFrame.new(e + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, 0, math.pi / 2), if frozen then C.SnowShade else WATER_DEEP, { decor = true, shadow = false, shape = Enum.PartType.Cylinder })
		waterDisc(m, cf * CFrame.new(e + Vector3.new(0, 0.2, 0)), 12, 0.26, frozen)
		D(m, cf * CFrame.new(e + Vector3.new(0, 0.12, 0)), 15.4, 0.3, bank, { decor = true, shadow = false })
	end
	-- stones on the banks, reeds and lily pads (summer), snow lumps (winter)
	for _ = 1, 14 do
		local i = rng:NextInteger(1, #pts)
		local s = if rng:NextNumber() < 0.5 then -1 else 1
		local p = pts[i] + Vector3.new(rng:NextNumber(-2, 2), 0, s * rng:NextNumber(5.6, 7.4))
		local d = rng:NextNumber(0.9, 2.2)
		B(m, d, (cf * CFrame.new(p + Vector3.new(0, d * 0.25, 0))).Position, if rng:NextNumber() < 0.5 then C.Rock else C.Stone2, { decor = true })
	end
	if not frozen then
		for _ = 1, 4 do
			local i = rng:NextInteger(2, #pts - 1)
			if math.abs(pts[i].X) < 7 then
				continue
			end
			local s = if rng:NextNumber() < 0.5 then -1 else 1
			local base = cf * CFrame.new(pts[i] + Vector3.new(0, 0, s * 5.8))
			for k = 1, rng:NextInteger(3, 5) do
				local h = rng:NextNumber(1.8, 3.2)
				local foot = base * CFrame.new(rng:NextNumber(-0.9, 0.9), 0, rng:NextNumber(-0.6, 0.6)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), 0, rng:NextNumber(-0.12, 0.12))
				pole(m, foot, 0.22, h, if k % 2 == 0 then C.Leaf else C.LeafDark, { decor = true })
				P(m, Vector3.new(0.36, 0.8, 0.36), foot * CFrame.new(0, h + 0.2, 0), C.WoodDark, { decor = true })
			end
		end
		for _ = 1, 5 do
			local i = rng:NextInteger(2, #pts - 1)
			if math.abs(pts[i].X) < 6 then
				continue
			end
			local p = cf * CFrame.new(pts[i] + Vector3.new(rng:NextNumber(-2, 2), 0.36, rng:NextNumber(-3, 3)))
			D(m, p, rng:NextNumber(1.6, 2.4), 0.12, C.Leaf2, { decor = true, shadow = false })
			if rng:NextNumber() < 0.5 then
				B(m, 0.6, (p * CFrame.new(0.3, 0.2, 0)).Position, C.PinkLight, { decor = true })
			end
		end
		-- stepping stones across, away from the bridge
		local x = if rng:NextNumber() < 0.5 then -20 else 20
		for k = -2, 2 do
			D(m, cf * CFrame.new(x + rng:NextNumber(-0.5, 0.5), 0.35, k * 2.6), 2.2, 0.5, C.Stone2)
		end
	else
		for _ = 1, 6 do
			local i = rng:NextInteger(1, #pts)
			local s = if rng:NextNumber() < 0.5 then -1 else 1
			B(m, rng:NextNumber(1.5, 2.6), (cf * CFrame.new(pts[i] + Vector3.new(0, 0.4, s * 6.5))).Position, C.Snow, { decor = true })
		end
	end
	-- the bridge (unchanged: the hiding spot sits under it)
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
	m:SetAttribute("Style", styleName)
	m:SetAttribute("Frozen", frozen == true)
	m:SetAttribute("V3", true)
	return m, { kind = "bridge", pos = at(cf, 0, 0.8, 0).Position }
end

function Kit.waterfall(parent: Instance, cf: CFrame, rng: Random, frozen: boolean?): (Model, Spot)
	local m = M(parent, "Waterfall")
	local top = if frozen then C.Snow else C.Moss
	-- the cliff: rough rock blocks round the old footprint (30 x 16 x 12 at z 6; an upper tier at -3, 25)
	local blocks = {
		{ Vector3.new(14, 15, 11), Vector3.new(-9, 7.5, 6.5) },
		{ Vector3.new(13, 16.5, 12), Vector3.new(6.5, 8.2, 6) },
		{ Vector3.new(9, 13, 9), Vector3.new(-0.5, 6.5, 8) },
		{ Vector3.new(8, 9, 8), Vector3.new(-12, 4.5, 2.5) },
		{ Vector3.new(7, 8, 7), Vector3.new(12, 4, 2) },
		{ Vector3.new(17, 9, 9), Vector3.new(-3, 20.5, 8.5) },
		{ Vector3.new(8, 6, 7), Vector3.new(5, 19, 9.5) },
	}
	for i, b in blocks do
		local tilt = CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.06, 0.06))
		local cfb = at(cf, b[2].X, b[2].Y, b[2].Z) * tilt
		P(m, b[1], cfb, if i % 3 == 0 then C.RockDark else C.Rock)
		P(m, Vector3.new(b[1].X - 0.6, 0.8, b[1].Z - 0.6), cfb * CFrame.new(0, b[1].Y / 2 + 0.3, 0), top, { decor = true })
		if not frozen then
			for _ = 1, 2 do
				P(m, Vector3.new(rng:NextNumber(1.5, 3), rng:NextNumber(1, 2.4), 0.5), cfb * CFrame.new(rng:NextNumber(-b[1].X / 2.6, b[1].X / 2.6), rng:NextNumber(-b[1].Y / 3, b[1].Y / 3), -b[1].Z / 2 - 0.1), C.Moss, { decor = true, shadow = false })
			end
		end
	end
	-- the falls: a see-through sheet and flowing water in front, from the top down into the pool
	for _, f in { { -4.5, 16.6, 5.5 }, { 4.5, 16.6, 5 }, { -3, 25.2, 4 } } do
		local x, y, w = f[1], f[2], f[3]
		local zTop = if y > 20 then 3.6 else 0.2
		local bottomY = if y > 20 then 16.8 else 0.4
		P(m, Vector3.new(w, y - bottomY, 0.5), at(cf, x, (y + bottomY) / 2, zTop - 0.4), if frozen then ICE else C.WaterLight, {
			mat = Enum.Material.Glass,
			t = if frozen then 0.1 else 0.35,
			refl = 0.2,
			decor = true,
			shadow = false,
		})
		if not frozen then
			flow(m, at(cf, x, y, zTop - 0.8).Position, at(cf, x, bottomY, zTop - 1.6).Position, w, w + 1.2, 2.2, C.White)
		else
			for k = -1, 1 do
				W(m, Vector3.new(0.6, 2.2, 0.6), at(cf, x + k * w / 3, y - 1.2, zTop - 0.9) * CFrame.Angles(math.pi, 0, 0), ICE, { decor = true })
			end
		end
	end
	-- the pool: a bed, glassy water, a ring of stones; foam and mist where the falls land
	D(m, at(cf, 0, 0.07, -7), 25, 0.12, if frozen then C.SnowShade else WATER_DEEP, { decor = true, shadow = false })
	waterDisc(m, at(cf, 0, 0.2, -7), 24, 0.26, frozen)
	for k = 0, 13 do
		local a = math.pi * (0.95 + k / 13 * 1.1)
		local d = rng:NextNumber(1.4, 2.6)
		B(m, d, at(cf, math.cos(a) * 12.6, d * 0.3, -7 + math.sin(a) * 12.6).Position, if k % 2 == 0 then C.Rock else C.Stone2, { decor = true })
	end
	if not frozen then
		for _, x in { -4.5, 4.5 } do
			local foam = B(m, 3, at(cf, x, 0.5, -1.4).Position, C.White, { decor = true, t = 0.35, shadow = false })
			droplets(foam, 16, 0.6, 9, 45)
			mist(foam, 6, 5)
		end
	else
		for _ = 1, 3 do
			Kit.crystals(m, at(cf, rng:NextNumber(-12, 12), 0, -10), rng, C.Ice)
		end
	end
	m:SetAttribute("Frozen", frozen == true)
	m:SetAttribute("V3", true)
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

-- V3: a real stone fountain: an octagonal basin (walls, a wide rim, corner posts with finials), a pedestal,
-- two bowls with lips, glassy water in each, water falling from bowl to bowl as flowing streams, a spray on
-- top, splashes where the water lands and a soft light under the water at night. s = scale (1.5 plaza, 0.75
-- in a zone).
function Kit.fountain(parent: Instance, cf: CFrame, s: number)
	local m = M(parent, "Fountain")
	local stone, stone2, light = C.Stone, C.Stone2, hex("eef0f5")
	local R = 12 * s
	local side = 2 * R * math.tan(math.pi / 8)
	-- floor of the basin (a blue mosaic look) and the octagonal wall with its rim
	D(m, at(cf, 0, 0.25 * s, 0), 2 * R + 0.4, 0.5 * s, hex("5a9fcf"))
	for i = 0, 7 do
		local a = i * math.pi / 4
		local w = cf * CFrame.Angles(0, a, 0)
		P(m, Vector3.new(side + 0.4 * s, 2.2 * s, 1.3 * s), w * CFrame.new(0, 1.1 * s, R), stone)
		P(m, Vector3.new(side + 0.9 * s, 0.45 * s, 2.1 * s), w * CFrame.new(0, 2.4 * s, R), light)
		P(m, Vector3.new(side * 0.7, 0.35 * s, 0.25), w * CFrame.new(0, 1.2 * s, R + 0.7 * s), stone2, { decor = true })
		-- corner posts with a ball on top
		local c = cf * CFrame.Angles(0, a + math.pi / 8, 0) * CFrame.new(0, 0, R / math.cos(math.pi / 8))
		P(m, Vector3.new(1.5 * s, 3.2 * s, 1.5 * s), c * CFrame.new(0, 1.6 * s, 0), stone2)
		B(m, 1.2 * s, (c * CFrame.new(0, 3.65 * s, 0)).Position, light, { decor = true })
	end
	local pool = waterDisc(m, at(cf, 0, 1.75 * s, 0), 2 * R - 0.6, 0.3 * s)
	-- pedestal, the big bowl, the column, the small bowl, the top
	D(m, at(cf, 0, 0.9 * s, 0), 5.2 * s, 0.8 * s, stone2)
	D(m, at(cf, 0, 3.5 * s, 0), 3.4 * s, 5 * s, stone)
	D(m, at(cf, 0, 5.75 * s, 0), 4.4 * s, 0.5 * s, stone2)
	D(m, at(cf, 0, 6.15 * s, 0), 7 * s, 0.4 * s, stone)
	D(m, at(cf, 0, 6.55 * s, 0), 9.2 * s, 0.45 * s, stone)
	D(m, at(cf, 0, 6.95 * s, 0), 11 * s, 0.45 * s, light)
	local bowl = waterDisc(m, at(cf, 0, 7.12 * s, 0), 10 * s, 0.2 * s)
	D(m, at(cf, 0, 8.4 * s, 0), 1.9 * s, 2.6 * s, stone)
	D(m, at(cf, 0, 9.75 * s, 0), 3.6 * s, 0.4 * s, stone)
	D(m, at(cf, 0, 10.1 * s, 0), 5.4 * s, 0.4 * s, light)
	waterDisc(m, at(cf, 0, 10.25 * s, 0), 4.8 * s, 0.15 * s)
	D(m, at(cf, 0, 10.75 * s, 0), 1.1 * s, 1 * s, stone)
	local top = B(m, 1.5 * s, at(cf, 0, 11.6 * s, 0).Position, light, { decor = true })
	-- the spray on top
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(C.WaterLight)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * s), NumberSequenceKeypoint.new(1, 0.2 * s) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	e.Rate = 30
	e.Lifetime = NumberRange.new(0.7, 0.9)
	e.Speed = NumberRange.new(4 * s, 5 * s)
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0, -20 * s, 0)
	e.LightEmission = 0.4
	e.Parent = top
	-- water falling from the small bowl into the big one, and from the big one into the basin
	for i = 0, 7 do
		local a = i * math.pi / 4 + math.pi / 8
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = cf.Position
		flow(m, base + dir * 2.7 * s + Vector3.new(0, 10.3 * s, 0), base + dir * 3.6 * s + Vector3.new(0, 7.2 * s, 0), 1.3 * s, 1.7 * s, 1.6)
	end
	for i = 0, 15 do
		local a = i * math.pi / 8
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = cf.Position
		flow(m, base + dir * 5.5 * s + Vector3.new(0, 7.0 * s, 0), base + dir * 6.9 * s + Vector3.new(0, 1.9 * s, 0), 2 * s, 2.6 * s, 1.8)
	end
	-- splashes where it lands, and a soft light under the water
	local ring = P(m, Vector3.new(14 * s, 0.2, 14 * s), at(cf, 0, 1.95 * s, 0), C.White, { decor = true, t = 1, shadow = false, name = "Splash" })
	droplets(ring, 30, 0.35 * s, 5 * s, 25)
	local glow = Instance.new("PointLight")
	glow.Color = hex("8fe0ff")
	glow.Range = 16 * s
	glow.Brightness = 1.2
	glow.Parent = pool
	local _ = bowl
	-- a ring of flower bushes round it
	for i = 0, 11 do
		local a = i * math.pi / 6
		local p = cf.Position + Vector3.new(math.cos(a) * 15 * s, 0, math.sin(a) * 15 * s)
		B(m, 2 * s, p + Vector3.new(0, 0.8 * s, 0), C.Leaf2, { decor = true })
		for k = 0, 2 do
			local b = k * 2.1 + i
			B(m, 0.7 * s, p + Vector3.new(math.cos(b) * 0.6 * s, 1.7 * s, math.sin(b) * 0.6 * s), Kit.FlowerColors[(i + k) % #Kit.FlowerColors + 1], { decor = true })
		end
	end
	m:SetAttribute("Scale", s)
	m:SetAttribute("V3", true)
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
	-- (round 2: no decorations inside the pen, only the house and the green floor)
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

----------------------------------------------------------------------------------------------------
-- V3 part 2: small ground details scattered between the clusters (MapTools/Detail). No collision, no queries,
-- no shadows: players walk through them and phones only draw them.

local function decor(): Opts
	return { decor = true, shadow = false }
end

local function spin(cf: CFrame, rng: Random): CFrame
	return cf * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

-- A clump of grass blades (thin wedges leaning out).
function Kit.tuft(parent: Instance, cf: CFrame, rng: Random, color: Color3?)
	local m = M(parent, "Tuft")
	local base = color or C.Leaf
	for _ = 1, rng:NextInteger(4, 6) do
		local h = rng:NextNumber(1.4, 2.6)
		local c = spin(cf, rng) * CFrame.new(rng:NextNumber(-0.7, 0.7), h / 2 - 0.05, rng:NextNumber(-0.7, 0.7))
		W(m, Vector3.new(0.34, h, 0.8), c * CFrame.Angles(rng:NextNumber(-0.25, 0.1), 0, 0), base:Lerp(C.Leaf2, rng:NextNumber(0, 0.6)), decor())
	end
end

-- A few flat stones.
function Kit.pebbles(parent: Instance, cf: CFrame, rng: Random, cap: Color3?)
	local m = M(parent, "Pebbles")
	for _ = 1, rng:NextInteger(2, 4) do
		local s = rng:NextNumber(0.8, 1.7)
		local c = spin(cf, rng) * CFrame.new(rng:NextNumber(-1.6, 1.6), s * 0.2, rng:NextNumber(-1.6, 1.6))
		P(m, Vector3.new(s * 1.3, s * 0.45, s), c * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15)),
			pick(rng, { C.Stone, C.Stone2, C.Rock }), decor())
		if cap then
			P(m, Vector3.new(s * 1.2, 0.12, s * 0.9), c * CFrame.new(0, s * 0.25, 0), cap, decor())
		end
	end
end

-- Toadstools: a stem and a red cap with white dots.
function Kit.mushroom(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Mushroom")
	for k = 1, rng:NextInteger(1, 3) do
		local s = if k == 1 then rng:NextNumber(1.3, 1.8) else rng:NextNumber(0.7, 1.1)
		local c = spin(cf, rng) * CFrame.new(if k == 1 then 0 else rng:NextNumber(-1.1, 1.1), 0, if k == 1 then 0 else rng:NextNumber(-1.1, 1.1))
		P(m, Vector3.new(0.45, 1.0, 0.45) * s, c * CFrame.new(0, 0.5 * s, 0), C.Cream, decor())
		P(m, Vector3.new(1.5, 0.55, 1.5) * s, c * CFrame.new(0, 1.15 * s, 0), pick(rng, { C.Red, C.Red, C.Orange }), decor())
		P(m, Vector3.new(1.0, 0.3, 1.0) * s, c * CFrame.new(0, 1.5 * s, 0), C.Red, decor())
		for _, d in { { -0.45, 0.2 }, { 0.35, -0.4 }, { 0.2, 0.45 } } do
			P(m, Vector3.new(0.22, 0.08, 0.22) * s, c * CFrame.new(d[1] * s, 1.44 * s, d[2] * s), C.White, decor())
		end
	end
end

-- A fern: leaves fanning out from the ground.
function Kit.fern(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Fern")
	local n = rng:NextInteger(5, 7)
	for k = 1, n do
		local a = k / n * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local len = rng:NextNumber(1.6, 2.4)
		local c = cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.45, -len / 2 + 0.2) * CFrame.Angles(0.45, 0, 0)
		P(m, Vector3.new(0.6, 0.12, len), c, if k % 2 == 0 then C.Leaf else C.LeafDark, decor())
	end
end

-- A fallen log with moss on top.
function Kit.log(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Log")
	local len = rng:NextNumber(3.5, 5.5)
	local c = spin(cf, rng) * CFrame.new(0, 0.55, 0)
	P(m, Vector3.new(len, 1.1, 1.1), c, C.Trunk, decor())
	P(m, Vector3.new(0.12, 0.85, 0.85), c * CFrame.new(len / 2 + 0.03, 0, 0), C.Wood, decor())
	P(m, Vector3.new(0.12, 0.85, 0.85), c * CFrame.new(-len / 2 - 0.03, 0, 0), C.Wood, decor())
	P(m, Vector3.new(len * 0.5, 0.2, 0.9), c * CFrame.new(rng:NextNumber(-0.5, 0.5), 0.6, 0), C.Moss, decor())
end

-- A little heap of autumn leaves (or petals: pass the colours).
function Kit.leafPile(parent: Instance, cf: CFrame, rng: Random, colors: { Color3 }?)
	local m = M(parent, "Leaves")
	local cols = colors or { C.Orange, C.Yellow, C.RedDark, C.Gold }
	for k = 1, rng:NextInteger(5, 8) do
		local c = spin(cf, rng) * CFrame.new(rng:NextNumber(-1, 1), 0.06 + k * 0.05, rng:NextNumber(-1, 1))
		P(m, Vector3.new(0.9, 0.08, 0.6), c * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)), pick(rng, cols), decor())
	end
end

-- Soft snow humps (balls half in the ground).
function Kit.snowMound(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "SnowMound")
	for k = 1, rng:NextInteger(2, 3) do
		local d = if k == 1 then rng:NextNumber(3, 4.5) else rng:NextNumber(1.8, 2.8)
		local c = cf * CFrame.new(if k == 1 then 0 else rng:NextNumber(-1.8, 1.8), -d * 0.22, if k == 1 then 0 else rng:NextNumber(-1.8, 1.8))
		B(m, d, c.Position, if k == 1 then C.Snow else C.SnowShade, decor())
	end
end

-- A young snowy pine (a small stack of green tiers with snow on each).
function Kit.sapling(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Sapling")
	local s = rng:NextNumber(0.8, 1.3)
	local c = spin(cf, rng)
	P(m, Vector3.new(0.4, 0.8, 0.4) * s, c * CFrame.new(0, 0.4 * s, 0), C.Trunk, decor())
	local y = 0.8 * s
	for i, w in { 2.2, 1.6, 1.0 } do
		local h = 0.75 * s
		P(m, Vector3.new(w, h, w) * s, c * CFrame.new(0, y + h / 2, 0), if i % 2 == 0 then C.Leaf else C.LeafDark, decor())
		P(m, Vector3.new(w * 0.92, 0.18, w * 0.92) * s, c * CFrame.new(0, y + h + 0.05, 0), C.Snow, decor())
		y += h
	end
end

-- A frozen puddle.
function Kit.icePatch(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "IcePatch")
	local d = rng:NextNumber(3.5, 6)
	D(m, cf * CFrame.new(0, 0.06, 0), d, 0.12, C.Ice, { decor = true, shadow = false, t = 0.35, refl = 0.25, mat = Enum.Material.Glass })
	D(m, cf * CFrame.new(rng:NextNumber(-0.6, 0.6), 0.1, rng:NextNumber(-0.6, 0.6)), d * 0.45, 0.06, C.WaterLight, { decor = true, shadow = false, t = 0.4 })
end

-- Old cobbles in the grass (market streets reaching into the grass).
function Kit.cobbles(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Cobbles")
	local base = spin(cf, rng)
	for ix = -1, 1 do
		for iz = -1, 1 do
			if rng:NextNumber() < 0.8 then
				local s = rng:NextNumber(1.2, 1.6)
				P(m, Vector3.new(s, 0.2, s * rng:NextNumber(0.8, 1)), base * CFrame.new(ix * 1.8 + rng:NextNumber(-0.2, 0.2), 0.08, iz * 1.8)
					* CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), pick(rng, { C.Rock, C.RockDark, C.Stone2 }), decor())
			end
		end
	end
end

-- A flower pot.
function Kit.flowerPot(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "FlowerPot")
	pole(m, cf, 1.6, 1.3, C.Brick, decor())
	D(m, cf * CFrame.new(0, 1.32, 0), 1.35, 0.08, C.Trunk, decor())
	for _ = 1, 3 do
		B(m, 0.6, (cf * CFrame.new(rng:NextNumber(-0.4, 0.4), 1.7 + rng:NextNumber(0, 0.4), rng:NextNumber(-0.4, 0.4))).Position,
			pick(rng, Kit.FlowerColors), decor())
	end
	B(m, 1.1, (cf * CFrame.new(0, 1.55, 0)).Position, C.Leaf2, decor())
end

-- A grain sack.
function Kit.sack(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Sack")
	local c = spin(cf, rng)
	P(m, Vector3.new(1.4, 1.5, 1.1), c * CFrame.new(0, 0.75, 0), hex("e2c48e"), decor())
	P(m, Vector3.new(0.8, 0.35, 0.6), c * CFrame.new(0, 1.65, 0), hex("cfae73"), decor())
	P(m, Vector3.new(0.9, 0.12, 0.7), c * CFrame.new(0, 1.5, 0), C.WoodDark, decor())
end

-- A few small crystals poking out of the ground.
function Kit.crystalBits(parent: Instance, cf: CFrame, rng: Random, color: Color3)
	local m = M(parent, "CrystalBits")
	for _ = 1, rng:NextInteger(2, 4) do
		local h = rng:NextNumber(0.8, 1.8)
		local c = spin(cf, rng) * CFrame.new(rng:NextNumber(-0.8, 0.8), h * 0.4, rng:NextNumber(-0.8, 0.8))
		P(m, Vector3.new(0.45, h, 0.45), c * CFrame.Angles(rng:NextNumber(-0.35, 0.35), 0.78, rng:NextNumber(-0.35, 0.35)), color,
			{ decor = true, shadow = false, mat = Enum.Material.Glass, t = 0.15 })
	end
end

-- A soft patch of darker / lighter grass (breaks up the checkerboard) with a tuft on it.
function Kit.grassPatch(parent: Instance, cf: CFrame, rng: Random, color: Color3?)
	local m = M(parent, "GrassPatch")
	local col = color or C.Grass2:Lerp(C.LeafDark, 0.35)
	for k = 1, rng:NextInteger(2, 3) do
		local w, d = rng:NextNumber(4, 7), rng:NextNumber(3, 6)
		P(m, Vector3.new(w, 0.1, d), spin(cf, rng) * CFrame.new(rng:NextNumber(-1.5, 1.5), 0.05 + k * 0.01, rng:NextNumber(-1.5, 1.5)),
			col:Lerp(C.Leaf2, rng:NextNumber(0, 0.25)), decor())
	end
	Kit.tuft(m, cf * CFrame.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)), rng, C.LeafDark)
end

-- Little flowers on stems.
function Kit.sprigs(parent: Instance, cf: CFrame, rng: Random)
	local m = M(parent, "Sprigs")
	for _ = 1, rng:NextInteger(2, 4) do
		local h = rng:NextNumber(1.2, 2.1)
		local c = cf * CFrame.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		P(m, Vector3.new(0.18, h, 0.18), c * CFrame.new(0, h / 2, 0), C.LeafDark, decor())
		B(m, 0.8, (c * CFrame.new(0, h + 0.15, 0)).Position, pick(rng, Kit.FlowerColors), decor())
	end
end

return Kit
