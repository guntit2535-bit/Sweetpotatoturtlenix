--!strict
-- Toasts (task 1.8): short messages from the server (Notify remote: textKey, vars, kind) shown at the top
-- centre in this client's language, a few at a time, each fading after Config-free fixed seconds.
-- Other client code can show one too: ToastController.show("PenFull", { max = 10 }, "bad").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Lang = require(script.Parent.Parent.Lang)
local Kit = require(script.Parent.Parent.UI.Kit)

local ToastController = {}

local SHOW_SECONDS = 3.2
local MAX_SHOWN = 4
local COLORS: { [string]: Color3 } = {
	info = Kit.Colors.sky,
	good = Kit.Colors.green,
	bad = Kit.Colors.coral,
	event = Kit.Colors.purple,
}

local list: Frame

-- Vars may name other text lines: { nameKey = "RodName", nameVars = { materialKey = "MatWood", n = 1 } } becomes
-- { name = "Wood Rod 1" } in this client's language (item names stay translatable inside toasts).
local function resolve(vars: { [string]: any }?): { [string]: any }?
	if not vars then
		return nil
	end
	local out: { [string]: any } = {}
	for k, v in vars do
		if type(k) == "string" and string.sub(k, -3) == "Key" and type(v) == "string" then
			local base = string.sub(k, 1, -4)
			out[base] = Lang.text(v, resolve(vars[base .. "Vars"]))
		elseif out[k] == nil then
			out[k] = v
		end
	end
	return out
end

function ToastController.show(key: string, vars: { [string]: any }?, kind: string?)
	if not list then
		return
	end
	local shown = list:GetChildren()
	local frames = {}
	for _, c in shown do
		if c:IsA("Frame") then
			table.insert(frames, c)
		end
	end
	if #frames >= MAX_SHOWN then
		frames[1]:Destroy()
	end
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.new(1, 0, 0, 50)
	toast.BackgroundColor3 = COLORS[kind or "info"] or Kit.Colors.sky
	toast.LayoutOrder = math.floor(os.clock() * 100)
	toast.Parent = list
	Kit.corner(toast, 25) -- R9 (mockup 11): a round pill with a paw on the left
	Kit.stroke(toast, 3, nil, true)
	Kit.paw(toast, 30, UDim2.fromOffset(12, 10), Color3.new(1, 1, 1), 0.1)
	local label = Kit.text(toast, "Text", UDim2.new(1, -60, 1, -6), UDim2.fromOffset(50, 3), 22, true)
	label.Text = Lang.text(key, resolve(vars))
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 22
	limit.Parent = label
	task.delay(SHOW_SECONDS, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.45)
			toast:Destroy()
		end
	end)
end

function ToastController.Start(_self: any)
	local gui = Kit.screen("Toasts", 20)
	list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.AnchorPoint = Vector2.new(0.5, 0)
	list.Position = UDim2.new(0.5, 0, 0, 12)
	list.Size = UDim2.new(0, 520, 0, 220)
	list.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(520, 220)
	constraint.Parent = list
	list.Size = UDim2.new(0.9, 0, 0, 220)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = list
	Remotes.event("Notify").OnClientEvent:Connect(function(key: unknown, vars: unknown, kind: unknown)
		if type(key) == "string" then
			ToastController.show(key, if type(vars) == "table" then vars :: any else nil, if type(kind) == "string" then kind else nil)
		end
	end)
end

return ToastController
