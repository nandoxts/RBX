--[[
	SETTINGS CONFIG - Configuración centralizada de Settings
	5 Tabs: Gráficos, Jugabilidad, Créditos, Comentarios, Alertas
]]

local SettingsConfig = {}

-- ============================================
-- INICIALES (DEFAULTS)
-- ============================================
SettingsConfig.DEFAULTS = {
	-- JUGABILIDAD
	chat = true,
	viewTagsUsers = true,
	viewUsers = true,
	viewFlagUser = false,
	viewSelected = true,
	
	-- GRÁFICOS
	atmosphere = true,
	blur = true,
	clouds = true,
	colorCorrection = false,
	depthOfField = false,
	diffuse = true,
	particles = true,
	reflections = true,
	shadows = true,
	textures = true,
	effects = true,
	
	-- ALERTAS
	soundDiscord = true,
	soundTwitter = true,
	soundWhatsApp = true,
}

-- ============================================
-- TABS ESTRUCTURA
-- ============================================
SettingsConfig.TABS = {
	{
		id = "gameplay",
		title = "JUGABILIDAD",
		icon = "🎮",
		order = 1
	},
	{
		id = "graphics",
		title = "GRÁFICOS",
		icon = "🖼️",
		order = 2
	},
	{
		id = "alerts",
		title = "ALERTAS",
		icon = "🔔",
		order = 3
	},
	{
		id = "credits",
		title = "CRÉDITOS",
		icon = "⭐",
		order = 4
	},
	{
		id = "comments",
		title = "COMENTARIOS",
		icon = "💬",
		order = 5
	},
}

-- ============================================
-- SETTINGS POR TAB
-- ============================================
SettingsConfig.SETTINGS = {
	gameplay = {
		{
			id = "chat",
			label = "Burbujas de Chat",
			desc = "Ver burbujas de chat de otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				game.Chat.BubbleChatEnabled = value
			end
		},
		{
			id = "viewTagsUsers",
			label = "Tags de Jugadores",
			desc = "Ver tags sobre otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "viewUsers",
			label = "Ver Jugadores",
			desc = "Mostrar/ocultar otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "viewFlagUser",
			label = "Ver Mi Bandera",
			desc = "Mostrar tu bandera de país",
			type = "toggle",
			default = false,
			action = function(value)
				-- Manejado en servidor
			end
		},
		{
			id = "viewSelected",
			label = "Cuadro de Selección",
			desc = "Ver cuadro al seleccionar jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
	},
	
	graphics = {
		{
			id = "atmosphere",
			label = "Atmósfera",
			desc = "Efecto de atmósfera/niebla",
			type = "toggle",
			default = true,
			action = function(value)
				game.Lighting.Atmosphere.Density = value and 0.3 or 0
			end
		},
		{
			id = "blur",
			label = "Desenfoque",
			desc = "Efecto de desenfoque de profundidad",
			type = "toggle",
			default = true,
			action = function(value)
				if game.Lighting:FindFirstChild("Desenfoque") then
					game.Lighting.Desenfoque.Size = value and 2 or 0
				end
			end
		},
		{
			id = "clouds",
			label = "Nubes",
			desc = "Nubes en el cielo",
			type = "toggle",
			default = true,
			action = function(value)
				if game.Workspace:FindFirstChild("Terrain") and game.Workspace.Terrain:FindFirstChild("Clouds") then
					game.Workspace.Terrain.Clouds.Enabled = value
				end
			end
		},
		{
			id = "shadows",
			label = "Sombras",
			desc = "Sombras globales",
			type = "toggle",
			default = true,
			action = function(value)
				game.Lighting.GlobalShadows = value
			end
		},
		{
			id = "textures",
			label = "Texturas",
			desc = "Texturas de alta calidad",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "reflections",
			label = "Reflejos",
			desc = "Reflejos ambientales",
			type = "toggle",
			default = true,
			action = function(value)
				game.Lighting.EnvironmentSpecularScale = value and 1 or 0
			end
		},
		{
			id = "diffuse",
			label = "Difusión",
			desc = "Difusión ambiental",
			type = "toggle",
			default = true,
			action = function(value)
				game.Lighting.EnvironmentDiffuseScale = value and 1 or 0
			end
		},
		{
			id = "particles",
			label = "Partículas",
			desc = "Efectos de partículas",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "effects",
			label = "Efectos Especiales",
			desc = "Efectos visuales especiales",
			type = "toggle",
			default = true,
			action = function(value)
				for _, player in pairs(game.Players:GetPlayers()) do
					player:SetAttribute("SpecialEffects", value)
				end
			end
		},
	},
	
	alerts = {
		{
			id = "soundDiscord",
			label = "Sonido Discord",
			desc = "Notificación de Discord",
			type = "toggle",
			default = true,
			action = function(value)
				local MainSounds = game:GetService("SoundService"):FindFirstChild("MainSounds")
				if MainSounds and MainSounds:FindFirstChild("NDC") then
					MainSounds.NDC.Volume = value and 0.5 or 0
				end
			end
		},
		{
			id = "soundTwitter",
			label = "Sonido Twitter",
			desc = "Notificación de Twitter",
			type = "toggle",
			default = true,
			action = function(value)
				local MainSounds = game:GetService("SoundService"):FindFirstChild("MainSounds")
				if MainSounds and MainSounds:FindFirstChild("NX") then
					MainSounds.NX.Volume = value and 0.5 or 0
				end
			end
		},
		{
			id = "soundWhatsApp",
			label = "Sonido WhatsApp",
			desc = "Notificación de WhatsApp",
			type = "toggle",
			default = true,
			action = function(value)
				local MainSounds = game:GetService("SoundService"):FindFirstChild("MainSounds")
				if MainSounds and MainSounds:FindFirstChild("NWSP") then
					MainSounds.NWSP.Volume = value and 0.5 or 0
				end
			end
		},
	},
	
	credits = {
		{
			id = "credits_info",
			label = "Sistema de Modales",
			desc = "Creado por ignxts",
			type = "info"
		},
		{
			id = "credits_ui",
			label = "UI/UX",
			desc = "Diseño y estructura profesional",
			type = "info"
		},
		{
			id = "credits_clan",
			label = "Sistema de Clanes",
			desc = "Integración completa con DataStore",
			type = "info"
		},
		{
			id = "credits_music",
			label = "Sistema de Música",
			desc = "DJ Dashboard con virtualización",
			type = "info"
		},
	},
	
	comments = {
		{
			id = "comments_placeholder",
			label = "Sección de Comentarios",
			desc = "Próximamente: Sistema de feedback en vivo",
			type = "info"
		},
	},
}

return SettingsConfig
