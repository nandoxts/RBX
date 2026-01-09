-- ============================================
-- CLAN SERVER - Sistema Consolidado de Clanes
-- ============================================
local ClanData = require(game:GetService("ServerStorage"):WaitForChild("ClanData"))

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local ADMIN_IDS = {
	8387751399,  -- nandoxts (Owner)
	9375636407,  -- Admin2
}

-- Sistema de permisos integrado
local PERMISOS = {
	owner = {
		invitar = true,
		expulsar = true,
		cambiar_lideres = true,
		cambiar_colideres = true,
		cambiar_descripcion = true,
		cambiar_nombre = true,
		cambiar_logo = true,
		disolver_clan = true,
	},
	colider = {
		invitar = true,
		expulsar = true,
		cambiar_lideres = true,
		cambiar_descripcion = true,
		cambiar_nombre = true,
		cambiar_logo = true
	},
	lider = {
		invitar = true,
		expulsar = true,
		cambiar_descripcion = true
	},
	miembro = {}
}

local JERARQUIA = {
	owner = 4,
	colider = 3,
	lider = 2,
	miembro = 1
}

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================
local function isAdmin(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then return true end
	end
	return false
end

local function hasPermission(rol, permiso)
	return PERMISOS[rol] and PERMISOS[rol][permiso] or false
end

local function canActOn(userRole, targetRole, action)
	if userRole == "owner" then return true end
	if not hasPermission(userRole, action) then return false end
	
	local userLevel = JERARQUIA[userRole] or 0
	local targetLevel = JERARQUIA[targetRole] or 0
	return userLevel > targetLevel
end

-- ============================================
-- LÓGICA DE NEGOCIO
-- ============================================
local ClanSystem = {}

function ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	if not clanName or clanName == "" then
		return false, "El nombre del clan es requerido"
	end
	
	if not clanTag or clanTag == "" or #clanTag < 2 or #clanTag > 5 then
		return false, "El TAG del clan debe tener entre 2 y 5 caracteres"
	end
	
	return ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
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
	return success, success and "Clan disuelto" or err
end

function ClanSystem:AdminDissolveClan(clanId)
	local success, err = ClanData:DissolveClan(clanId)
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
	return success, success and "Has abandonado el clan" or err
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
CreateClanEvent.OnServerInvoke = function(player, clanName, clanTag, clanLogo, clanDesc)
	local success, clanId = ClanSystem:CreateClan(clanName, player.UserId, clanTag, clanLogo, clanDesc)
	if success then
		print("✅ [Clan] Nuevo clan creado: " .. clanName .. " [" .. clanTag .. "] (" .. player.Name .. ")")
		return true, clanId, "Clan creado exitosamente"
	else
		warn("❌ [Clan] Error al crear clan: " .. tostring(clanId))
		return false, nil, clanId
	end
end

InvitePlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:InvitePlayer(clanId, player.UserId, targetPlayerId)
	print(success and ("✅ " .. player.Name .. " invitó a un jugador") or ("❌ " .. msg))
	return success, msg
end

KickPlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:KickPlayer(clanId, player.UserId, targetPlayerId)
	print(success and ("✅ " .. player.Name .. " expulsó a un jugador") or ("❌ " .. msg))
	return success, msg
end

ChangeRoleEvent.OnServerInvoke = function(player, clanId, targetPlayerId, newRole)
	local success, msg = ClanSystem:ChangeRole(clanId, player.UserId, targetPlayerId, newRole)
	print(success and ("✅ Rol cambiado") or ("❌ " .. msg))
	return success, msg
end

ChangeClanNameEvent.OnServerInvoke = function(player, clanId, newName)
	local success, msg = ClanSystem:ChangeName(clanId, player.UserId, newName)
	print(success and ("✅ Nombre actualizado: " .. newName) or ("❌ " .. msg))
	return success, msg
end

ChangeClanTagEvent.OnServerInvoke = function(player, clanId, newTag)
	local success, msg = ClanSystem:ChangeTag(clanId, player.UserId, newTag)
	print(success and ("✅ TAG actualizado: " .. newTag) or ("❌ " .. msg))
	return success, msg
end

ChangeClanDescEvent.OnServerInvoke = function(player, clanId, newDesc)
	local success, msg = ClanSystem:ChangeDescription(clanId, player.UserId, newDesc)
	print(success and "✅ Descripción actualizada" or ("❌ " .. msg))
	return success, msg
end

ChangeClanLogoEvent.OnServerInvoke = function(player, clanId, newLogoId)
	local success, msg = ClanSystem:ChangeLogo(clanId, player.UserId, newLogoId)
	print(success and "✅ Logo actualizado" or ("❌ " .. msg))
	return success, msg
end

DissolveEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:DissolveClan(clanId, player.UserId)
	print(success and ("✅ Clan disuelto por: " .. player.Name) or ("❌ " .. msg))
	return success, msg
end

AdminDissolveClanEvent.OnServerInvoke = function(player, clanId)
	if not isAdmin(player.UserId) then
		warn("⚠️ [Admin] Intento no autorizado por: " .. player.Name)
		return false, "No autorizado"
	end
	
	local success, msg = ClanSystem:AdminDissolveClan(clanId)
	print(success and ("✅ [Admin] Clan disuelto por: " .. player.Name) or ("❌ " .. msg))
	return success, msg
end

GetClanDataEvent.OnServerEvent:Connect(function(player, clanId)
	local clanData = ClanSystem:GetClanData(clanId)
	GetClanDataEvent:FireClient(player, clanData)
end)

JoinClanEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:JoinClan(clanId, player.UserId)
	print(success and ("✅ " .. player.Name .. " se unió al clan") or ("❌ " .. msg))
	return success, msg
end

LeaveClanEvent.OnServerInvoke = function(player, clanId)
	local success, msg = ClanSystem:LeaveClan(clanId, player.UserId)
	print(success and ("✅ " .. player.Name .. " salió del clan") or ("❌ " .. msg))
	return success, msg
end

GetClansListFunction.OnServerInvoke = function(player)
	local allClans = ClanSystem:GetAllClans()
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
-- Notificar a todos los clientes conectados
local allClans = ClanData:GetAllClans()
ClansUpdatedEvent:FireAllClients(allClans)

print("✅ [Clan System] Inicializado correctamente")

return {}
