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
local DataStoreQueue = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))

-- DataStore Queues para manejo de rate limit
local streakQueue = DataStoreQueue.new(streakStore, "StreakQueue")
local topRachaQueue = DataStoreQueue.new(TopRachaStore, "TopRachaQueue")

--// Constantes
local GroupID = Configuration.GroupID
local ALLOWED_RANKS = Configuration.ALLOWED_DJ_RANKS
local OWS_GAME_IDS = Configuration.OWS
local VIP_ID = Configuration.VIP
local GROUP_ROLES = GroupRolesModule.GROUP_ROLES

--// Configuración de tiempos de espera para carga de datos
local CLAN_LOAD_DELAY = 1.5
local CLAN_MAX_WAIT = 5
local CLAN_CHECK_INTERVAL = 0.5

--// Utilidad para banderas de país (fallback)
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

--------------------------------------------------------------------------------------------------------
-- ✅ BUSCADOR ROBUSTO PARA :rc (Name o DisplayName, sin importar mayúsculas)
local function findPlayerByNameOrDisplay(query)
	if not query or query == "" then return nil end
	local q = tostring(query):lower()

	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower() == q or p.DisplayName:lower() == q then
			return p
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then
			return p
		end
	end

	return nil
end

--------------------------------------------------------------------------------------------------------
-- ✅ Country Flags Catalog desde ReplicatedStorage/Config/CountryFlags (ModuleScript)
local CountryFlagsCatalog = nil
do
	local configFolder = ReplicatedStorage:FindFirstChild("Config")
	if configFolder then
		local mod = configFolder:FindFirstChild("CountryFlags")
		if mod and mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				CountryFlagsCatalog = data
			else
				warn("[FLAGS] CountryFlags no retornó tabla.")
			end
		end
	end
end

-- cache país por userId para no spammear LocalizationService
local countryCache = {} -- [userId] = { code="PE", t=os.clock() }
local COUNTRY_CACHE_TTL = 300 -- 5 min

local function getCountryCodeSafe(player)
	local userId = tostring(player.UserId)

	local cached = countryCache[userId]
	if cached and (os.clock() - cached.t) < COUNTRY_CACHE_TTL then
		return cached.code
	end

	local ok, code = pcall(function()
		return LocalizationService:GetCountryRegionForPlayerAsync(player)
	end)

	if ok and type(code) == "string" and #code == 2 then
		countryCache[userId] = { code = code, t = os.clock() }
		return code
	end

	return nil
end

local function getCountryEmojiSmart(code)
	if not code or code == "" then return "" end

	if CountryFlagsCatalog and CountryFlagsCatalog[code] then
		return CountryFlagsCatalog[code]
	end

	local ok, emoji = pcall(function()
		return FlagUtils.GetFlag(code)
	end)
	if ok and type(emoji) == "string" then
		return emoji
	end

	return ""
end

-- ✅ Render del DisplayName con Bandera + Racha (bandera al INICIO)
local function renderDisplayName(player, streakValue)
	if not player or not player.Character then return end

	local components = getOverheadComponents(player.Character)
	if not components or not components.nameFrame then return end

	local displayNameLabel = components.nameFrame:FindFirstChild("DisplayName")
	if not displayNameLabel then return end

	local showFlag = player:GetAttribute("ShowFlag")
	if showFlag == nil then
		showFlag = true
		player:SetAttribute("ShowFlag", true)
	end

	local emoji = ""
	if showFlag then
		local code = player:GetAttribute("CountryCode")
		if not code or code == "" then
			code = getCountryCodeSafe(player) or ""
			if code ~= "" then
				player:SetAttribute("CountryCode", code)
			end
		end
		emoji = getCountryEmojiSmart(code)
		player:SetAttribute("CountryEmoji", emoji)
	end

	local prefix = (emoji ~= "" and (emoji .. " ")) or ""
	displayNameLabel.Text = prefix .. player.DisplayName .. " 🔥" .. tostring(streakValue or 1)
end

local function resolveCountryForPlayer(player)
	if not player or not player.Parent then return end

	task.spawn(function()
		local code = getCountryCodeSafe(player)
		if code and code ~= "" then
			player:SetAttribute("CountryCode", code)
			player:SetAttribute("CountryEmoji", getCountryEmojiSmart(code))
		else
			player:SetAttribute("CountryCode", "")
			player:SetAttribute("CountryEmoji", "")
		end
	end)
end

-- Función para sincronizar estado VIP en tiempo real
local function updateVIPStatus(player)
	if not player or not player.Parent then return end
	local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)
	player:SetAttribute("HasVIP", hasVIP)
end

--------------------------------------------------------------------------------------------------------
--// Funciones para el sistema de racha
local function getCurrentDay()
	return math.floor(os.time() / 86400) -- Días desde epoch (24h completas)
end

local streakCache = {}

local function safeUpdateAsync(store, key, transformFn)
	local maxRetries = 5
	for attempt = 1, maxRetries do
		local ok, result = pcall(function()
			return store:UpdateAsync(key, transformFn)
		end)
		if ok then
			return true, result
		end
		warn(string.format("[RACHA] UpdateAsync error (intento %d/%d): %s", attempt, maxRetries, tostring(result)))
		task.wait(2 * attempt)
	end
	return false, nil
end

local function getSavedStreak(player)
	if not player or not player.UserId then return 1 end
	local userId = tostring(player.UserId)

	local cached = streakCache[userId]
	if cached then
		return cached.streak
	end

	local result = 1
	local isComplete = false
	
	streakQueue:GetAsync(userId, function(success, data)
		if success and data and data.streak then
			streakCache[userId] = {
				streak = data.streak,
				lastDay = data.lastLoginDay or data.lastDay or 0
			}
			result = data.streak
		end
		isComplete = true
	end)

	-- Esperar hasta que se complete (máximo 1 segundo)
	local startTime = tick()
	while not isComplete and (tick() - startTime) < 1 do
		task.wait(0.02)
	end
	
	return result
end

-- ✅ No pisa la racha si GetAsync falla
local function updateStreak(player)
	if not player or not player.UserId then return 1 end
	local userId = tostring(player.UserId)
	local today = getCurrentDay()

	local cached = streakCache[userId]
	if cached and cached.lastDay == today then
		return cached.streak
	end

	local success, data = false, nil
	local isComplete = false
	
	streakQueue:GetAsync(userId, function(s, d)
		success = s
		data = d
		isComplete = true
	end)

	-- Esperar hasta que se complete (máximo 1 segundo)
	local startTime = tick()
	while not isComplete and (tick() - startTime) < 1 do
		task.wait(0.02)
	end

	if not success then
		if cached then return cached.streak end
		warn("[RACHA] GetAsync falló para userId:", userId, "no se guardará nada.")
		return 1
	end

	local currentStreak = 1
	local lastDay = -1

	if data then
		currentStreak = tonumber(data.streak) or 1
		lastDay = tonumber(data.lastLoginDay or data.lastDay) or -1
	end

	local newStreak
	if lastDay == today then
		newStreak = currentStreak
	elseif lastDay == today - 1 then
		newStreak = currentStreak + 1
	else
		newStreak = 1
	end

	if (not cached) or cached.streak ~= newStreak or cached.lastDay ~= today then
		local ok = safeUpdateAsync(streakStore, userId, function(old)
			old = old or {}
			local oldStreak = tonumber(old.streak) or 1
			local oldLastDay = tonumber(old.lastLoginDay or old.lastDay) or -1

			local finalStreak
			if oldLastDay == today then
				finalStreak = oldStreak
			elseif oldLastDay == today - 1 then
				finalStreak = oldStreak + 1
			else
				finalStreak = 1
			end

			return {
				streak = finalStreak,
				lastLoginDay = today,
				lastDay = today
			}
		end)

		if ok then
			topRachaQueue:SetAsync(userId, newStreak, function() end)
		end
		streakCache[userId] = { streak = newStreak, lastDay = today }
	end

	return newStreak
end

local function setStreakManual(player, amount)
	if not player or not player.UserId then return end
	local userId = tostring(player.UserId)
	local today = getCurrentDay()

	amount = math.max(1, tonumber(amount) or 1)

	local newStreakData = {
		streak = amount,
		lastLoginDay = today,
		lastDay = today
	}
	streakQueue:SetAsync(userId, newStreakData, function() end)
	topRachaQueue:SetAsync(userId, amount, function() end)
	streakCache[userId] = { streak = amount, lastDay = today }

	renderDisplayName(player, amount)
end

local function EsAdminGrupo(player)
	return Colors.hasPermission(player, GroupID, ALLOWED_RANKS)
end

--------------------------------------------------------------------------------------------------------
-- ✅ COMANDO :rc (arreglado)
Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		local original = msg
		local lower = tostring(msg):lower()

		if lower:sub(1,3) == ":rc" then
			if not EsAdminGrupo(plr) then return end

			local args = original:split(" ")
			local targetName = args[2]
			local amount = tonumber(args[3])

			if not targetName or not amount then
				warn("[RC] Uso: :rc <jugador> <cantidad>")
				return
			end

			local target = findPlayerByNameOrDisplay(targetName)
			if target then
				setStreakManual(target, amount)
			else
				warn("[RC] Jugador no encontrado:", targetName)
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
	elseif displayName then
		displayName.TextColor3 = Color3.fromRGB(255,255,255)
	end
end

--------------------------------------------------------------------------------------------------------
-- ✅ ClanTag centralizado
local function updateClanTagDisplay(player, clanTagLabel)
	if not clanTagLabel then return end

	local clanTag = player:GetAttribute("ClanTag")
	local clanEmoji = player:GetAttribute("ClanEmoji")
	local clanColor = player:GetAttribute("ClanColor")

	if clanTag and clanTag ~= "" then
		local prefix = (clanEmoji and clanEmoji ~= "") and (clanEmoji .. " ") or ""
		clanTagLabel.Text = prefix .. "[" .. clanTag .. "]"
	else
		clanTagLabel.Text = ""
	end

	if clanColor and typeof(clanColor) == "Color3" then
		clanTagLabel.TextColor3 = clanColor
	else
		clanTagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function refreshClanTagWithRetry(player, char)
	if not player or not char then return end
	if player.Character ~= char then return end

	local components = getOverheadComponents(char)
	if not components or not components.nameFrame then return end

	local clanTagLabel = components.nameFrame:FindFirstChild("ClanTag")
	if not clanTagLabel then return end

	updateClanTagDisplay(player, clanTagLabel)

	local clanTag = player:GetAttribute("ClanTag")
	if not clanTag or clanTag == "" then
		task.spawn(function()
			local elapsed = 0
			while elapsed < CLAN_MAX_WAIT do
				task.wait(CLAN_CHECK_INTERVAL)
				elapsed = elapsed + CLAN_CHECK_INTERVAL

				if not player or not player.Parent then return end
				if player.Character ~= char then return end

				local newClanTag = player:GetAttribute("ClanTag")
				if newClanTag and newClanTag ~= "" then
					updateClanTagDisplay(player, clanTagLabel)
					break
				end
			end
		end)
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

	self:configureOverhead(overheadClone, player, char)
end

function OverheadManager:configureOverhead(overhead, player, char)
	local frame = overhead:FindFirstChild("Frame")
	if not frame then return end

	local roleFrame = frame:FindFirstChild("RoleFrame")
	local nameFrame = frame:FindFirstChild("NameFrame")
	local otherFrame = frame:FindFirstChild("OtherFrame")
	local levelFrame = frame:FindFirstChild("LevelFrame")

	if nameFrame then
		local clanTagLabel = nameFrame:FindFirstChild("ClanTag")
		if clanTagLabel then
			updateClanTagDisplay(player, clanTagLabel)
		end

		-- ✅ Nombre renderizado con bandera + racha (bandera al inicio)
		local streak = getSavedStreak(player)
		renderDisplayName(player, streak)
	end

	self:setupRole(roleFrame, player)
	self:setupBadges(otherFrame, player)
	self:setupLevelDisplay(levelFrame, player)
end

function OverheadManager:setupRole(roleFrame, player)
	if not roleFrame then return end
	local roleText = roleFrame:FindFirstChild("Role")
	if not roleText then return end

	local function updateRoleDisplay()
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
			local hasVIP = player:GetAttribute("HasVIP") or false

			if hasVIP then
				roleText.Text = "[ VIP ]"
				roleText.TextColor3 = Color3.fromRGB(217, 43, 13)
			else
				roleText.Text = "[ Tonero ]"
				roleText.TextColor3 = Color3.fromRGB(0, 85, 255)
			end
		end
	end

	-- Inicial
	updateRoleDisplay()
	
	-- Escuchar cambios en atributo HasVIP en tiempo real
	trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		updateRoleDisplay()
	end))
end

function OverheadManager:setupBadges(otherFrame, player)
	if not otherFrame then return end

	local premium = otherFrame:FindFirstChild("Premium")
	local vip = otherFrame:FindFirstChild("VIP")
	local verify = otherFrame:FindFirstChild("Verify")

	local function updateBadges()
		local hasVIP = player:GetAttribute("HasVIP") or false
		if premium then premium.Visible = player.MembershipType == Enum.MembershipType.Premium end
		if vip then vip.Visible = hasVIP end
		if verify then verify.Visible = table.find(OWS_GAME_IDS, player.UserId) ~= nil end
	end

	-- Inicial
	updateBadges()
	
	-- Escuchar cambios en HasVIP
	trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(updateBadges))
end

function OverheadManager:setupLevelDisplay(levelFrame, player)
	if not levelFrame then return end

	local levelLabel = levelFrame:FindFirstChild("Level")
	if not levelLabel then return end

	levelLabel.Text = "Cargando nivel..."
	player:SetAttribute("Level", 0)

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

	-- ✅ Actualiza racha y repinta nombre (con bandera al inicio)
	local currentStreak = updateStreak(player)
	renderDisplayName(player, currentStreak)

	task.delay(CLAN_LOAD_DELAY, function()
		refreshClanTagWithRetry(player, char)
	end)
end

Players.PlayerAdded:Connect(function(player)
	resolveCountryForPlayer(player)
	updateVIPStatus(player)

	trackConnection(player, player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
		updatePlayerNameColor(player)
	end))

	local function refreshClanTag()
		if not player or not player.Parent then return end
		if not player.Character then return end

		local components = getOverheadComponents(player.Character)
		if not components or not components.nameFrame then return end

		local clanTagLabel = components.nameFrame:FindFirstChild("ClanTag")
		if not clanTagLabel then return end

		updateClanTagDisplay(player, clanTagLabel)
	end

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
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		setupPlayerChat(player)
		resolveCountryForPlayer(player)
		updateVIPStatus(player)

		trackConnection(player, player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
			updatePlayerNameColor(player)
		end))

		local function refreshClanTag()
			if not player or not player.Parent then return end
			if not player.Character then return end

			local components = getOverheadComponents(player.Character)
			if not components or not components.nameFrame then return end

			local clanTagLabel = components.nameFrame:FindFirstChild("ClanTag")
			if not clanTagLabel then return end

			updateClanTagDisplay(player, clanTagLabel)
		end

		trackConnection(player, player:GetAttributeChangedSignal("ClanTag"):Connect(refreshClanTag))
		trackConnection(player, player:GetAttributeChangedSignal("ClanEmoji"):Connect(refreshClanTag))
		trackConnection(player, player:GetAttributeChangedSignal("ClanColor"):Connect(refreshClanTag))

		local char = player.Character or player.CharacterAdded:Wait()
		onCharacterAdded(char, player)
	end)
end

-- LIMPIAR CONEXIONES / CACHES CUANDO EL JUGADOR SALE
Players.PlayerRemoving:Connect(function(player)
	disconnectAllPlayerConnections(player.UserId)
	streakCache[tostring(player.UserId)] = nil
	countryCache[tostring(player.UserId)] = nil
end)
