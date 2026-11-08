--!strict
-- Per-player remote limiter (task 1.1). Run by scripts/check.luau (lune) with a fake clock.

local RateLimiter = require("../src/server/Util/RateLimiter")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL RateLimiter: {message}`)
	end
end

local now = 0
local limiter = RateLimiter.new(3, 1, function()
	return now
end)

local a, b = {}, {}
local first, second, third = limiter:allow(a), limiter:allow(a), limiter:allow(a)
check(first and second and third, "3 calls allowed")
check(not limiter:allow(a), "4th call in the same second refused")
check(limiter:allow(b), "another player has their own budget")

now = 0.99
check(not limiter:allow(a), "still refused before the window ends")
now = 1.0
check(limiter:allow(a), "allowed again in the next window")

check(limiter:count() == 2, "two keys held")
limiter:clear(a)
limiter:clear(b)
check(limiter:count() == 0, "cleared on leave")

check(not pcall(RateLimiter.new, 0, 1), "maxCalls 0 rejected")

if failures > 0 then
	error(`RateLimiter: {failures} failure(s)`)
end
print("PASS RateLimiter")
