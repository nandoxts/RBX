-- LocalAnnouncementClient.lua - LocalScript en StarterGui
-- Muestra anuncios locales apilados (como NotificationSystem)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
-- ESPERAR REMOTES
-- ════════════════════════════════════════════════════════════════
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local messageFolder = RemotesGlobal:WaitForChild("Message")
local localAnnouncement = messageFolder:WaitForChild("LocalAnnouncement")
local m2CooldownNotif = messageFolder:WaitForChild("M2CooldownNotif")

local THEME = require(ReplicatedStorage.Config.ThemeConfig)

-- NotificationSystem para mostrar cooldown
local NotificationSystem = require(ReplicatedStorage.Systems.NotificationSystem.NotificationSystem)

local COLORS = {
	Background = THEME.bg,
	TextPrimary = THEME.text,
	TextSecondary = THEME.muted,
	Border = THEME.stroke,
	Accent = THEME.accent,
}

-- ScreenGui (DisplayOrder igual a announcements pero menos que notifications)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocalAnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 98  -- Debajo de los anuncios globales (99)
screenGui.Parent = playerGui

-- Configuración
local CONFIG = {
	ANNOUNCEMENT_WIDTH = 520,
	ANNOUNCEMENT_HEIGHT = 100,
	SPACING = 8,
	ANIMATION_TIME = 0.4,
	DURATION = 5,  -- Duración en segundos antes de desaparecer
	MAX_ANNOUNCEMENTS = 5,
	CORNER_RADIUS = 15,
	START_Y = 20
}

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

-- Reposicionar anuncios cuando uno se cierra
local function repositionAnnouncements(skipLast)
	local yOffset = CONFIG.START_Y

	for i = 1, #activeAnnouncements do
		local announcement = activeAnnouncements[i]
		if announcement and announcement.Parent then
			local targetPos = UDim2.new(0.5, -CONFIG.ANNOUNCEMENT_WIDTH/2, 0, yOffset)

			if not (skipLast and i == #activeAnnouncements) then
				TweenService:Create(announcement, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = targetPos
				}):Play()
			else
				announcement.Position = targetPos
			end

			yOffset = yOffset + CONFIG.ANNOUNCEMENT_HEIGHT + CONFIG.SPACING
		end
	end
end

-- Remover anuncio con animación (desaparece hacia ARRIBA como NotificationSystem)
local function removeAnnouncement(announcement)
	-- Encontrar índice
	local index = table.find(activeAnnouncements, announcement)
	if index then
		table.remove(activeAnnouncements, index)
	end

	-- Animar cierre hacia ARRIBA (igual que NotificationSystem)
	local tween = TweenService:Create(
		announcement, 
		TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In), 
		{
			Position = UDim2.new(0.5, -CONFIG.ANNOUNCEMENT_WIDTH/2, 0, -CONFIG.ANNOUNCEMENT_HEIGHT - 20),
			BackgroundTransparency = 1
		}
	)

	tween.Completed:Connect(function()
		announcement:Destroy()
		repositionAnnouncements()
	end)

	-- Fade out de todos los elementos
	for _, child in ipairs(announcement:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				TextTransparency = 1
			}):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				BackgroundTransparency = 1
			}):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				Transparency = 1
			}):Play()
		end
	end

	tween:Play()
end

-- ════════════════════════════════════════════════════════════════
-- Crear Anuncio
-- ════════════════════════════════════════════════════════════════
local function createAnnouncement(senderName, message)
	if #activeAnnouncements >= CONFIG.MAX_ANNOUNCEMENTS then
		removeAnnouncement(activeAnnouncements[1])
	end

	-- Calcular posición Y
	local yOffset = CONFIG.START_Y
	for _ = 1, #activeAnnouncements do
		yOffset = yOffset + CONFIG.ANNOUNCEMENT_HEIGHT + CONFIG.SPACING
	end

	-- ═══════════════════════════════════════════════════════════
	-- FRAME PRINCIPAL
	-- ═══════════════════════════════════════════════════════════
	local announcement = Instance.new("Frame")
	announcement.Name = "LocalAnnouncement_" .. #activeAnnouncements
	announcement.Size = UDim2.new(0, CONFIG.ANNOUNCEMENT_WIDTH, 0, CONFIG.ANNOUNCEMENT_HEIGHT)
	announcement.Position = UDim2.new(0.5, -CONFIG.ANNOUNCEMENT_WIDTH/2, 0, yOffset - 100)  -- Inicia fuera de pantalla
	announcement.AnchorPoint = Vector2.new(0, 0)
	announcement.BackgroundColor3 = COLORS.Background
	announcement.BackgroundTransparency = 0.1
	announcement.BorderSizePixel = 0
	announcement.ZIndex = 100
	announcement.Parent = screenGui

	rounded(announcement, CONFIG.CORNER_RADIUS)
	stroked(announcement, COLORS.Border, 1.5, 0.3)

	-- ═══════════════════════════════════════════════════════════
	-- AVATAR CIRCULAR
	-- ═══════════════════════════════════════════════════════════
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.new(0, 60, 0, 60)
	avatarImage.Position = UDim2.new(0, 10, 0.5, 0)
	avatarImage.AnchorPoint = Vector2.new(0, 0.5)
	avatarImage.BackgroundColor3 = COLORS.Background
	avatarImage.BorderSizePixel = 0
	avatarImage.Image = ""
	avatarImage.ZIndex = 101
	avatarImage.Parent = announcement

	rounded(avatarImage, 30)  -- Circular
	stroked(avatarImage, COLORS.Border, 1.5, 0.2)

	-- ═══════════════════════════════════════════════════════════
	-- CONTENEDOR DE TEXTO
	-- ═══════════════════════════════════════════════════════════
	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Size = UDim2.new(1, -95, 1, -12)
	textContainer.Position = UDim2.new(0, 85, 0, 8)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 101
	textContainer.Parent = announcement

	-- Contenedor de nombre y username (lado a lado)
	local nameHandleContainer = Instance.new("Frame")
	nameHandleContainer.Name = "NameHandleContainer"
	nameHandleContainer.Size = UDim2.new(1, 0, 0, 18)
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

	-- Nombre del remitente
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "SenderName"
	nameLabel.Size = UDim2.new(0, 0, 0, 16)
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = senderName
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.Accent
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.LayoutOrder = 1
	nameLabel.ZIndex = 102
	nameLabel.Parent = nameHandleContainer

	-- Username del remitente
	local handleLabel = Instance.new("TextLabel")
	handleLabel.Name = "SenderHandle"
	handleLabel.Size = UDim2.new(0, 0, 0, 14)
	handleLabel.AutomaticSize = Enum.AutomaticSize.X
	handleLabel.BackgroundTransparency = 1
	handleLabel.Text = "@usuario"
	handleLabel.TextSize = 14
	handleLabel.Font = Enum.Font.GothamBold
	handleLabel.TextColor3 = COLORS.Accent
	handleLabel.TextXAlignment = Enum.TextXAlignment.Left
	handleLabel.LayoutOrder = 2
	handleLabel.ZIndex = 102
	handleLabel.Parent = nameHandleContainer

	-- Mensaje
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, 0, 1, -24)
	messageLabel.Position = UDim2.new(0, 0, 0, 20)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextSize = 17
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

	-- Calcular posición final antes de animar
	local finalPosition = UDim2.new(0.5, -CONFIG.ANNOUNCEMENT_WIDTH/2, 0, yOffset)

	-- Obtener avatar y username del remitente
	task.spawn(function()
		local success, userId = pcall(function()
			local targetPlayer = Players:FindFirstChild(senderName)
			if targetPlayer then
				return targetPlayer.UserId
			end
			return Players:GetUserIdFromNameAsync(senderName)
		end)

		if success and userId then
			-- Obtener username/handle
			local handleSuccess, handleName = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			
			if handleSuccess and handleName then
				if handleLabel and handleLabel.Parent then
					handleLabel.Text = "@" .. handleName
				end
			end
			
			-- Obtener avatar
			local thumbSuccess, thumb = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)

			if thumbSuccess and avatarImage and avatarImage.Parent then
				avatarImage.Image = thumb
			end
		end
	end)

	-- Inicial: transparente y fuera de pantalla (arriba)
	announcement.BackgroundTransparency = 1
	nameLabel.TextTransparency = 1
	messageLabel.TextTransparency = 1
	avatarImage.BackgroundTransparency = 1
	announcement.Position = UDim2.new(0.5, -CONFIG.ANNOUNCEMENT_WIDTH/2, 0, -CONFIG.ANNOUNCEMENT_HEIGHT)

	-- Animar entrada (hacia abajo)
	local tweenIn = TweenService:Create(
		announcement,
		TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Position = finalPosition,
			BackgroundTransparency = 0.1
		}
	)

	tweenIn:Play()

	-- Fade in de textos
	TweenService:Create(nameLabel, TweenInfo.new(CONFIG.ANIMATION_TIME), {
		TextTransparency = 0
	}):Play()

	TweenService:Create(messageLabel, TweenInfo.new(CONFIG.ANIMATION_TIME), {
		TextTransparency = 0
	}):Play()

	TweenService:Create(avatarImage, TweenInfo.new(CONFIG.ANIMATION_TIME), {
		BackgroundTransparency = 0
	}):Play()

	repositionAnnouncements(true)

	-- Auto-cerrar después de la duración
	task.delay(CONFIG.DURATION, function()
		removeAnnouncement(announcement)
	end)
end

-- Conectar al evento
localAnnouncement.OnClientEvent:Connect(function(senderName, message)
	if senderName and message then
		createAnnouncement(senderName, message)
	end
end)

-- Mostrar notificación de cooldown del ;m2
m2CooldownNotif.OnClientEvent:Connect(function(remainingTime)
	NotificationSystem:Warning(
		"Cooldown de ;m2",
		string.format("Espera %d segundo%s más", remainingTime, remainingTime == 1 and "" or "s"),
		2
	)
end)
