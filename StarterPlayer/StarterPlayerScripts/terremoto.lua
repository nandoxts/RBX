-- ============================================
-- EFECTO: TERREMOTO (Earthquake) - SIN BLOQUEAR CÁMARA
-- Evento: TerremotoEvent
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local terremotoEvent = eventsFolder:WaitForChild("TerremotoEvent")

local isShaking = false

local function startTerremotoEffect()
	if isShaking then return end -- Evitar duplicados
	isShaking = true

	-- VARIABLES MODIFICABLES
	local effectDuration = 15
	local fadeDuration = 2
	local shakeIntensity = 6      -- Intensidad del temblor (reducida)
	local shakeSpeed = 20             -- Velocidad del temblor
	local hueSpeed = 0.015            -- Velocidad cambio de color

	local startTime = tick()
	local hue = 0

	local function HSVtoRGB(h, s, v)
		local c = v * s
		local x = c * (1 - math.abs((h * 6) % 2 - 1))
		local m = v - c
		local r, g, b = 0, 0, 0

		if h < 1/6 then
			r, g, b = c, x, 0
		elseif h < 2/6 then
			r, g, b = x, c, 0
		elseif h < 3/6 then
			r, g, b = 0, c, x
		elseif h < 4/6 then
			r, g, b = 0, x, c
		elseif h < 5/6 then
			r, g, b = x, 0, c
		else
			r, g, b = c, 0, x
		end
		return Color3.new(r + m, g + m, b + m)
	end

	-- Crear efectos visuales
	local colorEffect = Instance.new("ColorCorrectionEffect")
	colorEffect.Name = "TerremotoColor"
	colorEffect.Parent = Lighting

	local blur = Instance.new("BlurEffect")
	blur.Name = "TerremotoBlur"
	blur.Size = 6
	blur.Parent = Lighting

	-- Variables para evitar acumulación del offset y generar impulsos (saltos)
	local prevOffset = CFrame.new()
	local impulseStart = 0
	local impulseEnd = 0
	local impulseVec = Vector3.new(0, 0, 0)
	local impulseRot = 0
	local nextImpulseTime = startTime

	local function getRandomImpulse(magnitude)
		local angle = math.random() * math.pi * 2
		-- Reducir la variación para saltos más suaves (rango más pequeño)
		local r = (math.random() - 0.5) * 0.6
		return Vector3.new(math.cos(angle) * r, math.sin(angle) * r, 0) * magnitude
	end

	-- Función que aplica el shake DESPUÉS de la cámara normal (impulsos discretos)
	local function applyShake()
		local now = tick()
		local elapsed = now - startTime

		-- Terminar efecto
		if elapsed > effectDuration + fadeDuration then
			RunService:UnbindFromRenderStep("TerremotoShake")
			-- Remover cualquier offset aplicado
			camera.CFrame = camera.CFrame * prevOffset:Inverse()
			if colorEffect then colorEffect:Destroy() end
			if blur then blur:Destroy() end
			isShaking = false
			return
		end

		-- Calcular intensidad según fase
		local intensityMult
		if elapsed <= 1 then
			intensityMult = elapsed / 1
		elseif elapsed <= effectDuration then
			intensityMult = 1 + math.sin(elapsed * 4) * 0.2
		else
			local fadeProgress = (elapsed - effectDuration) / fadeDuration
			intensityMult = 1 - fadeProgress
		end

		local currentShake = shakeIntensity * intensityMult

		-- Crear nuevos impulsos en intervalos cortos
		if now >= nextImpulseTime then
			local interval = 0.08 + math.random() * 0.12 -- 0.08..0.2s entre impulsos
			nextImpulseTime = now + interval
			impulseStart = now
			local dur = 0.06 + math.random() * 0.09 -- duración breve del impulso
			impulseEnd = now + dur
			impulseVec = getRandomImpulse(currentShake)
			-- Rotación más suave (menos exagerada)
			impulseRot = (math.random() - 0.5) * math.rad(currentShake * 1.2)
		end

		-- Remover offset previo para evitar acumulación
		local baseCFrame = camera.CFrame * prevOffset:Inverse()

		-- Calcular nuevo offset según progreso del impulso (pico sinusoidal)
		local newOffset = CFrame.new()
		if now <= impulseEnd and impulseEnd > impulseStart then
			local p = (now - impulseStart) / (impulseEnd - impulseStart)
			local ease = math.sin(p * math.pi) -- sube y baja
			newOffset = CFrame.new(impulseVec * ease) * CFrame.Angles(0, 0, impulseRot * ease)
		end

		-- Aplicar offset sobre la cámara base
		camera.CFrame = baseCFrame * newOffset
		prevOffset = newOffset

		-- Color arcoíris
		hue = (hue + hueSpeed) % 1
		local color = HSVtoRGB(hue, 1, 1)

		-- Aplicar efectos visuales
		if elapsed <= effectDuration then
			colorEffect.Saturation = 1
			colorEffect.TintColor = color
		else
			local fadeProgress = (elapsed - effectDuration) / fadeDuration
			colorEffect.Saturation = 1 - fadeProgress
			colorEffect.TintColor = Color3.new(1, 1, 1):Lerp(color, 1 - fadeProgress)
		end

		-- Blur pulsante
		blur.Size = 4 + math.abs(math.sin(elapsed * 6)) * 4 * intensityMult
	end

	-- CLAVE: BindToRenderStep con prioridad DESPUÉS de la cámara
	-- Enum.RenderPriority.Camera.Value = 200, usamos 201 para ir después
	RunService:BindToRenderStep("TerremotoShake", Enum.RenderPriority.Camera.Value + 1, applyShake)
end

terremotoEvent.OnClientEvent:Connect(startTerremotoEffect)