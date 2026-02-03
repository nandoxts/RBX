local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DataStoreService = game:GetService("DataStoreService")
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local DataStoreQueueManager = require(game.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))

local GamepassGifting = ReplicatedStorage["Panda ReplicatedStorage"]["Gamepass Gifting"].Remotes.Gifting
local Ownership = ReplicatedStorage["Panda ReplicatedStorage"]["Gamepass Gifting"].Remotes.Ownership
local Config = require(game.ReplicatedStorage["Panda ReplicatedStorage"]["Gamepass Gifting"].Modules.Config)
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)

local BADGES_Gift = Configuration.BADGES_Gift

-- Al inicio del script de regalos:
local CentralPurchaseHandler = require(script.ManagerProcess)

-- Inicializar queue para DataStore con delay de 0.15s
local DataStoreQueue = DataStoreQueueManager.new(GiftedGamepassesData, "GiftedGamepasses", 0.15)

local PlayersGifted = {}
local Username = nil
local UserId = nil

--// ----------------------------------------------------------- //
local function getAllPurchaseables()
	local all = {}
	for _, gp in ipairs(Config.Gamepasses) do
		table.insert(all, gp)
	end
	for _, tool in ipairs(Config.Tools) do
		table.insert(all, tool)
	end
	return all
end
--// ----------------------------------------------------------- //

-- Función para obtener thumbnail del jugador
local function FetchPlayerThumbnail(userId)
	local s, Url = pcall(function()
		return HttpService:JSONDecode(HttpService:GetAsync("https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds="..userId.."&size=150x150&format=Png"))
	end)
	return s and Url.data[1].imageUrl or "https://t3.rbxcdn.com/9fc30fe577bf95e045c9a3d4abaca05d"
end

-- Función para enviar webhook a Discord
local function SendDiscordWebhook(recipientsplayername, recipientsuserid, donorsplayername, donorsuserid, gamepassid)
	local url = "https://discord.com/api/webhooks/1356410314589081630/nh5XchxHjo0_icTnYUSiDPGkHcN0HS_QgcEeJhJKo8PY93wVxkQ-yOaKzKDnnHI4Gt7f"
	local RecipientsThumbnail = FetchPlayerThumbnail(recipientsuserid)

	local data = {
		["embeds"] = {{
			["title"] = "**Gamepass Gifting System**",
			["type"] = "rich",
			["color"] = tonumber(0xFF0000),
			["thumbnail"] = {["url"] = RecipientsThumbnail},
			["fields"] = {
				{name = "Recipient's Name", value = recipientsplayername, inline = true},
				{name = "Recipient Profile", value = "https://www.roblox.com/users/"..recipientsuserid.."/profile", inline = true},
				{name = "Donor's Name", value = donorsplayername, inline = true},
				{name = "Donor's Profile Link", value = "https://www.roblox.com/users/"..donorsuserid.."/profile", inline = true},
				{name = "Gamepass", value = "https://www.roblox.com/game-pass/"..gamepassid, inline = true},
			}
		}}
	}

	HttpService:PostAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
end

-- Evento para iniciar el proceso de regalo
GamepassGifting.OnServerEvent:Connect(function(player, gamepass, userId, username, identifier)
	--// -- // -- // -- // -- // --
	-- Forzar a número y validar
	userId = tonumber(userId)
	identifier = tonumber(identifier)
	--[[
	if not userId or not identifier then
		warn("Datos inválidos recibidos en GamepassGifting")
		return
	end

	-- Verificar si existe el usuario por ID
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if not success or not name then return end
	]]
	--// -- // -- // -- // -- // --
	
	if not game.Players:GetNameFromUserIdAsync(userId) then return end

	Username = username
	UserId = identifier

	for _, purchaseablegamepass in pairs(getAllPurchaseables()) do
		if purchaseablegamepass[1] == gamepass[1] and purchaseablegamepass[2] == gamepass[2] then
			if player.UserId ~= userId then
				local owns = MarketplaceService:UserOwnsGamePassAsync(userId, gamepass[1])
				local hasGift = false
				
				if not owns then
					-- Usar queue para verificar DataStore (no bloqueante)
					DataStoreQueue:GetAsync(userId .. "-" .. gamepass[1], function(success, result)
						hasGift = success and result or false
					end)
					owns = hasGift
				end

				if not owns then
					PlayersGifted[player.UserId] = userId
					MarketplaceService:PromptProductPurchase(player, gamepass[2])
				else
					local Asset = MarketplaceService:GetProductInfo(gamepass[1], Enum.InfoType.GamePass)
					GamepassGifting:FireClient(player, "Error", 
						game.Players:GetNameFromUserIdAsync(userId).. " ya tiene el gamepass ".. Asset.Name)
				end
			end
			break
		end
	end
end)

-- Cuando un jugador se une al juego
game.Players.PlayerAdded:Connect(function(player)
	-- Crear carpeta Gamepasses si no existe
	local Folder = player:FindFirstChild("Gamepasses")
	if not Folder then
		Folder = Instance.new("Folder")
		Folder.Parent = player
		Folder.Name = "Gamepasses"
	end

	-- Función mejorada para manejar gamepasses
	local function handleGamepasses()
		for _, gamepass in ipairs(getAllPurchaseables()) do
			local GamepassID = gamepass[1]
			local ownsGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamepassID)
			
			if not ownsGamepass then
				-- Verificar DataStore con queue (no bloqueante)
				DataStoreQueue:GetAsync(player.UserId .. "-" .. GamepassID, function(success, result)
					ownsGamepass = success and result or false
				end)
			end

			if ownsGamepass then
				local success, Asset = pcall(function()
					return MarketplaceService:GetProductInfo(GamepassID, Enum.InfoType.GamePass)
				end)

				if success and Asset then
					-- Verificar si ya existe el BoolValue para este gamepass
					local existingValue = Folder:FindFirstChild(Asset.Name)
					if not existingValue then
						-- Solo crear si no existe
						local GamepassValue = Instance.new("BoolValue")
						GamepassValue.Parent = Folder
						GamepassValue.Name = Asset.Name
						GamepassValue.Value = true
					else
						-- Actualizar el valor si ya existe
						existingValue.Value = true
					end
				end
			else
				-- Si no tiene el gamepass, eliminar el BoolValue si existe
				local success, Asset = pcall(function()
					return MarketplaceService:GetProductInfo(GamepassID, Enum.InfoType.GamePass)
				end)

				if success and Asset then
					local existingValue = Folder:FindFirstChild(Asset.Name)
					if existingValue then
						existingValue.Value = false
					end
				end
			end
		end
	end

	-- Manejar gamepasses al unirse y cuando el personaje aparece
	handleGamepasses()
	player.CharacterAdded:Connect(handleGamepasses)
end)


-- Reemplazar la función ProcessReceipt actual con:
local function handleGiftPurchase(receiptInfo)
	for _, gamepass in pairs(getAllPurchaseables()) do
		if receiptInfo.ProductId == gamepass[2] then
			local Recipient = PlayersGifted[receiptInfo.PlayerId]
			if not Recipient then return Enum.ProductPurchaseDecision.NotProcessedYet end

			PlayersGifted[receiptInfo.PlayerId] = nil

			local success = false
			
			-- Guardar en DataStore usando queue
			DataStoreQueue:SetAsync(Recipient .. "-" .. gamepass[1], true, function(s, r)
				success = s
			end)

			-- Enviar notificación a Discord
			pcall(function()
				SendDiscordWebhook(
					game:GetService("Players"):GetNameFromUserIdAsync(Recipient),
					Recipient, 
					Username, 
					UserId, 
					gamepass[1]
				)
			end)
			
			local recipientPlayer = Players:GetPlayerByUserId(Recipient)
			if recipientPlayer then
				local Folder = recipientPlayer:FindFirstChild("Gamepasses")
				if not Folder then
					Folder = Instance.new("Folder")
					Folder.Name = "Gamepasses"
					Folder.Parent = recipientPlayer
				end

				-- Obtener el nombre del gamepass
				local gpSuccess, Asset = pcall(function()
					return MarketplaceService:GetProductInfo(gamepass[1], Enum.InfoType.GamePass)
				end)

				if gpSuccess and Asset then
					local existingValue = Folder:FindFirstChild(Asset.Name)
					if not existingValue then
						local GamepassValue = Instance.new("BoolValue")
						GamepassValue.Name = Asset.Name
						GamepassValue.Value = true
						GamepassValue.Parent = Folder
					else
						existingValue.Value = true
					end
				end
			end

			-- Notificar al donante de que se completó la compra
			local donor = game.Players:GetPlayerByUserId(UserId)
			if donor then
				GamepassGifting:FireClient(donor, "Purchase")

				-- Otorgar Badge al donante si aún no lo tiene
				if not BadgeService:UserHasBadgeAsync(donor.UserId, BADGES_Gift) then
					BadgeService:AwardBadge(donor.UserId, BADGES_Gift)
				end
			end

			return success and Enum.ProductPurchaseDecision.PurchaseGranted or 
				Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end


-- Registrar el manejador
CentralPurchaseHandler.registerGiftHandler(handleGiftPurchase)

-- Verificar propiedad de gamepass
local function DoesUserOwnGamePass(player, gamepassId)
	local success, Info = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)

	if not success or not Info then return false end

	local Folder = player:FindFirstChild("Gamepasses")
	if Folder then
		for _, child in pairs(Folder:GetChildren()) do
			if child:IsA("BoolValue") and child.Name == Info.Name and child.Value then
				return true
			end
		end
	end

	local owns = false
	pcall(function() owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) end)
	return owns
end

Ownership.OnServerInvoke = function(player, gamepassId)
	return DoesUserOwnGamePass(player, gamepassId)
end