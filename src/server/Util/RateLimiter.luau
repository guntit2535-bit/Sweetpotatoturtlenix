--!strict
-- Fixed-window call limiter: at most maxCalls per window seconds for each key (usually a Player).
-- Use it through src/server/Util/Guard, which also clears a player's entry when they leave.
--
--   local limiter = RateLimiter.new(10, 1)
--   if not limiter:allow(player) then return end
--
-- No requires: this module is also loaded by the pure tests (tests/RateLimiter.spec.luau),
-- which pass their own clock.

type Entry = { windowStart: number, count: number }

export type RateLimiter = {
	allow: (self: RateLimiter, key: any) -> boolean,
	clear: (self: RateLimiter, key: any) -> (),
	count: (self: RateLimiter) -> number,
	_maxCalls: number,
	_window: number,
	_clock: () -> number,
	_entries: { [any]: Entry },
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(maxCalls: number, window: number, clock: (() -> number)?): RateLimiter
	assert(maxCalls >= 1 and window > 0, "RateLimiter: maxCalls >= 1 and window > 0")
	local self = {
		_maxCalls = maxCalls,
		_window = window,
		_clock = clock or os.clock,
		_entries = {},
	}
	return setmetatable(self, RateLimiter) :: any
end

function RateLimiter.allow(self: RateLimiter, key: any): boolean
	local now = self._clock()
	local entry = self._entries[key]
	if not entry or now - entry.windowStart >= self._window then
		self._entries[key] = { windowStart = now, count = 1 }
		return true
	end
	if entry.count >= self._maxCalls then
		return false
	end
	entry.count += 1
	return true
end

function RateLimiter.clear(self: RateLimiter, key: any)
	self._entries[key] = nil
end

-- Number of keys held (tests check that leaving players are cleared).
function RateLimiter.count(self: RateLimiter): number
	local n = 0
	for _ in self._entries do
		n += 1
	end
	return n
end

return RateLimiter
