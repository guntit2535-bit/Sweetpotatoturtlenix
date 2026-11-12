--!strict
-- W4 (revision 3 item 4, look A picked 2026-11-13, mockup https://claude.ai/artifact/CdjjgLzmYcnuWuG6c6S4e4): the
-- shop as a rail of tall cards, swiped left / right (touch scrolls the rail; it settles on the nearest card),
-- with arrow buttons on both sides. Every tab (rods, shoes, treats, crates, Robux) uses the same card:
--   name banner (the item's colour) / picture / a few lines / one button
--   local rail = ShopCard.rail(parent, height)      -- once
--   ShopCard.make(rail, order, { title = .., color = .., lines = { { "Luck +8%" } }, picture = fn, button = .. })
--   ShopCard.jumpTo(rail, index)                     -- show that card first (the next thing to buy)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)

local ShopCard = {}

local C = Kit.Colors
ShopCard.Width = 140
ShopCard.Gap = 10
ShopCard.Pad = 34 -- room for the arrows at both ends
ShopCard.Banner = 26
ShopCard.ButtonH = 38
ShopCard.LineH = 15

export type Line = { string | Color3 } -- { text, colour? }
export type Options = {
	title: string,
	color: Color3,
	lines: { Line },
	picture: ((box: Frame) -> boolean)?, -- fills the picture box; false = keep the colour chip
	button: { text: string, color: Color3, onClick: (() -> ())? },
	highlight: boolean?, -- the item in use: a purple frame
}

local function step(): number
	return ShopCard.Width + ShopCard.Gap
end

-- The horizontal rail under the tabs (from `top` px down), with its two arrows.
function ShopCard.rail(parent: GuiObject, top: number): ScrollingFrame
	local lane = Instance.new("Frame")
	lane.Name = "Lane"
	lane.BackgroundTransparency = 1
	lane.Position = UDim2.fromOffset(0, top)
	lane.Size = UDim2.new(1, 0, 1, -top)
	lane.Parent = parent
	local rail = Instance.new("ScrollingFrame")
	rail.Name = "List"
	rail.BackgroundTransparency = 1
	rail.BorderSizePixel = 0
	rail.Size = UDim2.fromScale(1, 1)
	rail.ScrollingDirection = Enum.ScrollingDirection.X
	rail.AutomaticCanvasSize = Enum.AutomaticSize.X
	rail.CanvasSize = UDim2.new()
	rail.ScrollBarThickness = 0
	rail.ElasticBehavior = Enum.ElasticBehavior.Always
	rail.Parent = lane
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, ShopCard.Gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = rail
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, ShopCard.Pad)
	pad.PaddingRight = UDim.new(0, ShopCard.Pad)
	pad.Parent = rail

	local tween: Tween? = nil
	local function goTo(x: number)
		local max = math.max(0, rail.AbsoluteCanvasSize.X - rail.AbsoluteWindowSize.X)
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(rail, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CanvasPosition = Vector2.new(math.clamp(x, 0, max), 0),
		})
		;(tween :: Tween):Play()
	end
	rail:SetAttribute("Step", step())

	-- arrows: three cards at a time
	for _, dir in { -1, 1 } do
		local b = Kit.button(lane, if dir < 0 then "Back" else "Next", C.yellow, UDim2.fromOffset(30, 46), UDim2.new(if dir < 0 then 0 else 1, if dir < 0 then -4 else -26, 0.5, -25))
		Kit.setButtonText(b, if dir < 0 then "<" else ">")
		;(b.Parent :: GuiObject).ZIndex = 5
		b.Activated:Connect(function()
			local s = step()
			goTo((math.floor(rail.CanvasPosition.X / s + 0.5) + dir * 3) * s)
		end)
	end

	-- after a swipe, settle on the nearest card once the rail has been still for a moment (no finger on it)
	local lastX, still = -1, 0
	local touching = 0
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touching += 1
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touching = math.max(0, touching - 1)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		if not rail.Visible or not rail:FindFirstAncestorWhichIsA("LayerCollector") then
			return
		end
		local x = rail.CanvasPosition.X
		if math.abs(x - lastX) > 0.5 then
			lastX, still = x, 0
			return
		end
		still += dt
		if still > 0.15 and touching == 0 and not (tween and tween.PlaybackState == Enum.PlaybackState.Playing) then
			local s = step()
			local target = math.floor(x / s + 0.5) * s
			if math.abs(target - x) > 1 then
				goTo(target)
			end
			still = -math.huge -- once per stop
		end
	end)
	return rail
end

function ShopCard.jumpTo(rail: ScrollingFrame, index: number)
	task.defer(function()
		local s = step()
		local max = math.max(0, rail.AbsoluteCanvasSize.X - rail.AbsoluteWindowSize.X)
		rail.CanvasPosition = Vector2.new(math.clamp((index - 1) * s, 0, max), 0)
	end)
end

function ShopCard.clear(rail: ScrollingFrame)
	for _, c in rail:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

function ShopCard.make(rail: ScrollingFrame, order: number, o: Options): Frame
	local card = Instance.new("Frame")
	card.Name = `Item{order}`
	card.LayoutOrder = order
	card.Size = UDim2.new(0, ShopCard.Width, 1, -10)
	card.BackgroundColor3 = C.soft
	card.ClipsDescendants = false
	card.Parent = rail
	Kit.corner(card, 16)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = if o.highlight then 5 else 3
	stroke.Color = if o.highlight then C.purple else C.ink
	stroke.Parent = card

	-- the name banner in the item's colour
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.new(1, 0, 0, ShopCard.Banner)
	banner.BackgroundColor3 = o.color
	banner.Parent = card
	Kit.corner(banner, 14)
	local fill = Instance.new("Frame") -- squares off the banner's lower corners
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = o.color
	fill.Position = UDim2.new(0, 0, 1, -10)
	fill.Size = UDim2.new(1, 0, 0, 10)
	fill.Parent = banner
	local line = Instance.new("Frame")
	line.BorderSizePixel = 0
	line.BackgroundColor3 = C.ink
	line.Position = UDim2.new(0, 0, 1, 0)
	line.Size = UDim2.new(1, 0, 0, 3)
	line.Parent = banner
	local name = Kit.text(banner, "Name", UDim2.new(1, -8, 1, -2), UDim2.fromOffset(4, 1), 15, true)
	name.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 15
	limit.Parent = name
	name.Text = o.title
	name.ZIndex = 2

	-- the lines and the button sit at the bottom; the picture takes the rest
	-- a single line (a description) gets two rows and wraps; several lines (stats, odds) get one row each
	local single = #o.lines == 1
	local linesH = (if single then 2 else #o.lines) * ShopCard.LineH + 4
	local bottom = ShopCard.ButtonH + 12
	local pic = Instance.new("Frame")
	pic.Name = "Picture"
	pic.Position = UDim2.fromOffset(6, ShopCard.Banner + 6)
	pic.Size = UDim2.new(1, -12, 1, -(ShopCard.Banner + 6 + linesH + bottom + 4))
	pic.BackgroundColor3 = Color3.new(1, 1, 1)
	pic.Parent = card
	Kit.corner(pic, 12)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromHex("ffffff"), Color3.fromHex("dff1ff"))
	g.Rotation = 90
	g.Parent = pic
	local placed = o.picture and o.picture(pic)
	if not placed then
		local sq = Instance.new("Frame")
		sq.Name = "Color"
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Position = UDim2.fromScale(0.5, 0.5)
		sq.Size = UDim2.fromOffset(46, 46)
		sq.BackgroundColor3 = o.color
		sq.Parent = pic
		Kit.corner(sq, 10)
		Kit.stroke(sq, 3, nil, true)
	end

	local box = Instance.new("Frame")
	box.Name = "Lines"
	box.BackgroundTransparency = 1
	box.Position = UDim2.new(0, 8, 1, -(linesH + bottom))
	box.Size = UDim2.new(1, -16, 0, linesH)
	box.Parent = card
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = box
	for i, l in o.lines do
		local t = Kit.text(box, `Line{i}`, UDim2.new(1, 0, 0, ShopCard.LineH * (if single then 2 else 1)), UDim2.new(), 13)
		t.LayoutOrder = i
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextWrapped = single
		t.TextScaled = true
		local lim = Instance.new("UITextSizeConstraint")
		lim.MaxTextSize = 13
		lim.Parent = t
		t.Text = l[1] :: string
		t.TextColor3 = if typeof(l[2]) == "Color3" then l[2] :: Color3 else C.ink
	end

	local b = Kit.button(card, "Action", o.button.color, UDim2.new(1, -16, 0, ShopCard.ButtonH), UDim2.new(0, 8, 1, -(ShopCard.ButtonH + 10)))
	Kit.setButtonText(b, o.button.text)
	local label = b:FindFirstChild("Label")
	local lim = label and label:FindFirstChildOfClass("UITextSizeConstraint")
	if lim then
		lim.MaxTextSize = 17
	end
	if o.button.onClick then
		b.Activated:Connect(o.button.onClick)
	end
	return card
end

return ShopCard
