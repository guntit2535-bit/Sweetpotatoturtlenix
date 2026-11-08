--!strict
-- Walk speed (tasks 1.9 / 1.16, 2.3, 2.18): Humanoid.WalkSpeed = Bonus.walk(Speed stat, shoes, like buff,
-- x2 Speed pass), set on the server when the character spawns or any of those change.
-- Other services can slow a player down for a while: MovementService.setFactor(player, name, factor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bonus = require(ReplicatedStorage.Shared.Bonus)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local DataService = require(script.Parent.DataService)

local MovementService = {}

local factors: { [Player]: { [string]: number } } = {}

function MovementService.refresh(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = player:GetAttribute("Speed")
	local walk = Bonus.walk(if type(speed) == "number" then speed else 0, BonusCtx.of(player, DataService.GetData(player)))
	for _, f in factors[player] or {} do
		walk *= f
	end
	humanoid.WalkSpeed = walk
end

function MovementService.setFactor(player: Player, name: string, factor: number?)
	factors[player] = factors[player] or {}
	factors[player][name] = factor
	MovementService.refresh(player)
end

local function hook(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		MovementService.refresh(player)
	end)
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		MovementService.refresh(player)
	end)
	player:GetAttributeChangedSignal("LikeBuffUntil"):Connect(function()
		MovementService.refresh(player)
		local untilTime = player:GetAttribute("LikeBuffUntil")
		if type(untilTime) == "number" then
			task.delay(math.max(0, untilTime - workspace:GetServerTimeNow()) + 0.1, function()
				if player.Parent then
					MovementService.refresh(player)
				end
			end)
		end
	end)
	if player.Character then
		MovementService.refresh(player)
	end
end

function MovementService:Start()
	DataService.Changed:Connect(MovementService.refresh) -- shoes, the x2 Speed switch
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		factors[player] = nil
	end)
end

return MovementService
