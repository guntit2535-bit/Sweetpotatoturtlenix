--!strict
-- Rebirth (task 2.7, blueprint §11; SKY PUTT's RebirthService): up to Config.Rebirth.Max times. Needs Strength
-- >= CatRules.rebirthNeed(rebirths). Resets money, Strength, Speed and the weights / treadmill levels; keeps
-- cats, the book, rods, shoes and pen slots; every rebirth gives x1.5 money and x1.5 Strength for good
-- (shared/Bonus) and opens zones by rebirth count (Config.World.Zones[i].Rebirths). Saved before the toast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CatRules = require(Shared.CatRules)
local Config = require(Shared.Config)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)

local RebirthService = {}

local function onRebirth(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local need = CatRules.rebirthNeed(data.Rebirths)
	if not need then
		Notify.send(player, "RebirthMax", nil, "info")
		return
	end
	if data.Strength < need then
		Notify.send(player, "RebirthNotYet", nil, "bad")
		return
	end
	CarryService.drop(player) -- a carried cat is not lost: it drops where they stand
	DataService.Update(player, function(d)
		d.Rebirths += 1
		d.Money = 0
		d.MoneyFrac = 0
		d.Strength = Config.Data.StartStrength
		d.Speed = 0
		d.WeightsLevel = 1
		d.TreadLevel = 1
	end)
	DataService.SaveAsync(player)
	Notify.send(player, "RebirthDone", { n = data.Rebirths }, "good")
end

function RebirthService:Init()
	Guard.onEvent("Rebirth", { maxCalls = 1, window = 2 }, onRebirth)
end

return RebirthService
