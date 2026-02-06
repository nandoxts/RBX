--[[
	═══════════════════════════════════════════════════════════
	ADMIN GIFT GAMEPASS - Versión Múltiple
	═══════════════════════════════════════════════════════════
	Permite regalar múltiples gamepasses a múltiples usuarios
	
	USO:
	1. Agrega entradas a la lista REGALOS
	2. Ejecuta el script
	3. Los regalos se procesarán automáticamente
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════
-- ⚙️ LISTA DE REGALOS - EDITA AQUÍ
-- ═══════════════════════════════════════════════════════════

local REGALOS = {
	-- Formato: {userId = ID_USUARIO, gamepassId = ID_GAMEPASS}
	
	{userId = 10179455284, gamepassId = 123456789},  -- Ejemplo 1
	-- {userId = 987654321, gamepassId = 111111111},  -- Ejemplo 2 (comentado)
	-- {userId = 111222333, gamepassId = 222222222},  -- Ejemplo 3 (comentado)
	
	-- Agrega más regalos aquí...
}

-- ═══════════════════════════════════════════════════════════
-- 📦 SISTEMA
-- ═══════════════════════════════════════════════════════════

local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local DataStoreQueueManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)
local DataStoreQueue = DataStoreQueueManager.new(GiftedGamepassesData, "AdminGiftBatch", 0.2)

-- ═══════════════════════════════════════════════════════════
-- 🎁 FUNCIONES
-- ═══════════════════════════════════════════════════════════

local function regalarGamepass(userId, gamepassId)
	-- Validar datos
	if not userId or not gamepassId then
		return false, "❌ userId y gamepassId son requeridos"
	end
	
	-- Obtener nombre del usuario
	local userName = "Usuario desconocido"
	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	
	if not success then
		return false, "❌ Usuario inválido: " .. userId
	end
	
	userName = result
	
	-- Obtener información del gamepass
	local gamepassInfo = nil
	success, result = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	
	if not success or not result then
		return false, "❌ Gamepass inválido: " .. gamepassId
	end
	
	gamepassInfo = result
	
	-- Verificar si ya tiene el gamepass
	success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)
	
	if success and result then
		return true, "⚠️  Ya comprado: " .. userName .. " - " .. gamepassInfo.Name
	end
	
	-- Verificar si ya fue regalado
	local alreadyGifted = false
	local checkDone = false
	
	DataStoreQueue:GetAsync(userId .. "-" .. gamepassId, function(dsSuccess, dsResult)
		if dsSuccess and dsResult then
			alreadyGifted = true
		end
		checkDone = true
	end)
	
	local startTime = tick()
	while not checkDone and (tick() - startTime) < 5 do
		task.wait(0.05)
	end
	
	if alreadyGifted then
		return true, "⚠️  Ya regalado: " .. userName .. " - " .. gamepassInfo.Name
	end
	
	-- Guardar en DataStore
	local saveSuccess = false
	local saveDone = false
	
	DataStoreQueue:SetAsync(userId .. "-" .. gamepassId, true, function(dsSuccess, dsResult)
		saveSuccess = dsSuccess
		saveDone = true
	end)
	
	startTime = tick()
	while not saveDone and (tick() - startTime) < 10 do
		task.wait(0.05)
	end
	
	if not saveSuccess then
		return false, "❌ Error guardando: " .. userName .. " - " .. gamepassInfo.Name
	end
	
	-- Actualizar jugador si está conectado
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local Folder = player:FindFirstChild("Gamepasses")
		if not Folder then
			Folder = Instance.new("Folder")
			Folder.Name = "Gamepasses"
			Folder.Parent = player
		end
		
		local existingValue = Folder:FindFirstChild(gamepassInfo.Name)
		if not existingValue then
			local GamepassValue = Instance.new("BoolValue")
			GamepassValue.Name = gamepassInfo.Name
			GamepassValue.Value = true
			GamepassValue.Parent = Folder
		else
			existingValue.Value = true
		end
		
		if gamepassId == Configuration.VIP then
			player:SetAttribute("HasVIP", true)
		end
		
		if _G.HDConnect_HandleGiftedGamepass then
			pcall(_G.HDConnect_HandleGiftedGamepass, userId, gamepassId)
		end
	end
	
	return true, "✅ Regalado: " .. userName .. " - " .. gamepassInfo.Name
end

-- ═══════════════════════════════════════════════════════════
-- 🚀 PROCESAR TODOS LOS REGALOS
-- ═══════════════════════════════════════════════════════════

task.wait(3)

print("\n" .. string.rep("═", 50))
print("🎁 PROCESANDO REGALOS DE GAMEPASSES")
print(string.rep("═", 50))
print("Total de regalos en la lista:", #REGALOS)
print(string.rep("═", 50) .. "\n")

local exitosos = 0
local fallidos = 0
local omitidos = 0

for i, regalo in ipairs(REGALOS) do
	print(string.format("\n[%d/%d] Procesando...", i, #REGALOS))
	
	local exito, mensaje = regalarGamepass(regalo.userId, regalo.gamepassId)
	
	print(mensaje)
	
	if exito then
		if string.find(mensaje, "Ya") then
			omitidos = omitidos + 1
		else
			exitosos = exitosos + 1
		end
	else
		fallidos = fallidos + 1
	end
	
	-- Pequeño delay entre regalos para no saturar
	task.wait(0.3)
end

print("\n" .. string.rep("═", 50))
print("📊 RESUMEN FINAL")
print(string.rep("═", 50))
print("✅ Exitosos:", exitosos)
print("⚠️  Omitidos (ya tenían):", omitidos)
print("❌ Fallidos:", fallidos)
print("📦 Total procesados:", exitosos + omitidos + fallidos)
print(string.rep("═", 50) .. "\n")
