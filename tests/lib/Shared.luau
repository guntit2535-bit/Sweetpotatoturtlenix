--!strict
-- Loads src/shared modules in Lune the way Roblox would, so modules that use
-- `require(script.Parent.Config)` can be tested:
--
--   local Shared = require("./lib/Shared")      -- from a tests/*.spec.luau file
--   local DataTemplate = Shared.require("DataTemplate")
--
-- `script` is a stand-in whose Parent.<Name> points to src/shared/<Name>.luau (Parent.<Folder>.<Name> to
-- src/shared/<Folder>/<Name>.luau). Each module is loaded
-- once and cached, like ModuleScripts. Only works for modules that need nothing else from Roblox.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local ROOT = "src/shared"

local Shared = {}

local cache: { [string]: any } = {}

type Ref = { __module: string }

local function ref(path: string): Ref
	return setmetatable({ __module = path }, {
		__index = function(_, child: string): Ref
			return ref(`{path}/{child}`)
		end,
	}) :: any
end

local function load(name: string): any
	if cache[name] ~= nil then
		return cache[name]
	end
	local path = `{ROOT}/{name}.luau`
	assert(fs.isFile(path), `tests/lib/Shared: {path} not found`)

	local parent = setmetatable({}, {
		__index = function(_, child: string): Ref
			return ref(child)
		end,
	})
	local fakeScript = { Name = name, Parent = parent }
	local function fakeRequire(target: any): any
		if type(target) == "table" and type(target.__module) == "string" then
			return load(target.__module)
		end
		error(`tests/lib/Shared: {name} requires something outside src/shared`)
	end

	local chunk = luau.load(fs.readFile(path), {
		debugName = path,
		-- Roblox data types for modules that build numbers into them (CatShapes)
		environment = {
			script = fakeScript,
			require = fakeRequire,
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
		},
	})
	local result = chunk()
	cache[name] = result
	return result
end

function Shared.require(name: string): any
	return load(name)
end

return Shared
