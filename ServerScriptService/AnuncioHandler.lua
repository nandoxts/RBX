-- BY OWNER

local whitelist = {"xlm_brem", "AngeloGarciia", "bvwdhfv","ignxts"}
local messagingService = game:GetService("MessagingService")

game.Players.PlayerAdded:Connect(function(plr)
	if table.find(whitelist, plr.Name) then
		plr.Chatted:Connect(function(msg)
			if string.find(msg, "/global ") then
				local actualMessage = string.gsub(msg, "/global ", "")
				local duration = 10

				
				messagingService:PublishAsync("GlobalAnnouncement", plr.Name.."sTrInGsEpErAtOr"..actualMessage.."sTrInGsEpErAtOr"..duration)
			end
		end)
	end
end)

messagingService:SubscribeAsync("GlobalAnnouncement", function(msg)
	local splitMessage = string.split(msg.Data, "sTrInGsEpErAtOr")
	local plrName = splitMessage[1]
	local message = splitMessage[2]
	local duration = tonumber(splitMessage[3])


	game.ReplicatedStorage.CrearAnuncio:FireAllClients(plrName, message, duration)
end)
