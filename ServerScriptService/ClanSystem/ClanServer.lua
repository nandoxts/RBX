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

function ClanSystem:CreateClan(clanName, ownerId, clanLogo, clanDesc)
	if not clanName or clanName == "" then
		return false, "El nombre del clan es requerido"
	end
	
	return ClanData:CreateClan(clanName, ownerId, clanLogo, clanDesc)
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
	
	local inviterData = clanData.miembros_data[inviterId]
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
	
	local kickerData = clanData.miembros_data[kickerId]
	local targetData = clanData.miembros_data[targetUserId]
	
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
	
	local requesterData = clanData.miembros_data[requesterId]
	local targetData = clanData.miembros_data[targetUserId]
	
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
	
	local requesterData = clanData.miembros_data[requesterId]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_nombre") then
		return false, "No tienes permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {clanName = newName})
	return success, success and "Nombre actualizado" or result
end

function ClanSystem:ChangeDescription(clanId, requesterId, newDesc)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end
	
	local requesterData = clanData.miembros_data[requesterId]
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
	
	local requesterData = clanData.miembros_data[requesterId]
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

local InvitePlayerEvent = Instance.new("RemoteEvent", clanEvents)
InvitePlayerEvent.Name = "InvitePlayer"

local KickPlayerEvent = Instance.new("RemoteEvent", clanEvents)
KickPlayerEvent.Name = "KickPlayer"

local ChangeRoleEvent = Instance.new("RemoteEvent", clanEvents)
ChangeRoleEvent.Name = "ChangeRole"

local ChangeClanNameEvent = Instance.new("RemoteEvent", clanEvents)
ChangeClanNameEvent.Name = "ChangeClanName"

local ChangeClanDescEvent = Instance.new("RemoteEvent", clanEvents)
ChangeClanDescEvent.Name = "ChangeClanDescription"

local ChangeClanLogoEvent = Instance.new("RemoteEvent", clanEvents)
ChangeClanLogoEvent.Name = "ChangeClanLogo"

local DissolveEvent = Instance.new("RemoteEvent", clanEvents)
DissolveEvent.Name = "DissolveClan"

local GetClanDataEvent = Instance.new("RemoteEvent", clanEvents)
GetClanDataEvent.Name = "GetClanData"

local JoinClanEvent = Instance.new("RemoteFunction", clanEvents)
JoinClanEvent.Name = "JoinClan"

local AdminDissolveClanEvent = Instance.new("RemoteFunction", clanEvents)
AdminDissolveClanEvent.Name = "AdminDissolveClan"

local GetClansListFunction = Instance.new("RemoteFunction", clanEvents)
GetClansListFunction.Name = "GetClansList"

local GetPlayerClanFunction = Instance.new("RemoteFunction", clanEvents)
GetPlayerClanFunction.Name = "GetPlayerClan"

-- ============================================
-- MANEJADORES DE EVENTOS
-- ============================================
CreateClanEvent.OnServerInvoke = function(player, clanName, clanLogo, clanDesc)
	local success, clanId = ClanSystem:CreateClan(clanName, player.UserId, clanLogo, clanDesc)
	if success then
		print("✅ [Clan] Nuevo clan creado: " .. clanName .. " (" .. player.Name .. ")")
		return true, clanId, "Clan creado exitosamente"
	else
		warn("❌ [Clan] Error al crear clan: " .. tostring(clanId))
		return false, nil, clanId
	end
end

InvitePlayerEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:InvitePlayer(clanId, player.UserId, targetPlayerId)
	print(success and ("✅ " .. player.Name .. " invitó a un jugador") or ("❌ " .. msg))
end)

KickPlayerEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId)
	local success, msg = ClanSystem:KickPlayer(clanId, player.UserId, targetPlayerId)
	print(success and ("✅ " .. player.Name .. " expulsó a un jugador") or ("❌ " .. msg))
end)

ChangeRoleEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId, newRole)
	local success, msg = ClanSystem:ChangeRole(clanId, player.UserId, targetPlayerId, newRole)
	print(success and ("✅ Rol cambiado") or ("❌ " .. msg))
end)

ChangeClanNameEvent.OnServerEvent:Connect(function(player, clanId, newName)
	local success, msg = ClanSystem:ChangeName(clanId, player.UserId, newName)
	print(success and ("✅ Nombre actualizado: " .. newName) or ("❌ " .. msg))
end)

ChangeClanDescEvent.OnServerEvent:Connect(function(player, clanId, newDesc)
	local success, msg = ClanSystem:ChangeDescription(clanId, player.UserId, newDesc)
	print(success and "✅ Descripción actualizada" or ("❌ " .. msg))
end)

ChangeClanLogoEvent.OnServerEvent:Connect(function(player, clanId, newLogoId)
	local success, msg = ClanSystem:ChangeLogo(clanId, player.UserId, newLogoId)
	print(success and "✅ Logo actualizado" or ("❌ " .. msg))
end)

DissolveEvent.OnServerEvent:Connect(function(player, clanId)
	local success, msg = ClanSystem:DissolveClan(clanId, player.UserId)
	print(success and ("✅ Clan disuelto por: " .. player.Name) or ("❌ " .. msg))
end)

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

GetClansListFunction.OnServerInvoke = function(player)
	return ClanSystem:GetAllClans()
end

GetPlayerClanFunction.OnServerInvoke = function(player)
	local playerClanData = ClanSystem:GetPlayerClan(player.UserId)
	if playerClanData and playerClanData.clanId then
		return ClanSystem:GetClanData(playerClanData.clanId)
	end
	return nil
end

print("✅ [Sistema] Clan System inicializado (Simplificado)")

return {}
