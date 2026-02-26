local RunService = game:GetService("RunService")
local sound = game:GetService("Workspace"):FindFirstChild("QueueSound")

-- Parámetros ajustables
local baseThreshold = 100
local peakThreshold = 180
local checkInterval = 0.01
local minTransparency = 1
local maxTransparency = 0
local minBrightness = 10 
local maxBrightness = 30 

if not sound then
	warn("No se encontró el sonido 'QueueSound' en SoundService")
	return
end

-- ================================
local mainEffects = game.Workspace:FindFirstChild("Effects")
local pointLightFolder = nil
if mainEffects and mainEffects:FindFirstChild("Parts") then
	pointLightFolder = mainEffects.Parts:FindFirstChild("PointLightParts")
end
-- ================================

local function getNeonLightFolders()
	local folders = {}

	local mainNeonLightFolder = game:GetService("Workspace"):FindFirstChild("Effects")
	if mainNeonLightFolder then
		mainNeonLightFolder = mainNeonLightFolder:FindFirstChild("Parts")
		if mainNeonLightFolder then
			local neonLightFolder = mainNeonLightFolder:FindFirstChild("SoundParts")
			if neonLightFolder then
				table.insert(folders, neonLightFolder)
			end
		end
	end

	-- Nota: se eliminó la búsqueda en Map.ChangingMap; ahora solo usamos
	-- Workspace.Effects.Parts.SoundParts como fuente global de SoundParts.

	return folders
end

local function findLight(part)
	return part:FindFirstChildWhichIsA("SurfaceLight") or part:FindFirstChildWhichIsA("Light")
end

local function getAllNeonLightParts()
	local allParts = {}
	local folders = getNeonLightFolders()

	for _, folder in ipairs(folders) do
		for _, part in ipairs(folder:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(allParts, part)
			end
		end
	end

	return allParts
end
-- ================================
local function getPointLightParts()
	local list = {}
	if pointLightFolder then
		for _, p in ipairs(pointLightFolder:GetChildren()) do
			if p:IsA("BasePart") then
				local pl = p:FindFirstChildWhichIsA("PointLight")
				if pl then
					table.insert(list, pl)
				end
			end
		end
	end
	return list
end
-- ================================

local function updateEffect()
	-- obtener listas una vez, no en cada tick
	local allParts = getAllNeonLightParts()
	local pointLights = getPointLightParts()
	local lastMaterial = nil

	-- pre-cachear la referencia al light de cada SurfaceLight part
	local lightCache = {}
	for _, part in ipairs(allParts) do
		if part.Name == "NeonLight-Sound-SurfaceLight" then
			lightCache[part] = findLight(part)
		end
	end

	while sound.IsPlaying do
		local loudness = sound.PlaybackLoudness
		local isPeak = loudness > peakThreshold
		local isBase = loudness > baseThreshold

		local targetTransparency = isPeak and maxTransparency or (isBase and 0.5 or minTransparency)
		local targetBrightness = isPeak and maxBrightness or (isBase and (maxBrightness + minBrightness)/2 or minBrightness)
		local targetMaterial = isPeak and Enum.Material.Neon or Enum.Material.SmoothPlastic

		for _, part in ipairs(allParts) do
			if part.Name == "NeonLight-Sound-SurfaceLight" then
				local light = lightCache[part] -- cacheado, sin FindFirstChildWhichIsA
				if light then
					light.Brightness = targetBrightness
				end
			else
				part.Transparency = targetTransparency
				-- solo cambiar Material si realmente cambió
				if targetMaterial ~= lastMaterial then
					part.Material = targetMaterial
				end
			end
		end
		lastMaterial = targetMaterial

		for _, pl in ipairs(pointLights) do
			if loudness > 250 then
				pl.Enabled = true
				pl.Brightness = 6
			else
				pl.Enabled = false
			end
		end

		RunService.Heartbeat:Wait()
	end

	-- buscar todos los items frescos al resetear (por si hubo cambios dinámicos)
	local resetParts = getAllNeonLightParts()
	local resetLights = getPointLightParts()
	for _, part in ipairs(resetParts) do
		if part.Name == "NeonLight-Sound-SurfaceLight" then
			local light = findLight(part)
			if light then
				light.Brightness = minBrightness
			end
		else
			part.Transparency = minTransparency
		end
	end
	for _, pl in ipairs(resetLights) do
		pl.Enabled = false
	end
end

-- Nota: la lógica anterior que escuchaba Map.ChangingMap fue eliminada.
-- Si se necesita detectar mapas añadidos dinámicamente, reimplementar
-- la escucha apuntando al folder correcto dentro de Workspace.

-- Control reproducción
sound:GetPropertyChangedSignal("Playing"):Connect(function()
	if sound.IsPlaying then
		updateEffect()
	else
		local allParts = getAllNeonLightParts()
		for _, part in ipairs(allParts) do
			if part.Name == "NeonLight-Sound-SurfaceLight" then
				local light = findLight(part)
				if light then
					light.Brightness = minBrightness
				end
			else
				part.Transparency = minTransparency
			end
		end

		local pointLights = getPointLightParts()
		for _, pl in ipairs(pointLights) do
			pl.Enabled = false
		end
	end
end)

if sound.IsPlaying then
	updateEffect()
end
