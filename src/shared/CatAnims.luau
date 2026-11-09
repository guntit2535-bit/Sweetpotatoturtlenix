--!strict
-- Cat animation clips as plain maths (no uploaded animations): every clip turns a time in seconds into
-- joint angles (radians) and the body's lift (studs at size 1) for the rig in shared/CatModel.
-- CatAnimController (client) applies them to the Motor6D.Transform values every frame.
-- Pure module: tested by tests/CatAnims.spec.luau.
--
--   local pose = CatAnims.pose("walk", os.clock() + phase)
--
-- Signs: leg pitch > 0 swings the paw forward; head pitch > 0 lifts the nose; tail pitch > 0 lowers the
-- tail; wing > 0 lifts both wings.

export type Pose = {
	bodyY: number,
	bodyPitch: number,
	bodyRoll: number,
	bodyYaw: number,
	headPitch: number,
	headYaw: number,
	headRoll: number,
	tail1Pitch: number,
	tail1Yaw: number,
	tail2Pitch: number,
	tail2Yaw: number,
	legFL: number,
	legFR: number,
	legBL: number,
	legBR: number,
	wing: number, -- flap: 0 = folded along the body
	fxYaw: number, -- the things round a Mythical / Secret cat (the Fx bone) turn round it
}

local CatAnims = {}

CatAnims.FxSpin = 0.9 -- radians a second (Config.CatAnim.FxSpin sets it on the client)

CatAnims.Clips = { "idle", "walk", "struggle", "carried", "sleep" }

local sin, cos, abs = math.sin, math.cos, math.abs

local function blank(): Pose
	return {
		bodyY = 0,
		bodyPitch = 0,
		bodyRoll = 0,
		bodyYaw = 0,
		headPitch = 0,
		headYaw = 0,
		headRoll = 0,
		tail1Pitch = 0,
		tail1Yaw = 0,
		tail2Pitch = 0,
		tail2Yaw = 0,
		legFL = 0,
		legFR = 0,
		legBL = 0,
		legBR = 0,
		wing = 0,
		fxYaw = 0,
	}
end
CatAnims.blank = blank

type Clip = (p: Pose, t: number) -> ()

local CLIPS: { [string]: Clip } = {}

-- Standing: slow breathing, looking around, lazy tail.
CLIPS.idle = function(p, t)
	p.bodyY = 0.05 * sin(t * 2.2)
	p.headPitch = 0.06 * sin(t * 1.3)
	p.headYaw = 0.22 * sin(t * 0.7)
	p.headRoll = 0.08 * sin(t * 0.5 + 1)
	p.tail1Yaw = 0.35 * sin(t * 1.6)
	p.tail2Yaw = 0.3 * sin(t * 1.6 - 0.7)
	p.tail2Pitch = 0.08 * sin(t * 0.9)
	p.wing = 0.15 + 0.1 * sin(t * 2.2)
end

-- Trotting in place or along a path: diagonal legs together, a little bounce.
CLIPS.walk = function(p, t)
	local w = t * 9
	local s = sin(w)
	p.legFL = 0.55 * s
	p.legBR = 0.55 * s
	p.legFR = -0.55 * s
	p.legBL = -0.55 * s
	p.bodyY = 0.14 * abs(cos(w))
	p.bodyRoll = 0.04 * s
	p.headPitch = 0.05 * sin(w * 2)
	p.headYaw = 0.05 * sin(w * 0.5)
	p.tail1Yaw = 0.25 * sin(w * 0.5)
	p.tail2Yaw = 0.3 * sin(w * 0.5 - 0.6)
	p.tail1Pitch = -0.1
	p.wing = 0.25 + 0.25 * abs(s)
end

-- Hooked on the rod: wriggling hard, paws paddling, tail thrashing.
CLIPS.struggle = function(p, t)
	p.bodyRoll = 0.32 * sin(t * 14)
	p.bodyYaw = 0.22 * sin(t * 9)
	p.bodyPitch = 0.1 * sin(t * 11 + 0.5)
	p.bodyY = 0.25 * abs(sin(t * 7))
	p.headYaw = 0.4 * sin(t * 14 + 1)
	p.headPitch = 0.25 + 0.15 * sin(t * 10)
	local w = t * 16
	p.legFL = 0.9 * sin(w)
	p.legFR = 0.9 * sin(w + math.pi)
	p.legBL = 0.7 * sin(w + math.pi * 0.5)
	p.legBR = 0.7 * sin(w + math.pi * 1.5)
	p.tail1Yaw = 0.8 * sin(t * 12)
	p.tail2Yaw = 0.7 * sin(t * 12 - 0.8)
	p.tail1Pitch = 0.2 * sin(t * 6)
	p.wing = 0.6 + 0.5 * sin(t * 20)
end

-- Held over a player's head: legs dangling, tail swaying, looking around.
CLIPS.carried = function(p, t)
	p.legFL = 0.35 + 0.18 * sin(t * 3.5)
	p.legFR = 0.35 + 0.18 * sin(t * 3.5 + 1.6)
	p.legBL = -0.3 + 0.15 * sin(t * 3.5 + 0.8)
	p.legBR = -0.3 + 0.15 * sin(t * 3.5 + 2.4)
	p.bodyRoll = 0.08 * sin(t * 2)
	p.headYaw = 0.35 * sin(t * 1.2)
	p.headPitch = -0.1 + 0.08 * sin(t * 2.4)
	p.tail1Pitch = 0.6
	p.tail1Yaw = 0.5 * sin(t * 3)
	p.tail2Yaw = 0.4 * sin(t * 3 - 0.8)
	p.wing = 0.4 + 0.3 * sin(t * 6)
end

-- Napping in the pen: lying low, paws tucked, slow breathing, tail curled.
CLIPS.sleep = function(p, t)
	p.bodyY = -0.55 + 0.04 * sin(t * 1.6)
	p.legFL = -1.25
	p.legFR = -1.25
	p.legBL = 1.25
	p.legBR = 1.25
	p.headPitch = -0.3 + 0.03 * sin(t * 1.6)
	p.headRoll = 0.12
	p.tail1Pitch = 0.9
	p.tail1Yaw = 0.7
	p.tail2Yaw = 0.6 + 0.05 * sin(t * 0.8)
end

-- "showcase": plays every clip in turn, forever (preview videos).
CatAnims.Showcase = { { "idle", 4 }, { "walk", 4 }, { "struggle", 3 }, { "carried", 3 }, { "sleep", 4 } }

local function showcaseClip(t: number): string
	local total = 0
	for _, step in CatAnims.Showcase do
		total += step[2] :: number
	end
	local at = t % total
	for _, step in CatAnims.Showcase do
		at -= step[2] :: number
		if at < 0 then
			return step[1] :: string
		end
	end
	return "idle"
end
CatAnims.showcaseClip = showcaseClip

-- The pose of a clip at time t (unknown clips play "idle"). `into` is reused when given (no garbage).
function CatAnims.pose(clip: string, t: number, into: Pose?): Pose
	local p = into or blank()
	for k in p do
		(p :: any)[k] = 0
	end
	if clip == "showcase" then
		clip = showcaseClip(t)
	end
	local f = CLIPS[clip] or CLIPS.idle
	f(p, t)
	p.fxYaw = (t * CatAnims.FxSpin) % (2 * math.pi) -- every clip: the effect never stops turning
	return p
end

function CatAnims.has(clip: string): boolean
	return CLIPS[clip] ~= nil
end

return CatAnims
