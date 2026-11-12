--!strict
-- Leaderboards (task 2.14; SKY PUTT / Tamer Academy): money per second and cats owned, across all servers
-- (OrderedDataStores in Config.Leaderboards). Every WriteEvery seconds each online player's scores are
-- written (and when they leave), every ReadEvery the top Show are read back. Two boards stand just outside
-- the lobby ring (built here at start); each client draws them in its language from the board's attribute
-- "Rows" (JSON: { { name, value } }).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataTemplate = require(ReplicatedStorage.Shared.DataTemplate)
local DataService = require(script.Parent.DataService)
local PenService = require(script.Parent.PenService)

local LeaderboardService = {}

local L = Config.Leaderboards
local stores: { [string]: OrderedDataStore } = {}
local boards: { [string]: BasePart } = {}
local names: { [number]: string } = {}

local BOARDS = {
	{ key = "Income", angle = 22.5 },
	{ key = "Cats", angle = 202.5 },
}

local function buildBoards()
	local old = workspace:FindFirstChild("Leaderboards")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = workspace
	for _, b in BOARDS do
		local a = math.rad(b.angle)
		local r = Config.World.LobbyRadius + 14
		local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local cf = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
		local m = Instance.new("Model")
		m.Name = b.key
		local function part(size: Vector3, c: CFrame, color: Color3): Part
			local p = Instance.new("Part")
			p.Size = size
			p.CFrame = c
			p.Color = color
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored = true
			p.CanTouch = false
			p.Parent = m
			return p
		end
		for _, x in { -9, 9 } do
			part(Vector3.new(1.4, 20, 1.4), cf * CFrame.new(x, 10, 0), Color3.fromHex("a8693a"))
		end
		part(Vector3.new(20, 17, 1.2), cf * CFrame.new(0, 13.5, 0), Color3.fromHex("2f3552"))
		local board = part(Vector3.new(19, 16, 0.4), cf * CFrame.new(0, 13.5, -0.75), Color3.fromHex("ffffff"))
		board.Name = "Board"
		board:SetAttribute("Board", b.key)
		board:SetAttribute("Rows", "[]")
		boards[b.key] = board
		m.Parent = folder
	end
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok and n then n else `#{userId}`
	return names[userId]
end

local function scores(player: Player): { [string]: number }?
	local d = DataService.GetData(player)
	if not d then
		return nil
	end
	-- R4: income can reach Sx, past what an OrderedDataStore holds: store it on a log scale
	local income = math.max(0, PenService.incomeRate(player))
	return { Income = math.floor(math.log10(1 + income) * Config.Leaderboards.LogScale), Cats = DataTemplate.catCount(d) }
end

local function write(player: Player)
	local s = scores(player)
	if not s then
		return
	end
	for key, store in stores do
		pcall(function()
			store:SetAsync(tostring(player.UserId), s[key])
		end)
	end
end

local function read()
	for key, store in stores do
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, L.Show)
		end)
		if ok and pages then
			local rows = {}
			for _, entry in pages:GetCurrentPage() do
				local id = tonumber(entry.key)
				local value = if key == "Income" then 10 ^ (entry.value / Config.Leaderboards.LogScale) - 1 else entry.value
				table.insert(rows, { name = if id then nameOf(id) else entry.key, value = value })
			end
			if boards[key] then
				boards[key]:SetAttribute("Rows", HttpService:JSONEncode(rows))
			end
		end
	end
end

function LeaderboardService:Start()
	buildBoards()
	for key, name in L.Stores do
		local ok, store = pcall(function()
			-- a new set of boards for every player reset (Config.Data.ResetEpoch): they start empty
			return DataStoreService:GetOrderedDataStore(`{name}_r{Config.Data.ResetEpoch}`)
		end)
		if ok then
			stores[key] = store
		end
	end
	Players.PlayerRemoving:Connect(write)
	task.spawn(function()
		task.wait(10)
		while true do
			for _, p in Players:GetPlayers() do
				write(p)
			end
			read()
			task.wait(L.WriteEvery)
		end
	end)
end

return LeaderboardService
