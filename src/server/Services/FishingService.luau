--!strict
-- Fishing cats with the rod (tasks 1.11 / 1.12, blueprint §2-3; Pet Storm Escape's multi-catcher capture).
-- Cast(wildId): the server checks the rod is held, the distance, the cat can be fished, and Strength >= its
-- weight (else "Need X Strength"). Each fishing player gets their own bar (shared/FishingBar), stepped here
-- from their FishHold input; the client only draws it. Several players can fish the same cat: the first
-- full meter wins (CarryService.pickUp), everyone else is dropped at once. An empty meter = the cat breaks
-- free and hides somewhere new. Fishing players stand still and cannot be hit (BatService asks isFishing).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Cats = require(Shared.Cats)
local Bonus = require(Shared.Bonus)
local CatRules = require(Shared.CatRules)
local BonusCtx = require(script.Parent.Parent.Util.BonusCtx)
local FishingBar = require(Shared.FishingBar)
local Mutation = require(Shared.Mutation)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Validate = require(Shared.Validate)
local Guard = require(script.Parent.Parent.Util.Guard)
local Notify = require(script.Parent.Parent.Util.Notify)
local ToolAnim = require(script.Parent.Parent.Util.ToolAnim)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local MovementService = require(script.Parent.MovementService)
local WildCatService = require(script.Parent.WildCatService)

type Session = {
	wild: WildCatService.Wild,
	bar: FishingBar.State,
	holding: boolean,
	sinceSnap: number,
	beam: Beam?,
}

local FishingService = {}

local sessions: { [Player]: Session } = {}
local startRemote: RemoteEvent
local stateRemote: RemoteEvent
local endRemote: RemoteEvent

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function FishingService.isFishing(player: Player): boolean
	return sessions[player] ~= nil
end

local function stillFishing(w: WildCatService.Wild): boolean
	for _, s in sessions do
		if s.wild == w then
			return true
		end
	end
	return false
end

local function finish(player: Player, key: string, vars: { [string]: any }?, caught: boolean?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	if s.beam then
		local a0 = s.beam.Attachment1
		s.beam:Destroy()
		if a0 then
			a0:Destroy()
		end
	end
	MovementService.setFactor(player, "fishing", nil)
	player:SetAttribute("Fishing", nil)
	endRemote:FireClient(player, key, vars, caught == true)
	-- nobody else on it: the cat calms down where it is
	local w = s.wild
	if WildCatService.get(w.id) == w and not stillFishing(w) and w.state == "hooked" then
		WildCatService.setState(w, (w :: any).restState or "hiding")
	end
end

local function makeBeam(player: Player, w: WildCatService.Wild): Beam?
	local character = player.Character
	local rod = character and character:FindFirstChild("Rod")
	local tip = rod and rod:FindFirstChild("Tip", true)
	local catRoot = w.model.PrimaryPart
	if not tip or not tip:IsA("Attachment") or not catRoot then
		return nil
	end
	local hook = Instance.new("Attachment")
	hook.Name = `Hook_{player.UserId}`
	hook.Position = Vector3.new(0, catRoot.Size.Y * 0.3, 0)
	hook.Parent = catRoot
	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = hook
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	beam.FaceCamera = true
	beam.CurveSize0 = 2
	beam.Segments = 12
	beam.Parent = tip
	return beam
end

local function onCast(player: Player, rawId: unknown)
	local id = Validate.id(rawId)
	if not id or sessions[player] or CarryService.isCarrying(player) then
		return
	end
	local w = WildCatService.get(id)
	local root = rootOf(player)
	local data = DataService.GetData(player)
	local character = player.Character
	if not w or not root or not data or not character or not character:FindFirstChild("Rod") then
		return
	end
	if w.state ~= "hiding" and w.state ~= "hooked" and w.state ~= "dropped" then
		Notify.send(player, "CatBusy", nil, "bad")
		return
	end
	local catPos = w.model:GetPivot().Position
	if (catPos - root.Position).Magnitude > Config.Fishing.CastRange + 4 then
		return
	end
	-- R4: the world keeps the base weight; this player catches it at base x KgMult ^ their rebirths
	local kg = CatRules.kgFor(w.kg, data.Rebirths)
	if data.Strength < CatRules.strengthNeeded(kg) then
		Notify.send(player, "NeedStrength", { kg = Format.short(math.ceil(kg)) }, "bad")
		return
	end
	if w.state ~= "hooked" then
		(w :: any).restState = w.state
		WildCatService.setState(w, "hooked")
	end
	local seed = math.random(1, 2 ^ 30)
	local easy = Bonus.easy(BonusCtx.of(player, data))
	local bar = FishingBar.new(seed, FishingBar.params(w.tier, data.RodLevel, easy))
	sessions[player] = { wild = w, bar = bar, holding = false, sinceSnap = 0, beam = makeBeam(player, w) }
	MovementService.setFactor(player, "fishing", 0)
	player:SetAttribute("Fishing", w.id)
	-- face the cat and swing the rod (the reel pose follows from the "Fishing" attribute, PlayerAnimController)
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(catPos.X, root.Position.Y, catPos.Z))
	local rod = character:FindFirstChild("Rod")
	if rod then
		ToolAnim.play(rod, "Slash")
	end
	startRemote:FireClient(player, w.id, w.tier, FishingBar.snapshot(bar), data.RodLevel, easy)
end

local function onHold(player: Player, raw: unknown)
	local holding = Validate.boolean(raw)
	local s = sessions[player]
	if s and holding ~= nil then
		s.holding = holding
	end
end

local function step(dt: number)
	for player, s in sessions do
		local w = s.wild
		local root = rootOf(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		-- the cat is gone (someone else won, it escaped) / the player walked off, died or put the rod away
		if WildCatService.get(w.id) ~= w then
			if sessions[player] then
				finish(player, "FishEscaped")
			end
			continue
		end
		if not root or not humanoid or humanoid.Health <= 0 or not character:FindFirstChild("Rod")
			or (w.model:GetPivot().Position - root.Position).Magnitude > Config.Fishing.KeepRange then
			finish(player, "FishGaveUp")
			continue
		end
		local result = FishingBar.step(s.bar, dt, s.holding)
		if result == "win" then
			local design = Cats.ById[w.kind]
			local winnerName = player.DisplayName
			-- everyone else on this cat loses it at once
			for other, os2 in sessions do
				if other ~= player and os2.wild == w then
					finish(other, "FishLost", { name = winnerName })
				end
			end
			-- a mutation is rolled once, with the winner's luck (a knocked-loose cat keeps its own)
			local mutation = w.mutation or Mutation.roll(w.tier, Bonus.luck(BonusCtx.of(player, DataService.GetData(player))), math.random())
			finish(player, "FishCaught", {
				mutation = mutation,
				kind = w.kind, -- R9: the client draws the cat on the Caught! card
				name = if design then design.Name else "?",
				tier = Config.Tiers[w.tier].Key,
				kg = Format.money(CatRules.kgFor(w.kg, (DataService.GetData(player) or { Rebirths = 0 } :: any).Rebirths)),
			}, true)
			CarryService.pickUp(player, w, mutation)
		elseif result == "lose" then
			for other, os2 in sessions do
				if other ~= player and os2.wild == w then
					finish(other, "FishEscaped")
				end
			end
			finish(player, "FishEscaped")
			WildCatService.remove(w, "escaped")
		else
			s.sinceSnap += dt
			if s.sinceSnap >= Config.Fishing.SnapshotEvery then
				s.sinceSnap = 0
				stateRemote:FireClient(player, w.id, FishingBar.snapshot(s.bar))
			end
		end
	end
end

function FishingService:Init()
	startRemote = Remotes.event("FishStart")
	stateRemote = Remotes.event("FishState")
	endRemote = Remotes.event("FishEnd")
	Guard.onEvent("Cast", Config.Fishing.CastRate, onCast)
	Guard.onEvent("FishHold", Config.Fishing.HoldRate, onHold)
	Guard.onEvent("FishGiveUp", nil, function(player)
		finish(player, "FishGaveUp")
	end)
end

function FishingService:Start()
	Players.PlayerRemoving:Connect(function(player)
		finish(player, "FishGaveUp")
	end)
	task.spawn(function()
		local dt = 1 / Config.Fishing.TickRate
		while true do
			task.wait(dt)
			step(dt)
		end
	end)
end

return FishingService
