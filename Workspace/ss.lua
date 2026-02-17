local ServerStorage = game:GetService("ServerStorage"):WaitForChild("Systems")

-- Servicios
local PlayersService = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Panda ServerScriptService")

-- Módulos externos
local Configuration = require(ServerScriptService.Configuration)
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)

-- Configuración de multiplicadores de tiempo
local TIME_MULTIPLIERS = {
	VIP = {
		ID = Configuration.VIP,
		MULTIPLIER = 2
	},
	COMMANDS = {
		ID = Configuration.COMMANDS,
		MULTIPLIER = 5
	},
	OWS = {
		IDs = Configuration.OWS,
		MULTIPLIER = 20  -- Cada minuto cuenta como 5 minutos
	}
}

-- Módulo de configuración
local Config = require(script.Parent.Settings)

-- Clase principal
local TimePlayedTracker = {}
TimePlayedTracker.__index = TimePlayedTracker

function TimePlayedTracker.new()
	local self = setmetatable({}, TimePlayedTracker)

	-- Configuración
	self.DataStoreName = Config.DATA_STORE
	self.StatName = Config.NAME_OF_STAT
	self.LevelStatName = Config.NAME_OF_STAT .. "_Level" -- Nombre para el datastore de niveles
	self.ScoreUpdateInterval = Config.SCORE_UPDATE * 60
	self.BoardUpdateInterval = Config.LEADERBOARD_UPDATE * 60
	self.UseLeaderstats = Config.USE_LEADERSTATS
	self.LeaderstatsTime = Config.NAME_LEADERSTATS_TIME
	self.LeaderstatsLevel = Config.NAME_LEADERSTATS_LEVEL
	self.LevelUpMinutes = Config.LEVEL_UP_MINUTES
	self.ShowTopPlayerAvatar = Config.SHOW_1ST_PLACE_AVATAR or true
	self.DebugEnabled = Config.DO_DEBUG

	-- Referencias a objetos
	self.ScoreBlock = script.Parent.ScoreBlock
	self.UpdateTimerLabel = script.Parent.UpdateBoardTimer.Timer.TextLabel

	-- Estado interno
	self.DataStore = nil
	self.LevelDataStore = nil -- DataStore separado para niveles
	self.IsMainScript = nil
	self.ApiServicesEnabled = false
	self.IsDancingRigEnabled = false
	self.DancingRigModule = nil

	-- Cachés
	self.UsernameCache = {}
	self.ThumbnailCache = {}
	self.MembershipCache = {} -- Caché para membresías de jugadores
	self.LevelCache = {} -- Nuevo: caché para niveles de jugadores

	self:Initialize()

	return self
end

function TimePlayedTracker:Initialize()
	if self.DebugEnabled then
		warn("TimePlayedTracker: La depuración está habilitada.")
	end

	self:CheckIfMainScript()

	if self.IsMainScript then
		if not self:CheckDataStoreAvailability() then
			self:ClearLeaderboard()
			self.ScoreBlock.NoAPIServices.Warning.Visible = true
			return
		end
	else
		self.ApiServicesEnabled = (ServerStorage:WaitForChild("TopTimePlayedLeaderboard_NoAPIServices_Flag", 99) :: BoolValue).Value
		if not self.ApiServicesEnabled then
			self:ClearLeaderboard()
			self.ScoreBlock.NoAPIServices.Warning.Visible = true
			return
		end
	end

	-- Inicializar DataStores
	local success, error = pcall(function()
		self.DataStore = DataStoreService:GetOrderedDataStore(self.DataStoreName)
		self.LevelDataStore = DataStoreService:GetDataStore(self.LevelStatName) -- DataStore para niveles
	end)

	if not success or self.DataStore == nil or self.LevelDataStore == nil then
		warn("Error al inicializar DataStores:", error)
		script.Parent:Destroy()
		return
	end

	self:CheckDancingRigAvailability()

	-- Configurar leaderstats para jugadores
	if self.UseLeaderstats and self.IsMainScript then
		self:SetupLeaderstats()
	end

	-- Configurar manejo de eventos de jugadores
	self:SetupPlayerEvents()

	-- Iniciar procesos en segundo plano
	self:StartScoreUpdateProcess()
	self:StartBoardUpdateProcess()
end

function TimePlayedTracker:SetupPlayerEvents()
	-- Limpiar caché cuando un jugador abandone el juego
	PlayersService.PlayerRemoving:Connect(function(player)
		local userId = player.UserId
		self.MembershipCache[userId] = nil
		self.LevelCache[userId] = nil
		self.UsernameCache[userId] = nil
		self.ThumbnailCache[userId] = nil

		if self.DebugEnabled then
			print("Caché limpiada para el jugador:", player.Name)
		end
	end)

	-- Para jugadores que ya están en el juego, inicializar su caché
	for _, player in ipairs(PlayersService:GetPlayers()) do
		self:CachePlayerMembership(player.UserId)
		self:CachePlayerLevel(player.UserId) -- Inicializar caché de nivel
	end
end

function TimePlayedTracker:CachePlayerMembership(userId)
	-- Inicializar caché para el jugador si no existe
	if not self.MembershipCache[userId] then
		self.MembershipCache[userId] = {
			multiplier = 1,
			lastUpdated = os.time()
		}

		-- Calcular multiplicador inicial
		self:UpdateMembershipCache(userId)
	end
end

function TimePlayedTracker:CachePlayerLevel(userId)
	-- Inicializar caché de nivel para el jugador si no existe
	if not self.LevelCache[userId] then
		local success, level = pcall(function()
			return self.LevelDataStore:GetAsync(tostring(userId))
		end)

		self.LevelCache[userId] = {
			level = success and level or 1,
			lastUpdated = os.time()
		}

		if self.DebugEnabled then
			print("Nivel cargado para usuario", userId, ":", self.LevelCache[userId].level)
		end
	end
end

function TimePlayedTracker:UpdateMembershipCache(userId)
	local player = PlayersService:GetPlayerByUserId(userId)
	if not player then return end

	local multiplier = 1

	-- Verificar OWS (máxima prioridad)
	for _, owsId in ipairs(TIME_MULTIPLIERS.OWS.IDs) do
		if player.UserId == owsId then
			multiplier = TIME_MULTIPLIERS.OWS.MULTIPLIER
			break
		end
	end

	-- Solo verificar otros gamepasses si no es OWS
	if multiplier == 1 then
		-- Verificar COMMANDS
		if GamepassManager.HasGamepass(player, TIME_MULTIPLIERS.COMMANDS.ID) then
			multiplier = TIME_MULTIPLIERS.COMMANDS.MULTIPLIER
			-- Verificar VIP
		elseif GamepassManager.HasGamepass(player, TIME_MULTIPLIERS.VIP.ID) then
			multiplier = TIME_MULTIPLIERS.VIP.MULTIPLIER
		end
	end

	-- Actualizar caché
	self.MembershipCache[userId] = {
		multiplier = multiplier,
		lastUpdated = os.time()
	}

	if self.DebugEnabled then
		print("Caché de membresía actualizada para", player.Name, ": x" .. multiplier)
	end

	return multiplier
end

function TimePlayedTracker:GetTimeMultiplier(userId)
	-- Verificar si el usuario está en caché, si no, agregarlo
	if not self.MembershipCache[userId] then
		self:CachePlayerMembership(userId)
	end

	-- Devolver el multiplicador desde caché
	return self.MembershipCache[userId].multiplier
end

function TimePlayedTracker:GetPlayerLevel(userId)
	-- Verificar si el nivel del usuario está en caché, si no, agregarlo
	if not self.LevelCache[userId] then
		self:CachePlayerLevel(userId)
	end

	-- Devolver el nivel desde caché
	return self.LevelCache[userId].level
end

function TimePlayedTracker:CalculateLevelFromTime(minutesPlayed)
	-- Cada 5 minutos = 1 nivel
	return math.floor(minutesPlayed / self.LevelUpMinutes) + 1
end

function TimePlayedTracker:UpdatePlayerLevel(userId, newTimePlayed)
	local newLevel = self:CalculateLevelFromTime(newTimePlayed)
	local currentLevel = self:GetPlayerLevel(userId)

	if newLevel > currentLevel then
		-- Guardar nuevo nivel en DataStore
		local success, error = pcall(function()
			self.LevelDataStore:SetAsync(tostring(userId), newLevel)
		end)

		if success then
			-- Actualizar caché
			self.LevelCache[userId] = {
				level = newLevel,
				lastUpdated = os.time()
			}

			-- Actualizar leaderstats si está habilitado
			self:UpdatePlayerLevelLeaderstat(userId, newLevel)

			if self.DebugEnabled then
				print("Nivel actualizado para usuario", userId, ":", currentLevel, "->", newLevel)
			end

			return true -- Nivel actualizado
		else
			warn("Error al guardar nivel para usuario", userId, ":", error)
		end
	end

	return false -- Nivel no cambió
end

function TimePlayedTracker:SetupLeaderstats()
	local function createLeaderstats(player)
		task.spawn(function()
			-- Buscar o crear folder leaderstats
			local leaderstatsFolder = player:WaitForChild("leaderstats", 8)
			if not leaderstatsFolder then
				if self.DebugEnabled then
					print("Creando folder leaderstats para", player.Name)
				end
				leaderstatsFolder = Instance.new("Configuration")
				leaderstatsFolder.Name = "leaderstats"
				leaderstatsFolder.Parent = player
			end

			local LocalizationService = game:GetService("LocalizationService")

			-- Crear stat de país
			local countryStat = Instance.new("StringValue")
			countryStat.Name = "Country"
			countryStat.Parent = leaderstatsFolder

			-- Obtener país del jugador
			local success, countryCode = pcall(function()
				return LocalizationService:GetCountryRegionForPlayerAsync(player)
			end)

			-- Convertir país a bandera
			local function CountryToFlag(code)
				if not code then return "🏳️" end
				local flag = ""
				for i = 1, #code do
					flag ..= utf8.char(127397 + string.byte(code, i))
				end
				return flag
			end

			countryStat.Value = success and CountryToFlag(countryCode) or "🏳️"


			-- Obtener tiempo guardado del jugador
			local success, timeResult = pcall(function()
				return self.DataStore:GetAsync(self.StatName .. player.UserId)
			end)

			-- Inicializar cachés para el jugador
			self:CachePlayerMembership(player.UserId)
			self:CachePlayerLevel(player.UserId)
		end)
	end

	-- Configurar jugadores existentes
	for _, player in ipairs(PlayersService:GetPlayers()) do
		createLeaderstats(player)
	end

	-- Configurar nuevos jugadores
	PlayersService.PlayerAdded:Connect(function(player)
		createLeaderstats(player)

		-- Actualizar cachés después de un breve delay
		task.wait(2) -- Esperar a que el jugador esté completamente cargado
		self:UpdateMembershipCache(player.UserId)
	end)
end

function TimePlayedTracker:StartScoreUpdateProcess()
	if not self.IsMainScript then return end

	task.spawn(function()
		while true do
			task.wait(self.ScoreUpdateInterval)
			self:UpdateAllPlayersScores()
		end
	end)
end

function TimePlayedTracker:StartBoardUpdateProcess()
	task.spawn(function()
		self:UpdateLeaderboard()  -- Actualizar inmediatamente

		local countdown = self.BoardUpdateInterval
		while true do
			task.wait(1)
			countdown -= 1
			self.UpdateTimerLabel.Text = string.format("Actualizando tablero en %d segundos", countdown)

			if countdown <= 0 then
				self:UpdateLeaderboard()
				countdown = self.BoardUpdateInterval
			end
		end
	end)
end

function TimePlayedTracker:ClearLeaderboard()
	local sections = {
		self.ScoreBlock.Leaderboard.Names,
		self.ScoreBlock.Leaderboard.Photos,
		self.ScoreBlock.Leaderboard.Score,
		self.ScoreBlock.Leaderboard.Level
	}

	for _, section in ipairs(sections) do
		for _, element in ipairs(section:GetChildren()) do
			element.Visible = false
		end
	end
end

function TimePlayedTracker:UpdateLeaderboard()
	if self.DebugEnabled then
		print("Actualizando tablero de líderes")
	end

	local success, results = pcall(function()
		return self.DataStore:GetSortedAsync(false, 10, 1):GetCurrentPage()
	end)

	if not success or not results then
		if self.DebugEnabled then
			warn("Error al obtener top 10:", results)
		end
		return
	end

	local leaderboardUI = self.ScoreBlock.Leaderboard
	self.ScoreBlock.Credits.Enabled = true
	leaderboardUI.Enabled = #results > 0
	self.ScoreBlock.NoDataFound.Enabled = #results == 0

	self:ClearLeaderboard()

	for position, data in ipairs(results) do
		local userId = tonumber(string.split(data.key, self.StatName)[2])
		local username, thumbnail

		if userId <= 0 then
			username = "Studio Test Profile"
			thumbnail = "rbxassetid://11569282129"
		else
			username = self:GetCachedUsername(userId)
			thumbnail = self:GetCachedThumbnail(userId)
		end

		local formattedTime = self:FormatTime(data.value)
		local playerLevel = self:GetPlayerLevel(userId) or 1

		self:UpdatePlayerLeaderstat(userId, data.value)

		-- Actualizar UI
		leaderboardUI.Names["Name" .. position].Visible = true
		leaderboardUI.Score["Score" .. position].Visible = true
		leaderboardUI.Photos["Photo" .. position].Visible = true
		leaderboardUI.Level["Level" .. position].Visible = true

		leaderboardUI.Names["Name" .. position].Text = username
		leaderboardUI.Score["Score" .. position].Text = formattedTime
		leaderboardUI.Photos["Photo" .. position].Image = thumbnail
		leaderboardUI.Level["Level" .. position].Text = "Nvl. " .. tostring(playerLevel)

		-- Configurar avatar del primer lugar si es necesario
		if position == 1 and self.DancingRigModule then
			task.spawn(function()
				self.DancingRigModule.SetRigHumanoidDescription(userId > 0 and userId or 1)
			end)
		end
	end

	-- Crear efecto de espejo en la parte trasera
	if self.ScoreBlock:FindFirstChild("_backside") then
		self.ScoreBlock._backside:Destroy()
	end

	local mirror = leaderboardUI:Clone()
	mirror.Parent = self.ScoreBlock
	mirror.Name = "_backside"
	mirror.Face = Enum.NormalId.Back

	if self.DebugEnabled then
		print("Tablero actualizado correctamente")
	end
end

function TimePlayedTracker:UpdateAllPlayersScores()
	local players = PlayersService:GetPlayers()

	for _, player in ipairs(players) do
		local statKey = self.StatName .. player.UserId
		local multiplier = self:GetTimeMultiplier(player.UserId)
		local incrementValue = (self.ScoreUpdateInterval / 60) * multiplier

		local success, newTime = pcall(function()
			return self.DataStore:IncrementAsync(statKey, incrementValue)
		end)

		if success then
			-- Verificar y actualizar nivel si es necesario
			self:UpdatePlayerLevel(player.UserId, newTime)

			if self.DebugEnabled then
				print("Tiempo incrementado para", player.Name, ":", newTime, "(x" .. multiplier .. ")")
			end
		elseif self.DebugEnabled then
			warn("Error al incrementar tiempo para", player.Name, ":", newTime)
		end
	end
end

function TimePlayedTracker:UpdatePlayerLeaderstat(userId, minutes)
	if not self.UseLeaderstats or not self.IsMainScript then
		return
	end

	local player = PlayersService:GetPlayerByUserId(userId)
	if not player or not player:FindFirstChild("leaderstats") then
		return
	end

	local timeStat = player.leaderstats:FindFirstChild(self.LeaderstatsTime)
	if timeStat then
		timeStat.Value = tonumber(minutes)
	end
end

function TimePlayedTracker:UpdatePlayerLevelLeaderstat(userId, level)
	if not self.UseLeaderstats or not self.IsMainScript then
		return
	end

	local player = PlayersService:GetPlayerByUserId(userId)
	if not player or not player:FindFirstChild("leaderstats") then
		return
	end

	local levelStat = player.leaderstats:FindFirstChild(self.LeaderstatsLevel)
	if levelStat then
		levelStat.Value = tonumber(level)
	end
end

function TimePlayedTracker:CheckDancingRigAvailability()
	if not self.ShowTopPlayerAvatar then
		local rigFolder = script.Parent:FindFirstChild("First Place Avatar")
		if rigFolder then
			rigFolder:Destroy()
		end
		return
	end

	local rigFolder = script.Parent:FindFirstChild("First Place Avatar")
	if not rigFolder then
		return
	end

	local rig = rigFolder:FindFirstChild("Rig")
	local rigModule = rigFolder:FindFirstChild("PlayAnimationInRig")

	if rig and rigModule then
		self.DancingRigModule = require(rigModule)
		self.IsDancingRigEnabled = self.DancingRigModule ~= nil
	end
end

function TimePlayedTracker:CheckIfMainScript()
	local isAlreadyRunning = ServerStorage:FindFirstChild("TopTimePlayedLeaderboard_Running_Flag")

	if isAlreadyRunning then
		self.IsMainScript = false
	else
		self.IsMainScript = true
		local flag = Instance.new("BoolValue")
		flag.Name = "TopTimePlayedLeaderboard_Running_Flag"
		flag.Value = true
		flag.Parent = ServerStorage
	end
end

function TimePlayedTracker:CheckDataStoreAvailability()
	local success, error = pcall(function()
		DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
	end)

	if not success and (
		string.find(error, "404", 1, true) or
			string.find(error, "403", 1, true) or
			string.find(error, "must publish", 1, true)
		) then
		local flag = Instance.new("BoolValue")
		flag.Value = false
		flag.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
		flag.Parent = ServerStorage
		return false
	end

	self.ApiServicesEnabled = true
	local flag = Instance.new("BoolValue")
	flag.Value = true
	flag.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
	flag.Parent = ServerStorage

	return true
end

function TimePlayedTracker:GetCachedUsername(userId)
	if self.UsernameCache[userId] then
		return self.UsernameCache[userId]
	end

	local success, username = pcall(function()
		return PlayersService:GetNameFromUserIdAsync(userId)
	end)

	if not success then
		if self.DebugEnabled then
			warn("Error al obtener nombre para userId", userId, ":", username)
		end
		return "Nombre no encontrado"
	end

	self.UsernameCache[userId] = username
	return username
end

function TimePlayedTracker:GetCachedThumbnail(userId)
	if self.ThumbnailCache[userId] then
		return self.ThumbnailCache[userId]
	end

	local success, thumbnail = pcall(function()
		return PlayersService:GetUserThumbnailAsync(
			userId, 
			Enum.ThumbnailType.HeadShot, 
			Enum.ThumbnailSize.Size150x150
		)
	end)

	if not success then
		if self.DebugEnabled then
			warn("Error al obtener thumbnail para userId", userId, ":", thumbnail)
		end
		return "rbxassetid://5107154082"
	end

	self.ThumbnailCache[userId] = thumbnail
	return thumbnail
end

function TimePlayedTracker:FormatTime(minutes)
	local totalSeconds = minutes * 60
	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)

	return string.format("%02dd : %02dh : %02dm", days, hours, minutes)
end

-- Inicializar el tracker
TimePlayedTracker.new()