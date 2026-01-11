--[[
	═══════════════════════════════════════════════════════════════════════════════
	   EMOTES SYSTEM - MODERN UI
	   GUI generada 100% por código • Diseño responsive • Animaciones fluidas
	═══════════════════════════════════════════════════════════════════════════════
]]--

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN (AJUSTA ESTOS VALORES SEGÚN TUS NECESIDADES)
-- ════════════════════════════════════════════════════════════════════════════════

local Config = {
	-- TAMAÑO PC
	PC_Ancho = 180,
	PC_Alto = 380,
	PC_MargenIzquierdo = 5,
	PC_OffsetVertical = 18, -- offset desde el centro (positivo = más abajo)

	-- TAMAÑO MÓVIL
	Movil_Ancho = 150,
	Movil_Alto = 120,
	Movil_MargenIzquierdo = 5,
	Movil_OffsetVertical = 10, -- offset desde el centro (positivo = más abajo)

	-- MOSTRAR/OCULTAR ELEMENTOS
	Movil_MostrarTitulo = false,
	Movil_MostrarSlider = false,
	Movil_MostrarBusqueda = true,
}

-- ════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicado = ReplicatedStorage:WaitForChild("Panda ReplicatedStorage")
local Ownership = ReplicatedStorage["Panda ReplicatedStorage"]["Gamepass Gifting"].Remotes.Ownership

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE COLORES Y TEMA
-- ════════════════════════════════════════════════════════════════════════════════

local THEME_CONFIG = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local Theme = {
	-- Fondos desde ThemeConfig
	Background = THEME_CONFIG.bg,
	BackgroundSecondary = THEME_CONFIG.panel,
	BackgroundTertiary = THEME_CONFIG.elevated,

	-- Acentos
	Primary = THEME_CONFIG.accent,
	PrimaryHover = THEME_CONFIG.accentHover,
	Secondary = THEME_CONFIG.accent,
	Success = THEME_CONFIG.success,
	Warning = THEME_CONFIG.warn,
	Danger = THEME_CONFIG.warn,

	-- Categorías especiales (colores sólidos vibrantes)
	Favorites = Color3.fromRGB(255, 200, 0),     -- Amarillo dorado
	Trending = Color3.fromRGB(255, 140, 0),      -- Naranja
	VIP = Color3.fromRGB(180, 100, 255),         -- Púrpura
	Recommended = Color3.fromRGB(0, 200, 255),   -- Cyan
	Normal = Color3.fromRGB(150, 150, 150),      -- Gris

	-- Texto desde ThemeConfig
	TextPrimary = THEME_CONFIG.text,
	TextSecondary = THEME_CONFIG.muted,
	TextMuted = THEME_CONFIG.subtle,

	-- Bordes desde ThemeConfig
	Border = THEME_CONFIG.stroke,
	BorderLight = THEME_CONFIG.strokeLight,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- REMOTES Y MÓDULOS
-- ════════════════════════════════════════════════════════════════════════════════

local Remotos = Replicado:WaitForChild("Eventos_Emote")
local ObtenerFavs = Remotos:WaitForChild("ObtenerFavs")
local AnadirFav = Remotos:WaitForChild("AnadirFav")
local Noti = Remotos:WaitForChild("RemoteNoti")
local ObtenerTrending = Remotos:WaitForChild("ObtenerTrending")

local RemotesSync = Replicado:WaitForChild("Emotes_Sync")
local PlayAnimationRemote = RemotesSync.PlayAnimation
local StopAnimationRemote = RemotesSync.StopAnimation

local Animaciones = Replicado:WaitForChild("Emotes_Sync"):WaitForChild("Emotes_Modules"):WaitForChild("Animaciones")
local SliderModule = require(Replicado:WaitForChild("Emotes_Sync"):WaitForChild("Emotes_Modules"):WaitForChild("Slider"))

local ConfigModule = require(Replicado:WaitForChild("Configuration"))
local VIPGamePassID = ConfigModule.VIP

local MIcon = ReplicatedStorage:WaitForChild("Icon")
local Icon = require(MIcon)

local Modulo = require(Animaciones)

local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- ════════════════════════════════════════════════════════════════════════════════
-- VARIABLES DEL JUGADOR
-- ════════════════════════════════════════════════════════════════════════════════

local Jugador = Players.LocalPlayer
local PlayerGui = Jugador:WaitForChild("PlayerGui")
local Char = Jugador.Character or Jugador.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Animator = Hum:WaitForChild("Animator")

-- ════════════════════════════════════════════════════════════════════════════════
-- DETECCIÓN DE DISPOSITIVO
-- ════════════════════════════════════════════════════════════════════════════════

local function EsMovil()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function GetScreenSize()
	local viewport = workspace.CurrentCamera.ViewportSize
	return viewport.X, viewport.Y
end

local IsMobile = EsMovil()

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES DE UI
-- ════════════════════════════════════════════════════════════════════════════════

local UI = {}

function UI.Tween(objeto, duracion, propiedades, estilo, direccion)
	estilo = estilo or Enum.EasingStyle.Quint
	direccion = direccion or Enum.EasingDirection.Out
	local info = TweenInfo.new(duracion, estilo, direccion)
	local tween = TweenService:Create(objeto, info, propiedades)
	tween:Play()
	return tween
end

function UI.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

function UI.CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

function UI.CreatePadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end

function UI.CreateGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

function UI.CreateShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR GUI PRINCIPAL
-- ════════════════════════════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EmotesModernUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Frame Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

-- Tamaño responsive - Centrado verticalmente a la izquierda
if IsMobile then
	MainFrame.Size = UDim2.new(0, Config.Movil_Ancho, 0, Config.Movil_Alto)
	MainFrame.Position = UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
	MainFrame.AnchorPoint = Vector2.new(0, 0.5)
else
	MainFrame.Size = UDim2.new(0, Config.PC_Ancho, 0, Config.PC_Alto)
	MainFrame.Position = UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)
	MainFrame.AnchorPoint = Vector2.new(0, 0.5)
end

UI.CreateCorner(MainFrame, 12)
UI.CreateStroke(MainFrame, Theme.Border, 1, 0.5)
UI.CreateShadow(MainFrame)

-- Gradiente sutil de fondo
local bgGradient = Instance.new("Frame")
bgGradient.Name = "BackgroundGradient"
bgGradient.Size = UDim2.new(1, 0, 0.3, 0)
bgGradient.Position = UDim2.new(0, 0, 0, 0)
bgGradient.BackgroundColor3 = Theme.Primary
bgGradient.BackgroundTransparency = 0.92
bgGradient.BorderSizePixel = 0
bgGradient.ZIndex = 1
bgGradient.Parent = MainFrame
UI.CreateCorner(bgGradient, 16)

local gradientEffect = Instance.new("UIGradient")
gradientEffect.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1)
})
gradientEffect.Rotation = 180
gradientEffect.Parent = bgGradient

-- ════════════════════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarTitulo = IsMobile and Config.Movil_MostrarTitulo or true

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, mostrarTitulo and (IsMobile and 28 or 40) or 0)
Header.BackgroundTransparency = 1
Header.BorderSizePixel = 0
Header.ZIndex = 5
Header.Visible = mostrarTitulo
Header.Parent = MainFrame

-- Título centrado
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Bailes"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = IsMobile and 16 or 20
TitleLabel.Parent = Header

-- Calcular posición Y base después del header
local posYBase = mostrarTitulo and (IsMobile and 30 or 42) or 8

-- ════════════════════════════════════════════════════════════════════════════════
-- BARRA DE BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarBusqueda = IsMobile and Config.Movil_MostrarBusqueda or true

local SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(1, -16, 0, mostrarBusqueda and (IsMobile and 26 or 32) or 0)
SearchContainer.Position = UDim2.new(0, 8, 0, posYBase)
SearchContainer.BackgroundColor3 = Theme.BackgroundSecondary
SearchContainer.BorderSizePixel = 0
SearchContainer.ZIndex = 5
SearchContainer.Visible = mostrarBusqueda
SearchContainer.Parent = MainFrame
UI.CreateCorner(SearchContainer, 8)
UI.CreateStroke(SearchContainer, Theme.Border, 1, 0.3)

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -16, 1, 0)
SearchBox.Position = UDim2.new(0, 10, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Busca tu Baile"
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.TextSize = IsMobile and 11 or 14
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchContainer

-- Actualizar posición Y después de búsqueda
local posYDespuesBusqueda = posYBase + (mostrarBusqueda and (IsMobile and 30 or 36) or 0)

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER DE VELOCIDAD
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarSlider = IsMobile and Config.Movil_MostrarSlider or true

local SliderSection = Instance.new("Frame")
SliderSection.Name = "SliderSection"
SliderSection.Size = UDim2.new(1, -16, 0, mostrarSlider and 32 or 0)
SliderSection.Position = UDim2.new(0, 8, 0, posYDespuesBusqueda)
SliderSection.BackgroundColor3 = Theme.BackgroundSecondary
SliderSection.BorderSizePixel = 0
SliderSection.ZIndex = 5
SliderSection.Visible = mostrarSlider
SliderSection.Parent = MainFrame
UI.CreateCorner(SliderSection, 8)

-- Posición final del contenido
local posYContenido = posYDespuesBusqueda + (mostrarSlider and 36 or 4)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Size = UDim2.new(0, 35, 1, 0)
SpeedLabel.Position = UDim2.new(0, 8, 0, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Font = Enum.Font.GothamMedium
SpeedLabel.Text = "Vel:"
SpeedLabel.TextColor3 = Theme.TextSecondary
SpeedLabel.TextSize = 12
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = SliderSection

local SpeedValue = Instance.new("TextLabel")
SpeedValue.Name = "SpeedValue"
SpeedValue.Size = UDim2.new(0, 35, 1, 0)
SpeedValue.Position = UDim2.new(1, -42, 0, 0)
SpeedValue.BackgroundTransparency = 1
SpeedValue.Font = Enum.Font.GothamBold
SpeedValue.Text = "1.0x"
SpeedValue.TextColor3 = Theme.Primary
SpeedValue.TextSize = 12
SpeedValue.TextXAlignment = Enum.TextXAlignment.Right
SpeedValue.Parent = SliderSection

-- Track del slider
local SliderTrack = Instance.new("Frame")
SliderTrack.Name = "SliderTrack"
SliderTrack.Size = UDim2.new(0.5, 0, 0, 8)
SliderTrack.Position = UDim2.new(0.22, 0, 0.5, -4)
SliderTrack.BackgroundColor3 = Theme.BackgroundTertiary
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderSection
UI.CreateCorner(SliderTrack, 4)

local SliderFill = Instance.new("Frame")
SliderFill.Name = "SliderFill"
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = Theme.Primary
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
UI.CreateCorner(SliderFill, 4)

local SliderKnob = Instance.new("Frame")
SliderKnob.Name = "SliderKnob"
SliderKnob.Size = UDim2.new(0, 16, 0, 16)
SliderKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
SliderKnob.BackgroundColor3 = Theme.TextPrimary
SliderKnob.BorderSizePixel = 0
SliderKnob.ZIndex = 3
SliderKnob.Parent = SliderTrack
UI.CreateCorner(SliderKnob, 8)
UI.CreateStroke(SliderKnob, Theme.Primary, 2)

-- ════════════════════════════════════════════════════════════════════════════════
-- SCROLLING FRAME PARA EMOTES
-- ════════════════════════════════════════════════════════════════════════════════

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -16, 1, -(posYContenido + 8))
ContentArea.Position = UDim2.new(0, 8, 0, posYContenido)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Theme.Primary
ScrollFrame.ScrollBarImageTransparency = 0.5
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollFrame.Parent = ContentArea

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, IsMobile and 3 or 6)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = ScrollFrame

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, IsMobile and 2 or 4)
ContentPadding.PaddingBottom = UDim.new(0, IsMobile and 4 or 10)
ContentPadding.PaddingLeft = UDim.new(0, IsMobile and 4 or 6)
ContentPadding.PaddingRight = UDim.new(0, IsMobile and 4 or 6)
ContentPadding.Parent = ScrollFrame

-- Notificaciones usando NotificationSystem

-- ════════════════════════════════════════════════════════════════════════════════
-- NOTIFICACIONES (usando NotificationSystem)
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR TARJETAS DE EMOTES
-- ════════════════════════════════════════════════════════════════════════════════

local EmotesFavs = ObtenerFavs:InvokeServer() or {}
local EmotesTrending = ObtenerTrending:InvokeServer() or {}
local DanceActivated = nil
local ActiveCard = nil -- Guardar la tarjeta activa

local function EncontrarNombre(BaileId)
	-- Buscar en Ids normales
	if Modulo.Ids then
		for _, v in pairs(Modulo.Ids) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	-- Buscar en VIP
	if Modulo.Vip then
		for _, v in pairs(Modulo.Vip) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	-- Buscar en Recomendados
	if Modulo.Recomendado then
		for _, v in pairs(Modulo.Recomendado) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	return "Dance"
end

local function CrearSeparador(texto, icono, color)
	local separator = Instance.new("Frame")
	separator.Name = "Separator_" .. texto
	separator.Size = UDim2.new(1, 0, 0, IsMobile and 16 or 26)
	separator.BackgroundTransparency = 1
	separator:SetAttribute("EmoteEntry", true)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = (icono or "") .. " " .. texto .. " " .. (icono or "")
	label.TextColor3 = color or Theme.TextSecondary
	label.TextSize = IsMobile and 9 or 13
	label.Parent = separator

	return separator
end

local function CrearTarjetaEmote(nombre, id, tipo, orden)
	local cardHeight = IsMobile and 28 or 38

	local card = Instance.new("TextButton")
	card.Name = "Emote_" .. nombre
	card.Size = UDim2.new(1, 0, 0, cardHeight)
	card.BackgroundColor3 = Theme[tipo] or Theme.Normal
	card.BorderSizePixel = 0
	card.LayoutOrder = orden
	card.Text = ""
	card.AutoButtonColor = false
	card:SetAttribute("EmoteEntry", true)
	card:SetAttribute("EmoteID", id)
	card:SetAttribute("EmoteName", nombre)
	UI.CreateCorner(card, IsMobile and 5 or 8)

	-- Gradiente del color al negro
	local cardColor = Theme[tipo] or Theme.Normal
	UI.CreateGradient(card, cardColor, Color3.fromRGB(0, 0, 0), 180)

	-- INDICADORES DE ACTIVE (todos invisibles inicialmente)

	-- 1. Barra lateral de color
	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.Size = UDim2.new(0, 4, 1, 0)
	activeBar.Position = UDim2.new(0, 0, 0, 0)
	activeBar.BackgroundColor3 = cardColor
	activeBar.BorderSizePixel = 0
	activeBar.BackgroundTransparency = 1
	activeBar.ZIndex = 10
	activeBar.Parent = card
	UI.CreateCorner(activeBar, IsMobile and 5 or 8)

	-- 2. Overlay de brillo sobre la tarjeta
	local activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "ActiveOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.BackgroundColor3 = cardColor
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.BorderSizePixel = 0
	activeOverlay.ZIndex = 2
	activeOverlay.Parent = card
	UI.CreateCorner(activeOverlay, IsMobile and 5 or 8)

	-- 3. Borde grueso que se muestra cuando está activo
	local activeBorder = Instance.new("UIStroke")
	activeBorder.Name = "ActiveBorder"
	activeBorder.Color = cardColor
	activeBorder.Thickness = 3
	activeBorder.Transparency = 1
	activeBorder.Parent = card

	-- Nombre del emote
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "EmoteName"
	nameLabel.Size = UDim2.new(1, IsMobile and -32 or -45, 1, 0)
	nameLabel.Position = UDim2.new(0, IsMobile and 6 or 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = nombre
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = IsMobile and 10 or 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Botón Favorito (estrella) - ahora más a la derecha
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "FavButton"
	favBtn.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 20 or 26)
	favBtn.Position = UDim2.new(1, IsMobile and -24 or -38, 0.5, IsMobile and -10 or -13)
	favBtn.BackgroundTransparency = 1
	favBtn.Text = table.find(EmotesFavs, id) and "★" or "☆"
	favBtn.TextColor3 = table.find(EmotesFavs, id) and Theme.Warning or Color3.fromRGB(50, 50, 50)
	favBtn.TextSize = IsMobile and 16 or 22
	favBtn.Font = Enum.Font.GothamBold
	favBtn.AutoButtonColor = false
	favBtn.ZIndex = 2
	favBtn.Parent = card

	-- Efectos hover
	card.MouseEnter:Connect(function()
		UI.Tween(card, 0.15, {BackgroundColor3 = (Theme[tipo] or Theme.Normal):Lerp(Color3.fromRGB(255,255,255), 0.2)})
	end)

	card.MouseLeave:Connect(function()
		UI.Tween(card, 0.15, {BackgroundColor3 = Theme[tipo] or Theme.Normal})
	end)

	return card, favBtn, activeBorder
end

-- ════════════════════════════════════════════════════════════════════════════════
-- LÓGICA DE BOTONES
-- ════════════════════════════════════════════════════════════════════════════════

local Actualizar -- Forward declaration

local function AplicarEfectoActivo(card, activeBorder)
	-- Animar todos los elementos visuales de active
	local activeBar = card:FindFirstChild("ActiveBar")
	local activeOverlay = card:FindFirstChild("ActiveOverlay")

	-- 1. Mostrar borde grueso
	UI.Tween(activeBorder, 0.3, {Transparency = 0})

	-- 2. Mostrar barra lateral con efecto de entrada
	if activeBar then
		activeBar.Size = UDim2.new(0, 0, 1, 0)
		UI.Tween(activeBar, 0.3, {BackgroundTransparency = 0})
		UI.Tween(activeBar, 0.4, {Size = UDim2.new(0, 4, 1, 0)}, Enum.EasingStyle.Back)
	end

	-- 3. Overlay de brillo sutil
	if activeOverlay then
		UI.Tween(activeOverlay, 0.3, {BackgroundTransparency = 0.85})
	end

	-- 4. Efecto de escala sutil (pulso)
	UI.Tween(card, 0.2, {Size = UDim2.new(1, 4, 0, (IsMobile and 28 or 38) + 2)}, Enum.EasingStyle.Back)
end

local function RemoverEfectoActivo(activeBorder, card)
	-- Esconder todos los elementos visuales
	local activeBar = card:FindFirstChild("ActiveBar")
	local activeOverlay = card:FindFirstChild("ActiveOverlay")

	-- 1. Esconder borde
	UI.Tween(activeBorder, 0.2, {Transparency = 1})

	-- 2. Esconder barra lateral
	if activeBar then
		UI.Tween(activeBar, 0.2, {BackgroundTransparency = 1})
		UI.Tween(activeBar, 0.2, {Size = UDim2.new(0, 0, 1, 0)})
	end

	-- 3. Esconder overlay
	if activeOverlay then
		UI.Tween(activeOverlay, 0.2, {BackgroundTransparency = 1})
	end

	-- 4. Volver al tamaño normal
	UI.Tween(card, 0.2, {Size = UDim2.new(1, 0, 0, IsMobile and 28 or 38)})
end

local function ConfigurarBotones(card, favBtn, activeBorder, id, nombre, tieneVIP)
	-- Hacer la tarjeta clickeable para reproducir
	card.MouseButton1Click:Connect(function()
		if DanceActivated == nombre then
			DanceActivated = nil
			StopAnimationRemote:FireServer()
			RemoverEfectoActivo(activeBorder, card)
			ActiveCard = nil
		else
			-- Detener baile anterior si hay uno
			if ActiveCard and ActiveCard ~= card then
				local prevBorder = ActiveCard:FindFirstChild("ActiveBorder")
				if prevBorder then
					RemoverEfectoActivo(prevBorder, ActiveCard)
				end
			end

			DanceActivated = nombre
			ActiveCard = card
			PlayAnimationRemote:FireServer("playAnim", nombre)
			AplicarEfectoActivo(card, activeBorder)
		end
	end)

	-- Botón Favorito
	favBtn.MouseButton1Click:Connect(function()
		local status = AnadirFav:InvokeServer(id)

		if status == "Anadido" then
			NotificationSystem:Success("Favorito", nombre .. " añadido a favoritos", 3)
			favBtn.Text = "★"
			favBtn.TextColor3 = Theme.Warning

			-- Actualizar lista de favoritos y refrescar
			task.spawn(function()
				task.wait(0.3)
				local newFavs = ObtenerFavs:InvokeServer()
				if newFavs then
					EmotesFavs = newFavs
				end
				Actualizar()
			end)

		elseif status == "Eliminada" then
			NotificationSystem:Success("Favorito", nombre .. " eliminado de favoritos", 3)
			favBtn.Text = "☆"
			favBtn.TextColor3 = Color3.fromRGB(50, 50, 50)

			-- Actualizar lista de favoritos y refrescar
			task.spawn(function()
				task.wait(0.3)
				local newFavs = ObtenerFavs:InvokeServer()
				if newFavs then
					EmotesFavs = newFavs
				end
				Actualizar()
			end)
		else
			NotificationSystem:Error("Error", "No se pudo modificar favoritos", 4)
		end
	end)
end

local function ConfigurarBotonVIPBloqueado(card, nombre)
	local debounce = false
	card.MouseButton1Click:Connect(function()
		if not debounce then
			debounce = true
			NotificationSystem:Warning("Acceso VIP", "Necesitas el GamePass VIP para este baile", 4)
			task.wait(0.5)
			MarketplaceService:PromptGamePassPurchase(Jugador, VIPGamePassID)
			debounce = false
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- FUNCIÓN ACTUALIZAR
-- ════════════════════════════════════════════════════════════════════════════════

Actualizar = function(filtro)
	-- Limpiar scroll - PERO NO DESTRUIR LA TARJETA ACTIVA
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("EmoteEntry") then
			-- No destruir la tarjeta que está siendo reproducida
			if ActiveCard and child == ActiveCard then
				-- Preservar la tarjeta activa para que el borde pueda animarse
			else
				child:Destroy()
			end
		end
	end

	EmotesTrending = ObtenerTrending:InvokeServer() or {}
	local tieneVIP = Ownership:InvokeServer(VIPGamePassID)

	local orden = 1
	local filtroLower = filtro and filtro:lower() or ""

	local function pasaFiltro(nombre)
		if filtroLower == "" then return true end
		return nombre:lower():find(filtroLower, 1, true) ~= nil
	end

	-- FAVORITOS
	local favoritosVisibles = {}
	if EmotesFavs and #EmotesFavs > 0 then
		for _, v in pairs(EmotesFavs) do
			local nombre = EncontrarNombre(v)
			if pasaFiltro(nombre) then
				table.insert(favoritosVisibles, {id = v, nombre = nombre})
			end
		end
	end

	if #favoritosVisibles > 0 then
		local sep = CrearSeparador("FAVORITOS", "⭐", Theme.Favorites)
		sep.LayoutOrder = orden
		sep.Parent = ScrollFrame
		orden = orden + 1

		for _, data in ipairs(favoritosVisibles) do
			local card, favBtn, activeBorder = CrearTarjetaEmote(data.nombre, data.id, "Favorites", orden)
			card.Parent = ScrollFrame
			ConfigurarBotones(card, favBtn, activeBorder, data.id, data.nombre, tieneVIP)
			orden = orden + 1
		end
	end

	-- TRENDING
	local trendingVisibles = {}
	if EmotesTrending and #EmotesTrending > 0 then
		for _, v in pairs(EmotesTrending) do
			if not table.find(EmotesFavs or {}, v) then
				local nombre = EncontrarNombre(v)
				if pasaFiltro(nombre) then
					table.insert(trendingVisibles, {id = v, nombre = nombre})
				end
			end
		end
	end

	if #trendingVisibles > 0 then
		local sep = CrearSeparador("TRENDING", "🔥", Theme.Trending)
		sep.LayoutOrder = orden
		sep.Parent = ScrollFrame
		orden = orden + 1

		for _, data in ipairs(trendingVisibles) do
			local card, favBtn, activeBorder = CrearTarjetaEmote(data.nombre, data.id, "Trending", orden)
			card.Parent = ScrollFrame
			ConfigurarBotones(card, favBtn, activeBorder, data.id, data.nombre, tieneVIP)
			orden = orden + 1
		end
	end

	-- VIP
	if Modulo.Vip and #Modulo.Vip > 0 then
		local vipVisibles = {}
		for _, v in ipairs(Modulo.Vip) do
			if not table.find(EmotesTrending or {}, v.ID) and not table.find(EmotesFavs or {}, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(vipVisibles, v)
				end
			end
		end

		if #vipVisibles > 0 then
			local sep = CrearSeparador("VIP", "👑", Theme.VIP)
			sep.LayoutOrder = orden
			sep.Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(vipVisibles) do
				local card, favBtn, activeBorder = CrearTarjetaEmote(v.Nombre, v.ID, "VIP", orden)
				card.Parent = ScrollFrame

				if tieneVIP then
					ConfigurarBotones(card, favBtn, activeBorder, v.ID, v.Nombre, true)
				else
					ConfigurarBotonVIPBloqueado(card, v.Nombre)
					-- Favorito sigue funcionando
					favBtn.MouseButton1Click:Connect(function()
						local status = AnadirFav:InvokeServer(v.ID)
						if status == "Anadido" then
							NotificationSystem:Success("Favorito", v.Nombre .. " añadido a favoritos", 3)
							task.spawn(function()
								task.wait(0.3)
								EmotesFavs = ObtenerFavs:InvokeServer() or {}
								Actualizar(filtro)
							end)
						elseif status == "Eliminada" then
							NotificationSystem:Success("Favorito", v.Nombre .. " eliminado de favoritos", 3)
							task.spawn(function()
								task.wait(0.3)
								EmotesFavs = ObtenerFavs:InvokeServer() or {}
								Actualizar(filtro)
							end)
						end
					end)
				end
				orden = orden + 1
			end
		end
	end

	-- RECOMENDADOS
	if Modulo.Recomendado and #Modulo.Recomendado > 0 then
		local recVisibles = {}
		for _, v in ipairs(Modulo.Recomendado) do
			if not table.find(EmotesTrending or {}, v.ID) and not table.find(EmotesFavs or {}, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(recVisibles, v)
				end
			end
		end

		if #recVisibles > 0 then
			local sep = CrearSeparador("RECOMENDADOS", "💡", Theme.Recommended)
			sep.LayoutOrder = orden
			sep.Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(recVisibles) do
				local card, favBtn, activeBorder = CrearTarjetaEmote(v.Nombre, v.ID, "Recommended", orden)
				card.Parent = ScrollFrame
				ConfigurarBotones(card, favBtn, activeBorder, v.ID, v.Nombre, tieneVIP)
				orden = orden + 1
			end
		end
	end

	-- TODOS LOS BAILES
	if Modulo.Ids and #Modulo.Ids > 0 then
		local todosVisibles = {}
		for _, v in ipairs(Modulo.Ids) do
			if not table.find(EmotesTrending or {}, v.ID) and not table.find(EmotesFavs or {}, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(todosVisibles, v)
				end
			end
		end

		if #todosVisibles > 0 then
			local sep = CrearSeparador("TODOS LOS BAILES", "🎵", Theme.Normal)
			sep.LayoutOrder = orden
			sep.Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(todosVisibles) do
				local card, favBtn, activeBorder = CrearTarjetaEmote(v.Nombre, v.ID, "Normal", orden)
				card.Parent = ScrollFrame
				ConfigurarBotones(card, favBtn, activeBorder, v.ID, v.Nombre, tieneVIP)
				orden = orden + 1
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER DE VELOCIDAD - LÓGICA
-- ════════════════════════════════════════════════════════════════════════════════

local sliderDragging = false
local speedValues = {0.01, 0.05, 0.3, 0.5, 0.7, 1, 1.3, 1.6, 1.9, 2.2, 2.5}
local currentSpeedIndex = 6 -- 1.0x por defecto

local function UpdateSliderVisual(percentage)
	SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
	SliderKnob.Position = UDim2.new(percentage, -8, 0.5, -8)

	local index = math.clamp(math.floor(percentage * 10) + 1, 1, 11)
	local speed = speedValues[index]
	SpeedValue.Text = string.format("%.1fx", speed)
end

local function SetSliderValue(percentage)
	percentage = math.clamp(percentage, 0, 1)
	UpdateSliderVisual(percentage)

	local index = math.clamp(math.floor(percentage * 10) + 1, 1, 11)
	if index ~= currentSpeedIndex then
		currentSpeedIndex = index
		PlayAnimationRemote:FireServer("speed", speedValues[index])
	end
end

SliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
		local relativeX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
		SetSliderValue(relativeX)
	end
end)

SliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local relativeX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
		SetSliderValue(relativeX)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)

-- Inicializar slider al 50% (velocidad 1.0x)
UpdateSliderVisual(0.5)

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

local searchDebounce = false
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true

	task.delay(0.3, function()
		Actualizar(SearchBox.Text)
		searchDebounce = false
	end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- TOGGLE GUI & TOPBAR ICON
-- ════════════════════════════════════════════════════════════════════════════════

local function ToggleGUI(visible)
	if visible then
		MainFrame.Visible = true
		MainFrame.BackgroundTransparency = 1
		UI.Tween(MainFrame, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad)
	else
		local tween = UI.Tween(MainFrame, 0.25, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
		tween.Completed:Wait()
		MainFrame.Visible = false
	end
end

-- TopbarPlus Icon
local Icono = Icon.new()
Icono:setOrder(2)
Icono:setLabel("Bailes!!")
Icono:setImage("127784597936941")
Icono:disableStateOverlay(false)

Icono.selected:Connect(function()
	ToggleGUI(true)
end)

Icono.deselected:Connect(function()
	ToggleGUI(false)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SINCRONIZACIÓN DE BAILES
-- ════════════════════════════════════════════════════════════════════════════════

local Estado = nil
local Termino = false
local ConexionAnim = nil
local UltimaAnim = nil

local function BuscarJugador(str)
	local jugador = Players:FindFirstChild(str)
	if jugador then return jugador end

	for _, v in pairs(Players:GetPlayers()) do
		if v.Name:lower():find(str:lower()) then
			return v
		end
	end
	return nil
end

local function ObtenerNumero(str)
	local numero = ""
	for i = 1, #str do
		local letra = str:sub(i, i)
		if tonumber(letra) then
			numero = numero .. letra
		end
	end
	return tonumber(numero)
end

local function Comparar(otroAnimator)
	local animaciones = otroAnimator:GetPlayingAnimationTracks()
	local baile = animaciones[#animaciones]

	if not baile or not baile.Animation then return false end

	if UltimaAnim ~= baile.Animation then
		for _, data in pairs(Modulo.Ids) do
			if data.ID == ObtenerNumero(baile.Animation.AnimationId) then
				UltimaAnim = baile.Animation
				return true
			end
		end
	end
	return false
end

local function Sincronizar(otroAnimator, miAnimator)
	local animaciones = otroAnimator:GetPlayingAnimationTracks()
	local baile = animaciones[#animaciones]

	if not baile or not baile.Animation then return end

	if ConexionAnim then
		ConexionAnim:Stop()
	end

	UltimaAnim = baile.Animation
	ConexionAnim = miAnimator:LoadAnimation(baile.Animation)
	ConexionAnim.Priority = Enum.AnimationPriority.Action
	ConexionAnim:Play()
	ConexionAnim.TimePosition = baile.TimePosition
	ConexionAnim:AdjustSpeed(baile.Speed)
end

Jugador.Chatted:Connect(function(mensaje)
	if mensaje:sub(1, 5):lower() == "/sync" then
		local solicitud = mensaje:sub(7)
		local jugador = BuscarJugador(solicitud)

		if jugador then
			NotificationSystem:Success("Sincronización", "Sincronizado con: " .. jugador.Name, 4)
			Estado = jugador
			Termino = false
		else
			NotificationSystem:Error("Búsqueda", "Usuario no encontrado", 3)
		end
	end

	if mensaje:sub(1, 7):lower() == "/unsync" then
		if Estado then
			Estado = nil
			NotificationSystem:Success("Sincronización", "Sincronización detenida", 3)
		else
			NotificationSystem:Warning("Sincronización", "No estás sincronizado", 3)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if Estado then
		local otroChar = Estado.Character
		if otroChar then
			local otroHum = otroChar:FindFirstChild("Humanoid")
			if otroHum then
				local otroAnimator = otroHum:FindFirstChild("Animator")
				if otroAnimator and Comparar(otroAnimator) then
					Sincronizar(otroAnimator, Animator)
				end
			end
		end
	elseif not Termino then
		Termino = true
		if ConexionAnim then
			ConexionAnim:Stop()
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- RESPONSIVE - ACTUALIZAR EN CAMBIO DE TAMAÑO
-- ════════════════════════════════════════════════════════════════════════════════

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local newIsMobile = EsMovil()
	if newIsMobile ~= IsMobile then
		IsMobile = newIsMobile
		-- Actualizar tamaños si cambia el tipo de dispositivo
		if IsMobile then
			MainFrame.Size = UDim2.new(0, Config.Movil_Ancho, 0, Config.Movil_Alto)
			MainFrame.Position = UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
			MainFrame.AnchorPoint = Vector2.new(0, 0.5)
		else
			MainFrame.Size = UDim2.new(0, Config.PC_Ancho, 0, Config.PC_Alto)
			MainFrame.Position = UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)
			MainFrame.AnchorPoint = Vector2.new(0, 0.5)
		end
		Actualizar(SearchBox.Text)
	end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

Actualizar()

