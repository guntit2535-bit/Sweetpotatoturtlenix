--!strict
-- The language this client shows. English until the player's "Language" attribute (set by the server:
-- SettingsService, and from the save in task 1.2) says otherwise.
--
--   Lang.text("SettingsTitle")
--   Lang.text("SomeLine", { count = 3 })
--   Lang.changed:Connect(function(lang) ... redraw texts ... end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Text = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Text"))

local changedEvent = Instance.new("BindableEvent")
local current: Text.Lang = Text.Default

local Lang = {}

Lang.changed = changedEvent.Event

function Lang.get(): Text.Lang
	return current
end

-- Accepts any value; unknown values fall back to English.
function Lang.set(setting: unknown)
	local new = Text.resolve(setting)
	if new ~= current then
		current = new
		changedEvent:Fire(current)
	end
end

function Lang.text(key: string, vars: Text.Vars?): string
	return Text.get(key, current, vars)
end

-- Follow the server's attribute for the local player.
local player = Players.LocalPlayer
if player then
	Lang.set(player:GetAttribute("Language"))
	player:GetAttributeChangedSignal("Language"):Connect(function()
		Lang.set(player:GetAttribute("Language"))
	end)
end

return Lang
