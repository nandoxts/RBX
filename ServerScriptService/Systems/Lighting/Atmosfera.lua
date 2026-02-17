-- SERVICES
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- OBJECTS
local Clouds = workspace:WaitForChild("Terrain"):WaitForChild("Clouds")
local Atmosphere = Lighting:WaitForChild("Atmosphere")

-- CONFIG
local LIGHT_TAG = "Light"
local DAY_START = 6
local NIGHT_START = 20

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
		TweenInfo.new(time or 5, Enum.EasingStyle.Quart),
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
		tween(Atmosphere, {Color = Color3.fromRGB(200,224,255), Decay = Color3.fromRGB(64,64,64)}, 10)
		tween(Clouds, {Color = Color3.fromRGB(160,160,160), Cover = 0.65}, 10)
		Lighting.ColorShift_Top = Color3.fromRGB(255,240,224)

	elseif time > 16.5 and time <= 17.75 then
		tween(Atmosphere, {Color = Color3.fromRGB(200,224,255), Decay = Color3.fromRGB(200,144,96)}, 10)
		tween(Clouds, {Color = Color3.fromRGB(160,160,160), Cover = 0.65}, 10)
		Lighting.ColorShift_Top = Color3.fromRGB(255,192,128)

	elseif time > 17.75 or time < 6 then
		tween(Atmosphere, {Color = Color3.fromRGB(64,64,64), Decay = Color3.fromRGB(0,0,0)}, 10)
		tween(Clouds, {Color = Color3.fromRGB(64,64,64), Cover = 0.55}, 10)
		Lighting.ColorShift_Top = Color3.fromRGB(255,255,255)

	elseif time >= 6 and time <= 7.5 then
		tween(Atmosphere, {Color = Color3.fromRGB(200,224,255), Decay = Color3.fromRGB(255,192,128)}, 10)
		tween(Clouds, {Color = Color3.fromRGB(96,96,96), Cover = 0.55}, 10)
		Lighting.ColorShift_Top = Color3.fromRGB(255,192,128)
	end
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
	if tick() - lastTick < 1 then return end
	lastTick = tick()

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
	if isNightTime() then
		setLightColor(light, Color3.new(1,1,1), false)
	else
		setLightColor(light, Color3.new(0,0,0), false)
	end
end)

print("✅ Day/Night Lighting System Loaded")
