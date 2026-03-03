-- ════════════════════════════════════════════════════════════════
-- DJ MUSIC SYSTEM
-- by ignxts | refactored by Sistema
-- OPTIMIZED: Cached audio validation, unified song-end detection,
--            metadata cache with LRU eviction, batched client updates,
--            race condition fixes — ready for 200+ players
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local SoundService       = game:GetService("SoundService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService         = game:GetService("RunService")

local MusicConfig    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local Systems        = ServerScriptService:WaitForChild("Systems")
local Configuration  = require(Systems:WaitForChild("Configuration"))
local GamepassManager = require(Systems:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))

-- ════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ════════════════════════════════════════════════════════════════
local VIP_ID            = Configuration.VIP
local DEV_USER_ID       = 8387751399
local DEV_DISPLAY_NAME  = "Sistema"
local ASSET_PREFIX      = "rbxassetid://"
local DEFAULT_PITCH     = 1
local DEFAULT_VOLUME    = MusicConfig:GetDefaultVolume() or 0.5
local LOAD_TIMEOUT      = 12
local PLAY_CHECK_DELAY  = 0.5
local TRANSITION_DELAY  = 0.3
local MAX_RANDOM_RETRIES = 5

-- [OPT] Cache limits
local MAX_METADATA_CACHE = 2000
local MAX_AUDIO_PERM_CACHE = 500
local AUDIO_PERM_CACHE_TTL = 600 -- 10 minutes

-- [OPT] Batched update constants
local UPDATE_BATCH_INTERVAL = 0.2 -- Max update frequency to clients

local RC = {
	SUCCESS      = "SUCCESS",
	INVALID_ID   = "ERROR_INVALID_ID",
	BLACKLISTED  = "ERROR_BLACKLISTED",
	DUPLICATE    = "ERROR_DUPLICATE",
	NOT_FOUND    = "ERROR_NOT_FOUND",
	NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED",
	QUEUE_FULL   = "ERROR_QUEUE_FULL",
	PERMISSION   = "ERROR_PERMISSION",
	COOLDOWN     = "ERROR_COOLDOWN",
	UNKNOWN      = "ERROR_UNKNOWN",
	EVENT_LOCKED = "ERROR_EVENT_LOCKED",
}

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local musicDatabase   = {}
local djOrder         = {
	"Top Hits", "Reggaeton", "Mix Brazil", "Kpop Army",
	"DJ Angelisai", "DJ AngeloGarcia", "Hora Loca", "Rock",
	"Reparto", "Phonk", "Vallenatos", "Mix Argentina",
	"Electronica", "Romanticas", "Mixes Djs", "Mix chile",
	"DJ Alex", "DJ SPARTAN", "DJ POOLEX", "Cumbia", "Salsa",
}
local playQueue       = {}
local currentSongIndex = 1
local isPlaying       = false
local isPaused        = false
local isTransitioning = false
local currentPlayingId = nil
local metadataCache   = {}
local playerCooldowns = {}
local pitchLookup     = {}

-- [OPT] Audio permission cache: {[audioId] = {canPlay = bool, timestamp = number}}
local audioPermCache = {}
local audioPermCacheOrder = {} -- LRU order

-- [OPT] Metadata cache LRU tracking
local metadataCacheOrder = {}

-- [OPT] Batched update state
local updatePending = false
local lastUpdateSent = 0

-- [OPT] Song-end detection: single mechanism flag
local songEndHandled = false

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesGlobal")
if not remotesFolder then warn("RemotesGlobal not found") return end

local function getRemote(folder, name)
	local f = remotesFolder:FindFirstChild(folder)
	return f and f:FindFirstChild(name)
end

local R = {
	Play            = getRemote("MusicPlayback", "PlaySong"),
	Next            = getRemote("MusicPlayback", "NextSong"),
	Stop            = getRemote("MusicPlayback", "StopSong"),
	ChangeVolume    = getRemote("MusicPlayback", "ChangeVolume"),
	Update          = getRemote("UI", "UpdateUI"),
	AddToQueue      = getRemote("MusicQueue", "AddToQueue"),
	AddResponse     = getRemote("MusicQueue", "AddToQueueResponse"),
	RemoveFromQueue = getRemote("MusicQueue", "RemoveFromQueue"),
	RemoveResponse  = getRemote("MusicQueue", "RemoveFromQueueResponse"),
	ClearQueue      = getRemote("MusicQueue", "ClearQueue"),
	ClearResponse   = getRemote("MusicQueue", "ClearQueueResponse"),
	PurchaseSkip    = getRemote("MusicQueue", "PurchaseSkip"),
	GetDJs          = getRemote("MusicLibrary", "GetDJs"),
	GetSongsByDJ    = getRemote("MusicLibrary", "GetSongsByDJ"),
	GetSongMetadata = getRemote("MusicLibrary", "GetSongMetadata"),
	SearchSongs     = getRemote("MusicLibrary", "SearchSongs"),
	GetSongRange    = getRemote("MusicLibrary", "GetSongRange"),
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
local function loadPitchModule()
	local pitchModuleScript = script.Parent:FindFirstChild("PitchModule")
	if not pitchModuleScript then return end
	local ok, pitchModule = pcall(require, pitchModuleScript)
	if not ok or type(pitchModule) ~= "table" or not pitchModule.ids then return end
	for _, entry in ipairs(pitchModule.ids) do
		if entry.id and entry.pitch then
			pitchLookup[ASSET_PREFIX .. tostring(entry.id)] = tonumber(entry.pitch) or DEFAULT_PITCH
		end
	end
end

local function applyPitch()
	soundObject.PlaybackSpeed = pitchLookup[soundObject.SoundId] or DEFAULT_PITCH
end

loadPitchModule()
soundObject:GetPropertyChangedSignal("SoundId"):Connect(function()
	task.delay(0.05, applyPitch)
end)

-- ════════════════════════════════════════════════════════════════
-- UTILITY LAYER
-- ════════════════════════════════════════════════════════════════
local function response(code, msg, data)
	return { code = code, success = code == RC.SUCCESS, message = msg, data = data or {}, timestamp = os.time() }
end

local function fireClient(remote, player, data)
	if remote then pcall(remote.FireClient, remote, player, data) end
end

local function adjustIndex()
	if currentSongIndex > #playQueue then
		currentSongIndex = 1
	end
end

local function getAllDJs()
	local list = {}
	for _, name in ipairs(djOrder) do
		local data = musicDatabase[name]
		if data then
			table.insert(list, {
				name      = name,
				cover     = data.cover or "",
				userId    = data.userId,
				songCount = #(data.songIds or {}),
			})
		end
	end
	return list
end

-- [OPT] Cached DJ list — only rebuild when database changes
local cachedDJList = nil
local djListDirty = true

local function getCachedDJList()
	if djListDirty or not cachedDJList then
		cachedDJList = getAllDJs()
		djListDirty = false
	end
	return cachedDJList
end

-- [OPT] Batched updateAllClients — coalesces rapid updates
local function buildUpdatePacket()
	local currentSong = (#playQueue > 0 and currentSongIndex <= #playQueue) and playQueue[currentSongIndex] or nil
	return {
		queue       = playQueue,
		currentSong = currentSong,
		djs         = getCachedDJList(),
		isPlaying   = isPlaying,
		isPaused    = isPaused,
		currentIndex = currentSongIndex,
		queueLength = #playQueue,
		timestamp   = os.time(),
	}
end

local function sendUpdateNow()
	if not R.Update then return end
	local packet = buildUpdatePacket()
	local players = Players:GetPlayers()

	-- [OPT] For 200+ players, fire in small batches to avoid frame spikes
	local BATCH = 50
	for i = 1, #players, BATCH do
		for j = i, math.min(i + BATCH - 1, #players) do
			fireClient(R.Update, players[j], packet)
		end
		if i + BATCH <= #players then
			task.wait() -- yield once per batch to spread network load
		end
	end

	lastUpdateSent = tick()
	updatePending = false
end

local function updateAllClients()
	local now = tick()
	if (now - lastUpdateSent) >= UPDATE_BATCH_INTERVAL then
		sendUpdateNow()
	elseif not updatePending then
		updatePending = true
		task.delay(UPDATE_BATCH_INTERVAL - (now - lastUpdateSent), function()
			if updatePending then sendUpdateNow() end
		end)
	end
end

-- Force immediate update (for critical state changes like song start)
local function updateAllClientsImmediate()
	updatePending = false
	sendUpdateNow()
end

-- ════════════════════════════════════════════════════════════════
-- PERMISSION LAYER
-- ════════════════════════════════════════════════════════════════
local function hasPermission(player, action)
	return MusicConfig:HasPermission(player.UserId, action)
end

local function isEventBlocked(action, player)
	if not (_G.EventModeActive) then return false end
	if player and MusicConfig:IsAdmin(player) then return false end
	for _, blocked in ipairs(MusicConfig.EVENT_MODE.BlockedActions or {}) do
		if blocked == action then return true end
	end
	return false
end

local function checkAccess(player, action)
	if isEventBlocked(action, player) then
		return response(RC.EVENT_LOCKED, "Modo evento activo")
	end
	if not hasPermission(player, action) then
		return response(RC.PERMISSION, "Sin permiso")
	end
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- DATABASE LAYER
-- ════════════════════════════════════════════════════════════════
local function loadDJs()
	musicDatabase = {}
	local rawDJs = MusicConfig:GetDJs()
	for name, data in pairs(rawDJs) do
		local ids = {}
		for _, id in ipairs(data.SongIds or {}) do
			if type(id) == "number" then table.insert(ids, id) end
		end
		musicDatabase[name] = {
			cover     = data.ImageId or "",
			userId    = data.userId,
			songIds   = ids,
			songCount = #ids,
		}
		local found = false
		for _, n in ipairs(djOrder) do if n == name then found = true break end end
		if not found then table.insert(djOrder, name) end
	end
	djListDirty = true
end

local function findDJForSong(audioId)
	for djName, djData in pairs(musicDatabase) do
		for _, id in ipairs(djData.songIds or {}) do
			if id == audioId then return djName, djData.cover end
		end
	end
	return nil, nil
end

-- [OPT] Pre-built flat list for random song selection (rebuilt on loadDJs)
local flatSongList = nil

local function buildFlatSongList()
	flatSongList = {}
	for djName, djData in pairs(musicDatabase) do
		for _, id in ipairs(djData.songIds or {}) do
			table.insert(flatSongList, { id = id, dj = djName, djCover = djData.cover })
		end
	end
end

local function getRandomSongFromLibrary()
	if not flatSongList then buildFlatSongList() end
	if #flatSongList == 0 then return nil end
	return flatSongList[math.random(#flatSongList)]
end

local function isInQueue(audioId)
	if MusicConfig.LIMITS.AllowDuplicatesInQueue then return false end
	for _, s in ipairs(playQueue) do
		if s.id == audioId then return true, s end
	end
	return false
end

-- ════════════════════════════════════════════════════════════════
-- [OPT] LRU CACHE HELPERS
-- ════════════════════════════════════════════════════════════════
local function evictLRU(cache, order, maxSize)
	while #order > maxSize do
		local oldest = table.remove(order, 1)
		cache[oldest] = nil
	end
end

local function touchLRU(order, key)
	-- Move key to end (most recent)
	for i, k in ipairs(order) do
		if k == key then
			table.remove(order, i)
			break
		end
	end
	table.insert(order, key)
end

-- ════════════════════════════════════════════════════════════════
-- METADATA LAYER
-- ════════════════════════════════════════════════════════════════
local function getOrLoadMetadata(audioId)
	local cached = metadataCache[audioId]
	if cached and cached.loaded and not cached.error then
		touchLRU(metadataCacheOrder, audioId)
		return cached.name, cached.artist, true
	end

	local djName = findDJForSong(audioId)
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, audioId, Enum.InfoType.Asset)

	if ok and info and info.AssetTypeId == 3 then
		local name   = info.Name or ("Audio " .. audioId)
		local artist = (info.Creator and info.Creator.Name) or "Unknown"
		metadataCache[audioId] = { name = name, artist = artist, loaded = true }
		table.insert(metadataCacheOrder, audioId)
		evictLRU(metadataCache, metadataCacheOrder, MAX_METADATA_CACHE)
		return name, artist, true
	end

	if djName then
		return "Audio " .. audioId, djName, true
	end

	return nil, nil, false
end

local function loadMetadataBatch(ids, callback)
	if #ids == 0 then
		if callback then callback({}) end
		return
	end

	local BATCH_SIZE  = 5
	local BATCH_DELAY = 0.3
	local results = {}
	local pending = #ids

	for batchStart = 1, #ids, BATCH_SIZE do
		local batchEnd = math.min(batchStart + BATCH_SIZE - 1, #ids)
		for i = batchStart, batchEnd do
			local id = ids[i]
			task.spawn(function()
				local name, artist, ok = getOrLoadMetadata(id)
				results[id] = ok
					and { name = name, artist = artist, loaded = true }
					or  { name = "Audio " .. id, artist = "Unknown", loaded = true, error = true }
				pending = pending - 1
				if pending == 0 and callback then callback(results) end
			end)
		end
		if batchEnd < #ids then task.wait(BATCH_DELAY) end
	end
end

-- ════════════════════════════════════════════════════════════════
-- [OPT] AUDIO PERMISSION VALIDATOR — with cache
-- ════════════════════════════════════════════════════════════════
local function validateAudioPermission(audioId)
	-- Check cache first
	local cached = audioPermCache[audioId]
	if cached and (tick() - cached.timestamp) < AUDIO_PERM_CACHE_TTL then
		touchLRU(audioPermCacheOrder, audioId)
		return cached.canPlay
	end

	local testSound = Instance.new("Sound")
	testSound.SoundId = ASSET_PREFIX .. audioId
	testSound.Volume  = 0
	testSound.Parent  = SoundService

	local canPlay, done = false, false
	local conn
	conn = testSound.Loaded:Connect(function()
		canPlay = testSound.TimeLength > 0
		done    = true
		conn:Disconnect()
	end)

	local deadline = tick() + 5
	while not done and tick() < deadline do
		task.wait(0.1)
		if testSound.IsLoaded and testSound.TimeLength > 0 then
			canPlay = true
			done    = true
		end
	end

	if conn then conn:Disconnect() end
	testSound:Destroy()

	-- Store in cache
	audioPermCache[audioId] = { canPlay = canPlay, timestamp = tick() }
	table.insert(audioPermCacheOrder, audioId)
	evictLRU(audioPermCache, audioPermCacheOrder, MAX_AUDIO_PERM_CACHE)

	return canPlay
end

-- ════════════════════════════════════════════════════════════════
-- QUEUE VALIDATION
-- ════════════════════════════════════════════════════════════════
local function getUserQueueLimit(player)
	if MusicConfig:IsAdmin(player) then
		return MusicConfig.LIMITS.MaxSongsPerUserAdmin, "Admin"
	elseif GamepassManager.HasGamepass(player, VIP_ID) then
		return MusicConfig.LIMITS.MaxSongsPerUserVIP, "VIP"
	end
	return MusicConfig.LIMITS.MaxSongsPerUserNormal, "Normal"
end

local function validateQueueAdd(player, audioId)
	-- 1. Cooldown
	local cooldown = MusicConfig.LIMITS.AddToQueueCooldown or 2
	local last = playerCooldowns[player.UserId]
	local now  = tick()
	if last and (now - last) < cooldown then
		local wait = math.ceil(cooldown - (now - last))
		return nil, response(RC.COOLDOWN, "Espera " .. wait .. "s")
	end

	-- 2. ID format
	local id = tonumber(audioId)
	local idStr = id and tostring(id) or ""
	if not id or #idStr < 6 or #idStr > 19 then
		return nil, response(RC.INVALID_ID, "ID inválido")
	end

	-- 3. Blacklist
	local valid, err = MusicConfig:ValidateAudioId(id)
	if not valid then return nil, response(RC.BLACKLISTED, err) end

	-- 4. Global queue cap
	if #playQueue >= MusicConfig.LIMITS.MaxQueueSize then
		return nil, response(RC.QUEUE_FULL, "Cola llena (" .. #playQueue .. "/" .. MusicConfig.LIMITS.MaxQueueSize .. ")")
	end

	-- 5. Per-user cap
	local limit, role = getUserQueueLimit(player)
	local userCount = 0
	for _, song in ipairs(playQueue) do
		if song.userId == player.UserId then userCount = userCount + 1 end
	end
	if userCount >= limit then
		return nil, response(RC.QUEUE_FULL, "Límite alcanzado (" .. userCount .. "/" .. limit .. " como " .. role .. ")")
	end

	-- 6. Duplicate check early (before expensive operations)
	local dup, existing = isInQueue(id)
	if dup then
		return nil, response(RC.DUPLICATE, "Ya está en la cola", { songName = existing.name })
	end

	-- 7. Metadata (single call)
	local name, artist, metaOk = getOrLoadMetadata(id)
	if not metaOk then return nil, response(RC.NOT_FOUND, "Audio no encontrado") end

	-- 8. Audio permission (single call — now cached)
	if not validateAudioPermission(id) then
		return nil, response(RC.NOT_AUTHORIZED, "Audio bloqueado o sin permisos")
	end

	-- All clear — stamp cooldown and return resolved data
	playerCooldowns[player.UserId] = now
	return { id = id, name = name, artist = artist }, nil
end

-- ════════════════════════════════════════════════════════════════
-- PLAYBACK ENGINE
-- ════════════════════════════════════════════════════════════════
local playSong, nextSong, playRandomSong   -- forward declarations

local function cleanupSound()
	pcall(soundObject.Stop, soundObject)
	soundObject.SoundId      = ""
	soundObject.TimePosition = 0
	currentPlayingId = nil
	songEndHandled = false -- [OPT] Reset end flag
end

local function stopSong()
	cleanupSound()
	isPlaying     = false
	isPaused      = false
	isTransitioning = false
	updateAllClientsImmediate()
end

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
	songEndHandled = false -- [OPT] Reset

	if #playQueue == 0 then
		isPlaying = false
		isPaused  = false
		updateAllClientsImmediate()
		task.defer(playRandomSong)
		return
	end

	currentSongIndex = math.clamp(index or currentSongIndex, 1, #playQueue)
	local song = playQueue[currentSongIndex]
	currentPlayingId = song.id
	soundObject.Volume  = DEFAULT_VOLUME
	soundObject.SoundId = ASSET_PREFIX .. song.id

	local loaded      = false
	local thisPlayId  = song.id
	local loadConn

	local function startPlaying()
		if loaded or currentPlayingId ~= thisPlayId then
			if loadConn then loadConn:Disconnect() end
			return
		end
		loaded = true
		loadConn:Disconnect()

		task.wait(0.15)

		if soundObject.TimeLength == 0 then
			removeCurrentAndContinue()
			return
		end

		soundObject.TimePosition = 0
		pcall(soundObject.Play, soundObject)
		isPlaying = true
		isPaused  = false
		songEndHandled = false -- [OPT]
		updateAllClientsImmediate() -- Use immediate for song start

		task.delay(PLAY_CHECK_DELAY, function()
			if currentPlayingId ~= thisPlayId or not isPlaying or isPaused then return end
			if soundObject.TimePosition >= 0.1 then return end

			pcall(function()
				soundObject:Stop()
				task.wait(0.1)
				soundObject.TimePosition = 0
				soundObject:Play()
			end)

			task.delay(PLAY_CHECK_DELAY, function()
				if currentPlayingId == thisPlayId and isPlaying and not isPaused then
					if soundObject.TimePosition < 0.1 then nextSong() end
				end
			end)
		end)
	end

	loadConn = soundObject.Loaded:Connect(startPlaying)

	task.defer(function()
		if not loaded and currentPlayingId == thisPlayId and soundObject.IsLoaded then
			startPlaying()
		end
	end)

	task.delay(LOAD_TIMEOUT, function()
		if not loaded and currentPlayingId == thisPlayId then
			loaded = true
			if loadConn then loadConn:Disconnect() end
			removeCurrentAndContinue()
		end
	end)
end

playRandomSong = function()
	if #playQueue > 0 then
		currentSongIndex = 1
		task.defer(function() playSong(1) end)
		return
	end

	if isTransitioning then return end

	for attempt = 1, MAX_RANDOM_RETRIES do
		local randomSong = getRandomSongFromLibrary()
		if not randomSong then
			warn("[playRandomSong] Biblioteca vacía")
			return
		end

		local name, artist, metaOk = getOrLoadMetadata(randomSong.id)
		local canPlay = metaOk and validateAudioPermission(randomSong.id)

		if canPlay then
			table.insert(playQueue, {
				id          = randomSong.id,
				name        = name,
				artist      = artist,
				userId      = DEV_USER_ID,
				requestedBy = DEV_DISPLAY_NAME,
				addedAt     = os.time(),
				dj          = randomSong.dj,
				djCover     = randomSong.djCover,
				isAutoPlay  = true,
			})
			currentSongIndex = 1
			task.delay(TRANSITION_DELAY, function() playSong(1) end)
			return
		end

		warn(string.format("[playRandomSong] Intento %d/%d falló para id=%s", attempt, MAX_RANDOM_RETRIES, randomSong.id))
		task.wait(0.1)
	end

	warn("[playRandomSong] No se encontró canción válida tras " .. MAX_RANDOM_RETRIES .. " intentos")
end

nextSong = function()
	if isTransitioning then return end
	isTransitioning = true
	songEndHandled = true -- [OPT] Prevent double-fire

	cleanupSound()
	isPlaying = false
	isPaused  = false

	if #playQueue > 0 then
		table.remove(playQueue, currentSongIndex)
		adjustIndex()
	end

	updateAllClients()

	task.delay(#playQueue > 0 and TRANSITION_DELAY or 0.5, function()
		isTransitioning = false
		if #playQueue > 0 then
			playSong(currentSongIndex)
		else
			playRandomSong()
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- QUEUE MANAGEMENT
-- ════════════════════════════════════════════════════════════════
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
		updateAllClients()
	else
		updateAllClients()
	end

	return true, removed.name
end

local function clearQueue()
	if #playQueue == 0 then return false, 0 end

	if isPlaying and currentSongIndex <= #playQueue then
		-- [OPT] Fixed: safely keep current song regardless of index
		local currentSongData = playQueue[currentSongIndex]
		local count = #playQueue - 1
		playQueue = { currentSongData }
		currentSongIndex = 1
		updateAllClients()
		return true, count
	end

	local count = #playQueue
	playQueue = {}
	currentSongIndex = 1
	stopSong()
	task.defer(playRandomSong)
	return true, count
end

-- ════════════════════════════════════════════════════════════════
-- [OPT] UNIFIED SONG END DETECTION
-- Single polling mechanism + Ended signal, both gated by songEndHandled flag
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(0.4)
		if isPlaying and not isPaused and not isTransitioning and not songEndHandled then
			local len = soundObject.TimeLength
			local pos = soundObject.TimePosition
			if soundObject.SoundId ~= "" and len > 0 and currentPlayingId then
				if (len - pos) < 0.5 then
					songEndHandled = true -- [OPT] Gate: prevent Ended from also firing
					nextSong()
					task.wait(2)
				end
			end
		end
	end
end)

soundObject.Ended:Connect(function()
	-- [OPT] Only fire if polling hasn't already handled it
	if isPlaying and not isTransitioning and not songEndHandled then
		songEndHandled = true
		nextSong()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- LIBRARY HELPERS
-- ════════════════════════════════════════════════════════════════
local function getSongRange(djName, startIdx, endIdx)
	local dj = musicDatabase[djName]
	if not dj then return { songs = {}, total = 0 } end

	local ids = dj.songIds or {}
	startIdx = math.max(1, startIdx or 1)
	endIdx   = math.min(endIdx or (startIdx + 19), #ids)

	local songs, toLoad = {}, {}
	for i = startIdx, endIdx do
		local id = ids[i]
		if id then
			local c = metadataCache[id]
			table.insert(songs, {
				id      = id,
				index   = i,
				loaded  = c and c.loaded or false,
				name    = c and c.name   or "Cargando...",
				artist  = c and c.artist or ("ID: " .. id),
			})
			if not (c and c.loaded) then table.insert(toLoad, id) end
		end
	end

	return { songs = songs, total = #ids, startIndex = startIdx, endIndex = endIdx,
		hasMore = endIdx < #ids, idsToLoad = toLoad }
end

local function searchSongs(djName, query, maxResults)
	maxResults = maxResults or 50
	local dj = musicDatabase[djName]
	if not dj then return { songs = {}, total = 0, query = query } end

	local ids     = dj.songIds or {}
	local results = {}
	local qLower  = string.lower(query or "")
	local qNum    = tonumber(query)

	if qNum then
		for i, id in ipairs(ids) do
			if tostring(id):find(tostring(qNum), 1, true) then
				local c = metadataCache[id]
				table.insert(results, { id = id, index = i, loaded = c and c.loaded or false,
					name = c and c.name or ("Audio " .. id), artist = c and c.artist or "Unknown", matchType = "id" })
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
					local nameMatch   = string.lower(c.name):find(qLower, 1, true)
					local artistMatch = string.lower(c.artist or ""):find(qLower, 1, true)
					if nameMatch or artistMatch then
						table.insert(results, { id = id, index = i, loaded = true,
							name = c.name, artist = c.artist, matchType = "name" })
						if #results >= maxResults then break end
					end
				end
			end
		end
	end

	return { songs = results, total = #results, query = query, totalInDJ = #ids }
end

-- ════════════════════════════════════════════════════════════════
-- REMOTE HANDLERS
-- ════════════════════════════════════════════════════════════════

R.Play.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "PlaySong") then return end
	if isPaused then
		pcall(soundObject.Resume, soundObject)
		isPaused  = false
		isPlaying = true
		updateAllClientsImmediate()
	elseif #playQueue > 0 then
		playSong(currentSongIndex)
	else
		playRandomSong()
	end
end)

R.Next.OnServerEvent:Connect(function(player)
	local deny = checkAccess(player, "NextSong")
	if deny then return end
	print("Skip normal", player.DisplayName .. "(@" .. player.Name .. ")")
	nextSong()
end)

R.Stop.OnServerEvent:Connect(function(player)
	if not hasPermission(player, "StopSong") then return end
	stopSong()
end)

if R.ChangeVolume then
	R.ChangeVolume.OnServerEvent:Connect(function(player, volume)
		player:SetAttribute("MusicVolume", math.clamp(tonumber(volume) or 0.5, 0, 1))
	end)
end

if R.PurchaseSkip then
	R.PurchaseSkip.OnServerEvent:Connect(function(player)
		if isEventBlocked("NextSong", player) then return end
		print("Skip pagado", player.DisplayName .. "(@" .. player.Name .. ")")
		nextSong()
	end)
end

R.AddToQueue.OnServerEvent:Connect(function(player, audioId)
	local deny = checkAccess(player, "AddToQueue")
	if deny then return fireClient(R.AddResponse, player, deny) end

	local songData, err = validateQueueAdd(player, audioId)
	if err then return fireClient(R.AddResponse, player, err) end

	-- [OPT] Duplicate check moved into validateQueueAdd (step 6)
	-- Double-check right before insert for race conditions
	local dup, existing = isInQueue(songData.id)
	if dup then
		return fireClient(R.AddResponse, player, response(RC.DUPLICATE, "Ya está en la cola", { songName = existing.name }))
	end

	local djName, djCover = findDJForSong(songData.id)
	local songInfo = {
		id          = songData.id,
		name        = songData.name,
		artist      = songData.artist,
		userId      = player.UserId,
		requestedBy = player.Name,
		addedAt     = os.time(),
		dj          = djName,
		djCover     = djCover,
	}

	table.insert(playQueue, songInfo)
	fireClient(R.AddResponse, player, response(RC.SUCCESS, "Añadido", {
		songName = songInfo.name,
		artist   = songInfo.artist,
		position = #playQueue,
		songId   = songInfo.id, -- [OPT] Include songId for client card resolution
	}))
	updateAllClients()

	if not isPlaying and not isPaused and #playQueue == 1 then
		task.delay(TRANSITION_DELAY, function() playSong(1) end)
	end
end)

R.RemoveFromQueue.OnServerEvent:Connect(function(player, index)
	local deny = checkAccess(player, "RemoveFromQueue")
	if deny then return fireClient(R.RemoveResponse, player, deny) end

	local ok, name = removeFromQueue(index)
	fireClient(R.RemoveResponse, player, ok
		and response(RC.SUCCESS, "Eliminado", { songName = name })
		or  response(RC.INVALID_ID, "Índice inválido"))
end)

R.ClearQueue.OnServerEvent:Connect(function(player)
	local deny = checkAccess(player, "ClearQueue")
	if deny then return fireClient(R.ClearResponse, player, deny) end

	local ok, count = clearQueue()
	fireClient(R.ClearResponse, player, ok
		and response(RC.SUCCESS, "Limpiado", { clearedCount = count })
		or  response(RC.UNKNOWN, "Cola vacía"))
end)

R.GetDJs.OnServerEvent:Connect(function(player)
	fireClient(R.GetDJs, player, { djs = getCachedDJList() })
end)

R.GetSongsByDJ.OnServerEvent:Connect(function(player, djName)
	local dj = musicDatabase[djName]
	fireClient(R.GetSongsByDJ, player, { djName = djName, total = dj and #(dj.songIds or {}) or 0, songs = {} })
end)

R.GetSongRange.OnServerEvent:Connect(function(player, djName, startIdx, endIdx)
	local result = getSongRange(djName, startIdx, endIdx)
	result.djName = djName
	fireClient(R.GetSongRange, player, result)

	if result.idsToLoad and #result.idsToLoad > 0 then
		loadMetadataBatch(result.idsToLoad, function()
			local updated = getSongRange(djName, startIdx, endIdx)
			updated.djName  = djName
			updated.isUpdate = true
			fireClient(R.GetSongRange, player, updated)
		end)
	end
end)

R.SearchSongs.OnServerEvent:Connect(function(player, djName, query)
	local result = searchSongs(djName, query)
	result.djName = djName
	fireClient(R.SearchSongs, player, result)

	local idsToLoad = {}
	for _, song in ipairs(result.songs or {}) do
		if not (metadataCache[song.id] and metadataCache[song.id].loaded) then
			table.insert(idsToLoad, song.id)
		end
	end

	if #idsToLoad > 0 then
		loadMetadataBatch(idsToLoad, function()
			local updated = searchSongs(djName, query)
			updated.djName  = djName
			updated.isUpdate = true
			fireClient(R.SearchSongs, player, updated)
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
				results[id] = { name = "Cargando...", artist = "ID: " .. id, loaded = false }
			end
		end
	end
	fireClient(R.GetSongMetadata, player, { metadata = results, pending = #toLoad })

	if #toLoad > 0 then
		loadMetadataBatch(toLoad, function(loaded)
			fireClient(R.GetSongMetadata, player, { metadata = loaded, pending = 0, isUpdate = true })
		end)
	end
end)

-- ════════════════════════════════════════════════════════════════
-- PLAYER EVENTS
-- ════════════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function()
	task.defer(updateAllClients)
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil

	local removedAny = false
	local i = 1
	while i <= #playQueue do
		local song = playQueue[i]
		if song.userId == player.UserId and i ~= currentSongIndex then
			table.remove(playQueue, i)
			if i < currentSongIndex then currentSongIndex = currentSongIndex - 1 end
			removedAny = true
		else
			i = i + 1
		end
	end

	if removedAny then
		updateAllClients()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- [OPT] PERIODIC CLEANUP — Evict stale audio permission cache entries
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(120) -- Every 2 minutes
		local now = tick()
		local toRemove = {}
		for id, entry in pairs(audioPermCache) do
			if (now - entry.timestamp) > AUDIO_PERM_CACHE_TTL then
				table.insert(toRemove, id)
			end
		end
		for _, id in ipairs(toRemove) do
			audioPermCache[id] = nil
		end
		-- Rebuild order list (cheaper than scanning)
		if #toRemove > 0 then
			audioPermCacheOrder = {}
			for id, _ in pairs(audioPermCache) do
				table.insert(audioPermCacheOrder, id)
			end
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════════
loadDJs()
buildFlatSongList() -- [OPT] Pre-build flat list for random selection

task.delay(1, function()
	updateAllClientsImmediate()
	if #playQueue == 0 then playRandomSong() end
end)