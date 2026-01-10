-- ════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM - Sistema de Notificaciones Profesional
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
POSITION_START = UDim2.new(0.5, 0, 0, 20),  -- Arriba centro
NOTIFICATION_WIDTH = 380,
NOTIFICATION_HEIGHT = 85,
SPACING = 12,
DURATION_SHORT = 3,
DURATION_MEDIUM = 5,
DURATION_LONG = 8,
ANIMATION_TIME = 0.4,
MAX_NOTIFICATIONS = 5
}

-- ════════════════════════════════════════════════════════════════
-- TIPOS DE NOTIFICACIONES - Diseño Moderno y Profesional
-- ════════════════════════════════════════════════════════════════
local NOTIFICATION_TYPES = {
	success = {
		icon = "✅",
		color = Color3.fromRGB(16, 185, 129),        -- Verde moderno esmeralda
		bgColor = Color3.fromRGB(6, 78, 59),         -- Fondo oscuro profesional
		borderColor = Color3.fromRGB(16, 185, 129),
		glowColor = Color3.fromRGB(16, 185, 129),
		sound = "rbxassetid://6026984224"
	},
	error = {
		icon = "❌",
		color = Color3.fromRGB(239, 68, 68),         -- Rojo moderno suave
		bgColor = Color3.fromRGB(87, 13, 13),        -- Fondo oscuro elegante
		borderColor = Color3.fromRGB(239, 68, 68),
		glowColor = Color3.fromRGB(239, 68, 68),
		sound = "rbxassetid://6026984224"
	},
	warning = {
		icon = "⚠️",
		color = Color3.fromRGB(251, 191, 36),        -- Amarillo ámbar profesional
		bgColor = Color3.fromRGB(78, 63, 14),        -- Fondo oscuro cálido
		borderColor = Color3.fromRGB(251, 191, 36),
		glowColor = Color3.fromRGB(251, 191, 36),
		sound = "rbxassetid://6026984224"
	},
	info = {
		icon = "ℹ️",
		color = Color3.fromRGB(59, 130, 246),        -- Azul moderno claro
		bgColor = Color3.fromRGB(17, 44, 83),        -- Fondo oscuro profundo
		borderColor = Color3.fromRGB(59, 130, 246),
		glowColor = Color3.fromRGB(59, 130, 246),
		sound = "rbxassetid://6026984224"
	},
	clan = {
		icon = "⚔️",
		color = Color3.fromRGB(168, 85, 247),        -- Púrpura moderno vibrante
		bgColor = Color3.fromRGB(66, 33, 99),        -- Fondo oscuro místico
		borderColor = Color3.fromRGB(168, 85, 247),
		glowColor = Color3.fromRGB(168, 85, 247),
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

local function stroked(inst, color, thickness)
local s = Instance.new("UIStroke")
s.Color = color
s.Thickness = thickness or 1.5
s.Transparency = 0
s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
s.Parent = inst
return s
end

-- ════════════════════════════════════════════════════════════════
-- REPOSICIONAR NOTIFICACIONES
-- ════════════════════════════════════════════════════════════════
local function repositionNotifications(skipFirst)
	local yOffset = 20  -- Comienza desde arriba

	for i = 1, #NotificationSystem.activeNotifications do
		local notif = NotificationSystem.activeNotifications[i]
		if notif and notif.Parent then
			local targetPos = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, yOffset)

			-- Si es la primera notificación y skipFirst es true, no la animes (ya está en su posición)
			if not (skipFirst and i == #NotificationSystem.activeNotifications) then
				TweenService:Create(notif, TweenInfo.new(CONFIG.ANIMATION_TIME * 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
	-- Animación de salida: se desliza hacia la derecha y se desvanece
	local currentPos = notification.Position
	local tweenOut = TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + 500, currentPos.Y.Scale, currentPos.Y.Offset),
		BackgroundTransparency = 1
	})

tweenOut.Completed:Connect(function()
-- Remover de la lista activa
for i, notif in ipairs(NotificationSystem.activeNotifications) do
if notif == notification then
table.remove(NotificationSystem.activeNotifications, i)
break
end
end

notification:Destroy()
repositionNotifications()
end)

-- Hacer transparentes todos los hijos también
for _, child in ipairs(notification:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				BackgroundTransparency = 1,
				TextTransparency = 1
			}):Play()
		elseif child:IsA("ImageLabel") then
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				BackgroundTransparency = 1,
				ImageTransparency = 1
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

	-- Opciones por defecto
	options = options or {}
	local title = options.title or "Notificación"
	local message = options.message or ""
	local type = options.type or "info"
	local duration = options.duration or CONFIG.DURATION_MEDIUM
	local onClick = options.onClick

-- Limitar cantidad de notificaciones
if #NotificationSystem.activeNotifications >= CONFIG.MAX_NOTIFICATIONS then
removeNotification(NotificationSystem.activeNotifications[1])
end

-- Obtener configuración del tipo
local typeConfig = NOTIFICATION_TYPES[type] or NOTIFICATION_TYPES.info

-- Crear ID único
NotificationSystem.notificationId = NotificationSystem.notificationId + 1
local notifId = "Notification_" .. NotificationSystem.notificationId

-- Buscar o crear ScreenGui
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

	-- Calcular posición final para la nueva notificación
	local finalPosition = calculateNewNotificationPosition()

	-- Crear frame de notificación
	local notification = Instance.new("Frame")
	notification.Name = notifId
	notification.Size = UDim2.new(0, CONFIG.NOTIFICATION_WIDTH, 0, CONFIG.NOTIFICATION_HEIGHT)
	notification.Position = finalPosition
	notification.BackgroundColor3 = Color3.fromRGB(20, 24, 32)  -- Fondo oscuro moderno
	notification.BackgroundTransparency = 0.15  -- Glassmorphism sutil
	notification.BorderSizePixel = 0
	notification.ZIndex = 100
	notification.ClipsDescendants = true  -- IMPORTANTE: Evita que la barra salga
	notification.AnchorPoint = Vector2.new(0, 0)
	notification.Parent = screenGui

	rounded(notification, 12)
	stroked(notification, typeConfig.borderColor, 1.5)
	
	-- Gradiente moderno diagonal
	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 30, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 25))
	}
	bgGradient.Rotation = 135
	bgGradient.Parent = notification

	-- Sombra profesional
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Size = UDim2.new(1, 40, 1, 40)
	shadow.ZIndex = 99
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.3
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = notification

	-- Barra de progreso inferior (sin contenedor adicional - método limpio)
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 0, 3)
	progressBar.Position = UDim2.new(0, 0, 1, -3)
	progressBar.BackgroundColor3 = typeConfig.color
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 101
	progressBar.Parent = notification
	
	-- Gradiente horizontal para efecto moderno
	local progressGlow = Instance.new("UIGradient")
	progressGlow.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, typeConfig.color),
		ColorSequenceKeypoint.new(0.5, Color3.new(
			math.min(typeConfig.color.R * 1.2, 1),
			math.min(typeConfig.color.G * 1.2, 1),
			math.min(typeConfig.color.B * 1.2, 1)
		)),
		ColorSequenceKeypoint.new(1, typeConfig.color)
	}
	progressGlow.Rotation = 0
	progressGlow.Parent = progressBar
	
	-- Icono con efecto glow moderno
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(0, 48, 0, 48)
	iconContainer.Position = UDim2.new(0, 14, 0.5, -24)
	iconContainer.BackgroundColor3 = typeConfig.bgColor
	iconContainer.BackgroundTransparency = 0.2
	iconContainer.BorderSizePixel = 0
	iconContainer.ZIndex = 101
	iconContainer.Parent = notification
	rounded(iconContainer, 10)
	
	-- Borde sutil del icono
	stroked(iconContainer, typeConfig.borderColor, 1)

	-- Gradiente moderno en el icono
	local iconGradient = Instance.new("UIGradient")
	iconGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(
			typeConfig.bgColor.R * 1.2,
			typeConfig.bgColor.G * 1.2,
			typeConfig.bgColor.B * 1.2
		)),
		ColorSequenceKeypoint.new(1, typeConfig.bgColor)
	}
	iconGradient.Rotation = 135
	iconGradient.Parent = iconContainer
	
	-- Emoji/Icono de texto (más grande y profesional)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = typeConfig.icon
	icon.TextColor3 = typeConfig.color
	icon.TextSize = 28
	icon.Font = Enum.Font.GothamBold
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.ZIndex = 102
	icon.Parent = iconContainer

	-- Contenedor de texto
	local textContainer = Instance.new("Frame")
	textContainer.Size = UDim2.new(1, -120, 1, -10)
	textContainer.Position = UDim2.new(0, 72, 0, 8)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 101
	textContainer.Parent = notification

	-- Título moderno
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.Position = UDim2.new(0, 0, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 102
	titleLabel.Parent = textContainer

	-- Mensaje con mejor contraste
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, 0, 0, 40)
	messageLabel.Position = UDim2.new(0, 0, 0, 32)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
	messageLabel.TextSize = 13
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
	messageLabel.ZIndex = 102
	messageLabel.Parent = textContainer
	-- Botón cerrar moderno
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
	closeBtn.BackgroundTransparency = 0.5
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "×"  -- Símbolo × más elegante
	closeBtn.TextColor3 = Color3.fromRGB(160, 165, 175)
	closeBtn.TextSize = 22
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.ZIndex = 103
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = notification
	rounded(closeBtn, 8)

	-- Hover effect moderno
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(220, 38, 38),
			BackgroundTransparency = 0
		}):Play()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {
			TextColor3 = Color3.new(1, 1, 1)
		}):Play()
	end)

	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(40, 45, 55),
			BackgroundTransparency = 0.5
		}):Play()
		TweenService:Create(closeBtn, TweenInfo.new(0.2), {
			TextColor3 = Color3.fromRGB(160, 165, 175)
		}):Play()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		removeNotification(notification)
	end)

	-- Hacer clickeable toda la notificación si hay onClick
	if onClick then
		local clickButton = Instance.new("TextButton")
		clickButton.Size = UDim2.new(1, -50, 1, 0)
		clickButton.Position = UDim2.new(0, 0, 0, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 100
		clickButton.AutoButtonColor = false
		clickButton.Parent = notification

		clickButton.MouseButton1Click:Connect(function()
			onClick()
			removeNotification(notification)
		end)

		-- Hover effect moderno
		clickButton.MouseEnter:Connect(function()
			TweenService:Create(notification, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(30, 36, 48)
			}):Play()
		end)

		clickButton.MouseLeave:Connect(function()
			TweenService:Create(notification, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(20, 24, 32)
			}):Play()
		end)
	end
	
	-- Reproducir sonido si está configurado
	if typeConfig.sound and typeConfig.sound ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = typeConfig.sound
		sound.Volume = 0.5
		sound.Parent = notification
		sound:Play()
		
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	table.insert(NotificationSystem.activeNotifications, notification)

	-- Animación de entrada: fade-in con un pequeño efecto de escala
	notification.Size = UDim2.new(0, CONFIG.NOTIFICATION_WIDTH * 0.95, 0, CONFIG.NOTIFICATION_HEIGHT * 0.95)
	
	local tweenIn = TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, CONFIG.NOTIFICATION_WIDTH, 0, CONFIG.NOTIFICATION_HEIGHT)
	})
	tweenIn:Play()
	
	-- Animar también la transparencia de todos los elementos hijos
	for _, child in ipairs(notification:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				TextTransparency = 0
			}):Play()
		elseif child:IsA("ImageLabel") and child.Name ~= "Shadow" then
			child.ImageTransparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				ImageTransparency = 0
			}):Play()
		elseif child:IsA("Frame") and child.Name ~= "Shadow" then
			if child.BackgroundTransparency < 1 then
				local originalTransparency = child.BackgroundTransparency
				child.BackgroundTransparency = 1
				TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
					BackgroundTransparency = originalTransparency
				}):Play()
			end
		elseif child:IsA("UIStroke") then
			child.Transparency = 1
			TweenService:Create(child, TweenInfo.new(CONFIG.ANIMATION_TIME), {
				Transparency = 0
			}):Play()
		end
	end

	-- Reposicionar todas las demás notificaciones (excepto la nueva)
	repositionNotifications(true)

	-- Auto-cerrar después de la duración
	if duration > 0 then
		task.delay(duration, function()
			if notification and notification.Parent then
				removeNotification(notification)
			end
		end)

		-- Animar la barra de progreso (reducción limpia)
		task.spawn(function()
			local startTime = tick()
			while notification and notification.Parent and (tick() - startTime) < duration do
				local progress = (tick() - startTime) / duration
				-- La barra se reduce de izquierda a derecha usando AnchorPoint
				progressBar.Size = UDim2.new(1 - progress, 0, 0, 3)
				task.wait(0.03)
			end
		end)
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
-- LIMPIAR TODAS LAS NOTIFICACIONES
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
