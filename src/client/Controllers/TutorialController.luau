--!strict
-- New-player tutorial on this client (task V4). The server owns the step (player attribute "Tutorial",
-- TutorialService); this draws it: a bubble at the bottom with the step's text (EN / TH), a Next / Let's go
-- button on the info steps, Skip, and a guide to the target: a light beam from the player plus a bouncing
-- marker over it (the Backyard, the nearest cat you can catch, your pen, your weights), or a pulsing ring on
-- the Shop button. Opening the Shop on step 6 tells the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local TutorialController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local remote: RemoteEvent
local TEXT = { "TutWelcome", "TutZone", "TutCatch", "TutCarry", "TutTrain", "TutShop", "TutDone" }
local ACK = { [1] = "TutNext", [7] = "TutGo" }

local panel: Frame
local body: TextLabel
local stepLabel: TextLabel
local nextButton: TextButton
local skipButton: TextButton
local ring: Frame
local beam: Beam
local from: Attachment
local to: Attachment
local marker: BillboardGui
local anchor: Part

local function step(): number?
	local s = me:GetAttribute("Tutorial")
	return if type(s) == "number" then s else nil
end

local function myPen(): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if not pens then
		return nil
	end
	for _, p in pens:GetChildren() do
		if p:GetAttribute("OwnerId") == me.UserId and p:IsA("Model") then
			return p
		end
	end
	return nil
end

-- The nearest wild cat this player can catch (Strength >= its kg); any wild cat if none.
local function nearestCat(root: BasePart): Vector3?
	local folder = workspace:FindFirstChild("WildCats")
	if not folder then
		return nil
	end
	local strength = me:GetAttribute("Strength")
	local best, bestD, any, anyD = nil, math.huge, nil, math.huge
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m.PrimaryPart then
			local pos = m.PrimaryPart.Position
			local d = (pos - root.Position).Magnitude
			local kg = m:GetAttribute("Kg")
			local ok = type(kg) == "number" and type(strength) == "number" and kg <= strength
			if ok and d < bestD then
				best, bestD = pos, d
			end
			if d < anyD then
				any, anyD = pos, d
			end
		end
	end
	return best or any
end

local function target(s: number, root: BasePart): Vector3?
	if s == 2 then
		-- straight out from the plaza to the Backyard
		local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
		local dir = if flat.Magnitude > 1 then flat.Unit else Vector3.new(0, 0, -1)
		return dir * (Config.World.LobbyRadius + 24) + Vector3.new(0, 3, 0)
	elseif s == 3 then
		return nearestCat(root)
	elseif s == 4 then
		local pen = myPen()
		local spawnPart = pen and pen:FindFirstChild("Spawn")
		return if spawnPart and spawnPart:IsA("BasePart") then spawnPart.Position else (pen and pen:GetPivot().Position)
	elseif s == 5 then
		local pen = myPen()
		local w = pen and pen:FindFirstChild("Weights")
		local stand = w and w:FindFirstChild("Stand")
		return if stand and stand:IsA("BasePart") then stand.Position else nil
	end
	return nil
end

local function shopButton(): GuiObject?
	local gui = me.PlayerGui:FindFirstChild("HudLeft")
	local b = gui and gui:FindFirstChild("Shop", true)
	return if b and b:IsA("GuiObject") then b else nil
end

local function refresh()
	local s = step()
	panel.Visible = s ~= nil
	if not s then
		ring.Visible = false
		return
	end
	local key = TEXT[s] or "TutWelcome"
	body.Text = Lang.text(key, { money = Format.short(Config.Tutorial.Reward) })
	stepLabel.Text = Lang.text("TutStep", { n = s, max = #TEXT })
	nextButton.Parent.Visible = ACK[s] ~= nil
	if ACK[s] then
		Kit.setButtonText(nextButton, Lang.text(ACK[s]))
	end
	Kit.setButtonText(skipButton, Lang.text("TutSkip"))
	skipButton.Parent.Visible = s < #TEXT
end

local function build()
	local gui = Kit.screen("Tutorial", 12)
	panel = Instance.new("Frame")
	panel.Name = "Bubble"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -84) -- bottom centre above the hotbar (toasts use the top)
	panel.Size = UDim2.fromOffset(520, 118)
	panel.BackgroundColor3 = C.panel
	panel.Visible = false
	panel.Parent = gui
	Kit.corner(panel, 22)
	Kit.stroke(panel, 4, nil, true)
	Kit.ears(panel, 22, { 0.1, 0.9 }, C.panel, C.pink)
	local fit = Instance.new("UIScale")
	fit.Parent = panel
	Kit.paw(panel, 40, UDim2.fromOffset(12, 14), C.pink, 0)
	stepLabel = Kit.text(panel, "Step", UDim2.fromOffset(60, 22), UDim2.fromOffset(4, 62), 16)
	stepLabel.TextColor3 = C.muted
	body = Kit.text(panel, "Body", UDim2.new(1, -210, 1, -16), UDim2.fromOffset(66, 8), 20)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextScaled = true
	local sizer = Instance.new("UITextSizeConstraint")
	sizer.MaxTextSize = 22
	sizer.Parent = body
	nextButton = Kit.button(panel, "Next", C.green, UDim2.fromOffset(128, 48), UDim2.new(1, -138, 0, 10))
	skipButton = Kit.button(panel, "Skip", C.grey, UDim2.fromOffset(128, 36), UDim2.new(1, -138, 1, -46))
	nextButton.Activated:Connect(function()
		local s = step()
		if s and ACK[s] then
			remote:FireServer("ack", s)
		end
	end)
	skipButton.Activated:Connect(function()
		remote:FireServer("skip")
	end)
	-- the ring on the Shop button (step 6)
	ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.BackgroundTransparency = 1
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Visible = false
	ring.Parent = gui
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0.5, 0)
	rc.Parent = ring
	local rs = Instance.new("UIStroke")
	rs.Thickness = 5
	rs.Color = C.yellow
	rs.Parent = ring
	-- the beam + marker (world)
	anchor = Instance.new("Part")
	anchor.Name = "TutorialTarget"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	to = Instance.new("Attachment")
	to.Parent = anchor
	from = Instance.new("Attachment")
	from.Name = "TutorialFrom"
	beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Color = ColorSequence.new(Color3.fromHex("ffd23f"))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.55) })
	beam.Width0 = 0.7
	beam.Width1 = 0.7
	beam.FaceCamera = true
	beam.LightEmission = 0.6
	beam.Segments = 20
	beam.Parent = anchor
	marker = Instance.new("BillboardGui")
	marker.Name = "Marker"
	marker.Size = UDim2.fromOffset(70, 80)
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.Adornee = anchor
	marker.Parent = anchor
	local arrow = Kit.text(marker, "Arrow", UDim2.fromScale(1, 0.55), UDim2.fromScale(0, 0.45), 46, true)
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromHex("ffd23f")
	Kit.paw(marker, 40, UDim2.new(0.5, -20, 0, 0), C.pink, 0)
	-- a phone-sized bubble
	local function rescale()
		local cam = workspace.CurrentCamera
		local size = cam and cam.ViewportSize or Vector2.new(1000, 700)
		fit.Scale = math.clamp(math.min((size.X - 240) / 560, size.Y / 760), 0.55, 1)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
end

local function update()
	local s = step()
	local character = me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pos = if s and root and root:IsA("BasePart") then target(s, root) else nil
	if pos and root and root:IsA("BasePart") then
		if from.Parent ~= root then
			from.Parent = root
		end
		anchor.Position = pos + Vector3.new(0, 1.5, 0)
		local bob = math.sin(os.clock() * 4) * 0.12
		marker.StudsOffsetWorldSpace = Vector3.new(0, 2.5 + bob * 4, 0)
		if anchor.Parent ~= workspace then
			anchor.Parent = workspace
		end
	elseif anchor.Parent then
		anchor.Parent = nil
	end
	-- the Shop ring
	local b = if s == 6 then shopButton() else nil
	if b then
		local size = math.max(b.AbsoluteSize.X, b.AbsoluteSize.Y) * (1.25 + math.sin(os.clock() * 5) * 0.08)
		ring.Position = UDim2.fromOffset(b.AbsolutePosition.X + b.AbsoluteSize.X / 2, b.AbsolutePosition.Y + b.AbsoluteSize.Y / 2)
		ring.Size = UDim2.fromOffset(size, size)
		ring.Visible = true
	else
		ring.Visible = false
	end
end

function TutorialController.Start(_self: any)
	remote = Remotes.event("Tutorial")
	build()
	refresh()
	me:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	Lang.changed:Connect(refresh)
	RunService.RenderStepped:Connect(update)
	-- step 6: opening the Shop window counts
	task.spawn(function()
		local shop = me.PlayerGui:WaitForChild("ShopWindow", 30)
		if not shop then
			return
		end
		local function check()
			if step() == 6 and (shop :: any).Enabled ~= false then
				local p = shop:FindFirstChild("Panel")
				if p and p:IsA("GuiObject") and p.Visible then
					remote:FireServer("ack", 6)
				end
			end
		end
		for _, d in shop:GetDescendants() do
			if d:IsA("GuiObject") and d.Name == "Panel" then
				d:GetPropertyChangedSignal("Visible"):Connect(check)
			end
		end
		if shop:IsA("ScreenGui") then
			shop:GetPropertyChangedSignal("Enabled"):Connect(check)
		end
	end)
end

return TutorialController
