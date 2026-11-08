--!strict
-- Client entry point. Loads every ModuleScript in script.Controllers with pcall:
-- first requires all of them, then calls Init() on each, then Start() on each.
-- A failing controller is logged and skipped; the others still load.

type Controller = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

local function log(message: string)
	print(`[Sweetpotato] {message}`)
end

local function fail(message: string)
	warn(`[Sweetpotato] {message}`)
end

local loaded: { { name: string, controller: Controller } } = {}

local controllersFolder = script:FindFirstChild("Controllers")
if controllersFolder then
	for _, child in controllersFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, result = pcall((require :: any), child)
			if ok and type(result) == "table" then
				table.insert(loaded, { name = child.Name, controller = result :: Controller })
			elseif ok then
				fail(`controller {child.Name} did not return a table`)
			else
				fail(`controller {child.Name} failed to load: {result}`)
			end
		end
	end
end

for _, entry in loaded do
	local init = entry.controller.Init
	if init then
		local ok, err = pcall(init, entry.controller)
		if not ok then
			fail(`controller {entry.name} Init failed: {err}`)
		end
	end
end

for _, entry in loaded do
	local start = entry.controller.Start
	if start then
		local ok, err = pcall(start, entry.controller)
		if not ok then
			fail(`controller {entry.name} Start failed: {err}`)
		end
	end
end

log("client ready")
