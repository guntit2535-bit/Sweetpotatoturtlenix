--!strict
-- The local player's copy of their save (task 1.2): asked once with GetData, then replaced by every
-- PlayerData snapshot the server sends. Read only: the client never changes it, it asks the server.
-- Simple numbers (Money, Strength ...) are also player attributes; use those for the HUD.
--
--   local data = PlayerData.get()          -- nil until loaded
--   PlayerData.changed:Connect(function(data) ... end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local changedEvent = Instance.new("BindableEvent")
local current: { [string]: any }? = nil

local PlayerData = {}

PlayerData.changed = changedEvent.Event

function PlayerData.get(): { [string]: any }?
	return current
end

local function set(snapshot: unknown)
	if type(snapshot) == "table" then
		current = snapshot :: any
		changedEvent:Fire(current)
	end
end

Remotes.event("PlayerData").OnClientEvent:Connect(set)
task.spawn(function()
	if current == nil then
		local ok, result = pcall(function()
			return Remotes.func("GetData"):InvokeServer()
		end)
		if ok and current == nil then
			set(result)
		end
	end
end)

return PlayerData
