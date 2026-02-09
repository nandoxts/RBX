-- SERVICES
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- OBJECTS
local Clouds = workspace:WaitForChild("Terrain"):WaitForChild("Clouds")
local Atmosphere = Lighting:WaitForChild("Atmosphere")

-- CONFIG
local LIGHT_TAG = "Light"
local DAY_START = 6
local NIGHT_START = 20
local ADMINS = {"ignxts", "AngeloGarciia", "ignxts0"} -- Usuarios autorizados
local SPEED = 0.0009

-- ESTADO
local forceNightValue = ReplicatedStorage:FindFirstChild("ForceNight")
if not forceNightValue then
	forceNightValue = Instance.new("BoolValue")
	forceNightValue.Name = "ForceNight"
	forceNightValue.Value = false
	forceNightValue.Parent = ReplicatedStorage
end

local lunarModeValue = ReplicatedStorage:FindFirstChild("LunarMode")
if not lunarModeValue then
	lunarModeValue = Instance.new("BoolValue")
	lunarModeValue.Name = "LunarMode"
	lunarModeValue.Value = false
	lunarModeValue.Parent = ReplicatedStorage
end

-- Inicializar hora a mediodía si está en 0 (inicio)
if Lighting.ClockTime == 0 then
	Lighting.ClockTime = 12
end

local lastIsNight = nil
local lastTick = 0

local tweens = {}

local function isNightTime()
	return Lighting.ClockTime >= NIGHT_START or Lighting.ClockTime < DAY_START
end

local function tween(obj, props, time)
	if tweens[obj] then
		tweens[obj]:Cancel()
	end
	tweens[obj] = TweenService:Create(
		obj,
		TweenInfo.new(time or 15, Enum.EasingStyle.Quart),
		props
	)
	tweens[obj]:Play()
end

local function setLightColor(light, color, smooth)
	if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
		light.Enabled = true
		if smooth then
			tween(light, {Color = color})
		else
			light.Color = color
		end
	elseif light:IsA("Frame") then
		light.BackgroundColor3 = color
	end
end

local function setAllLights(color, smooth)
	for _, light in CollectionService:GetTagged(LIGHT_TAG) do
		setLightColor(light, color, smooth)
	end
end

local function turnOnLights()
	setAllLights(Color3.new(0,0,0), false)
	setAllLights(Color3.new(1,1,1), true)
end

local function turnOffLights()
	setAllLights(Color3.new(1,1,1), false)
	setAllLights(Color3.new(0,0,0), true)
end

local function updateAtmosphere()
	local time = Lighting.ClockTime

	if time >= 7.5 and time <= 16.5 then
		-- DÍA: Sin neblina
		tween(Atmosphere, {
			Color = Color3.fromRGB(200,224,255), 
			Decay = Color3.fromRGB(64,64,64),
			Haze = 0,
			Density = 0
		}, 30)
		tween(Clouds, {Color = Color3.fromRGB(160,160,160), Cover = 0.65}, 30)
		tween(Lighting, {ColorShift_Top = Color3.fromRGB(255,240,224)}, 30)

	elseif time > 16.5 and time <= 17.75 then
		-- ATARDECER: Sin neblina
		tween(Atmosphere, {
			Color = Color3.fromRGB(200,224,255), 
			Decay = Color3.fromRGB(200,144,96),
			Haze = 0,
			Density = 0
		}, 30)
		tween(Clouds, {Color = Color3.fromRGB(160,160,160), Cover = 0.65}, 30)
		tween(Lighting, {ColorShift_Top = Color3.fromRGB(255,192,128)}, 30)

	elseif time > 17.75 or time < 6 then
		-- NOCHE: Sin neblicna
		tween(Atmosphere, {
			Color = Color3.fromRGB(64,64,64), 
			Decay = Color3.fromRGB(0,0,0),
			Haze = 0,
			Density = 0
		}, 30)
		tween(Clouds, {Color = Color3.fromRGB(64,64,64), Cover = 0.55}, 30)
		tween(Lighting, {ColorShift_Top = Color3.fromRGB(255,255,255)}, 30)

	elseif time >= 6 and time <= 7.5 then
		-- AMANECER: Sin neblina
		tween(Atmosphere, {
			Color = Color3.fromRGB(200,224,255), 
			Decay = Color3.fromRGB(255,192,128),
			Haze = 0,
			Density = 0
		}, 30)
		tween(Clouds, {Color = Color3.fromRGB(96,96,96), Cover = 0.55}, 30)
		tween(Lighting, {ColorShift_Top = Color3.fromRGB(255,192,128)}, 30)
	end
end

-- Aplicar atmosfera inicial
updateAtmosphere()
if not isNightTime() then
	turnOffLights()
end

local function activateLunarMode()
	lunarModeValue.Value = true
	forceNightValue.Value = true

	-- Configuración espacial/galaxia - SIN NEBLINA
	Lighting.ClockTime = 0 -- Medianoche

	-- Atmósfera espacial con tonos morados/azules pero SIN NEBLINA
	tween(Atmosphere, {
		Color = Color3.fromRGB(75, 0, 130), -- Púrpura oscuro
		Decay = Color3.fromRGB(138, 43, 226), -- Violeta brillante
		Density = 0,
		Offset = 0.25,
		Glare = 0,
		Haze = 0
	}, 3)

	-- Nubes espaciales
	tween(Clouds, {
		Color = Color3.fromRGB(148, 0, 211), -- Violeta oscuro
		Cover = 0.55,
		Density = 0
	}, 3)

	-- Colores de iluminación espacial
	Lighting.ColorShift_Top = Color3.fromRGB(255, 0, 255) -- Magenta
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 100, 255) -- Azul espacial
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 50, 150) -- Ambiente púrpura

	-- Luces normales (no colores galácticos)
	for _, light in CollectionService:GetTagged(LIGHT_TAG) do
		if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
			light.Enabled = true
			light.Color = Color3.new(1, 1, 1) -- Blanco normal
		end
	end

	print("Modo lunar activado")
end

local function deactivateLunarMode()
	lunarModeValue.Value = false
	forceNightValue.Value = false
	lastIsNight = nil

	-- Restaurar propiedades de atmósfera a valores por defecto (SIN NEBLINA)
	tween(Atmosphere, {
		Density = 0,
		Offset = 0.25,
		Glare = 0,
		Haze = 0
	}, 3)

	-- Restaurar colores normales
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)

	-- Forzar actualización de atmósfera según hora actual
	updateAtmosphere()

	print("Ciclo dia/noche activado")
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastTick < 1 then return end
	local elapsed = now - lastTick
	lastTick = now

	-- Avanzar el tiempo solo en modo normal
	if not forceNightValue.Value and not lunarModeValue.Value then
		Lighting.ClockTime = Lighting.ClockTime + (SPEED * elapsed * 20)
		if Lighting.ClockTime >= 24 then
			Lighting.ClockTime = Lighting.ClockTime - 24
		end
	end

	-- Si está en modo lunar, no hacer nada (mantener efecto galáctico)
	if lunarModeValue.Value then
		-- Mantener luces galácticas siempre encendidas
		if lastIsNight ~= true then
			lastIsNight = true
		end
		return
	end

	-- Si está forzado en noche (modo /noche), mantener en hora nocturna
	if forceNightValue.Value then
		if Lighting.ClockTime ~= 0 then
			Lighting.ClockTime = 0 -- Medianoche
		end
		if lastIsNight ~= true then
			lastIsNight = true
			turnOnLights()
		end
		return
	end

	-- Modo normal: ciclo automático día/noche
	local night = isNightTime()
	if night ~= lastIsNight then
		lastIsNight = night
		if night then
			turnOnLights()
		else
			turnOffLights()
		end
	end

	updateAtmosphere()
end)

-- NEW LIGHTS
CollectionService:GetInstanceAddedSignal(LIGHT_TAG):Connect(function(light)
	if lunarModeValue.Value then
		-- Modo lunar: luces blancas normales
		if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
			light.Enabled = true
			light.Color = Color3.new(1, 1, 1)
		end
	elseif isNightTime() or forceNightValue.Value then
		setLightColor(light, Color3.new(1,1,1), false)
	else
		setLightColor(light, Color3.new(0,0,0), false)
	end
end)

-- COMANDOS DE CHAT
local function setupCommands(player)
	-- Verificar si el jugador está en la lista de admins
	local isAdmin = false
	for _, adminName in ipairs(ADMINS) do
		if player.Name == adminName then
			isAdmin = true
			break
		end
	end

	if not isAdmin then return end

	player.Chatted:Connect(function(message)
		local cmd = string.lower(message)

		if cmd == "/lunar" then
			-- Activar modo lunar/galaxy
			activateLunarMode()

		elseif cmd == "/noche" then
			-- Modo noche estática (sin ciclo, sin efectos especiales, sin neblina)
			-- Primero, desactivar cualquier modo especial activo
			if lunarModeValue.Value then
				deactivateLunarMode()
			end

			forceNightValue.Value = true
			lastIsNight = true
			Lighting.ClockTime = 0

			-- Aplicar atmósfera nocturna normal SIN NEBLINA
			tween(Atmosphere, {
				Color = Color3.fromRGB(64,64,64),
				Decay = Color3.fromRGB(0,0,0),
				Density = 0,
				Offset = 0.25,
				Glare = 0,
				Haze = 0
			}, 3)
			tween(Clouds, {
				Color = Color3.fromRGB(64,64,64),
				Cover = 0.55,
				Density = 0
			}, 3)
			Lighting.ColorShift_Top = Color3.fromRGB(255,255,255)
			Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)

			turnOnLights()
			print("Modo noche activado")

		elseif cmd == "/normal" then
			-- Volver al ciclo automático día/noche - resetear TODO
			deactivateLunarMode()
		end
	end)
end

-- Conectar comandos para jugadores existentes y nuevos
for _, player in Players:GetPlayers() do
	setupCommands(player)
end

Players.PlayerAdded:Connect(setupCommands)


