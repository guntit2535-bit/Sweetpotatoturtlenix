--!strict
-- Item meshes made in Blender (task R5, art/blender) and imported by the developer into
-- ReplicatedStorage.ItemModels (a place folder, not Rojo). Each item is one MeshPart named by its id, plus
-- <id>_Glass for see-through parts and, for crates, <id>_Lid (+ <id>_Lid_Glass).
--
--   ItemModels.has(id) -> boolean
--   ItemModels.build(id, scale, withLid?) -> Model?   a fresh copy: an invisible "Root" part at the item's
--        origin (PrimaryPart; floor centre of gym pieces / crates / treats / shoes, the hand grip of rods / the
--        bat / a dumbbell) with the meshes welded on. The item's front faces Root's LookVector (-Z). Nothing
--        collides, touches or is queried; parts are massless and unanchored (anchor Root or weld it).
--        nil when the mesh is not imported, so callers keep their old part-built look.
--   ItemModels.point(scale, x, y, z) -> Vector3   a point of the Blender model (studs, Blender axes:
--        x right, y back, z up from the item origin) in Root space, e.g. a rod's tip
--
-- Checked in Studio 2026-11-08: the 3D Importer turned the meshes 180 degrees about Y, so a mesh's own
-- X and Z are the manifest's negated (Config.ItemModels.Flip).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local ItemModelData = require(script.Parent.ItemModelData)

local ItemModels = {}

local cache: { [string]: MeshPart | false } = {}

local function source(id: string): MeshPart?
	local hit = cache[id]
	if hit ~= nil then
		return if hit then hit else nil
	end
	local folder = ReplicatedStorage:FindFirstChild("ItemModels")
	local found = folder and folder:FindFirstChild(id, true)
	local part = if found and found:IsA("MeshPart") then found else nil
	if part or folder then
		cache[id] = part or false -- (no folder yet: ask again later)
	end
	return part
end

function ItemModels.has(id: string): boolean
	return source(id) ~= nil and ItemModelData[id] ~= nil
end

local function flip(): number
	return if (Config.ItemModels :: any).Flip then -1 else 1
end

-- Blender point (x right, y back, z up) of item `id` -> Root space (Roblox: X, Y up, front -Z)
function ItemModels.point(scale: number, x: number, y: number, z: number): Vector3
	local f = flip()
	-- manifest axes are (x, z, -y); the import turn negates X and Z
	return Vector3.new(x * f, z, -y * f) * scale
end

local function place(root: BasePart, model: Model, id: string, scale: number, name: string?)
	local original = source(id)
	local entry = ItemModelData[id]
	if not original or not entry then
		return nil
	end
	local f = flip()
	local part = original:Clone()
	part.Name = name or id
	part.Size = entry.size * scale
	part.CFrame = root.CFrame * CFrame.new(entry.center.X * f * scale, entry.center.Y * scale, entry.center.Z * f * scale)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = true
	if string.find(id, "_Glass$") then
		part.Transparency = (Config.ItemModels :: any).GlassTransparency
	end
	part.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = part
	w.Parent = part
	return part
end

function ItemModels.build(id: string, scale: number, withLid: boolean?): Model?
	if not ItemModels.has(id) then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = id
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Massless = true
	root.Anchored = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	place(root, model, id, scale, "Mesh")
	if source(id .. "_Glass") then
		place(root, model, id .. "_Glass", scale, "Glass")
	end
	if withLid ~= false and source(id .. "_Lid") then
		place(root, model, id .. "_Lid", scale, "Lid")
		if source(id .. "_Lid_Glass") then
			place(root, model, id .. "_Lid_Glass", scale, "LidGlass")
		end
	end
	return model
end

return ItemModels
