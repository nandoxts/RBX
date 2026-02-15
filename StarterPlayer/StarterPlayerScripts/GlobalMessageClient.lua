-- GlobalMessageClient.lua - Universal message handler for all system messages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
local commandsFolder = remotesGlobal:WaitForChild("Commands", 10)

-- Colores para diferentes tipos de mensajes
local MESSAGE_COLORS = {
	tone = { hex = "#FFC800", rgb = Color3.fromRGB(255, 200, 0) },      -- Amarillo/Dorado
	event = { hex = "#00D4FF", rgb = Color3.fromRGB(0, 212, 255) },      -- Azul/Cian
	noche = { hex = "#9D4EDD", rgb = Color3.fromRGB(157, 78, 221) }      -- Morado/Púrpura
}

local function displayMessage(message, colorInfo)
	-- Intentar con TextChatService (nuevo chat)
	local textChannels = TextChatService:WaitForChild("TextChannels", 5)
	if textChannels then
		local systemChannel = textChannels:FindFirstChild("RBXSystem")
		if systemChannel then
			local coloredMessage = '<font color="' .. colorInfo.hex .. '"><b>' .. message .. '</b></font>'
			systemChannel:DisplaySystemMessage(coloredMessage)
			return
		end
	end

	-- Fallback: chat legacy
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = colorInfo.rgb,
			Font = Enum.Font.GothamBold,
		})
	end)
end

-- Handler para ToneMessage
local toneMessageEvent = commandsFolder:WaitForChild("ToneMessage", 10)
if toneMessageEvent then
	toneMessageEvent.OnClientEvent:Connect(function(message)
		displayMessage(message, MESSAGE_COLORS.tone)
	end)
else
	warn("[CLIENT] ToneMessage NO encontrado!")
end

-- Handler para EventMessage
local eventMessageEvent = commandsFolder:WaitForChild("EventMessage", 10)
if eventMessageEvent then
	eventMessageEvent.OnClientEvent:Connect(function(message)
		displayMessage(message, MESSAGE_COLORS.event)
	end)
else
	warn("[CLIENT] EventMessage NO encontrado!")
end

-- Handler para NocheMessage
local nocheMessageEvent = commandsFolder:WaitForChild("NocheMessage", 10)
if nocheMessageEvent then
	nocheMessageEvent.OnClientEvent:Connect(function(message)
		displayMessage(message, MESSAGE_COLORS.noche)
	end)
else
	warn("[CLIENT] NocheMessage NO encontrado!")
end