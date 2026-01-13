-- ════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM - Diseño Profesional v2
-- Compatible con ThemeConfig
-- ════════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local NotificationSystem = {}
NotificationSystem.activeNotifications = {}
NotificationSystem.notificationId = 0

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════
local CONFIG = {
	NOTIFICATION_WIDTH = 340,
	NOTIFICATION_HEIGHT = 78,
	SPACING = 10,
	DURATION_SHORT = 3,
	DURATION_MEDIUM = 5,
	DURATION_LONG = 8,
	ANIMATION_TIME = 0.35,
	MAX_NOTIFICATIONS = 5,
	CORNER_RADIUS = 10,
	PROGRESS_BAR_HEIGHT = 2
}

-- ════════════════════════════════════════════════════════════════
-- TIPOS DE NOTIFICACIONES (sin emojis)
-- ════════════════════════════════════════════════════════════════
local NOTIFICATION_TYPES = {
	success = {
		iconType = "checkmark",
		accentColor = Color3.fromRGB(34, 197, 94),
		accentColorDark = Color3.fromRGB(22, 101, 52),
		sound = "rbxassetid://6026984224"
	},
	error = {
		iconType = "cross",
		accentColor = Color3.fromRGB(239, 68, 68),
		accentColorDark = Color3.fromRGB(127, 29, 29),
		sound = "rbxassetid://6026984224"
	},
	warning = {
		iconType = "exclamation",
		accentColor = Color3.fromRGB(251, 191, 36),
		accentColorDark = Color3.fromRGB(133, 77, 14),
		sound = "rbxassetid://6026984224"
	},
	info = {
		iconType = "info",
		accentColor = Color3.fromRGB(59, 130, 246),
		accentColorDark = Color3.fromRGB(30, 64, 175),
		sound = "rbxassetid://6026984224"
	},
	clan = {
		iconType = "shield",
		accentColor = Color3.fromRGB(168, 85, 247),
		accentColorDark = Color3.fromRGB(88, 28, 135),
		sound = "rbxassetid://6026984224"
	}
}

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ════════════════════════════════════════════════════════════════
local function rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function stroked(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

-- ════════════════════════════════════════════════════════════════
-- CREAR ICONOS GEOMÉTRICOS
-- ════════════════════════════════════════════════════════════════
local function createIcon(parent, iconType, color)
	local container = Instance.new("Frame")
	container.Name = "IconContainer"
	container.Size = UDim2.new(0, 38, 0, 38)
	container.Position = UDim2.new(0, 16, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundColor3 = color
	container.BackgroundTransparency = 0.85
	container.BorderSizePixel = 0
	container.ZIndex = 101
	container.Parent = parent
	rounded(container, 8)

	if iconType == "checkmark" then
		-- Checkmark usando frames
		local line1 = Instance.new("Frame")
		line1.Size = UDim2.new(0, 8, 0, 2)
		line1.Position = UDim2.new(0.5, -6, 0.5, 2)
		line1.AnchorPoint = Vector2.new(0, 0.5)
		line1.Rotation = 45
		line1.BackgroundColor3 = color
		line1.BorderSizePixel = 0
		line1.ZIndex = 102
		line1.Parent = container
		rounded(line1, 1)

		local line2 = Instance.new("Frame")
		line2.Size = UDim2.new(0, 14, 0, 2)
		line2.Position = UDim2.new(0.5, -2, 0.5, 0)
		line2.AnchorPoint = Vector2.new(0, 0.5)
		line2.Rotation = -45
		line2.BackgroundColor3 = color
		line2.BorderSizePixel = 0
		line2.ZIndex = 102
		line2.Parent = container
		rounded(line2, 1)

	elseif iconType == "cross" then
		-- X usando frames
		local line1 = Instance.new("Frame")
		line1.Size = UDim2.new(0, 16, 0, 2)
		line1.Position = UDim2.new(0.5, 0, 0.5, 0)
		line1.AnchorPoint = Vector2.new(0.5, 0.5)
		line1.Rotation = 45
		line1.BackgroundColor3 = color
		line1.BorderSizePixel = 0
		line1.ZIndex = 102
		line1.Parent = container
		rounded(line1, 1)

		local line2 = Instance.new("Frame")
		line2.Size = UDim2.new(0, 16, 0, 2)
		line2.Position = UDim2.new(0.5, 0, 0.5, 0)
		line2.AnchorPoint = Vector2.new(0.5, 0.5)
		line2.Rotation = -45
		line2.BackgroundColor3 = color
		line2.BorderSizePixel = 0
		line2.ZIndex = 102
		line2.Parent = container
		rounded(line2, 1)

	elseif iconType == "exclamation" then
		-- ! usando frames
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 3, 0, 14)
		line.Position = UDim2.new(0.5, 0, 0.5, -4)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = color
		line.BorderSizePixel = 0
		line.ZIndex = 102
		line.Parent = container
		rounded(line, 1)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 3, 0, 3)
		dot.Position = UDim2.new(0.5, 0, 0.5, 10)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = 102
		dot.Parent = container
		rounded(dot, 2)

	elseif iconType == "info" then
		-- i usando frames
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 3, 0, 3)
		dot.Position = UDim2.new(0.5, 0, 0.5, -8)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = color
		dot.BorderSizePixel = 0
		dot.ZIndex = 102
		dot.Parent = container
		rounded(dot, 2)

		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 3, 0, 12)
		line.Position = UDim2.new(0.5, 0, 0.5, 4)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = color
		line.BorderSizePixel = 0
		line.ZIndex = 102
		line.Parent = container
		rounded(line, 1)

	elseif iconType == "shield" then
		-- Escudo simplificado
		local shield = Instance.new("Frame")
		shield.Size = UDim2.new(0, 14, 0, 16)
		shield.Position = UDim2.new(0.5, 0, 0.5, -1)
		shield.AnchorPoint = Vector2.new(0.5, 0.5)
		shield.BackgroundColor3 = color
		shield.BackgroundTransparency = 0.3
		shield.BorderSizePixel = 0
		shield.ZIndex = 102
		shield.Parent = container
		rounded(shield, 3)
		stroked(shield, color, 2)

		-- Detalle interior
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(0, 6, 0, 6)
		inner.Position = UDim2.new(0.5, 0, 0.4, 0)
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.BackgroundColor3 = color
		inner.BorderSizePixel = 0
		inner.ZIndex = 103
		inner.Parent = container
		rounded(inner, 2)
	end

	return container
end

-- ════════════════════════════════════════════════════════════════
-- REPOSICIONAR NOTIFICACIONES
-- ════════════════════════════════════════════════════════════════
local function repositionNotifications(skipLast)
	local yOffset = 20

	for i = 1, #NotificationSystem.activeNotifications do
		local notif = NotificationSystem.activeNotifications[i]
		if notif and notif.Parent then
			local targetPos = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, yOffset)

			if not (skipLast and i == #NotificationSystem.activeNotifications) then
				TweenService:Create(notif, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = targetPos
				}):Play()
			else
				notif.Position = targetPos
			end

			yOffset = yOffset + CONFIG.NOTIFICATION_HEIGHT + CONFIG.SPACING
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- CALCULAR POSICIÓN PARA NUEVA NOTIFICACIÓN
-- ════════════════════════════════════════════════════════════════
local function calculateNewNotificationPosition()
	local yOffset = 20
	for i = 1, #NotificationSystem.activeNotifications do
		yOffset = yOffset + CONFIG.NOTIFICATION_HEIGHT + CONFIG.SPACING
	end
	return UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, yOffset)
end

-- ════════════════════════════════════════════════════════════════
-- REMOVER NOTIFICACIÓN
-- ════════════════════════════════════════════════════════════════
local function removeNotification(notification)
	local currentPos = notification.Position
	local tweenOut = TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, 0, -CONFIG.NOTIFICATION_HEIGHT - 20),
		BackgroundTransparency = 1
	})

	tweenOut.Completed:Connect(function()
		for i, notif in ipairs(NotificationSystem.activeNotifications) do
			if notif == notification then
				table.remove(NotificationSystem.activeNotifications, i)
				break
			end
		end

		notification:Destroy()
		repositionNotifications(false)
	end)

	for _, child in ipairs(notification:GetDescendants()) do
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

	tweenOut:Play()
end

-- ════════════════════════════════════════════════════════════════
-- CREAR NOTIFICACIÓN
-- ════════════════════════════════════════════════════════════════
function NotificationSystem:Notify(options)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	options = options or {}
	local title = options.title or "Notificación"
	local message = options.message or ""
	local notifType = options.type or "info"
	local duration = options.duration or CONFIG.DURATION_MEDIUM
	local onClick = options.onClick

	if #NotificationSystem.activeNotifications >= CONFIG.MAX_NOTIFICATIONS then
		removeNotification(NotificationSystem.activeNotifications[1])
	end

	local typeConfig = NOTIFICATION_TYPES[notifType] or NOTIFICATION_TYPES.info

	NotificationSystem.notificationId = NotificationSystem.notificationId + 1
	local notifId = "Notification_" .. NotificationSystem.notificationId

	local screenGui = playerGui:FindFirstChild("NotificationSystemGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NotificationSystemGui"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.DisplayOrder = 100
		screenGui.Parent = playerGui
	end

	local finalPosition = calculateNewNotificationPosition()

	-- ═══════════════════════════════════════════════════════════
	-- FRAME PRINCIPAL
	-- ═══════════════════════════════════════════════════════════
	local notification = Instance.new("Frame")
	notification.Name = notifId
	notification.Size = UDim2.new(0, CONFIG.NOTIFICATION_WIDTH, 0, CONFIG.NOTIFICATION_HEIGHT)
	notification.Position = finalPosition
	notification.BackgroundColor3 = THEME.bg
	notification.BackgroundTransparency = 0.05
	notification.BorderSizePixel = 0
	notification.ZIndex = 100
	notification.ClipsDescendants = true
	notification.Parent = screenGui

	rounded(notification, CONFIG.CORNER_RADIUS)
	stroked(notification, Color3.fromRGB(255, 255, 255), 1, 0.92)

	-- ═══════════════════════════════════════════════════════════
	-- BARRA DE PROGRESO INFERIOR
	-- ═══════════════════════════════════════════════════════════
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.Size = UDim2.new(1, -24, 0, CONFIG.PROGRESS_BAR_HEIGHT)
	progressContainer.Position = UDim2.new(0, 12, 1, -8)
	progressContainer.AnchorPoint = Vector2.new(0, 1)
	progressContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	progressContainer.BackgroundTransparency = 0.9
	progressContainer.BorderSizePixel = 0
	progressContainer.ZIndex = 101
	progressContainer.Parent = notification
	rounded(progressContainer, 1)

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = typeConfig.accentColor
	progressBar.BackgroundTransparency = 0.3
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 102
	progressBar.Parent = progressContainer
	rounded(progressBar, 1)

	-- ═══════════════════════════════════════════════════════════
	-- ICONO
	-- ═══════════════════════════════════════════════════════════
	createIcon(notification, typeConfig.iconType, typeConfig.accentColor)

	-- ═══════════════════════════════════════════════════════════
	-- TEXTO
	-- ═══════════════════════════════════════════════════════════
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 0, 18)
	titleLabel.Position = UDim2.new(0, 64, 0, 14)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 102
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -100, 0, 30)
	messageLabel.Position = UDim2.new(0, 64, 0, 34)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(156, 163, 175)
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
	messageLabel.ZIndex = 102
	messageLabel.Parent = notification

	-- ═══════════════════════════════════════════════════════════
	-- BOTÓN CERRAR (más sutil)
	-- ═══════════════════════════════════════════════════════════
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -32, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BackgroundTransparency = 0.95
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = ""
	closeBtn.ZIndex = 103
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = notification
	rounded(closeBtn, 6)

	-- X del botón cerrar usando frames
	local closeLine1 = Instance.new("Frame")
	closeLine1.Size = UDim2.new(0, 10, 0, 1.5)
	closeLine1.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeLine1.AnchorPoint = Vector2.new(0.5, 0.5)
	closeLine1.Rotation = 45
	closeLine1.BackgroundColor3 = Color3.fromRGB(156, 163, 175)
	closeLine1.BorderSizePixel = 0
	closeLine1.ZIndex = 104
	closeLine1.Parent = closeBtn

	local closeLine2 = Instance.new("Frame")
	closeLine2.Size = UDim2.new(0, 10, 0, 1.5)
	closeLine2.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeLine2.AnchorPoint = Vector2.new(0.5, 0.5)
	closeLine2.Rotation = -45
	closeLine2.BackgroundColor3 = Color3.fromRGB(156, 163, 175)
	closeLine2.BorderSizePixel = 0
	closeLine2.ZIndex = 104
	closeLine2.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.85
		}):Play()
		TweenService:Create(closeLine1, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		}):Play()
		TweenService:Create(closeLine2, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		}):Play()
	end)

	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.95
		}):Play()
		TweenService:Create(closeLine1, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(156, 163, 175)
		}):Play()
		TweenService:Create(closeLine2, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(156, 163, 175)
		}):Play()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		removeNotification(notification)
	end)

	-- ═══════════════════════════════════════════════════════════
	-- CLICK EN NOTIFICACIÓN (opcional)
	-- ═══════════════════════════════════════════════════════════
	if onClick then
		local clickButton = Instance.new("TextButton")
		clickButton.Size = UDim2.new(1, -40, 1, 0)
		clickButton.Position = UDim2.new(0, 0, 0, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 100
		clickButton.AutoButtonColor = false
		clickButton.Parent = notification

		clickButton.MouseEnter:Connect(function()
			TweenService:Create(notification, TweenInfo.new(0.15), {
				BackgroundTransparency = 0
			}):Play()
		end)

		clickButton.MouseLeave:Connect(function()
			TweenService:Create(notification, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.05
			}):Play()
		end)

		clickButton.MouseButton1Click:Connect(function()
			onClick()
			removeNotification(notification)
		end)
	end

	-- ═══════════════════════════════════════════════════════════
	-- SONIDO
	-- ═══════════════════════════════════════════════════════════
	if typeConfig.sound and typeConfig.sound ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = typeConfig.sound
		sound.Volume = 0.3
		sound.Parent = notification
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end

	table.insert(NotificationSystem.activeNotifications, notification)

	-- ═══════════════════════════════════════════════════════════
	-- ANIMACIÓN DE ENTRADA (desde arriba)
	-- ═══════════════════════════════════════════════════════════
	local startPos = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, -CONFIG.NOTIFICATION_HEIGHT)
	notification.Position = startPos
	notification.BackgroundTransparency = 1

	TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = finalPosition,
		BackgroundTransparency = 0.05
	}):Play()

	-- Fade in de elementos
	for _, child in ipairs(notification:GetDescendants()) do
		if child:IsA("TextLabel") then
			child.TextTransparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				TextTransparency = 0
			}):Play()
		elseif child:IsA("Frame") and child.Name ~= "ProgressBar" then
			local originalTrans = child.BackgroundTransparency
			child.BackgroundTransparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				BackgroundTransparency = originalTrans
			}):Play()
		elseif child:IsA("UIStroke") then
			local originalTrans = child.Transparency
			child.Transparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				Transparency = originalTrans
			}):Play()
		end
	end

	repositionNotifications(true)

	-- ═══════════════════════════════════════════════════════════
	-- AUTO-CERRAR Y ANIMACIÓN DE BARRA
	-- ═══════════════════════════════════════════════════════════
	if duration > 0 then
		task.delay(duration, function()
			if notification and notification.Parent then
				removeNotification(notification)
			end
		end)

		-- Animación suave de la barra de progreso
		TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		}):Play()
	end

	return notification
end

-- ════════════════════════════════════════════════════════════════
-- ATAJOS RÁPIDOS
-- ════════════════════════════════════════════════════════════════
function NotificationSystem:Success(title, message, duration)
	return self:Notify({
		title = title,
		message = message,
		type = "success",
		duration = duration or CONFIG.DURATION_MEDIUM
	})
end

function NotificationSystem:Error(title, message, duration)
	return self:Notify({
		title = title,
		message = message,
		type = "error",
		duration = duration or CONFIG.DURATION_LONG
	})
end

function NotificationSystem:Warning(title, message, duration)
	return self:Notify({
		title = title,
		message = message,
		type = "warning",
		duration = duration or CONFIG.DURATION_MEDIUM
	})
end

function NotificationSystem:Info(title, message, duration)
	return self:Notify({
		title = title,
		message = message,
		type = "info",
		duration = duration or CONFIG.DURATION_SHORT
	})
end

function NotificationSystem:Clan(title, message, duration, onClick)
	return self:Notify({
		title = title,
		message = message,
		type = "clan",
		duration = duration or CONFIG.DURATION_MEDIUM,
		onClick = onClick
	})
end

-- ════════════════════════════════════════════════════════════════
-- LIMPIAR TODAS
-- ════════════════════════════════════════════════════════════════
function NotificationSystem:ClearAll()
	for _, notif in ipairs(NotificationSystem.activeNotifications) do
		if notif and notif.Parent then
			removeNotification(notif)
		end
	end
	NotificationSystem.activeNotifications = {}
end

return NotificationSystem