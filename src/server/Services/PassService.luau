--!strict
-- Game passes (task 2.18, blueprint §13; Pet Storm Escape's PassService): x2 Speed, x2 Cash, x2 Strength, Lucky,
-- VIP. Ownership is checked on join and after a purchase in the game; it is shown as player attributes
-- "PassSpeed" / "PassCash" / "PassStrength" / "PassLucky" / "PassVIP" = true, which shared/Bonus reads
-- (Util/BonusCtx). Owners of x2 Speed switch it on and off (ToggleSpeed, saved). Pass ids are 0 until the
-- developer makes them: `!pass <Name> on|off` sets an attribute for tests.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local MovementService = require(script.Parent.MovementService)

local PassService = {}

-- attribute name -> Config.Passes key
PassService.Passes = {
	Speed = "Speed2x",
	Cash = "Cash2x",
	Strength = "Strength2x",
	Lucky = "Lucky",
	VIP = "VIP",
}

local function idOf(name: string): number
	local key = PassService.Passes[name]
	local p = key and (Config.Passes :: any)[key]
	return if p then p.Id else 0
end

local function check(player: Player)
	for name in PassService.Passes do
		local id = idOf(name)
		if id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and owns then
				player:SetAttribute(`Pass{name}`, true)
			end
		end
	end
	MovementService.refresh(player)
end

function PassService:Init()
	Guard.onEvent("ToggleSpeed", { maxCalls = 2, window = 1 }, function(player)
		if player:GetAttribute("PassSpeed") ~= true then
			return
		end
		DataService.Update(player, function(d)
			d.SpeedPassOn = not d.SpeedPassOn
		end)
		local d = DataService.GetData(player)
		Notify.send(player, if d and d.SpeedPassOn then "SpeedOn" else "SpeedOff", nil, "info")
	end)
	DebugService.register("pass", "!pass <Speed|Cash|Strength|Lucky|VIP> on|off  pretend to own a pass", function(player, args)
		local name = args[1]
		if not name or not PassService.Passes[name] then
			return "usage: !pass Cash on"
		end
		player:SetAttribute(`Pass{name}`, if args[2] == "off" then nil else true)
		MovementService.refresh(player)
		return `Pass{name} = {player:GetAttribute(`Pass{name}`)}`
	end)
end

function PassService:Start()
	Players.PlayerAdded:Connect(check)
	for _, p in Players:GetPlayers() do
		task.spawn(check, p)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		if not bought then
			return
		end
		for name in PassService.Passes do
			if idOf(name) == passId then
				player:SetAttribute(`Pass{name}`, true)
				Notify.send(player, "PurchaseThanks", { nameKey = "Pass" .. name }, "good")
			end
		end
		MovementService.refresh(player)
	end)
end

return PassService
