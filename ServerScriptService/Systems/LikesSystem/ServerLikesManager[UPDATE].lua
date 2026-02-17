-- ServerScript: Panda ServerScriptService/LikesSystem/ServerLikesManager
-- 🚀 VERSIÓN ULTRA-OPTIMIZADA CON PROTECCIÓN DATASTORE
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Systems")

-- Módulos
local CentralPurchaseHandler = require(ServerScriptService["Gamepass Gifting"].GiftGamepass.ManagerProcess)
local Configuration = require(ServerScriptService.Configuration)
local DataStoreQueueManager = require(game.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))

-- Datastore
local LikesDataStore = DataStoreService:GetDataStore("LikesData")
local LeaderboardDataStore = DataStoreService:GetOrderedDataStore('TopLikes')
-- Halloween UGC EVENT
--[[
local LikesDataStore = DataStoreService:GetDataStore("LikesDataHalloween")
local LeaderboardDataStore = DataStoreService:GetOrderedDataStore('TopLikesHalloween')
]]

-- 🎯 QUEUE MANAGERS
local likesQueue = DataStoreQueueManager.new(LikesDataStore, "LikesQueue")
local leaderboardQueue = DataStoreQueueManager.new(LeaderboardDataStore, "LeaderboardQueue")

-- Eventos
local LikesEvents = ReplicatedStorage:WaitForChild("LikesEvents")
local GiveLikeEvent = LikesEvents:WaitForChild("GiveLikeEvent")
local GiveSuperLikeEvent = LikesEvents:WaitForChild("GiveSuperLikeEvent")
local BroadcastEvent = LikesEvents:WaitForChild("BroadcastEvent")

-- Configuración
local SUPER_LIKE_PRODUCT_ID = Configuration.SUPER_LIKE
local LIKE_COOLDOWN = Configuration.LIKE_COOLDOWN 
local SUPER_LIKE_VALUE = Configuration.SUPER_LIKE_VALUE 
local AUTOSAVE_INTERVAL = Configuration.AUTOSAVE_INTERVAL
local GROUP_ID = Configuration.GroupID
local ALLOWED_RANKS_OWS = Configuration.ALLOWED_RANKS_OWS

-- 🛡️ LÍMITES DE DATASTORE (Roblox permite ~60 peticiones/minuto por servidor)
local MAX_SAVES_PER_BATCH = 10 -- Guardar máximo 10 jugadores por ciclo
local SAVE_COOLDOWN = 60 -- Mínimo 60 segundos entre guardados del mismo jugador
local SHUTDOWN_SAVE_DELAY = 0.1 -- Delay entre guardados en cierre

-- Almacenamiento
local PlayerData = {}
local LikeCooldowns = {}
local SuperLikeTargets = {}
local DirtyData = {}
local LeaderboardQueue = {}
local PlayerActionCounts = {}
local LastSaveTime = {} -- 🆕 Track último guardado por jugador

local MAX_ACTIONS_PER_MINUTE = 30  -- Aumentado para permitir más likes
local IS_SHUTTING_DOWN = false -- 🆕 Flag para cierre

-- ============================================
-- 🔧 FUNCIONES DE UTILIDAD
-- ============================================

local function updatePlayerAttributes(player, data)
	player:SetAttribute("TotalLikes", data.TotalLikes)
end

local function checkRateLimit(player)
	local userId = player.UserId
	local currentTime = tick()

	if not PlayerActionCounts[userId] then
		PlayerActionCounts[userId] = { count = 1, resetTime = currentTime + 60 }
		return true
	end

	local limiter = PlayerActionCounts[userId]

	if currentTime >= limiter.resetTime then
		limiter.count = 1
		limiter.resetTime = currentTime + 60
		return true
	end

	if limiter.count >= MAX_ACTIONS_PER_MINUTE then
		return false
	end

	limiter.count = limiter.count + 1
	return true
end

-- ============================================
-- 💾 SISTEMA DE DATOS MEJORADO
-- ============================================

local function loadPlayerData(player)
	local userId = player.UserId

	if PlayerData[userId] then
		return PlayerData[userId]
	end

	local success, data = pcall(function()
		return LikesDataStore:GetAsync("Player_" .. userId)
	end)

	if success and data then
		PlayerData[userId] = {
			TotalLikes = data.TotalLikes,
			LastSave = tick()
		}
	else
		PlayerData[userId] = {
			TotalLikes = 0,
			LastSave = tick()
		}
	end

	LikeCooldowns[userId] = {}
	LastSaveTime[userId] = tick()

	updatePlayerAttributes(player, PlayerData[userId])
	return PlayerData[userId]
end

local function markDirty(userId)
	DirtyData[userId] = true
end

local function queueLeaderboardUpdate(player, likes)
	if likes > 0 then
		LeaderboardQueue[player.UserId] = { player = player, likes = likes }
	end
end

-- 🆕 Verificar si un jugador puede ser guardado
local function canSavePlayer(userId)
	if not LastSaveTime[userId] then
		return true
	end

	local elapsed = tick() - LastSaveTime[userId]
	return elapsed >= SAVE_COOLDOWN or IS_SHUTTING_DOWN
end

-- ⚡ GUARDADO BATCH MEJORADO
local function saveBatch()
	local saveCount = 0
	local skippedCount = 0
	local savedUsers = {}

	-- Guardar solo jugadores que necesitan guardado
	for userId, _ in pairs(DirtyData) do
		if saveCount >= MAX_SAVES_PER_BATCH then
			break -- Limitar cantidad por ciclo
		end

		local player = Players:GetPlayerByUserId(userId)
		if player and PlayerData[userId] and canSavePlayer(userId) then
			task.spawn(function()
				likesQueue:SetAsync("Player_" .. userId, {
					TotalLikes = PlayerData[userId].TotalLikes
				})
				PlayerData[userId].LastSave = tick()
				LastSaveTime[userId] = tick()
				DirtyData[userId] = nil
				saveCount = saveCount + 1
			end)
		else
			skippedCount = skippedCount + 1
		end
	end

	-- Actualizar leaderboard en lote (menos prioritario)
	task.spawn(function()
		local leaderboardCount = 0
		for userId, data in pairs(LeaderboardQueue) do
			if leaderboardCount >= 5 then break end

			leaderboardQueue:SetAsync(tostring(userId), data.likes)
			LeaderboardQueue[userId] = nil
			leaderboardCount = leaderboardCount + 1

			task.wait(0.1)
		end
	end)

	if saveCount > 0 or skippedCount > 0 then
		--print(string.format("💾 Guardados: %d | ⏭️ Omitidos: %d", saveCount, skippedCount))
	end
end

-- 🆕 Guardar un jugador específico (para PlayerRemoving)
local function savePlayerData(userId, forceWait)
	if not PlayerData[userId] then return false end

	likesQueue:SetAsync("Player_" .. userId, {
		TotalLikes = PlayerData[userId].TotalLikes
	})
	LastSaveTime[userId] = tick()
	DirtyData[userId] = nil
	return true
end

-- ============================================
-- ❤️ SISTEMA DE LIKES
-- ============================================

local function checkLikeCooldown(userId, targetId)
	if not LikeCooldowns[userId] or not LikeCooldowns[userId][targetId] then
		return true, 0
	end

	local lastTime = LikeCooldowns[userId][targetId]
	local elapsed = tick() - lastTime

	return elapsed >= LIKE_COOLDOWN, lastTime
end

local function setLikeCooldown(userId, targetId)
	if not LikeCooldowns[userId] then
		LikeCooldowns[userId] = {}
	end
	LikeCooldowns[userId][targetId] = tick()
end

local function giveLike(player, targetPlayer)
	local userId = player.UserId
	local targetId = targetPlayer.UserId

	if not checkRateLimit(player) then
		return false, "Demasiadas acciones, espera un momento"
	end

	local canLike, lastTime = checkLikeCooldown(userId, targetId)
	if not canLike then
		local remaining = LIKE_COOLDOWN - (tick() - lastTime)
		return false, string.format("Espera %.0f minutos", math.ceil(remaining / 60))
	end

	local targetData = loadPlayerData(targetPlayer)
	targetData.TotalLikes = targetData.TotalLikes + 1

	updatePlayerAttributes(targetPlayer, targetData)
	setLikeCooldown(userId, targetId)
	markDirty(targetId)
	queueLeaderboardUpdate(targetPlayer, targetData.TotalLikes)

	return true, "Like dado"
end

local function giveSuperLike(player, targetPlayer)
	if not checkRateLimit(player) then
		return false, "Demasiadas acciones"
	end

	local targetData = loadPlayerData(targetPlayer)
	targetData.TotalLikes = targetData.TotalLikes + SUPER_LIKE_VALUE

	updatePlayerAttributes(targetPlayer, targetData)
	markDirty(targetPlayer.UserId)
	queueLeaderboardUpdate(targetPlayer, targetData.TotalLikes)

	return true, "Super like dado"
end

local function broadcastLike(senderName, targetName, isSuperLike, amount)
	BroadcastEvent:FireAllClients("LikeNotification", {
		Sender = senderName,
		Target = targetName,
		IsSuperLike = isSuperLike,
		Amount = amount or 1
	})
end

-- ============================================
-- 📡 EVENTOS DEL CLIENTE
-- ============================================

GiveLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
	if action == "GiveLike" then
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer or targetPlayer == player then
			task.spawn(function()
				GiveLikeEvent:FireClient(player, "Error", "No puedes darte like a ti mismo")
			end)
			return
		end

		local success, message = giveLike(player, targetPlayer)
		if success then
			broadcastLike(player.Name, targetPlayer.Name, false, 1)
			task.spawn(function()
				GiveLikeEvent:FireClient(player, "LikeSuccess")
			end)
		else
			task.spawn(function()
				GiveLikeEvent:FireClient(player, "Error", message)
			end)
		end

	elseif action == "RequestData" then
		local data = loadPlayerData(player)
		task.spawn(function()
			GiveLikeEvent:FireClient(player, "ReceiveData", {
				TotalLikes = data.TotalLikes
			})
		end)
	end
end)

GiveSuperLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
	if action == "GiveSuperLike" then
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer or targetPlayer == player then
			GiveSuperLikeEvent:FireClient(player, "Error", "No válido")
			return
		end

		local success, message = giveSuperLike(player, targetPlayer)
		if success then
			broadcastLike(player.Name, targetPlayer.Name, true, SUPER_LIKE_VALUE)
			GiveSuperLikeEvent:FireClient(player, "SuperLikeSuccess")
		else
			GiveSuperLikeEvent:FireClient(player, "Error", message)
		end

	elseif action == "SetSuperLikeTarget" then
		SuperLikeTargets[player.UserId] = targetUserId
		player:SetAttribute("SuperLikeTarget", targetUserId)
	end
end)

-- ============================================
-- 💳 COMPRAS (Super Like)
-- ============================================

local function handleSuperLikePurchase(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId ~= SUPER_LIKE_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local targetUserId = SuperLikeTargets[player.UserId] or player:GetAttribute("SuperLikeTarget")

	if not targetUserId then
		SuperLikeTargets[player.UserId] = nil
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		SuperLikeTargets[player.UserId] = nil
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local targetData = loadPlayerData(targetPlayer)
	targetData.TotalLikes = targetData.TotalLikes + SUPER_LIKE_VALUE

	updatePlayerAttributes(targetPlayer, targetData)
	markDirty(targetPlayer.UserId)
	queueLeaderboardUpdate(targetPlayer, targetData.TotalLikes)

	broadcastLike(player.Name, targetPlayer.Name, true, SUPER_LIKE_VALUE)
	GiveSuperLikeEvent:FireClient(player, "SuperLikeSuccess")

	SuperLikeTargets[player.UserId] = nil
	player:SetAttribute("SuperLikeTarget", nil)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ============================================
-- 🔐 COMANDOS DE ADMIN
-- ============================================

local function hasPermission(player)
	if not player then return false end

	local success, rank = pcall(function()
		return player:GetRankInGroup(GROUP_ID)
	end)

	if not success then return false end

	for _, allowedRank in ipairs(ALLOWED_RANKS_OWS) do
		if rank >= allowedRank then
			return true
		end
	end

	return false
end

local function handleAdminCommand(player, message)
	if not hasPermission(player) then return end

	local cmd, targetName, amountStr = message:match("^(%;like%w+)%s+([^%s]+)%s+(%d+)$")
	if not cmd then return end

	local amount = tonumber(amountStr)
	if not amount or amount <= 0 then return end

	local targetPlayer = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(targetName:lower(), 1, true) or 
			p.DisplayName:lower():find(targetName:lower(), 1, true) then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then return end

	local targetData = loadPlayerData(targetPlayer)

	if cmd == ";likeadd" then
		targetData.TotalLikes = targetData.TotalLikes + amount
	elseif cmd == ";likedel" then
		targetData.TotalLikes = math.max(0, targetData.TotalLikes - amount)
	end

	updatePlayerAttributes(targetPlayer, targetData)
	markDirty(targetPlayer.UserId)
	queueLeaderboardUpdate(targetPlayer, targetData.TotalLikes)
end

-- ============================================
-- 🎮 EVENTOS DE JUGADORES
-- ============================================

Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)

	player.Chatted:Connect(function(message)
		handleAdminCommand(player, message)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		handleAdminCommand(player, message)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	if PlayerData[userId] and DirtyData[userId] then
		-- Intentar guardar solo si tiene cambios pendientes
		savePlayerData(userId, false)
	end

	-- Limpiar memoria
	PlayerData[userId] = nil
	DirtyData[userId] = nil
	LikeCooldowns[userId] = nil
	SuperLikeTargets[userId] = nil
	PlayerActionCounts[userId] = nil
	LeaderboardQueue[userId] = nil
	LastSaveTime[userId] = nil
end)

-- ============================================
-- ⏰ SISTEMA DE AUTOGUARDADO
-- ============================================

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		if not IS_SHUTTING_DOWN then
			saveBatch()
		end
	end
end)

-- ============================================
-- 🛑 CIERRE DEL SERVIDOR OPTIMIZADO
-- ============================================

game:BindToClose(function()
	IS_SHUTTING_DOWN = true
	--print("🛑 Iniciando guardado de emergencia...")

	local playersToSave = {}
	for userId, _ in pairs(DirtyData) do
		if PlayerData[userId] then
			table.insert(playersToSave, userId)
		end
	end

	--print(string.format("💾 Guardando %d jugadores con cambios...", #playersToSave))

	-- Guardar en lotes pequeños con delay
	for i, userId in ipairs(playersToSave) do
		task.spawn(function()
			savePlayerData(userId, true)
		end)

		-- Delay entre guardados para no saturar
		if i % 5 == 0 then
			task.wait(SHUTDOWN_SAVE_DELAY)
		end
	end

	-- Dar tiempo para que terminen los guardados
	local maxWait = math.min(#playersToSave * 0.05, 10) -- Max 10 segundos
	task.wait(maxWait)

	--print("✅ Guardado de emergencia completado")
end)

-- ============================================
-- 🚀 INICIALIZACIÓN
-- ============================================

pcall(function()
	CentralPurchaseHandler.registerSuperLikeHandler(handleSuperLikePurchase)
end)
