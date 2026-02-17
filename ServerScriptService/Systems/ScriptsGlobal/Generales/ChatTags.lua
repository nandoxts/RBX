-- ========================================
-- SERVERSCRIPT (en ServerScriptService)
-- ========================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Systems")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local configuration = require(ServerScriptService.Configuration)
local GroupRolesModule = require(ServerScriptService.Modules.GroupRolesModule)

-- DataStore y cache para gamepasses
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local GamepassCache = {}

-- Cache del servidor para tags
local serverTagCache = {}
local groupRoles = GroupRolesModule.GROUP_ROLES

-- Crear/obtener RemoteEvents
local tagDataEvent = ReplicatedStorage.Chat:FindFirstChild("PlayerTagData")
if not tagDataEvent then
	tagDataEvent = Instance.new("RemoteEvent")
	tagDataEvent.Name = "PlayerTagData"
	tagDataEvent.Parent = ReplicatedStorage.Chat
end

local remoteFunction = ReplicatedStorage.Chat.CheckGamePass

-- Función optimizada para verificar gamepasses (tu código integrado)
local function checkPlayerGamepasses(userId)
	-- Si ya está en cache, devolverlo
	if GamepassCache[userId] then
		return GamepassCache[userId]
	end

	local cacheEntry = {
		status = nil, -- "VIPPLUS", "VIP" o nil
		lastChecked = os.time()
	}

	-- 1. Verificar VIPPLUS primero (máxima prioridad)
	local successVIPPlus, hasVIPPlus = pcall(function()
		-- Primero verificar compra directa
		if MarketplaceService:UserOwnsGamePassAsync(userId, configuration.VIPPLUS) then
			return true
		end
		-- Si no tiene comprado, verificar regalo
		return GiftedGamepassesData:GetAsync(userId .. "-" .. configuration.VIPPLUS)
	end)

	if successVIPPlus and hasVIPPlus then
		cacheEntry.status = "VIPPLUS"
		GamepassCache[userId] = cacheEntry
		return cacheEntry
	end

	-- 2. Solo verificar VIP si no tiene VIPPLUS
	local successVIP, hasVIP = pcall(function()
		-- Primero verificar compra directa
		if MarketplaceService:UserOwnsGamePassAsync(userId, configuration.VIP) then
			return true
		end
		-- Si no tiene comprado, verificar regalo
		return GiftedGamepassesData:GetAsync(userId .. "-" .. configuration.VIP)
	end)

	if successVIP and hasVIP then
		cacheEntry.status = "VIP"
		GamepassCache[userId] = cacheEntry
		return cacheEntry
	end

	-- 3. No tiene ninguno
	cacheEntry.status = nil
	GamepassCache[userId] = cacheEntry
	return cacheEntry
end

-- Función mejorada para obtener rank (SOLO en servidor)
local function getPlayerGroupRank(player)
	-- Intentar método nativo primero (más rápido)
	local success, rank = pcall(function()
		return player:GetRankInGroup(configuration.GroupID)
	end)

	if success and rank > 0 then
		return rank
	end

	-- Fallback con HttpService solo si es necesario
	local httpSuccess, result = pcall(function()
		return HttpService:GetAsync("https://groups.roblox.com/v1/users/" .. player.UserId .. "/groups/roles")
	end)

	if httpSuccess then
		local data = HttpService:JSONDecode(result)
		for _, groupData in ipairs(data.data) do
			if groupData.group.id == configuration.GroupID then
				return groupData.role.rank
			end
		end
	end

	return 0
end

-- Función para convertir Color3 a hex
local function color3ToHex(color)
	return string.format("#%02X%02X%02X", 
		math.round(color.R * 255), 
		math.round(color.G * 255), 
		math.round(color.B * 255)
	)
end

-- Función integrada para determinar tag completo
local function calculatePlayerTag(player)
	local userId = player.UserId

	-- Verificar cache del servidor
	if serverTagCache[userId] then
		return serverTagCache[userId]
	end

	local tagInfo = {}

	-- 1. Verificar rank en grupo primero (máxima prioridad)
	local playerRank = getPlayerGroupRank(player)
	local roleData = groupRoles[playerRank]

	if roleData and playerRank >= 10 then -- Recruiter hacia arriba
		local colorHex = color3ToHex(roleData.Color)
		local icon = roleData.Icon

		tagInfo = {
			Prefix = string.format("<font color='%s'>[%s]</font> <font color='%s'>%s</font> ", 
				colorHex, icon, colorHex, roleData.Name),
			--TextColor = colorHex,
			Priority = playerRank,
			HasSpecialTag = true,
			Source = "GROUP_RANK",
		}
	else
		-- 2. Si no tiene rank de grupo, verificar VIP GamePass (usando tu sistema)
		local gamepassInfo = checkPlayerGamepasses(userId)

		if gamepassInfo and gamepassInfo.status == "VIPPLUS" then
			tagInfo = {
				Prefix = "<font color='#FF330F'>[👑]</font> <font color='#FF330F'>[ VIP PLUS ]</font> ",
				TextColor = "#FF330F",
				Priority = 8,
				HasSpecialTag = true,
				Source = "VIPPLUS_GAMEPASS"
			}
		elseif gamepassInfo and gamepassInfo.status == "VIP" then
			tagInfo = {
				Prefix = "<font color='#D92B0D'>[👑]</font> <font color='#D92B0D'>[ VIP ]</font> ",
				TextColor = "#D92B0D",
				Priority = 5,
				HasSpecialTag = true,
				Source = "VIP_GAMEPASS"
			}
		else
			-- 3. Tag por defecto
			tagInfo = {
				Prefix = "<font color='#0099FF'>[👤]</font> <font color='#0099FF'>[ Tonero ]</font> ",
				TextColor = "#FFFFFF",
				Priority = 0,
				HasSpecialTag = false,
				Source = "DEFAULT"
			}
		end
	end

	-- Guardar en cache del servidor
	serverTagCache[userId] = tagInfo

	return tagInfo
end

-- Verificar al unirse y al reaparecer el personaje (tu código integrado)
local function setupPlayer(player)
	-- Verificar gamepasses inmediatamente al unirse
	checkPlayerGamepasses(player.UserId)

	-- Esperar un poco para que cargue completamente
	wait(2)

	-- 1. Calcular tag del nuevo jugador
	local tagInfo = calculatePlayerTag(player)

	-- 2. Enviar tag del nuevo jugador a TODOS los clientes
	tagDataEvent:FireAllClients(player.UserId, tagInfo)

	-- 3. IMPORTANTE: Enviar tags de TODOS los jugadores existentes al nuevo cliente
	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		if existingPlayer ~= player and serverTagCache[existingPlayer.UserId] then
			-- Enviar tag de cada jugador existente solo al nuevo cliente
			tagDataEvent:FireClient(player, existingPlayer.UserId, serverTagCache[existingPlayer.UserId])
		end
	end

	--print("Tag calculado para", player.Name, ":", tagInfo.Prefix, "| Fuente:", tagInfo.Source)
	--print("Enviados", #Players:GetPlayers()-1, "tags existentes a", player.Name)

	-- Volver a verificar si el personaje reaparece
	player.CharacterAdded:Connect(function()
		-- Limpiar cache para forzar re-verificación
		serverTagCache[player.UserId] = nil
		GamepassCache[player.UserId] = nil

		-- Recalcular después de un pequeño delay
		wait(1)
		local newTagInfo = calculatePlayerTag(player)
		tagDataEvent:FireAllClients(player.UserId, newTagInfo)

		--print("Tag actualizado para", player.Name, "tras respawn:", newTagInfo.Source)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Limpiar ambos caches al desconectar
Players.PlayerRemoving:Connect(function(player)
	serverTagCache[player.UserId] = nil
	GamepassCache[player.UserId] = nil
end)

-- Para jugadores ya conectados cuando se inicia el script
for _, player in ipairs(Players:GetPlayers()) do
	spawn(function()
		-- Calcular tag para jugador existente
		local tagInfo = calculatePlayerTag(player)

		-- Enviar a todos los clientes
		tagDataEvent:FireAllClients(player.UserId, tagInfo)

		--print("Tag inicial calculado para", player.Name, ":", tagInfo.Source)
	end)
end

-- Manejar la invocación remota (tu código integrado - compatibilidad)
remoteFunction.OnServerInvoke = function(player, targetUserId)
	-- Si no está en cache, verificar ahora
	if not GamepassCache[targetUserId] then
		checkPlayerGamepasses(targetUserId)
	end

	-- Devolver el estado cacheado (puede ser nil)
	return GamepassCache[targetUserId] and GamepassCache[targetUserId].status
end

-- Función para forzar actualización de tag (útil para cambios de gamepass)
local function forceUpdatePlayerTag(player)
	-- Limpiar ambos caches
	serverTagCache[player.UserId] = nil
	GamepassCache[player.UserId] = nil

	-- Recalcular
	local tagInfo = calculatePlayerTag(player)

	-- Enviar actualización
	tagDataEvent:FireAllClients(player.UserId, tagInfo)

	--print("Tag forzado para", player.Name, ":", tagInfo.Source)
end

-- Event para actualizaciones manuales (opcional - para admins)
local updateTagEvent = ReplicatedStorage.Chat:FindFirstChild("ForceUpdateTag")
if not updateTagEvent then
	updateTagEvent = Instance.new("RemoteEvent")
	updateTagEvent.Name = "ForceUpdateTag"
	updateTagEvent.Parent = ReplicatedStorage.Chat
end

updateTagEvent.OnServerEvent:Connect(function(player, targetUserId)
	-- Solo admins pueden forzar actualización
	if player:GetRankInGroup(configuration.GroupID) >= 255 then -- Admin o superior
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then
			forceUpdatePlayerTag(targetPlayer)
		end
	end
end)