-- ════════════════════════════════════════════════════════════════
-- USER PANEL SERVER - HÍBRIDO (API + MANUAL)
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local UNIVERSE_ID = game.GameId
local PLACE_ID = game.PlaceId

-- Acceso directo al DataStore de likes
local LikesDataStore = DataStoreService:GetDataStore("LikesData")

-- Sistema de Likes Events
local LikesEvents = ReplicatedStorage:FindFirstChild("Panda ReplicatedStorage") 
	and ReplicatedStorage["Panda ReplicatedStorage"]:FindFirstChild("LikesEvents")

-- Importar GamePassManager para validar pases (comprados + regalados)
local GamePassManager = require(game.ServerScriptService["Panda ServerScriptService"]["Gamepass Gifting"]["GamepassManager"])

-- Importar Config con lista de gamepasses
local ReplicatedStoragePanda = ReplicatedStorage:WaitForChild("Panda ReplicatedStorage")
local Config = require(ReplicatedStoragePanda["Gamepass Gifting"].Modules.Config)
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))

-- ═══════════════════════════════════════════════════════════════
--  GAME PASSES MANUALES DE TU JUEGO
-- Agrega los IDs de tus game passes aquí:
-- ═══════════════════════════════════════════════════════════════

local MANUAL_GAMEPASS_IDS = {
	-- Ejemplo:
	1534560518
	-- 987654321,
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local CONFIG = {
	STATS_CACHE_TIME = 30,
	DONATIONS_CACHE_TIME = 120,
	GAMEPASSES_CACHE_TIME = 120,
	MAX_GAMES_TO_SEARCH = 5,
	HTTP_DELAY = 0.1,

	-- Límites de performance
	MAX_ITEMS_TO_SHOW = 15,  -- Máximo de items a mostrar (evita lag)
	MAX_ITEMS_TO_VALIDATE = 10,  -- Validar solo los primeros N inmediatamente

	-- APIs (rotunnel funciona para donaciones)
	FRIENDS_API = "https://friends.roproxy.com/v1/users/",
	GAMES_API = "https://games.roproxy.com/v2/users/",
	PASSES_API = "https://apis.rotunnel.com/game-passes/v1/universes/",
}

-- ═══════════════════════════════════════════════════════════════
-- CREAR REMOTES
-- ═══════════════════════════════════════════════════════════════

local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")

local userPanelFolder = remotesGlobal:FindFirstChild("UserPanel")
if not userPanelFolder then
	userPanelFolder = Instance.new("Folder")
	userPanelFolder.Name = "UserPanel"
	userPanelFolder.Parent = remotesGlobal
end

local remoteNames = {"GetUserData", "RefreshUserData", "GetUserDonations", "GetGamePasses"}
for _, name in ipairs(remoteNames) do
	local existing = userPanelFolder:FindFirstChild(name)
	if existing then existing:Destroy() end
end

local GetUserData = Instance.new("RemoteFunction")
GetUserData.Name = "GetUserData"
GetUserData.Parent = userPanelFolder

local RefreshUserData = Instance.new("RemoteEvent")
RefreshUserData.Name = "RefreshUserData"
RefreshUserData.Parent = userPanelFolder

local GetUserDonations = Instance.new("RemoteFunction")
GetUserDonations.Name = "GetUserDonations"
GetUserDonations.Parent = userPanelFolder

local GetGamePasses = Instance.new("RemoteFunction")
GetGamePasses.Name = "GetGamePasses"
GetGamePasses.Parent = userPanelFolder

local CheckGamePass = Instance.new("RemoteFunction")
CheckGamePass.Name = "CheckGamePass"
CheckGamePass.Parent = userPanelFolder

-- ═══════════════════════════════════════════════════════════════
-- CACHÉ
-- ═══════════════════════════════════════════════════════════════

local Cache = {
	stats = {},
	donations = {},
	gamePasses = nil,
	gamePassesTime = 0
}

-- Función para validar si un jugador tiene un pase (comprado o regalado)
local function checkPlayerGamePass(player, passId)
	if not player or not passId then return false end

	-- Verificar en la carpeta de Gamepasses (regalados)
	local folder = player:FindFirstChild("Gamepasses")
	if folder then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
		end)

		if success and info then
			for _, child in pairs(folder:GetChildren()) do
				if child:IsA("BoolValue") and child.Name == info.Name and child.Value then
					return true
				end
			end
		end
	end

	-- Verificar con MarketplaceService (comprados)
	local owns = false
	pcall(function()
		owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	return owns
end

local function isCacheValid(cacheEntry, maxAge)
	if not cacheEntry then return false end
	return os.time() - cacheEntry.timestamp < maxAge
end

-- ═══════════════════════════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════════════════════════

local function httpGet(url)
	local success, result = pcall(function()
		local response = HttpService:GetAsync(url)
		return HttpService:JSONDecode(response)
	end)

	if not success then
		warn("[UserPanel] HTTP Error:", result)
		return nil
	end

	return result
end

-- ═══════════════════════════════════════════════════════════════
-- ESTADÍSTICAS
-- ═══════════════════════════════════════════════════════════════

local function getTotalLikes(userId)
	-- Primero intenta obtener del jugador en memoria
	local player = Players:FindFirstChild(tostring(userId))
	if player then
		return player:GetAttribute("TotalLikes") or 0
	end

	-- Si no está en memoria, obtener del DataStore
	local success, data = pcall(function()
		return LikesDataStore:GetAsync("Player_" .. userId)
	end)

	if success and data and data.TotalLikes then
		return data.TotalLikes
	end

	return 0
end

local function getUserStats(userId)
	local cached = Cache.stats[userId]
	if isCacheValid(cached, CONFIG.STATS_CACHE_TIME) then
		return cached.data
	end

	local stats = { followers = 0, following = 0, friends = 0, likes = 0 }

	local followersData = httpGet(CONFIG.FRIENDS_API .. userId .. "/followers/count")
	if followersData and followersData.count then
		stats.followers = followersData.count
	end

	local followingData = httpGet(CONFIG.FRIENDS_API .. userId .. "/followings/count")
	if followingData and followingData.count then
		stats.following = followingData.count
	end

	local friendsData = httpGet(CONFIG.FRIENDS_API .. userId .. "/friends/count")
	if friendsData and friendsData.count then
		stats.friends = friendsData.count
	end

	-- Obtener TotalLikes del DataStore o del atributo del jugador
	stats.likes = getTotalLikes(userId)

	Cache.stats[userId] = { data = stats, timestamp = os.time() }
	return stats
end

-- ═══════════════════════════════════════════════════════════════
-- OBTENER INFO DE GAME PASS (MarketplaceService)
-- ═══════════════════════════════════════════════════════════════

local function getGamePassInfo(passId, productId)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
	end)

	if success and info then
		local price = info.PriceInRobux or 0

		-- Solo retornar si tiene precio > 0
		if price > 0 then
			local result = {
				passId = passId,
				productId = productId,
				name = info.Name or "Game Pass",
				price = price,
				icon = info.IconImageAssetId and ("rbxassetid://" .. info.IconImageAssetId) or ""
			}
			return result
		end
	end

	return nil
end

-- ═══════════════════════════════════════════════════════════════
-- GAME PASSES VIA API (para donaciones de otros usuarios)
-- ═══════════════════════════════════════════════════════════════

local function getGamePassesFromAPI(universeId)
	local passes = {}
	local nextPageToken = ""

	repeat
		local url = CONFIG.PASSES_API .. universeId .. "/game-passes?passView=Full&pageSize=100"
		if nextPageToken ~= "" then
			url = url .. "&pageToken=" .. nextPageToken
		end

		local data = httpGet(url)

		if not data or not data.gamePasses then
			break
		end

		for _, pass in ipairs(data.gamePasses) do
			if pass.price and pass.price > 0 and pass.id then
				local iconId = pass.displayIconImageAssetId or 0
				table.insert(passes, {
					passId = pass.id,
					productId = pass.id,  -- El productId es igual al passId para donaciones
					name = pass.displayName or pass.name or "Pass",
					price = pass.price,
					icon = iconId > 0 and ("rbxassetid://" .. tostring(iconId)) or ""
				})
			end
		end

		nextPageToken = data.nextPageToken or ""
	until nextPageToken == ""

	return passes
end

-- ═══════════════════════════════════════════════════════════════
-- OBTENER GAME PASSES DEL JUEGO ACTUAL
-- ═══════════════════════════════════════════════════════════════

local function getGamePasses()
	local passes = {}
	if Config.Gamepasses then
		for _, gamepass in ipairs(Config.Gamepasses) do
			local gamepassId = gamepass[1]
			local productId = gamepass[2]

			local passInfo = getGamePassInfo(gamepassId, productId)
			if passInfo then
				table.insert(passes, passInfo)
			end
		end
	end
	-- Ordenar por precio
	table.sort(passes, function(a, b) return a.price < b.price end)

	return passes
end

-- ═══════════════════════════════════════════════════════════════
-- DONACIONES DE USUARIOS
-- ═══════════════════════════════════════════════════════════════

local function getUserGames(userId)
	local games = {}
	local cursor = ""

	repeat
		local url = CONFIG.GAMES_API .. userId .. "/games?accessFilter=Public&limit=50"
		if cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end

		local data = httpGet(url)
		if not data or not data.data then break end

		for _, game in ipairs(data.data) do
			table.insert(games, { universeId = game.id, name = game.name })
		end

		cursor = data.nextPageCursor or ""
	until cursor == ""

	return games
end

local function getUserDonations(userId)
	local cached = Cache.donations[userId]
	if isCacheValid(cached, CONFIG.DONATIONS_CACHE_TIME) then
		return cached.data
	end

	local allPasses = {}
	local games = getUserGames(userId)

	local gamesToSearch = math.min(#games, CONFIG.MAX_GAMES_TO_SEARCH)

	for i = 1, gamesToSearch do
		local game = games[i]
		local passes = getGamePassesFromAPI(game.universeId)

		for _, pass in ipairs(passes) do
			table.insert(allPasses, pass)
		end

		if i < gamesToSearch then
			task.wait(CONFIG.HTTP_DELAY)
		end
	end

	table.sort(allPasses, function(a, b) return a.price < b.price end)

	Cache.donations[userId] = { data = allPasses, timestamp = os.time() }

	return allPasses
end

-- ═══════════════════════════════════════════════════════════════
-- HANDLERS
-- ═══════════════════════════════════════════════════════════════

GetUserData.OnServerInvoke = function(_, targetUserId)
	return getUserStats(targetUserId)
end

RefreshUserData.OnServerEvent:Connect(function(requestingPlayer, targetUserId)
	Cache.stats[targetUserId] = nil
	local freshData = getUserStats(targetUserId)
	RefreshUserData:FireClient(requestingPlayer, freshData)
end)

GetUserDonations.OnServerInvoke = function(player, targetUserId)
	if not targetUserId or not player then return {} end
	local donations = getUserDonations(targetUserId)

	-- Limitar cantidad de items (performance)
	if #donations > CONFIG.MAX_ITEMS_TO_SHOW then
		local limited = {}
		for i = 1, CONFIG.MAX_ITEMS_TO_SHOW do
			table.insert(limited, donations[i])
		end
		donations = limited
	end

	-- Validar si YO (player) ya compré esos gamepasses
	if player and donations and #donations > 0 then
		local toValidate = math.min(#donations, CONFIG.MAX_ITEMS_TO_VALIDATE)
		local completed = 0

		for i = 1, toValidate do
			local donation = donations[i]
			task.spawn(function()
				-- Verificar si YO ya tengo este pase
				donation.hasPass = checkPlayerGamePass(player, donation.passId)
				completed = completed + 1
			end)
		end

		-- Marcar el resto como "no validado"
		for i = toValidate + 1, #donations do
			donations[i].hasPass = nil
		end

		-- Esperar validaciones
		local startTime = tick()
		while completed < toValidate and (tick() - startTime) < 3 do
			task.wait(0.05)
		end
	end

	return donations
end

GetGamePasses.OnServerInvoke = function(player, targetUserId)
	local passes = getGamePasses()

	-- Obtener el Player object del jugador objetivo
	local targetPlayer = targetUserId and Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		-- Si no está en el servidor, no podemos validar
		return passes
	end

	-- Limitar cantidad de items (performance)
	if #passes > CONFIG.MAX_ITEMS_TO_SHOW then
		local limited = {}
		for i = 1, CONFIG.MAX_ITEMS_TO_SHOW do
			table.insert(limited, passes[i])
		end
		passes = limited
	end

	-- Validar solo primeros N items en PARALELO
	if targetPlayer and passes and #passes > 0 then
		local toValidate = math.min(#passes, CONFIG.MAX_ITEMS_TO_VALIDATE)
		local completed = 0

		for i = 1, toValidate do
			local pass = passes[i]
			task.spawn(function()
				-- Verificar si el JUGADOR OBJETIVO ya tiene el pase
				pass.hasPass = checkPlayerGamePass(targetPlayer, pass.passId)
				completed = completed + 1
			end)
		end

		-- Marcar el resto como "no validado"
		for i = toValidate + 1, #passes do
			passes[i].hasPass = nil
		end

		-- Esperar validaciones
		local startTime = tick()
		while completed < toValidate and (tick() - startTime) < 3 do
			task.wait(0.05)
		end
	end

	return passes
end

CheckGamePass.OnServerInvoke = function(player, passId, targetUserId)
	if not passId then return false end

	-- Para "Donar": validar si YO tengo el pase (player)
	-- Para "Regalar": validar si EL OBJETIVO tiene el pase (targetUserId)
	local playerToCheck = player
	if targetUserId then
		playerToCheck = Players:GetPlayerByUserId(targetUserId)
		if not playerToCheck then return false end
	end

	if not playerToCheck then return false end
	return checkPlayerGamePass(playerToCheck, passId)
end

-- ═══════════════════════════════════════════════════════════════
-- INVALIDAR CACHÉ CUANDO SE ACTUALIZAN LIKES
-- ═══════════════════════════════════════════════════════════════
local function invalidateStatsCache(userId)
	Cache.stats[userId] = nil
end

-- Escuchar eventos de likes para invalidar caché
if LikesEvents then
	local GiveLikeEvent = LikesEvents:FindFirstChild("GiveLikeEvent")
	local GiveSuperLikeEvent = LikesEvents:FindFirstChild("GiveSuperLikeEvent")

	if GiveLikeEvent then
		GiveLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
			if action == "GiveLike" and targetUserId then
				-- Invalidar caché del jugador que recibió el like
				task.delay(0.5, function()
					invalidateStatsCache(targetUserId)
				end)
			end
		end)
	end

	if GiveSuperLikeEvent then
		GiveSuperLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
			if action == "GiveSuperLike" and targetUserId then
				task.delay(0.5, function()
					invalidateStatsCache(targetUserId)
				end)
			end
			if action == "SetSuperLikeTarget" and targetUserId then
				-- No invalidar aquí, solo cuando se complete la compra
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════════════

task.spawn(function()
	getGamePasses()
end)