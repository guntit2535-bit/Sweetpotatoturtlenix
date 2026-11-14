--!strict
-- X3 (revision 4 item 3, look 3A small): a small pin over your own pen so you can find the way home from anywhere: a
-- pink circle with a white house and the distance under it, always on top (seen through walls). Hidden near home.
-- When home is off screen, the same small pin sits along the top middle of the screen, slid toward home's side
-- (not during the tutorial, which has its own edge arrow). The world pin is parented to its anchor part. The pen's position is kept once seen: far away the pen may stream out.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Kit = require(script.Parent.Parent.UI.Kit)

local HomeMarkerController = {}

local me = Players.LocalPlayer
local PINK = Color3.fromHex("ff5fa2")

-- A little pin: a circle with a house drawn from frames (no image needed) and a distance label under it.
local function pin(parent: Instance, size: number): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "HomePin"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromOffset(size + 30, size + 22)
	f.Parent = parent
	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0)
	circle.Position = UDim2.fromScale(0.5, 0)
	circle.Size = UDim2.fromOffset(size, size)
	circle.BackgroundColor3 = PINK
	circle.Parent = f
	Kit.corner(circle, size)
	local ring = Instance.new("UIStroke")
	ring.Thickness = 2.5
	ring.Color = Color3.new(1, 1, 1)
	ring.Parent = circle
	local roof = Instance.new("Frame")
	roof.AnchorPoint = Vector2.new(0.5, 0.5)
	roof.Position = UDim2.fromScale(0.5, 0.42)
	roof.Size = UDim2.fromScale(0.42, 0.42)
	roof.Rotation = 45
	roof.BackgroundColor3 = Color3.new(1, 1, 1)
	roof.BorderSizePixel = 0
	roof.Parent = circle
	local body = Instance.new("Frame")
	body.AnchorPoint = Vector2.new(0.5, 0)
	body.Position = UDim2.fromScale(0.5, 0.44)
	body.Size = UDim2.fromScale(0.46, 0.32)
	body.BackgroundColor3 = Color3.new(1, 1, 1)
	body.BorderSizePixel = 0
	body.Parent = circle
	local door = Instance.new("Frame")
	door.AnchorPoint = Vector2.new(0.5, 1)
	door.Position = UDim2.fromScale(0.5, 1)
	door.Size = UDim2.fromScale(0.3, 0.6)
	door.BackgroundColor3 = PINK
	door.BorderSizePixel = 0
	door.Parent = body
	local dist = Kit.text(f, "Dist", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, size + 2), 16, true)
	return f, dist
end

function HomeMarkerController.Start(_self: any)
	local M = Config.HomeMarker
	local home: Vector3? = nil
	local anchor = Instance.new("Part")
	anchor.Name = "HomeMarker"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	local board = Instance.new("BillboardGui")
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.Size = UDim2.fromOffset(M.Size + 30, M.Size + 22)
	board.Adornee = anchor
	board.Parent = anchor
	local _, worldDist = pin(board, M.Size)
	-- the screen-edge copy
	local gui = Kit.screen("HomeEdge", 3)
	gui.ClipToDeviceSafeArea = false
	local edge, edgeDist = pin(gui, M.Size)
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
	edge.Visible = false

	local function findHome()
		local map = workspace:FindFirstChild("Map")
		local pens = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
		if not pens then
			return
		end
		for _, p in pens:GetChildren() do
			if p:GetAttribute("OwnerId") == me.UserId then
				local floor = p:FindFirstChild("Floor")
				if floor and floor:IsA("BasePart") then
					home = floor.Position
					anchor.Position = floor.Position + Vector3.new(0, M.Height, 0)
					anchor.Parent = workspace
				end
			end
		end
	end

	local nextLook = 0
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if not home and now >= nextLook then
			nextLook = now + 1
			findHome()
		end
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local h = home
		if not h or not root or not root:IsA("BasePart") then
			board.Enabled = false
			edge.Visible = false
			return
		end
		local d = (Vector3.new(h.X, 0, h.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
		local show = d > M.HideWithin and not Kit.anyWindowOpen()
		local text = `{math.floor(d)} m`
		worldDist.Text = text
		edgeDist.Text = text
		board.Enabled = show
		-- off screen: the small pin at the edge, toward home
		local cam = workspace.CurrentCamera
		local sp, on = cam:WorldToViewportPoint(anchor.Position)
		local size = cam.ViewportSize
		local inView = on and sp.X > 30 and sp.X < size.X - 30 and sp.Y > 30 and sp.Y < size.Y - 30
		if show and not inView and me:GetAttribute("Tutorial") == nil then
			local c = Vector2.new(size.X / 2, size.Y / 2)
			local v = Vector2.new(sp.X, sp.Y) - c
			if sp.Z < 0 then
				v = -v
			end
			if v.Magnitude < 1 then
				v = Vector2.new(0, -1)
			end
			-- along the top middle of the screen, slid toward home's side (the side columns, the Rebirth button and
			-- the corners stay clear; seen in Studio: an ellipse put it on top of Rebirth)
			local u = v.Unit
			local x = c.X + math.clamp(u.X, -1, 1) * size.X * 0.28
			edge.Position = UDim2.fromOffset(x, size.Y * 0.1 + M.Size / 2)
			edge.Visible = true
		else
			edge.Visible = false
		end
	end)
end

return HomeMarkerController
