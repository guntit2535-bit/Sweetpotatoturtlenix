--!strict
-- Rebirth on this client (task 2.7): a Rebirth button under the Strength panel opens a window with the
-- Strength needed, what it gives and what it resets; the server checks and does it (Rebirth remote).
-- R9 (mockup 07): "you keep" / "you reset" cards around a glowing cat, "Rebirth 3 -> 4", bonus chips from
-- Config.Rebirth, a Strength progress bar and the big button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatRules = require(Shared:WaitForChild("CatRules"))
local Format = require(Shared:WaitForChild("Format"))
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local CatPortrait = require(script.Parent.Parent.UI.CatPortrait)
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local RebirthController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local window: Kit.Window
local need: TextLabel
local gives: TextLabel
local resets: TextLabel
local go: TextButton
local step: TextLabel
local chips: { TextLabel } = {}
local barFill: Frame
local barText: TextLabel
local keepTitle: TextLabel
local resetTitle: TextLabel
local open: TextButton

local function num(name: string): number
	local v = me:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

local function refresh()
	local r = num("Rebirths")
	local n = CatRules.rebirthNeed(r)
	local strength = num("Strength")
	Kit.setButtonText(open, Lang.text("RebirthButton") .. (if r > 0 then ` {r}` else ""))
	window.title.Text = Lang.text("RebirthTitle", { n = r + 1 })
	gives.Text = Lang.text("RebirthKeeps")
	resets.Text = Lang.text("RebirthResetsShort")
	keepTitle.Text = Lang.text("RebirthYouKeep")
	resetTitle.Text = Lang.text("RebirthYouReset")
	step.Text = Lang.text("RebirthStep", { from = r, to = r + 1 })
	local R = Config.Rebirth
	chips[1].Text = Lang.text("RebirthChipMoney", { m = R.MoneyMult })
	chips[2].Text = Lang.text("RebirthChipStrength", { m = R.StrengthMult })
	chips[3].Text = Lang.text("RebirthChipCats", { m = R.KgMult })
	if not n then
		need.Text = Lang.text("RebirthMax")
		barFill.Size = UDim2.fromScale(1, 1)
		barText.Text = ""
		Kit.setButtonColor(go, C.grey)
	else
		need.Text = ""
		local frac = math.clamp(strength / n, 0, 1)
		barFill.Size = UDim2.fromScale(frac, 1)
		barText.Text = Lang.text("RebirthBar", { have = Format.short(strength), need = Format.short(n), pct = math.floor(frac * 100) })
		Kit.setButtonColor(go, if strength >= n then C.purple else C.grey)
	end
	Kit.setButtonText(go, Lang.text("RebirthGo"))
end

function RebirthController.Start(_self: any)
	local remote = Remotes.event("Rebirth")
	window = Kit.window({ name = "RebirthWindow", width = 660, height = 470, color = C.purple })
	local body = window.body
	-- the two cards
	local function card(x: number, color: Color3): (TextLabel, TextLabel)
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(196, 150)
		f.Position = UDim2.new(x, if x > 0.5 then -196 else 0, 0, 8)
		f.BackgroundColor3 = C.soft
		f.Parent = body
		Kit.corner(f, 18)
		Kit.stroke(f, 3, nil, true)
		local head = Instance.new("Frame")
		head.AnchorPoint = Vector2.new(0.5, 0.5)
		head.Position = UDim2.new(0.5, 0, 0, 2)
		head.Size = UDim2.new(0.86, 0, 0, 34)
		head.BackgroundColor3 = color
		head.Parent = f
		Kit.corner(head, 17)
		Kit.stroke(head, 3, nil, true)
		local ht = Kit.text(head, "Title", UDim2.new(1, -10, 1, 0), UDim2.fromOffset(5, 0), 20, true)
		ht.TextScaled = true
		local text = Kit.text(f, "Text", UDim2.new(1, -16, 1, -30), UDim2.fromOffset(8, 24), 21)
		text.TextWrapped = true
		return ht, text
	end
	keepTitle, gives = card(0, C.green)
	resetTitle, resets = card(1, C.pink)
	-- the glowing cat in the middle
	local glow = Instance.new("Frame")
	glow.Name = "Picture"
	glow.AnchorPoint = Vector2.new(0.5, 0)
	glow.Position = UDim2.new(0.5, 0, 0, 0)
	glow.Size = UDim2.fromOffset(190, 160)
	glow.BackgroundColor3 = Color3.fromHex("c9a6ff")
	glow.BackgroundTransparency = 0.35
	glow.Parent = body
	Kit.corner(glow, 80)
	local mythical = Cats.ById[Cats.ByTier[5][1]]
	if mythical then
		CatPortrait.make(glow, mythical.Look)
	end
	step = Kit.text(body, "Step", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 164), 34, true)
	-- bonus chips
	for i = 1, 3 do
		local chip = Instance.new("Frame")
		chip.Size = UDim2.fromOffset(196, 38)
		chip.Position = UDim2.new((i - 1) / 3, 4, 0, 210)
		chip.BackgroundColor3 = C.green
		chip.Parent = body
		Kit.corner(chip, 19)
		Kit.stroke(chip, 3, nil, true)
		local t = Kit.text(chip, "Text", UDim2.new(1, -12, 1, -4), UDim2.fromOffset(6, 2), 20, true)
		t.TextScaled = true
		chips[i] = t
	end
	-- Strength progress bar
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, 262)
	bar.Size = UDim2.new(1, 0, 0, 36)
	bar.BackgroundColor3 = Color3.fromHex("e2e2ea")
	bar.Parent = body
	Kit.corner(bar, 18)
	Kit.stroke(bar, 3, nil, true)
	barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = C.green
	barFill.Parent = bar
	Kit.corner(barFill, 18)
	barText = Kit.text(bar, "Text", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 20, true)
	need = Kit.text(body, "Need", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 262), 24, true)
	go = Kit.button(body, "Go", C.purple, UDim2.fromOffset(300, 60), UDim2.new(0.5, -150, 1, -66))
	go.Activated:Connect(function()
		remote:FireServer()
		window.setOpen(false)
	end)
	-- the button under the Strength panel
	local gui = Kit.screen("RebirthButton", 2)
	open = Kit.button(gui, "Open", C.purple, UDim2.fromOffset(150, 44), UDim2.new(1, -162, 0, 252))
	local holder = open.Parent :: Frame
	-- R9: the icon on the left, the label beside it
	Kit.icon(open, "Rebirth", 40, UDim2.fromOffset(4, 2))
	local openLabel = open:FindFirstChild("Label") :: TextLabel
	openLabel.Position = UDim2.fromOffset(44, 0)
	openLabel.Size = UDim2.new(1, -50, 1, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	-- right under the Strength panel (HudController: top 92, height 150, scaled the same way)
	local camera = workspace.CurrentCamera
	local s = if camera then math.clamp(camera.ViewportSize.Y / 720, 0.6, 1) else 1
	scale.Scale = s
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, -12, 0, 104 + 160 * s + 12)
	open.Activated:Connect(function()
		refresh()
		window.setOpen(not window.isOpen())
	end)
	refresh()
	for _, a in { "Rebirths", "Strength" } do
		me:GetAttributeChangedSignal(a):Connect(refresh)
	end
	Lang.changed:Connect(refresh)
end

return RebirthController
