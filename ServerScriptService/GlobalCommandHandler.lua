-- GlobalCommandHandler.lua (Optimizado)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local HDConnect = require(game:GetService("ServerScriptService"):WaitForChild("Panda ServerScriptService"):WaitForChild("Gamepass Gifting"):WaitForChild("HD-CONNECT"))

-- Obtener HD Admin main
local SetupHd = ReplicatedStorage:WaitForChild("HDAdminSetup", 10)
local hdMain = SetupHd and require(SetupHd):GetMain()
local hd = hdMain and hdMain:GetModule("API")

local CONFIG = {
	prefix = ";tono",
	eventPrefix = ";event",
	uneventPrefix = ";unevent",
	m2Prefix = ";m2",
	messages = {
		disabled = "Sistema de tono desactivado.",
		rainbow = "Modo rainbow activado.",
		theme = "Modo %s se ha activado.",
	}
}

-- ║ Permisos para ;m2 (Rango mínimo = 0, todos pueden usar)
local M2_MIN_RANK = 0

-- ═══════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local commandsFolder = remotesGlobal:WaitForChild("Commands")

local toneModeEvent = commandsFolder:WaitForChild("ToneModeChanged")
local getModeFunction = commandsFolder:WaitForChild("GetToneMode")
local toneMessageEvent = commandsFolder:WaitForChild("ToneMessage")
local eventMessageEvent = commandsFolder:WaitForChild("EventMessage")

-- RemoteFunction para obtener temas disponibles de RainbowSync
local getThemesFunction = commandsFolder:WaitForChild("GetAvailableThemes")

-- M2 Announcement Remotes
local messageFolder = remotesGlobal:FindFirstChild("Message")
if not messageFolder then
	messageFolder = Instance.new("Folder")
	messageFolder.Name = "Message"
	messageFolder.Parent = remotesGlobal
end

local M2CommandProcessor = messageFolder:FindFirstChild("M2CommandProcessor")
if not M2CommandProcessor then
	M2CommandProcessor = Instance.new("RemoteFunction")
	M2CommandProcessor.Name = "M2CommandProcessor"
	M2CommandProcessor.Parent = messageFolder
end

local localAnnouncement = messageFolder:FindFirstChild("LocalAnnouncement")
if not localAnnouncement then
	localAnnouncement = Instance.new("RemoteEvent")
	localAnnouncement.Name = "LocalAnnouncement"
	localAnnouncement.Parent = messageFolder
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════
-- Obtener el rango HD Admin del usuario
local function getUserRank(player)
	if not hd then return 0 end
	local rank = hd:GetRankFor(player) or 0
	return rank
end

-- Validar permisos para ;m2
local function canUseM2Command(player)
	local userRank = getUserRank(player)
	return userRank >= M2_MIN_RANK
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

	-- Procesar comando ;tono
	if lower:sub(1, #CONFIG.prefix) == CONFIG.prefix then
		local args = message:sub(#CONFIG.prefix + 1)
		handleCommand(args)
	end

	-- Procesar comando ;event
	if lower == CONFIG.eventPrefix then
		if MusicConfig:IsAdmin(player) then
			setEventMode(true)
			local msg = "MODO EVENTO ACTIVADO"
			print("Modo Evento ACTIVADO por: " .. player.Name)
			fireAllClients(eventMessageEvent, msg)
		end
	end

	-- Procesar comando ;unevent
	if lower == CONFIG.uneventPrefix then
		if MusicConfig:IsAdmin(player) then
			setEventMode(false)
			local msg = " MODO EVENTO DESACTIVADO"
			print("Modo Evento DESACTIVADO por: " .. player.Name)
			fireAllClients(eventMessageEvent, msg)
		end
	end
end

local function connectPlayer(player)
	if AdminConfig:IsAdmin(player) then
		player.Chatted:Connect(function(msg) onChatted(player, msg) end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- REMOTEFUNCTION M2COMMANDPROCESSOR
-- ═══════════════════════════════════════════════════════════════════
M2CommandProcessor.OnServerInvoke = function(player, message)
	print("[M2 SYSTEM] Cliente (" .. player.Name .. ") invocó M2CommandProcessor:", message)
	
	-- Validar permisos con HD Admin
	if not canUseM2Command(player) then
		print("[M2 SYSTEM] DENEGADO - Usuario sin permisos (Rango:", getUserRank(player), ")")
		return false
	end
	
	print("[M2 SYSTEM] Permiso APROBADO para", player.Name)
	
	-- Validar mensaje
	if not message or message == "" then
		print("[M2 SYSTEM] ERROR - Mensaje vacío")
		return false
	end
	
	-- Disparar anuncio a todos los clientes
	print("[M2 SYSTEM] Disparando anuncio:", player.Name, " - ", message)
	pcall(function()
		localAnnouncement:FireAllClients(player.Name, message)
	end)
	
	return true
end

print("[M2 SYSTEM] RemoteFunction M2CommandProcessor inicializada ✓")

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════
for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)