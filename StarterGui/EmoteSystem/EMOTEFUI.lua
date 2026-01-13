--[[
	═══════════════════════════════════════════════════════════════════════════════
	   EMOTES SYSTEM - TABS (Optimizado con gestión de memoria)
	═══════════════════════════════════════════════════════════════════════════════
]]--

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

local Config = {
	PC_Ancho = 180,
	PC_Alto = 380,
	PC_MargenIzquierdo = 5,
	PC_OffsetVertical = 40,

	Movil_Ancho = 150,
	Movil_Alto = 250,
	Movil_MargenIzquierdo = 5,
	Movil_OffsetVertical = 10,

	Movil_MostrarSlider = false,
	Movil_MostrarBusqueda = true,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- SERVICIOS
-- ════════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
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
	Warning = THEME_CONFIG.warn,
	TextPrimary = THEME_CONFIG.text,
	TextSecondary = THEME_CONFIG.muted,
	TextMuted = THEME_CONFIG.subtle,
	Border = THEME_CONFIG.stroke,
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

local IsMobile = UserInputService.TouchEnabled
local EmotesFavs = {}
local EmotesTrending = {}
local DanceActivated = nil
local ActiveCard = nil
local tieneVIP = false
local TabActual = "Todos"

-- Gestión de memoria
local CardConnections = {}
local ActiveTweens = {}

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════════════════════════════════════════════

local function Tween(obj, dur, props, style)
	local tween = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function CreateCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
end

local function CreateStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function GetCardHeight()
	return IsMobile and 28 or 38
end

local function EncontrarDatos(BaileId)
	for _, lista in ipairs({Modulo.Ids, Modulo.Vip, Modulo.Recomendado}) do
		if lista then
			for _, v in pairs(lista) do
				if v.ID == BaileId then return v.Nombre, lista == Modulo.Vip end
			end
		end
	end
	return "Dance", false
end

local function EstaEnFavoritos(id)
	return table.find(EmotesFavs, id) ~= nil
end

local function ObtenerTipo(id)
	if table.find(EmotesTrending or {}, id) then return "Trending" end
	for _, v in ipairs(Modulo.Vip or {}) do if v.ID == id then return "VIP" end end
	for _, v in ipairs(Modulo.Recomendado or {}) do if v.ID == id then return "Recommended" end end
	return "Normal"
end

-- ════════════════════════════════════════════════════════════════════════════════
-- GESTIÓN DE MEMORIA
-- ════════════════════════════════════════════════════════════════════════════════

local function TrackConnection(card, connection)
	if not CardConnections[card] then
		CardConnections[card] = {}
	end
	table.insert(CardConnections[card], connection)
end

local function TrackTween(card, tween)
	if not ActiveTweens[card] then
		ActiveTweens[card] = {}
	end
	table.insert(ActiveTweens[card], tween)
end

local function CleanupCard(card)
	if ActiveTweens[card] then
		for _, tween in ipairs(ActiveTweens[card]) do
			tween:Cancel()
		end
		ActiveTweens[card] = nil
	end

	if CardConnections[card] then
		for _, conn in ipairs(CardConnections[card]) do
			conn:Disconnect()
		end
		CardConnections[card] = nil
	end
end

local function CleanupAllCards()
	for card in pairs(CardConnections) do
		CleanupCard(card)
	end
	CardConnections = {}
	ActiveTweens = {}
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ANIMACIÓN ACTIVA
-- ════════════════════════════════════════════════════════════════════════════════

local function AplicarEfectoActivo(card)
	if not card or not card.Parent then return end

	local border = card:FindFirstChild("ActiveBorder")
	local overlay = card:FindFirstChild("ActiveOverlay")
	local cardHeight = GetCardHeight()

	if border then
		TrackTween(card, Tween(border, 0.3, {Transparency = 0, Thickness = 3}))
	end

	if overlay then
		TrackTween(card, Tween(overlay, 0.3, {BackgroundTransparency = 0.85}))
	end

	TrackTween(card, Tween(card, 0.25, {Size = UDim2.new(1, 6, 0, cardHeight + 4)}, Enum.EasingStyle.Back))
end

local function RemoverEfectoActivo(card)
	if not card or not card.Parent then return end

	local border = card:FindFirstChild("ActiveBorder")
	local overlay = card:FindFirstChild("ActiveOverlay")
	local cardHeight = GetCardHeight()

	if border then
		TrackTween(card, Tween(border, 0.2, {Transparency = 1, Thickness = 2}))
	end

	if overlay then
		TrackTween(card, Tween(overlay, 0.2, {BackgroundTransparency = 1}))
	end

	TrackTween(card, Tween(card, 0.2, {Size = UDim2.new(1, 0, 0, cardHeight)}))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- GUI PRINCIPAL
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

CreateCorner(MainFrame, 12)
CreateStroke(MainFrame, Theme.Border, 1, 0.5)

-- ════════════════════════════════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════════════════════════════════

local TabsContainer = Instance.new("Frame")
TabsContainer.Name = "TabsContainer"
TabsContainer.Size = UDim2.new(1, -16, 0, IsMobile and 24 or 30)
TabsContainer.Position = UDim2.new(0, 8, 0, 8)
TabsContainer.BackgroundColor3 = Theme.BackgroundSecondary
TabsContainer.BorderSizePixel = 0
TabsContainer.Parent = MainFrame
CreateCorner(TabsContainer, 8)

local TabIndicator = Instance.new("Frame")
TabIndicator.Name = "TabIndicator"
TabIndicator.Size = UDim2.new(0.5, -4, 1, -4)
TabIndicator.Position = UDim2.new(0, 2, 0, 2)
TabIndicator.BackgroundColor3 = Theme.Primary
TabIndicator.BorderSizePixel = 0
TabIndicator.ZIndex = 2
TabIndicator.Parent = TabsContainer
CreateCorner(TabIndicator, 6)

local TabTodos = Instance.new("TextButton")
TabTodos.Name = "TabTodos"
TabTodos.Size = UDim2.new(0.5, 0, 1, 0)
TabTodos.BackgroundTransparency = 1
TabTodos.Font = Enum.Font.GothamBold
TabTodos.Text = "Todos"
TabTodos.TextColor3 = Theme.TextPrimary
TabTodos.TextSize = IsMobile and 12 or 14
TabTodos.ZIndex = 3
TabTodos.Parent = TabsContainer

local TabFavoritos = Instance.new("TextButton")
TabFavoritos.Name = "TabFavoritos"
TabFavoritos.Size = UDim2.new(0.5, 0, 1, 0)
TabFavoritos.Position = UDim2.new(0.5, 0, 0, 0)
TabFavoritos.BackgroundTransparency = 1
TabFavoritos.Font = Enum.Font.GothamBold
TabFavoritos.Text = "Favoritos"
TabFavoritos.TextColor3 = Theme.TextSecondary
TabFavoritos.TextSize = IsMobile and 12 or 14
TabFavoritos.ZIndex = 3
TabFavoritos.Parent = TabsContainer

local posY = IsMobile and 36 or 42

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarBusqueda = IsMobile and Config.Movil_MostrarBusqueda or true
local SearchContainer, SearchBox

if mostrarBusqueda then
	SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -16, 0, IsMobile and 26 or 32)
	SearchContainer.Position = UDim2.new(0, 8, 0, posY)
	SearchContainer.BackgroundColor3 = Theme.BackgroundSecondary
	SearchContainer.BorderSizePixel = 0
	SearchContainer.Parent = MainFrame
	CreateCorner(SearchContainer, 8)
	CreateStroke(SearchContainer, Theme.Border, 1, 0.3)

	SearchBox = Instance.new("TextBox")
	SearchBox.Size = UDim2.new(1, -16, 1, 0)
	SearchBox.Position = UDim2.new(0, 10, 0, 0)
	SearchBox.BackgroundTransparency = 1
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.PlaceholderText = "Buscar baile..."
	SearchBox.PlaceholderColor3 = Theme.TextMuted
	SearchBox.Text = ""
	SearchBox.TextColor3 = Theme.TextPrimary
	SearchBox.TextSize = IsMobile and 11 or 14
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.ClearTextOnFocus = false
	SearchBox.Parent = SearchContainer

	posY = posY + (IsMobile and 30 or 36)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarSlider = IsMobile and Config.Movil_MostrarSlider or true
local SpeedValue, SliderFill, SliderKnob, SliderTrack

if mostrarSlider then
	local SliderSection = Instance.new("Frame")
	SliderSection.Name = "SliderSection"
	SliderSection.Size = UDim2.new(1, -16, 0, 32)
	SliderSection.Position = UDim2.new(0, 8, 0, posY)
	SliderSection.BackgroundColor3 = Theme.BackgroundSecondary
	SliderSection.BorderSizePixel = 0
	SliderSection.Parent = MainFrame
	CreateCorner(SliderSection, 8)

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
	SliderTrack.Size = UDim2.new(0.5, 0, 0, 8)
	SliderTrack.Position = UDim2.new(0.22, 0, 0.5, -4)
	SliderTrack.BackgroundColor3 = Theme.BackgroundTertiary
	SliderTrack.BorderSizePixel = 0
	SliderTrack.Parent = SliderSection
	CreateCorner(SliderTrack, 4)

	SliderFill = Instance.new("Frame")
	SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
	SliderFill.BackgroundColor3 = Theme.Primary
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderTrack
	CreateCorner(SliderFill, 4)

	SliderKnob = Instance.new("Frame")
	SliderKnob.Size = UDim2.new(0, 16, 0, 16)
	SliderKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
	SliderKnob.BackgroundColor3 = Theme.TextPrimary
	SliderKnob.BorderSizePixel = 0
	SliderKnob.ZIndex = 3
	SliderKnob.Parent = SliderTrack
	CreateCorner(SliderKnob, 8)
	CreateStroke(SliderKnob, Theme.Primary, 2)

	posY = posY + 36
else
	posY = posY + 4
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CONTENEDOR DE SCROLL
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

local EmptyMessage = Instance.new("TextLabel")
EmptyMessage.Name = "EmptyMessage"
EmptyMessage.Size = UDim2.new(0, 0, 0, 0) -- Empieza sin tamaño
EmptyMessage.BackgroundTransparency = 1
EmptyMessage.Font = Enum.Font.GothamMedium
EmptyMessage.Text = "Sin favoritos\nToca la estrella en cualquier baile"
EmptyMessage.TextColor3 = Theme.TextMuted
EmptyMessage.TextSize = IsMobile and 11 or 13
EmptyMessage.Visible = false
EmptyMessage.LayoutOrder = 999 -- Al final
EmptyMessage.Parent = ScrollFrame

local function MostrarEmptyMessage(mostrar, texto)
	if texto then EmptyMessage.Text = texto end
	EmptyMessage.Visible = mostrar
	EmptyMessage.Size = mostrar and UDim2.new(1, 0, 0, 60) or UDim2.new(0, 0, 0, 0)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR TARJETA
-- ════════════════════════════════════════════════════════════════════════════════

local function CrearSeparador(texto, icono, color, orden)
	local separator = Instance.new("Frame")
	separator.Name = "Sep_" .. texto
	separator.Size = UDim2.new(1, 0, 0, IsMobile and 16 or 22)
	separator.BackgroundTransparency = 1
	separator.LayoutOrder = orden
	separator:SetAttribute("Entry", true)
	separator.Parent = ScrollFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = icono .. " " .. texto
	label.TextColor3 = color
	label.TextSize = IsMobile and 9 or 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = separator
end

local function CrearTarjeta(nombre, id, tipo, orden, esVIP)
	local cardColor = Theme[tipo] or Theme.Normal
	local esFavorito = EstaEnFavoritos(id)
	local esVIPBloqueado = esVIP and not tieneVIP
	local cardHeight = GetCardHeight()

	local card = Instance.new("TextButton")
	card.Name = "Card_" .. id
	card.Size = UDim2.new(1, 0, 0, cardHeight)
	card.BackgroundColor3 = cardColor
	card.BorderSizePixel = 0
	card.LayoutOrder = orden
	card.Text = ""
	card.AutoButtonColor = false
	card:SetAttribute("Entry", true)
	card:SetAttribute("ID", id)
	card:SetAttribute("Name", nombre)
	card.Parent = ScrollFrame

	CreateCorner(card, IsMobile and 5 or 8)

	-- Gradient negro
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cardColor),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	})
	gradient.Rotation = 180
	gradient.Parent = card

	-- Overlay para efecto activo
	local activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "ActiveOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.BorderSizePixel = 0
	activeOverlay.ZIndex = 2
	activeOverlay.Parent = card
	CreateCorner(activeOverlay, IsMobile and 5 or 8)

	-- Borde activo
	local activeBorder = Instance.new("UIStroke")
	activeBorder.Name = "ActiveBorder"
	activeBorder.Color = Color3.fromRGB(255, 255, 255)
	activeBorder.Thickness = 2
	activeBorder.Transparency = 1
	activeBorder.Parent = card

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, IsMobile and -30 or -40, 1, 0)
	nameLabel.Position = UDim2.new(0, IsMobile and 8 or 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = nombre
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = IsMobile and 10 or 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 3
	nameLabel.Parent = card

	-- Botón favorito
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "FavBtn"
	favBtn.Size = UDim2.new(0, IsMobile and 24 or 32, 1, 0)
	favBtn.Position = UDim2.new(1, IsMobile and -24 or -32, 0, 0)
	favBtn.BackgroundTransparency = 1
	favBtn.Text = esFavorito and "★" or "☆"
	favBtn.TextColor3 = esFavorito and Theme.Warning or Color3.fromRGB(80, 80, 80)
	favBtn.TextSize = IsMobile and 14 or 18
	favBtn.Font = Enum.Font.GothamBold
	favBtn.ZIndex = 4
	favBtn.Parent = card

	-- Hover
	TrackConnection(card, card.MouseEnter:Connect(function()
		Tween(card, 0.15, {BackgroundColor3 = cardColor:Lerp(Color3.fromRGB(255,255,255), 0.15)})
	end))

	TrackConnection(card, card.MouseLeave:Connect(function()
		Tween(card, 0.15, {BackgroundColor3 = cardColor})
	end))

	-- Click tarjeta
	TrackConnection(card, card.MouseButton1Click:Connect(function()
		if esVIPBloqueado then
			NotificationSystem:Warning("VIP", "Necesitas VIP para este baile", 3)
			task.wait(0.3)
			MarketplaceService:PromptGamePassPurchase(Jugador, VIPGamePassID)
			return
		end

		if DanceActivated == nombre then
			DanceActivated = nil
			StopAnimationRemote:FireServer()
			RemoverEfectoActivo(card)
			ActiveCard = nil
		else
			if ActiveCard and ActiveCard.Parent then
				RemoverEfectoActivo(ActiveCard)
			end

			DanceActivated = nombre
			ActiveCard = card
			PlayAnimationRemote:FireServer("playAnim", nombre)
			AplicarEfectoActivo(card)
		end
	end))

	-- Click favorito
	TrackConnection(card, favBtn.MouseButton1Click:Connect(function()
		local success, status = pcall(function()
			return AnadirFav:InvokeServer(id)
		end)

		if not success then
			NotificationSystem:Error("Error", "Error de conexión", 2)
			return
		end

		if status == "Anadido" then
			table.insert(EmotesFavs, id)
			NotificationSystem:Success("Favorito", nombre .. " añadido", 2)

			for _, child in ipairs(ScrollFrame:GetChildren()) do
				if child:GetAttribute("ID") == id then
					local btn = child:FindFirstChild("FavBtn")
					if btn then
						btn.Text = "★"
						btn.TextColor3 = Theme.Warning
					end
				end
			end

		elseif status == "Eliminada" then
			local idx = table.find(EmotesFavs, id)
			if idx then table.remove(EmotesFavs, idx) end
			NotificationSystem:Success("Favorito", nombre .. " quitado", 2)

			if TabActual == "Favoritos" then
				CleanupCard(card)

				Tween(card, 0.25, {
					Position = UDim2.new(1.5, 0, 0, 0),
					BackgroundTransparency = 0.8
				}, Enum.EasingStyle.Back)

				task.delay(0.2, function()
					local t = Tween(card, 0.15, {Size = UDim2.new(1, 0, 0, 0)})
					t.Completed:Connect(function()
						card:Destroy()
						if #EmotesFavs == 0 then
							MostrarEmptyMessage(true, "Sin favoritos\nToca la estrella en cualquier baile")
						end
					end)
				end)
			else
				for _, child in ipairs(ScrollFrame:GetChildren()) do
					if child:GetAttribute("ID") == id then
						local btn = child:FindFirstChild("FavBtn")
						if btn then
							btn.Text = "☆"
							btn.TextColor3 = Color3.fromRGB(80, 80, 80)
						end
					end
				end
			end
		end
	end))

	return card
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CARGAR CONTENIDO
-- ════════════════════════════════════════════════════════════════════════════════

local function LimpiarScroll()
	CleanupAllCards()

	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("Entry") then
			child:Destroy()
		end
	end
	MostrarEmptyMessage(false)
	ActiveCard = nil
end

local function RestaurarBaileActivo()
	if not DanceActivated then return end

	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("Name") == DanceActivated then
			ActiveCard = child
			AplicarEfectoActivo(child)
			break
		end
	end
end

local function CargarTodos(filtro)
	LimpiarScroll()

	filtro = (filtro or ""):lower()
	local orden = 1

	local function pasaFiltro(nombre)
		return filtro == "" or nombre:lower():find(filtro, 1, true)
	end

	if EmotesTrending and #EmotesTrending > 0 then
		local hayVisibles = false
		for _, id in ipairs(EmotesTrending) do
			local nombre = EncontrarDatos(id)
			if pasaFiltro(nombre) then
				if not hayVisibles then
					CrearSeparador("TRENDING", "🔥", Theme.Trending, orden)
					orden = orden + 1
					hayVisibles = true
				end
				CrearTarjeta(nombre, id, "Trending", orden, false)
				orden = orden + 1
			end
		end
	end

	if Modulo.Vip and #Modulo.Vip > 0 then
		local hayVisibles = false
		for _, v in ipairs(Modulo.Vip) do
			if not table.find(EmotesTrending or {}, v.ID) and pasaFiltro(v.Nombre) then
				if not hayVisibles then
					CrearSeparador("VIP", "👑", Theme.VIP, orden)
					orden = orden + 1
					hayVisibles = true
				end
				CrearTarjeta(v.Nombre, v.ID, "VIP", orden, true)
				orden = orden + 1
			end
		end
	end

	if Modulo.Recomendado and #Modulo.Recomendado > 0 then
		local hayVisibles = false
		for _, v in ipairs(Modulo.Recomendado) do
			if not table.find(EmotesTrending or {}, v.ID) and pasaFiltro(v.Nombre) then
				if not hayVisibles then
					CrearSeparador("RECOMENDADOS", "💡", Theme.Recommended, orden)
					orden = orden + 1
					hayVisibles = true
				end
				CrearTarjeta(v.Nombre, v.ID, "Recommended", orden, false)
				orden = orden + 1
			end
		end
	end

	if Modulo.Ids and #Modulo.Ids > 0 then
		local hayVisibles = false
		for _, v in ipairs(Modulo.Ids) do
			if not table.find(EmotesTrending or {}, v.ID) and pasaFiltro(v.Nombre) then
				if not hayVisibles then
					CrearSeparador("TODOS", "🎵", Theme.Normal, orden)
					orden = orden + 1
					hayVisibles = true
				end
				CrearTarjeta(v.Nombre, v.ID, "Normal", orden, false)
				orden = orden + 1
			end
		end
	end

	RestaurarBaileActivo()
end

local function CargarFavoritos(filtro)
	LimpiarScroll()

	if #EmotesFavs == 0 then
		MostrarEmptyMessage(true, "Sin favoritos\nToca la estrella en cualquier baile")
		return
	end

	filtro = (filtro or ""):lower()
	local orden = 1
	local hayVisibles = false

	for _, id in ipairs(EmotesFavs) do
		local nombre, esVIP = EncontrarDatos(id)
		if filtro == "" or nombre:lower():find(filtro, 1, true) then
			local tipo = ObtenerTipo(id)
			CrearTarjeta(nombre, id, tipo, orden, esVIP)
			orden = orden + 1
			hayVisibles = true
		end
	end

	if not hayVisibles then
		MostrarEmptyMessage(true, "Sin resultados")
	end

	RestaurarBaileActivo()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CAMBIO DE TABS
-- ════════════════════════════════════════════════════════════════════════════════

local function CambiarTab(tab)
	if tab == TabActual then return end
	TabActual = tab

	local filtro = SearchBox and SearchBox.Text or ""

	if tab == "Todos" then
		Tween(TabIndicator, 0.25, {Position = UDim2.new(0, 2, 0, 2)}, Enum.EasingStyle.Back)
		TabTodos.TextColor3 = Theme.TextPrimary
		TabFavoritos.TextColor3 = Theme.TextSecondary
		CargarTodos(filtro)
	else
		Tween(TabIndicator, 0.25, {Position = UDim2.new(0.5, 2, 0, 2)}, Enum.EasingStyle.Back)
		TabTodos.TextColor3 = Theme.TextSecondary
		TabFavoritos.TextColor3 = Theme.TextPrimary
		CargarFavoritos(filtro)
	end
end

TabTodos.MouseButton1Click:Connect(function() CambiarTab("Todos") end)
TabFavoritos.MouseButton1Click:Connect(function() CambiarTab("Favoritos") end)

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA
-- ════════════════════════════════════════════════════════════════════════════════

if SearchBox then
	local searchDebounce = false
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounce then return end
		searchDebounce = true
		task.delay(0.25, function()
			if TabActual == "Todos" then
				CargarTodos(SearchBox.Text)
			else
				CargarFavoritos(SearchBox.Text)
			end
			searchDebounce = false
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER
-- ════════════════════════════════════════════════════════════════════════════════

if SliderTrack then
	local sliderDragging = false
	local speedValues = {0.01, 0.05, 0.3, 0.5, 0.7, 1, 1.3, 1.6, 1.9, 2.2, 2.5}
	local currentSpeedIndex = 6

	local function UpdateSlider(pct)
		pct = math.clamp(pct, 0, 1)
		SliderFill.Size = UDim2.new(pct, 0, 1, 0)
		SliderKnob.Position = UDim2.new(pct, -8, 0.5, -8)
		local idx = math.clamp(math.floor(pct * 10) + 1, 1, 11)
		SpeedValue.Text = string.format("%.1fx", speedValues[idx])
		if idx ~= currentSpeedIndex then
			currentSpeedIndex = idx
			PlayAnimationRemote:FireServer("speed", speedValues[idx])
		end
	end

	SliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
			UpdateSlider((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X)
		end
	end)

	SliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateSlider((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = false
		end
	end)

	UpdateSlider(0.5)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TOGGLE GUI
-- ════════════════════════════════════════════════════════════════════════════════

local function ToggleGUI(visible)
	if visible then
		MainFrame.Visible = true
		MainFrame.BackgroundTransparency = 1
		Tween(MainFrame, 0.3, {BackgroundTransparency = 0})
	else
		local t = Tween(MainFrame, 0.2, {BackgroundTransparency = 1})
		t.Completed:Wait()
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
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

EmotesFavs = ObtenerFavs:InvokeServer() or {}
EmotesTrending = ObtenerTrending:InvokeServer() or {}
tieneVIP = Ownership:InvokeServer(VIPGamePassID)
CargarTodos()