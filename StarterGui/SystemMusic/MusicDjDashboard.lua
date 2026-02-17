--[[ Music Dashboard - Professional Edition v7
	by ignxts
	OPTIMIZADO: Virtualización + Búsqueda + Carga bajo demanda
	MEJORADO: Header estilo Spotify con cover dinámico
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))

-- ════════════════════════════════════════════════════════════════
-- RESPONSE CODES
-- ════════════════════════════════════════════════════════════════
local ResponseCodes = {
	SUCCESS = "SUCCESS",
	ERROR_INVALID_ID = "ERROR_INVALID_ID",
	ERROR_BLACKLISTED = "ERROR_BLACKLISTED",
	ERROR_DUPLICATE = "ERROR_DUPLICATE",
	ERROR_NOT_FOUND = "ERROR_NOT_FOUND",
	ERROR_NOT_AUDIO = "ERROR_NOT_AUDIO",
	ERROR_NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED",
	ERROR_QUEUE_FULL = "ERROR_QUEUE_FULL",
	ERROR_PERMISSION = "ERROR_PERMISSION",
	ERROR_UNKNOWN = "ERROR_UNKNOWN"
}

local ResponseMessages = {
	[ResponseCodes.SUCCESS] = {type = "success", title = "Éxito"},
	[ResponseCodes.ERROR_INVALID_ID] = {type = "error", title = "ID Inválido"},
	[ResponseCodes.ERROR_BLACKLISTED] = {type = "error", title = "Audio Bloqueado"},
	[ResponseCodes.ERROR_DUPLICATE] = {type = "warning", title = "Duplicado"},
	[ResponseCodes.ERROR_NOT_FOUND] = {type = "error", title = "No Encontrado"},
	[ResponseCodes.ERROR_NOT_AUDIO] = {type = "error", title = "Tipo Incorrecto"},
	[ResponseCodes.ERROR_NOT_AUTHORIZED] = {type = "error", title = "No Autorizado"},
	[ResponseCodes.ERROR_QUEUE_FULL] = {type = "warning", title = "Cola Llena"},
	[ResponseCodes.ERROR_PERMISSION] = {type = "error", title = "Sin Permiso"},
	[ResponseCodes.ERROR_UNKNOWN] = {type = "error", title = "Error"}
}

-- ════════════════════════════════════════════════════════════════
-- ADMIN CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local MusicSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local SHOW_ADMIN_UI = true

local isAdmin = MusicSystemConfig:IsAdmin(player) and SHOW_ADMIN_UI

-- ════════════════════════════════════════════════════════════════
-- THEME & CONFIG
-- ════════════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local R_PANEL, R_CTRL = 12, 10
local ENABLE_BLUR, BLUR_SIZE = true, 14
local PANEL_W_PX = THEME.panelWidth
local PANEL_H_PX = THEME.panelHeight

-- Virtualización
local CARD_HEIGHT = 54
local CARD_PADDING = 6
local VISIBLE_BUFFER = 3
local BATCH_SIZE = 15

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local playQueue, currentSong = {}, nil
local allDJs, selectedDJ = {}, nil
local selectedDJInfo = nil  -- Objeto completo del DJ seleccionado (con cover)
local currentPage = "Queue"
local currentSoundObject = nil
local progressConnection = nil

local virtualScrollState = {
	totalSongs = 0,
	songData = {},
	visibleCards = {},
	firstVisibleIndex = 1,
	lastVisibleIndex = 1,
	isSearching = false,
	searchQuery = "",
	searchResults = {},
	pendingRequests = {},
}

-- UI Elements
local quickAddBtn, quickInput, qiStroke
local isAddingToQueue = false
local songsScroll, songsContainer, searchInput, loadingIndicator, songCountLabel
local cardPool = {}
local MAX_POOL_SIZE = 25

-- Header elements para actualización dinámica
local headerCoverImage, headerGradientOverlay, headerDJName, headerSongInfo

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function isValidAudioId(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	local len = #text
	return len >= 6 and len <= 19
end

local function getRemote(name)
	local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
	if not RemotesGlobal then return end

	local remoteMap = {
		NextSong = "MusicPlayback", PlaySong = "MusicPlayback", PauseSong = "MusicPlayback", StopSong = "MusicPlayback", ChangeVolume = "MusicPlayback",
		AddToQueue = "MusicQueue", AddToQueueResponse = "MusicQueue", RemoveFromQueue = "MusicQueue",
		RemoveFromQueueResponse = "MusicQueue", ClearQueue = "MusicQueue", ClearQueueResponse = "MusicQueue",
		UpdateUI = "UI", GetDJs = "MusicLibrary", GetSongsByDJ = "MusicLibrary", GetSongRange = "MusicLibrary",
		SearchSongs = "MusicLibrary", GetSongMetadata = "MusicLibrary",
	}

	local subfolder = remoteMap[name] or "MusicLibrary"
	local folder = RemotesGlobal:FindFirstChild(subfolder)
	return folder and folder:FindFirstChild(name)
end

local function formatTime(seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function showNotification(response)
	local config = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local message = response.message or "Operación completada"
	if response.data and response.data.songName then
		message = message .. ": " .. response.data.songName
	end

	local notifyFuncs = {success = Notify.Success, warning = Notify.Warning, error = Notify.Error}
	local func = notifyFuncs[config.type] or Notify.Info
	func(Notify, config.title, message, config.type == "error" and 4 or 3)
end

local function setAddButtonState(state, customMessage)
	if not quickAddBtn or not quickInput or not qiStroke then return end

	local states = {
		loading = {adding = true, text = "...", bg = THEME.surface, stroke = THEME.surface, auto = false},
		success = {adding = false, text = "AÑADIDO", bg = Color3.fromRGB(72, 187, 120), stroke = Color3.fromRGB(72, 187, 120), clear = true, delay = 2},
		error = {adding = false, text = "ERROR", bg = THEME.btnDanger, stroke = THEME.btnDanger, clear = true, placeholder = customMessage, delay = 3},
		duplicate = {adding = false, text = "DUPLICADO", bg = THEME.warn, stroke = THEME.warn, clear = true, placeholder = customMessage or "La canción ya está en la cola", delay = 3},
		default = {adding = false, text = "AÑADIR", bg = THEME.accent, stroke = THEME.stroke, auto = true, placeholder = "Introduce ID de audio..."}
	}

	local s = states[state] or states.default
	isAddingToQueue = s.adding
	quickAddBtn.Text = s.text
	quickAddBtn.BackgroundColor3 = s.bg
	qiStroke.Color = s.stroke
	quickAddBtn.AutoButtonColor = s.auto ~= false

	if s.clear then quickInput.Text = "" end
	if s.placeholder then quickInput.PlaceholderText = s.placeholder end
	if s.delay then
		task.delay(s.delay, function()
			if quickAddBtn and qiStroke then setAddButtonState("default") end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local R = {
	Next = getRemote("NextSong"),
	Play = getRemote("PlaySong"),
	Stop = getRemote("StopSong"),
	Add = getRemote("AddToQueue"),
	AddResponse = getRemote("AddToQueueResponse"),
	Remove = getRemote("RemoveFromQueue"),
	RemoveResponse = getRemote("RemoveFromQueueResponse"),
	Clear = getRemote("ClearQueue"),
	ClearResponse = getRemote("ClearQueueResponse"),
	Update = getRemote("UpdateUI"),
	GetDJs = getRemote("GetDJs"),
	GetSongsByDJ = getRemote("GetSongsByDJ"),
	GetSongRange = getRemote("GetSongRange"),
	SearchSongs = getRemote("SearchSongs"),
	GetSongMetadata = getRemote("GetSongMetadata"),
	ChangeVolume = getRemote("ChangeVolume"),
}

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicDashboardUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ✅ DETECTAR MÓVIL justo antes de crear modal (asegura que UserInputService esté listo)
task.wait(0.5)  -- Pequeña espera para asegurar que UserInputService esté completamente inicializado
local isMobileDevice = UserInputService.TouchEnabled

-- Valores responsivos para componentes del dashboard
local HEADER_HEIGHT_BASE = 140
local HEADER_HEIGHT = isMobileDevice and 100 or HEADER_HEIGHT_BASE
local CONTENT_PADDING = isMobileDevice and 10 or 20
local NOW_PLAYING_HEIGHT = isMobileDevice and 50 or 70
local MINI_COVER_SIZE = isMobileDevice and 40 or 56
local CONTROLS_HEIGHT = isMobileDevice and 28 or 32

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════

local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "MusicDashboard",
	panelWidth = PANEL_W_PX,
	panelHeight = PANEL_H_PX,
	cornerRadius = R_PANEL,
	enableBlur = ENABLE_BLUR,
	blurSize = BLUR_SIZE,
	isMobile = isMobileDevice,  -- ✅ PASAR la detección de móvil
	onClose = function()
		-- Limpiar conexiones cuando se cierre
		if progressConnection then
			progressConnection:Disconnect()
			progressConnection = nil
		end
	end
})

local panel = modal:getPanel()
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- HEADER SPOTIFY STYLE
-- ════════════════════════════════════════════════════════════════

local header = UI.frame({name = "Header", size = UDim2.new(1, 0, 0, HEADER_HEIGHT), pos = UDim2.new(0, 0, 0, 0), bg = Color3.fromRGB(18, 18, 22), z = 102, parent = panel, corner = 16, clip = true})

-- Cover de fondo (blur effect) - Muestra el DJ de la canción actual
headerCoverImage = Instance.new("ImageLabel")
headerCoverImage.Name = "CoverBackground"
headerCoverImage.Size = UDim2.new(1, 0, 1, 0)
headerCoverImage.Position = UDim2.new(0, 0, 0, 0)
headerCoverImage.BackgroundTransparency = 1
headerCoverImage.Image = ""
headerCoverImage.ImageTransparency = 0.5
headerCoverImage.ScaleType = Enum.ScaleType.Crop
headerCoverImage.ZIndex = 102
headerCoverImage.Parent = header
UI.rounded(headerCoverImage, 16)

-- Gradient overlay sobre el cover
headerGradientOverlay = Instance.new("Frame")
headerGradientOverlay.Name = "GradientOverlay"
headerGradientOverlay.Size = UDim2.new(1, 0, 1, 0)
headerGradientOverlay.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
headerGradientOverlay.BackgroundTransparency = 0.3
headerGradientOverlay.BorderSizePixel = 0
headerGradientOverlay.ZIndex = 103
headerGradientOverlay.Parent = header
UI.rounded(headerGradientOverlay, 16)

local overlayGradient = Instance.new("UIGradient")
overlayGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(18, 18, 22)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 38))
}
overlayGradient.Rotation = 90
overlayGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.4),
	NumberSequenceKeypoint.new(1, 0.7)
}
overlayGradient.Parent = headerGradientOverlay

-- Container para el contenido del header
local headerContent = Instance.new("Frame")
headerContent.Name = "Content"
-- Margen interior responsivo para título y controles
headerContent.Size = UDim2.new(1, -CONTENT_PADDING*2, 1, -CONTENT_PADDING)
headerContent.Position = UDim2.new(0, CONTENT_PADDING, 0, CONTENT_PADDING/2)
headerContent.BackgroundTransparency = 1
headerContent.ZIndex = 104
headerContent.Parent = header

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 140, 0, 28)
title.BackgroundTransparency = 1
title.Text = "MÚSICA"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 105
title.Parent = headerContent



-- ════════════════════════════════════════════════════════════════
-- CONTROLES ROW (Volumen + Skip + Clear)
-- ════════════════════════════════════════════════════════════════
local controlsRow = Instance.new("Frame")
controlsRow.Name = "ControlsRow"
-- Usar todo el ancho interior del headerContent y dejar margen interno gestionado por UIPadding
controlsRow.Size = UDim2.new(1, 0, 0, CONTROLS_HEIGHT)
controlsRow.Position = UDim2.new(0, 0, 0, 6)
controlsRow.BackgroundTransparency = 1
controlsRow.ZIndex = 105
controlsRow.Parent = headerContent

local controlsPadding = Instance.new("UIPadding")
controlsPadding.PaddingRight = UDim.new(0, 12)
controlsPadding.PaddingLeft = UDim.new(0, 0)
controlsPadding.PaddingTop = UDim.new(0, 0)
controlsPadding.PaddingBottom = UDim.new(0, 0)
controlsPadding.Parent = controlsRow

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
controlsLayout.Padding = UDim.new(0, 10)
controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlsLayout.Parent = controlsRow

-- Spacer para empujar a la derecha (antes del close btn)
local controlsSpacer = Instance.new("Frame")
controlsSpacer.Size = UDim2.new(0, 10, 0, CONTROLS_HEIGHT)
controlsSpacer.BackgroundTransparency = 1
controlsSpacer.LayoutOrder = 0
controlsSpacer.Parent = controlsRow

-- CLEAR button (solo admin)
local clearB = nil
if isAdmin then
	clearB = Instance.new("TextButton")
	clearB.Name = "ClearBtn"
	clearB.Size = UDim2.new(0, 70, 0, CONTROLS_HEIGHT)
	clearB.BackgroundColor3 = Color3.fromRGB(161, 124, 72)
	clearB.Text = "CLEAR"
	clearB.TextColor3 = Color3.new(1, 1, 1)
	clearB.Font = Enum.Font.GothamBold
	clearB.TextSize = 13
	clearB.BorderSizePixel = 0
	clearB.LayoutOrder = 3
	clearB.ZIndex = 105
	clearB.Parent = controlsRow
	UI.rounded(clearB, 6)
end

-- SKIP button
local skipB = Instance.new("TextButton")
skipB.Name = "SkipBtn"
skipB.Size = UDim2.new(0, 70, 0, CONTROLS_HEIGHT)
skipB.BackgroundColor3 = THEME.accent
skipB.Text = "SKIP"
skipB.TextColor3 = Color3.new(1, 1, 1)
skipB.Font = Enum.Font.GothamBold
skipB.TextSize = 13
skipB.BorderSizePixel = 0
skipB.LayoutOrder = 2
skipB.ZIndex = 105
skipB.Parent = controlsRow
UI.rounded(skipB, 6)

-- Volume control container
local volFrame = Instance.new("Frame")
volFrame.Name = "VolumeControl"
volFrame.Size = UDim2.new(0, 145, 0, CONTROLS_HEIGHT)
volFrame.BackgroundTransparency = 1
volFrame.LayoutOrder = 1
volFrame.ZIndex = 105
volFrame.Parent = controlsRow

local volSliderBg = Instance.new("Frame")
volSliderBg.Size = UDim2.new(0, 90, 0, CONTROLS_HEIGHT-2)
volSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
volSliderBg.BorderSizePixel = 0
volSliderBg.ZIndex = 105
volSliderBg.Parent = volFrame
UI.rounded(volSliderBg, 6)

local volSliderFill = Instance.new("Frame")
volSliderFill.Size = UDim2.new(1, 0, 1, 0)
volSliderFill.BackgroundColor3 = THEME.accent
volSliderFill.BorderSizePixel = 0
volSliderFill.ZIndex = 106
volSliderFill.Parent = volSliderBg
UI.rounded(volSliderFill, 6)

local volLabel = Instance.new("ImageButton")
volLabel.Size = UDim2.new(0, 50, 0, CONTROLS_HEIGHT-2)
volLabel.Position = UDim2.new(0, 95, 0, 0)
volLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
volLabel.Image = "rbxassetid://14861812886"
volLabel.ImageTransparency = 1  -- Oculta por defecto
volLabel.ScaleType = Enum.ScaleType.Fit
volLabel.BorderSizePixel = 0
volLabel.ZIndex = 105
volLabel.AutoButtonColor = false
volLabel.Parent = volFrame
UI.rounded(volLabel, 6)

-- TextLabel dentro del ImageButton para mostrar el porcentaje
local volLabelText = Instance.new("TextLabel")
volLabelText.Size = UDim2.new(1, 0, 1, 0)
volLabelText.BackgroundTransparency = 1
volLabelText.Text = "100%"
volLabelText.TextColor3 = THEME.text
volLabelText.Font = Enum.Font.GothamBold
volLabelText.TextSize = 13
volLabelText.ZIndex = 106
volLabelText.Parent = volLabel

local volInput = Instance.new("TextBox")
volInput.Size = volLabel.Size
volInput.Position = volLabel.Position
volInput.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
volInput.Text = "100"
volInput.TextColor3 = THEME.text
volInput.Font = Enum.Font.GothamBold
volInput.TextSize = 13
volInput.BorderSizePixel = 0
volInput.ZIndex = 106
volInput.Visible = false
volInput.ClearTextOnFocus = true
volInput.MultiLine = false
volInput.TextXAlignment = Enum.TextXAlignment.Center
volInput.Parent = volFrame
UI.rounded(volInput, 6)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, isMobileDevice and 32 or 36, 0, isMobileDevice and 32 or 36)
closeBtn.BackgroundColor3 = THEME.card
closeBtn.BackgroundTransparency = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = THEME.muted
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = isMobileDevice and 20 or 22
closeBtn.ZIndex = 103
-- Insertar dinámicamente dentro de controlsRow para alinearlo con los controles
closeBtn.LayoutOrder = 1000
closeBtn.Parent = controlsRow
UI.rounded(closeBtn, 8)
UI.stroked(closeBtn, 0.4)
-- ════════════════════════════════════════════════════════════════
-- NOW PLAYING SECTION
-- ════════════════════════════════════════════════════════════════
local nowPlayingSection = Instance.new("Frame")
nowPlayingSection.Name = "NowPlaying"
nowPlayingSection.Size = UDim2.new(1, 0, 0, NOW_PLAYING_HEIGHT)
nowPlayingSection.Position = UDim2.new(0, 0, 0, isMobileDevice and 32 or 36)
nowPlayingSection.BackgroundTransparency = 1
nowPlayingSection.ZIndex = 104
nowPlayingSection.Parent = headerContent

-- Mini cover del DJ actual
local miniCover = Instance.new("ImageLabel")
miniCover.Name = "MiniCover"
miniCover.Size = UDim2.new(0, MINI_COVER_SIZE, 0, MINI_COVER_SIZE)
miniCover.Position = UDim2.new(0, 0, 0, 4)
-- Hacemos el fondo transparente para que la imagen respete el corner y se vea limpia
miniCover.BackgroundTransparency = 1
miniCover.Image = ""
miniCover.ScaleType = Enum.ScaleType.Crop
miniCover.ZIndex = 105
miniCover.Parent = nowPlayingSection
miniCover.ClipsDescendants = true
UI.rounded(miniCover, 8)

local miniCoverStroke = Instance.new("UIStroke")
miniCoverStroke.Color = THEME.accent
miniCoverStroke.Thickness = 2
miniCoverStroke.Transparency = 0.5
miniCoverStroke.Parent = miniCover

-- Song info
local songInfoFrame = Instance.new("Frame")
songInfoFrame.Size = UDim2.new(1, -MINI_COVER_SIZE-80, 0, isMobileDevice and 16 or 22)
songInfoFrame.Position = UDim2.new(0, MINI_COVER_SIZE+12, 0, 2)
songInfoFrame.BackgroundTransparency = 1
songInfoFrame.ZIndex = 105
songInfoFrame.Parent = nowPlayingSection

local songTitle = Instance.new("TextLabel")
songTitle.Name = "SongTitle"
songTitle.Size = UDim2.new(1, 0, 1, 0)
songTitle.BackgroundTransparency = 1
songTitle.Text = "No song playing"
songTitle.TextColor3 = THEME.text
songTitle.Font = Enum.Font.GothamBold
songTitle.TextSize = isMobileDevice and 13 or 18
songTitle.TextXAlignment = Enum.TextXAlignment.Left
songTitle.TextTruncate = Enum.TextTruncate.AtEnd
songTitle.ZIndex = 105
songTitle.Parent = songInfoFrame

-- DJ Name (creado una sola vez con propiedades dinámicas)
-- Contenedor para DJ name y Song ID (alineados horizontalmente junto al mini cover)
local headerNameContainer = Instance.new("Frame")
headerNameContainer.Name = "HeaderNameRow"
headerNameContainer.Size = UDim2.new(1, -MINI_COVER_SIZE-12, 0, isMobileDevice and 16 or 18)
headerNameContainer.Position = UDim2.new(0, MINI_COVER_SIZE+12, 0, isMobileDevice and 20 or 26)
headerNameContainer.BackgroundTransparency = 1
headerNameContainer.ZIndex = 105
headerNameContainer.Parent = nowPlayingSection

local headerNameLayout = Instance.new("UIListLayout")
headerNameLayout.FillDirection = Enum.FillDirection.Horizontal
headerNameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
headerNameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerNameLayout.Padding = UDim.new(0, 8)
headerNameLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerNameLayout.Parent = headerNameContainer

-- DJ Name (creado una sola vez con propiedades dinámicas)
headerDJName = Instance.new("TextLabel")
headerDJName.Name = "DJName"
headerDJName.Size = UDim2.new(0, isMobileDevice and 120 or 220, 1, 0)
headerDJName.BackgroundTransparency = 1
headerDJName.Text = ""
headerDJName.TextColor3 = THEME.muted
headerDJName.Font = Enum.Font.GothamMedium
headerDJName.TextSize = isMobileDevice and 10 or 15
headerDJName.TextXAlignment = Enum.TextXAlignment.Left
headerDJName.TextTruncate = Enum.TextTruncate.AtEnd
headerDJName.LayoutOrder = 1
headerDJName.ZIndex = 105
headerDJName.Parent = headerNameContainer

-- Song ID visible en header (alineado a la derecha del DJ name)
local headerSongID = Instance.new("TextLabel")
headerSongID.Name = "SongID"
headerSongID.Size = UDim2.new(0, isMobileDevice and 110 or 150, 1, 0)
headerSongID.BackgroundTransparency = 1
headerSongID.Text = ""
headerSongID.TextColor3 = THEME.text
headerSongID.Font = Enum.Font.GothamBold
headerSongID.TextSize = isMobileDevice and 11 or 14
headerSongID.TextXAlignment = Enum.TextXAlignment.Left
headerSongID.LayoutOrder = 2
headerSongID.ZIndex = 108
headerSongID.Parent = headerNameContainer


-- Progress bar (alineado abajo en PC, al lado en mobile)
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(isMobileDevice and 1 or 1, isMobileDevice and -MINI_COVER_SIZE-100 or -MINI_COVER_SIZE-80, 0, 18)
progressContainer.Position = UDim2.new(0, isMobileDevice and MINI_COVER_SIZE+97 or MINI_COVER_SIZE+12, 0, isMobileDevice and 20 or 48)
progressContainer.BackgroundTransparency = 1
progressContainer.ZIndex = 105
progressContainer.Parent = nowPlayingSection

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(1, -100, 0, isMobileDevice and 4 or 6)
progressBar.Position = UDim2.new(0, 0, 0.5, isMobileDevice and -2 or -3)
progressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 105
progressBar.Parent = progressContainer
UI.rounded(progressBar, 3)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.accent
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 106
progressFill.Parent = progressBar
UI.rounded(progressFill, 3)

local currentTimeLabel = Instance.new("TextLabel")
currentTimeLabel.Size = UDim2.new(0, 45, 1, 0)
currentTimeLabel.Position = UDim2.new(1, -90, 0, 0)
currentTimeLabel.BackgroundTransparency = 1
currentTimeLabel.Text = "0:00"
currentTimeLabel.TextColor3 = THEME.muted
currentTimeLabel.Font = Enum.Font.GothamMedium
currentTimeLabel.TextSize = isMobileDevice and 11 or 14
currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
currentTimeLabel.ZIndex = 105
currentTimeLabel.Parent = progressContainer

local timeSeparator = Instance.new("TextLabel")
timeSeparator.Size = UDim2.new(0, 10, 1, 0)
timeSeparator.Position = UDim2.new(1, -45, 0, 0)
timeSeparator.BackgroundTransparency = 1
timeSeparator.Text = "/"
timeSeparator.TextColor3 = THEME.muted
timeSeparator.Font = Enum.Font.GothamMedium
timeSeparator.TextSize = isMobileDevice and 11 or 14
timeSeparator.ZIndex = 105
timeSeparator.Parent = progressContainer

local totalTimeLabel = Instance.new("TextLabel")
totalTimeLabel.Size = UDim2.new(0, 45, 1, 0)
totalTimeLabel.Position = UDim2.new(1, -35, 0, 0)
totalTimeLabel.BackgroundTransparency = 1
totalTimeLabel.Text = "0:00"
totalTimeLabel.TextColor3 = THEME.muted
totalTimeLabel.Font = Enum.Font.GothamMedium
totalTimeLabel.TextSize = isMobileDevice and 11 or 14
totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
totalTimeLabel.ZIndex = 105
totalTimeLabel.Parent = progressContainer

-- ════════════════════════════════════════════════════════════════
-- VOLUME LOGIC
-- ════════════════════════════════════════════════════════════════
local defaultVol = MusicSystemConfig.PLAYBACK.DefaultVolume
local savedVolume = player:GetAttribute("MusicVolume") or defaultVol
local currentVolume = savedVolume
local dragging = false

local maxVolume = MusicSystemConfig.PLAYBACK.MaxVolume
local minVolume = MusicSystemConfig.PLAYBACK.MinVolume

-- Sistema de mute sincronizado con el topbar
local function isMusicMuted()
	return _G.MusicMutedState or false
end

local function updateVolume(volume)
	currentVolume = math.clamp(volume, minVolume, maxVolume)
	local sliderFill = (currentVolume - minVolume) / (maxVolume - minVolume)
	volSliderFill.Size = UDim2.new(sliderFill, 0, 1, 0)

	-- Mostrar estado de mute en la etiqueta
	if isMusicMuted() then
		-- Muteado: mostrar imagen PRO, ocultar texto
		volLabel.ImageTransparency = 0
		volLabelText.Text = ""
		volLabel.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	else
		-- No muteado: ocultar imagen, mostrar porcentaje
		volLabel.ImageTransparency = 1
		volLabelText.Text = math.floor(currentVolume * 100) .. "%"
		volLabelText.TextColor3 = THEME.text
		volLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
	end

	volInput.Text = tostring(math.floor(currentVolume * 100))
	player:SetAttribute("MusicVolume", currentVolume)

	--  APLICAR VOLUMEN LOCALMENTE (respetando el mute del topbar)
	local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup")
	if musicSoundGroup then
		-- Si está muteado, mantener volumen a 0, aunque cambies el slider
		if isMusicMuted() then
			musicSoundGroup.Volume = 0
		else
			musicSoundGroup.Volume = currentVolume
		end
	end

	-- Notificar servidor del cambio de volumen usando el remote
	if R and R.ChangeVolume then
		pcall(function() R.ChangeVolume:FireServer(currentVolume) end)
	end
end

-- Monitorear cambios en el estado de mute del topbar
local lastMuteState = isMusicMuted()
task.spawn(function()
	while true do
		task.wait(0.1)
		local currentMuteState = isMusicMuted()
		if currentMuteState ~= lastMuteState then
			-- El estado de mute cambió
			lastMuteState = currentMuteState
			local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup")
			if musicSoundGroup then
				if currentMuteState then
					-- Se activó el mute: guardar volumen actual y poner a 0
					musicSoundGroup.Volume = 0
					-- Mostrar imagen PRO, ocultar texto
					volLabel.ImageTransparency = 0
					volLabelText.Text = ""
					volLabel.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
					-- Deshabilitar slider visualmente
					TweenService:Create(volSliderBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 30, 30)}):Play()
					volSliderFill.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
				else
					-- Se desactivó el mute: restaurar volumen guardado
					musicSoundGroup.Volume = currentVolume
					-- Ocultar imagen, mostrar porcentaje
					volLabel.ImageTransparency = 1
					volLabelText.Text = math.floor(currentVolume * 100) .. "%"
					volLabelText.TextColor3 = THEME.text
					volLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
					-- Restaurar apariencia del slider
					TweenService:Create(volSliderBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
					volSliderFill.BackgroundColor3 = THEME.accent
				end
			end
		end
	end
end)

updateVolume(currentVolume)

volSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isMusicMuted() then
			-- Mostrar notificación si está muteado
			if Notify then
				Notify:Info("Música Silenciada", "Desmutea el sonido en el topbar para cambiar el volumen", 2)
			end
			return
		end
		dragging = true
		local pos = math.clamp((input.Position.X - volSliderBg.AbsolutePosition.X) / volSliderBg.AbsoluteSize.X, 0, 1)
		updateVolume(pos)
	end
end)

volSliderBg.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

volSliderBg.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local pos = math.clamp((input.Position.X - volSliderBg.AbsolutePosition.X) / volSliderBg.AbsoluteSize.X, 0, 1)
		updateVolume(pos)
	end
end)

volLabel.MouseButton1Click:Connect(function()
	if isMusicMuted() then
		-- Mostrar notificación si está muteado
		if Notify then
			Notify:Info("Música Silenciada", "Desmutea el sonido en el topbar para cambiar el volumen", 2)
		end
		return
	end
	volInput.Visible = true
	volInput:CaptureFocus()
	volInput.Text = tostring(math.floor(currentVolume * 100))
end)

volInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = volInput.Text:gsub("[^%d]", "")
	if #text > 3 then text = string.sub(text, 1, 3) end
	local value = tonumber(text)
	local maxPercent = math.floor(maxVolume * 100)
	if value and value > maxPercent then text = tostring(maxPercent) end
	volInput.Text = text
end)

local function applyVolumeInput()
	local value = tonumber(volInput.Text) or 100
	local maxPercent = math.floor(maxVolume * 100)
	value = math.clamp(value, 0, maxPercent)
	updateVolume(value / 100)
	volInput.Visible = false
	volLabel.Visible = true
end

volInput.FocusLost:Connect(function(enterPressed)
	applyVolumeInput()
end)

-- También permitir presionar Enter para aplicar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Return and volInput.Visible and volInput:IsFocused() then
		applyVolumeInput()
	end
end)

volLabel.MouseEnter:Connect(function()
	if isMusicMuted() then
		TweenService:Create(volLabel, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(140, 60, 60)}):Play()
	else
		TweenService:Create(volLabel, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 70, 80)}):Play()
	end
end)

volLabel.MouseLeave:Connect(function()
	if isMusicMuted() then
		TweenService:Create(volLabel, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 50, 50)}):Play()
	else
		TweenService:Create(volLabel, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- SKIP/CLEAR LOGIC
-- ════════════════════════════════════════════════════════════════
local skipProductId = 3468988018

-- Use el Remote `PurchaseSkip` en `RemotesGlobal/MusicQueue` (no usar Panda)
local skipRemote = ReplicatedStorage:WaitForChild("RemotesGlobal")
	:WaitForChild("MusicQueue")
	:WaitForChild("PurchaseSkip")

-- Cooldown para skip
local lastSkipTime = 0
local skipCooldown = MusicSystemConfig.LIMITS.SkipCooldown or 3

-- Botón Skip
skipB.MouseButton1Click:Connect(function()
	local now = tick()
	local timeSinceSkip = now - lastSkipTime

	-- Validar cooldown (SOLO para jugadores normales, NO para admins)
	if not isAdmin and timeSinceSkip < skipCooldown then
		if Notify then
			Notify:Info("Cooldown", "Espera " .. math.ceil(skipCooldown - timeSinceSkip) .. " segundos")
		end
		skipB.Enabled = false
		return
	end

	lastSkipTime = now

	if isAdmin then
		if R.Next then
			R.Next:FireServer()
		end
	else
		MarketplaceService:PromptProductPurchase(player, skipProductId)
	end
end)

-- Botón Clear (si existe)
if clearB then
	clearB.MouseButton1Click:Connect(function()
		if R.Clear then
			R.Clear:FireServer()
		end
	end)
end

-- Cuando la compra termina con éxito -> SKIP automático
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	-- Comparar UserId, no el objeto Player
	if userId ~= player.UserId then return end
	if productId ~= skipProductId then return end
	if not wasPurchased then return end

	if skipRemote then
		pcall(function()
			skipRemote:FireServer(true)
		end)
	end
end)

-- ═════════════════════════════════════════════════════════
-- NAVIGATION BAR
-- ════════════════════════════════════════════════════════════════
-- Colocar la barra de navegación justo debajo del header sin margen extra
local NAV_TOP = HEADER_HEIGHT

local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(1, 0, 0, 36)
navBar.Position = UDim2.new(0, 0, 0, NAV_TOP)
navBar.BackgroundTransparency = 1
navBar.BorderSizePixel = 0
navBar.ZIndex = 101
navBar.Parent = panel

local navList = Instance.new("UIListLayout")
navList.FillDirection = Enum.FillDirection.Horizontal
navList.Padding = UDim.new(0, 12)
navList.Parent = navBar

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 20)
navPadding.PaddingTop = UDim.new(0, 6)
navPadding.Parent = navBar

local function createTab(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 0, 24)
	btn.BackgroundTransparency = 1
	btn.Text = text
	btn.TextColor3 = THEME.muted
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Parent = navBar
	return btn
end

local tQueue = createTab("EN COLA")
local tLibrary = createTab("BIBLIOTECA")

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, NAV_TOP + 33)
underline.BackgroundColor3 = THEME.accent
underline.BorderSizePixel = 0
underline.ZIndex = 102
underline.Parent = panel
UI.rounded(underline, 2)

-- ════════════════════════════════════════════════════════════════
-- CONTENT HOLDER
-- ════════════════════════════════════════════════════════════════
local CONTENT_TOP = NAV_TOP + 36

local holder = Instance.new("Frame")
holder.Name = "PageHolder"
holder.Size = UDim2.new(1, 0, 1, -CONTENT_TOP)
holder.Position = UDim2.new(0, 0, 0, CONTENT_TOP)
holder.BackgroundTransparency = 1
holder.BorderSizePixel = 0
holder.ZIndex = 100
holder.ClipsDescendants = true
holder.Parent = panel

local pageLayout = Instance.new("UIPageLayout")
pageLayout.FillDirection = Enum.FillDirection.Horizontal
pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pageLayout.EasingStyle = Enum.EasingStyle.Quad
pageLayout.EasingDirection = Enum.EasingDirection.Out
pageLayout.TweenTime = 0.25
pageLayout.Padding = UDim.new(0, 0)
pageLayout.ScrollWheelInputEnabled = false
pageLayout.TouchInputEnabled = false
pageLayout.Parent = holder

-- ════════════════════════════════════════════════════════════════
-- QUEUE PAGE
-- ════════════════════════════════════════════════════════════════
local queuePage = Instance.new("Frame")
queuePage.Name = "Queue"
queuePage.Size = UDim2.new(1, 0, 1, 0)
queuePage.BackgroundTransparency = 1
queuePage.LayoutOrder = 1
queuePage.Parent = holder

local quickAddFrame = Instance.new("Frame")
quickAddFrame.Size = UDim2.new(1, -24, 0, 36)
quickAddFrame.Position = UDim2.new(0, 12, 0, 8)
quickAddFrame.BackgroundColor3 = THEME.card
quickAddFrame.BorderSizePixel = 0
quickAddFrame.Parent = queuePage
UI.rounded(quickAddFrame, 8)
qiStroke = UI.stroked(quickAddFrame, 0.3)

quickInput = Instance.new("TextBox")
quickInput.Size = UDim2.new(1, -80, 1, 0)
quickInput.Position = UDim2.new(0, 10, 0, 0)
quickInput.BackgroundTransparency = 1
quickInput.Text = ""
quickInput.PlaceholderText = "Enter Audio ID..."
quickInput.TextColor3 = THEME.text
quickInput.PlaceholderColor3 = THEME.muted
quickInput.Font = Enum.Font.Gotham
quickInput.TextSize = 14
quickInput.TextXAlignment = Enum.TextXAlignment.Left
quickInput.ClearTextOnFocus = false
quickInput.Parent = quickAddFrame

quickInput:GetPropertyChangedSignal("Text"):Connect(function()
	if #quickInput.Text > 19 then quickInput.Text = string.sub(quickInput.Text, 1, 19) end
end)

quickAddBtn = Instance.new("TextButton")
quickAddBtn.Size = UDim2.new(0, 60, 0, 26)
quickAddBtn.Position = UDim2.new(1, -65, 0.5, -13)
quickAddBtn.BackgroundColor3 = THEME.accent
quickAddBtn.Text = "ADD"
quickAddBtn.TextColor3 = Color3.new(1, 1, 1)
quickAddBtn.Font = Enum.Font.GothamBold
quickAddBtn.TextSize = 12
quickAddBtn.BorderSizePixel = 0
quickAddBtn.Parent = quickAddFrame
UI.rounded(quickAddBtn, 6)

quickAddBtn.MouseButton1Click:Connect(function()
	if isAddingToQueue then return end
	local aid = quickInput.Text:gsub("%s+", "")
	if not isValidAudioId(aid) then
		Notify:Warning("ID Inválido", "Ingresa un ID válido (6-19 dígitos)", 3)
		setAddButtonState("error", "Invalid Audio ID")
		return
	end
	setAddButtonState("loading")
	if R.Add then R.Add:FireServer(tonumber(aid)) end
end)

-- Response handlers
if R.AddResponse then
	R.AddResponse.OnClientEvent:Connect(function(response)
		if not response then return end
		showNotification(response)

		if response.success then
			setAddButtonState("success")
		elseif response.code == ResponseCodes.ERROR_DUPLICATE then
			setAddButtonState("duplicate", response.message)
		else
			setAddButtonState("error", response.message)
		end

		task.defer(function()
			if currentPage == "Library" and #cardPool > 0 then
				for _, card in ipairs(cardPool) do
					if card.Visible then
						local addBtn = card:FindFirstChild("AddButton")
						if addBtn and addBtn.Text == "..." then
							if response.success or response.code == ResponseCodes.ERROR_DUPLICATE then
								addBtn.Text = "EN COLA"
								addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
								addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
								addBtn.AutoButtonColor = false
							else
								addBtn.Text = "AÑADIR"
								addBtn.BackgroundColor3 = THEME.accent
								addBtn.TextColor3 = THEME.text
								addBtn.AutoButtonColor = true
							end
						end
					end
				end
			end
		end)
	end)
end

if R.RemoveResponse then
	R.RemoveResponse.OnClientEvent:Connect(function(response)
		if response then showNotification(response) end
	end)
end

if R.ClearResponse then
	R.ClearResponse.OnClientEvent:Connect(function(response)
		if response then showNotification(response) end
	end)
end

-- Queue Scroll
local queueScroll = Instance.new("ScrollingFrame")
queueScroll.Size = UDim2.new(1, -24, 1, -56)
queueScroll.Position = UDim2.new(0, 12, 0, 52)
queueScroll.BackgroundTransparency = 1
queueScroll.BorderSizePixel = 0
queueScroll.ScrollBarThickness = 6
queueScroll.ScrollBarImageColor3 = THEME.stroke
queueScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
queueScroll.ClipsDescendants = true
queueScroll.Parent = queuePage

local queueScrollPadding = Instance.new("UIPadding")
queueScrollPadding.PaddingLeft = UDim.new(0, 4)
queueScrollPadding.PaddingRight = UDim.new(0, 4)
queueScrollPadding.PaddingTop = UDim.new(0, 4)
queueScrollPadding.PaddingBottom = UDim.new(0, 4)
queueScrollPadding.Parent = queueScroll

local queueList = Instance.new("UIListLayout")
queueList.Padding = UDim.new(0, 6)
queueList.SortOrder = Enum.SortOrder.LayoutOrder
queueList.Parent = queueScroll

queueList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	queueScroll.CanvasSize = UDim2.new(0, 0, 0, queueList.AbsoluteContentSize.Y + 16)
end)

local function drawQueue()
	for _, child in pairs(queueScroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	if #playQueue == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "Queue is empty\nAdd songs from the library"
		empty.TextColor3 = THEME.muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.TextWrapped = true
		empty.Parent = queueScroll
		return
	end

	for i, song in ipairs(playQueue) do
		local isActive = currentSong and song.id == currentSong.id
		local userId = song.userId or song.requestedByUserId

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 54)
		card.BackgroundColor3 = isActive and THEME.accent or THEME.card
		card.BorderSizePixel = 0
		card.Parent = queueScroll
		UI.rounded(card, 8)
		UI.stroked(card, isActive and 0.6 or 0.3)

		if isActive then
			local glowStroke = Instance.new("UIStroke")
			glowStroke.Color = THEME.avatarRingGlow or THEME.accent
			glowStroke.Thickness = 1.2
			glowStroke.Transparency = 0.3
			glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			glowStroke.Parent = card

			task.spawn(function()
				while card.Parent and isActive do
					TweenService:Create(glowStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0, Thickness = 1.6}):Play()
					task.wait(1)
					TweenService:Create(glowStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.5, Thickness = 1.2}):Play()
					task.wait(1)
				end
			end)

			local gradientEffect = Instance.new("UIGradient")
			gradientEffect.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(68, 72, 100)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 32))
			}
			gradientEffect.Transparency = NumberSequence.new(0.3)
			gradientEffect.Offset = Vector2.new(-1, 0)
			gradientEffect.Parent = card

			task.spawn(function()
				while card.Parent and isActive do
					TweenService:Create(gradientEffect, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)}):Play()
					task.wait(2.5)
					gradientEffect.Offset = Vector2.new(-1, 0)
					task.wait(0.5)
				end
			end)
		end

		local avatarOffset = 4
		local contentLeft = avatarOffset

		if userId then
			local avatar = Instance.new("ImageLabel")
			avatar.Size = UDim2.new(0, 44, 0, 44)
			avatar.Position = UDim2.new(0, avatarOffset, 0.5, -22)
			avatar.BackgroundTransparency = 1
			avatar.ZIndex = 2
			avatar.Parent = card
			UI.rounded(avatar, 22)

			local border = Instance.new("UIStroke")
			border.Color = isActive and THEME.accent or Color3.fromRGB(100, 100, 110)
			border.Thickness = isActive and 2 or 1.5
			border.Parent = avatar

			task.spawn(function()
				local success, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if success then avatar.Image = thumb end
			end)
			contentLeft = avatarOffset + 44 + 8
		end

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, avatarOffset)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = card

		local nameFrame = Instance.new("Frame")
		nameFrame.Size = UDim2.new(1, -140, 0, 18)
		nameFrame.Position = UDim2.new(0, contentLeft, 0, 8)
		nameFrame.BackgroundTransparency = 1
		nameFrame.ZIndex = 2
		nameFrame.ClipsDescendants = true
		nameFrame.Parent = card

		local nameText = Instance.new("TextLabel")
		nameText.Size = UDim2.new(1, 0, 1, 0)
		nameText.BackgroundTransparency = 1
		nameText.Text = (song.name or "Unknown") .. "  |  Añadido por " .. (song.requestedBy or "Unknown")
		nameText.TextColor3 = isActive and Color3.new(1, 1, 1) or THEME.text
		nameText.Font = Enum.Font.GothamMedium
		nameText.TextSize = 13
		nameText.TextXAlignment = Enum.TextXAlignment.Left
		nameText.TextTruncate = Enum.TextTruncate.AtEnd
		nameText.ZIndex = 2
		nameText.Parent = nameFrame

		local artist = Instance.new("TextLabel")
		artist.Size = UDim2.new(1, -140, 0, 14)
		artist.Position = UDim2.new(0, contentLeft, 0, 28)
		artist.BackgroundTransparency = 1
		artist.Text = song.artist or "Unknown Artist"
		artist.TextColor3 = isActive and Color3.fromRGB(220, 220, 230) or THEME.muted
		artist.Font = Enum.Font.Gotham
		artist.TextSize = 12
		artist.TextXAlignment = Enum.TextXAlignment.Left
		artist.TextTruncate = Enum.TextTruncate.AtEnd
		artist.ZIndex = 2
		artist.Parent = card

		if isAdmin then
			local removeBtn = Instance.new("TextButton")
			removeBtn.Size = UDim2.new(0, 70, 0, 30)
			removeBtn.Position = UDim2.new(1, -75, 0.5, -15)
			removeBtn.BackgroundColor3 = THEME.btnDanger
			removeBtn.Text = "REMOVE"
			removeBtn.TextColor3 = Color3.new(1, 1, 1)
			removeBtn.Font = Enum.Font.GothamBold
			removeBtn.TextSize = 11
			removeBtn.BorderSizePixel = 0
			removeBtn.ZIndex = 2
			removeBtn.Parent = card
			UI.rounded(removeBtn, 6)

			removeBtn.MouseButton1Click:Connect(function()
				if R.Remove then R.Remove:FireServer(i) end
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- LIBRARY PAGE
-- ════════════════════════════════════════════════════════════════
local libraryPage = Instance.new("Frame")
libraryPage.Name = "Library"
libraryPage.Size = UDim2.new(1, 0, 1, 0)
libraryPage.BackgroundTransparency = 1
libraryPage.LayoutOrder = 2
libraryPage.Parent = holder

-- DJs Grid
local djsScroll = Instance.new("ScrollingFrame")
djsScroll.Size = UDim2.new(1, -24, 1, -16)
djsScroll.Position = UDim2.new(0, 12, 0, 8)
djsScroll.BackgroundTransparency = 1
djsScroll.BorderSizePixel = 0
djsScroll.ScrollBarThickness = 6
djsScroll.ScrollBarImageColor3 = THEME.stroke
djsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
djsScroll.Parent = libraryPage

local djsLayout = Instance.new("UIGridLayout")
djsLayout.CellSize = UDim2.new(0, 200, 0, 200)
djsLayout.CellPadding = UDim2.new(0, 12, 0, 12)
djsLayout.SortOrder = Enum.SortOrder.LayoutOrder
djsLayout.FillDirection = Enum.FillDirection.Horizontal
djsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
djsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
djsLayout.Parent = djsScroll

djsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	djsScroll.CanvasSize = UDim2.new(0, 0, 0, djsLayout.AbsoluteContentSize.Y + 24)
end)

-- ════════════════════════════════════════════════════════════════
-- SONGS VIEW (VIRTUALIZADA)
-- ════════════════════════════════════════════════════════════════
local songsView = Instance.new("Frame")
songsView.Name = "SongsView"
songsView.Size = UDim2.new(1, 0, 1, 0)
songsView.BackgroundTransparency = 1
songsView.Visible = false
songsView.Parent = libraryPage

local songsHeader = Instance.new("Frame")
songsHeader.Size = UDim2.new(1, -24, 0, 44)
songsHeader.Position = UDim2.new(0, 12, 0, 8)
songsHeader.BackgroundTransparency = 1
songsHeader.Parent = songsView

local backBtn = UI.button({size = UDim2.new(0, 36, 0, 36), pos = UDim2.new(0, 4, 0.5, -18), bg = THEME.card, text = "‹", color = THEME.text, textSize = 22, font = Enum.Font.GothamBold, z = 107, parent = songsHeader, corner = 8})

local searchContainer
searchContainer, searchInput = SearchModern.new(songsHeader, {
	placeholder = "Buscar por ID o nombre...",
	size = UDim2.new(1, -160, 0, 36),
	bg = THEME.card,
	corner = 8,
	z = 102,
	inputName = "SearchInput"
})
searchContainer.Position = UDim2.new(0, 48, 0, 4)

songCountLabel = Instance.new("TextLabel")
songCountLabel.Size = UDim2.new(0, 60, 0, 36)
songCountLabel.Position = UDim2.new(1, -68, 0, 4)
songCountLabel.BackgroundTransparency = 1
songCountLabel.Text = "0 songs"
songCountLabel.TextColor3 = THEME.muted
songCountLabel.Font = Enum.Font.Gotham
songCountLabel.TextSize = 12
songCountLabel.TextXAlignment = Enum.TextXAlignment.Right
songCountLabel.Parent = songsHeader

songsScroll = Instance.new("ScrollingFrame")
songsScroll.Size = UDim2.new(1, -24, 1, -64)
songsScroll.Position = UDim2.new(0, 12, 0, 56)
songsScroll.BackgroundTransparency = 1
songsScroll.BorderSizePixel = 0
songsScroll.ScrollBarThickness = 6
songsScroll.ScrollBarImageColor3 = THEME.stroke
songsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
songsScroll.ClipsDescendants = true
songsScroll.Parent = songsView

songsContainer = Instance.new("Frame")
songsContainer.Name = "SongsContainer"
songsContainer.Size = UDim2.new(1, 0, 0, 0)
songsContainer.BackgroundTransparency = 1
songsContainer.Parent = songsScroll

loadingIndicator = Instance.new("TextLabel")
loadingIndicator.Size = UDim2.new(1, 0, 0, 40)
loadingIndicator.BackgroundTransparency = 1
loadingIndicator.Text = "Cargando..."
loadingIndicator.TextColor3 = THEME.muted
loadingIndicator.Font = Enum.Font.Gotham
loadingIndicator.TextSize = 14
loadingIndicator.Visible = false
loadingIndicator.Parent = songsScroll

-- ════════════════════════════════════════════════════════════════
-- CARD POOL
-- ════════════════════════════════════════════════════════════════
local function createSongCard()
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, CARD_HEIGHT)
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.Visible = false
	UI.rounded(card, 8)
	UI.stroked(card, 0.3)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = card

	-- Imagen pequeña del DJ
	local djCover = Instance.new("ImageLabel")
	djCover.Name = "DJCover"
	djCover.Size = UDim2.new(0, 38, 0, 38)
	djCover.Position = UDim2.new(0, 0, 0, 8)
	djCover.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	djCover.BorderSizePixel = 0
	djCover.ScaleType = Enum.ScaleType.Crop
	djCover.Image = ""
	djCover.Parent = card
	UI.rounded(djCover, 6)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -210, 0, 18)
	nameLabel.Position = UDim2.new(0, 48, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = THEME.text
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	local artistLabel = Instance.new("TextLabel")
	artistLabel.Name = "ArtistLabel"
	artistLabel.Size = UDim2.new(1, -210, 0, 14)
	artistLabel.Position = UDim2.new(0, 48, 0, 28)
	artistLabel.BackgroundTransparency = 1
	artistLabel.TextColor3 = THEME.muted
	artistLabel.Font = Enum.Font.Gotham
	artistLabel.TextSize = 12
	artistLabel.TextXAlignment = Enum.TextXAlignment.Left
	artistLabel.TextTruncate = Enum.TextTruncate.AtEnd
	artistLabel.Parent = card

	local addBtn = Instance.new("TextButton")
	addBtn.Name = "AddButton"
	addBtn.Size = UDim2.new(0, 70, 0, 30)
	addBtn.Position = UDim2.new(1, -70, 0.5, -15)
	addBtn.BackgroundColor3 = THEME.accent
	addBtn.Text = "AÑADIR"
	addBtn.TextColor3 = THEME.text
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 11
	addBtn.BorderSizePixel = 0
	addBtn.Parent = card
	UI.rounded(addBtn, 6)

	return card
end

local function getCardFromPool()
	for _, card in ipairs(cardPool) do
		if not card.Visible then return card end
	end
	if #cardPool < MAX_POOL_SIZE then
		local newCard = createSongCard()
		newCard.Parent = songsContainer
		table.insert(cardPool, newCard)
		return newCard
	end
	return nil
end

local function releaseCard(card)
	card.Visible = false
	card:SetAttribute("SongIndex", nil)
	card:SetAttribute("SongID", nil)
end

local function releaseAllCards()
	for _, card in ipairs(cardPool) do releaseCard(card) end
end

-- ════════════════════════════════════════════════════════════════
-- VIRTUAL SCROLL LOGIC
-- ════════════════════════════════════════════════════════════════
local function getSongDataForDisplay()
	return virtualScrollState.isSearching and virtualScrollState.searchResults or virtualScrollState.songData
end

local function getTotalSongsForDisplay()
	return virtualScrollState.isSearching and #virtualScrollState.searchResults or virtualScrollState.totalSongs
end

local function isInQueue(songId)
	for _, song in ipairs(playQueue) do
		if song.id == songId then return true end
	end
	return false
end

local function updateSongCard(card, songData, index, inQueue)
	if not card or not songData then return end

	card:SetAttribute("SongIndex", index)
	card:SetAttribute("SongID", songData.id)

	local djCover = card:FindFirstChild("DJCover")
	local nameLabel = card:FindFirstChild("NameLabel")
	local artistLabel = card:FindFirstChild("ArtistLabel")
	local addBtn = card:FindFirstChild("AddButton")

	-- Actualizar imagen del DJ
	if djCover and selectedDJInfo and selectedDJInfo.cover then
		djCover.Image = selectedDJInfo.cover
	end

	if nameLabel then
		nameLabel.Text = songData.name or "Cargando..."
		nameLabel.TextColor3 = songData.loaded and THEME.text or THEME.muted
	end

	if artistLabel then
		artistLabel.Text = songData.artist or ("ID: " .. songData.id)
	end

	if addBtn then
		if inQueue then
			addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
			addBtn.Text = "EN COLA"
			addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
			addBtn.AutoButtonColor = false
		else
			addBtn.BackgroundColor3 = THEME.accent
			addBtn.Text = "AÑADIR"
			addBtn.TextColor3 = THEME.text
			addBtn.AutoButtonColor = true
		end
	end

	card.Position = UDim2.new(0, 4, 0, (index - 1) * (CARD_HEIGHT + CARD_PADDING))
	card.Visible = true
end

local function updateVisibleCards()
	if not songsScroll or not songsScroll.Parent then return end

	local scrollPos = songsScroll.CanvasPosition.Y
	local viewportHeight = songsScroll.AbsoluteSize.Y
	local totalItems = getTotalSongsForDisplay()

	if totalItems == 0 then
		releaseAllCards()
		return
	end

	local firstVisible = math.max(1, math.floor(scrollPos / (CARD_HEIGHT + CARD_PADDING)) + 1 - VISIBLE_BUFFER)
	local lastVisible = math.min(totalItems, math.ceil((scrollPos + viewportHeight) / (CARD_HEIGHT + CARD_PADDING)) + VISIBLE_BUFFER)

	local totalHeight = totalItems * (CARD_HEIGHT + CARD_PADDING)
	songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
	songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)

	for _, card in ipairs(cardPool) do
		if card.Visible then
			local cardIndex = card:GetAttribute("SongIndex")
			if cardIndex and (cardIndex < firstVisible or cardIndex > lastVisible) then
				releaseCard(card)
			end
		end
	end

	local dataSource = getSongDataForDisplay()
	local needsServerFetch = {}

	for i = firstVisible, lastVisible do
		local songData = dataSource[i]

		local existingCard = nil
		for _, card in ipairs(cardPool) do
			if card.Visible and card:GetAttribute("SongIndex") == i then
				existingCard = card
				break
			end
		end

		if songData then
			local card = existingCard or getCardFromPool()
			if card then updateSongCard(card, songData, i, isInQueue(songData.id)) end
		elseif not virtualScrollState.isSearching then
			table.insert(needsServerFetch, i)
		end
	end

	if #needsServerFetch > 0 and not virtualScrollState.isSearching then
		local minIndex, maxIndex = math.huge, 0
		for _, idx in ipairs(needsServerFetch) do
			minIndex = math.min(minIndex, idx)
			maxIndex = math.max(maxIndex, idx)
		end

		local rangeKey = minIndex .. "-" .. maxIndex
		if not virtualScrollState.pendingRequests[rangeKey] then
			virtualScrollState.pendingRequests[rangeKey] = true
			if R.GetSongRange and selectedDJ then
				R.GetSongRange:FireServer(selectedDJ, minIndex, maxIndex)
			end
		end
	end

	virtualScrollState.firstVisibleIndex = firstVisible
	virtualScrollState.lastVisibleIndex = lastVisible
end

local scrollConnection = nil

local function connectScrollListener()
	if scrollConnection then scrollConnection:Disconnect() end
	scrollConnection = songsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateVisibleCards)
end

-- ════════════════════════════════════════════════════════════════
-- SEARCH
-- ════════════════════════════════════════════════════════════════
local searchDebounce = nil

local function performSearch(query)
	if query == "" then
		virtualScrollState.isSearching = false
		virtualScrollState.searchQuery = ""
		virtualScrollState.searchResults = {}
		songCountLabel.Text = virtualScrollState.totalSongs .. " songs"
		songsScroll.CanvasPosition = Vector2.new(0, 0)
		updateVisibleCards()
		return
	end

	virtualScrollState.isSearching = true
	virtualScrollState.searchQuery = query
	loadingIndicator.Visible = true
	loadingIndicator.Text = "Buscando..."

	if R.SearchSongs and selectedDJ then
		R.SearchSongs:FireServer(selectedDJ, query)
	end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce = task.delay(0.3, function() performSearch(searchInput.Text) end)
end)

songsContainer.ChildAdded:Connect(function(child)
	if child:IsA("Frame") then
		local addBtn = child:FindFirstChild("AddButton")
		if addBtn then
			addBtn.MouseButton1Click:Connect(function()
				local songId = child:GetAttribute("SongID")
				if songId and not isInQueue(songId) then
					addBtn.BackgroundColor3 = THEME.surface
					addBtn.Text = "..."
					if R.Add then R.Add:FireServer(songId) end
				end
			end)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- UPDATE HEADER COVER - Basado en la canción que se reproduce
-- ════════════════════════════════════════════════════════════════
local currentHeaderCover = ""

local function updateHeaderCover(song)
	-- Si no hay canción, ocultar el cover
	if not song then
		if currentHeaderCover ~= "" then
			currentHeaderCover = ""
			TweenService:Create(headerCoverImage, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
			miniCover.Image = ""
			headerDJName.Text = ""
		end
		return
	end

	-- Usar directamente djCover y dj del song (viene del servidor)
	local djCover = song.djCover or ""
	local djName = song.dj or ""

	-- Solo actualizar si cambió el cover
	if djCover ~= currentHeaderCover then
		currentHeaderCover = djCover

		if djCover ~= "" then
			TweenService:Create(headerCoverImage, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
			task.wait(0.2)
			headerCoverImage.Image = djCover
			TweenService:Create(headerCoverImage, TweenInfo.new(0.5), {ImageTransparency = 0.5}):Play()
			miniCover.Image = djCover
		else
			TweenService:Create(headerCoverImage, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
			miniCover.Image = ""
		end
	end

	headerDJName.Text = djName

	-- Mostrar ID en el header si está disponible
	if song and song.id then
		headerSongID.Text = "ID: " .. tostring(song.id)
	else
		headerSongID.Text = ""
	end
end

-- ════════════════════════════════════════════════════════════════
-- DJs DRAWING
-- ════════════════════════════════════════════════════════════════
local function drawDJs()
	for _, child in pairs(djsScroll:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end

	if #allDJs == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 1, 0)
		empty.BackgroundTransparency = 1
		empty.Text = "No DJs available"
		empty.TextColor3 = THEME.muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.Parent = djsScroll
		return
	end

	for _, dj in ipairs(allDJs) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 1, 0)
		card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		card.BorderSizePixel = 0
		card.ZIndex = 50
		card.Parent = djsScroll
		UI.rounded(card, 16)
		UI.stroked(card, 0.4)

		local cover = Instance.new("ImageLabel")
		cover.Size = UDim2.new(1, 0, 1, 0)
		cover.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		cover.Image = dj.cover ~= "" and dj.cover or "rbxasset://textures/face.png"
		cover.ScaleType = Enum.ScaleType.Crop
		cover.BorderSizePixel = 0
		cover.ZIndex = 51
		cover.Parent = card
		UI.rounded(cover, 16)

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 52
		overlay.Parent = card
		UI.rounded(overlay, 16)

		local infoContainer = Instance.new("Frame")
		infoContainer.Size = UDim2.new(1, -24, 0, 60)
		infoContainer.Position = UDim2.new(0, 12, 1, -72)
		infoContainer.BackgroundTransparency = 1
		infoContainer.ZIndex = 53
		infoContainer.Parent = overlay

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 30)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = dj.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextWrapped = true
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextTransparency = 1
		nameLabel.ZIndex = 54
		nameLabel.Parent = infoContainer

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, 0, 0, 20)
		countLabel.Position = UDim2.new(0, 0, 0, 30)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = dj.songCount .. " songs"
		countLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
		countLabel.Font = Enum.Font.Gotham
		countLabel.TextSize = 14
		countLabel.TextTransparency = 1
		countLabel.ZIndex = 54
		countLabel.Parent = infoContainer

		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 55
		clickBtn.Parent = card

		clickBtn.MouseButton1Click:Connect(function()
			selectedDJ = dj.name
			selectedDJInfo = dj  -- Guardar objeto completo con cover

			virtualScrollState.totalSongs = dj.songCount
			virtualScrollState.songData = {}
			virtualScrollState.searchResults = {}
			virtualScrollState.isSearching = false
			virtualScrollState.searchQuery = ""
			virtualScrollState.pendingRequests = {}

			TweenService:Create(djsScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 12, 0, -50)}):Play()
			task.wait(0.15)
			djsScroll.Visible = false
			djsScroll.Position = UDim2.new(0, 12, 0, 8)

			songsView.Visible = true
			searchInput.Text = ""
			songCountLabel.Text = dj.songCount .. " songs"

			releaseAllCards()
			songsScroll.CanvasPosition = Vector2.new(0, 0)

			local totalHeight = dj.songCount * (CARD_HEIGHT + CARD_PADDING)
			songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
			songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)

			connectScrollListener()

			if R.GetSongRange then R.GetSongRange:FireServer(dj.name, 1, BATCH_SIZE) end

			songsView.Position = UDim2.new(0, 0, 0, 50)
			TweenService:Create(songsView, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		end)

		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
		end)

		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		end)
	end
end

backBtn.MouseButton1Click:Connect(function()
	selectedDJ = nil
	selectedDJInfo = nil  -- Limpiar info del DJ
	virtualScrollState.songData = {}
	virtualScrollState.searchResults = {}
	virtualScrollState.isSearching = false
	virtualScrollState.pendingRequests = {}
	releaseAllCards()

	if scrollConnection then
		scrollConnection:Disconnect()
		scrollConnection = nil
	end

	TweenService:Create(songsView, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0, 50)}):Play()
	task.wait(0.15)
	songsView.Visible = false
	songsView.Position = UDim2.new(0, 0, 0, 0)

	djsScroll.Visible = true
	djsScroll.Position = UDim2.new(0, 12, 0, -50)
	TweenService:Create(djsScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 12, 0, 8)}):Play()
end)

local function resetLibraryState()
	selectedDJ = nil
	selectedDJInfo = nil  -- Limpiar info del DJ
	virtualScrollState.songData = {}
	virtualScrollState.searchResults = {}
	virtualScrollState.isSearching = false
	virtualScrollState.pendingRequests = {}
	releaseAllCards()

	if scrollConnection then
		scrollConnection:Disconnect()
		scrollConnection = nil
	end

	djsScroll.Position = UDim2.new(0, 12, 0, 8)
	djsScroll.Visible = true
	djsScroll.CanvasPosition = Vector2.new(0, 0)
	songsView.Visible = false
	songsView.Position = UDim2.new(0, 0, 0, 0)
	searchInput.Text = ""
end

-- ════════════════════════════════════════════════════════════════
-- PROGRESS BAR UPDATE
-- ════════════════════════════════════════════════════════════════
local function updateProgressBar()
	-- Buscar el sound object en workspace
	if not currentSoundObject then
		currentSoundObject = workspace:FindFirstChild("QueueSound")
	end

	if not currentSoundObject or not currentSoundObject:IsA("Sound") or not currentSoundObject.Parent then
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"
		totalTimeLabel.Text = "0:00"
		if not currentSong then songTitle.Text = "No song playing" end
		return
	end

	local current = currentSoundObject.TimePosition
	local total = currentSoundObject.TimeLength

	if total > 0 then
		progressFill.Size = UDim2.new(math.clamp(current / total, 0, 1), 0, 1, 0)
		currentTimeLabel.Text = formatTime(current)
		totalTimeLabel.Text = formatTime(total)
	else
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"
		totalTimeLabel.Text = "0:00"
	end
end

-- ════════════════════════════════════════════════════════════════
-- NAVIGATION
-- ════════════════════════════════════════════════════════════════
local function moveUnderline(btn)
	if not btn then return end
	task.spawn(function()
		task.wait(0.05)
		local x = btn.AbsolutePosition.X - panel.AbsolutePosition.X
		local w = btn.AbsoluteSize.X
		TweenService:Create(underline, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, w, 0, 3),
			Position = UDim2.new(0, x, 0, NAV_TOP + 33)
		}):Play()
	end)
end

function showPage(name)
	-- Evitar re-render/animación si ya estamos en la misma página
	if currentPage == name then return end
	local previousPage = currentPage
	currentPage = name

	if previousPage == "Library" and name ~= "Library" then resetLibraryState() end

	queuePage.Visible = false
	libraryPage.Visible = false

	local pageFrame = holder:FindFirstChild(name)
	if pageFrame then
		pageFrame.Visible = true
		pageLayout:JumpTo(pageFrame)
	end

	if name == "Queue" then drawQueue() end
	if name == "Library" then
		resetLibraryState()
		if #allDJs > 0 then drawDJs() end
		if R.GetDJs then R.GetDJs:FireServer() end
	end
end

local function wireTab(btn, name)
	btn.MouseButton1Click:Connect(function()
		showPage(name)
		moveUnderline(btn)
	end)
end

wireTab(tQueue, "Queue")
wireTab(tLibrary, "Library")

task.defer(function()
	task.wait(0.1)
	moveUnderline(tQueue)
	showPage("Queue")
end)

-- ════════════════════════════════════════════════════════════════
-- UI OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
function openUI(openToLibrary)
	-- Si el modal ya está abierto, no hacer nada
	if modal:isModalOpen() then 
		return 
	end

	if openToLibrary then
		showPage("Library")
		moveUnderline(tLibrary)
	else
		showPage("Queue")
		moveUnderline(tQueue)
	end

	-- Abrir el modal
	modal:open()

	-- Conectar la barra de progreso
	if progressConnection then 
		progressConnection:Disconnect() 
	end
	progressConnection = RunService.Heartbeat:Connect(updateProgressBar)
end

function closeUI()
	-- Si el modal no está abierto, no hacer nada
	if not modal:isModalOpen() then 
		return 
	end

	-- Cerrar el modal (dispara onClose automáticamente)
	modal:close()
end
-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
	GlobalModalManager:closeModal("Music")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.KeyCode == Enum.KeyCode.Escape and modal:isModalOpen() then
			GlobalModalManager:closeModal("Music")
		elseif input.KeyCode == Enum.KeyCode.Return and volInput.Visible then
			applyVolumeInput()
		end
	end
end)

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 60, 60), TextColor3 = Color3.new(1, 1, 1)}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card, TextColor3 = THEME.muted}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- REMOTE UPDATES
-- ════════════════════════════════════════════════════════════════
if R.Update then
	R.Update.OnClientEvent:Connect(function(data)
		playQueue = data.queue or {}
		currentSong = data.currentSong
		allDJs = data.djs or allDJs

		-- Buscar QueueSound en workspace
		currentSoundObject = workspace:FindFirstChild("QueueSound")

		if currentSong then
			songTitle.Text = currentSong.name
			headerDJName.Text = currentSong.artist or "Unknown"
			-- actualizar ID en header
			if currentSong.id then
				headerSongID.Text = "ID: " .. tostring(currentSong.id)
			else
				headerSongID.Text = ""
			end
		else
			songTitle.Text = "No song playing"
			headerDJName.Text = ""
			headerSongID.Text = ""
		end

		-- Actualizar header cover basado en la canción actual
		updateHeaderCover(currentSong)

		if currentPage == "Queue" then drawQueue() end
		if currentPage == "Library" then
			if not selectedDJ then
				drawDJs()
			else
				updateVisibleCards()
			end
		end
	end)
end

if R.GetDJs then
	R.GetDJs.OnClientEvent:Connect(function(d)
		allDJs = (d and (d.djs or d)) or allDJs
		if currentPage == "Library" and not selectedDJ then drawDJs() end
	end)
end

if R.GetSongRange then
	R.GetSongRange.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end
		loadingIndicator.Visible = false

		for _, song in ipairs(data.songs or {}) do
			virtualScrollState.songData[song.index] = song
		end

		virtualScrollState.pendingRequests[data.startIndex .. "-" .. data.endIndex] = nil
		updateVisibleCards()
	end)
end

if R.SearchSongs then
	R.SearchSongs.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end
		loadingIndicator.Visible = false

		virtualScrollState.searchResults = data.songs or {}
		local countText = #virtualScrollState.searchResults .. " / " .. (data.totalInDJ or virtualScrollState.totalSongs) .. " songs"
		if data.cachedCount and data.cachedCount < (data.totalInDJ or 0) then
			countText = countText .. " " .. math.floor(data.cachedCount / (data.totalInDJ or 1) * 100) .. "%"
		end
		songCountLabel.Text = countText

		songsScroll.CanvasPosition = Vector2.new(0, 0)
		updateVisibleCards()
	end)
end

if R.GetSongsByDJ then
	R.GetSongsByDJ.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end

		virtualScrollState.totalSongs = data.total or 0
		songCountLabel.Text = data.total .. " songs"

		local totalHeight = data.total * (CARD_HEIGHT + CARD_PADDING)
		songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
		songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
if R.GetDJs then R.GetDJs:FireServer() end

for i = 1, MAX_POOL_SIZE do
	local card = createSongCard()
	card.Parent = songsContainer
	table.insert(cardPool, card)
end

-- ════════════════════════════════════════════════════════════════
-- GLOBAL FUNCTIONS (Para TOPBAR.lua y GlobalModalManager)
-- ════════════════════════════════════════════════════════════════
_G.OpenMusicUI = function() 
	openUI(false)
end

_G.CloseMusicUI = function()
	closeUI()
end