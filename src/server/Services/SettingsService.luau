--!strict
-- Player settings (task 1.1). The Settings window asks SetSetting(key, value); the server checks it and
-- sets the player attribute the clients follow (Language = "en" | "th"; every text switches at once).
-- Task 1.2 saves it in data.Settings and puts the saved value back on the attribute when the player joins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Text = require(ReplicatedStorage.Shared.Text)
local Validate = require(ReplicatedStorage.Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)

local SettingsService = {}

SettingsService.Keys = { "Language" }

-- Called by DataService (task 1.2) after a change, to save it.
SettingsService.onChanged = nil :: ((player: Player, key: string, value: any) -> ())?

local function onSet(player: Player, rawKey: unknown, rawValue: unknown)
	local key = Validate.oneOf(rawKey, SettingsService.Keys)
	if key == "Language" then
		if not Text.isLang(rawValue) then
			return
		end
		player:SetAttribute("Language", rawValue)
		if SettingsService.onChanged then
			SettingsService.onChanged(player, key, rawValue)
		end
	end
end

function SettingsService:Init()
	Guard.onEvent("SetSetting", Config.Settings.SetRate, onSet)
end

return SettingsService
