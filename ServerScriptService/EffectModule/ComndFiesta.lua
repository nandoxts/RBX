local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectModule = require(game.ServerScriptService:WaitForChild("EffectModule"))

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local fiestaEvent = eventsFolder:FindFirstChild("FiestaEvent")

-- Función para manejar mensajes del chat
local function onPlayerChatted(player, message)
	if message:lower() == "/fiesta" then
		if EffectModule:IsAuthorized(player) then
		     fiestaEvent:FireAllClients()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChatted(player, msg)
	end)
end)