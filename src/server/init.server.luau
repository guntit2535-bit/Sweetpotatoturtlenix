--!strict
-- Server entry point. Loads every ModuleScript in script.Services with pcall:
-- first requires all of them, then calls Init() on each, then Start() on each.
-- A failing service is logged and skipped; the others still load.

type Service = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

local function log(message: string)
	print(`[Sweetpotato] {message}`)
end

local function fail(message: string)
	warn(`[Sweetpotato] {message}`)
end

local loaded: { { name: string, service: Service } } = {}

local servicesFolder = script:FindFirstChild("Services")
if servicesFolder then
	for _, child in servicesFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, result = pcall((require :: any), child)
			if ok and type(result) == "table" then
				table.insert(loaded, { name = child.Name, service = result :: Service })
			elseif ok then
				fail(`service {child.Name} did not return a table`)
			else
				fail(`service {child.Name} failed to load: {result}`)
			end
		end
	end
end

for _, entry in loaded do
	local init = entry.service.Init
	if init then
		local ok, err = pcall(init, entry.service)
		if not ok then
			fail(`service {entry.name} Init failed: {err}`)
		end
	end
end

for _, entry in loaded do
	local start = entry.service.Start
	if start then
		local ok, err = pcall(start, entry.service)
		if not ok then
			fail(`service {entry.name} Start failed: {err}`)
		end
	end
end

log("server ready")
