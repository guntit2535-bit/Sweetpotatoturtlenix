--!strict
-- V3: swaps the map's old fountains, creeks and waterfalls for the new ones (MapKit) in place, without
-- rebuilding the map: each old piece's frame is read back from its main part, the new piece is built at the
-- same frame (the hiding spots stay where they are) and the old one is moved to ServerStorage.MapBackup_V3
-- (delete that folder once the new look is approved). Run from the Command Bar / Studio MCP in Edit mode:
--   require(game.ServerScriptService.Server.MapTools:Clone().Upgrade).water("Fountain")  -- or "Creek", "Waterfall"
-- Never required by the running game.

local ServerStorage = game:GetService("ServerStorage")

local Kit = require(script.Parent.MapKit)

local Upgrade = {}

local C = Kit.Colors

local function near(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.03
end

local function backup(): Folder
	local f = ServerStorage:FindFirstChild("MapBackup_V3")
	if not f then
		f = Instance.new("Folder")
		f.Name = "MapBackup_V3"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

local function sized(m: Model, size: Vector3): BasePart?
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and (p.Size - size).Magnitude < 0.05 then
			return p
		end
	end
	return nil
end

local function seed(cf: CFrame): Random
	return Random.new(math.floor(cf.Position.X * 13 + cf.Position.Z * 7))
end

-- Old creek: the water slab 56 x 0.3 x 12 at cf * (0, 0.16, 0); the bridge deck colour gives the style.
local function creek(m: Model): boolean
	local water = sized(m, Vector3.new(56, 0.3, 12))
	if not water then
		return false
	end
	local cf = water.CFrame * CFrame.new(0, -0.16, 0)
	local frozen = near(water.Color, C.Ice)
	local styleName = "wood"
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and (p.Size - Vector3.new(9, 1, 7)).Magnitude < 0.05 then
			styleName = "stone"
		elseif p:IsA("BasePart") and (p.Size - Vector3.new(7, 1, 7)).Magnitude < 0.05 and near(p.Color, C.Red) then
			styleName = "red"
		end
	end
	Kit.creek(m.Parent :: Instance, cf, seed(cf), styleName, frozen)
	return true
end

-- Old waterfall: the rock 30 x 16 x 12 at cf * (0, 8, 6); snow on top = frozen.
local function waterfall(m: Model): boolean
	local rock = sized(m, Vector3.new(30, 16, 12))
	if not rock then
		return false
	end
	local cf = rock.CFrame * CFrame.new(0, -8, -6)
	local frozen = false
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and near(p.Color, C.Snow) then
			frozen = true
		end
	end
	Kit.waterfall(m.Parent :: Instance, cf, seed(cf), frozen)
	return true
end

-- Old fountain: its widest disc is the basin (24 s across) at cf * (0, 0.9 s, 0).
local function fountain(m: Model): boolean
	local best: BasePart? = nil
	for _, p in m:GetChildren() do
		if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and (not best or p.Size.Y > best.Size.Y) then
			best = p
		end
	end
	if not best then
		return false
	end
	local s = best.Size.Y / 24
	local cf = best.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, -0.9 * s, 0)
	Kit.fountain(m.Parent :: Instance, CFrame.new(cf.Position), s)
	return true
end

local DO = { Creek = creek, Waterfall = waterfall, Fountain = fountain }

-- Swaps every old piece of one kind; returns how many were swapped / skipped.
function Upgrade.water(kind: string): string
	local fn = DO[kind]
	if not fn then
		return "kind: Fountain | Creek | Waterfall"
	end
	local map = workspace:FindFirstChild("Map")
	if not map then
		return "no Map"
	end
	local old = {}
	for _, d in map:GetDescendants() do
		if d:IsA("Model") and d.Name == kind and not d:GetAttribute("V3") then
			table.insert(old, d)
		end
	end
	local done, skipped = 0, 0
	local store = backup()
	for i, m in old do
		if fn(m) then
			m:SetAttribute("BackupOf", m:GetFullName())
			m.Parent = store
			done += 1
		else
			skipped += 1
		end
		if i % 5 == 0 then
			task.wait()
		end
	end
	return `{kind}: {done} swapped, {skipped} skipped`
end

-- Puts every backed-up piece back and removes the new ones (if the new look is not wanted).
function Upgrade.undo(): string
	local store = ServerStorage:FindFirstChild("MapBackup_V3")
	local map = workspace:FindFirstChild("Map")
	if not store or not map then
		return "nothing to undo"
	end
	local n = 0
	for _, d in map:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("V3") then
			d:Destroy()
		end
	end
	for _, m in store:GetChildren() do
		local path = m:GetAttribute("BackupOf")
		local parentPath = if type(path) == "string" then string.match(path, "^(.*)%.[^%.]+$") else nil
		local parent: Instance? = game
		for part in string.gmatch(parentPath or "", "[^%.]+") do
			parent = parent and parent:FindFirstChild(part)
		end
		if parent then
			m.Parent = parent
			n += 1
		end
	end
	return `{n} restored`
end

return Upgrade
