--!strict
-- A still picture of a cat for cards (R9: My Cats grid, collection book): the real CatModel in a ViewportFrame,
-- seen from the front three-quarter. `silhouette` paints every part dark navy (an unseen cat in the book).
-- The model is not tagged "Cat", so CatAnimController leaves it alone. Callers create portraits only for cards
-- on screen (CatPortrait.fillVisible) so a long list stays light on phones.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatModel = require(Shared:WaitForChild("CatModel"))

local CatPortrait = {}

local INK = Color3.fromHex("2a2f4f")

function CatPortrait.make(parent: Instance, look: any, silhouette: boolean?): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = "Portrait"
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromScale(1, 1)
	view.Ambient = Color3.fromRGB(205, 205, 215)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-0.6, -1, 0.8)
	view.Parent = parent
	local model = CatModel.build(look, CFrame.new(), 1)
	CollectionService:RemoveTag(model, CatModel.Tag)
	if silhouette then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = INK
				d.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	model.Parent = view
	local cf, size = model:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = math.max(size.X, size.Y, size.Z) * 1.95
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.42, dist * 0.32, -dist * 0.85), cf.Position)
	cam.Parent = view
	view.CurrentCamera = cam
	return view
end

-- Builds the portrait of every card in `list` that is on screen and has none yet. `lookOf(card)` gives the look
-- (nil = skip) and `silhouetteOf(card)` whether to draw it dark. The picture goes into the card's "Picture".
function CatPortrait.fillVisible(list: GuiObject, lookOf: (Instance) -> any, silhouetteOf: ((Instance) -> boolean)?)
	local top = list.AbsolutePosition.Y - 40
	local bottom = top + list.AbsoluteSize.Y + 80
	for _, card in list:GetChildren() do
		if card:IsA("GuiObject") then
			local box = card:FindFirstChild("Picture")
			if box and not box:FindFirstChild("Portrait") then
				local y = card.AbsolutePosition.Y
				if y + card.AbsoluteSize.Y >= top and y <= bottom then
					local look = lookOf(card)
					if look then
						CatPortrait.make(box, look, if silhouetteOf then silhouetteOf(card) else false)
					end
				end
			end
		end
	end
end

return CatPortrait
