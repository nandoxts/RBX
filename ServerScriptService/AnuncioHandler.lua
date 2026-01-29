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

				local uid = getUniqueId()
				pcall(function()
					MessagingService:PublishAsync(
						"GlobalAnnouncement",
						plr.Name .. "sTrInGsEpErAtOr" .. actualMessage .. "sTrInGsEpErAtOr" .. duration .. "sTrInGsEpErAtOr" .. uid
					)
				end)
			end

			local durationMatch = string.match(msg, "^/global:(%d+) ")
			if durationMatch then
				local duration = math.clamp(tonumber(durationMatch), 1, 30)
				local actualMessage = string.sub(msg, #("/global:" .. durationMatch .. " ") + 1)

				local uid = getUniqueId()
				pcall(function()
					MessagingService:PublishAsync(
						"GlobalAnnouncement",
						plr.Name .. "sTrInGsEpErAtOr" .. actualMessage .. "sTrInGsEpErAtOr" .. duration .. "sTrInGsEpErAtOr" .. uid
					)
				end)
			end
		end)
	end
end)

pcall(function()
	MessagingService:SubscribeAsync("GlobalAnnouncement", function(msg)
		local splitMessage = string.split(msg.Data, "sTrInGsEpErAtOr")
		local plrName = splitMessage[1]
		local message = splitMessage[2]
		local duration = tonumber(splitMessage[3]) or 10
		local uid = splitMessage[4] -- unique id (optional)

		-- Fire clients including uid to avoid identical payloads being coalesced
		crearAnuncio:FireAllClients(plrName, message, duration, uid)
	end)
end)