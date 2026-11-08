--!strict
-- Debug command parsing (task 1.3). Run by scripts/check.luau (lune).

local Shared = require("./lib/Shared")
local Commands = Shared.require("Commands")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Commands: {message}`)
	end
end

local name, args = Commands.parse("!coins 500", "!")
check(name == "coins" and args[1] == "500" and #args == 1, "!coins 500")

name, args = Commands.parse("!Storm   warn  ", "!")
check(name == "storm" and args[1] == "warn" and #args == 1, "case and spaces")

name = Commands.parse("hello !coins", "!")
check(name == nil, "not a command")

name = Commands.parse("!", "!")
check(name == nil, "prefix only")

check(Commands.integer("500") == 500, "integer")
check(Commands.integer("-20") == -20, "negative integer")
check(Commands.integer("1.5") == nil, "fraction")
check(Commands.integer("abc") == nil, "word")
check(Commands.integer(nil) == nil, "missing")

check(Commands.number("1.5") == 1.5, "number fraction")
check(Commands.number("20k") == 20000, "number k")
check(Commands.number("3M") == 3e6, "number M")
check(Commands.number("x2") == nil, "number word")
check(Commands.number("90Sx") == 9e22 and Commands.number("2qa") == 2e15 and Commands.number("5t") == 5e12, "number T / Qa / Sx (R4)")
check(Commands.number("5zz") == nil, "unknown suffix")

if failures > 0 then
	error(`Commands: {failures} failure(s)`)
end
print("PASS Commands")
