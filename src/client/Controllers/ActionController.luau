--!strict
-- X2 (revision 4 item 16): the big action button. While you carry a cat and stand at your own pen (player attribute
-- AtPen, set by CarryService), a green "Put in pen" button shows near the top of the screen; pressing it asks the
-- server (PutInPen), which checks again and puts the cat in. Until then you keep carrying it (and bats can knock
-- it loose). Placed bottom-centre above the hotbar (above the tutorial bubble while that shows), clear of both
-- side columns on a phone and of the cat carried over your head.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Config = require(Shared:WaitForChild("Config"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Mutation = require(Shared:WaitForChild("Mutation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local ActionController = {}

local me = Players.LocalPlayer
local SIZE = Vector2.new(300, 84)

local spot: Frame
local button: TextButton
local pulse: UIScale

-- X3: the same button sells the carried cat at the plaza's sell booth (AtBooth = what it sells for)
-- 2026-11-15 (bag): holding a cat from the bag on the sell booth's pad: the button sells that one (SellCat)
local function heldCat(): Tool?
	local character = me.Character
	if not character then
		return nil
	end
	for _, t in character:GetChildren() do
		if t:IsA("Tool") and type(t:GetAttribute("CatId")) == "string" then
			return t
		end
	end
	return nil
end

local function onBoothPad(): boolean
	local map = workspace:FindFirstChild("Map")
	local market = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Market")
	local booth = market and market:FindFirstChild("SellBooth")
	local pad = booth and booth:FindFirstChild("Pad")
	local character = me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not pad or not pad:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return false
	end
	local d = Vector3.new(root.Position.X - pad.Position.X, 0, root.Position.Z - pad.Position.Z).Magnitude
	return d <= Config.Market.PadRange and math.abs(root.Position.Y - pad.Position.Y) < 12
end

-- what the held cat sells for (as the server counts it: tier, kg, mutation, the money bonus)
local function heldValue(t: Tool): number
	local tier, kg = t:GetAttribute("Tier"), t:GetAttribute("Kg")
	if type(tier) ~= "number" or type(kg) ~= "number" then
		return 0
	end
	local mut = t:GetAttribute("Mutation")
	local mult = me:GetAttribute("IncomeMult")
	return math.floor(CatRules.sellPrice(tier, kg) * Mutation.money(if type(mut) == "string" then mut else nil) * (if type(mult) == "number" then mult else 1))
end

local function mode(): string?
	if Kit.anyWindowOpen() then
		return nil
	end
	if me:GetAttribute("CarryingCat") == nil then
		return if heldCat() and onBoothPad() then "sellHeld" else nil
	elseif me:GetAttribute("AtPen") == true then
		return "pen"
	elseif type(me:GetAttribute("AtBooth")) == "number" then
		return "sell"
	end
	return nil
end

local function refresh()
	local m = mode()
	spot.Visible = m ~= nil
	if m == "pen" then
		Kit.setButtonText(button, Lang.text("PutInPen"))
		Kit.setButtonColor(button, Kit.Colors.green)
	elseif m == "sellHeld" then
		local t = heldCat()
		Kit.setButtonText(button, Lang.text("SellCarried", { money = Format.short(if t then heldValue(t) else 0) }))
		Kit.setButtonColor(button, Kit.Colors.yellow)
	elseif m == "sell" then
		local v = me:GetAttribute("AtBooth")
		Kit.setButtonText(button, Lang.text("SellCarried", { money = Format.short(if type(v) == "number" then v else 0) }))
		Kit.setButtonColor(button, Kit.Colors.yellow)
	end
end

function ActionController.Start(_self: any)
	local remote = Remotes.event("PutInPen")
	local sellRemote = Remotes.event("SellCarried")
	local sellCatRemote = Remotes.event("SellCat")
	local gui = Kit.screen("ActionButton", 6)
	gui.ClipToDeviceSafeArea = false -- same screen space as the tutorial's glow frame
	spot = Instance.new("Frame")
	spot.Name = "Spot"
	spot.BackgroundTransparency = 1
	spot.AnchorPoint = Vector2.new(0.5, 1)
	spot.Position = UDim2.new(0.5, 0, 1, -82)
	spot.Size = UDim2.fromOffset(SIZE.X, SIZE.Y + 6)
	spot.Visible = false
	spot.Parent = gui
	Kit.fit(spot, 720, 0.55, Kit.TouchMin)
	-- a gentle pulse inside the screen scale, so it catches the eye
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromScale(1, 1)
	inner.Parent = spot
	pulse = Instance.new("UIScale")
	pulse.Parent = inner
	button = Kit.button(inner, "PutInPen", Kit.Colors.green, UDim2.fromOffset(SIZE.X, SIZE.Y), UDim2.new())
	local icon = 62
	Kit.icon(button, "MyCats", icon, UDim2.new(0, 8, 0.5, -icon / 2))
	local label = button:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.new(1, -icon - 18, 1, -8)
	label.Position = UDim2.fromOffset(icon + 12, 4)
	label.TextScaled = true
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 36
	limit.Parent = label
	button.Activated:Connect(function()
		local m = mode()
		if m == "sellHeld" then
			local t = heldCat()
			if t then
				sellCatRemote:FireServer(t:GetAttribute("CatId"))
			end
		elseif m == "sell" then
			sellRemote:FireServer()
		else
			remote:FireServer()
		end
	end)
	RunService.RenderStepped:Connect(function()
		if spot.Visible then
			pulse.Scale = 1 + 0.05 * math.sin(os.clock() * 5)
			-- bottom centre just above the hotbar, or just above the tutorial bubble while it shows (near the top it
			-- covered the cat over your head)
			local bubble = me.PlayerGui:FindFirstChild("Tutorial")
			local b = bubble and bubble:FindFirstChild("Bubble")
			local bottom = gui.AbsoluteSize.Y - 82
			if b and b:IsA("GuiObject") and b.Visible then
				bottom = math.min(bottom, b.AbsolutePosition.Y - 26) -- the bubble's ears stick up ~20 px
			end
			spot.Position = UDim2.fromOffset(gui.AbsoluteSize.X / 2, bottom)
		end
	end)
	-- (the held cat and the booth pad are not attributes: checked a few times a second)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if me:GetAttribute("CarryingCat") == nil then
				refresh()
			end
		end
	end)
	for _, attr in { "AtPen", "AtBooth", "CarryingCat" } do
		me:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	Kit.windowChanged:Connect(refresh)
	Lang.changed:Connect(refresh)
	refresh()
end

return ActionController
