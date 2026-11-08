--!strict
-- Quest progress hub (task 2.12): any service reports what a player did, RewardsService counts it.
-- Keeps services free of a dependency on RewardsService (no require cycles).
--   Progress.add(player, "Catch", 1)
--   Progress.Added:Connect(function(player, kind, amount) end)

local Progress = {}

local event = Instance.new("BindableEvent")

Progress.Added = event.Event

function Progress.add(player: Player, kind: string, amount: number?)
	event:Fire(player, kind, amount or 1)
end

return Progress
