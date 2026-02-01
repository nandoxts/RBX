--[[
	═══════════════════════════════════════════════════════════════════════════════
	   EMOTES SYSTEM 
	═══════════════════════════════════════════════════════════════════════════════
]]--

-- Autor: ignxts

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

local Config = {
	PC_Ancho = 200,
	PC_Alto = 400,
	PC_MargenIzquierdo = 5,
	PC_OffsetVertical = 70,

	Movil_Ancho = 150,
	Movil_Alto = 250,
	Movil_MargenIzquierdo = 5,
	Movil_OffsetVertical = 10,

	Movil_MostrarSlider = true,
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
local PlayAnimationRemote = RemotesSync:FindFirstChild("PlayAnimation")
local StopAnimationRemote = RemotesSync:FindFirstChild("StopAnimation")
local SyncRemote = RemotesSync:FindFirstChild("Sync")

-- Las funciones setActiveByName y clearActive se definen DESPUÉS de ScrollFrame

local THEME_CONFIG = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ConfigModule = require(Replicado:WaitForChild("Configuration"))
local Modulo = require(RemotesSync:WaitForChild("Emotes_Modules"):WaitForChild("Animaciones"))
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local VIPGamePassID = ConfigModule.VIP

-- Función para verificar VIP bajo demanda
local function TieneVIP()
	return Jugador:GetAttribute("HasVIP") or false
end

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
	-- Todos los tipos usan el mismo color del tema
	Card = THEME_CONFIG.elevated,
	Trending = THEME_CONFIG.elevated,
	VIP = THEME_CONFIG.elevated,
	Recommended = THEME_CONFIG.elevated,
	Normal = THEME_CONFIG.elevated,
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
local IsSynced = false -- Estado de sincronización
local currentLeaderUserId = nil -- UserId del jugador que sigo (nil si no sigo a nadie)

-- Gestión de memoria
local CardConnections = {}
local ActiveTweens = {}
local GlobalConnections = {}
-- (removed SyncOnOffConnection) ahora usamos `SyncUpdate` RemoteEvent desde el servidor

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ════════════════════════════════════════════════════════════════════════════════

local function Tween(obj, dur, props, style, direction)
	if not obj or not obj.Parent then return nil end
	local tween = TweenService:Create(
		obj, 
		TweenInfo.new(dur, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), 
		props
	)
	tween:Play()
	return tween
end

local function CreateCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
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
	return IsMobile and 32 or 42
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
-- GESTIÓN DE MEMORIA MEJORADA
-- ════════════════════════════════════════════════════════════════════════════════

local function TrackConnection(card, connection)
	if not card then return end
	if not CardConnections[card] then
		CardConnections[card] = {}
	end
	table.insert(CardConnections[card], connection)
end

local function TrackGlobalConnection(connection)
	table.insert(GlobalConnections, connection)
end

local function TrackTween(card, tween)
	if not card or not tween then return end
	if not ActiveTweens[card] then
		ActiveTweens[card] = {}
	end
	table.insert(ActiveTweens[card], tween)
end

local function CleanupCard(card)
	if not card then return end

	-- Cancelar tweens activos
	if ActiveTweens[card] then
		for _, tween in ipairs(ActiveTweens[card]) do
			if tween then
				pcall(function() tween:Cancel() end)
			end
		end
		ActiveTweens[card] = nil
	end

	-- Desconectar eventos
	if CardConnections[card] then
		for _, conn in ipairs(CardConnections[card]) do
			if conn then
				pcall(function() conn:Disconnect() end)
			end
		end
		CardConnections[card] = nil
	end
end

local function CleanupAllCards()
	for card in pairs(CardConnections) do
		CleanupCard(card)
	end
	for card in pairs(ActiveTweens) do
		if ActiveTweens[card] then
			for _, tween in ipairs(ActiveTweens[card]) do
				if tween then pcall(function() tween:Cancel() end) end
			end
		end
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
		TrackTween(card, Tween(border, 0.3, {Transparency = 0, Thickness = 2}))
	end

	if overlay then
		TrackTween(card, Tween(overlay, 0.3, {BackgroundTransparency = 0.8}))
	end

	TrackTween(card, Tween(card, 0.25, {Size = UDim2.new(1, 4, 0, cardHeight + 2)}, Enum.EasingStyle.Back))
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
TabsContainer.Size = UDim2.new(1, -16, 0, IsMobile and 28 or 34)
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
TabTodos.TextSize = IsMobile and 14 or 16
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
TabFavoritos.TextSize = IsMobile and 14 or 16
TabFavoritos.ZIndex = 3
TabFavoritos.Parent = TabsContainer

local posY = IsMobile and 40 or 46

-- ════════════════════════════════════════════════════════════════════════════════
-- BÚSQUEDA (ARREGLADA - sin desbordamiento de texto)
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarBusqueda = IsMobile and Config.Movil_MostrarBusqueda or true
local SearchContainer, SearchBox

if mostrarBusqueda then
	SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -16, 0, IsMobile and 30 or 36)
	SearchContainer.Position = UDim2.new(0, 8, 0, posY)
	SearchContainer.BackgroundColor3 = Theme.BackgroundSecondary
	SearchContainer.BorderSizePixel = 0
	SearchContainer.ClipsDescendants = true
	SearchContainer.Parent = MainFrame
	CreateCorner(SearchContainer, 8)

	-- Icono de lupa moderno (círculo + línea)
	local SearchIconContainer = Instance.new("Frame")
	SearchIconContainer.Name = "SearchIconContainer"
	SearchIconContainer.Size = UDim2.new(0, IsMobile and 20 or 26, 1, 0)
	SearchIconContainer.Position = UDim2.new(0, IsMobile and 4 or 6, 0, 0)
	SearchIconContainer.BackgroundTransparency = 1
	SearchIconContainer.Parent = SearchContainer

	-- Círculo de la lupa
	local SearchCircle = Instance.new("Frame")
	SearchCircle.Name = "SearchCircle"
	SearchCircle.Size = UDim2.new(0, IsMobile and 10 or 12, 0, IsMobile and 10 or 12)
	SearchCircle.Position = UDim2.new(0.5, IsMobile and -6 or -7, 0.5, IsMobile and -6 or -7)
	SearchCircle.BackgroundTransparency = 1
	SearchCircle.Parent = SearchIconContainer
	CreateCorner(SearchCircle, 100)
	local circleStroke = CreateStroke(SearchCircle, Theme.TextMuted, IsMobile and 1.5 or 2, 0.3)

	-- Línea diagonal de la lupa
	local SearchHandle = Instance.new("Frame")
	SearchHandle.Name = "SearchHandle"
	SearchHandle.Size = UDim2.new(0, IsMobile and 5 or 6, 0, IsMobile and 1.5 or 2)
	SearchHandle.Position = UDim2.new(0.5, IsMobile and 2 or 3, 0.5, IsMobile and 3 or 4)
	SearchHandle.Rotation = 45
	SearchHandle.BackgroundColor3 = Theme.TextMuted
	SearchHandle.BackgroundTransparency = 0.3
	SearchHandle.BorderSizePixel = 0
	SearchHandle.Parent = SearchIconContainer
	CreateCorner(SearchHandle, 2)

	SearchBox = Instance.new("TextBox")
	SearchBox.Name = "SearchBox"
	SearchBox.Size = UDim2.new(1, IsMobile and -28 or -36, 1, 0)
	SearchBox.Position = UDim2.new(0, IsMobile and 24 or 30, 0, 0)
	SearchBox.BackgroundTransparency = 1
	SearchBox.Font = Enum.Font.GothamMedium
	SearchBox.PlaceholderText = "Buscar baile..."
	SearchBox.PlaceholderColor3 = Theme.TextMuted
	SearchBox.Text = ""
	SearchBox.TextColor3 = Theme.TextPrimary
	SearchBox.TextSize = IsMobile and 13 or 15
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.TextTruncate = Enum.TextTruncate.AtEnd
	SearchBox.ClearTextOnFocus = false
	SearchBox.ClipsDescendants = true
	SearchBox.Parent = SearchContainer

	-- Animación al enfocar
	TrackGlobalConnection(SearchBox.Focused:Connect(function()
		Tween(circleStroke, 0.2, {Color = Theme.Primary, Transparency = 0})
		Tween(SearchHandle, 0.2, {BackgroundColor3 = Theme.Primary, BackgroundTransparency = 0})
	end))

	TrackGlobalConnection(SearchBox.FocusLost:Connect(function()
		Tween(circleStroke, 0.2, {Color = Theme.TextMuted, Transparency = 0.3})
		Tween(SearchHandle, 0.2, {BackgroundColor3 = Theme.TextMuted, BackgroundTransparency = 0.3})
	end))

	posY = posY + (IsMobile and 34 or 40)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- SLIDER MODERNO (Rediseño completo con botones +/-)
-- ════════════════════════════════════════════════════════════════════════════════

local mostrarSlider = IsMobile and Config.Movil_MostrarSlider or true
local currentSpeedIndex = 6
local speedValues = {0.01, 0.05, 0.3, 0.5, 0.7, 1, 1.3, 1.6, 1.9, 2.2, 2.5}
local SpeedValue = nil -- Declarar aquí, asignado más abajo

if mostrarSlider then
	local SliderSection = Instance.new("Frame")
	SliderSection.Name = "SliderSection"
	SliderSection.Size = UDim2.new(1, -16, 0, IsMobile and 30 or 34)
	SliderSection.Position = UDim2.new(0, 8, 0, posY)
	SliderSection.BackgroundColor3 = Theme.BackgroundSecondary
	SliderSection.BorderSizePixel = 0
	SliderSection.ClipsDescendants = false
	SliderSection.Parent = MainFrame
	CreateCorner(SliderSection, 8)

	-- Track del slider
	local SliderTrack = Instance.new("Frame")
	SliderTrack.Name = "SliderTrack"
	SliderTrack.Size = UDim2.new(1, -20, 0, IsMobile and 6 or 8)
	SliderTrack.Position = UDim2.new(0, 10, 0.5, IsMobile and -3 or -4)
	SliderTrack.BackgroundColor3 = Theme.BackgroundTertiary
	SliderTrack.BorderSizePixel = 0
	SliderTrack.Parent = SliderSection
	CreateCorner(SliderTrack, 4)

	-- Fill del slider
	local SliderFill = Instance.new("Frame")
	SliderFill.Name = "SliderFill"
	SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
	SliderFill.BackgroundColor3 = Theme.Primary
	SliderFill.BorderSizePixel = 0
	SliderFill.ZIndex = 2
	SliderFill.Parent = SliderTrack
	CreateCorner(SliderFill, 4)

	-- Knob minimalista
	local SliderKnob = Instance.new("Frame")
	SliderKnob.Name = "SliderKnob"
	SliderKnob.Size = UDim2.new(0, IsMobile and 6 or 8, 0, IsMobile and 16 or 20)
	SliderKnob.Position = UDim2.new(0.5, IsMobile and -3 or -4, 0.5, IsMobile and -8 or -10)
	SliderKnob.BackgroundColor3 = Theme.TextPrimary
	SliderKnob.BorderSizePixel = 0
	SliderKnob.ZIndex = 3
	SliderKnob.Parent = SliderTrack
	CreateCorner(SliderKnob, 3)

	-- Raya dentro del knob
	local KnobLine = Instance.new("Frame")
	KnobLine.Name = "KnobLine"
	KnobLine.Size = UDim2.new(0, 2, 0.6, 0)
	KnobLine.Position = UDim2.new(0.5, -1, 0.2, 0)
	KnobLine.BackgroundColor3 = Theme.BackgroundTertiary
	KnobLine.BorderSizePixel = 0
	KnobLine.ZIndex = 4
	KnobLine.Parent = SliderKnob
	CreateCorner(KnobLine, 1)

	-- Valor de velocidad (abajo del knob)
	SpeedValue = Instance.new("TextLabel")
	SpeedValue.Name = "SpeedValue"
	SpeedValue.Size = UDim2.new(0, 40, 0, 12)
	SpeedValue.Position = UDim2.new(0.5, -20, 1, 1)
	SpeedValue.BackgroundTransparency = 1
	SpeedValue.Font = Enum.Font.GothamBold
	SpeedValue.Text = "1.00x"
	SpeedValue.TextColor3 = Theme.TextPrimary
	SpeedValue.TextSize = IsMobile and 10 or 11
	SpeedValue.ZIndex = 5
	SpeedValue.Visible = false
	SpeedValue.Parent = SliderKnob

	local sliderDragging = false

	local function UpdateSlider(pct)
		pct = math.clamp(pct, 0, 1)
		SliderFill.Size = UDim2.new(pct, 0, 1, 0)
		SliderKnob.Position = UDim2.new(pct, IsMobile and -3 or -4, 0.5, IsMobile and -8 or -10)

		local idx = math.clamp(math.floor(pct * (#speedValues - 1) + 0.5) + 1, 1, #speedValues)
		local speed = speedValues[idx]
		SpeedValue.Text = string.format("%.2fx", speed)

		if idx ~= currentSpeedIndex then
			currentSpeedIndex = idx
			PlayAnimationRemote:FireServer("speed", speed)
		end
	end

	SliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
			SpeedValue.Visible = true
			UpdateSlider((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X)
		end
	end)

	SliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
			SpeedValue.Visible = true
		end
	end)

	TrackGlobalConnection(UserInputService.InputChanged:Connect(function(input)
		if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateSlider((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X)
		end
	end))

	TrackGlobalConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = false
			SpeedValue.Visible = false
		end
	end))

	-- Doble click para resetear a 1.0x
	local lastClickTime = 0
	SliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local now = tick()
			if now - lastClickTime < 0.3 then
				currentSpeedIndex = 6
				UpdateSlider(0.5)
			end
			lastClickTime = now
		end
	end)

	UpdateSlider(0.5)

	posY = posY + (IsMobile and 34 or 38)
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

-- ════════════════════════════════════════════════════════════════════════════════
-- OVERLAY DE SINCRONIZACIÓN MODERNO
-- ════════════════════════════════════════════════════════════════════════════════

local SyncOverlay = Instance.new("TextButton")
SyncOverlay.Name = "SyncOverlay"
SyncOverlay.Size = UDim2.new(1, 0, 1, 0)
SyncOverlay.Position = UDim2.new(0, 0, 0, 0)
SyncOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SyncOverlay.BackgroundTransparency = 0.1
SyncOverlay.BorderSizePixel = 0
SyncOverlay.Text = ""
SyncOverlay.AutoButtonColor = false
SyncOverlay.ZIndex = 100
SyncOverlay.Visible = false
SyncOverlay.Parent = ContentArea
CreateCorner(SyncOverlay, IsMobile and 8 or 12)

-- Container central para el contenido
local SyncContainer = Instance.new("Frame")
SyncContainer.Name = "SyncContainer"
SyncContainer.Size = UDim2.new(1, -40, 0, IsMobile and 120 or 140)
SyncContainer.Position = UDim2.new(0, 20, 0.5, IsMobile and -60 or -70)
SyncContainer.BackgroundColor3 = Theme.BackgroundTertiary
SyncContainer.BackgroundTransparency = 0.3
SyncContainer.BorderSizePixel = 0
SyncContainer.ZIndex = 101
SyncContainer.Parent = SyncOverlay
CreateCorner(SyncContainer, IsMobile and 12 or 16)

-- Borde sutil con efecto glow
local ContainerStroke = CreateStroke(SyncContainer, Theme.Primary, IsMobile and 1.5 or 2, 0.5)

-- Texto secundario: "Sincronizado" (arriba)
local SyncLabel = Instance.new("TextLabel")
SyncLabel.Name = "SyncLabel"
SyncLabel.Size = UDim2.new(1, -20, 0, IsMobile and 16 or 18)
SyncLabel.Position = UDim2.new(0, 10, 0.5, IsMobile and -28 or -32)
SyncLabel.BackgroundTransparency = 1
SyncLabel.Font = Enum.Font.GothamMedium
SyncLabel.Text = "Sincronizado"
SyncLabel.TextColor3 = Theme.TextSecondary
SyncLabel.TextSize = IsMobile and 11 or 13
SyncLabel.ZIndex = 102
SyncLabel.Parent = SyncContainer

-- Texto principal: Nombre del jugador (centro)
local SyncPlayerName = Instance.new("TextLabel")
SyncPlayerName.Name = "SyncPlayerName"
SyncPlayerName.Size = UDim2.new(1, -20, 0, IsMobile and 28 or 32)
SyncPlayerName.Position = UDim2.new(0, 10, 0.5, IsMobile and -10 or -12)
SyncPlayerName.BackgroundTransparency = 1
SyncPlayerName.Font = Enum.Font.GothamBold
SyncPlayerName.Text = "Player Name"
SyncPlayerName.TextColor3 = Theme.Primary
SyncPlayerName.TextSize = IsMobile and 16 or 20
SyncPlayerName.TextScaled = false
SyncPlayerName.TextWrapped = false
SyncPlayerName.TextTruncate = Enum.TextTruncate.AtEnd
SyncPlayerName.TextXAlignment = Enum.TextXAlignment.Center
SyncPlayerName.ZIndex = 102
SyncPlayerName.Parent = SyncContainer

-- Instrucción para cerrar (abajo)
local SyncHint = Instance.new("TextLabel")
SyncHint.Name = "SyncHint"
SyncHint.Size = UDim2.new(1, -20, 0, IsMobile and 16 or 18)
SyncHint.Position = UDim2.new(0, 10, 0.5, IsMobile and 20 or 24)
SyncHint.BackgroundTransparency = 1
SyncHint.Font = Enum.Font.GothamMedium
SyncHint.Text = "Toca para desincronizarte"
SyncHint.TextColor3 = Theme.TextMuted
SyncHint.TextSize = IsMobile and 10 or 11
SyncHint.ZIndex = 102
SyncHint.Parent = SyncContainer

-- Función para mostrar/ocultar el overlay
local function SetSyncOverlay(synced, syncedPlayerName)
	IsSynced = synced
	if synced then
		SyncOverlay.Visible = true
		SyncOverlay.BackgroundTransparency = 1
		SyncContainer.Size = UDim2.new(1, -40, 0, 0)

		-- Actualizar nombre del jugador
		SyncPlayerName.Text = syncedPlayerName or "Desconocido"

		-- Animaciones de entrada
		Tween(SyncOverlay, 0.3, {BackgroundTransparency = 0.3})
		Tween(SyncContainer, 0.4, {Size = UDim2.new(1, -40, 0, IsMobile and 120 or 140)}, Enum.EasingStyle.Back)
	else
		-- Animaciones de salida (similares a la entrada pero en reversa)
		Tween(SyncContainer, 0.3, {Size = UDim2.new(1, -40, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local t = Tween(SyncOverlay, 0.3, {BackgroundTransparency = 1})
		if t then
			t.Completed:Connect(function()
				SyncOverlay.Visible = false
			end)
		end
	end
end

-- Click en el overlay para desincronizarse
SyncOverlay.MouseButton1Click:Connect(function()
	if SyncRemote then
		SyncRemote:FireServer("unsync")
		SetSyncOverlay(false)
		NotificationSystem:Info("Sync", "Te has desincronizado", 2)
	end
end)

-- Hover en el overlay
SyncOverlay.MouseEnter:Connect(function()
	Tween(SyncOverlay, 0.15, {BackgroundTransparency = 0.2})
	Tween(SyncPlayerName, 0.15, {TextColor3 = Color3.fromRGB(255, 255, 255)})
	Tween(SyncContainer, 0.15, {BackgroundTransparency = 0.2})
	Tween(ContainerStroke, 0.15, {Transparency = 0.2})
end)

SyncOverlay.MouseLeave:Connect(function()
	Tween(SyncOverlay, 0.15, {BackgroundTransparency = 0.3})
	Tween(SyncPlayerName, 0.15, {TextColor3 = Theme.Primary})
	Tween(SyncContainer, 0.15, {BackgroundTransparency = 0.3})
	Tween(ContainerStroke, 0.15, {Transparency = 0.5})
end)

-- Nota: el cliente ya no usa valores en el Character; escucha `SyncUpdate` desde el servidor

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Theme.TextMuted
ScrollFrame.ScrollBarImageTransparency = 0.6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollFrame.Parent = ContentArea

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, IsMobile and 3 or 6)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = ScrollFrame

-- ════════════════════════════════════════════════════════════════════════════════
-- HELPERS PARA SINCRONIZAR UI (optimizado con caché y debouncing)
-- ════════════════════════════════════════════════════════════════════════════════

local CardCache = {} -- Caché: nombre -> card reference
local lastActiveUpdate = 0
local activeUpdateDebounce = 0.1 -- 100ms debounce

-- Actualizar caché cuando se cargan tarjetas
local function UpdateCardCache()
	CardCache = {}
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		local cardName = child:GetAttribute("Name")
		if cardName then
			CardCache[cardName] = child
		end
	end
end

local function setActiveByName(nombre)
	if not nombre then return end

	-- Debouncing: evitar actualizaciones muy frecuentes
	local now = tick()
	if now - lastActiveUpdate < activeUpdateDebounce then
		DanceActivated = nombre
		return
	end
	lastActiveUpdate = now

	-- Usar caché primero (muy rápido)
	local card = CardCache[nombre]

	-- Si no está en caché, buscar y actualizar caché
	if not card then
		for _, child in ipairs(ScrollFrame:GetChildren()) do
			if child:GetAttribute("Name") == nombre then
				card = child
				CardCache[nombre] = card
				break
			end
		end
	end

	-- Aplicar efecto si encontró la tarjeta
	if card and card.Parent then
		if ActiveCard and ActiveCard.Parent and ActiveCard ~= card then
			RemoverEfectoActivo(ActiveCard)
		end
		ActiveCard = card
		DanceActivated = nombre
		AplicarEfectoActivo(card)
	else
		-- Guardar nombre para cuando se carguen las tarjetas
		DanceActivated = nombre
	end
end

local function clearActive()
	if ActiveCard and ActiveCard.Parent then
		RemoverEfectoActivo(ActiveCard)
	end
	ActiveCard = nil
	DanceActivated = nil
end

-- Escuchar eventos del servidor (con debouncing integrado)
if PlayAnimationRemote and PlayAnimationRemote.IsA and PlayAnimationRemote:IsA("RemoteEvent") then
	TrackGlobalConnection(PlayAnimationRemote.OnClientEvent:Connect(function(action, payload)
		if action == "playAnim" and type(payload) == "string" then
			setActiveByName(payload)
		elseif action == "speed" then
			-- opcional: actualizar el slider si el servidor fuerza una velocidad
		end
	end))
end

if StopAnimationRemote and StopAnimationRemote.IsA and StopAnimationRemote:IsA("RemoteEvent") then
	TrackGlobalConnection(StopAnimationRemote.OnClientEvent:Connect(function()
		clearActive()
	end))
end

-- Escuchar actualizaciones de sincronización desde el servidor (payload: isSynced, leaderName, animationName, speed)
local SyncUpdate = RemotesSync:FindFirstChild("SyncUpdate")
if SyncUpdate and SyncUpdate.IsA and SyncUpdate:IsA("RemoteEvent") then
	TrackGlobalConnection(SyncUpdate.OnClientEvent:Connect(function(payload)
		if not payload then return end

		--  NOTIFICACIÓN DE SEGUIDORES
		if payload.followerNotification and payload.followerNames then
			local message = ""
			if #payload.followerNames == 1 then
				message = payload.followerNames[1] .. " te está siguiendo"
			else
				message = #payload.followerNames .. " personas te siguen"
			end

			-- Mostrar notificación usando el método correcto
			if NotificationSystem then
				pcall(function()
					NotificationSystem:Info("Seguidores", message, 4)
				end)
			end
			return -- No procesar más si es una notificación
		end

		-- Mostrar/ocultar overlay de sync
		if payload.isSynced ~= nil then
			SetSyncOverlay(payload.isSynced, payload.leaderName)
		end

		-- Mantener UserId del líder que sigo (nil si ya no sigo a nadie)
		if payload.leaderUserId ~= nil then
			currentLeaderUserId = payload.leaderUserId
		else
			if payload.isSynced == false then
				currentLeaderUserId = nil
			end
		end

		-- Sincronizar animación activa en UI
		if payload.animationName and type(payload.animationName) == "string" and payload.animationName ~= "" then
			setActiveByName(payload.animationName)
		elseif payload.animationName == nil then
			-- si el servidor indica nil, limpiar activo
			clearActive()
		end

		-- Sincronizar velocidad si el servidor la envía
		if payload.speed and type(payload.speed) == "number" then
			-- Encontrar el índice de speedValues más cercano a payload.speed
			local closestIdx = 1
			local closestDiff = math.huge
			for i, v in ipairs(speedValues) do
				local diff = math.abs(v - payload.speed)
				if diff < closestDiff then
					closestDiff = diff
					closestIdx = i
				end
			end
			currentSpeedIndex = closestIdx
			if SpeedValue then
				SpeedValue.Text = string.format("%.2fx", speedValues[currentSpeedIndex])
			end
		end
	end))
end

-- Escuchar broadcasts de líderes (debounced desde servidor). Aplicar solo si el broadcast
-- corresponde al líder que este cliente está siguiendo (filtrado por UserId).
local SyncBroadcast = RemotesSync:FindFirstChild("SyncBroadcast")
if SyncBroadcast and SyncBroadcast.IsA and SyncBroadcast:IsA("RemoteEvent") then
	TrackGlobalConnection(SyncBroadcast.OnClientEvent:Connect(function(payload)
		if not payload then return end
		if not payload.leaderUserId then return end

		-- Solo aplicar si el broadcast es del líder que seguimos actualmente
		if currentLeaderUserId and payload.leaderUserId == currentLeaderUserId then
			if payload.animationName ~= nil then
				if payload.animationName == "" then
					clearActive()
				else
					setActiveByName(payload.animationName)
				end
			end

			if payload.speed then
				-- Actualizar indicador de velocidad al valor más cercano disponible
				local closestIdx = 1
				local closestDiff = math.huge
				for i, v in ipairs(speedValues) do
					local diff = math.abs(v - payload.speed)
					if diff < closestDiff then
						closestDiff = diff
						closestIdx = i
					end
				end
				currentSpeedIndex = closestIdx
				if SpeedValue then
					SpeedValue.Text = string.format("%.2fx", speedValues[currentSpeedIndex])
				end
			end
		end
	end))
end

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, IsMobile and 2 or 4)
ContentPadding.PaddingBottom = UDim.new(0, IsMobile and 4 or 10)
ContentPadding.PaddingLeft = UDim.new(0, IsMobile and 4 or 6)
ContentPadding.PaddingRight = UDim.new(0, IsMobile and 4 or 6)
ContentPadding.Parent = ScrollFrame

local EmptyMessage = Instance.new("TextLabel")
EmptyMessage.Name = "EmptyMessage"
EmptyMessage.Size = UDim2.new(0, 0, 0, 0)
EmptyMessage.BackgroundTransparency = 1
EmptyMessage.Font = Enum.Font.GothamMedium
EmptyMessage.Text = "Sin favoritos\nToca ★ en cualquier baile"
EmptyMessage.TextColor3 = Theme.TextMuted
EmptyMessage.TextSize = IsMobile and 13 or 15
EmptyMessage.Visible = false
EmptyMessage.LayoutOrder = 999
EmptyMessage.Parent = ScrollFrame

local function MostrarEmptyMessage(mostrar, texto)
	if texto then EmptyMessage.Text = texto end
	EmptyMessage.Visible = mostrar
	EmptyMessage.Size = mostrar and UDim2.new(1, 0, 0, 60) or UDim2.new(0, 0, 0, 0)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CREAR TARJETA (con animación de favoritos mejorada)
-- ════════════════════════════════════════════════════════════════════════════════

local function CrearSeparador(texto, icono, color, orden)
	local separator = Instance.new("Frame")
	separator.Name = "Sep_" .. texto
	separator.Size = UDim2.new(1, 0, 0, IsMobile and 18 or 24)
	separator.BackgroundTransparency = 1
	separator.LayoutOrder = orden
	separator:SetAttribute("Entry", true)
	separator.Parent = ScrollFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	local labelText = (icono and icono ~= "" and (icono .. " ") or "") .. texto
	label.Text = labelText
	label.TextColor3 = color
	label.TextSize = IsMobile and 11 or 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = separator

	return separator
end

local function CrearTarjeta(nombre, id, tipo, orden, esVIP)
	local cardColor = Theme.Card -- Color uniforme para todas las tarjetas
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
	card:SetAttribute("IsFavorite", esFavorito)
	card.Parent = ScrollFrame

	CreateCorner(card, IsMobile and 5 or 8)

	-- Borde sutil para definir la tarjeta
	CreateStroke(card, Theme.Border, 1, 0.7)

	-- Overlay para efecto activo
	local activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "ActiveOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.BackgroundColor3 = Theme.Primary
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.BorderSizePixel = 0
	activeOverlay.ZIndex = 2
	activeOverlay.Parent = card
	CreateCorner(activeOverlay, IsMobile and 5 or 8)

	-- Borde activo
	local activeBorder = Instance.new("UIStroke")
	activeBorder.Name = "ActiveBorder"
	activeBorder.Color = Theme.Primary
	activeBorder.Thickness = 2
	activeBorder.Transparency = 1
	activeBorder.Parent = card

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, IsMobile and -30 or -40, 1, 0)
	nameLabel.Position = UDim2.new(0, IsMobile and 8 or 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = nombre
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextSize = IsMobile and 12 or 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 3
	nameLabel.Parent = card

	-- Contenedor del botón favorito (para mejor control de animaciones)
	local favContainer = Instance.new("Frame")
	favContainer.Name = "FavContainer"
	favContainer.Size = UDim2.new(0, IsMobile and 24 or 32, 1, 0)
	favContainer.Position = UDim2.new(1, IsMobile and -24 or -32, 0, 0)
	favContainer.BackgroundTransparency = 1
	favContainer.ZIndex = 4
	favContainer.Parent = card

	-- Botón favorito
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "FavBtn"
	favBtn.Size = UDim2.new(1, 0, 1, 0)
	favBtn.BackgroundTransparency = 1
	favBtn.Text = esFavorito and "★" or "☆"
	favBtn.TextColor3 = esFavorito and Theme.Warning or Color3.fromRGB(120, 120, 120)
	favBtn.TextSize = IsMobile and 16 or 20
	favBtn.Font = Enum.Font.GothamBold
	favBtn.ZIndex = 5
	favBtn.Parent = favContainer

	-- Variable para evitar clicks múltiples
	local isProcessingFav = false

	-- Hover en tarjeta
	TrackConnection(card, card.MouseEnter:Connect(function()
		if not isProcessingFav then
			Tween(card, 0.15, {BackgroundColor3 = Theme.Card:Lerp(Theme.Primary, 0.15)})
		end
	end))

	TrackConnection(card, card.MouseLeave:Connect(function()
		if not isProcessingFav then
			Tween(card, 0.15, {BackgroundColor3 = Theme.Card})
		end
	end))

	-- Click tarjeta (reproducir baile)
	TrackConnection(card, card.MouseButton1Click:Connect(function()
		if isProcessingFav then return end

		-- Bloquear si está sincronizado
		if IsSynced then
			return
		end

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

	-- Click favorito (MEJORADO - animación suave)
	TrackConnection(card, favBtn.MouseButton1Click:Connect(function()
		if isProcessingFav then return end
		isProcessingFav = true

		-- Animación de feedback inmediato
		Tween(favBtn, 0.1, {TextSize = IsMobile and 20 or 24})

		local success, status = pcall(function()
			return AnadirFav:InvokeServer(id)
		end)

		if not success then
			isProcessingFav = false
			Tween(favBtn, 0.15, {TextSize = IsMobile and 16 or 20})
			NotificationSystem:Error("Error", "Error de conexión", 2)
			return
		end

		if status == "Anadido" then
			-- Añadido a favoritos
			table.insert(EmotesFavs, id)
			card:SetAttribute("IsFavorite", true)

			-- Animación suave de estrella
			Tween(favBtn, 0.15, {TextSize = IsMobile and 16 or 20})
			favBtn.Text = "★"
			Tween(favBtn, 0.2, {TextColor3 = Theme.Warning})

			-- Actualizar todas las cards con el mismo ID
			for _, child in ipairs(ScrollFrame:GetChildren()) do
				if child:GetAttribute("ID") == id and child ~= card then
					local btn = child:FindFirstChild("FavContainer")
					if btn then
						local innerBtn = btn:FindFirstChild("FavBtn")
						if innerBtn then
							innerBtn.Text = "★"
							innerBtn.TextColor3 = Theme.Warning
						end
					end
				end
			end

			NotificationSystem:Success("Favorito", nombre .. " añadido", 2)

		elseif status == "Eliminada" then
			-- Eliminado de favoritos
			local idx = table.find(EmotesFavs, id)
			if idx then table.remove(EmotesFavs, idx) end
			card:SetAttribute("IsFavorite", false)

			if TabActual == "Favoritos" then
				-- Animación de salida suave
				favBtn.Text = "☆"
				Tween(favBtn, 0.1, {TextColor3 = Color3.fromRGB(120, 120, 120)})
				Tween(favBtn, 0.15, {TextSize = IsMobile and 16 or 20})

				-- Limpiar conexiones ANTES de animar
				CleanupCard(card)

				-- Animación de desvanecimiento
				local fadeOut = Tween(card, 0.25, {
					BackgroundTransparency = 0.8
				})

				task.delay(0.1, function()
					if card and card.Parent then
						local shrink = Tween(card, 0.2, {
							Size = UDim2.new(1, 0, 0, 0)
						}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

						if shrink then
							shrink.Completed:Connect(function()
								if card and card.Parent then
									card:Destroy()
								end
								-- Verificar si quedan favoritos
								task.defer(function()
									if #EmotesFavs == 0 then
										MostrarEmptyMessage(true, "Sin favoritos\nToca ★ en cualquier baile")
									end
								end)
							end)
						end
					end
				end)
			else
				-- Solo actualizar visual en tab Todos
				Tween(favBtn, 0.15, {TextSize = IsMobile and 16 or 20})
				favBtn.Text = "☆"
				Tween(favBtn, 0.2, {TextColor3 = Color3.fromRGB(120, 120, 120)})

				-- Actualizar otras cards
				for _, child in ipairs(ScrollFrame:GetChildren()) do
					if child:GetAttribute("ID") == id and child ~= card then
						local btn = child:FindFirstChild("FavContainer")
						if btn then
							local innerBtn = btn:FindFirstChild("FavBtn")
							if innerBtn then
								innerBtn.Text = "☆"
								innerBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
							end
						end
					end
				end
			end

			NotificationSystem:Success("Favorito", nombre .. " quitado", 2)
		end

		-- Pequeño delay antes de permitir otro click
		task.delay(0.3, function()
			isProcessingFav = false
		end)
	end))

	return card
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CARGAR CONTENIDO
-- ════════════════════════════════════════════════════════════════════════════════

local function LimpiarScroll()
	CleanupAllCards()
	CardCache = {} -- Limpiar caché

	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:GetAttribute("Entry") then
			child:Destroy()
		end
	end
	MostrarEmptyMessage(false)
	ActiveCard = nil
end

local function RestaurarBaileActivo()
	UpdateCardCache() -- Actualizar caché después de cargar tarjetas
	if not DanceActivated then return end

	local card = CardCache[DanceActivated]
	if card then
		ActiveCard = card
		AplicarEfectoActivo(card)
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
					CrearSeparador("TRENDING", nil, Theme.Primary, orden)
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
					CrearSeparador("VIP", nil, Theme.Primary, orden)
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
					CrearSeparador("RECOMENDADOS", nil, Theme.Primary, orden)
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
					CrearSeparador("TODOS", nil, Theme.Primary, orden)
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
		MostrarEmptyMessage(true, "Sin favoritos")
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
	TrackGlobalConnection(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
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
	end))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TOGGLE GUI
-- ════════════════════════════════════════════════════════════════════════════════

local function ToggleGUI(visible)
	local posicionFinal = IsMobile 
		and UDim2.new(0, Config.Movil_MargenIzquierdo, 0.5, Config.Movil_OffsetVertical)
		or UDim2.new(0, Config.PC_MargenIzquierdo, 0.5, Config.PC_OffsetVertical)

	local posicionOculta = IsMobile
		and UDim2.new(0, -(Config.Movil_Ancho + 10), 0.5, Config.Movil_OffsetVertical)
		or UDim2.new(0, -(Config.PC_Ancho + 10), 0.5, Config.PC_OffsetVertical)

	if visible then
		MainFrame.Position = posicionOculta
		MainFrame.Visible = true
		Tween(MainFrame, 0.3, {Position = posicionFinal}, Enum.EasingStyle.Back)
	else
		local t = Tween(MainFrame, 0.25, {Position = posicionOculta}, Enum.EasingStyle.Quint)
		if t then
			t.Completed:Wait()
		end
		MainFrame.Visible = false
	end
end

local Icono = Icon.new()
Icono:setOrder(2)
Icono:setImage("127784597936941")
Icono:disableStateOverlay(false)
Icono.selected:Connect(function() ToggleGUI(true) end)
Icono.deselected:Connect(function() ToggleGUI(false) end)

-- ════════════════════════════════════════════════════════════════════════════════
-- LIMPIEZA AL DESTRUIR
-- ════════════════════════════════════════════════════════════════════════════════

ScreenGui.Destroying:Connect(function()
	CleanupAllCards()

	-- Desconectar SyncOnOff
	-- (removed SyncOnOffConnection) ya no es usado

	-- Desconectar todas las conexiones globales
	for _, conn in ipairs(GlobalConnections) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end
	GlobalConnections = {}
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ════════════════════════════════════════════════════════════════════════════════

EmotesFavs = ObtenerFavs:InvokeServer() or {}
EmotesTrending = ObtenerTrending:InvokeServer() or {}
tieneVIP = Ownership:InvokeServer(VIPGamePassID)
CargarTodos()