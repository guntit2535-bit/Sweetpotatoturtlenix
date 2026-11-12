--!strict
-- The Rewards window (tasks 2.11 - 2.16): Daily (7-day login), Gifts (playtime), Quests, Codes, Group.
-- A Rewards button in the HUD's left column (W3, next to Rebirth) with a red "!" while something can be claimed (player
-- attribute RewardsReady). The client only asks (ClaimReward / RedeemCode); RewardsService decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local Hud = require(script.Parent.Parent.UI.Hud)

local RewardsController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local TABS = { "Daily", "Gifts", "Quests", "Codes", "Group" }
local window: Kit.Window
local list: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local current = "Daily"
local claimRemote: RemoteEvent
local codeRemote: RemoteEvent
local openButton: TextButton
local badge: Frame

local function today(): number
	return Rewards.day(math.floor(workspace:GetServerTimeNow()))
end

local function rewardText(r: any): string
	local parts = {}
	if r.Money then
		table.insert(parts, Lang.text("RewardMoneyLine"))
	end
	if r.Treat then
		for _, t in Config.Treats.List do
			if t.Key == r.Treat then
				table.insert(parts, Lang.text("Treat" .. t.Name))
			end
		end
	end
	if r.Crate then
		table.insert(parts, Lang.text("Crate" .. r.Crate))
	end
	return table.concat(parts, " + ")
end

local function row(order: number, title: string, line: string, color: Color3): Frame
	local f, picture = Kit.row(list, order, title, line, nil) -- R9 row (same as the shop), the gift icon in the box
	Kit.icon(picture, "Rewards", 56, UDim2.fromOffset(5, 5))
	local _ = color
	return f
end

local function button(f: Frame, text: string, color: Color3, onClick: (() -> ())?)
	local b = Kit.rowButton(f, text, color)
	if onClick then
		b.Activated:Connect(onClick)
	end
end

local function redraw()
	if not window then
		return
	end
	window.title.Text = Lang.text("RewardsTitle")
	for tab, b in tabButtons do
		Kit.setButtonText(b, Lang.text("Tab" .. tab))
		Kit.setButtonColor(b, if tab == current then C.yellow else C.tab)
	end
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local d = PlayerData.get() or {}
	if current == "Daily" then
		local step = d.LoginStep or 1
		local done = d.LoginDay == today()
		for i, r in Config.Login do
			local f = row(i, Lang.text("LoginDay", { n = i }), rewardText(r), if i == 7 then C.coral else C.sky)
			if i == step and not done then
				button(f, Lang.text("Claim"), C.green, function()
					claimRemote:FireServer("Login")
				end)
			elseif i == step and done then
				button(f, Lang.text("ComeBack"), C.grey)
			elseif i < step or (done and i == (step - 2) % #Config.Login + 1) then
				button(f, Lang.text("Claimed"), C.grey)
			end
		end
	elseif current == "Gifts" then
		local played = me:GetAttribute("PlaySeconds")
		local secs = if type(played) == "number" then played else (d.PlaySeconds or 0)
		for i, g in ipairs(Config.Playtime) do
			local f = row(i, Lang.text("GiftAt", { min = g.Minutes }), rewardText(g), C.green)
			if Rewards.claimed(d.PlayClaimed or 0, i) then
				button(f, Lang.text("Claimed"), C.grey)
			elseif secs >= g.Minutes * 60 then
				button(f, Lang.text("Claim"), C.green, function()
					claimRemote:FireServer("Playtime", i)
				end)
			else
				button(f, Lang.text("GiftWait", { time = Format.clock(g.Minutes * 60 - secs) }), C.grey)
			end
		end
	elseif current == "Quests" then
		for i, q in d.Quests or {} do
			local f = row(i, Lang.text("Quest" .. q.Kind, { goal = q.Goal }), Lang.text("QuestProgress", { n = q.Progress, goal = q.Goal }), C.purple)
			if q.Claimed then
				button(f, Lang.text("Claimed"), C.grey)
			elseif q.Progress >= q.Goal then
				button(f, Lang.text("Claim"), C.green, function()
					claimRemote:FireServer("Quest", i)
				end)
			end
		end
	elseif current == "Codes" then
		local f = row(1, Lang.text("TabCodes"), "", C.sky)
		local box = Instance.new("TextBox")
		box.Name = "Code"
		box.Size = UDim2.new(1, -220, 0, 34)
		box.Position = UDim2.fromOffset(32, 24)
		box.BackgroundColor3 = C.white
		box.Font = Kit.Font
		box.TextSize = 20
		box.PlaceholderText = Lang.text("CodeHint")
		box.Text = ""
		box.ClearTextOnFocus = false
		box.Parent = f
		Kit.corner(box, 8)
		Kit.stroke(box, 2, nil, true)
		;(f:FindFirstChild("Name") :: TextLabel).Visible = false
		;(f:FindFirstChild("InfoPill") :: Frame).Visible = false
		button(f, Lang.text("CodeRedeem"), C.green, function()
			codeRemote:FireServer(box.Text)
		end)
	elseif current == "Group" then
		local f = row(1, Lang.text("TabGroup"), Lang.text("GroupText", { money = Format.short(Config.Group.Money) }), C.coral)
		f.Size = UDim2.new(1, -12, 0, 90)
		local pill = f:FindFirstChild("InfoPill") :: Frame
		pill.Size = UDim2.new(1, -262, 0, 44)
		;(pill:FindFirstChild("Info") :: TextLabel).TextWrapped = true
		if d.GroupClaimed then
			button(f, Lang.text("Claimed"), C.grey)
		else
			button(f, Lang.text("Claim"), C.green, function()
				claimRemote:FireServer("Group")
			end)
		end
	end
end

local function refreshBadge()
	badge.Visible = me:GetAttribute("RewardsReady") == true
	Kit.setButtonText(openButton, Lang.text("RewardsButton"))
end

function RewardsController.Start(_self: any)
	claimRemote = Remotes.event("ClaimReward")
	codeRemote = Remotes.event("RedeemCode")
	window = Kit.window({ name = "RewardsWindow", width = 660, height = 520, color = C.green })
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 48)
	tabs.Parent = window.body
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.Padding = UDim.new(0, 8)
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Parent = tabs
	for i, tab in TABS do
		local b = Kit.button(tabs, tab, C.tab, UDim2.fromOffset(112, 40), UDim2.new())
		;(b.Parent :: Frame).LayoutOrder = i
		b.Activated:Connect(function()
			current = tab
			redraw()
		end)
		tabButtons[tab] = b
	end
	list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 56)
	list.Size = UDim2.new(1, 0, 1, -56)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.ScrollBarImageColor3 = C.ink
	list.Parent = window.body
	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, 8)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = list

	-- W3 (revision 3 item 13): a button in the HUD's left column (middle left), next to Rebirth
	openButton = Hud.leftButton("Rewards", "RewardsButton", C.green, 6, function()
		if window.isOpen() then
			window.setOpen(false)
		else
			redraw()
			window.setOpen(true)
		end
	end)
	badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(22, 22)
	badge.Position = UDim2.new(1, -12, 0, -10)
	badge.BackgroundColor3 = Color3.fromHex("ff3b3b")
	badge.ZIndex = 5
	badge.Parent = openButton
	Kit.corner(badge, 12)
	Kit.stroke(badge, 2, nil, true)
	local bang = Kit.text(badge, "Bang", UDim2.fromScale(1, 1), UDim2.new(), 18, true)
	bang.Text = "!"
	bang.ZIndex = 6
	refreshBadge()
	me:GetAttributeChangedSignal("RewardsReady"):Connect(refreshBadge)
	PlayerData.changed:Connect(function()
		if window.isOpen() then
			redraw()
		end
	end)
	Lang.changed:Connect(function()
		refreshBadge()
		redraw()
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			if window.isOpen() and current == "Gifts" then
				redraw()
			end
		end
	end)
end

return RewardsController
