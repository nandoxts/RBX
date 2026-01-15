local module = {}
-- Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
-----------------------------------------------------------------------------------
--> Modules
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Panda ServerScriptService")
local configuration = require(ServerScriptService.Configuration)
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)
local ModulePermisos = require(ServerScriptService.Effects.ColorEffectsModule)
-----------------------------------------------------------------------------------

local GROUP_ID = configuration.GroupID
local ALLOWED_RANKS = configuration.ALLOWED_DJ_RANKS
local ALLOWED_RANKS_EVENT = configuration.ALLOWED_RANKS_EVENTS

local function hasPermission(player)
	return ModulePermisos.hasPermission(player, GROUP_ID, ALLOWED_RANKS)
end
-----------------------------------------------------------------------------------

-- Cache para optimización
local validatedMusicIds = {} -- Cache para IDs de música validados
local specialPlayersCache = {} -- Cache para jugadores especiales
local musicInfoCache = {} -- Cache para información de música

-- Función para obtener el nombre de la música con cache
local function getMusicName(musicId)
	if musicInfoCache[musicId] and musicInfoCache[musicId].name then
		return musicInfoCache[musicId].name
	end

	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(musicId)
	end)

	if success then
		musicInfoCache[musicId] = {
			name = info.Name,
			AssetTypeId = info.AssetTypeId
		}
		return info.Name
	end

	return "Canción"..musicId
end

-- Función para normalizar una lista de nombres a minúsculas
local function normalizeList(list)
	local normalizedList = {}
	for _, name in ipairs(list) do
		table.insert(normalizedList, string.lower(name))
	end
	return normalizedList
end

-- Variables de configuración
local VIP = configuration.VIP
local VIPPLUS = configuration.VIPPLUS

local cooldownNormal = configuration.NormalUser
local cooldownVip = configuration.VipUser
local cooldownVipPlus = configuration.VipPlusUser
local cooldownPreference = configuration.PreferenceUser

-- Variables de estado
local x = {}
local Queue = {}
local _songMusicTable = {}
local savedStatus = {}
local savedHistory = {}
local savedMusicId = 0
local cooldown = {}
local skipCooldown = {}
local isResetting = false
local skipRequested = false
local skipPending = false
local currentMusicId = nil
local randomMusicList = {}
local isRandomPlaylistPlaying = false
local eventMode = false
local eventCommandCooldown = {}
local chatListeners = {}
-------------------------------------------- NUEVO 27-04-25
local lastCleanTime = 0
local CLEAN_COOLDOWN = 30 -- Segundos entre limpiezas para prevenir abuso
--------------------------------------------
local isLooping = false
--------------------------------------------

-- Remotes
local _updateRol = ReplicatedStorage:FindFirstChild("Music"):FindFirstChild("_updateRol")
local Remotes = ReplicatedStorage:WaitForChild("Music")
local _sendRequest = Remotes:WaitForChild("_sendRequest")
local _getQueue = Remotes:WaitForChild("_getQueue")
local _newMusic = Remotes:WaitForChild("_newMusic")
local _queueUpdated = Remotes:WaitForChild("_queueUpdated")
local _skipRequest = Remotes:WaitForChild("_skipRequest")
local _currentSong = Remotes:WaitForChild("_currentSong") 
local _updateQueueUI = Remotes:WaitForChild("_updateQueueUI")
local _loopMusic = Remotes:WaitForChild("_loopMusic")
local _loopStatus = Remotes:WaitForChild("_loopStatus")
local _resetMusic = Remotes:WaitForChild("_resetMusic")
-- Sound
local Musica = SoundService:WaitForChild("THEME")

-- Función optimizada para verificar jugadores especiales
local function isPlayerInSpecialList(player)
	return hasPermission(player)
end

-- Función para comandos de admin
local function canUseAdminCommands(player)
	return isPlayerInSpecialList(player)
end

-- Función para generar una lista aleatoria de IDs de música
local function generateRandomMusicList()
	randomMusicList = {}
	for _, id in ipairs(configuration.MusicList) do
		table.insert(randomMusicList, id)
	end
	-- Mezclar la lista aleatoriamente
	for i = #randomMusicList, 2, -1 do
		local j = math.random(i)
		randomMusicList[i], randomMusicList[j] = randomMusicList[j], randomMusicList[i]
	end
end

-- Función para reproducir la lista aleatoria
local function playRandomMusic()
	if #randomMusicList == 0 then
		generateRandomMusicList()
	end

	local nextMusicId = table.remove(randomMusicList, 1)
	table.insert(Queue, nextMusicId)
	savedHistory[nextMusicId] = {
		id = nextMusicId,
		user = "Dev. Panda15Fps",
		name = getMusicName(nextMusicId)
	}

	x.id = nextMusicId
	_queueUpdated:FireAllClients(#Queue)
	_updateQueueUI:FireAllClients(Queue, savedHistory) -- Asegurar que se notifique a la UI
	isRandomPlaylistPlaying = true

end

-- Función para verificar si la ID de la música es válida
local function isValidMusicId(id)
	if validatedMusicIds[id] ~= nil then
		return validatedMusicIds[id]
	end

	local success, result = pcall(function()
		if musicInfoCache[id] then
			return musicInfoCache[id]
		end

		local info = MarketplaceService:GetProductInfo(id)
		musicInfoCache[id] = info
		return info
	end)

	validatedMusicIds[id] = success and musicInfoCache[id].AssetTypeId == 3
	return validatedMusicIds[id]
end

------------------------------------------ NUEVO 27-04-25 ------------------------------------------------
-- Función para limpieza completa del sistema de música
function module:cleanMusicSystem(initiator)
	-- Verificar cooldown
	local currentTime = os.time()
	if currentTime - lastCleanTime < CLEAN_COOLDOWN then
		return false, "⏳ Espera "..(CLEAN_COOLDOWN - (currentTime - lastCleanTime)).." segundos antes de otra limpieza."
	end
	lastCleanTime = currentTime

	-- 1. Detener y resetear el sonido actual de forma segura
	pcall(function()
		Musica:Stop()
		Musica.TimePosition = 0
		Musica.SoundId = "rbxassetid://0"
	end)

	-- 2. Limpiar todas las colas y tablas internas
	Queue = {}
	_songMusicTable = {}
	savedMusicId = 0
	skipRequested = false
	skipPending = false
	currentMusicId = nil

	-- 4. Resetear estados del sistema
	isRandomPlaylistPlaying = false
	isResetting = false

	-- 5. Reconstruir conexiones esenciales
	module:_newMusic() -- Reestablecer los eventos Ended y Playing

	-- 6. Iniciar playlist automático
	generateRandomMusicList() -- Regenerar lista por si estaba corrupta
	playRandomMusic()

	-- 7. Notificar a todos los clientes
	_queueUpdated:FireAllClients(0)
	_updateQueueUI:FireAllClients({}, {})
	_newMusic:FireAllClients(0, "Dev. Panda15Fps")

	return true, "✅ Sistema de música reiniciado completamente."
end

------------------------------------------------------------------------------------------------------

-- Sistema de comandos de chat optimizado
local function handleChatMessage(player, message)
	if string.sub(message, 1, 1) == ";" then
		local command = string.sub(message:lower(), 2)
		local currentTime = os.time()

		-- Comandos de pitch (nuevos)
		if command:sub(1,7) == "pitchup" then
			if canUseAdminCommands(player) then
				local increment = tonumber(command:sub(9))
				if increment and increment > 0 then
					local currentSpeed = Musica.PlaybackSpeed or 1
					local newSpeed = currentSpeed + increment

					if newSpeed > 2 then
						newSpeed = 2
					end

					Musica.PlaybackSpeed = newSpeed
				end
			end
			return
		elseif command:sub(1,8) == "pitchlow" then
			if canUseAdminCommands(player) then
				local decrement = tonumber(command:sub(10))
				if decrement and decrement > 0 then
					local currentSpeed = Musica.PlaybackSpeed or 1
					local newSpeed = currentSpeed - decrement

					if newSpeed < 0.5 then
						newSpeed = 0.5
					end

					Musica.PlaybackSpeed = newSpeed
				end
			end
			return
		elseif command == "pitch default" then
			if canUseAdminCommands(player) then
				Musica.PlaybackSpeed = 1
			end
			return
		end

		if command:sub(1, 6) == "musics" then
			if canUseAdminCommands(player) then
				local idsString = command:sub(7):gsub("%s+", "") -- Eliminar espacios
				local ids = {}

				for id in string.gmatch(idsString, "([^,]+)") do
					if not table.find(ids, id) then
						table.insert(ids, id)
					end
				end

				if #ids == 0 then
					return
				end

				local added = 0
				local duplicates = 0
				local invalid = 0

				for _, id in ipairs(ids) do
					if table.find(Queue, id) then
						duplicates = duplicates + 1
						continue
					end

					if not isValidMusicId(id) then
						invalid = invalid + 1
						continue
					end

					if table.find(configuration.MusicBanned, tonumber(id)) then
						invalid = invalid + 1
						continue
					end

					table.insert(Queue, id)
					table.insert(_songMusicTable, id)

					savedHistory[id] = {
						id = id,
						user = player.Name,
						name = getMusicName(id)
					}

					added = added + 1
				end

				if added > 0 then
					_updateQueueUI:FireAllClients(Queue, savedHistory)
					x.id = Queue[#Queue] -- Actualizar la reproducción
					_queueUpdated:FireAllClients(#Queue)

					if isRandomPlaylistPlaying then
						isRandomPlaylistPlaying = false
					end
				end
			end
			return
		end

		------------------------------------------------ NUEVO 27-04-25 ------------------------------------------------------
		-- Comando !cleanmusic
		if (command == "cleanmusic") and canUseAdminCommands(player) then
			local success, result = module:cleanMusicSystem(player.Name)
			return
		end
		------------------------------------------------------------------------------------------------------

		-- Comando !skipp
		if command == "skipp" and canUseAdminCommands(player) then
			if isPlayerInSpecialList(player) then
				if not skipPending then
					skipPending = true
					task.delay(1, function() skipPending = false end)

					if #Queue > 0 then
						local nextMusicId = Queue[1]
						currentMusicId = nextMusicId
						module:_resetMusic(nextMusicId)
					else
						if not isRandomPlaylistPlaying then
							playRandomMusic()
						end
					end
				end
			end
			return
		end

		if (command == "resetmusic" or command == "reset music") and canUseAdminCommands(player) then
			if #Queue > 0 then
				Musica.TimePosition = 0
				Musica:Play()
			else
				playRandomMusic()
			end
			return
		end

		-- Comando !clearplaylist
		if command == "clearplaylist" and canUseAdminCommands(player) then
			Queue = {}
			_songMusicTable = {}

			for id, _ in pairs(savedHistory) do
				if table.find(Queue, id) then
					savedHistory[id] = nil
				end
			end

			pcall(function()
				Musica:Stop()
				Musica.TimePosition = 0
				Musica.SoundId = "rbxassetid://0"
			end)

			playRandomMusic()
			return
		end

		-- Comando !eventon
		if command == "eventon" and canUseAdminCommands(player) then
			if not eventCommandCooldown[player.UserId] or (currentTime - eventCommandCooldown[player.UserId] >= 10) then
				eventCommandCooldown[player.UserId] = currentTime
				eventMode = true
				_queueUpdated:FireAllClients("🔊 MODO EVENTO ACTIVADO - SOLO EL PERSONAL SELECCIONADO PUEDE AÑADIR MUSICA.")
			end
		elseif command == "eventoff" and canUseAdminCommands(player) then
			if not eventCommandCooldown[player.UserId] or (currentTime - eventCommandCooldown[player.UserId] >= 10) then
				eventCommandCooldown[player.UserId] = currentTime
				eventMode = false
				_queueUpdated:FireAllClients("🔊 MODO EVENTO DESACTIVADO - SE LIBRE DE PONER EL RITMO")
			end
		end

	end
end

function module:_resetMusic(id)
	table.remove(Queue, 1)
	if savedHistory[id] then
		savedHistory[id] = nil
	end
	Musica.TimePosition = 0
	Musica.SoundId = " "
	_queueUpdated:FireAllClients(#Queue)
	_updateQueueUI:FireAllClients(Queue, savedHistory)
	x.__newindex()
end

function x.__newindex(self, index, value)
	pcall(function()
		if #Queue > 1 then
			if "rbxassetid://"..Queue[1] == savedMusicId then
				return
			end
		end

		if #Queue == 0 then
			if not isRandomPlaylistPlaying then
				playRandomMusic()
			end
			return
		end

		if savedMusicId ~= Queue[1] then
			savedMusicId = Queue[1]

			skipRequested = false

			local success, errorMessage = pcall(function()
				Musica.SoundId = "rbxassetid://"..Queue[1]
				Musica:Play()
				isRandomPlaylistPlaying = false
			end)

			if not success then
				if string.find(errorMessage, "Asset is not approved for the requester") then
					module:_resetMusic(Queue[1])
				end
				return
			end

			local musicInfo = savedHistory[Queue[1]] or {user = "Dev. Panda15Fps"}
			_newMusic:FireAllClients(Queue[1], musicInfo.user)
			_currentSong:FireAllClients(Queue[1], musicInfo.user)
		end
	end)
end

function module:_newMusic()
	Musica.Ended:Connect(function()
		if isLooping and #Queue > 0 then
			local currentId = Queue[1]
			Musica:Stop()
			Musica.TimePosition = 0
			Musica:Play()
			return
		end

		module:_resetMusic(Queue[1])
		if #Queue == 0 then
			playRandomMusic()
		end
	end)
end

function module:_newPlayer()
	Players.PlayerAdded:Connect(function(plr)
		local _VIP = GamepassManager.HasGamepass(plr, VIP)
		local _VIPPLUS = GamepassManager.HasGamepass(plr, VIPPLUS)

		if _VIP then
			plr:SetAttribute("VIP", true)
		end

		if _VIPPLUS then
			plr:SetAttribute("VIPPLUS", true)
		end

		if chatListeners[plr.UserId] then
			chatListeners[plr.UserId]:Disconnect()
		end

		chatListeners[plr.UserId] = plr.Chatted:Connect(function(message)
			handleChatMessage(plr, message)
		end)

		plr.AncestryChanged:Connect(function()
			if not plr:IsDescendantOf(game) then
				if chatListeners[plr.UserId] then
					chatListeners[plr.UserId]:Disconnect()
					chatListeners[plr.UserId] = nil
				end
			end
		end)

		task.wait(1)
		_updateQueueUI:FireClient(plr, Queue, savedHistory)
	end)
end

function module:Init()
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			if savedStatus[plr.UserId] ~= nil then
				char:SetAttribute("MUSIC_MODE", savedStatus[plr.UserId])
			elseif savedStatus[plr.UserId] == nil then
				char:SetAttribute("MUSIC_MODE", true)
				savedStatus[plr.UserId] = true
			end
		end)
	end)

	_getQueue.OnServerInvoke = function(plr:Player)
		local queueInfo = {}
		for position, musicId in ipairs(Queue) do
			table.insert(queueInfo, {
				position = position,
				id = musicId,
				name = getMusicName(musicId),
				user = savedHistory[musicId] and savedHistory[musicId].user or "Dev. Panda15Fps"
			})
		end
		return queueInfo
	end

	x.__index = x
	local _songMusicTable = setmetatable(x, {
		__newindex = function(self, index, value)
			x.__newindex(self, index, value)
		end
	})

	module:_newPlayer()
	module:_newMusic()

	generateRandomMusicList()
	playRandomMusic()

	_sendRequest.OnServerInvoke = function(player:Player, id:number)
		if player and id then
			if table.find(configuration.MusicBanned, tonumber(id)) then
				return false, "❌ Esta canción está bloqueada y no se puede reproducir."
			end

			if not isValidMusicId(id) then
				return false, "❌ El ID de la música no es válido."
			end

			if eventMode and not isPlayerInSpecialList(player) then
				return false, "❌ Modo evento activado. Solo usuarios preferenciales pueden añadir música."
			end

			local tiempoEspera = cooldownNormal
			if isPlayerInSpecialList(player) then
				tiempoEspera = cooldownPreference
			elseif player:GetAttribute("VIPPLUS") then
				tiempoEspera = cooldownVipPlus
			elseif player:GetAttribute("VIP") then
				tiempoEspera = cooldownVip
			end

			local tiempoActual = os.time()
			if cooldown[player.UserId] and (tiempoActual - cooldown[player.UserId]) < tiempoEspera then
				local tiempoRestante = tiempoEspera - (tiempoActual - cooldown[player.UserId])
				return false, "⏳ Espera "..tiempoRestante.." segundos."
			end

			cooldown[player.UserId] = tiempoActual

			if not table.find(Queue, id) then
				table.insert(Queue, id)
				table.insert(_songMusicTable, id)

				savedHistory[id] = {
					id = id,
					user = player.Name,
					name = getMusicName(id)
				}

				_updateQueueUI:FireAllClients(Queue, savedHistory)

				x.id = id
				_queueUpdated:FireAllClients(#Queue)

				if isRandomPlaylistPlaying then
					isRandomPlaylistPlaying = false
				end

				return true, "✅ Canción añadida correctamente!"
			end
		end
		return false, "❌ No se pudo agregar la música a la cola."
	end
	
	_skipRequest.OnServerEvent:Connect(function(player, skipComprado)

		if not skipComprado then
			if not isPlayerInSpecialList(player) then
				return
			end
		end

		if not skipPending then
			skipPending = true
			task.delay(1, function() skipPending = false end)

			if #Queue > 0 then
				local nextMusicId = Queue[1]
				currentMusicId = nextMusicId
				module:_resetMusic(nextMusicId)

				print("Música saltada por "..player.Name.." (skip "..(skipComprado and "pagado" or "normal")..")")

			else
				if not isRandomPlaylistPlaying then
					playRandomMusic()
					print("Reproducción aleatoria iniciada por "..player.Name)
				end
			end
		end
	end)

	
	--[[
	_skipRequest.OnServerEvent:Connect(function(player)
		if isPlayerInSpecialList(player) then
			if not skipPending then
				skipPending = true
				task.delay(1, function() skipPending = false end)

				if #Queue > 0 then
					local nextMusicId = Queue[1]
					currentMusicId = nextMusicId
					module:_resetMusic(nextMusicId)
				else
					if not isRandomPlaylistPlaying then
						playRandomMusic()
					end
				end
			end
		end
	end)
	]]

	_loopMusic.OnServerEvent:Connect(function(player)
		if isPlayerInSpecialList(player) then
			isLooping = not isLooping

			if isLooping then
				_queueUpdated:FireAllClients("🔁 Loop activado")
				_loopStatus:FireAllClients(true)
			else
				_queueUpdated:FireAllClients("⏹️ Loop desactivado")
				_loopStatus:FireAllClients(false)
			end
		end
	end)

	_resetMusic.OnServerEvent:Connect(function(player)
		if canUseAdminCommands(player) then
			if #Queue > 0 then
				Musica.TimePosition = 0
				Musica:Play()
				_queueUpdated:FireAllClients("⏮️ Música reiniciada por "..player.Name)
			else
				playRandomMusic()
				_queueUpdated:FireAllClients("▶️ Playlist automática iniciada por "..player.Name)
			end
		end
	end)
end

return module