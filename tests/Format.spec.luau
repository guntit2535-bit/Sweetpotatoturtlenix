--!strict
-- Number formatting for the HUD and windows (task 1.1). Run by scripts/check.luau (lune).

local Format = require("../src/shared/Format")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Format: {message}`)
	end
end

check(Format.int(0) == "0", "int 0")
check(Format.int(18400) == "18,400", "int commas")
check(Format.int(1234567.9) == "1,234,567", "int floors")
check(Format.int(-2500) == "-2,500", "int negative")
check(Format.short(950) == "950", "short under 1000")
check(Format.short(1234) == "1.2K", "short K")
check(Format.short(1999) == "1.9K", "short cuts, never rounds up")
check(Format.short(2000000) == "2M", "short whole M")
check(Format.short(50000) == "50K", "50,000 kg -> 50K (Secret cat)")
check(Format.short(3.4e9) == "3.4B", "short B")
check(Format.short(-5) == "0", "short never negative")
check(Format.rate(1.5) == "1.5", "rate one decimal")
check(Format.rate(2000) == "2,000", "rate whole")
check(Format.clock(65.2) == "1:06", "clock rounds up")
check(Format.clock(180) == "3:00", "clock 3 minutes (event escape)")

if failures > 0 then
	error(`Format: {failures} failure(s)`)
end
print("PASS Format")
