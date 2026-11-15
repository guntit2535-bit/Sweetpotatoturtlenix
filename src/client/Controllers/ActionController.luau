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
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local ActionController = {}

local me = Players.LocalPlayer
local SIZE = Vector2.new(300, 84)

local spot: Frame
local button: TextButton
local pulse: UIScale

-- (2026-11-15: selling moved to the sell booth's talk menu, SellBoothController; this button is only "Put in pen")
local function mode(): string?
	if Kit.anyWindowOpen() then
		return nil
	end
	if me:GetAttribute("CarryingCat") ~= nil and me:GetAttribute("AtPen") == true then
		return "pen"
	end
	return nil
end

local function refresh()
	local m = mode()
	spot.Visible = m ~= nil
	if m == "pen" then
		Kit.setButtonText(button, Lang.text("PutInPen"))
		Kit.setButtonColor(button, Kit.Colors.green)
	end
end

function ActionController.Start(_self: any)
	local remote = Remotes.event("PutInPen")
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
		if mode() == "pen" then
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
	for _, attr in { "AtPen", "CarryingCat" } do
		me:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	Kit.windowChanged:Connect(refresh)
	Lang.changed:Connect(refresh)
	refresh()
end

return ActionController
