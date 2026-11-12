--!strict
-- Builds the whole 360 map in Workspace.Map from Config.World with the MapKit props (A2-A5, style A).
-- Each part can be rebuilt on its own (it clears what it built before). Command Bar / Studio MCP:
--   local B = require(game.ServerScriptService.Server.MapTools:Clone().BuildMap)
--   B.lighting() B.lobby() B.ground() B.roads() B.walls() B.zone(1) ... B.zone(4) B.sky()
-- or B.all(). Hiding spots go to Workspace.Map.HideSpots.Zone<i> as invisible "Spot" parts with the
-- attributes Zone / Kind and the CollectionService tag "HideSpot". Zone gates are "GateBarrier" parts
-- (attribute Zone = the zone behind the gate, tag "ZoneGate"); the game makes them solid later.
-- Edit-time only: the running game never requires this module.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- A clone, so the Command Bar's module cache never hands back an old Config after an edit.
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):Clone()) :: any
local Kit = require(script.Parent:WaitForChild("MapKit")) :: any

local World = Config.World
local C = Kit.Colors
local hex = Color3.fromHex
local TAU = math.pi * 2

local Build = {}

type Spot = { kind: string, pos: Vector3 }

----------------------------------------------------------------------------------------------------
-- helpers

local function mapRoot(): Folder
	local root = workspace:FindFirstChild("Map")
	if not root then
		local f = Instance.new("Folder")
		f.Name = "Map"
		f.Parent = workspace
		return f
	end
	return root :: Folder
end

local function freshFolder(parent: Instance, name: string): Folder
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function subFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f then
		return f :: Folder
	end
	local n = Instance.new("Folder")
	n.Name = name
	n.Parent = parent
	return n
end

-- Ground point at angle (degrees) and radius, facing the centre of the map.
local function polar(deg: number, r: number, y: number?): CFrame
	local a = math.rad(deg)
	local pos = Vector3.new(math.cos(a) * r, y or World.GroundY, math.sin(a) * r)
	return CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
end

local function roadAngles(): { number }
	local list = {}
	for k = 0, World.Roads.Count - 1 do
		table.insert(list, k * 360 / World.Roads.Count)
	end
	return list
end

-- Distance along the ring (studs) from angle deg at radius r to the nearest road.
local function roadDistance(deg: number, r: number): number
	local step = 360 / World.Roads.Count
	local d = deg % step
	d = math.min(d, step - d)
	return math.rad(d) * r
end

local function placeSpots(zone: number, spots: { Spot })
	local folder = freshFolder(subFolder(mapRoot(), "HideSpots"), `Zone{zone}`)
	table.sort(spots, function(a, b)
		return math.atan2(a.pos.Z, a.pos.X) < math.atan2(b.pos.Z, b.pos.X)
	end)
	local max = World.HideSpotsPerZone.Max
	local chosen = {}
	if #spots <= max then
		chosen = spots
	else
		local step = #spots / max
		for k = 1, max do
			table.insert(chosen, spots[math.floor((k - 1) * step) + 1])
		end
	end
	for i, s in chosen do
		local p = Instance.new("Part")
		p.Name = "Spot"
		p.Size = Vector3.new(2, 2, 2)
		p.CFrame = CFrame.new(s.pos)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p:SetAttribute("Zone", zone)
		p:SetAttribute("Kind", s.kind)
		p:SetAttribute("Index", i)
		CollectionService:AddTag(p, "HideSpot")
		p.Parent = folder
	end
	local kinds: { [string]: number } = {}
	for _, s in chosen do
		kinds[s.kind] = (kinds[s.kind] or 0) + 1
	end
	print(`[Sweetpotato] zone {zone}: {#chosen} hiding spots (of {#spots}) roof {kinds.roof or 0} bush {kinds.bush or 0} rock {kinds.rock or 0} bridge {kinds.bridge or 0}`)
	if #chosen < World.HideSpotsPerZone.Min then
		warn(`[Sweetpotato] zone {zone}: only {#chosen} hiding spots, need {World.HideSpotsPerZone.Min}`)
	end
end

local function add(spots: { Spot }, ...: any)
	for _, v in { ... } do
		if type(v) == "table" and v.kind then
			table.insert(spots, v :: Spot)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- lighting

function Build.lighting()
	Lighting.ClockTime = 14.3
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(120, 118, 132)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 162)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 222)
	Lighting.GlobalShadows = true
	local function effect(class: string, name: string): Instance
		local e = Lighting:FindFirstChildOfClass(class)
		if not e then
			e = Instance.new(class)
			e.Name = name
			e.Parent = Lighting
		end
		return e :: Instance
	end
	local grade = effect("ColorCorrectionEffect", "Grade") :: ColorCorrectionEffect
	grade.Saturation = 0.15
	grade.Contrast = 0.08
	grade.Brightness = 0.02
	grade.TintColor = Color3.fromRGB(255, 252, 246)
	local bloom = effect("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = 0.45
	bloom.Size = 20
	bloom.Threshold = 1.7
	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.Enabled = false
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays.Intensity = 0.04
	end
	local atm = effect("Atmosphere", "Atmosphere") :: Atmosphere
	atm.Density = 0.16
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(205, 230, 255)
	atm.Decay = Color3.fromRGB(150, 195, 235)
	atm.Glare = 0
	atm.Haze = 0.3
	workspace.FallenPartsDestroyHeight = -250
	print("[Sweetpotato] lighting set")
end

----------------------------------------------------------------------------------------------------
-- lobby

-- The 8 pens between the roads (Config.World.Pens). W7 (revision 3 item 15): can be run alone on a built map to
-- rebuild only the pens (e.g. after a size change):
--   require(game.ServerScriptService.Server.MapTools:Clone().BuildMap).pens()
-- It replaces Lobby.Pens and moves the lobby's flower beds that a bigger pen would cover out to FlowerAngle.
function Build.pens(lobby: Instance?)
	local f = lobby or mapRoot():FindFirstChild("Lobby") or error("Build.pens: Map.Lobby not found")
	local old = f:FindFirstChild("Pens")
	if old then
		old:Destroy()
	end
	local rng = Random.new(202)
	local pens = subFolder(f, "Pens")
	for i = 1, World.Pens.Count do
		local deg = (i - 0.5) * 360 / World.Pens.Count
		Kit.pen(pens, i, polar(deg, World.Pens.Ring), World.Pens.Width, World.Pens.Depth, Kit.RoofColors[i], rng)
	end
	if lobby == nil then
		-- flower beds beside a pen's back corners: out to FlowerAngle from the pen's centre line
		local step = 360 / World.Pens.Count
		local moved = 0
		for _, c in f:GetChildren() do
			if c:IsA("Model") and c.Name == "Flowers" then
				local p = c:GetPivot().Position
				local deg = math.deg(math.atan2(p.Z, p.X))
				local off = (deg % step) - step / 2 -- signed, from the nearest pen's centre line
				if math.abs(off) < World.Pens.FlowerAngle - 0.5 then
					local turn = (math.sign(off) * World.Pens.FlowerAngle - off)
					c:PivotTo(CFrame.Angles(0, -math.rad(turn), 0) * c:GetPivot())
					moved += 1
				end
			end
		end
		print(`[Sweetpotato] pens rebuilt ({World.Pens.Width} x {World.Pens.Depth}), {moved} flower beds moved`)
	end
end

function Build.lobby()
	local f = freshFolder(mapRoot(), "Lobby")
	local rng = Random.new(101)
	local plazaR = World.PlazaRadius
	Kit.disc(f, CFrame.new(0, 0.3, 0), plazaR * 2, 0.6, C.Stone, { name = "Plaza" })
	Kit.disc(f, CFrame.new(0, 0.33, 0), plazaR * 1.5, 0.62, hex("e9ebf1"), { decor = true })
	Kit.disc(f, CFrame.new(0, 0.36, 0), plazaR * 1.5 - 3, 0.64, C.Stone, { decor = true })
	Kit.fountain(f, CFrame.new(0, 0.6, 0), 1.5)
	-- pens between the roads
	Build.pens(f)
	-- safe-zone edge: a glowing ring with light posts
	local edge = subFolder(f, "SafeEdge")
	local r = World.LobbyRadius
	local segs = math.ceil(TAU * r / 8)
	for s = 0, segs - 1 do
		local deg = (s + 0.5) * 360 / segs
		Kit.part(edge, Vector3.new(TAU * r / segs + 0.2, 0.3, 1.4), polar(deg, r, 0.15), C.Yellow, { mat = Enum.Material.Neon, decor = true, shadow = false })
	end
	for s = 0, 23 do
		local deg = s * 15
		if roadDistance(deg, r) > 14 then
			local cf = polar(deg, r + 1.5)
			Kit.part(edge, Vector3.new(1.4, 3.4, 1.4), cf * CFrame.new(0, 1.7, 0), C.White)
			Kit.part(edge, Vector3.new(1.6, 1.2, 1.6), cf * CFrame.new(0, 4, 0), C.Lamp, { mat = Enum.Material.Neon, decor = true })
		end
	end
	-- trees, flowers and benches
	for i = 1, World.Pens.Count do
		local deg = (i - 0.5) * 360 / World.Pens.Count
		for _, side in { -1, 1 } do
			Kit.tree(f, polar(deg + side * 15, 136), rng)
			Kit.flowers(f, polar(deg + side * World.Pens.FlowerAngle, 128), rng, 5)
		end
		Kit.bench(f, polar(deg, plazaR + 5) * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, math.pi, 0))
	end
	for _, deg in roadAngles() do
		Kit.lamp(f, polar(deg + 13, plazaR - 3, 0.6), true)
	end
	-- one neutral spawn on the plaza until PenService spawns players at their pen
	local old = workspace:FindFirstChild("SpawnLocation")
	if old then
		old:Destroy()
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.CFrame = polar(0, 30, 0.55)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = f
	print(`[Sweetpotato] lobby built ({#f:GetDescendants()} instances)`)
end

----------------------------------------------------------------------------------------------------
-- ground: checkerboard tiles

local GROUND = {
	Lobby = { hex("a2ea72"), hex("7cd259") },
	{ hex("8ce060"), hex("5dbf45") },
	{ hex("e3d6bd"), hex("c9baa0") }, -- Town Market: paved squares (warm stone)
	{ hex("78d65b"), hex("4fb440") },
	{ C.Snow, hex("d0e4f6") },
}

local function zoneAt(r: number): number
	for i, z in World.Zones do
		if r < z.Outer then
			return i
		end
	end
	return #World.Zones
end

-- Does a 24-stud zone tile centred at radius r belong on the ground? The old rule (before revision 3) left long thin
-- holes: next to the lobby (its 20-stud tiles stop at r 150, the zone tiles started at r 133 by their centres)
-- and before the snow ledge (zone tiles stopped at r 858, the ledge starts at r 848). The new rule overlaps both:
-- zone tiles start 1.2 tiles inside the lobby edge (the lobby tiles sit 0.05 higher, so they win) and run on under
-- the snow ledge.
local function zoneTileWanted(r: number, old: boolean): boolean
	local T = World.Tile.Zones
	if old then
		return r <= World.Zones[4].Outer - T * 0.5 and r >= World.LobbyRadius - T * 0.7
	end
	return r <= World.Zones[4].Outer - 4 and r >= World.LobbyRadius - T * 1.2
end

function Build.ground()
	local f = freshFolder(mapRoot(), "Ground")
	local lobby = subFolder(f, "Lobby")
	local T = World.Tile.Lobby
	local n = math.ceil(World.LobbyRadius / T)
	for ix = -n, n do
		for iz = -n, n do
			local x, z = ix * T, iz * T
			if math.sqrt(x * x + z * z) < World.LobbyRadius then
				local c = GROUND.Lobby[(ix + iz) % 2 + 1]
				Kit.part(lobby, Vector3.new(T, 2, T), CFrame.new(x, -0.95, z), c, { shadow = false, name = "Tile" })
			end
		end
	end
	T = World.Tile.Zones
	local n2 = math.ceil((World.Zones[4].Outer - T * 0.5) / T) -- the row names of the first build
	for ix = -n2, n2 do
		local row = subFolder(f, `Row{ix + n2}`)
		for iz = -n2, n2 do
			local x, z = ix * T, iz * T
			if zoneTileWanted(math.sqrt(x * x + z * z), false) then
				local c = GROUND[zoneAt(math.sqrt(x * x + z * z))][(ix + iz) % 2 + 1]
				Kit.part(row, Vector3.new(T, 2, T), CFrame.new(x, -1, z), c, { shadow = false, name = "Tile" })
			end
		end
	end
	print(`[Sweetpotato] ground built ({#f:GetDescendants()} tiles)`)
end

-- W1 / revision 3 item 18: the place built before this fix has long thin holes where the lobby's 20-stud tiles
-- meet the zones' 24-stud tiles (16 spots at r ~142) and inside the snow ledge (24 spots at r ~847). Adds only
-- the zone tiles the old rule left out and the new rule wants; nothing else is touched. Run once:
--   require(game.ServerScriptService.Server.MapTools:Clone().BuildMap).groundGaps()
function Build.groundGaps()
	local f = mapRoot():FindFirstChild("Ground") or error("Build.groundGaps: Map.Ground not found")
	local T = World.Tile.Zones
	local have: { [string]: boolean } = {}
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Tile" and math.abs(d.Size.X - T) < 0.01 then
			have[`{math.round(d.Position.X / T)},{math.round(d.Position.Z / T)}`] = true
		end
	end
	local n2 = math.ceil((World.Zones[4].Outer - T * 0.5) / T) -- the row names of the first build
	local added = 0
	for ix = -n2, n2 do
		for iz = -n2, n2 do
			local x, z = ix * T, iz * T
			local r = math.sqrt(x * x + z * z)
			if zoneTileWanted(r, false) and not zoneTileWanted(r, true) and not have[`{ix},{iz}`] then
				local row = f:FindFirstChild(`Row{ix + n2}`) or subFolder(f, `Row{ix + n2}`)
				local c = GROUND[zoneAt(r)][(ix + iz) % 2 + 1]
				local p = Kit.part(row, Vector3.new(T, 2, T), CFrame.new(x, -1, z), c, { shadow = false, name = "Tile" })
				p:SetAttribute("GapFill", true)
				added += 1
			end
		end
	end
	print(`[Sweetpotato] ground gaps: {added} tiles added`)
	return added
end

----------------------------------------------------------------------------------------------------
-- roads

local ROAD = { hex("ddd5c4"), hex("e8d6ab"), hex("c4c3c9"), hex("dcc79f"), hex("c9dcef") }

function Build.roads()
	local f = freshFolder(mapRoot(), "Roads")
	local w = World.Roads.Width
	local spans = { { World.PlazaRadius - 1, World.LobbyRadius, ROAD[1] } }
	for i = 1, 4 do
		local z = World.Zones[i]
		local outer = if i == 4 then z.Outer - 6 else z.Outer
		table.insert(spans, { z.Inner, outer, ROAD[i + 1] })
	end
	for _, deg in roadAngles() do
		for _, s in spans do
			local r0, r1, c = s[1] :: number, s[2] :: number, s[3] :: Color3
			local mid = polar(deg, (r0 + r1) / 2, 0.15)
			Kit.part(f, Vector3.new(w, 0.3, r1 - r0), mid, c, { shadow = false, name = "Road" })
			for _, x in { -1, 1 } do
				Kit.part(f, Vector3.new(0.9, 0.45, r1 - r0), mid * CFrame.new(x * (w / 2 + 0.45), 0.08, 0), C.Stone2, { decor = true, shadow = false })
			end
		end
	end
	print("[Sweetpotato] roads built")
end

----------------------------------------------------------------------------------------------------
-- zone walls, gates and the snow cliff

local function gate(parent: Instance, cf: CFrame, zone: number, styleName: string)
	local m = Kit.model(parent, `Gate{zone}`)
	local gw = World.GateWidth
	if styleName == "torii" then
		local g = Kit.torii(m, cf)
		g.WorldPivot = cf
		g:ScaleTo(1.6)
	else
		local post, cap, beam = C.WoodDark, C.White, C.Wood
		if styleName == "stone" then
			post, cap, beam = C.Stone2, C.Stone, C.Stone2
		elseif styleName == "sky" then
			post, cap, beam = C.White, C.Gold, C.Gold
		end
		for _, x in { -1, 1 } do
			Kit.part(m, Vector3.new(3, 15, 3), cf * CFrame.new(x * (gw / 2 + 1.5), 7.5, 0), post)
			Kit.part(m, Vector3.new(3.6, 1, 3.6), cf * CFrame.new(x * (gw / 2 + 1.5), 15.5, 0), cap)
		end
		Kit.part(m, Vector3.new(gw + 7, 2, 3), cf * CFrame.new(0, 14, 0), beam)
		Kit.part(m, Vector3.new(gw - 6, 1.6, 0.6), cf * CFrame.new(0, 12.2, -1.6), cap, { decor = true })
	end
	local colors = { C.Leaf2, C.Orange, C.Pink, C.Ice, C.Purple }
	local barrier = Kit.part(m, Vector3.new(gw, 12, 0.6), cf * CFrame.new(0, 6, 0), colors[zone], {
		mat = Enum.Material.Neon,
		t = 0.65,
		decor = true,
		shadow = false,
		name = "GateBarrier",
	})
	barrier:SetAttribute("Zone", zone)
	CollectionService:AddTag(barrier, "ZoneGate")
end

local WALLS = {
	{ color = C.LeafDark, top = C.Leaf, h = 7, t = 5, gate = "wood" }, -- Backyard | Market: hedge
	{ color = C.Stone2, top = C.Stone, h = 6, t = 4, gate = "stone" }, -- Market | Forest: stone wall
	{ color = C.LeafDark, top = C.PinkLight, h = 7, t = 5, gate = "torii" }, -- Forest | Snow: blossom hedge
}

function Build.walls()
	local f = freshFolder(mapRoot(), "Walls")
	local gapHalf = World.GateWidth / 2 + 4
	for i, s in WALLS do
		local r = World.Zones[i].Outer
		local ring = subFolder(f, `Ring{i}`)
		local segs = math.ceil(TAU * r / 28)
		for k = 0, segs - 1 do
			local deg = (k + 0.5) * 360 / segs
			if roadDistance(deg, r) > gapHalf then
				local cf = polar(deg, r)
				local len = TAU * r / segs + 0.4
				Kit.part(ring, Vector3.new(len, s.h, s.t), cf * CFrame.new(0, s.h / 2, 0), s.color)
				Kit.part(ring, Vector3.new(len, 1, s.t + 0.6), cf * CFrame.new(0, s.h + 0.5, 0), s.top, { decor = true })
			end
		end
		for _, deg in roadAngles() do
			gate(ring, polar(deg, r), i + 1, s.gate)
		end
	end
	-- the snow ledge at the cliff edge to the Sky Islands
	local r = World.Zones[4].Outer
	local cliff = subFolder(f, "Cliff")
	local segs = math.ceil(TAU * r / 28)
	for k = 0, segs - 1 do
		local deg = (k + 0.5) * 360 / segs
		local len = TAU * r / segs + 0.6
		local open = roadDistance(deg, r) <= gapHalf
		local top = polar(deg, r - 6)
		if open then
			Kit.part(cliff, Vector3.new(len, 0.6, 32), top * CFrame.new(0, 0.3, 0), C.SnowShade, { shadow = false })
		else
			Kit.part(cliff, Vector3.new(len, 3, 32), top * CFrame.new(0, 1.5, 0), C.Snow)
		end
		Kit.part(cliff, Vector3.new(len + 0.4, 40, 12), polar(deg, r + 4) * CFrame.new(0, -20, 0), if k % 2 == 0 then C.Rock else C.RockDark)
	end
	for _, deg in roadAngles() do
		gate(cliff, polar(deg, r + 4), 5, "sky")
	end
	print("[Sweetpotato] walls, gates and cliff built")
end

----------------------------------------------------------------------------------------------------
-- zone clusters: each builds around cf (facing the lobby) and returns its hiding spots

type Cluster = (m: Instance, cf: CFrame, rng: Random) -> { Spot }

local function at(cf: CFrame, x: number, z: number, rot: number?): CFrame
	return cf * CFrame.new(x, 0, z) * CFrame.Angles(0, rot or 0, 0)
end

local CLUSTERS: { [number]: { Cluster } } = {}

CLUSTERS[1] = { -- Backyard
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.house(m, at(cf, 0, 6, rng:NextNumber(-0.25, 0.25)), rng)))
		Kit.fence(m, (cf * CFrame.new(-16, 0, -10)).Position, (cf * CFrame.new(-4, 0, -10)).Position)
		Kit.fence(m, (cf * CFrame.new(4, 0, -10)).Position, (cf * CFrame.new(16, 0, -10)).Position)
		add(spots, select(2, Kit.bush(m, at(cf, 16, -16), rng)))
		Kit.flowers(m, at(cf, -10, -14), rng)
		Kit.tree(m, at(cf, -18, 10), rng)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.creek(m, at(cf, 0, 0, math.pi / 2 + rng:NextNumber(-0.3, 0.3)), rng, "wood")))
		add(spots, select(2, Kit.rock(m, at(cf, -20, 8), rng)))
		add(spots, select(2, Kit.bush(m, at(cf, 18, 12), rng)))
		Kit.tree(m, at(cf, 22, -14), rng)
		Kit.flowers(m, at(cf, -16, -12), rng)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.house(m, at(cf, -6, 10, rng:NextNumber(-0.3, 0.3)), rng)))
		Kit.doghouse(m, at(cf, 10, 4, math.pi))
		Kit.clothesline(m, at(cf, 6, -10), rng)
		Kit.tree(m, at(cf, 18, 16), rng)
		add(spots, select(2, Kit.rock(m, at(cf, -20, -8), rng)))
		add(spots, select(2, Kit.bush(m, at(cf, -10, -14), rng)))
		Kit.flowers(m, at(cf, 18, -12), rng)
		return spots
	end,
}

local function paving(m: Instance, cf: CFrame, w: number, d: number)
	Kit.part(m, Vector3.new(w, 0.3, d), cf * CFrame.new(0, 0.15, 0), hex("e4ddcf"), { shadow = false })
	Kit.part(m, Vector3.new(w + 1.2, 0.25, d + 1.2), cf * CFrame.new(0, 0.12, 0), C.Stone2, { decor = true, shadow = false })
end

CLUSTERS[2] = { -- Town Market
	function(m, cf, rng)
		local spots = {}
		paving(m, cf, 40, 26)
		add(spots, select(2, Kit.shop(m, at(cf, 0, 18), rng)))
		Kit.stall(m, at(cf, -9, -4), rng)
		Kit.stall(m, at(cf, 9, -4), rng)
		Kit.barrel(m, at(cf, 17, 6))
		Kit.lamp(m, at(cf, -18, -10))
		add(spots, select(2, Kit.bush(m, at(cf, -16, 10), rng, C.LeafDark)))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		paving(m, cf, 34, 30)
		add(spots, select(2, Kit.shop(m, at(cf, 0, 6), rng)))
		Kit.barrel(m, at(cf, 11, -6))
		Kit.crate(m, at(cf, -11, -6), rng)
		Kit.lamp(m, at(cf, 14, -12))
		add(spots, select(2, Kit.bush(m, at(cf, -18, 12), rng, C.LeafDark)))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.creek(m, at(cf, 0, 0, math.pi / 2 + rng:NextNumber(-0.2, 0.2)), rng, "stone")))
		add(spots, select(2, Kit.rock(m, at(cf, 14, 10), rng)))
		add(spots, select(2, Kit.shop(m, at(cf, -16, 18), rng)))
		Kit.lamp(m, at(cf, 4, 12))
		Kit.flowers(m, at(cf, -14, -12), rng)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		paving(m, cf, 38, 38)
		Kit.fountain(m, at(cf, 0, 0), 0.75)
		for _, a in { 0, math.pi / 2, math.pi, math.pi * 1.5 } do
			Kit.bench(m, cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.3, -14))
		end
		add(spots, select(2, Kit.bush(m, at(cf, 22, 16), rng, C.LeafDark)))
		Kit.lamp(m, at(cf, -17, 17))
		return spots
	end,
}

CLUSTERS[3] = { -- Forest (garden)
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.pavilion(m, at(cf, 0, 6), C.Red, C.Navy, C.Gold, C.RedDark)))
		Kit.stoneLantern(m, at(cf, -8, -8))
		Kit.stoneLantern(m, at(cf, 8, -8))
		add(spots, select(2, Kit.bush(m, at(cf, -18, 4), rng)))
		Kit.blossom(m, at(cf, 18, 10), rng)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		for i = -1, 1 do
			Kit.torii(m, at(cf, 0, i * 12))
			Kit.part(m, Vector3.new(5, 0.4, 3.4), at(cf, rng:NextNumber(-0.6, 0.6), i * 12 - 5) * CFrame.new(0, 0.2, 0), C.Stone, { shadow = false })
			Kit.part(m, Vector3.new(5, 0.4, 3.4), at(cf, rng:NextNumber(-0.6, 0.6), i * 12 + 1) * CFrame.new(0, 0.2, 0), C.Stone, { shadow = false })
		end
		Kit.blossom(m, at(cf, -16, 0), rng)
		Kit.blossom(m, at(cf, 16, 8), rng)
		Kit.bamboo(m, at(cf, 18, -14), rng)
		add(spots, select(2, Kit.rock(m, at(cf, -16, -16), rng, "moss")))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.waterfall(m, at(cf, 0, 14), rng)))
		add(spots, select(2, Kit.creek(m, at(cf, 0, -14), rng, "red")))
		add(spots, select(2, Kit.rock(m, at(cf, -22, -2), rng, "moss")))
		Kit.bamboo(m, at(cf, 24, 4), rng)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		Kit.bamboo(m, at(cf, -10, 6), rng)
		Kit.bamboo(m, at(cf, 12, -8), rng)
		Kit.blossom(m, at(cf, 4, 12), rng)
		Kit.blossom(m, at(cf, -14, -10), rng)
		add(spots, select(2, Kit.bush(m, at(cf, 16, 10), rng)))
		add(spots, select(2, Kit.rock(m, at(cf, -2, -16), rng, "moss")))
		Kit.stoneLantern(m, at(cf, 0, -4))
		return spots
	end,
}

CLUSTERS[4] = { -- Snow Mountain
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.cabin(m, at(cf, 0, 6, rng:NextNumber(-0.3, 0.3)), rng)))
		Kit.pine(m, at(cf, -18, 10), rng, true)
		Kit.pine(m, at(cf, 18, 14), rng, true)
		Kit.snowman(m, at(cf, 12, -12, math.pi))
		Kit.lamp(m, at(cf, -10, -12))
		add(spots, select(2, Kit.bush(m, at(cf, -18, -8), rng, C.LeafDark, "snow")))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.creek(m, at(cf, 0, 0, math.pi / 2), rng, "wood", true)))
		Kit.crystals(m, at(cf, 16, 10), rng, C.Ice)
		add(spots, select(2, Kit.rock(m, at(cf, -18, 10), rng, "snow")))
		Kit.pine(m, at(cf, 20, -14), rng, true)
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		for _, p in { { -14, 8 }, { 0, 16 }, { 14, 6 }, { -4, -2 } } do
			Kit.pine(m, at(cf, p[1], p[2]), rng, true)
		end
		add(spots, select(2, Kit.bush(m, at(cf, 14, -12), rng, C.LeafDark, "berries")))
		add(spots, select(2, Kit.bush(m, at(cf, -16, -10), rng, C.LeafDark, "snow")))
		add(spots, select(2, Kit.rock(m, at(cf, 4, -16), rng, "snow")))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		add(spots, select(2, Kit.waterfall(m, at(cf, 0, 14), rng, true)))
		Kit.pine(m, at(cf, -22, 0), rng, true)
		add(spots, select(2, Kit.rock(m, at(cf, 22, -6), rng, "snow")))
		return spots
	end,
	function(m, cf, rng)
		local spots = {}
		Kit.mountain(m, at(cf, 0, 24), rng)
		Kit.crystals(m, at(cf, -18, -10), rng, C.Ice)
		add(spots, select(2, Kit.rock(m, at(cf, 16, -14), rng, "snow")))
		return spots
	end,
}

local function fillers(m: Instance, zone: number, cf: CFrame, rng: Random)
	for _ = 1, 3 do
		local c = cf * CFrame.new(rng:NextNumber(-38, 38), 0, rng:NextNumber(-34, 34))
		local p = c.Position
		local r = p.Magnitude
		local deg = math.deg(math.atan2(p.Z, p.X)) % 360
		local z = World.Zones[zone]
		if roadDistance(deg, r) > 16 and r > z.Inner + 14 and r < z.Outer - 14 then
			local roll = rng:NextNumber()
			if zone == 1 then
				if roll < 0.6 then
					Kit.tree(m, c, rng)
				else
					Kit.flowers(m, c, rng)
				end
			elseif zone == 2 then
				if roll < 0.3 then
					Kit.tree(m, c, rng)
				elseif roll < 0.5 then
					Kit.stall(m, c, rng)
				elseif roll < 0.7 then
					Kit.crate(m, c, rng)
					Kit.barrel(m, c * CFrame.new(3.5, 0, 1))
				else
					Kit.lamp(m, c)
				end
			elseif zone == 3 then
				if roll < 0.45 then
					Kit.blossom(m, c, rng)
				elseif roll < 0.75 then
					Kit.tree(m, c, rng)
				else
					Kit.bamboo(m, c, rng)
				end
			else
				if roll < 0.75 then
					Kit.pine(m, c, rng, true)
				else
					Kit.crystals(m, c, rng, C.Ice)
				end
			end
		end
	end
end

function Build.zone(i: number)
	assert(i >= 1 and i <= 4, "zones 1-4 (zone 5 is Build.sky)")
	local z = World.Zones[i]
	local f = freshFolder(mapRoot(), `Zone{i}`)
	f:SetAttribute("Key", z.Key)
	local rng = Random.new(1000 + i)
	local spots: { Spot } = {}
	local width = z.Outer - z.Inner
	local list = CLUSTERS[i]
	local count = 0
	for lane, frac in { 0.3, 0.72 } do
		local r = z.Inner + width * frac
		local per = math.max(1, math.floor(r * math.pi / 4 / World.ClusterSpacing + 0.5))
		for k = 0, World.Roads.Count - 1 do
			for j = 0, per - 1 do
				local deg = k * 45 + (j + 0.5) / per * 45 + rng:NextNumber(-2, 2)
				local cf = polar(deg, r + rng:NextNumber(-12, 12))
				count += 1
				local kind = list[(count + lane) % #list + 1]
				if i == 4 and kind == list[5] and lane == 1 then
					kind = list[3] -- mountains only on the outer lane
				end
				local m = Kit.model(f, "Cluster")
				for _, s in kind(m, cf, rng) do
					table.insert(spots, s)
				end
				fillers(m, i, cf, rng)
			end
		end
	end
	placeSpots(i, spots)
	print(`[Sweetpotato] zone {i} {z.Key}: {count} clusters ({#f:GetDescendants()} instances)`)
end

----------------------------------------------------------------------------------------------------
-- Sky Islands (zone 5)

function Build.sky()
	local z = World.Zones[5]
	local f = freshFolder(mapRoot(), "Zone5")
	f:SetAttribute("Key", z.Key)
	local rng = Random.new(1005)
	local spots: { Spot } = {}
	local inner = z.Inner + 50
	local outer = z.Outer - 40
	local n = 56
	local islands: { { pos: Vector3, size: number } } = {}
	local function decorate(m: Instance, cf: CFrame, size: number)
		local roll = rng:NextNumber()
		if roll < 0.3 then
			add(spots, select(2, Kit.pavilion(m, cf * CFrame.new(0, 0, size * 0.12), C.White, C.Blue, C.Gold, C.White)))
		elseif roll < 0.6 then
			add(spots, select(2, Kit.crystals(m, cf * CFrame.new(rng:NextNumber(-8, 8), 0, size * 0.18), rng, Kit.pick(rng, { C.Purple, C.Pink }), true)))
		else
			Kit.tree(m, cf * CFrame.new(rng:NextNumber(-10, 10), 0, size * 0.2), rng)
		end
		add(spots, select(2, Kit.bush(m, cf * CFrame.new(-size * 0.3, 0, -size * 0.15), rng)))
		Kit.flowers(m, cf * CFrame.new(size * 0.28, 0, -size * 0.2), rng)
		if rng:NextNumber() < 0.5 then
			add(spots, select(2, Kit.crystals(m, cf * CFrame.new(size * 0.3, 0, size * 0.25), rng, Kit.pick(rng, { C.Purple, C.Pink }))))
		end
	end
	for j = 0, n - 1 do
		local deg = j * 360 / n
		local size = if j % 7 == 0 then 66 else rng:NextInteger(54, 66)
		local cf = polar(deg, inner)
		local m = Kit.island(f, cf, size, rng)
		decorate(m, cf, size)
		table.insert(islands, { pos = cf.Position, size = size })
	end
	for j = 1, n do
		local a = islands[j]
		local b = islands[j % n + 1]
		local dir = (b.pos - a.pos).Unit
		add(spots, Kit.skyBridge(f, a.pos + dir * (a.size / 2 - 2), b.pos - dir * (b.size / 2 - 2)))
	end
	-- outer islands, each joined to the inner ring
	for j = 1, n - 1, 2 do
		local deg = j * 360 / n
		local size = rng:NextInteger(50, 62)
		local cf = polar(deg, outer)
		local m = Kit.island(f, cf, size, rng)
		decorate(m, cf, size)
		local a = islands[j + 1]
		local dir = (cf.Position - a.pos).Unit
		add(spots, Kit.skyBridge(f, a.pos + dir * (a.size / 2 - 2), cf.Position - dir * (size / 2 - 2)))
		if j % 4 == 1 then
			-- a waterfall pouring off the outer edge
			local edge = cf * CFrame.new(0, 0, size / 2 + 0.6)
			Kit.part(m, Vector3.new(7, 46, 1), edge * CFrame.new(0, -23, 0), C.WaterLight, { mat = Enum.Material.Neon, t = 0.3, decor = true, shadow = false })
			Kit.part(m, Vector3.new(7, 0.4, size * 0.4), cf * CFrame.new(0, 0.2, size * 0.3), C.Water, { decor = true, refl = 0.12, shadow = false })
		end
	end
	-- bridges from the snow cliff gates to the first islands
	for _, deg in roadAngles() do
		local from = polar(deg, z.Inner + 10).Position
		local j = math.floor(deg / (360 / n) + 0.5) % n + 1
		local isl = islands[j]
		local dir = (isl.pos - from).Unit
		Kit.skyBridge(f, from, isl.pos - dir * (isl.size / 2 - 2))
	end
	-- cloud sea, clouds in the sky, rainbows
	local sea = subFolder(f, "Clouds")
	for _ = 1, 260 do
		local a = rng:NextNumber(0, TAU)
		local r = rng:NextNumber(z.Inner - 30, z.Outer + 260)
		Kit.cloud(sea, Vector3.new(math.cos(a) * r, World.SkyCloudY + rng:NextNumber(-25, 10), math.sin(a) * r), rng:NextNumber(2.5, 5), rng)
	end
	for _ = 1, 26 do
		local a = rng:NextNumber(0, TAU)
		local r = rng:NextNumber(200, z.Outer + 200)
		Kit.cloud(sea, Vector3.new(math.cos(a) * r, rng:NextNumber(150, 230), math.sin(a) * r), rng:NextNumber(3, 5), rng)
	end
	for _, deg in { 62, 242 } do
		Kit.rainbow(f, polar(deg, z.Outer + 30, -30), 150)
	end
	placeSpots(5, spots)
	print(`[Sweetpotato] zone 5 SkyIslands built ({#f:GetDescendants()} instances)`)
end

function Build.all()
	Build.lighting()
	Build.lobby()
	Build.ground()
	Build.roads()
	Build.walls()
	for i = 1, 4 do
		Build.zone(i)
	end
	Build.sky()
	require(script.Parent.Lego).apply() -- revision 3: LEGO studs on the ground, paths and trees
end

return Build
