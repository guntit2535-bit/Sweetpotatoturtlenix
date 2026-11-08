--!strict
-- Labels over wild cats (task 1.10): "Rare · 32 kg" in the tier colour, and "Need 50 Strength" in red when
-- this player is not strong enough yet. Drawn on this client in its language; only within
-- Config.WildCats.LabelRange.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatRules = require(Shared:WaitForChild("CatRules"))
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local WildCatTagController = {}

local me = Players.LocalPlayer
local tags: { [Model]: BillboardGui } = {}

local function update(m: Model, gui: BillboardGui)
	local tier = m:GetAttribute("Tier")
	local base = m:GetAttribute("Kg")
	if type(tier) ~= "number" or type(base) ~= "number" then
		return
	end
	-- R4: the model carries the base weight; I see it at my rebirths' scale
	local rb = me:GetAttribute("Rebirths")
	local kg = CatRules.kgFor(base, if type(rb) == "number" then rb else 0)
	local t = Config.Tiers[tier]
	local top = gui:FindFirstChild("Top") :: TextLabel
	local need = gui:FindFirstChild("Need") :: TextLabel
	top.Text = Lang.text("CatLabel", { tier = Lang.text("Tier" .. t.Key), kg = Format.money(kg) })
	top.TextColor3 = Color3.fromHex(t.Color):Lerp(Color3.new(1, 1, 1), 0.15)
	local strength = me:GetAttribute("Strength")
	local tooHeavy = type(strength) == "number" and strength < kg
	need.Visible = tooHeavy
	need.Text = Lang.text("CatNeed", { kg = Format.short(math.ceil(kg)) })
end

local function add(inst: Instance)
	if not inst:IsA("Model") or tags[inst] then
		return
	end
	local root = inst.PrimaryPart
	if not root then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CatTag"
	gui.Adornee = root
	gui.Size = UDim2.fromOffset(200, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y * 0.75 + 1.5, 0)
	gui.MaxDistance = Config.WildCats.LabelRange
	gui.LightInfluence = 0
	gui.Parent = root
	local top = Kit.text(gui, "Top", UDim2.new(1, 0, 0, 28), UDim2.new(), 24, true)
	top.TextScaled = true
	local need = Kit.text(gui, "Need", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 28), 20, true)
	need.TextColor3 = Color3.fromHex("ff6b6b")
	need.TextScaled = true
	tags[inst] = gui
	update(inst, gui)
end

local function remove(inst: Instance)
	if inst:IsA("Model") and tags[inst] then
		tags[inst]:Destroy()
		tags[inst] = nil
	end
end

local function updateAll()
	for m, gui in tags do
		if m.Parent then
			update(m, gui)
		else
			tags[m] = nil
		end
	end
end

function WildCatTagController.Start(_self: any)
	for _, m in CollectionService:GetTagged("WildCat") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("WildCat"):Connect(function(m)
		task.defer(add, m) -- its parts may arrive a moment later (streaming)
	end)
	CollectionService:GetInstanceRemovedSignal("WildCat"):Connect(remove)
	me:GetAttributeChangedSignal("Strength"):Connect(updateAll)
	me:GetAttributeChangedSignal("Rebirths"):Connect(updateAll)
	Lang.changed:Connect(updateAll)
	task.spawn(function()
		while true do
			task.wait(2)
			for _, m in CollectionService:GetTagged("WildCat") do
				add(m)
			end
		end
	end)
end

return WildCatTagController
