--!strict
-- V3 part 2: small ground details between the clusters of every zone (grass tufts, pebbles, mushrooms, ferns, logs,
-- leaves, cobbles, pots, sacks, snow mounds, ice patches, crystal bits, flowers). Edit-time only, run from the
-- Command Bar / Studio MCP:
--   require(game.ServerScriptService.Server.MapTools:Clone().Detail).all()     -- every zone (replaces old details)
--   ... .zone(3)       one zone          ... .clear()      remove them all
-- Each zone's details go into Workspace.Map.Zone<i>.Details (Map.Zone5.Details for the sky islands), so clearing
-- touches nothing else. A detail goes only where a ray from above hits bare ground (a ground tile or an island's
-- grass) with nothing else within Clearance studs: never on roads, water, houses or hiding spots.
-- Every part is decoration: no collision, no queries, no touch, no shadow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.MapKit)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):Clone()) :: any

local World = Config.World

local Detail = {}

-- clumps per zone (Backyard .. Sky Islands): about 5k parts in each ground zone, ~20k in all (phones: decoration
-- only, StreamingEnabled loads the near ones)
Detail.Clumps = { 380, 340, 330, 380, 120 }
Detail.Clearance = 2.6
Detail.ClumpSize = { 3, 5 } -- details per clump
Detail.ClumpRadius = 7

type Maker = (parent: Instance, cf: CFrame, rng: Random) -> ()

local C = Kit.Colors

-- per zone: { weight, maker }
local MIX: { { { any } } } = {
	{ -- Backyard
		{ 20, function(p, cf, rng) Kit.grassPatch(p, cf, rng) end },
		{ 40, function(p, cf, rng) Kit.tuft(p, cf, rng) end },
		{ 24, function(p, cf, rng) Kit.sprigs(p, cf, rng) end },
		{ 20, function(p, cf, rng) Kit.pebbles(p, cf, rng) end },
		{ 12, function(p, cf, rng) Kit.mushroom(p, cf, rng) end },
		{ 3, function(p, cf, rng) Kit.leafPile(p, cf, rng) end },
	},
	{ -- Town Market
		{ 25, function(p, cf, rng) Kit.cobbles(p, cf, rng) end },
		{ 25, function(p, cf, rng) Kit.tuft(p, cf, rng) end },
		{ 18, function(p, cf, rng) Kit.flowerPot(p, cf, rng) end },
		{ 12, function(p, cf, rng) Kit.sack(p, cf, rng) end },
		{ 20, function(p, cf, rng) Kit.pebbles(p, cf, rng) end },
	},
	{ -- Forest
		{ 15, function(p, cf, rng) Kit.grassPatch(p, cf, rng, C.LeafDark) end },
		{ 28, function(p, cf, rng) Kit.fern(p, cf, rng) end },
		{ 20, function(p, cf, rng) Kit.mushroom(p, cf, rng) end },
		{ 10, function(p, cf, rng) Kit.log(p, cf, rng) end },
		{ 16, function(p, cf, rng) Kit.leafPile(p, cf, rng, { C.Pink, C.PinkLight, C.White }) end }, -- sakura petals
		{ 16, function(p, cf, rng) Kit.tuft(p, cf, rng, C.LeafDark) end },
		{ 10, function(p, cf, rng) Kit.pebbles(p, cf, rng, C.Moss) end },
	},
	{ -- Snow Mountain
		{ 18, function(p, cf, rng) Kit.snowMound(p, cf, rng) end },
		{ 30, function(p, cf, rng) Kit.sapling(p, cf, rng) end },
		{ 15, function(p, cf, rng) Kit.icePatch(p, cf, rng) end },
		{ 20, function(p, cf, rng) Kit.pebbles(p, cf, rng, C.Snow) end },
		{ 15, function(p, cf, rng) Kit.crystalBits(p, cf, rng, C.Ice) end },
		{ 15, function(p, cf, rng) Kit.tuft(p, cf, rng, C.SnowShade) end },
	},
	{ -- Sky Islands
		{ 15, function(p, cf, rng) Kit.grassPatch(p, cf, rng) end },
		{ 40, function(p, cf, rng) Kit.tuft(p, cf, rng) end },
		{ 30, function(p, cf, rng) Kit.sprigs(p, cf, rng) end },
		{ 30, function(p, cf, rng) Kit.crystalBits(p, cf, rng, Kit.pick(rng, { C.Purple, C.Pink })) end },
	},
}

local function choose(list: { { any } }, rng: Random): Maker
	local total = 0
	for _, e in list do
		total += e[1]
	end
	local roll = rng:NextNumber(0, total)
	for _, e in list do
		roll -= e[1]
		if roll <= 0 then
			return e[2]
		end
	end
	return list[#list][2]
end

local function mapRoot(): Instance
	return workspace:FindFirstChild("Map") or error("Detail: Workspace.Map not found (build the map first)")
end

local function zoneFolder(i: number): Instance
	local z = mapRoot():FindFirstChild(`Zone{i}`)
	return z or error(`Detail: Map.Zone{i} not found`)
end

local function roadClear(x: number, z: number): boolean
	-- the straight roads from the lobby at 0, 45, 90 .. degrees (BuildMap roadDistance): keep off them
	local r = math.sqrt(x * x + z * z)
	local step = 360 / World.Roads.Count
	local d = math.deg(math.atan2(z, x)) % step
	d = math.min(d, step - d)
	return math.rad(d) * r > World.Roads.Width / 2 + 5
end

-- where a detail may stand: the ground point under (x, z), or nil
local function groundAt(x: number, z: number, top: number, ground: { Instance }): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	local hit = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -top - 400, 0), params)
	if not hit then
		return nil
	end
	local inst = hit.Instance
	local ok = false
	for _, g in ground do
		if inst:IsDescendantOf(g) and (inst.Name == "Tile" or inst.Name == "Ground") then
			ok = true
		end
	end
	if not ok or hit.Normal.Y < 0.9 then
		return nil
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ground
	local near = workspace:GetPartBoundsInRadius(hit.Position + Vector3.new(0, 1.5, 0), Detail.Clearance, overlap)
	if #near > 0 then
		return nil
	end
	return hit.Position
end

function Detail.zone(i: number)
	local z = World.Zones[i]
	local folder = zoneFolder(i)
	local old = folder:FindFirstChild("Details")
	if old then
		old:Destroy()
	end
	local out = Instance.new("Folder")
	out.Name = "Details"
	local rng = Random.new(3000 + i)
	local ground: { Instance } = { mapRoot():FindFirstChild("Ground") or mapRoot() }
	if i == 5 then
		ground = { folder }
	end
	local inner, outer = z.Inner + 14, z.Outer - 14
	local clumps = Detail.Clumps[i] or 200
	local placed, tried = 0, 0
	local top = if i == 5 then 400 else 60
	for _ = 1, clumps do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber(inner * inner, outer * outer)) -- even over the ring's area
		local cx, cz = math.cos(a) * r, math.sin(a) * r
		if i < 5 and not roadClear(cx, cz) then
			continue
		end
		local make = choose(MIX[i], rng)
		for _ = 1, rng:NextInteger(Detail.ClumpSize[1], Detail.ClumpSize[2]) do
			tried += 1
			local x = cx + rng:NextNumber(-Detail.ClumpRadius, Detail.ClumpRadius)
			local zz = cz + rng:NextNumber(-Detail.ClumpRadius, Detail.ClumpRadius)
			local pos = groundAt(x, zz, top, ground)
			if pos then
				-- one clump mostly of one kind, now and then another for variety
				local kind = if rng:NextNumber() < 0.75 then make else choose(MIX[i], rng)
				kind(out, CFrame.new(pos), rng)
				placed += 1
			end
		end
		if placed % 50 == 0 then
			task.wait()
		end
	end
	out.Parent = folder
	local parts = 0
	for _, d in out:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	print(`[Sweetpotato] details zone {i} {z.Key}: {placed} of {tried} tries, {parts} parts`)
	return placed, parts
end

function Detail.all()
	for i = 1, #World.Zones do
		Detail.zone(i)
	end
end

function Detail.clear()
	for i = 1, #World.Zones do
		local f = mapRoot():FindFirstChild(`Zone{i}`)
		local old = f and f:FindFirstChild("Details")
		if old then
			old:Destroy()
		end
	end
end

return Detail
