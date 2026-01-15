-- ColorEffectsModule.lua
local module = {}

module.defaultSelectedColor = Color3.new(1, 1, 1)

module.colors = {
	-- PERSONALIZADOS
	panda = Color3.new(0.529412, 0.384314, 1),
	-- Rojos
	rojo = Color3.new(1, 0, 0),
	carmesi = Color3.new(0.59, 0, 0),
	escarlata = Color3.new(1, 0.14, 0),
	bermellon = Color3.new(0.85, 0.22, 0.12),
	rojooscuro = Color3.new(0.55, 0, 0),
	rubi = Color3.new(0.88, 0.07, 0.37),
	rojocereza = Color3.new(0.87, 0.19, 0.39),
	rojopasion = Color3.new(0.9, 0, 0.3),
	rojotormenta = Color3.new(0.8, 0.2, 0.2),
	rojovino = Color3.new(0.45, 0, 0.15),

	-- Azules
	azul = Color3.new(0, 0, 1),
	azulmarino = Color3.new(0, 0, 0.5),
	azulreal = Color3.new(0, 0.25, 0.5),
	azulceleste = Color3.new(0.35, 0.7, 0.9),
	azulacero = Color3.new(0.27, 0.51, 0.71),
	azulpolvo = Color3.new(0.42, 0.6, 0.8),
	azulnavy = Color3.new(0, 0, 0.4),
	azulhielo = Color3.new(0.84, 0.97, 1),
	azulultramar = Color3.new(0.07, 0.04, 0.56),
	azulzaffre = Color3.new(0, 0.08, 0.66),

	-- Verdes
	verde = Color3.new(0, 1, 0),
	verdeoscuro = Color3.new(0, 0.39, 0),
	verdebosque = Color3.new(0.13, 0.55, 0.13),
	verdeesmeralda = Color3.new(0.08, 0.8, 0.52),
	verdejade = Color3.new(0, 0.66, 0.42),
	verdeoliva = Color3.new(0.5, 0.5, 0),
	verdelimon = Color3.new(0.75, 1, 0),
	verdespring = Color3.new(0, 1, 0.5),
	verdementa = Color3.new(0.6, 1, 0.8),
	verdesapito = Color3.new(0.44, 0.84, 0.36),

	-- Amarillos
	amarillo = Color3.new(1, 1, 0),
	amarillocanario = Color3.new(1, 1, 0.4),
	amarillomaiz = Color3.new(0.98, 0.93, 0.36),
	amarillooro = Color3.new(1, 0.84, 0),
	amarillomostaza = Color3.new(1, 0.86, 0.35),
	amarillolimon = Color3.new(0.89, 1, 0.11),
	amarillocremoso = Color3.new(1, 1, 0.71),
	amarillomiel = Color3.new(0.96, 0.87, 0.37),
	amarillosol = Color3.new(1, 0.95, 0.3),
	amarillotaxi = Color3.new(0.98, 0.85, 0.11),

	-- Naranjas
	naranja = Color3.new(1, 0.5, 0),
	naranjaoscuro = Color3.new(1, 0.55, 0),
	naranjacalabaza = Color3.new(1, 0.46, 0.09),
	naranjasalmon = Color3.new(0.98, 0.5, 0.45),
	naranjamecanico = Color3.new(0.9, 0.4, 0),
	naranjapeach = Color3.new(1, 0.8, 0.64),
	naranjaapricot = Color3.new(0.98, 0.81, 0.69),
	naranjaburnt = Color3.new(0.8, 0.33, 0),
	naranjacoral = Color3.new(1, 0.5, 0.31),
	naranjaterracota = Color3.new(0.89, 0.45, 0.36),

	-- Morados/Violetas
	morado = Color3.new(0.5, 0, 0.5),
	violeta = Color3.new(0.56, 0, 1),
	lavanda = Color3.new(0.71, 0.49, 0.86),
	lila = Color3.new(0.78, 0.64, 0.78),
	uva = Color3.new(0.28, 0.15, 0.34),
	ciruela = Color3.new(0.56, 0.27, 0.52),
	berenjena = Color3.new(0.38, 0.25, 0.32),
	amatista = Color3.new(0.6, 0.4, 0.8),
	orquidea = Color3.new(0.85, 0.44, 0.84),
	purpura = Color3.new(0.63, 0.13, 0.94),

	-- Rosas
	rosa = Color3.new(1, 0.41, 0.71),
	rosapastel = Color3.new(1, 0.71, 0.76),
	rosachicle = Color3.new(0.97, 0.52, 0.75),
	rosafucsia = Color3.new(1, 0, 0.5),
	rosabrillante = Color3.new(1, 0.08, 0.58),
	rosabebe = Color3.new(0.96, 0.76, 0.86),
	rosadragon = Color3.new(1, 0.53, 0.81),
	rosamagenta = Color3.new(0.98, 0.5, 0.91),
	rosashocking = Color3.new(0.99, 0.06, 0.75),
	rosacarmin = Color3.new(0.92, 0.3, 0.54),

	-- Marrones
	marron = Color3.new(0.65, 0.16, 0.16),
	marronclaro = Color3.new(0.68, 0.5, 0.36),
	marronoscuro = Color3.new(0.4, 0.26, 0.13),
	cafe = Color3.new(0.44, 0.31, 0.22),
	chocolate = Color3.new(0.48, 0.25, 0),
	canela = Color3.new(0.82, 0.41, 0.12),
	caramelo = Color3.new(0.86, 0.58, 0.29),
	avellana = Color3.new(0.75, 0.56, 0.33),
	bronceado = Color3.new(0.82, 0.71, 0.55),
	sepia = Color3.new(0.44, 0.26, 0.08),

	-- Grises
	gris = Color3.new(0.5, 0.5, 0.5),
	grisclaro = Color3.new(0.75, 0.75, 0.75),
	grisoscuro = Color3.new(0.25, 0.25, 0.25),
	grisplata = Color3.new(0.75, 0.75, 0.75),
	grisacero = Color3.new(0.69, 0.77, 0.87),
	grispizarra = Color3.new(0.44, 0.5, 0.56),
	grisgrano = Color3.new(0.6, 0.6, 0.6),
	grisniebla = Color3.new(0.8, 0.8, 0.8),
	grisferro = Color3.new(0.3, 0.3, 0.3),
	grisperla = Color3.new(0.92, 0.92, 0.92),

	-- Blancos
	blanco = Color3.new(1, 1, 1),
	blancopuro = Color3.new(1, 1, 1),
	blancocrema = Color3.new(1, 0.99, 0.96),
	blancoperla = Color3.new(0.94, 0.92, 0.84),
	blancohueso = Color3.new(0.96, 0.96, 0.86),
	blancohumo = Color3.new(0.96, 0.96, 0.96),
	blancoghost = Color3.new(0.97, 0.97, 0.97),
	blancolino = Color3.new(0.98, 0.98, 0.94),
	blancofloral = Color3.new(1, 0.98, 0.98),
	blanconieve = Color3.new(0.96, 0.98, 1),

	-- Negros
	negro = Color3.new(0, 0, 0),
	negropuro = Color3.new(0, 0, 0),
	negroazabache = Color3.new(0.04, 0.04, 0.04),
	negrocarbon = Color3.new(0.11, 0.11, 0.11),
	negroebano = Color3.new(0.08, 0.08, 0.08),
	negroraiz = Color3.new(0.15, 0.13, 0.13),
	negrojet = Color3.new(0.2, 0.2, 0.2),
	negrolicorice = Color3.new(0.1, 0.07, 0.07),
	negromarte = Color3.new(0.13, 0.13, 0.13),
	negronoche = Color3.new(0.05, 0.05, 0.05),

	-- Metálicos
	dorado = Color3.new(1, 0.84, 0),
	plata = Color3.new(0.75, 0.75, 0.75),
	bronce = Color3.new(0.8, 0.5, 0.2),
	cobre = Color3.new(0.72, 0.45, 0.2),
	acero = Color3.new(0.45, 0.5, 0.55),
	titanio = Color3.new(0.6, 0.6, 0.6),
	hierro = Color3.new(0.36, 0.36, 0.36),
	mercurio = Color3.new(0.88, 0.88, 0.88),
	platino = Color3.new(0.9, 0.89, 0.89),
	laton = Color3.new(0.88, 0.76, 0.5),

	-- Pasteles
	pastelrosa = Color3.new(1, 0.71, 0.76),
	pastelazul = Color3.new(0.68, 0.85, 0.9),
	pastelverde = Color3.new(0.47, 0.87, 0.47),
	pastelamarillo = Color3.new(1, 1, 0.71),
	pastelmorado = Color3.new(0.81, 0.69, 1),
	pastelnaranja = Color3.new(1, 0.8, 0.6),
	pastelmenta = Color3.new(0.7, 1, 0.9),
	pastelmelocoton = Color3.new(1, 0.89, 0.81),
	pastellavanda = Color3.new(0.9, 0.9, 1),
	pastelceleste = Color3.new(0.7, 0.8, 1),

	-- Neón
	neonrosa = Color3.new(1, 0.08, 0.58),
	neonazul = Color3.new(0.13, 0.67, 1),
	neonverde = Color3.new(0.11, 1, 0.11),
	neonamarillo = Color3.new(0.89, 1, 0.11),
	neonmorado = Color3.new(0.76, 0.15, 0.99),
	neonnaranja = Color3.new(1, 0.42, 0.11),
	neoncyan = Color3.new(0.13, 1, 0.94),
	neonlima = Color3.new(0.65, 1, 0.16),
	neonrojo = Color3.new(1, 0.16, 0.22),
	neonfucsia = Color3.new(1, 0.02, 0.66),

	-- Naturales
	cieloazul = Color3.new(0.53, 0.81, 0.92),
	hojaverde = Color3.new(0.13, 0.55, 0.13),
	arena = Color3.new(0.94, 0.9, 0.55),
	oceano = Color3.new(0, 0.34, 0.68),
	tierra = Color3.new(0.44, 0.31, 0.22),
	piedra = Color3.new(0.67, 0.65, 0.62),
	musgo = Color3.new(0.38, 0.49, 0.33),
	corteza = Color3.new(0.38, 0.29, 0.22),
	atardecer = Color3.new(0.98, 0.51, 0.27),
	amanecer = Color3.new(1, 0.6, 0.5),

	-- Especiales
	arcoiris = Color3.new(1, 0, 0), -- Cambiar dinámicamente
	lava = Color3.new(0.81, 0.06, 0.13),
	fuego = Color3.new(1, 0.35, 0.15),
	electrico = Color3.new(0.49, 0.98, 1),
	hielo = Color3.new(0.84, 1, 1),
	veneno = Color3.new(0.64, 0.24, 0.96),
	sangre = Color3.new(0.65, 0.05, 0.07),
	oscuridad = Color3.new(0.02, 0.01, 0.1),
	mistico = Color3.new(0.7, 0.4, 0.9),
	galaxia = Color3.new(0.15, 0.05, 0.3),

	-- Nombres creativos/fantasia
	dragonfire = Color3.new(0.9, 0.3, 0.1),
	elfogreen = Color3.new(0.22, 0.8, 0.44),
	unicornmagic = Color3.new(0.9, 0.6, 1),
	fairydust = Color3.new(1, 0.82, 0.98),
	wizardpurple = Color3.new(0.4, 0.2, 0.6),
	mermaidteal = Color3.new(0.3, 0.8, 0.7),
	phoenixorange = Color3.new(1, 0.45, 0.15),
	werewolfgrey = Color3.new(0.4, 0.4, 0.45),
	vampireblood = Color3.new(0.5, 0, 0.1),
	pixiewings = Color3.new(0.8, 0.95, 1),
	
	-- Faltantes de colores básicos
	turquesa = Color3.new(0.25, 0.88, 0.82),

	-- Faltantes de colores RGB/CMYK
	cyan = Color3.new(0, 1, 1),
	magenta = Color3.new(1, 0, 1),
	limon = Color3.new(0.75, 1, 0),
	zafiro = Color3.new(0.06, 0.32, 0.73),

	-- Faltantes de colores especiales
	vino = Color3.new(0.45, 0, 0.15),
	menta = Color3.new(0.6, 1, 0.8),

	-- Faltantes de más colores
	oliva = Color3.new(0.5, 0.5, 0),

	-- Faltantes de colores adicionales
	beige = Color3.new(0.96, 0.96, 0.86),
	granate = Color3.new(0.5, 0, 0),
	teal = Color3.new(0, 0.5, 0.5),

	-- Faltantes de últimos colores
	caqui = Color3.new(0.76, 0.69, 0.57),
	borgona = Color3.new(0.53, 0.15, 0.34),
	chartreuse = Color3.new(0.5, 1, 0)
}

return module