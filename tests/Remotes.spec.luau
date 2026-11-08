--!strict
-- The remote list has no duplicates and only plain names (task 1.1). Run by scripts/check.luau (lune).
-- Remotes.luau needs Roblox services, so this reads its list from the source text.

local fs = require("@lune/fs")

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Remotes: {message}`)
	end
end

local source = fs.readFile("src/shared/Remotes.luau")
local seen: { [string]: boolean } = {}
local count = 0
for block in string.gmatch(source, "Remotes%.%a+ = (%b{})") do
	for name in string.gmatch(block, '"([^"]+)"') do
		count += 1
		check(not seen[name], `{name} listed twice`)
		check(string.find(name, "^%u%w+$") ~= nil, `{name} is a PascalCase name`)
		seen[name] = true
	end
end
check(count > 0, "remotes are listed")

if failures > 0 then
	error(`Remotes: {failures} failure(s)`)
end
print(`PASS Remotes ({count})`)
