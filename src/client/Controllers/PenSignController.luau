--!strict
-- Pen signs (task 1.9): each pen's Board shows the owner's name ("YOUR PEN" on your own) and the like
-- count, drawn on this client in its own language from the pen's attributes OwnerId / OwnerName / Likes
-- (PenService). The Like prompt's text follows the language too. Boards can stream in and out, so the
-- pens are looked at again every few seconds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local PenSignController = {}

local me = Players.LocalPlayer

local function pens(): { Model }
	local out = {}
	local map = workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("Lobby") and map.Lobby:FindFirstChild("Pens")
	if folder then
		for i = 1, Config.World.Pens.Count do
			local m = folder:FindFirstChild(`Pen{i}`)
			if m and m:IsA("Model") then
				table.insert(out, m)
			end
		end
	end
	return out
end

local function draw(pen: Model)
	local board = pen:FindFirstChild("Sign") and (pen :: any).Sign:FindFirstChild("Board")
	if not board or not board:IsA("BasePart") then
		return
	end
	local gui = board:FindFirstChild("SignGui") :: SurfaceGui?
	if not gui then
		local g = Instance.new("SurfaceGui")
		g.Name = "SignGui"
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 40
		g.LightInfluence = 0.3
		g.Parent = board
		local owner = Kit.text(g, "Owner", UDim2.new(1, -20, 0.6, 0), UDim2.fromOffset(10, 4), 60, true)
		owner.TextScaled = true
		local likes = Kit.text(g, "Likes", UDim2.new(1, -20, 0.36, 0), UDim2.new(0, 10, 0.62, 0), 40, true)
		likes.TextScaled = true
		likes.TextColor3 = Kit.Colors.yellow
		gui = g
		pen:GetAttributeChangedSignal("OwnerName"):Connect(function()
			draw(pen)
		end)
		pen:GetAttributeChangedSignal("Likes"):Connect(function()
			draw(pen)
		end)
	end
	local g = gui :: SurfaceGui
	local ownerId = pen:GetAttribute("OwnerId")
	local name = pen:GetAttribute("OwnerName")
	local ownerLabel = g:FindFirstChild("Owner") :: TextLabel
	local likesLabel = g:FindFirstChild("Likes") :: TextLabel
	if ownerId == me.UserId then
		ownerLabel.Text = Lang.text("PenYours")
	elseif type(name) == "string" and name ~= "" then
		ownerLabel.Text = Lang.text("PenOwner", { name = name })
	else
		ownerLabel.Text = Lang.text("PenFree")
	end
	local likes = pen:GetAttribute("Likes")
	likesLabel.Visible = type(name) == "string" and name ~= ""
	likesLabel.Text = Lang.text("PenLikes", { count = if type(likes) == "number" then likes else 0 })
	local prompt = board:FindFirstChild("LikePrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = Lang.text("LikePrompt")
		prompt.ObjectText = ownerLabel.Text
		prompt.Enabled = ownerId ~= me.UserId and type(name) == "string" and name ~= ""
	end
end

local function drawAll()
	for _, pen in pens() do
		draw(pen)
	end
end

function PenSignController.Start(_self: any)
	Lang.changed:Connect(drawAll)
	task.spawn(function()
		while true do
			drawAll()
			task.wait(3)
		end
	end)
end

return PenSignController
