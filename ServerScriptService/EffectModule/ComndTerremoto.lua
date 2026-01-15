local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectModule = require(game.ServerScriptService:WaitForChild("EffectModule"))

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local terremotoEvent = eventsFolder:FindFirstChild("TerremotoEvent")

local function onPlayerChatted(player, message)
	if message:lower() == "/quake" then
		if EffectModule:IsAuthorized(player) then
			terremotoEvent:FireAllClients()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChatted(player, msg)
	end)
end)