--!strict
-- Events on this client (task 1.18): while a Mythical / Secret cat is out (workspace attribute LiveEvent),
-- a big banner, an arrow over your head pointing at it, and a label on its light beam with the distance,
-- seen from anywhere. A Secret event also tints the sky and plays the event music (when the developer has
-- picked one: Config.Events.MusicId). The countdown itself is in the HUD (HudController).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local EventController = {}

local me = Players.LocalPlayer
local arrow: Model? = nil
local banner: TextLabel
local tint: ColorCorrectionEffect
local music: Sound? = nil

local function makeArrow(color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "EventArrow"
	local function p(size: Vector3, cf: CFrame, isWedge: boolean?)
		local part: BasePart = if isWedge then Instance.new("WedgePart") else Instance.new("Part")
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = m
		return part
	end
	local shaft = p(Vector3.new(0.6, 0.3, 2.4), CFrame.new(0, 0, 0.6))
	m.PrimaryPart = shaft
	-- head: a wedge pointing forward (-Z), lying flat
	p(Vector3.new(0.3, 1.8, 1.4), CFrame.new(0, 0, -1.2) * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), true)
	m.Parent = workspace
	return m
end

local function beamLabel(beam: BasePart, kind: string)
	if beam:FindFirstChild("EventLabel") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EventLabel"
	gui.Adornee = beam
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(220, 46)
	gui.StudsOffsetWorldSpace = Vector3.new(-Config.Events.BeamHeight / 2 + 12, 0, 0)
	gui.MaxDistance = math.huge
	gui.LightInfluence = 0
	local label = Kit.text(gui, "Text", UDim2.fromScale(1, 1), UDim2.new(), 26, true)
	label.TextScaled = true
	label.TextColor3 = beam.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	gui.Parent = beam
	gui:SetAttribute("Kind", kind)
end

local function setLive(kind: string?)
	if arrow then
		arrow:Destroy()
		arrow = nil
	end
	local secret = kind == "Secret"
	TweenService:Create(tint, TweenInfo.new(2), {
		TintColor = if secret then Color3.fromRGB(205, 185, 255) else Color3.new(1, 1, 1),
		Saturation = if secret then 0.25 else 0,
	}):Play()
	if music then
		if secret then
			music:Play()
		else
			music:Stop()
		end
	end
	if kind then
		arrow = makeArrow(if secret then Color3.fromHex("18c9b9") else Color3.fromHex("ff5fa2"))
		banner.Text = Lang.text(if secret then "EventOutSecret" else "EventOutMythical")
		banner.TextColor3 = if secret then Color3.fromHex("8ff7ee") else Color3.fromHex("ffb3dd")
		banner.Visible = true
		local s = banner:FindFirstChildOfClass("UIScale") :: UIScale
		s.Scale = if secret then 0.5 else 0.7
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(if secret then 6 else 4, function()
			banner.Visible = false
		end)
	end
end

local function step()
	local kind = workspace:GetAttribute("LiveEvent")
	local pos = workspace:GetAttribute("LiveEventPos")
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
	if arrow and typeof(pos) == "Vector3" and root and root:IsA("BasePart") then
		local from = root.Position + Vector3.new(0, 6.5, 0)
		local target = Vector3.new(pos.X, from.Y, pos.Z)
		if (target - from).Magnitude > 1 then
			arrow:PivotTo(CFrame.lookAt(from, target))
		end
	end
	if type(kind) == "string" then
		for _, c in workspace:GetChildren() do
			if c:IsA("BasePart") and c:GetAttribute("Event") == kind then
				beamLabel(c, kind)
				local gui = c:FindFirstChild("EventLabel")
				local label = gui and gui:FindFirstChild("Text")
				if label and label:IsA("TextLabel") and root and root:IsA("BasePart") and typeof(pos) == "Vector3" then
					label.Text = Lang.text("EventDistance", { event = Lang.text("Event" .. kind), m = math.floor((pos - root.Position).Magnitude) })
				end
			end
		end
	end
end

function EventController.Start(_self: any)
	tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "EventTint"
	tint.Parent = Lighting
	if Config.Events.MusicId ~= 0 then
		local s = Instance.new("Sound")
		s.SoundId = `rbxassetid://{Config.Events.MusicId}`
		s.Looped = true
		s.Volume = 0.6
		s.Parent = workspace
		music = s
	end
	local gui = Kit.screen("EventBanner", 18)
	banner = Kit.text(gui, "Banner", UDim2.new(0.76, 0, 0, 64), UDim2.new(0.12, 0, 0.24, 0), 44, true)
	banner.TextScaled = true
	banner.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = banner
	workspace:GetAttributeChangedSignal("LiveEvent"):Connect(function()
		local k = workspace:GetAttribute("LiveEvent")
		setLive(if type(k) == "string" then k else nil)
	end)
	local k = workspace:GetAttribute("LiveEvent")
	if type(k) == "string" then
		setLive(k)
	end
	RunService.RenderStepped:Connect(step)
end

return EventController
