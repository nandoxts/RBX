local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal"):WaitForChild("SelectedPlayer")

local Events = ReplicatedStorage.Events
local update_status = Events.update_status

function filterStatus(player: Player, unfilteredText: string)
	if typeof(unfilteredText) == "string" then
		-- Limitar a 30 caracteres y establecer directamente como atributo
		local sanitizedText = string.sub(unfilteredText, 1, 50)
		player:SetAttribute("status", sanitizedText)
	end
end

update_status.OnServerEvent:Connect(filterStatus)

--[[ CON CENSURA 
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal"):WaitForChild("SelectedPlayer")

local Events = ReplicatedStorage.Events
local update_status = Events.update_status

function filterStatus(player: Player, unfilteredText: string)
	if typeof(unfilteredText) == "string" then
		local sanitizedText = string.sub(unfilteredText, 1, 30)

		local success, result
		local retriesLeft = 3

		repeat
			success, result = pcall(TextService.FilterStringAsync, TextService, sanitizedText, player.UserId)

			if not success then
				if retriesLeft == 0 then
					return
				end

				retriesLeft -= 1
			end
		until success

		player:SetAttribute("status", result:GetNonChatStringForBroadcastAsync())
	end
end

update_status.OnServerEvent:Connect(filterStatus)
]]