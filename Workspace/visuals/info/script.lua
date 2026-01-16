local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

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

-- Obtener barras del ecualizador (incluir variantes: Bar1.., Bar01, EqualizerBar, etc.)
for _, child in ipairs(UI.Equalizer:GetChildren()) do
	-- considerar solo GuiObjects (Frames/Images) y nombres que parezcan barras
	if child:IsA("GuiObject") then
		local name = child.Name
		if name:match("Bar%d+") or name:match("%d+") or name:lower():find("bar") then
			table.insert(UI.EqualizerBars, child)
		end
	end
end

-- Si quedaron menos de 16, intentar añadir todos los hijos visibles como fallback
if #UI.EqualizerBars < 16 then
	for _, child in ipairs(UI.Equalizer:GetChildren()) do
		if child:IsA("GuiObject") and not table.find(UI.EqualizerBars, child) then
			table.insert(UI.EqualizerBars, child)
		end
	end
end

-- Ordenar por número si hay, sino por nombre
table.sort(UI.EqualizerBars, function(a, b)
	local na = tonumber(a.Name:match("%d+")) or math.huge
	local nb = tonumber(b.Name:match("%d+")) or math.huge
	if na ~= nb then return na < nb end
	return a.Name < b.Name
end)

-- Obtener el Glow si existe
UI.Glow = UI.ProgressFill:FindFirstChild("Glow")

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
	return
end

local lastSoundId = ""

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
	local idleHeight = 0.10
	local activeTweenTime = 0.08
	local idleTweenTime = 0.35

	while true do
		if SongHolder.Playing then
			for i, bar in ipairs(UI.EqualizerBars) do
				pcall(function()
					-- calcular altura dinámica (mantener algo de variación por barra)
					local rand = math.random(20, 100) / 100
					local base = 0.12
					local jitter = (i % 3) * 0.03
					local targetHeight = math.clamp(base + (rand * 0.88) + jitter, 0.08, 1)

					local curX = (bar.Size and bar.Size.X and bar.Size.X.Scale) and bar.Size.X.Scale or 0.05
					local targetSize = UDim2.new(curX, 0, targetHeight, 0)

					TweenService:Create(bar, TweenInfo.new(activeTweenTime, Enum.EasingStyle.Quad), {
						Size = targetSize
					}):Play()
				end)
			end
			task.wait(0.04)
		else
			for i, bar in ipairs(UI.EqualizerBars) do
				pcall(function()
					local curX = (bar.Size and bar.Size.X and bar.Size.X.Scale) and bar.Size.X.Scale or 0.05
					TweenService:Create(bar, TweenInfo.new(idleTweenTime, Enum.EasingStyle.Quad), {
						Size = UDim2.new(curX, 0, idleHeight, 0)
					}):Play()
				end)
			end
			task.wait(idleTweenTime)
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
