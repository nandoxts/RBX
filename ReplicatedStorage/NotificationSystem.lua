-- ════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM - Sistema de Notificaciones Profesional
-- Compatible con ThemeConfig
-- ════════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local THEME = require(script.Parent:WaitForChild("Config"):WaitForChild("ThemeConfig"))

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
-- TIPOS DE NOTIFICACIONES
-- ════════════════════════════════════════════════════════════════
-- Puedes usar texto (emoji) o AssetID de imagen
-- Para imagen: iconImage = "rbxassetid://TUNUMEROID"
local NOTIFICATION_TYPES = {
	success = {
		icon = "✓",
		iconImage = "rbxassetid://3926305904", -- Checkmark circular moderno (✓)
		color = THEME.success,
		bgColor = THEME.successMuted,
		borderColor = THEME.success,
		sound = "rbxassetid://6026984224",
		gradient = true
	},
	error = {
		icon = "✕",
		iconImage = "rbxassetid://3926305904", -- X circular moderno para errores
		color = THEME.warn,
		bgColor = THEME.warnMuted,
		borderColor = THEME.warn,
		sound = "rbxassetid://6026984224",
		gradient = true
	},
	warning = {
		icon = "⚠",
		iconImage = "rbxassetid://3926307971", -- Triángulo de advertencia moderno
		color = Color3.fromRGB(255, 193, 7),
		bgColor = Color3.fromRGB(60, 50, 30),
		borderColor = Color3.fromRGB(255, 193, 7),
		sound = "rbxassetid://6026984224",
		gradient = true
	},
	info = {
		icon = "ℹ",
		iconImage = "rbxassetid://3926305904", -- Info circular moderno (i)
		color = THEME.info,
		bgColor = THEME.infoMuted,
		borderColor = THEME.info,
		sound = "rbxassetid://6026984224",
		gradient = true
	},
	clan = {
		icon = "⚔",
		iconImage = "rbxassetid://3926305904", -- Escudo/estrella moderno para clan
		color = THEME.accent,
		bgColor = THEME.accentMuted,
		borderColor = THEME.accent,
		sound = "rbxassetid://6026984224",
		gradient = true
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
local function repositionNotifications()
	local yOffset = 20  -- Comienza desde arriba

	for i = 1, #NotificationSystem.activeNotifications do
		local notif = NotificationSystem.activeNotifications[i]
		if notif and notif.Parent then
			local targetPos = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, yOffset)

			TweenService:Create(notif, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = targetPos
			}):Play()

			yOffset = yOffset + CONFIG.NOTIFICATION_HEIGHT + CONFIG.SPACING
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- REMOVER NOTIFICACIÓN
-- ════════════════════════════════════════════════════════════════
local function removeNotification(notification)
-- Animación de salida
	local tweenOut = TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, -CONFIG.NOTIFICATION_HEIGHT - 20),  -- Sale hacia arriba
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

	-- Crear frame de notificación
	local notification = Instance.new("Frame")
	notification.Name = notifId
	notification.Size = UDim2.new(0, CONFIG.NOTIFICATION_WIDTH, 0, CONFIG.NOTIFICATION_HEIGHT)
	notification.Position = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, -CONFIG.NOTIFICATION_HEIGHT)  -- Arriba fuera de pantalla
	notification.BackgroundColor3 = THEME.panel
	notification.BorderSizePixel = 0
	notification.ZIndex = 100
	notification.ClipsDescendants = false
	notification.AnchorPoint = Vector2.new(0, 0)
	notification.Parent = screenGui

rounded(notification, 10)
stroked(notification, typeConfig.borderColor, 2)	
	-- Gradiente sutil en el fondo
	if typeConfig.gradient then
		local bgGradient = Instance.new("UIGradient")
		bgGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, THEME.panel),
			ColorSequenceKeypoint.new(1, Color3.new(
				THEME.panel.R * 0.9,
				THEME.panel.G * 0.9,
				THEME.panel.B * 0.9
			))
		}
		bgGradient.Rotation = 90
		bgGradient.Transparency = NumberSequence.new(0)
		bgGradient.Parent = notification
	end
-- Sombra
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = 99
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.Parent = notification

-- Barra de progreso (izquierda)
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 4, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = typeConfig.color
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 101
progressBar.Parent = notification

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = progressBar

-- Icono
local iconContainer = Instance.new("Frame")
iconContainer.Size = UDim2.new(0, 40, 0, 40)
iconContainer.Position = UDim2.new(0, 15, 0.5, -20)
iconContainer.BackgroundColor3 = typeConfig.bgColor
iconContainer.BorderSizePixel = 0
iconContainer.ZIndex = 101
iconContainer.Parent = notification
rounded(iconContainer, 8)

	-- Gradiente en el icono si está habilitado
	if typeConfig.gradient then
		local iconGradient = Instance.new("UIGradient")
		iconGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, typeConfig.bgColor),
			ColorSequenceKeypoint.new(1, Color3.new(
				typeConfig.bgColor.R * 0.7,
				typeConfig.bgColor.G * 0.7,
				typeConfig.bgColor.B * 0.7
			))
		}
		iconGradient.Rotation = 45
		iconGradient.Parent = iconContainer
	end
	
	-- Usar imagen o texto según configuración
	if typeConfig.iconImage and typeConfig.iconImage ~= "" then
		-- Icono personalizado (imagen)
		local iconImage = Instance.new("ImageLabel")
		iconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
		iconImage.Position = UDim2.new(0.15, 0, 0.15, 0)
		iconImage.BackgroundTransparency = 1
		iconImage.Image = typeConfig.iconImage
		iconImage.ImageColor3 = typeConfig.color
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.ZIndex = 102
		iconImage.Parent = iconContainer
	else
		-- Icono de texto (emoji)
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = typeConfig.icon
		icon.TextColor3 = typeConfig.color
		icon.TextSize = 20
		icon.Font = Enum.Font.GothamBold
		icon.ZIndex = 102
		icon.Parent = iconContainer
	end

-- Contenedor de texto
local textContainer = Instance.new("Frame")
textContainer.Size = UDim2.new(1, -120, 1, -16)
textContainer.Position = UDim2.new(0, 65, 0, 8)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 101
textContainer.Parent = notification

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 20)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = title
titleLabel.TextColor3 = THEME.text
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
titleLabel.ZIndex = 102
titleLabel.Parent = textContainer

-- Mensaje
local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, 0, 0, 36)
messageLabel.Position = UDim2.new(0, 0, 0, 32)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = message
messageLabel.TextColor3 = THEME.muted
messageLabel.TextSize = 12
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextWrapped = true
messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
messageLabel.ZIndex = 102
messageLabel.Parent = textContainer

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 8)
closeBtn.BackgroundColor3 = THEME.surface
closeBtn.BackgroundTransparency = 0.5
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.muted
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 103
closeBtn.AutoButtonColor = false
closeBtn.Parent = notification
rounded(closeBtn, 6)

-- Hover effect para close button
closeBtn.MouseEnter:Connect(function()
TweenService:Create(closeBtn, TweenInfo.new(0.2), {
BackgroundColor3 = THEME.btnDanger,
BackgroundTransparency = 0
}):Play()
TweenService:Create(closeBtn, TweenInfo.new(0.2), {
TextColor3 = Color3.new(1, 1, 1)
}):Play()
end)

closeBtn.MouseLeave:Connect(function()
TweenService:Create(closeBtn, TweenInfo.new(0.2), {
BackgroundColor3 = THEME.surface,
BackgroundTransparency = 0.5
}):Play()
TweenService:Create(closeBtn, TweenInfo.new(0.2), {
TextColor3 = THEME.muted
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

-- Hover effect
clickButton.MouseEnter:Connect(function()
TweenService:Create(notification, TweenInfo.new(0.2), {
BackgroundColor3 = THEME.card
}):Play()
end)

clickButton.MouseLeave:Connect(function()
TweenService:Create(notification, TweenInfo.new(0.2), {
BackgroundColor3 = THEME.panel
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

	-- Animación de entrada (viene desde arriba)
	local targetPos = UDim2.new(0.5, -CONFIG.NOTIFICATION_WIDTH / 2, 0, 20)

	local tweenIn = TweenService:Create(notification, TweenInfo.new(CONFIG.ANIMATION_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	tweenIn:Play()

-- Reposicionar todas las notificaciones
repositionNotifications()

-- Auto-cerrar después de la duración
if duration > 0 then
task.delay(duration, function()
if notification and notification.Parent then
removeNotification(notification)
end
end)

-- Animar la barra de progreso
task.spawn(function()
local startTime = tick()
while notification and notification.Parent and (tick() - startTime) < duration do
local progress = (tick() - startTime) / duration
progressBar.Size = UDim2.new(0, 4, 1 - progress, 0)
progressBar.Position = UDim2.new(0, 0, progress, 0)
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
