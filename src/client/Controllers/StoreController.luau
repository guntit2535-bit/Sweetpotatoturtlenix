--!strict
-- The Robux store (task 2.20): the Shop window's Robux tab lists the 5 game passes and the products, with the
-- price Roblox gives this player (regional) and the icon set in the Creator Dashboard (shown on the card). Buying opens Roblox's
-- own purchase prompt; the server grants (PassService / ProductService). Items whose id is still 0 say
-- "Not on sale yet". Also the x2 Speed button: owners switch it on / off, others get the pass prompt.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Lang = require(script.Parent.Parent.Lang)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Kit = require(script.Parent.Parent.UI.Kit)
local ShopController = require(script.Parent.ShopController)
local ToastController = require(script.Parent.ToastController)

local StoreController = {}

local C = Kit.Colors
local me = Players.LocalPlayer
local prices: { [string]: string } = {} -- "pass:id" / "product:id" -> "R$ 99"
local icons: { [string]: number } = {} -- the same keys -> the icon set in Creator Hub (0 = none yet)
local PASSES = { { "Speed", "Speed2x" }, { "Cash", "Cash2x" }, { "Strength", "Strength2x" }, { "Lucky", "Lucky" }, { "VIP", "VIP" } }

local function price(kind: string, id: number): string
	local key = `{kind}:{id}`
	if prices[key] then
		return prices[key]
	end
	prices[key] = "..."
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		prices[key] = if ok and info and info.PriceInRobux then `R$ {info.PriceInRobux}` else "R$ ?"
		icons[key] = if ok and info and type(info.IconImageAssetId) == "number" then info.IconImageAssetId else 0
		ShopController.redraw()
	end)
	return prices[key]
end

type Button = { text: string, color: Color3, onClick: (() -> ())? }

-- W4: a card on the shop's rail; the item's Creator Hub picture fills the picture box once it has loaded (the
-- coloured chip stays until then: a new icon can stay unloaded for a while during Roblox's review)
local function card(list: ScrollingFrame, order: number, title: string, line: string, color: Color3, iconKey: string, button: Button)
	ShopController.card(list, order, {
		title = title,
		color = color,
		lines = { { line } },
		picture = function(box: Frame): boolean
			local icon = icons[iconKey]
			if not icon or icon == 0 then
				return false
			end
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.AnchorPoint = Vector2.new(0.5, 0.5)
			img.Position = UDim2.fromScale(0.5, 0.5)
			img.Size = UDim2.fromScale(0.95, 0.95)
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = `rbxassetid://{icon}`
			img.Parent = box
			return true
		end,
		button = button,
	})
end

local function drawRobux(list: ScrollingFrame)
	local order = 0
	for _, p in PASSES do
		order += 1
		local name, key = p[1], p[2]
		local id = (Config.Passes :: any)[key].Id
		if id ~= 0 then
			price("pass", id) -- also loads the icon of an owned pass
		end
		local button: Button = if me:GetAttribute(`Pass{name}`) == true
			then { text = Lang.text("Owned2"), color = C.purple }
			elseif id == 0 then { text = Lang.text("NotOnSaleYet"), color = C.grey }
			else { text = price("pass", id), color = C.green, onClick = function()
				MarketplaceService:PromptGamePassPurchase(me, id)
			end }
		card(list, order, Lang.text("Pass" .. name), Lang.text("Pass" .. name .. "Desc"), C.sky, `pass:{id}`, button)
	end
	local data = PlayerData.get() or {}
	local income = me:GetAttribute("Income")
	local inc = if type(income) == "number" then income else 0
	local slotsShown = false
	for _, p in Config.Products.List do
		local title, line = Lang.text("Product" .. p.Key), ""
		local show = true
		if p.Kind == "Slots" then
			-- only the next price step
			local step = (data.SlotBuys or 0) + 1
			show = not slotsShown and p.Key == `Slots{math.min(step, 3)}` and (data.PenSlots or 10) < Config.Pen.MaxSlots
			if show then
				slotsShown = true
			end
			title = Lang.text("ProductSlots")
			line = Lang.text("PenEffect", { now = data.PenSlots or 10, next = math.min(Config.Pen.MaxSlots, (data.PenSlots or 10) + Config.Products.SlotsStep) })
		elseif p.Kind == "Cash" then
			line = Lang.text("ProductCashDesc", { money = Format.short(Rewards.money({ Base = p.Base, Seconds = p.Seconds }, inc)) })
		elseif p.Kind == "Strength" then
			line = Lang.text("ProductStrengthDesc", { kg = Format.short(p.Base) })
		elseif p.Kind == "ServerLuck" then
			line = Lang.text("ProductServerLuckDesc")
		elseif p.Kind == "Summon" then
			line = Lang.text("ProductSummonDesc")
		elseif p.Kind == "Starter" then
			line = Lang.text("ProductStarterDesc")
			show = not data.StarterBought
		elseif p.Kind == "Luck3" then
			line = Lang.text("ProductLuck3Desc")
		elseif p.Kind == "TrainBoost" then
			-- W6: only the next step of each (the one the board at the weights / treadmill sells)
			local have = (if p.Stat == "Weights" then data.BoostWeights else data.BoostTread) or 0
			local short = if p.Stat == "Weights" then "W" else "T"
			local mult = Config.TrainBoost.Mult ^ p.Step
			show = p.Step == have + 1
			title = Lang.text("TrainBoostTitle" .. short, { mult = mult })
			line = Lang.text("TrainBoostDesc" .. short, { mult = mult })
		end
		if show then
			order += 1
			if p.Id ~= 0 then
				price("product", p.Id)
			end
			local button: Button = if p.Id == 0
				then { text = Lang.text("NotOnSaleYet"), color = C.grey }
				else { text = price("product", p.Id), color = C.green, onClick = function()
					MarketplaceService:PromptProductPurchase(me, p.Id)
				end }
			card(list, order, title, line, C.yellow, `product:{p.Id}`, button)
		end
	end
end

-- The x2 Speed button on the left.
function StoreController.speedButton()
	if me:GetAttribute("PassSpeed") == true then
		Remotes.event("ToggleSpeed"):FireServer()
	elseif Config.Passes.Speed2x.Id ~= 0 then
		MarketplaceService:PromptGamePassPurchase(me, Config.Passes.Speed2x.Id)
	else
		ShopController.openTab("Robux")
		ToastController.show("NotOnSaleYet", nil, "info")
	end
end

function StoreController.Start(_self: any)
	ShopController.setRobuxBuilder(drawRobux)
	for _, p in PASSES do
		me:GetAttributeChangedSignal(`Pass{p[1]}`):Connect(ShopController.redraw)
	end
end

return StoreController
