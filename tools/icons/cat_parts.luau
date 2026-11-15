--!strict
-- Hotbar icons (developer 2026-11-15: the cat's slot in the hotbar shows the real cat). Step 1 of 3:
-- writes every cat's blocks, with this cat's own colours, to art/export/CatIcons/parts.json, for
-- art/blender/cat_icons.py (step 2: renders art/export/CatIcons/<id>.png) and tools/icons/upload.luau (step 3).
-- Same data as the game: shared/Cats (400 cats: 300 designs + tinted variants) and shared/CatShapes; the tint is
-- CatModel.tinted (copied here: CatModel itself builds Instances). Effect pieces (Mythical / Secret) are left out.
--
--   lune run tools/icons/cat_parts.luau

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Shared = require("../../tests/lib/Shared")
local Cats = Shared.require("Cats")
local CatShapes = Shared.require("CatShapes")

local Color3 = roblox.Color3

-- = CatModel.tinted
local function tinted(c: any, target: any): any
	local _, s, v = c:ToHSV()
	local th, ts, tv = target:ToHSV()
	return Color3.fromHSV(th, math.clamp(s * 0.5 + ts * 0.6, 0, 0.9), math.clamp(v * 0.75 + tv * 0.25, 0.42, 1))
end

local function r3(n: number): number
	return math.round(n * 1000) / 1000
end

local out = {}
for _, cat in Cats.List do
	local shape = CatShapes.get(cat.Look.design)
	if not shape then
		error(`no shape for {cat.Id} {cat.Look.design}`)
	end
	local target = if cat.Look.tint then Color3.fromHex(cat.Look.tint) else nil
	local colors = {}
	for i, p in shape.palette do
		local c = p.color
		if target and p.role ~= "-" then
			c = tinted(c, target)
		end
		colors[i] = c:ToHex()
	end
	local parts = {}
	for _, spec in shape.parts do
		if spec.bone == "Fx" then
			continue
		end
		local cf = spec.cf
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
		table.insert(parts, {
			k = spec.kind,
			p = { r3(x), r3(y), r3(z) },
			r = { r3(r00), r3(r01), r3(r02), r3(r10), r3(r11), r3(r12), r3(r20), r3(r21), r3(r22) },
			s = { r3(spec.size.X), r3(spec.size.Y), r3(spec.size.Z) },
			c = colors[spec.color] or "ffffff",
			n = spec.neon,
			t = spec.transparency,
			r2 = spec.r2,
		})
	end
	table.insert(out, { id = cat.Id, name = cat.Name, tier = cat.Tier, parts = parts })
end

fs.writeDir("art/export/CatIcons")
fs.writeFile("art/export/CatIcons/parts.json", serde.encode("json", out, false))
print(`{#out} cats -> art/export/CatIcons/parts.json`)
