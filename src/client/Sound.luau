--!strict
-- Sound effects on this client (task 2.23; ids in Config.Sounds, volumes in Config.SoundVolumes).
--   Sound.play(key, opts)  plays a sound once; opts.at = a world position (fades with distance, opts.range
--                          studs, default Config.SoundRange), opts.volume (x the key's volume), opts.pitch.
--                          Returns the Sound (nil for a key whose id is still 0).
--   Sound.loop(key, opts)  a looping sound (2D, or in opts.parent); the caller stops / destroys it.
-- Every effect goes through the SoundGroup "SFX" and music through "Music" (made here); the Settings
-- switches (player attributes MusicOn / SfxOn) mute them (SoundController).

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

export type Options = { at: Vector3?, volume: number?, pitch: number?, range: number?, parent: Instance? }

local Sound = {}

local function group(name: string): SoundGroup
	local found = SoundService:FindFirstChild(name)
	if found and found:IsA("SoundGroup") then
		return found
	end
	local made = Instance.new("SoundGroup")
	made.Name = name
	made.Volume = 1
	made.Parent = SoundService
	return made
end

Sound.sfx = group("SFX")
Sound.music = group("Music")

local function idOf(key: string): number?
	local id = (Config.Sounds :: any)[key]
	return if type(id) == "number" and id > 0 then id else nil
end

-- Loads every sound and song once when the game starts, so the first click / meow is not late or silent.
-- The silent copies stay in SoundService.Preload to keep the audio cached.
function Sound.preload()
	local ContentProvider = game:GetService("ContentProvider")
	local folder = Instance.new("Folder")
	folder.Name = "Preload"
	folder.Parent = SoundService
	local seen: { [number]: boolean } = {}
	local list: { Instance } = {}
	for _, ids in { Config.Sounds :: any, Config.Music :: any } do
		for _, id in ids do
			if type(id) == "number" and id > 0 and not seen[id] then
				seen[id] = true
				local s = Instance.new("Sound")
				s.SoundId = `rbxassetid://{id}`
				s.Volume = 0
				s.Parent = folder
				table.insert(list, s)
			end
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(list)
	end)
end

function Sound.volumeOf(key: string): number
	return (Config.SoundVolumes :: any)[key] or Config.SoundVolumes.default
end

local function make(key: string, opts: Options?): Sound?
	local id = idOf(key)
	if not id then
		return nil
	end
	local o: Options = opts or {}
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = `rbxassetid://{id}`
	sound.Volume = Sound.volumeOf(key) * (o.volume or 1)
	sound.PlaybackSpeed = o.pitch or 1
	sound.SoundGroup = Sound.sfx
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 20
	sound.RollOffMaxDistance = o.range or Config.SoundRange
	return sound
end

function Sound.play(key: string, opts: Options?): Sound?
	local sound = make(key, opts)
	if not sound then
		return nil
	end
	local o: Options = opts or {}
	if o.at then
		local holder = Instance.new("Part")
		holder.Name = "SoundAt"
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanTouch = false
		holder.CanQuery = false
		holder.Transparency = 1
		holder.Size = Vector3.one
		holder.Position = o.at
		holder.Parent = workspace
		sound.Parent = holder
		Debris:AddItem(holder, 12)
	else
		sound.Parent = o.parent or SoundService
		Debris:AddItem(sound, 12)
	end
	sound.Ended:Once(function()
		local holder = sound.Parent
		sound:Destroy()
		if holder and holder.Name == "SoundAt" then
			holder:Destroy()
		end
	end)
	sound:Play()
	return sound
end

function Sound.loop(key: string, opts: Options?): Sound?
	local sound = make(key, opts)
	if not sound then
		return nil
	end
	local o: Options = opts or {}
	sound.Looped = true
	sound.Parent = o.parent or SoundService
	sound:Play()
	return sound
end

return Sound
