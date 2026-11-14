--!strict
-- X4 water, second design (developer 2026-11-15: the first creeks "look messy, like geometry shapes"): every creek and
-- pool follows the world's 4-stud grid, which is also Terrain's grid and divides the 24-stud ground tiles, so the
-- water edges are straight pixel steps instead of angled cuts. Per creek / pool:
--   * the 4 x 4 cells under its old flat water become water 8 studs deep (Terrain, surface flush with the ground at
--     y 0), on a sand bed, with sand walls under the ground around it
--   * the ground tiles are cut along the same cells (axis-aligned boxes, one per row run)
--   * the ring of cells round the water gets a shore: style "sand" (a flat sand plate) or "stone" (a raised stone
--     border, two greys); shore plates are named "Ground" so MapTools/Pixel gives them the pixel + stud look
--   * the old glass water, dark bed, sand banks, pool rims and flow beams go to ServerStorage.MapBackup_X4
-- Edit-time only (Command Bar / Studio MCP):
--   local T = game.ServerScriptService.Server.MapTools:Clone()
--   require(T.WaterGrid).reset()            -- fresh ground tiles and no terrain (before a rebuild of the zones)
--   require(T.WaterGrid).zone(1, "sand")     -- every creek / pool of a zone; then Pixel.apply(<id>) again

local GeometryService = game:GetService("GeometryService")
local ServerStorage = game:GetService("ServerStorage")

local WaterGrid = {}

local CELL = 4
local WATER_BOTTOM = -8
local BED = -12
local DEEP = Color3.fromHex("2a6f9c")
local BANK = Color3.fromHex("ead9a8")
local SHORE_SAND = Color3.fromHex("f0dfae")
local SNOW = Color3.fromHex("f7fbff") -- MapKit's snow banks and the frozen bed (C.Snow, C.SnowShade)
local SNOW_SHADE = Color3.fromHex("dcecfa")
local STONES = { Color3.fromHex("b9c1cf"), Color3.fromHex("a3adbd") }

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

local function key(i: number, k: number): string
	return `{i},{k}`
end

-- the flat water parts of a creek / waterfall model
local function surfaces(model: Model): { Part }
	local out = {}
	for _, p in model:GetDescendants() do
		if p:IsA("Part") and p.Material == Enum.Material.Glass and p.Position.Y < 1.5 then
			local thin = if p.Shape == Enum.PartType.Cylinder then p.Size.X < 0.6 else p.Size.Y < 0.6
			if thin then
				table.insert(out, p)
			end
		end
	end
	return out
end

-- the grid cells a water part covers (sampled every stud over its footprint)
local function cellsOf(p: Part, cells: { [string]: { number } })
	local function mark(w: Vector3)
		local i, k = math.floor(w.X / CELL), math.floor(w.Z / CELL)
		cells[key(i, k)] = { i, k }
	end
	if p.Shape == Enum.PartType.Cylinder then
		local r = p.Size.Y / 2
		for x = -r, r, 1 do
			for z = -r, r, 1 do
				if x * x + z * z <= r * r then
					mark(p.Position + Vector3.new(x, 0, z))
				end
			end
		end
	else
		local hx, hz = p.Size.X / 2, p.Size.Z / 2
		for x = -hx, hx, 1 do
			for z = -hz, hz, 1 do
				mark(p.CFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
			end
		end
	end
end

local function carve(cells: { [string]: { number } })
	local map = workspace:FindFirstChild("Map")
	local ground = map and map:FindFirstChild("Ground")
	if not ground then
		return
	end
	-- one box per run of cells along X in each row
	local rows: { [number]: { number } } = {}
	for _, c in cells do
		rows[c[2]] = rows[c[2]] or {}
		table.insert(rows[c[2]], c[1])
	end
	local cutters: { Part } = {}
	for k, xs in rows do
		table.sort(xs)
		local start = xs[1]
		for n = 1, #xs do
			local last = n == #xs or xs[n + 1] ~= xs[n] + 1
			if last then
				local len = xs[n] - start + 1
				local c = Instance.new("Part")
				c.Anchored = true
				c.CanCollide = false
				c.Transparency = 1
				c.Size = Vector3.new(len * CELL, 12, CELL)
				c.CFrame = CFrame.new((start + len / 2) * CELL, -4, (k + 0.5) * CELL)
				c.Parent = workspace
				table.insert(cutters, c)
				if n < #xs then
					start = xs[n + 1]
				end
			end
		end
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
			for kk, v in tile:GetAttributes() do
				u:SetAttribute(kk, v)
			end
			u.Parent = tile.Parent
			tile.Parent = backupFolder()
		else
			warn(`[Sweetpotato] WaterGrid: could not cut {tile:GetFullName()}: {res}`)
		end
	end
	for _, c in cutters do
		c:Destroy()
	end
end

local function box(i: number, k: number, y0: number, y1: number): (CFrame, Vector3)
	return CFrame.new((i + 0.5) * CELL, (y0 + y1) / 2, (k + 0.5) * CELL), Vector3.new(CELL, y1 - y0, CELL)
end

local function shore(parent: Instance, ring: { [string]: { number } }, style: string)
	local f = Instance.new("Folder")
	f.Name = "Shore"
	f.Parent = parent
	for _, c in ring do
		local p = Instance.new("Part")
		p.Name = "Ground" -- (MapTools/Pixel puts the pixel + stud look on it)
		p.Anchored = true
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if style == "stone" then
			p.Size = Vector3.new(CELL, 0.8, CELL)
			p.Position = Vector3.new((c[1] + 0.5) * CELL, 0.4, (c[2] + 0.5) * CELL)
			p.Color = STONES[(c[1] + c[2]) % 2 + 1]
		else
			p.Size = Vector3.new(CELL, 0.12, CELL)
			p.Position = Vector3.new((c[1] + 0.5) * CELL, 0.06, (c[2] + 0.5) * CELL)
			p.Color = SHORE_SAND
			p.CanCollide = false
		end
		p.Parent = f
	end
end

-- One creek / waterfall pool (frozen ones become ice). style "sand" | "stone" (developer 2026-11-15: "B ขอบหิน")
function WaterGrid.model(model: Model, style: string): boolean
	if model:GetAttribute("GridWater") == true then
		return false
	end
	-- Snow Mountain's frozen creeks: the same grid, solid ice flush with the ground instead of water
	local frozen = model:GetAttribute("Frozen") == true
	local list = surfaces(model)
	if #list == 0 then
		return false
	end
	local cells: { [string]: { number } } = {}
	for _, p in list do
		cellsOf(p, cells)
	end
	-- the ring of cells round the water (8 neighbours)
	local ring: { [string]: { number } } = {}
	for _, c in cells do
		for di = -1, 1 do
			for dk = -1, 1 do
				local kk = key(c[1] + di, c[2] + dk)
				if not cells[kk] then
					ring[kk] = { c[1] + di, c[2] + dk }
				end
			end
		end
	end
	carve(cells)
	local T = workspace.Terrain
	for _, c in ring do
		local cf, size = box(c[1], c[2], BED, -2) -- the trench walls under the ground
		T:FillBlock(cf, size, Enum.Material.Sand)
	end
	for _, c in cells do
		local cf, size = box(c[1], c[2], BED, WATER_BOTTOM)
		T:FillBlock(cf, size, Enum.Material.Sand)
		cf, size = box(c[1], c[2], WATER_BOTTOM, 0)
		T:FillBlock(cf, size, Enum.Material.Air) -- water does not replace solid voxels
		T:FillBlock(cf, size, if frozen then Enum.Material.Glacier else Enum.Material.Water)
	end
	shore(model, ring, style)
	-- the old water and its edges go to the backup (the bridge, stones, reeds and lily pads stay)
	local backup = backupFolder()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Parent and p.Parent.Name ~= "Shore" then
			-- the sand bank strips and the pools' round sand rims (flat cylinders)
			local flat = p:IsA("Part") and (p.Size.Y < 0.5 or (p.Shape == Enum.PartType.Cylinder and p.Size.X < 0.5))
			local bank = flat and (near(p.Color, BANK) or (frozen and (near(p.Color, SNOW) or near(p.Color, SNOW_SHADE))))
			if table.find(list, p :: any) or near(p.Color, DEEP) or bank or p.Name == "Flow" then
				p.Parent = backup
			end
		end
	end
	model:SetAttribute("GridWater", true)
	return true
end

function WaterGrid.zone(i: number, style: string): number
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild(`Zone{i}`)
	if not zone then
		return 0
	end
	local n = 0
	for _, d in zone:GetDescendants() do
		if d:IsA("Model") and (d.Name == "Creek" or d.Name == "Waterfall") then
			if WaterGrid.model(d, style) then
				n += 1
				task.wait()
			end
		end
	end
	WaterGrid.look()
	print(`[Sweetpotato] WaterGrid: zone {i}: {n} creeks / pools on the grid ({style} shore)`)
	return n
end

-- Fresh ground tiles (no cuts) and no terrain: the start for a rebuild of the water.
function WaterGrid.reset()
	workspace.Terrain:Clear()
	local Build = require(script.Parent.BuildMap) :: any
	Build.ground()
	Build.groundGaps()
end

function WaterGrid.look()
	local T = workspace.Terrain
	T.WaterColor = Color3.fromHex("2fb7f5")
	T.WaterTransparency = 0.35
	T.WaterReflectance = 0.45
	T.WaterWaveSize = 0.05
	T.WaterWaveSpeed = 6
	T:SetMaterialColor(Enum.Material.Sand, BANK)
	T:SetMaterialColor(Enum.Material.Glacier, Color3.fromHex("a9e4ff")) -- the frozen creeks
end

return WaterGrid
