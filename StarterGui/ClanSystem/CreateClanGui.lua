--[[
	Clan System UI - COMPLETO Y OPTIMIZADO
	- Gestión de solicitudes de unión
	- Cambio de roles (owner/colider/lider)
	- Emoji y color del clan
	by ignxts
]]

-- Autor: ignxts

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local MembersList = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("MembersList"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local R_PANEL = 12
local ENABLE_BLUR, BLUR_SIZE = true, 14
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620

local ADMIN_IDS = ClanSystemConfig.ADMINS.AdminUserIds
local isAdmin = table.find(ADMIN_IDS, player.UserId) ~= nil

-- Colores predefinidos para clanes
local CLAN_COLORS = {
	{name = "Dorado", color = {255, 215, 0}},
	{name = "Rojo", color = {255, 69, 0}},
	{name = "Morado", color = {128, 0, 128}},
	{name = "Azul", color = {0, 122, 255}},
	{name = "Verde", color = {34, 177, 76}},
	{name = "Rosa", color = {255, 105, 180}},
	{name = "Cian", color = {0, 255, 255}},
	{name = "Blanco", color = {255, 255, 255}},
}

-- Emojis disponibles
local CLAN_EMOJIS = {"🔱", "⚔️", "🛡️", "👑", "💀", "🔥", "😈", "🦁", "🐉", "⭐", "💎", "🎯"}

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local currentPage = "TuClan"
local availableClans = {}
local isUpdating = false
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 1.5
local selectedColorIndex = 1
local selectedEmojiIndex = 1

-- ════════════════════════════════════════════════════════════════
-- GESTIÓN DE MEMORIA
-- ════════════════════════════════════════════════════════════════
local activeConnections = {}

local Memory = {}

function Memory.track(conn)
	if conn then table.insert(activeConnections, conn) end
	return conn
end

function Memory.cleanup()
	for i, conn in ipairs(activeConnections) do
		if conn then pcall(function() conn:Disconnect() end) end
		activeConnections[i] = nil
	end
	activeConnections = {}
	UI.cleanupLoading()
end

function Memory.destroyChildren(parent, exceptClass)
	if not parent then return end
	for _, child in ipairs(parent:GetChildren()) do
		if not exceptClass or not child:IsA(exceptClass) then
			child:Destroy()
		end
	end
end

UI.setTrack(Memory.track)

-- ════════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS
-- ════════════════════════════════════════════════════════════════
local loadPlayerClan, loadClansFromServer, loadAdminClans, createClanEntry, switchTab

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanSystemGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ════════════════════════════════════════════════════════════════
-- TOPBAR BUTTON
-- ════════════════════════════════════════════════════════════════
task.wait(1)

local Icon = nil
if _G.HDAdminMain and _G.HDAdminMain.client and _G.HDAdminMain.client.Assets then
	local iconModule = _G.HDAdminMain.client.Assets:FindFirstChild("Icon")
	if iconModule then Icon = require(iconModule) end
end

local clanIcon = nil
if Icon then
	if _G.ClanSystemIcon then pcall(function() _G.ClanSystemIcon:destroy() end) end
	clanIcon = Icon.new():setLabel("⚔️ CLAN ⚔️ "):setOrder(2):setEnabled(true)
	_G.ClanSystemIcon = clanIcon
end

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "ClanPanel",
	panelWidth = PANEL_W_PX,
	panelHeight = PANEL_H_PX,
	cornerRadius = R_PANEL,
	enableBlur = ENABLE_BLUR,
	blurSize = BLUR_SIZE,
	onOpen = function() if clanIcon then clanIcon:select() end end,
	onClose = function() if clanIcon then clanIcon:deselect() end end
})

local panel = modal:getPanel()
local tabButtons = {}
local tabPages = {}

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = UI.frame({
	name = "Header", size = UDim2.new(1, 0, 0, 60),
	bg = THEME.head or Color3.fromRGB(22, 22, 28), z = 101, parent = panel, corner = 12
})

local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new{
 	ColorSequenceKeypoint.new(0, THEME.panel),
 	ColorSequenceKeypoint.new(1, THEME.card)
}
headerGradient.Rotation = 90
headerGradient.Parent = header

UI.label({
	size = UDim2.new(1, -100, 0, 60), pos = UDim2.new(0, 20, 0, 0),
	text = "CLANES", textSize = 20, font = Enum.Font.GothamBold, z = 102, parent = header
})

local closeBtn = UI.button({
	name = "CloseBtn", size = UDim2.new(0, 36, 0, 36), pos = UDim2.new(1, -50, 0.5, -18),
	bg = THEME.card, text = "×", color = THEME.muted, textSize = 22, z = 103, parent = header, corner = 8
})
UI.stroked(closeBtn, 0.4)

Memory.track(closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 60, 60), TextColor3 = Color3.new(1, 1, 1)}):Play()
end))
Memory.track(closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card, TextColor3 = THEME.muted}):Play()
end))

-- ════════════════════════════════════════════════════════════════
-- TABS NAVIGATION
-- ════════════════════════════════════════════════════════════════
local tabNav = UI.frame({size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 60), bg = THEME.panel, z = 101, parent = panel})

local navList = Instance.new("UIListLayout")
navList.FillDirection = Enum.FillDirection.Horizontal
navList.Padding = UDim.new(0, 12)
navList.Parent = tabNav

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 20)
navPadding.PaddingTop = UDim.new(0, 6)
navPadding.Parent = tabNav

local function createTab(text)
	local btn = UI.button({
		size = UDim2.new(0, 90, 0, 24),
		bg = THEME.panel,
		text = text,
		color = THEME.muted,
		textSize = 13,
		font = Enum.Font.GothamBold,
		z = 101,
		parent = tabNav,
		corner = 0,
	})
	-- Mantener transparencia visual como antes (solo texto visible)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	return btn
end

tabButtons["TuClan"] = createTab("TU CLAN")
tabButtons["Disponibles"] = createTab("DISPONIBLES")
if isAdmin then
	tabButtons["Crear"] = createTab("CREAR")
	tabButtons["Admin"] = createTab("ADMIN")
end

local underline = UI.frame({
	size = UDim2.new(0, 90, 0, 3), pos = UDim2.new(0, 20, 0, 93),
	bg = THEME.accent, z = 102, parent = panel, corner = 2
})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name = "ContentArea", size = UDim2.new(1, -20, 1, -125), pos = UDim2.new(0, 10, 0, 106),
	bgT = 1, z = 101, parent = panel, corner = 10, clips = true
})

local pageLayout = Instance.new("UIPageLayout")
pageLayout.FillDirection = Enum.FillDirection.Horizontal
pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pageLayout.EasingStyle = Enum.EasingStyle.Quad
pageLayout.EasingDirection = Enum.EasingDirection.Out
pageLayout.TweenTime = 0.25
pageLayout.ScrollWheelInputEnabled = false
pageLayout.TouchInputEnabled = false
pageLayout.Parent = contentArea

-- ════════════════════════════════════════════════════════════════
-- PAGE: TU CLAN
-- ════════════════════════════════════════════════════════════════
local pageTuClan = UI.frame({name = "TuClan", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
pageTuClan.LayoutOrder = 1

local tuClanContainer = UI.frame({
	name = "Container", size = UDim2.new(1, -20, 1, -20), pos = UDim2.new(0, 10, 0, 10),
	bgT = 1, z = 102, parent = pageTuClan
})

tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = UI.frame({name = "Disponibles", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
pageDisponibles.LayoutOrder = 2

local searchBar = UI.frame({
	size = UDim2.new(1, -20, 0, 36), pos = UDim2.new(0, 10, 0, 10),
	bg = THEME.surface, z = 103, parent = pageDisponibles, corner = 8, stroke = true, strokeA = 0.6
})

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, -20, 1, 0)
searchInput.Position = UDim2.new(0, 36, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = ""
searchInput.PlaceholderText = "Buscar clanes..."
searchInput.PlaceholderColor3 = THEME.subtle
searchInput.TextColor3 = THEME.text
searchInput.TextSize = 13
searchInput.Font = Enum.Font.Gotham
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
searchInput.ZIndex = 104
searchInput.Parent = searchBar

local clansScroll = Instance.new("ScrollingFrame")
clansScroll.Size = UDim2.new(1, -20, 1, -56)
clansScroll.Position = UDim2.new(0, 10, 0, 52)
clansScroll.BackgroundTransparency = 1
clansScroll.ScrollBarThickness = 4
clansScroll.ScrollBarImageColor3 = THEME.accent
clansScroll.ScrollBarImageTransparency = 0.3
clansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
clansScroll.ZIndex = 103
clansScroll.Parent = pageDisponibles

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = clansScroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

local searchDebounce = false
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.4, function()
		if currentPage == "Disponibles" then loadClansFromServer(searchInput.Text) end
		searchDebounce = false
	end)
end)

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: CREAR (CON EMOJI Y COLOR)
-- ════════════════════════════════════════════════════════════════
local pageCrear = UI.frame({name = "Crear", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
pageCrear.LayoutOrder = 3

local createScroll = Instance.new("ScrollingFrame")
createScroll.Size = UDim2.new(1, -20, 1, -20)
createScroll.Position = UDim2.new(0, 10, 0, 10)
createScroll.BackgroundTransparency = 1
createScroll.ScrollBarThickness = 4
createScroll.ScrollBarImageColor3 = THEME.accent
createScroll.CanvasSize = UDim2.new(0, 0, 0, 620)
createScroll.ZIndex = 103
createScroll.Parent = pageCrear

local createCard = UI.frame({
	size = UDim2.new(1, 0, 0, 600), bg = THEME.card, z = 104, parent = createScroll, corner = 12, stroke = true, strokeA = 0.6
})

local createPadding = Instance.new("UIPadding")
createPadding.PaddingTop = UDim.new(0, 18)
createPadding.PaddingBottom = UDim.new(0, 18)
createPadding.PaddingLeft = UDim.new(0, 18)
createPadding.PaddingRight = UDim.new(0, 18)
createPadding.Parent = createCard

UI.label({size = UDim2.new(1, 0, 0, 20), text = "Crear Nuevo Clan", color = THEME.accent, textSize = 15, font = Enum.Font.GothamBold, z = 105, parent = createCard})

local inputNombre = UI.input("NOMBRE DEL CLAN", "Ej: Guardianes del Fuego", 40, createCard)
local inputTag = UI.input("TAG DEL CLAN (2-5 caracteres)", "Ej: FGT", 106, createCard)
local inputDesc = UI.input("DESCRIPCIÓN", "Describe tu clan...", 172, createCard, true)
local inputLogo = UI.input("LOGO (Asset ID - Opcional)", "rbxassetid://123456789", 258, createCard)

inputTag:GetPropertyChangedSignal("Text"):Connect(function()
	inputTag.Text = string.upper(inputTag.Text)
end)

-- EMOJI SELECTOR
UI.label({size = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 0, 324), text = "EMOJI DEL CLAN", textSize = 10, font = Enum.Font.GothamBold, z = 105, parent = createCard})

local emojiFrame = UI.frame({size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 342), bg = THEME.surface, z = 105, parent = createCard, corner = 8})

local emojiLayout = Instance.new("UIListLayout")
emojiLayout.FillDirection = Enum.FillDirection.Horizontal
emojiLayout.Padding = UDim.new(0, 4)
emojiLayout.VerticalAlignment = Enum.VerticalAlignment.Center
emojiLayout.Parent = emojiFrame

local emojiPad = Instance.new("UIPadding")
emojiPad.PaddingLeft = UDim.new(0, 6)
emojiPad.Parent = emojiFrame

local emojiButtons = {}
for i, emoji in ipairs(CLAN_EMOJIS) do
	-- Frame base para el emoji
	local emojiContainer = UI.frame({
		size = UDim2.new(0, 28, 0, 28),
		bg = i == 1 and THEME.accent or THEME.card,
		z = 106,
		parent = emojiFrame,
		corner = 6
	})

	-- Label del emoji
	UI.label({
		size = UDim2.new(1, 0, 1, 0),
		text = emoji,
		textSize = 16,
		alignX = Enum.TextXAlignment.Center,
		z = 107,
		parent = emojiContainer
	})

	-- Botón transparente para capturar clicks
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 108
	clickBtn.Parent = emojiContainer

	emojiButtons[i] = emojiContainer

	Memory.track(clickBtn.MouseButton1Click:Connect(function()
		selectedEmojiIndex = i
		for j, btn in ipairs(emojiButtons) do
			btn.BackgroundColor3 = j == i and THEME.accent or THEME.card
		end
	end))
end

-- COLOR SELECTOR
UI.label({size = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 0, 388), text = "COLOR DEL CLAN", textSize = 10, font = Enum.Font.GothamBold, z = 105, parent = createCard})

local colorFrame = UI.frame({size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 406), bg = THEME.surface, z = 105, parent = createCard, corner = 8})

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 6)
colorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
colorLayout.Parent = colorFrame

local colorPad = Instance.new("UIPadding")
colorPad.PaddingLeft = UDim.new(0, 6)
colorPad.Parent = colorFrame

local colorButtons = {}
for i, colorData in ipairs(CLAN_COLORS) do
	local c = colorData.color
	local colorBtn = UI.frame({
		size = UDim2.new(0, 28, 0, 28),
		bg = Color3.fromRGB(c[1], c[2], c[3]), z = 106, parent = colorFrame, corner = 6
	})

	local selectIndicator = UI.frame({
		size = UDim2.new(1, -6, 1, -6), pos = UDim2.new(0, 3, 0, 3),
		bgT = 1, z = 107, parent = colorBtn, corner = 4, stroke = true, strokeA = i == 1 and 0 or 1, strokeC = Color3.new(1, 1, 1)
	})

	colorButtons[i] = {btn = colorBtn, indicator = selectIndicator}

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 108
	clickBtn.Parent = colorBtn

	Memory.track(clickBtn.MouseButton1Click:Connect(function()
		selectedColorIndex = i
		for j, data in ipairs(colorButtons) do
			local stroke = data.indicator:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = j == i and 0 or 1 end
		end
	end))
end

-- OWNER ID (Admin only)
local inputOwnerId = UI.input("ID DEL OWNER (Opcional - Solo Admin)", "Ej: 123456789", 452, createCard)

local btnCrear = UI.button({
	size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 528),
	bg = THEME.accent, text = "CREAR CLAN", textSize = 13, z = 105, parent = createCard, corner = 8, hover = true
})

tabPages["Crear"] = pageCrear

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin, adminClansScroll

if isAdmin then
	pageAdmin = UI.frame({name = "Admin", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
	pageAdmin.LayoutOrder = 4

	local adminHeader = UI.frame({
		size = UDim2.new(1, -20, 0, 40), pos = UDim2.new(0, 10, 0, 10),
		bg = THEME.warnMuted, z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = THEME.btnDanger
	})

	UI.label({
		size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0),
		text = "⚠ Panel de Administrador - Acciones irreversibles",
		color = THEME.warn, textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader
	})

	adminClansScroll = Instance.new("ScrollingFrame")
	adminClansScroll.Size = UDim2.new(1, -20, 1, -60)
	adminClansScroll.Position = UDim2.new(0, 10, 0, 58)
	adminClansScroll.BackgroundTransparency = 1
	adminClansScroll.ScrollBarThickness = 4
	adminClansScroll.ScrollBarImageColor3 = THEME.accent
	adminClansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	adminClansScroll.ZIndex = 103
	adminClansScroll.Parent = pageAdmin

	local adminListLayout = Instance.new("UIListLayout")
	adminListLayout.Padding = UDim.new(0, 8)
	adminListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	adminListLayout.Parent = adminClansScroll

	adminListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		adminClansScroll.CanvasSize = UDim2.new(0, 0, 0, adminListLayout.AbsoluteContentSize.Y + 10)
	end)

	tabPages["Admin"] = pageAdmin
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES DE CARGA - SISTEMA DE NAVEGACIÓN JERÁRQUICA OPTIMIZADO
-- ════════════════════════════════════════════════════════════════

-- Variables de estado para navegación
local currentView = "main" -- "main", "members", "pending", "config"
local cachedClanData = nil
local cachedPlayerRole = nil
local viewsCreated = false
local membersListInstance = nil

-- Referencias a vistas (se crean una vez y se reutilizan)
local views = {
	main = nil,
	members = nil,
	pending = nil
}

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Animación de transición entre vistas
-- ════════════════════════════════════════════════════════════════
local function animateViewTransition(fromView, toView, direction)
	local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- direction: "forward" (main->detail) o "back" (detail->main)
	if direction == "forward" then
		-- Vista actual sale hacia la izquierda
		if fromView then
			TweenService:Create(fromView, tweenInfo, {Position = UDim2.new(-1, 0, 0, 0)}):Play()
		end
		-- Nueva vista entra desde la derecha
		if toView then
			toView.Position = UDim2.new(1, 0, 0, 0)
			toView.Visible = true
			TweenService:Create(toView, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		end
	else -- "back"
		-- Vista actual sale hacia la derecha
		if fromView then
			TweenService:Create(fromView, tweenInfo, {Position = UDim2.new(1, 0, 0, 0)}):Play()
		end
		-- Vista principal entra desde la izquierda
		if toView then
			toView.Position = UDim2.new(-1, 0, 0, 0)
			toView.Visible = true
			TweenService:Create(toView, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		end
	end

	-- Ocultar vista anterior después de la animación
	if fromView then
		task.delay(0.3, function()
			if fromView and fromView.Parent and currentView ~= (fromView.Name == "MainView" and "main" or fromView.Name:lower():gsub("view", "")) then
				fromView.Visible = false
			end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Navegar a una vista
-- ════════════════════════════════════════════════════════════════
local function navigateTo(viewName)
	if currentView == viewName then return end

	local fromViewFrame = views[currentView]
	local toViewFrame = views[viewName]

	local direction = (viewName == "main") and "back" or "forward"

	animateViewTransition(fromViewFrame, toViewFrame, direction)
	currentView = viewName
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear botón de navegación estilo card
-- ════════════════════════════════════════════════════════════════
local function createNavCard(config)
	local card = UI.frame({
		size = config.size or UDim2.new(1, 0, 0, 60),
		pos = config.pos or UDim2.new(0, 0, 0, 0),
		bg = THEME.card,
		z = 104,
		parent = config.parent,
		corner = 10,
		stroke = true,
		strokeA = 0.6
	})

	-- Icono
	UI.label({
		size = UDim2.new(0, 40, 0, 40),
		pos = UDim2.new(0, 12, 0.5, -20),
		text = config.icon or "👥",
		textSize = 22,
		alignX = Enum.TextXAlignment.Center,
		z = 105,
		parent = card
	})

	-- Título
	UI.label({
		size = UDim2.new(1, -120, 0, 20),
		pos = UDim2.new(0, 60, 0, 12),
		text = config.title or "Título",
		color = THEME.text,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 105,
		parent = card
	})

	-- Subtítulo/contador
	local subtitleLabel = UI.label({
		name = "Subtitle",
		size = UDim2.new(1, -120, 0, 16),
		pos = UDim2.new(0, 60, 0, 32),
		text = config.subtitle or "",
		color = THEME.muted,
		textSize = 11,
		alignX = Enum.TextXAlignment.Left,
		z = 105,
		parent = card
	})

	-- Flecha de navegación
	UI.label({
		size = UDim2.new(0, 30, 1, 0),
		pos = UDim2.new(1, -40, 0, 0),
		text = "›",
		color = THEME.muted,
		textSize = 24,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Center,
		z = 105,
		parent = card
	})

	-- Indicador de notificación (punto rojo)
	local notificationDot = nil
	if config.showNotification then
		notificationDot = UI.frame({
			name = "NotificationDot",
			size = UDim2.new(0, 10, 0, 10),
			pos = UDim2.new(1, -50, 0, 10),
			bg = THEME.btnDanger,
			z = 106,
			parent = card,
			corner = 5
		})
		notificationDot.Visible = false
	end

	-- Preview de avatares (opcional)
	local avatarPreview = nil
	if config.showAvatarPreview then
		avatarPreview = UI.frame({
			name = "AvatarPreview",
			size = UDim2.new(0, 70, 0, 28),
			pos = UDim2.new(1, -115, 0.5, -14),
			bgT = 1,
			z = 105,
			parent = card
		})
	end

	-- Hover effect
	UI.hover(card, THEME.card, THEME.hover)

	-- Hacer clickeable
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 107
	clickBtn.Parent = card

	return card, clickBtn, subtitleLabel, notificationDot, avatarPreview
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear header con botón de retroceso
-- ════════════════════════════════════════════════════════════════
local function createViewHeader(parent, title, onBack)
	local headerFrame = UI.frame({
		size = UDim2.new(1, 0, 0, 44),
		bg = THEME.surface,
		z = 106,
		parent = parent,
		corner = 10
	})

	-- Botón de retroceso
	local backBtn = UI.button({
		size = UDim2.new(0, 36, 0, 36),
		pos = UDim2.new(0, 4, 0.5, -18),
		bg = THEME.card,
		text = "‹",
		color = THEME.text,
		textSize = 22,
		font = Enum.Font.GothamBold,
		z = 107,
		parent = headerFrame,
		corner = 8
	})

	UI.hover(backBtn, THEME.card, THEME.accent)

	Memory.track(backBtn.MouseButton1Click:Connect(function()
		if onBack then onBack() end
	end))

	-- Título
	UI.label({
		size = UDim2.new(1, -90, 1, 0),
		pos = UDim2.new(0, 48, 0, 0),
		text = title,
		color = THEME.text,
		textSize = 15,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 107,
		parent = headerFrame
	})

	return headerFrame
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear vista principal del clan
-- ════════════════════════════════════════════════════════════════
local function createMainView(parent, clanData, playerRole)
	local mainView = UI.frame({
		name = "MainView",
		size = UDim2.new(1, 0, 1, 0),
		bgT = 1,
		z = 103,
		parent = parent,
		clips = true
	})

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 3
	scrollFrame.ScrollBarImageColor3 = THEME.accent
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ZIndex = 103
	scrollFrame.Parent = mainView

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 12)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = scrollFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 8)
	contentPadding.PaddingBottom = UDim.new(0, 8)
	contentPadding.PaddingLeft = UDim.new(0, 4)
	contentPadding.PaddingRight = UDim.new(0, 4)
	contentPadding.Parent = scrollFrame

	-- Contador dinámico de LayoutOrder
	local currentLayoutOrder = 0

	local function getNextOrder()
		currentLayoutOrder = currentLayoutOrder + 1
		return currentLayoutOrder
	end

	-- ══════════════════════════════════════════════════════════════
	-- CARD DE INFO DEL CLAN (Rediseñada - banner completo)
	-- ══════════════════════════════════════════════════════════════
	local infoCard = UI.frame({
		size = UDim2.new(1, -8, 0, 160),
		bg = THEME.card,
		z = 104,
		parent = scrollFrame,
		corner = 12,
		stroke = true,
		strokeA = 0.6,
		clips = true
	})
	infoCard.LayoutOrder = getNextOrder()

	-- Banner con logo de fondo - CUBRE TODA LA CARD
	local bannerImage = Instance.new("ImageLabel")
	bannerImage.Size = UDim2.new(1, 0, 1, 0)
	bannerImage.Position = UDim2.new(0, 0, 0, 0)
	bannerImage.BackgroundTransparency = 1
	bannerImage.Image = clanData.clanLogo or ""
	bannerImage.ScaleType = Enum.ScaleType.Crop
	bannerImage.ImageTransparency = 0.4
	bannerImage.ZIndex = 104
	bannerImage.Parent = infoCard
	UI.rounded(bannerImage, 12)

	local bannerGradient = Instance.new("UIGradient")
	bannerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0.06, 0.06, 0.08)),
		ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.12))
	}
	bannerGradient.Rotation = 90
	bannerGradient.Parent = bannerImage

	-- Logo/Emoji
	local logoFrame = UI.frame({
		size = UDim2.new(0, 74, 0, 74),
		pos = UDim2.new(0, 16, 0, 24),
		bg = THEME.surface,
		z = 106,
		parent = infoCard,
		corner = 37,
		stroke = true,
		strokeA = 0.3
	})

	if clanData.clanLogo and clanData.clanLogo ~= "" and clanData.clanLogo ~= "rbxassetid://0" then
		local logoImg = Instance.new("ImageLabel")
		logoImg.Size = UDim2.new(1, -8, 1, -8)
		logoImg.Position = UDim2.new(0, 4, 0, 4)
		logoImg.BackgroundTransparency = 1
		logoImg.Image = clanData.clanLogo
		logoImg.ScaleType = Enum.ScaleType.Fit
		logoImg.ZIndex = 107
		logoImg.Parent = logoFrame
		UI.rounded(logoImg, 33)
	else
		UI.label({
			size = UDim2.new(1, 0, 1, 0),
			text = clanData.clanEmoji or "⚔️",
			textSize = 36,
			alignX = Enum.TextXAlignment.Center,
			z = 107,
			parent = logoFrame
		})
	end

	-- Color del clan
	local clanColor = clanData.clanColor and Color3.fromRGB(
		clanData.clanColor[1] or 255, 
		clanData.clanColor[2] or 255, 
		clanData.clanColor[3] or 255
	) or THEME.accent

	-- Contar miembros
	local membersCount = 0
	if clanData.miembros_data then
		for _ in pairs(clanData.miembros_data) do
			membersCount = membersCount + 1
		end
	end

	-- Nombre del clan
	UI.label({
		size = UDim2.new(1, -110, 0, 26),
		pos = UDim2.new(0, 100, 0, 30),
		text = (clanData.clanEmoji or "") .. " " .. (clanData.clanName or "Clan"),
		color = clanColor,
		textSize = 18,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 106,
		parent = infoCard
	})

	-- Tag del clan
	UI.label({
		size = UDim2.new(0, 80, 0, 20),
		pos = UDim2.new(0, 100, 0, 56),
		text = "[" .. (clanData.clanTag or "TAG") .. "]",
		color = THEME.accent,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 106,
		parent = infoCard
	})

	-- Rol del jugador
	local roleData = ClanSystemConfig.ROLES.Visual[playerRole] or ClanSystemConfig.ROLES.Visual["miembro"]
	local roleColor = roleData.color
	local roleDisplay = roleData.display

	UI.label({
		size = UDim2.new(0, 100, 0, 20),
		pos = UDim2.new(1, -116, 0, 56),
		text = roleDisplay,
		color = roleColor,
		textSize = 13,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Right,
		z = 106,
		parent = infoCard
	})

	-- Descripción
	UI.label({
		size = UDim2.new(1, -32, 0, 36),
		pos = UDim2.new(0, 16, 0, 108),
		text = clanData.descripcion or "Sin descripción",
		color = THEME.muted,
		textSize = 13,
		wrap = true,
		alignX = Enum.TextXAlignment.Left,
		z = 106,
		parent = infoCard
	})

	-- ══════════════════════════════════════════════════════════════
	-- BOTONES DE NAVEGACIÓN (Cards clickeables)
	-- ══════════════════════════════════════════════════════════════

	-- Card: Miembros
	local membersCard, membersBtn, membersSubtitle, _, membersAvatarPreview = createNavCard({
		size = UDim2.new(1, -8, 0, 60),
		parent = scrollFrame,
		icon = "👥",
		title = "MIEMBROS",
		subtitle = membersCount .. " miembros en el clan",
		showAvatarPreview = true
	})
	membersCard.LayoutOrder = getNextOrder()

	-- Mostrar preview de avatares (primeros 3 miembros)
	if membersAvatarPreview and clanData.miembros_data then
		local avatarLayout = Instance.new("UIListLayout")
		avatarLayout.FillDirection = Enum.FillDirection.Horizontal
		avatarLayout.Padding = UDim.new(0, -8)
		avatarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		avatarLayout.Parent = membersAvatarPreview

		local count = 0
		for odI, _ in pairs(clanData.miembros_data) do
			if count >= 3 then break end
			local odINum = tonumber(odI)
			if odINum and odINum > 0 then
				local miniAvatar = UI.frame({
					size = UDim2.new(0, 26, 0, 26),
					bg = THEME.surface,
					z = 106,
					parent = membersAvatarPreview,
					corner = 13
				})

				local avatarImg = Instance.new("ImageLabel")
				avatarImg.Size = UDim2.new(1, -4, 1, -4)
				avatarImg.Position = UDim2.new(0, 2, 0, 2)
				avatarImg.BackgroundTransparency = 1
				avatarImg.Image = string.format(
					"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png",
					odINum
				)
				avatarImg.ZIndex = 107
				avatarImg.Parent = miniAvatar
				UI.rounded(avatarImg, 11)

				count = count + 1
			end
		end
	end

	Memory.track(membersBtn.MouseButton1Click:Connect(function()
		navigateTo("members")
	end))

	-- Card: Pendientes (solo si puede gestionar)
	local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")

	if canManageRequests then
		local pendingCard, pendingBtn, pendingSubtitle, pendingDot = createNavCard({
			size = UDim2.new(1, -8, 0, 60),
			parent = scrollFrame,
			icon = "📩",
			title = "SOLICITUDES",
			subtitle = "Cargando...",
			showNotification = true
		})
		pendingCard.LayoutOrder = getNextOrder()

		Memory.track(pendingBtn.MouseButton1Click:Connect(function()
			navigateTo("pending")
		end))

		-- Cargar conteo de pendientes en segundo plano
		task.spawn(function()
			local requests = ClanClient:GetJoinRequests(clanData.clanId) or {}
			local requestCount = #requests
			if pendingSubtitle and pendingSubtitle.Parent then
				pendingSubtitle.Text = requestCount > 0 and (requestCount .. " solicitudes pendientes") or "No hay solicitudes"
			end
			if pendingDot and pendingDot.Parent then
				pendingDot.Visible = requestCount > 0
			end
		end)
	end

	-- ══════════════════════════════════════════════════════════════
	-- BOTONES DE EDICIÓN (Se adaptan según permisos)
	-- ══════════════════════════════════════════════════════════════
	local permissions = ClanSystemConfig.ROLES.Permissions[playerRole] or {}
	local canEditName = permissions.cambiar_nombre or false
	local canEditTag = permissions.cambiar_tag or (playerRole == "owner") -- Solo owner puede cambiar tag
	local canChangeColor = permissions.cambiar_color or false

	-- Contenedor para NOMBRE y TAG en la misma línea (si tiene ambos permisos)
	if canEditName or canEditTag then
		local editRowContainer = UI.frame({
			size = UDim2.new(1, -8, 0, 42),
			bgT = 1,
			z = 104,
			parent = scrollFrame
		})
		editRowContainer.LayoutOrder = getNextOrder()

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.Padding = UDim.new(0, 8)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = editRowContainer

		-- Calcular ancho de botones
		local buttonCount = (canEditName and 1 or 0) + (canEditTag and 1 or 0)
		local buttonWidth = buttonCount == 2 and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 1, 0)

		-- Botón EDITAR NOMBRE
		if canEditName then
			local btnEditName = UI.button({
				size = buttonWidth,
				bg = THEME.surface,
				text = "EDITAR NOMBRE",
				color = THEME.text,
				textSize = 12,
				font = Enum.Font.GothamBold,
				z = 105,
				parent = editRowContainer,
				corner = 10
			})
			btnEditName.LayoutOrder = 1
			UI.hover(btnEditName, THEME.surface, THEME.stroke)

			Memory.track(btnEditName.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui,
					title = "Cambiar Nombre",
					message = "Ingresa el nuevo nombre:",
					inputText = true,
					inputPlaceholder = "Nuevo nombre",
					inputDefault = clanData.clanName,
					confirmText = "Cambiar",
					cancelText = "Cancelar",
					onConfirm = function(newName)
						if newName and #newName >= 3 then
							local success, msg = ClanClient:ChangeClanName(newName)
							if success then
								Notify:Success("Actualizado", "Nombre cambiado", 4)
								loadPlayerClan()
							else
								Notify:Error("Error", msg or "No se pudo cambiar", 4)
							end
						else
							Notify:Warning("Inválido", "Mínimo 3 caracteres", 3)
						end
					end
				})
			end))
		end

		-- Botón EDITAR TAG
		if canEditTag then
			local btnEditTag = UI.button({
				size = buttonWidth,
				bg = THEME.surface,
				text = "EDITAR TAG",
				color = THEME.text,
				textSize = 12,
				font = Enum.Font.GothamBold,
				z = 105,
				parent = editRowContainer,
				corner = 10
			})
			btnEditTag.LayoutOrder = 2
			UI.hover(btnEditTag, THEME.surface, THEME.stroke)

			Memory.track(btnEditTag.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui,
					title = "Cambiar TAG",
					message = "Ingresa el nuevo TAG (2-5 caracteres):",
					inputText = true,
					inputPlaceholder = "Ej: XYZ",
					inputDefault = clanData.clanTag,
					confirmText = "Cambiar",
					cancelText = "Cancelar",
					onConfirm = function(newTag)
						newTag = newTag and newTag:upper() or ""
						if #newTag >= 2 and #newTag <= 5 then
							local success, msg = ClanClient:ChangeClanTag(newTag)
							if success then
								Notify:Success("Actualizado", "TAG cambiado", 4)
								loadPlayerClan()
							else
								Notify:Error("Error", msg or "No se pudo cambiar", 4)
							end
						else
							Notify:Warning("Inválido", "Entre 2 y 5 caracteres", 3)
						end
					end
				})
			end))
		end
	end

	-- Botón EDITAR COLOR (línea completa separada)
	if canChangeColor then
		local btnEditColor = UI.button({
			size = UDim2.new(1, -8, 0, 42),
			bg = THEME.surface,
			text = "EDITAR COLOR",
			color = THEME.text,
			textSize = 12,
			font = Enum.Font.GothamBold,
			z = 104,
			parent = scrollFrame,
			corner = 10
		})
		btnEditColor.LayoutOrder = getNextOrder()
		UI.hover(btnEditColor, THEME.surface, THEME.stroke)

		Memory.track(btnEditColor.MouseButton1Click:Connect(function()
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Cambiar Color",
				message = "Ingresa nombre de color (ej: azul, dorado):",
				inputText = true,
				inputPlaceholder = "ej: dorado",
				inputDefault = "",
				confirmText = "Cambiar",
				cancelText = "Cancelar",
				onConfirm = function(input)
					if not input or input == "" then
						Notify:Warning("Inválido", "Ingresa un nombre de color", 3)
						return
					end
					-- Aceptar solo letras y espacios
					local name = input:match("^%s*([%a%s]+)%s*$")
					if not name then
						Notify:Warning("Inválido", "Solo letras", 3)
						return
					end
					name = name:lower():gsub("%s+", "")
					local success, msg = ClanClient:ChangeClanColor(name)
					if success then
						Notify:Success("Actualizado", msg or "Color cambiado", 4)
						loadPlayerClan()
					else
						Notify:Error("Error", msg or "No se pudo cambiar", 4)
					end
				end
			})
		end))
	end

	-- ══════════════════════════════════════════════════════════════
	-- BOTÓN SALIR / DISOLVER (siempre al final)
	-- ══════════════════════════════════════════════════════════════
	local actionBtnText = playerRole == "owner" and "DISOLVER CLAN" or "SALIR DEL CLAN"
	local actionBtn = UI.button({
		size = UDim2.new(1, -8, 0, 44),
		bg = THEME.warn,
		text = actionBtnText,
		color = Color3.new(1, 1, 1),
		textSize = 13,
		font = Enum.Font.GothamBold,
		z = 104,
		parent = scrollFrame,
		corner = 8
	})
	actionBtn.LayoutOrder = getNextOrder()

	UI.hover(actionBtn, THEME.warn, THEME.btnDanger)

	Memory.track(actionBtn.MouseButton1Click:Connect(function()
		if playerRole == "owner" then
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "⚠️ Disolver Clan",
				message = "¿Disolver \"" .. clanData.clanName .. "\"?\n\nEsta acción es IRREVERSIBLE.",
				confirmText = "Disolver",
				cancelText = "Cancelar",
				confirmColor = THEME.btnDanger,
				onConfirm = function()
					local success, msg = ClanClient:DissolveClan()
					if success then
						Notify:Success("Clan Disuelto", "El clan ha sido eliminado", 4)
						loadPlayerClan()
					else
						Notify:Error("Error", msg or "No se pudo disolver", 3)
					end
				end
			})
		else
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Salir del Clan",
				message = "¿Estás seguro de que quieres salir?",
				confirmText = "Salir",
				cancelText = "Cancelar",
				onConfirm = function()
					local success, msg = ClanClient:LeaveClan()
					if success then
						Notify:Success("Abandonado", "Has salido del clan", 4)
						loadPlayerClan()
					else
						Notify:Error("Error", msg or "No se pudo salir", 3)
					end
				end
			})
		end
	end))

	-- Actualizar canvas size
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
	end)

	return mainView
end
-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear vista de miembros
-- ════════════════════════════════════════════════════════════════
local function createMembersView(parent, clanData, playerRole)
	local membersView = UI.frame({
		name = "MembersView",
		size = UDim2.new(1, 0, 1, 0),
		pos = UDim2.new(1, 0, 0, 0),
		bgT = 1,
		z = 103,
		parent = parent,
		clips = true
	})
	membersView.Visible = false

	-- Header con botón de retroceso
	createViewHeader(membersView, "👥 MIEMBROS", function()
		navigateTo("main")
	end)

	-- Contenedor de la lista
	local listContainer = UI.frame({
		size = UDim2.new(1, -8, 1, -56),
		pos = UDim2.new(0, 4, 0, 52),
		bgT = 1,
		z = 104,
		parent = membersView
	})

	-- Crear instancia de MembersList
	membersListInstance = MembersList.new({
		parent = listContainer,
		screenGui = screenGui,
		mode = "members",
		clanData = clanData,
		playerRole = playerRole,
		onUpdate = function()
			loadPlayerClan()
		end
	})

	return membersView
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear vista de pendientes (usando MembersList reutilizable)
-- ════════════════════════════════════════════════════════════════
local pendingListInstance = nil

local function createPendingView(parent, clanData, playerRole)
	local pendingView = UI.frame({
		name = "PendingView",
		size = UDim2.new(1, 0, 1, 0),
		pos = UDim2.new(1, 0, 0, 0),
		bgT = 1,
		z = 103,
		parent = parent,
		clips = true
	})
	pendingView.Visible = false

	-- Header con botón de retroceso
	createViewHeader(pendingView, "📩 SOLICITUDES", function()
		navigateTo("main")
	end)

	-- Contenedor para la lista
	local listContainer = UI.frame({
		size = UDim2.new(1, -8, 1, -56),
		pos = UDim2.new(0, 4, 0, 52),
		bgT = 1,
		z = 104,
		parent = pendingView
	})

	-- Cargar solicitudes y crear lista
	task.spawn(function()
		local requests = ClanClient:GetJoinRequests(clanData.clanId) or {}

		-- Limpiar instancia anterior si existe
		if pendingListInstance then
			pendingListInstance:destroy()
			pendingListInstance = nil
		end

		-- Crear MembersList en modo "pending"
		pendingListInstance = MembersList.new({
			parent = listContainer,
			screenGui = screenGui,
			mode = "pending",
			clanData = clanData,
			playerRole = playerRole,
			requests = requests,
			onUpdate = function()
				loadPlayerClan()
			end
		})
	end)

	return pendingView
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN PRINCIPAL: Cargar clan del jugador
-- ════════════════════════════════════════════════════════════════
loadPlayerClan = function()
	-- Limpiar instancias anteriores
	if membersListInstance then
		membersListInstance:destroy()
		membersListInstance = nil
	end
	if pendingListInstance then
		pendingListInstance:destroy()
		pendingListInstance = nil
	end
	Memory.cleanup()
	Memory.destroyChildren(tuClanContainer)

	-- Reset de estado
	currentView = "main"
	views = { main = nil, members = nil, pending = nil }

	-- Mostrar loading
	local loadingFrame = UI.loading(tuClanContainer)

	task.spawn(function()
		local clanData = ClanClient:GetPlayerClan()

		-- Limpiar loading
		UI.cleanupLoading()
		if loadingFrame and loadingFrame.Parent then loadingFrame:Destroy() end
		Memory.destroyChildren(tuClanContainer)

		if clanData then
			-- Guardar en caché
			cachedClanData = clanData

			-- Obtener rol del jugador
			local playerRole = "miembro"
			if clanData.miembros_data and clanData.miembros_data[tostring(player.UserId)] then
				playerRole = clanData.miembros_data[tostring(player.UserId)].rol or "miembro"
			end
			cachedPlayerRole = playerRole

			-- Crear las 3 vistas (se crean una vez)
			views.main = createMainView(tuClanContainer, clanData, playerRole)
			views.members = createMembersView(tuClanContainer, clanData, playerRole)

			local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
			if canManageRequests then
				views.pending = createPendingView(tuClanContainer, clanData, playerRole)
			end

			-- Mostrar vista principal sin animación especial
			views.main.Position = UDim2.new(0, 0, 0, 0)
			views.main.Visible = true

		else
			-- No tiene clan - mostrar mensaje
			local noClanCard = UI.frame({
				size = UDim2.new(0, 280, 0, 140),
				pos = UDim2.new(0.5, -140, 0.5, -70),
				bg = THEME.card,
				z = 103,
				parent = tuClanContainer,
				corner = 12,
				stroke = true,
				strokeA = 0.6
			})

			UI.label({
				size = UDim2.new(1, 0, 0, 40),
				pos = UDim2.new(0, 0, 0, 30),
				text = "⚔️",
				textSize = 32,
				alignX = Enum.TextXAlignment.Center,
				z = 104,
				parent = noClanCard
			})

			UI.label({
				size = UDim2.new(1, -20, 0, 20),
				pos = UDim2.new(0, 10, 0, 75),
				text = "No perteneces a ningún clan",
				textSize = 13,
				font = Enum.Font.GothamBold,
				alignX = Enum.TextXAlignment.Center,
				z = 104,
				parent = noClanCard
			})

			UI.label({
				size = UDim2.new(1, -20, 0, 16),
				pos = UDim2.new(0, 10, 0, 100),
				text = "Explora clanes en 'Disponibles'",
				color = THEME.muted,
				textSize = 11,
				alignX = Enum.TextXAlignment.Center,
				z = 104,
				parent = noClanCard
			})

			-- Mostrar mensaje sin animación
			noClanCard.Position = UDim2.new(0.5, -140, 0.5, -70)
		end
	end)
end

-- Función: Crear entrada de clan
createClanEntry = function(clanData, pendingList)
	local entry = UI.frame({
		name = "ClanEntry_" .. (clanData.clanId or "unknown"),
		size = UDim2.new(1, 0, 0, 85), bg = THEME.card, z = 104, parent = clansScroll, corner = 10, stroke = true, strokeA = 0.6
	})

	local logoContainer = UI.frame({size = UDim2.new(0, 60, 0, 60), pos = UDim2.new(0, 12, 0.5, -30), bgT = 1, z = 105, parent = entry, corner = 10})

	if clanData.clanLogo and clanData.clanLogo ~= "" and clanData.clanLogo ~= "rbxassetid://0" then
		local logo = Instance.new("ImageLabel")
		logo.Size = UDim2.new(1, 0, 1, 0)
		logo.BackgroundTransparency = 1
		logo.Image = clanData.clanLogo
		logo.ScaleType = Enum.ScaleType.Fit
		logo.ZIndex = 106
		logo.Parent = logoContainer
		UI.rounded(logo, 8)
	else
		UI.label({
			size = UDim2.new(1, 0, 1, 0), text = clanData.clanEmoji or "⚔️",
			textSize = 30, alignX = Enum.TextXAlignment.Center, z = 106, parent = logoContainer
		})
	end

	local clanColor = clanData.clanColor and Color3.fromRGB(clanData.clanColor[1] or 255, clanData.clanColor[2] or 255, clanData.clanColor[3] or 255) or THEME.accent

	UI.label({
		size = UDim2.new(1, -180, 0, 18), pos = UDim2.new(0, 85, 0, 12),
		text = (clanData.clanEmoji or "") .. " " .. string.upper(clanData.clanName or "CLAN"),
		color = clanColor, textSize = 14, font = Enum.Font.GothamBold, z = 106, parent = entry
	})

	UI.label({
		size = UDim2.new(1, -180, 0, 26), pos = UDim2.new(0, 85, 0, 32),
		text = clanData.descripcion or "Sin descripción", color = THEME.subtle,
		textSize = 11, wrap = true, truncate = Enum.TextTruncate.AtEnd, z = 106, parent = entry
	})

	UI.label({
		size = UDim2.new(1, -180, 0, 28), pos = UDim2.new(0, 85, 0, 54),
		text = string.format("%d MIEMBROS [%s]", clanData.miembros_count or 0, clanData.clanTag or "?"),
		color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 106, parent = entry, alignX = Enum.TextXAlignment.Left
	})

	local joinBtn = UI.button({
		size = UDim2.new(0, 75, 0, 30), pos = UDim2.new(1, -87, 0.5, -15),
		bg = THEME.accent, text = "UNIRSE", textSize = 11, z = 106, parent = entry, corner = 6
	})

	local isPlayerMember = clanData.isPlayerMember or false
	local isPending = false
	if pendingList then
		for _, req in ipairs(pendingList) do
			if req.clanId == clanData.clanId then isPending = true break end
		end
	end

	if isPlayerMember then
		joinBtn.Text = "MIEMBRO"
		joinBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
		joinBtn.Active = false
	elseif isPending then
		joinBtn.Text = "PENDIENTE"
		joinBtn.BackgroundColor3 = Color3.fromRGB(220, 180, 60)
		Memory.track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:CancelAllJoinRequests()
			if success then Notify:Success("Cancelado", msg or "Solicitud cancelada", 5) end
		end))
	else
		UI.hover(joinBtn, THEME.accent, UI.brighten(THEME.accent, 1.15))
		Memory.track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:RequestJoinClan(clanData.clanId)
			if success then Notify:Success("Solicitud enviada", msg or "Esperando aprobación", 5)
			else Notify:Error("Error", msg or "No se pudo enviar", 5) end
		end))
	end

	UI.hover(entry, THEME.card, Color3.fromRGB(40, 40, 50))
	return entry
end

-- Función: Cargar clanes desde el servidor
loadClansFromServer = function(filtro)
	local now = tick()
	if isUpdating or (now - lastUpdateTime) < UPDATE_COOLDOWN then return end
	isUpdating = true
	lastUpdateTime = now

	filtro = filtro or ""
	local filtroLower = filtro:lower()
	local pendingList = ClanClient:GetUserPendingRequests()

	Memory.destroyChildren(clansScroll, "UIListLayout")

	local loadingContainer = UI.loading(clansScroll)

	task.spawn(function()
		local clans = ClanClient:GetClansList()

		UI.cleanupLoading()
		if loadingContainer and loadingContainer.Parent then loadingContainer:Destroy() end

		availableClans = clans or {}

		if #availableClans > 0 then
			local hayResultados = false
			for _, clanData in ipairs(availableClans) do
				local nombre = (clanData.clanName or ""):lower()
				local tag = (clanData.clanTag or ""):lower()

				if filtroLower == "" or nombre:find(filtroLower, 1, true) or tag:find(filtroLower, 1, true) then
					createClanEntry(clanData, pendingList)
					hayResultados = true
				end
			end

			if not hayResultados and filtroLower ~= "" then
				UI.label({size = UDim2.new(1, 0, 0, 60), text = "No se encontraron clanes", color = THEME.muted, textSize = 13, font = Enum.Font.GothamMedium, alignX = Enum.TextXAlignment.Center, z = 104, parent = clansScroll})
			end
		else
			UI.label({size = UDim2.new(1, 0, 0, 60), text = "No hay clanes disponibles", color = THEME.muted, textSize = 13, font = Enum.Font.GothamMedium, alignX = Enum.TextXAlignment.Center, z = 104, parent = clansScroll})
		end

		isUpdating = false
	end)
end

-- Función: Cargar clanes en admin
loadAdminClans = function()
	if not isAdmin or not adminClansScroll then return end

	local now = tick()
	if isUpdating or (now - lastUpdateTime) < UPDATE_COOLDOWN then return end
	isUpdating = true
	lastUpdateTime = now

	-- Solo destruir si no hay loading
	local hasLoading = false
	for _, child in ipairs(adminClansScroll:GetChildren()) do
		if child.Name == "Frame" then hasLoading = true break end
	end
	if not hasLoading then
		Memory.destroyChildren(adminClansScroll, "UIListLayout")
	end

	local loadingContainer = UI.loading(adminClansScroll)

	task.spawn(function()
		local clans = ClanClient:GetClansList()

		UI.cleanupLoading()
		if loadingContainer and loadingContainer.Parent then loadingContainer:Destroy() end
		Memory.destroyChildren(adminClansScroll, "UIListLayout")

		if not clans or #clans == 0 then
			UI.label({size = UDim2.new(1, 0, 0, 50), text = "No hay clanes registrados", color = THEME.muted, textSize = 12, alignX = Enum.TextXAlignment.Center, z = 104, parent = adminClansScroll})
			isUpdating = false
			return
		end

		for _, clanData in ipairs(clans) do
			local entry = UI.frame({size = UDim2.new(1, 0, 0, 65), bg = THEME.card, z = 104, parent = adminClansScroll, corner = 10, stroke = true, strokeA = 0.6})

			UI.label({size = UDim2.new(1, -160, 0, 18), pos = UDim2.new(0, 15, 0, 12), text = (clanData.clanEmoji or "") .. " " .. (clanData.clanName or "Sin nombre"), color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 105, parent = entry})
			UI.label({size = UDim2.new(1, -160, 0, 14), pos = UDim2.new(0, 15, 0, 34), text = "ID: " .. (clanData.clanId or "?") .. " • " .. (clanData.miembros_count or 0) .. " miembros", color = THEME.muted, textSize = 10, z = 105, parent = entry})

			local deleteBtn = UI.button({
				size = UDim2.new(0, 70, 0, 32), pos = UDim2.new(1, -80, 0.5, -16),
				bg = Color3.fromRGB(160, 50, 50), text = "Eliminar", textSize = 10, z = 105, parent = entry, corner = 6, hover = true, hoverBg = Color3.fromRGB(200, 70, 70)
			})

			UI.hover(entry, THEME.card, Color3.fromRGB(40, 40, 50))

			Memory.track(deleteBtn.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui, title = "Eliminar Clan",
					message = "¿Eliminar \"" .. (clanData.clanName or "Sin nombre") .. "\"?",
					confirmText = "Eliminar", cancelText = "Cancelar",
					onConfirm = function()
						local success, msg = ClanClient:AdminDissolveClan(clanData.clanId)
						if success then Notify:Success("Eliminado", msg or "Clan eliminado", 4)
						else Notify:Error("Error", msg or "No se pudo eliminar", 4) end
					end
				})
			end))
		end

		isUpdating = false
	end) -- Cierre de task.spawn
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING (Sin lag - limpia antes de mostrar)
-- ════════════════════════════════════════════════════════════════
switchTab = function(tabName)
	Memory.cleanup()
	currentPage = tabName

	for name, btn in pairs(tabButtons) do
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = (name == tabName) and THEME.accent or THEME.muted}):Play()
	end

	local positions = isAdmin and { TuClan = 20, Disponibles = 122, Crear = 224, Admin = 326 } or { TuClan = 20, Disponibles = 122 }
	TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, positions[tabName] or 20, 0, 93)}):Play()

	-- LIMPIAR contenido ANTES de cambiar de página (evita flash)
	if tabName == "TuClan" then
		Memory.destroyChildren(tuClanContainer)
		UI.loading(tuClanContainer) -- Mostrar loading inmediatamente
	elseif tabName == "Disponibles" then
		Memory.destroyChildren(clansScroll, "UIListLayout")
		UI.loading(clansScroll)
	elseif tabName == "Admin" and isAdmin and adminClansScroll then
		Memory.destroyChildren(adminClansScroll, "UIListLayout")
		UI.loading(adminClansScroll)
	end

	local pageFrame = contentArea:FindFirstChild(tabName)
	if pageFrame then pageLayout:JumpTo(pageFrame) end

	-- Cargar datos después de un pequeño delay para que se vea el loading
	task.delay(0.05, function()
		if tabName == "TuClan" then loadPlayerClan()
		elseif tabName == "Disponibles" then loadClansFromServer()
		elseif tabName == "Admin" and isAdmin then loadAdminClans()
		end
	end)
end

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ════════════════════════════════════════════════════════════════
-- OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	modal:open()
	if not ClanClient.initialized then task.spawn(function() ClanClient:Initialize() end) end
	switchTab("TuClan")
end

local function closeUI() modal:close() end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(closeUI)

btnCrear.MouseButton1Click:Connect(function()
	local clanName = inputNombre.Text
	local clanTag = inputTag.Text:upper()
	local clanDesc = inputDesc.Text ~= "" and inputDesc.Text or "Sin descripción"
	local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or ""
	local clanEmoji = CLAN_EMOJIS[selectedEmojiIndex] or "⚔️"
	local clanColor = CLAN_COLORS[selectedColorIndex].color
	local customOwnerId = inputOwnerId.Text ~= "" and tonumber(inputOwnerId.Text) or nil

	if #clanName < 3 then Notify:Warning("Nombre inválido", "Mínimo 3 caracteres", 3) return end
	if #clanTag < 2 or #clanTag > 5 then Notify:Warning("TAG inválido", "Entre 2 y 5 caracteres", 3) return end
	if customOwnerId and customOwnerId <= 0 then Notify:Warning("ID inválido", "ID debe ser válido", 3) return end

	btnCrear.Text = "Creando..."

	local success, clanId, msg = ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc, customOwnerId, clanEmoji, clanColor)

	if success then
		Notify:Success("Clan Creado", msg or "Clan creado exitosamente", 5)
		inputNombre.Text = ""
		inputTag.Text = ""
		inputDesc.Text = ""
		inputLogo.Text = ""
		inputOwnerId.Text = ""
		task.delay(0.5, function() switchTab("TuClan") end)
	else
		Notify:Error("Error", msg or "No se pudo crear el clan", 5)
	end

	btnCrear.Text = "CREAR CLAN"
end)

if clanIcon then
	clanIcon:bindEvent("selected", openUI)
	clanIcon:bindEvent("deselected", closeUI)
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER CON DEBOUNCE
-- ════════════════════════════════════════════════════════════════
local listenerDebounce = false
ClanClient.onClansUpdated = function(clans)
	if not screenGui or not screenGui.Parent then return end
	if listenerDebounce then return end

	listenerDebounce = true
	task.delay(UPDATE_COOLDOWN, function() listenerDebounce = false end)

	if currentPage == "Disponibles" then task.defer(loadClansFromServer)
	elseif currentPage == "Admin" and isAdmin then task.defer(loadAdminClans)
	elseif currentPage == "TuClan" then task.defer(loadPlayerClan)
	end
end

task.spawn(function() ClanClient:GetPlayerClan() end)