--!strict
-- Pen cats walk around (task 1.8), on this client only: each cat in Workspace.PenCats rests (idle or
-- sleep) for Config.Pen.RestSeconds, then walks to a random spot in its pen's Area at WanderSpeed.
-- The server places the cats once and never moves them, so nothing fights over their position.
-- Sets the cat's "Anim" attribute locally (CatAnimController plays it).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PenCatsController = {}

type State = { target: Vector3?, restUntil: number }

local states: { [Model]: State } = {}
local RANGE = 220

local function area(index: number): BasePart?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	local pen = pens and pens:FindFirstChild(`Pen{index}`)
	local a = pen and pen:FindFirstChild("Area")
	return if a and a:IsA("BasePart") then a else nil
end

local function randomPoint(a: BasePart): Vector3
	local s = a.Size
	return (a.CFrame * CFrame.new((math.random() - 0.5) * s.X, -s.Y / 2, (math.random() - 0.5) * s.Z)).Position
end

local function step(dt: number)
	local folder = workspace:FindFirstChild("PenCats")
	local camera = workspace.CurrentCamera
	if not folder or not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	local rest = Config.Pen.RestSeconds
	for _, penFolder in folder:GetChildren() do
		for _, cat in penFolder:GetChildren() do
			if not cat:IsA("Model") then
				continue
			end
			local index = cat:GetAttribute("PenIndex")
			local pivot = cat:GetPivot()
			if type(index) ~= "number" or (pivot.Position - eye).Magnitude > RANGE then
				continue
			end
			local state = states[cat]
			if not state then
				state = { target = nil, restUntil = now + math.random() * rest[2] }
				states[cat] = state
				cat:SetAttribute("Anim", if math.random() < 0.25 then "sleep" else "idle")
			end
			if state.target then
				local pos = pivot.Position
				local to = Vector3.new(state.target.X, pos.Y, state.target.Z)
				local delta = to - pos
				local dist = delta.Magnitude
				local move = Config.Pen.WanderSpeed * dt
				if dist <= move or dist < 0.05 then
					state.target = nil
					state.restUntil = now + rest[1] + math.random() * (rest[2] - rest[1])
					cat:SetAttribute("Anim", if math.random() < 0.25 then "sleep" else "idle")
				else
					local nextPos = pos + delta.Unit * move
					cat:PivotTo(CFrame.lookAt(nextPos, nextPos + delta.Unit))
				end
			elseif now >= state.restUntil then
				local a = area(index)
				if a then
					state.target = randomPoint(a)
					cat:SetAttribute("Anim", "walk")
				else
					state.restUntil = now + rest[2]
				end
			end
		end
	end
	for cat in states do
		if not cat.Parent then
			states[cat] = nil
		end
	end
end

function PenCatsController.Start(_self: any)
	RunService.Heartbeat:Connect(step)
end

return PenCatsController
