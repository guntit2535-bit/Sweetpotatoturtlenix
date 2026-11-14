--!strict
-- X4 (revision 4 item 11): real water as deep as a player is tall. Every creek and waterfall pool that is not frozen
-- becomes Terrain water about 5.6 studs deep in a trench cut through the ground tiles (GeometryService subtract), on a
-- sand bed; the old flat glass water, its dark bed and the pools' sand rims go to ServerStorage.MapBackup_X4 (delete
-- that folder once approved). The banks, stones, reeds, lily pads, stepping stones and bridges stay. Frozen water
-- (Snow Mountain) keeps its ice. Edit-time only, run from the Command Bar / Studio MCP, a zone at a time:
--   require(game.ServerScriptService.Server.MapTools:Clone().Water).zone(1)   -- 1-4; .look() sets the water colour

local GeometryService = game:GetService("GeometryService")
local ServerStorage = game:GetService("ServerStorage")

local Water = {}

local TOP = -0.3 -- water surface (the ground's top is 0)
local DEPTH = 5.6
local DEEP = Color3.fromHex("2a6f9c")
local SAND = Color3.fromHex("f3e2b5")

local function near(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.05
end

local function backupFolder(): Folder
	local f = ServerStorage:FindFirstChild("MapBackup_X4")
	if not f then
		local new = Instance.new("Folder")
		new.Name = "MapBackup_X4"
		new.Parent = ServerStorage
		f = new
	end
	return f :: Folder
end

-- the flat water surfaces of a creek / waterfall model (not the falling sheet)
local function surfaces(model: Model): { BasePart }
	local out = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Material == Enum.Material.Glass and p.Position.Y < 1.5 then
			local thin = if p.Shape == Enum.PartType.Cylinder then p.Size.X < 0.6 else p.Size.Y < 0.6
			if thin then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function yawOf(p: BasePart): number
	local _, yaw = p.CFrame:ToEulerAnglesYXZ()
	return yaw
end

-- a cutter that goes from below the trench to above the ground, over one water surface
local function cutter(p: BasePart): Part
	local c = Instance.new("Part")
	c.Anchored = true
	c.CanCollide = false
	c.Transparency = 1
	if p.Shape == Enum.PartType.Cylinder then
		c.Shape = Enum.PartType.Cylinder
		c.Size = Vector3.new(8, p.Size.Y + 1, p.Size.Z + 1)
		c.CFrame = CFrame.new(p.Position.X, -3, p.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	else
		c.Size = Vector3.new(p.Size.X + 0.6, 8, p.Size.Z + 1)
		c.CFrame = CFrame.new(p.Position.X, -3, p.Position.Z) * CFrame.Angles(0, yawOf(p), 0)
	end
	c.Parent = workspace
	return c
end

local function carve(cutters: { Part }): number
	local map = workspace:FindFirstChild("Map")
	local ground = map and map:FindFirstChild("Ground")
	if not ground then
		return 0
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { ground }
	local byTile: { [BasePart]: { Part } } = {}
	for _, c in cutters do
		for _, t in workspace:GetPartsInPart(c, params) do
			byTile[t] = byTile[t] or {}
			table.insert(byTile[t], c)
		end
	end
	local n = 0
	for tile, list in byTile do
		local ok, res = pcall(function()
			return GeometryService:SubtractAsync(tile, list, {
				CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
				RenderFidelity = Enum.RenderFidelity.Precise,
				SplitApart = false,
			})
		end)
		if ok and res and res[1] then
			local u = res[1] :: BasePart
			u.Name = tile.Name
			u.Anchored = true
			u.Color = tile.Color
			u.Material = tile.Material
			if u:IsA("PartOperation") then
				u.UsePartColor = true
			end
			for _, child in tile:GetChildren() do
				child:Clone().Parent = u
			end
			for k, v in tile:GetAttributes() do
				u:SetAttribute(k, v)
			end
			u:SetAttribute("X4Cut", true)
			u.Parent = tile.Parent
			tile.Parent = backupFolder()
			n += 1
		else
			warn(`[Sweetpotato] Water: could not cut {tile:GetFullName()}: {res}`)
		end
	end
	return n
end

local function fill(p: BasePart)
	local T = workspace.Terrain
	local mid = TOP - DEPTH / 2
	if p.Shape == Enum.PartType.Cylinder then
		local r = p.Size.Y / 2
		T:FillCylinder(CFrame.new(p.Position.X, -4.6, p.Position.Z), 5, r + 3, Enum.Material.Sand)
		local cf = CFrame.new(p.Position.X, mid, p.Position.Z)
		T:FillCylinder(cf, DEPTH, r, Enum.Material.Air) -- water does not replace solid voxels
		T:FillCylinder(cf, DEPTH, r, Enum.Material.Water)
	else
		local turn = CFrame.Angles(0, yawOf(p), 0)
		T:FillBlock(CFrame.new(p.Position.X, -4.6, p.Position.Z) * turn, Vector3.new(p.Size.X + 2, 5, p.Size.Z + 6), Enum.Material.Sand)
		local cf = CFrame.new(p.Position.X, mid, p.Position.Z) * turn
		T:FillBlock(cf, Vector3.new(p.Size.X + 0.6, DEPTH, p.Size.Z), Enum.Material.Air)
		T:FillBlock(cf, Vector3.new(p.Size.X + 0.6, DEPTH, p.Size.Z), Enum.Material.Water)
	end
end

function Water.model(model: Model): boolean
	if model:GetAttribute("Frozen") == true or model:GetAttribute("X4Water") == true then
		return false
	end
	local list = surfaces(model)
	if #list == 0 then
		return false
	end
	local cutters = {}
	for _, p in list do
		table.insert(cutters, cutter(p))
	end
	carve(cutters)
	for _, c in cutters do
		c:Destroy()
	end
	for _, p in list do
		fill(p)
	end
	-- the old water, its dark bed, the pools' sand rims and the flow beams go to the backup
	local backup = backupFolder()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local rim = p.Shape == Enum.PartType.Cylinder and p.Size.X < 0.5 and p.Size.Y > 13 and near(p.Color, SAND)
			if table.find(list, p) or near(p.Color, DEEP) or rim or p.Name == "Flow" then
				p.Parent = backup
			end
		end
	end
	model:SetAttribute("X4Water", true)
	return true
end

function Water.zone(i: number): number
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild(`Zone{i}`)
	if not zone then
		return 0
	end
	local n = 0
	for _, d in zone:GetDescendants() do
		if d:IsA("Model") and (d.Name == "Creek" or d.Name == "Waterfall") then
			if Water.model(d) then
				n += 1
				task.wait()
			end
		end
	end
	Water.look()
	print(`[Sweetpotato] Water: zone {i}: {n} creeks / pools turned to deep water`)
	return n
end

function Water.look()
	local T = workspace.Terrain
	T.WaterColor = Color3.fromHex("2fb7f5")
	T.WaterTransparency = 0.35
	T.WaterReflectance = 0.5
	T.WaterWaveSize = 0.08
	T.WaterWaveSpeed = 6
end

return Water
