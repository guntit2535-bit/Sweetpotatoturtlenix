--!strict
-- New-player tutorial on this client (task V4, redone in round 2: "arrows first, moves on by itself"). The
-- server owns the step (player attribute "Tutorial", TutorialService) and moves it on when the player does it;
-- this draws the guide:
--   * a banner at the bottom: the step number, a title, one short line, progress dots, a small Skip
--   * yellow arrow chevrons on the ground flowing from the player to the target
--   * a big bouncing 3D arrow over the target, and the target outlined (Highlight)
--   * an arrow at the screen edge (with the distance) while the target is off screen
--   * a pointing hand on the button to press (the Shop button; the hold button while fishing)
-- Targets: the Backyard, the nearest cat you can catch, your pen, your weights, the Shop button.

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
local STEPS = 7
local TITLE = { "TutT1", "TutT2", "TutT3", "TutT4", "TutT5", "TutT6", "TutT7" }
local BODY = { "TutWelcome", "TutZone", "TutCatch", "TutCarry", "TutTrain", "TutShop", "TutDone" }
local YELLOW = Color3.fromHex("ffd23f")
local CHEVRONS = 14
local SPACING = 5

local banner: Frame
local title: TextLabel
local body: TextLabel
local stepLabel: TextLabel
local dots: { Frame } = {}
local skipButton: TextButton
local edge: TextLabel
local edgeDist: TextLabel -- (not inside the arrow: it would turn with it)
local hand: TextLabel
local guide: Folder
local chevrons: { Model } = {}
local arrow: Model
local highlight: Highlight
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

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
local function nearestCat(root: BasePart): Model?
	local folder = workspace:FindFirstChild("WildCats")
	if not folder then
		return nil
	end
	local strength = me:GetAttribute("Strength")
	local best, bestD, any, anyD = nil, math.huge, nil, math.huge
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m.PrimaryPart then
			local d = (m.PrimaryPart.Position - root.Position).Magnitude
			local kg = m:GetAttribute("Kg")
			local ok = type(kg) == "number" and type(strength) == "number" and kg <= strength
			if ok and d < bestD then
				best, bestD = m, d
			end
			if d < anyD then
				any, anyD = m, d
			end
		end
	end
	return best or any
end

-- The target of a step: a world position and, when there is one, the model to outline.
local function target(s: number, root: BasePart): (Vector3?, Instance?)
	if s == 2 then
		local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
		local dir = if flat.Magnitude > 1 then flat.Unit else Vector3.new(0, 0, -1)
		return dir * (Config.World.LobbyRadius + 24), nil
	elseif s == 3 then
		if me:GetAttribute("Fishing") ~= nil then
			return nil, nil -- reeling: the hand points at the hold button instead
		end
		local cat = nearestCat(root)
		return if cat and cat.PrimaryPart then cat.PrimaryPart.Position else nil, cat
	elseif s == 4 then
		local pen = myPen()
		local spawnPart = pen and pen:FindFirstChild("Spawn")
		return if spawnPart and spawnPart:IsA("BasePart") then spawnPart.Position else (pen and pen:GetPivot().Position), nil
	elseif s == 5 then
		local pen = myPen()
		local w = pen and pen:FindFirstChild("Weights")
		local stand = w and w:FindFirstChild("Stand")
		return if stand and stand:IsA("BasePart") then stand.Position else nil, w
	end
	return nil, nil
end

-- The button the hand points at (screen), if any.
local function pointAt(s: number): GuiObject?
	if s == 6 then
		local gui = me.PlayerGui:FindFirstChild("HudLeft")
		local b = gui and gui:FindFirstChild("Shop", true)
		return if b and b:IsA("GuiObject") then b else nil
	elseif s == 3 and me:GetAttribute("Fishing") ~= nil then
		local gui = me.PlayerGui:FindFirstChild("FishingGui")
		local b = gui and gui:FindFirstChild("Hold")
		return if b and b:IsA("GuiObject") and b.Visible then b else nil
	end
	return nil
end

local function texts(): (string, string)
	local s = step() or 1
	local key = BODY[s] or "TutWelcome"
	if s == 3 and me:GetAttribute("Fishing") ~= nil then
		key = "TutHold"
	end
	return Lang.text(TITLE[s] or "TutT1"), Lang.text(key, { money = Format.short(Config.Tutorial.Reward) })
end

local function refresh()
	local s = step()
	banner.Visible = s ~= nil
	if not s then
		return
	end
	local t, b = texts()
	title.Text = t
	body.Text = b
	stepLabel.Text = Lang.text("TutStep", { n = s, max = STEPS })
	for i, d in dots do
		d.BackgroundColor3 = if i < s then C.green elseif i == s then YELLOW else C.grey
		d.Size = if i == s then UDim2.fromOffset(22, 22) else UDim2.fromOffset(14, 14)
	end
	Kit.setButtonText(skipButton, Lang.text("TutSkip"))
	;(skipButton.Parent :: GuiObject).Visible = s < STEPS
end

local function neon(parent: Instance, size: Vector3, cf: CFrame, wedge: boolean?): BasePart
	local p: BasePart = if wedge then Instance.new("WedgePart") else Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	p.Color = YELLOW
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function buildWorld()
	guide = Instance.new("Folder")
	guide.Name = "TutorialGuide"
	-- ground chevrons: ">" made of two bars, pointing along their -Z
	for _ = 1, CHEVRONS do
		local m = Instance.new("Model")
		m.Name = "Chevron"
		local root = neon(m, Vector3.new(0.1, 0.1, 0.1), CFrame.new())
		root.Transparency = 1
		m.PrimaryPart = root
		for _, side in { -1, 1 } do
			neon(m, Vector3.new(0.7, 0.15, 2.8), CFrame.new(side * 0.9, 0, 0.8) * CFrame.Angles(0, side * math.rad(-40), 0))
		end
		m.Parent = guide
		table.insert(chevrons, m)
	end
	-- the big arrow over the target: a shaft and a head pointing down
	arrow = Instance.new("Model")
	arrow.Name = "Arrow"
	local root = neon(arrow, Vector3.new(0.1, 0.1, 0.1), CFrame.new())
	root.Transparency = 1
	arrow.PrimaryPart = root
	neon(arrow, Vector3.new(1.1, 2.6, 1.1), CFrame.new(0, 2.6, 0))
	for _, side in { -1, 1 } do
		-- two wedges back to back make a triangle pointing down
		neon(arrow, Vector3.new(1.1, 1.8, 1.4), CFrame.new(side * 0.7, 0.6, 0) * CFrame.Angles(0, side * math.pi / 2, math.pi), true)
	end
	arrow.Parent = guide
	highlight = Instance.new("Highlight")
	highlight.FillColor = YELLOW
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = YELLOW
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = guide
end

local function buildGui()
	local gui = Kit.screen("Tutorial", 12)
	banner = Instance.new("Frame")
	banner.Name = "Bubble"
	banner.AnchorPoint = Vector2.new(0.5, 1)
	banner.Position = UDim2.new(0.5, 0, 1, -84) -- above the hotbar; toasts use the top
	banner.Size = UDim2.fromOffset(560, 116)
	banner.BackgroundColor3 = C.panel
	banner.Visible = false
	banner.Parent = gui
	Kit.corner(banner, 22)
	Kit.stroke(banner, 4, nil, true)
	Kit.ears(banner, 22, { 0.08, 0.92 }, C.panel, C.pink)
	local fit = Instance.new("UIScale")
	fit.Parent = banner
	-- the step number in a yellow circle
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(72, 72)
	pill.Position = UDim2.fromOffset(14, 16)
	pill.BackgroundColor3 = YELLOW
	pill.Parent = banner
	Kit.corner(pill, 36)
	Kit.stroke(pill, 3, nil, true)
	stepLabel = Kit.text(pill, "Step", UDim2.fromScale(1, 1), UDim2.new(), 24, true)
	title = Kit.text(banner, "Title", UDim2.new(1, -224, 0, 34), UDim2.fromOffset(98, 8), 28, true)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromHex("8a4dd6")
	body = Kit.text(banner, "Body", UDim2.new(1, -224, 0, 46), UDim2.fromOffset(98, 42), 20)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextScaled = true
	local sizer = Instance.new("UITextSizeConstraint")
	sizer.MaxTextSize = 21
	sizer.Parent = body
	-- progress dots
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(98, 88)
	row.Size = UDim2.fromOffset(240, 24)
	row.Parent = banner
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.Parent = row
	for i = 1, STEPS do
		local d = Instance.new("Frame")
		d.LayoutOrder = i
		d.Size = UDim2.fromOffset(14, 14)
		d.Parent = row
		Kit.corner(d, 11)
		Kit.stroke(d, 2, nil, true)
		table.insert(dots, d)
	end
	skipButton = Kit.button(banner, "Skip", C.grey, UDim2.fromOffset(104, 40), UDim2.new(1, -116, 0.5, -22))
	skipButton.Activated:Connect(function()
		remote:FireServer("skip")
	end)
	-- the edge arrow and the pointing hand
	edge = Kit.text(gui, "Edge", UDim2.fromOffset(84, 84), UDim2.new(), 56, true)
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
	edge.Text = "➤"
	edge.TextColor3 = YELLOW
	edge.Visible = false
	edgeDist = Kit.text(gui, "EdgeDist", UDim2.fromOffset(90, 26), UDim2.new(), 22, true)
	edgeDist.AnchorPoint = Vector2.new(0.5, 0)
	edgeDist.Visible = false
	hand = Kit.text(gui, "Hand", UDim2.fromOffset(70, 70), UDim2.new(), 54, true)
	hand.AnchorPoint = Vector2.new(0.5, 0.5)
	hand.Text = "👈"
	hand.Visible = false
	local function rescale()
		local cam = workspace.CurrentCamera
		local size = cam and cam.ViewportSize or Vector2.new(1000, 700)
		fit.Scale = math.clamp(math.min((size.X - 240) / 600, size.Y / 760), 0.55, 1)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
end

local function ground(p: Vector3): Vector3
	local hit = workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rayParams)
	return if hit then hit.Position else Vector3.new(p.X, 0, p.Z)
end

local function update()
	local s = step()
	local character = me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local now = os.clock()
	local pos: Vector3?, model: Instance? = nil, nil
	if s and root and root:IsA("BasePart") then
		pos, model = target(s, root)
	end
	if pos and root and root:IsA("BasePart") and character then
		if guide.Parent ~= workspace then
			guide.Parent = workspace
		end
		rayParams.FilterDescendantsInstances = { guide, character }
		-- chevrons flowing along the ground towards the target
		local from = Vector3.new(root.Position.X, 0, root.Position.Z)
		local to = Vector3.new(pos.X, 0, pos.Z)
		local flat = to - from
		local len = flat.Magnitude
		local dir = if len > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
		local phase = (now * 6) % SPACING
		for i, c in chevrons do
			local d = 3 + (i - 1) * SPACING + phase
			if d < len - 2 then
				local p = ground(from + dir * d) + Vector3.new(0, 0.18, 0)
				c:PivotTo(CFrame.lookAt(p, p + dir))
				local fade = math.clamp(math.min(d - 3, len - 2 - d) / 4, 0, 1)
				for _, part in c:GetChildren() do
					if part:IsA("BasePart") and part ~= c.PrimaryPart then
						part.Transparency = 1 - 0.85 * fade
					end
				end
			else
				c:PivotTo(CFrame.new(0, -500, 0))
			end
		end
		-- the big arrow bouncing over the target, and its outline
		local bob = math.abs(math.sin(now * 3)) * 1.4
		local topY = pos.Y
		if model and model:IsA("Model") then
			local cf, size = model:GetBoundingBox()
			topY = math.max(topY, cf.Position.Y + size.Y / 2)
		end
		arrow:PivotTo(CFrame.new(pos.X, topY + 1.5 + bob, pos.Z) * CFrame.Angles(0, now * 2, 0))
		highlight.Adornee = model
		highlight.Enabled = model ~= nil
		-- the edge arrow while the target is off screen
		local cam = workspace.CurrentCamera
		local sp, on = cam:WorldToViewportPoint(pos + Vector3.new(0, 2, 0))
		local size = cam.ViewportSize
		if on and sp.X > 40 and sp.X < size.X - 40 and sp.Y > 40 and sp.Y < size.Y - 40 then
			edge.Visible = false
			edgeDist.Visible = false
		else
			local c2 = Vector2.new(size.X / 2, size.Y / 2)
			local v = Vector2.new(sp.X, sp.Y) - c2
			if sp.Z < 0 then
				v = -v
			end
			if v.Magnitude < 1 then
				v = Vector2.new(0, -1)
			end
			local p = c2 + v.Unit * math.min(size.X, size.Y) * 0.38
			edge.Position = UDim2.fromOffset(p.X, p.Y)
			edge.Rotation = math.deg(math.atan2(v.Y, v.X))
			edge.Visible = true
			edgeDist.Position = UDim2.fromOffset(p.X, p.Y + 30)
			edgeDist.Text = `{math.floor(len)} m`
			edgeDist.Visible = true
		end
	else
		if guide.Parent then
			guide.Parent = nil
		end
		highlight.Enabled = false
		edge.Visible = false
		edgeDist.Visible = false
	end
	-- the hand pointing at a button
	local b = if s then pointAt(s) else nil
	if b then
		local nudge = math.sin(now * 6) * 8
		local cx = b.AbsolutePosition.Y + b.AbsoluteSize.Y / 2 -- the button's middle (same screen space as the hand)
		if b.AbsolutePosition.X > workspace.CurrentCamera.ViewportSize.X / 2 then
			hand.Position = UDim2.fromOffset(b.AbsolutePosition.X - 34 - nudge, cx)
			hand.Text = "👉"
		else
			hand.Position = UDim2.fromOffset(b.AbsolutePosition.X + b.AbsoluteSize.X + 34 + nudge, cx)
			hand.Text = "👈"
		end
		hand.Visible = true
	else
		hand.Visible = false
	end
end

function TutorialController.Start(_self: any)
	remote = Remotes.event("Tutorial")
	buildWorld()
	buildGui()
	refresh()
	me:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	me:GetAttributeChangedSignal("Fishing"):Connect(refresh)
	Lang.changed:Connect(refresh)
	RunService.RenderStepped:Connect(update)
	-- step 6: opening the Shop window counts
	task.spawn(function()
		local shop = me.PlayerGui:WaitForChild("ShopWindow", 30)
		if shop and shop:IsA("ScreenGui") then
			shop:GetPropertyChangedSignal("Enabled"):Connect(function()
				if step() == 6 and shop.Enabled then
					remote:FireServer("ack", 6)
				end
			end)
		end
	end)
end

return TutorialController
