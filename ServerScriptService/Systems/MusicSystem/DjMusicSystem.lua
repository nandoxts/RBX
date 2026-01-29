-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM - SERVER SCRIPT (ULTRA OPTIMIZADO)
-- Carga instantánea + Paginación de canciones
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- STATE
local musicDatabase = {}  -- DJ name -> {cover, songIds[]} (solo IDs, sin metadata)
local playQueue = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false
local metadataCache = {}  -- Cache de metadata por ID

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
	{folder = musicLibraryFolder, names = {"GetDJs", "GetSongsByDJ", "GetSongMetadata"}},
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
-- CARGA INSTANTÁNEA DE DJS (SOLO IDs, SIN METADATA)
-- ════════════════════════════════════════════════════════════════
local function loadDJsInstantly()
	musicDatabase = {}
	local djsConfig = MusicConfig:GetDJs()

	for djName, djData in pairs(djsConfig) do
		-- Solo guardamos los IDs, nada más
		local songIds = {}
		for _, songId in ipairs(djData.SongIds or {}) do
			if type(songId) == "number" then
				table.insert(songIds, songId)
			end
		end

		musicDatabase[djName] = {
			cover = djData.ImageId or "",
			userId = djData.userId,
			songIds = songIds,  -- Solo array de IDs
			songCount = #songIds
		}
	end

	print("[MUSIC] DJs cargados:", #musicDatabase > 0 and "OK" or "VACÍO")
end

-- ════════════════════════════════════════════════════════════════
-- OBTENER METADATA (SOLO CUANDO SE NECESITA)
-- ════════════════════════════════════════════════════════════════
local function getMetadataForId(audioId)
	if metadataCache[audioId] then
		return metadataCache[audioId]
	end

	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(audioId, Enum.InfoType.Asset)
	end)

	if success and info and info.AssetTypeId == 3 then
		local metadata = {
			name = info.Name or ("Audio " .. audioId),
			artist = (info.Creator and info.Creator.Name) or "Unknown"
		}
		metadataCache[audioId] = metadata
		return metadata
	end

	return {name = "Audio " .. audioId, artist = "Unknown"}
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
-- OBTENER CANCIONES POR LOTES (PAGINACIÓN)
-- ════════════════════════════════════════════════════════════════
local SONGS_PER_PAGE = 30

local function getSongsByDJPaginated(djName, page)
	page = page or 1

	if not musicDatabase[djName] then
		return {songs = {}, hasMore = false, total = 0, page = page}
	end

	local allIds = musicDatabase[djName].songIds or {}
	local total = #allIds
	local startIndex = (page - 1) * SONGS_PER_PAGE + 1
	local endIndex = math.min(startIndex + SONGS_PER_PAGE - 1, total)

	local songs = {}
	for i = startIndex, endIndex do
		local id = allIds[i]
		if id then
			-- Usar cache si existe, sino mostrar ID
			local cached = metadataCache[id]
			table.insert(songs, {
				id = id,
				name = cached and cached.name or ("Audio " .. id),
				artist = cached and cached.artist or "...",
				index = i
			})
		end
	end

	return {
		songs = songs,
		hasMore = endIndex < total,
		total = total,
		page = page,
		totalPages = math.ceil(total / SONGS_PER_PAGE)
	}
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

	-- Verificar que es audio válido
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

	-- Validar permisos con Sound temporal
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

		-- Guardar en cache
		metadataCache[id] = {name = songInfo.name, artist = songInfo.artist}

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
-- LIBRARY EVENTS
-- ════════════════════════════════════════════════════════════════
R.GetDJs.OnServerEvent:Connect(function(player)
	local djs = getAllDJs()
	R.GetDJs:FireClient(player, {djs = djs})
end)

-- PAGINACIÓN DE CANCIONES
R.GetSongsByDJ.OnServerEvent:Connect(function(player, djName, page)
	page = page or 1
	local result = getSongsByDJPaginated(djName, page)
	result.djName = djName
	R.GetSongsByDJ:FireClient(player, result)
end)

-- OBTENER METADATA BAJO DEMANDA (para lotes de IDs)
R.GetSongMetadata.OnServerEvent:Connect(function(player, audioIds)
	if type(audioIds) ~= "table" then return end

	-- Limitar a 10 IDs por request para no sobrecargar
	local results = {}
	for i = 1, math.min(#audioIds, 10) do
		local id = audioIds[i]
		if type(id) == "number" then
			local metadata = getMetadataForId(id)
			results[id] = metadata
		end
	end

	R.GetSongMetadata:FireClient(player, results)
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
print("[MUSIC] Sistema listo - DJs:", #getAllDJs())
task.defer(updateAllClients)