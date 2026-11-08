--!strict
-- The fishing bar minigame as plain maths (task 1.11, blueprint §2). The server steps one state per
-- fishing player from their hold input and decides the result; the client steps the same state for drawing
-- and is reset by the server's snapshots. Pure: tested by tests/FishingBar.spec.luau.
--
-- Positions are 0 (bottom) .. 1 (top). The cat moves toward a target that changes every so often; holding
-- pushes the green zone up, letting go lets it fall. The meter fills while the cat is inside the zone and
-- drains outside: full = caught, empty = the cat breaks free.
--
--   local s = FishingBar.new(seed, FishingBar.params(tier, rodLevel))
--   local result = FishingBar.step(s, dt, holding)   -- nil | "win" | "lose"

local Config = require(script.Parent.Config)

export type Params = {
	zone: number,
	catSpeed: number,
	changeMin: number,
	changeMax: number,
	fill: number,
	drain: number,
}

export type State = {
	params: Params,
	rng: number, -- generator state (sent in snapshots so the client continues the same cat path)
	zone: number, -- centre of the green zone
	vel: number,
	cat: number,
	target: number,
	nextChange: number, -- seconds until the cat picks a new target
	meter: number,
	time: number,
}

local FishingBar = {}

local function nextRandom(s: State): number
	s.rng = (s.rng * 1103515245 + 12345) % 2147483648
	return s.rng / 2147483648
end

-- Difficulty for a cat tier; rodLevel (milestone 2) and easy (Catnip treat) make it easier.
function FishingBar.params(tier: number, rodLevel: number?, easy: boolean?): Params
	local f = Config.Fishing
	local t = f.Tiers[math.clamp(tier, 1, #f.Tiers)]
	local rod = math.max(0, (rodLevel or 1) - 1)
	local zone = t.Zone + rod * f.RodZonePerLevel
	local fill = t.Fill * (1 + rod * f.RodFillPerLevel)
	if easy then
		zone *= 1.25
		fill *= 1.2
	end
	return {
		zone = math.min(zone, 0.6),
		catSpeed = t.CatSpeed,
		changeMin = t.Change[1],
		changeMax = t.Change[2],
		fill = fill,
		drain = t.Drain,
	}
end

function FishingBar.new(seed: number, params: Params): State
	local s: State = {
		params = params,
		rng = math.floor(math.abs(seed)) % 2147483648,
		zone = 0.5,
		vel = 0,
		cat = 0.5,
		target = 0.5,
		nextChange = 0,
		meter = Config.Fishing.StartMeter,
		time = 0,
	}
	return s
end

function FishingBar.inside(s: State): boolean
	return math.abs(s.cat - s.zone) <= s.params.zone / 2
end

-- Advances the state by dt seconds. Returns "win" when the meter is full, "lose" when it is empty.
function FishingBar.step(s: State, dt: number, holding: boolean): string?
	local f = Config.Fishing
	local p = s.params
	s.time += dt
	-- the cat
	s.nextChange -= dt
	if s.nextChange <= 0 then
		s.target = 0.06 + nextRandom(s) * 0.88
		s.nextChange = p.changeMin + nextRandom(s) * (p.changeMax - p.changeMin)
	end
	local d = s.target - s.cat
	local move = p.catSpeed * dt
	if math.abs(d) <= move then
		s.cat = s.target
	else
		s.cat += if d > 0 then move else -move
	end
	-- the green zone
	s.vel += (if holding then f.Lift else -f.Gravity) * dt
	s.vel = math.clamp(s.vel, -f.MaxVel, f.MaxVel)
	s.zone += s.vel * dt
	local half = p.zone / 2
	if s.zone < half then
		s.zone = half
		s.vel = -s.vel * f.Bounce
	elseif s.zone > 1 - half then
		s.zone = 1 - half
		s.vel = -s.vel * f.Bounce
	end
	-- the meter
	if FishingBar.inside(s) then
		s.meter += p.fill * dt
	else
		s.meter -= p.drain * dt
	end
	if s.meter >= 1 then
		s.meter = 1
		return "win"
	elseif s.meter <= 0 then
		s.meter = 0
		return "lose"
	end
	return nil
end

-- What the server sends the client (numbers only) and how the client takes it back.
function FishingBar.snapshot(s: State): { number }
	return { s.rng, s.zone, s.vel, s.cat, s.target, s.nextChange, s.meter, s.time }
end

function FishingBar.apply(s: State, snap: { number })
	s.rng, s.zone, s.vel, s.cat, s.target, s.nextChange, s.meter, s.time =
		snap[1], snap[2], snap[3], snap[4], snap[5], snap[6], snap[7], snap[8]
end

return FishingBar
