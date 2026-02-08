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

local UserInputService = game:GetService("UserInputService")

-- Detectar si es mobile
local function isMobileDevice()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local IS_MOBILE = isMobileDevice()

-- Configuración responsive
local PANEL_WIDTH = IS_MOBILE and 200 or 280
local PANEL_HEIGHT = IS_MOBILE and 280 or 350
local AVATAR_HEIGHT = IS_MOBILE and 170 or 200
local BUTTON_HEIGHT = IS_MOBILE and 20 or 38
local CARD_SIZE = IS_MOBILE and 80 or 75

return {
	-- Device detection
	IS_MOBILE = IS_MOBILE,
	
	-- Dimensiones del panel (responsivas)
	PANEL_WIDTH = PANEL_WIDTH,
	PANEL_HEIGHT = PANEL_HEIGHT,
	PANEL_PADDING = IS_MOBILE and 10 or 12,
	
	-- Avatar
	AVATAR_HEIGHT = AVATAR_HEIGHT,
	AVATAR_ZOOM = IS_MOBILE and 1.0 or 1.2,
	
	-- Stats
	STATS_WIDTH = IS_MOBILE and 50 or 70,
	STATS_ITEM_HEIGHT = IS_MOBILE and 35 or 50,
	
	-- Botones
	BUTTON_HEIGHT = BUTTON_HEIGHT,
	BUTTON_GAP = IS_MOBILE and 6 or 8,
	BUTTON_CORNER = 10,
	
	-- Cards
	CARD_SIZE = CARD_SIZE,
	
	-- Animaciones
	ANIM_FAST = 0.12,
	ANIM_NORMAL = 0.2,
	
	-- Cache y refresh
	AVATAR_CACHE_TIME = 300,
	AUTO_REFRESH_INTERVAL = 60,
	
	-- Raycast y input
	MAX_RAYCAST_DISTANCE = 80,
	CLICK_DEBOUNCE = IS_MOBILE and 0.5 or 0.3,
	
	-- Touch
	TOUCH_ENABLED = true,
	LONG_PRESS_TIME = 0.5,
	
	-- Likes
	LIKE_COOLDOWN = 60,
	
	-- Cursores (solo desktop)
	DEFAULT_CURSOR = "rbxassetid://13335399499",
	SELECTED_CURSOR = "rbxassetid://84923889690331",
	
	-- Tema
	THEME = THEME
}
