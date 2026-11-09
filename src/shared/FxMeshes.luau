--!strict
-- The V5j effect mesh library (art/blender/fx_export.py -> art/export/Effects.fbx), imported by the developer into
-- ReplicatedStorage.FxMeshes (a place folder, not Rojo): one MeshPart per layer, named like Fx_flame_1.
-- shared/FxMeshData says each layer's size, centre, tint and see-through at size 1.
--
--   FxMeshes.layers(kind) -> { Layer }?      the layers of an item kind (or GlowRing / MagicCircle / RingSeg / WheelRay)
--   FxMeshes.part(layer) -> MeshPart?         a fresh copy of a layer's mesh, nil until the meshes are imported
--   FxMeshes.offset(layer, scale) -> Vector3  where the layer's centre sits from the item's origin (the import turn,
--                                             Config.ItemModels.Flip, is applied like for the item meshes)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local FxMeshData = require(script.Parent.FxMeshData)

export type Layer = FxMeshData.Layer

local FxMeshes = {}

FxMeshes.BuiltRadius = FxMeshData.BuiltRadius

local cache: { [string]: MeshPart | false } = {}

local function source(name: string): MeshPart?
	local hit = cache[name]
	if hit ~= nil then
		return if hit then hit else nil
	end
	local folder = ReplicatedStorage:FindFirstChild("FxMeshes")
	local found = folder and folder:FindFirstChild(name, true)
	local part = if found and found:IsA("MeshPart") then found else nil
	if part or folder then
		cache[name] = part or false -- (no folder yet: ask again later)
	end
	return part
end

function FxMeshes.layers(kind: string): { Layer }?
	return FxMeshData.Kinds[kind]
end

function FxMeshes.ready(): boolean
	return source("Fx_GlowRing_1") ~= nil
end

function FxMeshes.part(layer: Layer): MeshPart?
	local original = source(layer.mesh)
	if not original then
		return nil
	end
	local p = original:Clone()
	p.TextureID = ""
	for _, d in p:GetChildren() do
		if d:IsA("SurfaceAppearance") then
			d:Destroy() -- the game colours the layer itself
		end
	end
	return p
end

function FxMeshes.offset(layer: Layer, scale: Vector3): Vector3
	local f = if (Config.ItemModels :: any).Flip then -1 else 1
	local c = layer.center
	return Vector3.new(c.X * f * scale.X, c.Y * scale.Y, c.Z * f * scale.Z)
end

-- A layer's colour from the piece's colour: "main", "light:k" (lightened by k) or "fixed:rrggbb".
function FxMeshes.tint(layer: Layer, color: Color3): Color3
	local t = layer.tint
	if t == "main" then
		return color
	end
	local k = string.match(t, "^light:([%d%.]+)$")
	if k then
		return color:Lerp(Color3.new(1, 1, 1), tonumber(k) or 0.5)
	end
	local hex = string.match(t, "^fixed:(%x+)$")
	return if hex then Color3.fromHex(hex) else color
end

return FxMeshes
