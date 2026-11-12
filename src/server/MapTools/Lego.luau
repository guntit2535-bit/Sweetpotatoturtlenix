--!strict
-- Revision 3 item 2: the "pixel + LEGO" look for the ground, the paths and the trees. Roblox's own Studs surface
-- (it shows only on Plastic) goes on the top of every ground tile, island top, road / curb and the blocks of every
-- tree (Tree, BlossomTree, Pine). Same colours and shapes, nothing uploaded, nothing added. Edit-time only, run from
-- the Command Bar / Studio MCP:
--   require(game.ServerScriptService.Server.MapTools:Clone().Lego).apply()   -- and .undo() to put it back
-- Each changed part keeps its old material in the attribute "LegoOld", so undo restores exactly.

local Lego = {}

local TREES = { Tree = true, BlossomTree = true, Pine = true }
local GROUND_NAMES = { Tile = true, Ground = true }

local function mapRoot(): Instance
	return workspace:FindFirstChild("Map") or error("Lego: Workspace.Map not found")
end

-- the parts that get studs
local function targets(): { BasePart }
	local map = mapRoot()
	local out: { BasePart } = {}
	local function add(p: Instance)
		if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 1 then
			table.insert(out, p)
		end
	end
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			local parent = d.Parent
			if GROUND_NAMES[d.Name] then
				add(d)
			elseif parent and TREES[parent.Name] and parent:IsA("Model") then
				add(d)
			end
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

function Lego.apply(): number
	local n = 0
	for i, p in targets() do
		if p:GetAttribute("LegoOld") == nil then
			p:SetAttribute("LegoOld", p.Material.Name)
		end
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
		n += 1
		if i % 2000 == 0 then
			task.wait()
		end
	end
	print(`[Sweetpotato] LEGO studs on {n} parts (ground, paths, trees)`)
	return n
end

function Lego.undo(): number
	local n = 0
	for i, d in mapRoot():GetDescendants() do
		local old = d:GetAttribute("LegoOld")
		if d:IsA("BasePart") and type(old) == "string" then
			d.Material = (Enum.Material :: any)[old]
			d.TopSurface = Enum.SurfaceType.Smooth
			d:SetAttribute("LegoOld", nil)
			n += 1
		end
		if i % 4000 == 0 then
			task.wait()
		end
	end
	print(`[Sweetpotato] LEGO studs removed from {n} parts`)
	return n
end

return Lego
