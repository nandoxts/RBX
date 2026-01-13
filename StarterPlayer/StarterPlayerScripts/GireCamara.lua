local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local rotateEvent = ReplicatedStorage:WaitForChild("RotateEffectEvent")

local isRotating = false

local function startRotateEffect()
	if isRotating then return end
	isRotating = true

	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- VARIABLES MODIFICABLES (valores reducidos para giro más suave)
	local effectDuration = 10
	local fadeDuration = 5
	local phaseSpeed1 = 0.8
	local phaseSpeed2 = 1.8
	local phaseSpeed3 = 3.2
	local hueSpeed = 0.01

	local saturation = 1
	local brightness = 1

	local beatFrequency = 2
	local beatAmplitude = 0.6

	local maxRotationDegrees = 8 -- amplitud máxima del giro en grados (reducido)

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

	local colorEffect = Lighting:FindFirstChild("CameraColorEffect")
	if not colorEffect then
		colorEffect = Instance.new("ColorCorrectionEffect")
		colorEffect.Name = "CameraColorEffect"
		colorEffect.Parent = Lighting
	end

	local prevOffset = CFrame.new()
	local prevRotation = CFrame.new()
	local lastTick = startTime

	local function applyRotate()
		local now = tick()
		local delta = now - lastTick
		lastTick = now
		local elapsed = now - startTime

		if elapsed > effectDuration + fadeDuration then
			RunService:UnbindFromRenderStep("RotateEffect")
			camera.CFrame = camera.CFrame * prevOffset:Inverse()
			if colorEffect then colorEffect:Destroy() end
			isRotating = false
			return
		end

		-- elegir velocidad según fase, pero con valores suaves
		local speed
		if elapsed <= 4 then
			speed = phaseSpeed1
		elseif elapsed <= 7 then
			speed = phaseSpeed2
		elseif elapsed <= effectDuration then
			speed = phaseSpeed3
		else
			speed = phaseSpeed3
		end

		-- Rotación incremental acumulada (visible y suave)
		local degPerSec = speed * 12 -- ajustar multiplicador para velocidad
		local angularDelta = math.rad(degPerSec * delta)
		local rotationIncrement = CFrame.Angles(0, 0, angularDelta)
		prevRotation = prevRotation * rotationIncrement

		hue = (hue + hueSpeed) % 1
		local color = HSVtoRGB(hue, saturation, brightness)

		if elapsed <= effectDuration then
			colorEffect.Saturation = saturation
			colorEffect.TintColor = color
		else
			local fadeProgress = (elapsed - effectDuration) / fadeDuration
			colorEffect.Saturation = saturation * (1 - fadeProgress)
			colorEffect.TintColor = Color3.new(1, 1, 1):Lerp(color, 1 - fadeProgress)
		end

		local beatOffset = math.sin(elapsed * math.pi * 2 * beatFrequency) * beatAmplitude

		-- Positional offset (no acumulativa, pequeña influencia)
		local forwardOffset = beatOffset * 0.6
		local positionalOffset = CFrame.new(0, 0, forwardOffset)

		-- Nuevo offset total = rotación acumulada * posicionamiento
		local newOffset = prevRotation * positionalOffset

		-- Aplicar offset relativo a la cámara actual (no re-centra la cámara en el personaje)
		local baseCFrame = camera.CFrame * prevOffset:Inverse()
		camera.CFrame = baseCFrame * newOffset
		prevOffset = newOffset
	end

	RunService:BindToRenderStep("RotateEffect", Enum.RenderPriority.Camera.Value + 1, applyRotate)
end

rotateEvent.OnClientEvent:Connect(function()
	startRotateEffect()
end)