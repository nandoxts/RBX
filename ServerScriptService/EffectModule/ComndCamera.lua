local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectModule = require(game.ServerScriptService:WaitForChild("EffectModule"))

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local rotateEvent = eventsFolder:FindFirstChild("RotateEffectEvent")

-- Función para manejar comandos del chat
local function onPlayerChatted(player, message)
	if message:lower() == "/pulse" then
		if EffectModule:IsAuthorized(player) then
			rotateEvent:FireAllClients()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChatted(player, msg)
	end)
end)
