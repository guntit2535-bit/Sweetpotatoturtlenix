--!strict
-- The baseball bat (task 1.14, blueprint §4; HatchRush's BatService). Swing() from the client; the server
-- checks the bat is held, the cooldown, and finds the nearest player in front within range. Nobody can hit
-- or be hit inside the lobby, and players who are fishing cannot be hit. A hit carrier drops the cat where
-- they stand (fishable by everyone, the hitter too) and flies far; anyone else is only pushed. The push is
-- applied by the victim's client (Knockback remote), which owns its character's physics.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local Progress = require(script.Parent.Parent.Util.Progress)
local ToolAnim = require(script.Parent.Parent.Util.ToolAnim)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local FishingService = require(script.Parent.FishingService)

local BatService = {}

local lastSwing: { [Player]: number } = {}
local knockRemote: RemoteEvent

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function inLobby(pos: Vector3): boolean
	return Vector3.new(pos.X, 0, pos.Z).Magnitude < Config.World.LobbyRadius
end

local function alive(player: Player): boolean
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0
end


local function onSwing(player: Player)
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < Config.Bat.Cooldown then
		return
	end
	local character = player.Character
	local bat = character and character:FindFirstChild("Bat")
	local root = rootOf(player)
	if not bat or not root or not alive(player) then
		return
	end
	lastSwing[player] = now
	ToolAnim.play(bat, "Slash")
	if inLobby(root.Position) then
		return
	end
	local look = root.CFrame.LookVector
	local best: Player? = nil
	local bestDist = math.huge
	for _, other in Players:GetPlayers() do
		local r = rootOf(other)
		if other ~= player and r and alive(other) and not FishingService.isFishing(other) and not inLobby(r.Position) then
			local offset = r.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local dist = flat.Magnitude
			if dist <= Config.Bat.Range and dist > 0.01 and look:Dot(flat.Unit) >= Config.Bat.Arc and math.abs(offset.Y) < 8 and dist < bestDist then
				best = other
				bestDist = dist
			end
		end
	end
	if not best then
		return
	end
	local target = best :: Player
	local targetRoot = rootOf(target) :: BasePart
	local dir = Vector3.new(targetRoot.Position.X - root.Position.X, 0, targetRoot.Position.Z - root.Position.Z).Unit
	if CarryService.isCarrying(target) then
		CarryService.drop(target)
		DataService.Update(player, function(d)
			d.Stats.Hits += 1
		end)
		knockRemote:FireClient(target, dir * Config.Bat.Knock + Vector3.new(0, Config.Bat.KnockUp, 0), Config.Bat.StunSeconds)
		Progress.add(player, "Hit", 1)
		Notify.send(target, "BatDropped", { name = player.DisplayName }, "bad")
		Notify.send(player, "BatHitCat", { name = target.DisplayName }, "good")
	else
		knockRemote:FireClient(target, dir * Config.Bat.SmallKnock + Vector3.new(0, Config.Bat.SmallKnockUp, 0), Config.Bat.SmallStunSeconds)
	end
end

function BatService:Init()
	knockRemote = Remotes.event("Knockback")
	Guard.onEvent("Swing", Config.Bat.SwingRate, onSwing)
end

function BatService:Start()
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return BatService
