local DataStoreService = game:GetService("DataStoreService")
local ClanData = {}

-- DataStores
local clanStore = DataStoreService:GetDataStore("ClansData")
local playerClanStore = DataStoreService:GetDataStore("PlayerClans")
local auditStore = DataStoreService:GetDataStore("AdminAudit")
local clanCooldownStore = DataStoreService:GetDataStore("ClanCooldowns")

-- Base de datos en memoria (como DjDashboard)
local clansDatabase = {}
local playerClansCache = {} -- Caché en memoria para clanes de jugadores {userId -> {clanId, rol}}
local clanDataUpdatedEvent = Instance.new("BindableEvent")

-- Crear clan
function ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	-- Validaciones básicas primero
	if not clanName or clanName == "" then
		return false, nil, "El nombre del clan es requerido"
	end
	
	if not clanTag or clanTag == "" then
		return false, nil, "El TAG del clan es requerido"
	end
	
	if not ownerId or ownerId == 0 then
		return false, nil, "Datos del jugador inválidos"
	end
	
	-- Convertir a minúsculas para comparación segura
	local clanNameLower = tostring(clanName):lower()
	local clanTagUpper = tostring(clanTag):upper()
	
	-- Validar nombre único
	local nameExists = false
	for clanId, clan in pairs(clansDatabase) do
		if clan and clan.clanName then
			if tostring(clan.clanName):lower() == clanNameLower then
				nameExists = true
				break
			end
		end
	end
	
	if nameExists then
		return false, nil, "Ya existe un clan con ese nombre"
	end
	
	-- Validar TAG único
	local tagExists = false
	for clanId, clan in pairs(clansDatabase) do
		if clan and clan.clanTag then
			if tostring(clan.clanTag):upper() == clanTagUpper then
				tagExists = true
				break
			end
		end
	end
	
	if tagExists then
		return false, nil, "Ya existe un clan con ese TAG"
	end
	
	local clanId = tostring(game:GetService("HttpService"):GenerateGUID(false)):sub(1, 12)

	local clanData = {
		clanId = clanId,
		clanName = clanName,
		clanTag = clanTag or "TAG",
		clanLogo = clanLogo or "rbxassetid://0",
		owner = ownerId,
		colideres = {},
		lideres = {},
		miembros = {ownerId},
		descripcion = clanDesc or "Sin descripción",
		nivel = 1,
		fechaCreacion = os.time(),
		miembros_data = {
			[tostring(ownerId)] = {
				nombre = game:GetService("Players"):GetNameFromUserIdAsync(ownerId),
				rol = "owner",
				fechaUnion = os.time()
			}
		}
	}

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. tostring(ownerId), {clanId = clanId, rol = "owner"})
	end)

	-- Actualizar base de datos en memoria
	if success then
		clansDatabase[clanId] = {
			clanId = clanId,
			clanName = clanName,
			clanTag = clanTag or "TAG",
			clanLogo = clanLogo or "rbxassetid://0",
			descripcion = clanDesc or "Sin descripción",
			nivel = 1,
			miembros_count = 1,
			fechaCreacion = os.time()
		}
		clanDataUpdatedEvent:Fire()
		return true, clanId, clanData
	else
		-- Si hay error en DataStore, devolver el error específico
		return false, nil, (err and tostring(err)) or "Error al guardar el clan en la base de datos"
	end
end

-- Obtener clan
function ClanData:GetClan(clanId)
local success, data = pcall(function()
return clanStore:GetAsync("clan:" .. clanId)
end)

if success and data and data.miembros_data then
-- Migración automática: Convertir keys numéricas a strings
local newMiembrosData = {}
local needsMigration = false

for userId, memberData in pairs(data.miembros_data) do
local userIdStr = tostring(userId)
newMiembrosData[userIdStr] = memberData
if type(userId) == "number" then
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

return (success and data) or nil
end

-- Obtener clan del jugador
function ClanData:GetPlayerClan(userId)
local success, data = pcall(function()
return playerClanStore:GetAsync("player:" .. userId)
end)
return (success and data) or nil
end

-- Actualizar clan
function ClanData:UpdateClan(clanId, updates)
	local clanData = self:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	for k, v in pairs(updates) do
		clanData[k] = v
	end

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	-- Actualizar base de datos en memoria
	if success then
		if clansDatabase[clanId] then
			for k, v in pairs(updates) do
				if k ~= "miembros_data" and k ~= "miembros" and k ~= "colideres" and k ~= "lideres" then
					clansDatabase[clanId][k] = v
				end
			end
		end
		clanDataUpdatedEvent:Fire()
	end

	return success, (success and clanData) or err
end

-- Agregar miembro
function ClanData:AddMember(clanId, userId, rol)
local clanData = self:GetClan(clanId)
if not clanData then return false, "Clan no encontrado" end

for _, memberId in pairs(clanData.miembros) do
if memberId == userId then
return false, "Ya es miembro del clan"
end
end

table.insert(clanData.miembros, userId)
clanData.miembros_data[tostring(userId)] = {
nombre = game:GetService("Players"):GetNameFromUserIdAsync(userId),
rol = rol or "miembro",
fechaUnion = os.time()
}

local success, err = pcall(function()
clanStore:SetAsync("clan:" .. clanId, clanData)
playerClanStore:SetAsync("player:" .. tostring(userId), {clanId = clanId, rol = rol or "miembro"})
end)

return success, (success and clanData) or err
end

-- Remover miembro
function ClanData:RemoveMember(clanId, userId)
local clanData = self:GetClan(clanId)
if not clanData then return false, "Clan no encontrado" end

-- Remover de listas
for i, memberId in pairs(clanData.miembros) do
if memberId == userId then
table.remove(clanData.miembros, i)
break
end
end

clanData.miembros_data[tostring(userId)] = nil

for i, id in pairs(clanData.colideres) do
if id == userId then
table.remove(clanData.colideres, i)
break
end
end

for i, id in pairs(clanData.lideres) do
if id == userId then
table.remove(clanData.lideres, i)
break
end
end

local success, err = pcall(function()
clanStore:SetAsync("clan:" .. clanId, clanData)
playerClanStore:RemoveAsync("player:" .. tostring(userId))
end)

return success, (success and clanData) or err
end

-- Cambiar rol
function ClanData:ChangeRole(clanId, userId, newRole)
local clanData = self:GetClan(clanId)
if not clanData or not clanData.miembros_data[tostring(userId)] then
return false, "Miembro no encontrado"
end

local oldRole = clanData.miembros_data[tostring(userId)].rol

-- Remover de listas antiguas
if oldRole == "colider" then
for i, id in pairs(clanData.colideres) do
if id == userId then table.remove(clanData.colideres, i) break end
end
elseif oldRole == "lider" then
for i, id in pairs(clanData.lideres) do
if id == userId then table.remove(clanData.lideres, i) break end
end
end

-- Agregar a nueva lista
if newRole == "colider" then
table.insert(clanData.colideres, userId)
elseif newRole == "lider" then
table.insert(clanData.lideres, userId)
end

clanData.miembros_data[tostring(userId)].rol = newRole

local success, err = pcall(function()
clanStore:SetAsync("clan:" .. clanId, clanData)
playerClanStore:SetAsync("player:" .. tostring(userId), {clanId = clanId, rol = newRole})
end)

return success, (success and clanData) or err
end

-- Disolver clan
function ClanData:DissolveClan(clanId)
	local clanData = self:GetClan(clanId)
	if not clanData then return false, "Clan no encontrado" end

	-- Remover todos los jugadores
	if clanData.miembros_data then
		for userId, _ in pairs(clanData.miembros_data) do
			pcall(function()
				playerClanStore:RemoveAsync("player:" .. tostring(userId))
			end)
		end
	end

	local success, err = pcall(function()
		clanStore:RemoveAsync("clan:" .. clanId)
	end)

	-- Remover de base de datos en memoria
	if success then
		clansDatabase[clanId] = nil
		clanDataUpdatedEvent:Fire()
	end

	return success, err
end

-- Registrar auditoría (para acciones de admin)
function ClanData:LogAdminAction(adminId, adminName, action, clanId, clanName, details)
	local logEntry = {
		timestamp = os.time(),
		adminId = adminId,
		adminName = adminName,
		action = action, -- "delete_clan", "ban_player", "reset_clan", etc
		clanId = clanId,
		clanName = clanName,
		details = details or {} -- info adicional
	}
	
	pcall(function()
		local existingLog = auditStore:GetAsync("admin_audit") or {}
		table.insert(existingLog, logEntry)
		
		-- Mantener solo los últimos 1000 registros
		if #existingLog > 1000 then
			table.remove(existingLog, 1)
		end
		
		auditStore:SetAsync("admin_audit", existingLog)
	end)
	
	return true
end

-- Obtener log de auditoría
function ClanData:GetAuditLog(limit)
	limit = limit or 50
	local success, log = pcall(function()
		return auditStore:GetAsync("admin_audit") or {}
	end)
	
	if not success then return {} end
	
	-- Retornar últimos N registros en orden inverso (más recientes primero)
	local result = {}
	for i = math.max(1, #log - limit + 1), #log do
		table.insert(result, 1, log[i])
	end
	
	return result
end

-- Cargar todos los clanes desde DataStore (solo al inicializar)
function ClanData:LoadAllClans()
	local success = pcall(function()
		local pages = clanStore:ListKeysAsync()
		
		while true do
			local keys = pages:GetCurrentPage()
			
			for _, key in ipairs(keys) do
				if key.KeyName:match("^clan:") then
					local clanSuccess, clanData = pcall(function()
						return clanStore:GetAsync(key.KeyName)
					end)
					
					if clanSuccess and clanData then
						local memberCount = 0
						if clanData.miembros_data then
							for _ in pairs(clanData.miembros_data) do
								memberCount = memberCount + 1
							end
						end
						
						clansDatabase[clanData.clanId] = {
							clanId = clanData.clanId,
							clanName = clanData.clanName,
							clanTag = clanData.clanTag or "TAG",
							clanLogo = clanData.clanLogo,
							descripcion = clanData.descripcion or "Sin descripción",
							nivel = clanData.nivel or 1,
							miembros_count = memberCount,
							fechaCreacion = clanData.fechaCreacion
						}
					else
						-- Eliminar clan corrupto
						pcall(function()
							clanStore:RemoveAsync(key.KeyName)
						end)
					end
				end
			end
			
			if pages.IsFinished then 
				break 
			end
			
			pages:AdvanceToNextPageAsync()
		end
	end)
	
	return success
end

-- Obtener todos los clanes (directo desde memoria)
function ClanData:GetAllClans()
	local allClans = {}
	for _, clanData in pairs(clansDatabase) do
		table.insert(allClans, clanData)
	end
	return allClans
end

-- Obtener evento de actualización (como DjDashboard)
function ClanData:OnClanDataUpdated()
	return clanDataUpdatedEvent.Event
end

return ClanData
