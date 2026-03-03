-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - PROFESSIONAL DARK
-- Paleta madura estilo Discord/Spotify
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Modern dark background palette (Neutro oscuro, sin tinte morado)
	deep     = Color3.fromRGB(16, 16, 20),      -- Fondo profundo (sidebar/columns)
	bg       = Color3.fromRGB(20, 20, 22),      -- Fondo principal
	panel    = Color3.fromRGB(24, 24, 27),      -- Paneles
	head     = Color3.fromRGB(26, 26, 30),      -- Header
	card     = Color3.fromRGB(28, 28, 32),      -- Cards internas
	elevated = Color3.fromRGB(35, 35, 40),      -- Elementos elevados (hover) - Gris neutro
	surface  = Color3.fromRGB(30, 30, 35),      -- Superficies interactivas

	-- Text colors
	text     = Color3.fromRGB(236, 240, 241),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(132, 142, 151),   -- Texto secundario
	subtle   = Color3.fromRGB(95, 100, 110),    -- Texto muy sutil

	-- Accent (purple)
	accent      = Color3.fromRGB(147, 76, 255),  -- Morado vibrante
	accentHover = Color3.fromRGB(186, 129, 255), -- Hover más claro

	-- Buttons
	warn       = Color3.fromRGB(251, 140, 0),    -- Orange suave
	warnMuted  = Color3.fromRGB(88, 56, 20),     -- Orange muted más oscuro
	btnDanger  = Color3.fromRGB(229, 57, 53),    -- Rojo profundo
	success    = Color3.fromRGB(76, 175, 80),    -- Verde suave (Spotify-like)

	-- UI elements
	stroke = Color3.fromRGB(40, 44, 52),
	hover  = Color3.fromRGB(45, 50, 58),

	-- Transparencies (valores consolidados)
	opaqueAlpha    = 0,     -- Elementos sólidos
	subtleAlpha    = 0.1,   -- Muy poco transparente
	lightAlpha     = 0.3,   -- Ligeramente transparente
	frameAlpha     = 0.4,  -- Frames principales
	mediumAlpha    = 0.6,   -- Medio transparente
	heavyAlpha     = 0.8,  -- Muy transparente
	invisibleAlpha = 1,     -- Elementos invisibles

	-- Panel sizes
	panelWidth  = 650,
	panelHeight = 650,
}

return THEME