--!strict
-- Launch check (task 2.25), run on launch day:   lune run scripts/launch_check.luau
-- Fails (exit 1) while anything that must be set before going public is missing:
--   every game pass and developer product id, Debug switched off, GroupId, 8 players.
-- Lists sound / music keys still at 0 as warnings (blank = the developer chose silence).
-- docs/LAUNCH_CHECKLIST.md has the rest (Dashboard settings, tests on phones and with players).

local process = require("@lune/process")
local Config = require("../src/shared/Config")

local problems: { string } = {}
local warnings: { string } = {}

for name, p in Config.Passes :: any do
	if p.Id == 0 then
		table.insert(problems, `game pass {name}: Id is 0`)
	end
end
for _, p in Config.Products.List do
	if p.Id == 0 then
		table.insert(problems, `developer product {p.Key}: Id is 0`)
	end
end
if Config.Debug.Enabled then
	table.insert(problems, "Config.Debug.Enabled is true (debug commands would work for the admins live)")
end
if Config.GroupId == 0 then
	table.insert(problems, "Config.GroupId is 0")
end
if Config.MaxPlayers ~= 8 then
	table.insert(problems, `Config.MaxPlayers is {Config.MaxPlayers}, the blueprint says 8`)
end

local silent: { string } = {}
for key, id in Config.Sounds :: any do
	if id == 0 then
		table.insert(silent, key)
	end
end
for key, id in Config.Music :: any do
	if id == 0 then
		table.insert(silent, "music " .. key)
	end
end
if #silent > 0 then
	table.sort(silent)
	table.insert(warnings, `{#silent} sounds have no id (silent): {table.concat(silent, ", ")}`)
end

table.sort(problems)
for _, w in warnings do
	print(`WARN  {w}`)
end
for _, p in problems do
	print(`FAIL  {p}`)
end
if #problems > 0 then
	print(`LAUNCH CHECK FAILED: {#problems} problem(s)`)
	process.exit(1)
end
print("LAUNCH CHECK PASSED")
