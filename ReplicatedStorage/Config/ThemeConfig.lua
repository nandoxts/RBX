-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - PROFESSIONAL DARK
-- Paleta madura estilo Discord/Spotify
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- ══════════════════════════════════════════════════════════════
	-- FONDOS - Escala de grises más rica
	-- ══════════════════════════════════════════════════════════════
	bg       = Color3.fromRGB(17, 17, 19),      -- Fondo principal
	panel    = Color3.fromRGB(22, 22, 27),      -- Panel modal
	head     = Color3.fromRGB(18, 18, 22),      -- Header más oscuro que panel
	card     = Color3.fromRGB(30, 30, 36),      -- Cards internas
	elevated = Color3.fromRGB(38, 38, 45),      -- Elementos elevados
	surface  = Color3.fromRGB(45, 45, 52),      -- Superficies interactivas

	-- ══════════════════════════════════════════════════════════════
	-- TEXTOS
	-- ══════════════════════════════════════════════════════════════
	text     = Color3.fromRGB(240, 240, 245),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(120, 120, 135),   -- Texto secundario
	subtle   = Color3.fromRGB(85, 85, 100),     -- Texto muy sutil

	-- ══════════════════════════════════════════════════════════════
	-- ACENTO PRINCIPAL - Azul sofisticado (menos saturado)
	-- ══════════════════════════════════════════════════════════════
	accent      = Color3.fromRGB(41, 44, 211),    -- Indigo elegante
	accentHover = Color3.fromRGB(76, 90, 218),   -- Hover más claro
	accentMuted = Color3.fromRGB(55, 58, 95),      -- Versión apagada para fondos

	-- ══════════════════════════════════════════════════════════════
	-- BOTONES - Estilo neutral profesional
	-- ══════════════════════════════════════════════════════════════
	btnPrimary      = Color3.fromRGB(55, 55, 65),     -- Gris oscuro elegante
	btnPrimaryHover = Color3.fromRGB(70, 70, 82),     -- Hover sutil
	btnSecondary    = Color3.fromRGB(40, 40, 48),     -- Botón secundario
	btnDanger       = Color3.fromRGB(180, 60, 60),    -- Rojo apagado
	btnDangerHover  = Color3.fromRGB(200, 80, 80),
	-- Alias históricos usados por UI scripts
	danger          = Color3.fromRGB(194, 48, 48),

	-- ══════════════════════════════════════════════════════════════
	-- ESTADOS - Colores funcionales (menos saturados)
	-- ══════════════════════════════════════════════════════════════
	success     = Color3.fromRGB(12, 196, 61),     -- Verde Google (menos neón)
	successMuted= Color3.fromRGB(35, 75, 45),      -- Fondo verde
	warn        = Color3.fromRGB(220, 95, 95),     -- Rojo suave
	warnMuted   = Color3.fromRGB(75, 40, 40),
	info        = Color3.fromRGB(66, 133, 244),    -- Azul info
	infoMuted   = Color3.fromRGB(35, 55, 85),

	-- ══════════════════════════════════════════════════════════════
	-- ELEMENTOS UI
	-- ══════════════════════════════════════════════════════════════
	stroke      = Color3.fromRGB(50, 50, 60),     -- Bordes sutiles
	strokeLight = Color3.fromRGB(65, 65, 78),     -- Borde más visible
	divider     = Color3.fromRGB(40, 40, 48),     -- Separadores
	hover       = Color3.fromRGB(70, 70, 82),     -- Color para estados hover

	-- ══════════════════════════════════════════════════════════════
	-- AVATAR RING - Para el borde del avatar
	-- ══════════════════════════════════════════════════════════════
	avatarRing     = Color3.fromRGB(99, 102, 241),  -- Mismo que accent
	avatarRingGlow = Color3.fromRGB(99, 102, 241),

	-- ══════════════════════════════════════════════════════════════
	-- TRANSPARENCIAS RECOMENDADAS
	-- ══════════════════════════════════════════════════════════════
	overlayAlpha = 0.6,   -- Para fondos semi-transparentes
	hoverAlpha   = 0.08,  -- Para efectos hover sutiles

	-- ══════════════════════════════════════════════════════════════
	-- TAMAÑOS DE PANEL - Consistencia entre dashboards
	-- ══════════════════════════════════════════════════════════════
	panelWidth  = 550,    -- Ancho principal de dashboards
	panelHeight = 650,    -- Alto principal de dashboards
}

return THEME