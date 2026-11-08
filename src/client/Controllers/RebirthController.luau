--!strict
-- Rebirth on this client (task 2.7): a Rebirth button under the Strength panel opens a window with the
-- Strength needed, what it gives and what it resets; the server checks and does it (Rebirth remote).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatRules = require(Shared:WaitForChild("CatRules"))
local Format = require(Shared:WaitForChild("Format"))
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
	gives.Text = Lang.text("RebirthGives")
	resets.Text = Lang.text("RebirthResets")
	if not n then
		need.Text = Lang.text("RebirthMax")
		Kit.setButtonColor(go, C.grey)
	else
		need.Text = Lang.text("RebirthNeed", { strength = Format.short(n), have = Format.short(strength) })
		need.TextColor3 = if strength >= n then Color3.fromHex("2f9a3a") else C.coral
		Kit.setButtonColor(go, if strength >= n then C.green else C.grey)
	end
	Kit.setButtonText(go, Lang.text("RebirthGo"))
end

function RebirthController.Start(_self: any)
	local remote = Remotes.event("Rebirth")
	window = Kit.window({ name = "RebirthWindow", width = 520, height = 330, color = C.purple })
	need = Kit.text(window.body, "Need", UDim2.new(1, 0, 0, 32), UDim2.new(), 24)
	gives = Kit.text(window.body, "Gives", UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 40), 20)
	gives.TextColor3 = Color3.fromHex("2f9a3a")
	resets = Kit.text(window.body, "Resets", UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 96), 17)
	resets.TextColor3 = C.muted
	go = Kit.button(window.body, "Go", C.green, UDim2.fromOffset(220, 56), UDim2.new(0.5, -110, 1, -66))
	go.Activated:Connect(function()
		remote:FireServer()
		window.setOpen(false)
	end)
	-- the button under the Strength panel
	local gui = Kit.screen("RebirthButton", 2)
	open = Kit.button(gui, "Open", C.purple, UDim2.fromOffset(150, 44), UDim2.new(1, -162, 0, 252))
	local holder = open.Parent :: Frame
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	-- right under the Strength panel (HudController: top 92, height 150, scaled the same way)
	local camera = workspace.CurrentCamera
	local s = if camera then math.clamp(camera.ViewportSize.Y / 720, 0.6, 1) else 1
	scale.Scale = s
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, -12, 0, 92 + 150 * s + 10)
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
