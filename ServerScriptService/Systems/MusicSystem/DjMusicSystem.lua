-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM - SERVER SCRIPT 
-- Sistema completo de música con respuestas síncronas
-- by ignxts
--
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
-- ContentProvider removed: PreloadAsync was causing slow responses

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- ════════════════════════════════════════════════════════════════
-- DATABASE & STATE
-- ════════════════════════════════════════════════════════════════
local musicDatabase = {}
local playQueue = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false
local productCache = {}

-- ════════════════════════════════════════════════════════════════
-- RESPONSE CODES (para UI sync)
-- ════════════════════════════════════════════════════════════════
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
-- ADMIN FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function isAdmin(player)
	return MusicConfig:IsAdmin(player.UserId)
end

local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
end

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

-- Crear remotes incluyendo el nuevo AddToQueueResponse
local playbackRemotes = {
	{folder = musicPlaybackFolder, names = {"PlaySong", "PauseSong", "NextSong", "StopSong", "UpdatePlayback"}},
	{folder = musicQueueFolder, names = {"AddToQueue", "AddToQueueResponse", "RemoveFromQueue", "RemoveFromQueueResponse", "ClearQueue", "ClearQueueResponse", "MoveInQueue", "UpdateQueue"}},
	{folder = musicLibraryFolder, names = {"GetDJs", "GetSongsByDJ", "SearchSongs"}},
	{folder = uiFolder, names = {"UpdateUI"}}
}

for _, group in ipairs(playbackRemotes) do
	for _, name in ipairs(group.names) do
		if not group.folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = group.folder
		end
	end
end

-- Sound Object
local SoundService = game:GetService("SoundService")
local soundObject = SoundService:FindFirstChild("QueueSound")
if soundObject then soundObject:Destroy() end

soundObject = Instance.new("Sound")
soundObject.Name = "QueueSound"
soundObject.Parent = SoundService
soundObject.Volume = MusicConfig:GetDefaultVolume()
soundObject.Looped = MusicConfig.PLAYBACK.LoopQueue

-- Get RemoteEvents
local R = {
	Play = musicPlaybackFolder:FindFirstChild("PlaySong"),
	Pause = musicPlaybackFolder:FindFirstChild("PauseSong"),
	Next = musicPlaybackFolder:FindFirstChild("NextSong"),
	Stop = musicPlaybackFolder:FindFirstChild("StopSong"),
	Update = uiFolder:FindFirstChild("UpdateUI"),
	UpdatePlayback = musicPlaybackFolder:FindFirstChild("UpdatePlayback"),
	AddToQueue = musicQueueFolder:FindFirstChild("AddToQueue"),
	AddToQueueResponse = musicQueueFolder:FindFirstChild("AddToQueueResponse"),
	RemoveFromQueue = musicQueueFolder:FindFirstChild("RemoveFromQueue"),
	RemoveFromQueueResponse = musicQueueFolder:FindFirstChild("RemoveFromQueueResponse"),
	ClearQueue = musicQueueFolder:FindFirstChild("ClearQueue"),
	ClearQueueResponse = musicQueueFolder:FindFirstChild("ClearQueueResponse"),
	MoveInQueue = musicQueueFolder:FindFirstChild("MoveInQueue"),
	UpdateQueue = musicQueueFolder:FindFirstChild("UpdateQueue"),
	GetDJs = musicLibraryFolder:FindFirstChild("GetDJs"),
	GetSongsByDJ = musicLibraryFolder:FindFirstChild("GetSongsByDJ"),
	SearchSongs = musicLibraryFolder:FindFirstChild("SearchSongs")
	-- RemoveDJ removed: DJs are immutable
}

-- ════════════════════════════════════════════════════════════════
-- HELPER: Crear respuesta estructurada
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

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN PARA VERIFICAR DUPLICADOS EN LA COLA
-- ════════════════════════════════════════════════════════════════
local function isAudioInQueue(audioId)
	if MusicConfig.LIMITS.AllowDuplicatesInQueue then
		return false, nil
	end

	for _, song in ipairs(playQueue) do
		if song.id == audioId then
			return true, song
		end
	end
	return false, nil
end

-- ════════════════════════════════════════════════════════════════
-- DATABASE FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function saveLibraryToDataStore()
	return
end

local function loadLibraryFromDataStore()
	musicDatabase = {}
	local djsConfig = MusicConfig:GetDJs()
	local count = 0
	for _ in pairs(djsConfig) do count = count + 1 end
	print("[MUSIC DEBUG] DJs encontrados en config:", count)
	local djIndex = 0
	for djName, djData in pairs(djsConfig) do
		djIndex = djIndex + 1
		print(string.format("[MUSIC DEBUG] DJ #%d: %s (ImageId: %s, Canciones: %d)", djIndex, tostring(djName), tostring(djData.ImageId), #(djData.SongIds or {})))
		local songsList = {}
		for _, s in ipairs(djData.SongIds or {}) do
			if type(s) == "number" then
				local id = s
				local name = "Audio " .. tostring(id)
				local artist = ""
				local duration = 0
				local verified = false
				local ok, info = pcall(function()
					if productCache[id] then return productCache[id] end
					local res = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
					productCache[id] = res
					return res
				end)
				if ok and info and info.AssetTypeId == 3 then
					name = info.Name or name
					artist = (info.Creator and info.Creator.Name) or artist
					duration = info.Playtime or info.PlayTime or duration
					verified = true
				end
				table.insert(songsList, {
					id = id,
					name = name,
					artist = artist,
					djName = djData.name or djName,
					duration = duration,
					verified = verified,
					addedDate = os.date("%Y-%m-%d"),
					addedBy = "Config"
				})
			elseif type(s) == "table" and s.id then
				s.djName = s.djName or djData.name or djName
				s.addedBy = s.addedBy or "Config"
				s.addedDate = s.addedDate or os.date("%Y-%m-%d")
				table.insert(songsList, s)
			end
		end
		musicDatabase[djName] = {
			cover = djData.ImageId,
			userId = djData.userId,
			songs = songsList
		}
	end
	print(string.format("[MUSIC DEBUG] DJs cargados en musicDatabase: %d", djIndex))
end

-- removeSongFromLibrary removed: never called, system is immutable

local function getAllDJs()
	local djsList = {}
	local stats = {}
	local count = 0
	print("[MUSIC DEBUG] getAllDJs: contenido actual de musicDatabase:")
	for k, v in pairs(musicDatabase) do
		print("  DJ:", k, "->", v and type(v) == "table" and ("canciones: "..tostring(#(v.songs or {}))) or tostring(v))
	end
	for djName, djData in pairs(musicDatabase) do
		count = count + 1
		print(string.format("[MUSIC DEBUG] getAllDJs: #%d %s (cover: %s, canciones: %d)", count, tostring(djName), tostring(djData.cover), #(djData.songs or {})))
		table.insert(djsList, {
			name = djName,
			cover = djData.cover,
			userId = djData.userId,
			songCount = #djData.songs
		})
		stats[djName] = #djData.songs
	end
	print(string.format("[MUSIC DEBUG] getAllDJs: total enviados: %d", count))
	return djsList, stats
end

-- removeDJ removed: DJs are immutable, loaded from config only
-- RenameDJ removed: DJs are read-only from MusicSystemConfig

local function searchSongsInLibrary(searchTerm)
	if not searchTerm or searchTerm == "" then
		return {}
	end

	local results = {}
	local lowerSearch = searchTerm:lower()

	   for djName, djData in pairs(musicDatabase) do
		   for _, song in ipairs(djData.songs) do
			local lowerName = song.name:lower()
			local lowerArtist = (song.artist or ""):lower()

			if lowerName:find(lowerSearch, 1, true) or lowerArtist:find(lowerSearch, 1, true) then
				local songCopy = {}
				for k, v in pairs(song) do
					songCopy[k] = v
				end
				songCopy.djName = djName
				table.insert(results, songCopy)
			end
		end
	end

	return results
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

-- Forward declaration
local updateAllClients

local function playSong(index)
	if #playQueue == 0 then
		isPlaying = false
		soundObject:Stop()
		return
	end

	index = index or currentSongIndex
	if index < 1 or index > #playQueue then
		warn("[SKIP] Invalid queue index:", index)
		return
	end

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

local function pauseSong()
	if isPlaying and not isPaused then
		soundObject:Pause()
		isPaused = true
		isPlaying = false
		updateAllClients()
	end
end

local function resumeSong()
	if isPaused then
		soundObject:Resume()
		isPaused = false
		isPlaying = true
		updateAllClients()
	end
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
		if currentSongIndex > #playQueue then
			currentSongIndex = 1
		end
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

local function removeFromQueue(index, adminName)
	if index < 1 or index > #playQueue then
		return false, "Invalid index"
	end

	local removedSong = table.remove(playQueue, index)

	if index == currentSongIndex then
		if #playQueue == 0 then
			stopSong()
			currentSongIndex = 1
		else
			if currentSongIndex > #playQueue then
				currentSongIndex = 1
			end
			playSong(currentSongIndex)
		end
	elseif index < currentSongIndex then
		currentSongIndex = currentSongIndex - 1
	end

	updateAllClients()
	return true, removedSong.name
end

local function clearQueue(adminName)
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
-- BROADCAST FUNCTIONS
-- ════════════════════════════════════════════════════════════════
function updateAllClients()
	if R.Update then
		local djs, stats = getAllDJs()
		local dataPacket = {
			library = musicDatabase,
			queue = playQueue,
			currentSong = getCurrentSong(),
			djs = djs,
			stats = stats,
			isPlaying = isPlaying,
			isPaused = isPaused
		}

		for _, player in ipairs(Players:GetPlayers()) do
			R.Update:FireClient(player, dataPacket)
		end
	end
end

-- updateLibrary removed: RemoveSongFromLibrary was never called from client, system is now immutable

-- ════════════════════════════════════════════════════════════════
-- SERVER EVENTS - PLAYBACK
-- ════════════════════════════════════════════════════════════════
R.Play.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "PlaySong") then 
		return 
	end

	if isPaused then
		resumeSong()
	else
		playSong(1)
	end
end)

R.Pause.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "PauseSong") then 
		return 
	end
	pauseSong()
end)

R.Next.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "NextSong") then 
		return 
	end
	nextSong()
end)

R.Stop.OnServerEvent:Connect(function(player)  
	if not MusicConfig:HasPermission(player.UserId, "StopSong") then 
		return 
	end
	stopSong()
end)

-- ════════════════════════════════════════════════════════════════
-- ADD TO QUEUE - CON RESPUESTA SÍNCRONA
-- ════════════════════════════════════════════════════════════════
R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	local function sendResponse(response)
		if R.AddToQueueResponse then
			R.AddToQueueResponse:FireClient(player, response)
		end
	end

	-- Verificar permisos
	if not hasPermission(player, "AddToQueue") then 
		sendResponse(createResponse(
			ResponseCodes.ERROR_PERMISSION,
			"No tienes permiso para añadir canciones"
			))
		return 
	end

	local id = tonumber(audioId)

	-- Validar formato de ID
	if not id or #tostring(id) < 6 or #tostring(id) > 19 then
		sendResponse(createResponse(
			ResponseCodes.ERROR_INVALID_ID,
			"ID de audio inválido (debe tener 6-19 dígitos)"
			))
		return
	end

	-- Validar contra blacklist
	local valid, validationError = MusicConfig:ValidateAudioId(id)
	if not valid then
		sendResponse(createResponse(
			ResponseCodes.ERROR_BLACKLISTED,
			"Audio bloqueado: " .. (validationError or "No permitido")
			))
		return
	end

	-- Verificar duplicados ANTES de consultar API
	local isDuplicate, existingSong = isAudioInQueue(id)
	if isDuplicate then
		sendResponse(createResponse(
			ResponseCodes.ERROR_DUPLICATE,
			"Esta canción ya está en la cola",
			{songName = existingSong.name}
			))
		return
	end

	-- Verificar en Roblox API
	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	end)

	if not success or not result then
		sendResponse(createResponse(
			ResponseCodes.ERROR_NOT_FOUND,
			"Audio no encontrado en Roblox"
			))
		return
	end

	if result.AssetTypeId ~= 3 then
		sendResponse(createResponse(
			ResponseCodes.ERROR_NOT_AUDIO,
			"El asset no es un archivo de audio"
			))
		return
	end

	-- NOTA: ContentProvider:PreloadAsync removido porque causa delays de varios segundos
	-- MarketplaceService:GetProductInfo ya valida que el asset existe y es audio
	-- El audio se cargará automáticamente cuando se reproduzca

	-- Verificar límite de cola
	if #playQueue >= MusicConfig.LIMITS.MaxQueueSize then
		sendResponse(createResponse(
			ResponseCodes.ERROR_QUEUE_FULL,
			"Cola llena (máximo " .. MusicConfig.LIMITS.MaxQueueSize .. " canciones)"
			))
		return
	end

	-- Validar permisos de acceso al asset usando Sound temporal
	local tempSound = Instance.new("Sound")
	tempSound.SoundId = "rbxassetid://" .. id
	tempSound.Parent = workspace

	local loaded = false
	local finished = false

	local function cleanup()
		if tempSound then
			tempSound:Destroy()
			tempSound = nil
		end
	end

	tempSound.Loaded:Connect(function()
		loaded = true
		finished = true
		cleanup()

		-- AGREGAR A LA COLA
		local songInfo = {
			id = id,
			name = result.Name or ("Audio " .. id),
			artist = result.Creator.Name or "Unknown",
			userId = player.UserId,
			requestedBy = player.Name,
			addedAt = os.time()
		}

		table.insert(playQueue, songInfo)

		-- Enviar respuesta de éxito
		sendResponse(createResponse(
			ResponseCodes.SUCCESS,
			"Canción añadida a la cola",
			{
				songName = songInfo.name,
				artist = songInfo.artist,
				position = #playQueue
			}
		))

		-- Actualizar TODOS los clientes
		updateAllClients()

		-- Auto-start si es la primera canción
		if not isPlaying and not isPaused and #playQueue == 1 then
			task.spawn(function()
				wait(0.3)
				playSong(1)
			end)
		end
	end)

	-- Timeout de 3 segundos
	task.delay(3, function()
		if not finished then
			finished = true
			cleanup()
			sendResponse(createResponse(
				ResponseCodes.ERROR_NOT_AUTHORIZED,
				"No tienes permiso para reproducir este audio"
			))
		end
	end)

	-- Intentar cargar
	pcall(function()
		tempSound:LoadAsync()
	end)
end)

-- ════════════════════════════════════════════════════════════════
-- REMOVE FROM QUEUE - CON RESPUESTA SÍNCRONA
-- ════════════════════════════════════════════════════════════════
R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	local function sendResponse(response)
		if R.RemoveFromQueueResponse then
			R.RemoveFromQueueResponse:FireClient(player, response)
		end
	end

	if not MusicConfig:HasPermission(player.UserId, "RemoveFromQueue") then 
		sendResponse(createResponse(
			ResponseCodes.ERROR_PERMISSION,
			"No tienes permiso para eliminar canciones"
			))
		return 
	end

	local success, songName = removeFromQueue(index, player.Name)

	if success then
		sendResponse(createResponse(
			ResponseCodes.SUCCESS,
			"Canción eliminada de la cola",
			{songName = songName}
			))
	else
		sendResponse(createResponse(
			ResponseCodes.ERROR_INVALID_ID,
			"Índice inválido"
			))
	end
end)

-- ════════════════════════════════════════════════════════════════
-- CLEAR QUEUE - CON RESPUESTA SÍNCRONA
-- ════════════════════════════════════════════════════════════════
R.ClearQueue.OnServerEvent:Connect(function(player)
	local function sendResponse(response)
		if R.ClearQueueResponse then
			R.ClearQueueResponse:FireClient(player, response)
		end
	end

	if not MusicConfig:HasPermission(player.UserId, "ClearQueue") then 
		sendResponse(createResponse(
			ResponseCodes.ERROR_PERMISSION,
			"No tienes permiso para limpiar la cola"
			))
		return 
	end

	local success, clearedCount = clearQueue(player.Name)

	if success then
		sendResponse(createResponse(
			ResponseCodes.SUCCESS,
			"Cola limpiada",
			{clearedCount = clearedCount}
			))
	else
		sendResponse(createResponse(
			ResponseCodes.ERROR_UNKNOWN,
			"La cola ya está vacía"
			))
	end
end)

-- ════════════════════════════════════════════════════════════════
-- LIBRARY EVENTS
-- ════════════════════════════════════════════════════════════════
R.GetDJs.OnServerEvent:Connect(function(player)
	local djs, stats = getAllDJs()
	R.GetDJs:FireClient(player, {
		djs = djs,
		stats = stats
	})
end)

R.GetSongsByDJ.OnServerEvent:Connect(function(player, djName)
	local songs = {}
	if musicDatabase[djName] then
		songs = musicDatabase[djName].songs or {}
	end
	R.GetSongsByDJ:FireClient(player, {
		djName = djName,
		songs = songs
	})
end)

R.SearchSongs.OnServerEvent:Connect(function(player, searchTerm)
	local results = searchSongsInLibrary(searchTerm)
	R.SearchSongs:FireClient(player, {songs = results})
end)

-- RemoveSongFromLibrary event handler removed: never called from client, system is immutable

-- GetLibrary event handler removed: never called from client, redundant with automatic updateAllClients()

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
	task.wait(2)
	if R.Update then
		local djs, stats = getAllDJs()
		R.Update:FireClient(player, {
			library = musicDatabase,
			queue = playQueue,
			currentSong = getCurrentSong(),
			djs = djs,
			stats = stats,
			isPlaying = isPlaying,
			isPaused = isPaused
		})
	end
end)

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
loadLibraryFromDataStore()
wait(1)
updateAllClients()