--!strict
-- Crates on this client (task 2.6): the Shop's Crates tab (each crate with every tier's chance in its colour,
-- shown before buying) and the reveal: a short shake, then the real cat model turning in a frame with its
-- name, tier, weight and mutation. The server already saved it (CrateResult comes after the save).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatModel = require(Shared:WaitForChild("CatModel"))
local CatRules = require(Shared:WaitForChild("CatRules"))
local Cats = require(Shared:WaitForChild("Cats"))
local Config = require(Shared:WaitForChild("Config"))
local Crates = require(Shared:WaitForChild("Crates"))
local Format = require(Shared:WaitForChild("Format"))
local Mutation = require(Shared:WaitForChild("Mutation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)
local ShopController = require(script.Parent.ShopController)

local CrateController = {}

local C = Kit.Colors
local buyRemote: RemoteEvent
local reveal: Frame
local spinning: Model? = nil

local function drawTab(list: ScrollingFrame)
	for i, crate in Config.Crates.List do
		local row = Instance.new("Frame")
		row.Name = crate.Key
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 104)
		row.BackgroundColor3 = C.soft
		row.Parent = list
		Kit.corner(row, 14)
		Kit.stroke(row, 3, nil, true)
		local box = Instance.new("Frame")
		box.Size = UDim2.fromOffset(64, 64)
		box.Position = UDim2.fromOffset(12, 20)
		box.BackgroundColor3 = Color3.fromHex(crate.Color)
		box.Parent = row
		Kit.corner(box, 10)
		Kit.stroke(box, 3, nil, true)
		local name = Kit.text(row, "Name", UDim2.new(1, -260, 0, 30), UDim2.fromOffset(88, 8), 24)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = Lang.text("Crate" .. crate.Key)
		-- the odds, one chip per tier
		local odds = Instance.new("Frame")
		odds.BackgroundTransparency = 1
		odds.Position = UDim2.fromOffset(88, 44)
		odds.Size = UDim2.new(1, -260, 0, 50)
		odds.Parent = row
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(118, 22)
		grid.CellPadding = UDim2.fromOffset(6, 4)
		grid.Parent = odds
		for _, o in Crates.odds(crate.Key) do
			local t = Config.Tiers[o.tier]
			local chip = Kit.text(odds, t.Key, UDim2.new(), UDim2.new(), 16, true)
			chip.Text = `{Lang.text("Tier" .. t.Key)} {o.percent}%`
			chip.TextColor3 = Color3.fromHex(t.Color)
			chip.TextXAlignment = Enum.TextXAlignment.Left
		end
		local b = Kit.button(row, "Buy", C.green, UDim2.fromOffset(150, 50), UDim2.new(1, -162, 0.5, -27))
		Kit.setButtonText(b, Lang.text("Buy", { cost = Format.short(crate.Cost) }))
		b.Activated:Connect(function()
			buyRemote:FireServer(crate.Key)
		end)
	end
end

local function showResult(key: string, kind: string, kg: number, mutation: string)
	local design = Cats.ById[kind]
	if not design then
		return
	end
	reveal.Visible = true
	local title = reveal:FindFirstChild("Title") :: TextLabel
	local body = reveal:FindFirstChild("Body") :: TextLabel
	local view = reveal:FindFirstChild("View") :: ViewportFrame
	title.Text = Lang.text("CrateOpening")
	body.Text = ""
	view.Visible = false
	-- shake the crate colour a moment
	local crate = Crates.get(key)
	reveal.BackgroundColor3 = if crate then Color3.fromHex(crate.Color) else C.white
	local t0 = os.clock()
	while os.clock() - t0 < Config.Crates.RevealSeconds do
		reveal.Rotation = math.sin((os.clock() - t0) * 40) * 4
		RunService.RenderStepped:Wait()
	end
	reveal.Rotation = 0
	reveal.BackgroundColor3 = C.white
	-- the cat
	for _, c in view:GetChildren() do
		if not c:IsA("Camera") then
			c:Destroy()
		end
	end
	local world = Instance.new("WorldModel")
	world.Parent = view
	local look = table.clone(design.Look) :: any
	look.mutation = if mutation ~= "" then mutation else nil
	local model = CatModel.build(look, CFrame.new(), 1.2)
	model.Parent = world
	spinning = model
	local cam = view:FindFirstChildOfClass("Camera") or Instance.new("Camera")
	cam.Parent = view
	view.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 4.5, -11), Vector3.new(0, 2.6, 0))
	view.Visible = true
	local t = Config.Tiers[design.Tier]
	title.Text = Lang.text("CrateGot", { name = design.Name })
	title.TextColor3 = Color3.fromHex(t.Color)
	local line = `{Lang.text("Tier" .. t.Key)} · {Lang.text("CatKg", { kg = Format.rate(kg) })} · {Lang.text("CatIncome", { money = Format.money(CatRules.income(design.Tier, kg) * Mutation.money(mutation)) })}`
	if mutation ~= "" then
		line = Lang.text("MutTag", { mutation = Lang.text("Mut" .. mutation), mult = Mutation.money(mutation) }) .. " · " .. line
	end
	body.Text = line
	local s = reveal:FindFirstChildOfClass("UIScale") :: UIScale
	s.Scale = 0.7
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(3.5, function()
		if spinning == model then
			reveal.Visible = false
			spinning = nil
		end
	end)
end

local function build()
	local gui = Kit.screen("CrateReveal", 16)
	reveal = Instance.new("Frame")
	reveal.Name = "Reveal"
	reveal.AnchorPoint = Vector2.new(0.5, 0.5)
	reveal.Position = UDim2.fromScale(0.5, 0.48)
	reveal.Size = UDim2.fromOffset(440, 400)
	reveal.BackgroundColor3 = C.white
	reveal.Visible = false
	reveal.Parent = gui
	Kit.corner(reveal, 24)
	Kit.stroke(reveal, 4, nil, true)
	local s = Instance.new("UIScale")
	s.Parent = reveal
	local title = Kit.text(reveal, "Title", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 10), 32, true)
	title.TextScaled = true
	local view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromOffset(70, 60)
	view.Size = UDim2.fromOffset(300, 260)
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightColor = Color3.new(1, 1, 1)
	view.Parent = reveal
	local body = Kit.text(reveal, "Body", UDim2.new(1, -24, 0, 56), UDim2.fromOffset(12, 330), 20)
	body.TextWrapped = true
	reveal.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			reveal.Visible = false
			spinning = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if spinning and spinning.Parent then
			spinning:PivotTo(spinning:GetPivot() * CFrame.Angles(0, dt * 1.2, 0))
		end
	end)
end

function CrateController.Start(_self: any)
	buyRemote = Remotes.event("BuyCrate")
	build()
	ShopController.setCratesBuilder(drawTab)
	Remotes.event("CrateResult").OnClientEvent:Connect(function(key: unknown, kind: unknown, kg: unknown, mutation: unknown)
		if type(key) == "string" and type(kind) == "string" and type(kg) == "number" then
			task.spawn(showResult, key, kind, kg, if type(mutation) == "string" then mutation else "")
		end
	end)
end

return CrateController
