local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local fiestaEvent = eventsFolder:WaitForChild("FiestaEvent")
local hueSpeed = 0.01

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

local function rotateCameraOnce()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local originalType = camera.CameraType
	local originalCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local duration = 1.5
	local startTime = tick()
	while tick() - startTime < duration do
		local progress = (tick() - startTime) / duration
		local angle = math.rad(progress * 360)
		local basePos = rootPart.Position + Vector3.new(0, 5, 10)
		local lookAt = rootPart.Position + Vector3.new(0, 2, 0)
		camera.CFrame = CFrame.new(basePos, lookAt) * CFrame.Angles(0, 0, angle)
		RunService.RenderStepped:Wait()
	end
	camera.CameraType = originalType
	camera.CFrame = originalCFrame
end

local function startFiestaEffect()
	local colorEffect = Instance.new("ColorCorrectionEffect")
	colorEffect.Name = "FiestaColor"
	colorEffect.Parent = Lighting

	colorEffect.TintColor = Color3.new(1,1,1)
	colorEffect.Saturation = 0

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	TweenService:Create(colorEffect, tweenInfo, {
		TintColor = Color3.new(0,0,0),
		Saturation = -1
	}):Play()

	task.wait(2)

	local blur = Instance.new("BlurEffect")
	blur.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 24
	bloom.Threshold = 1
	bloom.Parent = Lighting

	local hue = 0
	local stop = false

	local hbConn
	hbConn = RunService.Heartbeat:Connect(function()
		if stop then
			hbConn:Disconnect()
			return
		end
		hue = (hue + hueSpeed) % 1
		colorEffect.TintColor = HSVtoRGB(hue, 1, 1)
		colorEffect.Saturation = 1
		blur.Size = 10 + math.sin(tick() * 2) * 6
	end)

	task.spawn(function()
		for _ = 1,2 do
			rotateCameraOnce()
			task.wait(3)
		end
		task.wait(1)
		stop = true
		colorEffect:Destroy()
		blur:Destroy()
		bloom:Destroy()
	end)
end

fiestaEvent.OnClientEvent:Connect(startFiestaEffect)
