-- ============================================
-- CLAN DATA - Arquitectura Simplificada
-- Base de datos nueva, sin migración, sin complejidad
-- ============================================
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

local ClanData = {}

-- ============================================
-- DATASTORE ÚNICO (nueva versión)
-- ============================================
local DS = DataStoreService:GetDataStore(Config.DATABASE.ClanStoreName)

-- ============================================
-- KEYS PATTERN
-- ============================================
-- clan:{clanId}        → Datos completos del clan
-- player:{userId}      → {clanId, role} minimal
-- index:names          → {[lowerName] = clanId}
-- index:tags           → {[upperTag] = clanId}

-- ============================================
-- EVENTO DE ACTUALIZACIÓN
-- ============================================
local updateEvent = Instance.new("BindableEvent")

-- ============================================
-- HELPERS
-- ============================================
local function genId()
	return string.sub(HttpService:GenerateGUID(false), 1, 12)
end

local function getPlayerName(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then return player.Name end
	
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	
	return success and name or "User_" .. userId
end

-- ============================================
-- ÍNDICES (operaciones atómicas)
-- ============================================
local function addToNameIndex(name, clanId)
	local key = string.lower(name)
	DS:UpdateAsync("index:names", function(current)
		local index = current or {}
		index[key] = clanId
		return index
	end)
end

local function removeFromNameIndex(name)
	if not name or type(name) ~= "string" or name == "" then 
		warn("[ClanData] removeFromNameIndex: nombre inválido:", name)
		return 
	end
	
	local success, err = pcall(function()
		local key = string.lower(name)
		DS:UpdateAsync("index:names", function(current)
			if not current then return nil end
			current[key] = nil
			return next(current) and current or nil
		end)
	end)
	
	if not success then
		warn("[ClanData] Error removiendo nombre del índice:", name, err)
	end
end

local function addToTagIndex(tag, clanId)
	local key = string.upper(tag)
	DS:UpdateAsync("index:tags", function(current)
		local index = current or {}
		index[key] = clanId
		return index
	end)
end

local function removeFromTagIndex(tag)
	if not tag or type(tag) ~= "string" or tag == "" then 
		warn("[ClanData] removeFromTagIndex: tag inválido:", tag)
		return 
	end
	
	local success, err = pcall(function()
		local key = string.upper(tag)
		DS:UpdateAsync("index:tags", function(current)
			if not current then return nil end
			current[key] = nil
			return next(current) and current or nil
		end)
	end)
	
	if not success then
		warn("[ClanData] Error removiendo tag del índice:", tag, err)
	end
end

local function nameExists(name)
	local index = DS:GetAsync("index:names")
	return index and index[string.lower(name)] ~= nil
end

local function tagExists(tag)
	local index = DS:GetAsync("index:tags")
	return index and index[string.upper(tag)] ~= nil
end

-- ============================================
-- OPERACIONES DE CLAN
-- ============================================

-- OBTENER CLAN
function ClanData:GetClan(clanId)
	if not clanId then return nil end
	
	local success, data = pcall(function()
		return DS:GetAsync("clan:" .. clanId)
	end)
	
	return success and data or nil
end

-- OBTENER CLAN DEL JUGADOR
function ClanData:GetPlayerClan(userId)
	local success, playerData = pcall(function()
		return DS:GetAsync("player:" .. tostring(userId))
	end)
	
	if not success or not playerData or not playerData.clanId then
		return nil
	end
	
	return self:GetClan(playerData.clanId)
end

-- OBTENER ROL DEL JUGADOR
function ClanData:GetPlayerRole(userId, clanId)
	local playerData = DS:GetAsync("player:" .. tostring(userId))
	if playerData and playerData.clanId == clanId then
		return playerData.role
	end
	return nil
end

-- CREAR CLAN
function ClanData:CreateClan(name, ownerId, tag, logo, desc, emoji, color)
	-- Validar
	local validName, errName = Config:ValidateClanName(name)
	if not validName then return false, errName end
	
	local validTag, errTag = Config:ValidateTag(tag)
	if not validTag then return false, errTag end
	
	if nameExists(name) then return false, "Nombre ya existe" end
	if tagExists(tag) then return false, "TAG ya existe" end
	
	-- Verificar que el owner no tenga clan
	local playerData = DS:GetAsync("player:" .. tostring(ownerId))
	if playerData and playerData.clanId then
		return false, "Ya tienes un clan"
	end
	
	local clanId = genId()
	local now = os.time()
	local upperTag = string.upper(tag)
	
	local clan = {
		clanId = clanId,
		name = name,
		tag = upperTag,
		logo = logo or Config.DEFAULTS.Logo,
		emoji = emoji or Config.DEFAULTS.Emoji,
		color = color or Config.DEFAULTS.Color,
		description = desc or Config.DEFAULTS.Description,
		createdAt = now,
		
		-- Owners array (soporta múltiples)
		owners = {ownerId},
		
		-- Miembros flat (key = userId string)
		members = {
			[tostring(ownerId)] = {
				name = getPlayerName(ownerId),
				role = Config.ROLE_NAMES.OWNER,
				joinedAt = now
			}
		}
	}
	
	-- Guardar clan
	DS:SetAsync("clan:" .. clanId, clan)
	
	-- Guardar player mapping
	DS:SetAsync("player:" .. tostring(ownerId), {
		clanId = clanId,
		role = Config.ROLE_NAMES.OWNER
	})
	
	-- Actualizar índices
	addToNameIndex(name, clanId)
	addToTagIndex(upperTag, clanId)
	
	updateEvent:Fire(clanId)
	return true, clanId, clan
end

-- ACTUALIZAR CLAN (atómico)
function ClanData:UpdateClan(clanId, updates)
	local clan = self:GetClan(clanId)
	if not clan then 
		return false, "Clan no encontrado" 
	end
	
	-- PASO 1: Validar cambios ANTES de updateAsync
	if updates.name and updates.name ~= clan.name then
		if nameExists(updates.name) then
			return false, "Nombre ya existe"
		end
	end
	
	if updates.tag and updates.tag ~= clan.tag then
		local upperTag = string.upper(updates.tag)
		if tagExists(upperTag) then
			return false, "TAG ya existe"
		end
		updates.tag = upperTag
	end
	
	-- PASO 2: Actualizar clan en DataStore (ATÓMICO)
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- Aplicar cambios simples (sin llamar funciones de DataStore)
			for k, v in pairs(updates) do
				current[k] = v
			end
			
			return current
		end)
	end)
	
	if not success then
		return false, tostring(result)
	end
	
	-- PASO 3: Actualizar índices SINCRÓNAMENTE (ANTES de disparar evento)
	if updates.name and updates.name ~= clan.name then
		removeFromNameIndex(clan.name)
		addToNameIndex(updates.name, clanId)
	end
	
	if updates.tag and updates.tag ~= clan.tag then
		removeFromTagIndex(clan.tag)
		addToTagIndex(updates.tag, clanId)
	end
	
	updateEvent:Fire(clanId)
	return true, result
end

-- AGREGAR MIEMBRO
function ClanData:AddMember(clanId, userId, role)
	role = role or Config.DEFAULTS.MemberRole
	local userIdStr = tostring(userId)
	
	-- Verificar que el usuario no tenga clan
	local playerData = DS:GetAsync("player:" .. userIdStr)
	if playerData and playerData.clanId then
		return false, "Usuario ya tiene clan"
	end
	
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- Verificar si ya es miembro
			if current.members[userIdStr] then
				error("Ya es miembro")
			end
			
			-- Agregar
			current.members[userIdStr] = {
				name = getPlayerName(userId),
				role = role,
				joinedAt = os.time()
			}
			
			return current
		end)
	end)
	
	if success then
		-- Actualizar player mapping
		DS:SetAsync("player:" .. userIdStr, {
			clanId = clanId,
			role = role
		})
		updateEvent:Fire(clanId)
		return true, result
	else
		return false, tostring(result)
	end
end

-- REMOVER MIEMBRO
function ClanData:RemoveMember(clanId, userId)
	local userIdStr = tostring(userId)
	
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- Remover
			current.members[userIdStr] = nil
			
			-- Remover de owners si está
			for i, ownerId in ipairs(current.owners) do
				if ownerId == userId then
					table.remove(current.owners, i)
					break
				end
			end
			
			return current
		end)
	end)
	
	if success then
		-- Limpiar player mapping
		DS:RemoveAsync("player:" .. userIdStr)
		updateEvent:Fire(clanId)
		return true, result
	else
		return false, tostring(result)
	end
end

-- CAMBIAR ROL
function ClanData:ChangeRole(clanId, userId, newRole)
	local userIdStr = tostring(userId)
	
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			if not current.members[userIdStr] then
				error("No es miembro")
			end
			
			current.members[userIdStr].role = newRole
			return current
		end)
	end)
	
	if success then
		-- Actualizar player mapping
		DS:UpdateAsync("player:" .. userIdStr, function(current)
			if current then
				current.role = newRole
			end
			return current
		end)
		updateEvent:Fire(clanId)
		return true, result
	else
		return false, tostring(result)
	end
end

-- AGREGAR OWNER
function ClanData:AddOwner(clanId, userId)
	local userIdStr = tostring(userId)
	
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- Verificar que no sea ya owner
			if table.find(current.owners, userId) then
				error("Ya es owner")
			end
			
			-- Agregar a owners
			table.insert(current.owners, userId)
			
			-- Si no es miembro, agregarlo
			if not current.members[userIdStr] then
				current.members[userIdStr] = {
					name = getPlayerName(userId),
					role = Config.ROLE_NAMES.OWNER,
					joinedAt = os.time()
				}
			else
				current.members[userIdStr].role = Config.ROLE_NAMES.OWNER
			end
			
			return current
		end)
	end)
	
	if success then
		DS:SetAsync("player:" .. userIdStr, {
			clanId = clanId,
			role = Config.ROLE_NAMES.OWNER
		})
		updateEvent:Fire(clanId)
		return true, result
	else
		return false, tostring(result)
	end
end

-- REMOVER OWNER
function ClanData:RemoveOwner(clanId, userId)
	local userIdStr = tostring(userId)
	
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- No puede quedar sin owners
			if #current.owners <= 1 then
				error("No puede quedar sin owners")
			end
			
			-- Remover de owners
			for i, ownerId in ipairs(current.owners) do
				if ownerId == userId then
					table.remove(current.owners, i)
					break
				end
			end
			
			-- Cambiar rol a miembro
			if current.members[userIdStr] then
				current.members[userIdStr].role = Config.DEFAULTS.MemberRole
			end
			
			return current
		end)
	end)
	
	if success then
		DS:UpdateAsync("player:" .. userIdStr, function(current)
			if current then
				current.role = Config.DEFAULTS.MemberRole
			end
			return current
		end)
		updateEvent:Fire(clanId)
		return true, result
	else
		return false, tostring(result)
	end
end

-- DISOLVER CLAN
function ClanData:DissolveClan(clanId)
	if not clanId then 
		warn("[ClanData] DissolveClan: clanId es nil")
		return false, "ID del clan inválido" 
	end
	
	local clan = self:GetClan(clanId)
	if not clan then 
		warn("[ClanData] DissolveClan: Clan no encontrado para ID:", clanId)
		return false, "Clan no encontrado" 
	end
	
	-- Validar que members existe
	if not clan.members then
		warn("[ClanData] DissolveClan: clan.members es nil para clanId:", clanId)
		clan.members = {} -- Asignar tabla vacía para evitar error
	end
	
	-- Limpiar todos los miembros
	for userIdStr in pairs(clan.members) do
		local success, err = pcall(function()
			DS:RemoveAsync("player:" .. userIdStr)
		end)
		if not success then
			warn("[ClanData] Error limpiando player:" .. tostring(userIdStr), err)
		end
	end
	
	-- Borrar clan
	local success, err = pcall(function()
		DS:RemoveAsync("clan:" .. clanId)
	end)
	if not success then
		warn("[ClanData] Error borrando clan:", clanId, err)
		return false, "Error al eliminar clan: " .. tostring(err)
	end
	
	-- Limpiar índices (solo si existen y son válidos)
	if clan.name and type(clan.name) == "string" and clan.name ~= "" then
		removeFromNameIndex(clan.name)
	end
	if clan.tag and type(clan.tag) == "string" and clan.tag ~= "" then
		removeFromTagIndex(clan.tag)
	end
	
	updateEvent:Fire(clanId)
	return true, "Clan disuelto"
end

-- OBTENER TODOS LOS CLANES
function ClanData:GetAllClans()
	local nameIndex = DS:GetAsync("index:names")
	if not nameIndex then return {} end
	
	local clans = {}
	local seenClanIds = {} -- Evitar duplicados
	
	for _, clanId in pairs(nameIndex) do
		-- Deduplicar por clanId
		if not seenClanIds[clanId] then
			seenClanIds[clanId] = true
			
			local clan = self:GetClan(clanId)
			if clan then
				-- Contar miembros
				local count = 0
				for _ in pairs(clan.members) do
					count = count + 1
				end
				clan.memberCount = count
				table.insert(clans, clan)
			end
		else
			-- Ignorar duplicado silenciosamente
		end
	end
	
	return clans
end

-- ============================================
-- SOLICITUDES DE UNIÓN (simplificadas)
-- ============================================

-- Obtener solicitudes PENDIENTES del usuario
local function getUserPendingRequests(userId)
	local userIdStr = tostring(userId)
	local success, requests = pcall(function()
		return DS:GetAsync("player:" .. userIdStr .. ":requests") or {}
	end)
	
	if success then
		return requests
	else
		return {}
	end
end

-- ENVIAR SOLICITUD
function ClanData:RequestJoin(clanId, userId)
	local clan = self:GetClan(clanId)
	if not clan then 
		return false, "Clan no encontrado" 
	end
	
	local playerClan = self:GetPlayerClan(userId)
	if playerClan then 
		return false, "Ya tienes clan" 
	end

	local userIdStr = tostring(userId)
	
	-- ✅ VALIDACIÓN DIRECTA: Verificar si ya tiene solicitud en ESTE clan
	if clan.requests and clan.requests[userIdStr] then
		return false, "Ya has solicitado unirte a este clan"
	end
	
	-- ✅ VALIDACIÓN: Verificar si tiene solicitudes en OTROS clanes
	local nameIndex = DS:GetAsync("index:names")
	if nameIndex then
		for _, otherClanId in pairs(nameIndex) do
			if otherClanId ~= clanId then
				local otherClan = self:GetClan(otherClanId)
				if otherClan and otherClan.requests and otherClan.requests[userIdStr] then
					return false, "Ya tienes una solicitud pendiente en otro clan"
				end
			end
		end
	end
	
	-- Guardar solicitud en el clan
	local success = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			if not current.requests then 
				current.requests = {} 
			end
			
			if current.requests[userIdStr] then
				error("Ya existe solicitud para este usuario")
			end
			
			current.requests[userIdStr] = {
				userId = userId,
				playerName = getPlayerName(userId),
				time = os.time(),
				status = "pending"
			}
			
			return current
		end)
	end)
	
	if success then
		-- 🔥 OPCIONAL: Registrar en índice (solo para GetUserRequests, no crítico)
		pcall(function()
			DS:UpdateAsync("player:" .. userIdStr .. ":requests", function(current)
				local requests = current or {}
				requests[tostring(clanId)] = os.time()
				return requests
			end)
		end)
		
		updateEvent:Fire(clanId)
		return true, "Solicitud enviada"
	else
		return false, "Error al guardar solicitud"
	end
end

-- APROBAR SOLICITUD
function ClanData:ApproveRequest(clanId, approverId, targetUserId)
	local clan = self:GetClan(clanId)
	if not clan then 
		return false, "Clan no encontrado" 
	end
	
	-- Verificar permisos
	local approverRole = clan.members[tostring(approverId)]
	if not approverRole then 
		return false, "No eres miembro" 
	end
	
	local hasPermission = Config:HasPermission(approverRole.role, "invitar")
	if not hasPermission then 
		return false, "Sin permisos" 
	end
	
	-- Verificar que existe la solicitud
	local targetIdStr = tostring(targetUserId)
	if not clan.requests or not clan.requests[targetIdStr] then
		return false, "No hay solicitud pendiente"
	end
	
	-- Agregar al clan
	local success, err = self:AddMember(clanId, targetUserId, Config.DEFAULTS.MemberRole)
	
	if success then
		-- Limpiar solicitud del clan
		DS:UpdateAsync("clan:" .. clanId, function(current)
			if current and current.requests then
				current.requests[targetIdStr] = nil
			end
			return current
		end)
		
		-- 🔥 Limpiar del índice de solicitudes del usuario
		DS:UpdateAsync("player:" .. targetIdStr .. ":requests", function(current)
			local requests = current or {}
			requests[tostring(clanId)] = nil
			return next(requests) and requests or nil  -- Borrar key si no quedan solicitudes
		end)
		
		updateEvent:Fire(clanId)
		return true, "Solicitud aprobada"
	else
		return false, err
	end
end

-- RECHAZAR SOLICITUD
function ClanData:RejectRequest(clanId, rejecterId, targetUserId)
	local clan = self:GetClan(clanId)
	if not clan then 
		return false, "Clan no encontrado" 
	end
	
	-- Verificar permisos
	local rejecterRole = clan.members[tostring(rejecterId)]
	if not rejecterRole then 
		return false, "No eres miembro" 
	end
	
	local hasPermission = Config:HasPermission(rejecterRole.role, "invitar")
	if not hasPermission then 
		return false, "Sin permisos" 
	end
	
	local targetIdStr = tostring(targetUserId)
	
	-- Limpiar solicitud del clan
	local success = pcall(function()
		DS:UpdateAsync("clan:" .. clanId, function(current)
			if current and current.requests then
				current.requests[targetIdStr] = nil
			end
			return current
		end)
	end)
	
	if success then
		-- 🔥 Limpiar del índice de solicitudes del usuario
		DS:UpdateAsync("player:" .. targetIdStr .. ":requests", function(current)
			local requests = current or {}
			requests[tostring(clanId)] = nil
			return next(requests) and requests or nil  -- Borrar key si no quedan solicitudes
		end)
		
		updateEvent:Fire(clanId)
		return true, "Solicitud rechazada"
	else
		return false, "Error al rechazar"
	end
end

-- OBTENER SOLICITUDES DEL CLAN
function ClanData:GetClanRequests(clanId, requesterId)
	local clan = self:GetClan(clanId)
	if not clan then 
		return {} 
	end
	
	-- Verificar permisos
	local requesterRole = clan.members[tostring(requesterId)]
	if not requesterRole or not Config:HasPermission(requesterRole.role, "invitar") then
		return {}
	end
	
	-- Convertir solicitudes a formato que espera el cliente
	-- MembersList necesita: playerId, playerName, requestTime
	local results = {}
	if clan.requests then
		for userIdStr, requestData in pairs(clan.requests) do
			local userId = tonumber(userIdStr)
			if userId then
				table.insert(results, {
					playerId = userId,
					playerName = getPlayerName(userId),
					requestTime = requestData.time,
					status = requestData.status
				})
			end
		end
	end
	
	return results
end

-- OBTENER SOLICITUDES DEL USUARIO (busca en todos los clanes)
function ClanData:GetUserRequests(userId)
	local userIdStr = tostring(userId)
	local nameIndex = DS:GetAsync("index:names")
	if not nameIndex then return {} end
	
	local result = {}
	for _, clanId in pairs(nameIndex) do
		local clan = self:GetClan(clanId)
		if clan and clan.requests and clan.requests[userIdStr] then
			local request = clan.requests[userIdStr]
			table.insert(result, {
				clanId = clanId,
				clanName = clan.name,
				time = request.time
			})
		end
	end
	
	return result
end

-- CANCELAR SOLICITUD
function ClanData:CancelRequest(clanId, userId)
	local userIdStr = tostring(userId)
	
	local success = pcall(function()
		DS:UpdateAsync("clan:" .. clanId, function(current)
			if current and current.requests then
				current.requests[userIdStr] = nil
			end
			return current
		end)
	end)
	
	if success then
		-- 🔥 Limpiar del índice de solicitudes del usuario
		DS:UpdateAsync("player:" .. userIdStr .. ":requests", function(current)
			local requests = current or {}
			requests[tostring(clanId)] = nil
			return next(requests) and requests or nil  -- Borrar key si no quedan solicitudes
		end)
		
		updateEvent:Fire(clanId)
		return true, "Solicitud cancelada"
	else
		return false, "Error al cancelar"
	end
end

-- CANCELAR TODAS LAS SOLICITUDES (usuario solicita cancelación de TODAS sus requests)
function ClanData:CancelAllRequests(userId)
	-- Iterar todos los clanes y eliminar solicitudes del usuario
	local nameIndex = DS:GetAsync("index:names")
	if not nameIndex then return true, "Sin solicitudes" end
	
	local userIdStr = tostring(userId)
	for _, clanId in pairs(nameIndex) do
		pcall(function()
			DS:UpdateAsync("clan:" .. clanId, function(current)
				if current and current.requests then
					current.requests[userIdStr] = nil
				end
				return current
			end)
		end)
	end
	
	-- 🔥 Limpiar COMPLETAMENTE el índice de solicitudes del usuario
	DS:RemoveAsync("player:" .. userIdStr .. ":requests")
	
	updateEvent:Fire(nil)
	return true, "Solicitudes canceladas"
end

-- ============================================
-- CLANES POR DEFECTO
-- ============================================
function ClanData:CreateDefaultClans()
	if not Config.DEFAULT_CLANS then return 0 end
	
	local created = 0
	for _, def in ipairs(Config.DEFAULT_CLANS) do
		if not nameExists(def.clanName) and not tagExists(def.clanTag) then
			local success = self:CreateClan(
				def.clanName,
				def.ownerId,
				def.clanTag,
				def.clanLogo,
				def.descripcion,
				def.clanEmoji,
				def.clanColor
			)
			if success then
				created = created + 1
			end
			task.wait(Config.DATABASE.CreateClanDelay)
		end
	end
	return created
end

-- ============================================
-- EVENTO
-- ============================================
function ClanData:OnUpdate()
	return updateEvent.Event
end

return ClanData
