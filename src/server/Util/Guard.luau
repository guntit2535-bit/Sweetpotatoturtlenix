--!strict
-- The only way to listen to a client -> server remote. Every handler:
--   - is rate limited per player (Config.Remotes defaults, or its own rate),
--   - receives its arguments as `unknown` and must check them (src/shared/Validate),
--   - runs in pcall, so a bad call is logged and dropped instead of breaking the remote.
-- Limiter entries are cleared when a player leaves.
--
--   Guard.onEvent("RequestFeed", nil, function(player, creatureId, foodId)
--       local id = Validate.id(creatureId)
--       if not id then return end
--       ...
--   end)
--   Guard.onInvoke("GetData", { maxCalls = 2, window = 1 }, function(player) return ... end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local RateLimiter = require(script.Parent.RateLimiter)

export type Rate = { maxCalls: number, window: number }

local Guard = {}

local limiters: { RateLimiter.RateLimiter } = {}

local function newLimiter(rate: Rate?): RateLimiter.RateLimiter
	local maxCalls = if rate then rate.maxCalls else Config.Remotes.DefaultMaxCalls
	local window = if rate then rate.window else Config.Remotes.DefaultWindow
	local limiter = RateLimiter.new(maxCalls, window)
	table.insert(limiters, limiter)
	return limiter
end

local function fail(name: string, player: Player, err: unknown)
	warn(`[Sweetpotato] remote {name} from {player.Name} failed: {err}`)
end

function Guard.onEvent(name: string, rate: Rate?, handler: (player: Player, ...unknown) -> ())
	local remote = Remotes.event(name)
	local limiter = newLimiter(rate)
	remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not limiter:allow(player) then
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			fail(name, player, err)
		end
	end)
end

-- A rate-limited or failing call returns nil to the client.
function Guard.onInvoke(name: string, rate: Rate?, handler: (player: Player, ...unknown) -> unknown)
	local remote = Remotes.func(name)
	local limiter = newLimiter(rate)
	remote.OnServerInvoke = function(player: Player, ...: unknown): unknown
		if not limiter:allow(player) then
			return nil
		end
		local ok, result = pcall(handler, player, ...)
		if not ok then
			fail(name, player, result)
			return nil
		end
		return result
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	for _, limiter in limiters do
		limiter:clear(player)
	end
end)

return Guard
