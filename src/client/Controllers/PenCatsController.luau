--!strict
-- Pen cats walk around (task 1.8), on this client only: each cat in Workspace.PenCats rests (idle or
-- sleep) for Config.Pen.RestSeconds, then walks to a random spot in its pen's Area at WanderSpeed. Cats farther
-- than Config.CatAnim.Mid from the camera keep resting; far walkers step every Pen.FarStepSeconds (V5i: phones).
-- The server places the cats once and never moves them, so nothing fights over their position.
-- Sets the cat's "Anim" attribute locally (CatAnimController plays it).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PenCatsController = {}

type State = { target: Vector3?, restUntil: number, lastMove: number, scale: number }

local states: { [Model]: State } = {}
local nextSweep = 0
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
			local state = states[cat]
			-- a resting cat costs nothing until its rest is over (V5i: 480 cats in full pens)
			if state and not state.target and now < state.restUntil then
				continue
			end
			local index = cat:GetAttribute("PenIndex")
			local pivot = cat:GetPivot()
			if type(index) ~= "number" or (pivot.Position - eye).Magnitude > RANGE then
				if state then
					state.restUntil = now + rest[1]
				end
				continue
			end
			if not state then
				state = { target = nil, restUntil = now + math.random() * rest[2], lastMove = now, scale = math.max(1, cat:GetScale()) }
				states[cat] = state
				cat:SetAttribute("Anim", if math.random() < 0.25 then "sleep" else "idle")
			end
			if state.target then
				local pos = pivot.Position
				-- near cats move every frame (only their Root: CatAnimController poses the blocks after it); far
				-- ones every FarStepSeconds with the whole model (V5i: moving blocks is the cost)
				local near = (pos - eye).Magnitude <= Config.CatAnim.Near * state.scale
				local elapsed = math.min(now - state.lastMove, 0.5)
				if not near and elapsed < Config.Pen.FarStepSeconds then
					continue
				end
				state.lastMove = now
				local to = Vector3.new(state.target.X, pos.Y, state.target.Z)
				local delta = to - pos
				local dist = delta.Magnitude
				local move = Config.Pen.WanderSpeed * math.max(dt, elapsed)
				if dist <= move or dist < 0.05 then
					state.target = nil
					state.restUntil = now + rest[1] + math.random() * (rest[2] - rest[1])
					cat:SetAttribute("Anim", if math.random() < 0.25 then "sleep" else "idle")
				else
					local nextPos = pos + delta.Unit * move
					local cf = CFrame.lookAt(nextPos, nextPos + delta.Unit)
					local root = cat.PrimaryPart
					if root and near and cat:GetAttribute("Rig") == "anchored" then
						root.CFrame = cf * root.PivotOffset:Inverse()
					else
						cat:PivotTo(cf)
					end
				end
			elseif now >= state.restUntil then
				state.lastMove = now
				local a = area(index)
				if (pivot.Position - eye).Magnitude > Config.CatAnim.Mid * state.scale then
					-- far from the camera: keep resting (V5i: walking far cats cost the most and nobody sees it)
					state.restUntil = now + rest[1]
				elseif a then
					state.target = randomPoint(a)
					cat:SetAttribute("Anim", "walk")
				else
					state.restUntil = now + rest[2]
				end
			end
		end
	end
	if now >= nextSweep then
		nextSweep = now + 2
		for cat in states do
			if not cat.Parent then
				states[cat] = nil
			end
		end
	end
end

function PenCatsController.Start(_self: any)
	-- the average time this takes a frame, every second on the player ("PenCatsMs" attribute: phone checks, V5i)
	local spent, frames, since = 0, 0, os.clock()
	RunService.Heartbeat:Connect(function(dt: number)
		local t = os.clock()
		step(dt)
		spent += os.clock() - t
		frames += 1
		if t - since >= 1 then
			game:GetService("Players").LocalPlayer:SetAttribute("PenCatsMs", math.floor(spent / frames * 1e5) / 100)
			spent, frames, since = 0, 0, t
		end
	end)
end

return PenCatsController
