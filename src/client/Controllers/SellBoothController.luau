--!strict
-- The sell booth's talk menu (developer 2026-11-15: "press E" instead of standing on the green pad). A "Sell" prompt
-- on the booth's shopkeeper (made here, in this player's language) opens a menu at the bottom of the screen: the
-- shopkeeper's line and four numbered choices to tap or click (no number keys: 1-4 pick Roblox's hotbar slots):
--   1 Sell my bag! (count, money)   -> SellAtBooth("all"): every cat in the bag (not placed, not locked)
--   2 Sell this one! (money)        -> SellAtBooth("this"): the cat carried over the head, else the one held
--   3 How much is this worth?      -> the shopkeeper says it (worked out here, as the server counts it)
--   4 Never mind                   -> closes
-- The server checks everything again (BoothService). The menu closes when the player walks away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cats = require(Shared:WaitForChild("Cats"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Format = require(Shared:WaitForChild("Format"))
local Mutation = require(Shared:WaitForChild("Mutation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)

local SellBoothController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local M = Config.Market
local WIDTH, OPTION_H, GAP = 540, 50, 8
local CHOICES = 4

local remote: RemoteEvent
local gui: ScreenGui
local speech: TextLabel
local options: { TextButton } = {}
local prompt: ProximityPrompt? = nil
local promptSpot: BasePart? = nil
local isOpen = false

local function money(): number
	local m = me:GetAttribute("IncomeMult")
	return if type(m) == "number" then m else 1
end

local function value(tier: number, kg: number, mutation: string?): number
	return math.floor(CatRules.sellPrice(tier, kg) * Mutation.money(mutation) * money())
end

-- The cat "this" means: the one carried over the head, else the one held from the bag. (name, value) or nil.
local function thisCat(): (string?, number?)
	local carried = me:GetAttribute("CarryingCat")
	if type(carried) == "string" then
		local design = Cats.ById[carried]
		local v = me:GetAttribute("CarryValue")
		return if design then design.Name else "?", if type(v) == "number" then v else nil
	end
	local character = me.Character
	if character then
		for _, t in character:GetChildren() do
			if t:IsA("Tool") and type(t:GetAttribute("CatId")) == "string" then
				local tier, kg, mut = t:GetAttribute("Tier"), t:GetAttribute("Kg"), t:GetAttribute("Mutation")
				if type(tier) == "number" and type(kg) == "number" then
					return t.Name, value(tier, kg, if type(mut) == "string" then mut else nil)
				end
			end
		end
	end
	return nil, nil
end

-- The bag: how many cats can be sold (not placed, not locked) and what they bring.
local function bag(): (number, number)
	local data = PlayerData.get()
	local count, total = 0, 0
	if data and type(data.Cats) == "table" then
		for _, cat in data.Cats do
			if not cat.Placed and not cat.Locked then
				local design = Cats.ById[cat.Kind]
				if design then
					count += 1
					total += value(design.Tier, cat.Kg, cat.Mutation)
				end
			end
		end
	end
	return count, total
end

local function refresh()
	local count, total = bag()
	Kit.setButtonText(options[1], `1  {Lang.text("SellOptAll", { count = count, money = Format.short(total) })}`)
	local _, v = thisCat()
	Kit.setButtonText(options[2], `2  {if v then Lang.text("SellOptThis", { money = Format.short(v) }) else Lang.text("SellOptThisNone")}`)
	Kit.setButtonText(options[3], `3  {Lang.text("SellOptWorth")}`)
	Kit.setButtonText(options[4], `4  {Lang.text("SellOptBye")}`)
	Kit.setButtonColor(options[1], if count > 0 then C.green else C.grey)
	Kit.setButtonColor(options[2], if v then C.yellow else C.grey)
end

local function setOpen(on: boolean)
	isOpen = on
	gui.Enabled = on
	if prompt then
		prompt.Enabled = not on
	end
	if on then
		speech.Text = Lang.text("SellGreet")
		refresh()
	end
end

local function say(key: string, vars: { [string]: any }?)
	speech.Text = Lang.text(key, vars)
end

local function choose(n: number)
	if not isOpen then
		return
	end
	if n == 1 then
		local count = bag()
		if count == 0 then
			say("SellBagEmpty")
			return
		end
		remote:FireServer("all")
		say("SellThanks")
		task.delay(1.4, function()
			if isOpen then
				setOpen(false)
			end
		end)
	elseif n == 2 then
		local name = thisCat()
		if not name then
			say("SellHoldOne")
			return
		end
		remote:FireServer("this")
		say("SellThanks")
		task.delay(1.4, function()
			if isOpen then
				setOpen(false)
			end
		end)
	elseif n == 3 then
		local name, v = thisCat()
		if name and v then
			say("SellWorthIs", { name = name, money = Format.short(v) })
		else
			say("SellHoldOne")
		end
	else
		setOpen(false)
	end
end

local function build()
	gui = Kit.screen("SellTalk", 8)
	gui.Enabled = false
	local n = CHOICES
	local height = 26 + 96 + n * (OPTION_H + GAP) + 18
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -16)
	holder.Size = UDim2.fromOffset(WIDTH, height)
	holder.Parent = gui
	Kit.fit(holder, 720, 0.5, Kit.TouchMin)
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = C.panel
	panel.Position = UDim2.fromOffset(0, 26)
	panel.Size = UDim2.new(1, 0, 1, -26)
	panel.Parent = holder
	Kit.corner(panel, 22)
	Kit.stroke(panel, 4, nil, true)
	Kit.ears(panel, 34, { 0.12, 0.88 }, C.pink)
	-- the shopkeeper's name on a pink tab
	local tab = Instance.new("Frame")
	tab.Name = "Name"
	tab.BackgroundColor3 = C.pink
	tab.Position = UDim2.fromOffset(24, 0)
	tab.Size = UDim2.fromOffset(200, 44)
	tab.Parent = holder
	Kit.corner(tab, 22)
	Kit.stroke(tab, 3, nil, true)
	local name = Kit.text(tab, "Label", UDim2.new(1, -16, 1, -6), UDim2.fromOffset(8, 3), 24, true)
	name.TextScaled = true
	name.Text = Lang.text("SellNpc")
	-- what the shopkeeper says
	local bubble = Instance.new("Frame")
	bubble.Name = "Speech"
	bubble.BackgroundColor3 = C.white
	bubble.Position = UDim2.fromOffset(16, 30)
	bubble.Size = UDim2.new(1, -32, 0, 66)
	bubble.Parent = panel
	Kit.corner(bubble, 16)
	Kit.stroke(bubble, 3, C.peach, true)
	speech = Kit.text(bubble, "Text", UDim2.new(1, -24, 1, -8), UDim2.fromOffset(12, 4), 24)
	speech.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 26
	limit.Parent = speech
	for i = 1, n do
		local b = Kit.button(panel, `Option{i}`, C.yellow, UDim2.new(1, -32, 0, OPTION_H), UDim2.fromOffset(16, 30 + 66 + 12 + (i - 1) * (OPTION_H + GAP)))
		local label = b:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Position = UDim2.fromOffset(14, 0)
			label.Size = UDim2.new(1, -40, 1, 0)
		end
		b.Activated:Connect(function()
			choose(i)
		end)
		options[i] = b
	end
	Kit.setButtonColor(options[3], C.sky)
	Kit.setButtonColor(options[4], C.coral)
	Lang.changed:Connect(function()
		name.Text = Lang.text("SellNpc")
		if prompt then
			prompt.ActionText = Lang.text("SellPrompt")
			prompt.ObjectText = Lang.text("SellNpc")
		end
		if isOpen then
			speech.Text = Lang.text("SellGreet")
			refresh()
		end
	end)
end

-- The prompt sits on the sell booth's shopkeeper spot (it may stream in later).
local function placePrompt()
	local map = workspace:FindFirstChild("Map")
	local market = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Market")
	local booth = market and market:FindFirstChild("SellBooth")
	local spot = booth and booth:FindFirstChild("NpcSpot")
	if not spot or not spot:IsA("BasePart") or spot == promptSpot then
		return
	end
	if prompt then
		prompt:Destroy()
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = "SellPrompt"
	p.ActionText = Lang.text("SellPrompt")
	p.ObjectText = Lang.text("SellNpc")
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = M.PromptRange
	p.RequiresLineOfSight = false
	p.UIOffset = Vector2.new(0, -40)
	p.Parent = spot
	p.Triggered:Connect(function()
		setOpen(true)
	end)
	prompt, promptSpot = p, spot
end

function SellBoothController.Start(_self: any)
	remote = Remotes.event("SellAtBooth")
	build()
	PlayerData.changed:Connect(function()
		if isOpen then
			refresh()
		end
	end)
	for _, attr in { "CarryingCat", "CarryValue" } do
		me:GetAttributeChangedSignal(attr):Connect(function()
			if isOpen then
				refresh()
			end
		end)
	end
	task.spawn(function()
		while true do
			placePrompt()
			-- walked away (or holding something new): close / refresh
			if isOpen then
				local character = me.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local spot = promptSpot
				if not root or not root:IsA("BasePart") or not spot or (root.Position - spot.Position).Magnitude > M.CloseRange then
					setOpen(false)
				else
					refresh()
				end
			end
			task.wait(0.4)
		end
	end)
end

return SellBoothController
