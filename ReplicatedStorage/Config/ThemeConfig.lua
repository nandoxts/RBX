-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - PROFESSIONAL DARK
-- Paleta madura estilo Discord/Spotify
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Modern dark background palette (con tinte sutil de accent morado)
	bg       = Color3.fromRGB(24, 20, 38),      -- Fondo principal
	panel    = Color3.fromRGB(26, 24, 40),      -- Paneles
	head     = Color3.fromRGB(28, 25, 42),      -- Header
	card     = Color3.fromRGB(30, 27, 45),      -- Cards internas
	elevated = Color3.fromRGB(36, 29, 58),      -- Elementos elevados (hover)
	surface  = Color3.fromRGB(32, 28, 48),      -- Superficies interactivas

	-- Text colors
	text     = Color3.fromRGB(236, 240, 241),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(132, 142, 151),   -- Texto secundario
	subtle   = Color3.fromRGB(95, 100, 110),    -- Texto muy sutil

	-- Accent (purple)
	accent      = Color3.fromRGB(147, 76, 255),  -- Morado vibrante
	accentHover = Color3.fromRGB(186, 129, 255), -- Hover más claro

	-- Buttons
	warn       = Color3.fromRGB(255, 165, 80),   -- Orange
	warnMuted  = Color3.fromRGB(80, 40, 20),     -- Orange muted
	btnDanger  = Color3.fromRGB(222, 93, 119),   -- Soft red

	-- UI elements
	stroke = Color3.fromRGB(40, 44, 52),
	hover  = Color3.fromRGB(45, 50, 58),

	-- Transparencies (valores consolidados)
	opaqueAlpha    = 0,     -- Elementos sólidos
	subtleAlpha    = 0.1,   -- Muy poco transparente
	lightAlpha     = 0.2,   -- Ligeramente transparente
	frameAlpha     = 0.25,  -- Frames principales
	mediumAlpha    = 0.5,   -- Medio transparente
	heavyAlpha     = 0.85,  -- Muy transparente
	invisibleAlpha = 1,     -- Elementos invisibles

	-- Panel sizes
	panelWidth  = 650,
	panelHeight = 650,
}

return THEME