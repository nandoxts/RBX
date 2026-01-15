local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local SurfaceGui = script.Parent
local barra = SurfaceGui:WaitForChild("Barra")

-- ═══════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════
local Config = {
	UpdateRate = 0.05,
	TweenSpeed = 0.15,
	Colors = {
		Playing = Color3.fromRGB(30, 215, 96),
		Paused = Color3.fromRGB(255, 193, 7),
		Stopped = Color3.fromRGB(180, 180, 180),
		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(180, 180, 180),
	}
}

-- ═══════════════════════════════════════════════════════
-- REFERENCIAS EXISTENTES (tu estructura original)
-- ═══════════════════════════════════════════════════════
local progressBar = barra:WaitForChild("ProgressBar")
local progressFill = progressBar:WaitForChild("Frame")
local timeLabel = barra:WaitForChild("Time")
local minLabel = barra:WaitForChild("Min")

-- ═══════════════════════════════════════════════════════
-- CREAR ELEMENTOS NUEVOS
-- ═══════════════════════════════════════════════════════

-- NOW PLAYING
local nowPlaying = Instance.new("TextLabel")
nowPlaying.Name = "NowPlaying"
nowPlaying.Size = UDim2.new(1, 0, 0, 25)
nowPlaying.Position = UDim2.new(0, 0, 0, 5)
nowPlaying.BackgroundTransparency = 1
nowPlaying.Text = "♪ NOW PLAYING"
nowPlaying.TextColor3 = Config.Colors.Playing
nowPlaying.TextScaled = false
nowPlaying.TextSize = 18
nowPlaying.Font = Enum.Font.GothamBold
nowPlaying.TextXAlignment = Enum.TextXAlignment.Center
nowPlaying.Parent = barra

-- TÍTULO DE LA CANCIÓN
local songTitle = Instance.new("TextLabel")
songTitle.Name = "SongTitle"
songTitle.Size = UDim2.new(1, -20, 0, 40)
songTitle.Position = UDim2.new(0, 10, 0, 30)
songTitle.BackgroundTransparency = 1
songTitle.Text = "Cargando..."
songTitle.TextColor3 = Config.Colors.TextPrimary
songTitle.TextScaled = false
songTitle.TextSize = 32
songTitle.Font = Enum.Font.GothamBold
songTitle.TextXAlignment = Enum.TextXAlignment.Center
songTitle.TextTruncate = Enum.TextTruncate.AtEnd
songTitle.Parent = barra

-- ARTISTA
local artist = Instance.new("TextLabel")
artist.Name = "Artist"
artist.Size = UDim2.new(1, -20, 0, 25)
artist.Position = UDim2.new(0, 10, 0, 70)
artist.BackgroundTransparency = 1
artist.Text = "Artista"
artist.TextColor3 = Config.Colors.TextSecondary
artist.TextScaled = false
artist.TextSize = 20
artist.Font = Enum.Font.GothamMedium
artist.TextXAlignment = Enum.TextXAlignment.Center
artist.Parent = barra

-- GLOW para el fill
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.Size = UDim2.new(0, 30, 0, 30)
glow.Position = UDim2.new(1, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://5028857084"
glow.ImageColor3 = Config.Colors.Playing
glow.ImageTransparency = 0.4
glow.ZIndex = 5
glow.Parent = progressFill

-- Mejorar el Fill con gradiente
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 215, 96)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 255, 150))
})
gradient.Parent = progressFill

-- Corner para el fill si no tiene
if not progressFill:FindFirstChild("UICorner") then
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = progressFill
end

-- ═══════════════════════════════════════════════════════
-- BUSCAR SONIDO
-- ═══════════════════════════════════════════════════════
local SongHolder = workspace:FindFirstChild("CancionSistema") or SoundService:FindFirstChild("THEME")
if not SongHolder then
	songTitle.Text = "Sin música"
	artist.Text = "No se encontró CancionSistema"
	nowPlaying.Text = "⚠️ ERROR"
	nowPlaying.TextColor3 = Color3.fromRGB(255, 80, 80)
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

local function smoothTween(object, properties, duration)
	local tween = TweenService:Create(object, TweenInfo.new(duration or Config.TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	tween:Play()
	return tween
end

local function updateColors(color)
	smoothTween(progressFill, {BackgroundColor3 = color}, 0.5)
	smoothTween(glow, {ImageColor3 = color}, 0.5)
	smoothTween(nowPlaying, {TextColor3 = color}, 0.5)
end

local function updatePlayingState()
	local color = Config.Colors.Stopped
	local statusText = "⏹ STOPPED"
	
	if SongHolder.Playing then
		color = Config.Colors.Playing
		statusText = "♪ NOW PLAYING"
	elseif SongHolder.TimePosition > 0 then
		color = Config.Colors.Paused
		statusText = "❚❚ PAUSED"
	end
	
	nowPlaying.Text = statusText
	updateColors(color)
end

local function fetchSongMetadata(assetId)
	local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId)
	
	if success and info then
		-- Animación de entrada
		songTitle.TextTransparency = 1
		artist.TextTransparency = 1
		
		songTitle.Text = info.Name or "Desconocido"
		artist.Text = info.Creator and info.Creator.Name or "Artista"
		
		TweenService:Create(songTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		TweenService:Create(artist, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0}):Play()
	end
end

local function updateSongInfo()
	local soundId = SongHolder.SoundId
	if soundId == "" or soundId == lastSoundId then return end
	
	lastSoundId = soundId
	local assetId = extractAssetId(soundId)
	if not assetId then return end
	
	-- Reset
	progressFill.Size = UDim2.fromScale(0, 1)
	timeLabel.Text = "0:00"
	minLabel.Text = "--:--"
	songTitle.Text = "Cargando..."
	artist.Text = ""
	
	task.spawn(fetchSongMetadata, assetId)
end

-- ═══════════════════════════════════════════════════════
-- ANIMACIONES
-- ═══════════════════════════════════════════════════════
local function glowPulse()
	while true do
		if SongHolder.Playing then
			TweenService:Create(glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.2,
				Size = UDim2.new(0, 40, 0, 40)
			}):Play()
			task.wait(0.6)
			TweenService:Create(glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.5,
				Size = UDim2.new(0, 30, 0, 30)
			}):Play()
			task.wait(0.6)
		else
			task.wait(0.5)
		end
	end
end

local function startProgressLoop()
	local accumulated = 0
	
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < Config.UpdateRate then return end
		accumulated = 0
		
		local duration = SongHolder.TimeLength
		local position = SongHolder.TimePosition
		
		if duration > 0 then
			timeLabel.Text = formatTime(position)
			minLabel.Text = formatTime(duration)
			
			local progress = math.clamp(position / duration, 0, 1)
			smoothTween(progressFill, {Size = UDim2.fromScale(progress, 1)})
		end
	end)
end

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════
SongHolder:GetPropertyChangedSignal("SoundId"):Connect(updateSongInfo)
SongHolder:GetPropertyChangedSignal("Playing"):Connect(updatePlayingState)

updateSongInfo()
updatePlayingState()
startProgressLoop()
task.spawn(glowPulse)

print("🎵 Music Player iniciado correctamente")