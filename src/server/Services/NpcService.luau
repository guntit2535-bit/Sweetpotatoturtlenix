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

-- One block of the outfit, welded to a body part (unanchored and massless, so it follows the animations).
local function piece(model: Model, onto: string, size: Vector3, offset: CFrame, color: Color3, ball: boolean?)
	local base = model:FindFirstChild(onto)
	if not base or not base:IsA("BasePart") then
		return
	end
	local p = Instance.new("Part")
	p.Name = "Outfit"
	if ball then
		p.Shape = Enum.PartType.Ball
	end
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
end

-- Look C (developer 2026-11-15): a vest in the stall's colour over the white shirt, three gold buttons, a gold bow tie.
local function dress(model: Model, vest: Color3, trim: Color3)
	local ut = model:FindFirstChild("UpperTorso")
	if not ut or not ut:IsA("BasePart") then
		return
	end
	local s = ut.Size
	local front = -(s.Z / 2 + 0.05)
	for _, side in { -1, 1 } do
		piece(model, "UpperTorso", Vector3.new(s.X * 0.36, s.Y * 0.95, 0.1), CFrame.new(side * s.X * 0.3, -0.02, front), vest)
	end
	for i = 0, 2 do
		piece(model, "UpperTorso", Vector3.new(0.16, 0.16, 0.1), CFrame.new(s.X * 0.13, s.Y * (0.18 - i * 0.22), front - 0.06), trim, true)
	end
	local z = -(s.Z / 2 + 0.12)
	for _, side in { -1, 1 } do
		piece(model, "UpperTorso", Vector3.new(0.45, 0.4, 0.15), CFrame.new(side * 0.26, s.Y / 2 - 0.25, z) * CFrame.Angles(0, 0, side * 0.35), trim)
	end
	piece(model, "UpperTorso", Vector3.new(0.2, 0.22, 0.18), CFrame.new(0, s.Y / 2 - 0.25, z - 0.02), trim)
end

local function build(spot: BasePart)
	local who = spot:GetAttribute("Who")
	if type(who) ~= "string" or not spot.Parent or spot.Parent:FindFirstChild(`Shopkeeper_{who}`) then
		return
	end
	local cfg = Config.Npc
	local d = Instance.new("HumanoidDescription")
	d.HairAccessory = tostring(cfg.Hair)
	d.Head = cfg.Head
	local skin, pants = Color3.fromHex(cfg.Skin), Color3.fromHex(cfg.Pants)
	d.HeadColor, d.LeftArmColor, d.RightArmColor = skin, skin, skin
	d.TorsoColor = Color3.fromHex(cfg.ShirtColor) -- (a white shirt under the vest)
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
	dress(model, Color3.fromHex(cfg.Vest[who] or cfg.Vest.Shop), Color3.fromHex(cfg.Trim))
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
