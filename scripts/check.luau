--!strict
-- Project check, run before every commit:   lune run scripts/check.luau
--   1. every .luau file in src/ and tests/ compiles (syntax),
--   2. every .luau file outside src/server/Packages starts with --!strict,
--   3. every tests/*.spec.luau runs without error (pure-Luau tests of src/shared modules).
-- `rojo build` is run separately (see README). Engine behavior is tested in Studio.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local files: { string } = {}

local function walk(dir: string)
	if not fs.isDir(dir) then
		return
	end
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then
			walk(path)
		elseif string.sub(name, -5) == ".luau" then
			table.insert(files, path)
		end
	end
end

walk("src")
walk("tests")
walk("scripts")
walk("tools")
table.sort(files)

print("== 1. syntax + --!strict")
for _, path in files do
	local source = fs.readFile(path)
	local ok, err = pcall(luau.compile, source)
	if not ok then
		print(`  FAIL syntax {path}: {err}`)
		failures += 1
	end
	local isPackage = string.find(path, "src/server/Packages/", 1, true) ~= nil
	if not isPackage and string.sub(source, 1, 9) ~= "--!strict" then
		print(`  FAIL {path}: first line must be --!strict`)
		failures += 1
	end
end
print(`  {#files} files`)

print("== 2. pure tests")
local specs = 0
for _, path in files do
	if string.sub(path, -10) == ".spec.luau" then
		specs += 1
		local result = process.exec("lune", { "run", path })
		if result.ok then
			print(`  PASS {path}`)
		else
			print(`  FAIL {path}\n{result.stdout}{result.stderr}`)
			failures += 1
		end
	end
end
if specs == 0 then
	print("  no tests/*.spec.luau yet")
end

if failures == 0 then
	print("ALL CHECKS PASSED")
else
	print(`CHECKS FAILED ({failures})`)
	process.exit(1)
end
