--[[
    Sistema de Sincronización de Emotes - Versión Mejorada
    
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
local SyncRemote = Remotes.Sync
local PlayAnimationRemote = Remotes.PlayAnimation
local StopAnimationRemote = Remotes.StopAnimation

-- Configuración
local FADE_TIME = 0.3

-- Estado global de sincronización
local PlayerData = {}

-- Cache de animaciones: nombre -> assetId
local DanceCache = {}

-- Inicializar cache de bailes
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
end

-- Reproducir una animación en un jugador específico
local function PlayAnimationOnPlayer(player, animationId, animationName, timePosition, speed)
	if not CanAnimate(player) then return false end

	timePosition = timePosition or 0
	speed = speed or 1

	local data = PlayerData[player]
	local character = player.Character
	local humanoid = character.Humanoid
	local animator = humanoid.Animator
	local baileAnim = character.Baile

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

-- Propagar animación a todos los seguidores de un jugador
local function PropagateAnimationToFollowers(leader)
	if not IsValidPlayer(leader) then return end

	local leaderData = PlayerData[leader]
	if not leaderData.Animation then return end

	local animationId = leaderData.Animation.Animation.AnimationId
	local animationName = leaderData.AnimationName
	local timePosition = leaderData.Animation.TimePosition
	local speed = leaderData.Animation.Speed

	-- Obtener TODOS los seguidores (incluyendo seguidores de seguidores)
	local allFollowers = GetAllFollowers(leader)

	for _, follower in ipairs(allFollowers) do
		if CanAnimate(follower) then
			PlayAnimationOnPlayer(follower, animationId, animationName, timePosition, speed)
			NotifyClient(follower, animationName)
		end
	end
end

-- Detener animaciones de todos los seguidores
local function StopFollowersAnimations(leader)
	if not IsValidPlayer(leader) then return end

	local allFollowers = GetAllFollowers(leader)

	for _, follower in ipairs(allFollowers) do
		StopPlayerAnimation(follower)
		NotifyClient(follower, nil)
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
	end

	data.Following = nil

	-- Actualizar indicador visual
	if player.Character and player.Character:FindFirstChild("SyncOnOff") then
		player.Character.SyncOnOff.Value = false
	end
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

	-- Guardar mis seguidores actuales antes de cambiar
	local myFollowers = ShallowCopy(PlayerData[follower].Followers)

	-- Dejar de seguir al líder anterior si existe
	Unfollow(follower)

	-- Establecer nuevo líder
	local followerData = PlayerData[follower]
	followerData.Following = leader

	-- Agregar a la lista de seguidores del nuevo líder
	if not table.find(PlayerData[leader].Followers, follower) then
		table.insert(PlayerData[leader].Followers, follower)
	end

	-- Restaurar mis seguidores (ellos me siguen a mí, no al nuevo líder)
	followerData.Followers = myFollowers

	-- Actualizar indicador visual
	if follower.Character and follower.Character:FindFirstChild("SyncOnOff") then
		follower.Character.SyncOnOff.Value = true
	end

	-- Obtener la animación del líder raíz
	local rootLeader = GetRootLeader(leader)
	if rootLeader and IsValidPlayer(rootLeader) then
		local rootData = PlayerData[rootLeader]
		if rootData.Animation then
			local animId = rootData.Animation.Animation.AnimationId
			local animName = rootData.AnimationName
			local timePos = rootData.Animation.TimePosition
			local speed = rootData.Animation.Speed

			-- Aplicar animación al nuevo seguidor
			if PlayAnimationOnPlayer(follower, animId, animName, timePos, speed) then
				NotifyClient(follower, animName)
			end

			-- Propagar a todos mis seguidores también
			for _, myFollower in ipairs(myFollowers) do
				if CanAnimate(myFollower) then
					PlayAnimationOnPlayer(myFollower, animId, animName, timePos, speed)
					NotifyClient(myFollower, animName)

					-- Y a los seguidores de mis seguidores
					local subFollowers = GetAllFollowers(myFollower)
					for _, subFollower in ipairs(subFollowers) do
						if CanAnimate(subFollower) then
							PlayAnimationOnPlayer(subFollower, animId, animName, timePos, speed)
							NotifyClient(subFollower, animName)
						end
					end
				end
			end
		end
	end

	return true
end

--------------------------------------------------------------------------------
-- HANDLERS DE EVENTOS
--------------------------------------------------------------------------------

-- Reproducir animación (desde cliente)
local function OnPlayAnimation(player, action, animationData)
	if not IsValidPlayer(player) then return end

	if action == "playAnim" and animationData and DanceCache[animationData] then
		-- Guardar mis seguidores
		local myFollowers = ShallowCopy(PlayerData[player].Followers)

		-- Si estoy siguiendo a alguien, dejar de seguir
		-- (porque ahora YO soy el que elige el baile)
		Unfollow(player)

		-- Restaurar mis seguidores
		PlayerData[player].Followers = myFollowers

		-- Reproducir la animación
		local animId = DanceCache[animationData]
		if PlayAnimationOnPlayer(player, animId, animationData, 0, 1) then
			NotifyClient(player, animationData)

			-- Propagar a TODOS mis seguidores
			PropagateAnimationToFollowers(player)
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
				PropagateAnimationToFollowers(player)
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
local function OnSyncAction(player, action, targetName)
	if not IsValidPlayer(player) then return end

	if action == "sync" then
		local targetPlayer = FindPlayerByName(targetName)
		if targetPlayer and IsValidPlayer(targetPlayer) and player ~= targetPlayer then
			Follow(player, targetPlayer)
		end

	elseif action == "unsync" then
		-- Guardar seguidores antes de desincronizar
		local myFollowers = ShallowCopy(PlayerData[player].Followers)

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
	-- Crear instancias necesarias
	local animation = Instance.new("Animation")
	animation.Name = "Baile"
	animation.Parent = character

	local syncIndicator = Instance.new("BoolValue")
	syncIndicator.Name = "SyncOnOff"
	syncIndicator.Parent = character

	-- Manejar muerte del personaje
	local player = Players:GetPlayerFromCharacter(character)
	if not player or not PlayerData[player] then return end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		local diedConnection
		diedConnection = humanoid.Died:Connect(function()
			if diedConnection then
				diedConnection:Disconnect()
			end

			if not IsValidPlayer(player) then return end

			-- Detener animación al morir
			StopPlayerAnimation(player)
			PlayerData[player].Following = nil

			if Settings.ResetAnimationOnRespawn then
				-- Notificar a seguidores que ya no hay animación
				StopFollowersAnimations(player)

				-- Remover de la lista de seguidores de otros
				for otherPlayer, data in pairs(PlayerData) do
					if otherPlayer ~= player and data.Followers then
						SafeRemoveFromArray(data.Followers, player)
					end
				end

				-- Limpiar seguidores
				PlayerData[player].Followers = {}
			end
		end)

		table.insert(PlayerData[player].Connections, diedConnection)
	end
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
		end
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
