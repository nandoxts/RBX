--[[
	SISTEMA PRINCIPAL DE DONACIONES - OPTIMIZADO Y ACTUALIZADO 14-11-25
]]

--==================================================
--                 SERVICIOS Y MÓDULOS
--==================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage"):WaitForChild("Panda ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage"):WaitForChild("SelectedPlayer")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Configuration = require(game:GetService("ServerScriptService")["Panda ServerScriptService"].Configuration)
local ColorEffects = require(game:GetService("ServerScriptService")["Panda ServerScriptService"].Effects.ColorEffectsModule)

--==================================================
--                    CONSTANTES
--==================================================
local GROUP_ID = Configuration.GroupID
local ALLOWED_RANKS = Configuration.ALLOWED_RANKS_OWS
local HTTP_RETRY_LIMIT = 3
local HTTP_RETRY_DELAY = 1
local DATASTORE_RETRY_LIMIT = 3
local GIANT_EFFECT_CLEANUP_TIME = 40

--==================================================
--                    EVENTOS
--==================================================
local Events = ReplicatedStorage.Events
local update_donation = Events.update_donation
local donation_message = Events.donation_message

-- Eventos del UserPanel (nuevos)
local remotesGlobal = game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal")
local userPanelFolder = remotesGlobal:FindFirstChild("UserPanel")
local DonationNotify = userPanelFolder and userPanelFolder:FindFirstChild("DonationNotify")
local DonationMessage = userPanelFolder and userPanelFolder:FindFirstChild("DonationMessage")

--==================================================
--                ASSETS Y DATASTORES
--==================================================
local Assets = ServerStorage.Assets
local Auras = Assets.Auras
local RobuxHammerGiant = Assets:WaitForChild("RobuxHammerGiant")

local DonatorsDS = DataStoreService:GetOrderedDataStore("TopDona")
local ReceiversDS = DataStoreService:GetOrderedDataStore("TopRece")

--==================================================
--                    CACHE
--==================================================
local PlayerCache = {}
local ProductInfoCache = {}
local ActiveEffects = {}

--==================================================
--             CONFIGURACIÓN DE EFECTOS
--==================================================
local DONATION_EFFECTS = {
	{MaxAmount = 10,    Attachment = "bajo",     Duration = 2.3,  SoundId = "rbxassetid://82616454607059",   Volume = 0.3, GiantEffect = false},
	{MaxAmount = 100,   Attachment = "sayayin1",  Duration = 4,    SoundId = "rbxassetid://7727672197",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 200,   Attachment = "sayayin2",  Duration = 4.5,  SoundId = "rbxassetid://972919590",        Volume = 0.5, GiantEffect = false},
	{MaxAmount = 300,   Attachment = "sayayin3",  Duration = 4.5,  SoundId = "rbxassetid://2261507666",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 500,   Attachment = "bajo1",     Duration = 3,    SoundId = "rbxassetid://4612383790",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 600,   Attachment = "bajo2",     Duration = 3,    SoundId = "rbxassetid://84795270640054",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 700,   Attachment = "bajo3",     Duration = 3,    SoundId = "rbxassetid://119398240584172",  Volume = 0.5, GiantEffect = false},
	{MaxAmount = 800,   Attachment = "bajo4",     Duration = 5,    SoundId = "rbxassetid://137651128719857",  Volume = 0.5, GiantEffect = false},
	{MaxAmount = 1000,  Attachment = "bajo5",     Duration = 20,   SoundId = "rbxassetid://74948903354832",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 2000,  Attachment = "bajo6",     Duration = 21,   SoundId = "rbxassetid://74948903354832",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 3000,  Attachment = "bajo7",     Duration = 22,   SoundId = "rbxassetid://18866194712",      Volume = 0.5, GiantEffect = false},
	{MaxAmount = 5000,  Attachment = "bajo8",     Duration = 23,   SoundId = "rbxassetid://9043179746",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 7000,  Attachment = "bajo9",     Duration = 24,   SoundId = "rbxassetid://8982060550",       Volume = 0.8, GiantEffect = false},
	{MaxAmount = 10000, Attachment = "bajo10",    Duration = 25,   SoundId = "rbxassetid://8982060550",       Volume = 1,   GiantEffect = true},
	{MaxAmount = math.huge, Attachment = "bajo9", Duration = 30,   SoundId = "rbxassetid://8982060550",       Volume = 1.2, GiantEffect = true}
}

--==================================================
--             FUNCIONES AUXILIARES
--==================================================
local function formatNumber(n)
	local str = tostring(math.floor(n))
	return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function safeHttpGet(url, retries)
	retries = retries or HTTP_RETRY_LIMIT
	for attempt = 1, retries do
		local success, response = pcall(HttpService.GetAsync, HttpService, url)
		if success then
			return true, response
		end
		if attempt < retries then
			task.wait(HTTP_RETRY_DELAY * attempt)
		end
	end
	return false, nil
end

local function safeJSONDecode(jsonString)
	local success, result = pcall(HttpService.JSONDecode, HttpService, jsonString)
	return success and result or nil
end

--==================================================
--       EFECTOS VISUALES Y SONOROS
--==================================================
local function createSound(parent, soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	return sound
end

local function applyDonationEffect(targetPlayer, amount, donatingPlayer)
	if not targetPlayer or not targetPlayer.Character then return end

	local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Buscar efecto apropiado (el más alto que sea <= al monto)
	local selectedEffect = nil
	for i = #DONATION_EFFECTS, 1, -1 do
		if amount >= DONATION_EFFECTS[i].MaxAmount then
			selectedEffect = DONATION_EFFECTS[i]
			break
		end
	end

	if not selectedEffect then return end

	-- Aplicar efecto visual
	local aura = Auras:FindFirstChild(selectedEffect.Attachment)
	if aura then
		local clone = aura:Clone()
		clone.Parent = hrp

		-- Activar partículas
		for _, particle in ipairs(clone:GetChildren()) do
			if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
				particle.Enabled = true
			end
		end

		-- Programar desactivación
		task.delay(selectedEffect.Duration, function()
			for _, particle in ipairs(clone:GetChildren()) do
				if particle:IsA("ParticleEmitter") or particle:IsA("Beam") then
					particle.Enabled = false
				end
			end
			task.wait(1)
			if clone and clone.Parent then
				clone:Destroy()
			end
		end)
	end

	-- Aplicar sonido
	createSound(hrp, selectedEffect.SoundId, selectedEffect.Volume)

	-- Efecto gigante para donaciones grandes
	if selectedEffect.GiantEffect and amount >= 10000 then
		spawnGiantDonationEffect(donatingPlayer, targetPlayer, amount)
	end
end

function spawnGiantDonationEffect(donatingPlayer, donatedPlayer, amount)
	if not RobuxHammerGiant or not donatingPlayer or not donatedPlayer then return end

	local giantClone = RobuxHammerGiant:Clone()
	local mapFolder = Workspace:FindFirstChild("Map")
	if not mapFolder then
		giantClone:Destroy()
		return
	end

	local changingMap = mapFolder:FindFirstChild("ChangingMap")
	if not changingMap then
		giantClone:Destroy()
		return
	end

	giantClone.Parent = changingMap

	-- Optimizar colisiones
	for _, part in ipairs(giantClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	-- Configurar billboard
	local billboard = giantClone:FindFirstChild("BillboardGuiAnimation", true)
	if billboard and billboard:FindFirstChild("Frame") then
		local frame = billboard.Frame
		if frame:FindFirstChild("TopText") then
			frame.TopText.Text = "@"..donatingPlayer.Name.." donó"
		end
		if frame:FindFirstChild("MiddleText") then
			frame.MiddleText.Text = formatNumber(amount).." Robux"
		end
		if frame:FindFirstChild("BottomText") then
			frame.BottomText.Text = "Para @"..donatedPlayer.Name
		end
	end

	-- Aplicar skin del donador
	local humanoid = giantClone:FindFirstChildOfClass("Humanoid")
	if humanoid and donatingPlayer then
		task.spawn(function()
			local success, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, donatingPlayer.UserId)
			if success and desc and humanoid and humanoid.Parent then
				-- Guardar escalas originales
				local scales = {
					Height = humanoid:FindFirstChild("BodyHeightScale") and humanoid.BodyHeightScale.Value or 1,
					Width = humanoid:FindFirstChild("BodyWidthScale") and humanoid.BodyWidthScale.Value or 1,
					Depth = humanoid:FindFirstChild("BodyDepthScale") and humanoid.BodyDepthScale.Value or 1,
					Head = humanoid:FindFirstChild("HeadScale") and humanoid.HeadScale.Value or 1
				}

				pcall(humanoid.ApplyDescription, humanoid, desc)

				-- Restaurar escalas
				if humanoid:FindFirstChild("BodyHeightScale") then humanoid.BodyHeightScale.Value = scales.Height end
				if humanoid:FindFirstChild("BodyWidthScale") then humanoid.BodyWidthScale.Value = scales.Width end
				if humanoid:FindFirstChild("BodyDepthScale") then humanoid.BodyDepthScale.Value = scales.Depth end
				if humanoid:FindFirstChild("HeadScale") then humanoid.HeadScale.Value = scales.Head end
			end
		end)
	end

	-- Limpiar después del tiempo especificado
	task.delay(GIANT_EFFECT_CLEANUP_TIME, function()
		if giantClone and giantClone.Parent then
			giantClone:Destroy()
		end
	end)

	return giantClone
end

--==================================================
--              FETCH DE DATOS WEB
--==================================================
local function fetchPlayerClothing(player)
	local items = {}
	local cursor = ""
	local maxIterations = 10
	local iteration = 0

	repeat
		iteration = iteration + 1
		local url = string.format(
			"https://catalog.roproxy.com/v1/search/items/details?Category=3&CreatorName=%s&cursor=%s",
			player.Name, cursor
		)

		local success, response = safeHttpGet(url)
		if success then
			local data = safeJSONDecode(response)
			if data and data.data then
				for _, item in ipairs(data.data) do
					if item.itemType == "Asset" and item.price and item.price > 0 then
						table.insert(items, item.id)
					end
				end
				cursor = data.nextPageCursor or ""
			else
				break
			end
		else
			break
		end
	until cursor == "" or iteration >= maxIterations

	return items
end

local function fetchGamepasses(gameId)
	local items = {}
	local pageToken = ""
	local maxIterations = 10
	local iteration = 0

	--print("🔍 Fetching gamepasses for game:", gameId)

	repeat
		iteration = iteration + 1
		local url = string.format(
			"https://apis.roproxy.com/game-passes/v1/universes/%d/game-passes?pageSize=50%s",
			gameId, 
			pageToken ~= "" and ("&pageToken=" .. HttpService:UrlEncode(pageToken)) or ""
		)

		--print("📡 Request URL:", url)
		local success, response = safeHttpGet(url)

		if success then
			--print("✅ Response received")
			local data = safeJSONDecode(response)
			if data and data.gamePasses then
				--print("📦 Found", #data.gamePasses, "gamepasses")
				for _, gamepass in ipairs(data.gamePasses) do
					table.insert(items, gamepass.id)
				end
				pageToken = data.nextPageToken or ""
			else
				--print("❌ No gamePasses in response")
				break
			end
		else
			--print("❌ HTTP request failed")
			break
		end
	until pageToken == "" or iteration >= maxIterations

	--print("🎯 Total gamepasses found:", #items)
	return items
end

local function fetchPlayerGames(player)
	local items = {}
	local cursor = ""
	local maxIterations = 5
	local iteration = 0

	repeat
		iteration = iteration + 1
		local url = string.format(
			"https://games.roproxy.com/v2/users/%d/games?accessFilter=Public&limit=50&cursor=%s",
			player.UserId, cursor
		)

		local success, response = safeHttpGet(url)
		if success then
			local data = safeJSONDecode(response)
			if data and data.data then
				for _, game in ipairs(data.data) do
					local gamepasses = fetchGamepasses(game.id)
					for _, id in ipairs(gamepasses) do
						table.insert(items, id)
					end
				end
				cursor = data.nextPageCursor or ""
			else
				break
			end
		else
			break
		end
	until cursor == "" or iteration >= maxIterations

	return items
end

--==================================================
--          DATASTORE CON REINTENTOS
--==================================================
local function incrementDataStore(dataStore, key, amount)
	for attempt = 1, DATASTORE_RETRY_LIMIT do
		local success, err = pcall(function()
			dataStore:IncrementAsync(key, amount)
		end)

		if success then
			return true
		end

		if attempt < DATASTORE_RETRY_LIMIT then
			task.wait(0.5 * attempt)
		else
			warn(string.format("Error guardando en DataStore después de %d intentos: %s", DATASTORE_RETRY_LIMIT, tostring(err)))
		end
	end
	return false
end

--==================================================
--              REGISTRO DE DONACIONES
--==================================================
local function registerDonation(donatingPlayer, donatedPlayer, amount)
	if not donatingPlayer or not donatedPlayer or amount <= 0 then return end

	-- Actualizar cache
	if PlayerCache[donatingPlayer.UserId] then
		PlayerCache[donatingPlayer.UserId].Donated = PlayerCache[donatingPlayer.UserId].Donated + amount
	end

	if PlayerCache[donatedPlayer.UserId] then
		PlayerCache[donatedPlayer.UserId].Received = PlayerCache[donatedPlayer.UserId].Received + amount
	end

	-- Guardar en DataStore de forma asíncrona
	task.spawn(function()
		incrementDataStore(DonatorsDS, tostring(donatingPlayer.UserId), amount)
		incrementDataStore(ReceiversDS, tostring(donatedPlayer.UserId), amount)
	end)
end

--==================================================
--          MANEJO DE COMPRAS
--==================================================
local function getProductInfo(assetId, isGamepass)
	local cacheKey = tostring(assetId) .. (isGamepass and "_GP" or "_A")

	-- Verificar cache
	if ProductInfoCache[cacheKey] then
		return ProductInfoCache[cacheKey]
	end

	-- Obtener de MarketplaceService
	for attempt = 1, 3 do
		local success, response = pcall(function()
			return MarketplaceService:GetProductInfo(
				assetId,
				isGamepass and Enum.InfoType.GamePass or Enum.InfoType.Asset
			)
		end)

		if success and response then
			ProductInfoCache[cacheKey] = response
			return response
		end

		if attempt < 3 then
			task.wait(1)
		end
	end

	return nil
end

local function onPurchase(player, assetId, wasPurchased, isGamepass)
	if not wasPurchased or not player then return end

	local productInfo = getProductInfo(assetId, isGamepass)
	if not productInfo or not productInfo.PriceInRobux or productInfo.PriceInRobux <= 0 then
		return
	end

	local price = productInfo.PriceInRobux
	local creatorId = productInfo.Creator and productInfo.Creator.Id

	if not creatorId then return end

	-- Notificar clientes
	update_donation:Fire(player.UserId, price, creatorId)

	local donatedPlayer = Players:GetPlayerByUserId(creatorId)
	if donatedPlayer then
		-- Obtener nombre de forma segura
		local creatorName = donatedPlayer.Name

		-- Notificar sistema viejo
		donation_message:FireAllClients(player.Name, price, creatorName)

		-- Notificar UserPanel nuevo (si existe)
		if DonationNotify then
			DonationNotify:FireClient(donatedPlayer, player.UserId, price, creatorId)
		end
		if DonationMessage then
			DonationMessage:FireClient(player, player.Name, price, creatorName)
		end

		-- Registrar donación
		registerDonation(player, donatedPlayer, price)

		-- Aplicar efectos visuales
		applyDonationEffect(donatedPlayer, price, player)
	end
end

--==================================================
--          INICIALIZACIÓN DE JUGADOR
--==================================================
local function onPlayerAdded(player)
	-- Inicializar atributos
	player:SetAttribute("clothingOnSale", "{}")
	player:SetAttribute("gamepassesOnSale", "{}")

	-- Inicializar cache
	PlayerCache[player.UserId] = {
		Donated = 0,
		Received = 0
	}

	-- Fetch de ropa (async)
	task.spawn(function()
		local clothing = fetchPlayerClothing(player)
		if player and player.Parent then
			player:SetAttribute("clothingOnSale", HttpService:JSONEncode(clothing))
		end
	end)

	-- Fetch de gamepasses (async)
	task.spawn(function()
		local gamepasses = fetchPlayerGames(player)
		if player and player.Parent then
			player:SetAttribute("gamepassesOnSale", HttpService:JSONEncode(gamepasses))
		end
	end)

	-- Conectar comando de chat
	player.Chatted:Connect(function(message)
		handleCommand(player, message)
	end)
end

--==================================================
--          COMANDO FAKE DONATION
--==================================================
function handleCommand(player, message)
	if not message or message:sub(1, 1) ~= ";" then return end
	if not ColorEffects.hasPermission(player, GROUP_ID, ALLOWED_RANKS) then return end

	local args = message:split(" ")
	local command = args[1]:lower()

	if command == ";fd" and args[2] and args[3] then
		local targetName = args[2]
		local amount = tonumber(args[3])

		if not amount or amount <= 0 then
			warn("Fake donation: monto inválido")
			return
		end

		-- Buscar jugador
		local targetPlayer = nil
		local lowerTargetName = targetName:lower()

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name:lower():sub(1, #lowerTargetName) == lowerTargetName then
				targetPlayer = plr
				break
			end
		end

		if not targetPlayer then
			warn("Fake donation: jugador no encontrado - " .. targetName)
			return
		end

		-- Simular donación
		update_donation:Fire(player.UserId, amount, targetPlayer.UserId)
		donation_message:FireAllClients(player.Name, amount, targetPlayer.Name)

		-- Notificar UserPanel (si existe)
		if DonationNotify then
			DonationNotify:FireClient(targetPlayer, player.UserId, amount, targetPlayer.UserId)
		end
		if DonationMessage then
			DonationMessage:FireAllClients(player.Name, amount, targetPlayer.Name)
		end

		-- Aplicar efectos
		applyDonationEffect(targetPlayer, amount, player)
	end
end

--==================================================
--          LIMPIEZA Y CONEXIONES
--==================================================
Players.PlayerRemoving:Connect(function(player)
	PlayerCache[player.UserId] = nil
end)

MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, wasPurchased)
	onPurchase(player, assetId, wasPurchased, false)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	onPurchase(player, gamePassId, wasPurchased, true)
end)

Players.PlayerAdded:Connect(onPlayerAdded)

-- Procesar jugadores que ya están en el servidor
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end