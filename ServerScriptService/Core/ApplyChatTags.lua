-- Script: ApplyChatTags
-- Configura chat tags usando el sistema nativo de HD Admin
-- En ServerScriptService

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Cargar CentralAdminConfig
local CentralAdmin
local success, err = pcall(function()
	CentralAdmin = require(ServerStorage:WaitForChild("Config"):WaitForChild("CentralAdminConfig", 5))
end)

if not success or not CentralAdmin then
	warn("[ChatTags] Error al cargar configuración:", err)
	return
end

-- Contar admins con tags configurados
local tagCount = 0
for _, admin in pairs(CentralAdmin.Admins) do
	if admin.chatTag then
		tagCount = tagCount + 1
	end
end


-- ════════════════════════════════════════════════════════════════
-- APLICAR CHAT TAGS
-- ════════════════════════════════════════════════════════════════

local function applyChatTag(player)
	if not CentralAdmin:isAdmin(player.UserId) then
		return
	end

	local chatTag = CentralAdmin:getChatTag(player.UserId)
	local chatColor = CentralAdmin:getChatColor(player.UserId)

	if chatTag then
		-- Activar sistema HD Admin
		player:SetAttribute("HDChatConfigEnabled", true)
		player:SetAttribute("ChatTag", chatTag)
		player:SetAttribute("ChatTagColor", chatColor)

	end
end

-- Eventos
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	applyChatTag(player)
end)

-- Jugadores ya conectados (Studio)
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2)
		applyChatTag(player)
	end)
end