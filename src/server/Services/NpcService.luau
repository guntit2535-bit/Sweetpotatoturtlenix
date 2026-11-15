--!strict
-- The plaza shopkeepers (developer 2026-11-15: "bacon" Roblox avatars standing in the two stalls; they replace the
-- chibi girls). MapKit leaves an invisible "NpcSpot" behind each stall's counter (attribute Who = "Shop" / "Sell");
-- here the server builds a plain R15 avatar there from a HumanoidDescription: Roblox's own Pal Hair (the "bacon"
-- hair), a shirt in the stall's colour (Config.Npc). Only the root is anchored, so NpcController (client) can play
-- the idle / wave animations and turn the root toward a near player. Decoration: no remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local NpcService = {}

local function build(spot: BasePart)
	local who = spot:GetAttribute("Who")
	if type(who) ~= "string" or not spot.Parent or spot.Parent:FindFirstChild(`Shopkeeper_{who}`) then
		return
	end
	local cfg = Config.Npc
	local d = Instance.new("HumanoidDescription")
	d.HairAccessory = tostring(cfg.Hair)
	d.Head = cfg.Head
	local skin, shirt, pants = Color3.fromHex(cfg.Skin), Color3.fromHex(cfg.Shirt[who] or cfg.Shirt.Shop), Color3.fromHex(cfg.Pants)
	d.HeadColor, d.LeftArmColor, d.RightArmColor = skin, skin, skin
	d.TorsoColor = shirt
	d.LeftLegColor, d.RightLegColor = pants, pants
	d.HeightScale, d.WidthScale, d.DepthScale, d.HeadScale = cfg.Scale, cfg.Scale, cfg.Scale, cfg.Scale
	local ok, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	end)
	if not ok or not rig then
		warn("[Sweetpotato] NpcService: could not build the shopkeeper", who, rig)
		return
	end
	local model = rig :: Model
	model.Name = `Shopkeeper_{who}`
	model:SetAttribute("Who", who)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		model:Destroy()
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	root.Anchored = true
	-- the feet on the spot (+ Raise: a hidden step, so more of them shows over the counter)
	local feetToRoot = humanoid.HipHeight + root.Size.Y / 2
	model:PivotTo(spot.CFrame * CFrame.new(0, cfg.Raise + feetToRoot, 0))
	model.Parent = spot.Parent
end

local function scan()
	local map = workspace:FindFirstChild("Map")
	local lobby = map and map:FindFirstChild("Lobby")
	local market = lobby and lobby:FindFirstChild("Market")
	if not market then
		return
	end
	for _, spot in market:GetDescendants() do
		if spot:IsA("BasePart") and spot.Name == "NpcSpot" then
			build(spot)
		end
	end
end

function NpcService.Start(_self: any)
	task.spawn(scan)
end

return NpcService
