--!strict
-- Fishing on this client (tasks 1.11 / 1.12): using the Rod picks the wild cat you are looking at (within
-- Config.Fishing.CastRange) and asks Cast; the server answers FishStart and decides everything after that.
-- The bar is drawn from a local copy of the server's state (shared/FishingBar) that every FishState
-- snapshot resets. Hold = left mouse button / Space / the big HOLD button (phones). FishEnd closes it:
-- a "Caught!" card when you won, a toast otherwise.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FishingBar = require(Shared:WaitForChild("FishingBar"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)
local ToastController = require(script.Parent.ToastController)

local FishingController = {}

local C = Kit.Colors
local BAR_H = 360
local player = Players.LocalPlayer

local castRemote: RemoteEvent
local holdRemote: RemoteEvent
local giveUpRemote: RemoteEvent

local gui: ScreenGui
local zoneFrame: Frame
local catIcon: Frame
local meterFill: Frame
local hint: TextLabel
local holdButton: TextButton
local giveUp: TextButton
local card: Frame

local active: { id: string, bar: FishingBar.State }? = nil
local holdingMouse = false
local holdingKey = false
local holdingButton = false
local sentHold = false

local function holding(): boolean
	return holdingMouse or holdingKey or holdingButton
end

local function sendHold()
	local h = holding()
	if active and h ~= sentHold then
		sentHold = h
		holdRemote:FireServer(h)
	end
end

-- The wild cat the player means: in range, the one closest to where the camera looks.
local function pickTarget(): Model?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not root:IsA("BasePart") or not camera then
		return nil
	end
	local look = camera.CFrame.LookVector
	local best: Model? = nil
	local bestScore = -math.huge
	for _, m in CollectionService:GetTagged("WildCat") do
		if m:IsA("Model") and m.Parent then
			local pos = m:GetPivot().Position
			local offset = pos - root.Position
			local dist = offset.Magnitude
			if dist <= Config.Fishing.CastRange then
				local fromCam = (pos - camera.CFrame.Position).Unit
				local score = look:Dot(fromCam) * 2 - dist / Config.Fishing.CastRange
				if score > bestScore then
					best = m
					bestScore = score
				end
			end
		end
	end
	return best
end

local function onRodUsed()
	if active then
		return
	end
	local target = pickTarget()
	if not target then
		ToastController.show("FishNoCat", nil, "info")
		return
	end
	local id = target:GetAttribute("WildId")
	if type(id) == "string" then
		castRemote:FireServer(id)
	end
end

local function hookTool(tool: Instance)
	if tool:IsA("Tool") and tool.Name == "Rod" and not tool:GetAttribute("FishHooked") then
		tool:SetAttribute("FishHooked", true)
		tool.Activated:Connect(onRodUsed)
		tool.Unequipped:Connect(function()
			if active then
				giveUpRemote:FireServer()
			end
		end)
	end
end

local function build()
	gui = Kit.screen("FishingGui", 5)
	gui.Enabled = false
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -190, 0.45, 0)
	panel.Size = UDim2.fromOffset(150, BAR_H + 60)
	panel.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = math.clamp(h / 640, 0.55, 1)
	end
	fit()

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(0, 50)
	bar.Size = UDim2.fromOffset(78, BAR_H)
	bar.BackgroundColor3 = Color3.fromHex("27407a")
	bar.ClipsDescendants = true
	bar.Parent = panel
	Kit.corner(bar, 16)
	Kit.stroke(bar, 4, nil, true)
	zoneFrame = Instance.new("Frame")
	zoneFrame.Name = "Zone"
	zoneFrame.AnchorPoint = Vector2.new(0, 0.5)
	zoneFrame.Size = UDim2.new(1, -10, 0, 80)
	zoneFrame.Position = UDim2.new(0, 5, 0.5, 0)
	zoneFrame.BackgroundColor3 = C.green
	zoneFrame.BackgroundTransparency = 0.1
	zoneFrame.Parent = bar
	Kit.corner(zoneFrame, 12)
	Kit.stroke(zoneFrame, 2, Color3.fromHex("1f7a2c"), true)
	catIcon = Instance.new("Frame")
	catIcon.Name = "Cat"
	catIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	catIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	catIcon.Size = UDim2.fromOffset(46, 40)
	catIcon.BackgroundColor3 = Color3.fromHex("f2a65a")
	catIcon.ZIndex = 3
	catIcon.Parent = bar
	Kit.corner(catIcon, 10)
	Kit.stroke(catIcon, 3, nil, true)
	for _, x in { 0.3, 0.7 } do
		local eye = Instance.new("Frame")
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(x, 0.45)
		eye.Size = UDim2.fromOffset(7, 9)
		eye.BackgroundColor3 = C.ink
		eye.ZIndex = 4
		eye.Parent = catIcon
		Kit.corner(eye, 4)
		local ear = Instance.new("Frame")
		ear.AnchorPoint = Vector2.new(0.5, 0.5)
		ear.Position = UDim2.new(x, 0, 0, -2)
		ear.Size = UDim2.fromOffset(13, 13)
		ear.Rotation = 45
		ear.BackgroundColor3 = Color3.fromHex("f2a65a")
		ear.ZIndex = 2
		ear.Parent = catIcon
		Kit.stroke(ear, 3, nil, true)
	end

	local meter = Instance.new("Frame")
	meter.Name = "Meter"
	meter.Position = UDim2.fromOffset(94, 50)
	meter.Size = UDim2.fromOffset(32, BAR_H)
	meter.BackgroundColor3 = C.white
	meter.ClipsDescendants = true
	meter.Parent = panel
	Kit.corner(meter, 12)
	Kit.stroke(meter, 4, nil, true)
	meterFill = Instance.new("Frame")
	meterFill.Name = "Fill"
	meterFill.AnchorPoint = Vector2.new(0, 1)
	meterFill.Position = UDim2.fromScale(0, 1)
	meterFill.Size = UDim2.fromScale(1, 0.3)
	meterFill.BackgroundColor3 = C.yellow
	meterFill.Parent = meter
	Kit.corner(meterFill, 10)

	giveUp = Kit.button(panel, "GiveUp", C.coral, UDim2.fromOffset(126, 40), UDim2.fromOffset(0, 0))
	giveUp.Activated:Connect(function()
		giveUpRemote:FireServer()
	end)

	hint = Kit.text(gui, "Hint", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.15, 0, 0, 70), 28, true)
	hint.TextScaled = true

	holdButton = Kit.button(gui, "Hold", C.green, UDim2.fromOffset(150, 150), UDim2.new(1, -170, 1, -190))
	local holdHolder = holdButton.Parent :: Frame
	local hs = Instance.new("UIScale")
	hs.Parent = holdHolder
	hs.Scale = if UserInputService.TouchEnabled then 1 else 0.7
	Kit.corner(holdButton, 75)
	local lip = holdHolder:FindFirstChild("Lip")
	if lip then
		Kit.corner(lip, 75)
	end
	holdButton.MouseButton1Down:Connect(function()
		holdingButton = true
		sendHold()
	end)
	holdButton.MouseButton1Up:Connect(function()
		holdingButton = false
		sendHold()
	end)
	holdButton.MouseLeave:Connect(function()
		holdingButton = false
		sendHold()
	end)

	-- the "Caught!" card
	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.42)
	card.Size = UDim2.fromOffset(420, 150)
	card.BackgroundColor3 = C.white
	card.Visible = false
	card.Parent = Kit.screen("CaughtCard", 15)
	Kit.corner(card, 22)
	Kit.stroke(card, 4, nil, true)
	local title = Kit.text(card, "Title", UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 8), 40, true)
	title.TextColor3 = C.yellow
	local body = Kit.text(card, "Body", UDim2.new(1, -24, 0, 70), UDim2.fromOffset(12, 64), 24)
	body.TextWrapped = true
end

local function refreshTexts()
	hint.Text = Lang.text("FishHoldHint")
	Kit.setButtonText(holdButton, Lang.text("FishHold"))
	Kit.setButtonText(giveUp, Lang.text("FishGiveUp"))
end

local function draw()
	local s = active
	if not s then
		return
	end
	local b = s.bar
	zoneFrame.Size = UDim2.new(1, -10, b.params.zone, 0)
	zoneFrame.Position = UDim2.new(0, 5, 1 - b.zone, 0)
	catIcon.Position = UDim2.new(0.5, 0, 1 - b.cat, 0)
	meterFill.Size = UDim2.fromScale(1, b.meter)
	meterFill.BackgroundColor3 = if b.meter > 0.66 then C.green elseif b.meter > 0.33 then C.yellow else C.coral
	zoneFrame.BackgroundColor3 = if FishingBar.inside(b) then C.green else Color3.fromHex("8fd38f")
end

local function showCard(vars: { [string]: any })
	(card:FindFirstChild("Title") :: TextLabel).Text = Lang.text("CaughtTitle")
	local tier = vars.tier
	local tierText = if type(tier) == "string" then Lang.text("Tier" .. tier) else ""
	;(card:FindFirstChild("Body") :: TextLabel).Text = Lang.text("FishCaught", { name = vars.name, tier = tierText, kg = vars.kg })
		.. (if type(vars.mutation) == "string" and vars.mutation ~= "" then " · " .. Lang.text("Mut" .. vars.mutation) .. "!" else "")
	card.Visible = true
	local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = card
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.6, function()
		card.Visible = false
	end)
end

function FishingController.Start(_self: any)
	castRemote = Remotes.event("Cast")
	holdRemote = Remotes.event("FishHold")
	giveUpRemote = Remotes.event("FishGiveUp")
	build()
	refreshTexts()
	Lang.changed:Connect(refreshTexts)

	local function watch(container: Instance)
		for _, c in container:GetChildren() do
			hookTool(c)
		end
		container.ChildAdded:Connect(hookTool)
	end
	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(character)
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = true
			sendHold()
		elseif input.KeyCode == Enum.KeyCode.Space then
			holdingKey = true
			sendHold()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = false
			sendHold()
		elseif input.KeyCode == Enum.KeyCode.Space then
			holdingKey = false
			sendHold()
		end
	end)

	Remotes.event("FishStart").OnClientEvent:Connect(function(id: unknown, tier: unknown, snap: unknown, rod: unknown, easy: unknown)
		if type(id) ~= "string" or type(tier) ~= "number" or type(snap) ~= "table" then
			return
		end
		local bar = FishingBar.new(0, FishingBar.params(tier, if type(rod) == "number" then rod else 1, easy == true))
		FishingBar.apply(bar, snap :: { number })
		active = { id = id, bar = bar }
		sentHold = false
		holdingMouse = false
		holdingKey = false
		holdingButton = false
		gui.Enabled = true
		draw()
	end)
	Remotes.event("FishState").OnClientEvent:Connect(function(id: unknown, snap: unknown)
		if active and id == active.id and type(snap) == "table" then
			FishingBar.apply(active.bar, snap :: { number })
		end
	end)
	Remotes.event("FishEnd").OnClientEvent:Connect(function(key: unknown, vars: unknown, caught: unknown)
		active = nil
		gui.Enabled = false
		if caught == true and type(vars) == "table" then
			showCard(vars :: any)
		elseif type(key) == "string" then
			ToastController.show(key, if type(vars) == "table" then vars :: any else nil, if key == "FishGaveUp" then "info" else "bad")
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if active then
			FishingBar.step(active.bar, dt, holding())
			draw()
		end
	end)
end

return FishingController
