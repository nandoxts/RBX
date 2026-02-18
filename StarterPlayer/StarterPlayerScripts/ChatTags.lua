-- ========================================
-- LOCALSCRIPT (Cliente - ULTRA OPTIMIZADO)
-- ========================================
local textChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal")

local player = game.Players.LocalPlayer

-- Cache local (sin expiración, se actualiza por eventos)
local clientTagCache = {}

-- Eventos del servidor
local tagDataEvent = ReplicatedStorage.Chat:WaitForChild("PlayerTagData")

-- Recibir datos de tags del servidor
tagDataEvent.OnClientEvent:Connect(function(userId, tagInfo)
	clientTagCache[userId] = tagInfo
	local targetPlayer = Players:GetPlayerByUserId(userId)
	local playerName = targetPlayer and targetPlayer.Name or "Desconocido"
	print("Tag recibido para", playerName, "(" .. userId .. "):", tagInfo.Source)
end)

-- Handler del chat (CERO consultas API)
textChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local userId = message.TextSource.UserId
		local tagInfo = clientTagCache[userId]

		if tagInfo then
			-- Aplicar prefix
			properties.PrefixText = tagInfo.Prefix .. message.PrefixText

			-- Aplicar color al texto solo si tiene tag especial
			if tagInfo.HasSpecialTag and tagInfo.TextColor then
				properties.Text = string.format("<font color='%s'>%s</font>", tagInfo.TextColor, message.Text)
				-- Solo aplica color si TextColor existe
			end
		else
			-- Fallback temporal (no debería pasar frecuentemente)
			properties.PrefixText = "<font color='#CCCCCC'>[⏳]</font> <font color='#CCCCCC'>[ Cargando... ]</font> " .. message.PrefixText
			warn("Tag no encontrado para UserID:", userId)
		end
	end

	return properties
end

-- Limpiar cache local cuando alguien se va
Players.PlayerRemoving:Connect(function(player)
	clientTagCache[player.UserId] = nil
end)

