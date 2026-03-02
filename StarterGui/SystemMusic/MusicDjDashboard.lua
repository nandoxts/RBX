--[[ Music Dashboard - Professional Edition v8 (Refactored)
	by ignxts
	REDISEÑO: Layout 3 columnas (DJ List | Songs | Queue) + Barra inferior
	Refactored: Helpers reutilizables, ~40% menos líneas
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
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

-- ════════════════════════════════════════════════════════════════
-- INSTANCE HELPER — Reduce creación repetitiva
-- ════════════════════════════════════════════════════════════════
local function make(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, child in ipairs(children) do child.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function makeLabel(props)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = props.font or Enum.Font.Gotham,
		TextSize = props.size or 13,
		TextColor3 = props.color or THEME and THEME.text or Color3.new(1,1,1),
		TextXAlignment = props.alignX or Enum.TextXAlignment.Left,
		TextTruncate = props.truncate or Enum.TextTruncate.None,
		Text = props.text or "",
		Size = props.dim or UDim2.new(1, 0, 0, 20),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		ZIndex = props.z or 102,
		Visible = props.visible ~= false,
		Name = props.name or "Label",
		TextWrapped = props.wrap or false,
		Parent = props.parent,
	})
end

local function makeBtn(props)
	local btn = make("TextButton", {
		Size = props.dim or UDim2.new(0, 80, 0, 30),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = props.bg or Color3.fromRGB(60, 60, 68),
		Text = props.text or "",
		TextColor3 = props.textColor or Color3.new(1, 1, 1),
		Font = props.font or Enum.Font.GothamBold,
		TextSize = props.textSize or 13,
		BorderSizePixel = 0,
		ZIndex = props.z or 103,
		Name = props.name or "Button",
		Parent = props.parent,
	})
	if props.round then UI.rounded(btn, props.round) end
	return btn
end

local function makeFrame(props)
	return make("Frame", {
		Size = props.dim or UDim2.new(1, 0, 1, 0),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = props.bg or Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = props.bgT or 1,
		BorderSizePixel = 0,
		ZIndex = props.z or 100,
		ClipsDescendants = props.clip or false,
		Name = props.name or "Frame",
		Parent = props.parent,
	})
end

local function makeImage(props)
	return make("ImageLabel", {
		Size = props.dim or UDim2.new(0, 40, 0, 40),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = props.bgT or 1,
		BackgroundColor3 = props.bg or Color3.fromRGB(30, 30, 35),
		Image = props.image or "",
		ImageColor3 = props.imageColor or Color3.new(1, 1, 1),
		ImageTransparency = props.imageT or 0,
		ScaleType = props.scale or Enum.ScaleType.Crop,
		BorderSizePixel = 0,
		ZIndex = props.z or 103,
		Visible = props.visible ~= false,
		Name = props.name or "Image",
		Parent = props.parent,
	})
end

-- Scroll reutilizable con scrollbar y layout
local function makeScrollColumn(parent, offsetY, paddingOpts, theme)
	local scroll = make("ScrollingFrame", {
		Size = UDim2.new(1, paddingOpts.sizeXOff or -8, 1, -(offsetY + (paddingOpts.bottomOff or 8))),
		Position = UDim2.new(0, paddingOpts.posX or 4, 0, offsetY),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		ZIndex = 101,
		Parent = parent,
	})

	local scrollbar = ModernScrollbar.setup(scroll, parent, theme, {color = theme.accent, colorHover = theme.accent, transparency = 0, transparencyHover = 0})

	if paddingOpts.padding then
		make("UIPadding", {
			PaddingLeft = UDim.new(0, paddingOpts.padding),
			PaddingRight = UDim.new(0, paddingOpts.padding),
			PaddingTop = UDim.new(0, paddingOpts.paddingTop or paddingOpts.padding),
			PaddingBottom = UDim.new(0, paddingOpts.padding),
			Parent = scroll,
		})
	end

	local layout = make("UIListLayout", {
		Padding = UDim.new(0, paddingOpts.gap or 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)

	return scroll, layout, scrollbar
end

-- Tween helper
local function tween(obj, duration, props)
	TweenService:Create(obj, TweenInfo.new(duration), props):Play()
end

-- Hover helper para botones
local function addHover(btn, hoverColor, defaultColor, defaultTransparency)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = defaultColor, BackgroundTransparency = defaultTransparency or 0})
	end)
end

-- ════════════════════════════════════════════════════════════════
-- RESPONSE CODES
-- ════════════════════════════════════════════════════════════════
local ResponseCodes = {
	SUCCESS = "SUCCESS", ERROR_INVALID_ID = "ERROR_INVALID_ID",
	ERROR_BLACKLISTED = "ERROR_BLACKLISTED", ERROR_DUPLICATE = "ERROR_DUPLICATE",
	ERROR_NOT_FOUND = "ERROR_NOT_FOUND", ERROR_NOT_AUDIO = "ERROR_NOT_AUDIO",
	ERROR_NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED", ERROR_QUEUE_FULL = "ERROR_QUEUE_FULL",
	ERROR_PERMISSION = "ERROR_PERMISSION", ERROR_UNKNOWN = "ERROR_UNKNOWN",
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
	[ResponseCodes.ERROR_UNKNOWN] = {type = "error", title = "Error"},
}

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local MusicSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local SHOW_ADMIN_UI = true
local isAdmin = MusicSystemConfig:IsAdmin(player) and SHOW_ADMIN_UI

local R_PANEL, R_CTRL = 12, 10
local ENABLE_BLUR, BLUR_SIZE = true, 14

local CARD_HEIGHT, CARD_PADDING = 54, 6
local VISIBLE_BUFFER, BATCH_SIZE, MAX_POOL_SIZE = 3, 15, 25

local ICONS = {
	PLAY_ADD = "rbxassetid://84692791859484",
	CHECK = "rbxassetid://102926522001210",
	DELETE = "rbxassetid://94904012825024",
	LOADING = "rbxassetid://122161736287488",
}

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local playQueue, currentSong = {}, nil
local allDJs, selectedDJ, selectedDJInfo = {}, nil, nil
local currentSoundObject, progressConnection = nil, nil
local isAddingToQueue, pendingCardSongId = false, nil
local loadingDotsThread = nil
local cardPool, cardsIndex = {}, {}
local selectedDJCard = nil
local currentHeaderCover = ""

local virtualScrollState = {
	totalSongs = 0, songData = {}, visibleCards = {},
	firstVisibleIndex = 1, lastVisibleIndex = 1,
	isSearching = false, searchQuery = "", searchResults = {},
	pendingRequests = {},
}

-- UI refs (forward declarations)
local quickAddBtn, quickInput, qiStroke
local quickAddBtnImg, quickAddBtnLoading
local songsScroll, songsContainer, searchInput, loadingIndicator, songCountLabel
local headerDJName, headerSongID, songTitle, songIdDisplay
local miniCover, bottomBarBg
local songsPlaceholder, songsTitle
local progressFill, currentTimeLabel, totalTimeLabel
local volSliderFill, volSliderBg, volLabelText, volInput

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function isValidAudioId(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	return #text >= 6 and #text <= 19
end

local function getRemote(name)
	local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
	if not RemotesGlobal then return end
	local remoteMap = {
		NextSong = "MusicPlayback", PlaySong = "MusicPlayback", PauseSong = "MusicPlayback",
		StopSong = "MusicPlayback", ChangeVolume = "MusicPlayback",
		AddToQueue = "MusicQueue", AddToQueueResponse = "MusicQueue",
		RemoveFromQueue = "MusicQueue", RemoveFromQueueResponse = "MusicQueue",
		ClearQueue = "MusicQueue", ClearQueueResponse = "MusicQueue",
		UpdateUI = "UI", GetDJs = "MusicLibrary", GetSongsByDJ = "MusicLibrary",
		GetSongRange = "MusicLibrary", SearchSongs = "MusicLibrary",
		GetSongMetadata = "MusicLibrary",
	}
	local folder = RemotesGlobal:FindFirstChild(remoteMap[name] or "MusicLibrary")
	return folder and folder:FindFirstChild(name)
end

local function formatTime(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

local function showNotification(response)
	local cfg = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local msg = response.message or "Operación completada"
	if response.data and response.data.songName then msg = msg .. ": " .. response.data.songName end
	local fn = ({success = Notify.Success, warning = Notify.Warning, error = Notify.Error})[cfg.type] or Notify.Info
	fn(Notify, cfg.title, msg, cfg.type == "error" and 4 or 3)
end

local function isInQueue(songId)
	for _, song in ipairs(playQueue) do
		if song.id == songId then return true end
	end
	return false
end

local function isMusicMuted() return _G.MusicMutedState or false end

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local remoteNames = {
	"NextSong", "PlaySong", "StopSong", "AddToQueue", "AddToQueueResponse",
	"RemoveFromQueue", "RemoveFromQueueResponse", "ClearQueue", "ClearQueueResponse",
	"UpdateUI", "GetDJs", "GetSongsByDJ", "GetSongRange", "SearchSongs",
	"GetSongMetadata", "ChangeVolume",
}
local shortNames = {
	NextSong = "Next", PlaySong = "Play", StopSong = "Stop",
	AddToQueue = "Add", AddToQueueResponse = "AddResponse",
	RemoveFromQueue = "Remove", RemoveFromQueueResponse = "RemoveResponse",
	ClearQueue = "Clear", ClearQueueResponse = "ClearResponse",
	UpdateUI = "Update",
}
local R = {}
for _, name in ipairs(remoteNames) do
	R[shortNames[name] or name] = getRemote(name)
end

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = make("ScreenGui", {
	Name = "MusicDashboardUI", ResetOnSpawn = false,
	IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

task.wait(0.5)
local isMobileDevice = UserInputService.TouchEnabled
local mob = isMobileDevice -- alias corto

-- ════════════════════════════════════════════════════════════════
-- LAYOUT CONSTANTS
-- ════════════════════════════════════════════════════════════════
local PANEL_W = mob and THEME.panelWidth or math.max(THEME.panelWidth, 1100)
local PANEL_H = mob and THEME.panelHeight or math.max(THEME.panelHeight, 620)
local DJ_W, SONGS_W, QUEUE_W = 0.22, 0.48, 0.30
local BOTTOM_BAR_H = mob and 90 or 100
local COL_HEADER_H = 36

-- ════════════════════════════════════════════════════════════════
-- MODAL
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui, panelName = "MusicDashboard",
	panelWidth = PANEL_W, panelHeight = PANEL_H,
	cornerRadius = R_PANEL, enableBlur = ENABLE_BLUR, blurSize = BLUR_SIZE,
	isMobile = mob,
	onClose = function()
		if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
	end,
})

local panel = modal:getPanel()
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- MAIN LAYOUT
-- ════════════════════════════════════════════════════════════════
-- Content area (3 columnas)
local contentArea = makeFrame({
	dim = UDim2.new(1, 0, 1, -BOTTOM_BAR_H),
	z = 100, clip = true, name = "ContentArea", parent = panel,
})

-- Bottom bar
local bottomBar = makeFrame({
	dim = UDim2.new(1, 0, 0, BOTTOM_BAR_H),
	pos = UDim2.new(0, 0, 1, -BOTTOM_BAR_H),
	bg = Color3.fromRGB(14, 14, 18), bgT = 0,
	z = 110, name = "BottomBar", parent = panel,
})
UI.rounded(bottomBar, R_PANEL)

make("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
		ColorSequenceKeypoint.new(0.15, Color3.fromRGB(14, 14, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
	},
	Rotation = 90, Parent = bottomBar,
})

make("UIStroke", {
	Color = THEME.stroke, Thickness = 1, Transparency = 0.6,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bottomBar,
})

bottomBarBg = makeImage({
	dim = UDim2.new(1, 0, 1, 0), z = 110, imageT = 0.6,
	name = "BottomBarBg", parent = bottomBar,
})
UI.rounded(bottomBarBg, R_PANEL)

-- Overlay oscuro
local bbOverlay = makeFrame({
	bg = Color3.fromRGB(10, 10, 14), bgT = 0.45, z = 110, parent = bottomBar,
})
UI.rounded(bbOverlay, R_PANEL)

-- ════════════════════════════════════════════════════════════════
-- COLUMNA IZQUIERDA: DJ LIST
-- ════════════════════════════════════════════════════════════════
local djColumn = makeFrame({
	dim = UDim2.new(DJ_W, 0, 1, 0),
	bg = Color3.fromRGB(16, 16, 20), bgT = 0.3,
	z = 100, name = "DJColumn", parent = contentArea,
})
UI.rounded(djColumn, R_PANEL)

-- Separador derecho
makeFrame({dim = UDim2.new(0, 1, 1, -20), pos = UDim2.new(1, 0, 0, 10), bg = THEME.stroke, bgT = 0.5, z = 101, parent = djColumn})

-- Header
makeLabel({
	text = "DJ LIST", font = Enum.Font.GothamBold, size = 16,
	dim = UDim2.new(1, -16, 0, COL_HEADER_H), pos = UDim2.new(0, 12, 0, 0),
	z = 102, parent = djColumn,
})

-- DJ Scroll
local djsScroll = nil
do
	djsScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, -8, 1, -COL_HEADER_H - 8),
		Position = UDim2.new(0, 4, 0, COL_HEADER_H + 4),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true, ZIndex = 101, Parent = djColumn,
	})
	ModernScrollbar.setup(djsScroll, djColumn, THEME, {color = THEME.accent, colorHover = THEME.accent, transparency = 0, transparencyHover = 0})

	local layout = make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = djsScroll})
	make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 2), Parent = djsScroll})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		djsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- COLUMNA CENTRAL: SONGS LIST
-- ════════════════════════════════════════════════════════════════
local songsColumn = makeFrame({
	dim = UDim2.new(SONGS_W, 0, 1, 0), pos = UDim2.new(DJ_W, 0, 0, 0),
	z = 100, name = "SongsColumn", parent = contentArea,
})

-- Header songs
local songsHeader = makeFrame({
	dim = UDim2.new(1, -16, 0, 64), pos = UDim2.new(0, 8, 0, 0),
	z = 101, clip = true, parent = songsColumn,
})

-- Fila 1: Nombre DJ (izquierda) + contador (derecha)
songsTitle = makeLabel({
	text = "Mix", font = Enum.Font.GothamBold, size = 15,
	dim = UDim2.new(1, -70, 0, 28), pos = UDim2.new(0, 0, 0, 0),
	truncate = Enum.TextTruncate.AtEnd,
	alignX = Enum.TextXAlignment.Left, z = 102,
	name = "SongsTitle", parent = songsHeader,
})

songCountLabel = makeLabel({
	dim = UDim2.new(0, 65, 0, 28), pos = UDim2.new(1, -65, 0, 0),
	color = THEME.accent, font = Enum.Font.GothamBold, size = 12,
	alignX = Enum.TextXAlignment.Right, z = 102,
	visible = false, parent = songsHeader,
})

-- Fila 2: Buscador full width
local searchContainer
searchContainer, searchInput = SearchModern.new(songsHeader, {
	placeholder = "Buscar por ID o nombre...",
	size = UDim2.new(1, 0, 0, 28),
	bg = THEME.card, corner = 8, z = 102, inputName = "SearchInput",
})
searchContainer.Position = UDim2.new(0, 0, 0, 34)
searchContainer.Size = UDim2.new(1, -2, 0, 26)

-- Songs scroll (virtualizado)
songsScroll = make("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -80),
	Position = UDim2.new(0, 8, 0, 72),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ClipsDescendants = true, ZIndex = 101, Parent = songsColumn,
})
ModernScrollbar.setup(songsScroll, songsColumn, THEME, {color = THEME.accent, colorHover = THEME.accent, transparency = 0, transparencyHover = 0})

songsContainer = makeFrame({name = "SongsContainer", dim = UDim2.new(1, 0, 0, 0), z = 101, parent = songsScroll})

loadingIndicator = makeLabel({
	dim = UDim2.new(1, 0, 0, 40), text = "Cargando...",
	color = THEME.muted, size = 15, z = 102, visible = false, parent = songsScroll,
})

songsPlaceholder = makeLabel({
	dim = UDim2.new(1, -40, 0, 80), pos = UDim2.new(0, 20, 0.4, 0),
	text = "Selecciona un DJ\npara ver sus canciones",
	color = THEME.muted, size = 16, wrap = true, z = 102,
	alignX = Enum.TextXAlignment.Center,
	name = "Placeholder", parent = songsColumn,
})

-- ════════════════════════════════════════════════════════════════
-- COLUMNA DERECHA: PLAYLIST QUEUE
-- ════════════════════════════════════════════════════════════════
local queueColumn = makeFrame({
	dim = UDim2.new(QUEUE_W, 0, 1, 0), pos = UDim2.new(DJ_W + SONGS_W, 0, 0, 0),
	bg = Color3.fromRGB(16, 16, 20), bgT = 0.3,
	z = 100, name = "QueueColumn", parent = contentArea,
})
UI.rounded(queueColumn, R_PANEL)

-- Separador izquierdo
makeFrame({dim = UDim2.new(0, 1, 1, -20), pos = UDim2.new(0, 0, 0, 10), bg = THEME.stroke, bgT = 0.5, z = 101, parent = queueColumn})

-- Header
local queueHeader = makeFrame({dim = UDim2.new(1, 0, 0, COL_HEADER_H), z = 101, parent = queueColumn})

makeLabel({
	text = "PLAYLIST QUEUE", font = Enum.Font.GothamBold, size = 15,
	dim = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 12, 0, 0),
	z = 102, parent = queueHeader,
})

local clearB = nil
if isAdmin then
	clearB = makeBtn({
		dim = UDim2.new(0, 52, 0, 24), pos = UDim2.new(1, -60, 0.5, -12),
		bg = Color3.fromRGB(161, 124, 72), text = "CLEAR", textSize = 11,
		z = 103, round = 6, parent = queueHeader,
	})
end

-- Queue scroll
local queueScroll, queueList = makeScrollColumn(queueColumn, COL_HEADER_H + 4, {
	sizeXOff = -12, posX = 6, bottomOff = 8, padding = 4, paddingTop = 4, gap = 4,
}, THEME)

-- ════════════════════════════════════════════════════════════════
-- BOTTOM BAR CONTENT
-- ════════════════════════════════════════════════════════════════
local bottomContent = makeFrame({
	dim = UDim2.new(1, -24, 1, -12), pos = UDim2.new(0, 12, 0, 6),
	z = 111, parent = bottomBar,
})

-- ═══ SECCIÓN IZQUIERDA: Now Playing ═══
local nowPlaying = makeFrame({
	dim = UDim2.new(0.30, -10, 1, 0), z = 112, name = "NowPlaying", parent = bottomContent,
})

local MINI_COVER = mob and 48 or 70
miniCover = makeImage({
	dim = UDim2.new(0, MINI_COVER, 0, MINI_COVER),
	pos = UDim2.new(0, 0, 0.5, -MINI_COVER/2),
	z = 113, name = "MiniCover", parent = nowPlaying,
})
miniCover.ClipsDescendants = true
UI.rounded(miniCover, 6)
make("UIStroke", {Color = THEME.accent, Thickness = 1.5, Transparency = 0.5, Parent = miniCover})

local infoX = MINI_COVER + 10
local infoDim = UDim2.new(1, -MINI_COVER - 12, 0, 18)

songTitle = makeLabel({
	dim = infoDim, pos = UDim2.new(0, infoX, 0, mob and 8 or 12),
	text = "No song playing", font = Enum.Font.GothamBold, size = mob and 13 or 15,
	truncate = Enum.TextTruncate.AtEnd, z = 113, name = "SongTitle", parent = nowPlaying,
})

headerDJName = makeLabel({
	dim = UDim2.new(1, -MINI_COVER - 12, 0, 14),
	pos = UDim2.new(0, infoX, 0, mob and 26 or 32),
	color = THEME.muted, font = Enum.Font.GothamMedium, size = mob and 10 or 12,
	truncate = Enum.TextTruncate.AtEnd, z = 113, name = "DJName", parent = nowPlaying,
})

headerSongID = makeLabel({
	dim = UDim2.new(1, -MINI_COVER - 12, 0, 14),
	pos = UDim2.new(0, infoX, 0, mob and 40 or 48),
	color = THEME.accent, font = Enum.Font.GothamBold, size = mob and 10 or 12,
	z = 113, name = "SongID", parent = nowPlaying,
})

-- ═══ SECCIÓN CENTRAL: Progress + Input ═══
local centerSection = makeFrame({
	dim = UDim2.new(0.40, -20, 1, 0), pos = UDim2.new(0.30, 10, 0, 0),
	z = 112, name = "CenterSection", parent = bottomContent,
})

-- Progress bar
local progressContainer = makeFrame({
	dim = UDim2.new(1, 0, 0, 24), pos = UDim2.new(0, 0, 0, mob and 6 or 10),
	z = 113, parent = centerSection,
})

currentTimeLabel = makeLabel({
	dim = UDim2.new(0, 40, 1, 0), text = "0:00",
	color = THEME.muted, font = Enum.Font.GothamMedium, size = mob and 11 or 13,
	alignX = Enum.TextXAlignment.Right, z = 114, parent = progressContainer,
})

local progressBar = makeFrame({
	dim = UDim2.new(1, -100, 0, mob and 4 or 6),
	pos = UDim2.new(0, 48, 0.5, mob and -2 or -3),
	bg = Color3.fromRGB(60, 60, 68), bgT = 0, z = 113, parent = progressContainer,
})
UI.rounded(progressBar, 3)

progressFill = makeFrame({
	dim = UDim2.new(0, 0, 1, 0), bg = THEME.accent, bgT = 0, z = 114, parent = progressBar,
})
UI.rounded(progressFill, 3)

totalTimeLabel = makeLabel({
	dim = UDim2.new(0, 40, 1, 0), pos = UDim2.new(1, -40, 0, 0),
	text = "0:00", color = THEME.muted, font = Enum.Font.GothamMedium,
	size = mob and 11 or 13, alignX = Enum.TextXAlignment.Left, z = 114,
	parent = progressContainer,
})

-- Quick add frame
local quickAddFrame = makeFrame({
	dim = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, mob and 34 or 40),
	bg = THEME.card, bgT = 0, z = 113, parent = centerSection,
})
UI.rounded(quickAddFrame, 8)
qiStroke = UI.stroked(quickAddFrame, 0.3)

quickInput = make("TextBox", {
	Size = UDim2.new(1, -50, 0, 34), Position = UDim2.new(0, 10, 0.5, -17),
	BackgroundTransparency = 1, Text = "", PlaceholderText = "Input ID",
	TextColor3 = THEME.text, PlaceholderColor3 = THEME.muted,
	Font = Enum.Font.Gotham, TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false, ZIndex = 114, Parent = quickAddFrame,
})

quickInput:GetPropertyChangedSignal("Text"):Connect(function()
	if #quickInput.Text > 19 then quickInput.Text = string.sub(quickInput.Text, 1, 19) end
end)

quickAddBtn = makeBtn({
	dim = UDim2.new(0, 40, 0, 34), pos = UDim2.new(1, -44, 0.5, -17),
	bg = THEME.accent, z = 114, round = 6, parent = quickAddFrame,
})

quickAddBtnImg = makeImage({
	dim = UDim2.new(0.65, 0, 0.65, 0), pos = UDim2.new(0.175, 0, 0.175, 0),
	image = ICONS.PLAY_ADD, z = 115, parent = quickAddBtn,
})

quickAddBtnLoading = makeImage({
	dim = UDim2.new(0.65, 0, 0.65, 0), pos = UDim2.new(0.175, 0, 0.175, 0),
	image = ICONS.LOADING, z = 116, visible = false, parent = quickAddBtn,
})

songIdDisplay = makeLabel({
	dim = UDim2.new(1, 0, 0, 16), pos = UDim2.new(0, 0, 0, mob and 68 or 76),
	color = THEME.muted, font = Enum.Font.GothamMedium, size = 12,
	z = 113, visible = false, name = "SongIdDisplay", parent = centerSection,
})

-- ═══ SECCIÓN DERECHA: Skip + Volume ═══
local rightSection = makeFrame({
	dim = UDim2.new(0.30, -10, 1, 0), pos = UDim2.new(0.70, 10, 0, 0),
	z = 112, name = "RightControls", parent = bottomContent,
})

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = rightSection,
})
make("UIPadding", {PaddingRight = UDim.new(0, 4), Parent = rightSection})

local skipB = makeBtn({
	dim = UDim2.new(0, 90, 0, 34), bg = THEME.accent,
	text = "Skip song", textSize = 13, z = 113,
	round = 8, parent = rightSection, name = "SkipBtn",
})
skipB.LayoutOrder = 2

-- Volume control
local volFrame = makeFrame({
	dim = UDim2.new(0, 140, 0, 34), z = 113,
	name = "VolumeControl", parent = rightSection,
})
volFrame.LayoutOrder = 1

makeImage({
	dim = UDim2.new(0, 22, 0, 22), pos = UDim2.new(0, 0, 0.5, -11),
	image = "rbxassetid://14861812886", imageColor = THEME.muted,
	z = 114, parent = volFrame,
})

volSliderBg = makeFrame({
	dim = UDim2.new(0, 70, 0, 6), pos = UDim2.new(0, 28, 0.5, -3),
	bg = Color3.fromRGB(40, 40, 48), bgT = 0, z = 114, parent = volFrame,
})
UI.rounded(volSliderBg, 3)

volSliderFill = makeFrame({
	dim = UDim2.new(1, 0, 1, 0), bg = THEME.accent, bgT = 0, z = 115, parent = volSliderBg,
})
UI.rounded(volSliderFill, 3)

volLabelText = makeLabel({
	dim = UDim2.new(0, 38, 0, 24), pos = UDim2.new(0, 102, 0.5, -12),
	text = "100%", color = THEME.muted, font = Enum.Font.GothamMedium,
	size = 11, alignX = Enum.TextXAlignment.Center, z = 114, parent = volFrame,
})

volInput = make("TextBox", {
	Size = UDim2.new(0, 40, 0, 24), Position = UDim2.new(0, 100, 0.5, -12),
	BackgroundColor3 = Color3.fromRGB(60, 60, 70), Text = "100",
	TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 12,
	BorderSizePixel = 0, ZIndex = 116, Visible = false,
	ClearTextOnFocus = true, TextXAlignment = Enum.TextXAlignment.Center,
	Parent = volFrame,
})
UI.rounded(volInput, 4)

-- ════════════════════════════════════════════════════════════════
-- ADD BUTTON STATE MACHINE
-- ════════════════════════════════════════════════════════════════
local function setAddButtonState(state, customMessage)
	if not quickAddBtn or not quickInput or not qiStroke then return end
	if loadingDotsThread then task.cancel(loadingDotsThread); loadingDotsThread = nil end

	local states = {
		loading   = {adding = true,  bg = THEME.surface, stroke = THEME.accent, auto = false},
		success   = {adding = false, bg = Color3.fromRGB(72, 187, 120), stroke = Color3.fromRGB(72, 187, 120), clear = true, delay = 2},
		error     = {adding = false, bg = THEME.btnDanger, stroke = THEME.btnDanger, clear = true, placeholder = customMessage, delay = 3},
		duplicate = {adding = false, bg = THEME.warn, stroke = THEME.warn, clear = true, placeholder = customMessage or "La canción ya está en la cola", delay = 3},
		default   = {adding = false, bg = THEME.accent, stroke = THEME.stroke, auto = true, placeholder = "Input ID"},
	}

	local s = states[state] or states.default
	isAddingToQueue = s.adding
	quickAddBtn.BackgroundColor3 = s.bg
	qiStroke.Color = s.stroke
	quickAddBtn.AutoButtonColor = s.auto ~= false

	if state == "loading" then
		quickAddBtnImg.Visible = false
		quickAddBtnLoading.Visible = true
		if loadingDotsThread then task.cancel(loadingDotsThread); loadingDotsThread = nil end
		loadingDotsThread = task.spawn(function()
			local tween = TweenService:Create(quickAddBtnLoading, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
			tween:Play()
			while true do task.wait(0.1) end
		end)
	else
		quickAddBtnLoading.Visible = false
		quickAddBtnImg.Visible = true
	end

	if s.clear then quickInput.Text = "" end
	if s.placeholder then quickInput.PlaceholderText = s.placeholder end
	if s.delay then
		task.delay(s.delay, function()
			if quickAddBtn and qiStroke then setAddButtonState("default") end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- QUICK ADD + RESPONSE HANDLERS
-- ════════════════════════════════════════════════════════════════
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

-- Función reutilizable para actualizar card después de response
local function updatePendingCard(response)
	task.defer(function()
		local targetSongId = pendingCardSongId; pendingCardSongId = nil
		if not targetSongId then return end
		for _, card in ipairs(cardPool) do
			if card.Visible and card:GetAttribute("SongID") == targetSongId then
				local addBtn = card:FindFirstChild("AddButton")
				if not addBtn then break end
				
				-- Ocultar icono de cargando
				local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
				if loadingIcon then loadingIcon.Visible = false end
				
				local icon = addBtn:FindFirstChild("IconImage")
				if icon then icon.Visible = true end
				
				if response.success or response.code == ResponseCodes.ERROR_DUPLICATE then
					if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1, 1, 1) end
					addBtn.BackgroundColor3 = THEME.success
					addBtn.AutoButtonColor = false
				else
					if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.text end
					addBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 68); addBtn.AutoButtonColor = true
				end
				break
			end
		end
	end)
end

if R.AddResponse then
	R.AddResponse.OnClientEvent:Connect(function(response)
		if not response then return end
		showNotification(response)
		if response.success then setAddButtonState("success")
		elseif response.code == ResponseCodes.ERROR_DUPLICATE then setAddButtonState("duplicate", response.message)
		else setAddButtonState("error", response.message) end
		updatePendingCard(response)
	end)
end

-- Handlers simples de notificación
for _, remoteName in ipairs({"RemoveResponse", "ClearResponse"}) do
	if R[remoteName] then
		R[remoteName].OnClientEvent:Connect(function(response)
			if response then showNotification(response) end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- VOLUME LOGIC
-- ════════════════════════════════════════════════════════════════
local maxVolume = MusicSystemConfig.PLAYBACK.MaxVolume
local minVolume = MusicSystemConfig.PLAYBACK.MinVolume
local currentVolume = player:GetAttribute("MusicVolume") or MusicSystemConfig.PLAYBACK.DefaultVolume
local dragging = false

local function updateVolume(volume)
	currentVolume = math.clamp(volume, minVolume, maxVolume)
	local fill = (currentVolume - minVolume) / (maxVolume - minVolume)
	volSliderFill.Size = UDim2.new(fill, 0, 1, 0)

	if isMusicMuted() then
		volLabelText.Text = "MUTE"; volLabelText.TextColor3 = Color3.fromRGB(200, 80, 80)
	else
		volLabelText.Text = math.floor(currentVolume * 100) .. "%"; volLabelText.TextColor3 = THEME.muted
	end

	volInput.Text = tostring(math.floor(currentVolume * 100))
	player:SetAttribute("MusicVolume", currentVolume)

	local sg = SoundService:FindFirstChild("MusicSoundGroup")
	if sg then sg.Volume = isMusicMuted() and 0 or currentVolume end
	if R.ChangeVolume then pcall(function() R.ChangeVolume:FireServer(currentVolume) end) end
end

-- Monitor mute state
local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup") or SoundService:WaitForChild("MusicSoundGroup", 10)
task.spawn(function()
	local lastMute = isMusicMuted()
	while true do
		task.wait(0.1)
		local muted = isMusicMuted()
		if muted ~= lastMute then
			lastMute = muted
			if musicSoundGroup then
				musicSoundGroup.Volume = muted and 0 or currentVolume
				volLabelText.Text = muted and "MUTE" or (math.floor(currentVolume * 100) .. "%")
				volLabelText.TextColor3 = muted and Color3.fromRGB(200, 80, 80) or THEME.muted
				tween(volSliderBg, 0.2, {BackgroundColor3 = muted and Color3.fromRGB(50, 30, 30) or Color3.fromRGB(40, 40, 48)})
				volSliderFill.BackgroundColor3 = muted and Color3.fromRGB(150, 70, 70) or THEME.accent
			end
		end
	end
end)

updateVolume(currentVolume)

-- Volume slider interaction
local function handleMuteCheck()
	if isMusicMuted() then
		Notify:Info("Música Silenciada", "Desmutea el sonido en el topbar para cambiar el volumen", 2)
		return true
	end
	return false
end

volSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if handleMuteCheck() then return end
		dragging = true
		updateVolume(math.clamp((input.Position.X - volSliderBg.AbsolutePosition.X) / volSliderBg.AbsoluteSize.X, 0, 1))
	end
end)
volSliderBg.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
volSliderBg.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateVolume(math.clamp((input.Position.X - volSliderBg.AbsolutePosition.X) / volSliderBg.AbsoluteSize.X, 0, 1))
	end
end)

-- Volume label click → input
volLabelText.Parent.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if handleMuteCheck() then return end
		volInput.Visible = true; volLabelText.Visible = false
		volInput:CaptureFocus(); volInput.Text = tostring(math.floor(currentVolume * 100))
	end
end)

volInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = volInput.Text:gsub("[^%d]", "")
	if #text > 3 then text = string.sub(text, 1, 3) end
	local v = tonumber(text)
	local maxP = math.floor(maxVolume * 100)
	if v and v > maxP then text = tostring(maxP) end
	volInput.Text = text
end)

local function applyVolumeInput()
	updateVolume(math.clamp(tonumber(volInput.Text) or 100, 0, math.floor(maxVolume * 100)) / 100)
	volInput.Visible = false; volLabelText.Visible = true
end

volInput.FocusLost:Connect(applyVolumeInput)

-- ════════════════════════════════════════════════════════════════
-- SKIP/CLEAR LOGIC
-- ════════════════════════════════════════════════════════════════
local skipProductId = 3468988018
local skipRemote = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("MusicQueue"):WaitForChild("PurchaseSkip")
local lastSkipTime = 0
local skipCooldown = MusicSystemConfig.LIMITS.SkipCooldown or 3

skipB.MouseButton1Click:Connect(function()
	local elapsed = tick() - lastSkipTime
	if not isAdmin and elapsed < skipCooldown then
		Notify:Info("Cooldown", "Espera " .. math.ceil(skipCooldown - elapsed) .. " segundos")
		return
	end
	lastSkipTime = tick()
	if isAdmin then
		if R.Next then R.Next:FireServer() end
	else
		MarketplaceService:PromptProductPurchase(player, skipProductId)
	end
end)

if clearB then clearB.MouseButton1Click:Connect(function() if R.Clear then R.Clear:FireServer() end end) end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if userId == player.UserId and productId == skipProductId and wasPurchased and skipRemote then
		pcall(function() skipRemote:FireServer(true) end)
	end
end)

-- ════════════════════════════════════════════════════════════════
-- DRAW QUEUE (columna derecha)
-- ════════════════════════════════════════════════════════════════
local function clearChildren(parent, keep)
	for _, child in pairs(parent:GetChildren()) do
		local skip = false
		for _, cls in ipairs(keep or {}) do if child:IsA(cls) then skip = true; break end end
		if not skip then child:Destroy() end
	end
end

local function createActiveCardEffects(card)
	local glowStroke = make("UIStroke", {
		Color = THEME.avatarRingGlow or THEME.accent,
		Thickness = 1.2, Transparency = 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card,
	})
	task.spawn(function()
		while card.Parent do
			tween(glowStroke, 1, {Transparency = 0, Thickness = 1.6}); task.wait(1)
			tween(glowStroke, 1, {Transparency = 0.5, Thickness = 1.2}); task.wait(1)
		end
	end)

	local grad = make("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(48, 52, 70)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(68, 72, 100)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(48, 52, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 32)),
		},
		Transparency = NumberSequence.new(0.3), Offset = Vector2.new(-1, 0),
		Parent = card,
	})
	task.spawn(function()
		while card.Parent do
			tween(grad, 2.5, {Offset = Vector2.new(1, 0)}); task.wait(2.5)
			grad.Offset = Vector2.new(-1, 0); task.wait(0.5)
		end
	end)
end

local function drawQueue()
	clearChildren(queueScroll, {"UIListLayout", "UIPadding"})

	if #playQueue == 0 then
		makeLabel({text = "Queue is empty", color = THEME.muted, size = 13, dim = UDim2.new(1, 0, 0, 60), wrap = true, parent = queueScroll})
		return
	end

	for i, song in ipairs(playQueue) do
		local isActive = currentSong and song.id == currentSong.id
		local userId = song.userId or song.requestedByUserId

		local card = makeFrame({
			dim = UDim2.new(1, 0, 0, 54),
			bg = isActive and THEME.accent or THEME.card, bgT = 0,
			z = 101, parent = queueScroll,
		})
		UI.rounded(card, 8)
		UI.stroked(card, isActive and 0.6 or 0.3)

		if isActive then createActiveCardEffects(card) end

		local contentLeft = 4
		if userId then
			local avatar = makeImage({
				dim = UDim2.new(0, 40, 0, 40), pos = UDim2.new(0, 4, 0.5, -20),
				z = 102, parent = card,
			})
			UI.rounded(avatar, 20)
			make("UIStroke", {
				Color = isActive and THEME.accent or Color3.fromRGB(100, 100, 110),
				Thickness = isActive and 2 or 1, Parent = avatar,
			})
			task.spawn(function()
				local ok, thumb = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				if ok then avatar.Image = thumb end
			end)
			contentLeft = 50
		end

		make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8), Parent = card})

		local nameClip = makeFrame({
			dim = UDim2.new(1, -(contentLeft + (isAdmin and 40 or 8)), 0, 18),
			pos = UDim2.new(0, contentLeft, 0, 8),
			z = 102, clip = true, parent = card,
		})
		makeLabel({
			text = song.name or "Unknown",
			color = isActive and Color3.new(1, 1, 1) or THEME.text,
			font = Enum.Font.GothamBold, size = 12,
			truncate = Enum.TextTruncate.AtEnd, z = 102, parent = nameClip,
		})

		makeLabel({
			dim = UDim2.new(1, -(contentLeft + (isAdmin and 40 or 8)), 0, 14),
			pos = UDim2.new(0, contentLeft, 0, 28),
			text = song.requestedBy or "Unknown",
			color = isActive and Color3.fromRGB(220, 220, 230) or THEME.muted,
			font = Enum.Font.GothamMedium, size = 11,
			truncate = Enum.TextTruncate.AtEnd, z = 102, parent = card,
		})

		if isAdmin then
			local removeBtn = makeBtn({
				dim = UDim2.new(0, 28, 0, 28), pos = UDim2.new(1, -32, 0.5, -14),
				bg = THEME.btnDanger, z = 103, round = 8, parent = card,
			})
			makeImage({
				dim = UDim2.new(0.7, 0, 0.7, 0), pos = UDim2.new(0.15, 0, 0.15, 0),
				image = ICONS.DELETE, z = 104, name = "IconImage", parent = removeBtn,
			})
			removeBtn.MouseButton1Click:Connect(function()
				if R.Remove then R.Remove:FireServer(i) end
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SONG CARD POOL (virtualización)
-- ════════════════════════════════════════════════════════════════
local function createSongCard()
	local card = makeFrame({dim = UDim2.new(1, -8, 0, CARD_HEIGHT), bg = THEME.card, bgT = 0, z = 102})
	card.Visible = false
	UI.rounded(card, 8); UI.stroked(card, 0.3)
	make("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card})

	makeImage({dim = UDim2.new(0, 38, 0, 38), pos = UDim2.new(0, 0, 0, 8), bg = Color3.fromRGB(30, 30, 35), bgT = 0, z = 103, name = "DJCover", parent = card})
	UI.rounded(card:FindFirstChild("DJCover"), 6)

	makeLabel({dim = UDim2.new(1, -170, 0, 18), pos = UDim2.new(0, 48, 0, 10), font = Enum.Font.GothamBold, size = 14, truncate = Enum.TextTruncate.AtEnd, z = 103, name = "NameLabel", parent = card})
	makeLabel({dim = UDim2.new(1, -170, 0, 14), pos = UDim2.new(0, 48, 0, 28), color = THEME.muted, font = Enum.Font.GothamMedium, size = 12, truncate = Enum.TextTruncate.AtEnd, z = 103, name = "ArtistLabel", parent = card})

	local addBtn = makeBtn({dim = UDim2.new(0, 32, 0, 32), pos = UDim2.new(1, -36, 0.5, -16), z = 103, round = 16, name = "AddButton", parent = card})
	makeImage({dim = UDim2.new(0.75, 0, 0.75, 0), pos = UDim2.new(0.125, 0, 0.125, 0), image = ICONS.PLAY_ADD, imageColor = THEME.text, z = 104, name = "IconImage", parent = addBtn})
	
	local loadingIcon = makeImage({
		dim = UDim2.new(0.75, 0, 0.75, 0), pos = UDim2.new(0.125, 0, 0.125, 0),
		image = ICONS.LOADING, imageColor = THEME.text, z = 105, visible = false, name = "LoadingIcon", parent = addBtn,
	})

	return card
end

local function getCardFromPool()
	for _, card in ipairs(cardPool) do if not card.Visible then return card end end
	if #cardPool < MAX_POOL_SIZE then
		local c = createSongCard(); c.Parent = songsContainer; table.insert(cardPool, c); return c
	end
end

local function releaseCard(card)
	local idx = card:GetAttribute("SongIndex")
	if idx then cardsIndex[idx] = nil end
	card.Visible = false; card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil)
end

local function releaseAllCards()
	cardsIndex = {}
	for _, card in ipairs(cardPool) do
		card.Visible = false; card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil)
	end
end

-- ════════════════════════════════════════════════════════════════
-- VIRTUAL SCROLL
-- ════════════════════════════════════════════════════════════════
local function getSongData() return virtualScrollState.isSearching and virtualScrollState.searchResults or virtualScrollState.songData end
local function getTotalSongs() return virtualScrollState.isSearching and #virtualScrollState.searchResults or virtualScrollState.totalSongs end

local function updateSongCard(card, data, index, inQueue)
	if not card or not data then return end
	card:SetAttribute("SongIndex", index); card:SetAttribute("SongID", data.id)
	cardsIndex[index] = card

	local djCover = card:FindFirstChild("DJCover")
	if djCover and selectedDJInfo and selectedDJInfo.cover then djCover.Image = selectedDJInfo.cover end

	local nl = card:FindFirstChild("NameLabel")
	if nl then nl.Text = data.name or "Cargando..."; nl.TextColor3 = data.loaded and THEME.text or THEME.muted end

	local al = card:FindFirstChild("ArtistLabel")
	if al then al.Text = data.artist or ("ID: " .. data.id) end

	local ab = card:FindFirstChild("AddButton")
	if ab then
		local icon = ab:FindFirstChild("IconImage")
		local loadingIcon = ab:FindFirstChild("LoadingIcon")
		if inQueue then
			ab.BackgroundColor3 = THEME.success
			ab.AutoButtonColor = false
			if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1, 1, 1); icon.Visible = true end
			if loadingIcon then loadingIcon.Visible = false end
		else
			ab.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
			ab.AutoButtonColor = true
			if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.text; icon.Visible = true end
			if loadingIcon then loadingIcon.Visible = false end
		end
	end

	card.Position = UDim2.new(0, 4, 0, (index - 1) * (CARD_HEIGHT + CARD_PADDING))
	card.Visible = true
end

local function updateVisibleCards()
	if not songsScroll or not songsScroll.Parent then return end
	local totalItems = getTotalSongs()
	if totalItems == 0 then releaseAllCards(); return end

	local scrollY, vpH = songsScroll.CanvasPosition.Y, songsScroll.AbsoluteSize.Y
	local step = CARD_HEIGHT + CARD_PADDING
	local first = math.max(1, math.floor(scrollY / step) + 1 - VISIBLE_BUFFER)
	local last = math.min(totalItems, math.ceil((scrollY + vpH) / step) + VISIBLE_BUFFER)

	local totalH = totalItems * step
	songsContainer.Size = UDim2.new(1, 0, 0, totalH)
	songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)

	for idx, card in pairs(cardsIndex) do
		if card and card.Visible and (idx < first or idx > last) then releaseCard(card) end
	end

	local dataSource = getSongData()
	local needsFetch = {}

	for i = first, last do
		local sd = dataSource[i]
		if sd then
			local c = cardsIndex[i] or getCardFromPool()
			if c then updateSongCard(c, sd, i, isInQueue(sd.id)) end
		elseif not virtualScrollState.isSearching then
			table.insert(needsFetch, i)
		end
	end

	if #needsFetch > 0 and not virtualScrollState.isSearching then
		local mn, mx = math.huge, 0
		for _, idx in ipairs(needsFetch) do mn = math.min(mn, idx); mx = math.max(mx, idx) end
		local key = mn .. "-" .. mx
		if not virtualScrollState.pendingRequests[key] then
			virtualScrollState.pendingRequests[key] = true
			if R.GetSongRange and selectedDJ then R.GetSongRange:FireServer(selectedDJ, mn, mx) end
		end
	end

	virtualScrollState.firstVisibleIndex = first
	virtualScrollState.lastVisibleIndex = last
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
	loadingIndicator.Visible = true; loadingIndicator.Text = "Buscando..."
	if R.SearchSongs and selectedDJ then R.SearchSongs:FireServer(selectedDJ, query) end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if not selectedDJ then return end
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce = task.delay(0.3, function() performSearch(searchInput.Text) end)
end)

songsContainer.ChildAdded:Connect(function(child)
	if not child:IsA("Frame") then return end
	local addBtn = child:FindFirstChild("AddButton")
	if addBtn then
		addBtn.MouseButton1Click:Connect(function()
			local songId = child:GetAttribute("SongID")
			if songId and not isInQueue(songId) and not pendingCardSongId then
				pendingCardSongId = songId
				
				-- Mostrar animación de cargando
				local iconImg = addBtn:FindFirstChild("IconImage")
				local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
				
				if iconImg then iconImg.Visible = false end
				if loadingIcon then
					loadingIcon.Visible = true
					task.spawn(function()
						local tween = TweenService:Create(loadingIcon, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
						tween:Play()
						while loadingIcon.Visible do task.wait(0.1) end
						if tween then tween:Cancel() end
					end)
				end
				
				addBtn.BackgroundColor3 = THEME.surface
				addBtn.AutoButtonColor = false
				if R.Add then R.Add:FireServer(songId) end
			end
		end)
	end
end)

-- ════════════════════════════════════════════════════════════════
-- HEADER COVER UPDATE
-- ════════════════════════════════════════════════════════════════
local function updateHeaderCover(song)
	if not song then
		if currentHeaderCover ~= "" then
			currentHeaderCover = ""
			TweenService:Create(bottomBarBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
			task.delay(0.3, function()
				miniCover.Image = ""; bottomBarBg.Image = ""; headerDJName.Text = ""
			end)
		end
		return
	end
	local cover = song.djCover or ""
	if cover ~= currentHeaderCover then
		currentHeaderCover = cover
		-- Fade out → cambiar imagen → fade in
		TweenService:Create(bottomBarBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
		task.delay(0.25, function()
			miniCover.Image = cover
			bottomBarBg.Image = cover
			TweenService:Create(bottomBarBg, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {ImageTransparency = 0.6}):Play()
		end)
	end
	headerDJName.Text = song.dj or ""
	headerSongID.Text = song.id and ("ID: " .. tostring(song.id)) or ""
	songIdDisplay.Text = song.id and tostring(song.id) or ""
end

-- ════════════════════════════════════════════════════════════════
-- DRAW DJs (columna izquierda)
-- ════════════════════════════════════════════════════════════════
local function drawDJs()
	clearChildren(djsScroll, {"UIListLayout", "UIPadding"})
	selectedDJCard = nil

	if #allDJs == 0 then
		makeLabel({text = "No DJs available", color = THEME.muted, size = 13, dim = UDim2.new(1, 0, 0, 60), parent = djsScroll})
		return
	end

	for _, dj in ipairs(allDJs) do
		local isSel = selectedDJ == dj.name

		local card = makeFrame({
			dim = UDim2.new(1, 0, 0, 68),
			bg = Color3.fromRGB(22, 22, 28),
			bgT = isSel and 0.1 or 0.3, z = 102, parent = djsScroll,
		})
		UI.rounded(card, 8)

		-- Un solo UIStroke por card, tweeneado en hover/click
		local stroke = make("UIStroke", {
			Color = isSel and THEME.accent or THEME.stroke,
			Thickness = isSel and 1.5 or 1,
			Transparency = isSel and 0.3 or 0.6,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = card,
		})

		if isSel then selectedDJCard = card end

		-- Music icon (fallback)
		makeLabel({
			dim = UDim2.new(0, 48, 0, 48), pos = UDim2.new(0, 8, 0.5, -24),
			text = "♪", font = Enum.Font.GothamBold, size = 28,
			color = isSel and THEME.accent or THEME.muted,
			alignX = Enum.TextXAlignment.Center, z = 103, parent = card,
		})

		if dj.cover and dj.cover ~= "" then
			local cover = makeImage({
				dim = UDim2.new(0, 48, 0, 48), pos = UDim2.new(0, 8, 0.5, -24),
				bg = Color3.fromRGB(30, 30, 40), bgT = 0, image = dj.cover, z = 104, parent = card,
			})
			UI.rounded(cover, 6)
		end

		makeLabel({
			dim = UDim2.new(1, -80, 0, 22), pos = UDim2.new(0, 64, 0, 8),
			text = dj.name, color = isSel and THEME.text or Color3.fromRGB(200, 200, 210),
			font = Enum.Font.GothamBold, size = 14,
			truncate = Enum.TextTruncate.AtEnd, z = 103, parent = card,
		})

		makeLabel({
			dim = UDim2.new(1, -80, 0, 18), pos = UDim2.new(0, 64, 0, 32),
			text = dj.songCount .. " songs", color = THEME.accent,
			font = Enum.Font.GothamMedium, size = 12, z = 103, parent = card,
		})

		local clickBtn = makeBtn({dim = UDim2.new(1, 0, 1, 0), z = 105, parent = card})
		clickBtn.BackgroundTransparency = 1

		-- Hover suave sobre la card
		clickBtn.MouseEnter:Connect(function()
			if selectedDJCard ~= card then
				tween(card, 0.2, {BackgroundTransparency = 0.15})
				tween(stroke, 0.2, {Color = THEME.accentHover, Transparency = 0.5})
			end
		end)
		clickBtn.MouseLeave:Connect(function()
			if selectedDJCard ~= card then
				tween(card, 0.2, {BackgroundTransparency = 0.3})
				tween(stroke, 0.2, {Color = THEME.stroke, Transparency = 0.6})
			end
		end)

		clickBtn.MouseButton1Click:Connect(function()
			-- Deseleccionar anterior con tween suave
			if selectedDJCard and selectedDJCard ~= card then
				local prevStroke = selectedDJCard:FindFirstChildWhichIsA("UIStroke")
				if prevStroke then
					tween(prevStroke, 0.25, {Color = THEME.stroke, Transparency = 0.6})
					tween(prevStroke.Parent, 0.25, {BackgroundTransparency = 0.3})
				end
			end

			-- Seleccionar nueva card con tween suave
			selectedDJ = dj.name; selectedDJInfo = dj; selectedDJCard = card
			tween(stroke, 0.25, {Color = THEME.accent, Transparency = 0.3})
			tween(card, 0.25, {BackgroundTransparency = 0.1})

			virtualScrollState.totalSongs = dj.songCount
			virtualScrollState.songData = {}
			virtualScrollState.searchResults = {}
			virtualScrollState.isSearching = false
			virtualScrollState.searchQuery = ""
			virtualScrollState.pendingRequests = {}

			searchInput.Text = ""
			songCountLabel.Text = dj.songCount .. " songs"; songCountLabel.Visible = true
			songsPlaceholder.Visible = false
			songsTitle.Text = dj.name

			releaseAllCards()
			songsScroll.CanvasPosition = Vector2.new(0, 0)

			local totalH = dj.songCount * (CARD_HEIGHT + CARD_PADDING)
			songsContainer.Size = UDim2.new(1, 0, 0, totalH)
			songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)

			connectScrollListener()
			if R.GetSongRange then R.GetSongRange:FireServer(dj.name, 1, BATCH_SIZE) end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- PROGRESS BAR UPDATE
-- ════════════════════════════════════════════════════════════════
local function updateProgressBar()
	if not currentSoundObject then currentSoundObject = workspace:FindFirstChild("QueueSound") end
	if not currentSoundObject or not currentSoundObject:IsA("Sound") or not currentSoundObject.Parent then
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"; totalTimeLabel.Text = "0:00"
		if not currentSong then songTitle.Text = "No song playing" end
		return
	end
	local cur, total = currentSoundObject.TimePosition, currentSoundObject.TimeLength
	if total > 0 then
		progressFill.Size = UDim2.new(math.clamp(cur / total, 0, 1), 0, 1, 0)
		currentTimeLabel.Text = formatTime(cur); totalTimeLabel.Text = formatTime(total)
	else
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"; totalTimeLabel.Text = "0:00"
	end
end

-- ════════════════════════════════════════════════════════════════
-- UI OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	drawQueue()
	if #allDJs > 0 then drawDJs() end
	modal:open()
	if progressConnection then progressConnection:Disconnect() end
	progressConnection = RunService.Heartbeat:Connect(updateProgressBar)
end

local function closeUI()
	if modal:isModalOpen() then modal:close() end
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and modal:isModalOpen() then
		GlobalModalManager:closeModal("Music")
	elseif input.KeyCode == Enum.KeyCode.Return and volInput.Visible then
		applyVolumeInput()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- REMOTE UPDATES
-- ════════════════════════════════════════════════════════════════
local function updateNowPlayingInfo(song)
	if song then
		songTitle.Text = song.name
		headerDJName.Text = song.artist or "Unknown"
		headerSongID.Text = song.id and ("ID: " .. tostring(song.id)) or ""
		songIdDisplay.Text = song.id and tostring(song.id) or ""
	else
		songTitle.Text = "No song playing"
		headerDJName.Text = ""; headerSongID.Text = ""; songIdDisplay.Text = ""
	end
end

if R.Update then
	R.Update.OnClientEvent:Connect(function(data)
		playQueue = data.queue or {}
		currentSong = data.currentSong
		allDJs = data.djs or allDJs
		currentSoundObject = workspace:FindFirstChild("QueueSound")

		updateNowPlayingInfo(currentSong)
		updateHeaderCover(currentSong)
		drawQueue()
		if selectedDJ then updateVisibleCards() end
		if #allDJs > 0 then drawDJs() end
	end)
end

if R.GetDJs then
	R.GetDJs.OnClientEvent:Connect(function(d)
		allDJs = (d and (d.djs or d)) or allDJs
		drawDJs()
	end)
end

if R.GetSongRange then
	R.GetSongRange.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end
		loadingIndicator.Visible = false
		for _, song in ipairs(data.songs or {}) do virtualScrollState.songData[song.index] = song end
		virtualScrollState.pendingRequests[data.startIndex .. "-" .. data.endIndex] = nil
		updateVisibleCards()
	end)
end

if R.SearchSongs then
	R.SearchSongs.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end
		loadingIndicator.Visible = false
		virtualScrollState.searchResults = data.songs or {}
		local total = data.totalInDJ or virtualScrollState.totalSongs
		local countText = #virtualScrollState.searchResults .. " / " .. total .. " songs"
		if data.cachedCount and data.cachedCount < total then
			countText = countText .. " " .. math.floor(data.cachedCount / total * 100) .. "%"
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
		local totalH = data.total * (CARD_HEIGHT + CARD_PADDING)
		songsContainer.Size = UDim2.new(1, 0, 0, totalH)
		songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
if R.GetDJs then R.GetDJs:FireServer() end

for _ = 1, MAX_POOL_SIZE do
	local card = createSongCard(); card.Parent = songsContainer; table.insert(cardPool, card)
end

-- ════════════════════════════════════════════════════════════════
-- GLOBAL FUNCTIONS
-- ════════════════════════════════════════════════════════════════
_G.OpenMusicUI = openUI
_G.CloseMusicUI = closeUI