--!strict
-- Cat crates (task 2.6, blueprint §12; SKY PUTT's CrateService rules): bought with in-game money (not
-- Robux, so not a paid random item), the odds are shown before buying (shared/Crates, the same table), the
-- server rolls tier, design, weight and mutation (with the buyer's luck), the cat goes straight into the pen
-- and the save is written before CrateResult tells the client what came out. A full pen refuses the crate
-- before any money is taken. No Secret in any crate. `!crate <key> <n>` checks the odds at scale.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Bonus = require(Shared.Bonus)
local Cats = require(Shared.Cats)
local CatRules = require(Shared.CatRules)
local Commands = require(Shared.Commands)
local Config = require(Shared.Config)
local Crates = require(Shared.Crates)
local Format = require(Shared.Format)
local Mutation = require(Shared.Mutation)
local Remotes = require(Shared.Remotes)
local Validate = require(Shared.Validate)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local Progress = require(script.Parent.Parent.Util.Progress)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local PenService = require(script.Parent.PenService)

local CrateService = {}

local rng = Random.new()
local resultRemote: RemoteEvent
local busy: { [Player]: boolean } = {}

local function keys(): { string }
	local out = {}
	for _, c in Config.Crates.List do
		table.insert(out, c.Key)
	end
	return out
end

local function onBuy(player: Player, rawKey: unknown)
	local key = Validate.oneOf(rawKey, keys())
	local data = DataService.GetData(player)
	if not key or not data or busy[player] then
		return
	end
	local crate = Crates.get(key)
	if not PenService.hasRoom(player) then
		Notify.send(player, "PenFull", { max = data.PenSlots }, "bad")
		return
	end
	if not DataService.SpendMoney(player, crate.Cost) then
		Notify.send(player, "NotEnoughMoney", { cost = Format.short(crate.Cost) }, "bad")
		return
	end
	busy[player] = true
	if not CrateService.give(player, key) then
		DataService.AddMoney(player, crate.Cost) -- the pen filled up in between: money back
	end
	busy[player] = nil
	Progress.add(player, "Crate", 1)
end

-- Rolls a crate for free (paid above, or a reward) into the pen; saved before CrateResult. False when full.
function CrateService.give(player: Player, key: string): boolean
	local data = DataService.GetData(player)
	if not data or not Crates.get(key) or not PenService.hasRoom(player) then
		return false
	end
	local tier = Crates.roll(key, rng:NextNumber())
	local list = Cats.ByTier[tier]
	local kind = list[rng:NextInteger(1, #list)]
	local kg = CatRules.rollKg(tier, rng:NextNumber())
	local mutation = Mutation.roll(tier, Bonus.luck(BonusCtx.of(player, data)), rng:NextNumber())
	local id = PenService.addCat(player, kind, kg, mutation)
	if not id then
		return false
	end
	DataService.SaveAsync(player) -- saved before it is shown
	resultRemote:FireClient(player, key, kind, kg, mutation)
	return true
end

function CrateService:Init()
	resultRemote = Remotes.event("CrateResult")
	Guard.onEvent("BuyCrate", Config.Crates.BuyRate, onBuy)
	DebugService.register("crate", "!crate <Paper|Wood|Gold|Diamond> N  roll N crates (nothing given) and print the tiers", function(_, args)
		local key = args[1]
		local n = math.clamp(Commands.integer(args[2]) or 1000, 1, 1000000)
		if not key or not Crates.get(key) then
			return "usage: !crate Paper 10000"
		end
		local counts: { [number]: number } = {}
		for _ = 1, n do
			local t = Crates.roll(key, rng:NextNumber())
			counts[t] = (counts[t] or 0) + 1
		end
		local parts = {}
		for _, o in Crates.odds(key) do
			table.insert(parts, string.format("%s %.2f%% (odds %s%%)", Config.Tiers[o.tier].Key, (counts[o.tier] or 0) / n * 100, tostring(o.percent)))
		end
		return `{key} x{n}: ` .. table.concat(parts, ", ")
	end)
end

function CrateService:Start()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return CrateService
