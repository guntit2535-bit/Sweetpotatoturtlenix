--!strict
-- X4 (map restyle, look B "pixel voxel"): the pixel + LEGO ground. A grey texture (art/export/PixelGround.png: 8 x 8
-- studs of 3-shade pixel noise with a LEGO stud on each stud, uploaded by the developer to the group) goes on the top
-- of every ground tile, island top and road, tinted with the part's own colour, so the zone colours and the green
-- checker stay. The part's Studs surface (Lego.apply) is turned off under it (the studs are in the picture).
-- Edit-time only, run from the Command Bar / Studio MCP:
--   require(game.ServerScriptService.Server.MapTools:Clone().Pixel).apply(<image id>)   -- and .undo()

local Pixel = {}

local GROUND_NAMES = { Tile = true, Ground = true }
local STUDS_PER_TILE = 8

local function mapRoot(): Instance
	return workspace:FindFirstChild("Map") or error("Pixel: Workspace.Map not found")
end

local function targets(): { BasePart }
	local map = mapRoot()
	local out: { BasePart } = {}
	local function add(p: Instance)
		if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 1 then
			table.insert(out, p)
		end
	end
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and GROUND_NAMES[d.Name] then
			add(d)
		end
	end
	local roads = map:FindFirstChild("Roads")
	if roads then
		for _, d in roads:GetDescendants() do
			add(d)
		end
	end
	return out
end

function Pixel.apply(imageId: number): number
	assert(type(imageId) == "number" and imageId > 0, "Pixel.apply(<uploaded image id>)")
	local n = 0
	for i, p in targets() do
		local t = p:FindFirstChild("PixelTex") :: Texture?
		if not t then
			local new = Instance.new("Texture")
			new.Name = "PixelTex"
			new.Face = Enum.NormalId.Top
			new.Parent = p
			t = new
		end
		local tex = t :: Texture
		tex.Texture = `rbxassetid://{imageId}`
		tex.StudsPerTileU = STUDS_PER_TILE
		tex.StudsPerTileV = STUDS_PER_TILE
		tex.Color3 = p.Color
		if p:GetAttribute("PixelOldTop") == nil then
			p:SetAttribute("PixelOldTop", p.TopSurface.Name)
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		n += 1
		if i % 1500 == 0 then
			task.wait()
		end
	end
	print(`[Sweetpotato] pixel ground on {n} parts (image {imageId})`)
	return n
end

function Pixel.undo(): number
	local n = 0
	for i, d in mapRoot():GetDescendants() do
		if d:IsA("Texture") and d.Name == "PixelTex" then
			local p = d.Parent
			d:Destroy()
			if p and p:IsA("BasePart") then
				local old = p:GetAttribute("PixelOldTop")
				if type(old) == "string" then
					p.TopSurface = (Enum.SurfaceType :: any)[old]
				end
				p:SetAttribute("PixelOldTop", nil)
			end
			n += 1
		end
		if i % 4000 == 0 then
			task.wait()
		end
	end
	print(`[Sweetpotato] pixel ground removed from {n} parts`)
	return n
end

return Pixel
