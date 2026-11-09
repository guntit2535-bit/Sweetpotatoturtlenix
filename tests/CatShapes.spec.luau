--!strict
-- The 300 block-cat designs decode into parts on known bones (V5h). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local CatShapes = Shared.require("CatShapes")
local CatDesigns = Shared.require("CatDesigns")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL CatShapes: {message}`)
	end
end

local KINDS = { B = true, S = true, E = true, C = true, K = true, W = true, G = true }
local total, most = 0, 0
for _, tier in CatShapes.Tiers do
	for _, name in CatDesigns[tier] do
		local shape = CatShapes.get(name)
		check(shape ~= nil, `{name} has blocks`)
		if not shape then
			continue
		end
		check(shape.tier == tier and CatShapes.tierOf(name) == tier, `{name} tier`)
		check(shape.bones.Body ~= nil and shape.bones.Head ~= nil, `{name} has Body and Head bones`)
		check(#shape.parts >= 20, `{name}: {#shape.parts} parts`)
		check(#shape.parts <= 140, `{name}: {#shape.parts} parts is too many for phones`)
		check(#shape.palette >= 2, `{name} palette`)
		for _, p in shape.parts do
			check(shape.bones[p.bone] ~= nil, `{name}: part on missing bone {p.bone}`)
			check(KINDS[p.kind] == true, `{name}: kind {p.kind}`)
			check(shape.palette[p.color] ~= nil, `{name}: colour {p.color}`)
			check(p.size.X > 0 and p.size.Y > 0 and p.size.Z > 0, `{name}: part size`)
		end
		-- Mythical / Secret cats carry their effect on the Fx bone
		if tier == "Mythical" or tier == "Secret" then
			check(shape.bones.Fx ~= nil, `{name} has an effect`)
		end
		total += #shape.parts
		most = math.max(most, #shape.parts)
	end
end
check(CatShapes.get("No Such Cat") == nil, "unknown design -> nil")

if failures > 0 then
	error(`CatShapes: {failures} failure(s)`)
end
print(`PASS CatShapes (300 designs, {total} parts, most {most})`)
