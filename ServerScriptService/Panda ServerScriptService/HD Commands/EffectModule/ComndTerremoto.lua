local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectModule = require(game.ServerScriptService:WaitForChild("EffectModule"))

local terremotoEvent = ReplicatedStorage:FindFirstChild("TerremotoEvent")
if not terremotoEvent then
	terremotoEvent = Instance.new("RemoteEvent")
	terremotoEvent.Name = "TerremotoEvent"
	terremotoEvent.Parent = ReplicatedStorage
end

local function onPlayerChatted(player, message)
	if message:lower() == "/quake" then
		if EffectModule:IsAuthorized(player) then
			terremotoEvent:FireAllClients()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChatted(player, msg)
	end)
end)