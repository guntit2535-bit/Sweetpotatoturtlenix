--!strict
-- Draws the two lobby leaderboards (task 2.14) in this client's language from each board's "Rows"
-- attribute (LeaderboardService): title, then rank, name and value (money per second, or cats).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local LeaderboardController = {}

local function draw(board: BasePart)
	local key = board:GetAttribute("Board")
	local gui = board:FindFirstChild("BoardGui") :: SurfaceGui?
	if not gui then
		local g = Instance.new("SurfaceGui")
		g.Name = "BoardGui"
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 30
		g.LightInfluence = 0.2
		g.Parent = board
		local title = Kit.text(g, "Title", UDim2.new(1, -20, 0, 60), UDim2.fromOffset(10, 6), 44)
		title.TextScaled = true
		title.TextColor3 = Kit.Colors.coral
		local list = Instance.new("Frame")
		list.Name = "List"
		list.BackgroundTransparency = 1
		list.Position = UDim2.fromOffset(20, 76)
		list.Size = UDim2.new(1, -40, 1, -86)
		list.Parent = g
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
		gui = g
		board:GetAttributeChangedSignal("Rows"):Connect(function()
			draw(board)
		end)
	end
	local g = gui :: SurfaceGui
	;(g:FindFirstChild("Title") :: TextLabel).Text = Lang.text(if key == "Income" then "LeaderIncome" else "LeaderCats")
	local list = g:FindFirstChild("List") :: Frame
	for _, c in list:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local ok, rows = pcall(function()
		return HttpService:JSONDecode(board:GetAttribute("Rows") or "[]")
	end)
	if not ok or type(rows) ~= "table" then
		return
	end
	for i, r in rows do
		local line = Kit.text(list, `Row{i}`, UDim2.new(1, 0, 0, 36), UDim2.new(), 28)
		line.LayoutOrder = i
		line.TextXAlignment = Enum.TextXAlignment.Left
		local value = if key == "Income" then "$" .. Format.money(r.value) .. "/s" else tostring(r.value)
		line.Text = `{i}. {r.name}  —  {value}`
		line.TextColor3 = if i == 1 then Color3.fromHex("c98a00") else Kit.Colors.ink
	end
end

local function drawAll()
	local folder = workspace:FindFirstChild("Leaderboards")
	if not folder then
		return
	end
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Board") then
			draw(d)
		end
	end
end

function LeaderboardController.Start(_self: any)
	Lang.changed:Connect(drawAll)
	task.spawn(function()
		while true do
			drawAll()
			task.wait(10)
		end
	end)
end

return LeaderboardController
