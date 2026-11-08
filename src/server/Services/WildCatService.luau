--!strict
-- Wild cats at the hiding spots (task 1.10, blueprint §1; based on Pet Storm Escape's SpawnService).
-- Each zone keeps Config.World.Zones[i].Cats cats at random free spots (Workspace.Map.HideSpots.Zone<i>),
-- rolled on the server by the zone's odds and weight skew. A cat that is caught or escapes comes back at
-- another free spot after 30-90 s.
-- A wild cat is a CatModel in Workspace.WildCats with attributes WildId, Kind, Tier, Kg, Zone, State
-- ("hiding" | "hooked" | "carried" | "dropped") and the tag "WildCat"; clients draw its label.
-- Other services (FishingService, CarryService, EventService) use the API below.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local CatModel = require(Shared.CatModel)
local CatRules = require(Shared.CatRules)
local Commands = require(Shared.Commands)
local DebugService = require(script.Parent.DebugService)

export type Wild = {
	id: string,
	kind: string,
	tier: number,
	kg: number,
	zone: number, -- 0 for event cats placed anywhere
	spot: BasePart?, -- the hiding spot it holds (nil once caught / dropped / for event cats)
	model: Model,
	state: string,
	event: string?, -- "Mythical" | "Secret" for event cats (task 1.18)
}

local WildCatService = {}

local cats: { [string]: Wild } = {}
local taken: { [BasePart]: boolean } = {}
local folder: Folder
local rng = Random.new()
local nextId = 0
local removedEvent = Instance.new("BindableEvent")

-- Fires (wildId, reason) when a wild cat leaves the world: "caught" | "escaped" | "returned" | "event".
-- (An id, not the record: BindableEvents copy tables, so a record would not compare equal.)
WildCatService.Removed = removedEvent.Event

local function spotsOf(zone: number): { BasePart }
	local out = {}
	local map = workspace:FindFirstChild("Map")
	local f = map and map:FindFirstChild("HideSpots") and map.HideSpots:FindFirstChild(`Zone{zone}`)
	if f then
		for _, p in f:GetChildren() do
			if p:IsA("BasePart") then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function freeSpot(zone: number, avoid: BasePart?): BasePart?
	local free = {}
	for _, p in spotsOf(zone) do
		if not taken[p] and p ~= avoid then
			table.insert(free, p)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[rng:NextInteger(1, #free)]
end

local function setState(w: Wild, state: string)
	w.state = state
	w.model:SetAttribute("State", state)
	w.model:SetAttribute("Anim", if state == "hooked" then "struggle" elseif state == "carried" then "carried" else "idle")
end

local function build(kind: string, kg: number, at: CFrame, size: number, zone: number): Wild
	local design = Cats.ById[kind]
	nextId += 1
	local id = `w{nextId}`
	local model = CatModel.build(design.Look :: any, at, CatRules.size(design.Tier, kg) * size)
	model.Name = id
	model:SetAttribute("WildId", id)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Tier", design.Tier)
	model:SetAttribute("Kg", kg)
	model:SetAttribute("Zone", zone)
	CollectionService:AddTag(model, "WildCat")
	model.Parent = folder
	local w: Wild = { id = id, kind = kind, tier = design.Tier, kg = kg, zone = zone, spot = nil, model = model, state = "hiding" }
	cats[id] = w
	setState(w, "hiding")
	return w
end

-- Puts a new rolled cat at a free spot of the zone. Returns it, or nil when every spot is taken.
function WildCatService.spawnInZone(zone: number, avoid: BasePart?): Wild?
	local z = Config.World.Zones[zone]
	local spot = freeSpot(zone, avoid)
	if not z or not spot then
		return nil
	end
	local tier = CatRules.pickTier(z.Odds, rng:NextNumber())
	local list = Cats.ByTier[tier]
	local kind = list[rng:NextInteger(1, #list)]
	local kg = CatRules.rollKg(tier, rng:NextNumber(), (z :: any).KgSkew)
	local kindName = spot:GetAttribute("Kind")
	local size = Config.WildCats.SizeBySpot[if type(kindName) == "string" then kindName else "rock"] or 1
	local at = CFrame.new(spot.Position - Vector3.new(0, 1, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local w = build(kind, kg, at, size, zone)
	w.spot = spot
	taken[spot] = true
	return w
end

-- An event cat (task 1.18) at any position, not on a hiding spot.
function WildCatService.spawnAt(kind: string, kg: number, at: CFrame, event: string?): Wild
	local w = build(kind, kg, at, 1, 0)
	w.event = event
	w.model:SetAttribute("Event", event)
	return w
end

function WildCatService.get(id: string): Wild?
	return cats[id]
end

function WildCatService.all(): { [string]: Wild }
	return cats
end

function WildCatService.setState(w: Wild, state: string)
	setState(w, state)
end

-- The cat leaves its hiding spot (caught): the spot is free again for others.
function WildCatService.leaveSpot(w: Wild)
	if w.spot then
		taken[w.spot] = nil
		w.spot = nil
	end
end

-- Removes a wild cat from the world; a normal zone cat is replaced at another spot after 30-90 s.
function WildCatService.remove(w: Wild, reason: string)
	if not cats[w.id] then
		return
	end
	cats[w.id] = nil
	local oldSpot = w.spot
	WildCatService.leaveSpot(w)
	if w.model.Parent then
		w.model:Destroy()
	end
	removedEvent:Fire(w.id, reason)
	if w.zone > 0 then
		local wait = rng:NextNumber(Config.WildCats.RespawnMin, Config.WildCats.RespawnMax)
		task.delay(wait, function()
			WildCatService.spawnInZone(w.zone, oldSpot)
		end)
	end
end

-- Hands a caught cat's model over (CarryService welds it to the carrier); the wild record ends.
function WildCatService.take(w: Wild): Model
	cats[w.id] = nil
	WildCatService.leaveSpot(w)
	CollectionService:RemoveTag(w.model, "WildCat")
	removedEvent:Fire(w.id, "caught")
	if w.zone > 0 then
		local wait = rng:NextNumber(Config.WildCats.RespawnMin, Config.WildCats.RespawnMax)
		task.delay(wait, function()
			WildCatService.spawnInZone(w.zone)
		end)
	end
	return w.model
end

-- A knocked-loose cat lies where its carrier was hit (task 1.14): a new wild record, state "dropped",
-- fishable by everyone; nobody catching it in Config.Carry.DroppedSeconds sends it back into hiding.
function WildCatService.drop(kind: string, kg: number, at: CFrame, event: string?, zone: number?): Wild
	local w = build(kind, kg, at, 1, 0)
	w.event = event
	w.model:SetAttribute("Event", event)
	setState(w, "dropped")
	-- (its zone already got a replacement when it was caught, so "back into hiding" = it leaves)
	local _ = zone
	task.delay(Config.Carry.DroppedSeconds, function()
		if cats[w.id] == w and w.state == "dropped" then
			WildCatService.remove(w, "returned")
		end
	end)
	return w
end

function WildCatService:Init()
	local old = workspace:FindFirstChild("WildCats")
	if old then
		old:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "WildCats"
	folder.Parent = workspace

	DebugService.register("wild", "!wild  count wild cats per zone and state", function()
		local counts = {}
		for _, w in cats do
			local key = `z{w.zone}:{w.state}`
			counts[key] = (counts[key] or 0) + 1
		end
		local parts = {}
		for k, n in counts do
			table.insert(parts, `{k}={n}`)
		end
		table.sort(parts)
		return table.concat(parts, " ")
	end)
	DebugService.register("nearcat", "!nearcat [tier]  put a wild cat 15 studs in front of you", function(player, args)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return "no character"
		end
		local tier = math.clamp(Commands.integer(args[1]) or 1, 1, #Config.Tiers)
		local list = Cats.ByTier[tier]
		local kind = list[rng:NextInteger(1, #list)]
		local kg = CatRules.rollKg(tier, rng:NextNumber())
		local pos = (root.CFrame * CFrame.new(0, 0, -15)).Position
		local ray = workspace:Raycast(pos + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0))
		local ground = if ray then ray.Position.Y else pos.Y - 3
		local w = WildCatService.spawnAt(kind, kg, CFrame.new(pos.X, ground, pos.Z), nil)
		return `{w.id}: {Cats.ById[kind].Name} ({Config.Tiers[tier].Key}, {kg} kg)`
	end)
end

function WildCatService:Start()
	for zone, z in Config.World.Zones do
		local n = 0
		for _ = 1, z.Cats do
			if WildCatService.spawnInZone(zone) then
				n += 1
			end
		end
		print(`[Sweetpotato] WildCatService: zone {zone} {z.Key}: {n} cats on {#spotsOf(zone)} spots`)
	end
end

return WildCatService
