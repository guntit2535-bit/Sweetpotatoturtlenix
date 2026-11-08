--!strict
-- The 5 looks of a pen's weights (task 1.15, blueprint §8): dumbbell rack > barbell > bench press >
-- weight machine > giant barbell, one per Config.Gym.LookEvery levels. Built from parts in front of the
-- pen (base = the equipment's floor point, front = -Z toward the player standing at it).
-- R5 / R6 / R7: when the Blender meshes are imported (shared/ItemModels) every level has its own look instead:
-- Weights1..25 (rack + pair) and Treadmill1..25, placed from the pen's original spot (kept in the "Base"
-- attribute), with an invisible collider; the treadmill's Stand moves onto the belt of the (bigger) machine.
-- GymLooks.applyLevel does that; the 5 part-built weights looks below stay as the fallback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemModels = require(ReplicatedStorage.Shared.ItemModels)

local GymLooks = {}

local hex = Color3.fromHex
local NAVY = hex("2f3552")
local STEEL = hex("b8bdcb")
local PINK = hex("ff8fca")
local YELLOW = hex("ffd23f")
local BLUE = hex("3e8ef2")
local GOLD = hex("f5bf2e")
local WOOD = hex("dc9e55")

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, neon: boolean?): Part
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = parent
	return p
end

-- A weight plate (disc facing along X) on a bar along X.
local function plate(parent: Instance, cf: CFrame, d: number, t: number, color: Color3, neon: boolean?)
	part(parent, Vector3.new(t, d, d), cf, color, Enum.PartType.Cylinder, neon)
end

local function bar(parent: Instance, cf: CFrame, len: number, thick: number)
	part(parent, Vector3.new(len, thick, thick), cf, STEEL, Enum.PartType.Cylinder)
end

local LOOKS: { (m: Model, base: CFrame) -> () } = {
	function(m, base) -- 1 dumbbell rack
		part(m, Vector3.new(7, 0.6, 3), base * CFrame.new(0, 0.3, 2), NAVY)
		for _, x in { -3.2, 3.2 } do
			part(m, Vector3.new(0.6, 3.6, 0.6), base * CFrame.new(x, 2.1, 2), NAVY)
		end
		part(m, Vector3.new(7, 0.5, 0.6), base * CFrame.new(0, 3.7, 2), NAVY)
		for i, c in { PINK, YELLOW, BLUE } do
			local b = base * CFrame.new(0, 0.9 + i * 0.9, 1.6)
			bar(m, b, 4, 0.35)
			for _, x in { -1.7, 1.7 } do
				plate(m, b * CFrame.new(x, 0, 0), 1.4, 0.7, c)
			end
		end
	end,
	function(m, base) -- 2 barbell on a rack
		for _, x in { -3.4, 3.4 } do
			part(m, Vector3.new(0.7, 4.6, 0.7), base * CFrame.new(x, 2.3, 2.4), NAVY)
			part(m, Vector3.new(1.6, 0.4, 1.6), base * CFrame.new(x, 0.2, 2.4), NAVY)
		end
		local b = base * CFrame.new(0, 4.4, 2.1)
		bar(m, b, 9, 0.4)
		for _, x in { -3, 3 } do
			plate(m, b * CFrame.new(x, 0, 0), 2.8, 0.6, BLUE)
			plate(m, b * CFrame.new(x * 0.82, 0, 0), 2.2, 0.5, PINK)
		end
	end,
	function(m, base) -- 3 bench press
		part(m, Vector3.new(2.4, 0.9, 6.4), base * CFrame.new(0, 2, 3), NAVY)
		part(m, Vector3.new(2.2, 0.5, 6), base * CFrame.new(0, 2.6, 3), hex("ef4b42"))
		for _, z in { 0.8, 5.4 } do
			part(m, Vector3.new(1.4, 1.6, 0.6), base * CFrame.new(0, 0.8, z), NAVY)
		end
		for _, x in { -2, 2 } do
			part(m, Vector3.new(0.6, 5, 0.6), base * CFrame.new(x, 2.5, 5.6), NAVY)
		end
		local b = base * CFrame.new(0, 4.9, 5.2)
		bar(m, b, 8, 0.4)
		for _, x in { -2.9, 2.9 } do
			plate(m, b * CFrame.new(x, 0, 0), 3, 0.6, YELLOW)
		end
	end,
	function(m, base) -- 4 weight machine
		for _, x in { -2.4, 2.4 } do
			part(m, Vector3.new(0.7, 9, 0.7), base * CFrame.new(x, 4.5, 4), NAVY)
		end
		part(m, Vector3.new(5.5, 0.7, 0.9), base * CFrame.new(0, 9, 4), NAVY)
		part(m, Vector3.new(6, 0.5, 4), base * CFrame.new(0, 0.25, 3.5), NAVY)
		for i = 0, 5 do
			part(m, Vector3.new(2.6, 0.45, 1.6), base * CFrame.new(0, 0.8 + i * 0.5, 4), if i % 2 == 0 then YELLOW else hex("ffb020"))
		end
		part(m, Vector3.new(0.15, 6, 0.15), base * CFrame.new(0, 6, 4), STEEL)
		part(m, Vector3.new(4.5, 0.35, 0.35), base * CFrame.new(0, 7, 2.2), STEEL)
		part(m, Vector3.new(2.6, 0.6, 2.6), base * CFrame.new(0, 1.6, 1.8), hex("ef4b42"))
		part(m, Vector3.new(0.6, 1.4, 0.6), base * CFrame.new(0, 0.7, 1.8), NAVY)
	end,
	function(m, base) -- 5 giant barbell
		for _, x in { -5, 5 } do
			part(m, Vector3.new(1.2, 3.4, 1.2), base * CFrame.new(x, 1.7, 2.6), GOLD)
			part(m, Vector3.new(2.4, 0.5, 2.4), base * CFrame.new(x, 0.25, 2.6), NAVY)
		end
		local b = base * CFrame.new(0, 3.8, 2.6)
		bar(m, b, 14, 0.7)
		for _, x in { -6.2, 6.2 } do
			plate(m, b * CFrame.new(x, 0, 0), 6.4, 1, GOLD, true)
			plate(m, b * CFrame.new(x * 0.86, 0, 0), 5, 0.8, hex("ffe680"))
		end
		local spark = part(m, Vector3.new(1, 1, 1), b, GOLD)
		spark.Transparency = 1
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(hex("fff2a8"))
		e.Size = NumberSequence.new(0.4, 0)
		e.Rate = 6
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.LightEmission = 0.8
		e.Parent = spark
		local _ = WOOD
	end,
}

GymLooks.Count = #LOOKS

-- Replaces the look of a pen's Weights model (keeps its "Stand" part).
function GymLooks.apply(weights: Model, look: number)
	if weights:GetAttribute("Look") == look then
		return
	end
	local stand = weights:FindFirstChild("Stand")
	if not stand or not stand:IsA("BasePart") then
		return
	end
	for _, c in weights:GetChildren() do
		if c ~= stand then
			c:Destroy()
		end
	end
	local base = stand.CFrame * CFrame.new(0, -2, 2)
	local m = Instance.new("Model")
	m.Name = "Look"
	LOOKS[math.clamp(look, 1, #LOOKS)](m, base)
	m.Parent = weights
	weights:SetAttribute("Look", look)
end


-- R5: the mesh look of a pen's Weights / Treadmill model for `level`. Returns false when the mesh is not
-- imported (the caller keeps the old look).
local function collider(parent: Instance, size: Vector3, cf: CFrame)
	local c = Instance.new("Part")
	c.Name = "Collider"
	c.Size = size
	c.CFrame = cf
	c.Transparency = 1
	c.Anchored = true
	c.CanTouch = false
	c.CanQuery = false
	c.Parent = parent
end

function GymLooks.applyLevel(gym: Model, which: string, level: number): boolean
	local id = which .. level
	if not ItemModels.has(id) then
		return false
	end
	if gym:GetAttribute("Look") == id then
		return true
	end
	local stand = gym:FindFirstChild("Stand")
	if not stand or not stand:IsA("BasePart") then
		return false
	end
	-- the machine's floor point as the map built it (before any move of the Stand)
	local base = gym:GetAttribute("Base")
	if typeof(base) ~= "CFrame" then
		base = if which == "Treadmill" then stand.CFrame * CFrame.new(0, -2, -0.3) else stand.CFrame * CFrame.new(0, -2, 2)
		gym:SetAttribute("Base", base)
	end
	local floor = base :: CFrame
	local isTread = which == "Treadmill"
	local scale = if isTread
		then Config.ItemModels.TreadmillScale
		else Config.ItemModels.WeightsScale * (1 + 0.06 * (level - 1)) ^ (Config.ItemModels.WeightsGrowth - 1)
	local model = ItemModels.build(id, scale) :: Model
	model.Name = "Look"
	for _, c in gym:GetChildren() do
		if c ~= stand then
			c:Destroy()
		end
	end
	local mesh = model:FindFirstChild("Mesh") :: BasePart
	local place: CFrame
	if isTread then
		place = floor
	else
		-- the rack's front edge stays half a stud behind the floor point, however big the rack grows
		place = floor * CFrame.new(0, 0, 0.5 + mesh.Size.Z / 2)
	end
	model:PivotTo(place)
	;(model.PrimaryPart :: BasePart).Anchored = true
	model.Parent = gym
	if isTread then
		-- items.py treadmill: deck top 0.82, belt top 0.9 and belt centre 0.1 back, x (1 + 0.02 (level - 1))
		local k = 1 + 0.02 * (level - 1)
		local beltTop = ItemModels.point(scale, 0, 0.1 * k, 0.9 * k)
		collider(gym, Vector3.new(2.4, 0.9, 4.2) * k * scale, place * CFrame.new(0, 0.45 * k * scale, 0))
		stand.CFrame = place * CFrame.new(beltTop) * CFrame.new(0, -stand.Size.Y / 2, 0)
	else
		collider(gym, mesh.Size, mesh.CFrame)
	end
	gym:SetAttribute("Look", id)
	return true
end

return GymLooks
