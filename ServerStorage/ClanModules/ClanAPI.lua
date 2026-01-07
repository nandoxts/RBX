local ClanDatabase = require(script.Parent:FindFirstChild("ClanDatabase") or error("ClanDatabase no encontrado"))
local ClanPermissions = require(script.Parent:FindFirstChild("ClanPermissions") or error("ClanPermissions no encontrado"))

local ClanAPI = {}

-- Crear un nuevo clan
function ClanAPI:CreateClan(clanName, ownerId, clanLogo, clanDesc)
	if not clanName or clanName == "" then
		return false, "El nombre del clan es requerido"
	end

	if not ownerId or ownerId <= 0 then
		return false, "El ID del dueño es inválido"
	end

	local success, clanId, clanData = ClanDatabase:CreateClan(clanName, ownerId, clanLogo, clanDesc)
	if success then
		return true, clanId, clanData
	else
		return false, clanId -- clanId contiene el error
	end
end

-- Obtener clan del jugador
function ClanAPI:GetPlayerClan(userId)
	return ClanDatabase:GetPlayerClan(userId)
end

-- Obtener datos del clan
function ClanAPI:GetClanData(clanId)
	return ClanDatabase:GetClan(clanId)
end

-- Invitar jugador a clan
function ClanAPI:InvitePlayerToClan(clanId, inviterId, targetUserId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Obtener rol del invitador
	local inviterData = clanData.miembros_data[inviterId]
	if not inviterData then
		return false, "El invitador no es miembro del clan"
	end

	-- Verificar permisos
	if not ClanPermissions:HasPermission(inviterData.rol, "invitar") then
		return false, "No tienes permiso para invitar"
	end

	-- Agregar miembro
	local success, updatedClan = ClanDatabase:AddMember(clanId, targetUserId, "miembro")

	if success then
		return true, "Jugador invitado correctamente"
	else
		return false, updatedClan -- updatedClan contiene el error
	end
end

-- Expulsar jugador del clan
function ClanAPI:KickPlayerFromClan(clanId, kickerId, targetUserId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Evitar auto-expulsión
	if kickerId == targetUserId then
		return false, "No puedes expulsarte a ti mismo"
	end

	-- Obtener roles
	local kickerData = clanData.miembros_data[kickerId]
	local targetData = clanData.miembros_data[targetUserId]

	if not kickerData then
		return false, "El usuario que expulsa no es miembro"
	end

	if not targetData then
		return false, "El usuario a expulsar no es miembro"
	end

	-- Verificar permisos
	if not ClanPermissions:CanActOn(kickerData.rol, targetData.rol, "expulsar") then
		return false, "No tienes permiso para expulsar a este usuario"
	end

	-- Remover miembro
	local success, updatedClan = ClanDatabase:RemoveMember(clanId, targetUserId)

	if success then
		return true, "Jugador expulsado correctamente"
	else
		return false, updatedClan
	end
end

-- Cambiar rol de un miembro
function ClanAPI:ChangePlayerRole(clanId, requesterId, targetUserId, newRole)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data[requesterId]
	local targetData = clanData.miembros_data[targetUserId]

	if not requesterData then
		return false, "El usuario que solicita no es miembro"
	end

	if not targetData then
		return false, "El usuario objetivo no es miembro"
	end

	-- Verificar permisos según el nuevo rol
	local permissionNeeded = "cambiar_" .. newRole
	if not ClanPermissions:CanActOn(requesterData.rol, targetData.rol, permissionNeeded) then
		return false, "No tienes permiso para cambiar roles"
	end

	-- Cambiar rol
	local success, updatedClan = ClanDatabase:ChangeMemberRole(clanId, targetUserId, newRole)

	if success then
		return true, "Rol actualizado correctamente"
	else
		return false, updatedClan
	end
end

-- Cambiar descripción del clan
function ClanAPI:ChangeClanDescription(clanId, requesterId, newDescription)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data[requesterId]
	if not requesterData then
		return false, "El usuario no es miembro del clan"
	end

	if not ClanPermissions:HasPermission(requesterData.rol, "cambiar_descripcion") then
		return false, "No tienes permiso para cambiar la descripción"
	end

	local success, updatedClan = ClanDatabase:UpdateClan(clanId, {descripcion = newDescription})

	if success then
		return true, "Descripción actualizada"
	else
		return false, updatedClan
	end
end

-- Cambiar nombre del clan
function ClanAPI:ChangeClanName(clanId, requesterId, newName)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data[requesterId]
	if not requesterData then
		return false, "El usuario no es miembro del clan"
	end

	if not ClanPermissions:HasPermission(requesterData.rol, "cambiar_nombre") then
		return false, "No tienes permiso para cambiar el nombre"
	end

	if not newName or newName == "" then
		return false, "El nombre del clan no puede estar vacío"
	end

	local success, updatedClan = ClanDatabase:UpdateClan(clanId, {clanName = newName})

	if success then
		return true, "Nombre del clan actualizado"
	else
		return false, updatedClan
	end
end

-- Cambiar logo del clan
function ClanAPI:ChangeClanLogo(clanId, requesterId, newLogoAssetId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data[requesterId]
	if not requesterData then
		return false, "El usuario no es miembro del clan"
	end

	if not ClanPermissions:HasPermission(requesterData.rol, "cambiar_logo") then
		return false, "No tienes permiso para cambiar el logo"
	end

	if not newLogoAssetId or newLogoAssetId == "" then
		return false, "El ID del asset no es válido"
	end

	local success, updatedClan = ClanDatabase:UpdateClan(clanId, {clanLogo = newLogoAssetId})

	if success then
		return true, "Logo actualizado"
	else
		return false, updatedClan
	end
end

-- Disolver clan
function ClanAPI:DissolveClan(clanId, requesterId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Solo el owner puede disolver
	if clanData.owner ~= requesterId then
		return false, "Solo el owner puede disolver el clan"
	end

	local success, err = ClanDatabase:DissolveClan(clanId)

	if success then
		return true, "Clan disuelto"
	else
		return false, err
	end
end

-- Obtener miembros del clan
function ClanAPI:GetClanMembers(clanId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return nil
	end

	return clanData.miembros_data
end

-- Obtener estadísticas del clan
function ClanAPI:GetClanStats(clanId)
	local clanData = ClanDatabase:GetClan(clanId)
	if not clanData then
		return nil
	end

	return {
		clanId = clanData.clanId,
		clanName = clanData.clanName,
		owner = clanData.owner,
		totalMembers = #clanData.miembros,
		colideres = #clanData.colideres,
		lideres = #clanData.lideres,
		nivel = clanData.nivel,
		fechaCreacion = clanData.fechaCreacion
	}
end

-- Obtener todos los clanes
function ClanAPI:GetAllClans()
	return ClanDatabase:GetAllClans()
end

