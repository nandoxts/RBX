--[[
	SETTINGS CONFIG - Configuración centralizada de Settings
		label = [[¡Gracias por ser parte de esta gran familia!
]]

local SettingsConfig = {}

-- ============================================
-- INICIALES (DEFAULTS)
	--[[ Comentado temporalmente: sección de comentarios
	{
		id = "comments",
		title = "COMENTARIOS",
		icon = "💬",
		order = 5,
	},
	]]
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
		title = "NOTIFICACIONES",
		icon = "🔔",
		order = 3
	},
	{
		id = "credits",
		title = "CRÉDITOS",
		icon = "⭐",
		order = 4
	},
	-- comentarios está temporalmente deshabilitado
}

-- ============================================
-- SETTINGS POR TAB
-- ============================================
SettingsConfig.SETTINGS = {
	gameplay = {
		{
			id = "chat",
			label = "Burbujas de chat",
			desc = "Mostrar burbujas de chat de otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				game.Chat.BubbleChatEnabled = value
			end
		},
		{
			id = "viewTagsUsers",
			label = "Etiquetas de jugadores",
			desc = "Mostrar etiquetas sobre otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "viewUsers",
			label = "Mostrar jugadores",
			desc = "Mostrar u ocultar otros jugadores",
			type = "toggle",
			default = true,
			action = function(value)
				-- Manejado en cliente
			end
		},
		{
			id = "viewFlagUser",
			label = "Mostrar mi bandera",
			desc = "Mostrar tu bandera de país",
			type = "toggle",
			default = false,
			action = function(value)
				-- Manejado en servidor
			end
		},
		{
			id = "viewSelected",
			label = "Resaltar seleccionado",
			desc = "Mostrar un cuadro al seleccionar jugadores",
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
			desc = "Efecto de atmósfera / niebla",
			type = "toggle",
			default = true,
			action = function(value)
				game.Lighting.Atmosphere.Density = value and 0.3 or 0
			end
		},
		{
			id = "blur",
			label = "Desenfoque",
			desc = "Desenfoque de profundidad (Depth of Field)",
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
			desc = "Activar nubes en el terreno",
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
			desc = "Activar sombras globales",
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
			label = "Difusión ambiental",
			desc = "Escala de difusión ambiental",
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
			label = "Efectos especiales",
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
			label = "Notificaciones: Discord",
			desc = "Reproducir sonido de notificación de Discord",
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
			label = "Notificaciones: Twitter",
			desc = "Reproducir sonido de notificación de Twitter",
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
			label = "Notificaciones: WhatsApp",
			desc = "Reproducir sonido de notificación de WhatsApp",
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
			id = "credits_title",
			label = "Créditos",
			type = "credit"
		},
		{
			id = "credits_text",
			label = "¡Gracias por ser parte de Ritmo Latino! 💜🎶 A cada persona que entra, participa, baila y comparte buena vibra: gracias de corazón. Su apoyo, sus ideas y su energía han sido clave para que este servidor crezca y se sienta como casa. Ritmo Latino no sería lo mismo sin ustedes. ✨ ¡Sigamos construyendo juntos más momentos, música y comunidad! 🕺💃",
			type = "credit"
		},
		{
			id = "credits_devs",
			label = "Developers",
			desc = "xlm_brem | ignxts",
			type = "credit"
		},
	},
	
	--[[ Comentado temporalmente: settings de comentarios
	comments = {
		{
			id = "comments_placeholder",
			label = "Sección de Comentarios",
			desc = "Próximamente: Sistema de feedback en vivo",
			type = "info"
		},
	},
	]]
}

return SettingsConfig
