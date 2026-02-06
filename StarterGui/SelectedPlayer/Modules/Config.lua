--[[
	═══════════════════════════════════════════════════════════
	CONFIG - Configuraciones del UserPanel
	═══════════════════════════════════════════════════════════
	Todas las constantes y configuraciones estáticas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local configFolder = ReplicatedStorage:FindFirstChild("Config") or ReplicatedStorage:WaitForChild("Config", 2)
local THEME = pcall(function()
	return require(configFolder:FindFirstChild("ThemeConfig") or configFolder:WaitForChild("ThemeConfig", 2))
end) and require(configFolder:FindFirstChild("ThemeConfig") or configFolder:WaitForChild("ThemeConfig", 2)) or {}

return {
	-- Dimensiones del panel
	PANEL_WIDTH = 280,
	PANEL_HEIGHT = 350,
	PANEL_PADDING = 12,
	
	-- Avatar
	AVATAR_HEIGHT = 200,
	AVATAR_ZOOM = 1.2,
	
	-- Stats
	STATS_WIDTH = 70,
	STATS_ITEM_HEIGHT = 50,
	
	-- Botones
	BUTTON_HEIGHT = 38,
	BUTTON_GAP = 8,
	BUTTON_CORNER = 10,
	
	-- Cards
	CARD_SIZE = 75,
	
	-- Animaciones
	ANIM_FAST = 0.12,
	ANIM_NORMAL = 0.2,
	
	-- Cache y refresh
	AVATAR_CACHE_TIME = 300,
	AUTO_REFRESH_INTERVAL = 60,
	
	-- Raycast y input
	MAX_RAYCAST_DISTANCE = 80,
	CLICK_DEBOUNCE = 0.3,
	
	-- Likes
	LIKE_COOLDOWN = 60,
	
	-- Cursores
	DEFAULT_CURSOR = "rbxassetid://13335399499",
	SELECTED_CURSOR = "rbxassetid://84923889690331",
	
	-- Tema
	THEME = THEME
}
