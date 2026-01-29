-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - PROFESSIONAL DARK
-- Paleta madura estilo Discord/Spotify
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Modern dark background palette
	bg       = Color3.fromRGB(13, 15, 19),      -- Fondo principal (más profundo)
	panel    = Color3.fromRGB(18, 21, 26),      -- Paneles
	head     = Color3.fromRGB(20, 23, 28),      -- Header
	card     = Color3.fromRGB(22, 25, 31),      -- Cards internas
	elevated = Color3.fromRGB(32, 35, 43),      -- Elementos elevados
	surface  = Color3.fromRGB(26, 30, 36),      -- Superficies interactivas

	-- Text colors
	text     = Color3.fromRGB(236, 240, 241),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(132, 142, 151),   -- Texto secundario
	subtle   = Color3.fromRGB(95, 100, 110),    -- Texto muy sutil

	-- Accent (purple)
	accent      = Color3.fromRGB(147, 76, 255),  -- Morado vibrante
	accentHover = Color3.fromRGB(186, 129, 255), -- Hover más claro
	accentMuted = Color3.fromRGB(65, 18, 75),    -- Versión apagada

	-- Buttons
	btnPrimary      = Color3.fromRGB(124, 58, 237), -- Primary purple
	btnPrimaryHover = Color3.fromRGB(165, 115, 255),
	btnSecondary    = Color3.fromRGB(36, 40, 46),   -- Neutral secondary
	btnDanger       = Color3.fromRGB(222, 93, 119), -- Soft red
	btnDangerHover  = Color3.fromRGB(235, 110, 135),
	-- Alias historic
	danger          = Color3.fromRGB(222, 93, 119),

	-- States
	success      = Color3.fromRGB(88, 230, 140),   -- Green
	successMuted = Color3.fromRGB(28, 80, 40),
	warn         = Color3.fromRGB(255, 165, 80),   -- Orange
	warnMuted    = Color3.fromRGB(80, 40, 20),
	info         = Color3.fromRGB(90, 200, 250),   -- Cyan-ish info
	infoMuted    = Color3.fromRGB(30, 65, 85),

	-- UI elements
	stroke      = Color3.fromRGB(40, 44, 52),
	strokeLight = Color3.fromRGB(60, 66, 78),
	divider     = Color3.fromRGB(36, 40, 46),
	hover       = Color3.fromRGB(45, 50, 58),

	-- Avatar ring
	avatarRing     = Color3.fromRGB(147, 76, 255),
	avatarRingGlow = Color3.fromRGB(186, 129, 255),

	-- Transparencies
	overlayAlpha = 0.5,
	hoverAlpha   = 0.06,

	-- Panel sizes
	panelWidth  = 650,
	panelHeight = 650,
}

return THEME