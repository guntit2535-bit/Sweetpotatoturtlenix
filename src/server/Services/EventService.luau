--!strict
-- Mythical and Secret cat events (task 1.18, blueprint §10; Pet Storm Escape's Mythic / Golden events).
-- A Mythical cat every 10-20 minutes (random) and a Secret cat every 40 minutes appear at a random
-- hiding spot anywhere on the map: everyone is told, a light beam rises from the cat, the clients show the
-- way and a countdown. Nobody hooking it within 3 minutes = it runs away. Caught event cats are carried
-- home like any cat (and can be knocked loose). One event at a time; a due event waits for the live one.
-- Workspace attributes for the clients: NextMythicalAt, NextSecretAt, LiveEvent ("Mythical" | "Secret"),
-- LiveEventEnds, LiveEventPos (all server times / positions).
-- Milestone 2's "summon Mythical" product calls EventService.start("Mythical").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local CatRules = require(Shared.CatRules)
local Commands = require(Shared.Commands)
local Notify = require(script.Parent.Parent.Util.Notify)
local CarryService = require(script.Parent.CarryService)
local DebugService = require(script.Parent.DebugService)
local WildCatService = require(script.Parent.WildCatService)

local EventService = {}

local rng = Random.new()
local live: { kind: string, wild: WildCatService.Wild, beam: BasePart, ends: number }? = nil
local nextAt = { Mythical = 0, Secret = 0 }

local function now(): number
	return workspace:GetServerTimeNow()
end

local function publish()
	workspace:SetAttribute("NextMythicalAt", nextAt.Mythical)
	workspace:SetAttribute("NextSecretAt", nextAt.Secret)
	workspace:SetAttribute("LiveEvent", if live then live.kind else nil)
	workspace:SetAttribute("LiveEventEnds", if live then live.ends else nil)
	workspace:SetAttribute("LiveEventPos", if live then live.wild.model:GetPivot().Position else nil)
end

local function schedule(kind: string)
	if kind == "Mythical" then
		local e = Config.Events.MythicalEvery
		nextAt.Mythical = now() + rng:NextNumber(e[1], e[2])
	else
		nextAt.Secret = now() + Config.Events.SecretEvery
	end
	publish()
end

local function randomSpot(): CFrame?
	local map = workspace:FindFirstChild("Map")
	local spots = map and map:FindFirstChild("HideSpots")
	if not spots then
		return nil
	end
	local all = {}
	for _, d in spots:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(all, d)
		end
	end
	if #all == 0 then
		return nil
	end
	local p = all[rng:NextInteger(1, #all)]
	-- stand next to the spot, on the ground
	local pos = p.Position + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
	local ray = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0))
	local ground = if ray then ray.Position else pos
	return CFrame.new(ground) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

local function makeBeam(kind: string, at: Vector3): BasePart
	local beam = Instance.new("Part")
	beam.Name = `{kind}Beam`
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(Config.Events.BeamHeight, 6, 6)
	beam.CFrame = CFrame.new(at + Vector3.new(0, Config.Events.BeamHeight / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Color = if kind == "Secret" then Color3.fromHex("18c9b9") else Color3.fromHex("ff5fa2")
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.45
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam:SetAttribute("Event", kind)
	beam.Parent = workspace
	return beam
end

local function endLive(reason: string, winner: Player?)
	local l = live
	if not l then
		return
	end
	live = nil
	if l.beam.Parent then
		l.beam:Destroy()
	end
	if reason == "escaped" then
		if WildCatService.get(l.wild.id) == l.wild then
			WildCatService.remove(l.wild, "event")
		end
		Notify.all("EventEscaped", { event = l.kind }, "event")
	elseif reason == "caught" and winner then
		Notify.all("EventCaught", { name = winner.DisplayName, event = l.kind }, "event")
	end
	publish()
end

-- Starts an event now (also the debug commands and the milestone 2 summon product).
function EventService.start(kind: string): string
	if live then
		return "an event is already live"
	end
	local at = randomSpot()
	if not at then
		return "no hiding spots on the map"
	end
	local tier = if kind == "Secret" then 6 else 5
	local list = Cats.ByTier[tier]
	local catKind = list[rng:NextInteger(1, #list)]
	local kg = CatRules.rollKg(tier, rng:NextNumber())
	local w = WildCatService.spawnAt(catKind, kg, at, kind)
	live = { kind = kind, wild = w, beam = makeBeam(kind, at.Position), ends = now() + Config.Events.EscapeSeconds }
	Notify.all(if kind == "Secret" then "EventOutSecret" else "EventOutMythical", nil, "event")
	publish()
	return `{kind}: {Cats.ById[catKind].Name} ({kg} kg) at {math.floor(at.Position.X)}, {math.floor(at.Position.Z)}`
end

function EventService:Init()
	DebugService.register("mythical", "!mythical  start a Mythical event now", function()
		return EventService.start("Mythical")
	end)
	DebugService.register("secret", "!secret  start a Secret event now", function()
		return EventService.start("Secret")
	end)
	DebugService.register("eventin", "!eventin mythical|secret S  next event in S seconds", function(_, args)
		local s = Commands.integer(args[2])
		local which = if args[1] == "secret" then "Secret" else "Mythical"
		if not s then
			return "usage: !eventin mythical|secret S"
		end
		nextAt[which] = now() + s
		publish()
		return `{which} in {s} s`
	end)
	DebugService.register("endevent", "!endevent  make the live event cat run away", function()
		endLive("escaped")
		return "ended"
	end)
end

function EventService:Start()
	schedule("Mythical")
	schedule("Secret")
	-- caught: the event is won once someone carries it home or takes it (it can still be knocked loose)
	CarryService.Delivered:Connect(function(player, _kind, _kg, event)
		if event and live and live.kind == event then
			endLive("caught", player)
		elseif event then
			Notify.all("EventCaught", { name = player.DisplayName, event = event }, "event")
		end
	end)
	-- the live cat leaves the world: caught = the beam goes (it is carried now); broke free from a rod =
	-- it hides at a new spot and the event goes on (blueprint §2: an empty meter = it hides somewhere new)
	WildCatService.Removed:Connect(function(id: string, reason: string)
		local l = live
		if not l or l.wild.id ~= id then
			return
		end
		if reason == "caught" then
			if l.beam.Parent then
				l.beam:Destroy()
			end
			live = nil
			publish()
		elseif reason == "escaped" then
			local at = randomSpot()
			if not at then
				endLive("escaped")
				return
			end
			l.wild = WildCatService.spawnAt(l.wild.kind, l.wild.kg, at, l.kind)
			l.beam.CFrame = CFrame.new(at.Position + Vector3.new(0, Config.Events.BeamHeight / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			Notify.all("EventMoved", { event = l.kind }, "event")
			publish()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			local l = live
			if l then
				local w = l.wild
				if WildCatService.get(w.id) ~= w then
					continue -- being replaced or carried (handled by Removed)
				elseif w.state == "hooked" then
					l.ends = math.max(l.ends, t + 5) -- someone is fishing it: no escape mid-fight
					publish()
				elseif t >= l.ends then
					endLive("escaped")
				end
			else
				for _, kind in { "Secret", "Mythical" } do
					if t >= (nextAt :: any)[kind] and not live then
						EventService.start(kind)
						schedule(kind)
					end
				end
			end
		end
	end)
end

return EventService
