-- ToneMessageClient.lua
-- LocalScript para mostrar mensajes del sistema de tono

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- Obtener el RemoteEvent
local toneMessageEvent = ReplicatedStorage:WaitForChild("ToneMessage")

-- Obtener el canal de sistema
local systemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

-- Conectar al evento
toneMessageEvent.OnClientEvent:Connect(function(message)
	systemChannel:DisplaySystemMessage(message)
end)