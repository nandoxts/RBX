-- ToneCommandHandler.lua (Optimizado)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════
local CONFIG = {
	prefix = ";tono",
	whitelist = {
		"xlm_brem",
		"AngeloGarciia",
		"bvwdhfv",
		"ignxts"
	},
    messages = {
        disabled = "Sistema de tono desactivado.",
        rainbow = "Modo rainbow activado.",
        theme = "Modo %s se ha activado.",  -- ← Cambiar aquí
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

-- ═══════════════════════════════════════════════════════════════════
-- LÓGICA
-- ═══════════════════════════════════════════════════════════════════
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
		toneModeEvent:Fire("theme", args)
		broadcast(string.format(CONFIG.messages.theme, args))
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
	if table.find(CONFIG.whitelist, player.Name) then
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