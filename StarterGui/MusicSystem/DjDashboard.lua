--[[ Music Dashboard - Professional Edition v6
	by ignxts
	OPTIMIZADO: Virtualización + Búsqueda + Carga bajo demanda
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
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

local ADMIN_IDS = {
	8387751399,
	9375636407,
}

local function isAdminUser(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then return true end
	end
	return false
end

local SHOW_ADMIN_UI = false
local isAdmin = isAdminUser(player.UserId) or SHOW_ADMIN_UI

-- ════════════════════════════════════════════════════════════════
-- THEME & CONFIG
-- ════════════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local R_PANEL, R_CTRL = 12, 10
local ENABLE_BLUR, BLUR_SIZE = true, 14

local USE_PIXEL_SIZE = true
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620

-- ════════════════════════════════════════════════════════════════
-- VIRTUALIZACIÓN CONFIG
-- ════════════════════════════════════════════════════════════════
local CARD_HEIGHT = 54
local CARD_PADDING = 6
local VISIBLE_BUFFER = 3 -- Cards extra arriba/abajo del viewport
local BATCH_SIZE = 15 -- Cuántas canciones pedir por batch

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local musicLibrary, playQueue, currentSong = {}, {}, nil
local allDJs, selectedDJ = {}, nil
local currentPage = "Queue"
local currentSoundObject = nil
local progressConnection = nil

-- Virtual scroll state
local virtualScrollState = {
	totalSongs = 0,
	songData = {}, -- Cache local de canciones: index -> songInfo
	visibleCards = {}, -- Pool de cards UI
	firstVisibleIndex = 1,
	lastVisibleIndex = 1,
	isSearching = false,
	searchQuery = "",
	searchResults = {},
	pendingRequests = {}, -- Rangos que ya pedimos
}

-- UI Elements references
local quickAddBtn, quickInput, qiStroke = nil, nil, nil
local isAddingToQueue = false
local songsScroll = nil
local songsContainer = nil
local searchInput = nil
local loadingIndicator = nil
local songCountLabel = nil

-- Pool de cards (declarado aquí para que exista cuando llega AddResponse)
local cardPool = {}
local MAX_POOL_SIZE = 25

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local isValidAudioId = function(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	local len = #text
	return (len >= 6 and len <= 19)
end

local function getRemote(name)
	local MusicRemotes = ReplicatedStorage:WaitForChild("MusicRemotes", 10)
	if not MusicRemotes then return end

	local remoteMap = {
		NextSong = "MusicPlayback",
		PlaySong = "MusicPlayback",
		PauseSong = "MusicPlayback",
		StopSong = "MusicPlayback",
		AddToQueue = "MusicQueue",
		AddToQueueResponse = "MusicQueue",
		RemoveFromQueue = "MusicQueue",
		RemoveFromQueueResponse = "MusicQueue",
		ClearQueue = "MusicQueue",
		ClearQueueResponse = "MusicQueue",
		UpdateUI = "UI",
		GetDJs = "MusicLibrary",
		GetSongsByDJ = "MusicLibrary",
		GetSongRange = "MusicLibrary",
		SearchSongs = "MusicLibrary",
		GetSongMetadata = "MusicLibrary",
	}

	local subfolder = remoteMap[name] or "MusicLibrary"
	local folder = MusicRemotes:FindFirstChild(subfolder)
	if not folder then return nil end
	return folder:FindFirstChild(name)
end

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- ════════════════════════════════════════════════════════════════
-- NOTIFICATION HELPER
-- ════════════════════════════════════════════════════════════════
local function showNotification(response)
	local config = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local notifyType = config.type
	local title = config.title
	local message = response.message or "Operación completada"

	if response.data and response.data.songName then
		message = message .. ": " .. response.data.songName
	end

	if notifyType == "success" then
		Notify:Success(title, message, 3)
	elseif notifyType == "warning" then
		Notify:Warning(title, message, 3)
	elseif notifyType == "error" then
		Notify:Error(title, message, 4)
	else
		Notify:Info(title, message, 3)
	end
end

-- ════════════════════════════════════════════════════════════════
-- UI STATE HELPER
-- ════════════════════════════════════════════════════════════════
local function setAddButtonState(state, customMessage)
	if not quickAddBtn or not quickInput or not qiStroke then return end

	if state == "loading" then
		isAddingToQueue = true
		quickAddBtn.Text = "..."
		quickAddBtn.BackgroundColor3 = THEME.info
		qiStroke.Color = THEME.info
		quickAddBtn.AutoButtonColor = false
	elseif state == "success" then
		isAddingToQueue = false
		quickInput.Text = ""
		qiStroke.Color = THEME.success
		quickAddBtn.Text = "AÑADIDO"
		quickAddBtn.BackgroundColor3 = THEME.success
		task.delay(2, function()
			if quickAddBtn and qiStroke then setAddButtonState("default") end
		end)
	elseif state == "error" then
		isAddingToQueue = false
		quickInput.Text = ""
		qiStroke.Color = THEME.danger
		quickAddBtn.Text = "ERROR"
		quickAddBtn.BackgroundColor3 = THEME.danger
		if customMessage then quickInput.PlaceholderText = customMessage end
		task.delay(3, function()
			if quickAddBtn and qiStroke then setAddButtonState("default") end
		end)
	elseif state == "duplicate" then
		isAddingToQueue = false
		quickInput.Text = ""
		qiStroke.Color = Color3.fromRGB(255, 150, 0)
		quickAddBtn.Text = "DUPLICADO"
		quickAddBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		quickInput.PlaceholderText = customMessage or "La canción ya está en la cola"
		task.delay(3, function()
			if quickAddBtn and qiStroke then setAddButtonState("default") end
		end)
	elseif state == "default" then
		isAddingToQueue = false
		qiStroke.Color = THEME.stroke
		quickInput.PlaceholderText = "Introduce ID de audio..."
		quickAddBtn.Text = "AÑADIR"
		quickAddBtn.BackgroundColor3 = THEME.accent
		quickAddBtn.AutoButtonColor = true
	end
end

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local R = {
	Next = getRemote("NextSong"),
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
}

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = script.Parent
screenGui.IgnoreGuiInset = true

-- ════════════════════════════════════════════════════════════════
-- TOPBAR MUSIC BUTTON
-- ════════════════════════════════════════════════════════════════
local musicIcon = nil
task.wait(2)

local Icon = nil
if _G.HDAdminMain then
	local main = _G.HDAdminMain
	if main.client and main.client.Assets then
		local iconModule = main.client.Assets:FindFirstChild("Icon")
		if iconModule then
			Icon = require(iconModule)
		end
	end
end

if Icon then
	if _G.MusicDashboardIcon then
		pcall(function() _G.MusicDashboardIcon:destroy() end)
		_G.MusicDashboardIcon = nil
	end

	musicIcon = Icon.new()
		:setLabel("MUSIC")
		:setOrder(1)
		:bindEvent("selected", function() openUI(false) end)
		:bindEvent("deselected", function() closeUI() end)
		:setEnabled(true)

	_G.MusicDashboardIcon = musicIcon
end

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
	onOpen = function()
		if musicIcon then
			musicIcon:setLabel("CLOSE")
			musicIcon:select()
		end
	end,
	onClose = function()
		if musicIcon then
			musicIcon:setLabel("MUSIC")
			musicIcon:deselect()
		end
	end
})

local panel = modal:getPanel()
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- HEADER (mismo que antes)
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 126)
header.BackgroundColor3 = THEME.head
header.BorderSizePixel = 0
header.ZIndex = 102
header.Parent = panel
UI.rounded(header, 18)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 28)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
}
gradient.Rotation = 90
gradient.Parent = header

local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1, -80, 0, 40)
titleFrame.Position = UDim2.new(0, 20, 0, 12)
titleFrame.BackgroundTransparency = 1
titleFrame.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "XT"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -50, 0, 12)
closeBtn.BackgroundColor3 = THEME.card
closeBtn.Text = "X"
closeBtn.TextColor3 = THEME.muted
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header
UI.rounded(closeBtn, 8)
UI.stroked(closeBtn, 0.4)

-- ════════════════════════════════════════════════════════════════
-- NOW PLAYING BAR
-- ════════════════════════════════════════════════════════════════
local nowPlayingBar = Instance.new("Frame")
nowPlayingBar.Size = UDim2.new(1, -40, 0, 50)
nowPlayingBar.Position = UDim2.new(0, 20, 0, 56)
nowPlayingBar.BackgroundColor3 = THEME.card
nowPlayingBar.BorderSizePixel = 0
nowPlayingBar.Parent = header
UI.rounded(nowPlayingBar, 8)
UI.stroked(nowPlayingBar, 0.3)

local npPadding = Instance.new("UIPadding")
npPadding.PaddingLeft = UDim.new(0, 14)
npPadding.PaddingRight = UDim.new(0, 14)
npPadding.PaddingTop = UDim.new(0, 8)
npPadding.PaddingBottom = UDim.new(0, 8)
npPadding.Parent = nowPlayingBar

local songInfo = Instance.new("Frame")
songInfo.Size = UDim2.new(0.5, 0, 0, 18)
songInfo.BackgroundTransparency = 1
songInfo.Parent = nowPlayingBar

local songTitle = Instance.new("TextLabel")
songTitle.BackgroundTransparency = 1
songTitle.Size = UDim2.new(1, 0, 1, 0)
songTitle.Text = "No song playing"
songTitle.TextColor3 = THEME.text
songTitle.Font = Enum.Font.GothamMedium
songTitle.TextSize = 14
songTitle.TextXAlignment = Enum.TextXAlignment.Left
songTitle.TextTruncate = Enum.TextTruncate.AtEnd
songTitle.Parent = songInfo

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(1, 0, 0, 10)
progressBar.Position = UDim2.new(0, 0, 0, 26)
progressBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
progressBar.BorderSizePixel = 0
progressBar.Parent = nowPlayingBar
UI.rounded(progressBar, 2)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBar
UI.rounded(progressFill, 5)

local timeLabels = Instance.new("Frame")
timeLabels.Size = UDim2.new(1, 0, 0, 16)
timeLabels.Position = UDim2.new(0, 0, 0, 44)
timeLabels.BackgroundTransparency = 1
timeLabels.Parent = nowPlayingBar

local currentTimeLabel = Instance.new("TextLabel")
currentTimeLabel.BackgroundTransparency = 1
currentTimeLabel.Size = UDim2.new(0, 40, 1, 0)
currentTimeLabel.Text = "0:00"
currentTimeLabel.TextColor3 = THEME.muted
currentTimeLabel.Font = Enum.Font.GothamMedium
currentTimeLabel.TextSize = 16
currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
currentTimeLabel.Parent = timeLabels

local totalTimeLabel = Instance.new("TextLabel")
totalTimeLabel.BackgroundTransparency = 1
totalTimeLabel.Size = UDim2.new(0, 40, 1, 0)
totalTimeLabel.Position = UDim2.new(1, -40, 0, 0)
totalTimeLabel.Text = "0:00"
totalTimeLabel.TextColor3 = THEME.muted
totalTimeLabel.Font = Enum.Font.GothamMedium
totalTimeLabel.TextSize = 16
totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
totalTimeLabel.Parent = timeLabels

-- ════════════════════════════════════════════════════════════════
-- ADMIN CONTROLS
-- ════════════════════════════════════════════════════════════════
if isAdmin then
	local ctrl = Instance.new("Frame")
	ctrl.Size = UDim2.new(0, 120, 0, 28)
	ctrl.Position = UDim2.new(1, -200, 0, 14)
	ctrl.BackgroundTransparency = 1
	ctrl.Parent = header

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = ctrl

	local function mini(text, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 56, 0, 26)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.Parent = ctrl
		UI.rounded(b, 6)
		UI.stroked(b, 0.2)
		return b
	end

	local skipB = mini("SKIP", THEME.accent)
	local clearB = mini("CLEAR", Color3.fromRGB(161, 124, 72))

	if R.Next then skipB.MouseButton1Click:Connect(function() R.Next:FireServer() end) end
	if R.Clear then clearB.MouseButton1Click:Connect(function() R.Clear:FireServer() end) end
end

-- ════════════════════════════════════════════════════════════════
-- PERSONAL VOLUME CONTROL (igual que antes, resumido)
-- ════════════════════════════════════════════════════════════════
local volFrame = Instance.new("Frame")
volFrame.Size = UDim2.new(0, 140, 0, 28)
volFrame.Position = UDim2.new(1, isAdmin and -338 or -220, 0, 14)
volFrame.BackgroundTransparency = 1
volFrame.ZIndex = 102
volFrame.Parent = header

local volSliderBg = Instance.new("Frame")
volSliderBg.Size = UDim2.new(0, 85, 0, 26)
volSliderBg.Position = UDim2.new(0, 0, 0, 0)
volSliderBg.BackgroundColor3 = THEME.head
volSliderBg.BorderSizePixel = 0
volSliderBg.ZIndex = 102
volSliderBg.Parent = volFrame
UI.rounded(volSliderBg, 8)
UI.stroked(volSliderBg, 0.6)

local volSliderFill = Instance.new("Frame")
volSliderFill.Size = UDim2.new(0.8, 0, 1, 0)
volSliderFill.BackgroundColor3 = THEME.accent
volSliderFill.BorderSizePixel = 0
volSliderFill.ZIndex = 103
volSliderFill.Parent = volSliderBg
UI.rounded(volSliderFill, 8)

local volLabel = Instance.new("TextButton")
volLabel.Size = UDim2.new(0, 42, 0, 26)
volLabel.Position = UDim2.new(0, 90, 0, 0)
volLabel.BackgroundColor3 = THEME.card
volLabel.Text = "80%"
volLabel.TextColor3 = THEME.text
volLabel.Font = Enum.Font.GothamBold
volLabel.TextSize = 16
volLabel.BorderSizePixel = 0
volLabel.ZIndex = 103
volLabel.AutoButtonColor = false
volLabel.Parent = volFrame
UI.rounded(volLabel, 8)
UI.stroked(volLabel, 0.3)

local volInput = Instance.new("TextBox")
volInput.Size = volLabel.Size
volInput.Position = volLabel.Position
volInput.BackgroundColor3 = THEME.elevated or THEME.card
volInput.Text = "80"
volInput.TextColor3 = THEME.text
volInput.Font = Enum.Font.GothamBold
volInput.TextSize = 16
volInput.BorderSizePixel = 0
volInput.ZIndex = 104
volInput.Visible = false
volInput.ClearTextOnFocus = false
volInput.TextXAlignment = Enum.TextXAlignment.Center
volInput.Parent = volFrame
UI.rounded(volInput, 8)
UI.stroked(volInput, 0.4)

local savedVolume = player:GetAttribute("MusicVolume") or 0.8
local currentVolume = savedVolume
local dragging = false

local function updateVolume(volume)
	currentVolume = math.clamp(volume, 0, 1)
	volSliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	volLabel.Text = math.floor(currentVolume * 100) .. "%"
	volInput.Text = tostring(math.floor(currentVolume * 100))
	local sound = game:GetService("SoundService"):FindFirstChild("QueueSound")
	if sound and sound:IsA("Sound") then sound.Volume = currentVolume end
	player:SetAttribute("MusicVolume", currentVolume)
end

updateVolume(currentVolume)

volSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
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

-- Click en el label para editar manualmente
volLabel.MouseButton1Click:Connect(function()
	volLabel.Visible = false
	volInput.Visible = true
	volInput:CaptureFocus()
	volInput.Text = tostring(math.floor(currentVolume * 100))
end)

-- Validar input mientras escribe
volInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = volInput.Text:gsub("[^%d]", "")
	if #text > 3 then
		text = string.sub(text, 1, 3)
	end
	local value = tonumber(text)
	if value and value > 100 then
		text = "100"
	end
	volInput.Text = text
end)

-- Aplicar valor al perder foco
local function applyInputValue()
	local value = tonumber(volInput.Text)
	if not value or value < 1 then
		value = 1
	end
	value = math.clamp(value, 1, 100)
	updateVolume(value / 100)
	volInput.Visible = false
	volLabel.Visible = true
end

volInput.FocusLost:Connect(applyInputValue)

-- Hover effects en volLabel
volLabel.MouseEnter:Connect(function()
	TweenService:Create(volLabel, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.hover or Color3.fromRGB(60, 60, 70)
	}):Play()
end)

volLabel.MouseLeave:Connect(function()
	TweenService:Create(volLabel, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card
	}):Play()
end)

-- Enter key para aplicar valor
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Return and volInput.Visible then
		applyInputValue()
	end
end)

RunService.Heartbeat:Connect(function()
	local sound = game:GetService("SoundService"):FindFirstChild("QueueSound")
	if sound and sound:IsA("Sound") and sound.Volume ~= currentVolume then
		sound.Volume = currentVolume
	end
end)

-- ════════════════════════════════════════════════════════════════
-- NAVIGATION BAR
-- ════════════════════════════════════════════════════════════════
local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(1, 0, 0, 36)
navBar.Position = UDim2.new(0, 0, 0, header.Size.Y.Offset)
navBar.BackgroundColor3 = THEME.panel
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

local tQueue = createTab("COLA")
local tLibrary = createTab("BIBLIOTECA")

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, header.Size.Y.Offset + 33)
underline.BackgroundColor3 = THEME.accent
underline.BorderSizePixel = 0
underline.ZIndex = 102
underline.Parent = panel
UI.rounded(underline, 2)

-- ════════════════════════════════════════════════════════════════
-- CONTENT HOLDER
-- ════════════════════════════════════════════════════════════════
local holder = Instance.new("Frame")
holder.Name = "PageHolder"
holder.Size = UDim2.new(1, 0, 1, -(header.Size.Y.Offset + navBar.Size.Y.Offset))
holder.Position = UDim2.new(0, 0, 0, header.Size.Y.Offset + navBar.Size.Y.Offset)
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
pageLayout.Parent = holder
pageLayout.ScrollWheelInputEnabled = false
pageLayout.TouchInputEnabled = false

-- ════════════════════════════════════════════════════════════════
-- QUEUE PAGE (igual que antes)
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
quickInput.TextSize = 16
quickInput.TextXAlignment = Enum.TextXAlignment.Left
quickInput.ClearTextOnFocus = false
quickInput.Parent = quickAddFrame

quickInput:GetPropertyChangedSignal("Text"):Connect(function()
	if #quickInput.Text > 19 then
		quickInput.Text = string.sub(quickInput.Text, 1, 19)
	end
end)

quickAddBtn = Instance.new("TextButton")
quickAddBtn.Size = UDim2.new(0, 60, 0, 26)
quickAddBtn.Position = UDim2.new(1, -65, 0.5, -13)
quickAddBtn.BackgroundColor3 = THEME.accent
quickAddBtn.Text = "ADD"
quickAddBtn.TextColor3 = Color3.new(1, 1, 1)
quickAddBtn.Font = Enum.Font.GothamBold
quickAddBtn.TextSize = 16
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

if R.AddResponse then
	R.AddResponse.OnClientEvent:Connect(function(response)
		if not response then return end
		showNotification(response)

		-- Actualizar Quick Add button
		if response.success then
			setAddButtonState("success")
		elseif response.code == ResponseCodes.ERROR_DUPLICATE then
			setAddButtonState("duplicate", response.message)
		else
			setAddButtonState("error", response.message)
		end

		-- Actualizar botones de las cards en Library (se hace después cuando cardPool existe)
		task.defer(function()
			if currentPage == "Library" and cardPool and #cardPool > 0 then
				for _, card in ipairs(cardPool) do
					if card and card.Visible then
						local addBtn = card:FindFirstChild("AddButton")

						if addBtn and addBtn.Text == "..." then
							if response.success then
								addBtn.Text = "EN COLA"
								addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
								addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
								addBtn.AutoButtonColor = false
							elseif response.code == ResponseCodes.ERROR_DUPLICATE then
								addBtn.Text = "EN COLA"
								addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
								addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
								addBtn.AutoButtonColor = false
							else
								addBtn.Text = "AÑADIR"
								addBtn.BackgroundColor3 = THEME.success
								addBtn.TextColor3 = Color3.new(1, 1, 1)
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
		empty.Text = "La cola está vacía\nAgrega canciones desde la biblioteca"
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

		local nameText = Instance.new("TextLabel")
		nameText.Size = UDim2.new(1, -140, 0, 18)
		nameText.Position = UDim2.new(0, contentLeft, 0, 8)
		nameText.BackgroundTransparency = 1
		nameText.Text = (song.name or "Unknown") .. "  |  " .. (song.requestedBy or "Unknown")
		nameText.TextColor3 = isActive and Color3.new(1, 1, 1) or THEME.text
		nameText.Font = Enum.Font.GothamMedium
		nameText.TextSize = 16
		nameText.TextXAlignment = Enum.TextXAlignment.Left
		nameText.TextTruncate = Enum.TextTruncate.AtEnd
		nameText.ZIndex = 2
		nameText.Parent = card

		local artist = Instance.new("TextLabel")
		artist.Size = UDim2.new(1, -140, 0, 14)
		artist.Position = UDim2.new(0, contentLeft, 0, 28)
		artist.BackgroundTransparency = 1
		artist.Text = song.artist or "Unknown Artist"
		artist.TextColor3 = isActive and Color3.fromRGB(220, 220, 230) or THEME.muted
		artist.Font = Enum.Font.Gotham
		artist.TextSize = 14
		artist.TextXAlignment = Enum.TextXAlignment.Left
		artist.TextTruncate = Enum.TextTruncate.AtEnd
		artist.ZIndex = 2
		artist.Parent = card

		if isAdmin then
			local removeBtn = Instance.new("TextButton")
			removeBtn.Size = UDim2.new(0, 70, 0, 30)
			removeBtn.Position = UDim2.new(1, -75, 0.5, -15)
			removeBtn.BackgroundColor3 = THEME.danger
			removeBtn.Text = "REMOVE"
			removeBtn.TextColor3 = Color3.new(1, 1, 1)
			removeBtn.Font = Enum.Font.GothamBold
			removeBtn.TextSize = 16
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
-- LIBRARY PAGE (OPTIMIZADA CON VIRTUALIZACIÓN)
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

-- Header con búsqueda
local songsHeader = Instance.new("Frame")
songsHeader.Size = UDim2.new(1, -24, 0, 44)
songsHeader.Position = UDim2.new(0, 12, 0, 8)
songsHeader.BackgroundTransparency = 1
songsHeader.Parent = songsView

-- Back button
local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0, 80, 0, 36)
backBtn.Position = UDim2.new(0, 0, 0, 4)
backBtn.BackgroundColor3 = THEME.accent
backBtn.Text = "BACK"
backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 14
backBtn.BorderSizePixel = 0
backBtn.ZIndex = 102
backBtn.Parent = songsHeader
UI.rounded(backBtn, 8)
UI.stroked(backBtn, 0.2)

local searchContainer
searchContainer, searchInput = SearchModern.new(songsHeader, {
	placeholder = "Buscar por ID o nombre...",
	size = UDim2.new(1, -200, 0, 36),
	bg = THEME.card,
	corner = 8,
	z = 102,
	inputName = "SearchInput"
})
searchContainer.Position = UDim2.new(0, 92, 0, 4)


-- Song count label
songCountLabel = Instance.new("TextLabel")
songCountLabel.Size = UDim2.new(0, 100, 0, 36)
songCountLabel.Position = UDim2.new(1, -100, 0, 4)
songCountLabel.BackgroundTransparency = 1
songCountLabel.Text = "0 songs"
songCountLabel.TextColor3 = THEME.muted
songCountLabel.Font = Enum.Font.Gotham
songCountLabel.TextSize = 12
songCountLabel.TextXAlignment = Enum.TextXAlignment.Right
songCountLabel.Parent = songsHeader

-- Songs scroll (VIRTUALIZADA)
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

-- Container para cards virtuales
songsContainer = Instance.new("Frame")
songsContainer.Name = "SongsContainer"
songsContainer.Size = UDim2.new(1, 0, 0, 0)
songsContainer.BackgroundTransparency = 1
songsContainer.Parent = songsScroll

-- Loading indicator
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
-- POOL DE CARDS (REUTILIZABLES)
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

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -160, 0, 18)
	nameLabel.Position = UDim2.new(0, 0, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = THEME.text
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	local artistLabel = Instance.new("TextLabel")
	artistLabel.Name = "ArtistLabel"
	artistLabel.Size = UDim2.new(1, -160, 0, 14)
	artistLabel.Position = UDim2.new(0, 0, 0, 28)
	artistLabel.BackgroundTransparency = 1
	artistLabel.TextColor3 = THEME.muted
	artistLabel.Font = Enum.Font.Gotham
	artistLabel.TextSize = 14
	artistLabel.TextXAlignment = Enum.TextXAlignment.Left
	artistLabel.TextTruncate = Enum.TextTruncate.AtEnd
	artistLabel.Parent = card

	local addBtn = Instance.new("TextButton")
	addBtn.Name = "AddButton"
	addBtn.Size = UDim2.new(0, 70, 0, 30)
	addBtn.Position = UDim2.new(1, -70, 0.5, -15)
	addBtn.BackgroundColor3 = THEME.success
	addBtn.Text = "AÑADIR"
	addBtn.TextColor3 = Color3.new(1, 1, 1)
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 16
	addBtn.BorderSizePixel = 0
	addBtn.Parent = card
	UI.rounded(addBtn, 6)

	return card
end

local function getCardFromPool()
	for i, card in ipairs(cardPool) do
		if not card.Visible then
			return card
		end
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
	for _, card in ipairs(cardPool) do
		releaseCard(card)
	end
end

-- ════════════════════════════════════════════════════════════════
-- VIRTUAL SCROLL LOGIC
-- ════════════════════════════════════════════════════════════════
local function getSongDataForDisplay()
	if virtualScrollState.isSearching then
		return virtualScrollState.searchResults
	end
	return virtualScrollState.songData
end

local function getTotalSongsForDisplay()
	if virtualScrollState.isSearching then
		return #virtualScrollState.searchResults
	end
	return virtualScrollState.totalSongs
end

local function updateSongCard(card, songData, index, isInQueue)
	if not card or not songData then return end

	card:SetAttribute("SongIndex", index)
	card:SetAttribute("SongID", songData.id)

	local nameLabel = card:FindFirstChild("NameLabel")
	local artistLabel = card:FindFirstChild("ArtistLabel")
	local addBtn = card:FindFirstChild("AddButton")

	if nameLabel then
		nameLabel.Text = songData.name or "Cargando..."
		nameLabel.TextColor3 = songData.loaded and THEME.text or THEME.muted
	end

	if artistLabel then
		artistLabel.Text = songData.artist or ("ID: " .. songData.id)
	end

	if addBtn then
		-- Limpiar conexiones anteriores
		for _, conn in pairs(addBtn:GetAttribute("Connections") or {}) do
			-- No podemos guardar conexiones en atributos, así que usamos otro método
		end

		if isInQueue then
			addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
			addBtn.Text = "EN COLA"
			addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
			addBtn.AutoButtonColor = false
		else
			addBtn.BackgroundColor3 = THEME.success
			addBtn.Text = "AÑADIR"
			addBtn.TextColor3 = Color3.new(1, 1, 1)
			addBtn.AutoButtonColor = true
		end
	end

	local yPos = (index - 1) * (CARD_HEIGHT + CARD_PADDING)
	card.Position = UDim2.new(0, 4, 0, yPos)
	card.Visible = true
end

local function isInQueue(songId)
	for _, song in ipairs(playQueue) do
		if song.id == songId then return true end
	end
	return false
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

	-- Calcular rango visible
	local firstVisible = math.max(1, math.floor(scrollPos / (CARD_HEIGHT + CARD_PADDING)) + 1 - VISIBLE_BUFFER)
	local lastVisible = math.min(totalItems, math.ceil((scrollPos + viewportHeight) / (CARD_HEIGHT + CARD_PADDING)) + VISIBLE_BUFFER)

	-- Actualizar canvas size
	local totalHeight = totalItems * (CARD_HEIGHT + CARD_PADDING)
	songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
	songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)

	-- Liberar cards fuera del rango
	for _, card in ipairs(cardPool) do
		if card.Visible then
			local cardIndex = card:GetAttribute("SongIndex")
			if cardIndex and (cardIndex < firstVisible or cardIndex > lastVisible) then
				releaseCard(card)
			end
		end
	end

	-- Mostrar cards en el rango
	local dataSource = getSongDataForDisplay()
	local needsServerFetch = {}

	for i = firstVisible, lastVisible do
		local songData = nil

		if virtualScrollState.isSearching then
			songData = dataSource[i]
		else
			songData = dataSource[i]
		end

		-- Verificar si ya hay una card para este índice
		local existingCard = nil
		for _, card in ipairs(cardPool) do
			if card.Visible and card:GetAttribute("SongIndex") == i then
				existingCard = card
				break
			end
		end

		if songData then
			local card = existingCard or getCardFromPool()
			if card then
				updateSongCard(card, songData, i, isInQueue(songData.id))
			end
		elseif not virtualScrollState.isSearching then
			-- No tenemos data, pedir al servidor
			table.insert(needsServerFetch, i)
		end
	end

	-- Pedir datos faltantes al servidor
	if #needsServerFetch > 0 and not virtualScrollState.isSearching then
		local minIndex = math.huge
		local maxIndex = 0

		for _, idx in ipairs(needsServerFetch) do
			minIndex = math.min(minIndex, idx)
			maxIndex = math.max(maxIndex, idx)
		end

		-- Verificar si ya pedimos este rango
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

-- Conectar el scroll
local scrollConnection = nil

local function connectScrollListener()
	if scrollConnection then scrollConnection:Disconnect() end

	scrollConnection = songsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		updateVisibleCards()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- BÚSQUEDA
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
	local text = searchInput.Text

	-- Debounce
	if searchDebounce then
		task.cancel(searchDebounce)
	end

	searchDebounce = task.delay(0.3, function()
		performSearch(text)
	end)
end)

-- ════════════════════════════════════════════════════════════════
-- CONEXIONES DE BOTONES EN CARDS
-- ════════════════════════════════════════════════════════════════
-- Usar un único listener en el container
songsContainer.ChildAdded:Connect(function(child)
	if child:IsA("Frame") then
		local addBtn = child:FindFirstChild("AddButton")
		if addBtn then
			addBtn.MouseButton1Click:Connect(function()
				local songId = child:GetAttribute("SongID")
				if songId and not isInQueue(songId) then
					addBtn.BackgroundColor3 = THEME.info
					addBtn.Text = "..."
					if R.Add then
						R.Add:FireServer(songId)
					end
				end
			end)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- DJs DRAWING
-- ════════════════════════════════════════════════════════════════
local function drawDJs()
	for _, child in pairs(djsScroll:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
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

			-- Resetear estado virtual
			virtualScrollState.totalSongs = dj.songCount
			virtualScrollState.songData = {}
			virtualScrollState.searchResults = {}
			virtualScrollState.isSearching = false
			virtualScrollState.searchQuery = ""
			virtualScrollState.pendingRequests = {}

			-- Transición
			TweenService:Create(djsScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Position = UDim2.new(0, 12, 0, -50)
			}):Play()

			task.wait(0.15)
			djsScroll.Visible = false
			djsScroll.Position = UDim2.new(0, 12, 0, 8)

			songsView.Visible = true
			searchInput.Text = ""
			songCountLabel.Text = dj.songCount .. " songs"

			-- Limpiar cards y pedir datos iniciales
			releaseAllCards()
			songsScroll.CanvasPosition = Vector2.new(0, 0)

			-- Configurar canvas inicial
			local totalHeight = dj.songCount * (CARD_HEIGHT + CARD_PADDING)
			songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
			songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)

			connectScrollListener()

			-- Pedir primer batch
			if R.GetSongRange then
				R.GetSongRange:FireServer(dj.name, 1, BATCH_SIZE)
			end

			-- Animar entrada
			songsView.Position = UDim2.new(0, 0, 0, 50)
			TweenService:Create(songsView, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
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

-- Back button
backBtn.MouseButton1Click:Connect(function()
	selectedDJ = nil

	-- Limpiar estado
	virtualScrollState.songData = {}
	virtualScrollState.searchResults = {}
	virtualScrollState.isSearching = false
	virtualScrollState.pendingRequests = {}
	releaseAllCards()

	if scrollConnection then
		scrollConnection:Disconnect()
		scrollConnection = nil
	end

	TweenService:Create(songsView, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, 0, 0, 50)
	}):Play()

	task.wait(0.15)
	songsView.Visible = false
	songsView.Position = UDim2.new(0, 0, 0, 0)

	djsScroll.Visible = true
	djsScroll.Position = UDim2.new(0, 12, 0, -50)
	TweenService:Create(djsScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, 12, 0, 8)
	}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- RESET LIBRARY STATE
-- ════════════════════════════════════════════════════════════════
local function resetLibraryState()
	selectedDJ = nil
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
	if not currentSoundObject then
		currentSoundObject = game:GetService("SoundService"):FindFirstChild("QueueSound")
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
		local progress = math.clamp(current / total, 0, 1)
		progressFill.Size = UDim2.new(progress, 0, 1, 0)
		currentTimeLabel.Text = formatTime(current)
		totalTimeLabel.Text = formatTime(total)
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
		local y = header.Size.Y.Offset + 33
		TweenService:Create(underline, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, w, 0, 3),
			Position = UDim2.new(0, x, 0, y)
		}):Play()
	end)
end

function showPage(name)
	local previousPage = currentPage
	currentPage = name

	if previousPage == "Library" and name ~= "Library" then
		resetLibraryState()
	end

	if queuePage then queuePage.Visible = false end
	if libraryPage then libraryPage.Visible = false end

	local pageFrame = holder:FindFirstChild(name)
	if pageFrame then
		pageFrame.Visible = true
		pageLayout:JumpTo(pageFrame)
	end

	if name == "Queue" then drawQueue() end

	if name == "Library" then
		resetLibraryState()
		if #allDJs > 0 then
			drawDJs()
		end
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
	if modal:isModalOpen() then return end

	if openToLibrary then
		showPage("Library")
		moveUnderline(tLibrary)
	else
		showPage("Queue")
		moveUnderline(tQueue)
	end

	modal:open()

	if progressConnection then progressConnection:Disconnect() end
	progressConnection = RunService.Heartbeat:Connect(updateProgressBar)
end

function closeUI()
	if not modal:isModalOpen() then return end

	if progressConnection then
		progressConnection:Disconnect()
		progressConnection = nil
	end

	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(closeUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and modal:isModalOpen() then
		closeUI()
	end
end)

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.hover,
		TextColor3 = THEME.warn
	}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card,
		TextColor3 = THEME.muted
	}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- REMOTE UPDATES
-- ════════════════════════════════════════════════════════════════
if R.Update then
	R.Update.OnClientEvent:Connect(function(data)
		musicLibrary = data.library or musicLibrary
		playQueue = data.queue or {}
		currentSong = data.currentSong
		allDJs = data.djs or allDJs

		currentSoundObject = game:GetService("SoundService"):FindFirstChild("QueueSound")

		if currentSong then
			songTitle.Text = currentSong.name .. " - " .. (currentSong.artist or "Unknown")
		else
			songTitle.Text = "No song playing"
		end

		if currentPage == "Queue" then drawQueue() end

		if currentPage == "Library" then
			if not selectedDJ then
				drawDJs()
			else
				-- Actualizar estado de botones en cards visibles
				updateVisibleCards()
			end
		end
	end)
end

if R.GetDJs then
	R.GetDJs.OnClientEvent:Connect(function(d)
		allDJs = (d and (d.djs or d)) or allDJs
		if currentPage == "Library" and not selectedDJ then
			drawDJs()
		end
	end)
end

-- Recibir rango de canciones
if R.GetSongRange then
	R.GetSongRange.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end

		loadingIndicator.Visible = false

		-- Guardar canciones en cache local
		for _, song in ipairs(data.songs or {}) do
			virtualScrollState.songData[song.index] = song
		end

		-- Limpiar request pendiente
		local rangeKey = data.startIndex .. "-" .. data.endIndex
		virtualScrollState.pendingRequests[rangeKey] = nil

		-- Actualizar cards visibles
		updateVisibleCards()
	end)
end

-- Recibir resultados de búsqueda
if R.SearchSongs then
	R.SearchSongs.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end

		loadingIndicator.Visible = false

		virtualScrollState.searchResults = data.songs or {}
		songCountLabel.Text = #virtualScrollState.searchResults .. " / " .. (data.totalInDJ or virtualScrollState.totalSongs) .. " songs"

		if data.cachedCount and data.cachedCount < (data.totalInDJ or 0) then
			songCountLabel.Text = songCountLabel.Text .. " " .. math.floor(data.cachedCount / (data.totalInDJ or 1) * 100) .. "%"
		end

		songsScroll.CanvasPosition = Vector2.new(0, 0)
		updateVisibleCards()
	end)
end

-- Recibir info inicial del DJ
if R.GetSongsByDJ then
	R.GetSongsByDJ.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end

		virtualScrollState.totalSongs = data.total or 0
		songCountLabel.Text = data.total .. " songs"

		-- Actualizar canvas size
		local totalHeight = data.total * (CARD_HEIGHT + CARD_PADDING)
		songsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
		songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
if R.GetDJs then R.GetDJs:FireServer() end

-- Pre-crear pool de cards
for i = 1, MAX_POOL_SIZE do
	local card = createSongCard()
	card.Parent = songsContainer
	table.insert(cardPool, card)
end