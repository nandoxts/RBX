-- LocalAnnouncementClient.lua - LocalScript en StarterGui
-- Muestra anuncios locales apilados (como NotificationSystem)
-- Modificado: Responsive PC/Móvil

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
-- ESPERAR REMOTES
-- ════════════════════════════════════════════════════════════════
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local messageFolder = RemotesGlobal:WaitForChild("Message")
local localAnnouncement = messageFolder:WaitForChild("LocalAnnouncement")
local m2CooldownNotif = messageFolder:WaitForChild("M2CooldownNotif")
local m2FilterNotif = messageFolder:WaitForChild("M2FilterNotif")

local THEME = require(ReplicatedStorage.Config.ThemeConfig)
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local NotificationSystem = require(ReplicatedStorage.Systems.NotificationSystem.NotificationSystem)

local COLORS = {
	Background = THEME.bg,
	TextPrimary = THEME.text,
	TextSecondary = THEME.muted,
	Border = THEME.stroke,
	Accent = THEME.accent,
	Verified = THEME.text,
}

-- ════════════════════════════════════════════════════════════════
-- CONFIG RESPONSIVO (PC / MÓVIL)
-- ════════════════════════════════════════════════════════════════
local PC = {
	WIDTH = 520,
	HEIGHT = 100,
	AVATAR_SIZE = 60,
	AVATAR_RADIUS = 30,        -- Circular
	AVATAR_STROKE = 1.5,
	AVATAR_OFFSET_X = 10,
	TEXT_OFFSET_X = 85,
	TEXT_PADDING = 10,
	DISPLAY_NAME_SIZE = 20,
	HANDLE_SIZE = 14,
	VERIFIED_SIZE = 18,
	MESSAGE_SIZE = 17,
	NAME_HEIGHT = 18,
	MESSAGE_TOP = 20,
	CORNER_RADIUS = 15,
	STROKE_THICKNESS = 1.5,
	SPACING = 8,
	MAX_ANNOUNCEMENTS = 5,
	DURATION = 5,
	ANIMATION_TIME = 0.4,
	START_Y = 20,
}

local MOBILE = {
	WIDTH = 340,
	HEIGHT = 80,
	AVATAR_SIZE = 42,
	AVATAR_RADIUS = 21,        -- Circular
	AVATAR_STROKE = 1,
	AVATAR_OFFSET_X = 8,
	TEXT_OFFSET_X = 60,
	TEXT_PADDING = 8,
	DISPLAY_NAME_SIZE = 15,
	HANDLE_SIZE = 11,
	VERIFIED_SIZE = 13,
	MESSAGE_SIZE = 13,
	NAME_HEIGHT = 14,
	MESSAGE_TOP = 16,
	CORNER_RADIUS = 12,
	STROKE_THICKNESS = 1,
	SPACING = 6,
	MAX_ANNOUNCEMENTS = 4,
	DURATION = 5,
	ANIMATION_TIME = 0.4,
	START_Y = 14,
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
screenGui.Name = "LocalAnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 98
screenGui.Parent = playerGui

local activeAnnouncements = {}

-- ════════════════════════════════════════════════════════════════
-- Funciones auxiliares
-- ════════════════════════════════════════════════════════════════
local function rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
end

local function stroked(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = inst
end

local function repositionAnnouncements(skipLast)
	local yOffset = CFG.START_Y

	for i = 1, #activeAnnouncements do
		local announcement = activeAnnouncements[i]
		if announcement and announcement.Parent then
			local targetPos = UDim2.new(0.5, -CFG.WIDTH / 2, 0, yOffset)

			if not (skipLast and i == #activeAnnouncements) then
				TweenService:Create(announcement, TweenInfo.new(CFG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = targetPos
				}):Play()
			else
				announcement.Position = targetPos
			end

			yOffset = yOffset + CFG.HEIGHT + CFG.SPACING
		end
	end
end

local function removeAnnouncement(announcement)
	local index = table.find(activeAnnouncements, announcement)
	if index then
		table.remove(activeAnnouncements, index)
	end

	local tween = TweenService:Create(
		announcement,
		TweenInfo.new(CFG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0.5, -CFG.WIDTH / 2, 0, -CFG.HEIGHT - 20),
			BackgroundTransparency = 1
		}
	)

	tween.Completed:Connect(function()
		announcement:Destroy()
		repositionAnnouncements()
	end)

	for _, child in ipairs(announcement:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(CFG.ANIMATION_TIME), {
				TextTransparency = 1
			}):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(CFG.ANIMATION_TIME), {
				BackgroundTransparency = 1
			}):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(CFG.ANIMATION_TIME), {
				Transparency = 1
			}):Play()
		end
	end

	tween:Play()
end

-- ════════════════════════════════════════════════════════════════
-- Crear Anuncio
-- ════════════════════════════════════════════════════════════════
local function createAnnouncement(displayName, userName, message)
	if #activeAnnouncements >= CFG.MAX_ANNOUNCEMENTS then
		removeAnnouncement(activeAnnouncements[1])
	end

	local yOffset = CFG.START_Y
	for _ = 1, #activeAnnouncements do
		yOffset = yOffset + CFG.HEIGHT + CFG.SPACING
	end

	-- ═══════════════════════════════════════════════════════════
	-- FRAME PRINCIPAL
	-- ═══════════════════════════════════════════════════════════
	local announcement = Instance.new("Frame")
	announcement.Name = "LocalAnnouncement_" .. #activeAnnouncements
	announcement.Size = UDim2.new(0, CFG.WIDTH, 0, CFG.HEIGHT)
	announcement.Position = UDim2.new(0.5, -CFG.WIDTH / 2, 0, yOffset - 100)
	announcement.AnchorPoint = Vector2.new(0, 0)
	announcement.BackgroundColor3 = COLORS.Background
	announcement.BackgroundTransparency = 0.1
	announcement.BorderSizePixel = 0
	announcement.ZIndex = 100
	announcement.Parent = screenGui

	rounded(announcement, CFG.CORNER_RADIUS)
	stroked(announcement, COLORS.Border, CFG.STROKE_THICKNESS, 0.3)

	-- ═══════════════════════════════════════════════════════════
	-- AVATAR CIRCULAR
	-- ═══════════════════════════════════════════════════════════
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.new(0, CFG.AVATAR_SIZE, 0, CFG.AVATAR_SIZE)
	avatarImage.Position = UDim2.new(0, CFG.AVATAR_OFFSET_X, 0.5, 0)
	avatarImage.AnchorPoint = Vector2.new(0, 0.5)
	avatarImage.BackgroundColor3 = COLORS.Background
	avatarImage.BorderSizePixel = 0
	avatarImage.Image = ""
	avatarImage.ZIndex = 101
	avatarImage.Parent = announcement

	rounded(avatarImage, CFG.AVATAR_RADIUS)
	stroked(avatarImage, COLORS.Border, CFG.AVATAR_STROKE, 0.2)

	-- ═══════════════════════════════════════════════════════════
	-- CONTENEDOR DE TEXTO
	-- ═══════════════════════════════════════════════════════════
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -(CFG.TEXT_OFFSET_X + CFG.TEXT_PADDING), 1, -12)
	textContainer.Position = UDim2.new(0, CFG.TEXT_OFFSET_X, 0, 8)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 101
	textContainer.Parent = announcement

	-- Contenedor de nombre y username
	local nameHandleContainer = Instance.new("Frame")
	nameHandleContainer.Name = "NameHandleContainer"
	nameHandleContainer.Size = UDim2.new(1, 0, 0, CFG.NAME_HEIGHT)
	nameHandleContainer.Position = UDim2.new(0, 0, 0, 0)
	nameHandleContainer.BackgroundTransparency = 1
	nameHandleContainer.ZIndex = 101
	nameHandleContainer.Parent = textContainer

	local nameHandleLayout = Instance.new("UIListLayout")
	nameHandleLayout.FillDirection = Enum.FillDirection.Horizontal
	nameHandleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	nameHandleLayout.Padding = UDim.new(0, 4)
	nameHandleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nameHandleLayout.Parent = nameHandleContainer

	-- Display name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "SenderName"
	nameLabel.Size = UDim2.new(0, 0, 0, CFG.NAME_HEIGHT)
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextSize = CFG.DISPLAY_NAME_SIZE
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.Accent
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.LayoutOrder = 1
	nameLabel.ZIndex = 102
	nameLabel.Parent = nameHandleContainer

	-- Username
	local handleLabel = Instance.new("TextLabel")
	handleLabel.Name = "SenderHandle"
	handleLabel.Size = UDim2.new(0, 0, 0, CFG.NAME_HEIGHT - 2)
	handleLabel.AutomaticSize = Enum.AutomaticSize.X
	handleLabel.BackgroundTransparency = 1
	handleLabel.Text = "@" .. userName
	handleLabel.TextSize = CFG.HANDLE_SIZE
	handleLabel.Font = Enum.Font.GothamBold
	handleLabel.TextColor3 = COLORS.Accent
	handleLabel.TextXAlignment = Enum.TextXAlignment.Left
	handleLabel.LayoutOrder = 2
	handleLabel.ZIndex = 102
	handleLabel.Parent = nameHandleContainer

	-- Check de verificado (solo si es admin)
	if AdminConfig:IsAdmin(userName) then
		local verifiedCheck = Instance.new("TextLabel")
		verifiedCheck.Name = "VerifiedCheck"
		verifiedCheck.Size = UDim2.new(0, CFG.VERIFIED_SIZE, 0, CFG.VERIFIED_SIZE)
		verifiedCheck.BackgroundTransparency = 1
		verifiedCheck.Text =""
		verifiedCheck.Font = Enum.Font.GothamBold
		verifiedCheck.TextSize = CFG.VERIFIED_SIZE
		verifiedCheck.TextColor3 = COLORS.Verified
		verifiedCheck.TextXAlignment = Enum.TextXAlignment.Left
		verifiedCheck.TextYAlignment = Enum.TextYAlignment.Center
		verifiedCheck.LayoutOrder = 3
		verifiedCheck.ZIndex = 102
		verifiedCheck.Parent = nameHandleContainer
	end

	-- Mensaje
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, 0, 1, -24)
	messageLabel.Position = UDim2.new(0, 0, 0, CFG.MESSAGE_TOP)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextSize = CFG.MESSAGE_SIZE
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.TextColor3 = COLORS.TextPrimary
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
	messageLabel.ZIndex = 102
	messageLabel.Parent = textContainer

	-- ═══════════════════════════════════════════════════════════
	-- ANIMACIÓN DE ENTRADA
	-- ═══════════════════════════════════════════════════════════
	table.insert(activeAnnouncements, announcement)

	local finalPosition = UDim2.new(0.5, -CFG.WIDTH / 2, 0, yOffset)

	-- Obtener avatar
	task.spawn(function()
		local success, userId = pcall(function()
			local targetPlayer = Players:FindFirstChild(userName)
			if targetPlayer then
				return targetPlayer.UserId
			end
			return Players:GetUserIdFromNameAsync(userName)
		end)

		if success and userId then
			local thumbSuccess, thumb = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)

			if thumbSuccess and avatarImage and avatarImage.Parent then
				avatarImage.Image = thumb
			end
		end
	end)

	-- Estado inicial: transparente y fuera de pantalla
	announcement.BackgroundTransparency = 1
	nameLabel.TextTransparency = 1
	handleLabel.TextTransparency = 1
	messageLabel.TextTransparency = 1
	avatarImage.BackgroundTransparency = 1
	announcement.Position = UDim2.new(0.5, -CFG.WIDTH / 2, 0, -CFG.HEIGHT)

	-- Animar entrada
	TweenService:Create(
		announcement,
		TweenInfo.new(CFG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Position = finalPosition,
			BackgroundTransparency = 0.1
		}
	):Play()

	-- Fade in de textos
	TweenService:Create(nameLabel, TweenInfo.new(CFG.ANIMATION_TIME), { TextTransparency = 0 }):Play()
	TweenService:Create(handleLabel, TweenInfo.new(CFG.ANIMATION_TIME), { TextTransparency = 0 }):Play()
	TweenService:Create(messageLabel, TweenInfo.new(CFG.ANIMATION_TIME), { TextTransparency = 0 }):Play()
	TweenService:Create(avatarImage, TweenInfo.new(CFG.ANIMATION_TIME), { BackgroundTransparency = 0 }):Play()

	repositionAnnouncements(true)

	-- Auto-cerrar
	task.delay(CFG.DURATION, function()
		removeAnnouncement(announcement)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- CONEXIONES
-- ════════════════════════════════════════════════════════════════

localAnnouncement.OnClientEvent:Connect(function(displayName, userName, message)
	if displayName and userName and message then
		createAnnouncement(displayName, userName, message)
	end
end)

m2CooldownNotif.OnClientEvent:Connect(function(remainingTime)
	NotificationSystem:Warning(
		"Cooldown de ;m2",
		string.format("Espera %d segundo%s más", remainingTime, remainingTime == 1 and "" or "s"),
		2
	)
end)

if m2FilterNotif then
	m2FilterNotif.OnClientEvent:Connect(function()
		NotificationSystem:Warning(
			"Mensaje bloqueado",
			"Tu mensaje contiene lenguaje inapropiado.",
			3
		)
	end)
end