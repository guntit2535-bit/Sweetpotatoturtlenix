--!strict
-- Player arm poses (task 2.22) as plain maths, like shared/CatAnims: no animation uploads.
-- PlayerAnimController turns them into shoulder Motor6D.Transform values on every nearby player:
--   carry: both arms straight up holding the cat over the head, with a small struggle bob
--   reel:  the rod arm held out in front, the other arm turning the reel (V2: on R15 the rod moves to the left
--          hand (ToolService) and the right hand is put on the crank by PlayerAnimController)
--   curl:  R6 task: standing two-hand dumbbell curl, the arms taking turns (elbows bend; R15 only)
-- The cast and the bat swing use Roblox's default tool "Slash" (Util/ToolAnim on the server); lifting and
-- the treadmill use Roblox's default run (TrainingController); lifting is the curl here (R15; R6 rigs, which
-- have no elbows, keep Roblox's cheer).
-- Angles are radians in the torso's axes at the shoulder: x raises the arm forward-up (pi = straight up);
-- z tilts it sideways (negative = right arm inward, positive = left arm inward). re / le bend the elbows
-- (0 = straight, about 2.3 = fully curled); nil leaves the elbows to the Animator.

local PlayerPoses = {}

export type Arms = {
	rx: number,
	rz: number,
	lx: number,
	lz: number,
	re: number?,
	le: number?,
	crank: number?, -- reel: the crank's angle (the right hand follows it)
	hx: number?, -- reel: the rod-holding (left) arm when the crank is used
	hz: number?,
	he: number?,
}

PlayerPoses.Kinds = { "carry", "reel", "curl" }
PlayerPoses.CurlRep = 1.2 -- seconds for one arm's rep; the arms take turns

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
			-- the rod in the right hand (R6, or no crank): the right arm out in front, the left arm circling
			rx = 1.25 + math.sin(t * 3) * 0.08,
			rz = 0.1,
			lx = 1.0 + math.sin(turn) * 0.35,
			lz = 0.3 + math.cos(turn) * 0.2,
			-- V2 (R15 with the mesh rod): the rod held in the LEFT hand in close by the belly, tipping a little
			-- as the cat pulls; the right hand turns the crank (PlayerAnimController)
			hx = 0.45 + math.sin(t * 3) * 0.05,
			hz = -0.3,
			he = 1.35,
			crank = turn % (2 * math.pi) - math.pi,
		}
	elseif kind == "curl" then
		-- each arm: down, lift slowly, squeeze at the top, lower; the left arm half a rep behind
		local function bend(phase: number): number
			local u = (phase % 1)
			local s = 0.5 - 0.5 * math.cos(u * 2 * math.pi)
			return 0.15 + 2.05 * s ^ 0.8
		end
		local p = t / PlayerPoses.CurlRep
		local r, l = bend(p), bend(p + 0.5)
		return {
			rx = 0.12 + 0.12 * r / 2.2, -- the upper arm lifts a little as the dumbbell comes up
			rz = 0.14, -- slightly out from the body so the dumbbell clears the leg
			lx = 0.12 + 0.12 * l / 2.2,
			lz = -0.14,
			re = r,
			le = l,
		}
	end
	return { rx = 0, rz = 0, lx = 0, lz = 0 }
end

-- Which pose a player shows, from the attributes the server sets (carrying wins over fishing, fishing over
-- lifting).
function PlayerPoses.kindOf(carrying: unknown, fishing: unknown, training: unknown?): string?
	if carrying ~= nil then
		return "carry"
	elseif fishing ~= nil then
		return "reel"
	elseif training == "weights" then
		return "curl"
	end
	return nil
end

return PlayerPoses
