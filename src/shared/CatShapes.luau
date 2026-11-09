--!strict
-- The blocks of the 300 cat designs (V5h), made in Blender (art/blender/cats_*.py, approved sheets in
-- art/preview/cats_v1/) and exported by art/blender/cats_export.py into shared/CatShapeData/<Tier>. A design is
-- decoded the first time it is asked for and kept. shared/CatModel turns a shape into Roblox Parts.
-- Pure module: tested by tests/CatShapes.spec.luau.
--
--   local shape = CatShapes.get("Ginger Tabby")   -- nil for an unknown name
--   shape.parts[1] -> { bone = "LegFR", kind = "B", cf = CFrame, size = Vector3, color = 1, ... }
--
-- Units: Blender units = studs at size 1 (CatModel scales the model). Front = -Z, feet on y = 0.
-- kind: B box, S ball, E ellipsoid, C cylinder (axis X), K cone (axis X, radius size.Y / 2 at -X to r2 at +X),
-- W wedge (WedgePart), G gem (a turned box).

local CatDesigns = require(script.Parent.CatDesigns)

export type PartSpec = {
	bone: string,
	kind: string,
	cf: CFrame,
	size: Vector3,
	color: number, -- index into the palette
	studs: string?, -- "all" | "top"
	neon: boolean,
	transparency: number,
	r2: number, -- cone end radius
}

export type PaletteEntry = { color: Color3, role: string } -- role "f" fur, "p" pattern, "-" other

-- V5j effect pieces (Mythical / Secret), built by CatModel from the mesh library (shared/FxMeshData):
--   I an item (kind, at, s, colors[1], emit, out = the way its front faces), G ground glow, M magic circle,
--   R ring of arcs (colors), W radiant wheel behind (n rays), B Secret burst (r, top, colors)
export type FxPiece = {
	what: string,
	kind: string,
	at: Vector3,
	s: number,
	r: number,
	top: number,
	n: number,
	emit: number,
	out: Vector3,
	colors: { Color3 },
}

export type Shape = {
	name: string,
	tier: string,
	pivot: Vector3, -- the feet, under the middle of the body
	bones: { [string]: Vector3 }, -- bone -> joint position
	palette: { PaletteEntry },
	parts: { PartSpec },
	fx: { FxPiece },
}

type Raw = { name: string, pivot: string, bones: string, palette: string, parts: string, fx: string? }

local CatShapes = {}

CatShapes.Bones = { "Body", "Head", "Tail1", "Tail2", "LegFL", "LegFR", "LegBL", "LegBR", "WingL", "WingR", "Fx" }
CatShapes.Tiers = { "Basic", "Rare", "Epic", "Legendary", "Mythical", "Secret" }

local tierOf: { [string]: string } = {}
for _, tier in CatShapes.Tiers do
	for _, name in (CatDesigns :: any)[tier] do
		tierOf[name] = tier
	end
end

local cache: { [string]: Shape } = {}
local tierData: { [string]: { Raw } } = {}

local function vec(s: string): Vector3
	local x, y, z = string.match(s, "^(-?%d+),(-?%d+),(-?%d+)$")
	assert(x and y and z, `CatShapes: bad vector {s}`)
	return Vector3.new(tonumber(x) :: number / 100, tonumber(y) :: number / 100, tonumber(z) :: number / 100)
end

local function decode(raw: Raw, tier: string): Shape
	local bones = {}
	for bone, at in string.gmatch(raw.bones, "(%w+)=(%S+)") do
		bones[bone] = vec(at)
	end
	local palette = {}
	for hex, role in string.gmatch(raw.palette, "(%x%x%x%x%x%x)(%S)") do
		table.insert(palette, { color = Color3.fromHex(hex), role = role })
	end
	local parts = {}
	for line in string.gmatch(raw.parts, "[^\n]+") do
		local f = string.split(line, " ")
		local n = table.create(#f, 0)
		for i = 3, #f do
			n[i] = tonumber(f[i]) or 0
		end
		local cf = CFrame.new(n[3] / 100, n[4] / 100, n[5] / 100)
		if #f >= 13 then
			cf *= CFrame.Angles(math.rad(n[11]), math.rad(n[12]), math.rad(n[13]))
		end
		local flags = f[10]
		local alpha = string.match(flags, "a(%d)")
		local r2 = string.match(flags, "r(%d+)")
		table.insert(parts, {
			bone = CatShapes.Bones[(tonumber(f[1]) :: number) + 1],
			kind = f[2],
			cf = cf,
			size = Vector3.new(n[6] / 100, n[7] / 100, n[8] / 100),
			color = n[9] + 1,
			studs = if string.find(flags, "s", 1, true) then "all" elseif string.find(flags, "t", 1, true) then "top" else nil,
			neon = string.find(flags, "n", 1, true) ~= nil,
			transparency = if alpha then (tonumber(alpha) :: number) / 10 else 0,
			r2 = if r2 then (tonumber(r2) :: number) / 100 else 0,
		})
	end
	local fx = {}
	for line in string.gmatch(raw.fx or "", "[^\n]+") do
		local f = string.split(line, " ")
		local what = f[1]
		local function num(i: number): number
			return (tonumber(f[i]) or 0) / 100
		end
		local function colors(text: string?): { Color3 }
			local out = {}
			for hex in string.gmatch(text or "", "%x%x%x%x%x%x") do
				table.insert(out, Color3.fromHex(hex))
			end
			return out
		end
		local piece: FxPiece = {
			what = what,
			kind = "",
			at = Vector3.zero,
			s = 1,
			r = 0,
			top = 0,
			n = 0,
			emit = 0,
			out = Vector3.new(0, 0, -1),
			colors = {},
		}
		if what == "I" then
			piece.kind = f[2]
			piece.at = Vector3.new(num(3), num(4), num(5))
			piece.s = num(6)
			piece.colors = colors(f[7])
			piece.emit = num(8)
			piece.out = Vector3.new(num(9), 0, num(10))
		else
			piece.at = Vector3.new(num(2), num(3), num(4))
			piece.r = num(5)
			if what == "W" then
				piece.n = tonumber(f[6]) or 12
				piece.colors = colors(f[7])
			elseif what == "B" then
				piece.top = num(6)
				piece.colors = colors(f[7])
			else
				piece.colors = colors(f[6])
			end
		end
		table.insert(fx, piece)
	end
	return { name = raw.name, tier = tier, pivot = vec(raw.pivot), bones = bones, palette = palette, parts = parts, fx = fx }
end

-- The tier key of a design ("Basic" .. "Secret"), nil when unknown.
function CatShapes.tierOf(name: string): string?
	return tierOf[name]
end

function CatShapes.get(name: string): Shape?
	local hit = cache[name]
	if hit then
		return hit
	end
	local tier = tierOf[name]
	if not tier then
		return nil
	end
	local list = tierData[tier]
	if not list then
		list = require(script.Parent.CatShapeData[tier]) :: any
		tierData[tier] = list
	end
	for _, raw in list do
		if raw.name == name then
			local shape = decode(raw, tier)
			cache[name] = shape
			return shape
		end
	end
	return nil
end

return CatShapes
