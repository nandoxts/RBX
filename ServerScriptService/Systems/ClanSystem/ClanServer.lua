-- ============================================
-- CLAN SERVER - Sistema Consolidado de Clanes
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClanData = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

-- ============================================
-- CONFIGURACIÓN (desde módulo)
-- ============================================
local ADMIN_IDS = Config.ADMINS.AdminUserIds
local PERMISOS = Config.ROLES.Permissions
local JERARQUIA = Config.ROLES.Hierarchy

-- ============================================
-- RATE LIMITING & SPAM PROTECTION (desde config)
-- ============================================
local playerRequestLimits = {} -- { userId = { funcName = lastTime } }

local function checkRateLimit(userId, funcName)
	local userLimits = playerRequestLimits[tostring(userId)] or {}
	local lastTime = userLimits[funcName] or 0
	local now = os.time()
	local interval = Config:GetRateLimit(funcName) or 1
	
	if interval == 0 then return true, nil end
	
	if (now - lastTime) < interval then
		local remainingTime = interval - (now - lastTime)
		return false, "Espera " .. remainingTime .. " segundos antes de hacer esa acción"
	end
	
	playerRequestLimits[tostring(userId)] = userLimits
	userLimits[funcName] = now
	return true, nil
end

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
	
	local userLevel = Config:GetRoleLevel(userRole)
	local targetLevel = Config:GetRoleLevel(targetRole)
	return userLevel > targetLevel
end

-- ============================================
-- FUNCIONES DE ATRIBUTOS PARA OVERHEAD
-- ============================================
local function updatePlayerClanAttributes(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end
	
	local playerClan = ClanData:GetPlayerClan(userId)
	if playerClan and playerClan.clanId then
		local clanData = ClanData:GetClan(playerClan.clanId)
		if clanData then
			player:SetAttribute("ClanTag", clanData.clanTag or "")
			player:SetAttribute("ClanName", clanData.clanName or "")
			player:SetAttribute("ClanId", clanData.clanId or "")
		else
			player:SetAttribute("ClanTag", nil)
			player:SetAttribute("ClanName", nil)
			player:SetAttribute("ClanId", nil)
		end
	else
		player:SetAttribute("ClanTag", nil)
		player:SetAttribute("ClanName", nil)
		player:SetAttribute("ClanId", nil)
	end
end

local function initializePlayerClanAttributes(player)
	task.wait(1) -- Esperar a que el jugador esté completamente cargado
	updatePlayerClanAttributes(player.UserId)
end

-- ============================================
-- LÓGICA DE NEGOCIO
-- ============================================
local ClanSystem = {}

function ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	-- Rate limiting
	local allowed, errMsg = checkRateLimit(ownerId, "CreateClan")
	if not allowed then
		return false, nil, errMsg
	end
	
	-- Validar con Config (ya no necesitamos validar aquí, ClanData lo hace)
	return ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
end

function ClanSystem:GetClanData(clanId)
	return ClanData:GetClan(clanId)
end

function ClanSystem:GetPlayerClan(userId)
	return ClanData:GetPlayerClan(userId)
end

function ClanSystem:GetAllClans()
	-- Sin rate limiting - devuelve datos frescos siempre
	return ClanData:GetAllClans()
end

function ClanSystem:JoinClan(clanId, playerId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	if clanData.miembros_data[playerId] then
		return false, "Ya eres miembro de este clan"
	end
	
	local playerClanId = ClanData:GetPlayerClan(playerId)
	if playerClanId then
		return false, "Ya perteneces a otro clan"
	end
	
	local success, result = ClanData:AddMember(clanId, playerId, "miembro")
	if success then
		updatePlayerClanAttributes(playerId)
	end
	return success, success and "Te has unido al clan" or result
end

function ClanSystem:InvitePlayer(clanId, inviterId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local inviterData = clanData.miembros_data[tostring(inviterId)]
	if not inviterData then
		return false, "No eres miembro del clan"
	end
	
	if not hasPermission(inviterData.rol, "invitar") then
		return false, "No tienes permiso para invitar"
	end
	
	local success, result = ClanData:AddMember(clanId, targetUserId, "miembro")
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Jugador invitado" or result
end

function ClanSystem:KickPlayer(clanId, kickerId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	if kickerId == targetUserId then
		return false, "No puedes expulsarte a ti mismo"
	end
	
	local kickerData = clanData.miembros_data[tostring(kickerId)]
	local targetData = clanData.miembros_data[tostring(targetUserId)]
	
	if not kickerData then
		return false, "No eres miembro del clan"
	end
	
	if not targetData then
		return false, "El usuario no es miembro"
	end
	
	if not canActOn(kickerData.rol, targetData.rol, "expulsar") then
		return false, "No tienes permiso para expulsar a este usuario"
	end
	
	local success, result = ClanData:RemoveMember(clanId, targetUserId)
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Jugador expulsado" or result
end

function ClanSystem:ChangeRole(clanId, requesterId, targetUserId, newRole)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local requesterData = clanData.miembros_data[tostring(requesterId)]
	local targetData = clanData.miembros_data[tostring(targetUserId)]
	
	if not requesterData then
		return false, "No eres miembro del clan"
	end
	
	if not targetData then
		return false, "El usuario no es miembro"
	end
	
	local permissionNeeded = "cambiar_" .. newRole .. "s"
	if not canActOn(requesterData.rol, targetData.rol, permissionNeeded) then
		return false, "No tienes permiso para cambiar roles"
	end
	
	local success, result = ClanData:ChangeRole(clanId, targetUserId, newRole)
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Rol actualizado" or result
end

function ClanSystem:ChangeName(clanId, requesterId, newName)
	if not newName or newName == "" then
		return false, "El nombre no puede estar vacío"
	end
	
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local requesterData = clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_nombre") then
		return false, "No tienes permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {clanName = newName})
	if success and clanData and clanData.miembros_data then
		for memberIdStr, _ in pairs(clanData.miembros_data) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Nombre actualizado" or result
end

function ClanSystem:ChangeTag(clanId, requesterId, newTag)
	if not newTag or newTag == "" or #newTag < 2 or #newTag > 5 then
		return false, "El TAG debe tener entre 2 y 5 caracteres"
	end
	
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	-- Convertir requesterId a string para comparar
	local requesterData = clanData.miembros_data[tostring(requesterId)]
	if not requesterData or requesterData.rol ~= "owner" then
		return false, "Solo el owner puede cambiar el TAG"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {clanTag = newTag})
	if success then
		-- Re-obtener datos del clan después de actualizar
		clanData = ClanData:GetClan(clanId)
		-- Actualizar atributos de todos los miembros del clan
		if clanData and clanData.miembros_data then
			for memberIdStr, memberData in pairs(clanData.miembros_data) do
				updatePlayerClanAttributes(tonumber(memberIdStr))
			end
		end
	end
	return success, success and "TAG actualizado" or result
end

function ClanSystem:ChangeDescription(clanId, requesterId, newDesc)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local requesterData = clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_descripcion") then
		return false, "No tienes permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {descripcion = newDesc})
	if success and clanData and clanData.miembros_data then
		for memberIdStr, _ in pairs(clanData.miembros_data) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Descripción actualizada" or result
end

function ClanSystem:ChangeLogo(clanId, requesterId, newLogoId)
	if not newLogoId or newLogoId == "" then
		return false, "Logo inválido"
	end
	
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local requesterData = clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_logo") then
		return false, "No tienes permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {clanLogo = newLogoId})
	if success and clanData and clanData.miembros_data then
		for memberIdStr, _ in pairs(clanData.miembros_data) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Logo actualizado" or result
end

function ClanSystem:DissolveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	if clanData.owner ~= requesterId then
		return false, "Solo el owner puede disolver el clan"
	end
	
	local success, err = ClanData:DissolveClan(clanId)
	if success then
		-- Limpiar atributos de todos los miembros
		for memberIdStr, memberData in pairs(clanData.miembros_data) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Clan disuelto" or err
end

function ClanSystem:AdminDissolveClan(adminId, clanId)
	-- Rate limiting
	local allowed, errMsg = checkRateLimit(adminId, "AdminDissolveClan")
	if not allowed then
		return false, errMsg
	end
	
	-- Obtener data del clan antes de eliminarlo (para auditoría)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	-- Obtener nombre del admin
	local adminName = game:GetService("Players"):GetNameFromUserIdAsync(adminId)
	
	-- Registrar en auditoría
	ClanData:LogAdminAction(adminId, adminName, "delete_clan", clanId, clanData.clanName, {
		timestamp = os.time(),
		memberCount = #clanData.miembros,
		ownerUserId = clanData.owner
	})
	
	local success, err = ClanData:DissolveClan(clanId)
	if success and clanData and clanData.miembros_data then
		for memberIdStr, _ in pairs(clanData.miembros_data) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Clan disuelto por admin" or err
end

function ClanSystem:LeaveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	if clanData.owner == requesterId then
		return false, "El owner no puede abandonar el clan. Disuelve el clan si deseas"
	end
	
	local success, err = ClanData:RemoveMember(clanId, requesterId)
	if success then
		updatePlayerClanAttributes(requesterId)
	end
	return success, success and "Has abandonado el clan" or err
end

function ClanSystem:AdminGetAuditLog(limit)
	return ClanData:GetAuditLog(limit or 50)
end

-- ============================================
-- CONFIGURACIÓN DE EVENTOS
-- ============================================
local existingEvents = game.ReplicatedStorage:FindFirstChild("ClanEvents")
if existingEvents then
	existingEvents:Destroy()
end

local clanEvents = Instance.new("Folder")
clanEvents.Name = "ClanEvents"
clanEvents.Parent = game:GetService("ReplicatedStorage")

-- Crear eventos
local CreateClanEvent = Instance.new("RemoteFunction", clanEvents)
CreateClanEvent.Name = "CreateClan"

local InvitePlayerEvent = Instance.new("RemoteFunction", clanEvents)
InvitePlayerEvent.Name = "InvitePlayer"

local KickPlayerEvent = Instance.new("RemoteFunction", clanEvents)
KickPlayerEvent.Name = "KickPlayer"

local ChangeRoleEvent = Instance.new("RemoteFunction", clanEvents)
ChangeRoleEvent.Name = "ChangeRole"

local ChangeClanNameEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanNameEvent.Name = "ChangeClanName"

local ChangeClanTagEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanTagEvent.Name = "ChangeClanTag"

local ChangeClanDescEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanDescEvent.Name = "ChangeClanDescription"

local ChangeClanLogoEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanLogoEvent.Name = "ChangeClanLogo"

local DissolveEvent = Instance.new("RemoteFunction", clanEvents)
DissolveEvent.Name = "DissolveClan"

local LeaveClanEvent = Instance.new("RemoteFunction", clanEvents)
LeaveClanEvent.Name = "LeaveClan"

local JoinClanEvent = Instance.new("RemoteFunction", clanEvents)
JoinClanEvent.Name = "JoinClan"

local AdminDissolveClanEvent = Instance.new("RemoteFunction", clanEvents)
AdminDissolveClanEvent.Name = "AdminDissolveClan"

local GetClanDataEvent = Instance.new("RemoteEvent", clanEvents)
GetClanDataEvent.Name = "GetClanData"

local ClansUpdatedEvent = Instance.new("RemoteEvent", clanEvents)
ClansUpdatedEvent.Name = "ClansUpdated"

local GetClansListFunction = Instance.new("RemoteFunction", clanEvents)
GetClansListFunction.Name = "GetClansList"

-- Conectar evento de actualización para notificar a clientes
ClanData:OnClanDataUpdated():Connect(function()
	local allClans = ClanData:GetAllClans()
	ClansUpdatedEvent:FireAllClients(allClans)
end)

local GetPlayerClanFunction = Instance.new("RemoteFunction", clanEvents)
GetPlayerClanFunction.Name = "GetPlayerClan"

-- ============================================
-- MANEJADORES DE EVENTOS
-- ============================================
CreateClanEvent.OnServerInvoke = function(player, clanName, clanTag, clanLogo, clanDesc, customOwnerId)
	-- Usar customOwnerId si se proporciona y el jugador es admin, sino usar player.UserId
	local ownerId = player.UserId
	if customOwnerId and isAdmin(player.UserId) then
		ownerId = customOwnerId
	end
	
	local success, clanId, result = ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	if success then
		-- Refrescar atributos del owner
		updatePlayerClanAttributes(ownerId)
		return true, clanId, "Clan creado exitosamente"
	else
		local errorMsg = tostring(result or "Error desconocido")
		return false, nil, errorMsg
	end
end

InvitePlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:InvitePlayer(clanId, player.UserId, targetPlayerId)
	return success, msg
end

KickPlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:KickPlayer(clanId, player.UserId, targetPlayerId)
	return success, msg
end

ChangeRoleEvent.OnServerInvoke = function(player, clanId, targetPlayerId, newRole)
	local success, msg = ClanSystem:ChangeRole(clanId, player.UserId, targetPlayerId, newRole)
	return success, msg
end

ChangeClanNameEvent.OnServerInvoke = function(player, clanId, newName)
	local success, msg = ClanSystem:ChangeName(clanId, player.UserId, newName)
	return success, msg
end

ChangeClanTagEvent.OnServerInvoke = function(player, clanId, newTag)
	local success, msg = ClanSystem:ChangeTag(clanId, player.UserId, newTag)
	return success, msg
end

ChangeClanDescEvent.OnServerInvoke = function(player, clanId, newDesc)
	local success, msg = ClanSystem:ChangeDescription(clanId, player.UserId, newDesc)
	return success, msg
end

ChangeClanLogoEvent.OnServerInvoke = function(player, clanId, newLogoId)
	local success, msg = ClanSystem:ChangeLogo(clanId, player.UserId, newLogoId)
	return success, msg
end

DissolveEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:DissolveClan(clanId, player.UserId)
	return success, msg
end

AdminDissolveClanEvent.OnServerInvoke = function(player, clanId)
	if not isAdmin(player.UserId) then
		warn("⚠️ [Admin] Intento no autorizado por: " .. player.Name)
		return false, "No autorizado"
	end
	
	local success, msg = ClanSystem:AdminDissolveClan(player.UserId, clanId)
	return success, msg
end

GetClanDataEvent.OnServerEvent:Connect(function(player, clanId)
	local clanData = ClanSystem:GetClanData(clanId)
	GetClanDataEvent:FireClient(player, clanData)
end)

JoinClanEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:JoinClan(clanId, player.UserId)
	return success, msg
end

LeaveClanEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:LeaveClan(clanId, player.UserId)
	return success, msg
end

GetClansListFunction.OnServerInvoke = function(player)
	-- Obtener clanes frescos sin caché
	local allClans = ClanData:GetAllClans()
	
	-- Agregar flag isPlayerMember a cada clan (datos frescos del servidor)
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	local playerClanId = playerClan and playerClan.clanId or nil
	
	for _, clanData in ipairs(allClans) do
		clanData.isPlayerMember = (clanData.clanId == playerClanId)
	end
	
	return allClans
end

GetPlayerClanFunction.OnServerInvoke = function(player)
	local playerClanData = ClanSystem:GetPlayerClan(player.UserId)
	if playerClanData and playerClanData.clanId then
		return ClanSystem:GetClanData(playerClanData.clanId)
	end
	return nil
end

-- ============================================
-- INICIALIZACIÓN (como DjDashboard)
-- ============================================
ClanData:LoadAllClans()
task.wait(0.5)
-- Crear clans por defecto si no existen
ClanData:CreateDefaultClans()
-- Inicializar atributos de clanes para jugadores ya en el juego
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(initializePlayerClanAttributes, player)
end

-- Conectar evento PlayerAdded para nuevos jugadores
Players.PlayerAdded:Connect(initializePlayerClanAttributes)

-- Notificar a todos los clientes conectados
local allClans = ClanData:GetAllClans()
ClansUpdatedEvent:FireAllClients(allClans)

print(" [Clan System] Inicializado correctamente")

return {}
