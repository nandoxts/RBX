local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Theme
local okTheme, THEME = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
end)
if not okTheme then
	THEME = { accent = Color3.fromRGB(30,215,96) }
end

-- ═══════════════════════════════════════════════════════
-- REFERENCIAS A LA ESTRUCTURA EXISTENTE
-- ═══════════════════════════════════════════════════════
local visuals = script.Parent
local MusicPlayerUI = visuals:WaitForChild("MusicPlayerUI")
local Main = MusicPlayerUI:WaitForChild("Main")

-- ═══════════════════════════════════════════════════════
-- OBTENER ELEMENTOS DE LA UI EXISTENTE
-- ═══════════════════════════════════════════════════════
local UI = {
	SongTitle = Main:WaitForChild("SongTitle"),
	Artist = Main:WaitForChild("Artist"),
	TimeDisplay = Main:WaitForChild("TimeDisplay"),
	ProgressBg = Main:WaitForChild("ProgressBg"),
	ProgressFill = Main.ProgressBg:WaitForChild("ProgressFill"),
	Equalizer = Main:WaitForChild("Equalizer"),
	SeparatorLine = Main:WaitForChild("SeparatorLine"),
	EqualizerBars = {},
}

-- Obtener barras del ecualizador
for i = 1, 16 do
	local bar = UI.Equalizer:FindFirstChild("Bar" .. i)
	if bar then
		table.insert(UI.EqualizerBars, bar)
	end
end

-- Obtener el Glow si existe
UI.Glow = UI.ProgressFill:FindFirstChild("Glow")

-- Asegurar color único para las barras del ecualizador usando THEME.accent
for _, bar in ipairs(UI.EqualizerBars) do
	pcall(function()
		bar.BackgroundColor3 = THEME.accent
		bar.BorderSizePixel = 0
	end)
end

-- ═══════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════
local Config = {
	UpdateRate = 0.05,
}

-- ═══════════════════════════════════════════════════════
-- BUSCAR SONIDO
-- ═══════════════════════════════════════════════════════
local SongHolder = workspace:FindFirstChild("CancionSistema") or SoundService:FindFirstChild("THEME")
if not SongHolder then
	UI.SongTitle.Text = "Sin música"
	UI.Artist.Text = "No se encontró CancionSistema"
	warn("Music UI: no SongHolder found (CancionSistema / THEME)")
	return
end

-- Asegurar que SongHolder sea un Sound
if not SongHolder:IsA("Sound") then
	local fallback = SoundService:FindFirstChild("THEME")
	if fallback and fallback:IsA("Sound") then
		SongHolder = fallback
	else
		warn("Music UI: SongHolder no es un Sound. Encontrado:", SongHolder.ClassName)
	end
end

local lastSoundId = ""

-- Loudness sampling
local loudnessValue = 0
local loudnessAlpha = 0.18 -- suavizado exponencial (0..1)
local loudnessSensitivity = 1.6 -- multiplicador para ajustar sensibilidad visible

local function sampleLoudness()
	local ok, val = pcall(function() return SongHolder and SongHolder.PlaybackLoudness end)
	if ok and type(val) == "number" then
		local scaled = math.clamp(val * loudnessSensitivity / 100, 0, 1)
		loudnessValue = loudnessValue * (1 - loudnessAlpha) + scaled * loudnessAlpha
		return true
	end
	-- fallback: decay toward zero
	loudnessValue = loudnessValue * (1 - loudnessAlpha)
	return false
end

-- ═══════════════════════════════════════════════════════
-- FUNCIONES
-- ═══════════════════════════════════════════════════════
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

local function extractAssetId(soundId)
	return soundId:match("rbxassetid://(%d+)")
end

local function smoothTween(object, properties, dur)
	local tween = TweenService:Create(object, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	tween:Play()
	return tween
end

local function fetchSongMetadata(assetId)
	local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId)

	if success and info then
		UI.SongTitle.TextTransparency = 1
		UI.Artist.TextTransparency = 1

		UI.SongTitle.Text = info.Name or "Desconocido"
		UI.Artist.Text = info.Creator and info.Creator.Name or "Artista"

		TweenService:Create(UI.SongTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		TweenService:Create(UI.Artist, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0}):Play()
	end
end

local function updateSongInfo()
	local soundId = SongHolder.SoundId
	if soundId == "" or soundId == lastSoundId then return end

	lastSoundId = soundId
	local assetId = extractAssetId(soundId)
	if not assetId then return end

	UI.ProgressFill.Size = UDim2.fromScale(0, 1)
	UI.TimeDisplay.Text = "0:00 / 0:00"
	UI.SongTitle.Text = "Cargando..."
	UI.Artist.Text = ""

	task.spawn(fetchSongMetadata, assetId)
end

-- ═══════════════════════════════════════════════════════
-- ANIMACIONES
-- ═══════════════════════════════════════════════════════

-- Animación del ecualizador
local function animateEqualizer()
	-- Función para intentar leer PlaybackLoudness de forma segura
	local function tryGetLoudness()
		local ok, val = pcall(function() return SongHolder.PlaybackLoudness end)
		if ok and type(val) == "number" then
			return val
		end
		return nil
	end

	while true do
		if SongHolder.Playing then
			-- Sample loudness each loop; if not available, loudnessValue decays slowly
			sampleLoudness()

			-- Intensidad base mínima para que las barras no queden pegadas
			local base = 0.12
			local intensity = base + (loudnessValue * 0.88) -- normalize into [base, 1]

			for i, bar in ipairs(UI.EqualizerBars) do
				-- variar un poco por barra para movimiento orgánico
				local jitter = (i % 3) * 0.03
				local randomFactor = 0.6 + math.random() * 0.4
				local targetHeight = math.clamp(base + (randomFactor * intensity) + jitter, 0.08, 1)

				TweenService:Create(bar, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					Size = UDim2.fromScale(bar.Size.X.Scale, targetHeight)
				}):Play()
			end
			task.wait(0.06)
		else
			-- reducir suavemente cuando no se reproduce
			for i, bar in ipairs(UI.EqualizerBars) do
				TweenService:Create(bar, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {
					Size = UDim2.fromScale(bar.Size.X.Scale, 0.08)
				}):Play()
			end
			task.wait(0.45)
		end
	end
end

-- Glow pulsante
local function glowPulse()
	if not UI.Glow then return end
	while true do
		if SongHolder.Playing then
			TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.1, Size = UDim2.fromOffset(60, 60)
			}):Play()
			task.wait(0.6)
			TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.4, Size = UDim2.fromOffset(40, 40)
			}):Play()
			task.wait(0.6)
		else
			task.wait(0.5)
		end
	end
end

-- Animación de la línea separadora (arcoíris moviéndose)
local function animateSeparator()
	local gradient = UI.SeparatorLine:FindFirstChild("UIGradient")
	if not gradient then return end

	local offset = 0
	while true do
		offset = (offset + 0.01) % 1
		gradient.Offset = Vector2.new(offset, 0)
		task.wait(0.05)
	end
end

-- Loop de progreso
local function startProgressLoop()
	local accumulated = 0

	RunService.Heartbeat:Connect(function(dt)
		accumulated = accumulated + dt
		if accumulated < Config.UpdateRate then return end
		accumulated = 0

		local dur = SongHolder.TimeLength
		local pos = SongHolder.TimePosition

		if dur > 0 then
			UI.TimeDisplay.Text = formatTime(pos) .. " / " .. formatTime(dur)

			local progress = math.clamp(pos / dur, 0, 1)
			smoothTween(UI.ProgressFill, {Size = UDim2.fromScale(progress, 1)})
		end
	end)
end

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════
SongHolder:GetPropertyChangedSignal("SoundId"):Connect(updateSongInfo)

updateSongInfo()
startProgressLoop()
task.spawn(animateEqualizer)
task.spawn(glowPulse)
task.spawn(animateSeparator)

print("🎵 Music Player conectado a UI existente")