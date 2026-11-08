--!strict
-- A6 preview: one cat per tier plus shape / pattern variants, lined up on the lobby road at 270 degrees
-- (Workspace.CatPreview). Edit-time only, for the developer's review and screenshots; delete the
-- folder (or run CatPreview.clear()) when the real wild cats exist.
--   require(game.ServerScriptService.Server.MapTools:Clone().CatPreview).build()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatModel = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatModel"):Clone()) :: any

local Preview = {}

-- The tier line-up: Basic .. Secret (sizes: Basic-Legendary 1x, Mythical 1.3-2x, Secret 3-6x).
Preview.Tiers = {
	{ tier = "Basic", size = 1, look = { shape = "Loaf", fur = "f2a65a", second = "fff1dc", pattern = "tabby", patternColor = "d9823a" } },
	{ tier = "Rare", size = 1, look = { shape = "Slim", fur = "9aa3b5", second = "ffffff", pattern = "socks", accessory = "collar", accessoryColor = "3e8ef2" } },
	{ tier = "Epic", size = 1, look = { shape = "Fluffy", fur = "ffffff", second = "fff4e8", pattern = "patches", patternColor = "f29b4a", patternColor2 = "3a3340", accessory = "bow", accessoryColor = "ff6fae", aura = "sparkle" } },
	{ tier = "Legendary", size = 1, look = { shape = "Loaf", fur = "f6c945", second = "fff3c4", pattern = "tabby", patternColor = "e09a1f", accessory = "crown", aura = "gold", eyes = "2b6fd6" } },
	{ tier = "Mythical", size = 1.6, look = { shape = "Fluffy", fur = "c9b6ff", second = "fff0ff", pattern = "spots", patternColor = "ff8fd1", accessory = "wings", accessoryColor = "ffffff", aura = "glow", eyes = "8a3cff" } },
	{ tier = "Secret", size = 4, look = { shape = "Slim", fur = "2d2b45", second = "8fe8ff", pattern = "spots", patternColor = "ffe066", accessory = "halo", aura = "rainbow", eyes = "4fe3ff" } },
}

-- Variants of the same 3 shapes (how 400 designs come from shapes x colours x patterns x accessories).
Preview.Variants = {
	{ shape = "Loaf", fur = "3a3340", second = "ffffff", pattern = "tuxedo" },
	{ shape = "Slim", fur = "f7f3ea", second = "ffffff", pattern = "patches", patternColor = "f29b4a", patternColor2 = "3a3340", accessory = "flowers", accessoryColor = "ff8fca" },
	{ shape = "Fluffy", fur = "a8aebd", second = "ffffff", pattern = "tabby", patternColor = "6f7585", accessory = "scarf", accessoryColor = "ef4b42" },
	{ shape = "Loaf", fur = "8b5a3c", second = "f3d9bf", pattern = "solid", accessory = "hat", accessoryColor = "ef4b42" },
	{ shape = "Slim", fur = "ffd6e8", second = "ffffff", pattern = "spots", patternColor = "ff8fca", accessory = "bow", accessoryColor = "9a6bff" },
	{ shape = "Fluffy", fur = "f2a65a", second = "fff1dc", pattern = "socks", accessory = "collar", accessoryColor = "2fc7c0" },
}

function Preview.clear()
	local old = workspace:FindFirstChild("CatPreview")
	if old then
		old:Destroy()
	end
end

function Preview.build()
	Preview.clear()
	local f = Instance.new("Folder")
	f.Name = "CatPreview"
	f.Parent = workspace
	-- facing the fountain (+Z), on the road leaving the plaza toward 270 degrees (-Z)
	local face = CFrame.Angles(0, math.pi, 0)
	local spots = {
		CFrame.new(-21, 0.6, -40),
		CFrame.new(-7, 0.6, -40),
		CFrame.new(7, 0.6, -40),
		CFrame.new(21, 0.6, -40),
		CFrame.new(-11, 0.3, -66),
		CFrame.new(10, 0.3, -98),
	}
	-- each cat shows one clip in Play (CatAnimController): idle, walk, struggle, carried, sleep
	-- "showcase" = every clip in turn, looping (developer 2026-11-08: for the client video)
	local tierAnims = table.create(6, "showcase")
	local variantAnims = table.create(6, "showcase")
	for i, t in Preview.Tiers do
		local cat = CatModel.build(t.look, spots[i] * face, t.size)
		cat.Name = t.tier
		cat:SetAttribute("Anim", tierAnims[i])
		cat.Parent = f
	end
	for i, look in Preview.Variants do
		local cat = CatModel.build(look, CFrame.new(-27.5 + i * 7.8, 0.6, -28) * face, 0.85)
		cat.Name = `Variant{i}`
		cat:SetAttribute("Anim", variantAnims[i])
		cat.Parent = f
	end
	print(`[Sweetpotato] cat preview: {#f:GetChildren()} cats`)
end

return Preview
