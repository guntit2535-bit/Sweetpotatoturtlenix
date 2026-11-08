--!strict
-- Crates on this client (task 2.6): the Shop's Crates tab (each crate with every tier's chance in its colour,
-- shown before buying) and the opening (R8, below): the crate drops, shakes, the lid flies off and the real cat
-- jumps out, then a card with its name, tier, weight and mutation. The server already saved it (CrateResult
-- comes after the save).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
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
local ItemModels = require(Shared:WaitForChild("ItemModels"))
local Mutation = require(Shared:WaitForChild("Mutation"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)
local Sound = require(script.Parent.Parent.Sound)
local ItemPortrait = require(script.Parent.Parent.UI.ItemPortrait)
local ShopController = require(script.Parent.ShopController)

local CrateController = {}

local C = Kit.Colors
local buyRemote: RemoteEvent

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
		-- R5: the crate's mesh over its colour
		if ItemPortrait.make(box, "Crate_" .. crate.Key) then
			box.BackgroundColor3 = C.panel
		end
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
		local rb = Players.LocalPlayer:GetAttribute("Rebirths")
		Kit.setButtonText(b, Lang.text("Buy", { cost = Format.short(Crates.cost(crate.Key, if type(rb) == "number" then rb else 0)) }))
		b.Activated:Connect(function()
			buyRemote:FireServer(crate.Key)
		end)
	end
end

-- R8: the 5-second opening (mockup 12), on a full-screen layer. Timeline (Config.Crates.Open):
--   0 .. Drop      the crate (R5 mesh) drops in and bounces
--   Drop .. Shake  it wobbles faster and faster; a glow in the colour of the best tier this crate can give
--   Shake .. Pop   the lid flies off with a burst: confetti, rays (crate_reveal / crate_rare sound)
--   Pop .. Done    the cat jumps out in its tier's light; the card shows name, tier, kg, income (mutation)
-- A tap before the burst skips to it; a tap after the card closes. The result was saved by the server
-- before CrateResult came (the animation only shows it).
type Scene = {
	t0: number,
	key: string,
	design: any,
	kg: number,
	mutation: string,
	world: WorldModel,
	root: BasePart?,
	parts: { [BasePart]: CFrame }, -- body parts and their offsets from the crate's root
	lid: { [BasePart]: CFrame },
	cat: Model?,
	catHalf: number, -- the cat's root height above its feet at scale 1
	catScale: number, -- every cat is fitted to about the crate's size
	shake: Sound?,
	popped: boolean,
	carded: boolean,
	confetti: { { g: Frame, v: Vector2, spin: number, born: number } },
}

local overlay: Frame
local view: ViewportFrame
local rays: Frame
local glow: Frame
local card: Frame
local layer: Frame
local scene: Scene? = nil

local CONFETTI = { "ff7fb6", "ffd23f", "5ec4ff", "5bd65a", "b07cff", "ff5e7e", "ffffff" }
local CRATE_SCALE = 1.35
local CAT_SIZE = 3.1 -- studs: the cat's biggest side at full size
local CRATE_YAW = math.rad(-22)

local function bestTier(key: string): number
	local best = 1
	for _, o in Crates.odds(key) do
		best = math.max(best, o.tier)
	end
	return best
end

local function easeOutBounce(u: number): number
	local n, d = 7.5625, 2.75
	if u < 1 / d then
		return n * u * u
	elseif u < 2 / d then
		u -= 1.5 / d
		return n * u * u + 0.75
	elseif u < 2.5 / d then
		u -= 2.25 / d
		return n * u * u + 0.9375
	end
	u -= 2.625 / d
	return n * u * u + 0.984375
end

local function easeOutBack(u: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (u - 1) ^ 3 + c1 * (u - 1) ^ 2
end

local function tint(color: Color3)
	for _, r in rays:GetDescendants() do
		if r:IsA("Frame") and r.Name == "Ray" then
			r.BackgroundColor3 = color
		end
	end
	for _, g in glow:GetChildren() do
		if g:IsA("Frame") then
			g.BackgroundColor3 = color
		end
	end
end

-- The crate: its mesh (body + lid parts) when imported, else a plain box in the crate's colour.
local function buildCrate(s: Scene)
	local model = ItemModels.build("Crate_" .. s.key, CRATE_SCALE, true)
	if not model then
		local crate = Crates.get(s.key)
		local box = Instance.new("Part")
		box.Size = Vector3.new(2.4, 2.1, 2.4) * CRATE_SCALE
		box.Color = if crate then Color3.fromHex(crate.Color) else C.peach
		box.Anchored = true
		box.Parent = s.world
		s.parts[box] = CFrame.new(0, box.Size.Y / 2, 0)
		local lid = Instance.new("Part")
		lid.Size = Vector3.new(2.6, 0.5, 2.6) * CRATE_SCALE
		lid.Color = box.Color:Lerp(Color3.new(1, 1, 1), 0.25)
		lid.Anchored = true
		lid.Parent = s.world
		s.lid[lid] = CFrame.new(0, box.Size.Y + lid.Size.Y / 2, 0)
		return
	end
	local root = model.PrimaryPart :: BasePart
	for _, d in model:GetDescendants() do
		if d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p ~= root then
			p.Anchored = true
			local offset = root.CFrame:ToObjectSpace(p.CFrame)
			if p.Name == "Lid" or p.Name == "LidGlass" then
				s.lid[p] = offset
			else
				s.parts[p] = offset
			end
		end
	end
	root.Anchored = true
	model.Parent = s.world
	s.root = root
end

local function spawnConfetti(s: Scene)
	local centre = Vector2.new(layer.AbsoluteSize.X * 0.5, layer.AbsoluteSize.Y * 0.36)
	for i = 1, 40 do
		local g = Instance.new("Frame")
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22))
		g.BackgroundColor3 = Color3.fromHex(CONFETTI[(i % #CONFETTI) + 1])
		g.BorderSizePixel = 0
		g.Position = UDim2.fromOffset(centre.X, centre.Y)
		g.Rotation = math.random(0, 360)
		g.Parent = layer
		Kit.corner(g, 3)
		local a = math.rad(math.random(-75, 75))
		local speed = math.random(420, 820)
		table.insert(s.confetti, {
			g = g,
			v = Vector2.new(math.sin(a) * speed, -math.cos(a) * speed),
			spin = math.random(-400, 400),
			born = os.clock(),
		})
	end
end

local function showCard(s: Scene)
	local design = s.design
	local t = Config.Tiers[design.Tier]
	local tierColor = Color3.fromHex(t.Color)
	;(card:FindFirstChild("Name") :: TextLabel).Text = design.Name
	local ribbon = card:FindFirstChild("Ribbon") :: Frame
	ribbon.BackgroundColor3 = tierColor
	;(ribbon:FindFirstChild("Label") :: TextLabel).Text = string.upper(Lang.text("Tier" .. t.Key))
	;(card:FindFirstChild("Kg") :: Frame):FindFirstChild("Label").Text = Lang.text("CatKg", { kg = Format.money(s.kg) })
	local income = CatRules.income(design.Tier, s.kg) * Mutation.money(s.mutation)
	;(card:FindFirstChild("Income") :: Frame):FindFirstChild("Label").Text = "+" .. Lang.text("CatIncome", { money = Format.money(income) })
	local mut = card:FindFirstChild("Mutation") :: TextLabel
	mut.Visible = s.mutation ~= ""
	if s.mutation ~= "" then
		mut.Text = Lang.text("MutTag", { mutation = Lang.text("Mut" .. s.mutation), mult = Mutation.money(s.mutation) })
	end
	;(card:FindFirstChild("Tap") :: TextLabel).Text = Lang.text("CrateTap")
	card.Visible = true
	local sc = card:FindFirstChildOfClass("UIScale") :: UIScale
	local fit = math.clamp(overlay.AbsoluteSize.Y / 720, 0.55, 1)
	sc.Scale = fit * 0.6
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit }):Play()
end

local function close()
	local s = scene
	scene = nil
	if s then
		if s.shake and s.shake.Parent then
			s.shake:Stop()
		end
		for _, c in s.confetti do
			c.g:Destroy()
		end
		s.world:Destroy()
	end
	overlay.Visible = false
	card.Visible = false
end

local function step()
	local s = scene
	if not s then
		return
	end
	local O = Config.Crates.Open
	local now = os.clock()
	local t = now - s.t0
	-- the crate: drop + bounce, then the wobble
	local y, roll, hop = 0, 0, 0
	if t < O.Drop then
		y = (1 - easeOutBounce(t / O.Drop)) * 9
	elseif t < O.Shake then
		local u = (t - O.Drop) / (O.Shake - O.Drop)
		local freq = 9 + 26 * u
		roll = math.sin((t - O.Drop) * freq) * math.rad(3 + 11 * u)
		hop = math.abs(math.sin((t - O.Drop) * freq * 0.5)) * 0.25 * u
		if not s.shake then
			s.shake = Sound.play("crate_shake")
		end
	end
	local base = CFrame.new(0, y + hop, 0) * CFrame.Angles(0, CRATE_YAW, roll)
	local root = s.root
	if root then
		root.CFrame = base
	end
	for p, offset in s.parts do
		p.CFrame = base * offset
	end
	-- the lid: on the crate, then it flies up and away to the right
	local lu = math.clamp((t - O.Shake) / (O.Pop - O.Shake), 0, 1)
	local le = easeOutBack(lu)
	local fly = CFrame.new(-2.6 * le, 2.6 * le, 0.4 * le) * CFrame.Angles(0.5 * le, 0, 0.9 * le)
	for p, offset in s.lid do
		local pos = base * offset
		p.CFrame = if lu > 0 then CFrame.new(fly.Position) * pos * fly.Rotation else pos
	end
	-- glow while it shakes (best tier colour), rays after the burst (the cat's tier colour)
	local shakeU = math.clamp((t - O.Drop) / (O.Shake - O.Drop), 0, 1)
	local pulse = 0.5 + 0.5 * math.sin(t * (6 + 14 * shakeU))
	for i, g in glow:GetChildren() do
		if g:IsA("Frame") then
			g.BackgroundTransparency = 1 - (0.12 + 0.28 * shakeU) * (0.6 + 0.4 * pulse) / i
		end
	end
	glow.Size = UDim2.fromScale(0.34 + 0.12 * shakeU + 0.03 * pulse, 0.34 + 0.12 * shakeU + 0.03 * pulse)
	rays.Rotation = t * 18
	if t >= O.Shake and not s.popped then
		s.popped = true
		if s.shake and s.shake.Parent then
			s.shake:Stop()
		end
		Sound.play(if s.design.Tier >= 4 then "crate_rare" else "crate_reveal")
		tint(Color3.fromHex(Config.Tiers[s.design.Tier].Color))
		spawnConfetti(s)
		view.LightColor = Color3.new(1, 1, 1)
	end
	rays.Visible = s.popped
	if s.popped then
		local ru = math.clamp((t - O.Shake) / 0.5, 0, 1)
		for _, r in rays:GetDescendants() do
			if r:IsA("UIGradient") then
				r.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 1 - 0.55 * ru),
				})
			end
		end
	end
	-- the cat jumps out of the crate
	local cat = s.cat
	if cat and t >= O.Shake + 0.15 then
		local cu = math.clamp((t - O.Shake - 0.15) / 0.8, 0, 1)
		if not cat.Parent then
			cat.Parent = s.world
		end
		local k = s.catScale * math.max(0.05, 0.35 + 0.65 * easeOutBack(cu))
		cat:ScaleTo(k)
		-- feet from inside the crate up to just over its top (a hop at the top), then a gentle bob
		local top = 1.85 * CRATE_SCALE
		local feet = top - 1.2 + (1.5 + math.sin(math.min(cu, 1) * math.pi) * 0.7) * cu
		if cu >= 1 then
			feet = top + 0.3 + math.sin(t * 3) * 0.1
		end
		cat:PivotTo(CFrame.new(0, feet + s.catHalf * k, 0) * CFrame.Angles(0, math.sin(t * 1.4) * 0.3, 0))
	end
	if t >= O.Done - 1.2 and not s.carded then
		s.carded = true
		showCard(s)
	end
	-- confetti
	for i = #s.confetti, 1, -1 do
		local c = s.confetti[i]
		local age = now - c.born
		if age > 1.8 then
			c.g:Destroy()
			table.remove(s.confetti, i)
		else
			local v = c.v + Vector2.new(0, 1100 * age)
			local pos = c.g.Position
			c.g.Position = UDim2.fromOffset(pos.X.Offset + v.X / 60, pos.Y.Offset + v.Y / 60)
			c.g.Rotation += c.spin / 60
			c.g.BackgroundTransparency = math.clamp((age - 1.3) / 0.5, 0, 1)
		end
	end
	if t >= O.AutoClose then
		close()
	end
end

local function showResult(key: string, kind: string, kg: number, mutation: string)
	local design = Cats.ById[kind]
	if not design then
		return
	end
	close()
	local world = Instance.new("WorldModel")
	world.Parent = view
	local s: Scene = {
		t0 = os.clock(),
		key = key,
		design = design,
		kg = kg,
		mutation = mutation,
		world = world,
		root = nil,
		parts = {},
		lid = {},
		cat = nil,
		catHalf = 1,
		catScale = 1,
		shake = nil,
		popped = false,
		carded = false,
		confetti = {},
	}
	buildCrate(s)
	local look = table.clone(design.Look) :: any
	look.mutation = if mutation ~= "" then mutation else nil
	local cat = CatModel.build(look, CFrame.new(), 1)
	CollectionService:RemoveTag(cat, CatModel.Tag)
	for _, d in cat:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	s.catHalf = if cat.PrimaryPart then cat.PrimaryPart.Position.Y else 1
	local _, size = cat:GetBoundingBox()
	s.catScale = CAT_SIZE / math.max(size.X, size.Y, size.Z, 0.1)
	s.cat = cat
	tint(Color3.fromHex(Config.Tiers[bestTier(key)].Color))
	view.LightColor = Color3.fromRGB(255, 240, 220)
	card.Visible = false
	rays.Visible = false
	overlay.Visible = true
	scene = s
end

local function onTap()
	local s = scene
	if not s then
		return
	end
	local O = Config.Crates.Open
	local t = os.clock() - s.t0
	if t < O.Shake then
		s.t0 = os.clock() - O.Shake -- skip to the burst
	elseif s.carded and t > O.Done - 0.9 then
		close()
	end
end

local function build()
	local gui = Kit.screen("CrateReveal", 16)
	gui.IgnoreGuiInset = true
	overlay = Instance.new("Frame")
	overlay.Name = "Open"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromHex("1d1b35")
	overlay.BackgroundTransparency = 0.22
	overlay.Visible = false
	overlay.Parent = gui
	-- rays (behind everything): 14 bars turning around the crate
	rays = Instance.new("Frame")
	rays.Name = "Rays"
	rays.BackgroundTransparency = 1
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.34)
	rays.Size = UDim2.fromScale(1.6, 1.6)
	rays.Parent = overlay
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = rays
	for i = 1, 14 do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(1, 1)
		holder.Rotation = i * 360 / 14
		holder.Parent = rays
		local r = Instance.new("Frame")
		r.Name = "Ray"
		r.AnchorPoint = Vector2.new(0.5, 1)
		r.Position = UDim2.fromScale(0.5, 0.5)
		r.Size = UDim2.fromScale(0.09, 0.5)
		r.BorderSizePixel = 0
		r.Parent = holder
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Parent = r
	end
	-- glow: three soft circles behind the crate
	glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundTransparency = 1
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.38)
	glow.Size = UDim2.fromScale(0.36, 0.36)
	glow.Parent = overlay
	local ga = Instance.new("UIAspectRatioConstraint")
	ga.AspectRatio = 1
	ga.Parent = glow
	for i = 1, 3 do
		local c = Instance.new("Frame")
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.fromScale(0.5, 0.5)
		c.Size = UDim2.fromScale(0.45 + i * 0.2, 0.45 + i * 0.2)
		c.BorderSizePixel = 0
		c.Parent = glow
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0.5, 0)
		cc.Parent = c
	end
	-- the 3D scene
	view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.BackgroundTransparency = 1
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.33)
	view.Size = UDim2.fromScale(1, 0.66)
	view.Ambient = Color3.fromRGB(205, 200, 215)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-0.5, -1, 0.7)
	view.Parent = overlay
	local cam = Instance.new("Camera")
	cam.FieldOfView = 38
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 5.8, -15), Vector3.new(0, 3.9, 0))
	cam.Parent = view
	view.CurrentCamera = cam
	-- confetti layer over the scene
	layer = Instance.new("Frame")
	layer.Name = "Confetti"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.Parent = overlay
	-- the card (mockup 12): name, tier ribbon, kg and income pills, mutation, "Tap to continue"
	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -12)
	card.Size = UDim2.fromOffset(480, 200)
	card.BackgroundColor3 = C.panel
	card.Visible = false
	card.Parent = overlay
	Kit.corner(card, 26)
	Kit.stroke(card, 4, nil, true)
	local sc = Instance.new("UIScale")
	sc.Parent = card
	local name = Kit.text(card, "Name", UDim2.new(1, -24, 0, 46), UDim2.fromOffset(12, 10), 38, true)
	name.TextScaled = true
	name.TextColor3 = Color3.fromHex("8a4dd6")
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Position = UDim2.new(0.5, 0, 0, 60)
	ribbon.Size = UDim2.fromOffset(220, 38)
	ribbon.Parent = card
	Kit.corner(ribbon, 19)
	Kit.stroke(ribbon, 3, nil, true)
	local rl = Kit.text(ribbon, "Label", UDim2.fromScale(1, 1), UDim2.new(), 24, true)
	rl.TextScaled = true
	local function pill(nameKey: string, x: number, icon: string)
		local p = Instance.new("Frame")
		p.Name = nameKey
		p.Position = UDim2.new(x, 0, 0, 108)
		p.AnchorPoint = Vector2.new(0.5, 0)
		p.Size = UDim2.fromOffset(205, 44)
		p.BackgroundColor3 = C.soft
		p.Parent = card
		Kit.corner(p, 22)
		Kit.stroke(p, 3, nil, true)
		Kit.icon(p, icon, 34, UDim2.fromOffset(6, 5))
		local l = Kit.text(p, "Label", UDim2.new(1, -50, 1, -6), UDim2.fromOffset(44, 3), 22)
		l.TextScaled = true
		l.Font = Kit.Font
	end
	pill("Kg", 0.27, "Strength")
	pill("Income", 0.73, "Coin")
	local mut = Kit.text(card, "Mutation", UDim2.fromOffset(160, 26), UDim2.new(1, -172, 0, 66), 18, true)
	mut.TextColor3 = C.yellow
	mut.TextXAlignment = Enum.TextXAlignment.Right
	local tap = Kit.text(card, "Tap", UDim2.new(1, -24, 0, 30), UDim2.new(0, 12, 1, -38), 22)
	tap.TextScaled = true
	-- a tap anywhere: skip ahead, or close once the card is shown
	local catcher = Instance.new("TextButton")
	catcher.Name = "Tap"
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.ZIndex = 10
	catcher.Parent = overlay
	catcher.Activated:Connect(onTap)
	RunService.RenderStepped:Connect(step)
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
