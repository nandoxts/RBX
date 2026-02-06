--[[
	═══════════════════════════════════════════════════════════
	ADMIN GIFT GAMEPASS - Script Manual de Regalo
	═══════════════════════════════════════════════════════════
	Permite regalar gamepasses directamente a usuarios
	sin necesidad de compra.
	
	USO:
	1. Cambia USER_ID por el ID del usuario receptor
	2. Cambia GAMEPASS_ID por el ID del gamepass a regalar
	3. Ejecuta el script
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════
-- ⚙️ CONFIGURACIÓN - EDITA ESTOS VALORES
-- ═══════════════════════════════════════════════════════════

local USER_ID = 10464331837        -- ← ID del usuario que recibirá el gamepass
local GAMEPASS_ID = 1179926968     -- ← ID del gamepass a regalar (TOMBO/POLICÍA)

-- ═══════════════════════════════════════════════════════════
-- 📦 SISTEMA (No editar)
-- ═══════════════════════════════════════════════════════════

local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local DataStoreQueueManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)

-- Inicializar queue
local DataStoreQueue = DataStoreQueueManager.new(GiftedGamepassesData, "AdminGiftGamepass", 0.15)

-- ═══════════════════════════════════════════════════════════
-- 🎁 FUNCIÓN PRINCIPAL
-- ═══════════════════════════════════════════════════════════

local function regalarGamepass(userId, gamepassId)
	print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🎁 INICIANDO REGALO DE GAMEPASS")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	-- Validar datos
	if not userId or not gamepassId then
		warn("❌ Error: userId y gamepassId son requeridos")
		return false
	end
	
	-- Obtener nombre del usuario
	local userName = "Usuario desconocido"
	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	
	if not success then
		warn("❌ Error: No se pudo obtener el nombre del usuario con ID:", userId)
		return false
	end
	
	userName = result
	print("👤 Usuario:", userName, "(" .. userId .. ")")
	
	-- Obtener información del gamepass
	local gamepassInfo = nil
	success, result = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	
	if not success or not result then
		warn("❌ Error: No se pudo obtener información del gamepass ID:", gamepassId)
		return false
	end
	
	gamepassInfo = result
	print("🎫 Gamepass:", gamepassInfo.Name)
	
	-- Verificar si ya tiene el gamepass
	local alreadyOwns = false
	success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)
	
	if success and result then
		alreadyOwns = true
		print("⚠️  El usuario ya compró este gamepass directamente")
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
	
	-- Esperar verificación
	local startTime = tick()
	while not checkDone and (tick() - startTime) < 5 do
		task.wait(0.05)
	end
	
	if alreadyGifted then
		print("⚠️  El usuario ya tiene este gamepass regalado")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("ℹ️  No se requiere acción adicional")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
		return true
	end
	
	-- Guardar en DataStore
	print("💾 Guardando en DataStore...")
	local saveSuccess = false
	local saveDone = false
	
	DataStoreQueue:SetAsync(userId .. "-" .. gamepassId, true, function(dsSuccess, dsResult)
		saveSuccess = dsSuccess
		saveDone = true
	end)
	
	-- Esperar guardado
	startTime = tick()
	while not saveDone and (tick() - startTime) < 10 do
		task.wait(0.05)
	end
	
	if not saveSuccess then
		warn("❌ Error al guardar en DataStore")
		return false
	end
	
	print("✅ Guardado en DataStore exitoso")
	
	-- Actualizar jugador si está en el juego
	local player = Players:GetPlayerByUserId(userId)
	if player then
		print("🔄 Actualizando jugador conectado...")
		
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
		
		-- Actualizar atributo HasVIP si es el VIP
		if gamepassId == Configuration.VIP then
			player:SetAttribute("HasVIP", true)
			print("👑 Atributo HasVIP actualizado")
		end
		
		-- Notificar a HD-CONNECT
		if _G.HDConnect_HandleGiftedGamepass then
			pcall(_G.HDConnect_HandleGiftedGamepass, userId, gamepassId)
			print("🔗 HD-CONNECT notificado")
		end
		
		print("✅ Jugador actualizado en tiempo real")
	else
		print("ℹ️  Jugador no está conectado (se aplicará cuando se una)")
	end
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("✅ GAMEPASS REGALADO EXITOSAMENTE")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	
	return true
end

-- ═══════════════════════════════════════════════════════════
-- 🚀 EJECUTAR
-- ═══════════════════════════════════════════════════════════

task.wait(3) -- Esperar a que cargue el sistema

-- Ejecutar regalo
local exito = regalarGamepass(USER_ID, GAMEPASS_ID)

if exito then
	print("🎉 Proceso completado con éxito")
else
	warn("⚠️  El proceso no se completó correctamente")
end
