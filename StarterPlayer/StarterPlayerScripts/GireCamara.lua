local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local rotateEvent = ReplicatedStorage:WaitForChild("RotateEffectEvent")

local function startRotateEffect()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- VARIABLES MODIFICABLES
	local effectDuration = 10 
	local fadeDuration = 5
	local speedPhase1 = 0.5
	local speedPhase2 = 5
	local speedPhase3 = 13
	local hueSpeed = 0.01

	local saturation = 1
	local brightness = 1

	local beatFrequency = 3
	local beatAmplitude = 1

	local originalCameraType = camera.CameraType
	local originalCFrame = camera.CFrame

	camera.CameraType = Enum.CameraType.Scriptable

	local startTime = tick()
	local hue = 0
	local rotationZ = 0

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

	local lastTick = tick()

	while true do
		local now = tick()
		local deltaTime = now - lastTick
		lastTick = now

		local elapsed = now - startTime

		if elapsed > effectDuration + fadeDuration then
			camera.CameraType = originalCameraType
			camera.CFrame = originalCFrame
			colorEffect:Destroy()
			break
		end

		local speed
		if elapsed <= 4 then
			speed = speedPhase1
		elseif elapsed <= 7 then
			speed = speedPhase2
		elseif elapsed <= effectDuration then
			speed = speedPhase3
		else
			speed = speedPhase3
		end

		rotationZ = (rotationZ + speed * 60 * deltaTime) % 360

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

		local basePosition = rootPart.Position + Vector3.new(0, 5, 10 + beatOffset)
		local lookAt = rootPart.Position + Vector3.new(0, 2, 0)
		local camCFrame = CFrame.new(basePosition, lookAt) * CFrame.Angles(0, 0, math.rad(rotationZ))

		camera.CFrame = camCFrame

		RunService.RenderStepped:Wait()
	end
end

rotateEvent.OnClientEvent:Connect(function()
	startRotateEffect()
end)