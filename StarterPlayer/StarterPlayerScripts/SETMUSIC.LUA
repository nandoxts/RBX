-- SETMUSIC.LUA deprecated
-- La lógica de efecto reactivo al audio fue movida a ServerScriptService/RainbowSync.lua
-- Para evitar duplicados, este archivo se mantiene como stub.
warn("SETMUSIC.LUA está deshabilitado: use RainbowSync para efectos de audio")
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
	while sound.IsPlaying do
		local loudness = sound.PlaybackLoudness
		local isPeak = loudness > peakThreshold
		local isBase = loudness > baseThreshold

		local targetTransparency = isPeak and maxTransparency or (isBase and 0.5 or minTransparency)
		local targetBrightness = isPeak and maxBrightness or (isBase and (maxBrightness + minBrightness)/2 or minBrightness)

		local allParts = getAllNeonLightParts()

		for _, part in ipairs(allParts) do
			if part.Name == "NeonLight-Sound-SurfaceLight" then
				local light = findLight(part)
				if light then
					light.Brightness = targetBrightness
					pcall(function() light.Color = currentRainbowColor end)
				end
			else
				part.Transparency = targetTransparency
				part.Material = isPeak and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
		end

		local pointLights = getPointLightParts()
		for _, pl in ipairs(pointLights) do
			if loudness > 250 then
				pl.Enabled = true
				pl.Brightness = 6
			else
				pl.Enabled = false
			end
		end


		task.wait(checkInterval)
	end

	local allParts = getAllNeonLightParts()
	for _, part in ipairs(allParts) do
		if part.Name == "NeonLight-Sound-SurfaceLight" then
			local light = findLight(part)
				if light then
					light.Brightness = minBrightness
					pcall(function() light.Color = currentRainbowColor end)
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
