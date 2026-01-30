-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM - SERVER SCRIPT (OPTIMIZADO)
-- by ignxts - Versión reducida con validación de reproducción
-- CORREGIDO: Forward declaration para playRandomSong
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local DEV_USER_ID = 8387751399
local DEV_DISPLAY_NAME = "Sistema"
local MAX_RETRY_ATTEMPTS = 5 -- Intentos máximos si una canción falla

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local musicDatabase = {}
local playQueue = {}
local currentSongIndex = 1
local isPlaying, isPaused, isTransitioning = false, false, false
local metadataCache = {}
local playerCooldowns = {}
local currentPlaybackId = 0

-- Response Codes (simplificado)
local RC = {
	SUCCESS = "SUCCESS", INVALID_ID = "ERROR_INVALID_ID", BLACKLISTED = "ERROR_BLACKLISTED",
	DUPLICATE = "ERROR_DUPLICATE", NOT_FOUND = "ERROR_NOT_FOUND", NOT_AUDIO = "ERROR_NOT_AUDIO",
	NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED", QUEUE_FULL = "ERROR_QUEUE_FULL",
	PERMISSION = "ERROR_PERMISSION", COOLDOWN = "ERROR_COOLDOWN", UNKNOWN = "ERROR_UNKNOWN"
}

-- ════════════════════════════════════════════════════════════════
-- REMOTES SETUP
-- ════════════════════════════════════════════════════════════════
local remotesFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remotesFolder then warn("[DjMusicSystem] MusicRemotes not found") return end

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
local soundObject = SoundService:FindFirstChild("QueueSound")
if soundObject then soundObject:Destroy() end

soundObject = Instance.new("Sound")
soundObject.Name = "QueueSound"
soundObject.Volume = MusicConfig:GetDefaultVolume()
soundObject.Looped = false
soundObject.Parent = SoundService

local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup")
if musicSoundGroup then soundObject.SoundGroup = musicSoundGroup end

-- Pitch lookup
local pitchLookup = {}
do
	local ok, pm = pcall(function()
		return require(script.Parent:FindFirstChild("PitchModule"))
	end)
	if ok and pm and pm.ids then
		for _, e in ipairs(pm.ids) do
			if e.id then
				local d = tostring(e.id):match("(%d+)")
				if d then pitchLookup[d] = tonumber(e.speed) or tonumber(e.pitch) or 1 end
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function response(code, msg, data)
	return {code = code, success = code == RC.SUCCESS, message = msg, data = data or {}, timestamp = os.time()}
end

local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
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

-- ════════════════════════════════════════════════════════════════
-- METADATA
-- ════════════════════════════════════════════════════════════════
local function loadMetadataBatch(ids, callback)
	if #ids == 0 then if callback then callback({}) end return end

	local results, pending = {}, #ids
	for _, id in ipairs(ids) do
		if metadataCache[id] and metadataCache[id].loaded then
			results[id] = metadataCache[id]
			pending -= 1
			if pending == 0 and callback then callback(results) end
		else
			task.spawn(function()
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)
				metadataCache[id] = ok and info and info.AssetTypeId == 3
					and {name = info.Name or "Audio "..id, artist = (info.Creator and info.Creator.Name) or "Unknown", loaded = true}
					or {name = "Audio "..id, artist = "Unknown", loaded = true, error = true}
				results[id] = metadataCache[id]
				pending -= 1
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
-- VALIDACIÓN DE AUDIO
-- ════════════════════════════════════════════════════════════════
local function validateAudioId(audioId, timeout)
	timeout = timeout or 3
	local tempSound = Instance.new("Sound")
	tempSound.Parent = workspace

	local loaded, valid = false, false
	local conn
	conn = tempSound.Loaded:Connect(function()
		loaded = true
		valid = true
		if conn then conn:Disconnect() end
	end)

	tempSound.SoundId = "rbxassetid://" .. audioId

	-- Verificar si ya está cargado (caché)
	task.defer(function()
		local ok, isLoaded = pcall(function() return tempSound.IsLoaded end)
		if ok and isLoaded then loaded, valid = true, true end
	end)

	-- Esperar con timeout
	local startTime = tick()
	while not loaded and (tick() - startTime) < timeout do
		task.wait(0.1)
	end

	pcall(function() tempSound:Destroy() end)
	return valid
end

-- ════════════════════════════════════════════════════════════════
-- PLAYBACK (CON VALIDACIÓN Y RETRY)
-- ════════════════════════════════════════════════════════════════

-- ⚠️ FORWARD DECLARATIONS - Resolver dependencias circulares
local playRandomSong
local playSong
local nextSong

local function stopSong()
	isTransitioning = false
	currentPlaybackId += 1
	pcall(function() soundObject:Stop() end)
	isPlaying, isPaused = false, false
	updateAllClients()
end

local function getRandomSongFromLibrary(excludeIds)
	excludeIds = excludeIds or {}
	local all = {}
	for djName, djData in pairs(musicDatabase) do
		for _, id in ipairs(djData.songIds or {}) do
			if not excludeIds[id] then
				table.insert(all, {id = id, dj = djName, djCover = djData.cover})
			end
		end
	end
	return #all > 0 and all[math.random(#all)] or nil
end

-- Implementación de playSong (ahora como asignación)
playSong = function(index, retryCount, failedIds)
	if isTransitioning then return end
	isTransitioning = true
	retryCount = retryCount or 0
	failedIds = failedIds or {}

	currentPlaybackId += 1
	local myPlaybackId = currentPlaybackId

	pcall(function() soundObject:Stop() end)

	if #playQueue == 0 then
		isPlaying, isPaused, isTransitioning = false, false, false
		updateAllClients()
		return
	end

	index = math.clamp(index or currentSongIndex, 1, #playQueue)
	currentSongIndex = index
	local song = playQueue[currentSongIndex]

	-- Configurar sonido
	soundObject.Volume = 0
	soundObject.SoundId = "rbxassetid://" .. song.id
	soundObject.PlaybackSpeed = pitchLookup[tostring(song.id):match("(%d+)")] or 1

	local hasStarted = false
	local function startPlayback()
		if myPlaybackId ~= currentPlaybackId or hasStarted then return end
		hasStarted = true

		local ok = pcall(function() soundObject:Play() end)
		if ok then
			isPlaying, isPaused = true, false
			TweenService:Create(soundObject, TweenInfo.new(0.3), {Volume = MusicConfig:GetDefaultVolume()}):Play()
		else
			isPlaying = false
		end
		isTransitioning = false
		updateAllClients()
	end

	local function handleFailure()
		if hasStarted then return end
		hasStarted = true
		isTransitioning = false

		warn("[DjMusicSystem] Audio inválido o sin permiso:", song.id)
		failedIds[song.id] = true

		-- Remover de la cola
		table.remove(playQueue, currentSongIndex)

		if retryCount < MAX_RETRY_ATTEMPTS then
			if #playQueue > 0 then
				-- Intentar la siguiente en cola
				if currentSongIndex > #playQueue then currentSongIndex = 1 end
				task.defer(function() playSong(currentSongIndex, retryCount + 1, failedIds) end)
			else
				-- Cola vacía, buscar aleatoria
				task.defer(function() playRandomSong(retryCount + 1, failedIds) end)
			end
		else
			warn("[DjMusicSystem] Máximo de reintentos alcanzado")
			stopSong()
		end
	end

	-- Verificar si ya está cargado
	local ok, loaded = pcall(function() return soundObject.IsLoaded end)
	if ok and loaded then
		startPlayback()
	else
		local conn
		conn = soundObject.Loaded:Connect(function()
			if conn then conn:Disconnect() conn = nil end
			startPlayback()
		end)

		-- Timeout - si no carga, es inválido
		task.delay(4, function()
			if not hasStarted and myPlaybackId == currentPlaybackId then
				if conn then conn:Disconnect() conn = nil end
				handleFailure()
			end
		end)
	end
end

-- Implementación de playRandomSong (ahora como asignación)
playRandomSong = function(retryCount, failedIds)
	retryCount = retryCount or 0
	failedIds = failedIds or {}

	if #playQueue > 0 or isPlaying then return end
	if retryCount >= MAX_RETRY_ATTEMPTS then
		warn("[DjMusicSystem] No se encontró canción válida después de", retryCount, "intentos")
		return
	end

	local randomSong = getRandomSongFromLibrary(failedIds)
	if not randomSong then
		warn("[DjMusicSystem] No hay canciones disponibles")
		return
	end

	-- Obtener metadata
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, randomSong.id, Enum.InfoType.Asset)
	local name = (ok and info and info.Name) or "Audio " .. randomSong.id
	local artist = (ok and info and info.Creator and info.Creator.Name) or "Unknown"

	metadataCache[randomSong.id] = {name = name, artist = artist, loaded = true}

	table.insert(playQueue, {
		id = randomSong.id, name = name, artist = artist,
		userId = DEV_USER_ID, requestedBy = DEV_DISPLAY_NAME, addedAt = os.time(),
		dj = randomSong.dj, djCover = randomSong.djCover, isAutoPlay = true
	})

	task.delay(0.2, function() playSong(1, retryCount, failedIds) end)
end

-- Implementación de nextSong (ahora como asignación)
nextSong = function()
	if isTransitioning then return end

	if #playQueue == 0 then
		stopSong()
		task.delay(0.5, playRandomSong)
		return
	end

	table.remove(playQueue, currentSongIndex)

	if #playQueue == 0 then
		currentSongIndex = 1
		stopSong()
		task.delay(0.5, playRandomSong)
	else
		if currentSongIndex > #playQueue then currentSongIndex = 1 end
		playSong(currentSongIndex)
	end
end

local function removeFromQueue(index)
	if index < 1 or index > #playQueue then return false end
	local removed = table.remove(playQueue, index)

	if index == currentSongIndex then
		if #playQueue == 0 then
			stopSong()
			currentSongIndex = 1
		else
			if currentSongIndex > #playQueue then currentSongIndex = 1 end
			playSong(currentSongIndex)
		end
	elseif index < currentSongIndex then
		currentSongIndex -= 1
	end

	updateAllClients()
	return true, removed.name
end

local function clearQueue()
	if #playQueue == 0 then return false, 0 end
	local count = #playQueue

	if isPlaying and currentSongIndex == 1 then
		playQueue = {playQueue[1]}
		count -= 1
	else
		playQueue = {}
		currentSongIndex = 1
		stopSong()
	end

	updateAllClients()
	return true, count
end

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

	-- Buscar por ID
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

	-- Buscar por nombre
	if #results < maxResults and qLower ~= "" then
		local seen = {}
		for _, r in ipairs(results) do seen[r.id] = true end

		for i, id in ipairs(ids) do
			if not seen[id] then
				local c = metadataCache[id]
				if c and c.loaded and c.name then
					if string.lower(c.name):find(qLower, 1, true) or string.lower(c.artist or ""):find(qLower, 1, true) then
						table.insert(results, {id = id, index = i, loaded = true,
							name = c.name, artist = c.artist, matchType = "name"})
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

-- Playback
R.Play.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PlaySong") then return end
	if isPaused then
		pcall(function() soundObject:Resume() end)
		isPaused, isPlaying = false, true
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
		isPaused, isPlaying = true, false
		updateAllClients()
	end
end)

R.Next.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "NextSong") then return end
	nextSong()
end)

R.Stop.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "StopSong") then return end
	stopSong()
end)

if R.PurchaseSkip then
	R.PurchaseSkip.OnServerEvent:Connect(function(player)
		print("[DjMusicSystem] Skip pagado por:", player.Name)
		nextSong()
	end)
end

if R.ChangeVolume then
	R.ChangeVolume.OnServerEvent:Connect(function(player, vol)
		if type(vol) ~= "number" or not hasPermission(player, "ChangeVolume") then return end
		soundObject.Volume = math.clamp(vol, 0, 1)
	end)
end

-- Queue
R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	local function send(r) fireClient(R.AddResponse, player, r) end

	if not hasPermission(player, "AddToQueue") then
		return send(response(RC.PERMISSION, "No tienes permiso"))
	end

	-- Cooldown
	local cooldown = MusicConfig.LIMITS.AddToQueueCooldown or 2
	local last = playerCooldowns[player.UserId]
	local now = tick()
	if last and (now - last) < cooldown then
		return send(response(RC.COOLDOWN, "Espera "..math.ceil(cooldown - (now - last)).."s"))
	end
	playerCooldowns[player.UserId] = now

	-- Validaciones
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

	-- Validar que se puede cargar
	local tempSound = Instance.new("Sound")
	tempSound.Parent = workspace

	local finished = false
	local function onLoaded()
		if finished then return end
		finished = true
		pcall(function() tempSound:Destroy() end)

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
	end

	tempSound.Loaded:Connect(onLoaded)
	tempSound.SoundId = "rbxassetid://" .. id

	task.defer(function()
		local loadOk, loaded = pcall(function() return tempSound.IsLoaded end)
		if loadOk and loaded and not finished then onLoaded() end
	end)

	task.delay(5, function()
		if not finished then
			finished = true
			pcall(function() tempSound:Destroy() end)
			send(response(RC.NOT_AUTHORIZED, "Sin permiso para este audio"))
		end
	end)
end)

R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	if not hasPermission(player, "RemoveFromQueue") then
		return fireClient(R.RemoveResponse, player, response(RC.PERMISSION, "Sin permiso"))
	end
	local ok, name = removeFromQueue(index)
	fireClient(R.RemoveResponse, player, ok
		and response(RC.SUCCESS, "Eliminado", {songName = name})
		or response(RC.INVALID_ID, "Índice inválido"))
end)

R.ClearQueue.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "ClearQueue") then
		return fireClient(R.ClearResponse, player, response(RC.PERMISSION, "Sin permiso"))
	end
	local ok, count = clearQueue()
	fireClient(R.ClearResponse, player, ok
		and response(RC.SUCCESS, "Limpiado", {clearedCount = count})
		or response(RC.UNKNOWN, "Cola vacía"))
end)

-- Library
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

-- ════════════════════════════════════════════════════════════════
-- AUTO EVENTS
-- ════════════════════════════════════════════════════════════════
soundObject.Ended:Connect(function()
	if not isPlaying and not isPaused then return end
	local pos, len = soundObject.TimePosition, soundObject.TimeLength
	if len > 0 and (pos >= len - 0.5 or pos == 0) then
		task.defer(nextSong)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.defer(function() updateAllClients() end)
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
	if #playQueue == 0 then playRandomSong() end
end)