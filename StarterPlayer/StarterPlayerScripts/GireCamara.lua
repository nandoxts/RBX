local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local rotateEvent = eventsFolder:WaitForChild("RotateEffectEvent")

-- ══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL EFECTO
-- ══════════════════════════════════════════════════════════════════════════════

local CONFIG = {
	-- Duración
	effectDuration = 10,

	-- Cámara orbital
	orbitDistance = 12,
	orbitHeight = 4,
	mouseSensitivity = 0.5,
	smoothness = 0.12,

	-- Velocidad de rotación automática por fases
	autoRotateSpeeds = {
		{time = 0, speed = 0.3},
		{time = 4, speed = 1.5},
		{time = 7, speed = 3},
		{time = 9, speed = 6},
	},

	-- Colores
	hueSpeed = 0.008,
	saturation = 0.9,
	brightness = 1.1,

	-- Beat/Pulso
	beatFrequency = 2.5,
	beatAmplitude = 1.5,
	fovBeatAmplitude = 8,
	baseFOV = 70,

	-- Shake
	shakeIntensity = 0.3,

	-- Final épico
	finalShakeDuration = 0.5,
	finalShakeIntensity = 2,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ══════════════════════════════════════════════════════════════════════════════

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function createEffect(className, name, props)
	local effect = Lighting:FindFirstChild(name)
	if not effect then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	for prop, value in pairs(props or {}) do
		effect[prop] = value
	end
	return effect
end

local function shake(intensity)
	return Vector3.new(
		(math.random() - 0.5) * 2 * intensity,
		(math.random() - 0.5) * 2 * intensity,
		(math.random() - 0.5) * 2 * intensity
	)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EFECTO PRINCIPAL
-- ══════════════════════════════════════════════════════════════════════════════

local function startRotateEffect()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Guardar estados originales
	local originalCameraType = camera.CameraType
	local originalFOV = camera.FieldOfView

	-- Configurar cámara
	camera.CameraType = Enum.CameraType.Scriptable

	-- ═══════════════════════════════════════════════════════════════════════
	-- MOUSE LIBRE Y VISIBLE
	-- ═══════════════════════════════════════════════════════════════════════
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	-- Variables de órbita
	local orbitAngleX = 0
	local orbitAngleY = 0.3
	local targetAngleX = 0
	local targetAngleY = 0.3
	local autoRotateAngle = 0

	-- Control de mouse (clic derecho + arrastrar)
	local isDragging = false
	local lastMousePos = Vector2.new(0, 0)
	local manualControl = false
	local manualControlTimer = 0

	-- Crear efectos visuales
	local colorCorrection = createEffect("ColorCorrectionEffect", "RotateColorEffect", {
		Brightness = 0,
		Contrast = 0.1,
		Saturation = 0
	})

	local bloom = createEffect("BloomEffect", "RotateBloomEffect", {
		Intensity = 0.5,
		Size = 24,
		Threshold = 0.8
	})

	local blur = createEffect("BlurEffect", "RotateBlurEffect", {
		Size = 0
	})

	-- ═══════════════════════════════════════════════════════════════════════
	-- INPUT: Clic derecho para rotar cámara manualmente
	-- ═══════════════════════════════════════════════════════════════════════
	local connections = {}

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isDragging = true
			lastMousePos = UserInputService:GetMouseLocation()
			manualControl = true
			manualControlTimer = 2 -- Segundos de control manual después de soltar
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isDragging = false
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local currentPos = UserInputService:GetMouseLocation()
			local delta = currentPos - lastMousePos

			targetAngleX = targetAngleX - delta.X * CONFIG.mouseSensitivity * 0.01
			targetAngleY = math.clamp(
				targetAngleY + delta.Y * CONFIG.mouseSensitivity * 0.01,
				-0.5,
				1.2
			)

			lastMousePos = currentPos
		end
	end))

	local startTime = tick()
	local hue = 0
	local running = true

	-- ══════════════════════════════════════════════════════════════════════════
	-- LOOP PRINCIPAL
	-- ══════════════════════════════════════════════════════════════════════════

	while running do
		local now = tick()
		local elapsed = now - startTime
		local dt = RunService.RenderStepped:Wait()

		-- Mantener mouse libre siempre
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true

		if elapsed > CONFIG.effectDuration then
			running = false
			break
		end

		-- Timer de control manual
		if manualControl and not isDragging then
			manualControlTimer = manualControlTimer - dt
			if manualControlTimer <= 0 then
				manualControl = false
			end
		end

		-- Obtener velocidad de rotación automática según fase
		local autoSpeed = CONFIG.autoRotateSpeeds[1].speed
		for _, phase in ipairs(CONFIG.autoRotateSpeeds) do
			if elapsed >= phase.time then
				autoSpeed = phase.speed
			end
		end

		-- Rotación automática (solo si no hay control manual)
		if not manualControl then
			autoRotateAngle = autoRotateAngle + autoSpeed * dt
			targetAngleX = autoRotateAngle
		else
			-- Sincronizar auto rotate con posición manual
			autoRotateAngle = targetAngleX
		end

		-- Suavizar movimiento
		orbitAngleX = lerp(orbitAngleX, targetAngleX, CONFIG.smoothness)
		orbitAngleY = lerp(orbitAngleY, targetAngleY, CONFIG.smoothness)

		-- Calcular posición orbital
		local beat = math.sin(elapsed * math.pi * 2 * CONFIG.beatFrequency)
		local currentDistance = CONFIG.orbitDistance + beat * CONFIG.beatAmplitude

		local horizontalDistance = currentDistance * math.cos(orbitAngleY)
		local verticalOffset = currentDistance * math.sin(orbitAngleY) + CONFIG.orbitHeight

		local offsetX = horizontalDistance * math.sin(orbitAngleX)
		local offsetZ = horizontalDistance * math.cos(orbitAngleX)

		local targetPos = rootPart.Position
		local cameraPos = targetPos + Vector3.new(offsetX, verticalOffset, offsetZ)

		-- Shake progresivo
		local progress = elapsed / CONFIG.effectDuration
		local currentShake = shake(CONFIG.shakeIntensity * progress * 2)
		cameraPos = cameraPos + currentShake

		-- Aplicar cámara
		camera.CFrame = CFrame.new(cameraPos, targetPos + Vector3.new(0, 2, 0))

		-- FOV con beat
		camera.FieldOfView = CONFIG.baseFOV + beat * CONFIG.fovBeatAmplitude * (1 + progress)

		-- Colores
		hue = (hue + CONFIG.hueSpeed) % 1
		local color = Color3.fromHSV(hue, CONFIG.saturation, CONFIG.brightness)

		colorCorrection.TintColor = color
		colorCorrection.Saturation = CONFIG.saturation * (0.5 + progress * 0.5)
		colorCorrection.Contrast = 0.1 + progress * 0.15

		-- Bloom aumenta con el tiempo
		bloom.Intensity = 0.5 + progress * 1
		bloom.Size = 24 + progress * 20

		-- Blur en velocidad alta
		blur.Size = progress * 6
	end

	-- ══════════════════════════════════════════════════════════════════════════
	-- FINAL ÉPICO
	-- ══════════════════════════════════════════════════════════════════════════

	-- Desconectar inputs
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end

	-- FASE 1: Flash blanco instantáneo
	local flash = createEffect("ColorCorrectionEffect", "FinalFlash", {
		Brightness = 3,
		Contrast = 1,
		Saturation = -1,
		TintColor = Color3.new(1, 1, 1)
	})

	bloom.Intensity = 3
	bloom.Size = 56
	blur.Size = 24

	-- FASE 2: Shake violento + zoom out
	local finalStart = tick()
	local lastCamPos = camera.CFrame.Position
	local targetPos = rootPart.Position

	while tick() - finalStart < CONFIG.finalShakeDuration do
		local t = (tick() - finalStart) / CONFIG.finalShakeDuration
		local easeOut = 1 - math.pow(1 - t, 3)

		-- Shake que disminuye
		local shakeAmount = CONFIG.finalShakeIntensity * (1 - easeOut)
		local shakeOffset = shake(shakeAmount)

		-- Zoom out rápido
		local zoomOut = 1 + easeOut * 0.5
		local direction = (lastCamPos - targetPos).Unit
		local newPos = targetPos + direction * CONFIG.orbitDistance * zoomOut + shakeOffset

		camera.CFrame = CFrame.new(newPos, targetPos + Vector3.new(0, 2, 0))
		camera.FieldOfView = CONFIG.baseFOV + (1 - easeOut) * 20

		-- Desvanecer flash
		flash.Brightness = 3 * (1 - easeOut)
		bloom.Intensity = 3 * (1 - easeOut)
		blur.Size = 24 * (1 - easeOut)

		-- Color vuelve a normal
		colorCorrection.Saturation = CONFIG.saturation * (1 - easeOut)
		colorCorrection.TintColor = colorCorrection.TintColor:Lerp(Color3.new(1,1,1), easeOut * 0.5)

		RunService.RenderStepped:Wait()
	end

	-- FASE 3: Corte limpio
	flash:Destroy()
	colorCorrection:Destroy()
	bloom:Destroy()
	blur:Destroy()

	camera.CameraType = originalCameraType
	camera.FieldOfView = originalFOV

	-- Snap visual al volver
	task.spawn(function()
		local snapBlur = createEffect("BlurEffect", "SnapBlur", {Size = 8})
		task.wait(0.05)
		TweenService:Create(snapBlur, TweenInfo.new(0.15), {Size = 0}):Play()
		task.wait(0.15)
		snapBlur:Destroy()
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CONEXIÓN DEL EVENTO
-- ══════════════════════════════════════════════════════════════════════════════

rotateEvent.OnClientEvent:Connect(function()
	startRotateEffect()
end)