--!strict
-- Money popups (task R3): every income tick each of your own pen cats near the camera shows "+$12" that
-- floats up and fades, and a "+$total" rises from the money pill. The amount is the cat's BaseRate (set by
-- PenService) x your IncomeMult (every money bonus), so it matches what the server pays. One label per cat,
-- reused every tick; popups start at slightly different times so they do not all jump at once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Kit = require(script.Parent.Parent.UI.Kit)

local IncomePopupController = {}

local me = Players.LocalPlayer
local GREEN = Color3.fromHex("4cd98a")

local function num(name: string, default: number): number
	local v = me:GetAttribute(name)
	return if type(v) == "number" then v else default
end

local function rise(gui: BillboardGui, label: TextLabel, base: Vector3)
	local cfg = Config.IncomePopup
	gui.StudsOffsetWorldSpace = base
	label.TextTransparency = 0
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	gui.Enabled = true
	local info = TweenInfo.new(cfg.Seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = base + Vector3.new(0, cfg.Rise, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
end

local function popOver(cat: Model, amount: number)
	local root = cat.PrimaryPart or cat:FindFirstChild("Root")
	if not root or not root:IsA("BasePart") then
		return
	end
	local gui = cat:FindFirstChild("IncomePop") :: BillboardGui?
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = "IncomePop"
		g.Size = UDim2.fromOffset(140, 34)
		g.LightInfluence = 0
		g.MaxDistance = Config.IncomePopup.Range
		g.Adornee = root
		local label = Kit.text(g, "Text", UDim2.fromScale(1, 1), UDim2.new(), 24, true)
		label.TextColor3 = GREEN
		g.Parent = cat
		gui = g
	end
	local g = gui :: BillboardGui
	local label = g:FindFirstChild("Text") :: TextLabel
	label.Text = "+$" .. Format.money(amount)
	rise(g, label, Vector3.new(0, (root :: BasePart).Size.Y / 2 + 1, 0))
end

local hudPop: TextLabel? = nil

-- "+$total" over the money pill (HudController's "Money" pill).
local function popHud(amount: number)
	if not hudPop or not hudPop.Parent then
		local gui = me:FindFirstChildOfClass("PlayerGui")
		local pill: Frame? = nil
		if gui then
			for _, d in gui:GetDescendants() do
				if d:IsA("Frame") and d.Name == "Money" and d:FindFirstChild("Money") then
					pill = d
					break
				end
			end
		end
		if not pill then
			return
		end
		local label = Kit.text(pill, "IncomePop", UDim2.fromOffset(200, 30), UDim2.new(1, 10, 0, 12), 22, true)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = GREEN
		label.TextTransparency = 1
		hudPop = label
	end
	local label = hudPop :: TextLabel
	label.Text = "+$" .. Format.money(amount)
	-- right of the pill (above it is the Speed pill), rising a little
	label.Position = UDim2.new(1, 10, 0, 12)
	label.TextTransparency = 0
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	local info = TweenInfo.new(Config.IncomePopup.Seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, { Position = UDim2.new(1, 10, 0, -8), TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
end

local function tick()
	local income = num("Income", 0)
	if income <= 0 then
		return
	end
	local step = Config.Economy.IncomeTick
	popHud(income * step)
	local folder = workspace:FindFirstChild("PenCats")
	local camera = workspace.CurrentCamera
	if not folder or not camera then
		return
	end
	local eye = camera.CFrame.Position
	local mult = num("IncomeMult", 1)
	for _, pen in folder:GetChildren() do
		for _, cat in pen:GetChildren() do
			if cat:IsA("Model") and cat:GetAttribute("OwnerId") == me.UserId then
				local base = cat:GetAttribute("BaseRate")
				if type(base) == "number" and base > 0 and (cat:GetPivot().Position - eye).Magnitude < Config.IncomePopup.Range then
					local amount = base * mult * step
					task.delay(math.random() * Config.IncomePopup.Spread, popOver, cat, amount)
				end
			end
		end
	end
end

function IncomePopupController.Start(_self: any)
	task.spawn(function()
		while true do
			task.wait(Config.Economy.IncomeTick)
			tick()
		end
	end)
end

return IncomePopupController
