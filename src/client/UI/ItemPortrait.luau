--!strict
-- R5: a still picture of an item mesh (shared/ItemModels) for shop rows: the model in a ViewportFrame, seen
-- from the front three-quarter, filling `parent`. Returns nil when the mesh is not imported (the caller keeps
-- its colour chip).

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemModels = require(Shared:WaitForChild("ItemModels"))

local ItemPortrait = {}

-- view: the camera's direction from the item (Roblox axes, the item's front is -Z)
function ItemPortrait.make(parent: GuiObject, id: string, view: Vector3?): ViewportFrame?
	local model = ItemModels.build(id, 1)
	if not model then
		return nil
	end
	local vf = Instance.new("ViewportFrame")
	vf.Name = "Portrait"
	vf.BackgroundTransparency = 1
	vf.Size = UDim2.fromScale(1, 1)
	vf.Ambient = Color3.fromRGB(205, 205, 215)
	vf.LightColor = Color3.new(1, 1, 1)
	vf.LightDirection = Vector3.new(-0.6, -1, -0.8)
	vf.ZIndex = parent.ZIndex + 1
	;(model.PrimaryPart :: BasePart).Anchored = true
	model.Parent = vf
	local cf, size = model:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = math.max(size.X, size.Y, size.Z) * 1.75
	local dir = (view or Vector3.new(0.55, 0.42, -1)).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	cam.Parent = vf
	vf.CurrentCamera = cam
	vf.Parent = parent
	-- W4: a ViewportFrame does not draw again when a mesh's texture finishes loading, so an item seen for the first
	-- time (the crates: their palette was never used in the world yet) stayed grey. Load the textures, then put the
	-- model back in so the frame draws it again with its colours.
	task.spawn(function()
		local parts = {}
		for _, d in model:GetDescendants() do
			if d:IsA("MeshPart") then
				table.insert(parts, d)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(parts)
		end)
		if vf.Parent then
			model.Parent = nil
			model.Parent = vf
		end
	end)
	return vf
end

-- Puts the item's picture over a row's colour chip (Kit.row "Picture" / its "Color" square).
function ItemPortrait.onRow(row: Instance, id: string, view: Vector3?)
	local chip = row:FindFirstChild("Picture")
	if chip and chip:IsA("GuiObject") and ItemPortrait.make(chip, id, view) then
		local sq = chip:FindFirstChild("Color")
		if sq and sq:IsA("GuiObject") then
			sq.Visible = false
		end
	end
end

return ItemPortrait
