--!strict
-- Zone gates on this client: a gate barrier (tag "ZoneGate", attribute Zone) is solid for this player
-- while that zone is closed to them (CatRules.zoneOpen with their Strength / Rebirths) and see-through-open
-- once they qualify. The server double-checks (ZoneGateService).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatRules"))

local GateController = {}

local me = Players.LocalPlayer

local function refresh()
	local s = me:GetAttribute("Strength")
	local r = me:GetAttribute("Rebirths")
	local strength = if type(s) == "number" then s else 0
	local rebirths = if type(r) == "number" then r else 0
	for _, b in CollectionService:GetTagged("ZoneGate") do
		local zone = b:GetAttribute("Zone")
		if b:IsA("BasePart") and type(zone) == "number" then
			local open = CatRules.zoneOpen(zone, strength, rebirths)
			b.CanCollide = not open
			b.Transparency = if open then 0.85 else 0.45
		end
	end
end

function GateController.Start(_self: any)
	me:GetAttributeChangedSignal("Strength"):Connect(refresh)
	me:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
	CollectionService:GetInstanceAddedSignal("ZoneGate"):Connect(refresh)
	task.spawn(function()
		while true do
			refresh()
			task.wait(3)
		end
	end)
end

return GateController
