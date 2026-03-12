local RunService = game:GetService("RunService")
local sound = workspace:WaitForChild("QueueSound", 30)

-- ── Parámetros ────────────────────────────────────────────────────
local baseThreshold  = 100
local peakThreshold  = 180
local minTransparency = 1
local maxTransparency = 0
local minBrightness  = 10
local maxBrightness  = 30

if not sound then
	warn("SETMUSIC: No se encontró QueueSound en workspace")
	return
end

-- ── Cache de objetos ──────────────────────────────────────────────
-- allParts   → BaseParts (Transparency + Material)
-- allLights  → SurfaceLight / SpotLight (Brightness)
-- pointLights→ PointLight (Enabled + Brightness)
local allParts   = {}
local allLights  = {}
local pointLights = {}

local function buildCache()
	allParts    = {}
	allLights   = {}
	pointLights = {}

	local effects = workspace:FindFirstChild("Effects")
	if not effects then return end
	local partsFolder = effects:FindFirstChild("Parts")
	if not partsFolder then return end

	-- SoundParts: escaneo recursivo completo (Models, Unions, Parts, todo)
	local soundPartsContainer = partsFolder:FindFirstChild("SoundParts")
	if soundPartsContainer then
		for _, obj in ipairs(soundPartsContainer:GetDescendants()) do
			if obj:IsA("PointLight") then
				table.insert(pointLights, obj)
			elseif obj:IsA("SurfaceLight") or obj:IsA("SpotLight") then
				table.insert(allLights, obj)
			elseif obj:IsA("BasePart") then
				table.insert(allParts, obj)
			end
		end
	end

	-- PointLightParts: solo PointLight instances (opcional)
	local pointLightContainer = partsFolder:FindFirstChild("PointLightParts")
	if pointLightContainer then
		for _, obj in ipairs(pointLightContainer:GetDescendants()) do
			if obj:IsA("PointLight") then
				table.insert(pointLights, obj)
			end
		end
	end
end

-- ── Loop principal ────────────────────────────────────────────────
local function updateEffect()
	local lastMaterial = nil

	while sound.IsPlaying do
		local loudness = sound.PlaybackLoudness
		local isPeak   = loudness > peakThreshold
		local isBase   = loudness > baseThreshold

		local targetTransp   = isPeak and maxTransparency   or (isBase and 0.5 or minTransparency)
		local targetBright   = isPeak and maxBrightness     or (isBase and (maxBrightness + minBrightness) / 2 or minBrightness)
		local targetMaterial = isPeak and Enum.Material.Neon or Enum.Material.SmoothPlastic

		for _, part in ipairs(allParts) do
			part.Transparency = targetTransp
			if targetMaterial ~= lastMaterial then
				pcall(function() part.Material = targetMaterial end)
			end
		end

		for _, light in ipairs(allLights) do
			light.Brightness = targetBright
		end

		lastMaterial = targetMaterial

		for _, pl in ipairs(pointLights) do
			if loudness > 250 then
				pl.Enabled   = true
				pl.Brightness = 6
			else
				pl.Enabled = false
			end
		end

		RunService.Heartbeat:Wait()
	end

	-- Reset al parar
	for _, part in ipairs(allParts) do
		part.Transparency = minTransparency
		pcall(function() part.Material = Enum.Material.SmoothPlastic end)
	end
	for _, light in ipairs(allLights) do
		light.Brightness = minBrightness
	end
	for _, pl in ipairs(pointLights) do
		pl.Enabled = false
	end
end

-- ── Arranque automático ───────────────────────────────────────────
sound.Played:Connect(function()
	buildCache()
	task.spawn(updateEffect)
end)

if sound.IsPlaying then
	buildCache()
	task.spawn(updateEffect)
end

