-- Tonemessageclient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
local commandsFolder = remotesGlobal:WaitForChild("Commands", 10)
local toneMessageEvent = commandsFolder:WaitForChild("ToneMessage", 10)

if not toneMessageEvent then
	warn("[CLIENT] ToneMessage NO encontrado!")
	return
end

toneMessageEvent.OnClientEvent:Connect(function(message)
	-- Intentar con TextChatService (nuevo chat)
	local textChannels = TextChatService:WaitForChild("TextChannels", 5)
	if textChannels then
		local systemChannel = textChannels:FindFirstChild("RBXSystem")
		if systemChannel then
			-- Rich Text para color amarillo/dorado
			local coloredMessage = '<font color="#FFC800"><b>' .. message .. '</b></font>'
			systemChannel:DisplaySystemMessage(coloredMessage)
			return
		end
	end

	-- Fallback: chat legacy
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = Color3.fromRGB(255, 200, 0),
			Font = Enum.Font.GothamBold,
		})
	end)
end)