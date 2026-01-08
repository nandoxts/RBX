local DataStoreService = game:GetService("DataStoreService")
local ClanData = {}

-- DataStores
local clanStore = DataStoreService:GetDataStore("ClansData")
local playerClanStore = DataStoreService:GetDataStore("PlayerClans")

-- Crear clan
function ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
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

return success, (success and clanId) or err, (success and clanData) or nil
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

return success, err
end

-- Obtener todos los clanes
function ClanData:GetAllClans()
local allClans = {}

local success, result = pcall(function()
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

table.insert(allClans, {
clanId = clanData.clanId,
clanName = clanData.clanName,
clanLogo = clanData.clanLogo,
descripcion = clanData.descripcion or "Sin descripción",
nivel = clanData.nivel or 1,
miembros_count = memberCount,
fechaCreacion = clanData.fechaCreacion
})
end
end
end

if pages.IsFinished then break end
pages:AdvanceToNextPageAsync()
end
end)

return success and allClans or {}
end

return ClanData
