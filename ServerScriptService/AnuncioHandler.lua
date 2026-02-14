-- ANUNCIO HANDLER - ServerScriptService

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Seed random for unique id generation
math.randomseed(os.time())

local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))

local function getUniqueId()
	return tostring(os.time()) .. tostring(math.random(1000, 9999))
end

-- Obtener el RemoteEvent desde la carpeta canonical: ReplicatedStorage/Systems/Events
local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local crearAnuncio = eventsFolder:WaitForChild("CrearAnuncio")

Players.PlayerAdded:Connect(function(plr)
	if AdminConfig:IsAdmin(plr) then
		plr.Chatted:Connect(function(msg)
			if string.sub(msg, 1, 8) == "/global " then
				local actualMessage = string.sub(msg, 9)
				local duration = 10
				local displayName = plr.DisplayName or plr.Name

				local uid = getUniqueId()
				pcall(function()
					MessagingService:PublishAsync(
						"GlobalAnnouncement",
						displayName .. "sTrInGsEpErAtOr" .. plr.Name .. "sTrInGsEpErAtOr" .. actualMessage .. "sTrInGsEpErAtOr" .. duration .. "sTrInGsEpErAtOr" .. uid
					)
				end)
			end

			local durationMatch = string.match(msg, "^/global:(%d+) ")
			if durationMatch then
				local duration = math.clamp(tonumber(durationMatch), 1, 30)
				local actualMessage = string.sub(msg, #("/global:" .. durationMatch .. " ") + 1)
				local displayName = plr.DisplayName or plr.Name

				local uid = getUniqueId()
				pcall(function()
					MessagingService:PublishAsync(
						"GlobalAnnouncement",
						displayName .. "sTrInGsEpErAtOr" .. plr.Name .. "sTrInGsEpErAtOr" .. actualMessage .. "sTrInGsEpErAtOr" .. duration .. "sTrInGsEpErAtOr" .. uid
					)
				end)
			end
		end)
	end
end)

pcall(function()
	MessagingService:SubscribeAsync("GlobalAnnouncement", function(msg)
		local splitMessage = string.split(msg.Data, "sTrInGsEpErAtOr")
		local displayName = splitMessage[1]
		local userName = splitMessage[2]
		local message = splitMessage[3]
		local duration = tonumber(splitMessage[4]) or 10
		local uid = splitMessage[5] -- unique id (optional)

		-- Fire clients including uid to avoid identical payloads being coalesced
		crearAnuncio:FireAllClients(displayName, userName, message, duration, uid)
	end)
end)