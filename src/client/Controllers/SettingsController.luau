--!strict
-- Settings (task 1.1): a gear button at the top right opens the Settings window. Language: English /
-- ไทย (English by default). The client only asks (SetSetting); the server sets the player's "Language"
-- attribute and Lang switches every text at once. Saved from task 1.2. Music / sound switches come
-- with the sounds (2.23).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Text = require(ReplicatedStorage.Shared.Text)
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local SettingsController = {}

local C = Kit.Colors
local window: Kit.Window
local english: TextButton
local thai: TextButton
local labels: { [TextLabel]: string } = {}
local buttonLabel: TextLabel

local function refresh()
	window.title.Text = Lang.text("SettingsTitle")
	for label, key in labels do
		label.Text = Lang.text(key)
	end
	buttonLabel.Text = Lang.text("SettingsButton")
	local isThai = Lang.get() == "th"
	Kit.setButtonColor(english, if isThai then C.grey else C.yellow)
	Kit.setButtonColor(thai, if isThai then C.yellow else C.grey)
end

local function build(setRemote: RemoteEvent)
	window = Kit.window({ name = "SettingsWindow", width = 480, height = 182, color = C.purple })

	local row = Instance.new("Frame")
	row.Name = "Language"
	row.Size = UDim2.new(1, 0, 0, 92)
	row.BackgroundColor3 = C.soft
	row.Parent = window.body
	Kit.corner(row, 16)
	Kit.stroke(row, 3, nil, true)
	local name = Kit.text(row, "Title", UDim2.new(0.45, 0, 0, 34), UDim2.fromOffset(16, 14), 26)
	name.TextXAlignment = Enum.TextXAlignment.Left
	labels[name] = "SettingsLanguage"
	local note = Kit.text(row, "Note", UDim2.new(0.45, 0, 0, 22), UDim2.fromOffset(16, 52), 16)
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.TextColor3 = C.muted
	labels[note] = "SettingsLanguageNote"

	english = Kit.button(row, "English", C.yellow, UDim2.fromOffset(112, 50), UDim2.new(1, -244, 0.5, -28))
	thai = Kit.button(row, "Thai", C.grey, UDim2.fromOffset(112, 50), UDim2.new(1, -124, 0.5, -28))
	Kit.setButtonText(english, Text.get("LanguageEnglish", "en"))
	Kit.setButtonText(thai, Text.get("LanguageThai", "th"))
	english.Activated:Connect(function()
		setRemote:FireServer("Language", "en")
	end)
	thai.Activated:Connect(function()
		setRemote:FireServer("Language", "th")
	end)

	-- the gear button (top right, under Roblox's own top bar)
	local hud = Kit.screen("SettingsButton", 1)
	local gear = Kit.button(hud, "Gear", C.purple, UDim2.fromOffset(64, 64), UDim2.new(1, -78, 0, 10))
	Kit.setButtonText(gear, "")
	local icon = Kit.gear(gear, 34)
	icon.Position = UDim2.new(0.5, 0, 0.42, 0)
	buttonLabel = Kit.text(gear, "Caption", UDim2.new(1, 8, 0, 18), UDim2.new(0, -4, 1, -20), 15, true)
	gear.Activated:Connect(function()
		window.setOpen(not window.isOpen())
	end)
end

function SettingsController.Start(_self: any)
	build(Remotes.event("SetSetting"))
	refresh()
	Lang.changed:Connect(refresh)
end

return SettingsController
