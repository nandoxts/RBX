--[[
	═══════════════════════════════════════════════════════════
	SCRIPT DE VERIFICACIÓN - Usuario en Clan
	═══════════════════════════════════════════════════════════
	Verifica si el usuario 10179455284 está en algún clan
	
	ESTRUCTURA DE DATOS:
	- player:{userId} → {clanId, role}
	- clan:{clanId}   → datos completos del clan con members
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar a que cargue la configuración
local Config = ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig")
local ClanSystemConfig = require(Config)

-- DataStore del sistema de clanes
local DS = DataStoreService:GetDataStore(ClanSystemConfig.DATABASE.ClanStoreName)

-- Usuario a verificar
local USER_ID = 10179455284

-- ═══════════════════════════════════════════════════════════
-- FUNCIÓN DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════
local function verificarUsuario()
	print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🔍 VERIFICANDO USUARIO:", USER_ID)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	
	-- PASO 1: Buscar data del jugador
	local success, playerData = pcall(function()
		return DS:GetAsync("player:" .. tostring(USER_ID))
	end)
	
	if not success then
		warn("❌ Error al consultar DataStore:", playerData)
		return
	end
	
	-- PASO 2: Verificar si está en algún clan
	if not playerData then
		print("📊 Resultado: El usuario NO está en ningún clan")
		print("   • Key consultada: player:" .. tostring(USER_ID))
		print("   • Valor obtenido: nil\n")
		return
	end
	
	print("✅ El usuario SÍ está en un clan!")
	print("   • Clan ID:", playerData.clanId)
	print("   • Rol:", playerData.role)
	
	-- PASO 3: Obtener detalles del clan
	local clanSuccess, clanData = pcall(function()
		return DS:GetAsync("clan:" .. playerData.clanId)
	end)
	
	if clanSuccess and clanData then
		print("\n📋 Detalles del clan:")
		print("   • Nombre:", clanData.name)
		print("   • TAG:", clanData.tag)
		print("   • Descripción:", clanData.description)
		print("   • Emoji:", clanData.emoji)
		
		-- Contar miembros
		local memberCount = 0
		if clanData.members then
			for _ in pairs(clanData.members) do
				memberCount = memberCount + 1
			end
		end
		print("   • Total miembros:", memberCount)
		
		-- Verificar si está en la lista de miembros
		if clanData.members and clanData.members[tostring(USER_ID)] then
			local memberInfo = clanData.members[tostring(USER_ID)]
			print("\n👤 Info del miembro:")
			print("   • Nombre:", memberInfo.name)
			print("   • Rol en members:", memberInfo.role)
			print("   • Se unió:", os.date("%d/%m/%Y %H:%M", memberInfo.joinedAt))
		end
		
		-- Verificar si es owner
		if clanData.owners then
			for _, ownerId in ipairs(clanData.owners) do
				if ownerId == USER_ID then
					print("   • 👑 ES OWNER DEL CLAN")
					break
				end
			end
		end
	else
		warn("⚠️  No se pudieron obtener los detalles del clan")
	end
	
	print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("✓ Verificación completada")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
end

-- ═══════════════════════════════════════════════════════════
-- EJECUTAR
-- ═══════════════════════════════════════════════════════════
wait(3) -- Esperar a que el juego cargue completamente
verificarUsuario()
