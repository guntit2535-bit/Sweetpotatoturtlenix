--!strict
-- Settings (task 1.1): a gear button at the top right opens the Settings window. Language: English /
-- ไทย (English by default). The client only asks (SetSetting); the server sets the player's "Language"
-- attribute and Lang switches every text at once. Saved from task 1.2. Music and Sound effects on / off
-- (task 2.23): the server sets MusicOn / SfxOn and saves them; SoundController mutes the sound groups.

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
local toggles: { { key: string, button: TextButton } } = {}
local me = game:GetService("Players").LocalPlayer

-- MusicOn / SfxOn: nil (not loaded yet) counts as on
local function isOn(key: string): boolean
	return me:GetAttribute(key .. "On") ~= false
end

local function refresh()
	window.title.Text = Lang.text("SettingsTitle")
	for label, key in labels do
		label.Text = Lang.text(key)
	end
	buttonLabel.Text = Lang.text("SettingsButton")
	local isThai = Lang.get() == "th"
	Kit.setButtonColor(english, if isThai then C.grey else C.yellow)
	Kit.setButtonColor(thai, if isThai then C.yellow else C.grey)
	for _, t in toggles do
		local on = isOn(t.key)
		Kit.setButtonColor(t.button, if on then C.green else C.grey)
		Kit.setButtonText(t.button, Lang.text(if on then "SettingOn" else "SettingOff"))
	end
end

local function build(setRemote: RemoteEvent)
	window = Kit.window({ name = "SettingsWindow", width = 480, height = 386, color = C.purple })

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

	-- Music and Sound effects: one on / off button each
	for i, key in { "Music", "Sfx" } do
		local r = Instance.new("Frame")
		r.Name = key
		r.Size = UDim2.new(1, 0, 0, 92)
		r.Position = UDim2.fromOffset(0, 102 * i)
		r.BackgroundColor3 = C.soft
		r.Parent = window.body
		Kit.corner(r, 16)
		Kit.stroke(r, 3, nil, true)
		local t = Kit.text(r, "Title", UDim2.new(0.55, 0, 0, 34), UDim2.fromOffset(16, 14), 26)
		t.TextXAlignment = Enum.TextXAlignment.Left
		labels[t] = "Settings" .. key
		local n = Kit.text(r, "Note", UDim2.new(0.55, 0, 0, 22), UDim2.fromOffset(16, 52), 16)
		n.TextXAlignment = Enum.TextXAlignment.Left
		n.TextColor3 = C.muted
		labels[n] = "Settings" .. key .. "Note"
		local b = Kit.button(r, "Toggle", C.green, UDim2.fromOffset(150, 50), UDim2.new(1, -164, 0.5, -28))
		b.Activated:Connect(function()
			setRemote:FireServer(key, not isOn(key))
		end)
		table.insert(toggles, { key = key, button = b })
	end

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
	me:GetAttributeChangedSignal("MusicOn"):Connect(refresh)
	me:GetAttributeChangedSignal("SfxOn"):Connect(refresh)
end

return SettingsController
