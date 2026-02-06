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
-- request:{userId}     → {[clanId] = {time, status}}

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
	local key = string.lower(name)
	DS:UpdateAsync("index:names", function(current)
		if not current then return nil end
		current[key] = nil
		return next(current) and current or nil
	end)
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
	local key = string.upper(tag)
	DS:UpdateAsync("index:tags", function(current)
		if not current then return nil end
		current[key] = nil
		return next(current) and current or nil
	end)
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
	
	updateEvent:Fire()
	return true, clanId, clan
end

-- ACTUALIZAR CLAN (atómico)
function ClanData:UpdateClan(clanId, updates)
	local success, result = pcall(function()
		return DS:UpdateAsync("clan:" .. clanId, function(current)
			if not current then return nil end
			
			-- Validar cambios de nombre/tag
			if updates.name and updates.name ~= current.name then
				if nameExists(updates.name) then
					error("Nombre ya existe")
				end
				removeFromNameIndex(current.name)
				addToNameIndex(updates.name, clanId)
			end
			
			if updates.tag and updates.tag ~= current.tag then
				local upperTag = string.upper(updates.tag)
				if tagExists(upperTag) then
					error("TAG ya existe")
				end
				removeFromTagIndex(current.tag)
				addToTagIndex(upperTag, clanId)
				updates.tag = upperTag
			end
			
			-- Aplicar cambios
			for k, v in pairs(updates) do
				current[k] = v
			end
			
			return current
		end)
	end)
	
	if success then
		updateEvent:Fire()
		return true, result
	else
		return false, tostring(result)
	end
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
		updateEvent:Fire()
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
		DS:SetAsync("player:" .. userIdStr, nil)
		updateEvent:Fire()
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
		updateEvent:Fire()
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
		updateEvent:Fire()
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
		updateEvent:Fire()
		return true, result
	else
		return false, tostring(result)
	end
end

-- DISOLVER CLAN
function ClanData:DissolveClan(clanId)
	local clan = self:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	-- Limpiar todos los miembros
	for userIdStr in pairs(clan.members) do
		DS:SetAsync("player:" .. userIdStr, nil)
	end
	
	-- Borrar clan
	DS:SetAsync("clan:" .. clanId, nil)
	
	-- Limpiar índices
	removeFromNameIndex(clan.name)
	removeFromTagIndex(clan.tag)
	
	updateEvent:Fire()
	return true, "Clan disuelto"
end

-- OBTENER TODOS LOS CLANES
function ClanData:GetAllClans()
	local nameIndex = DS:GetAsync("index:names")
	if not nameIndex then return {} end
	
	local clans = {}
	for _, clanId in pairs(nameIndex) do
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
	end
	
	return clans
end

-- ============================================
-- SOLICITUDES DE UNIÓN (simplificadas)
-- ============================================

-- ENVIAR SOLICITUD
function ClanData:RequestJoin(clanId, userId)
	local clan = self:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local playerClan = self:GetPlayerClan(userId)
	if playerClan then return false, "Ya tienes clan" end
	
	local userIdStr = tostring(userId)
	
	-- Guardar solicitud del usuario
	local success = pcall(function()
		DS:UpdateAsync("request:" .. userIdStr, function(current)
			local requests = current or {}
			
			-- Verificar si ya tiene solicitud en este clan
			if requests[clanId] then
				error("Ya tienes solicitud pendiente")
			end
			
			requests[clanId] = {
				time = os.time(),
				status = "pending",
				clanName = clan.name
			}
			
			return requests
		end)
	end)
	
	if success then
		updateEvent:Fire()
		return true, "Solicitud enviada"
	else
		return false, "Error al enviar solicitud"
	end
end

-- APROBAR SOLICITUD
function ClanData:ApproveRequest(clanId, approverId, targetUserId)
	local clan = self:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	-- Verificar permisos
	local approverRole = clan.members[tostring(approverId)]
	if not approverRole then return false, "No eres miembro" end
	
	local hasPermission = Config:HasPermission(approverRole.role, "invitar")
	if not hasPermission then return false, "Sin permisos" end
	
	-- Verificar que existe la solicitud
	local targetIdStr = tostring(targetUserId)
	local requests = DS:GetAsync("request:" .. targetIdStr)
	if not requests or not requests[clanId] then
		return false, "No hay solicitud pendiente"
	end
	
	-- Agregar al clan
	local success, err = self:AddMember(clanId, targetUserId, Config.DEFAULTS.MemberRole)
	
	if success then
		-- Limpiar solicitud
		DS:UpdateAsync("request:" .. targetIdStr, function(current)
			if current then
				current[clanId] = nil
			end
			return next(current) and current or nil
		end)
		updateEvent:Fire()
		return true, "Solicitud aprobada"
	else
		return false, err
	end
end

-- RECHAZAR SOLICITUD
function ClanData:RejectRequest(clanId, rejecterId, targetUserId)
	local clan = self:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	-- Verificar permisos
	local rejecterRole = clan.members[tostring(rejecterId)]
	if not rejecterRole then return false, "No eres miembro" end
	
	local hasPermission = Config:HasPermission(rejecterRole.role, "invitar")
	if not hasPermission then return false, "Sin permisos" end
	
	local targetIdStr = tostring(targetUserId)
	
	-- Limpiar solicitud
	local success = pcall(function()
		DS:UpdateAsync("request:" .. targetIdStr, function(current)
			if current then
				current[clanId] = nil
			end
			return next(current) and current or nil
		end)
	end)
	
	if success then
		updateEvent:Fire()
		return true, "Solicitud rechazada"
	else
		return false, "Error al rechazar"
	end
end

-- OBTENER SOLICITUDES DEL CLAN
function ClanData:GetClanRequests(clanId, requesterId)
	local clan = self:GetClan(clanId)
	if not clan then return {} end
	
	-- Verificar permisos
	local requesterRole = clan.members[tostring(requesterId)]
	if not requesterRole or not Config:HasPermission(requesterRole.role, "invitar") then
		return {}
	end
	
	-- Buscar todas las solicitudes que mencionen este clan
	-- Esto requiere iterar players, pero es rápido si la BD es nueva
	local nameIndex = DS:GetAsync("index:names")
	if not nameIndex then return {} end
	
	local results = {}
	
	-- Por cada clan, buscar sus miembros actuales
	-- Luego buscar en request:{userId} solo de usuarios que NO estén en clanes
	-- OPTIMIZACIÓN: Guardar lista de solicitudes en el clan mismo
	
	-- Por simplicidad, guardamos también en el clan:
	return clan.requests or {}
end

-- OBTENER SOLICITUDES DEL USUARIO
function ClanData:GetUserRequests(userId)
	local requests = DS:GetAsync("request:" .. tostring(userId))
	if not requests then return {} end
	
	local result = {}
	for clanId, data in pairs(requests) do
		if data.status == "pending" then
			table.insert(result, {
				clanId = clanId,
				clanName = data.clanName,
				time = data.time
			})
		end
	end
	
	return result
end

-- CANCELAR SOLICITUD
function ClanData:CancelRequest(clanId, userId)
	local userIdStr = tostring(userId)
	
	local success = pcall(function()
		DS:UpdateAsync("request:" .. userIdStr, function(current)
			if current then
				current[clanId] = nil
			end
			return next(current) and current or nil
		end)
	end)
	
	if success then
		updateEvent:Fire()
		return true, "Solicitud cancelada"
	else
		return false, "Error al cancelar"
	end
end

-- CANCELAR TODAS LAS SOLICITUDES
function ClanData:CancelAllRequests(userId)
	DS:SetAsync("request:" .. tostring(userId), nil)
	updateEvent:Fire()
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
