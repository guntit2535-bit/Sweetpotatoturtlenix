--!strict
-- Zone gates (blueprint §1): a zone opens with enough Strength or rebirths (CatRules.zoneOpen). The
-- clients make the gate barriers solid for themselves (GateController); the server checks every
-- Config.Gates.CheckEvery that nobody stands in a zone they may not enter yet, and puts them back just
-- outside it with a message saying what is missing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local CatRules = require(Shared.CatRules)
local Format = require(Shared.Format)
local Text = require(Shared.Text)
local Notify = require(script.Parent.Parent.Util.Notify)
local DataService = require(script.Parent.DataService)

local ZoneGateService = {}

local lastNote: { [Player]: number } = {}

local function check()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local data = DataService.GetData(player)
		if root and root:IsA("BasePart") and data then
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			local r = flat.Magnitude
			for i, z in Config.World.Zones do
				if r >= z.Inner and r < z.Outer and not CatRules.zoneOpen(i, data.Strength, data.Rebirths) then
					local back = flat.Unit * (z.Inner - Config.Gates.PushBack)
					character:PivotTo(CFrame.lookAt(Vector3.new(back.X, root.Position.Y + 1, back.Z), Vector3.new(0, root.Position.Y + 1, 0)))
					if not lastNote[player] or os.clock() - lastNote[player] > 3 then
						lastNote[player] = os.clock()
						Notify.send(player, "ZoneLocked", {
							zone = Text.get("Zone" .. z.Key, "en"), -- zone names are English in both languages
							strength = Format.short(z.Strength),
							rebirths = z.Rebirths,
						}, "bad")
					end
					break
				end
			end
		end
	end
end

function ZoneGateService:Start()
	Players.PlayerRemoving:Connect(function(player)
		lastNote[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Gates.CheckEvery)
			check()
		end
	end)
end

return ZoneGateService
