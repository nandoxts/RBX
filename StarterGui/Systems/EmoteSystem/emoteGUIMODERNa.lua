--[[
	═══════════════════════════════════════════════════════════════════════════════
	   EMOTES SYSTEM - MODERN UI (OPTIMIZADO)
	═══════════════════════════════════════════════════════════════════════════════
]]--

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

local Config = {
	PC_Ancho = 180,
	PC_Alto = 380,
	PC_MargenIzquierdo = 5,
	PC_OffsetVertical = 18,

	Movil_Ancho = 150,
	Movil_Alto = 120,
	Movil_MargenIzquierdo = 5,
	Movil_OffsetVertical = 10,

	Movil_MostrarTitulo = false,
	Movil_MostrarSlider = false,
	Movil_MostrarBusqueda = true,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- SERVICIOS
-- ════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════════════════════════════════
-- REFERENCIAS
-- ════════════════════════════════════════════════════════════════════════════════

local Replicado = ReplicatedStorage:WaitForChild("Panda ReplicatedStorage")
local Ownership = Replicado["Gamepass Gifting"].Remotes.Ownership
local Remotos = Replicado:WaitForChild("Eventos_Emote")
local RemotesSync = Replicado:WaitForChild("Emotes_Sync")

local ObtenerFavs = Remotos:WaitForChild("ObtenerFavs")
local AnadirFav = Remotos:WaitForChild("AnadirFav")
local ObtenerTrending = Remotos:WaitForChild("ObtenerTrending")
local PlayAnimationRemote = RemotesSync.PlayAnimation
local StopAnimationRemote = RemotesSync.StopAnimation

local THEME_CONFIG = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ConfigModule = require(Replicado:WaitForChild("Configuration"))
local Modulo = require(RemotesSync:WaitForChild("Emotes_Modules"):WaitForChild("Animaciones"))
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local VIPGamePassID = ConfigModule.VIP

-- ════════════════════════════════════════════════════════════════════════════════
-- TEMA
-- ════════════════════════════════════════════════════════════════════════════════

local Theme = {
	Background = THEME_CONFIG.bg,
	BackgroundSecondary = THEME_CONFIG.panel,
	BackgroundTertiary = THEME_CONFIG.elevated,
	Primary = THEME_CONFIG.accent,
	PrimaryHover = THEME_CONFIG.accentHover,
	Warning = THEME_CONFIG.warn,
	TextPrimary = THEME_CONFIG.text,
	TextSecondary = THEME_CONFIG.muted,
	TextMuted = THEME_CONFIG.subtle,
	Border = THEME_CONFIG.stroke,
	
	-- Categorías
	Favorites = Color3.fromRGB(255, 200, 0),
	Trending = Color3.fromRGB(255, 140, 0),
	VIP = Color3.fromRGB(180, 100, 255),
	Recommended = Color3.fromRGB(0, 200, 255),
	Normal = Color3.fromRGB(150, 150, 150),
}

-- ════════════════════════════════════════════════════════════════════════════════
-- VARIABLES
-- ════════════════════════════════════════════════════════════════════════════════

local Jugador = Players.LocalPlayer
local PlayerGui = Jugador:WaitForChild("PlayerGui")
local Char = Jugador.Character or Jugador.CharacterAdded:Wait()
local Animator = Char:WaitForChild("Humanoid"):WaitForChild("Animator")

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local EmotesFavs = {}
local EmotesTrending = {}
local DanceActivated = nil
local ActiveCard = nil
local tieneVIP = false

-- Debounces
local actualizandoDebounce = false
local favoritoDebounce = false

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES UI
-- ════════════════════════════════════════════════════════════════════════════════

local UI = {}

function UI.Tween(obj, dur, props, style, dir)
	local tween = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

function UI.CreateCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

function UI.CreateStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

function UI.CreateGradient(parent, color1, color2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

function UI.CreateShadow(parent)
	local s = Instance.new("ImageLabel")
	s.Name = "Shadow"
	s.BackgroundTransparency = 1
	s.Image = "rbxassetid://5554236805"
	s.ImageColor3 = Color3.fromRGB(0, 0, 0)
	s.ImageTransparency = 0.6
	s.ScaleType = Enum.ScaleType.Slice
	s.SliceCenter = Rect.new(23, 23, 277, 277)
	s.Size = UDim2.new(1, 30, 1, 30)
	s.Position = UDim2.new(0, -15, 0, -15)
	s.ZIndex = parent.ZIndex - 1
	s.Parent = parent
	return s
end

-- ════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════

local function GetCardHeight()
	return IsMobile and 28 or 38
end

local function EncontrarNombre(BaileId)
	for _, lista in ipairs({Modulo.Ids, Modulo.Vip, Modulo.Recomendado}) do
		if lista then
			for _, v in pairs(lista) do
				if v.ID == BaileId then return v.Nombre end
			end
		end
	end
	return "Dance"
end

local function EstaEnFavoritos(id)
	return table.find(EmotesFavs, id) ~= nil
end

-- Animar visibilidad de elementos hijos
local function AnimarElementos(card, visible, excludeActiveBorder)
	local targetTransparency = visible and 0 or 1
	
	UI.Tween(card, 0.3, {BackgroundTransparency = targetTransparency})
	
	for _, child in ipairs(card:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			UI.Tween(child, 0.3, {TextTransparency = targetTransparency})
		elseif child:IsA("ImageLabel") then
			UI.Tween(child, 0.3, {ImageTransparency = targetTransparency})
		elseif child:IsA("UIStroke") then
			if not (excludeActiveBorder and child.Name == "ActiveBorder") then
				UI.Tween(child, 0.3, {Transparency = targetTransparency})
			end
		end
	end
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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.Parent = ScreenGui

local function ActualizarTamanoFrame()
	if IsMobile then
		MainFrame.Size = UDim2.new(0, Config.Movil_Ancho, 0, Config.Movil_Alto)
		MainFrame.Position = UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
	else
		MainFrame.Size = UDim2.new(0, Config.PC_Ancho, 0, Config.PC_Alto)
		MainFrame.Position = UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)
	end
end
ActualizarTamanoFrame()

UI.CreateCorner(MainFrame, 12)
UI.CreateStroke(MainFrame, Theme.Border, 1, 0.5)
UI.CreateShadow(MainFrame)

-- Gradiente de fondo
local bgGradient = Instance.new("Frame")
bgGradient.Name = "BackgroundGradient"
bgGradient.Size = UDim2.new(1, 0, 0.3, 0)
bgGradient.BackgroundColor3 = Theme.Primary
bgGradient.BackgroundTransparency = 0.92
bgGradient.BorderSizePixel = 0
bgGradient.ZIndex = 1
bgGradient.Parent = MainFrame
UI.CreateCorner(bgGradient, 16)

local gradientEffect = Instance.new("UIGradient")
gradientEffect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
gradientEffect.Rotation = 180
gradientEffect.Parent = bgGradient

-- ════════════════════════════════════════════════════════════════════════════════
-- HEADER, BÚSQUEDA, SLIDER (configuración dinámica)
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarTitulo = IsMobile and Config.Movil_MostrarTitulo or true
local mostrarBusqueda = IsMobile and Config.Movil_MostrarBusqueda or true
local mostrarSlider = IsMobile and Config.Movil_MostrarSlider or true

local posY = 8

-- Header
if mostrarTitulo then
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, IsMobile and 28 or 40)
	Header.Position = UDim2.new(0, 0, 0, 0)
	Header.BackgroundTransparency = 1
	Header.ZIndex = 5
	Header.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, 0, 1, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = "Bailes"
	TitleLabel.TextColor3 = Theme.TextPrimary
	TitleLabel.TextSize = IsMobile and 16 or 20
	TitleLabel.Parent = Header
	
	posY = IsMobile and 30 or 42
end

-- Búsqueda
local SearchBox
if mostrarBusqueda then
	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -16, 0, IsMobile and 26 or 32)
	SearchContainer.Position = UDim2.new(0, 8, 0, posY)
	SearchContainer.BackgroundColor3 = Theme.BackgroundSecondary
	SearchContainer.BorderSizePixel = 0
	SearchContainer.ZIndex = 5
	SearchContainer.Parent = MainFrame
	UI.CreateCorner(SearchContainer, 8)
	UI.CreateStroke(SearchContainer, Theme.Border, 1, 0.3)

	SearchBox = Instance.new("TextBox")
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
	
	posY = posY + (IsMobile and 30 or 36)
else
	-- Crear SearchBox dummy para evitar nil errors
	SearchBox = {Text = "", GetPropertyChangedSignal = function() return {Connect = function() end} end}
end

-- Slider
local SpeedValue, SliderFill, SliderKnob, SliderTrack
if mostrarSlider then
	local SliderSection = Instance.new("Frame")
	SliderSection.Name = "SliderSection"
	SliderSection.Size = UDim2.new(1, -16, 0, 32)
	SliderSection.Position = UDim2.new(0, 8, 0, posY)
	SliderSection.BackgroundColor3 = Theme.BackgroundSecondary
	SliderSection.BorderSizePixel = 0
	SliderSection.ZIndex = 5
	SliderSection.Parent = MainFrame
	UI.CreateCorner(SliderSection, 8)

	local SpeedLabel = Instance.new("TextLabel")
	SpeedLabel.Size = UDim2.new(0, 35, 1, 0)
	SpeedLabel.Position = UDim2.new(0, 8, 0, 0)
	SpeedLabel.BackgroundTransparency = 1
	SpeedLabel.Font = Enum.Font.GothamMedium
	SpeedLabel.Text = "Vel:"
	SpeedLabel.TextColor3 = Theme.TextSecondary
	SpeedLabel.TextSize = 12
	SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
	SpeedLabel.Parent = SliderSection

	SpeedValue = Instance.new("TextLabel")
	SpeedValue.Size = UDim2.new(0, 35, 1, 0)
	SpeedValue.Position = UDim2.new(1, -42, 0, 0)
	SpeedValue.BackgroundTransparency = 1
	SpeedValue.Font = Enum.Font.GothamBold
	SpeedValue.Text = "1.0x"
	SpeedValue.TextColor3 = Theme.Primary
	SpeedValue.TextSize = 12
	SpeedValue.TextXAlignment = Enum.TextXAlignment.Right
	SpeedValue.Parent = SliderSection

	SliderTrack = Instance.new("Frame")
	SliderTrack.Name = "SliderTrack"
	SliderTrack.Size = UDim2.new(0.5, 0, 0, 8)
	SliderTrack.Position = UDim2.new(0.22, 0, 0.5, -4)
	SliderTrack.BackgroundColor3 = Theme.BackgroundTertiary
	SliderTrack.BorderSizePixel = 0
	SliderTrack.Parent = SliderSection
	UI.CreateCorner(SliderTrack, 4)

	SliderFill = Instance.new("Frame")
	SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
	SliderFill.BackgroundColor3 = Theme.Primary
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderTrack
	UI.CreateCorner(SliderFill, 4)

	SliderKnob = Instance.new("Frame")
	SliderKnob.Size = UDim2.new(0, 16, 0, 16)
	SliderKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
	SliderKnob.BackgroundColor3 = Theme.TextPrimary
	SliderKnob.BorderSizePixel = 0
	SliderKnob.ZIndex = 3
	SliderKnob.Parent = SliderTrack
	UI.CreateCorner(SliderKnob, 8)
	UI.CreateStroke(SliderKnob, Theme.Primary, 2)
	
	posY = posY + 36
else
	posY = posY + 4
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SCROLLING FRAME
-- ════════════════════════════════════════════════════════════════════════════════

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -16, 1, -(posY + 8))
ContentArea.Position = UDim2.new(0, 8, 0, posY)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
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

-- ════════════════════════════════════════════════════════════════════════════════
-- EFECTOS DE TARJETA ACTIVA
-- ════════════════════════════════════════════════════════════════════════════════

local function AplicarEfectoActivo(card)
	local activeBar = card:FindFirstChild("ActiveBar")
	local activeOverlay = card:FindFirstChild("ActiveOverlay")
	local activeBorder = card:FindFirstChild("ActiveBorder")
	
	if activeBorder then UI.Tween(activeBorder, 0.3, {Transparency = 0}) end
	
	if activeBar then
		activeBar.Size = UDim2.new(0, 0, 1, 0)
		UI.Tween(activeBar, 0.3, {BackgroundTransparency = 0})
		UI.Tween(activeBar, 0.4, {Size = UDim2.new(0, 4, 1, 0)}, Enum.EasingStyle.Back)
	end
	
	if activeOverlay then
		UI.Tween(activeOverlay, 0.3, {BackgroundTransparency = 0.85})
	end
	
	UI.Tween(card, 0.2, {Size = UDim2.new(1, 4, 0, GetCardHeight() + 2)}, Enum.EasingStyle.Back)
end

local function RemoverEfectoActivo(card)
	local activeBar = card:FindFirstChild("ActiveBar")
	local activeOverlay = card:FindFirstChild("ActiveOverlay")
	local activeBorder = card:FindFirstChild("ActiveBorder")
	
	if activeBorder then UI.Tween(activeBorder, 0.2, {Transparency = 1}) end
	
	if activeBar then
		UI.Tween(activeBar, 0.2, {BackgroundTransparency = 1})
		UI.Tween(activeBar, 0.2, {Size = UDim2.new(0, 0, 1, 0)})
	end
	
	if activeOverlay then
		UI.Tween(activeOverlay, 0.2, {BackgroundTransparency = 1})
	end
	
	UI.Tween(card, 0.2, {Size = UDim2.new(1, 0, 0, GetCardHeight())})
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR ELEMENTOS
-- ════════════════════════════════════════════════════════════════════════════════

local function CrearSeparador(texto, icono, color, orden)
	local separator = Instance.new("Frame")
	separator.Name = "Separator_" .. texto
	separator.Size = UDim2.new(1, 0, 0, IsMobile and 16 or 26)
	separator.BackgroundTransparency = 1
	separator.LayoutOrder = orden
	separator:SetAttribute("EmoteEntry", true)
	separator.Parent = ScrollFrame

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
	local cardColor = Theme[tipo] or Theme.Normal
	local cardHeight = GetCardHeight()
	local esFavorito = EstaEnFavoritos(id)

	local card = Instance.new("TextButton")
	card.Name = "Emote_" .. nombre
	card.Size = UDim2.new(1, 0, 0, cardHeight)
	card.BackgroundColor3 = cardColor
	card.BorderSizePixel = 0
	card.LayoutOrder = orden
	card.Text = ""
	card.AutoButtonColor = false
	card:SetAttribute("EmoteEntry", true)
	card:SetAttribute("EmoteID", id)
	card:SetAttribute("EmoteName", nombre)
	card:SetAttribute("EmoteTipo", tipo)
	card.Parent = ScrollFrame
	
	UI.CreateCorner(card, IsMobile and 5 or 8)
	UI.CreateGradient(card, cardColor, Color3.fromRGB(0, 0, 0), 180)

	-- Elementos de estado activo (invisibles inicialmente)
	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.Size = UDim2.new(0, 4, 1, 0)
	activeBar.BackgroundColor3 = cardColor
	activeBar.BackgroundTransparency = 1
	activeBar.BorderSizePixel = 0
	activeBar.ZIndex = 10
	activeBar.Parent = card
	UI.CreateCorner(activeBar, IsMobile and 5 or 8)
	
	local activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "ActiveOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.BackgroundColor3 = cardColor
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.BorderSizePixel = 0
	activeOverlay.ZIndex = 2
	activeOverlay.Parent = card
	UI.CreateCorner(activeOverlay, IsMobile and 5 or 8)
	
	local activeBorder = Instance.new("UIStroke")
	activeBorder.Name = "ActiveBorder"
	activeBorder.Color = cardColor
	activeBorder.Thickness = 3
	activeBorder.Transparency = 1
	activeBorder.Parent = card

	-- Nombre
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

	-- Botón favorito
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "FavButton"
	favBtn.Size = UDim2.new(0, IsMobile and 22 or 30, 0, IsMobile and 20 or 26)
	favBtn.Position = UDim2.new(1, IsMobile and -24 or -38, 0.5, IsMobile and -10 or -13)
	favBtn.BackgroundTransparency = 1
	favBtn.Text = esFavorito and "★" or "☆"
	favBtn.TextColor3 = esFavorito and Theme.Warning or Color3.fromRGB(50, 50, 50)
	favBtn.TextSize = IsMobile and 16 or 22
	favBtn.Font = Enum.Font.GothamBold
	favBtn.AutoButtonColor = false
	favBtn.ZIndex = 2
	favBtn.Parent = card

	-- Hover
	card.MouseEnter:Connect(function()
		UI.Tween(card, 0.15, {BackgroundColor3 = cardColor:Lerp(Color3.fromRGB(255,255,255), 0.2)})
	end)
	card.MouseLeave:Connect(function()
		UI.Tween(card, 0.15, {BackgroundColor3 = cardColor})
	end)

	return card, favBtn
end

-- ════════════════════════════════════════════════════════════════════════════════
-- LÓGICA DE TARJETAS
-- ════════════════════════════════════════════════════════════════════════════════

local Actualizar -- Forward declaration

local function ManejarClickTarjeta(card, nombre, esVIPBloqueado)
	if esVIPBloqueado then
		NotificationSystem:Warning("Acceso VIP", "Necesitas el GamePass VIP para este baile", 4)
		task.wait(0.5)
		MarketplaceService:PromptGamePassPurchase(Jugador, VIPGamePassID)
		return
	end
	
	if DanceActivated == nombre then
		DanceActivated = nil
		StopAnimationRemote:FireServer()
		RemoverEfectoActivo(card)
		ActiveCard = nil
	else
		if ActiveCard and ActiveCard ~= card then
			RemoverEfectoActivo(ActiveCard)
		end
		DanceActivated = nombre
		ActiveCard = card
		PlayAnimationRemote:FireServer("playAnim", nombre)
		AplicarEfectoActivo(card)
	end
end

local function ManejarClickFavorito(id, nombre)
	if favoritoDebounce then return end
	favoritoDebounce = true
	
	local success, status = pcall(function()
		return AnadirFav:InvokeServer(id)
	end)
	
	if not success then
		NotificationSystem:Error("Error", "Error de conexión al servidor", 3)
		favoritoDebounce = false
		return
	end

	if status == "Anadido" then
		NotificationSystem:Success("Favorito", nombre .. " añadido a favoritos", 3)
	elseif status == "Eliminada" then
		NotificationSystem:Success("Favorito", nombre .. " eliminado de favoritos", 3)
	else
		NotificationSystem:Error("Error", "No se pudo modificar favoritos", 4)
		favoritoDebounce = false
		return
	end
	
	EmotesFavs = ObtenerFavs:InvokeServer() or {}
	favoritoDebounce = false
	Actualizar()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- FUNCIÓN ACTUALIZAR
-- ════════════════════════════════════════════════════════════════════════════════

Actualizar = function(filtro)
	if actualizandoDebounce then return end
	actualizandoDebounce = true
	
	filtro = filtro or (type(SearchBox) == "table" and SearchBox.Text or "")
	
	local activeDanceName = DanceActivated
	local scrollPosition = ScrollFrame.CanvasPosition.Y
	
	-- Limpiar
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("EmoteEntry") then
			child:Destroy()
		end
	end
	ActiveCard = nil

	-- Obtener datos
	EmotesTrending = ObtenerTrending:InvokeServer() or {}
	tieneVIP = Ownership:InvokeServer(VIPGamePassID)

	local orden = 1
	local filtroLower = filtro:lower()
	local delayCounter = 0

	local function pasaFiltro(nombre)
		return filtroLower == "" or nombre:lower():find(filtroLower, 1, true)
	end
	
	local function crearYAnimarTarjeta(nombre, id, tipo, esVIPBloqueado)
		local card, favBtn = CrearTarjetaEmote(nombre, id, tipo, orden)
		orden = orden + 1
		
		-- Iniciar invisible
		card.BackgroundTransparency = 1
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = 1
			elseif child:IsA("UIStroke") then
				child.Transparency = 1
			end
		end
		
		-- Animar entrada
		delayCounter = delayCounter + 1
		task.delay(delayCounter * 0.03, function()
			if card and card.Parent then
				AnimarElementos(card, true, true)
			end
		end)
		
		-- Configurar clicks
		card.MouseButton1Click:Connect(function()
			ManejarClickTarjeta(card, nombre, esVIPBloqueado)
		end)
		
		favBtn.MouseButton1Click:Connect(function()
			ManejarClickFavorito(id, nombre)
		end)
		
		return card
	end

	-- Categorías de emotes con su configuración
	local categorias = {
		{
			nombre = "FAVORITOS",
			icono = "⭐",
			color = Theme.Favorites,
			tipo = "Favorites",
			datos = EmotesFavs,
			esID = true,
			filtrarDe = {}
		},
		{
			nombre = "TRENDING",
			icono = "🔥",
			color = Theme.Trending,
			tipo = "Trending",
			datos = EmotesTrending,
			esID = true,
			filtrarDe = {EmotesFavs}
		},
		{
			nombre = "VIP",
			icono = "👑",
			color = Theme.VIP,
			tipo = "VIP",
			datos = Modulo.Vip,
			esID = false,
			filtrarDe = {EmotesFavs, EmotesTrending},
			esVIP = true
		},
		{
			nombre = "RECOMENDADOS",
			icono = "💡",
			color = Theme.Recommended,
			tipo = "Recommended",
			datos = Modulo.Recomendado,
			esID = false,
			filtrarDe = {EmotesFavs, EmotesTrending}
		},
		{
			nombre = "TODOS LOS BAILES",
			icono = "🎵",
			color = Theme.Normal,
			tipo = "Normal",
			datos = Modulo.Ids,
			esID = false,
			filtrarDe = {EmotesFavs, EmotesTrending}
		}
	}

	for _, cat in ipairs(categorias) do
		if cat.datos and #cat.datos > 0 then
			local visibles = {}
			
			for _, v in ipairs(cat.datos) do
				local id = cat.esID and v or v.ID
				local nombre = cat.esID and EncontrarNombre(v) or v.Nombre
				
				-- Verificar si no está en listas de filtro
				local enOtraLista = false
				for _, lista in ipairs(cat.filtrarDe) do
					if table.find(lista or {}, id) then
						enOtraLista = true
						break
					end
				end
				
				if not enOtraLista and pasaFiltro(nombre) then
					table.insert(visibles, {id = id, nombre = nombre})
				end
			end
			
			if #visibles > 0 then
				CrearSeparador(cat.nombre, cat.icono, cat.color, orden)
				orden = orden + 1
				
				for _, data in ipairs(visibles) do
					local esVIPBloqueado = cat.esVIP and not tieneVIP
					crearYAnimarTarjeta(data.nombre, data.id, cat.tipo, esVIPBloqueado)
				end
			end
		end
	end
	
	-- Restaurar estado
	task.delay(0.15, function()
		ScrollFrame.CanvasPosition = Vector2.new(0, scrollPosition)
		
		if activeDanceName then
			for _, child in ipairs(ScrollFrame:GetChildren()) do
				if child:GetAttribute("EmoteName") == activeDanceName then
					ActiveCard = child
					AplicarEfectoActivo(child)
					break
				end
			end
		end
		
		actualizandoDebounce = false
	end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER DE VELOCIDAD
-- ════════════════════════════════════════════════════════════════════════════════

if mostrarSlider and SliderTrack then
	local sliderDragging = false
	local speedValues = {0.01, 0.05, 0.3, 0.5, 0.7, 1, 1.3, 1.6, 1.9, 2.2, 2.5}
	local currentSpeedIndex = 6

	local function UpdateSliderVisual(percentage)
		SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
		SliderKnob.Position = UDim2.new(percentage, -8, 0.5, -8)
		local index = math.clamp(math.floor(percentage * 10) + 1, 1, 11)
		SpeedValue.Text = string.format("%.1fx", speedValues[index])
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

	UpdateSliderVisual(0.5)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

if mostrarBusqueda and type(SearchBox) ~= "table" then
	local searchDebounce = false
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounce then return end
		searchDebounce = true
		task.delay(0.3, function()
			Actualizar(SearchBox.Text)
			searchDebounce = false
		end)
	end)
end

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

local Icono = Icon.new()
Icono:setOrder(2)
Icono:setLabel("Bailes!!")
Icono:setImage("127784597936941")
Icono:disableStateOverlay(false)
Icono.selected:Connect(function() ToggleGUI(true) end)
Icono.deselected:Connect(function() ToggleGUI(false) end)

-- ════════════════════════════════════════════════════════════════════════════════
-- SINCRONIZACIÓN DE BAILES
-- ════════════════════════════════════════════════════════════════════════════════

local SyncTarget = nil
local SyncAnim = nil
local LastSyncedAnim = nil

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

local function GetAnimID(str)
	local num = ""
	for i = 1, #str do
		local c = str:sub(i, i)
		if tonumber(c) then num = num .. c end
	end
	return tonumber(num)
end

Jugador.Chatted:Connect(function(msg)
	if msg:sub(1, 5):lower() == "/sync" then
		local target = BuscarJugador(msg:sub(7))
		if target then
			SyncTarget = target
			NotificationSystem:Success("Sync", "Sincronizado con " .. target.Name, 3)
		else
			NotificationSystem:Error("Sync", "Usuario no encontrado", 3)
		end
	elseif msg:sub(1, 7):lower() == "/unsync" then
		if SyncTarget then
			SyncTarget = nil
			if SyncAnim then SyncAnim:Stop() end
			NotificationSystem:Success("Sync", "Desincronizado", 3)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not SyncTarget then return end

	local char = SyncTarget.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	local animator = hum:FindFirstChild("Animator")
	if not animator then return end

	local tracks = animator:GetPlayingAnimationTracks()
	local track = tracks[#tracks]

	if not track or not track.Animation then return end
	if track.Animation == LastSyncedAnim then return end

	-- Verificar si es un baile válido
	local animId = GetAnimID(track.Animation.AnimationId)
	local esValido = false
	for _, data in pairs(Modulo.Ids) do
		if data.ID == animId then esValido = true break end
	end

	if not esValido then return end

	LastSyncedAnim = track.Animation
	if SyncAnim then SyncAnim:Stop() end

	SyncAnim = Animator:LoadAnimation(track.Animation)
	SyncAnim.Priority = Enum.AnimationPriority.Action
	SyncAnim:Play()
	SyncAnim.TimePosition = track.TimePosition
	SyncAnim:AdjustSpeed(track.Speed)
	
	NotificationSystem:Success("Sincronización", "Sincronizado: " .. LastSyncedAnim.Name, 2)
end)


-- ════════════════════════════════════════════════════════════════════════════════
-- RESPONSIVE
-- ════════════════════════════════════════════════════════════════════════════════

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local newIsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if newIsMobile ~= IsMobile then
		IsMobile = newIsMobile
		ActualizarTamanoFrame()
		Actualizar()
	end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

EmotesFavs = ObtenerFavs:InvokeServer() or {}
Actualizar()