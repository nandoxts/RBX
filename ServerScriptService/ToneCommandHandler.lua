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
local toneModeEvent = ReplicatedStorage:WaitForChild("ToneModeChanged")
local getModeFunction = ReplicatedStorage:WaitForChild("GetToneMode")

local toneMessageEvent = ReplicatedStorage:FindFirstChild("ToneMessage") or (function()
	local event = Instance.new("RemoteEvent")
	event.Name = "ToneMessage"
	event.Parent = ReplicatedStorage
	return event
end)()

-- RemoteFunction para obtener temas disponibles de RainbowSync
-- Usar WaitForChild para asegurar que RainbowSync lo cree primero
local getThemesFunction
local success = false
local attempts = 0

while not success and attempts < 30 do  -- Esperar máximo 30 segundos (30 * 1 segundo)
	local ok, result = pcall(function()
		return ReplicatedStorage:WaitForChild("GetAvailableThemes", 1)  -- Timeout de 1 segundo
	end)

	if ok and result then
		getThemesFunction = result
		success = true
	else
		attempts = attempts + 1
		task.wait(1)
	end
end

if not success then
	error("[ToneCommandHandler] CRITICAL: GetAvailableThemes no fue encontrada después de 30 segundos. RainbowSync podría no haberse ejecutado.")
end

-- ═══════════════════════════════════════════════════════════════════
-- LÓGICA
-- ═══════════════════════════════════════════════════════════════════
local function getAvailableThemes()
	if not getThemesFunction then
		return {}
	end
	
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