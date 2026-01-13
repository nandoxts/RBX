local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

local ClanData = {}

-- ============================================
-- DATASTORES
-- ============================================
local clanStore = DataStoreService:GetDataStore(Config.DATABASE.ClanStoreName)
local playerClanStore = DataStoreService:GetDataStore(Config.DATABASE.PlayerClanStoreName)
local auditStore = DataStoreService:GetDataStore(Config.DATABASE.AuditStoreName)
local indexStore = DataStoreService:GetDataStore("ClansIndex_v1")

-- ============================================
-- EVENTO DE ACTUALIZACIÓN
-- ============================================
local clanDataUpdatedEvent = Instance.new("BindableEvent")

-- ============================================
-- HELPERS
-- ============================================
local function getPlayerName(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.Name
	end
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	return success and name or tostring(userId)
end

local function generateClanId()
	return string.sub(HttpService:GenerateGUID(false), 1, 12)
end

-- ============================================
-- ÍNDICE DE CLANES
-- ============================================
local function getIndex()
	local success, data = pcall(function()
		return indexStore:GetAsync("clans_index")
	end)
	if success and data then
		return data
	end
	return {
		clans = {},
		names = {},
		tags = {}
	}
end

local function saveIndex(index)
	local success, err = pcall(function()
		indexStore:SetAsync("clans_index", index)
	end)
	return success, err
end

local function addToIndex(clanId, clanName, clanTag)
	local index = getIndex()
	index.clans[clanId] = {name = clanName, tag = clanTag}
	index.names[string.lower(clanName)] = clanId
	index.tags[string.upper(clanTag)] = clanId
	return saveIndex(index)
end

local function removeFromIndex(clanId, clanName, clanTag)
	local index = getIndex()
	index.clans[clanId] = nil
	if clanName then
		index.names[string.lower(clanName)] = nil
	end
	if clanTag then
		index.tags[string.upper(clanTag)] = nil
	end
	return saveIndex(index)
end

local function nameExistsInIndex(clanName)
	local index = getIndex()
	return index.names[string.lower(clanName)] ~= nil
end

local function tagExistsInIndex(clanTag)
	local index = getIndex()
	return index.tags[string.upper(clanTag)] ~= nil
end

-- ============================================
-- OBTENER CLAN
-- ============================================
function ClanData:GetClan(clanId)
	if not clanId then return nil end

	local success, data = pcall(function()
		return clanStore:GetAsync("clan:" .. clanId)
	end)

	if not success or not data then
		return nil
	end

	-- Migración: convertir keys numéricas a strings
	if data.miembros_data then
		local needsMigration = false
		local newMiembrosData = {}

		for odigo, memberData in pairs(data.miembros_data) do
			local userIdStr = tostring(odigo)
			newMiembrosData[userIdStr] = memberData
			if type(odigo) == "number" then
				needsMigration = true
			end
		end

		if needsMigration then
			data.miembros_data = newMiembrosData
			pcall(function()
				clanStore:SetAsync("clan:" .. clanId, data)
			end)
		end
	end

	return data
end

-- ============================================
-- OBTENER CLAN DEL JUGADOR (con verificación)
-- ============================================
function ClanData:GetPlayerClan(userId)
	local success, data = pcall(function()
		return playerClanStore:GetAsync("player:" .. tostring(userId))
	end)

	if not success or not data then
		return nil
	end

	-- VERIFICAR que el clan realmente existe
	if data.clanId then
		local clanExists = self:GetClan(data.clanId)
		if not clanExists then
			-- Clan no existe, limpiar registro huérfano
			print("  🧹 Limpiando registro huérfano para userId: " .. tostring(userId))
			pcall(function()
				playerClanStore:RemoveAsync("player:" .. tostring(userId))
			end)
			return nil
		end
	end

	return data
end

-- ============================================
-- LIMPIAR REGISTRO DE JUGADOR (forzado)
-- ============================================
function ClanData:ClearPlayerClan(userId)
	local success = pcall(function()
		playerClanStore:RemoveAsync("player:" .. tostring(userId))
	end)
	return success
end

-- ============================================
-- OBTENER TODOS LOS CLANES
-- ============================================
function ClanData:GetAllClans()
	local index = getIndex()
	local result = {}

	for clanId, basicInfo in pairs(index.clans) do
		local clanData = self:GetClan(clanId)
		if clanData then
			table.insert(result, {
				clanId = clanId,
				clanName = clanData.clanName,
				clanTag = clanData.clanTag,
				clanLogo = clanData.clanLogo,
				clanEmoji = clanData.clanEmoji or "",
				clanColor = clanData.clanColor,
				descripcion = clanData.descripcion,
				nivel = clanData.nivel or 1,
				miembros_count = clanData.miembros and #clanData.miembros or 0,
				fechaCreacion = clanData.fechaCreacion
			})
		else
			-- Clan en índice pero no existe, limpiar
			print("  🧹 Limpiando clan huérfano del índice: " .. clanId)
			removeFromIndex(clanId, basicInfo.name, basicInfo.tag)
		end
	end

	return result
end

-- ============================================
-- CREAR CLAN
-- ============================================
function ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc, clanEmoji, clanColor)
	-- Validaciones básicas
	local validName, nameError = Config:ValidateClanName(clanName)
	if not validName then
		return false, nil, nameError
	end

	local validTag, tagError = Config:ValidateTag(clanTag)
	if not validTag then
		return false, nil, tagError
	end

	if not ownerId or ownerId == 0 then
		return false, nil, "Datos del jugador inválidos"
	end

	-- Verificar que el owner no tenga clan (GetPlayerClan ya limpia huérfanos)
	local existingClan = self:GetPlayerClan(ownerId)
	if existingClan then
		return false, nil, "Ya perteneces a un clan"
	end

	-- Verificar duplicados en índice
	if nameExistsInIndex(clanName) then
		return false, nil, "Ya existe un clan con ese nombre"
	end

	if tagExistsInIndex(clanTag) then
		return false, nil, "Ya existe un clan con ese TAG"
	end

	local clanId = generateClanId()
	local ownerName = getPlayerName(ownerId)
	local now = os.time()
	local upperTag = string.upper(clanTag)

	local fullClanData = {
		clanId = clanId,
		clanName = clanName,
		clanTag = upperTag,
		clanLogo = clanLogo or "rbxassetid://0",
		clanEmoji = clanEmoji or "",
		clanColor = clanColor,
		owner = ownerId,
		colideres = {},
		lideres = {},
		miembros = {ownerId},
		descripcion = clanDesc or "Sin descripción",
		nivel = 1,
		fechaCreacion = now,
		joinRequests = {}, -- Solicitudes de unión pendientes
		miembros_data = {
			[tostring(ownerId)] = {
				nombre = ownerName,
				rol = "owner",
				fechaUnion = now
			}
		}
	}

	-- Guardar en DataStore
	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, fullClanData)
		playerClanStore:SetAsync("player:" .. tostring(ownerId), {clanId = clanId, rol = "owner"})
	end)

	if not success then
		return false, nil, err and tostring(err) or "Error al guardar en DataStore"
	end

	-- Agregar al índice
	addToIndex(clanId, clanName, upperTag)

	clanDataUpdatedEvent:Fire()
	return true, clanId, fullClanData
end

-- ============================================
-- ACTUALIZAR CLAN
-- ============================================
function ClanData:UpdateClan(clanId, updates)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local oldName, oldTag = clanData.clanName, clanData.clanTag

	-- Verificar duplicados si cambia nombre o tag
	if updates.clanName and string.lower(updates.clanName) ~= string.lower(oldName) then
		if nameExistsInIndex(updates.clanName) then
			return false, "Ya existe un clan con ese nombre"
		end
	end

	if updates.clanTag and string.upper(updates.clanTag) ~= string.upper(oldTag) then
		if tagExistsInIndex(updates.clanTag) then
			return false, "Ya existe un clan con ese TAG"
		end
	end

	-- Aplicar cambios
	for k, v in pairs(updates) do
		clanData[k] = v
	end

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	if success then
		-- Actualizar índice si cambió nombre o tag
		if updates.clanName or updates.clanTag then
			local index = getIndex()

			if updates.clanName then
				index.names[string.lower(oldName)] = nil
				index.names[string.lower(updates.clanName)] = clanId
			end
			if updates.clanTag then
				index.tags[string.upper(oldTag)] = nil
				index.tags[string.upper(updates.clanTag)] = clanId
			end

			index.clans[clanId] = {
				name = clanData.clanName,
				tag = clanData.clanTag
			}

			saveIndex(index)
		end

		clanDataUpdatedEvent:Fire()
	end

	return success, success and clanData or err
end

-- ============================================
-- AGREGAR MIEMBRO
-- ============================================
function ClanData:AddMember(clanId, userId, rol)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local userIdStr = tostring(userId)

	if clanData.miembros_data and clanData.miembros_data[userIdStr] then
		return false, "Ya es miembro del clan"
	end

	local existingClan = self:GetPlayerClan(userId)
	if existingClan then
		return false, "Ya pertenece a otro clan"
	end

	table.insert(clanData.miembros, userId)
	clanData.miembros_data = clanData.miembros_data or {}
	clanData.miembros_data[userIdStr] = {
		nombre = getPlayerName(userId),
		rol = rol or "miembro",
		fechaUnion = os.time()
	}

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. userIdStr, {clanId = clanId, rol = rol or "miembro"})
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and clanData or err
end

-- ============================================
-- REMOVER MIEMBRO
-- ============================================
function ClanData:RemoveMember(clanId, userId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local userIdStr = tostring(userId)

	for i, memberId in ipairs(clanData.miembros) do
		if memberId == userId then
			table.remove(clanData.miembros, i)
			break
		end
	end

	if clanData.miembros_data then
		clanData.miembros_data[userIdStr] = nil
	end

	for i, id in ipairs(clanData.colideres or {}) do
		if id == userId then
			table.remove(clanData.colideres, i)
			break
		end
	end

	for i, id in ipairs(clanData.lideres or {}) do
		if id == userId then
			table.remove(clanData.lideres, i)
			break
		end
	end

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:RemoveAsync("player:" .. userIdStr)
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and clanData or err
end

-- ============================================
-- CAMBIAR ROL
-- ============================================
function ClanData:ChangeRole(clanId, userId, newRole)
	local clanData = self:GetClan(clanId)
	local userIdStr = tostring(userId)

	if not clanData or not clanData.miembros_data or not clanData.miembros_data[userIdStr] then
		return false, "Miembro no encontrado"
	end

	local oldRole = clanData.miembros_data[userIdStr].rol

	if oldRole == "colider" then
		for i, id in ipairs(clanData.colideres or {}) do
			if id == userId then
				table.remove(clanData.colideres, i)
				break
			end
		end
	elseif oldRole == "lider" then
		for i, id in ipairs(clanData.lideres or {}) do
			if id == userId then
				table.remove(clanData.lideres, i)
				break
			end
		end
	end

	if newRole == "colider" then
		clanData.colideres = clanData.colideres or {}
		table.insert(clanData.colideres, userId)
	elseif newRole == "lider" then
		clanData.lideres = clanData.lideres or {}
		table.insert(clanData.lideres, userId)
	end

	clanData.miembros_data[userIdStr].rol = newRole

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. userIdStr, {clanId = clanId, rol = newRole})
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and clanData or err
end

-- ============================================
-- DISOLVER CLAN
-- ============================================
function ClanData:DissolveClan(clanId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	if clanData.miembros_data then
		for userIdStr, _ in pairs(clanData.miembros_data) do
			pcall(function()
				playerClanStore:RemoveAsync("player:" .. userIdStr)
			end)
		end
	end

	local success, err = pcall(function()
		clanStore:RemoveAsync("clan:" .. clanId)
	end)

	if success then
		removeFromIndex(clanId, clanData.clanName, clanData.clanTag)
		clanDataUpdatedEvent:Fire()
	end

	return success, err
end

-- ============================================
-- SOLICITUDES DE UNIÓN
-- ============================================

-- ENVIAR SOLICITUD DE UNIÓN
function ClanData:RequestJoinClan(clanId, playerId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local playerIdStr = tostring(playerId)

	-- Verificar si ya es miembro
	if clanData.miembros_data and clanData.miembros_data[playerIdStr] then
		return false, "Ya eres miembro de este clan"
	end

	-- Verificar si ya pertenece a otro clan
	local existingClan = self:GetPlayerClan(playerId)
	if existingClan then
		return false, "Ya perteneces a otro clan"
	end

	-- Verificar si ya tiene una solicitud pendiente
	if clanData.joinRequests and clanData.joinRequests[playerIdStr] then
		return false, "Ya tienes una solicitud pendiente para este clan"
	end

	-- Crear solicitud
	clanData.joinRequests = clanData.joinRequests or {}
	clanData.joinRequests[playerIdStr] = {
		playerId = playerId,
		playerName = getPlayerName(playerId),
		requestTime = os.time(),
		status = "pending"
	}

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and "Solicitud enviada" or err
end

-- APROBAR SOLICITUD DE UNIÓN
function ClanData:ApproveJoinRequest(clanId, approverId, targetUserId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local approverIdStr = tostring(approverId)
	local targetIdStr = tostring(targetUserId)

	-- Verificar permisos (owner, colider, lider)
	local memberData = clanData.miembros_data and clanData.miembros_data[approverIdStr]
	if not memberData then
		return false, "No eres miembro de este clan"
	end

	local hasPermission = (memberData.rol == "owner" or memberData.rol == "colider" or memberData.rol == "lider")
	if not hasPermission then
		return false, "No tienes permisos para aprobar solicitudes"
	end

	-- Verificar que existe la solicitud
	if not clanData.joinRequests or not clanData.joinRequests[targetIdStr] then
		return false, "No hay solicitud pendiente de este jugador"
	end

	-- Verificar que el objetivo no sea ya miembro
	if clanData.miembros_data and clanData.miembros_data[targetIdStr] then
		-- Limpiar solicitud si ya es miembro
		clanData.joinRequests[targetIdStr] = nil
		pcall(function()
			clanStore:SetAsync("clan:" .. clanId, clanData)
		end)
		clanDataUpdatedEvent:Fire()
		return false, "El jugador ya es miembro del clan"
	end

	-- Agregar al clan
	local success, err = self:AddMember(clanId, targetUserId, "miembro")
	if success then
		-- Limpiar solicitud
		clanData = self:GetClan(clanId) -- Recargar datos actualizados
		if clanData.joinRequests then
			clanData.joinRequests[targetIdStr] = nil
			pcall(function()
				clanStore:SetAsync("clan:" .. clanId, clanData)
			end)
		end
		clanDataUpdatedEvent:Fire()
	end

	return success, success and "Solicitud aprobada" or err
end

-- RECHAZAR SOLICITUD DE UNIÓN
function ClanData:RejectJoinRequest(clanId, rejectorId, targetUserId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local rejectorIdStr = tostring(rejectorId)
	local targetIdStr = tostring(targetUserId)

	-- Verificar permisos
	local memberData = clanData.miembros_data and clanData.miembros_data[rejectorIdStr]
	if not memberData then
		return false, "No eres miembro de este clan"
	end

	local hasPermission = (memberData.rol == "owner" or memberData.rol == "colider" or memberData.rol == "lider")
	if not hasPermission then
		return false, "No tienes permisos para rechazar solicitudes"
	end

	-- Verificar que existe la solicitud
	if not clanData.joinRequests or not clanData.joinRequests[targetIdStr] then
		return false, "No hay solicitud pendiente de este jugador"
	end

	-- Rechazar solicitud
	clanData.joinRequests[targetIdStr] = nil

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and "Solicitud rechazada" or err
end

-- OBTENER SOLICITUDES PENDIENTES
function ClanData:GetJoinRequests(clanId, requesterId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return {}
	end

	local requesterIdStr = tostring(requesterId)

	-- Verificar permisos
	local memberData = clanData.miembros_data and clanData.miembros_data[requesterIdStr]
	if not memberData then
		return {}
	end

	local hasPermission = (memberData.rol == "owner" or memberData.rol == "colider" or memberData.rol == "lider")
	if not hasPermission then
		return {}
	end

	-- Retornar solicitudes pendientes
	local requests = {}
	if clanData.joinRequests then
		for playerIdStr, requestData in pairs(clanData.joinRequests) do
			if requestData.status == "pending" then
				table.insert(requests, {
					playerId = requestData.playerId,
					playerName = requestData.playerName,
					requestTime = requestData.requestTime
				})
			end
		end
	end

	return requests
end

-- ============================================
-- CLANES POR DEFECTO
-- ============================================
local defaultClansProcessed = false

function ClanData:CreateDefaultClans()
	if defaultClansProcessed then
		print("[ClanData] CreateDefaultClans ya procesado")
		return 0
	end
	defaultClansProcessed = true

	if not Config.DEFAULT_CLANS or #Config.DEFAULT_CLANS == 0 then
		return 0
	end

	local created, skipped = 0, 0

	for _, defaultClan in ipairs(Config.DEFAULT_CLANS) do
		-- Verificar en índice primero
		if tagExistsInIndex(defaultClan.clanTag) then
			skipped = skipped + 1
		elseif nameExistsInIndex(defaultClan.clanName) then
			skipped = skipped + 1
		else
			-- Limpiar cualquier registro huérfano del owner ANTES de crear
			local existingPlayerClan = self:GetPlayerClan(defaultClan.ownerId)
			-- GetPlayerClan ya limpia huérfanos automáticamente

			local success, clanId, result = self:CreateClan(
				defaultClan.clanName,
				defaultClan.ownerId,
				defaultClan.clanTag,
				defaultClan.clanLogo or "rbxassetid://0",
				defaultClan.descripcion or "Clan oficial",
				defaultClan.clanEmoji or "",
				defaultClan.clanColor
			)

			-- Si el clan se creó exitosamente y hay atributos adicionales, actualizarlos
			if success and clanId then
				local needsUpdate = false
				local clanData = self:GetClan(clanId)

				-- Agregar cualquier atributo adicional que no esté en CreateClan
				for key, value in pairs(defaultClan) do
					if not table.find({"clanName", "ownerId", "clanTag", "clanLogo", "descripcion", "clanEmoji", "clanColor"}, key) then
						clanData[key] = value
						needsUpdate = true
					end
				end

				-- Guardar si hay cambios
				if needsUpdate then
					local updateSuccess = pcall(function()
						clanStore:SetAsync("clan:" .. clanId, clanData)
					end)
					if updateSuccess then
						print("  ✅ Atributos adicionales agregados al clan:", defaultClan.clanName)
					end
				end
			end

			if success then
				created = created + 1
			end
		end

		task.wait(0.15) -- Evitar rate limits
	end

	return created
end

-- ============================================
-- SINCRONIZAR ÍNDICE (ejecutar una vez si hay problemas)
-- ============================================
function ClanData:RebuildIndex()
	local newIndex = {
		clans = {},
		names = {},
		tags = {}
	}

	saveIndex(newIndex)
	return true
end

-- ============================================
-- LIMPIAR TODOS LOS DATOS (usar con cuidado)
-- ============================================
function ClanData:ClearAllPlayerClans(userIds)
	for _, odigo in ipairs(userIds) do
		pcall(function()
			playerClanStore:RemoveAsync("player:" .. tostring(odigo))
		end)
	end
end

-- ============================================
-- AUDITORÍA
-- ============================================
function ClanData:LogAdminAction(adminId, adminName, action, clanId, clanName, details)
	if not Config.ADMINS.LogAdminActions then
		return true
	end

	pcall(function()
		local log = auditStore:GetAsync("admin_audit") or {}
		table.insert(log, {
			timestamp = os.time(),
			adminId = adminId,
			adminName = adminName,
			action = action,
			clanId = clanId,
			clanName = clanName,
			details = details or {}
		})
		if #log > 1000 then
			table.remove(log, 1)
		end
		auditStore:SetAsync("admin_audit", log)
	end)

	return true
end

function ClanData:GetAuditLog(limit)
	limit = limit or 50
	local success, log = pcall(function()
		return auditStore:GetAsync("admin_audit") or {}
	end)

	if not success then return {} end

	local result = {}
	for i = math.max(1, #log - limit + 1), #log do
		table.insert(result, 1, log[i])
	end

	return result
end

-- ============================================
-- EVENTO
-- ============================================
function ClanData:OnClanDataUpdated()
	return clanDataUpdatedEvent.Event
end

-- ============================================
-- VERIFICAR SOLICITUDES PENDIENTES DEL USUARIO
-- ============================================
function ClanData:GetUserPendingRequests(userId)
	local userIdStr = tostring(userId)
	local pendingRequests = {}

	-- Obtener todos los clanes
	local allClans = self:GetAllClans()

	for _, clanInfo in ipairs(allClans) do
		local clanData = self:GetClan(clanInfo.clanId)
		if clanData and clanData.joinRequests and clanData.joinRequests[userIdStr] then
			local request = clanData.joinRequests[userIdStr]
			if request.status == "pending" then
				table.insert(pendingRequests, {
					clanId = clanInfo.clanId,
					clanName = clanInfo.clanName,
					clanTag = clanInfo.clanTag,
					requestTime = request.requestTime
				})
			end
		end
	end

	return pendingRequests
end

-- ============================================
-- CANCELAR SOLICITUD DE UNIÓN
-- ============================================
function ClanData:CancelJoinRequest(clanId, playerId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local playerIdStr = tostring(playerId)

	-- Verificar que existe la solicitud
	if not clanData.joinRequests or not clanData.joinRequests[playerIdStr] then
		return false, "No tienes una solicitud pendiente en este clan"
	end

	-- Verificar que la solicitud sea del propio jugador
	if clanData.joinRequests[playerIdStr].playerId ~= playerId then
		return false, "No puedes cancelar solicitudes de otros jugadores"
	end

	-- Cancelar solicitud
	clanData.joinRequests[playerIdStr] = nil

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	if success then
		clanDataUpdatedEvent:Fire()
	end

	return success, success and "Solicitud cancelada" or err
end

-- CANCELAR TODAS LAS SOLICITUDES DE UNIÓN DEL USUARIO
function ClanData:CancelAllJoinRequests(playerId)
	local userIdStr = tostring(playerId)
	local allClans = self:GetAllClans()
	local count = 0
	for _, clanInfo in ipairs(allClans) do
		local clanData = self:GetClan(clanInfo.clanId)
		if clanData and clanData.joinRequests and clanData.joinRequests[userIdStr] then
			clanData.joinRequests[userIdStr] = nil
			pcall(function()
				clanStore:SetAsync("clan:" .. clanInfo.clanId, clanData)
			end)
			count = count + 1
		end
	end
	if count > 0 then
		clanDataUpdatedEvent:Fire()
	end
	return true, count .. " solicitudes canceladas"
end

return ClanData