-- ============================================
-- CLAN SERVER - Sistema Consolidado de Clanes
-- VERSIÓN OPTIMIZADA CON EMOJI Y COLOR
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClanData = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

-- ============================================
-- RATE LIMITING (Simplificado)
-- ============================================
local playerLimits = {}

local function checkRateLimit(userId, action)
	local limit = Config:GetRateLimit(action) or 1
	if limit == 0 then return true end

	local key = tostring(userId)
	playerLimits[key] = playerLimits[key] or {}

	local now = os.time()
	local last = playerLimits[key][action] or 0

	if (now - last) < limit then
		return false, "Espera " .. (limit - (now - last)) .. "s"
	end

	playerLimits[key][action] = now
	return true
end

-- Limpiar límites de jugadores desconectados cada 10 min
task.spawn(function()
	while true do
		task.wait(600)
		local online = {}
		for _, p in ipairs(Players:GetPlayers()) do
			online[tostring(p.UserId)] = true
		end
		for odigo in pairs(playerLimits) do
			if not online[odigo] then
				playerLimits[odigo] = nil
			end
		end
	end
end)

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================
local function isAdmin(userId)
	return Config:IsAdmin(userId)
end

local function hasPermission(rol, permiso)
	return Config:HasPermission(rol, permiso)
end

local function canActOn(userRole, targetRole, action)
	if userRole == "owner" then return true end
	if not hasPermission(userRole, action) then return false end
	return Config:GetRoleLevel(userRole) > Config:GetRoleLevel(targetRole)
end

-- ============================================
-- ATRIBUTOS PARA OVERHEAD
-- ============================================
local function updatePlayerAttributes(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local playerClan = ClanData:GetPlayerClan(userId)

	if playerClan and playerClan.clanId then
		local clanData = ClanData:GetClan(playerClan.clanId)
		if clanData then
			player:SetAttribute("ClanTag", clanData.clanTag or "")
			player:SetAttribute("ClanName", clanData.clanName or "")
			player:SetAttribute("ClanId", clanData.clanId or "")
			player:SetAttribute("ClanEmoji", clanData.clanEmoji or "")

			if clanData.clanColor and type(clanData.clanColor) == "table" then
				player:SetAttribute("ClanColor", Color3.fromRGB(
					clanData.clanColor[1] or 255,
					clanData.clanColor[2] or 255,
					clanData.clanColor[3] or 255
					))
			else
				player:SetAttribute("ClanColor", Color3.fromRGB(255, 255, 255))
			end
			return
		end
	end

	-- Limpiar atributos si no tiene clan
	player:SetAttribute("ClanTag", nil)
	player:SetAttribute("ClanName", nil)
	player:SetAttribute("ClanId", nil)
	player:SetAttribute("ClanEmoji", nil)
	player:SetAttribute("ClanColor", nil)
end

-- Actualizar atributos de todos los miembros del clan
local function updateAllMembersAttributes(clanData)
	if not clanData or not clanData.miembros_data then return end
	for odigo in pairs(clanData.miembros_data) do
		updatePlayerAttributes(tonumber(odigo))
	end
end

-- ============================================
-- SISTEMA DE CLANES
-- ============================================
local ClanSystem = {}

-- CREAR CLAN (con emoji y color)
function ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc, clanEmoji, clanColor)
	local allowed, err = checkRateLimit(ownerId, "CreateClan")
	if not allowed then return false, nil, err end

	local success, clanId, result = ClanData:CreateClan(
		clanName, ownerId, clanTag, clanLogo, clanDesc, clanEmoji, clanColor
	)

	if success then
		updatePlayerAttributes(ownerId)
	end

	return success, clanId, result
end

function ClanSystem:GetClanData(clanId)
	return ClanData:GetClan(clanId)
end

function ClanSystem:GetPlayerClan(userId)
	return ClanData:GetPlayerClan(userId)
end

function ClanSystem:GetAllClans()
	return ClanData:GetAllClans()
end

-- INVITAR JUGADOR
function ClanSystem:InvitePlayer(clanId, inviterId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local inviterData = clanData.miembros_data and clanData.miembros_data[tostring(inviterId)]
	if not inviterData then return false, "No eres miembro del clan" end
	if not hasPermission(inviterData.rol, "invitar") then return false, "Sin permiso" end

	local success, result = ClanData:AddMember(clanId, targetUserId, "miembro")
	if success then updatePlayerAttributes(targetUserId) end
	return success, success and "Jugador invitado" or result
end

-- EXPULSAR JUGADOR
function ClanSystem:KickPlayer(clanId, kickerId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end
	if kickerId == targetUserId then return false, "No puedes expulsarte" end

	local kickerData = clanData.miembros_data and clanData.miembros_data[tostring(kickerId)]
	local targetData = clanData.miembros_data and clanData.miembros_data[tostring(targetUserId)]

	if not kickerData then return false, "No eres miembro" end
	if not targetData then return false, "Usuario no es miembro" end
	if not canActOn(kickerData.rol, targetData.rol, "expulsar") then 
		return false, "Sin permiso" 
	end

	local success, result = ClanData:RemoveMember(clanId, targetUserId)
	if success then updatePlayerAttributes(targetUserId) end
	return success, success and "Jugador expulsado" or result
end

-- CAMBIAR ROL
function ClanSystem:ChangeRole(clanId, requesterId, targetUserId, newRole)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	local targetData = clanData.miembros_data and clanData.miembros_data[tostring(targetUserId)]

	if not requesterData then return false, "No eres miembro" end
	if not targetData then return false, "Usuario no es miembro" end

	-- Verificar permisos según el nuevo rol
	local permiso = "cambiar_lideres"
	if newRole == "colider" then permiso = "cambiar_colideres" end

	if not canActOn(requesterData.rol, targetData.rol, permiso) then
		return false, "Sin permiso para este cambio"
	end

	local success, result = ClanData:ChangeRole(clanId, targetUserId, newRole)
	if success then updatePlayerAttributes(targetUserId) end
	return success, success and "Rol actualizado" or result
end

-- ============================================
-- SOLICITUDES DE UNIÓN
-- ============================================

function ClanSystem:RequestJoinClan(clanId, playerId)
	local allowed, err = checkRateLimit(playerId, "RequestJoinClan")
	if not allowed then return false, err end

	-- Verificar solicitudes pendientes
	local pending = ClanData:GetUserPendingRequests(playerId)
	if #pending > 0 then
		return false, "Ya tienes solicitud pendiente en '" .. pending[1].clanName .. "'"
	end

	return ClanData:RequestJoinClan(clanId, playerId)
end

function ClanSystem:ApproveJoinRequest(clanId, approverId, targetUserId)
	local allowed, err = checkRateLimit(approverId, "ApproveJoinRequest")
	if not allowed then return false, err end

	local success, result = ClanData:ApproveJoinRequest(clanId, approverId, targetUserId)
	if success then updatePlayerAttributes(targetUserId) end
	return success, result
end

function ClanSystem:RejectJoinRequest(clanId, rejectorId, targetUserId)
	local allowed, err = checkRateLimit(rejectorId, "RejectJoinRequest")
	if not allowed then return false, err end
	return ClanData:RejectJoinRequest(clanId, rejectorId, targetUserId)
end

function ClanSystem:CancelJoinRequest(clanId, playerId)
	local allowed, err = checkRateLimit(playerId, "CancelJoinRequest")
	if not allowed then return false, err end
	return ClanData:CancelJoinRequest(clanId, playerId)
end

function ClanSystem:CancelAllJoinRequests(playerId)
	local allowed, err = checkRateLimit(playerId, "CancelJoinRequest")
	if not allowed then return false, err end
	return ClanData:CancelAllJoinRequests(playerId)
end

function ClanSystem:GetJoinRequests(clanId, requesterId)
	local allowed = checkRateLimit(requesterId, "GetJoinRequests")
	if not allowed then return {} end
	return ClanData:GetJoinRequests(clanId, requesterId)
end

-- ============================================
-- EDICIÓN DEL CLAN
-- ============================================

function ClanSystem:ChangeName(clanId, requesterId, newName)
	if not newName or newName == "" then return false, "Nombre vacío" end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_nombre") then
		return false, "Sin permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanName = newName})
	if success then updateAllMembersAttributes(ClanData:GetClan(clanId)) end
	return success, success and "Nombre actualizado" or result
end

function ClanSystem:ChangeTag(clanId, requesterId, newTag)
	if not newTag or #newTag < 2 or #newTag > 5 then
		return false, "TAG debe tener 2-5 caracteres"
	end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or requesterData.rol ~= "owner" then
		return false, "Solo el owner puede cambiar el TAG"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanTag = string.upper(newTag)})
	if success then updateAllMembersAttributes(ClanData:GetClan(clanId)) end
	return success, success and "TAG actualizado" or result
end

function ClanSystem:ChangeDescription(clanId, requesterId, newDesc)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_descripcion") then
		return false, "Sin permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {descripcion = newDesc})
	return success, success and "Descripción actualizada" or result
end

function ClanSystem:ChangeLogo(clanId, requesterId, newLogoId)
	if not newLogoId or newLogoId == "" then return false, "Logo inválido" end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_logo") then
		return false, "Sin permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanLogo = newLogoId})
	return success, success and "Logo actualizado" or result
end

function ClanSystem:ChangeColor(clanId, requesterId, newColor)
	-- Rate limit
	local ok, err = checkRateLimit(requesterId, "ChangeColor")
	if not ok then return false, err end

	-- Validación básica del color (espera tabla {r,g,b})
	if type(newColor) ~= "table" then return false, "Color inválido" end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_color") then
		return false, "Sin permiso"
	end

	-- Usar la validación del config si existe
	local valid, vmsg = (Config.ValidateColor and Config:ValidateColor(newColor)) or (type(newColor) == "table")
	if valid ~= true then
		return false, vmsg or "Color inválido"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanColor = newColor})
	if success then
		-- Actualizar atributos de miembros para reflejar cambio (si existe la función)
		pcall(function()
			updateAllMembersAttributes(result)
		end)
	end

	return success, success and "Color actualizado" or result
end

-- ============================================
-- DISOLVER / SALIR
-- ============================================

function ClanSystem:DissolveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end
	if clanData.owner ~= requesterId then return false, "Solo el owner puede disolver" end

	local members = clanData.miembros_data
	local success, err = ClanData:DissolveClan(clanId)

	if success and members then
		for odigo in pairs(members) do
			updatePlayerAttributes(tonumber(odigo))
		end
	end
	return success, success and "Clan disuelto" or err
end

function ClanSystem:AdminDissolveClan(adminId, clanId)
	local allowed, err = checkRateLimit(adminId, "AdminDissolveClan")
	if not allowed then return false, err end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	local adminName = Players:GetNameFromUserIdAsync(adminId)
	ClanData:LogAdminAction(adminId, adminName, "delete_clan", clanId, clanData.clanName, {
		memberCount = clanData.miembros and #clanData.miembros or 0,
		ownerUserId = clanData.owner
	})

	local members = clanData.miembros_data
	local success, err = ClanData:DissolveClan(clanId)

	if success and members then
		for odigo in pairs(members) do
			updatePlayerAttributes(tonumber(odigo))
		end
	end
	return success, success and "Clan disuelto por admin" or err
end

function ClanSystem:LeaveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end
	if clanData.owner == requesterId then
		return false, "El owner no puede abandonar. Disuelve el clan"
	end

	local success, err = ClanData:RemoveMember(clanId, requesterId)
	if success then updatePlayerAttributes(requesterId) end
	return success, success and "Has abandonado el clan" or err
end

-- ============================================
-- CREAR EVENTOS (Limpiar existentes)
-- ============================================
local existingEvents = ReplicatedStorage:FindFirstChild("ClanEvents")
if existingEvents then existingEvents:Destroy() end

local clanEvents = Instance.new("Folder")
clanEvents.Name = "ClanEvents"
clanEvents.Parent = ReplicatedStorage

-- Helper para crear RemoteFunctions
local function createRemoteFunction(name)
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = clanEvents
	return rf
end

local function createRemoteEvent(name)
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = clanEvents
	return re
end

-- RemoteFunctions
local CreateClanEvent = createRemoteFunction("CreateClan")
local InvitePlayerEvent = createRemoteFunction("InvitePlayer")
local KickPlayerEvent = createRemoteFunction("KickPlayer")
local ChangeRoleEvent = createRemoteFunction("ChangeRole")
local ChangeClanNameEvent = createRemoteFunction("ChangeClanName")
local ChangeClanTagEvent = createRemoteFunction("ChangeClanTag")
local ChangeClanDescEvent = createRemoteFunction("ChangeClanDescription")
local ChangeClanLogoEvent = createRemoteFunction("ChangeClanLogo")
local ChangeClanColorEvent = createRemoteFunction("ChangeClanColor")
local DissolveEvent = createRemoteFunction("DissolveClan")
local LeaveClanEvent = createRemoteFunction("LeaveClan")
local AdminDissolveClanEvent = createRemoteFunction("AdminDissolveClan")
local GetClansListFunction = createRemoteFunction("GetClansList")
local GetPlayerClanFunction = createRemoteFunction("GetPlayerClan")

-- Solicitudes de unión
local RequestJoinClanEvent = createRemoteFunction("RequestJoinClan")
local ApproveJoinRequestEvent = createRemoteFunction("ApproveJoinRequest")
local RejectJoinRequestEvent = createRemoteFunction("RejectJoinRequest")
local GetJoinRequestsEvent = createRemoteFunction("GetJoinRequests")
local CancelJoinRequestEvent = createRemoteFunction("CancelJoinRequest")
local CancelAllJoinRequestsEvent = createRemoteFunction("CancelAllJoinRequests")
local GetUserPendingRequestsEvent = createRemoteFunction("GetUserPendingRequests")

-- RemoteEvents
local GetClanDataEvent = createRemoteEvent("GetClanData")
local ClansUpdatedEvent = createRemoteEvent("ClansUpdated")

-- Evento de actualización
ClanData:OnClanDataUpdated():Connect(function()
	ClansUpdatedEvent:FireAllClients(ClanData:GetAllClans())
end)

-- ============================================
-- HANDLERS
-- ============================================

-- CREAR CLAN (con emoji y color)
CreateClanEvent.OnServerInvoke = function(player, clanName, clanTag, clanLogo, clanDesc, customOwnerId, clanEmoji, clanColor)
	local ownerId = player.UserId
	if customOwnerId and isAdmin(player.UserId) then
		ownerId = customOwnerId
	end

	local success, clanId, result = ClanSystem:CreateClan(
		clanName, ownerId, clanTag, clanLogo, clanDesc, clanEmoji, clanColor
	)

	if success then
		return true, clanId, "Clan creado exitosamente"
	end
	return false, nil, tostring(result or "Error desconocido")
end

InvitePlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	return ClanSystem:InvitePlayer(clanId, player.UserId, targetPlayerId)
end

KickPlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	return ClanSystem:KickPlayer(clanId, player.UserId, targetPlayerId)
end

ChangeRoleEvent.OnServerInvoke = function(player, clanId, targetPlayerId, newRole)
	return ClanSystem:ChangeRole(clanId, player.UserId, targetPlayerId, newRole)
end

ChangeClanNameEvent.OnServerInvoke = function(player, clanId, newName)
	return ClanSystem:ChangeName(clanId, player.UserId, newName)
end

ChangeClanTagEvent.OnServerInvoke = function(player, clanId, newTag)
	return ClanSystem:ChangeTag(clanId, player.UserId, newTag)
end

ChangeClanDescEvent.OnServerInvoke = function(player, clanId, newDesc)
	return ClanSystem:ChangeDescription(clanId, player.UserId, newDesc)
end

ChangeClanLogoEvent.OnServerInvoke = function(player, clanId, newLogoId)
	return ClanSystem:ChangeLogo(clanId, player.UserId, newLogoId)
end

ChangeClanColorEvent.OnServerInvoke = function(player, clanId, newColor)
    return ClanSystem:ChangeColor(clanId, player.UserId, newColor)
end

DissolveEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:DissolveClan(clanId, player.UserId)
end

AdminDissolveClanEvent.OnServerInvoke = function(player, clanId)
	if not isAdmin(player.UserId) then return false, "No autorizado" end
	return ClanSystem:AdminDissolveClan(player.UserId, clanId)
end

LeaveClanEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:LeaveClan(clanId, player.UserId)
end

GetClanDataEvent.OnServerEvent:Connect(function(player, clanId)
	GetClanDataEvent:FireClient(player, ClanSystem:GetClanData(clanId))
end)

GetClansListFunction.OnServerInvoke = function(player)
	local allClans = ClanData:GetAllClans()
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	local playerClanId = playerClan and playerClan.clanId or nil

	for _, clan in ipairs(allClans) do
		clan.isPlayerMember = (clan.clanId == playerClanId)
	end
	return allClans
end

GetPlayerClanFunction.OnServerInvoke = function(player)
	local playerClan = ClanSystem:GetPlayerClan(player.UserId)
	if playerClan and playerClan.clanId then
		return ClanSystem:GetClanData(playerClan.clanId)
	end
	return nil
end

-- HANDLERS PARA SOLICITUDES
RequestJoinClanEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:RequestJoinClan(clanId, player.UserId)
end

ApproveJoinRequestEvent.OnServerInvoke = function(player, clanId, targetUserId)
	return ClanSystem:ApproveJoinRequest(clanId, player.UserId, targetUserId)
end

RejectJoinRequestEvent.OnServerInvoke = function(player, clanId, targetUserId)
	return ClanSystem:RejectJoinRequest(clanId, player.UserId, targetUserId)
end

GetJoinRequestsEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:GetJoinRequests(clanId, player.UserId)
end

CancelJoinRequestEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:CancelJoinRequest(clanId, player.UserId)
end

CancelAllJoinRequestsEvent.OnServerInvoke = function(player)
	return ClanSystem:CancelAllJoinRequests(player.UserId)
end

GetUserPendingRequestsEvent.OnServerInvoke = function(player)
	return ClanData:GetUserPendingRequests(player.UserId)
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================
task.spawn(function()
	-- Limpiar registros huérfanos
	for _, defaultClan in ipairs(Config.DEFAULT_CLANS or {}) do
		ClanData:GetPlayerClan(defaultClan.ownerId)
	end

	-- Crear clanes por defecto
	local created = ClanData:CreateDefaultClans()
	print("[ClanServer] Clanes por defecto creados:", created)

	-- Notificar clientes
	ClansUpdatedEvent:FireAllClients(ClanData:GetAllClans())
end)

-- Inicializar atributos para jugadores conectados
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(updatePlayerAttributes, player.UserId)
end

Players.PlayerAdded:Connect(function(player)
	updatePlayerAttributes(player.UserId)
end)

return {}