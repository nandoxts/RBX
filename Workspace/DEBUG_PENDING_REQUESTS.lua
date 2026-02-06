--[[
	═══════════════════════════════════════════════════════════
	DEBUG SOLICITUDES PENDIENTES
	Script para debuggear qué está pasando con las solicitudes
	═══════════════════════════════════════════════════════════
]]

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuración
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))
local DS = DataStoreService:GetDataStore(Config.DATABASE.ClanStoreName)

-- VIP CLAN (reemplaza con tu clanId)
local VIP_CLAN_ID = "robloxclanvip" -- CAMBIA ESTO AL ID DE TU CLAN VIP

local function getPlayerName(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then return player.Name end
	
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	
	return success and name or "User_" .. userId
end

local function debugClan(clanId)
	print("\n" .. string.rep("═", 60))
	print("DEBUG CLAN: " .. clanId)
	print(string.rep("═", 60))
	
	-- 1. Obtener datos del clan
	local success, clanData = pcall(function()
		return DS:GetAsync("clan:" .. clanId)
	end)
	
	if not success or not clanData then
		print("❌ No se encontró el clan")
		return
	end
	
	print("✅ Clan encontrado: " .. (clanData.name or "?"))
	print("   Miembros:", clanData.memberCount or 0)
	
	-- 2. Verificar solicitudes del clan
	print("\n📋 SOLICITUDES EN clan:" .. clanId)
	if not clanData.requests or next(clanData.requests) == nil then
		print("   ❌ Sin solicitudes")
	else
		for userIdStr, reqData in pairs(clanData.requests) do
			local userId = tonumber(userIdStr)
			local name = getPlayerName(userId)
			print(string.format("   • %s (ID: %s) - Estado: %s - Hora: %s", 
				name, 
				userId, 
				reqData.status or "?",
				os.date("%H:%M:%S", reqData.time or 0)
			))
		end
	end
	
	-- 3. Verificar solicitudes por usuario (buscar en todos los clanes)
	print("\n📩 SOLICITUDES POR USUARIO (búsqueda en todos clanes)")
	
	local index = DS:GetAsync("index:names")
	if not index then
		print("   ❌ Sin clanes registrados")
	else
		for userIdStr in pairs(clanData.members or {}) do
			local userId = tonumber(userIdStr)
			local name = getPlayerName(userId)
			local foundRequests = {}
			
			-- Buscar este usuario en solicitudes de TODOS los clanes
			for _, checkClanId in pairs(index) do
				local success2, checkClan = pcall(function()
					return DS:GetAsync("clan:" .. checkClanId)
				end)
				
				if success2 and checkClan and checkClan.requests and checkClan.requests[userIdStr] then
					table.insert(foundRequests, checkClanId)
				end
			end
			
			if #foundRequests > 0 then
				print(string.format("   Usuario %s (%s):", name, userId))
				for _, foundClanId in ipairs(foundRequests) do
					print(string.format("      └─ Solicitud en clan: %s", foundClanId))
				end
			end
		end
	end
	
	-- 4. Test: Obtener solicitudes como lo haría el servidor
	print("\n✨ TEST GetJoinRequests (como lo ve el server):")
	local requesterRole = clanData.members[tostring(Players:GetPlayers()[1] and Players:GetPlayers()[1].UserId or 0)]
	if clanData.requests and next(clanData.requests) ~= nil then
		for userIdStr, requestData in pairs(clanData.requests) do
			local userId = tonumber(userIdStr)
			print(string.format("   • %s - Status: %s", getPlayerName(userId), requestData.status))
		end
	else
		print("   ❌ Sin solicitudes en clan.requests")
	end
end

-- FUNCTION PARA BUSCAR SOLICITUDES PENDIENTES EN TODO EL SERVIDOR
local function debugAllRequests()
	print("\n" .. string.rep("═", 60))
	print("DEBUG TODAS LAS SOLICITUDES PENDIENTES")
	print(string.rep("═", 60))
	
	-- Esto es un scan bruto, realmente lento pero útil para debug
	print("⚠️  Esto puede ser lento, escaneando...")
	
	-- Mejor: iteramos sobre clanes conocidos
	local success, nameIndex = pcall(function()
		return DS:GetAsync("index:names")
	end)
	
	if success and nameIndex then
		for clanName, clanId in pairs(nameIndex) do
			debugClan(clanId)
		end
	else
		print("❌ No se pudo obtener índice de clanes")
	end
end

-- EJECUTAR DEBUG
print("\n🔍 INICIANDO DEBUG DE SOLICITUDES")
print(string.format("🎮 Hora del servidor: %s", os.date("%Y-%m-%d %H:%M:%S")))

-- Debug del clan VIP
if VIP_CLAN_ID ~= "robloxclanvip" then
	debugClan(VIP_CLAN_ID)
else
	print("\n⚠️  NO CAMBIÓ EL VIP_CLAN_ID - Escaneando todos los clanes...")
	debugAllRequests()
end

print("\n" .. string.rep("═", 60))
print("DEBUG COMPLETADO")
print(string.rep("═", 60))

-- Monitoring automático
local function startMonitoring()
	print("\n🔄 INICIANDO MONITOREO AUTOMÁTICO (cada 5 segundos)")
	
	task.spawn(function()
		while true do
			task.wait(5)
			if VIP_CLAN_ID ~= "robloxclanvip" then
				print("\n[" .. os.date("%H:%M:%S") .. "] Verificando clan VIP...")
				debugClan(VIP_CLAN_ID)
			end
		end
	end)
end

-- Descomenta esto si quieres monitoreo automático:
-- startMonitoring()

return {
	debugClan = debugClan,
	debugAllRequests = debugAllRequests,
	startMonitoring = startMonitoring
}
