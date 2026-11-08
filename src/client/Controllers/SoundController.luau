--!strict
-- Every sound and the music on this client (task 2.23; ids in Config.Sounds / Config.Music, all 0 until the
-- developer picks them from docs/Sweetpotato_Sounds.xlsx: a key with id 0 is silent). It only listens to
-- signals the game already has, so the other controllers stay as they were:
--   UI: every button click (not the fishing HOLD button), a window opening, every toast by its key / kind
--   catching: reel loop while your own minigame runs, catch + meow / escape at the end, hidden cats near the
--     camera meow now and then (a hint where they are)
--   tools: anyone's cast / bat swing near the camera (the server's "toolanim" in the held tool), a bat hit
--   training: a soft tick on each Strength / Speed gain while training
--   crates: shake, then reveal (rare for Legendary or better) after Config.Crates.RevealSeconds
--   music: Lobby inside the lobby ring, Zones outside, Mythical / Secret while that event is live
--     (cross-fade Config.MusicFade); event_start when an event begins
-- The Settings switches (MusicOn / SfxOn attributes) mute the Music / SFX sound groups.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatModel = require(Shared:WaitForChild("CatModel"))
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sound = require(script.Parent.Parent.Sound)

local SoundController = {}

local me = Players.LocalPlayer

-- Toast key -> sound (keys not listed use their kind: good -> claim, bad -> error, info -> toast).
local TOASTS: { [string]: string } = {
	Bought = "buy",
	PurchaseThanks = "buy",
	SoldCat = "coins",
	RewardMoney = "coins",
	OfflineIncome = "coins",
	CatHome = "deliver",
	EventCaught = "fanfare",
	RebirthDone = "rebirth",
	LikeGot = "like",
	LikeDone = "like",
	BatHitCat = "bonk",
	BatDropped = "drop",
	EventEscaped = "escape",
	EventMythical = "", -- the music change and event_start cover these
	EventMoved = "",
	ServerLuckOn = "event_start",
	CarryHint = "",
}
local KINDS: { [string]: string } = { good = "claim", bad = "error", info = "toast", event = "toast" }

-- Settings ---------------------------------------------------------------------------------------

local function applySwitches()
	Sound.music.Volume = if me:GetAttribute("MusicOn") == false then 0 else 1
	Sound.sfx.Volume = if me:GetAttribute("SfxOn") == false then 0 else 1
end

-- Music ------------------------------------------------------------------------------------------

local songs: { [string]: Sound } = {}
local currentSong: string? = nil

local function songFor(key: string): Sound?
	local id = (Config.Music :: any)[key]
	if type(id) ~= "number" or id <= 0 then
		return nil
	end
	local song = songs[key]
	if not song then
		local made = Instance.new("Sound")
		made.Name = `Music_{key}`
		made.SoundId = `rbxassetid://{id}`
		made.Looped = true
		made.Volume = 0
		made.SoundGroup = Sound.music
		made.Parent = SoundService
		songs[key] = made
		song = made
	end
	return song
end

local function playSong(key: string)
	if key == currentSong then
		return
	end
	local fade = TweenInfo.new(Config.MusicFade)
	local old = if currentSong then songs[currentSong] else nil
	if old then
		local tween = TweenService:Create(old, fade, { Volume = 0 })
		tween:Play()
		local stopping = old
		tween.Completed:Once(function()
			if stopping.Volume < 0.01 then
				stopping:Pause()
			end
		end)
	end
	currentSong = key
	local song = songFor(key)
	if song then
		if not song.IsPlaying then
			song:Play()
		end
		TweenService:Create(song, fade, { Volume = Config.MusicVolume }):Play()
	end
end

local function musicKey(): string
	local live = workspace:GetAttribute("LiveEvent")
	if live == "Mythical" or live == "Secret" then
		return live
	end
	local root = me.Character and me.Character.PrimaryPart
	local pos = if root then root.Position else Vector3.zero
	return if Vector3.new(pos.X, 0, pos.Z).Magnitude < Config.World.LobbyRadius then "Lobby" else "Zones"
end

-- UI ---------------------------------------------------------------------------------------------

local hooked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function hookGui(d: Instance)
	if hooked[d] then
		return
	end
	if d:IsA("GuiButton") and d.Name ~= "Hold" then
		hooked[d] = true
		d.Activated:Connect(function()
			Sound.play("click")
		end)
	elseif d:IsA("ScreenGui") and string.sub(d.Name, -6) == "Window" then
		hooked[d] = true
		d:GetPropertyChangedSignal("Enabled"):Connect(function()
			if d.Enabled then
				Sound.play("open")
			end
		end)
	end
end

local function onToast(key: unknown, _vars: unknown, kind: unknown)
	if type(key) ~= "string" then
		return
	end
	local s = TOASTS[key]
	if s == nil then
		s = if type(kind) == "string" then KINDS[kind] else nil
	end
	if s and s ~= "" then
		Sound.play(s)
	end
end

-- Tools (anyone's cast / swing) ------------------------------------------------------------------

local function hookTool(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] then
		return
	end
	hooked[tool] = true
	tool.ChildAdded:Connect(function(c)
		if c.Name == "toolanim" then
			local handle = tool:FindFirstChild("Handle")
			local at = if handle and handle:IsA("BasePart") then handle.Position else nil
			Sound.play(if tool.Name == "Bat" then "swing" else "cast", { at = at })
		end
	end)
end

local function hookCharacter(character: Model)
	for _, c in character:GetChildren() do
		hookTool(c)
	end
	character.ChildAdded:Connect(hookTool)
end

local function hookPlayer(player: Player)
	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)
end

-- Fishing ----------------------------------------------------------------------------------------

local reel: Sound? = nil

local function stopReel()
	if reel then
		reel:Destroy()
		reel = nil
	end
end

-- Hidden cats meow now and then -------------------------------------------------------------------

local function meowNearby()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local near: { Model } = {}
	for _, m in CollectionService:GetTagged(CatModel.Tag) do
		if m:IsA("Model") and m:GetAttribute("State") == "hiding" then
			if (m:GetPivot().Position - eye).Magnitude < Config.SoundMeow.Range then
				table.insert(near, m)
			end
		end
	end
	if #near > 0 then
		local cat = near[math.random(1, #near)]
		Sound.play("meow", { at = cat:GetPivot().Position, pitch = 0.9 + math.random() * 0.35, range = Config.SoundMeow.Range })
	end
end

function SoundController.Start(_self: any)
	task.spawn(Sound.preload)
	applySwitches()
	me:GetAttributeChangedSignal("MusicOn"):Connect(applySwitches)
	me:GetAttributeChangedSignal("SfxOn"):Connect(applySwitches)

	local gui = me:WaitForChild("PlayerGui")
	for _, d in gui:GetDescendants() do
		hookGui(d)
	end
	gui.DescendantAdded:Connect(hookGui)

	Remotes.event("Notify").OnClientEvent:Connect(onToast)
	Remotes.event("Knockback").OnClientEvent:Connect(function()
		Sound.play("bonk")
	end)
	Remotes.event("FishStart").OnClientEvent:Connect(function()
		stopReel()
		reel = Sound.loop("reel")
	end)
	Remotes.event("FishEnd").OnClientEvent:Connect(function(key: unknown, _vars: unknown, caught: unknown)
		stopReel()
		if caught == true then
			Sound.play("catch")
			task.delay(0.3, function()
				Sound.play("meow")
			end)
		elseif key == "FishEscaped" then
			Sound.play("escape")
		end
	end)
	Remotes.event("CrateResult").OnClientEvent:Connect(function(_key: unknown, kind: unknown)
		local shake = Sound.play("crate_shake")
		local design = if type(kind) == "string" then Cats.ById[kind] else nil
		task.delay(Config.Crates.RevealSeconds, function()
			if shake and shake.Parent then
				shake:Stop() -- the shake sound may be longer than the shake
			end
			Sound.play(if design and design.Tier >= 4 then "crate_rare" else "crate_reveal")
		end)
	end)

	for _, p in Players:GetPlayers() do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)

	-- training ticks
	local lastTick = 0
	local function onGain(name: string)
		local last = me:GetAttribute(name)
		me:GetAttributeChangedSignal(name):Connect(function()
			local now = me:GetAttribute(name)
			if type(now) == "number" and type(last) == "number" and now > last and me:GetAttribute("Training") ~= nil then
				if os.clock() - lastTick >= Config.SoundTrainGap then
					lastTick = os.clock()
					Sound.play("train", { pitch = 0.95 + math.random() * 0.1 })
				end
			end
			last = now
		end)
	end
	onGain("Strength")
	onGain("Speed")

	-- events
	workspace:GetAttributeChangedSignal("LiveEvent"):Connect(function()
		if workspace:GetAttribute("LiveEvent") ~= nil then
			Sound.play("event_start")
		end
		playSong(musicKey())
	end)

	-- music by place, and the meows
	task.spawn(function()
		local nextMeow = os.clock() + math.random(Config.SoundMeow.Every[1], Config.SoundMeow.Every[2])
		while true do
			playSong(musicKey())
			if os.clock() >= nextMeow then
				nextMeow = os.clock() + math.random(Config.SoundMeow.Every[1], Config.SoundMeow.Every[2])
				meowNearby()
			end
			task.wait(1)
		end
	end)
end

return SoundController
