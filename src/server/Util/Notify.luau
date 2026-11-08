--!strict
-- Toasts for one player or everyone (the client shows them in its own language: ToastController).
--   Notify.send(player, "SoldCat", { name = "Mochi", money = "120" }, "good")
--   Notify.all("EventMythical", nil, "event")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Notify = {}

export type Kind = "info" | "good" | "bad" | "event"

function Notify.send(player: Player, key: string, vars: { [string]: any }?, kind: Kind?)
	Remotes.event("Notify"):FireClient(player, key, vars, kind or "info")
end

function Notify.all(key: string, vars: { [string]: any }?, kind: Kind?)
	Remotes.event("Notify"):FireAllClients(key, vars, kind or "info")
end

return Notify
