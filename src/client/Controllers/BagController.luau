--!strict
-- The cat bag on this client (developer 2026-11-15; BagService on the server). While you hold a cat from your bag
-- (a Tool with a CatId), a ring follows the pointer on your own pen's floor: green where the cat can go, red outside.
-- Tap / click (the tool's Activated) asks the server to put it there (PlaceCat); the server checks it again.
-- Each of your own placed cats gets a "Pick up" prompt (made here, only you see it) that puts it back into the bag
-- (PickUpCat).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local ToastController = require(script.Parent.ToastController)

local BagController = {}

local me = Players.LocalPlayer
local mouse = me:GetMouse()
local B = Config.Bag
local GREEN, RED = Color3.fromHex("4fd38a"), Color3.fromHex("ff5e7e")

local placeRemote: RemoteEvent
local pickRemote: RemoteEvent
local ring: Part
local held: Tool? = nil
local prompts: { [Model]: ProximityPrompt } = {}

local function myPen(): Model?
	local map = workspace:FindFirstChild("Map")
	local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if not pens then
		return nil
	end
	for _, p in pens:GetChildren() do
		if p:IsA("Model") and p:GetAttribute("OwnerId") == me.UserId then
			return p
		end
	end
	return nil
end

local function myArea(): BasePart?
	local pen = myPen()
	local a = pen and pen:FindFirstChild("Area")
	return if a and a:IsA("BasePart") then a else nil
end

-- Where the pointer is on the ground, and whether a cat may go there.
local function aim(): (Vector3?, boolean)
	local area = myArea()
	if not area then
		return nil, false
	end
	local character = me.Character
	mouse.TargetFilter = character
	local hit = mouse.Hit.Position
	local rel = area.CFrame:PointToObjectSpace(hit)
	local s = area.Size
	if math.abs(rel.X) > s.X / 2 + 12 or math.abs(rel.Z) > s.Z / 2 + 12 then
		return nil, false -- pointing far from the pen: no ring
	end
	local inside = math.abs(rel.X) <= s.X / 2 - B.Margin and math.abs(rel.Z) <= s.Z / 2 - B.Margin
	local floor = (area.CFrame * CFrame.new(rel.X, -s.Y / 2, rel.Z)).Position
	return floor, inside
end

local function onActivated()
	local t = held
	if not t then
		return
	end
	local pos, ok = aim()
	if pos and ok then
		placeRemote:FireServer(t:GetAttribute("CatId"), pos.X, pos.Z)
	elseif pos then
		-- outside the floor: the server would say no; say it here at once (the same words)
		ToastController.show("PlaceOutside", nil, "bad")
	end
end

local function watchCharacter(character: Model)
	local conns: { RBXScriptConnection } = {}
	local function check()
		local now: Tool? = nil
		for _, t in character:GetChildren() do
			if t:IsA("Tool") and type(t:GetAttribute("CatId")) == "string" then
				now = t
			end
		end
		if now ~= held then
			for _, c in conns do
				c:Disconnect()
			end
			table.clear(conns)
			held = now
			if now then
				table.insert(conns, now.Activated:Connect(onActivated))
			end
		end
	end
	character.ChildAdded:Connect(check)
	character.ChildRemoved:Connect(check)
	check()
end

-- "Pick up" on each of my placed cats (the server's Workspace.PenCats.Pen<i>)
local function syncPrompts()
	local pen = myPen()
	local folder = workspace:FindFirstChild("PenCats")
	local mine = pen and folder and folder:FindFirstChild(pen.Name)
	for m, p in prompts do
		if not m.Parent or m.Parent ~= mine then
			p:Destroy()
			prompts[m] = nil
		end
	end
	if not mine then
		return
	end
	for _, m in mine:GetChildren() do
		if m:IsA("Model") and not prompts[m] and m.PrimaryPart and type(m:GetAttribute("CatId")) == "string" then
			local p = Instance.new("ProximityPrompt")
			p.Name = "PickUpPrompt"
			p.ActionText = Lang.text("PickUpCat")
			p.ObjectText = ""
			p.HoldDuration = 0.25
			p.MaxActivationDistance = B.PromptRange
			p.RequiresLineOfSight = false
			p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			p.Parent = m.PrimaryPart
			p.Triggered:Connect(function()
				pickRemote:FireServer(m:GetAttribute("CatId"))
			end)
			prompts[m] = p
		end
	end
end

function BagController.Start(_self: any)
	placeRemote = Remotes.event("PlaceCat")
	pickRemote = Remotes.event("PickUpCat")
	ring = Instance.new("Part")
	ring.Name = "PlaceRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.15, 4, 4)
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	me.CharacterAdded:Connect(watchCharacter)
	if me.Character then
		watchCharacter(me.Character)
	end
	Lang.changed:Connect(function()
		for _, p in prompts do
			p.ActionText = Lang.text("PickUpCat")
		end
	end)
	task.spawn(function()
		while true do
			-- the placing ring
			local pos, ok = nil, false
			if held then
				pos, ok = aim()
			end
			if pos then
				ring.Color = if ok then GREEN else RED
				ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
				ring.Parent = workspace
			elseif ring.Parent then
				ring.Parent = nil
			end
			task.wait(B.PreviewEvery)
		end
	end)
	task.spawn(function()
		while true do
			syncPrompts()
			task.wait(1)
		end
	end)
end

return BagController
