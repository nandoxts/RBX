-- SISTEMA DE ANUNCIOS GLOBALES - LocalScript (StarterGui)
-- Autor: ignxts
-- Modificado: Responsive PC/Móvil + Avatar circular

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local THEME = require(ReplicatedStorage.Config.ThemeConfig)

local COLORS = {
	Background = THEME.bg,
	BackgroundDark = THEME.panel,
	TextPrimary = THEME.text,
	TextSecondary = THEME.muted,
	Accent = THEME.accent,
	Border = THEME.stroke,
	Verified = THEME.text,
}

-- ════════════════════════════════════════════════════════════════
-- CONFIG RESPONSIVO (PC / MÓVIL)
-- ════════════════════════════════════════════════════════════════
local PC = {
	WIDTH = 640,
	MIN_HEIGHT = 140,
	MAX_HEIGHT = 380,
	AVATAR_SIZE = 96,
	AVATAR_RADIUS = 48,        -- Circular (mitad del tamaño)
	AVATAR_STROKE = 2.5,
	AVATAR_OFFSET_X = 20,
	TEXT_OFFSET_X = 126,
	TEXT_PADDING = 20,
	DISPLAY_NAME_SIZE = 24,
	HANDLE_SIZE = 18,
	VERIFIED_SIZE = 22,
	MESSAGE_BASE_SIZE = 26,
	MESSAGE_MIN_SIZE = 6,
	MESSAGE_TOP = 35,
	NAME_HEIGHT = 28,
	CORNER_RADIUS = 20,
	STROKE_THICKNESS = 1.5,
	PROGRESS_HEIGHT = 4,
	PROGRESS_BOTTOM = 12,
	SLIDE_Y = 25,
}

local MOBILE = {
	WIDTH = 370,
	MIN_HEIGHT = 100,
	MAX_HEIGHT = 260,
	AVATAR_SIZE = 56,
	AVATAR_RADIUS = 28,        -- Circular
	AVATAR_STROKE = 2,
	AVATAR_OFFSET_X = 12,
	TEXT_OFFSET_X = 78,
	TEXT_PADDING = 14,
	DISPLAY_NAME_SIZE = 17,
	HANDLE_SIZE = 13,
	VERIFIED_SIZE = 16,
	MESSAGE_BASE_SIZE = 18,
	MESSAGE_MIN_SIZE = 6,
	MESSAGE_TOP = 26,
	NAME_HEIGHT = 20,
	CORNER_RADIUS = 14,
	STROKE_THICKNESS = 1,
	PROGRESS_HEIGHT = 3,
	PROGRESS_BOTTOM = 8,
	SLIDE_Y = 18,
}

local function isMobile()
	local touchEnabled = UserInputService.TouchEnabled
	local keyboardEnabled = UserInputService.KeyboardEnabled
	local gamepadEnabled = UserInputService.GamepadEnabled
	local screenSmall = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 700
	return (touchEnabled and not keyboardEnabled and not gamepadEnabled) or screenSmall or false
end

local CFG = isMobile() and MOBILE or PC

-- ════════════════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnuncioGlobalGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, CFG.WIDTH, 0, CFG.MIN_HEIGHT)
mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
mainContainer.AnchorPoint = Vector2.new(0.5, 0)
mainContainer.BackgroundColor3 = COLORS.Background
mainContainer.BackgroundTransparency = 0.1
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ZIndex = 100
mainContainer.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, CFG.CORNER_RADIUS)
mainCorner.Parent = mainContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Border
mainStroke.Thickness = CFG.STROKE_THICKNESS
mainStroke.Transparency = 0.3
mainStroke.Parent = mainContainer

-- Avatar del usuario (CIRCULAR)
local userImage = Instance.new("ImageLabel")
userImage.Name = "UserImage"
userImage.Size = UDim2.new(0, CFG.AVATAR_SIZE, 0, CFG.AVATAR_SIZE)
userImage.Position = UDim2.new(0, CFG.AVATAR_OFFSET_X, 0.5, 0)
userImage.AnchorPoint = Vector2.new(0, 0.5)
userImage.BackgroundColor3 = COLORS.BackgroundDark
userImage.BorderSizePixel = 0
userImage.Image = ""
userImage.ZIndex = 101
userImage.Parent = mainContainer

local userImageCorner = Instance.new("UICorner")
userImageCorner.CornerRadius = UDim.new(0, CFG.AVATAR_RADIUS)
userImageCorner.Parent = userImage

local userImageStroke = Instance.new("UIStroke")
userImageStroke.Color = COLORS.Border
userImageStroke.Thickness = CFG.AVATAR_STROKE
userImageStroke.Parent = userImage

-- Contenedor de texto
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -(CFG.TEXT_OFFSET_X + CFG.TEXT_PADDING), 1, -20)
textContainer.Position = UDim2.new(0, CFG.TEXT_OFFSET_X, 0, 10)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 101
textContainer.Parent = mainContainer

-- Contenedor del nombre + check
local nameContainer = Instance.new("Frame")
nameContainer.Name = "NameContainer"
nameContainer.Size = UDim2.new(1, 0, 0, CFG.NAME_HEIGHT)
nameContainer.Position = UDim2.new(0, 0, 0, 5)
nameContainer.BackgroundTransparency = 1
nameContainer.ZIndex = 101
nameContainer.Parent = textContainer

local nameLayout = Instance.new("UIListLayout")
nameLayout.FillDirection = Enum.FillDirection.Horizontal
nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
nameLayout.Padding = UDim.new(0, 6)
nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
nameLayout.Parent = nameContainer

-- Nombre de usuario
local displayNameLabel = Instance.new("TextLabel")
displayNameLabel.Name = "DisplayName"
displayNameLabel.Size = UDim2.new(0, 0, 0, CFG.NAME_HEIGHT)
displayNameLabel.AutomaticSize = Enum.AutomaticSize.X
displayNameLabel.BackgroundTransparency = 1
displayNameLabel.Text = "DisplayName"
displayNameLabel.TextSize = CFG.DISPLAY_NAME_SIZE
displayNameLabel.Font = Enum.Font.GothamBold
displayNameLabel.TextColor3 = COLORS.TextPrimary
displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
displayNameLabel.LayoutOrder = 1
displayNameLabel.ZIndex = 102
displayNameLabel.Parent = nameContainer

local userHandle = Instance.new("TextLabel")
userHandle.Name = "UserHandle"
userHandle.Size = UDim2.new(0, 0, 0, CFG.NAME_HEIGHT - 4)
userHandle.AutomaticSize = Enum.AutomaticSize.X
userHandle.BackgroundTransparency = 1
userHandle.Text = "@usuario"
userHandle.TextSize = CFG.HANDLE_SIZE
userHandle.Font = Enum.Font.GothamMedium
userHandle.TextColor3 = COLORS.TextSecondary
userHandle.TextXAlignment = Enum.TextXAlignment.Left
userHandle.LayoutOrder = 2
userHandle.ZIndex = 102
userHandle.Parent = nameContainer

-- Check de verificado
local verifiedCheck = Instance.new("TextLabel")
verifiedCheck.Name = "VerifiedCheck"
verifiedCheck.Size = UDim2.new(0, CFG.VERIFIED_SIZE, 0, CFG.VERIFIED_SIZE)
verifiedCheck.BackgroundTransparency = 1
verifiedCheck.Text = ""
verifiedCheck.Font = Enum.Font.GothamBold
verifiedCheck.TextSize = CFG.VERIFIED_SIZE
verifiedCheck.TextColor3 = COLORS.Verified
verifiedCheck.TextXAlignment = Enum.TextXAlignment.Left
verifiedCheck.TextYAlignment = Enum.TextYAlignment.Center
verifiedCheck.LayoutOrder = 3
verifiedCheck.ZIndex = 102
verifiedCheck.Parent = nameContainer

-- Mensaje
local messageText = Instance.new("TextLabel")
messageText.Name = "MessageText"
messageText.Size = UDim2.new(1, 0, 0, 45)
messageText.Position = UDim2.new(0, 0, 0, CFG.MESSAGE_TOP)
messageText.BackgroundTransparency = 1
messageText.Text = ""
messageText.TextSize = CFG.MESSAGE_BASE_SIZE
messageText.Font = Enum.Font.GothamBold
messageText.TextColor3 = COLORS.TextPrimary
messageText.TextXAlignment = Enum.TextXAlignment.Left
messageText.TextYAlignment = Enum.TextYAlignment.Top
messageText.TextWrapped = true
messageText.TextTruncate = Enum.TextTruncate.AtEnd
messageText.ZIndex = 102
messageText.AutomaticSize = Enum.AutomaticSize.Y
messageText.Parent = textContainer

-- Barra de progreso
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Size = UDim2.new(1, -30, 0, CFG.PROGRESS_HEIGHT)
progressBarBg.Position = UDim2.new(0.5, 0, 1, -CFG.PROGRESS_BOTTOM)
progressBarBg.AnchorPoint = Vector2.new(0.5, 0)
progressBarBg.BackgroundColor3 = COLORS.BackgroundDark
progressBarBg.BorderSizePixel = 0
progressBarBg.ZIndex = 101
progressBarBg.Parent = mainContainer

local progressBarBgCorner = Instance.new("UICorner")
progressBarBgCorner.CornerRadius = UDim.new(1, 0)
progressBarBgCorner.Parent = progressBarBg

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(1, 0, 1, 0)
progressBar.BackgroundColor3 = COLORS.Accent
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 102
progressBar.Parent = progressBarBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

-- ════════════════════════════════════════════════════════════════
-- ANIMACIONES
-- ════════════════════════════════════════════════════════════════

local function animateIn()
	mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
	mainContainer.Visible = true

	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, CFG.SLIDE_Y)
	})
	tween:Play()
end

local function animateOut()
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -150)
	})
	tween:Play()

	pcall(function()
		tween.Completed:Wait()
	end)
	mainContainer.Visible = false
	pcall(function()
		progressBar.Size = UDim2.new(1, 0, 1, 0)
		mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
	end)
end

local function animateProgress(duration)
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTOS Y COLA
-- ════════════════════════════════════════════════════════════════

local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
local crearAnuncio = eventsFolder:WaitForChild("CrearAnuncio")

local announcementQueue = {}
local processingAnnouncements = false
local startProcessing

local function processQueue()
	while #announcementQueue > 0 do
		local item = table.remove(announcementQueue, 1)
		local ok, err = pcall(function()
			local displayName = item.displayName
			local userName = item.userName
			local msg = item.msg
			local duration = item.duration or 4

			local userId
			local targetPlayer = Players:FindFirstChild(userName)
			if targetPlayer then
				userId = targetPlayer.UserId
			else
				local success, result = pcall(function()
					return Players:GetUserIdFromNameAsync(userName)
				end)
				if success then
					userId = result
				end
			end

			messageText.Text = msg

			local displayLabel = nameContainer:FindFirstChild("DisplayName")
			local handleLabel = nameContainer:FindFirstChild("UserHandle")
			if displayLabel then displayLabel.Text = displayName end
			if handleLabel then handleLabel.Text = "@" .. userName end

			-- Ajuste de texto responsivo
			local maxWidth = CFG.WIDTH
			local minFontSize = CFG.MESSAGE_MIN_SIZE
			local baseFontSize = CFG.MESSAGE_BASE_SIZE
			local maxContainerHeight = CFG.MAX_HEIGHT
			local minContainerHeight = CFG.MIN_HEIGHT
			local maxLines = 5
			local lineHeightFactor = 1.15

			if mainContainer.AbsoluteSize.X == 0 then
				repeat task.wait() until mainContainer.AbsoluteSize.X > 0
			end
			local availableWidth = math.max(10, maxWidth - CFG.TEXT_OFFSET_X - 12)
			local function textHeightFor(size, text)
				local okSize, sizeVec = pcall(function()
					return TextService:GetTextSize(text or msg, size, messageText.Font, Vector2.new(availableWidth, 10000))
				end)
				return (okSize and sizeVec.Y) or 0
			end

			local chosenSize = baseFontSize
			for s = baseFontSize, minFontSize, -1 do
				local h = textHeightFor(s, msg)
				local maxAllowed = maxLines * s * lineHeightFactor
				if h <= maxAllowed then
					chosenSize = s
					break
				end
			end

			local hBase = textHeightFor(baseFontSize, msg)
			local singleLineHeight = baseFontSize * lineHeightFactor
			if hBase <= singleLineHeight then
				for s = baseFontSize + 1, baseFontSize + 8 do
					if textHeightFor(s, msg) <= singleLineHeight then
						chosenSize = s
					else
						break
					end
				end
			end

			messageText.TextSize = chosenSize
			local requiredHeight = textHeightFor(chosenSize, messageText.Text)
			local desiredHeight = math.clamp(requiredHeight + 55, minContainerHeight, maxContainerHeight)

			local targetSize = UDim2.new(0, maxWidth, 0, math.min(desiredHeight, maxContainerHeight))
			TweenService:Create(mainContainer, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
			if textHeightFor(chosenSize, messageText.Text) > (mainContainer.AbsoluteSize.Y - 55) then
				local truncated = msg
				while textHeightFor(chosenSize, truncated .. "...") > (mainContainer.AbsoluteSize.Y - 55) and #truncated > 0 do
					truncated = truncated:sub(1, -2)
				end
				messageText.Text = truncated .. (truncated ~= msg and "..." or "")
				requiredHeight = textHeightFor(chosenSize, messageText.Text)
				local finalSize = UDim2.new(0, maxWidth, 0, math.clamp(requiredHeight + 55, minContainerHeight, maxContainerHeight))
				TweenService:Create(mainContainer, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = finalSize}):Play()
			end
			messageText.TextSize = chosenSize

			if userId then
				local successThumb, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				end)
				if successThumb then
					userImage.Image = thumb
				end
			else
				userImage.Image = ""
			end

			progressBar.Size = UDim2.new(1, 0, 1, 0)
			mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
			mainContainer.Visible = false
			animateIn()
			animateProgress(duration)

			task.wait(duration)

			animateOut()
		end)
		if not ok then
			warn("[AnuncioGlobal] Error mostrando anuncio: " .. tostring(err))
		end
	end
end

startProcessing = function()
	if processingAnnouncements then
		return
	end
	processingAnnouncements = true
	task.spawn(function()
		local ok, err = pcall(processQueue)
		if not ok then
			warn("[AnuncioGlobal] Error en la cola: " .. tostring(err))
		end
		processingAnnouncements = false
		if #announcementQueue > 0 then
			startProcessing()
		end
	end)
end

crearAnuncio.OnClientEvent:Connect(function(displayName, userName, msg, duration, uid)
	table.insert(announcementQueue, {displayName = displayName, userName = userName, msg = msg, duration = duration or 4, uid = uid})
	startProcessing()
end)