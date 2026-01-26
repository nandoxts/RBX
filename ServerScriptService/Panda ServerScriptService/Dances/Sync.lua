--[[
    Sistema de Sincronización de Emotes
	-- by ignxts
    Arquitectura:
    - Cada jugador puede seguir a UN solo líder (Following)
    - Cada jugador puede tener MÚLTIPLES seguidores (Followers)
    - Cuando un líder cambia de animación, TODOS sus seguidores se actualizan
    - Cuando un líder sigue a otro, sus seguidores heredan la nueva animación
    
    Estructura de datos por jugador:
    {
        Animation = AnimationTrack | nil,      -- Animación actual
        AnimationName = string | nil,          -- Nombre del baile actual
        Following = Player | nil,              -- A quién sigo
        Followers = {Player},                  -- Quiénes me siguen
        Connections = {RBXScriptConnection},   -- Conexiones para cleanup
    }
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local Animaciones = require(ReplicatedStorage:WaitForChild("Emotes_Sync"):WaitForChild("Emotes_Modules"):WaitForChild("Animaciones"))
local Settings = require(script.Settings)

local Remotes = ReplicatedStorage:WaitForChild("Emotes_Sync")

-- Función auxiliar para crear RemoteEvents de forma segura
local function GetOrCreateRemoteEvent(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

-- Función auxiliar para crear RemoteFunctions de forma segura
local function GetOrCreateRemoteFunction(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

-- RemoteEvent principal para sync/unsync
local SyncRemote = GetOrCreateRemoteEvent(Remotes, "Sync")

-- RemoteEvent para reproducir animaciones
local PlayAnimationRemote = GetOrCreateRemoteEvent(Remotes, "PlayAnimation")

-- RemoteEvent para detener animaciones
local StopAnimationRemote = GetOrCreateRemoteEvent(Remotes, "StopAnimation")

-- RemoteEvent para notificar estado de sincronización a clientes
local SyncUpdate = GetOrCreateRemoteEvent(Remotes, "SyncUpdate")

-- RemoteEvent broadcast para líderes: servidor -> todos los clientes
local SyncBroadcast = GetOrCreateRemoteEvent(Remotes, "SyncBroadcast")

-- RemoteFunction para que el cliente consulte su estado de sincronización
local GetSyncState = GetOrCreateRemoteFunction(Remotes, "GetSyncState")

-- RemoteEvent para Dance Leader UI
local DanceLeaderEvent = GetOrCreateRemoteEvent(Remotes, "DanceLeaderEvent")

-- Configuración
local FADE_TIME = 0.3

-- Estado global de sincronización
local PlayerData = {}

-- Cache de animaciones: nombre -> assetId
local DanceCache = {}

-- Inicializar cache de bailes (una sola vez)
local function InitializeDanceCache()
	local sources = {Animaciones.Ids, Animaciones.Recomendado, Animaciones.Vip}
	for _, source in ipairs(sources) do
		for _, anim in pairs(source) do
			DanceCache[anim.Nombre] = "rbxassetid://" .. tostring(anim.ID)
		end
	end
end
InitializeDanceCache()

--------------------------------------------------------------------------------
-- UTILIDADES
--------------------------------------------------------------------------------

-- Validar que un jugador existe y tiene datos
local function IsValidPlayer(player)
	return player 
		and player.Parent == Players 
		and PlayerData[player] ~= nil
end

-- Implementación de GetSyncState RemoteFunction
GetSyncState.OnServerInvoke = function(player)
	if not IsValidPlayer(player) then
		return { isSynced = false, leaderName = nil }
	end
	local data = PlayerData[player]
	local isSynced = data and data.Following ~= nil
	local leaderName = (data and data.Following) and data.Following.Name or nil
	return { isSynced = isSynced, leaderName = leaderName }
end

-- Validar que un jugador puede bailar (tiene Character, Humanoid, etc.)
local function CanAnimate(player)
	if not IsValidPlayer(player) then return false end

	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then return false end

	local baileAnim = character:FindFirstChild("Baile")
	if not baileAnim then return false end

	return true
end

-- Obtener el líder raíz de una cadena de sincronización
-- Si A sigue a B y B sigue a C, el líder raíz de A es C
local function GetRootLeader(player)
	if not IsValidPlayer(player) then return nil end

	local visited = {}
	local current = player

	while current and PlayerData[current] and PlayerData[current].Following do
		-- Prevenir loops infinitos
		if visited[current] then
			warn("[EmotesSync] Loop detectado en cadena de sincronización")
			return current
		end
		visited[current] = true
		current = PlayerData[current].Following
	end

	return current
end

-- Obtener TODOS los seguidores de un jugador (recursivamente)
local function GetAllFollowers(player, visited)
	visited = visited or {}
	local allFollowers = {}

	if not IsValidPlayer(player) or visited[player] then 
		return allFollowers 
	end
	visited[player] = true

	local data = PlayerData[player]
	if not data or not data.Followers then return allFollowers end

	for _, follower in ipairs(data.Followers) do
		-- Validar que el seguidor siga siendo válido
		if IsValidPlayer(follower) and not visited[follower] then
			table.insert(allFollowers, follower)
			-- Obtener seguidores de este seguidor también
			local subFollowers = GetAllFollowers(follower, visited)
			for _, subFollower in ipairs(subFollowers) do
				table.insert(allFollowers, subFollower)
			end
		end
	end

	return allFollowers
end

-- Copiar tabla de manera segura (shallow copy)
local function ShallowCopy(tbl)
	local copy = {}
	for i, v in ipairs(tbl) do
		copy[i] = v
	end
	return copy
end

-- Remover un elemento de un array de manera segura
local function SafeRemoveFromArray(array, element)
	for i = #array, 1, -1 do
		if array[i] == element then
			table.remove(array, i)
		end
	end
end

-- Buscar jugador por nombre parcial
local function FindPlayerByName(partialName)
	if not partialName or partialName == "" then return nil end

	partialName = partialName:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #partialName) == partialName then
			return player
		end
	end
	return nil
end

-- Actualizar atributo de followers en el jugador (para Dance Leader System)
local function UpdateFollowerCount(player)
	if not IsValidPlayer(player) then return end

	local followerCount = #PlayerData[player].Followers
	pcall(function()
		player:SetAttribute("followers", followerCount)
	end)
end

-- Notificar a un jugador sobre quién lo sigue
local function NotifyFollowers(player)
	if not IsValidPlayer(player) then return end
	
	local followers = PlayerData[player].Followers
	if #followers > 0 then
		local followerNames = {}
		for _, follower in ipairs(followers) do
			if IsValidPlayer(follower) then
				table.insert(followerNames, follower.Name)
			end
		end
		
		if #followerNames > 0 then
			pcall(function()
				SyncUpdate:FireClient(player, {
					followerNotification = true,
					followerNames = followerNames
				})
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- SISTEMA DE ANIMACIONES
--------------------------------------------------------------------------------

-- Notificar al cliente sobre cambio de animación
local function NotifyClient(player, animationName)
	if not IsValidPlayer(player) then return end

	PlayerData[player].AnimationName = animationName

	pcall(function()
		if animationName then
			PlayAnimationRemote:FireClient(player, "playAnim", animationName)
		else
			StopAnimationRemote:FireClient(player)
		end
	end)

	-- Enviar actualización de sincronización al cliente (payload completo)
	pcall(function()
		local data = PlayerData[player]
		local isSynced = data and data.Following ~= nil
		local leaderName = (data and data.Following) and data.Following.Name or nil
		local leaderUserId = (data and data.Following) and data.Following.UserId or nil

		local speed = nil
		if data and data.Animation and data.Animation.Speed then
			speed = data.Animation.Speed
		end

		-- SIEMPRE enviar payload completo con todos los campos
		SyncUpdate:FireClient(player, { 
			isSynced = isSynced, 
			leaderName = leaderName, 
			leaderUserId = leaderUserId, 
			animationName = animationName, 
			speed = speed 
		})
	end)

	-- Si este player es líder raíz, planificar broadcast debounced a todos los clientes
	pcall(function()
		local rootLeader = GetRootLeader(player)
		if rootLeader == player then
			ScheduleLeaderBroadcast(player)
		end
	end)
end

-- Debounce/batching para broadcasts por líder
local PendingBroadcasts = {}
local BROADCAST_DEBOUNCE = 0.1 -- segundos

local function FireLeaderBroadcast(leader)
	local entry = PendingBroadcasts[leader]
	if not entry then return end
	PendingBroadcasts[leader] = nil

	-- construir payload tomando estado actual del leader
	if not IsValidPlayer(leader) then return end
	local data = PlayerData[leader]
	local payload = {
		leaderUserId = leader.UserId,
		animationName = data and data.AnimationName or nil,
		timePosition = (data and data.Animation) and data.Animation.TimePosition or 0,
		speed = (data and data.Animation) and data.Animation.Speed or 1,
		timestamp = os.time(),
	}

	pcall(function()
		SyncBroadcast:FireAllClients(payload)
	end)
end

function ScheduleLeaderBroadcast(leader)
	if not leader then return end
	-- reemplazar cualquier entrada existente
	if PendingBroadcasts[leader] then
		-- reiniciar timer: (we'll simply ignore because existing task will fire soon)
	else
		PendingBroadcasts[leader] = true
		task.delay(BROADCAST_DEBOUNCE, function()
			FireLeaderBroadcast(leader)
		end)
	end
end

-- Detener la animación de un jugador
local function StopPlayerAnimation(player)
	if not IsValidPlayer(player) then return end

	local data = PlayerData[player]
	if data.Animation then
		pcall(function()
			data.Animation:Stop(FADE_TIME)
			data.Animation:Destroy()
		end)
		data.Animation = nil
	end
	data.AnimationName = nil

	-- NOTA: NO enviamos SyncUpdate aquí porque puede interferir con Follow()
	-- El estado de sync se maneja en Follow(), Unfollow() y NotifyClient()
end

-- Reproducir una animación en un jugador específico
local function PlayAnimationOnPlayer(player, animationId, animationName, timePosition, speed)
	if not CanAnimate(player) then return false end

	timePosition = timePosition or 0
	speed = speed or 1

	local data = PlayerData[player]
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then return false end

	local baileAnim = character:FindFirstChild("Baile")
	if not baileAnim then return false end

	-- Detener animación actual
	StopPlayerAnimation(player)

	-- Configurar y reproducir nueva animación
	baileAnim.AnimationId = animationId

	local track = animator:LoadAnimation(baileAnim)
	track.Priority = Enum.AnimationPriority.Action
	track:Play(FADE_TIME)
	track.TimePosition = timePosition
	track:AdjustSpeed(speed)

	data.Animation = track
	data.AnimationName = animationName

	return true
end

-- Obtener followers válidos de un jugador
local function GetValidFollowers(player)
	if not IsValidPlayer(player) then return {} end

	local validFollowers = {}
	for _, follower in ipairs(PlayerData[player].Followers) do
		if IsValidPlayer(follower) then
			table.insert(validFollowers, follower)
		end
	end
	return validFollowers
end

-- Propagar animación a una cadena de followers recursivamente
local function PropagateToFollowerChain(followers, animId, animName, timePos, speed)
	for _, follower in ipairs(followers) do
		if IsValidPlayer(follower) and CanAnimate(follower) then
			if follower.Character and follower.Character.Parent then
				PlayAnimationOnPlayer(follower, animId, animName, timePos, speed)
				NotifyClient(follower, animName)

				-- Propagar a subfollowers
				local subFollowers = GetAllFollowers(follower)
				if #subFollowers > 0 then
					PropagateToFollowerChain(subFollowers, animId, animName, timePos, speed)
				end
			end
		end
	end
end

-- Detener animaciones de todos los seguidores
local function StopFollowersAnimations(leader)
	if not IsValidPlayer(leader) then return end

	local allFollowers = GetAllFollowers(leader)

	for _, follower in ipairs(allFollowers) do
		-- Validar que el seguidor sigue siendo válido
		if IsValidPlayer(follower) and CanAnimate(follower) then
			StopPlayerAnimation(follower)
			NotifyClient(follower, nil)
		end
	end
end

--------------------------------------------------------------------------------
-- SISTEMA DE SINCRONIZACIÓN
--------------------------------------------------------------------------------

-- Dejar de seguir a un líder
local function Unfollow(player)
	if not IsValidPlayer(player) then return end

	local data = PlayerData[player]
	local currentLeader = data.Following

	if currentLeader and IsValidPlayer(currentLeader) then
		-- Remover de la lista de seguidores del líder anterior
		SafeRemoveFromArray(PlayerData[currentLeader].Followers, player)
		-- ACTUALIZAR atributo del líder para que Dance Leader System se entere
		UpdateFollowerCount(currentLeader)
	end

	data.Following = nil

	-- ACTUALIZAR atributo "following" para DanceLeaderSystem
	pcall(function()
		player:SetAttribute("following", nil)
	end)

	-- Actualizar indicador visual
	-- Nota: dejamos de usar SyncOnOff/atributos en el character; el cliente recibirá el estado por SyncUpdate

	-- Notificar cliente inmediatamente que dejó de seguir
	pcall(function()
		SyncUpdate:FireClient(player, { isSynced = false, leaderName = nil, animationName = nil, speed = nil })
	end)
end

-- Seguir a un nuevo líder
local function Follow(follower, leader)
	if not IsValidPlayer(follower) or not IsValidPlayer(leader) then return false end
	if follower == leader then return false end

	-- Prevenir loops: no puedo seguir a alguien que me sigue (directa o indirectamente)
	local allMyFollowers = GetAllFollowers(follower)
	for _, f in ipairs(allMyFollowers) do
		if f == leader then
			warn("[EmotesSync] No se puede seguir a un seguidor propio")
			return false
		end
	end

	-- Guardar mis seguidores válidos antes de cambiar
	local myFollowers = GetValidFollowers(follower)

	-- Dejar de seguir al líder anterior si existe (SILENCIOSAMENTE)
	local followerData = PlayerData[follower]
	local currentLeader = followerData.Following
	if currentLeader and IsValidPlayer(currentLeader) then
		SafeRemoveFromArray(PlayerData[currentLeader].Followers, follower)
		-- ACTUALIZAR atributo del líder anterior para que Dance Leader System se entere
		UpdateFollowerCount(currentLeader)
	end

	-- Validar nuevamente que el líder sigue siendo válido
	if not IsValidPlayer(leader) then return false end

	-- Establecer nuevo líder
	followerData.Following = leader

	-- ACTUALIZAR atributo "following" para DanceLeaderSystem
	pcall(function()
		follower:SetAttribute("following", leader.Name)
	end)

	-- Agregar a la lista de seguidores del nuevo líder
	if not table.find(PlayerData[leader].Followers, follower) then
		table.insert(PlayerData[leader].Followers, follower)
	end

	-- ACTUALIZAR atributo del nuevo líder para que Dance Leader System se entere
	UpdateFollowerCount(leader)

	-- Restaurar mis seguidores (ellos me siguen a mí, no al nuevo líder)
	followerData.Followers = myFollowers

	-- Obtener la animación del líder raíz
	local rootLeader = GetRootLeader(leader)
	local animName = nil
	local speed = nil
	local hasAnimation = false

	if rootLeader and IsValidPlayer(rootLeader) then
		local rootData = PlayerData[rootLeader]
		if rootData.Animation then
			local animId = rootData.Animation.Animation.AnimationId
			animName = rootData.AnimationName
			local timePos = rootData.Animation.TimePosition
			speed = rootData.Animation.Speed
			hasAnimation = true

			-- Aplicar animación al nuevo seguidor
			PlayAnimationOnPlayer(follower, animId, animName, timePos, speed)

			-- Propagar a todos mis seguidores usando el helper
			if #myFollowers > 0 then
				PropagateToFollowerChain(myFollowers, animId, animName, timePos, speed)
			end
		end
	end

	-- ENVIAR UN SOLO SyncUpdate CON TODO EL ESTADO ACTUALIZADO
	local leaderUserId = rootLeader and rootLeader.UserId or leader.UserId

	local success = pcall(function()
		SyncUpdate:FireClient(follower, { 
			isSynced = true, 
			leaderName = leader.Name, 
			leaderUserId = leaderUserId, 
			animationName = animName, 
			speed = speed 
		})
	end)

	if not success then
		warn("[EmotesSync] Error al enviar SyncUpdate a", follower.Name)
	end

	-- También enviar PlayAnimationRemote si hay animación activa
	if hasAnimation and animName then
		pcall(function()
			PlayAnimationRemote:FireClient(follower, "playAnim", animName)
		end)
	end
	
	-- 🔔 NOTIFICAR al líder que tiene un nuevo seguidor
	NotifyFollowers(leader)

	return true
end

--------------------------------------------------------------------------------
-- HANDLERS DE EVENTOS
--------------------------------------------------------------------------------

-- Reproducir animación (desde cliente)
local function OnPlayAnimation(player, action, animationData)
	if not IsValidPlayer(player) then return end

	if action == "playAnim" and animationData and DanceCache[animationData] then
		-- Guardar mis seguidores válidos antes de cambiar
		local myFollowers = GetValidFollowers(player)

		-- Si estoy siguiendo a alguien, dejar de seguir
		-- (porque ahora YO soy el que elige el baile)
		Unfollow(player)

		-- Restaurar mis seguidores
		PlayerData[player].Followers = myFollowers

		-- Reproducir la animación
		local animId = DanceCache[animationData]
		if PlayAnimationOnPlayer(player, animId, animationData, 0, 1) then
			NotifyClient(player, animationData)

			-- Propagar a todos mis seguidores
			if IsValidPlayer(player) and #myFollowers > 0 then
				PropagateToFollowerChain(myFollowers, animId, animationData, 0, 1)
			end
		end

	elseif action == "speed" and type(animationData) == "number" then
		local data = PlayerData[player]
		if data.Animation then
			local animId = data.Animation.Animation.AnimationId
			local animName = data.AnimationName
			local timePos = data.Animation.TimePosition

			-- Recrear animación con nueva velocidad
			if PlayAnimationOnPlayer(player, animId, animName, timePos, animationData) then
				-- Propagar cambio de velocidad a seguidores
				local followers = GetValidFollowers(player)
				if #followers > 0 then
					PropagateToFollowerChain(followers, animId, animName, timePos, animationData)
				end
			end
		end
	end
end

-- Detener animación (desde cliente)
local function OnStopAnimation(player)
	if not IsValidPlayer(player) then return end

	-- Detener mi animación
	StopPlayerAnimation(player)
	NotifyClient(player, nil)

	-- Detener animaciones de todos mis seguidores
	StopFollowersAnimations(player)
end

-- Acción de sincronización (desde cliente)
local function OnSyncAction(player, action, target)
	if not IsValidPlayer(player) then return end

	if action == "sync" then
		-- El cliente puede enviar un Player object o un string (nombre)
		local targetPlayer
		if typeof(target) == "Instance" and target:IsA("Player") then
			targetPlayer = target
		elseif typeof(target) == "string" then
			targetPlayer = FindPlayerByName(target)
		end

		if targetPlayer and IsValidPlayer(targetPlayer) and player ~= targetPlayer then
			Follow(player, targetPlayer)
		end

	elseif action == "unsync" then
		-- Guardar seguidores válidos antes de desincronizar
		local myFollowers = GetValidFollowers(player)

		-- Dejar de seguir
		Unfollow(player)

		-- Detener mi animación
		StopPlayerAnimation(player)
		NotifyClient(player, nil)

		-- Restaurar seguidores y detener sus animaciones
		PlayerData[player].Followers = myFollowers
		StopFollowersAnimations(player)
	end
end

--------------------------------------------------------------------------------
-- MANEJO DE JUGADORES
--------------------------------------------------------------------------------

local function OnCharacterAdded(character)
	-- Obtener player ANTES de cualquier otra cosa
	local player = Players:GetPlayerFromCharacter(character)
	if not player or not PlayerData[player] then return end

	-- 🔄 IMPORTANTE: GUARDAR estado de sync ANTES de limpiar
	local wasFollowing = PlayerData[player].Following
	local myFollowers = ShallowCopy(PlayerData[player].Followers)

	-- LIMPIAR referencias stale en TODOS los demás jugadores
	-- (previene que la animación se propague al nuevo character)
	for otherPlayer, data in pairs(PlayerData) do
		if otherPlayer ~= player and data and data.Followers then
			SafeRemoveFromArray(data.Followers, player)
			-- ACTUALIZAR atributo de followers para este jugador
			UpdateFollowerCount(otherPlayer)
		end
	end

	-- Crear instancias necesarias en el nuevo character
	local animation = Instance.new("Animation")
	animation.Name = "Baile"
	animation.Parent = character

	-- Usar spawn para no bloquear si Humanoid tarda
	task.spawn(function()
		local humanoid = character:FindFirstChild("Humanoid")

		-- Si no hay Humanoid inmediatamente, esperar máximo 1 segundo
		if not humanoid then
			humanoid = character:WaitForChild("Humanoid", 1)
		end

		if humanoid then
			local diedConnection
			diedConnection = humanoid.Died:Connect(function()
				-- Desconectar de inmediato
				if diedConnection then
					diedConnection:Disconnect()
					diedConnection = nil
				end

				-- Validar jugador sigue siendo válido
				if not IsValidPlayer(player) then return end
				if not PlayerData[player] then return end

				-- Detener animación al morir
				StopPlayerAnimation(player)

				-- Guardar seguidores antes de limpiar
				local myFollowers = ShallowCopy(PlayerData[player].Followers)

				-- Dejar de seguir a líder
				if PlayerData[player].Following then
					Unfollow(player)
				end

				-- SIEMPRE limpiar referencias stale en TODOS los casos
				-- (esto previene que se propague animaciones al respawnear)
				for otherPlayer, data in pairs(PlayerData) do
					if otherPlayer ~= player and data and data.Followers then
						SafeRemoveFromArray(data.Followers, player)
						-- ACTUALIZAR atributo de followers para este jugador
						UpdateFollowerCount(otherPlayer)
					end
				end

				if Settings.ResetAnimationOnRespawn then
					-- Notificar a seguidores que ya no hay animación
					StopFollowersAnimations(player)

					-- Limpiar seguidores
					PlayerData[player].Followers = {}
				end
			end)

			if PlayerData[player] then
				table.insert(PlayerData[player].Connections, diedConnection)
			end
		end
		
		--  RESTAURAR sync después del respawn/;char
		task.wait(0.5) -- Esperar a que el character esté completamente cargado
		
		if not IsValidPlayer(player) then return end
		
		-- Restaurar mis seguidores
		PlayerData[player].Followers = myFollowers
		UpdateFollowerCount(player)
		
		-- Si estaba siguiendo a alguien, RE-SINCRONIZAR
		if wasFollowing and IsValidPlayer(wasFollowing) then
			-- Re-establecer la sincronización
			Follow(player, wasFollowing)
			print("[EmotesSync] ", player.Name, " re-sincronizado con", wasFollowing.Name, "después de respawn")
		end
		
		-- Notificar a mis seguidores que sigo disponible
		if #myFollowers > 0 then
			NotifyFollowers(player)
		end
	end)
end

local function OnPlayerAdded(player)
	-- Inicializar datos del jugador
	PlayerData[player] = {
		Animation = nil,
		AnimationName = nil,
		Following = nil,
		Followers = {},
		Connections = {},
	}

	-- Conexión para cuando se agrega el personaje
	local charConnection = player.CharacterAdded:Connect(OnCharacterAdded)
	table.insert(PlayerData[player].Connections, charConnection)

	-- Si ya tiene personaje, inicializarlo
	if player.Character then
		OnCharacterAdded(player.Character)
	end

	-- Manejar comandos de chat
	local chatConnection = player.Chatted:Connect(function(message)
		local args = message:split(" ")
		local command = args[1] and args[1]:lower()

		if command == "sync" and args[2] then
			local targetPlayer = FindPlayerByName(args[2])
			if targetPlayer and player ~= targetPlayer then
				Follow(player, targetPlayer)
			end
		elseif command == "unsync" then
			OnSyncAction(player, "unsync", nil)
		end
	end)
	table.insert(PlayerData[player].Connections, chatConnection)
end

local function OnPlayerRemoving(player)
	if not PlayerData[player] then return end

	-- Detener mi animación y notificar seguidores
	StopPlayerAnimation(player)
	StopFollowersAnimations(player)

	-- Dejar de seguir a mi líder
	Unfollow(player)

	-- Remover de la lista de seguidores de otros jugadores
	for otherPlayer, data in pairs(PlayerData) do
		if otherPlayer ~= player and data.Followers then
			SafeRemoveFromArray(data.Followers, player)
			-- ACTUALIZAR atributo de followers para este jugador
			UpdateFollowerCount(otherPlayer)
		end
	end

	-- Limpiar broadcasts pendientes de este jugador
	if PendingBroadcasts[player] then
		PendingBroadcasts[player] = nil
	end

	-- Desconectar todas las conexiones
	for _, connection in ipairs(PlayerData[player].Connections) do
		if connection then
			pcall(function() connection:Disconnect() end)
		end
	end

	-- Limpiar datos
	PlayerData[player] = nil
end

--------------------------------------------------------------------------------
-- INICIALIZACIÓN
--------------------------------------------------------------------------------

-- Conectar eventos
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
PlayAnimationRemote.OnServerEvent:Connect(OnPlayAnimation)
StopAnimationRemote.OnServerEvent:Connect(OnStopAnimation)
SyncRemote.OnServerEvent:Connect(OnSyncAction)

-- Inicializar jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

