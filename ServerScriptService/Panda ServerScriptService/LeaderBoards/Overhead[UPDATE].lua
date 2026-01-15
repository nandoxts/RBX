--// Servicios y Template
local OverheadTemplate = script:WaitForChild("Template")
local GamePassService = game:GetService("GamePassService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LocalizationService = game:GetService("LocalizationService")
local DataStoreService = game:GetService("DataStoreService")

-- DataStores
local streakStore = DataStoreService:GetDataStore("LoginStreaks")
local TopRachaStore = DataStoreService:GetOrderedDataStore("TopRacha")

--  GESTIÓN DE CONEXIONES POR JUGADOR
local playerConnections = {}

local function trackConnection(player, connection)
	if not playerConnections[player.UserId] then
		playerConnections[player.UserId] = {}
	end
	table.insert(playerConnections[player.UserId], connection)
	return connection
end

local function disconnectAllPlayerConnections(userId)
	if not playerConnections[userId] then return end
	for _, conn in ipairs(playerConnections[userId]) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end
	playerConnections[userId] = nil
end

--// Módulos
local PandaSSS = ServerScriptService:WaitForChild("Panda ServerScriptService")
local Configuration = require(PandaSSS:WaitForChild("Configuration"))
local GamepassManager = require(PandaSSS:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))
local Colors = require(PandaSSS.Effects.ColorEffectsModule)
local ModulesFolder = PandaSSS:WaitForChild("Modules")
local GroupRolesModule = require(ModulesFolder:WaitForChild("GroupRolesModule"))
local LevelConfigModule = require(ModulesFolder:WaitForChild("LevelConfigModule"))

--// Constantes
local GroupID = Configuration.GroupID
local ALLOWED_RANKS = Configuration.ALLOWED_DJ_RANKS
local OWS_GAME_IDS = Configuration.OWS
local VIP_ID = Configuration.VIP
local VIP_PLUS_ID = Configuration.VIPPLUS
local GROUP_ROLES = GroupRolesModule.GROUP_ROLES

--// Utilidad para banderas de país
local FlagUtils = {}
do
	local flagOffset = 0x1F1E6
	local asciiOffset = 0x41

	function FlagUtils.GetFlag(country)
		local first = utf8.codepoint(country, 1) - asciiOffset + flagOffset
		local second = utf8.codepoint(country, 2) - asciiOffset + flagOffset
		return utf8.char(first, second)
	end
end

--// Cache de componentes del overhead para acceso rápido
local function getOverheadComponents(char)
	local head = char:FindFirstChild("Head")
	if not head then return nil end

	local overhead = head:FindFirstChild("Overhead")
	if not overhead then return nil end

	local frame = overhead:FindFirstChild("Frame")
	if not frame then return nil end

	return {
		overhead = overhead,
		frame = frame,
		roleFrame = frame:FindFirstChild("RoleFrame"),
		nameFrame = frame:FindFirstChild("NameFrame"),
		otherFrame = frame:FindFirstChild("OtherFrame"),
		levelFrame = frame:FindFirstChild("LevelFrame")
	}
end

--// Funciones para el sistema de racha
local function getCurrentDay()
	-- Usar UTC explícitamente para evitar problemas de zona horaria
	local now = os.date("!*t")  -- El ! fuerza UTC
	now.hour = 0
	now.min = 0
	now.sec = 0

	local dayNumber = math.floor(os.time(now) / 86400)
	return dayNumber
end

local streakCache = {}
local function updateStreak(player)
	if not player or not player.UserId then return 1 end
	local userId = tostring(player.UserId)
	local today = getCurrentDay()

	-- Usar caché si existe y es del día
	local cached = streakCache[userId]
	if cached and cached.lastDay == today then
		return cached.streak
	end

	local success, data = pcall(function()
		return streakStore:GetAsync(userId)
	end)

	local streak = 1
	local lastDay = -1

	if success and data then
		streak = data.streak or 1
		lastDay = data.lastLoginDay or data.lastDay or -1

		local dayDiff = today - lastDay
		if lastDay == today then
			streak = streak
		elseif lastDay == today - 1 then
			streak = streak + 1
		else
			streak = 1
		end
	end

	-- Solo guardar si cambió la racha
	local function safeSetAsync(store, key, value)
		local maxRetries = 3
		local retryDelay = 5
		for attempt = 1, maxRetries do
			local ok, err = pcall(function()
				store:SetAsync(key, value)
			end)
			if ok then return true end
			warn(string.format("[RACHA] SetAsync error (intento %d): %s", attempt, tostring(err)))
			task.wait(retryDelay * attempt)
		end
		return false
	end

	if not cached or cached.streak ~= streak or cached.lastDay ~= today then
		safeSetAsync(streakStore, userId, {
			streak = streak,
			lastLoginDay = today,
			lastDay = today
		})
		safeSetAsync(TopRachaStore, userId, streak)
		streakCache[userId] = {streak = streak, lastDay = today}
	end

	return streak
end

local function getSavedStreak(player)
	if not player or not player.UserId then return 1 end
	local userId = tostring(player.UserId)
	local cached = streakCache[userId]
	if cached then return cached.streak end
	local success, data = pcall(function()
		return streakStore:GetAsync(userId)
	end)
	if success and data and data.streak then
		streakCache[userId] = {streak = data.streak, lastDay = data.lastLoginDay or data.lastDay or 0}
		return data.streak
	end
	return 1
end

local function EsAdminGrupo(player)
	return Colors.hasPermission(player, GroupID, ALLOWED_RANKS)
end

local function updateStreakDisplay(player, streakValue)
	if not player or not player.Character then return end

	local components = getOverheadComponents(player.Character)
	if not components or not components.nameFrame then return end

	local displayName = components.nameFrame:FindFirstChild("DisplayName")
	if displayName then
		displayName.Text = player.DisplayName .. " 🔥" .. tostring(streakValue)
	end
end

local function setStreakManual(player, amount)
	local userId = tostring(player.UserId)

	local data = {
		streak = amount,
		lastLoginDay = getCurrentDay()
	}

	pcall(function()
		streakStore:SetAsync(userId, data)
	end)

	pcall(function()
		TopRachaStore:SetAsync(userId, amount)
	end)

	-- Actualizar display inmediatamente
	updateStreakDisplay(player, amount)
end

Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		msg = msg:lower()

		if msg:sub(1,3) == ":rc" then
			if not EsAdminGrupo(plr) then return end

			local args = msg:split(" ")
			local targetName = args[2]
			local amount = tonumber(args[3])

			if not targetName or not amount then return end

			local target = Players:FindFirstChild(targetName)
			if target then
				setStreakManual(target, amount)
			end
		end
	end)
end)

--------------------------------------------------------------------------------------------------------
-- Actualizar display de nivel
local function updateLevelDisplay(levelLabel, level)
	if not levelLabel then return end

	local config = LevelConfigModule.getLevelConfig(level)
	levelLabel.Text = "Lv. " .. level .. " " .. config.Emoji
	levelLabel.TextColor3 = config.Color
end

--------------------------------------------------------------------------------------------------------
-- Actualizar color del nombre
local function updatePlayerNameColor(player)
	local char = player.Character
	if not char then return end

	local components = getOverheadComponents(char)
	if not components or not components.nameFrame then return end

	local colorName = player:GetAttribute("SelectedColor") or "default"
	local color = Colors.colors[colorName] or Colors.defaultSelectedColor

	local displayName = components.nameFrame:FindFirstChild("DisplayName")

	if displayName and typeof(color) == "Color3" then
		displayName.TextColor3 = color
	else
		if displayName then
			displayName.TextColor3 = Color3.fromRGB(255,255,255)
		end
	end
end

--------------------------------------------------------------------------------------------------------
-- Gestión de AFK
local function setAFK(player, state)
	local char = player.Character
	if not char then return end

	local components = getOverheadComponents(char)
	if not components or not components.otherFrame then return end

	local afkImage = components.otherFrame:FindFirstChild("AFK")
	if afkImage then afkImage.Visible = state end

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			if state then
				if not part:GetAttribute("OriginalMaterial") then
					part:SetAttribute("OriginalMaterial", part.Material.Name)
				end
				part.Material = Enum.Material.ForceField
			else
				local original = part:GetAttribute("OriginalMaterial")
				if original then
					part.Material = Enum.Material[original]
					part:SetAttribute("OriginalMaterial", nil)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
-- Gestión de overheads
local OverheadManager = {}

function OverheadManager:setupOverhead(char, player)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local existingOverhead = char:FindFirstChild("Overhead")
	if existingOverhead then existingOverhead:Destroy() end

	local overheadClone = OverheadTemplate:Clone()
	overheadClone.Name = "Overhead"
	overheadClone.Parent = char:WaitForChild("Head")

	self:configureOverhead(overheadClone, player)
end

function OverheadManager:configureOverhead(overhead, playemoduler)
	local frame = overhead:FindFirstChild("Frame")
	if not frame then return end

	local roleFrame = frame:FindFirstChild("RoleFrame")
	local nameFrame = frame:FindFirstChild("NameFrame")
	local otherFrame = frame:FindFirstChild("OtherFrame")
	local levelFrame = frame:FindFirstChild("LevelFrame")

	if nameFrame then
		local displayName = nameFrame:FindFirstChild("DisplayName")
		local clanTagLabel = nameFrame:FindFirstChild("ClanTag")

		local streak = getSavedStreak(player)

		if displayName then
			displayName.Text = player.DisplayName .. " 🔥" .. tostring(streak)
		end

		if clanTagLabel then 
			-- Obtener atributos del clan
			local clanTag = player:GetAttribute("ClanTag")
			local clanEmoji = player:GetAttribute("ClanEmoji")
			local clanColor = player:GetAttribute("ClanColor")

			-- Texto con emoji opcional
			if clanTag and clanTag ~= "" then
				local prefix = (clanEmoji and clanEmoji ~= "") and (clanEmoji .. " ") or ""
				clanTagLabel.Text = prefix .. "[" .. clanTag .. "]"
			else
				clanTagLabel.Text = ""
			end

			-- Color del clan
			if clanColor and typeof(clanColor) == "Color3" then
				clanTagLabel.TextColor3 = clanColor
			else
				clanTagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end

	self:setupRole(roleFrame, player)
	self:setupBadges(otherFrame, player)
	self:setupCountryFlag(otherFrame, player)
	self:setupLevelDisplay(levelFrame, player)
end

function OverheadManager:setupRole(roleFrame, player)
	if not roleFrame then return end

	local roleText = roleFrame:FindFirstChild("Role")
	if not roleText then return end

	local roleAssigned = false

	if player:IsInGroup(GroupID) then
		local success, rank = pcall(function()
			return player:GetRankInGroup(GroupID)
		end)

		if success then

			if GROUP_ROLES[rank] then
				roleText.Text = GROUP_ROLES[rank].Name
				roleText.TextColor3 = GROUP_ROLES[rank].Color
				roleAssigned = true
			else
				local highestRole = nil
				for roleRank, roleData in pairs(GROUP_ROLES) do
					if rank >= roleRank and (not highestRole or roleRank > highestRole) then
						highestRole = roleRank
					end
				end

				if highestRole then
					roleText.Text = GROUP_ROLES[highestRole].Name
					roleText.TextColor3 = GROUP_ROLES[highestRole].Color
					roleAssigned = true
				end
			end
		end
	end

	if not roleAssigned then
		local hasVIPPlus = GamepassManager.HasGamepass(player, VIP_PLUS_ID)
		local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)

		if hasVIPPlus then
			roleText.Text = "[ VIP PLUS ]"
			roleText.TextColor3 = Color3.fromRGB(255, 51, 15)
		elseif hasVIP then
			roleText.Text = "[ VIP ]"
			roleText.TextColor3 = Color3.fromRGB(217, 43, 13)
		else
			roleText.Text = "[ Tonero ]"
			roleText.TextColor3 = Color3.fromRGB(0, 85, 255)
		end
	end
end

function OverheadManager:setupBadges(otherFrame, player)
	if not otherFrame then return end

	local hasVIPPlus = GamepassManager.HasGamepass(player, VIP_PLUS_ID)
	local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)

	local premium = otherFrame:FindFirstChild("Premium")
	local vipPlus = otherFrame:FindFirstChild("VIPPLUS")
	local vip = otherFrame:FindFirstChild("VIP")
	local verify = otherFrame:FindFirstChild("Verify")

	if premium then premium.Visible = player.MembershipType == Enum.MembershipType.Premium end
	if vipPlus then vipPlus.Visible = hasVIPPlus end
	if vip then vip.Visible = hasVIP and not hasVIPPlus end
	if verify then verify.Visible = table.find(OWS_GAME_IDS, player.UserId) ~= nil end
end

function OverheadManager:setupCountryFlag(otherFrame, player)
	if not otherFrame then return end

	local countryFlag = otherFrame:FindFirstChild("Country")
	if not countryFlag then return end

	local showFlag = player:GetAttribute("ShowFlag")
	if showFlag == nil then
		showFlag = false
		player:SetAttribute("ShowFlag", false)
	end

	local success, country = pcall(function()
		return LocalizationService:GetCountryRegionForPlayerAsync(player)
	end)

	if success and country then
		countryFlag.Text = FlagUtils.GetFlag(country)
		countryFlag.Visible = showFlag
	else
		countryFlag.Text = ""
		countryFlag.Visible = false
	end
end

function OverheadManager:setupLevelDisplay(levelFrame, player)
	if not levelFrame then return end

	local levelLabel = levelFrame:FindFirstChild("Level")
	if not levelLabel then return end

	levelLabel.Text = "Cargando nivel..."
	player:SetAttribute("Level", 0)

	-- Esperar leaderstats
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("No se encontraron leaderstats para: " .. player.Name)
		levelLabel.Text = "Lv. ?"
		return
	end

	local levelStat = leaderstats:WaitForChild("Level 🌟", 10)
	if not levelStat then
		warn("No se encontró Level 🌟 en leaderstats de: " .. player.Name)
		levelLabel.Text = "Lv. ?"
		return
	end

	updateLevelDisplay(levelLabel, levelStat.Value)
	player:SetAttribute("Level", levelStat.Value)

	-- ✅ TRACK CONNECTION PARA LIMPIARLA DESPUÉS
	trackConnection(player, levelStat:GetPropertyChangedSignal("Value"):Connect(function()
		updateLevelDisplay(levelLabel, levelStat.Value)
		player:SetAttribute("Level", levelStat.Value)
	end))
end

--------------------------------------------------------------------------------------------------------

local function setupPlayerChat(player)
	player.Chatted:Connect(function(msg)
		if msg:lower():gsub("%s+", "") == ";afk" then
			setAFK(player, true)
		end
	end)
end

--------------------------------------------------------------------------------------------------------

local function setupMovementDetection(char, player)
	local humanoid = char:WaitForChild("Humanoid")

	local function removeAFK()
		setAFK(player, false)
	end

	-- ✅ TRACK CONNECTIONS
	trackConnection(player, humanoid.Running:Connect(function(speed)
		if speed > 0 then removeAFK() end
	end))

	trackConnection(player, humanoid.Jumping:Connect(function(isActive)
		if isActive then removeAFK() end
	end))
end

--------------------------------------------------------------------------------------------------------

local function onCharacterAdded(char, player)
	OverheadManager:setupOverhead(char, player)
	updatePlayerNameColor(player)
	setAFK(player, false)
	setupMovementDetection(char, player)

	-- Actualizar display de racha con valor guardado
	local savedStreak = getSavedStreak(player)
	updateStreakDisplay(player, savedStreak)
end

Players.PlayerAdded:Connect(function(player)
	trackConnection(player, player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
		updatePlayerNameColor(player)
	end))
	
	-- Listener para actualizar el overhead cuando cambie el tag del clan
	local function refreshClanTag()
		if not player.Character then return end
		local components = getOverheadComponents(player.Character)
		if not components or not components.nameFrame then return end
		local clanTagLabel = components.nameFrame:FindFirstChild("ClanTag")
		if not clanTagLabel then return end
		local clanTag = player:GetAttribute("ClanTag")
		local clanEmoji = player:GetAttribute("ClanEmoji")
		local clanColor = player:GetAttribute("ClanColor") -- Color3 directo
		local prefix = (clanEmoji and clanEmoji ~= "") and (clanEmoji .. " ") or ""
		clanTagLabel.Text = (clanTag and clanTag ~= "") and (prefix .. "[" .. clanTag .. "]") or ""
		-- Validar que sea Color3 antes de aplicar
		if clanColor and typeof(clanColor) == "Color3" then
			clanTagLabel.TextColor3 = clanColor
		else
			clanTagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	-- ✅ TRACK ATTRIBUTE CONNECTIONS
	trackConnection(player, player:GetAttributeChangedSignal("ClanTag"):Connect(refreshClanTag))
	trackConnection(player, player:GetAttributeChangedSignal("ClanEmoji"):Connect(refreshClanTag))
	trackConnection(player, player:GetAttributeChangedSignal("ClanColor"):Connect(refreshClanTag))

	setupPlayerChat(player)

	trackConnection(player, player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end))

	if player.Character then
		onCharacterAdded(player.Character, player)
	end

	local currentStreak = updateStreak(player)
	updateStreakDisplay(player, currentStreak)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		setupPlayerChat(player)
		local char = player.Character or player.CharacterAdded:Wait()
		onCharacterAdded(char, player)
		local currentStreak = updateStreak(player)
		updateStreakDisplay(player, currentStreak)
	end)
end

-- ✅ LIMPIAR CONEXIONES CUANDO EL JUGADOR SALE
Players.PlayerRemoving:Connect(function(player)
	disconnectAllPlayerConnections(player.UserId)
end)
