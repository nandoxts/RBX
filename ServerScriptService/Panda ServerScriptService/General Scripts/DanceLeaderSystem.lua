--[[
DANCE LEADER SYSTEM
Sistema para detectar y marcar líderes de danza basado en cantidad de seguidores
Si un jugador tiene >= FOLLOWER_DANCE seguidores, se marca como dance leader
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local Emotes_Sync = ReplicatedStorage:WaitForChild("Emotes_Sync")
local Configuration = require(script.Parent.Parent.Configuration)

-- Configuración
local FOLLOWER_DANCE_THRESHOLD = Configuration.FOLLOWER_DANCE or 10
local CHECK_INTERVAL = Configuration.CHECK_TIME_FOLLOWER or 300
local BILLBOARD_NAME = Configuration.BILLBOARD_NAME or "Dance_Leader"

-- Obtener RemoteEvent existente
local DanceLeaderEvent = Emotes_Sync:WaitForChild("DanceLeaderEvent")

-- Estado de líderes actuales
local CurrentDanceLeaders = {}

-- Función para obtener todos los seguidores de un jugador
-- Se obtienen desde el atributo 'followers' del jugador
local function GetAllFollowersForPlayer(player)
-- Esta función necesita acceder a PlayerData del módulo Sync
-- Por ahora usamos una aproximación más simple
return 0
end

-- Obtener los datos de seguidores desde la UI del jugador
local function GetFollowerCount(player)
local playerData = player:GetAttribute("followers") or 0
return tonumber(playerData) or 0
end

-- Verificar quién debería ser dance leader
local function CheckDanceLeaders()
local newLeaders = {}

for _, player in ipairs(Players:GetPlayers()) do
if player and player.Parent == Players then
local followerCount = GetFollowerCount(player)

if followerCount >= FOLLOWER_DANCE_THRESHOLD then
table.insert(newLeaders, player)

-- Si es nuevo líder, notificar
if not CurrentDanceLeaders[player] then
print("[Dance Leader] " .. player.Name .. " es ahora un Dance Leader con " .. followerCount .. " seguidores")
DanceLeaderEvent:FireClient(player, "setLeader", true)
DanceLeaderEvent:FireAllClients("leaderAdded", player)
end
CurrentDanceLeaders[player] = true
else
-- Si dejó de ser líder
if CurrentDanceLeaders[player] then
print("[Dance Leader] " .. player.Name .. " dejó de ser Dance Leader (" .. followerCount .. " seguidores)")
DanceLeaderEvent:FireClient(player, "setLeader", false)
DanceLeaderEvent:FireAllClients("leaderRemoved", player)
end
CurrentDanceLeaders[player] = nil
end
end
end
end

-- Tabla para rastrear conexiones de atributos por jugador
local PlayerConnections = {}

-- Conectar cambios de atributos (cuando cambia followers)
local function OnPlayerAdded(player)
	-- Escuchar cambios en el atributo "followers"
	local attrConnection = player:GetAttributeChangedSignal("followers"):Connect(function()
		CheckDanceLeaders()
	end)
	
	-- Guardar conexión en tabla local para limpiar después
	PlayerConnections[player] = attrConnection
end

local function OnPlayerRemoving(player)
	-- Limpiar conexión
	if PlayerConnections[player] then
		pcall(function() PlayerConnections[player]:Disconnect() end)
		PlayerConnections[player] = nil
	end
	
	-- Remover de líderes actuales
	CurrentDanceLeaders[player] = nil
end

-- Eventos
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Verificar periódicamente (cada 5 minutos)
while true do
	wait(CHECK_INTERVAL)
	CheckDanceLeaders()
end
