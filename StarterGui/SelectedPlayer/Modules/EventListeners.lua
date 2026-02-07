--[[
	═══════════════════════════════════════════════════════════
	EVENT LISTENERS - Listeners broadcast globales
	═══════════════════════════════════════════════════════════
	Maneja todos los eventos broadcast (regalos, likes, donaciones)
]]

local EventListeners = {}
local Remotes, TextChatService

function EventListeners.init(remotes)
	Remotes = remotes
	TextChatService = remotes.Services.TextChatService
	
	-- Setup todos los listeners
	EventListeners.setupDonationListeners()
	EventListeners.setupLikeBroadcast()
	EventListeners.setupGiftBroadcast()
end

-- ═══════════════════════════════════════════════════════════════
-- DONACIONES
-- ═══════════════════════════════════════════════════════════════

function EventListeners.setupDonationListeners()
	local player = Remotes.Services.Player
	local NotificationSystem = Remotes.Systems.NotificationSystem
	
	if Remotes.Remotes.DonationNotify then
		Remotes.Remotes.DonationNotify.OnClientEvent:Connect(function(donatorId, amount, recipientId)
			-- Notificación PERSONAL solo si yo soy el receptor
			if recipientId == player.UserId and NotificationSystem then
				NotificationSystem:Success("Donación", "Recibiste una donación de " .. amount, 4)
			end
		end)
	end
	
	if Remotes.Remotes.DonationMessage then
		Remotes.Remotes.DonationMessage.OnClientEvent:Connect(function(donatorName, amount, recipientName)
			-- Notificación PERSONAL: solo si yo soy el donador
			if donatorName == player.Name and NotificationSystem then
				NotificationSystem:Success("Donación", "Donaste " .. amount .. " a " .. recipientName, 4)
			end
			
			-- Mensaje en chat global PARA TODOS
			local displayName = recipientName
			if recipientName == "ignxts" then
				displayName = "Ritmo Latino"
			end
			
			pcall(function()
				local TextChannels = TextChatService:WaitForChild("TextChannels")
				local RBXSystem = TextChannels:WaitForChild("RBXSystem")
				RBXSystem:DisplaySystemMessage(
					'<font color="#8762FF"><b>' .. donatorName .. " donó " .. tostring(amount) .. " a " .. displayName .. "</b></font>"
				)
			end)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- LIKES BROADCAST
-- ═══════════════════════════════════════════════════════════════

function EventListeners.setupLikeBroadcast()
	local BroadcastEvent = Remotes.Likes.BroadcastEvent
	local player = Remotes.Services.Player
	local NotificationSystem = Remotes.Systems.NotificationSystem
	
	if not BroadcastEvent then return end
	
	BroadcastEvent.OnClientEvent:Connect(function(action, data)
		if action ~= "LikeNotification" or not data then return end
		
		
		-- Notificación PERSONAL al receptor
		if data.Target and data.Target == player.Name then
			local notifMessage = ""
			local notifTitle = "Like"
			
			if data.IsSuperLike then
				notifTitle = "Super Like"
				notifMessage = "¡" .. data.Sender .. " te dio un Super Like (+" .. tostring(data.Amount or 0) .. ")!"
			else
				notifMessage = "¡" .. data.Sender .. " te dio un Like!"
			end
			
			if NotificationSystem then
				pcall(function()
					if data.IsSuperLike then
						NotificationSystem:Success(notifTitle, notifMessage, 3)
					else
						NotificationSystem:Info(notifTitle, notifMessage, 3)
					end
				end)
			end
		end
		
		-- Mensaje en chat global PARA TODOS
		local chatMessage = ""
		if data.IsSuperLike then
			chatMessage = '<font color="#F7004D"><b>' .. data.Sender .. ' dio un Super Like (+' .. tostring(data.Amount or 0) .. ') a ' .. data.Target .. '</b></font>'
		else
			chatMessage = '<font color="#FFFF7F"><b>' .. data.Sender .. ' dio un Like a ' .. data.Target .. '</b></font>'
		end
		
		pcall(function()
			local TextChannels = TextChatService:WaitForChild("TextChannels")
			local RBXSystem = TextChannels:WaitForChild("RBXSystem")
			RBXSystem:DisplaySystemMessage(chatMessage)
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- REGALOS BROADCAST
-- ═══════════════════════════════════════════════════════════════

function EventListeners.setupGiftBroadcast()
	local GiftBroadcastEvent = Remotes.Gifting.GiftBroadcastEvent
	if GiftBroadcastEvent then
		GiftBroadcastEvent.OnClientEvent:Connect(function(action, data)
			if action == "GiftNotification" then
				local message = '<font color="#00D9FF"><b>' .. data.Donor .. ' regaló el gamepass "' .. data.GamepassName .. '" a ' .. data.Recipient .. '</b></font>'
				
				pcall(function()
					local TextChannels = TextChatService:WaitForChild("TextChannels")
					local RBXSystem = TextChannels:WaitForChild("RBXSystem")
					RBXSystem:DisplaySystemMessage(message)
				end)
			end
		end)
	end
end

return EventListeners
