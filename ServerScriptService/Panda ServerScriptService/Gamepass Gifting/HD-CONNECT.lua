local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local DataStoreQueueManager = require(game.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Inicializar queue con delay de 0.12s
local DataStoreQueue = DataStoreQueueManager.new(GiftedGamepassesData, "HDConnectQueue", 0.12)

-- Configuración HD Admin
local SetupHd = ReplicatedStorage:WaitForChild("HDAdminSetup", 10)
local hdMain = SetupHd and require(SetupHd):GetMain()
local hd = hdMain and hdMain:GetModule("API")

-- Mapeo de Gamepass IDs a Rangos HD Admin
local GAMEPASS_RANKS = {
	[Configuration.COMMANDS] = "COMMANDS",
	[Configuration.VIP] = "VIP"
}

local GROUP_RANKS = {
	[Configuration.GroupID] = {
		[255] = "Owner"; -- [ Propietario ]
		[254] = "Owner"; -- [ Co-Owner ]
		[253] = "Help Creator"; -- [ Help Creator ]
		[252] = "Lead Admin"; -- [ Lead Admin ]
		[251] = "Head Admin"; -- [ Head Admin ]
		[250] = "Administrador"; -- [ Administrador ]
		[249] = "Moderador"; -- [ Moderador ]
		[248] = "DJ"; -- [ DJ ]
		[247] = "Influencer"; -- [ Influencer ]
		[246] = "Socio" -- [ Socio ]
		--[253] = "Owner"; -- [ Lead Designer ]
		--[252] = "Owner"; -- [ Project Manager ]
		--[251] = "Owner"; -- [ Developer ]
		--[250] = "Staff"; -- [ Builder ]
		--[249] = "Owner"; -- [ Modeler ]
		--[248] = "Staff"; -- [ Animator ]
		--[247] = "Staff"; -- [ UI/UX Designer ]
		--[246] = "Staff"; -- [ Tester Lead ]
		--[245] = "Admin"; -- [ Admin ]
		--[244] = "Admin"; -- [ Moderator ]
		--[243] = "Admin"; -- [ Helper ]
		--[242] = "Admin"; -- [ Support Staff ]
		--[241] = "Admin"; -- [ Community Manager ]
		--[240] = "DJ House"; -- [ Event Manager ]
		--[239] = "DJ House"; -- [ DJ House ]
		--[238] = "DJ"; -- [ DJ ]
		--[237] = "Influencer"; -- [ Collaborator ]
		--[236] = "Influencer"; -- [ Sponsor ]
		--[235] = "Influencer"; -- [ Influencer ]
		--[234] = "Influencer"; -- [ Recruiter ]
	}
}

-- Función para obtener el rango más alto del grupo
local function GetHighestGroupRank(player)
	for groupId, ranks in pairs(GROUP_RANKS) do
		local success, rankInGroup = pcall(function()
			return player:GetRankInGroup(groupId)
		end)

		if success and rankInGroup and ranks[rankInGroup] then
			local rankName = ranks[rankInGroup]
			local rankId = hd:GetRankId(rankName)
			return rankName, rankId
		end
	end
	return nil, nil
end

-- Función para obtener el mejor rango de gamepass
local function GetBestGamepassRank(player)
	local bestRankName, bestRankId = nil, nil

	for gamepassId, rankName in pairs(GAMEPASS_RANKS) do
		local isGifted = false
		local isComplete = false
		
		-- Usar queue y ESPERAR la respuesta
		DataStoreQueue:GetAsync(player.UserId .. "-" .. gamepassId, function(success, result)
			isGifted = success and result or false
			isComplete = true
		end)
		
		-- Esperar a que se complete (máximo 500ms)
		local startTime = tick()
		while not isComplete and (tick() - startTime) < 0.5 do
			task.wait(0.01)
		end
		
		local ownsGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) or isGifted

		if ownsGamepass then
			local rankId = hd:GetRankId(rankName)
			if rankId and (not bestRankId or rankId > bestRankId) then
				bestRankName, bestRankId = rankName, rankId
			end
		end
	end

	return bestRankName, bestRankId
end

-- Función para crear/verificar la carpeta Gamepasses
local function EnsureGamepassesFolder(player)
	local folder = player:FindFirstChild("Gamepasses")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Gamepasses"
		folder.Parent = player
	end
	return folder
end

-- Función para verificar todos los gamepasses de un jugador
local function CheckAllGamepasses(player)
	local gamepassesFolder = EnsureGamepassesFolder(player)

	for gamepassId, _ in pairs(GAMEPASS_RANKS) do
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
		end)

		if success and productInfo then
			local isGifted = false
			local isComplete = false
			
			-- Usar queue y ESPERAR la respuesta
			DataStoreQueue:GetAsync(player.UserId .. "-" .. gamepassId, function(giftSuccess, giftResult)
				isGifted = giftSuccess and giftResult or false
				isComplete = true
			end)
			
			-- Esperar a que se complete (máximo 500ms)
			local startTime = tick()
			while not isComplete and (tick() - startTime) < 0.5 do
				task.wait(0.01)
			end
			
			local ownsGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) or isGifted

			-- Verificar si ya existe un BoolValue para este gamepass
			local gamepassValue = gamepassesFolder:FindFirstChild(productInfo.Name)
			if ownsGamepass then
				if not gamepassValue then
					-- Solo crear si no existe y el jugador tiene el gamepass
					gamepassValue = Instance.new("BoolValue")
					gamepassValue.Name = productInfo.Name
					gamepassValue.Value = true
					gamepassValue.Parent = gamepassesFolder
				else
					-- Actualizar el valor si ya existe
					gamepassValue.Value = true
				end
			elseif gamepassValue then
				-- Si el jugador ya no tiene el gamepass, actualizar el valor
				gamepassValue.Value = false
			end
		end
	end
end

-- Función para asignar el rango apropiado
local function AssignAppropriateRank(player)
	if not hd then return end

	-- 1. Obtener rango actual
	local currentRankId, currentRankName = hd:GetRank(player)
	
	-- Si es dueño del servidor privado, darle directamente "DJ House"
	if game.PrivateServerOwnerId ~= 0 and player.UserId == game.PrivateServerOwnerId then
		local djRankId = hd:GetRankId("DJ House")
		if djRankId and (not currentRankId or currentRankId ~= djRankId) then
			hd:SetRank(player, djRankId, "Auto-assigned as Private Server Owner")
		end
		return -- Importante: salir aquí para que no lo reemplacen otros checks
	end

	-- 2. Obtener mejor rango de grupo
	local groupRankName, groupRankId = GetHighestGroupRank(player)

	-- 3. Obtener mejor rango de gamepass
	local gamepassRankName, gamepassRankId = GetBestGamepassRank(player)

	-- Determinar el rango final a asignar
	local finalRankId, finalRankName = nil, nil

	-- Prioridad 1: Rangos de grupo
	if groupRankId then
		finalRankId, finalRankName = groupRankId, groupRankName
		-- Prioridad 2: Rangos de gamepass
	elseif gamepassRankId then
		finalRankId, finalRankName = gamepassRankId, gamepassRankName
	end

	-- Solo asignar si es diferente al actual y no es nil
	if finalRankId and (not currentRankId or currentRankId ~= finalRankId) then
		local source = groupRankId and "group rank" or "gamepass"
		hd:SetRank(player, finalRankId, "Auto-assigned from "..source)
	end
end

-- Manejar cuando un jugador se une
local function OnPlayerAdded(player)
	-- Crear la carpeta de gamepasses
	EnsureGamepassesFolder(player)

	-- Verificar gamepasses y asignar rango después de un pequeño delay
	delay(1, function()
		if not player or not player.Parent then return end

		CheckAllGamepasses(player)
		AssignAppropriateRank(player)
	end)
end

-- Manejar cuando aparece el personaje
local function OnCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		CheckAllGamepasses(player)
		AssignAppropriateRank(player)
	end
end

-- Conectar eventos
Players.PlayerAdded:Connect(function(player)
	pcall(OnPlayerAdded, player)
	player.CharacterAdded:Connect(OnCharacterAdded)
end)

-- Procesar jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		pcall(OnPlayerAdded, player)
	end)
end

-- Función para verificar un gamepass específico
local function DoesUserOwnGamePass(player, gamepassId)
	if not player or not player:IsDescendantOf(game) then return false end

	-- Verificar carpeta Gamepasses primero
	local gamepassesFolder = player:FindFirstChild("Gamepasses")
	if gamepassesFolder then
		for _, value in ipairs(gamepassesFolder:GetChildren()) do
			if value:IsA("BoolValue") and value.Value then
				local success, info = pcall(function()
					return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
				end)
				if success and value.Name == info.Name then
					return true
				end
			end
		end
	end

	-- Verificar compra directa
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	if success and owns then return true end

	-- Verificar en DataStore con queue
	local gifted = false
	local isComplete = false
	DataStoreQueue:GetAsync(player.UserId .. "-" .. gamepassId, function(s, r)
		gifted = s and r or false
		isComplete = true
	end)
	
	-- Esperar a que se complete (máximo 500ms)
	local startTime = tick()
	while not isComplete and (tick() - startTime) < 0.5 do
		task.wait(0.01)
	end

	return gifted
end

-- Exportar funciones para uso en otros scripts
return {
	EnsureGamepassesFolder = EnsureGamepassesFolder,
	CheckAllGamepasses = CheckAllGamepasses,
	DoesUserOwnGamePass = DoesUserOwnGamePass,
	AssignAppropriateRank = AssignAppropriateRank,
	GetHighestGroupRank = GetHighestGroupRank,
	GetBestGamepassRank = GetBestGamepassRank
}

