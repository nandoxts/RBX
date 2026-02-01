-- ToneCommandHandler.lua (Optimizado)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))

local CONFIG = {
	prefix = ";tono",
	messages = {
		disabled = "Sistema de tono desactivado.",
		rainbow = "Modo rainbow activado.",
		theme = "Modo %s se ha activado.",
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

-- RemoteFunction para obtener temas disponibles de RainbowSync
local getThemesFunction = commandsFolder:WaitForChild("GetAvailableThemes")

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
	if lower:sub(1, #CONFIG.prefix) == CONFIG.prefix then
		local args = message:sub(#CONFIG.prefix + 1)
		handleCommand(args)
	end
end

local function connectPlayer(player)
	if AdminConfig:IsAdmin(player) then
		player.Chatted:Connect(function(msg) onChatted(player, msg) end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════
for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)