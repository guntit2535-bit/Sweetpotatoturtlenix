--!strict
-- The plaza shopkeepers (client 2026-11-15: cute girls in the two stalls; style A chibi voxel). MapKit puts each one in
-- her stall at an invisible "NpcSpot" (her feet) with her body and waving-arm meshes; here, on this client only, she
-- breathes (a small bob), waves (the arm swings about her shoulder) and turns a little toward this player when they
-- come near. Decoration: nothing is sent to the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NpcController = {}

local me = Players.LocalPlayer
local SHOULDER = Vector3.new(1, 2, 0) -- in her feet's space at scale 1 (MapKit: the arm's origin x the "Scale" attribute)
local NEAR = 40 -- studs: she looks at a player this close
local MAX_TURN = math.rad(55)

type Npc = {
	spot: BasePart,
	base: CFrame,
	body: BasePart,
	arm: BasePart?,
	bodyOff: CFrame,
	armOff: CFrame?,
	shoulder: CFrame,
	yaw: number,
	phase: number,
}

local npcs: { [BasePart]: Npc } = {}

local function scan()
	local map = workspace:FindFirstChild("Map")
	local lobby = map and map:FindFirstChild("Lobby")
	local market = lobby and lobby:FindFirstChild("Market")
	if not market then
		return
	end
	for _, spot in market:GetDescendants() do
		if spot:IsA("BasePart") and spot.Name == "NpcSpot" and not npcs[spot] then
			local who = spot:GetAttribute("Who")
			local stall = spot.Parent
			local body = stall and stall:FindFirstChild(`NPC_{who}`)
			local arm = stall and stall:FindFirstChild(`NPC_{who}_Arm`)
			if body and body:IsA("BasePart") then
				local base = spot.CFrame
				local sc = spot:GetAttribute("Scale")
				local shoulder = CFrame.new(SHOULDER * (if type(sc) == "number" then sc else 1))
				npcs[spot] = {
					spot = spot,
					base = base,
					body = body,
					arm = if arm and arm:IsA("BasePart") then arm else nil,
					bodyOff = base:ToObjectSpace(body.CFrame),
					armOff = if arm and arm:IsA("BasePart") then shoulder:Inverse() * base:ToObjectSpace(arm.CFrame) else nil,
					shoulder = shoulder,
					yaw = 0,
					phase = if who == "Sell" then 1.7 else 0,
				}
			end
		end
	end
end

function NpcController.Start(_self: any)
	task.spawn(function()
		while true do
			scan()
			task.wait(2) -- (the market may stream in later)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for spot, n in npcs do
			if not spot.Parent or not n.body.Parent then
				npcs[spot] = nil
				continue
			end
			-- turn toward this player when near (within MAX_TURN of her stall's facing)
			local want = 0
			if root and root:IsA("BasePart") then
				local rel = n.base:PointToObjectSpace(root.Position)
				local flat = Vector3.new(rel.X, 0, rel.Z)
				if flat.Magnitude < NEAR and flat.Magnitude > 0.5 then
					want = math.clamp(math.atan2(-rel.X, -rel.Z), -MAX_TURN, MAX_TURN)
				end
			end
			n.yaw += (want - n.yaw) * math.min(1, dt * 4)
			local bob = math.sin(t * 2 + n.phase) * 0.08
			local feet = n.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, n.yaw, 0)
			n.body.CFrame = feet * n.bodyOff
			if n.arm and n.armOff then
				local wave = math.sin(t * 5 + n.phase) * 0.4
				n.arm.CFrame = feet * n.shoulder * CFrame.Angles(0, 0, wave) * n.armOff
			end
		end
	end)
end

return NpcController
