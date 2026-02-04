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

-- ═══════════════════════════════════════════════════════════════
-- ⚠️ GAME PASSES MANUALES DE TU JUEGO
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

local remoteNames = {"GetUserData", "RefreshUserData", "GetUserDonations", "GetGamePasses", "SendLike"}
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

local SendLike = Instance.new("RemoteEvent")
SendLike.Name = "SendLike"
SendLike.Parent = userPanelFolder

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

local function getGamePassInfo(passId)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
	end)

	if success and info then
		local price = info.PriceInRobux or 0

		-- Solo retornar si tiene precio > 0
		if price > 0 then
			return {
				passId = passId,
				name = info.Name or "Game Pass",
				price = price,
				icon = info.IconImageAssetId and ("rbxassetid://" .. info.IconImageAssetId) or ""
			}
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
			if pass.price and pass.price > 0 then
				local iconId = pass.displayIconImageAssetId or 0
				table.insert(passes, {
					passId = pass.id,
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
-- GAME PASSES MANUALES (para tu juego)
-- ═══════════════════════════════════════════════════════════════

local function getGamePassesManual()
	local passes = {}

	for _, passId in ipairs(MANUAL_GAMEPASS_IDS) do
		local passInfo = getGamePassInfo(passId)
		if passInfo then
			table.insert(passes, passInfo)
			print("[UserPanel] ✓ Pass cargado:", passInfo.name, "R$" .. passInfo.price)
		else
			warn("[UserPanel] ✗ Pass no válido o sin precio:", passId)
		end
	end

	return passes
end

-- ═══════════════════════════════════════════════════════════════
-- OBTENER GAME PASSES DEL JUEGO ACTUAL
-- ═══════════════════════════════════════════════════════════════

local function getGamePasses()
	if Cache.gamePasses and os.time() - Cache.gamePassesTime < CONFIG.GAMEPASSES_CACHE_TIME then
		return Cache.gamePasses
	end

	local passes = {}

	-- Método 1: Intentar API
	print("[UserPanel] Intentando cargar passes via API...")
	passes = getGamePassesFromAPI(UNIVERSE_ID)

	-- Método 2: Si API falló, usar manuales
	if #passes == 0 then
		print("[UserPanel] API no devolvió passes, intentando manuales...")
		passes = getGamePassesManual()
	end

	-- Ordenar por precio
	table.sort(passes, function(a, b) return a.price < b.price end)

	Cache.gamePasses = passes
	Cache.gamePassesTime = os.time()

	print("[UserPanel] Game passes cargados:", #passes)

	if #passes == 0 then
		warn("[UserPanel] ══════════════════════════════════════")
		warn("[UserPanel] ⚠️ NO HAY GAME PASSES CONFIGURADOS")
		warn("[UserPanel] Agrega los IDs en MANUAL_GAMEPASS_IDS")
		warn("[UserPanel] ══════════════════════════════════════")
	end

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

	print("[UserPanel] Usuario", userId, "tiene", #games, "juegos")

	local gamesToSearch = math.min(#games, CONFIG.MAX_GAMES_TO_SEARCH)

	for i = 1, gamesToSearch do
		local game = games[i]
		local passes = getGamePassesFromAPI(game.universeId)

		print("[UserPanel]", game.name or "Sin nombre", "->", #passes, "passes")

		for _, pass in ipairs(passes) do
			table.insert(allPasses, pass)
		end

		if i < gamesToSearch then
			task.wait(CONFIG.HTTP_DELAY)
		end
	end

	table.sort(allPasses, function(a, b) return a.price < b.price end)

	Cache.donations[userId] = { data = allPasses, timestamp = os.time() }

	print("[UserPanel] TOTAL donaciones:", #allPasses)
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
	if not targetUserId then return {} end
	local donations = getUserDonations(targetUserId)
	
	-- Validar cada donación en PARALELO con MarketplaceService
	if player and donations and #donations > 0 then
		local completed = 0
		local total = #donations
		
		for i, donation in ipairs(donations) do
			task.spawn(function()
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, donation.passId)
				end)
				donation.hasPass = (success and owns) or false
				completed = completed + 1
			end)
		end
		
		-- Esperar a que TODAS las validaciones terminen (máximo 5 segundos)
		local startTime = tick()
		while completed < total and (tick() - startTime) < 5 do
			task.wait(0.05)
		end
		
		print("[UserPanel Server] Validadas", completed, "/", total, "donaciones para", player.Name)
	end
	
	return donations
end

GetGamePasses.OnServerInvoke = function(player)
	local passes = getGamePasses()
	
	-- Validar cada pass en PARALELO con MarketplaceService
	if player and passes and #passes > 0 then
		local completed = 0
		local total = #passes
		
		for i, pass in ipairs(passes) do
			task.spawn(function()
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.passId)
				end)
				pass.hasPass = (success and owns) or false
				completed = completed + 1
			end)
		end
		
		-- Esperar a que TODAS las validaciones terminen (máximo 5 segundos)
		local startTime = tick()
		while completed < total and (tick() - startTime) < 5 do
			task.wait(0.05)
		end
		
		print("[UserPanel Server] Validados", completed, "/", total, "game passes para", player.Name)
	end
	
	return passes
end

SendLike.OnServerEvent:Connect(function(donatingPlayer, targetUserId)
	if not donatingPlayer or not targetUserId then return end
	
	print("[UserPanel] 👍 Like recibido: " .. donatingPlayer.Name .. " le dio like a usuario " .. targetUserId)
	-- Aquí puedes agregar lógica adicional como guardar en DataStore, efectos visuales, etc.
end)

CheckGamePass.OnServerInvoke = function(player, passId)
	if not player or not passId then return false end
	
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	
	if success then
		return hasPass
	end
	
	return false
end

-- ═══════════════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════════════

task.spawn(function()
	getGamePasses()
end)