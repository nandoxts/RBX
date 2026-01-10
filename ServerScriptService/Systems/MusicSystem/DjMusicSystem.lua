-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM - SERVER SCRIPT v3.1
-- Sistema completo de música con validación avanzada
-- Autor: nandoxts
-- Fecha: 2025-10-19
--
-- CORRECCIONES APLICADAS v3.1:
-- [SKIP] Prevención de duplicados en la cola
-- [SKIP] Actualización en tiempo real para todos los clientes
-- [SKIP] Feedback específico cuando se intenta agregar duplicado
-- [SKIP] Verificación de duplicados antes de validar en MarketplaceService
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN (desde módulo centralizado)
-- ════════════════════════════════════════════════════════════════
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local AdminConfig = require(game.ServerStorage:WaitForChild("Config"):WaitForChild("CentralAdminConfig"))

-- ════════════════════════════════════════════════════════════════
-- DATABASE
-- ════════════════════════════════════════════════════════════════
local MusicDB = require(ServerStorage:WaitForChild("Systems"):WaitForChild("MusicSystem"):WaitForChild("MusicDatabase"))

-- DataStore configurable desde MusicSystemConfig
local musicStore = MusicConfig.DATABASE.UseDataStore and DataStoreService:GetDataStore(MusicConfig.DATABASE.MusicLibraryStoreName) or nil

local musicDatabase = {}
local playQueue = {}
local currentSongIndex = 1
local isPlaying = false
local isPaused = false

-- ════════════════════════════════════════════════════════════════
-- ADMIN FUNCTIONS (usando MusicConfig)
-- ════════════════════════════════════════════════════════════════
local function isAdmin(player)
	return MusicConfig:IsAdmin(player.UserId)
end

local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
end

-- ════════════════════════════════════════════════════════════════
-- REMOTE EVENTS
-- ════════════════════════════════════════════════════════════════
local remotesFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "MusicRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Crear carpetas de organización
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

-- Crear remotes en sus carpetas correspondientes
local playbackRemotes = {
	{folder = musicPlaybackFolder, names = {"PlaySong", "PauseSong", "NextSong", "StopSong", "UpdatePlayback"}},
	{folder = musicQueueFolder, names = {"AddToQueue", "RemoveFromQueue", "ClearQueue", "MoveInQueue", "UpdateQueue"}},
	{folder = musicLibraryFolder, names = {"GetDJs", "GetSongsByDJ", "SearchSongs", "AddSongToDJ", "RemoveSongFromLibrary", "RemoveDJ", "RenameDJ", "AddToLibrary", "RemoveFromLibrary", "GetLibrary", "UpdateLibrary"}},
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
local soundObject = Workspace:FindFirstChild("QueueSound")
if soundObject then soundObject:Destroy() end

soundObject = Instance.new("Sound")
soundObject.Name = "QueueSound"
soundObject.Parent = Workspace
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
	RemoveFromQueue = musicQueueFolder:FindFirstChild("RemoveFromQueue"),
	ClearQueue = musicQueueFolder:FindFirstChild("ClearQueue"),
	MoveInQueue = musicQueueFolder:FindFirstChild("MoveInQueue"),
	UpdateQueue = musicQueueFolder:FindFirstChild("UpdateQueue"),
	GetDJs = musicLibraryFolder:FindFirstChild("GetDJs"),
	GetSongsByDJ = musicLibraryFolder:FindFirstChild("GetSongsByDJ"),
	SearchSongs = musicLibraryFolder:FindFirstChild("SearchSongs"),
	AddSongToDJ = musicLibraryFolder:FindFirstChild("AddSongToDJ"),
	RemoveSongFromLibrary = musicLibraryFolder:FindFirstChild("RemoveSongFromLibrary"),
	RemoveDJ = musicLibraryFolder:FindFirstChild("RemoveDJ"),
	RenameDJ = musicLibraryFolder:FindFirstChild("RenameDJ"),
	AddToLibrary = musicLibraryFolder:FindFirstChild("AddToLibrary"),
	RemoveFromLibrary = musicLibraryFolder:FindFirstChild("RemoveFromLibrary"),
	GetLibrary = musicLibraryFolder:FindFirstChild("GetLibrary"),
	UpdateLibrary = musicLibraryFolder:FindFirstChild("UpdateLibrary")
}

-- ════════════════════════════════════════════════════════════════
-- 🆕 FUNCIÓN PARA VERIFICAR DUPLICADOS EN LA COLA
-- ════════════════════════════════════════════════════════════════
local function isAudioInQueue(audioId)
	-- Verificar si se permiten duplicados
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
	if not MusicConfig.DATABASE.UseDataStore then
		print("⚠️ [LIBRARY_SAVE] DataStore deshabilitado - no se guardará")
		return
	end
	
	pcall(function()
		local dataToSave = {
			djs = musicDatabase,
			metadata = {
				version = MusicConfig.SYSTEM.Version,
				lastUpdated = os.date("%Y-%m-%d %H:%M:%S"),
				totalSongs = 0
			}
		}

		for djName, djData in pairs(musicDatabase) do
			dataToSave.metadata.totalSongs = dataToSave.metadata.totalSongs + #djData.songs
		end

		musicStore:SetAsync("MusicLibrary_Global", dataToSave)
		print("[LIBRARY_SAVE] Total songs stored:", dataToSave.metadata.totalSongs, "| Timestamp:", dataToSave.metadata.lastUpdated)
	end)
end

local function loadLibraryFromDataStore()
	local success, data = pcall(function()
		return musicStore:GetAsync("MusicLibrary_Global")
	end)

	if success and data and data.djs then
		musicDatabase = data.djs

		local totalSongs = 0
		for djName, djData in pairs(musicDatabase) do
			totalSongs = totalSongs + #djData.songs
		end

	else
		musicDatabase = {}

		-- Intentar cargar desde MusicDatabase.lua
		if MusicDB and MusicDB.djs then
			for djName, djData in pairs(MusicDB.djs) do
				musicDatabase[djName] = {
					cover = djData.cover,
					userId = djData.userId,
					songs = {}
				}
				for _, song in ipairs(djData.songs) do
					if song.id > 0 then
						table.insert(musicDatabase[djName].songs, {
							id = song.id,
							name = song.name,
							artist = song.artist,
							djName = djName,
							duration = song.duration or 0,
							verified = song.verified or false,
							addedDate = os.date("%Y-%m-%d"),
							addedBy = "System"
						})
					end
				end
				print("[LIBRARY_LOAD] DJ:", djName, "| Songs loaded:", #musicDatabase[djName].songs)
			end
		else
			-- Usar DJs predeterminados desde MusicConfig
			for _, djData in ipairs(MusicConfig:GetDefaultDJs()) do
				musicDatabase[djData.name] = {
					cover = djData.cover,
					userId = djData.userId,
					songs = djData.songs
				}
				print("[LIBRARY_LOAD] DJ (Config):", djData.name, "| Songs:", #djData.songs)
			end
		end

		saveLibraryToDataStore()
		print("[SYSTEM] Library initialization complete | Status: SUCCESS")
	end
end

local function findSongInLibrary(audioId)
	for djName, djData in pairs(musicDatabase) do
		for _, song in ipairs(djData.songs) do
			if song.id == audioId then
				song.djName = djName
				return song
			end
		end
	end
	return nil
end

local function addSongToDJ(audioId, songName, artistName, djName, adminName)
	djName = djName or "Uncategorized"

	if not musicDatabase[djName] then
		musicDatabase[djName] = {
			cover = "rbxassetid://0",
			userId = 0,
			songs = {}
		}
		print("[DJ_CREATE] New DJ added:", djName, "| Timestamp:", os.date("%H:%M:%S"))
	end

	-- Verificar límite de canciones por DJ
	if musicDatabase[djName] and #musicDatabase[djName].songs >= MusicConfig.LIMITS.MaxSongsPerDJ then
		warn("[VALIDATION_ERROR] DJ song limit reached | DJ:", djName, "| Limit:", MusicConfig.LIMITS.MaxSongsPerDJ, "| Action: SKIP")
		return false, "DJ ha alcanzado el límite de " .. MusicConfig.LIMITS.MaxSongsPerDJ .. " canciones"
	end

	local existingSong = findSongInLibrary(audioId)
	if existingSong then
		print("[WARNING] Song already exists | Audio ID:", audioId, "| DJ:", existingSong.djName)
		return false, "Canción ya existe"
	end

	local newSong = {
		id = audioId,
		name = songName,
		artist = artistName,
		djName = djName,
		duration = 0,
		verified = false,
		addedDate = os.date("%Y-%m-%d"),
		addedBy = adminName
	}

	table.insert(musicDatabase[djName].songs, newSong)
	saveLibraryToDataStore()

	print("[SONG_ADD] Admin:", adminName, "| Song:", songName, "| DJ:", djName, "| Audio ID:", audioId)
	return true, "Canción agregada exitosamente"
end

local function removeSongFromLibrary(audioId, adminName)
	for djName, djData in pairs(musicDatabase) do
		for i, song in ipairs(djData.songs) do
			if song.id == audioId then
				local removedSong = table.remove(djData.songs, i)
				saveLibraryToDataStore()
				print("[SONG_REMOVE] Admin:", adminName, "| Song:", removedSong.name, "| DJ:", djName, "| Audio ID:", audioId)
				return true, djName, removedSong.name
			end
		end
	end
	return false, nil, nil
end

local function getAllDJs()
	local djsList = {}
	local stats = {}

	for djName, djData in pairs(musicDatabase) do
		table.insert(djsList, {
			name = djName,
			cover = djData.cover,
			userId = djData.userId,
			songCount = #djData.songs
		})
		stats[djName] = #djData.songs
	end

	return djsList, stats
end

local function removeDJ(djName, adminName)
	if not musicDatabase[djName] then
		return false, "DJ not found"
	end

	local songCount = #musicDatabase[djName].songs

	musicDatabase[djName] = nil
	saveLibraryToDataStore()

	print("[DJ_DELETE] Admin:", adminName, "| DJ:", djName, "| Songs removed:", songCount)
	return true, "DJ deleted: " .. djName .. " (" .. songCount .. " songs)"
end

local function renameDJ(oldName, newName, adminName)
	if not musicDatabase[oldName] then
		return false, "DJ not found"
	end

	if oldName == newName then
		return false, "Same name provided"
	end

	if musicDatabase[newName] then
		return false, "DJ name already exists"
	end

	if newName:match("^%s*$") or #newName > 30 then
		return false, "Invalid DJ name"
	end

	musicDatabase[newName] = musicDatabase[oldName]
	musicDatabase[oldName] = nil

	for _, song in ipairs(musicDatabase[newName].songs) do
		song.djName = newName
	end

	saveLibraryToDataStore()

	print("[DJ_RENAME] Admin:", adminName, "| Old name:", oldName, "| New name:", newName)
	return true, "DJ renamed: " .. oldName .. " → " .. newName
end

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

local function playSong(index)
	if #playQueue == 0 then
		print("[WARNING] Queue is empty | Action: SKIP play")
		isPlaying = false
		soundObject:Stop()
		return
	end

	index = index or currentSongIndex
	if index < 1 or index > #playQueue then
		print("[WARNING] Invalid queue index:", index, "| Queue length:", #playQueue, "| Action: SKIP")
		return
	end

	currentSongIndex = index
	local song = playQueue[currentSongIndex]

	soundObject.SoundId = "rbxassetid://" .. song.id
	soundObject:Play()
	isPlaying = true
	isPaused = false

	-- Fade-in suave (transición de volumen)
	soundObject.Volume = 0
	task.spawn(function()
		for i = 1, 10 do
			soundObject.Volume = i * 0.1
			task.wait(0.05)
		end
	end)

	print("[PLAYBACK_START] Song:", song.name, "| Audio ID:", song.id, "| Queue index:", currentSongIndex, "| Status: PLAYING")

	-- [SKIP] Actualizar TODOS los clientes inmediatamente
	updateAllClients()
end

local function pauseSong()
	if isPlaying and not isPaused then
		soundObject:Pause()
		isPaused = true
		isPlaying = false
		print("[PLAYBACK_PAUSE] Current song:", getCurrentSong().name, "| Status: PAUSED")
		updateAllClients()
	end
end

local function resumeSong()
	if isPaused then
		soundObject:Resume()
		isPaused = false
		isPlaying = true
		print("[PLAYBACK_RESUME] Current song:", getCurrentSong().name, "| Status: PLAYING")
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
		print("[PLAYBACK_QUEUE_END] All songs in queue finished | Status: COMPLETE")
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
	print("[PLAYBACK_STOP] Song stopped | Status: STOPPED")
	updateAllClients()
end

local function removeFromQueue(index, adminName)
	if index < 1 or index > #playQueue then
		warn("[ERROR] Invalid queue index:", index, "| Queue length:", #playQueue, "| Action: SKIP")
		return
	end

	local removedSong = table.remove(playQueue, index)
	print("[QUEUE_REMOVE] Admin:", adminName, "| Song:", removedSong.name, "| Index:", index, "| Audio ID:", removedSong.id)

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
end

local function clearQueue(adminName)
	if #playQueue > 0 then
		if isPlaying and currentSongIndex == 1 then
			local currentSong = playQueue[1]
			playQueue = {currentSong}
			currentSongIndex = 1
			print("[QUEUE_CLEAR] Admin:", adminName, "| Mode: Keep current | Remaining songs: 1")
		else
			playQueue = {}
			currentSongIndex = 1
			stopSong()
			print("[QUEUE_CLEAR] Admin:", adminName, "| Mode: Full clear | Remaining songs: 0")
		end
		updateAllClients()  -- Actualizar toda la UI (incluye la cola)
		return true
	end
	return false
end


-- ════════════════════════════════════════════════════════════════
-- [SKIP] ACTUALIZACIÓN MEJORADA - BROADCAST A TODOS LOS CLIENTES
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

		-- [SKIP] Enviar a TODOS los jugadores conectados
		for _, player in ipairs(Players:GetPlayers()) do
			R.Update:FireClient(player, dataPacket)
		end
	end
end

function updateLibrary()
	if R.UpdateLibrary then
		local djs, stats = getAllDJs()
		for _, player in ipairs(Players:GetPlayers()) do
			R.UpdateLibrary:FireClient(player, {
				library = musicDatabase,
				djs = djs,
				stats = stats
			})
		end
	end

	-- También enviar DJs actualizados
	if R.GetDJs then
		local djs, stats = getAllDJs()
		for _, player in ipairs(Players:GetPlayers()) do
			R.GetDJs:FireClient(player, {
				djs = djs,
				stats = stats
			})
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SERVER EVENTS
-- ════════════════════════════════════════════════════════════════

-- PLAY / PAUSE
R.Play.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "PlaySong") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: PLAY | Reason: Insufficient permissions | Action: SKIP")
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
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: PAUSE | Reason: Insufficient permissions | Action: SKIP")
		return 
	end
	pauseSong()
end)

-- NEXT SONG
R.Next.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "NextSong") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: NEXT | Reason: Insufficient permissions | Action: SKIP")
		return 
	end
	nextSong()
end)

-- STOP
R.Stop.OnServerEvent:Connect(function(player)  
	if not MusicConfig:HasPermission(player.UserId, "StopSong") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: STOP | Reason: Insufficient permissions | Action: SKIP")
		return 
	end
	stopSong()
end)

-- ════════════════════════════════════════════════════════════════
-- [SKIP] ADD TO QUEUE - CON PREVENCIÓN DE DUPLICADOS
-- ════════════════════════════════════════════════════════════════
R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	if not hasPermission(player, "add") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: ADD_QUEUE | Reason: Insufficient permissions | Action: SKIP")
		return 
	end

	local id = tonumber(audioId)

	-- Validar formato de ID
	if not id or #tostring(id) < 6 or #tostring(id) > 19 then
		warn("[VALIDATION_ERROR] Invalid Audio ID format | Input:", audioId, "| Required: 6-19 digits | Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Invalid Audio ID (6-19 digits)"
			})
		end
		return
	end

	-- Validar contra blacklist usando MusicConfig
	local valid, validationError = MusicConfig:ValidateAudioId(id)
	if not valid then
		warn("[VALIDATION_ERROR] Blacklisted Audio ID | Audio ID:", id, "| Reason:", validationError, "| Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Audio bloqueado: " .. validationError
			})
		end
		return
	end

	-- [SKIP] PRIMERO: Verificar si ya está en la cola (antes de consultar API)
	local isDuplicate, existingSong = isAudioInQueue(id)
	if isDuplicate then
		warn("[VALIDATION_ERROR] Duplicate song in queue | Song:", existingSong.name, "| Audio ID:", id, "| Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Canción ya en cola"
			})
		end
		return
	end

	-- Verificar en Roblox API
	local success, result = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
	end)

	if not success or not result then
		warn("[API_ERROR] Audio asset not found | Audio ID:", id, "| Service: MarketplaceService | Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Audio not found"
			})
		end
		return
	end

	if result.AssetTypeId ~= 3 then
		warn("[VALIDATION_ERROR] Asset type mismatch | Required: 3 (Audio) | Provided:", result.AssetTypeId, "| Audio ID:", id, "| Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Not an audio asset"
			})
		end
		return
	end

	-- Verificar límite de cola
	if #playQueue >= MusicConfig.LIMITS.MaxQueueSize then
		warn("[VALIDATION_ERROR] Queue full | Limit:", MusicConfig.LIMITS.MaxQueueSize, "| Action: SKIP")
		if R.Update then
			local djs, stats = getAllDJs()
			R.Update:FireClient(player, {
				library = musicDatabase,
				queue = playQueue,
				currentSong = getCurrentSong(),
				djs = djs,
				error = "Cola llena (máximo " .. MusicConfig.LIMITS.MaxQueueSize .. " canciones)"
			})
		end
		return
	end

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
	print("[QUEUE_ADD] Player:", player.Name, "| Song:", songInfo.name, "| Artist:", songInfo.artist, "| Audio ID:", id, "| Queue position:", #playQueue)

	-- [SKIP] Actualizar TODOS los clientes inmediatamente
	updateAllClients()

	-- Auto-start
	if not isPlaying and not isPaused and #playQueue == 1 then
		task.spawn(function()
			wait(0.3)
			playSong(1)
		end)
	end
end)

-- REMOVE FROM QUEUE
R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	if not MusicConfig:HasPermission(player.UserId, "RemoveFromQueue") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: REMOVE | Reason: Insufficient permissions | Action: SKIP")
		return 
	end
	removeFromQueue(index, player.Name)
end)

-- CLEAR QUEUE
R.ClearQueue.OnServerEvent:Connect(function(player)
	if not MusicConfig:HasPermission(player.UserId, "ClearQueue") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: CLEAR_QUEUE | Reason: Insufficient permissions | Action: SKIP")
		return 
	end
	clearQueue(player.Name)
end)

-- GET DJs
R.GetDJs.OnServerEvent:Connect(function(player)
	local djs, stats = getAllDJs()
	R.GetDJs:FireClient(player, {
		djs = djs,
		stats = stats
	})
end)

-- GET SONGS BY DJ
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

-- SEARCH SONGS
R.SearchSongs.OnServerEvent:Connect(function(player, searchTerm)
	local results = searchSongsInLibrary(searchTerm)
	R.SearchSongs:FireClient(player, {songs = results})
end)

-- ADD SONG TO DJ (para agregar a la biblioteca)
R.AddSongToDJ.OnServerEvent:Connect(function(player, audioId, songName, artistName, djName)
	if not MusicConfig:HasPermission(player.UserId, "AddToLibrary") then 
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: ADD_LIBRARY | Reason: Insufficient permissions | Action: SKIP")
		return 
	end

	local id = tonumber(audioId)
	if not id then
		warn("[VALIDATION_ERROR] Invalid Audio ID format | Input:", audioId, "| Action: SKIP")
		return
	end

	local success, message = addSongToDJ(id, songName or "Sin título", artistName or "Desconocido", djName or "Uncategorized", player.Name)
	if success then
		updateLibrary()
		R.AddSongToDJ:FireClient(player, {success = true, message = "Canción agregada a " .. djName})
	else
		R.AddSongToDJ:FireClient(player, {success = false, message = message or "La canción ya existe"})
	end
end)

-- REMOVE FROM LIBRARY
R.RemoveSongFromLibrary.OnServerEvent:Connect(function(player, audioId)
	if not MusicConfig:HasPermission(player.UserId, "RemoveFromLibrary") then
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: REMOVE_LIBRARY | Reason: Insufficient permissions | Action: SKIP")
		return 
	end

	local id = tonumber(audioId)
	if not id then
		warn("[VALIDATION_ERROR] Invalid Audio ID format | Input:", audioId, "| Action: SKIP")
		return
	end

	local success, djName, songName = removeSongFromLibrary(id, player.Name)

	if success then
		updateLibrary()
		if R.RemoveSongFromLibrary then
			R.RemoveSongFromLibrary:FireClient(player, {
				success = true, 
				message = "[SUCCESS] Song removed: " .. songName .. " from " .. djName
			})
		end
	else
		if R.RemoveSongFromLibrary then
			R.RemoveSongFromLibrary:FireClient(player, {
				success = false, 
				message = "[ERROR] Song not found"
			})
		end
	end
end)

-- GET LIBRARY
R.GetLibrary.OnServerEvent:Connect(function(player)
	updateAllClients()
end)

-- REMOVE DJ
R.RemoveDJ.OnServerEvent:Connect(function(player, djName)
	if not MusicConfig:HasPermission(player.UserId, "RemoveDJ") then
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: REMOVE_DJ | Reason: Insufficient permissions | Action: SKIP")
		return
	end

	if not djName or djName == "" then
		warn("[VALIDATION_ERROR] Invalid DJ name | Input:", djName, "| Action: SKIP")
		return
	end

	local success, message = removeDJ(djName, player.Name)

	if success then
		updateLibrary()
		if R.RemoveDJ then
			R.RemoveDJ:FireClient(player, {
				success = true,
				message = message
			})
		end
	else
		if R.RemoveDJ then
			R.RemoveDJ:FireClient(player, {
				success = false,
				message = message
			})
		end
	end
end)

-- RENAME DJ
R.RenameDJ.OnServerEvent:Connect(function(player, oldName, newName)
	if not MusicConfig:HasPermission(player.UserId, "RenameDJ") then
		warn("[PERMISSION_DENIED] Player:", player.Name, "| Action: RENAME_DJ | Reason: Insufficient permissions | Action: SKIP")
		return
	end

	if not oldName or oldName == "" then
		warn("[VALIDATION_ERROR] Invalid old DJ name | Input:", oldName, "| Action: SKIP")
		return
	end

	if not newName or newName == "" then
		warn("[VALIDATION_ERROR] Invalid new DJ name | Input:", newName, "| Action: SKIP")
		return
	end

	local success, message = renameDJ(oldName, newName, player.Name)

	if success then
		updateLibrary()
		if R.RenameDJ then
			R.RenameDJ:FireClient(player, {
				success = true,
				message = message,
				oldName = oldName,
				newName = newName
			})
		end
	else
		if R.RenameDJ then
			R.RenameDJ:FireClient(player, {
				success = false,
				message = message
			})
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- AUTO EVENTS
-- ════════════════════════════════════════════════════════════════
soundObject.Ended:Connect(function()
	if isPlaying then
		local currentSong = getCurrentSong()
		if currentSong then
			print("[PLAYBACK_END] Song finished | Song:", currentSong.name, "| Audio ID:", currentSong.id, "| Queue index:", currentSongIndex)
		end
		
		-- Fade-out suave antes de cambiar de canción
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
-- PLAYER EVENTS - Actualizar UI cuando un jugador entra
-- ════════════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Esperar a que el cliente cargue
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