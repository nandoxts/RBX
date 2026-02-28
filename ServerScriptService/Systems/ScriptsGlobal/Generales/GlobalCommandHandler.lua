-- GlobalCommandHandler.lua (Optimizado)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

-- Configuración HD Admin
local SetupHd = ReplicatedStorage:WaitForChild("HDAdminSetup", 10)
local hdMain = SetupHd and require(SetupHd):GetMain()
local hd = hdMain and hdMain:GetModule("API")

local CONFIG = {
	prefix = ";tono",
	eventPrefix = ";event",
	uneventPrefix = ";unevent",
	m2Prefix = ";m2",
	nochePrefix = ";noche",
	diaPrefix = ";dia",
	messages = {
		disabled = "Sistema de tono desactivado.",
		rainbow = "Modo rainbow activado.",
		theme = "Modo %s se ha activado.",
		noche = "Noche Activa",
		dia = "CICLO DÍA/NOCHE ACTIVADO",
	}
}

-- ═══════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local commandsFolder = remotesGlobal:WaitForChild("Commands")

local toneModeEvent = commandsFolder:WaitForChild("ToneModeChanged")
local getModeFunction = commandsFolder:WaitForChild("GetToneMode")
local toneMessageEvent = commandsFolder:WaitForChild("ToneMessage")
local eventMessageEvent = commandsFolder:WaitForChild("EventMessage")
local nocheMessageEvent = commandsFolder:WaitForChild("NocheMessage")

-- RemoteFunction para obtener temas disponibles de RainbowSync
local getThemesFunction = commandsFolder:WaitForChild("GetAvailableThemes")

-- M2 Announcement Remotes
local messageFolder = remotesGlobal:WaitForChild("Message")
local localAnnouncement = messageFolder:WaitForChild("LocalAnnouncement")
local m2CooldownNotif = messageFolder:WaitForChild("M2CooldownNotif")

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════
-- Validar permisos para ;m2 (Solo Influencer en adelante)
local function canUseM2Command(player)
	if not hd then return false end

	-- Obtener rango actual del usuario
	local rankId = hd:GetRank(player)

	-- Obtener rankId de Influencer (es el rango mínimo para M2)
	local influencerRankId = hd:GetRankId("Influencer")

	-- Comparar si es >= Influencer
	if rankId and influencerRankId then
		return rankId >= influencerRankId
	end

	return false
end

-- m2Cooldown
local m2Cooldown = {}
local M2_COOLDOWN_TIME = 7

local function canUseM2Cooldown(player)
	local now = tick()
	local lastUse = m2Cooldown[player.UserId]

	if lastUse and (now - lastUse) < M2_COOLDOWN_TIME then
		local remainingTime = math.ceil(M2_COOLDOWN_TIME - (now - lastUse))
		pcall(function()
			m2CooldownNotif:FireClient(player, remainingTime)
		end)
		return false
	end

	m2Cooldown[player.UserId] = now
	return true
end

local eventModeActive = MusicConfig.EVENT_MODE.Enabled or false

-- Exportar a _G para que otros scripts puedan acceder
_G.EventModeActive = eventModeActive

local function fireAllClients(remote, message)
	if remote then
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() remote:FireClient(p, message) end)
		end
	end
end

-- Actualizar _G cuando cambia el estado
local function setEventMode(value)
	eventModeActive = value
	_G.EventModeActive = value
end

-- ═══════════════════════════════════════════════════════════════════
-- LÓGICA
-- ═══════════════════════════════════════════════════════════════════
local function getAvailableThemes()
	local ok, themes = pcall(function()
		return getThemesFunction:Invoke()
	end)

	return ok and themes or {}
end

local function isThemeValid(themeName)
	local themes = getAvailableThemes()
	for _, theme in ipairs(themes) do
		if theme == themeName then
			return true
		end
	end
	return false
end

local function broadcast(msg)
	toneMessageEvent:FireAllClients(msg)
end

local function handleCommand(args)
	args = args:lower():gsub("^%s*(.-)%s*$", "%1") -- trim

	if args == "" then
		-- Toggle rainbow/disabled
		local current = getModeFunction:Invoke()
		if current == "rainbow" then
			toneModeEvent:Fire("disabled")
			broadcast(CONFIG.messages.disabled)
		else
			toneModeEvent:Fire("rainbow")
			broadcast(CONFIG.messages.rainbow)
		end
	elseif args == "off" then
		toneModeEvent:Fire("disabled")
		broadcast(CONFIG.messages.disabled)
	else
		-- Validar que el tema exista antes de enviar mensaje
		if isThemeValid(args) then
			toneModeEvent:Fire("theme", args)
			broadcast(string.format(CONFIG.messages.theme, args))
		end
		-- Si no existe, no hacer nada (silenciosamente)
	end
end

local function onChatted(player, message)
	local lower = message:lower()

	-- Procesar comando ;tono (requiere admin)
	if lower:sub(1, #CONFIG.prefix) == CONFIG.prefix then
		if not AdminConfig:IsAdmin(player) then
			return
		end
		local args = message:sub(#CONFIG.prefix + 1)
		handleCommand(args)
	end

	-- Procesar comando ;event (requiere admin)
	if lower == CONFIG.eventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(true)
			local msg = "MODO EVENTO ACTIVADO"
			fireAllClients(eventMessageEvent, msg)
		end
	end


	-- Procesar comando ;noche (requiere admin)
	if lower == CONFIG.nochePrefix then
		if AdminConfig:IsAdmin(player) then
			-- Desactivar ciclo de tiempo y forzar noche
			_G.ClockEnabled = false
			game:GetService("Lighting").ClockTime = 22

			-- Notificar a todos los jugadores
			fireAllClients(nocheMessageEvent, CONFIG.messages.noche)
		end
	end

	-- Procesar comando ;dia (requiere admin)
	if lower == CONFIG.diaPrefix then
		if AdminConfig:IsAdmin(player) then
			-- Activar ciclo día/noche
			_G.ClockEnabled = true

			-- Notificar a todos los jugadores
			fireAllClients(nocheMessageEvent, CONFIG.messages.dia)
		end
	end
	-- Procesar comando ;unevent (requiere admin)
	if lower == CONFIG.uneventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(false)
			local msg = " MODO EVENTO DESACTIVADO"
			fireAllClients(eventMessageEvent, msg)
		end
	end

	-- Procesar comando ;m2 (requiere Influencer+ en HD Admin)
	if lower:sub(1, #CONFIG.m2Prefix) == CONFIG.m2Prefix and lower:sub(#CONFIG.m2Prefix + 1, #CONFIG.m2Prefix + 1) == " " then
		-- Si modo evento está activo, deshabilitar ;m2
		if eventModeActive then
			return
		end

		-- Validar cooldown
		if not canUseM2Cooldown(player) then
			return
		end

		-- Validar permisos (Solo Influencer+)
		if not canUseM2Command(player) then
			return
		end

		-- Extraer mensaje original (preserva mayúsculas)
		local m2Message = message:sub(#CONFIG.m2Prefix + 2)

		if m2Message and m2Message ~= "" then
			-- Procesar en hilo separado porque FilterStringAsync es una función async (yield)
			task.spawn(function()
				local textToSend = m2Message
				local blocked = false

				-- Intentar filtrar con la API oficial de Roblox
				local filterOk, filterResult = pcall(function()
					return TextService:FilterStringAsync(m2Message, player.UserId, Enum.TextFilterContext.PublicChat)
				end)

				if filterOk and filterResult then
					local filteredOk, filteredText = pcall(function()
						return filterResult:GetNonChatStringForBroadcastAsync()
					end)

					if filteredOk and filteredText then
						-- Roblox reemplaza contenido inapropiado con ###
						if filteredText:match("#+") and #filteredText:gsub("[^#]", "") >= 3 then
							blocked = true
						else
							textToSend = filteredText
						end
					end
					-- Si GetNonChatStringForBroadcastAsync falla => mensaje pasa (fail-open)
				end
				-- Si FilterStringAsync falla (error de red) => mensaje pasa (fail-open)

				if blocked then
					pcall(function()
						toneMessageEvent:FireClient(player, "Tu mensaje fue bloqueado por contener lenguaje inapropiado.")
					end)
					return
				end

				-- Obtener display name del jugador
				local displayName = player.DisplayName or player.Name

				-- Disparar anuncio a todos los clientes
				pcall(function()
					localAnnouncement:FireAllClients(displayName, player.Name, textToSend)
				end)
			end)
		end
	end
end

local function connectPlayer(player)
	player.Chatted:Connect(function(msg) onChatted(player, msg) end)
end

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════
-- Pequeño delay para asegurar que los Remotes estén disponibles en clientes
task.wait(0.5)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)