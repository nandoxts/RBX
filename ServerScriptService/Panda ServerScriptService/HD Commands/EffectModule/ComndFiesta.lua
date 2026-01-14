local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectModule = require(game.ServerScriptService:WaitForChild("EffectModule"))

local fiestaEvent = ReplicatedStorage:FindFirstChild("FiestaEvent")
if not fiestaEvent then
	fiestaEvent = Instance.new("RemoteEvent")
	fiestaEvent.Name = "FiestaEvent"
	fiestaEvent.Parent = ReplicatedStorage
end

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