--[[
	═══════════════════════════════════════════════════════════════════════════════
	   EMOTES SYSTEM - MODERN UI (OPTIMIZADO)
	   GUI generada 100% por código • Diseño responsive
	═══════════════════════════════════════════════════════════════════════════════
]]--

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

local Config = {
	-- TAMAÑO PC
	PC_Ancho = 180,
	PC_Alto = 380,
	PC_MargenIzquierdo = 5,
	PC_OffsetVertical = 18,

	-- TAMAÑO MÓVIL
	Movil_Ancho = 150,
	Movil_Alto = 200,
	Movil_MargenIzquierdo = 5,
	Movil_OffsetVertical = 10,

	-- MOSTRAR/OCULTAR ELEMENTOS
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
local Ownership = Replicado:WaitForChild("Gamepass Gifting").Remotes.Ownership

local THEME_CONFIG = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local Theme = {
	Background = THEME_CONFIG.bg,
	BackgroundSecondary = THEME_CONFIG.panel,
	BackgroundTertiary = THEME_CONFIG.elevated,
	Primary = THEME_CONFIG.accent,
	PrimaryHover = THEME_CONFIG.accentHover,
	Success = THEME_CONFIG.success,
	Warning = THEME_CONFIG.warn,
	Danger = THEME_CONFIG.warn,
	Favorites = Color3.fromRGB(255, 200, 0),
	Trending = Color3.fromRGB(255, 140, 0),
	VIP = Color3.fromRGB(180, 100, 255),
	Recommended = Color3.fromRGB(0, 200, 255),
	Normal = Color3.fromRGB(150, 150, 150),
	TextPrimary = THEME_CONFIG.text,
	TextSecondary = THEME_CONFIG.muted,
	TextMuted = THEME_CONFIG.subtle,
	Border = THEME_CONFIG.stroke,
}

-- Remotos
local Remotos = Replicado:WaitForChild("Eventos_Emote")
local ObtenerFavs = Remotos:WaitForChild("ObtenerFavs")
local AnadirFav = Remotos:WaitForChild("AnadirFav")
local ObtenerTrending = Remotos:WaitForChild("ObtenerTrending")

local RemotesSync = Replicado:WaitForChild("Emotes_Sync")
local PlayAnimationRemote = RemotesSync.PlayAnimation
local StopAnimationRemote = RemotesSync.StopAnimation

local Animaciones = Replicado:WaitForChild("Emotes_Sync"):WaitForChild("Emotes_Modules"):WaitForChild("Animaciones")
local ConfigModule = require(Replicado:WaitForChild("Configuration"))
local VIPGamePassID = ConfigModule.VIP

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))
local Modulo = require(Animaciones)
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- ════════════════════════════════════════════════════════════════════════════════
-- VARIABLES
-- ════════════════════════════════════════════════════════════════════════════════

local Jugador = Players.LocalPlayer
local PlayerGui = Jugador:WaitForChild("PlayerGui")
local Char = Jugador.Character or Jugador.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Animator = Hum:WaitForChild("Animator")

local function EsMovil()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local IsMobile = EsMovil()

-- Estado global
local EmotesFavs = {}
local EmotesTrending = {}
local DanceActivated = nil
local TieneVIP = false

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES UI
-- ════════════════════════════════════════════════════════════════════════════════

local UI = {}

function UI.Tween(obj, dur, props, style)
	local tween = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
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
-- CREAR GUI
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
MainFrame.Parent = ScreenGui

if IsMobile then
	MainFrame.Size = UDim2.new(0, Config.Movil_Ancho, 0, Config.Movil_Alto)
	MainFrame.Position = UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
else
	MainFrame.Size = UDim2.new(0, Config.PC_Ancho, 0, Config.PC_Alto)
	MainFrame.Position = UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)
end
MainFrame.AnchorPoint = Vector2.new(0, 0.5)

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
gradientEffect.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1)
})
gradientEffect.Rotation = 180
gradientEffect.Parent = bgGradient

-- ════════════════════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarTitulo = not IsMobile or Config.Movil_MostrarTitulo
local headerHeight = mostrarTitulo and (IsMobile and 28 or 40) or 0

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, headerHeight)
Header.BackgroundTransparency = 1
Header.Visible = mostrarTitulo
Header.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Bailes"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = IsMobile and 16 or 20
TitleLabel.Parent = Header

local posY = headerHeight > 0 and (headerHeight + 4) or 8

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarBusqueda = not IsMobile or Config.Movil_MostrarBusqueda
local searchHeight = mostrarBusqueda and (IsMobile and 26 or 32) or 0

local SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(1, -16, 0, searchHeight)
SearchContainer.Position = UDim2.new(0, 8, 0, posY)
SearchContainer.BackgroundColor3 = Theme.BackgroundSecondary
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

posY = posY + (searchHeight > 0 and (searchHeight + 4) or 0)

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER DE VELOCIDAD
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarSlider = not IsMobile or Config.Movil_MostrarSlider
local sliderHeight = mostrarSlider and 32 or 0

local SliderSection = Instance.new("Frame")
SliderSection.Name = "SliderSection"
SliderSection.Size = UDim2.new(1, -16, 0, sliderHeight)
SliderSection.Position = UDim2.new(0, 8, 0, posY)
SliderSection.BackgroundColor3 = Theme.BackgroundSecondary
SliderSection.Visible = mostrarSlider
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

local SliderTrack = Instance.new("Frame")
SliderTrack.Name = "SliderTrack"
SliderTrack.Size = UDim2.new(0.5, 0, 0, 8)
SliderTrack.Position = UDim2.new(0.22, 0, 0.5, -4)
SliderTrack.BackgroundColor3 = Theme.BackgroundTertiary
SliderTrack.Parent = SliderSection
UI.CreateCorner(SliderTrack, 4)

local SliderFill = Instance.new("Frame")
SliderFill.Name = "SliderFill"
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = Theme.Primary
SliderFill.Parent = SliderTrack
UI.CreateCorner(SliderFill, 4)

local SliderKnob = Instance.new("Frame")
SliderKnob.Name = "SliderKnob"
SliderKnob.Size = UDim2.new(0, 16, 0, 16)
SliderKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
SliderKnob.BackgroundColor3 = Theme.TextPrimary
SliderKnob.ZIndex = 3
SliderKnob.Parent = SliderTrack
UI.CreateCorner(SliderKnob, 8)
UI.CreateStroke(SliderKnob, Theme.Primary, 2)

posY = posY + (sliderHeight > 0 and (sliderHeight + 4) or 0)

-- ════════════════════════════════════════════════════════════════════════════════
-- SCROLL FRAME
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
ContentPadding.PaddingTop = UDim.new(0, 2)
ContentPadding.PaddingBottom = UDim.new(0, 6)
ContentPadding.PaddingLeft = UDim.new(0, 4)
ContentPadding.PaddingRight = UDim.new(0, 4)
ContentPadding.Parent = ScrollFrame

-- ════════════════════════════════════════════════════════════════════════════════
-- FUNCIONES HELPER
-- ════════════════════════════════════════════════════════════════════════════════

local function EncontrarNombre(BaileId)
	if Modulo.Ids then
		for _, v in pairs(Modulo.Ids) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	if Modulo.Vip then
		for _, v in pairs(Modulo.Vip) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	if Modulo.Recomendado then
		for _, v in pairs(Modulo.Recomendado) do
			if v.ID == BaileId then return v.Nombre end
		end
	end
	return "Dance"
end

local function EsFavorito(id)
	return table.find(EmotesFavs, id) ~= nil
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR ELEMENTOS UI
-- ════════════════════════════════════════════════════════════════════════════════

local function CrearSeparador(texto, icono, color, orden)
	local separator = Instance.new("Frame")
	separator.Name = "Sep_" .. texto
	separator.Size = UDim2.new(1, 0, 0, IsMobile and 16 or 22)
	separator.BackgroundTransparency = 1
	separator.LayoutOrder = orden
	separator:SetAttribute("IsEmoteElement", true)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = (icono or "") .. " " .. texto .. " " .. (icono or "")
	label.TextColor3 = color or Theme.TextSecondary
	label.TextSize = IsMobile and 9 or 12
	label.Parent = separator

	return separator
end

local function CrearTarjeta(nombre, id, tipo, orden, bloqueado)
	local cardHeight = IsMobile and 28 or 36
	local cardColor = Theme[tipo] or Theme.Normal
	local esActivo = (DanceActivated == nombre)
	local esFav = EsFavorito(id)

	local card = Instance.new("TextButton")
	card.Name = "Card_" .. id
	card.Size = UDim2.new(1, 0, 0, cardHeight)
	card.BackgroundColor3 = cardColor
	card.BorderSizePixel = 0
	card.LayoutOrder = orden
	card.Text = ""
	card.AutoButtonColor = false
	card:SetAttribute("IsEmoteElement", true)
	card:SetAttribute("EmoteID", id)
	card:SetAttribute("EmoteName", nombre)
	card:SetAttribute("Bloqueado", bloqueado or false)
	UI.CreateCorner(card, IsMobile and 5 or 8)
	UI.CreateGradient(card, cardColor, Color3.fromRGB(0, 0, 0), 180)

	-- Borde activo (inicialmente transparente)
	local activeBorder = UI.CreateStroke(card, cardColor, 3, 1)
	activeBorder.Name = "ActiveBorder"

	-- Overlay de brillo cuando está activo
	local activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "ActiveOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.BackgroundColor3 = cardColor
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.BorderSizePixel = 0
	activeOverlay.ZIndex = 2
	activeOverlay.Parent = card
	UI.CreateCorner(activeOverlay, IsMobile and 5 or 8)

	-- Barra lateral indicadora (color de la categoría)
	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.Size = UDim2.new(0, 0, 1, 0)
	activeBar.Position = UDim2.new(0, 0, 0, 0)
	activeBar.BackgroundColor3 = cardColor
	activeBar.BorderSizePixel = 0
	activeBar.ZIndex = 10
	activeBar.Parent = card
	UI.CreateCorner(activeBar, IsMobile and 5 or 8)

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, IsMobile and -32 or -40, 1, 0)
	nameLabel.Position = UDim2.new(0, IsMobile and 6 or 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = nombre
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = IsMobile and 10 or 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 3
	nameLabel.Parent = card

	-- Favorito
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "FavBtn"
	favBtn.Size = UDim2.new(0, IsMobile and 22 or 28, 1, 0)
	favBtn.Position = UDim2.new(1, IsMobile and -22 or -28, 0, 0)
	favBtn.BackgroundTransparency = 1
	favBtn.Text = esFav and "★" or "☆"
	favBtn.TextColor3 = esFav and Theme.Warning or Color3.fromRGB(80, 80, 80)
	favBtn.TextSize = IsMobile and 14 or 18
	favBtn.Font = Enum.Font.GothamBold
	favBtn.ZIndex = 5
	favBtn.Parent = card

	-- Si está activo, animar entrada
	if esActivo then
		task.defer(function()
			UI.Tween(activeBorder, 0.3, {Transparency = 0})
			UI.Tween(activeOverlay, 0.3, {BackgroundTransparency = 0.85})
			UI.Tween(activeBar, 0.4, {Size = UDim2.new(0, 4, 1, 0)}, Enum.EasingStyle.Back)
		end)
	end

	return card, favBtn, activeBorder, activeOverlay, activeBar
end

-- ════════════════════════════════════════════════════════════════════════════════
-- FUNCIÓN ACTUALIZAR (SIMPLIFICADA)
-- ════════════════════════════════════════════════════════════════════════════════

local Actualizar

local function LimpiarScroll()
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("IsEmoteElement") then
			child:Destroy()
		end
	end
end

local function ToggleFavorito(id, nombre)
	local status = AnadirFav:InvokeServer(id)

	if status == "Anadido" then
		NotificationSystem:Success("Favorito", nombre .. " añadido", 2)
		EmotesFavs = ObtenerFavs:InvokeServer() or {}
		Actualizar()
	elseif status == "Eliminada" then
		NotificationSystem:Success("Favorito", nombre .. " eliminado", 2)
		EmotesFavs = ObtenerFavs:InvokeServer() or {}
		Actualizar()
	end
end

local function ToggleBaile(nombre, card, activeBorder)
	local activeOverlay = card:FindFirstChild("ActiveOverlay")
	local activeBar = card:FindFirstChild("ActiveBar")

	if DanceActivated == nombre then
		-- Detener baile
		DanceActivated = nil
		StopAnimationRemote:FireServer()

		-- Animación de desactivar
		UI.Tween(activeBorder, 0.2, {Transparency = 1})
		if activeOverlay then
			UI.Tween(activeOverlay, 0.2, {BackgroundTransparency = 1})
		end
		if activeBar then
			UI.Tween(activeBar, 0.2, {Size = UDim2.new(0, 0, 1, 0)})
		end
	else
		-- Primero desactivar el anterior visualmente
		for _, child in ipairs(ScrollFrame:GetChildren()) do
			if child:GetAttribute("IsEmoteElement") and child:IsA("TextButton") then
				local border = child:FindFirstChild("ActiveBorder")
				local overlay = child:FindFirstChild("ActiveOverlay")
				local bar = child:FindFirstChild("ActiveBar")

				if border then UI.Tween(border, 0.15, {Transparency = 1}) end
				if overlay then UI.Tween(overlay, 0.15, {BackgroundTransparency = 1}) end
				if bar then UI.Tween(bar, 0.15, {Size = UDim2.new(0, 0, 1, 0)}) end
			end
		end

		-- Activar nuevo baile
		DanceActivated = nombre
		PlayAnimationRemote:FireServer("playAnim", nombre)

		-- Animación de activar
		UI.Tween(activeBorder, 0.3, {Transparency = 0})
		if activeOverlay then
			UI.Tween(activeOverlay, 0.3, {BackgroundTransparency = 0.85})
		end
		if activeBar then
			UI.Tween(activeBar, 0.4, {Size = UDim2.new(0, 4, 1, 0)}, Enum.EasingStyle.Back)
		end
	end
end

local function PromptVIP()
	NotificationSystem:Warning("VIP", "Necesitas el GamePass VIP", 3)
	task.wait(0.3)
	MarketplaceService:PromptGamePassPurchase(Jugador, VIPGamePassID)
end

Actualizar = function(filtro)
	filtro = filtro or SearchBox.Text or ""
	local filtroLower = filtro:lower()

	local function pasaFiltro(nombre)
		if filtroLower == "" then return true end
		return nombre:lower():find(filtroLower, 1, true) ~= nil
	end

	-- Guardar scroll
	local scrollPos = ScrollFrame.CanvasPosition.Y

	-- Limpiar
	LimpiarScroll()

	local orden = 1

	-- FAVORITOS
	if #EmotesFavs > 0 then
		local favs = {}
		for _, id in ipairs(EmotesFavs) do
			local nombre = EncontrarNombre(id)
			if pasaFiltro(nombre) then
				table.insert(favs, {id = id, nombre = nombre})
			end
		end

		if #favs > 0 then
			CrearSeparador("FAVORITOS", "⭐", Theme.Favorites, orden).Parent = ScrollFrame
			orden = orden + 1

			for _, data in ipairs(favs) do
				local card, favBtn, border = CrearTarjeta(data.nombre, data.id, "Favorites", orden, false)
				card.Parent = ScrollFrame

				card.MouseButton1Click:Connect(function()
					ToggleBaile(data.nombre, card, border)
				end)

				favBtn.MouseButton1Click:Connect(function()
					ToggleFavorito(data.id, data.nombre)
				end)

				orden = orden + 1
			end
		end
	end

	-- TRENDING
	if #EmotesTrending > 0 then
		local trending = {}
		for _, id in ipairs(EmotesTrending) do
			if not EsFavorito(id) then
				local nombre = EncontrarNombre(id)
				if pasaFiltro(nombre) then
					table.insert(trending, {id = id, nombre = nombre})
				end
			end
		end

		if #trending > 0 then
			CrearSeparador("TRENDING", "🔥", Theme.Trending, orden).Parent = ScrollFrame
			orden = orden + 1

			for _, data in ipairs(trending) do
				local card, favBtn, border = CrearTarjeta(data.nombre, data.id, "Trending", orden, false)
				card.Parent = ScrollFrame

				card.MouseButton1Click:Connect(function()
					ToggleBaile(data.nombre, card, border)
				end)

				favBtn.MouseButton1Click:Connect(function()
					ToggleFavorito(data.id, data.nombre)
				end)

				orden = orden + 1
			end
		end
	end

	-- VIP
	if Modulo.Vip and #Modulo.Vip > 0 then
		local vips = {}
		for _, v in ipairs(Modulo.Vip) do
			if not EsFavorito(v.ID) and not table.find(EmotesTrending, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(vips, v)
				end
			end
		end

		if #vips > 0 then
			CrearSeparador("VIP", "👑", Theme.VIP, orden).Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(vips) do
				local card, favBtn, border = CrearTarjeta(v.Nombre, v.ID, "VIP", orden, not TieneVIP)
				card.Parent = ScrollFrame

				if TieneVIP then
					card.MouseButton1Click:Connect(function()
						ToggleBaile(v.Nombre, card, border)
					end)
				else
					card.MouseButton1Click:Connect(PromptVIP)
				end

				favBtn.MouseButton1Click:Connect(function()
					ToggleFavorito(v.ID, v.Nombre)
				end)

				orden = orden + 1
			end
		end
	end

	-- RECOMENDADOS
	if Modulo.Recomendado and #Modulo.Recomendado > 0 then
		local recs = {}
		for _, v in ipairs(Modulo.Recomendado) do
			if not EsFavorito(v.ID) and not table.find(EmotesTrending, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(recs, v)
				end
			end
		end

		if #recs > 0 then
			CrearSeparador("RECOMENDADOS", "💡", Theme.Recommended, orden).Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(recs) do
				local card, favBtn, border = CrearTarjeta(v.Nombre, v.ID, "Recommended", orden, false)
				card.Parent = ScrollFrame

				card.MouseButton1Click:Connect(function()
					ToggleBaile(v.Nombre, card, border)
				end)

				favBtn.MouseButton1Click:Connect(function()
					ToggleFavorito(v.ID, v.Nombre)
				end)

				orden = orden + 1
			end
		end
	end

	-- TODOS
	if Modulo.Ids and #Modulo.Ids > 0 then
		local todos = {}
		for _, v in ipairs(Modulo.Ids) do
			if not EsFavorito(v.ID) and not table.find(EmotesTrending, v.ID) then
				if pasaFiltro(v.Nombre) then
					table.insert(todos, v)
				end
			end
		end

		if #todos > 0 then
			CrearSeparador("TODOS", "🎵", Theme.Normal, orden).Parent = ScrollFrame
			orden = orden + 1

			for _, v in ipairs(todos) do
				local card, favBtn, border = CrearTarjeta(v.Nombre, v.ID, "Normal", orden, false)
				card.Parent = ScrollFrame

				card.MouseButton1Click:Connect(function()
					ToggleBaile(v.Nombre, card, border)
				end)

				favBtn.MouseButton1Click:Connect(function()
					ToggleFavorito(v.ID, v.Nombre)
				end)

				orden = orden + 1
			end
		end
	end

	-- Restaurar scroll
	task.defer(function()
		ScrollFrame.CanvasPosition = Vector2.new(0, scrollPos)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER LÓGICA
-- ════════════════════════════════════════════════════════════════════════════════

local sliderDragging = false
local speedValues = {0.01, 0.05, 0.3, 0.5, 0.7, 1, 1.3, 1.6, 1.9, 2.2, 2.5}
local currentSpeedIndex = 6

local function UpdateSlider(percentage)
	percentage = math.clamp(percentage, 0, 1)
	SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
	SliderKnob.Position = UDim2.new(percentage, -8, 0.5, -8)

	local index = math.clamp(math.floor(percentage * 10) + 1, 1, 11)
	SpeedValue.Text = string.format("%.1fx", speedValues[index])

	if index ~= currentSpeedIndex then
		currentSpeedIndex = index
		PlayAnimationRemote:FireServer("speed", speedValues[index])
	end
end

SliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
		local relX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
		UpdateSlider(relX)
	end
end)

SliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local relX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
		UpdateSlider(relX)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)

UpdateSlider(0.5)

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

local searchDebounce = false
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.25, function()
		Actualizar()
		searchDebounce = false
	end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- TOGGLE GUI
-- ════════════════════════════════════════════════════════════════════════════════

local function ToggleGUI(visible)
	if visible then
		MainFrame.Visible = true
		MainFrame.BackgroundTransparency = 1
		UI.Tween(MainFrame, 0.25, {BackgroundTransparency = 0})
	else
		UI.Tween(MainFrame, 0.2, {BackgroundTransparency = 1}).Completed:Wait()
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
-- SINCRONIZACIÓN
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
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- RESPONSIVE
-- ════════════════════════════════════════════════════════════════════════════════

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local newMobile = EsMovil()
	if newMobile ~= IsMobile then
		IsMobile = newMobile
		if IsMobile then
			MainFrame.Size = UDim2.new(0, Config.Movil_Ancho, 0, Config.Movil_Alto)
			MainFrame.Position = UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
		else
			MainFrame.Size = UDim2.new(0, Config.PC_Ancho, 0, Config.PC_Alto)
			MainFrame.Position = UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)
		end
		Actualizar()
	end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

-- Cargar datos iniciales
EmotesFavs = ObtenerFavs:InvokeServer() or {}
EmotesTrending = ObtenerTrending:InvokeServer() or {}
TieneVIP = Ownership:InvokeServer(VIPGamePassID) or false

-- Renderizar
Actualizar()

