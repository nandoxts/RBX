--[[
	MUSIC VISUALS - LocalScript (FINAL - SIN BUGS)
	
	UBICACIÓN: StarterPlayerScripts
	
	Lee metadata desde Attributes del Sound (seteados por el servidor)
	Si no existen, usa MarketplaceService como fallback
	
	NO hay parpadeo ni "Cargando..." porque el servidor ya tiene la info
]]

local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Theme
local okTheme, THEME = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
end)
if not okTheme then
	THEME = { accent = Color3.fromRGB(70, 30, 215) }
end

-- ═══════════════════════════════════════════════════════
-- BUSCAR UI
-- ═══════════════════════════════════════════════════════
local visuals = Workspace:WaitForChild("visuals", 15)
if not visuals then return end

local MusicPlayerUI = visuals:WaitForChild("MusicPlayerUI", 15)
if not MusicPlayerUI then return end

local Main = MusicPlayerUI:WaitForChild("Main", 15)
if not Main then return end

-- ═══════════════════════════════════════════════════════
-- ELEMENTOS UI
-- ═══════════════════════════════════════════════════════
local UI = {
	SongTitle = Main:FindFirstChild("SongTitle"),
	Artist = Main:FindFirstChild("Artist"),
	TimeDisplay = Main:FindFirstChild("TimeDisplay"),
	ProgressBg = Main:FindFirstChild("ProgressBg"),
	ProgressFill = nil,
	Equalizer = Main:FindFirstChild("Equalizer"),
	SeparatorLine = Main:FindFirstChild("SeparatorLine"),
	EqualizerBars = {},
	Glow = nil,
}

if UI.ProgressBg then
	UI.ProgressFill = UI.ProgressBg:FindFirstChild("ProgressFill")
	if UI.ProgressFill then
		UI.Glow = UI.ProgressFill:FindFirstChild("Glow")
	end
end

if UI.Equalizer then
	for _, child in ipairs(UI.Equalizer:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(UI.EqualizerBars, child)
		end
	end
	table.sort(UI.EqualizerBars, function(a, b)
		local na = tonumber(a.Name:match("%d+")) or math.huge
		local nb = tonumber(b.Name:match("%d+")) or math.huge
		return na < nb
	end)
end

for _, bar in ipairs(UI.EqualizerBars) do
	pcall(function()
		bar.BackgroundColor3 = THEME.accent
		bar.BorderSizePixel = 0
	end)
end

-- Rainbow
local rainbowValue = ReplicatedStorage:FindFirstChild("RainbowColor")
if rainbowValue and rainbowValue:IsA("Color3Value") then
	local function applyColor(c)
		for _, bar in ipairs(UI.EqualizerBars) do
			pcall(function() bar.BackgroundColor3 = c end)
		end
		if UI.ProgressFill then
			pcall(function() UI.ProgressFill.BackgroundColor3 = c end)
		end
	end
	applyColor(rainbowValue.Value)
	rainbowValue.Changed:Connect(applyColor)
end

-- ═══════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════
local SongHolder = nil
local displayedSongId = nil -- El ID que actualmente se MUESTRA
local metadataCache = {}
local failedCache = {} -- Cachear IDs que fallaron para no reintentar
local pendingRequests = {} -- Solicitudes en progreso

-- Loudness
local loudnessValue = 0
local loudnessAlpha = 0.18
local loudnessSensitivity = 1.6

-- ═══════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════
local function formatTime(s)
	if not s or s ~= s or s < 0 then return "0:00" end
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

local function getAssetId(soundId)
	if not soundId or soundId == "" then return nil end
	return soundId:match("rbxassetid://(%d+)")
end

-- ═══════════════════════════════════════════════════════
-- MOSTRAR EN UI
-- ═══════════════════════════════════════════════════════
local function showText(title, artist)
	if UI.SongTitle then
		UI.SongTitle.Text = title or "Sin música"
	end
	if UI.Artist then
		UI.Artist.Text = artist or ""
	end
end

local function showNoMusic()
	displayedSongId = nil
	showText("Sin música", "Esperando...")
	if UI.TimeDisplay then UI.TimeDisplay.Text = "0:00 / 0:00" end
	if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(0, 1) end
end

-- ═══════════════════════════════════════════════════════
-- OBTENER METADATA (PRIORIDAD: Attributes > Cache > MarketplaceService)
-- ═══════════════════════════════════════════════════════
local function getMetadata(sound, assetId, callback)
	-- VALIDAR ENTRADA
	if not assetId or assetId == "" then
		callback("Sin música", "Desconocido")
		return
	end

	-- 1. PRIMERO: Intentar leer Attributes del Sound (SIEMPRE prioritario)
	if sound then
		local attrName = sound:GetAttribute("SongName")
		local attrArtist = sound:GetAttribute("SongArtist")

		-- Validar que los atributos sean útiles (no vacíos ni del ID)
		if attrName and attrName ~= "" and attrName ~= assetId then
			callback(attrName, attrArtist or "Desconocido")
			return
		end
	end

	-- 2. SEGUNDO: Verificar cache de ÉXITO
	if metadataCache[assetId] then
		local cached = metadataCache[assetId]
		callback(cached.name, cached.artist)
		return
	end

	-- 3. TERCERO: Verificar si YA FALLÓ antes (evitar reintentos)
	if failedCache[assetId] then
		callback("Audio " .. assetId, "Desconocido")
		return
	end

	-- 4. CUARTO: Solicitar de MarketplaceService (ASYNC, no bloquea)
	-- Si ya hay una solicitud en progreso, esperar a que termine
	if pendingRequests[assetId] then
		-- No hacer nada, let callback esperar
		return
	end

	pendingRequests[assetId] = true

	task.spawn(function()
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(assetId), Enum.InfoType.Asset)
		end)

		if success and info and info.Name and info.Name ~= "" then
			local name = info.Name
			local artist = (info.Creator and info.Creator.Name) or "Desconocido"

			-- Validar que no sea un nombre vacío o inválido
			if name and name ~= "" and name ~= assetId then
				-- Guardar en cache de ÉXITO
				metadataCache[assetId] = { name = name, artist = artist }
				callback(name, artist)
			else
				-- Marcar como fallido
				failedCache[assetId] = true
				callback("Audio " .. assetId, "Desconocido")
			end
		else
			-- Marcar como fallido
			failedCache[assetId] = true
			callback("Audio " .. assetId, "Desconocido")
		end

		pendingRequests[assetId] = nil
	end)
end

-- ═══════════════════════════════════════════════════════
-- ACTUALIZAR INFO DE CANCIÓN
-- ═══════════════════════════════════════════════════════
local function updateSongInfo()
	if not SongHolder then
		showNoMusic()
		return
	end

	-- Obtener SoundId actual
	local soundId = ""
	pcall(function() soundId = SongHolder.SoundId end)

	if soundId == "" then
		showNoMusic()
		return
	end

	local assetId = getAssetId(soundId)
	if not assetId then
		showNoMusic()
		return
	end

	-- Si ya mostramos esta canción, no hacer nada
	if assetId == displayedSongId then
		return
	end

	-- Reset progreso
	if UI.ProgressFill then
		UI.ProgressFill.Size = UDim2.fromScale(0, 1)
	end
	if UI.TimeDisplay then
		UI.TimeDisplay.Text = "0:00 / 0:00"
	end

	-- Obtener metadata CON CALLBACK (puede ser async)
	getMetadata(SongHolder, assetId, function(name, artist)
		-- Solo mostrar si seguimos en la misma canción
		if assetId == displayedSongId then
			return  -- Ya se mostró
		end
		
		showText(name, artist)
		displayedSongId = assetId
	end)
end

-- ═══════════════════════════════════════════════════════
-- CONECTAR AL SOUND
-- ═══════════════════════════════════════════════════════
local soundConnection = nil
local attrConnection = nil

local function connectToSound(sound)
	-- Desconectar anterior
	if soundConnection then
		pcall(function() soundConnection:Disconnect() end)
	end
	if attrConnection then
		pcall(function() attrConnection:Disconnect() end)
	end

	SongHolder = sound
	displayedSongId = nil

	if not sound then
		showNoMusic()
		return
	end

	-- Escuchar cambio de SoundId
	soundConnection = sound:GetPropertyChangedSignal("SoundId"):Connect(function()
		-- Delay para asegurar que los Attributes fueron seteados por el servidor
		task.delay(0.1, updateSongInfo)
	end)

	-- También escuchar cambios en el Attribute SongName (por si cambia después de setear SoundId)
	attrConnection = sound:GetAttributeChangedSignal("SongName"):Connect(function()
		task.delay(0.05, updateSongInfo)
	end)

	-- Actualizar con delay para que los Attributes ya estén seteados
	task.delay(0.05, updateSongInfo)
end

-- ═══════════════════════════════════════════════════════
-- BUSCAR SOUND CONTINUAMENTE
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	while true do
		local sound = SoundService:FindFirstChild("QueueSound")

		if sound and sound:IsA("Sound") then
			if SongHolder ~= sound then
				connectToSound(sound)
			end
		else
			if SongHolder ~= nil then
				connectToSound(nil)
			end
		end

		task.wait(0.5)
	end
end)

-- ═══════════════════════════════════════════════════════
-- LOOP DE PROGRESO Y TIEMPO
-- ═══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if not SongHolder then return end

	local dur, pos = 0, 0
	pcall(function()
		dur = SongHolder.TimeLength
		pos = SongHolder.TimePosition
	end)

	if dur and dur > 0 then
		if UI.TimeDisplay then
			UI.TimeDisplay.Text = formatTime(pos) .. " / " .. formatTime(dur)
		end
		if UI.ProgressFill then
			local progress = math.clamp(pos / dur, 0, 1)
			UI.ProgressFill.Size = UDim2.fromScale(progress, 1)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
-- ECUALIZADOR
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	if #UI.EqualizerBars == 0 then return end

	while true do
		local playing = false
		if SongHolder then
			pcall(function() playing = SongHolder.Playing end)
		end

		if playing then
			local ok, val = pcall(function() return SongHolder.PlaybackLoudness end)
			if ok and type(val) == "number" then
				local scaled = math.clamp(val * loudnessSensitivity / 100, 0, 1)
				loudnessValue = loudnessValue * (1 - loudnessAlpha) + scaled * loudnessAlpha
			end

			local base = 0.12
			local intensity = base + (loudnessValue * 0.88)

			for i, bar in ipairs(UI.EqualizerBars) do
				local jitter = (i % 3) * 0.03
				local randomFactor = 0.6 + math.random() * 0.4
				local targetHeight = math.clamp(base + (randomFactor * intensity) + jitter, 0.08, 1)
				TweenService:Create(bar, TweenInfo.new(0.1), {
					Size = UDim2.fromScale(bar.Size.X.Scale, targetHeight)
				}):Play()
			end
			task.wait(0.06)
		else
			loudnessValue = loudnessValue * 0.9
			for _, bar in ipairs(UI.EqualizerBars) do
				TweenService:Create(bar, TweenInfo.new(0.4), {
					Size = UDim2.fromScale(bar.Size.X.Scale, 0.08)
				}):Play()
			end
			task.wait(0.3)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
-- GLOW
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	if not UI.Glow then return end

	while true do
		local playing = false
		if SongHolder then
			pcall(function() playing = SongHolder.Playing end)
		end

		if playing then
			TweenService:Create(UI.Glow, TweenInfo.new(0.6), {ImageTransparency = 0.1, Size = UDim2.fromOffset(60, 60)}):Play()
			task.wait(0.6)
			TweenService:Create(UI.Glow, TweenInfo.new(0.6), {ImageTransparency = 0.4, Size = UDim2.fromOffset(40, 40)}):Play()
			task.wait(0.6)
		else
			task.wait(0.5)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
-- SEPARADOR RAINBOW
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	if not UI.SeparatorLine then return end
	local gradient = UI.SeparatorLine:FindFirstChild("UIGradient")
	if not gradient then return end

	local offset = 0
	while true do
		offset = (offset + 0.01) % 1
		gradient.Offset = Vector2.new(offset, 0)
		task.wait(0.05)
	end
end)

-- ═══════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════
showNoMusic()