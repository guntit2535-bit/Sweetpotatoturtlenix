--!strict
-- Checks for client-sent values (task 1.1). Run by scripts/check.luau (lune).

local Validate = require("../src/shared/Validate")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Validate: {message}`)
	end
end

local nan = 0 / 0

check(Validate.number(5, 0, 10) == 5, "number in range")
check(Validate.number(11, 0, 10) == nil, "number above max")
check(Validate.number(-1, 0, 10) == nil, "number below min")
check(Validate.number(nan, -math.huge, math.huge) == nil, "NaN")
check(Validate.number(math.huge, -math.huge, math.huge) == nil, "inf")
check(Validate.number("5", 0, 10) == nil, "string is not a number")

check(Validate.integer(3, 1, 5) == 3, "integer")
check(Validate.integer(3.5, 1, 5) == nil, "fraction is not an integer")

check(Validate.boolean(false) == false, "boolean false")
check(Validate.boolean(0) == nil, "0 is not a boolean")

check(Validate.string("abc", 10) == "abc", "string")
check(Validate.string("", 10) == nil, "empty string")
check(Validate.string(string.rep("a", 11), 10) == nil, "too long")
check(Validate.string("\255\254", 10) == nil, "bad UTF-8")
check(Validate.string("ไทย", 20) == "ไทย", "Thai UTF-8")

check(Validate.oneOf("en", { "en", "th" }) == "en", "oneOf hit")
check(Validate.oneOf("fr", { "en", "th" }) == nil, "oneOf miss")

local map = { Clover = 1 }
check(Validate.key("Clover", map) == "Clover", "key hit")
check(Validate.key("__index", map) == nil, "key miss")

check(Validate.id("c12_ab-3") == "c12_ab-3", "id")
check(Validate.id("a b") == nil, "id with space")
check(Validate.id(string.rep("a", 33)) == nil, "id too long")
check(Validate.id(12) == nil, "id number")

if failures > 0 then
	error(`Validate: {failures} failure(s)`)
end
print("PASS Validate")
