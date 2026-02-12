--> Loaded services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage"):WaitForChild("Panda ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Panda ServerScriptService")
local RunService = game:GetService("RunService")

--> Modules
local Configuration = require(ServerScriptService.Configuration)
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)
local ColorEffects = require(ServerScriptService.Effects.ColorEffectsModule)

-- ClanData para obtener información del clan
local ClanData = nil
pcall(function()
	local serverStorage = game:GetService("ServerStorage")
	local systems = serverStorage:FindFirstChild("Systems")
	if systems then
		local clanSystem = systems:FindFirstChild("ClanSystem")
		if clanSystem then
			-- Buscar V2 primero, luego V1 como fallback
			local clanDataModule = clanSystem:FindFirstChild("ClanDataV2") 
				or clanSystem:FindFirstChild("ClanData")
			if clanDataModule then
				ClanData = require(clanDataModule)
			end
		end
	end
end)

--> Constants
local EFFECT_PARTS = {"Head", "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg"}
local BLACKLISTED_USERIDS = Configuration.OWS

--> Estado global
local activeEffects = {}
local giftItemsEquipped = {}
local originalAccessories = {}
local originalTools = {}
local commandCooldowns = {} -- Anti-spam

--> Configuración de comandos especiales
local SPECIAL_COMMANDS = {
	TOMBO = {
		gamepassKey = Configuration.TOMBO,
		clothing = {
			pantsID = 10820482467,
			shirtID = 16963556758
		},
		itemFolder = "TOMBO"
	},
	SERE = {
		gamepassKey = Configuration.SERE,
		clothing = {
			shirtID = 7650880991
		},
		accessories = {
			hatID = 125648027192051,
			backAccessoryID = 125602307013071
		},
		itemFolder = "SERE"
	},
	CHORO = {
		gamepassKey = Configuration.CHORO,
		itemFolder = "CHORO"
	},
	ARMYBOOMS = {
		gamepassKey = Configuration.ARMYBOOMS,
		itemFolder = "ARMYBOOMS"
	},
	LIGHTSTICK = {
		gamepassKey = Configuration.LIGHTSTICK,
		itemFolder = "LIGHTSTICK"
	}
}

-- Tracking de comandos activos por jugador
local activeSpecialCommands = {}

-----------------------------------------------------------------------------------
--> EFFECT SYSTEM
-----------------------------------------------------------------------------------

local PlayerEffects = {
	fire = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local fire = Instance.new("Fire")
				fire.Color = color
				fire.SecondaryColor = Color3.new(color.r * 0.5, color.g * 0.5, color.b * 0.5)
				fire.Size = 3
				fire.Parent = part
				table.insert(created, fire)
			end
		end
		return created
	end,

	smk = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local smoke = Instance.new("Smoke")
				smoke.Color = color
				smoke.Size = 0.0005
				smoke.Opacity = 0.005
				smoke.RiseVelocity = 1
				smoke.Parent = part
				table.insert(created, smoke)
			end
		end
		return created
	end,

	lght = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local light = Instance.new("PointLight")
				light.Color = color
				light.Brightness = 5
				light.Range = 10
				light.Shadows = true
				light.Parent = part
				table.insert(created, light)
			end
		end
		return created
	end,

	prtcl = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local emitter = Instance.new("ParticleEmitter")
				emitter.Color = ColorSequence.new(color)
				emitter.Size = NumberSequence.new(0.4, 0.8)
				emitter.LightEmission = 0.5
				emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				emitter.Lifetime = NumberRange.new(1, 2)
				emitter.Rate = 10
				emitter.Speed = NumberRange.new(1)
				emitter.Parent = part
				table.insert(created, emitter)
			end
		end
		return created
	end,

	trail = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local att0 = Instance.new("Attachment", part)
				local att1 = Instance.new("Attachment", part)
				att1.Position = Vector3.new(0, -1, 0)

				local trail = Instance.new("Trail")
				trail.Color = ColorSequence.new(color)
				trail.LightEmission = 0.7
				trail.Transparency = NumberSequence.new(0, 1)
				trail.WidthScale = NumberSequence.new(0.2, 1)
				trail.Lifetime = 0.6
				trail.Attachment0 = att0
				trail.Attachment1 = att1
				trail.Parent = part

				table.insert(created, {trail, att0, att1})
			end
		end
		return created
	end,

	destacar = function(character, color)
		local existingHighlight = character:FindFirstChild("Destacar")
		if existingHighlight then
			pcall(function() existingHighlight:Destroy() end)
			task.wait()
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "Destacar"
		highlight.OutlineColor = color
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0.1
		highlight.Parent = character
		return {highlight}
	end
}

local function clearPlayerEffect(player)
	if activeEffects[player] then
		for _, inst in ipairs(activeEffects[player]) do
			if inst and typeof(inst) == "Instance" and inst.Parent then
				pcall(function() inst:Destroy() end)
			end
		end
		activeEffects[player] = nil
	end

	local character = player.Character
	if character then
		local existingHighlight = character:FindFirstChild("Destacar")
		if existingHighlight and existingHighlight:IsA("Highlight") then
			pcall(function() existingHighlight:Destroy() end)
		end
	end
end

local function applyEffectToPlayer(targetPlayer, effectType, color, commandingPlayer)
	local character = targetPlayer.Character
	if not character then return end

	-- Si commandingPlayer es diferente a targetPlayer, verificar permisos
	if commandingPlayer and commandingPlayer ~= targetPlayer then
		-- Solo Owner/Admin pueden aplicar efectos a otros
		if not ColorEffects.hasPermission(commandingPlayer, Configuration.GroupID, Configuration.ALLOWED_RANKS_OWS) then
			return
		end
	end

	clearPlayerEffect(targetPlayer)

	local fn = PlayerEffects[effectType]
	if fn then
		activeEffects[targetPlayer] = fn(character, color)
	end
end

local function resolveColor(token)
	if not token or token == "" then
		return Color3.new(1, 0, 0) -- Rojo por defecto
	end

	local key = string.lower(token)
	if ColorEffects.colors[key] then
		return ColorEffects.colors[key]
	end

	local hex = key:gsub("#", "")
	if hex:match("^%x%x%x%x%x%x$") then
		local r = tonumber(hex:sub(1, 2), 16) / 255
		local g = tonumber(hex:sub(3, 4), 16) / 255
		local b = tonumber(hex:sub(5, 6), 16) / 255
		return Color3.new(r, g, b)
	end

	return Color3.new(1, 0, 0) -- Rojo por defecto si no encuentra el color
end

-----------------------------------------------------------------------------------
--> CHARACTER MODIFICATION
-----------------------------------------------------------------------------------

local function modifyCharacter(character, modification)
	if not character or not character.Parent or not character:IsDescendantOf(game) then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		local success, result = pcall(function()
			return character:WaitForChild("Humanoid", 2)
		end)
		if not success then return false end
		humanoid = result
	end

	if not humanoid or not humanoid.Parent or not humanoid:IsDescendantOf(game) then
		return false
	end

	local success, err = pcall(function()
		if modification.type == "description" then
			-- Verificar que todo siga siendo válido antes de aplicar
			if not character:IsDescendantOf(game) or not humanoid:IsDescendantOf(game) then
				return
			end
			
			local humanoidDescription = humanoid:GetAppliedDescription()
			if humanoidDescription then
				humanoidDescription[modification.part] = modification.value
				humanoid:ApplyDescription(humanoidDescription)
			end
		elseif modification.type == "scale" then
			if not character:IsDescendantOf(game) or not humanoid:IsDescendantOf(game) then
				return
			end
			
			humanoid:WaitForChild("BodyHeightScale").Value = modification.value
			humanoid:WaitForChild("BodyDepthScale").Value = modification.value
			humanoid:WaitForChild("BodyWidthScale").Value = modification.value
			humanoid:WaitForChild("HeadScale").Value = modification.value
		end
	end)

	if not success then
		warn("Error al modificar personaje:", err)
		return false
	end

	return true
end

local function equipAccessory(character, accessoryId)
	if not character then return end

	local success, asset = pcall(function()
		return InsertService:LoadAsset(accessoryId)
	end)

	if success and asset then
		local accessory = asset:FindFirstChildOfClass("Accessory")
		if accessory then
			accessory.Parent = character
			task.wait(0.05) -- Esperar a que se parente correctamente
		end
	end
end

local function applyClothing(character, clothingConfig)
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local success, err = pcall(function()
		local desc = humanoid:GetAppliedDescription()

		if clothingConfig.shirtID then
			desc.Shirt = clothingConfig.shirtID
		end

		if clothingConfig.pantsID then
			desc.Pants = clothingConfig.pantsID
		end

		humanoid:ApplyDescription(desc)
	end)

	if not success then
		warn("Error aplicando ropa:", err)
	end
end

local function removeSpecialCommandItems(player, commandName)
	local commandConfig = SPECIAL_COMMANDS[commandName]
	if not commandConfig then return end

	local character = player.Character
	local backpack = player.Backpack

	-- Remover items del folder específico
	if commandConfig.itemFolder then
		local itemsFolder = ServerStorage:FindFirstChild("Items")
		if itemsFolder then
			local typeFolder = itemsFolder:FindFirstChild(commandConfig.itemFolder)
			if typeFolder then
				-- Remover del backpack
				for _, tool in ipairs(backpack:GetChildren()) do
					if tool:IsA("Tool") and typeFolder:FindFirstChild(tool.Name) then
						tool:Destroy()
					end
				end

				-- Remover del personaje (si está equipado)
				if character then
					for _, tool in ipairs(character:GetChildren()) do
						if tool:IsA("Tool") and typeFolder:FindFirstChild(tool.Name) then
							tool:Destroy()
						end
					end
				end
			end
		end
	end

	-- Remover accesorios específicos (para SERE)
	if commandConfig.accessories and character then
		for _, accessoryId in pairs(commandConfig.accessories) do
			-- Buscar y remover accesorios por ID
			for _, accessory in ipairs(character:GetChildren()) do
				if accessory:IsA("Accessory") then
					-- Intentar obtener el ID del accessory
					local success, assetId = pcall(function()
						return accessory:GetAttribute("AssetId") or 
							(accessory.PrimaryPart and accessory.PrimaryPart:GetAttribute("AssetId"))
					end)
					if success and assetId == accessoryId then
						accessory:Destroy()
					end
				end
			end
		end
	end

	-- Reset ropa a la original solo si el comando tenía ropa
	if commandConfig.clothing and character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local success, originalDesc = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(player.UserId)
			end)

			if success and originalDesc then
				pcall(function()
					local currentDesc = humanoid:GetAppliedDescription()

					if commandConfig.clothing.shirtID then
						currentDesc.Shirt = originalDesc.Shirt
					end

					if commandConfig.clothing.pantsID then
						currentDesc.Pants = originalDesc.Pants
					end

					humanoid:ApplyDescription(currentDesc)
				end)
			end
		end
	end
end

local function clearAllSpecialCommands(player)
	-- Remover todos los comandos especiales activos
	for commandName, _ in pairs(SPECIAL_COMMANDS) do
		removeSpecialCommandItems(player, commandName)
	end
	activeSpecialCommands[player.UserId] = nil
end

-----------------------------------------------------------------------------------
--> ITEM MANAGEMENT
-----------------------------------------------------------------------------------

local function equipItems(player, itemType)
	local itemsFolder = ServerStorage:FindFirstChild("Items")
	if not itemsFolder then return end

	local typeFolder = itemsFolder:FindFirstChild(itemType)
	if not typeFolder then return end

	local backpack = player:WaitForChild("Backpack")
	for _, item in ipairs(typeFolder:GetChildren()) do
		if not backpack:FindFirstChild(item.Name) then
			local clonedItem = item:Clone()
			if clonedItem:IsA("Tool") then
				clonedItem.CanBeDropped = false
			end
			clonedItem.Parent = backpack
		end
	end
end

local function grantItemsBasedOnPasses(player)
	-- Otorgar automáticamente al inicio
	local gamepassesToCheck = {
		{key = "VIP", folder = "VIP", id = Configuration.VIP},
		{key = "ARMYBOOMS", folder = "ARMYBOOMS", id = Configuration.ARMYBOOMS},
		{key = "LIGHTSTICK", folder = "LIGHTSTICK", id = Configuration.LIGHTSTICK},
	}

	for _, gamepass in ipairs(gamepassesToCheck) do
		if gamepass.id then
			local hasPass = GamepassManager.HasGamepass(player, gamepass.id)
			if hasPass then
				equipItems(player, gamepass.folder)
			end
		end
	end
end

local function equipGiftItems(player)
	if giftItemsEquipped[player.UserId] then return end

	local giftItems = ServerStorage:FindFirstChild("Items")
	if giftItems then
		giftItems = giftItems:FindFirstChild("GiftItems")
	end

	if not giftItems then return end

	for _, item in ipairs(giftItems:GetChildren()) do
		local clonedItem = item:Clone()
		if clonedItem:IsA("Tool") then
			clonedItem.CanBeDropped = false
		end
		clonedItem.Parent = player.Backpack
	end

	giftItemsEquipped[player.UserId] = true
end

-----------------------------------------------------------------------------------
--> ORIGINAL ITEMS TRACKING
-----------------------------------------------------------------------------------

local function storeOriginalItems(player)
	local character = player.Character or player.CharacterAdded:Wait()

	originalAccessories[player.UserId] = {}
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			table.insert(originalAccessories[player.UserId], accessory.Name)
		end
	end

	local backpack = player:WaitForChild("Backpack")
	originalTools[player.UserId] = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(originalTools[player.UserId], tool.Name)
		end
	end
end

local function isVIPItem(item)
	local itemsFolder = ServerStorage:FindFirstChild("Items")
	if not itemsFolder then return false end

	local paidItemsFolders = {
		"VIP", "TOMBO", "CHORO", "SERE", "ARMYBOOMS", "LIGHTSTICK"
	}

	for _, folderName in ipairs(paidItemsFolders) do
		local folder = itemsFolder:FindFirstChild(folderName)
		if folder and folder:FindFirstChild(item.Name) then
			return true
		end
	end

	return false
end

local function resetCharacter(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild('Humanoid')

	-- Guardar overhead
	local overheadClone = nil
	if character:FindFirstChild("Head") then
		local overhead = character.Head:FindFirstChild("Overhead")
		if overhead then
			overheadClone = overhead:Clone()
		end
	end

	-- Remover accesorios no originales y no VIP
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") and not isVIPItem(accessory) and 
			not table.find(originalAccessories[player.UserId] or {}, accessory.Name) then
			accessory:Destroy()
		end
	end

	-- Remover tools duplicados
	local backpack = player:WaitForChild("Backpack")
	local toolsSeen = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local isProtected = isVIPItem(tool) or table.find(originalTools[player.UserId] or {}, tool.Name)
			if not isProtected and toolsSeen[tool.Name] then
				tool:Destroy()
			else
				toolsSeen[tool.Name] = true
			end
		end
	end

	-- Reset apariencia
	local success, humanoidDescription = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)

	if success and humanoidDescription then
		humanoid:ApplyDescription(humanoidDescription)
	end

	-- Restaurar overhead
	if overheadClone then
		task.delay(0.5, function()
			local head = character:FindFirstChild("Head")
			if head then
				local oldOverhead = head:FindFirstChild("Overhead")
				if oldOverhead then oldOverhead:Destroy() end
				pcall(function()
					overheadClone.Parent = head
				end)
			end
		end)
	end

	-- Reset gift items
	giftItemsEquipped[player.UserId] = false

	-- Remover partículas
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local commandParticles = humanoidRootPart:FindFirstChild("CommandParticles")
		if commandParticles and commandParticles:IsA("ParticleEmitter") then
			commandParticles:Destroy()
		end
	end

	-- Clear efectos
	clearPlayerEffect(player)

	-- Clear comandos especiales activos
	clearAllSpecialCommands(player)

	-- Guardar ítems originales de nuevo
	storeOriginalItems(player)
end

-----------------------------------------------------------------------------------
--> COMMAND HANDLERS
-----------------------------------------------------------------------------------

local function handleParticleCommand(player, character, textureId)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		return 
	end

	local isClan = string.lower(textureId) == "clan"
	local textureIdToUse = textureId

	-- Si es clan, obtener el logo del clan
	if isClan and ClanData then
		local playerClan = ClanData:GetPlayerClan(player.UserId)
		if playerClan and playerClan.logo then
			textureIdToUse = playerClan.logo:gsub("rbxassetid://", "")
		end
	end

	local existingParticleEmitter = humanoidRootPart:FindFirstChild("CommandParticles")
	local particleEmitter = existingParticleEmitter

	if not particleEmitter then
		local commandParticles = ServerStorage:FindFirstChild("Commands")
		if commandParticles then
			commandParticles = commandParticles:FindFirstChild("CommandParticles")
			if commandParticles then
				particleEmitter = commandParticles:Clone()
				particleEmitter.Name = "CommandParticles"
				particleEmitter.Parent = humanoidRootPart
			else
				return
			end
		else
			return
		end
	end

	-- Configurar propiedades para que reboten alrededor del cuerpo
	particleEmitter.Size = NumberSequence.new(0.25, 0.35)
	particleEmitter.Lifetime = NumberRange.new(2, 3)
	particleEmitter.Rate = 15
	particleEmitter.Speed = NumberRange.new(2, 4)
	particleEmitter.Drag = 1.5
	particleEmitter.VelocityInheritance = 0.1
	particleEmitter.Acceleration = Vector3.new(0, 0, 0)
	particleEmitter.SpreadAngle = Vector2.new(180, 180)
	particleEmitter.Transparency = NumberSequence.new(0.2, 0.5, 1)

	pcall(function()
		local fullTexture = "rbxassetid://" .. textureIdToUse
		particleEmitter.Texture = fullTexture
	end)

	particleEmitter.Enabled = true
end

local function handleCloneCommand(player, targetName)
	local success, targetUserId = pcall(function()
		return Players:GetUserIdFromNameAsync(targetName)
	end)

	if not success then return end

	-- Verificar blacklist
	for _, blockedUserId in ipairs(BLACKLISTED_USERIDS) do
		if targetUserId == blockedUserId then
			player:Kick("No puedes clonar a este usuario")
			return
		end
	end

	local targetPlayer = Players:FindFirstChild(targetName)
	local humanoidDescription

	if targetPlayer then
		local targetCharacter = targetPlayer.Character
		if targetCharacter then
			local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
			if targetHumanoid then
				humanoidDescription = targetHumanoid:GetAppliedDescription()
			end
		end
	else
		local success, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(targetUserId)
		end)
		if success then humanoidDescription = result end
	end

	if humanoidDescription then
		local playerCharacter = player.Character
		if playerCharacter then
			local playerHumanoid = playerCharacter:FindFirstChild("Humanoid")
			if playerHumanoid then
				playerHumanoid:ApplyDescription(humanoidDescription)
			end
		end
	end
end

local function handleAppearanceCommand(player, commandType)
	local character = player.Character
	if not character or not character.Parent then
		task.delay(1, function()
			handleAppearanceCommand(player, commandType)
		end)
		return
	end

	local modification = {}
	if commandType == "headless" then
		modification = {type = "description", part = "Head", value = 15093053680}
	elseif commandType == "korblox" then
		modification = {type = "description", part = "RightLeg", value = 139607718}
	end

	local maxAttempts = 3
	local attempt = 1

	local function attemptModification()
		if attempt > maxAttempts then return end

		local success = modifyCharacter(character, modification)
		if not success and attempt < maxAttempts then
			attempt = attempt + 1
			task.delay(0.5 * attempt, attemptModification)
		end
	end

	attemptModification()
end

-- NUEVO: Handler para comandos especiales (TOMBO, SERE, CHORO)
local function handleSpecialCommand(player, commandName)
	local commandConfig = SPECIAL_COMMANDS[commandName]
	if not commandConfig then return end

	-- Verificar gamepass
	if not GamepassManager.HasGamepass(player, commandConfig.gamepassKey) then
		return
	end

	local character = player.Character
	if not character then return end

	-- Si el jugador ya tiene un comando especial activo, removerlo primero
	local currentCommand = activeSpecialCommands[player.UserId]
	if currentCommand and currentCommand ~= commandName then
		removeSpecialCommandItems(player, currentCommand)
	end

	-- Aplicar ropa si existe
	if commandConfig.clothing then
		applyClothing(character, commandConfig.clothing)
	end

	-- Equipar accesorios si existen
	if commandConfig.accessories then
		for _, accessoryId in pairs(commandConfig.accessories) do
			equipAccessory(character, accessoryId)
		end
	end

	-- Equipar items del folder
	if commandConfig.itemFolder then
		equipItems(player, commandConfig.itemFolder)
	end

	-- Registrar el comando activo
	activeSpecialCommands[player.UserId] = commandName
end

-- Sistema anti-spam
local function checkCooldown(player, commandType)
	local userId = player.UserId
	if not commandCooldowns[userId] then
		commandCooldowns[userId] = {}
	end

	local lastUse = commandCooldowns[userId][commandType]
	local currentTime = tick()

	if lastUse and (currentTime - lastUse) < 2 then
		return false
	end

	commandCooldowns[userId][commandType] = currentTime
	return true
end

-----------------------------------------------------------------------------------
--> PLAYER SETUP
-----------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)
		storeOriginalItems(player)
		grantItemsBasedOnPasses(player)
	end)

	-- Prevenir tools duplicados
	player.Backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Parent == player.Backpack then
			task.wait(0.1)
			local duplicates = 0
			for _, tool in ipairs(player.Backpack:GetChildren()) do
				if tool.Name == child.Name then
					duplicates = duplicates + 1
					if duplicates > 1 then
						child:Destroy()
						break
					end
				end
			end
		end
	end)

	-- Command handling
	player.CharacterAdded:Connect(function(character)
		local pandaUsed = false

		player.Chatted:Connect(function(message)
			-- Extraer comandos
			local korblox = message:match(Configuration.CommandKorblox)
			local headless = message:match(Configuration.CommandHeadless)
			local hatCommand = message:match(Configuration.CommandHat)
			local particleCommand = message:match(Configuration.CommandParticle)
			local sizeCommand = message:match(Configuration.CommandSize)
			local pandaCommand = message:match(Configuration.CommandPanda)
			local cloneCommand = message:match(Configuration.CommandClone)
			local resetCommand = message:match(Configuration.CommandReset)
			local resetv2Command = message:match(Configuration.CommandReset2)
			local fireColorTok = message:match(Configuration.CommandFIRE)
			local smkColorTok = message:match(Configuration.CommandSMK)
			local lghtColorTok = message:match(Configuration.CommandLGHT)
			local prtclColorTok = message:match(Configuration.CommandPRTCL)
			local trailColorTok = message:match(Configuration.CommandTRAIL)
			local rmvMatch = message:match(Configuration.CommandRMV)
			local destacado = message:match(Configuration.CommandDestacado)

			-- NUEVOS COMANDOS
			local tombo = message:match(Configuration.CommandTOMBO)
			local choro = message:match(Configuration.CommandCHORO)
			local sere = message:match(Configuration.CommandSERE)
			local armybooms = message:match(Configuration.CommandARMYBOOMS)

			-- Verificar si tiene gamepass de comandos
			local hasCommands = GamepassManager.HasGamepass(player, Configuration.COMMANDS)

			-- Función helper para parsear y aplicar efectos con soporte a target
			local function applyEffectWithTarget(effectType, input, commandKey)
				if not input then return end

				local parts = {}
				for part in string.gmatch(input, "%S+") do
					table.insert(parts, part)
				end

				local colorToken = parts[1]
				local targetName = parts[2]
				local color = resolveColor(colorToken)

				if targetName then
					local targetPlayer = Players:FindFirstChild(targetName)
					if targetPlayer then
						applyEffectToPlayer(targetPlayer, effectType, color, player)
					end
				else
					applyEffectToPlayer(player, effectType, color, player)
				end
			end

			-- COMANDOS DE EFECTOS (requieren COMMANDS gamepass)
			if hasCommands then
				if fireColorTok then
					applyEffectWithTarget("fire", fireColorTok, "fire")
				elseif smkColorTok then
					applyEffectWithTarget("smk", smkColorTok, "smk")
				elseif lghtColorTok then
					applyEffectWithTarget("lght", lghtColorTok, "lght")
				elseif prtclColorTok then
					applyEffectWithTarget("prtcl", prtclColorTok, "prtcl")
				elseif trailColorTok then
					applyEffectWithTarget("trail", trailColorTok, "trail")
				elseif rmvMatch then
					clearPlayerEffect(player)
				elseif destacado then
					applyEffectWithTarget("destacar", destacado, "destacar")
				end
			end

			-- VIP COMMANDS
			local function checkVIP()
				if Configuration.VIP == nil then return true end
				return GamepassManager.HasGamepass(player, Configuration.VIP)
			end

			if korblox and checkVIP() then
				handleAppearanceCommand(player, "korblox")

			elseif headless and checkVIP() then
				handleAppearanceCommand(player, "headless")

				-- COMMANDS GAMEPASS
			elseif hatCommand and hasCommands then
				for id in string.gmatch(hatCommand, "%d+") do
					equipAccessory(character, tonumber(id))
				end

			elseif particleCommand and hasCommands then
				handleParticleCommand(player, character, particleCommand)

			elseif sizeCommand and hasCommands then
				local size = tonumber(sizeCommand)
				if size and size >= 0.5 and size <= 2 then
					modifyCharacter(character, {
						type = "scale",
						value = size
					})
				end

			elseif cloneCommand and hasCommands then
				handleCloneCommand(player, message:match(Configuration.CommandClone))

				-- COMANDOS ESPECIALES (TOMBO, CHORO, SERE)
			elseif tombo then
				handleSpecialCommand(player, "TOMBO")

			elseif choro then
				handleSpecialCommand(player, "CHORO")

			elseif sere then
				handleSpecialCommand(player, "SERE")

				-- PANDA (requiere estar en el grupo)
			elseif pandaCommand and player:IsInGroup(Configuration.GroupID) and not pandaUsed then
				equipAccessory(character, Configuration.AssetFree)
				equipGiftItems(player)
				pandaUsed = true

				-- RESET
			elseif resetCommand or resetv2Command then
				if Configuration.COMMANDS == nil or hasCommands then
					resetCharacter(player)
					clearPlayerEffect(player)
					pandaUsed = false
				end
			end
		end)
	end)

	-- Cleanup al salir
	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(game) then
			activeEffects[player] = nil
			giftItemsEquipped[player.UserId] = nil
			originalAccessories[player.UserId] = nil
			originalTools[player.UserId] = nil
			commandCooldowns[player.UserId] = nil
			activeSpecialCommands[player.UserId] = nil
		end
	end)
end)