-- ════════════════════════════════════════════════════════════════
--  TitleConfig  |  ReplicatedStorage/Config/TitleConfig
--  Fuente única para el shop, el overhead y el chat.
--
--  id         → clave interna (única, sin espacios)
--  gamepassId → ID real del gamepass en Roblox  (0 = dev/gratis)
--  name       → texto de la card en la tienda
--  label      → texto que aparece en overhead y chat  ej: "[ LEYENDA ]"
--  color      → hex del título
--  price      → precio en Robux (solo referencia en la card)
--  icon       → rbxassetid del icono de la card
--  fondo      → rbxassetid del fondo de la card
-- ════════════════════════════════════════════════════════════════
return {
	{
		id         = "novato",
		gamepassId = 0,                   -- ← pon el ID real aquí
		name       = "NOVATO",
		label      = "[ NOVATO ]",
		color      = "#A0A0A0",
		price      = 50,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
	{
		id         = "veterano",
		gamepassId = 0,
		name       = "VETERANO",
		label      = "[ VETERANO ]",
		color      = "#00AAFF",
		price      = 100,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
	{
		id         = "leyenda",
		gamepassId = 0,
		name       = "LEYENDA",
		label      = "[ LEYENDA ]",
		color      = "#FF8C00",
		price      = 250,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
	{
		id         = "elite",
		gamepassId = 0,
		name       = "ELITE",
		label      = "[ ELITE ]",
		color      = "#FF4040",
		price      = 500,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
	{
		id         = "diamante",
		gamepassId = 0,
		name       = "DIAMANTE",
		label      = "[ DIAMANTE ]",
		color      = "#40CFFF",
		price      = 750,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
	{
		id         = "supremo",
		gamepassId = 0,
		name       = "SUPREMO",
		label      = "[ SUPREMO ]",
		color      = "#FFD700",
		price      = 1000,
		icon       = "103185544418844",
		fondo      = "103185544418844",
	},
}
