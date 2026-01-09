--[[ Music Dashboard - Professional Edition v4
     • Sistema completo de música con múltiples admins
     • Tabs: Queue / Library / Add
     • Control de volumen PERSONAL (no global)
     • Reproductor en tiempo real con progreso
     • Layout optimizado y responsive
     
     CORRECCIONES APLICADAS v4:
     1. FIX: Bug de navegación - Ahora resetea el estado de Library al cambiar de tab
     2. FIX: Posiciones consistentes en djsScroll y songsScroll
     3. FIX: Se resetea selectedDJ al salir de Library
     4. Todas las correcciones anteriores de v3 incluidas
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
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("ConfirmationModal"))
local ModalManager = require(ReplicatedStorage:WaitForChild("ModalManager"))
local Notify = require(ReplicatedStorage:WaitForChild("NotificationSystem"))

-- ════════════════════════════════════════════════════════════════
-- ADMIN CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer

local ADMIN_IDS = {
	8387751399,  -- nandoxts (Owner)
	9375636407,  -- Admin2
}

local function isAdminUser(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then return true end
	end
	return false
end

-- DEBUG: activar para mostrar controles de admin en este cliente (útil para pruebas)
local SHOW_ADMIN_UI = false

local isAdmin = isAdminUser(player.UserId) or SHOW_ADMIN_UI

-- ════════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local R_PANEL, R_CTRL = 12, 10
local ENABLE_BLUR, BLUR_SIZE = true, 14

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local USE_PIXEL_SIZE = true
local PANEL_W_SCALE = 0.40
local PANEL_H_SCALE = 0.86
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620 

-- ════════════════════════════════════════════════════════════════
-- POSICIONES CONSTANTES (para evitar inconsistencias)
-- ════════════════════════════════════════════════════════════════
local DJS_SCROLL_DEFAULT_POS = UDim2.new(0, 12, 0, 8)
local SONGS_SCROLL_DEFAULT_POS = UDim2.new(0, 12, 0, 56)

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local musicLibrary, playQueue, currentSong = {}, {}, nil
local allDJs, selectedDJ = {}, nil
local currentPage = "Queue"
local currentSoundObject = nil
local progressConnection = nil
local quickAddBtn, quickInput, qiStroke = nil, nil, nil

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function stroked(inst, alpha)
	local s = Instance.new("UIStroke")
	s.Color = THEME.stroke
	s.Thickness = 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function isValidAudioId(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	local len = #text
	return (len >= 6 and len <= 19)
end

local function getRemote(name)
	local MusicRemotes = ReplicatedStorage:WaitForChild("MusicRemotes", 10)
	if not MusicRemotes then warn("[MusicDashboard] Remote folder missing"); return end

	local remoteMap = {
		NextSong = "MusicPlayback",
		PlaySong = "MusicPlayback",
		PauseSong = "MusicPlayback",
		StopSong = "MusicPlayback",
		UpdatePlayback = "MusicPlayback",
		AddToQueue = "MusicQueue",
		RemoveFromQueue = "MusicQueue",
		ClearQueue = "MusicQueue",
		MoveInQueue = "MusicQueue",
		UpdateQueue = "MusicQueue",
		UpdateUI = "UI",
		GetDJs = "MusicLibrary",
		GetSongsByDJ = "MusicLibrary",
		AddSongToDJ = "MusicLibrary",
		RemoveSongFromLibrary = "MusicLibrary",
		RemoveDJ = "MusicLibrary",
		RenameDJ = "MusicLibrary"
	}

	local subfolder = remoteMap[name] or "MusicLibrary"
	local folder = MusicRemotes:FindFirstChild(subfolder)
	if not folder then
		warn("[MusicDashboard] Subfolder missing:", subfolder)
		return nil
	end

	local r = folder:FindFirstChild(name)
	if not r then warn("[MusicDashboard] Remote missing:", name, "in", subfolder) end
	return r
end

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local R = {
	Next = getRemote("NextSong"),
	Add = getRemote("AddToQueue"),
	Remove = getRemote("RemoveFromQueue"),
	Clear = getRemote("ClearQueue"),
	Update = getRemote("UpdateUI"),
	GetDJs = getRemote("GetDJs"),
	GetSongsByDJ = getRemote("GetSongsByDJ"),
	AddSongToDJ = getRemote("AddSongToDJ"),
	RemoveSongFromLibrary = getRemote("RemoveSongFromLibrary"),
	RemoveDJ = getRemote("RemoveDJ"),
	RenameDJ = getRemote("RenameDJ")
}

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = script.Parent :: ScreenGui
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
		pcall(function()
			_G.MusicDashboardIcon:destroy()
		end)
		_G.MusicDashboardIcon = nil
	end

	musicIcon = Icon.new()
		:setLabel("MUSIC")
		:setOrder(1)
		:bindEvent("selected", function()
			openUI(false)
		end)
		:bindEvent("deselected", function()
			closeUI()
		end)
		:setEnabled(true)

	_G.MusicDashboardIcon = musicIcon
end

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER - Panel centralizado
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
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 126)
header.BackgroundColor3 = THEME.head
header.BorderSizePixel = 0
header.ZIndex = 102
header.Parent = panel
rounded(header, 18)

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
title.TextSize = 18
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
rounded(closeBtn, 8)
stroked(closeBtn, 0.4)

-- ════════════════════════════════════════════════════════════════
-- NOW PLAYING BAR
-- ════════════════════════════════════════════════════════════════
local nowPlayingBar = Instance.new("Frame")
nowPlayingBar.Size = UDim2.new(1, -40, 0, 50)
nowPlayingBar.Position = UDim2.new(0, 20, 0, 56)
nowPlayingBar.BackgroundColor3 = THEME.card
nowPlayingBar.BorderSizePixel = 0
nowPlayingBar.Parent = header
rounded(nowPlayingBar, 8)
stroked(nowPlayingBar, 0.3)

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
songTitle.TextSize = 15
songTitle.TextXAlignment = Enum.TextXAlignment.Left
songTitle.TextTruncate = Enum.TextTruncate.AtEnd
songTitle.Parent = songInfo

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(1, 0, 0, 10)
progressBar.Position = UDim2.new(0, 0, 0, 26)
progressBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
progressBar.BorderSizePixel = 0
progressBar.Parent = nowPlayingBar
rounded(progressBar, 2)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBar
rounded(progressFill, 5)

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
currentTimeLabel.TextSize = 12
currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
currentTimeLabel.Parent = timeLabels

local totalTimeLabel = Instance.new("TextLabel")
totalTimeLabel.BackgroundTransparency = 1
totalTimeLabel.Size = UDim2.new(0, 40, 1, 0)
totalTimeLabel.Position = UDim2.new(1, -40, 0, 0)
totalTimeLabel.Text = "0:00"
totalTimeLabel.TextColor3 = THEME.muted
totalTimeLabel.Font = Enum.Font.GothamMedium
totalTimeLabel.TextSize = 12
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
		b.TextSize = 12
		b.Parent = ctrl
		rounded(b, 6)
		stroked(b, 0.2)

		b.MouseEnter:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(
					color.R * 255 + 15,
					color.G * 255 + 15,
					color.B * 255 + 15
				)
			}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = color
			}):Play()
		end)

		return b
	end

	local skipB = mini("SKIP", THEME.accent)
	local clearB = mini("CLEAR", Color3.fromRGB(161, 124, 72))

	if R.Next then skipB.MouseButton1Click:Connect(function() R.Next:FireServer() end) end
	if R.Clear then clearB.MouseButton1Click:Connect(function() R.Clear:FireServer() end) end
end

-- ════════════════════════════════════════════════════════════════
-- PERSONAL VOLUME CONTROL
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
rounded(volSliderBg, 8)
stroked(volSliderBg, 0.6)

local volSliderFill = Instance.new("Frame")
volSliderFill.Size = UDim2.new(0.8, 0, 1, 0)
volSliderFill.BackgroundColor3 = THEME.accent
volSliderFill.BorderSizePixel = 0
volSliderFill.ZIndex = 103
volSliderFill.Parent = volSliderBg
rounded(volSliderFill, 8)

local volLabel = Instance.new("TextButton")
volLabel.Size = UDim2.new(0, 42, 0, 26)
volLabel.Position = UDim2.new(0, 90, 0, 0)
volLabel.BackgroundColor3 = THEME.card
volLabel.Text = "80%"
volLabel.TextColor3 = THEME.text
volLabel.Font = Enum.Font.GothamBold
volLabel.TextSize = 14
volLabel.BorderSizePixel = 0
volLabel.ZIndex = 103
volLabel.AutoButtonColor = false
volLabel.Parent = volFrame
rounded(volLabel, 8)
stroked(volLabel, 0.3)

local volInput = Instance.new("TextBox")
volInput.Size = volLabel.Size
volInput.Position = volLabel.Position
volInput.BackgroundColor3 = THEME.elevated
volInput.Text = "80"
volInput.TextColor3 = THEME.text
volInput.Font = Enum.Font.GothamBold
volInput.TextSize = 14
volInput.BorderSizePixel = 0
volInput.ZIndex = 104
volInput.Visible = false
volInput.ClearTextOnFocus = false
volInput.TextXAlignment = Enum.TextXAlignment.Center
volInput.Parent = volFrame
rounded(volInput, 8)
stroked(volInput, 0.4)

local savedVolume = player:GetAttribute("MusicVolume") or 0.8
local currentVolume = savedVolume
local dragging = false

local function saveVolume(volume)
	player:SetAttribute("MusicVolume", volume)
end

local function updateVolume(volume)
	currentVolume = math.clamp(volume, 0, 1)
	volSliderFill.Size = UDim2.new(currentVolume, 0, 1, 0)
	volLabel.Text = math.floor(currentVolume * 100) .. "%"
	volInput.Text = tostring(math.floor(currentVolume * 100))

	local sound = workspace:FindFirstChild("QueueSound")
	if sound and sound:IsA("Sound") then
		sound.Volume = currentVolume
	end

	saveVolume(currentVolume)
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

volSliderBg.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local pos = math.clamp((input.Position.X - volSliderBg.AbsolutePosition.X) / volSliderBg.AbsoluteSize.X, 0, 1)
		updateVolume(pos)
	end
end)

volLabel.MouseButton1Click:Connect(function()
	volLabel.Visible = false
	volInput.Visible = true
	volInput:CaptureFocus()
	volInput.Text = tostring(math.floor(currentVolume * 100))
end)

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

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Return and volInput.Visible then
		applyInputValue()
	end
end)

volLabel.MouseEnter:Connect(function()
	TweenService:Create(volLabel, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.hover
	}):Play()
end)

volLabel.MouseLeave:Connect(function()
	TweenService:Create(volLabel, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card
	}):Play()
end)

RunService.Heartbeat:Connect(function()
	local sound = workspace:FindFirstChild("QueueSound")
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
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Parent = navBar
	return btn
end

local tQueue = createTab("QUEUE")
local tLibrary = createTab("LIBRARY")
local tAdd = isAdmin and createTab("ADD") or nil

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, header.Size.Y.Offset + 33)
underline.BackgroundColor3 = THEME.accent
underline.BorderSizePixel = 0
underline.ZIndex = 102
underline.Parent = panel
rounded(underline, 2)

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
rounded(quickAddFrame, 8)
qiStroke = stroked(quickAddFrame, 0.3)

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
quickAddBtn.TextSize = 12
quickAddBtn.BorderSizePixel = 0
quickAddBtn.Parent = quickAddFrame
rounded(quickAddBtn, 6)

quickAddBtn.MouseButton1Click:Connect(function()
	local aid = quickInput.Text:gsub("%s+", "")

	if not isValidAudioId(aid) then
		Notify:Warning("Audio ID Inválido", "Ingresa un ID válido (6-19 dígitos)", 3)
		qiStroke.Color = THEME.danger
		quickInput.Text = ""
		quickInput.PlaceholderText = "Invalid Audio ID (6-19 digits)"
		quickAddBtn.Text = "ERROR"
		quickAddBtn.BackgroundColor3 = THEME.danger
		task.delay(2, function()
			if qiStroke and quickInput and quickAddBtn then
				qiStroke.Color = THEME.stroke
				quickInput.PlaceholderText = "Enter Audio ID..."
				quickAddBtn.Text = "ADD"
				quickAddBtn.BackgroundColor3 = THEME.accent
			end
		end)
		return
	end

	quickAddBtn.Text = "..."
	quickAddBtn.BackgroundColor3 = THEME.info
	qiStroke.Color = THEME.info

	local loadingLoop = true
	task.spawn(function()
		while loadingLoop and quickAddBtn.Text == "..." do
			for i = 1, 3 do
				if not loadingLoop then break end
				quickAddBtn.Text = string.rep(".", i)
				task.wait(0.3)
			end
		end
	end)

	if R.Add then
		R.Add:FireServer(tonumber(aid))
	end

	task.delay(5, function()
		if quickAddBtn.Text:match("%.") then
			loadingLoop = false
			quickAddBtn.Text = "TIMEOUT"
			quickAddBtn.BackgroundColor3 = THEME.warn
			qiStroke.Color = THEME.warn
			quickInput.Text = ""
			task.delay(2, function()
				if qiStroke and quickInput and quickAddBtn then
					qiStroke.Color = THEME.stroke
					quickInput.PlaceholderText = "Enter Audio ID..."
					quickAddBtn.Text = "ADD"
					quickAddBtn.BackgroundColor3 = THEME.accent
				end
			end)
		end
	end)
end)

local queueScroll = Instance.new("ScrollingFrame")
local topOffset = 10
local bottomInset = -12
if quickAddFrame and quickAddFrame.Parent and quickAddFrame.Visible then
	topOffset = 10 + quickAddFrame.Size.Y.Offset + 4
	bottomInset = -(quickAddFrame.Size.Y.Offset + 4)
end
queueScroll.Size = UDim2.new(1, -24, 1, bottomInset)
queueScroll.Position = UDim2.new(0, 12, 0, topOffset)
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
		empty.TextSize = 15
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
		rounded(card, 8)

		local cardStroke = stroked(card, isActive and 0.6 or 0.3)
		if isActive then
			local glowStroke = Instance.new("UIStroke")
			glowStroke.Color = Color3.fromRGB(120, 140, 255)
			glowStroke.Thickness = 2.5
			glowStroke.Transparency = 0.3
			glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			glowStroke.Parent = card

			task.spawn(function()
				while card.Parent and isActive do
					TweenService:Create(glowStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Transparency = 0,
						Thickness = 3
					}):Play()
					task.wait(1)
					TweenService:Create(glowStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Transparency = 0.5,
						Thickness = 2.5
					}):Play()
					task.wait(1)
				end
			end)

			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(68, 72, 100)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 32))
			}
			gradient.Rotation = 0
			gradient.Transparency = NumberSequence.new(0.3)
			gradient.Offset = Vector2.new(-1, 0)
			gradient.Parent = card

			task.spawn(function()
				while card.Parent and isActive do
					TweenService:Create(gradient, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
						Offset = Vector2.new(1, 0)
					}):Play()
					task.wait(2.5)
					gradient.Offset = Vector2.new(-1, 0)
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
			avatar.ImageTransparency = 0
			avatar.Parent = card
			rounded(avatar, 22)

			local border = Instance.new("UIStroke")
			border.Color = isActive and THEME.accent or Color3.fromRGB(100, 100, 110)
			border.Thickness = isActive and 2 or 1.5
			border.Transparency = 0
			border.Parent = avatar

			task.spawn(function()
				local success, thumb, isReady = pcall(function()
					return game.Players:GetUserThumbnailAsync(
						userId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
				end)
				if success and isReady then
					avatar.Image = thumb
				end
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
		nameText.TextSize = 14
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
		artist.TextSize = 13
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
			removeBtn.TextSize = 12
			removeBtn.BorderSizePixel = 0
			removeBtn.ZIndex = 2
			removeBtn.Parent = card
			rounded(removeBtn, 6)

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
djsScroll.Position = DJS_SCROLL_DEFAULT_POS  -- USAR CONSTANTE
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

-- Songs scroll
local songsScroll = Instance.new("ScrollingFrame")
songsScroll.Size = UDim2.new(1, -24, 1, -64)
songsScroll.Position = SONGS_SCROLL_DEFAULT_POS  -- USAR CONSTANTE
songsScroll.BackgroundTransparency = 1
songsScroll.BorderSizePixel = 0
songsScroll.ScrollBarThickness = 6
songsScroll.ScrollBarImageColor3 = THEME.stroke
songsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
songsScroll.Visible = false
songsScroll.Parent = libraryPage

local songsList = Instance.new("UIListLayout")
songsList.Padding = UDim.new(0, 6)
songsList.SortOrder = Enum.SortOrder.LayoutOrder
songsList.Parent = songsScroll

songsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	songsScroll.CanvasSize = UDim2.new(0, 0, 0, songsList.AbsoluteContentSize.Y + 12)
end)

-- Back button
local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0, 80, 0, 36)
backBtn.Position = UDim2.new(0, 12, 0, 12)
backBtn.BackgroundColor3 = THEME.accent
backBtn.Text = "← BACK"
backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 13
backBtn.BorderSizePixel = 0
backBtn.Visible = false
backBtn.ZIndex = 102
backBtn.Parent = libraryPage
rounded(backBtn, 8)
stroked(backBtn, 0.2)

-- ════════════════════════════════════════════════════════════════
-- FIX: FUNCIÓN PARA RESETEAR EL ESTADO DE LIBRARY
-- ════════════════════════════════════════════════════════════════
local function resetLibraryState()
	selectedDJ = nil
	
	-- Cancelar cualquier tween en progreso
	-- Resetear posiciones a sus valores por defecto SIN animación
	djsScroll.Position = DJS_SCROLL_DEFAULT_POS
	djsScroll.Visible = true
	djsScroll.CanvasPosition = Vector2.new(0, 0)
	
	songsScroll.Position = SONGS_SCROLL_DEFAULT_POS
	songsScroll.Visible = false
	songsScroll.CanvasPosition = Vector2.new(0, 0)
	
	backBtn.Visible = false
end

backBtn.MouseButton1Click:Connect(function()
	selectedDJ = nil
	
	-- Animación de salida para songs
	TweenService:Create(songsScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0, 12, 0, 150)
	}):Play()
	
	task.wait(0.1)
	
	songsScroll.Visible = false
	songsScroll.Position = SONGS_SCROLL_DEFAULT_POS  -- USAR CONSTANTE
	
	djsScroll.Visible = true
	djsScroll.Position = DJS_SCROLL_DEFAULT_POS  -- USAR CONSTANTE
	backBtn.Visible = false
	
	-- Animación de entrada para DJs
	djsScroll.Position = UDim2.new(0, 12, 0, 0)
	TweenService:Create(djsScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Position = DJS_SCROLL_DEFAULT_POS
	}):Play()
end)

backBtn.MouseEnter:Connect(function()
	TweenService:Create(backBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(THEME.accent.R * 255 * 0.8, THEME.accent.G * 255 * 0.8, THEME.accent.B * 255 * 0.8)
	}):Play()
end)

backBtn.MouseLeave:Connect(function()
	TweenService:Create(backBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.accent
	}):Play()
end)

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
		empty.TextSize = 15
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
		rounded(card, 16)
		stroked(card, 0.4)

		local cover = Instance.new("ImageLabel")
		cover.Size = UDim2.new(1, 0, 1, 0)
		cover.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		cover.Image = dj.cover ~= "" and dj.cover or "rbxasset://textures/face.png"
		cover.ScaleType = Enum.ScaleType.Crop
		cover.BorderSizePixel = 0
		cover.ZIndex = 51
		cover.Parent = card
		rounded(cover, 16)

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 52
		overlay.Parent = card
		rounded(overlay, 16)

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
		countLabel.TextSize = 13
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
			
			-- Animación de salida para DJs
			TweenService:Create(djsScroll, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Position = UDim2.new(0, 12, 0, -50)
			}):Play()
			
			task.wait(0.15)
			
			djsScroll.Visible = false
			djsScroll.Position = DJS_SCROLL_DEFAULT_POS  -- USAR CONSTANTE para reset
			
			songsScroll.Visible = true
			backBtn.Visible = true
			
			-- Animación de entrada para Songs
			songsScroll.Position = UDim2.new(0, 12, 0, 100)
			TweenService:Create(songsScroll, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = SONGS_SCROLL_DEFAULT_POS
			}):Play()
			
			if R.GetSongsByDJ then
				R.GetSongsByDJ:FireServer(dj.name)
			end
		end)

		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0.3
			}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				TextTransparency = 0
			}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				TextTransparency = 0
			}):Play()
		end)

		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(nameLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				TextTransparency = 1
			}):Play()
			TweenService:Create(countLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				TextTransparency = 1
			}):Play()
		end)
	end
end

local function drawSongs(songs)
	for _, child in pairs(songsScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then 
			child:Destroy() 
		end
	end

	if not songs or #songs == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "No songs in this DJ"
		empty.TextColor3 = THEME.muted
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 15
		empty.Parent = songsScroll
		return
	end

	for _, song in ipairs(songs) do
		local isInQueue = false
		for _, queueSong in ipairs(playQueue) do
			if queueSong.id == song.id then
				isInQueue = true
				break
			end
		end

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 54)
		card.BackgroundColor3 = THEME.card
		card.BorderSizePixel = 0
		card.Parent = songsScroll
		rounded(card, 8)
		stroked(card, 0.3)

		card.Name = "SongCard_" .. song.id
		card:SetAttribute("SongID", song.id)

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = card

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -160, 0, 18)
		name.Position = UDim2.new(0, 0, 0, 10)
		name.BackgroundTransparency = 1
		name.Text = song.name or "Unknown"
		name.TextColor3 = THEME.text
		name.Font = Enum.Font.GothamMedium
		name.TextSize = 15
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Parent = card

		local artist = Instance.new("TextLabel")
		artist.Size = UDim2.new(1, -160, 0, 14)
		artist.Position = UDim2.new(0, 0, 0, 28)
		artist.BackgroundTransparency = 1
		artist.Text = song.artist or "Unknown Artist"
		artist.TextColor3 = THEME.muted
		artist.Font = Enum.Font.Gotham
		artist.TextSize = 13
		artist.TextXAlignment = Enum.TextXAlignment.Left
		artist.TextTruncate = Enum.TextTruncate.AtEnd
		artist.Parent = card

		local addBtn = Instance.new("TextButton")
		addBtn.Size = UDim2.new(0, 70, 0, 30)
		addBtn.Position = UDim2.new(1, isAdmin and -150 or -70, 0.5, -15)
		addBtn.Font = Enum.Font.GothamBold
		addBtn.TextSize = 12
		addBtn.BorderSizePixel = 0
		addBtn.Parent = card
		rounded(addBtn, 6)
		addBtn.Name = "QueueButton"

		if isInQueue then
			addBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
			addBtn.Text = "EN COLA"
			addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
			addBtn.AutoButtonColor = false

			addBtn.MouseButton1Click:Connect(function()
				local originalColor = addBtn.BackgroundColor3
				addBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
				task.wait(0.1)
				addBtn.BackgroundColor3 = originalColor
			end)
		else
			addBtn.BackgroundColor3 = THEME.success
			addBtn.Text = "QUEUE"
			addBtn.TextColor3 = Color3.new(1, 1, 1)
			addBtn.AutoButtonColor = true

			addBtn.MouseButton1Click:Connect(function()
				if R.Add then 
					R.Add:FireServer(song.id)
					Notify:Success("Canción Agregada", "\"" .. song.name .. "\" fue añadida a la cola", 3)
					addBtn.BackgroundColor3 = THEME.info
					addBtn.Text = "..."
				end
			end)
		end

		if isAdmin then
			local delBtn = Instance.new("TextButton")
			delBtn.Size = UDim2.new(0, 70, 0, 30)
			delBtn.Position = UDim2.new(1, -75, 0.5, -15)
			delBtn.BackgroundColor3 = THEME.danger
			delBtn.Text = "DELETE"
			delBtn.TextColor3 = Color3.new(1, 1, 1)
			delBtn.Font = Enum.Font.GothamBold
			delBtn.TextSize = 12
			delBtn.BorderSizePixel = 0
			delBtn.Parent = card
			rounded(delBtn, 6)

			delBtn.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui,
					theme = THEME,
					Title = "Delete Song",
					Message = "Are you sure you want to delete '" .. song.name .. "' from the library?",
					ConfirmText = "DELETE",
					CancelText = "CANCEL",
					OnConfirm = function()
						if R.RemoveFromLibrary then
							R.RemoveFromLibrary:FireServer(song.id)
						end
					end
				})
			end)
		end
	end
end

local function updateLibraryButtonStates()
	if currentPage ~= "Library" then return end
	if not songsScroll then return end

	for _, card in pairs(songsScroll:GetChildren()) do
		if card:IsA("Frame") and card.Name:match("^SongCard_") then
			local songId = card:GetAttribute("SongID")
			if not songId then continue end

			local addBtn = card:FindFirstChild("QueueButton")
			if not addBtn or not addBtn:IsA("TextButton") then continue end

			local isInQueue = false
			for _, queueSong in ipairs(playQueue) do
				if queueSong.id == songId then
					isInQueue = true
					break
				end
			end

			if isInQueue then
				if addBtn.Text ~= "EN COLA" then
					TweenService:Create(addBtn, TweenInfo.new(0.2), {
						BackgroundColor3 = Color3.fromRGB(100, 100, 110)
					}):Play()
					addBtn.Text = "EN COLA"
					addBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
					addBtn.AutoButtonColor = false
				end
			else
				if addBtn.Text ~= "QUEUE" then
					TweenService:Create(addBtn, TweenInfo.new(0.2), {
						BackgroundColor3 = THEME.success
					}):Play()
					addBtn.Text = "QUEUE"
					addBtn.TextColor3 = Color3.new(1, 1, 1)
					addBtn.AutoButtonColor = true
				end
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- ADD PAGE (Solo para admins)
-- ════════════════════════════════════════════════════════════════
local addPage
if isAdmin then
	addPage = Instance.new("Frame")
	addPage.Name = "Add"
	addPage.Size = UDim2.new(1, 0, 1, 0)
	addPage.BackgroundTransparency = 1
	addPage.LayoutOrder = 3
	addPage.Parent = holder

	local form = Instance.new("Frame")
	form.Size = UDim2.new(0.9, 0, 0, 470)
	form.Position = UDim2.new(0.05, 0, 0, 20)
	form.BackgroundTransparency = 1
	form.Parent = addPage

	local function inputField(label, placeholder, yPos, maxLength)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 18)
		lbl.Position = UDim2.new(0, 0, 0, yPos)
		lbl.BackgroundTransparency = 1
		lbl.Text = label
		lbl.TextColor3 = THEME.muted
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = form

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(1, 0, 0, 42)
		input.Position = UDim2.new(0, 0, 0, yPos + 22)
		input.BackgroundColor3 = THEME.elevated
		input.Text = ""
		input.PlaceholderText = placeholder
		input.TextColor3 = THEME.text
		input.PlaceholderColor3 = THEME.muted
		input.Font = Enum.Font.Gotham
		input.TextSize = 14
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ClearTextOnFocus = false
		input.BorderSizePixel = 0
		input.Parent = form
		rounded(input, 8)
		stroked(input, 0.3)

		local inPad = Instance.new("UIPadding")
		inPad.PaddingLeft = UDim.new(0, 12)
		inPad.Parent = input

		if maxLength then
			input:GetPropertyChangedSignal("Text"):Connect(function()
				if #input.Text > maxLength then
					input.Text = string.sub(input.Text, 1, maxLength)
				end
			end)
		end

		return input
	end

	local idBox = inputField("AUDIO ID", "Enter Roblox Audio ID", 0, 19)
	local nameBox = inputField("SONG NAME", "Auto-filled from Audio ID", 78)
	local artistBox = inputField("ARTIST", "Auto-filled from Audio ID", 156)

	idBox.FocusLost:Connect(function()
		local audioId = idBox.Text
		if isValidAudioId(audioId) then
			local id = tonumber(audioId)
			task.spawn(function()
				local success, result = pcall(function()
					return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
				end)

				if success and result then
					if result.AssetTypeId == 3 then
						nameBox.Text = result.Name or ""
						artistBox.Text = result.Creator.Name or ""
						nameBox.PlaceholderText = "Enter song name"
						artistBox.PlaceholderText = "Enter artist name (optional)"
					else
						nameBox.Text = ""
						artistBox.Text = ""
						nameBox.PlaceholderText = "Not an audio asset"
					end
				else
					nameBox.Text = ""
					artistBox.Text = ""
					nameBox.PlaceholderText = "Audio not found"
				end
			end)
		else
			nameBox.Text = ""
			artistBox.Text = ""
			nameBox.PlaceholderText = "Invalid Audio ID"
		end
	end)

	local catLabel = Instance.new("TextLabel")
	catLabel.Size = UDim2.new(1, 0, 0, 18)
	catLabel.Position = UDim2.new(0, 0, 0, 234)
	catLabel.BackgroundTransparency = 1
	catLabel.Text = "DJ"
	catLabel.TextColor3 = THEME.muted
	catLabel.Font = Enum.Font.GothamBold
	catLabel.TextSize = 12
	catLabel.TextXAlignment = Enum.TextXAlignment.Left
	catLabel.Parent = form

	local catDropdown = Instance.new("TextButton")
	catDropdown.Size = UDim2.new(1, 0, 0, 42)
	catDropdown.Position = UDim2.new(0, 0, 0, 256)
	catDropdown.BackgroundColor3 = THEME.elevated
	catDropdown.Text = "Select DJ"
	catDropdown.TextColor3 = THEME.text
	catDropdown.Font = Enum.Font.Gotham
	catDropdown.TextSize = 14
	catDropdown.TextXAlignment = Enum.TextXAlignment.Left
	catDropdown.BorderSizePixel = 0
	catDropdown.Parent = form
	rounded(catDropdown, 8)
	stroked(catDropdown, 0.3)

	local catPad = Instance.new("UIPadding")
	catPad.PaddingLeft = UDim.new(0, 12)
	catPad.Parent = catDropdown

	local selectedCat = nil

	catDropdown.MouseButton1Click:Connect(function()
		local existingMenu = form:FindFirstChild("DJMenu")
		if existingMenu then
			existingMenu:Destroy()
			return
		end

		local menu = Instance.new("Frame")
		menu.Name = "DJMenu"
		menu.Size = UDim2.new(0, catDropdown.AbsoluteSize.X, 0, math.min(#allDJs * 34 + 12, 210))
		menu.Position = UDim2.new(0, catDropdown.Position.X.Offset, 0, catDropdown.Position.Y.Offset + 46)
		menu.BackgroundColor3 = THEME.elevated
		menu.BorderSizePixel = 0
		menu.ZIndex = 110
		menu.Parent = form
		rounded(menu, 8)
		stroked(menu, 0.3)

		local menuScroll = Instance.new("ScrollingFrame")
		menuScroll.Size = UDim2.new(1, -12, 1, -12)
		menuScroll.Position = UDim2.new(0, 6, 0, 6)
		menuScroll.BackgroundTransparency = 1
		menuScroll.BorderSizePixel = 0
		menuScroll.ScrollBarThickness = 5
		menuScroll.ScrollBarImageColor3 = THEME.stroke
		menuScroll.CanvasSize = UDim2.new(0, 0, 0, #allDJs * 34)
		menuScroll.ZIndex = 111
		menuScroll.Parent = menu

		local menuList = Instance.new("UIListLayout")
		menuList.Padding = UDim.new(0, 3)
		menuList.Parent = menuScroll

		for _, dj in ipairs(allDJs) do
			local opt = Instance.new("TextButton")
			opt.Size = UDim2.new(1, 0, 0, 32)
			opt.BackgroundColor3 = THEME.card
			opt.Text = dj.name
			opt.TextColor3 = THEME.text
			opt.Font = Enum.Font.Gotham
			opt.TextSize = 13
			opt.TextXAlignment = Enum.TextXAlignment.Left
			opt.BorderSizePixel = 0
			opt.ZIndex = 112
			opt.Parent = menuScroll
			rounded(opt, 6)

			local optPad = Instance.new("UIPadding")
			optPad.PaddingLeft = UDim.new(0, 12)
			optPad.Parent = opt

			opt.MouseEnter:Connect(function()
				opt.BackgroundColor3 = THEME.hover
			end)

			opt.MouseLeave:Connect(function()
				opt.BackgroundColor3 = THEME.card
			end)

			opt.MouseButton1Click:Connect(function()
				selectedCat = dj.name
				catDropdown.Text = dj.name
				menu:Destroy()
			end)
		end

		task.delay(0.2, function()
			local conn
			conn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local mousePos = UserInputService:GetMouseLocation()
					local menuPos = menu.AbsolutePosition
					local menuSize = menu.AbsoluteSize

					if mousePos.X < menuPos.X or mousePos.X > menuPos.X + menuSize.X or
						mousePos.Y < menuPos.Y or mousePos.Y > menuPos.Y + menuSize.Y then
						conn:Disconnect()
						if menu and menu.Parent then menu:Destroy() end
					end
				end
			end)
		end)
	end)

	local newCatBox = inputField("NEW DJ", "Or create new DJ", 312)

	local addLib = Instance.new("TextButton")
	addLib.Size = UDim2.new(1, 0, 0, 44)
	addLib.Position = UDim2.new(0, 0, 0, 408)
	addLib.BackgroundColor3 = THEME.accent
	addLib.Text = "ADD TO LIBRARY"
	addLib.TextColor3 = Color3.new(1, 1, 1)
	addLib.Font = Enum.Font.GothamBold
	addLib.TextSize = 15
	addLib.BorderSizePixel = 0
	addLib.Parent = form
	rounded(addLib, 8)
	stroked(addLib, 0.15)

	addLib.MouseButton1Click:Connect(function()
		local aid = idBox.Text
		local nm = nameBox.Text
		local ar = artistBox.Text
		local cat = newCatBox.Text ~= "" and newCatBox.Text or selectedCat

		if not isValidAudioId(aid) then
			idBox.Text = ""
			idBox.PlaceholderText = "INVALID AUDIO ID"
			return
		end

		if nm == "" then
			nameBox.PlaceholderText = "REQUIRED"
			return
		end

		if not cat then
			catDropdown.Text = "SELECT DJ"
			return
		end

		if R.AddSongToDJ then
			R.AddSongToDJ:FireServer(tonumber(aid), nm, ar, cat)

			idBox.Text = ""
			nameBox.Text = ""
			artistBox.Text = ""
			newCatBox.Text = ""
			catDropdown.Text = "Select DJ"
			selectedCat = nil

			addLib.Text = "ADDED SUCCESSFULLY"
			addLib.BackgroundColor3 = THEME.success
			task.delay(2, function()
				addLib.Text = "ADD TO LIBRARY"
				addLib.BackgroundColor3 = THEME.accent
			end)
		end
	end)

	addLib.MouseEnter:Connect(function()
		TweenService:Create(addLib, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(
				THEME.accent.R * 255 + 20,
				THEME.accent.G * 255 + 20,
				THEME.accent.B * 255 + 20
			)
		}):Play()
	end)

	addLib.MouseLeave:Connect(function()
		TweenService:Create(addLib, TweenInfo.new(0.15), {
			BackgroundColor3 = THEME.accent
		}):Play()
	end)
end

-- ════════════════════════════════════════════════════════════════
-- PROGRESS BAR UPDATE
-- ════════════════════════════════════════════════════════════════
local function updateProgressBar()
	if not currentSoundObject then
		currentSoundObject = Workspace:FindFirstChild("QueueSound")
	end

	if not currentSoundObject or not currentSoundObject:IsA("Sound") or not currentSoundObject.Parent then
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		currentTimeLabel.Text = "0:00"
		totalTimeLabel.Text = "0:00"
		if not currentSong then
			songTitle.Text = "No song playing"
		end
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
-- NAVIGATION - FIX PRINCIPAL
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
	
	-- ════════════════════════════════════════════════════════════════
	-- FIX: RESETEAR ESTADO DE LIBRARY AL SALIR DE ELLA
	-- ════════════════════════════════════════════════════════════════
	if previousPage == "Library" and name ~= "Library" then
		-- Estábamos en Library y vamos a otra página
		-- Resetear el estado completamente (sin animaciones)
		resetLibraryState()
	end
	
	if queuePage then queuePage.Visible = false end
	if libraryPage then libraryPage.Visible = false end
	if addPage then addPage.Visible = false end

	local pageFrame = holder:FindFirstChild(name)
	if pageFrame then
		pageFrame.Visible = true
		pageLayout:JumpTo(pageFrame)
	end

	if name == "Queue" then 
		drawQueue() 
	end
	
	if name == "Library" then
		-- Asegurar que el estado esté limpio al entrar
		resetLibraryState()
		
		if #allDJs > 0 then
			drawDJs()
		else
			for _, child in pairs(djsScroll:GetChildren()) do
				if not child:IsA("UIGridLayout") then 
					child:Destroy() 
				end
			end
		end
		
		if R.GetDJs then
			R.GetDJs:FireServer()
		end
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
if tAdd then wireTab(tAdd, "Add") end

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
	
	if progressConnection then
		progressConnection:Disconnect()
	end
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

		currentSoundObject = workspace:FindFirstChild("QueueSound")

		if currentSong then
			songTitle.Text = currentSong.name .. " - " .. (currentSong.artist or "Unknown")
		else
			songTitle.Text = "No song playing"
		end

		if data.error and quickAddBtn then
			local isBlocked = data.error == "Canción ya en cola"

			if isBlocked then
				Notify:Info("Canción Bloqueada", "Esta canción ya está en la cola", 3)
				qiStroke.Color = Color3.fromRGB(255, 150, 0)
				quickInput.Text = ""
				quickInput.PlaceholderText = data.error
				quickAddBtn.Text = "BLOCKED"
				quickAddBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
			else
				Notify:Error("Error al Agregar", data.error, 3)
				qiStroke.Color = THEME.danger
				quickInput.Text = ""
				quickInput.PlaceholderText = data.error
				quickAddBtn.Text = "ERROR"
				quickAddBtn.BackgroundColor3 = THEME.danger
			end

			task.delay(3, function()
				if qiStroke and quickInput and quickAddBtn then
					qiStroke.Color = THEME.stroke
					quickInput.PlaceholderText = "Enter Audio ID..."
					quickAddBtn.Text = "ADD"
					quickAddBtn.BackgroundColor3 = THEME.accent
				end
			end)

		elseif quickAddBtn and quickAddBtn.Text == "..." then
			Notify:Success("Canción Agregada", "La canción ha sido añadida a la cola", 3)
			quickInput.Text = ""
			qiStroke.Color = THEME.success
			quickAddBtn.Text = "ADDED"
			quickAddBtn.BackgroundColor3 = THEME.success

			task.delay(2, function()
				if qiStroke and quickInput and quickAddBtn then
					qiStroke.Color = THEME.stroke
					quickInput.PlaceholderText = "Enter Audio ID..."
					quickAddBtn.Text = "ADD"
					quickAddBtn.BackgroundColor3 = THEME.accent
				end
			end)
		end

		if currentPage == "Queue" then 
			drawQueue() 
		end

		if currentPage == "Library" then 
			if selectedDJ then
				if R.GetSongsByDJ then
					R.GetSongsByDJ:FireServer(selectedDJ)
				end
			else
				drawDJs()
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

if R.GetSongsByDJ then
	R.GetSongsByDJ.OnClientEvent:Connect(function(p)
		if p and p.songs then drawSongs(p.songs) end
	end)
end

if R.AddSongToDJ then
	R.AddSongToDJ.OnClientEvent:Connect(function(response)
		if response and response.success ~= nil then
			if response.success then
				if quickAddBtn then
					quickAddBtn.Text = "OK"
					quickAddBtn.BackgroundColor3 = THEME.success
					quickInput.PlaceholderText = "Enter Audio ID..."
				end
			else
				if quickAddBtn then
					quickAddBtn.Text = "ERROR"
					quickAddBtn.BackgroundColor3 = THEME.danger
					quickInput.PlaceholderText = response.message or "Error adding song"
					qiStroke.Color = THEME.danger
				end
			end

			task.delay(2, function()
				if quickAddBtn then
					quickAddBtn.Text = "ADD"
					quickAddBtn.BackgroundColor3 = THEME.accent
					qiStroke.Color = THEME.stroke
					quickInput.PlaceholderText = "Enter Audio ID..."
				end
			end)
		end
	end)
end

if R.RemoveFromLibrary then
	R.RemoveFromLibrary.OnClientEvent:Connect(function(response)
		if response.success then
			print("Song removed:", response.message)
			if currentPage == "Library" and selectedDJ then
				if R.GetSongsByDJ then
					R.GetSongsByDJ:FireServer(selectedDJ)
				end
			end
		else
			warn("Error removing song:", response.message)
		end
	end)
end

if R.RemoveDJ then
	R.RemoveDJ.OnClientEvent:Connect(function(response)
		if response.success then
			print("DJ removed:", response.message)
			selectedDJ = nil
			if currentPage == "Library" then
				drawDJs()
				if R.GetDJs then
					R.GetDJs:FireServer()
				end
			end
		else
			warn("Error removing DJ:", response.message)
		end
	end)
end

if R.RenameDJ then
	R.RenameDJ.OnClientEvent:Connect(function(response)
		if response.success then
			print("DJ renamed:", response.message)
			if selectedDJ == response.oldName then
				selectedDJ = response.newName
			end
			if currentPage == "Library" then
				drawDJs()
				if selectedDJ and R.GetSongsByDJ then
					R.GetSongsByDJ:FireServer(selectedDJ)
				end
			end
		else
			warn("Error renaming DJ:", response.message)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
if R.GetDJs then R.GetDJs:FireServer() end