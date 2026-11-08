--!strict
-- Player arm poses (task 2.22) as plain maths, like shared/CatAnims: no animation uploads.
-- PlayerAnimController turns them into shoulder Motor6D.Transform values on every nearby player:
--   carry: both arms straight up holding the cat over the head, with a small struggle bob
--   reel:  the rod arm held out in front, the other arm turning the reel
-- The cast and the bat swing use Roblox's default tool "Slash" (Util/ToolAnim on the server); lifting and
-- the treadmill use Roblox's default cheer / run (TrainingController).
-- Angles are radians in the torso's axes at the shoulder: x raises the arm forward-up (pi = straight up);
-- z tilts it sideways (negative = right arm inward, positive = left arm inward).

local PlayerPoses = {}

export type Arms = { rx: number, rz: number, lx: number, lz: number }

PlayerPoses.Kinds = { "carry", "reel" }

function PlayerPoses.has(kind: string): boolean
	return table.find(PlayerPoses.Kinds, kind) ~= nil
end

-- The arm angles of a pose at time t (seconds).
function PlayerPoses.arms(kind: string, t: number): Arms
	if kind == "carry" then
		local bob = math.sin(t * 7) * 0.08
		return { rx = 2.9 + bob, rz = -0.25, lx = 2.9 - bob, lz = 0.25 }
	elseif kind == "reel" then
		local turn = t * 11
		return {
			rx = 1.25 + math.sin(t * 3) * 0.08,
			rz = 0.1,
			lx = 1.0 + math.sin(turn) * 0.35,
			lz = 0.3 + math.cos(turn) * 0.2,
		}
	end
	return { rx = 0, rz = 0, lx = 0, lz = 0 }
end

-- Which pose a player shows, from the attributes the server sets (carrying wins over fishing).
function PlayerPoses.kindOf(carrying: unknown, fishing: unknown): string?
	if carrying ~= nil then
		return "carry"
	elseif fishing ~= nil then
		return "reel"
	end
	return nil
end

return PlayerPoses
