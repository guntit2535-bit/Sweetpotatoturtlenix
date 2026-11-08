--!strict
-- R5: the player's best pair of shoes (data.Shoes = pairs bought, Config.Shoes.List) is worn on both feet:
-- the Blender mesh Shoe_<key> welded under each R15 foot (the same right shoe on the left foot; the shoes are
-- symmetric enough). Nothing when no pair is owned, shoes are off (Config.Shoes.Enabled), the avatar is R6 or
-- the meshes are not imported. Looks only: the speed comes from Bonus / MovementService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ItemModels = require(ReplicatedStorage.Shared.ItemModels)
local DataService = require(script.Parent.DataService)

local ShoeService = {}

local FOLDER = "Shoes"

local function wear(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local data = DataService.GetData(player)
	local pair = if data and Config.Shoes.Enabled then data.Shoes else 0
	local shoe = Config.Shoes.List[pair]
	local id = if shoe then "Shoe_" .. shoe.Key else nil
	local old = character:FindFirstChild(FOLDER)
	if old and old:GetAttribute("Id") == id then
		return
	end
	if old then
		old:Destroy()
	end
	if not id or not ItemModels.has(id) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder:SetAttribute("Id", id)
	for _, footName in { "RightFoot", "LeftFoot" } do
		local foot = character:FindFirstChild(footName)
		local model = ItemModels.build(id, Config.ItemModels.ShoeScale)
		if foot and foot:IsA("BasePart") and model then
			model:PivotTo(foot.CFrame * CFrame.new(0, -foot.Size.Y / 2, 0))
			local w = Instance.new("WeldConstraint")
			w.Part0 = foot
			w.Part1 = model.PrimaryPart
			w.Parent = model
			model.Name = footName
			model.Parent = folder
		elseif model then
			model:Destroy()
		end
	end
	folder.Parent = character
end

function ShoeService:Start()
	local function hook(player: Player)
		player.CharacterAppearanceLoaded:Connect(function()
			wear(player)
		end)
		if player.Character then
			task.defer(wear, player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	DataService.PlayerLoaded:Connect(wear)
	DataService.Changed:Connect(wear) -- a no-op unless the best pair changed
end

return ShoeService
