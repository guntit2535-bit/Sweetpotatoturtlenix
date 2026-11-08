--!strict
-- Fishing bar win rate of a simple "hold when the zone is below the cat" player, per tier:
--   lune run tools/sim/fishing.luau
local Shared = require("../../tests/lib/Shared")
local FishingBar = Shared.require("FishingBar")
local DT = 1 / 15
for tier = 1, 6 do
	local wins, t = 0, 0
	for seed = 1, 100 do
		local s = FishingBar.new(seed, FishingBar.params(tier))
		for i = 1, 15 * 120 do
			local r = FishingBar.step(s, DT, s.zone < s.cat + 0.02 or s.vel < -0.4)
			if r == "win" then wins += 1; t += i * DT break elseif r == "lose" then break end
		end
	end
	print(tier, wins, wins > 0 and t / wins or 0)
end
