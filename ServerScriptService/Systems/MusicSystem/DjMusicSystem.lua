-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM 
-- by ignxts 
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- Cargar GamepassManager para verificar VIP
local ServerScriptService = game:GetService("ServerScriptService")
local PandaSSS = ServerScriptService:WaitForChild("Panda ServerScriptService")
local Configuration = require(PandaSSS:WaitForChild("Configuration"))
local GamepassManager = require(PandaSSS:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))
local VIP_ID = Configuration.VIP

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local DEV_USER_ID = 8387751399
local DEV_DISPLAY_NAME = "Sistema"
local ASSET_PREFIX = "rbxassetid://"
local DEFAULT_PITCH = 1
local DEFAULT_VOLUME = MusicConfig:GetDefaultVolume() or 0.5

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local musicDatabase = {}
local playQueue = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false
local metadataCache = {}
local playerCooldowns = {}
local isTransitioning = false
local currentPlayingId = nil

-- Response Codes
local RC = {
	SUCCESS = "SUCCESS", INVALID_ID = "ERROR_INVALID_ID", BLACKLISTED = "ERROR_BLACKLISTED",
	DUPLICATE = "ERROR_DUPLICATE", NOT_FOUND = "ERROR_NOT_FOUND", NOT_AUDIO = "ERROR_NOT_AUDIO",
	NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED", QUEUE_FULL = "ERROR_QUEUE_FULL",
	PERMISSION = "ERROR_PERMISSION", COOLDOWN = "ERROR_COOLDOWN", UNKNOWN = "ERROR_UNKNOWN",
	EVENT_LOCKED = "ERROR_EVENT_LOCKED"
}

-- ════════════════════════════════════════════════════════════════
-- REMOTES SETUP
-- ════════════════════════════════════════════════════════════════
local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesGlobal")
if not remotesFolder then warn("RemotesGlobal not found") return end

local function getRemote(folder, name)
	local f = remotesFolder:FindFirstChild(folder)
	return f and f:FindFirstChild(name)
end

local R = {
	Play = getRemote("MusicPlayback", "PlaySong"),
	Pause = getRemote("MusicPlayback", "PauseSong"),
	Next = getRemote("MusicPlayback", "NextSong"),
	Stop = getRemote("MusicPlayback", "StopSong"),
	ChangeVolume = getRemote("MusicPlayback", "ChangeVolume"),
	Update = getRemote("UI", "UpdateUI"),
	AddToQueue = getRemote("MusicQueue", "AddToQueue"),
	AddResponse = getRemote("MusicQueue", "AddToQueueResponse"),
	RemoveFromQueue = getRemote("MusicQueue", "RemoveFromQueue"),
	RemoveResponse = getRemote("MusicQueue", "RemoveFromQueueResponse"),
	ClearQueue = getRemote("MusicQueue", "ClearQueue"),
	ClearResponse = getRemote("MusicQueue", "ClearQueueResponse"),
	PurchaseSkip = getRemote("MusicQueue", "PurchaseSkip"),
	GetDJs = getRemote("MusicLibrary", "GetDJs"),
	GetSongsByDJ = getRemote("MusicLibrary", "GetSongsByDJ"),
	GetSongMetadata = getRemote("MusicLibrary", "GetSongMetadata"),
	SearchSongs = getRemote("MusicLibrary", "SearchSongs"),
	GetSongRange = getRemote("MusicLibrary", "GetSongRange"),
}

-- ════════════════════════════════════════════════════════════════
-- SOUND SETUP
-- ════════════════════════════════════════════════════════════════
local soundObject = workspace:FindFirstChild("QueueSound")
soundObject.Volume = DEFAULT_VOLUME
soundObject.Looped = false

local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup")
if musicSoundGroup then soundObject.SoundGroup = musicSoundGroup end

-- ════════════════════════════════════════════════════════════════
-- PITCH MODULE
-- ════════════════════════════════════════════════════════════════
local pitchLookup = {}

local function loadPitchModule()
	local pitchModuleScript = script.Parent:FindFirstChild("PitchModule")
	if not pitchModuleScript then return end

	local success, pitchModule = pcall(function()
		return require(pitchModuleScript)
	end)

	if not success or type(pitchModule) ~= "table" or not pitchModule.ids then return end

	for _, entry in ipairs(pitchModule.ids) do
		if entry.id and entry.pitch then
			pitchLookup[ASSET_PREFIX .. tostring(entry.id)] = tonumber(entry.pitch) or DEFAULT_PITCH
		end
	end
end

local function applyPitch()
	local pitch = pitchLookup[soundObject.SoundId] or DEFAULT_PITCH
	soundObject.PlaybackSpeed = pitch
end

loadPitchModule()

soundObject:GetPropertyChangedSignal("SoundId"):Connect(function()
	task.delay(0.05, applyPitch)
end)

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function response(code, msg, data)
	return {code = code, success = code == RC.SUCCESS, message = msg, data = data or {}, timestamp = os.time()}
end

local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
end

-- Verificar si una acción está bloqueada en modo evento
local function isActionBlockedByEventMode(action, player)
	-- Obtener estado de GlobalCommandHandler o usar estado local
	local eventActive = _G.EventModeActive or false
	if not eventActive then return false end

	-- Los admins pueden hacer todo incluso en modo evento
	if player and MusicConfig:IsAdmin(player) then return false end

	for _, blockedAction in ipairs(MusicConfig.EVENT_MODE.BlockedActions or {}) do
		if blockedAction == action then return true end
	end
	return false
end

local function isInQueue(audioId)
	if MusicConfig.LIMITS.AllowDuplicatesInQueue then return false end
	for _, s in ipairs(playQueue) do
		if s.id == audioId then return true, s end
	end
	return false
end

local function findDJForSong(audioId)
	for djName, djData in pairs(musicDatabase) do
		for _, id in ipairs(djData.songIds or {}) do
			if id == audioId then return djName, djData.cover end
		end
	end
	return nil, nil
end

local function getAllDJs()
	local list = {}
	for name, data in pairs(musicDatabase) do
		table.insert(list, {name = name, cover = data.cover or "", userId = data.userId, songCount = #(data.songIds or {})})
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

local function fireClient(remote, player, data)
	if remote then pcall(function() remote:FireClient(player, data) end) end
end

local function fireAllClients(remote, message)
	if remote then
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() remote:FireClient(p, message) end)
		end
	end
end

local function updateAllClients()
	if not R.Update then return end
	local currentSong = (#playQueue > 0 and currentSongIndex <= #playQueue) and playQueue[currentSongIndex] or nil
	local packet = {
		queue = playQueue, currentSong = currentSong, djs = getAllDJs(),
		isPlaying = isPlaying, isPaused = isPaused, currentIndex = currentSongIndex,
		queueLength = #playQueue, timestamp = os.time()
	}
	for _, p in ipairs(Players:GetPlayers()) do
		fireClient(R.Update, p, packet)
	end
end

-- Helper: Ajustar índice si excede la cola
local function adjustIndex()
	if currentSongIndex > #playQueue then
		currentSongIndex = 1
	end
end

-- ════════════════════════════════════════════════════════════════
-- AUDIO PERMISSION VALIDATOR
-- ════════════════════════════════════════════════════════════════
local function validateAudioPermission(audioId)
	local testSound = Instance.new("Sound")
	testSound.SoundId = ASSET_PREFIX .. audioId
	testSound.Volume = 0
	testSound.Parent = SoundService

	local canPlay = false
	local checkComplete = false

	local loadedConn
	loadedConn = testSound.Loaded:Connect(function()
		if testSound.TimeLength > 0 then
			canPlay = true
		end
		checkComplete = true
		if loadedConn then loadedConn:Disconnect() end
	end)

	local startTime = tick()
	while not checkComplete and (tick() - startTime) < 5 do
		task.wait(0.1)
		if testSound.IsLoaded and testSound.TimeLength > 0 then
			canPlay = true
			checkComplete = true
		end
	end

	if loadedConn then loadedConn:Disconnect() end
	testSound:Destroy()

	return canPlay
end

-- ════════════════════════════════════════════════════════════════
-- METADATA
-- ════════════════════════════════════════════════════════════════
local function loadMetadataBatch(ids, callback)
	if #ids == 0 then if callback then callback({}) end return end
	local results, pending = {}, #ids
	for _, id in ipairs(ids) do
		if metadataCache[id] and metadataCache[id].loaded then
			results[id] = metadataCache[id]
			pending = pending - 1
			if pending == 0 and callback then callback(results) end
		else
			task.spawn(function()
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)
				metadataCache[id] = ok and info and info.AssetTypeId == 3
					and {name = info.Name or "Audio "..id, artist = (info.Creator and info.Creator.Name) or "Unknown", loaded = true}
					or {name = "Audio "..id, artist = "Unknown", loaded = true, error = true}
				results[id] = metadataCache[id]
				pending = pending - 1
				if pending == 0 and callback then callback(results) end
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- LOAD DJS
-- ════════════════════════════════════════════════════════════════
local function loadDJs()
	musicDatabase = {}
	for name, data in pairs(MusicConfig:GetDJs()) do
		local ids = {}
		for _, id in ipairs(data.SongIds or {}) do
			if type(id) == "number" then table.insert(ids, id) end
		end
		musicDatabase[name] = {cover = data.ImageId or "", userId = data.userId, songIds = ids, songCount = #ids}
	end
end

-- ════════════════════════════════════════════════════════════════
-- PLAYBACK
-- ════════════════════════════════════════════════════════════════

local function cleanupSound()
	pcall(function() soundObject:Stop() end)
	soundObject.SoundId = ""
	soundObject.TimePosition = 0
	currentPlayingId = nil
end

local function stopSong()
	cleanupSound()
	isPlaying = false
	isPaused = false
	isTransitioning = false
	updateAllClients()
end

local function getRandomSongFromLibrary()
	local all = {}
	for djName, djData in pairs(musicDatabase) do
		for _, id in ipairs(djData.songIds or {}) do
			table.insert(all, {id = id, dj = djName, djCover = djData.cover})
		end
	end
	return #all > 0 and all[math.random(#all)] or nil
end

-- Forward declarations
local playSong, nextSong, playRandomSong

-- Helper centralizado: Remover canción actual y continuar
local function removeCurrentAndContinue()
	if currentSongIndex <= #playQueue then
		table.remove(playQueue, currentSongIndex)
	end
	adjustIndex()

	if #playQueue > 0 then
		task.defer(function() playSong(currentSongIndex) end)
	else
		task.defer(playRandomSong)
	end
end

playSong = function(index)
	cleanupSound()
	isTransitioning = false

	if #playQueue == 0 then
		isPlaying = false
		isPaused = false
		updateAllClients()
		task.defer(playRandomSong)
		return
	end

	index = math.clamp(index or currentSongIndex, 1, #playQueue)
	currentSongIndex = index
	local song = playQueue[currentSongIndex]

	-- Si por alguna razón no hay canción (no debería pasar), ir a random
	if not song then
		isPlaying = false
		isPaused = false
		updateAllClients()
		task.defer(playRandomSong)
		return
	end

	currentPlayingId = song.id
	soundObject.Volume = DEFAULT_VOLUME

	task.wait()
	soundObject.SoundId = ASSET_PREFIX .. song.id

	local loaded = false
	local loadConn = nil
	local thisPlayId = song.id

	local function startPlaying()
		if loaded or currentPlayingId ~= thisPlayId then
			if loadConn then loadConn:Disconnect() end
			return
		end

		loaded = true
		if loadConn then loadConn:Disconnect() end

		task.wait(0.15)

		-- Audio sin duración = moderado o inválido
		if soundObject.TimeLength == 0 then
			removeCurrentAndContinue()
			return
		end

		-- Asegurar que empiece desde el inicio
		soundObject.TimePosition = 0
		pcall(function() soundObject:Play() end)

		isPlaying = true
		isPaused = false
		updateAllClients()

		-- Verificar que el audio realmente está avanzando (única verificación)
		task.delay(0.5, function()
			if currentPlayingId == thisPlayId and isPlaying and not isPaused then
				if soundObject.TimePosition < 0.1 then
					-- Reintentar Play()
					pcall(function()
						soundObject:Stop()
						task.wait(0.1)
						soundObject.TimePosition = 0
						soundObject:Play()
					end)

					-- Segunda verificación
					task.delay(0.5, function()
						if currentPlayingId == thisPlayId and isPlaying and not isPaused then
							if soundObject.TimePosition < 0.1 then
								-- Audio definitivamente no funciona, saltar
								nextSong()
							end
						end
					end)
				end
			end
		end)
	end

	loadConn = soundObject.Loaded:Connect(startPlaying)

	-- Verificar si ya está cargado (caché)
	task.defer(function()
		if not loaded and currentPlayingId == thisPlayId then
			local ok, isLoadedNow = pcall(function() return soundObject.IsLoaded end)
			if ok and isLoadedNow then
				startPlaying()
			end
		end
	end)

	-- Timeout de carga (12 segundos)
	task.delay(12, function()
		if not loaded and currentPlayingId == thisPlayId then
			loaded = true
			if loadConn then loadConn:Disconnect() end
			removeCurrentAndContinue()
		end
	end)
end

playRandomSong = function()
	-- Si hay canciones en cola, reproducir desde ahí
	if #playQueue > 0 then
		currentSongIndex = 1
		task.defer(function() playSong(1) end)
		return
	end

	if isTransitioning then return end

	local randomSong = getRandomSongFromLibrary()
	if not randomSong then return end

	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, randomSong.id, Enum.InfoType.Asset)
	local name = (ok and info and info.Name) or "Audio " .. randomSong.id
	local artist = (ok and info and info.Creator and info.Creator.Name) or "Unknown"

	metadataCache[randomSong.id] = {name = name, artist = artist, loaded = true}

	table.insert(playQueue, {
		id = randomSong.id, name = name, artist = artist,
		userId = DEV_USER_ID, requestedBy = DEV_DISPLAY_NAME, addedAt = os.time(),
		dj = randomSong.dj, djCover = randomSong.djCover, isAutoPlay = true
	})

	currentSongIndex = 1
	task.delay(0.3, function() playSong(1) end)
end

nextSong = function()
	if isTransitioning then return end
	isTransitioning = true

	cleanupSound()
	isPlaying = false
	isPaused = false

	if #playQueue == 0 then
		updateAllClients()
		task.delay(0.5, function()
			isTransitioning = false
			playRandomSong()
		end)
		return
	end

	table.remove(playQueue, currentSongIndex)
	adjustIndex()
	updateAllClients()

	if #playQueue == 0 then
		task.delay(0.5, function()
			isTransitioning = false
			playRandomSong()
		end)
	else
		task.delay(0.3, function()
			isTransitioning = false
			playSong(currentSongIndex)
		end)
	end
end

local function removeFromQueue(index)
	if index < 1 or index > #playQueue then return false end
	local removed = table.remove(playQueue, index)

	if index == currentSongIndex then
		if #playQueue == 0 then
			stopSong()
			currentSongIndex = 1
			task.defer(playRandomSong)
		else
			adjustIndex()
			playSong(currentSongIndex)
		end
	elseif index < currentSongIndex then
		currentSongIndex = currentSongIndex - 1
	else
		-- index > currentSongIndex: solo actualizar clientes
		updateAllClients()
	end

	return true, removed.name
end

local function clearQueue()
	if #playQueue == 0 then return false, 0 end
	local count = #playQueue

	if isPlaying and currentSongIndex == 1 then
		playQueue = {playQueue[1]}
		count = count - 1
		updateAllClients()
	else
		playQueue = {}
		currentSongIndex = 1
		stopSong()
		task.defer(playRandomSong)
	end

	return true, count
end

-- ════════════════════════════════════════════════════════════════
-- DETECCIÓN DE FIN DE CANCIÓN (única fuente de verdad)
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(0.4)

		if isPlaying and not isPaused and not isTransitioning then
			local soundId = soundObject.SoundId
			local timeLength = soundObject.TimeLength
			local timePosition = soundObject.TimePosition

			if soundId ~= "" and timeLength > 0 and currentPlayingId then
				local remaining = timeLength - timePosition

				-- Canción por terminar
				if remaining < 0.5 and remaining >= 0 then
					nextSong()
					task.wait(2) -- Evitar doble trigger
				end
			end
		end
	end
end)

-- Backup: evento Ended (solo si polling no lo detectó)
soundObject.Ended:Connect(function()
	if isPlaying and not isTransitioning then
		nextSong()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- LIBRARY HELPERS
-- ════════════════════════════════════════════════════════════════
local function getSongRange(djName, startIdx, endIdx)
	local dj = musicDatabase[djName]
	if not dj then return {songs = {}, total = 0} end
	local ids = dj.songIds or {}
	local total = #ids
	startIdx = math.max(1, startIdx or 1)
	endIdx = math.min(endIdx or startIdx + 19, total)
	local songs, toLoad = {}, {}
	for i = startIdx, endIdx do
		local id = ids[i]
		if id then
			local c = metadataCache[id]
			table.insert(songs, {
				id = id, index = i, loaded = c and c.loaded or false,
				name = c and c.name or "Cargando...",
				artist = c and c.artist or "ID: "..id
			})
			if not (c and c.loaded) then table.insert(toLoad, id) end
		end
	end
	return {songs = songs, total = total, startIndex = startIdx, endIndex = endIdx, hasMore = endIdx < total, idsToLoad = toLoad}
end

local function searchSongs(djName, query, maxResults)
	maxResults = maxResults or 50
	local dj = musicDatabase[djName]
	if not dj then return {songs = {}, total = 0, query = query} end
	local ids = dj.songIds or {}
	local results = {}
	local qLower = string.lower(query or "")
	local qNum = tonumber(query)
	if qNum then
		for i, id in ipairs(ids) do
			if tostring(id):find(tostring(qNum), 1, true) then
				local c = metadataCache[id]
				table.insert(results, {id = id, index = i, loaded = c and c.loaded or false,
					name = c and c.name or "Audio "..id, artist = c and c.artist or "Unknown", matchType = "id"})
				if #results >= maxResults then break end
			end
		end
	end
	if #results < maxResults and qLower ~= "" then
		local seen = {}
		for _, r in ipairs(results) do seen[r.id] = true end
		for i, id in ipairs(ids) do
			if not seen[id] then
				local c = metadataCache[id]
				if c and c.loaded and c.name then
					if string.lower(c.name):find(qLower, 1, true) or string.lower(c.artist or ""):find(qLower, 1, true) then
						table.insert(results, {id = id, index = i, loaded = true, name = c.name, artist = c.artist, matchType = "name"})
						if #results >= maxResults then break end
					end
				end
			end
		end
	end
	return {songs = results, total = #results, query = query, totalInDJ = #ids}
end

-- ════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ════════════════════════════════════════════════════════════════

R.Play.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PlaySong") then return end
	if isPaused then
		pcall(function() soundObject:Resume() end)
		isPaused = false
		isPlaying = true
		updateAllClients()
	elseif #playQueue > 0 then
		playSong(currentSongIndex)
	else
		playRandomSong()
	end
end)

R.Pause.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PauseSong") then return end
	if isPlaying and not isPaused then
		pcall(function() soundObject:Pause() end)
		isPaused = true
		isPlaying = false
		updateAllClients()
	end
end)

R.Next.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "NextSong") then return end
	if isActionBlockedByEventMode("NextSong", player) then return end
	print("SKIP por:", player.Name)
	nextSong()
end)

R.Stop.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "StopSong") then return end
	stopSong()
end)

if R.PurchaseSkip then
	R.PurchaseSkip.OnServerEvent:Connect(function(player)
		print("Skip pagado por:", player.Name)
		nextSong()
	end)
end

if R.ChangeVolume then
	R.ChangeVolume.OnServerEvent:Connect(function(player, vol)
		if type(vol) ~= "number" or not hasPermission(player, "ChangeVolume") then return end
	end)
end

R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	local function send(r) fireClient(R.AddResponse, player, r) end

	if isActionBlockedByEventMode("AddToQueue", player) then
		return send(response(RC.EVENT_LOCKED, "Modo evento activo - No se pueden añadir canciones"))
	end

	if not hasPermission(player, "AddToQueue") then
		return send(response(RC.PERMISSION, "No tienes permiso"))
	end

	local cooldown = MusicConfig.LIMITS.AddToQueueCooldown or 2
	local last = playerCooldowns[player.UserId]
	local now = tick()
	if last and (now - last) < cooldown then
		return send(response(RC.COOLDOWN, "Espera "..math.ceil(cooldown - (now - last)).."s"))
	end
	playerCooldowns[player.UserId] = now

	local id = tonumber(audioId)
	if not id or #tostring(id) < 6 or #tostring(id) > 19 then
		return send(response(RC.INVALID_ID, "ID inválido"))
	end

	local valid, err = MusicConfig:ValidateAudioId(id)
	if not valid then return send(response(RC.BLACKLISTED, err)) end

	local dup, existing = isInQueue(id)
	if dup then return send(response(RC.DUPLICATE, "Ya está en la cola", {songName = existing.name})) end

	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)
	if not ok or not info then return send(response(RC.NOT_FOUND, "Audio no encontrado")) end
	if info.AssetTypeId ~= 3 then return send(response(RC.NOT_AUDIO, "No es audio")) end

	if #playQueue >= MusicConfig.LIMITS.MaxQueueSize then
		return send(response(RC.QUEUE_FULL, "Cola llena ("..#playQueue.."/"..MusicConfig.LIMITS.MaxQueueSize..")"))
	end

	-- VERIFICAR LÍMITE POR ROL
	local isAdmin = MusicConfig:IsAdmin(player)
	local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)
	local maxSongsPerUser

	if isAdmin then
		maxSongsPerUser = MusicConfig.LIMITS.MaxSongsPerUserAdmin
	elseif hasVIP then
		maxSongsPerUser = MusicConfig.LIMITS.MaxSongsPerUserVIP
	else
		maxSongsPerUser = MusicConfig.LIMITS.MaxSongsPerUserNormal
	end

	-- Contar cuántas canciones ha agregado este jugador
	local userSongCount = 0
	for _, song in ipairs(playQueue) do
		if song.userId == player.UserId then
			userSongCount = userSongCount + 1
		end
	end

	if userSongCount >= maxSongsPerUser then
		local roleLabel = isAdmin and "Admin" or (hasVIP and "VIP" or "Normal")
		return send(response(RC.QUEUE_FULL, "Límite de canciones alcanzado ("..userSongCount.."/"..maxSongsPerUser.." como "..roleLabel..")"))
	end

	local canPlay = validateAudioPermission(id)
	if not canPlay then
		return send(response(RC.NOT_AUTHORIZED, "No tienes permisos para usar este audio"))
	end

	local djName, djCover = findDJForSong(id)
	local songInfo = {
		id = id, name = info.Name or "Audio "..id, artist = info.Creator.Name or "Unknown",
		userId = player.UserId, requestedBy = player.Name, addedAt = os.time(),
		dj = djName, djCover = djCover
	}

	metadataCache[id] = {name = songInfo.name, artist = songInfo.artist, loaded = true}
	table.insert(playQueue, songInfo)

	send(response(RC.SUCCESS, "Añadido", {songName = songInfo.name, artist = songInfo.artist, position = #playQueue}))
	updateAllClients()

	if not isPlaying and not isPaused and #playQueue == 1 then
		task.delay(0.3, function() playSong(1) end)
	end
end)

R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	if isActionBlockedByEventMode("RemoveFromQueue", player) then
		return fireClient(R.RemoveResponse, player, response(RC.EVENT_LOCKED, "Modo evento activo - No se pueden eliminar canciones"))
	end
	if not hasPermission(player, "RemoveFromQueue") then
		return fireClient(R.RemoveResponse, player, response(RC.PERMISSION, "Sin permiso"))
	end
	local ok, name = removeFromQueue(index)
	fireClient(R.RemoveResponse, player, ok
		and response(RC.SUCCESS, "Eliminado", {songName = name})
		or response(RC.INVALID_ID, "Índice inválido"))
end)

R.ClearQueue.OnServerEvent:Connect(function(player)
	if isActionBlockedByEventMode("ClearQueue", player) then
		return fireClient(R.ClearResponse, player, response(RC.EVENT_LOCKED, "Modo evento activo - No se puede limpiar la cola"))
	end
	if not hasPermission(player, "ClearQueue") then
		return fireClient(R.ClearResponse, player, response(RC.PERMISSION, "Sin permiso"))
	end
	print("Cola limpiada por:", player.Name)
	local ok, count = clearQueue()
	fireClient(R.ClearResponse, player, ok
		and response(RC.SUCCESS, "Limpiado", {clearedCount = count})
		or response(RC.UNKNOWN, "Cola vacía"))
end)

R.GetDJs.OnServerEvent:Connect(function(player)
	fireClient(R.GetDJs, player, {djs = getAllDJs()})
end)

R.GetSongsByDJ.OnServerEvent:Connect(function(player, djName)
	local dj = musicDatabase[djName]
	fireClient(R.GetSongsByDJ, player, {djName = djName, total = dj and #(dj.songIds or {}) or 0, songs = {}})
end)

R.GetSongRange.OnServerEvent:Connect(function(player, djName, startIdx, endIdx)
	local result = getSongRange(djName, startIdx, endIdx)
	result.djName = djName
	fireClient(R.GetSongRange, player, result)
	if result.idsToLoad and #result.idsToLoad > 0 then
		loadMetadataBatch(result.idsToLoad, function()
			local updated = getSongRange(djName, startIdx, endIdx)
			updated.djName = djName
			updated.isUpdate = true
			fireClient(R.GetSongRange, player, updated)
		end)
	end
end)

R.SearchSongs.OnServerEvent:Connect(function(player, djName, query)
	local result = searchSongs(djName, query)
	result.djName = djName
	fireClient(R.SearchSongs, player, result)
	
	-- ✅ CARGAR METADATA EN BACKGROUND (igual a getSongRange)
	local idsToLoad = {}
	if result.songs then
		for _, song in ipairs(result.songs) do
			if not (metadataCache[song.id] and metadataCache[song.id].loaded) then
				table.insert(idsToLoad, song.id)
			end
		end
	end
	
	if #idsToLoad > 0 then
		loadMetadataBatch(idsToLoad, function(loaded)
			-- Actualizar búsqueda con metadata cargada
			local updatedResult = searchSongs(djName, query)
			updatedResult.djName = djName
			updatedResult.isUpdate = true
			fireClient(R.SearchSongs, player, updatedResult)
		end)
	end
end)

R.GetSongMetadata.OnServerEvent:Connect(function(player, audioIds)
	if type(audioIds) ~= "table" then return end
	local results, toLoad = {}, {}
	for i = 1, math.min(#audioIds, 20) do
		local id = audioIds[i]
		if type(id) == "number" then
			local c = metadataCache[id]
			if c and c.loaded then
				results[id] = c
			else
				table.insert(toLoad, id)
				results[id] = {name = "Cargando...", artist = "ID: "..id, loaded = false}
			end
		end
	end
	fireClient(R.GetSongMetadata, player, {metadata = results, pending = #toLoad})
	if #toLoad > 0 then
		loadMetadataBatch(toLoad, function(loaded)
			fireClient(R.GetSongMetadata, player, {metadata = loaded, pending = 0, isUpdate = true})
		end)
	end
end)

-- ════════════════════════════════════════════════════════════
-- PLAYER EVENTS
-- ════════════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
	task.defer(updateAllClients)
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

-- ════════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════════
loadDJs()

task.delay(1, function()
	updateAllClients()
	if #playQueue == 0 then
		playRandomSong()
	end
end)