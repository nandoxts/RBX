-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM - SERVER SCRIPT (OPTIMIZADO CON BÚSQUEDA)
-- Virtualización + Búsqueda + Carga bajo demanda
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- STATE
local musicDatabase = {}  -- DJ name -> {cover, songIds[]}
local playQueue = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false
local metadataCache = {}  -- Cache de metadata por ID: {name, artist, loaded}

-- RESPONSE CODES
local ResponseCodes = {
	SUCCESS = "SUCCESS",
	ERROR_INVALID_ID = "ERROR_INVALID_ID",
	ERROR_BLACKLISTED = "ERROR_BLACKLISTED",
	ERROR_DUPLICATE = "ERROR_DUPLICATE",
	ERROR_NOT_FOUND = "ERROR_NOT_FOUND",
	ERROR_NOT_AUDIO = "ERROR_NOT_AUDIO",
	ERROR_NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED",
	ERROR_QUEUE_FULL = "ERROR_QUEUE_FULL",
	ERROR_PERMISSION = "ERROR_PERMISSION",
	ERROR_UNKNOWN = "ERROR_UNKNOWN"
}

-- ════════════════════════════════════════════════════════════════
-- REMOTE EVENTS SETUP
-- ════════════════════════════════════════════════════════════════
local remotesFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "MusicRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateFolder(parent, folderName)
	local folder = parent:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end
	return folder
end

local musicPlaybackFolder = getOrCreateFolder(remotesFolder, "MusicPlayback")
local musicQueueFolder = getOrCreateFolder(remotesFolder, "MusicQueue")
local musicLibraryFolder = getOrCreateFolder(remotesFolder, "MusicLibrary")
local uiFolder = getOrCreateFolder(remotesFolder, "UI")

local remotesList = {
	{folder = musicPlaybackFolder, names = {"PlaySong", "PauseSong", "NextSong", "StopSong"}},
	{folder = musicQueueFolder, names = {"AddToQueue", "AddToQueueResponse", "RemoveFromQueue", "RemoveFromQueueResponse", "ClearQueue", "ClearQueueResponse"}},
	{folder = musicLibraryFolder, names = {"GetDJs", "GetSongsByDJ", "GetSongMetadata", "SearchSongs", "GetSongRange"}},
	{folder = uiFolder, names = {"UpdateUI"}}
}

for _, group in ipairs(remotesList) do
	for _, name in ipairs(group.names) do
		if not group.folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = group.folder
		end
	end
end

-- Sound Object
local soundObject = SoundService:FindFirstChild("QueueSound")
if soundObject then soundObject:Destroy() end

soundObject = Instance.new("Sound")
soundObject.Name = "QueueSound"
soundObject.Parent = SoundService
soundObject.Volume = MusicConfig:GetDefaultVolume()
soundObject.Looped = false

-- Get RemoteEvents
local R = {
	Play = musicPlaybackFolder:FindFirstChild("PlaySong"),
	Pause = musicPlaybackFolder:FindFirstChild("PauseSong"),
	Next = musicPlaybackFolder:FindFirstChild("NextSong"),
	Stop = musicPlaybackFolder:FindFirstChild("StopSong"),
	Update = uiFolder:FindFirstChild("UpdateUI"),
	AddToQueue = musicQueueFolder:FindFirstChild("AddToQueue"),
	AddToQueueResponse = musicQueueFolder:FindFirstChild("AddToQueueResponse"),
	RemoveFromQueue = musicQueueFolder:FindFirstChild("RemoveFromQueue"),
	RemoveFromQueueResponse = musicQueueFolder:FindFirstChild("RemoveFromQueueResponse"),
	ClearQueue = musicQueueFolder:FindFirstChild("ClearQueue"),
	ClearQueueResponse = musicQueueFolder:FindFirstChild("ClearQueueResponse"),
	GetDJs = musicLibraryFolder:FindFirstChild("GetDJs"),
	GetSongsByDJ = musicLibraryFolder:FindFirstChild("GetSongsByDJ"),
	GetSongMetadata = musicLibraryFolder:FindFirstChild("GetSongMetadata"),
	SearchSongs = musicLibraryFolder:FindFirstChild("SearchSongs"),
	GetSongRange = musicLibraryFolder:FindFirstChild("GetSongRange"),
}

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function createResponse(code, message, data)
	return {
		code = code,
		success = code == ResponseCodes.SUCCESS,
		message = message,
		data = data or {},
		timestamp = os.time()
	}
end

local function isAudioInQueue(audioId)
	if MusicConfig.LIMITS.AllowDuplicatesInQueue then return false, nil end
	for _, song in ipairs(playQueue) do
		if song.id == audioId then return true, song end
	end
	return false, nil
end

local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
end

-- ════════════════════════════════════════════════════════════════
-- CARGA DE DJS (SOLO IDs)
-- ════════════════════════════════════════════════════════════════
local function loadDJsInstantly()
	musicDatabase = {}
	local djsConfig = MusicConfig:GetDJs()

	for djName, djData in pairs(djsConfig) do
		local songIds = {}
		for _, songId in ipairs(djData.SongIds or {}) do
			if type(songId) == "number" then
				table.insert(songIds, songId)
			end
		end

		musicDatabase[djName] = {
			cover = djData.ImageId or "",
			userId = djData.userId,
			songIds = songIds,
			songCount = #songIds
		}
	end

	print("[MUSIC] DJs cargados:", #musicDatabase > 0 and "OK" or "VACÍO")
end

-- ════════════════════════════════════════════════════════════════
-- METADATA FUNCTIONS (OPTIMIZADO)
-- ════════════════════════════════════════════════════════════════
local metadataLoadQueue = {}
local isLoadingMetadata = false

-- Cargar metadata de un batch de IDs
local function loadMetadataBatch(ids, callback)
	local results = {}
	local pending = #ids

	if pending == 0 then
		if callback then callback({}) end
		return
	end

	for _, id in ipairs(ids) do
		-- Si ya está en cache, usar cache
		if metadataCache[id] and metadataCache[id].loaded then
			results[id] = metadataCache[id]
			pending = pending - 1
			if pending == 0 and callback then
				callback(results)
			end
		else
			-- Cargar desde MarketplaceService
			task.spawn(function()
				local success, info = pcall(function()
					return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
				end)

				if success and info and info.AssetTypeId == 3 then
					metadataCache[id] = {
						name = info.Name or ("Audio " .. id),
						artist = (info.Creator and info.Creator.Name) or "Unknown",
						loaded = true
					}
				else
					metadataCache[id] = {
						name = "Audio " .. id,
						artist = "Unknown",
						loaded = true,
						error = true
					}
				end

				results[id] = metadataCache[id]
				pending = pending - 1

				if pending == 0 and callback then
					callback(results)
				end
			end)
		end
	end
end

-- Obtener metadata (sync si está en cache, placeholder si no)
local function getMetadataForId(audioId, forceLoad)
	if metadataCache[audioId] and metadataCache[audioId].loaded then
		return metadataCache[audioId]
	end

	-- Retornar placeholder inmediato
	local placeholder = {
		name = "Cargando...",
		artist = "ID: " .. audioId,
		loaded = false
	}

	if forceLoad then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(audioId, Enum.InfoType.Asset)
		end)

		if success and info and info.AssetTypeId == 3 then
			metadataCache[audioId] = {
				name = info.Name or ("Audio " .. audioId),
				artist = (info.Creator and info.Creator.Name) or "Unknown",
				loaded = true
			}
			return metadataCache[audioId]
		end
	end

	return placeholder
end

-- ════════════════════════════════════════════════════════════════
-- OBTENER LISTA DE DJS (INSTANTÁNEO)
-- ════════════════════════════════════════════════════════════════
local function getAllDJs()
	local djsList = {}

	for djName, djData in pairs(musicDatabase) do
		table.insert(djsList, {
			name = djName,
			cover = djData.cover or "",
			userId = djData.userId,
			songCount = djData.songCount or #(djData.songIds or {})
		})
	end

	table.sort(djsList, function(a, b) return a.name < b.name end)
	return djsList
end

-- ════════════════════════════════════════════════════════════════
-- OBTENER RANGO DE CANCIONES (PARA VIRTUALIZACIÓN)
-- ════════════════════════════════════════════════════════════════
local function getSongRange(djName, startIndex, endIndex, loadMetadata)
	if not musicDatabase[djName] then
		return {songs = {}, total = 0}
	end

	local allIds = musicDatabase[djName].songIds or {}
	local total = #allIds

	startIndex = math.max(1, startIndex or 1)
	endIndex = math.min(endIndex or (startIndex + 19), total)

	local songs = {}
	local idsToLoad = {}

	for i = startIndex, endIndex do
		local id = allIds[i]
		if id then
			local cached = metadataCache[id]
			if cached and cached.loaded then
				table.insert(songs, {
					id = id,
					name = cached.name,
					artist = cached.artist,
					index = i,
					loaded = true
				})
			else
				-- Placeholder mientras carga
				table.insert(songs, {
					id = id,
					name = "Cargando...",
					artist = "ID: " .. id,
					index = i,
					loaded = false
				})
				if loadMetadata then
					table.insert(idsToLoad, id)
				end
			end
		end
	end

	return {
		songs = songs,
		total = total,
		startIndex = startIndex,
		endIndex = endIndex,
		hasMore = endIndex < total,
		idsToLoad = idsToLoad
	}
end

-- ════════════════════════════════════════════════════════════════
-- BÚSQUEDA DE CANCIONES
-- ════════════════════════════════════════════════════════════════
local function searchSongs(djName, query, maxResults)
	maxResults = maxResults or 50

	if not musicDatabase[djName] then
		return {songs = {}, total = 0, query = query}
	end

	local allIds = musicDatabase[djName].songIds or {}
	local results = {}
	local queryLower = string.lower(query or "")
	local queryNumber = tonumber(query)

	-- Si la query es un número, buscar por ID primero
	if queryNumber then
		for i, id in ipairs(allIds) do
			if tostring(id):find(tostring(queryNumber), 1, true) then
				local cached = metadataCache[id]
				table.insert(results, {
					id = id,
					name = cached and cached.name or ("Audio " .. id),
					artist = cached and cached.artist or "Unknown",
					index = i,
					loaded = cached and cached.loaded or false,
					matchType = "id"
				})
				if #results >= maxResults then break end
			end
		end
	end

	-- Buscar por nombre en cache
	if #results < maxResults and queryLower ~= "" then
		for i, id in ipairs(allIds) do
			local cached = metadataCache[id]
			if cached and cached.loaded and cached.name then
				local nameLower = string.lower(cached.name)
				local artistLower = string.lower(cached.artist or "")

				if nameLower:find(queryLower, 1, true) or artistLower:find(queryLower, 1, true) then
					-- Evitar duplicados
					local isDupe = false
					for _, r in ipairs(results) do
						if r.id == id then isDupe = true break end
					end

					if not isDupe then
						table.insert(results, {
							id = id,
							name = cached.name,
							artist = cached.artist,
							index = i,
							loaded = true,
							matchType = "name"
						})
						if #results >= maxResults then break end
					end
				end
			end
		end
	end

	return {
		songs = results,
		total = #results,
		query = query,
		totalInDJ = #allIds,
		cachedCount = 0 -- Se calculará abajo
	}
end

-- Contar cuántas canciones tienen metadata cacheada
local function getCachedCount(djName)
	if not musicDatabase[djName] then return 0 end

	local count = 0
	for _, id in ipairs(musicDatabase[djName].songIds or {}) do
		if metadataCache[id] and metadataCache[id].loaded then
			count = count + 1
		end
	end
	return count
end

-- ════════════════════════════════════════════════════════════════
-- PLAYBACK FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function getCurrentSong()
	if #playQueue > 0 and currentSongIndex >= 1 and currentSongIndex <= #playQueue then
		return playQueue[currentSongIndex]
	end
	return nil
end

local updateAllClients

local function playSong(index)
	if #playQueue == 0 then
		isPlaying = false
		soundObject:Stop()
		return
	end

	index = index or currentSongIndex
	if index < 1 or index > #playQueue then return end

	currentSongIndex = index
	local song = playQueue[currentSongIndex]

	soundObject.SoundId = "rbxassetid://" .. song.id
	soundObject:Play()
	isPlaying = true
	isPaused = false

	soundObject.Volume = 0
	task.spawn(function()
		for i = 1, 10 do
			soundObject.Volume = i * 0.1
			task.wait(0.05)
		end
	end)

	updateAllClients()
end

local function nextSong()
	if #playQueue == 0 then
		isPlaying = false
		soundObject:Stop()
		updateAllClients()
		return
	end

	table.remove(playQueue, currentSongIndex)

	if #playQueue == 0 then
		currentSongIndex = 1
		isPlaying = false
		soundObject:Stop()
	else
		if currentSongIndex > #playQueue then currentSongIndex = 1 end
		playSong(currentSongIndex)
	end

	updateAllClients()
end

local function stopSong()
	soundObject:Stop()
	isPlaying = false
	isPaused = false
	updateAllClients()
end

local function removeFromQueue(index)
	if index < 1 or index > #playQueue then return false, "Invalid" end

	local removedSong = table.remove(playQueue, index)

	if index == currentSongIndex then
		if #playQueue == 0 then
			stopSong()
			currentSongIndex = 1
		else
			if currentSongIndex > #playQueue then currentSongIndex = 1 end
			playSong(currentSongIndex)
		end
	elseif index < currentSongIndex then
		currentSongIndex = currentSongIndex - 1
	end

	updateAllClients()
	return true, removedSong.name
end

local function clearQueue()
	if #playQueue > 0 then
		local clearedCount = #playQueue
		if isPlaying and currentSongIndex == 1 then
			local currentSongData = playQueue[1]
			playQueue = {currentSongData}
			currentSongIndex = 1
			clearedCount = clearedCount - 1
		else
			playQueue = {}
			currentSongIndex = 1
			stopSong()
		end
		updateAllClients()
		return true, clearedCount
	end
	return false, 0
end

-- ════════════════════════════════════════════════════════════════
-- BROADCAST
-- ════════════════════════════════════════════════════════════════
function updateAllClients()
	if R.Update then
		local djs = getAllDJs()
		local dataPacket = {
			queue = playQueue,
			currentSong = getCurrentSong(),
			djs = djs,
			isPlaying = isPlaying,
			isPaused = isPaused
		}

		for _, player in ipairs(Players:GetPlayers()) do
			R.Update:FireClient(player, dataPacket)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SERVER EVENTS - PLAYBACK
-- ════════════════════════════════════════════════════════════════
R.Play.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PlaySong") then return end
	if isPaused then
		soundObject:Resume()
		isPaused = false
		isPlaying = true
		updateAllClients()
	else
		playSong(1)
	end
end)

R.Pause.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PauseSong") then return end
	if isPlaying and not isPaused then
		soundObject:Pause()
		isPaused = true
		isPlaying = false
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

-- ════════════════════════════════════════════════════════════════
-- ADD TO QUEUE
-- ════════════════════════════════════════════════════════════════
R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	local function sendResponse(response)
		if R.AddToQueueResponse then
			R.AddToQueueResponse:FireClient(player, response)
		end
	end

	if not hasPermission(player, "AddToQueue") then
		sendResponse(createResponse(ResponseCodes.ERROR_PERMISSION, "No tienes permiso"))
		return
	end

	local id = tonumber(audioId)
	if not id or #tostring(id) < 6 or #tostring(id) > 19 then
		sendResponse(createResponse(ResponseCodes.ERROR_INVALID_ID, "ID inválido"))
		return
	end

	local valid, validationError = MusicConfig:ValidateAudioId(id)
	if not valid then
		sendResponse(createResponse(ResponseCodes.ERROR_BLACKLISTED, validationError))
		return
	end

	local isDuplicate, existingSong = isAudioInQueue(id)
	if isDuplicate then
		sendResponse(createResponse(ResponseCodes.ERROR_DUPLICATE, "Ya está en la cola", {songName = existingSong.name}))
		return
	end

	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	end)

	if not success or not result then
		sendResponse(createResponse(ResponseCodes.ERROR_NOT_FOUND, "Audio no encontrado"))
		return
	end

	if result.AssetTypeId ~= 3 then
		sendResponse(createResponse(ResponseCodes.ERROR_NOT_AUDIO, "No es audio"))
		return
	end

	if #playQueue >= MusicConfig.LIMITS.MaxQueueSize then
		sendResponse(createResponse(ResponseCodes.ERROR_QUEUE_FULL, "Cola llena"))
		return
	end

	local tempSound = Instance.new("Sound")
	tempSound.SoundId = "rbxassetid://" .. id
	tempSound.Parent = workspace

	local finished = false

	tempSound.Loaded:Connect(function()
		if finished then return end
		finished = true
		tempSound:Destroy()

		local songInfo = {
			id = id,
			name = result.Name or ("Audio " .. id),
			artist = result.Creator.Name or "Unknown",
			userId = player.UserId,
			requestedBy = player.Name,
			addedAt = os.time()
		}

		metadataCache[id] = {name = songInfo.name, artist = songInfo.artist, loaded = true}

		table.insert(playQueue, songInfo)

		sendResponse(createResponse(ResponseCodes.SUCCESS, "Añadido", {
			songName = songInfo.name,
			artist = songInfo.artist,
			position = #playQueue
		}))

		updateAllClients()

		if not isPlaying and not isPaused and #playQueue == 1 then
			task.delay(0.3, function() playSong(1) end)
		end
	end)

	task.delay(3, function()
		if not finished then
			finished = true
			tempSound:Destroy()
			sendResponse(createResponse(ResponseCodes.ERROR_NOT_AUTHORIZED, "Sin permiso para este audio"))
		end
	end)

	pcall(function() tempSound:LoadAsync() end)
end)

-- ════════════════════════════════════════════════════════════════
-- REMOVE/CLEAR QUEUE
-- ════════════════════════════════════════════════════════════════
R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	local function sendResponse(response)
		if R.RemoveFromQueueResponse then
			R.RemoveFromQueueResponse:FireClient(player, response)
		end
	end

	if not hasPermission(player, "RemoveFromQueue") then
		sendResponse(createResponse(ResponseCodes.ERROR_PERMISSION, "Sin permiso"))
		return
	end

	local success, songName = removeFromQueue(index)
	if success then
		sendResponse(createResponse(ResponseCodes.SUCCESS, "Eliminado", {songName = songName}))
	else
		sendResponse(createResponse(ResponseCodes.ERROR_INVALID_ID, "Índice inválido"))
	end
end)

R.ClearQueue.OnServerEvent:Connect(function(player)
	local function sendResponse(response)
		if R.ClearQueueResponse then
			R.ClearQueueResponse:FireClient(player, response)
		end
	end

	if not hasPermission(player, "ClearQueue") then
		sendResponse(createResponse(ResponseCodes.ERROR_PERMISSION, "Sin permiso"))
		return
	end

	local success, clearedCount = clearQueue()
	if success then
		sendResponse(createResponse(ResponseCodes.SUCCESS, "Limpiado", {clearedCount = clearedCount}))
	else
		sendResponse(createResponse(ResponseCodes.ERROR_UNKNOWN, "Cola vacía"))
	end
end)

-- ════════════════════════════════════════════════════════════════
-- LIBRARY EVENTS (OPTIMIZADOS)
-- ════════════════════════════════════════════════════════════════
R.GetDJs.OnServerEvent:Connect(function(player)
	local djs = getAllDJs()
	R.GetDJs:FireClient(player, {djs = djs})
end)

-- OBTENER INFO INICIAL DEL DJ (sin cargar metadata)
R.GetSongsByDJ.OnServerEvent:Connect(function(player, djName)
	if not musicDatabase[djName] then
		R.GetSongsByDJ:FireClient(player, {
			djName = djName,
			total = 0,
			songs = {},
			cachedCount = 0
		})
		return
	end

	local djData = musicDatabase[djName]
	local total = #(djData.songIds or {})
	local cachedCount = getCachedCount(djName)

	-- Enviar solo la info inicial, sin canciones
	R.GetSongsByDJ:FireClient(player, {
		djName = djName,
		total = total,
		cachedCount = cachedCount,
		songs = {} -- El cliente pedirá rangos específicos
	})
end)

-- OBTENER RANGO DE CANCIONES (PARA SCROLL VIRTUAL)
R.GetSongRange.OnServerEvent:Connect(function(player, djName, startIndex, endIndex)
	local result = getSongRange(djName, startIndex, endIndex, true)
	result.djName = djName

	-- Si hay IDs para cargar, cargarlos y enviar actualización
	if result.idsToLoad and #result.idsToLoad > 0 then
		-- Primero enviar con placeholders
		R.GetSongRange:FireClient(player, result)

		-- Luego cargar metadata y enviar actualización
		loadMetadataBatch(result.idsToLoad, function(metadata)
			-- Re-obtener el rango con metadata cargada
			local updatedResult = getSongRange(djName, startIndex, endIndex, false)
			updatedResult.djName = djName
			updatedResult.isUpdate = true
			R.GetSongRange:FireClient(player, updatedResult)
		end)
	else
		R.GetSongRange:FireClient(player, result)
	end
end)

-- BÚSQUEDA DE CANCIONES
R.SearchSongs.OnServerEvent:Connect(function(player, djName, query)
	local result = searchSongs(djName, query, 50)
	result.djName = djName
	result.cachedCount = getCachedCount(djName)
	R.SearchSongs:FireClient(player, result)
end)

-- OBTENER METADATA DE IDs ESPECÍFICOS
R.GetSongMetadata.OnServerEvent:Connect(function(player, audioIds)
	if type(audioIds) ~= "table" then return end

	local results = {}
	local idsToLoad = {}

	-- Primero enviar lo que ya está en cache
	for i = 1, math.min(#audioIds, 20) do
		local id = audioIds[i]
		if type(id) == "number" then
			if metadataCache[id] and metadataCache[id].loaded then
				results[id] = metadataCache[id]
			else
				table.insert(idsToLoad, id)
				results[id] = {name = "Cargando...", artist = "ID: " .. id, loaded = false}
			end
		end
	end

	-- Enviar respuesta inmediata
	R.GetSongMetadata:FireClient(player, {metadata = results, pending = #idsToLoad})

	-- Si hay IDs por cargar, cargarlos y enviar actualización
	if #idsToLoad > 0 then
		loadMetadataBatch(idsToLoad, function(loadedMetadata)
			R.GetSongMetadata:FireClient(player, {
				metadata = loadedMetadata,
				pending = 0,
				isUpdate = true
			})
		end)
	end
end)

-- ════════════════════════════════════════════════════════════════
-- AUTO EVENTS
-- ════════════════════════════════════════════════════════════════
soundObject.Ended:Connect(function()
	if isPlaying then
		task.spawn(function()
			for i = 10, 1, -1 do
				soundObject.Volume = i * 0.1
				task.wait(0.03)
			end
		end)
		task.wait(0.5)
		nextSong()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- PLAYER EVENTS
-- ════════════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		if R.Update then
			local djs = getAllDJs()
			R.Update:FireClient(player, {
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				isPlaying = isPlaying,
				isPaused = isPaused
			})
		end
	end)
end)

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
loadDJsInstantly()
task.defer(updateAllClients)