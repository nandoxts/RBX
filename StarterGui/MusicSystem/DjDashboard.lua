--[[ Music Dashboard - Professional Edition v6 (ULTRA OPTIMIZADO)
	by ignxts
	
	OPTIMIZACIONES:
	- Carga por lotes (30 canciones a la vez)
	- Scroll infinito (carga más al llegar al fondo)
	- Metadata se carga en background
	- UI 100% fluida
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

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
	[ResponseCodes.ERROR_BLACKLISTED] = {type = "error", title = "Bloqueado"},
	[ResponseCodes.ERROR_DUPLICATE] = {type = "warning", title = "Duplicado"},
	[ResponseCodes.ERROR_NOT_FOUND] = {type = "error", title = "No Encontrado"},
	[ResponseCodes.ERROR_NOT_AUDIO] = {type = "error", title = "No es Audio"},
	[ResponseCodes.ERROR_NOT_AUTHORIZED] = {type = "error", title = "No Autorizado"},
	[ResponseCodes.ERROR_QUEUE_FULL] = {type = "warning", title = "Cola Llena"},
	[ResponseCodes.ERROR_PERMISSION] = {type = "error", title = "Sin Permiso"},
	[ResponseCodes.ERROR_UNKNOWN] = {type = "error", title = "Error"}
}

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local ADMIN_IDS = {8387751399, 9375636407}

local function isAdminUser(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then return true end
	end
	return false
end

local isAdmin = isAdminUser(player.UserId)

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local playQueue = {}
local currentSong = nil
local allDJs = {}
local selectedDJ = nil
local currentPage = "Queue"
local currentSoundObject = nil
local progressConnection = nil

-- Paginación de canciones
local currentSongsPage = 1
local loadedSongs = {}
local isLoadingMore = false
local hasMoreSongs = true
local totalSongs = 0

-- UI refs
local quickAddBtn, quickInput, qiStroke = nil, nil, nil
local isAddingToQueue = false
local songsScroll = nil
local djsScroll = nil

-- Metadata cache local
local localMetadataCache = {}

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function isValidAudioId(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	return #text >= 6 and #text <= 19
end

local function getRemote(name)
	local MusicRemotes = ReplicatedStorage:WaitForChild("MusicRemotes", 10)
	if not MusicRemotes then return nil end

	local remoteMap = {
		NextSong = "MusicPlayback", PlaySong = "MusicPlayback",
		PauseSong = "MusicPlayback", StopSong = "MusicPlayback",
		AddToQueue = "MusicQueue", AddToQueueResponse = "MusicQueue",
		RemoveFromQueue = "MusicQueue", RemoveFromQueueResponse = "MusicQueue",
		ClearQueue = "MusicQueue", ClearQueueResponse = "MusicQueue",
		UpdateUI = "UI", GetDJs = "MusicLibrary",
		GetSongsByDJ = "MusicLibrary", GetSongMetadata = "MusicLibrary",
	}

	local subfolder = remoteMap[name] or "MusicLibrary"
	local folder = MusicRemotes:FindFirstChild(subfolder)
	if not folder then return nil end
	return folder:FindFirstChild(name)
end

local function formatTime(seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function showNotification(response)
	local config = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local message = response.message or "OK"
	if response.data and response.data.songName then
		message = message .. ": " .. response.data.songName
	end
	if config.type == "success" then Notify:Success(config.title, message, 3)
	elseif config.type == "warning" then Notify:Warning(config.title, message, 3)
	elseif config.type == "error" then Notify:Error(config.title, message, 4)
	else Notify:Info(config.title, message, 3) end
end

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
		quickAddBtn.Text = "✓"
		quickAddBtn.BackgroundColor3 = THEME.success
		task.delay(2, function() if quickAddBtn then setAddButtonState("default") end end)
	elseif state == "error" then
		isAddingToQueue = false
		quickInput.Text = ""
		qiStroke.Color = THEME.danger
		quickAddBtn.Text = "!"
		quickAddBtn.BackgroundColor3 = THEME.danger
		task.delay(2, function() if quickAddBtn then setAddButtonState("default") end end)
	elseif state == "duplicate" then
		isAddingToQueue = false
		quickInput.Text = ""
		qiStroke.Color = Color3.fromRGB(255, 150, 0)
		quickAddBtn.Text = "DUP"
		quickAddBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		task.delay(2, function() if quickAddBtn then setAddButtonState("default") end end)
	else
		isAddingToQueue = false
		qiStroke.Color = THEME.stroke
		quickInput.PlaceholderText = "Enter Audio ID..."
		quickAddBtn.Text = "ADD"
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
	GetSongMetadata = getRemote("GetSongMetadata"),
}

-- ════════════════════════════════════════════════════════════════
-- GUI SETUP
-- ════════════════════════════════════════════════════════════════
local screenGui = script.Parent
screenGui.IgnoreGuiInset = true

-- Topbar Icon
local musicIcon = nil
task.wait(2)

local Icon = nil
if _G.HDAdminMain then
	local main = _G.HDAdminMain
	if main.client and main.client.Assets then
		local iconModule = main.client.Assets:FindFirstChild("Icon")
		if iconModule then Icon = require(iconModule) end
	end
end

if Icon then
	if _G.MusicDashboardIcon then
		pcall(function() _G.MusicDashboardIcon:destroy() end)
	end
	musicIcon = Icon.new()
		:setLabel("MUSIC"):setOrder(1)
		:bindEvent("selected", function() openUI(false) end)
		:bindEvent("deselected", function() closeUI() end)
		:setEnabled(true)
	_G.MusicDashboardIcon = musicIcon
end

-- Modal
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "MusicDashboard",
	panelWidth = PANEL_W_PX,
	panelHeight = PANEL_H_PX,
	cornerRadius = 12,
	enableBlur = true,
	blurSize = 14,
	onOpen = function() if musicIcon then musicIcon:setLabel("CLOSE"):select() end end,
	onClose = function() if musicIcon then musicIcon:setLabel("MUSIC"):deselect() end end
})

local panel = modal:getPanel()
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- HEADER
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 100, 0, 20)
title.Position = UDim2.new(0, 20, 0, 12)
title.BackgroundTransparency = 1
title.Text = "XT"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

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

-- Now Playing Bar
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
npPadding.Parent = nowPlayingBar

local songTitle = Instance.new("TextLabel")
songTitle.Size = UDim2.new(0.6, 0, 0, 18)
songTitle.BackgroundTransparency = 1
songTitle.Text = "No song playing"
songTitle.TextColor3 = THEME.text
songTitle.Font = Enum.Font.GothamMedium
songTitle.TextSize = 14
songTitle.TextXAlignment = Enum.TextXAlignment.Left
songTitle.TextTruncate = Enum.TextTruncate.AtEnd
songTitle.Parent = nowPlayingBar

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(1, 0, 0, 6)
progressBar.Position = UDim2.new(0, 0, 0, 24)
progressBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
progressBar.BorderSizePixel = 0
progressBar.Parent = nowPlayingBar
UI.rounded(progressBar, 3)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBar
UI.rounded(progressFill, 3)

local currentTimeLabel = Instance.new("TextLabel")
currentTimeLabel.Size = UDim2.new(0, 40, 0, 14)
currentTimeLabel.Position = UDim2.new(0, 0, 0, 32)
currentTimeLabel.BackgroundTransparency = 1
currentTimeLabel.Text = "0:00"
currentTimeLabel.TextColor3 = THEME.muted
currentTimeLabel.Font = Enum.Font.Gotham
currentTimeLabel.TextSize = 11
currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
currentTimeLabel.Parent = nowPlayingBar

local totalTimeLabel = Instance.new("TextLabel")
totalTimeLabel.Size = UDim2.new(0, 40, 0, 14)
totalTimeLabel.Position = UDim2.new(1, -40, 0, 32)
totalTimeLabel.BackgroundTransparency = 1
totalTimeLabel.Text = "0:00"
totalTimeLabel.TextColor3 = THEME.muted
totalTimeLabel.Font = Enum.Font.Gotham
totalTimeLabel.TextSize = 11
totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
totalTimeLabel.Parent = nowPlayingBar

-- Admin Controls
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
		b.TextSize = 12
		b.Parent = ctrl
		UI.rounded(b, 6)
		return b
	end

	local skipB = mini("SKIP", THEME.accent)
	local clearB = mini("CLEAR", Color3.fromRGB(161, 124, 72))

	if R.Next then skipB.MouseButton1Click:Connect(function() R.Next:FireServer() end) end
	if R.Clear then clearB.MouseButton1Click:Connect(function() R.Clear:FireServer() end) end
end

-- Volume Control
local volFrame = Instance.new("Frame")
volFrame.Size = UDim2.new(0, 130, 0, 26)
volFrame.Position = UDim2.new(1, isAdmin and -338 or -200, 0, 15)
volFrame.BackgroundTransparency = 1
volFrame.ZIndex = 102
volFrame.Parent = header

local volSliderBg = Instance.new("Frame")
volSliderBg.Size = UDim2.new(0, 80, 0, 24)
volSliderBg.BackgroundColor3 = THEME.head
volSliderBg.BorderSizePixel = 0
volSliderBg.ZIndex = 102
volSliderBg.Parent = volFrame
UI.rounded(volSliderBg, 6)
UI.stroked(volSliderBg, 0.6)

local volSliderFill = Instance.new("Frame")
volSliderFill.Size = UDim2.new(0.8, 0, 1, 0)
volSliderFill.BackgroundColor3 = THEME.accent
volSliderFill.BorderSizePixel = 0
volSliderFill.ZIndex = 103
volSliderFill.Parent = volSliderBg
UI.rounded(volSliderFill, 6)

local volLabel = Instance.new("TextLabel")
volLabel.Size = UDim2.new(0, 40, 0, 24)
volLabel.Position = UDim2.new(0, 85, 0, 0)
volLabel.BackgroundColor3 = THEME.card
volLabel.Text = "80%"
volLabel.TextColor3 = THEME.text
volLabel.Font = Enum.Font.GothamBold
volLabel.TextSize = 11
volLabel.BorderSizePixel = 0
volLabel.ZIndex = 103
volLabel.Parent = volFrame
UI.rounded(volLabel, 6)

local currentVolume = player:GetAttribute("MusicVolume") or 0.8
local dragging = false

local function updateVolume(volume)
	currentVolume = math.clamp(volume, 0, 1)
	volSliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	volLabel.Text = math.floor(currentVolume * 100) .. "%"
	local sound = game:GetService("SoundService"):FindFirstChild("QueueSound")
	if sound then sound.Volume = currentVolume end
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

RunService.Heartbeat:Connect(function()
	local sound = game:GetService("SoundService"):FindFirstChild("QueueSound")
	if sound and sound.Volume ~= currentVolume then sound.Volume = currentVolume end
end)

-- ════════════════════════════════════════════════════════════════
-- NAVIGATION
-- ════════════════════════════════════════════════════════════════
local navBar = Instance.new("Frame")
navBar.Size = UDim2.new(1, 0, 0, 36)
navBar.Position = UDim2.new(0, 0, 0, 126)
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
	btn.AutoButtonColor = false
	btn.Parent = navBar
	return btn
end

local tQueue = createTab("QUEUE")
local tLibrary = createTab("LIBRARY")

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, 159)
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
holder.Size = UDim2.new(1, 0, 1, -162)
holder.Position = UDim2.new(0, 0, 0, 162)
holder.BackgroundTransparency = 1
holder.ClipsDescendants = true
holder.Parent = panel

local pageLayout = Instance.new("UIPageLayout")
pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
pageLayout.EasingStyle = Enum.EasingStyle.Quad
pageLayout.TweenTime = 0.2
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
quickInput.Size = UDim2.new(1, -70, 1, 0)
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
quickAddBtn.Size = UDim2.new(0, 50, 0, 26)
quickAddBtn.Position = UDim2.new(1, -55, 0.5, -13)
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
		Notify:Warning("ID Inválido", "6-19 dígitos", 2)
		return
	end
	setAddButtonState("loading")
	if R.Add then R.Add:FireServer(tonumber(aid)) end
end)

local queueScroll = Instance.new("ScrollingFrame")
queueScroll.Size = UDim2.new(1, -24, 1, -52)
queueScroll.Position = UDim2.new(0, 12, 0, 50)
queueScroll.BackgroundTransparency = 1
queueScroll.ScrollBarThickness = 4
queueScroll.ScrollBarImageColor3 = THEME.stroke
queueScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
queueScroll.Parent = queuePage

local queueList = Instance.new("UIListLayout")
queueList.Padding = UDim.new(0, 4)
queueList.Parent = queueScroll

queueList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	queueScroll.CanvasSize = UDim2.new(0, 0, 0, queueList.AbsoluteContentSize.Y + 8)
end)

local function drawQueue()
	for _, child in pairs(queueScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	if #playQueue == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 50)
		empty.BackgroundTransparency = 1
		empty.Text = "Cola vacía"
		empty.TextColor3 = THEME.muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.Parent = queueScroll
		return
	end

	for i, song in ipairs(playQueue) do
		local isActive = currentSong and song.id == currentSong.id

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 48)
		card.BackgroundColor3 = isActive and THEME.accent or THEME.card
		card.BorderSizePixel = 0
		card.Parent = queueScroll
		UI.rounded(card, 6)

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = card

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -80, 0, 16)
		name.Position = UDim2.new(0, 0, 0, 8)
		name.BackgroundTransparency = 1
		name.Text = (song.name or "Unknown") .. " • " .. (song.requestedBy or "?")
		name.TextColor3 = isActive and Color3.new(1,1,1) or THEME.text
		name.Font = Enum.Font.GothamMedium
		name.TextSize = 13
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Parent = card

		local artist = Instance.new("TextLabel")
		artist.Size = UDim2.new(1, -80, 0, 14)
		artist.Position = UDim2.new(0, 0, 0, 26)
		artist.BackgroundTransparency = 1
		artist.Text = song.artist or "Unknown"
		artist.TextColor3 = isActive and Color3.fromRGB(220,220,230) or THEME.muted
		artist.Font = Enum.Font.Gotham
		artist.TextSize = 11
		artist.TextXAlignment = Enum.TextXAlignment.Left
		artist.Parent = card

		if isAdmin then
			local removeBtn = Instance.new("TextButton")
			removeBtn.Size = UDim2.new(0, 60, 0, 26)
			removeBtn.Position = UDim2.new(1, -60, 0.5, -13)
			removeBtn.BackgroundColor3 = THEME.danger
			removeBtn.Text = "DEL"
			removeBtn.TextColor3 = Color3.new(1,1,1)
			removeBtn.Font = Enum.Font.GothamBold
			removeBtn.TextSize = 11
			removeBtn.Parent = card
			UI.rounded(removeBtn, 4)
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
djsScroll = Instance.new("ScrollingFrame")
djsScroll.Size = UDim2.new(1, -24, 1, -8)
djsScroll.Position = UDim2.new(0, 12, 0, 4)
djsScroll.BackgroundTransparency = 1
djsScroll.ScrollBarThickness = 4
djsScroll.ScrollBarImageColor3 = THEME.stroke
djsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
djsScroll.Parent = libraryPage

local djsLayout = Instance.new("UIGridLayout")
djsLayout.CellSize = UDim2.new(0, 180, 0, 180)
djsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
djsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
djsLayout.Parent = djsScroll

djsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	djsScroll.CanvasSize = UDim2.new(0, 0, 0, djsLayout.AbsoluteContentSize.Y + 16)
end)

-- Songs scroll (con scroll infinito)
songsScroll = Instance.new("ScrollingFrame")
songsScroll.Size = UDim2.new(1, -24, 1, -56)
songsScroll.Position = UDim2.new(0, 12, 0, 52)
songsScroll.BackgroundTransparency = 1
songsScroll.ScrollBarThickness = 4
songsScroll.ScrollBarImageColor3 = THEME.stroke
songsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
songsScroll.Visible = false
songsScroll.Parent = libraryPage

local songsList = Instance.new("UIListLayout")
songsList.Padding = UDim.new(0, 4)
songsList.Parent = songsScroll

songsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	songsScroll.CanvasSize = UDim2.new(0, 0, 0, songsList.AbsoluteContentSize.Y + 60)
end)

-- Back button
local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0, 70, 0, 32)
backBtn.Position = UDim2.new(0, 12, 0, 8)
backBtn.BackgroundColor3 = THEME.accent
backBtn.Text = "← BACK"
backBtn.TextColor3 = Color3.new(1,1,1)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 12
backBtn.Visible = false
backBtn.ZIndex = 102
backBtn.Parent = libraryPage
UI.rounded(backBtn, 6)

-- Loading indicator
local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0, 30)
loadingLabel.BackgroundTransparency = 1
loadingLabel.Text = "Cargando más..."
loadingLabel.TextColor3 = THEME.muted
loadingLabel.Font = Enum.Font.Gotham
loadingLabel.TextSize = 12
loadingLabel.Visible = false
loadingLabel.Name = "LoadingLabel"

-- Song counter
local songCountLabel = Instance.new("TextLabel")
songCountLabel.Size = UDim2.new(0, 150, 0, 32)
songCountLabel.Position = UDim2.new(0, 90, 0, 8)
songCountLabel.BackgroundTransparency = 1
songCountLabel.Text = ""
songCountLabel.TextColor3 = THEME.muted
songCountLabel.Font = Enum.Font.Gotham
songCountLabel.TextSize = 12
songCountLabel.TextXAlignment = Enum.TextXAlignment.Left
songCountLabel.Visible = false
songCountLabel.ZIndex = 102
songCountLabel.Parent = libraryPage

local function resetLibraryState()
	selectedDJ = nil
	currentSongsPage = 1
	loadedSongs = {}
	hasMoreSongs = true
	isLoadingMore = false
	totalSongs = 0
	djsScroll.Visible = true
	djsScroll.CanvasPosition = Vector2.new(0, 0)
	songsScroll.Visible = false
	songsScroll.CanvasPosition = Vector2.new(0, 0)
	backBtn.Visible = false
	songCountLabel.Visible = false
end

backBtn.MouseButton1Click:Connect(function()
	resetLibraryState()
end)

-- ════════════════════════════════════════════════════════════════
-- DRAW DJS
-- ════════════════════════════════════════════════════════════════
local function drawDJs()
	for _, child in pairs(djsScroll:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end

	if #allDJs == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 50)
		empty.BackgroundTransparency = 1
		empty.Text = "Cargando DJs..."
		empty.TextColor3 = THEME.muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.Parent = djsScroll
		return
	end

	for _, dj in ipairs(allDJs) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		card.BorderSizePixel = 0
		card.Parent = djsScroll
		UI.rounded(card, 12)
		UI.stroked(card, 0.3)

		local cover = Instance.new("ImageLabel")
		cover.Size = UDim2.new(1, 0, 1, 0)
		cover.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		cover.Image = dj.cover ~= "" and dj.cover or ""
		cover.ScaleType = Enum.ScaleType.Crop
		cover.BorderSizePixel = 0
		cover.Parent = card
		UI.rounded(cover, 12)

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Parent = card
		UI.rounded(overlay, 12)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -16, 0, 24)
		nameLabel.Position = UDim2.new(0, 8, 1, -48)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = dj.name
		nameLabel.TextColor3 = Color3.new(1,1,1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextTransparency = 1
		nameLabel.Parent = overlay

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -16, 0, 16)
		countLabel.Position = UDim2.new(0, 8, 1, -24)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = dj.songCount .. " songs"
		countLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
		countLabel.Font = Enum.Font.Gotham
		countLabel.TextSize = 12
		countLabel.TextTransparency = 1
		countLabel.Parent = overlay

		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.Parent = card

		clickBtn.MouseButton1Click:Connect(function()
			selectedDJ = dj.name
			totalSongs = dj.songCount
			currentSongsPage = 1
			loadedSongs = {}
			hasMoreSongs = true

			djsScroll.Visible = false
			songsScroll.Visible = true
			backBtn.Visible = true
			songCountLabel.Visible = true
			songCountLabel.Text = "0 / " .. totalSongs .. " canciones"

			-- Limpiar scroll
			for _, child in pairs(songsScroll:GetChildren()) do
				if not child:IsA("UIListLayout") then child:Destroy() end
			end

			-- Pedir primera página
			if R.GetSongsByDJ then
				R.GetSongsByDJ:FireServer(dj.name, 1)
			end
		end)

		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
		end)

		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- CREAR CARD DE CANCIÓN (reutilizable)
-- ════════════════════════════════════════════════════════════════
local function createSongCard(song)
	local isInQueue = false
	for _, queueSong in ipairs(playQueue) do
		if queueSong.id == song.id then isInQueue = true break end
	end

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 44)
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.Name = "Song_" .. song.id
	UI.rounded(card, 6)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = card

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -80, 0, 16)
	name.Position = UDim2.new(0, 0, 0, 6)
	name.BackgroundTransparency = 1
	name.Text = song.name or ("Audio " .. song.id)
	name.TextColor3 = THEME.text
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 13
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Name = "SongName"
	name.Parent = card

	local artist = Instance.new("TextLabel")
	artist.Size = UDim2.new(1, -80, 0, 12)
	artist.Position = UDim2.new(0, 0, 0, 24)
	artist.BackgroundTransparency = 1
	artist.Text = song.artist or "..."
	artist.TextColor3 = THEME.muted
	artist.Font = Enum.Font.Gotham
	artist.TextSize = 11
	artist.TextXAlignment = Enum.TextXAlignment.Left
	artist.Name = "ArtistName"
	artist.Parent = card

	local addBtn = Instance.new("TextButton")
	addBtn.Size = UDim2.new(0, 60, 0, 24)
	addBtn.Position = UDim2.new(1, -60, 0.5, -12)
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 10
	addBtn.BorderSizePixel = 0
	addBtn.Name = "QueueBtn"
	addBtn.Parent = card
	UI.rounded(addBtn, 4)

	if isInQueue then
		addBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		addBtn.Text = "EN COLA"
		addBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
		addBtn.AutoButtonColor = false
	else
		addBtn.BackgroundColor3 = THEME.success
		addBtn.Text = "QUEUE"
		addBtn.TextColor3 = Color3.new(1, 1, 1)
		addBtn.AutoButtonColor = true

		local adding = false
		addBtn.MouseButton1Click:Connect(function()
			if adding then return end
			adding = true
			addBtn.Text = "..."
			addBtn.BackgroundColor3 = THEME.info
			if R.Add then R.Add:FireServer(song.id) end
		end)
	end

	return card
end

-- ════════════════════════════════════════════════════════════════
-- AÑADIR CANCIONES AL SCROLL (INCREMENTAL)
-- ════════════════════════════════════════════════════════════════
local function appendSongsToScroll(songs)
	for _, song in ipairs(songs) do
		-- Verificar si ya existe
		if not songsScroll:FindFirstChild("Song_" .. song.id) then
			local card = createSongCard(song)
			card.Parent = songsScroll
			table.insert(loadedSongs, song)
		end
	end

	-- Actualizar contador
	songCountLabel.Text = #loadedSongs .. " / " .. totalSongs .. " canciones"
end

-- ════════════════════════════════════════════════════════════════
-- SCROLL INFINITO - DETECTAR CUANDO LLEGA AL FONDO
-- ════════════════════════════════════════════════════════════════
songsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	if not selectedDJ or isLoadingMore or not hasMoreSongs then return end

	local scrollPos = songsScroll.CanvasPosition.Y
	local canvasHeight = songsScroll.CanvasSize.Y.Offset
	local frameHeight = songsScroll.AbsoluteSize.Y

	-- Si está cerca del fondo (100px), cargar más
	if scrollPos + frameHeight >= canvasHeight - 100 then
		isLoadingMore = true
		currentSongsPage = currentSongsPage + 1

		if R.GetSongsByDJ then
			R.GetSongsByDJ:FireServer(selectedDJ, currentSongsPage)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- PROGRESS BAR
-- ════════════════════════════════════════════════════════════════
local function updateProgressBar()
	if not currentSoundObject then
		currentSoundObject = game:GetService("SoundService"):FindFirstChild("QueueSound")
	end

	if not currentSoundObject or not currentSoundObject.Parent then
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"
		totalTimeLabel.Text = "0:00"
		return
	end

	local current = currentSoundObject.TimePosition
	local total = currentSoundObject.TimeLength

	if total > 0 then
		progressFill.Size = UDim2.new(math.clamp(current / total, 0, 1), 0, 1, 0)
		currentTimeLabel.Text = formatTime(current)
		totalTimeLabel.Text = formatTime(total)
	end
end

-- ════════════════════════════════════════════════════════════════
-- NAVIGATION
-- ════════════════════════════════════════════════════════════════
local function moveUnderline(btn)
	task.spawn(function()
		task.wait(0.03)
		local x = btn.AbsolutePosition.X - panel.AbsolutePosition.X
		TweenService:Create(underline, TweenInfo.new(0.2), {
			Position = UDim2.new(0, x, 0, 159)
		}):Play()
	end)
end

function showPage(name)
	local prev = currentPage
	currentPage = name

	if prev == "Library" and name ~= "Library" then
		resetLibraryState()
	end

	queuePage.Visible = false
	libraryPage.Visible = false

	local page = holder:FindFirstChild(name)
	if page then
		page.Visible = true
		pageLayout:JumpTo(page)
	end

	if name == "Queue" then drawQueue() end
	if name == "Library" then
		resetLibraryState()
		drawDJs()
		if R.GetDJs then R.GetDJs:FireServer() end
	end
end

tQueue.MouseButton1Click:Connect(function() showPage("Queue") moveUnderline(tQueue) end)
tLibrary.MouseButton1Click:Connect(function() showPage("Library") moveUnderline(tLibrary) end)

task.defer(function()
	task.wait(0.1)
	moveUnderline(tQueue)
	showPage("Queue")
end)

-- ════════════════════════════════════════════════════════════════
-- UI OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
function openUI(toLibrary)
	if modal:isModalOpen() then return end
	if toLibrary then showPage("Library") moveUnderline(tLibrary)
	else showPage("Queue") moveUnderline(tQueue) end
	modal:open()
	if progressConnection then progressConnection:Disconnect() end
	progressConnection = RunService.Heartbeat:Connect(updateProgressBar)
end

function closeUI()
	if not modal:isModalOpen() then return end
	if progressConnection then progressConnection:Disconnect() progressConnection = nil end
	modal:close()
end

closeBtn.MouseButton1Click:Connect(closeUI)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and modal:isModalOpen() then
		closeUI()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- REMOTE EVENTS
-- ════════════════════════════════════════════════════════════════

-- Update general
if R.Update then
	R.Update.OnClientEvent:Connect(function(data)
		playQueue = data.queue or {}
		currentSong = data.currentSong
		if data.djs and #data.djs > 0 then allDJs = data.djs end
		currentSoundObject = game:GetService("SoundService"):FindFirstChild("QueueSound")

		songTitle.Text = currentSong and (currentSong.name .. " - " .. (currentSong.artist or "?")) or "No song playing"

		if currentPage == "Queue" then drawQueue() end
		if currentPage == "Library" and not selectedDJ then drawDJs() end
	end)
end

-- GetDJs response
if R.GetDJs then
	R.GetDJs.OnClientEvent:Connect(function(data)
		if data and data.djs and #data.djs > 0 then
			allDJs = data.djs
			if currentPage == "Library" and not selectedDJ then drawDJs() end
		end
	end)
end

-- GetSongsByDJ response (PAGINADO)
if R.GetSongsByDJ then
	R.GetSongsByDJ.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= selectedDJ then return end

		isLoadingMore = false
		hasMoreSongs = data.hasMore or false

		if data.songs and #data.songs > 0 then
			appendSongsToScroll(data.songs)
		end

		-- Si no hay más, mostrar mensaje
		if not hasMoreSongs and #loadedSongs > 0 then
			local endLabel = songsScroll:FindFirstChild("EndLabel")
			if not endLabel then
				endLabel = Instance.new("TextLabel")
				endLabel.Name = "EndLabel"
				endLabel.Size = UDim2.new(1, 0, 0, 30)
				endLabel.BackgroundTransparency = 1
				endLabel.Text = "— Fin de la lista —"
				endLabel.TextColor3 = THEME.muted
				endLabel.Font = Enum.Font.Gotham
				endLabel.TextSize = 11
				endLabel.LayoutOrder = 99999
				endLabel.Parent = songsScroll
			end
		end
	end)
end

-- GetSongMetadata response (para actualizar nombres)
if R.GetSongMetadata then
	R.GetSongMetadata.OnClientEvent:Connect(function(results)
		if not results then return end

		for id, metadata in pairs(results) do
			localMetadataCache[id] = metadata

			-- Actualizar UI si la canción está visible
			local card = songsScroll:FindFirstChild("Song_" .. id)
			if card then
				local nameLabel = card:FindFirstChild("SongName")
				local artistLabel = card:FindFirstChild("ArtistName")
				if nameLabel then nameLabel.Text = metadata.name end
				if artistLabel then artistLabel.Text = metadata.artist end
			end
		end
	end)
end

-- Add response
if R.AddResponse then
	R.AddResponse.OnClientEvent:Connect(function(response)
		if not response then return end
		showNotification(response)

		if response.success then setAddButtonState("success")
		elseif response.code == ResponseCodes.ERROR_DUPLICATE then setAddButtonState("duplicate")
		else setAddButtonState("error") end

		-- Actualizar botones en songs scroll
		if songsScroll then
			for _, card in pairs(songsScroll:GetChildren()) do
				if card:IsA("Frame") then
					local btn = card:FindFirstChild("QueueBtn")
					if btn and btn.Text == "..." then
						if response.success or response.code == ResponseCodes.ERROR_DUPLICATE then
							btn.Text = "EN COLA"
							btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
							btn.TextColor3 = Color3.fromRGB(150, 150, 160)
							btn.AutoButtonColor = false
						else
							btn.Text = "QUEUE"
							btn.BackgroundColor3 = THEME.success
							btn.TextColor3 = Color3.new(1, 1, 1)
						end
					end
				end
			end
		end
	end)
end

if R.RemoveResponse then
	R.RemoveResponse.OnClientEvent:Connect(function(r) if r then showNotification(r) end end)
end

if R.ClearResponse then
	R.ClearResponse.OnClientEvent:Connect(function(r) if r then showNotification(r) end end)
end

-- ════════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════════
task.defer(function()
	if R.GetDJs then R.GetDJs:FireServer() end
end)