--!strict
-- Cat preview (V5h): the cats of one tier in a grid on the lobby road at 270 degrees (Workspace.CatPreview), for
-- the developer's review and screenshots. Edit-time only; CatPreview.clear() removes it.
--   require(game.ServerScriptService.Server.MapTools:Clone().CatPreview).tier("Mythical")
--   ... .tier("Basic", true)    -- the colour variants of a tier instead of its designs
--   ... .ids({ "cat001", "cat051" }, "Gold")   -- some cats, optionally with a mutation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- a fresh copy of the shared modules, so an edit-time run always uses the latest code
local Shared = ReplicatedStorage:WaitForChild("Shared"):Clone()
local CatModel = require(Shared:WaitForChild("CatModel")) :: any
local Cats = require(Shared:WaitForChild("Cats")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any

local Preview = {}

local SIZE = { 1, 1, 1, 1, 1.3, 3 } -- the smallest size of each tier (Config.Tiers SizeMin)

function Preview.clear()
	local old = workspace:FindFirstChild("CatPreview")
	if old then
		old:Destroy()
	end
end

local function lineUp(list: { any }, mutation: string?)
	Preview.clear()
	local f = Instance.new("Folder")
	f.Name = "CatPreview"
	f.Parent = workspace
	local face = CFrame.Angles(0, math.pi, 0) -- facing the fountain (+Z)
	local cols = 10
	local biggest = 1
	for _, cat in list do
		biggest = math.max(biggest, SIZE[cat.Tier] or 1)
	end
	local gap = 8 * biggest -- one spacing for the whole grid, so big Secret cats do not overlap the others
	for i, cat in list do
		local size = SIZE[cat.Tier] or 1
		local col, row = (i - 1) % cols, (i - 1) // cols
		local look = table.clone(cat.Look)
		look.mutation = mutation
		local m = CatModel.build(look, CFrame.new((col - (cols - 1) / 2) * gap, 0.6, -36 - row * gap) * face, size)
		m.Name = `{cat.Id} {cat.Name}`
		m:SetAttribute("Anim", "idle")
		m.Parent = f
	end
	print(`[Sweetpotato] cat preview: {#list} cats`)
end

function Preview.tier(key: string, variants: boolean?)
	local list = {}
	for tier, t in Config.Tiers do
		if t.Key == key then
			for _, id in Cats.ByTier[tier] do
				local cat = Cats.ById[id]
				if (cat.Look.tint ~= nil) == (variants == true) then
					table.insert(list, cat)
				end
			end
		end
	end
	lineUp(list)
end

function Preview.ids(ids: { string }, mutation: string?)
	local list = {}
	for _, id in ids do
		table.insert(list, Cats.ById[id])
	end
	lineUp(list, mutation)
end

return Preview
