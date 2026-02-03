-- ============================================
-- DEBUG BÚSQUEDA DE CLANES ORPHANED
-- ============================================
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local clanStore = DataStoreService:GetDataStore("ClansData_v2")
local playerClanStore = DataStoreService:GetDataStore("PlayerClansData_v2")
local indexStore = DataStoreService:GetDataStore("ClansIndex_v1")

-- Versiones antiguas
local clanStoreOld = DataStoreService:GetDataStore("ClansData_v1")
local playerClanStoreOld = DataStoreService:GetDataStore("PlayerClansData_v1")

print("\n" .. string.rep("=", 100))
print("🔎 BÚSQUEDA EXHAUSTIVA DE CLANES (incluyendo orphaned)")
print(string.rep("=", 100) .. "\n")

-- ============================================
-- 1. VERIFICAR JUGADOR ACTUAL (ignxts)
-- ============================================
local currentPlayer = Players:FindFirstChild("ignxts")
if currentPlayer then
	print("👤 VERIFICANDO JUGADOR ACTUAL: ignxts (ID: 8387751399)\n")
	
	-- Buscar en v2
	print("  🔍 Buscando en PlayerClansData_v2...")
	local v2Success, v2Data = pcall(function()
		return playerClanStore:GetAsync("player:8387751399")
	end)
	if v2Success and v2Data then
		print("    ✅ ENCONTRADO EN V2")
		print("    " .. HttpService:JSONEncode(v2Data))
	else
		print("    ❌ No encontrado en v2")
	end
	
	-- Buscar en v1 (versión antigua)
	print("\n  🔍 Buscando en PlayerClansData_v1...")
	local v1Success, v1Data = pcall(function()
		return playerClanStoreOld:GetAsync("player:8387751399")
	end)
	if v1Success and v1Data then
		print("    ✅ ENCONTRADO EN V1 (VERSIÓN ANTIGUA)")
		print("    " .. HttpService:JSONEncode(v1Data))
		
		-- Si encontró en v1, buscar el clan
		if v1Data.clanId then
			print("\n    📍 Clan ID encontrado: " .. v1Data.clanId)
			print("    Buscando datos del clan en v1...")
			
			local clanV1Success, clanV1Data = pcall(function()
				return clanStoreOld:GetAsync("clan:" .. v1Data.clanId)
			end)
			
			if clanV1Success and clanV1Data then
				print("    ✅ CLAN ENCONTRADO EN V1")
				print("    Nombre: " .. (clanV1Data.clanName or "N/A"))
				print("    Tag: " .. (clanV1Data.clanTag or "N/A"))
				print("    Dueño: " .. tostring(clanV1Data.owner or "N/A"))
				print("    " .. HttpService:JSONEncode(clanV1Data))
			else
				print("    ❌ Clan no encontrado en v1")
			end
		end
	else
		print("    ❌ No encontrado en v1")
	end
	
	print("\n")
end

-- ============================================
-- 2. BUSCAR POR TODOS LOS CLANES POTENCIALES
-- ============================================
print(string.rep("=", 100))
print("🏰 BÚSQUEDA DE CLANES POTENCIALES CON NOMBRE VIP/ADMIN\n")

-- Lista de posibles IDs o patrones comunes
local possibleClanIds = {
	"vip", "VIP", "admin", "ADMIN", "premium", "PREMIUM", 
	"donator", "DONATOR", "staff", "STAFF", "moderator", "MODERATOR"
}

-- Intentar búsquedas directas con patrones conocidos
for _, pattern in ipairs(possibleClanIds) do
	local success, data = pcall(function()
		return clanStore:GetAsync("clan:" .. pattern)
	end)
	
	if success and data then
		print("✅ ENCONTRADO: " .. pattern)
		print("   Nombre: " .. (data.clanName or "N/A"))
		print("   " .. HttpService:JSONEncode(data) .. "\n")
	end
end

-- ============================================
-- 3. VERIFICAR TODOS LOS JUGADORES EN LÍNEA
-- ============================================
print(string.rep("=", 100))
print("👥 VERIFICAR ASOCIACIONES EN AMBAS VERSIONES\n")

local allPlayers = Players:GetPlayers()
for _, player in ipairs(allPlayers) do
	print("[👤 " .. player.Name .. " - ID: " .. player.UserId .. "]")
	
	-- Verificar v2
	local v2Success, v2Data = pcall(function()
		return playerClanStore:GetAsync("player:" .. tostring(player.UserId))
	end)
	
	-- Verificar v1
	local v1Success, v1Data = pcall(function()
		return playerClanStoreOld:GetAsync("player:" .. tostring(player.UserId))
	end)
	
	if (v2Success and v2Data) or (v1Success and v1Data) then
		if v2Success and v2Data then
			print("  ✅ En V2: Clan " .. v2Data.clanId)
		end
		if v1Success and v1Data then
			print("  ✅ En V1: Clan " .. v1Data.clanId)
		end
	else
		print("  ❌ Sin clan en ninguna versión")
	end
	
	print()
end

-- ============================================
-- 4. MOSTRAR ÍNDICES DE AMBAS VERSIONES
-- ============================================
print(string.rep("=", 100))
print("📋 VERIFICAR ÍNDICES\n")

-- V2
print("📊 ÍNDICE V2 (ClansIndex_v1):")
local indexV2Success, indexV2Data = pcall(function()
	return indexStore:GetAsync("clans_index")
end)

if indexV2Success and indexV2Data then
	print("  Clanes: " .. tostring(indexV2Data.clans and #indexV2Data.clans or 0))
	if indexV2Data.clans then
		for clanId, info in pairs(indexV2Data.clans) do
			print("    • " .. info.name .. " (" .. info.tag .. ") - ID: " .. clanId)
		end
	end
else
	print("  ❌ Error al leer índice v2")
end

print("\n")
print(string.rep("=", 100))
print("✅ BÚSQUEDA COMPLETADA")
print(string.rep("=", 100) .. "\n")
