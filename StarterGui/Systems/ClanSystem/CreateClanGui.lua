--[[
	Clan System 
	Sistema completo de clanes con roles
]]

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
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local R_PANEL = 12
local ENABLE_BLUR, BLUR_SIZE = true, 14
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620

-- Admin IDs
local ADMIN_IDS = { 8387751399, 9375636407 }
local isAdmin = table.find(ADMIN_IDS, player.UserId) ~= nil

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local currentPage = "Disponibles"
local availableClans = {}

-- ════════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS (para evitar errores de orden)
-- ════════════════════════════════════════════════════════════════
local loadPlayerClan
local loadClansFromServer
local loadAdminClans
local createClanEntry
local switchTab

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function stroked(inst, alpha, color)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.stroke
	s.Thickness = 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function hoverEffect(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
	end)
end

local function brighten(color, factor)
	return Color3.fromRGB(
		math.min(255, color.R * 255 * factor),
		math.min(255, color.G * 255 * factor),
		math.min(255, color.B * 255 * factor)
	)
end

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
	if _G.ClanSystemIcon then
		pcall(function() _G.ClanSystemIcon:destroy() end)
	end
	clanIcon = Icon.new()
		:setLabel("CLAN")
		:setOrder(2)
		:setEnabled(true)
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
	onOpen = function()
		if clanIcon then clanIcon:select() end
	end,
	onClose = function()
		if clanIcon then clanIcon:deselect() end
	end
})

local panel = modal:getPanel()
local tabButtons = {}
local tabPages = {}

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = THEME.head or Color3.fromRGB(22, 22, 28)
header.BorderSizePixel = 0
header.ZIndex = 101
header.Parent = panel
rounded(header, 12)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 24))
}
headerGradient.Rotation = 90
headerGradient.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -100, 0, 60)
title.Position = UDim2.new(0, 20, 0, 0)
title.Text = "CLANES"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.ZIndex = 102
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -50, 0.5, -18)
closeBtn.BackgroundColor3 = THEME.card
closeBtn.Text = "×"
closeBtn.TextColor3 = THEME.muted
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 103
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
rounded(closeBtn, 8)
stroked(closeBtn, 0.4)

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(180, 60, 60),
		TextColor3 = Color3.new(1, 1, 1)
	}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card,
		TextColor3 = THEME.muted
	}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- TABS NAVIGATION
-- ════════════════════════════════════════════════════════════════
local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(1, 0, 0, 36)
tabNav.Position = UDim2.new(0, 0, 0, 60)
tabNav.BackgroundColor3 = THEME.panel
tabNav.BorderSizePixel = 0
tabNav.ZIndex = 101
tabNav.Parent = panel

local navList = Instance.new("UIListLayout")
navList.FillDirection = Enum.FillDirection.Horizontal
navList.Padding = UDim.new(0, 12)
navList.Parent = tabNav

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 20)
navPadding.PaddingTop = UDim.new(0, 6)
navPadding.Parent = tabNav

local function createTab(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 0, 24)
	btn.BackgroundTransparency = 1
	btn.Text = text
	btn.TextColor3 = THEME.muted
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = tabNav
	return btn
end

tabButtons["TuClan"] = createTab("TU CLAN")
tabButtons["Disponibles"] = createTab("DISPONIBLES")
if isAdmin then
	tabButtons["Crear"] = createTab("CREAR")
	tabButtons["Admin"] = createTab("ADMIN")
end

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, 93)
underline.BackgroundColor3 = THEME.accent
underline.BorderSizePixel = 0
underline.ZIndex = 102
underline.Parent = panel
rounded(underline, 2)

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -40, 1, -125)
contentArea.Position = UDim2.new(0, 20, 0, 106)
contentArea.BackgroundColor3 = THEME.elevated
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.ZIndex = 101
contentArea.Parent = panel
rounded(contentArea, 10)
stroked(contentArea, 0.6)

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
local pageTuClan = Instance.new("Frame")
pageTuClan.Name = "TuClan"
pageTuClan.Size = UDim2.fromScale(1, 1)
pageTuClan.BackgroundTransparency = 1
pageTuClan.LayoutOrder = 1
pageTuClan.ZIndex = 102
pageTuClan.Parent = contentArea

local tuClanContainer = Instance.new("Frame")
tuClanContainer.Name = "Container"
tuClanContainer.Size = UDim2.new(1, -30, 1, -30)
tuClanContainer.Position = UDim2.new(0, 15, 0, 15)
tuClanContainer.BackgroundTransparency = 1
tuClanContainer.ZIndex = 102
tuClanContainer.Parent = pageTuClan

tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = Instance.new("Frame")
pageDisponibles.Name = "Disponibles"
pageDisponibles.Size = UDim2.fromScale(1, 1)
pageDisponibles.BackgroundTransparency = 1
pageDisponibles.LayoutOrder = 2
pageDisponibles.ZIndex = 102
pageDisponibles.Parent = contentArea

local searchBar = Instance.new("Frame")
searchBar.Size = UDim2.new(1, -20, 0, 36)
searchBar.Position = UDim2.new(0, 10, 0, 10)
searchBar.BackgroundColor3 = THEME.surface
searchBar.BorderSizePixel = 0
searchBar.ZIndex = 103
searchBar.Parent = pageDisponibles
rounded(searchBar, 8)
stroked(searchBar, 0.6)

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

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: CREAR
-- ════════════════════════════════════════════════════════════════
local pageCrear = Instance.new("Frame")
pageCrear.Name = "Crear"
pageCrear.Size = UDim2.fromScale(1, 1)
pageCrear.BackgroundTransparency = 1
pageCrear.LayoutOrder = 3
pageCrear.ZIndex = 102
pageCrear.Parent = contentArea

local createScroll = Instance.new("ScrollingFrame")
createScroll.Size = UDim2.new(1, -20, 1, -20)
createScroll.Position = UDim2.new(0, 10, 0, 10)
createScroll.BackgroundTransparency = 1
createScroll.ScrollBarThickness = 4
createScroll.ScrollBarImageColor3 = THEME.accent
createScroll.CanvasSize = UDim2.new(0, 0, 0, 506)
createScroll.ZIndex = 103
createScroll.Parent = pageCrear

local createCard = Instance.new("Frame")
createCard.Size = UDim2.new(1, 0, 0, 486)
createCard.BackgroundColor3 = THEME.card
createCard.BorderSizePixel = 0
createCard.ZIndex = 104
createCard.Parent = createScroll
rounded(createCard, 12)
stroked(createCard, 0.6)

local createPadding = Instance.new("UIPadding")
createPadding.PaddingTop = UDim.new(0, 18)
createPadding.PaddingBottom = UDim.new(0, 18)
createPadding.PaddingLeft = UDim.new(0, 18)
createPadding.PaddingRight = UDim.new(0, 18)
createPadding.Parent = createCard

local createTitle = Instance.new("TextLabel")
createTitle.Size = UDim2.new(1, 0, 0, 20)
createTitle.BackgroundTransparency = 1
createTitle.Text = "Crear Nuevo Clan"
createTitle.TextColor3 = THEME.accent
createTitle.TextSize = 15
createTitle.Font = Enum.Font.GothamBold
createTitle.TextXAlignment = Enum.TextXAlignment.Left
createTitle.ZIndex = 105
createTitle.Parent = createCard

-- Función para crear campos de entrada
local function createInputField(labelText, placeholder, yPos, parent, multiLine)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Position = UDim2.new(0, 0, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = THEME.text
	label.TextSize = 10
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 105
	label.Parent = parent

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, 0, 0, multiLine and 55 or 36)
	input.Position = UDim2.new(0, 0, 0, yPos + 18)
	input.BackgroundColor3 = THEME.surface
	input.BorderSizePixel = 0
	input.Text = ""
	input.TextColor3 = THEME.text
	input.TextSize = 12
	input.Font = Enum.Font.Gotham
	input.PlaceholderText = placeholder
	input.PlaceholderColor3 = THEME.subtle
	input.ClearTextOnFocus = false
	input.TextWrapped = multiLine or false
	input.MultiLine = multiLine or false
	input.TextYAlignment = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	input.ZIndex = 105
	input.Parent = parent
	rounded(input, 8)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	if multiLine then pad.PaddingTop = UDim.new(0, 8) end
	pad.Parent = input

	return input
end

local inputNombre = createInputField("NOMBRE DEL CLAN", "Ej: Guardianes del Fuego", 40, createCard)
local inputTag = createInputField("TAG DEL CLAN (2-5 caracteres)", "Ej: FGT", 106, createCard)
local inputDesc = createInputField("DESCRIPCIÓN", "Describe tu clan...", 172, createCard, true)
local inputLogo = createInputField("LOGO (Asset ID - Opcional)", "rbxassetid://123456789", 258, createCard)
local inputOwnerId = createInputField("ID DEL OWNER (Opcional - Solo Admin)", "Ej: 123456789", 324, createCard)

inputTag:GetPropertyChangedSignal("Text"):Connect(function()
	inputTag.Text = string.upper(inputTag.Text)
end)

local btnCrear = Instance.new("TextButton")
btnCrear.Size = UDim2.new(1, 0, 0, 40)
btnCrear.Position = UDim2.new(0, 0, 0, 414)
btnCrear.BackgroundColor3 = THEME.accent
btnCrear.Text = "CREAR CLAN"
btnCrear.TextColor3 = Color3.new(1, 1, 1)
btnCrear.TextSize = 13
btnCrear.Font = Enum.Font.GothamBold
btnCrear.AutoButtonColor = false
btnCrear.ZIndex = 105
btnCrear.Parent = createCard
rounded(btnCrear, 8)

hoverEffect(btnCrear, THEME.accent, brighten(THEME.accent, 1.15))

tabPages["Crear"] = pageCrear

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin, adminClansScroll

if isAdmin then
	pageAdmin = Instance.new("Frame")
	pageAdmin.Name = "Admin"
	pageAdmin.Size = UDim2.fromScale(1, 1)
	pageAdmin.BackgroundTransparency = 1
	pageAdmin.LayoutOrder = 4
	pageAdmin.ZIndex = 102
	pageAdmin.Parent = contentArea

	local adminHeader = Instance.new("Frame")
	adminHeader.Size = UDim2.new(1, -20, 0, 40)
	adminHeader.Position = UDim2.new(0, 10, 0, 10)
	adminHeader.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
	adminHeader.ZIndex = 103
	adminHeader.Parent = pageAdmin
	rounded(adminHeader, 8)
	stroked(adminHeader, 0.5, Color3.fromRGB(180, 70, 70))

	local adminWarning = Instance.new("TextLabel")
	adminWarning.Size = UDim2.new(1, -16, 1, 0)
	adminWarning.Position = UDim2.new(0, 8, 0, 0)
	adminWarning.BackgroundTransparency = 1
	adminWarning.Text = "⚠ Panel de Administrador - Acciones irreversibles"
	adminWarning.TextColor3 = Color3.fromRGB(255, 160, 160)
	adminWarning.TextSize = 11
	adminWarning.Font = Enum.Font.GothamMedium
	adminWarning.TextXAlignment = Enum.TextXAlignment.Left
	adminWarning.ZIndex = 104
	adminWarning.Parent = adminHeader

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
-- FUNCIONES DE CARGA (DEFINIDAS ANTES DE SER USADAS)
-- ════════════════════════════════════════════════════════════════

-- Función: Cargar clan del jugador
loadPlayerClan = function()
	for _, child in ipairs(tuClanContainer:GetChildren()) do
		child:Destroy()
	end

	local clanData = ClanClient:GetPlayerClan()

	if clanData then
		-- Tiene clan
		local clanScroll = Instance.new("ScrollingFrame")
		clanScroll.Size = UDim2.new(1, 0, 1, 0)
		clanScroll.BackgroundTransparency = 1
		clanScroll.ScrollBarThickness = 4
		clanScroll.ScrollBarImageColor3 = THEME.accent
		clanScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
		clanScroll.ZIndex = 103
		clanScroll.Parent = tuClanContainer

		local clanCard = Instance.new("Frame")
		clanCard.Size = UDim2.new(1, 0, 0, 300)
		clanCard.BackgroundColor3 = THEME.card
		clanCard.ZIndex = 104
		clanCard.Parent = clanScroll
		rounded(clanCard, 12)
		stroked(clanCard, 0.6)

		-- Logo de fondo (con desenfoque visual)
		local logoContainer = Instance.new("Frame")
		logoContainer.Size = UDim2.new(1, 0, 1, 0)
		logoContainer.Position = UDim2.new(0, 0, 0, 0)
		logoContainer.BackgroundTransparency = 1
		logoContainer.ZIndex = 103
		logoContainer.Parent = clanCard
		rounded(logoContainer, 12)

		local logo = Instance.new("ImageLabel")
		logo.Size = UDim2.new(1, 0, 1, 0)
		logo.BackgroundTransparency = 1
		logo.Image = clanData.clanLogo or ""
		logo.ScaleType = Enum.ScaleType.Crop
		logo.ImageTransparency = 0.3
		logo.ZIndex = 103
		logo.Parent = logoContainer
		rounded(logo, 12)

		-- Desvanecimiento con gradiente
		local fadeGradient = Instance.new("UIGradient")
		fadeGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.new(0.2, 0.2, 0.2)),
			ColorSequenceKeypoint.new(1, Color3.new(0.15, 0.15, 0.17))
		}
		fadeGradient.Rotation = 45
		fadeGradient.Parent = logo

		-- Overlay oscuro fuerte (efecto blur visual)
		local blurOverlay = Instance.new("Frame")
		blurOverlay.Size = UDim2.new(1, 0, 1, 0)
		blurOverlay.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		blurOverlay.BackgroundTransparency = 0.6
		blurOverlay.ZIndex = 103
		blurOverlay.Parent = logoContainer
		rounded(blurOverlay, 12)

		-- Logo frontal (70x70 centrado)
		local logoFront = Instance.new("Frame")
		logoFront.Size = UDim2.new(0, 70, 0, 70)
		logoFront.Position = UDim2.new(0.5, -35, 0, 18)
		logoFront.BackgroundTransparency = 1
		logoFront.ZIndex = 105
		logoFront.Parent = clanCard
		rounded(logoFront, 12)

		local logoImage = Instance.new("ImageLabel")
		logoImage.Size = UDim2.new(1, 0, 1, 0)
		logoImage.BackgroundTransparency = 1
		logoImage.Image = clanData.clanLogo or ""
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.ZIndex = 106
		logoImage.Parent = logoFront
		rounded(logoImage, 10)

		if not clanData.clanLogo or clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
			logoImage.Visible = false
		end

		-- Nombre y Tag
		local clanName = Instance.new("TextLabel")
		clanName.Size = UDim2.new(1, -20, 0, 20)
		clanName.Position = UDim2.new(0, 10, 0, 96)
		clanName.BackgroundTransparency = 1
		clanName.Text = clanData.clanName or "Clan"
		clanName.TextColor3 = THEME.text
		clanName.TextSize = 15
		clanName.Font = Enum.Font.GothamBold
		clanName.TextXAlignment = Enum.TextXAlignment.Center
		clanName.ZIndex = 104
		clanName.Parent = clanCard

		local clanTag = Instance.new("TextLabel")
		clanTag.Size = UDim2.new(1, -20, 0, 16)
		clanTag.Position = UDim2.new(0, 10, 0, 118)
		clanTag.BackgroundTransparency = 1
		clanTag.Text = "[" .. (clanData.clanTag or "TAG") .. "]"
		clanTag.TextColor3 = THEME.accent
		clanTag.TextSize = 12
		clanTag.Font = Enum.Font.GothamBold
		clanTag.TextXAlignment = Enum.TextXAlignment.Center
		clanTag.ZIndex = 104
		clanTag.Parent = clanCard

		-- Descripción
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -20, 0, 36)
		desc.Position = UDim2.new(0, 10, 0, 140)
		desc.BackgroundTransparency = 1
		desc.Text = clanData.descripcion or "Sin descripción"
		desc.TextColor3 = THEME.muted
		desc.TextSize = 11
		desc.Font = Enum.Font.Gotham
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Center
		desc.ZIndex = 104
		desc.Parent = clanCard

		-- Stats
		local statsFrame = Instance.new("Frame")
		statsFrame.Size = UDim2.new(1, -20, 0, 22)
		statsFrame.Position = UDim2.new(0, 10, 0, 182)
		statsFrame.BackgroundTransparency = 1
		statsFrame.ZIndex = 104
		statsFrame.Parent = clanCard

		local memberCount = Instance.new("TextLabel")
		memberCount.Size = UDim2.new(0.33, 0, 1, 0)
		memberCount.BackgroundTransparency = 1
		memberCount.Text = ((clanData.miembros and #clanData.miembros) or 1) .. " Miembros"
		memberCount.TextColor3 = THEME.text
		memberCount.TextSize = 10
		memberCount.Font = Enum.Font.Gotham
		memberCount.ZIndex = 104
		memberCount.Parent = statsFrame

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(0.33, 0, 1, 0)
		levelLabel.Position = UDim2.new(0.33, 0, 0, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "Nivel " .. (clanData.nivel or 1)
		levelLabel.TextColor3 = THEME.text
		levelLabel.TextSize = 10
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.ZIndex = 104
		levelLabel.Parent = statsFrame

		local playerRole = "Miembro"
		local playerRoleLower = "miembro" -- para comparaciones
		if clanData.miembros_data and clanData.miembros_data[tostring(player.UserId)] then
			local pData = clanData.miembros_data[tostring(player.UserId)]
			playerRole = pData.rol and (pData.rol:sub(1,1):upper() .. pData.rol:sub(2)) or "Miembro"
			playerRoleLower = pData.rol or "miembro"
		end

		local roleLabel = Instance.new("TextLabel")
		roleLabel.Size = UDim2.new(0.33, 0, 1, 0)
		roleLabel.Position = UDim2.new(0.66, 0, 0, 0)
		roleLabel.BackgroundTransparency = 1
		roleLabel.Text = playerRole
		roleLabel.TextColor3 = THEME.accent
		roleLabel.TextSize = 10
		roleLabel.Font = Enum.Font.GothamMedium
		roleLabel.ZIndex = 104
		roleLabel.Parent = statsFrame

		-- Botones de edición
		local editFrame = Instance.new("Frame")
		editFrame.Size = UDim2.new(1, -20, 0, 28)
		editFrame.Position = UDim2.new(0, 10, 0, 212)
		editFrame.BackgroundTransparency = 1
		editFrame.ZIndex = 104
		editFrame.Parent = clanCard

		local btnEditName = Instance.new("TextButton")
		btnEditName.Size = UDim2.new(0.48, 0, 1, 0)
		btnEditName.BackgroundColor3 = THEME.surface
		btnEditName.Text = "Editar Nombre"
		btnEditName.TextColor3 = THEME.text
		btnEditName.TextSize = 10
		btnEditName.Font = Enum.Font.GothamMedium
		btnEditName.AutoButtonColor = false
		btnEditName.ZIndex = 104
		btnEditName.Parent = editFrame
		rounded(btnEditName, 6)

		local btnEditTag = Instance.new("TextButton")
		btnEditTag.Size = UDim2.new(0.48, 0, 1, 0)
		btnEditTag.Position = UDim2.new(0.52, 0, 0, 0)
		btnEditTag.BackgroundColor3 = THEME.surface
		btnEditTag.Text = "Editar TAG"
		btnEditTag.TextColor3 = THEME.text
		btnEditTag.TextSize = 10
		btnEditTag.Font = Enum.Font.GothamMedium
		btnEditTag.AutoButtonColor = false
		btnEditTag.ZIndex = 104
		btnEditTag.Parent = editFrame
		rounded(btnEditTag, 6)

		btnEditName.MouseButton1Click:Connect(function()
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
							Notify:Success("Actualizado", "Nombre cambiado a: " .. newName, 4)
							task.wait(1)
							loadPlayerClan()
						else
							Notify:Error("Error", msg or "No se pudo cambiar el nombre", 4)
						end
					else
						Notify:Warning("Inválido", "Mínimo 3 caracteres", 3)
					end
				end
			})
		end)

		btnEditTag.MouseButton1Click:Connect(function()
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
							Notify:Success("Actualizado", "TAG cambiado a: [" .. newTag .. "]", 4)
							task.wait(1)
							loadPlayerClan()
						else
							Notify:Error("Error", msg or "No se pudo cambiar el TAG", 4)
						end
					else
						Notify:Warning("Inválido", "Entre 2 y 5 caracteres", 3)
					end
				end
			})
		end)

		-- Botón salir/disolver (solo para owner)
		-- Solo mostrar botón si es owner
		if playerRoleLower == "owner" then
			local btnDissolve = Instance.new("TextButton")
			btnDissolve.Size = UDim2.new(1, -20, 0, 28)
			btnDissolve.Position = UDim2.new(0, 10, 0, 248)
			btnDissolve.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			btnDissolve.Text = "DISOLVER CLAN"
			btnDissolve.TextColor3 = Color3.new(1, 1, 1)
			btnDissolve.TextSize = 12
			btnDissolve.Font = Enum.Font.GothamBold
			btnDissolve.AutoButtonColor = false
			btnDissolve.ZIndex = 104
			btnDissolve.Parent = clanCard
			rounded(btnDissolve, 6)

			btnDissolve.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui,
					title = "Disolver Clan",
					message = "¿Disolver \"" .. clanData.clanName .. "\"?\n\nEsta acción es IRREVERSIBLE y todos los miembros serán removidos.",
					confirmText = "Disolver",
					cancelText = "Cancelar",
					onConfirm = function()
						local success, msg = ClanClient:DissolveClan()
						if success then
							Notify:Success("Clan Disuelto", "El clan ha sido eliminado", 4)
							task.wait(1)
							loadPlayerClan()
						else
							Notify:Error("Error", msg or "No se pudo disolver", 3)
						end
					end
				})
			end)
		else
			-- Para miembros no-owner: botón de salir
			local btnLeave = Instance.new("TextButton")
			btnLeave.Size = UDim2.new(1, -20, 0, 28)
			btnLeave.Position = UDim2.new(0, 10, 0, 248)
			btnLeave.BackgroundColor3 = THEME.danger or Color3.fromRGB(200, 60, 60)
			btnLeave.Text = "SALIR DEL CLAN"
			btnLeave.TextColor3 = Color3.new(1, 1, 1)
			btnLeave.TextSize = 12
			btnLeave.Font = Enum.Font.GothamBold
			btnLeave.AutoButtonColor = false
			btnLeave.ZIndex = 104
			btnLeave.Parent = clanCard
			rounded(btnLeave, 6)

			btnLeave.MouseButton1Click:Connect(function()
				ConfirmationModal.new({
					screenGui = screenGui,
					title = "Salir del Clan",
					message = "¿Estás seguro? Esta acción no se puede deshacer.",
					confirmText = "Salir",
					cancelText = "Cancelar",
					onConfirm = function()
						local success, msg = ClanClient:LeaveClan()
						if success then
							Notify:Success("Abandonado", "Has salido del clan", 4)
							task.wait(1)
							loadPlayerClan()
						else
							Notify:Error("Error", msg or "No se pudo salir", 3)
						end
					end
				})
			end)
		end

		-- Miembros
		local membersCard = Instance.new("Frame")
		membersCard.Size = UDim2.new(1, 0, 0, 130)
		membersCard.Position = UDim2.new(0, 0, 0, 310)
		membersCard.BackgroundColor3 = THEME.card
		membersCard.ZIndex = 105
		membersCard.Parent = clanScroll
		rounded(membersCard, 12)
		stroked(membersCard, 0.6)

		local membersTitle = Instance.new("TextLabel")
		membersTitle.Size = UDim2.new(1, -20, 0, 18)
		membersTitle.Position = UDim2.new(0, 10, 0, 10)
		membersTitle.BackgroundTransparency = 1
		membersTitle.Text = "Miembros"
		membersTitle.TextColor3 = THEME.text
		membersTitle.TextSize = 12
		membersTitle.Font = Enum.Font.GothamBold
		membersTitle.TextXAlignment = Enum.TextXAlignment.Left
		membersTitle.ZIndex = 105
		membersTitle.Parent = membersCard

		local membersScroll = Instance.new("ScrollingFrame")
		membersScroll.Size = UDim2.new(1, -20, 1, -40)
		membersScroll.Position = UDim2.new(0, 10, 0, 30)
		membersScroll.BackgroundTransparency = 1
		membersScroll.ScrollBarThickness = 3
		membersScroll.ScrollBarImageColor3 = THEME.accent
		membersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		membersScroll.ZIndex = 105
		membersScroll.Parent = membersCard

		local membersLayout = Instance.new("UIListLayout")
		membersLayout.Padding = UDim.new(0, 8)
		membersLayout.FillDirection = Enum.FillDirection.Horizontal
		membersLayout.Parent = membersScroll

		if clanData.miembros_data then
			for odI, memberData in pairs(clanData.miembros_data) do
				local memberFrame = Instance.new("Frame")
				memberFrame.Size = UDim2.new(0, 80, 0, 85)
				memberFrame.BackgroundColor3 = THEME.surface
				memberFrame.ZIndex = 106
				memberFrame.Parent = membersScroll
				rounded(memberFrame, 8)

				local avatar = Instance.new("ImageLabel")
				avatar.Size = UDim2.new(0, 50, 0, 50)
				avatar.Position = UDim2.new(0.5, -25, 0, 5)
				avatar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. odI .. "&width=420&height=420&format=png"
				avatar.ZIndex = 107
				avatar.Parent = memberFrame
				rounded(avatar, 6)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -4, 0, 12)
				nameLabel.Position = UDim2.new(0, 2, 0, 58)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = (memberData.nombre or "Usuario"):sub(1, 10)
				nameLabel.TextColor3 = THEME.text
				nameLabel.TextSize = 8
				nameLabel.Font = Enum.Font.Gotham
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.ZIndex = 107
				nameLabel.Parent = memberFrame

				local rolLabel = Instance.new("TextLabel")
				rolLabel.Size = UDim2.new(1, -4, 0, 10)
				rolLabel.Position = UDim2.new(0, 2, 0, 72)
				rolLabel.BackgroundTransparency = 1
				rolLabel.Text = memberData.rol:sub(1,1):upper() .. memberData.rol:sub(2)
				rolLabel.TextColor3 = THEME.accent
				rolLabel.TextSize = 7
				rolLabel.Font = Enum.Font.GothamBold
				rolLabel.ZIndex = 107
				rolLabel.Parent = memberFrame
			end
		end

		task.wait()
		membersScroll.CanvasSize = UDim2.new(0, membersLayout.AbsoluteContentSize.X + 16, 0, 0)
		clanScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
	else
		-- No tiene clan
		local noClanCard = Instance.new("Frame")
		noClanCard.Size = UDim2.new(0, 300, 0, 160)
		noClanCard.Position = UDim2.new(0.5, -150, 0.5, -80)
		noClanCard.BackgroundColor3 = THEME.card
		noClanCard.ZIndex = 103
		noClanCard.Parent = tuClanContainer
		rounded(noClanCard, 12)
		stroked(noClanCard, 0.6)

		local shieldEmoji = Instance.new("TextLabel")
		shieldEmoji.Size = UDim2.new(0, 60, 0, 60)
		shieldEmoji.Position = UDim2.new(0.5, -30, 0, 15)
		shieldEmoji.BackgroundTransparency = 1
		shieldEmoji.Text = "🛡️"
		shieldEmoji.TextSize = 40
		shieldEmoji.ZIndex = 104
		shieldEmoji.Parent = noClanCard

		local noClanText = Instance.new("TextLabel")
		noClanText.Size = UDim2.new(1, -20, 0, 20)
		noClanText.Position = UDim2.new(0, 10, 0, 82)
		noClanText.BackgroundTransparency = 1
		noClanText.Text = "No perteneces a ningún clan"
		noClanText.TextColor3 = THEME.text
		noClanText.TextSize = 14
		noClanText.Font = Enum.Font.GothamBold
		noClanText.ZIndex = 104
		noClanText.Parent = noClanCard

		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, -20, 0, 32)
		hint.Position = UDim2.new(0, 10, 0, 106)
		hint.BackgroundTransparency = 1
		hint.Text = "Únete a un clan en 'Disponibles' o crea uno en 'Crear'"
		hint.TextColor3 = THEME.muted
		hint.TextSize = 11
		hint.Font = Enum.Font.Gotham
		hint.TextWrapped = true
		hint.ZIndex = 104
		hint.Parent = noClanCard
	end
end

-- Función: Crear entrada de clan (AHORA loadPlayerClan ya está definida)
createClanEntry = function(clanData)
	local entry = Instance.new("Frame")
	entry.Name = "ClanEntry_" .. (clanData.clanId or "unknown")
	entry.Size = UDim2.new(1, 0, 0, 85)
	entry.BackgroundColor3 = THEME.card
	entry.ZIndex = 104
	entry.Parent = clansScroll
	rounded(entry, 10)
	stroked(entry, 0.6)


	-- Logo
	local logoContainer = Instance.new("Frame")
	logoContainer.Size = UDim2.new(0, 60, 0, 60)
	logoContainer.Position = UDim2.new(0, 12, 0.5, -30)
	logoContainer.BackgroundTransparency = 1
	logoContainer.ZIndex = 105
	logoContainer.Parent = entry
	rounded(logoContainer, 10)

	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(1, 0, 1, 0)
	logo.BackgroundTransparency = 1
	logo.Image = clanData.clanLogo or ""
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 106
	logo.Parent = logoContainer
	rounded(logo, 8)

	if not clanData.clanLogo or clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
		logo.Visible = false
		-- Icono predeterminado sin fondo
		local defaultIcon = Instance.new("Frame")
		defaultIcon.Size = UDim2.new(0, 22, 0, 22)
		defaultIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
		defaultIcon.BackgroundColor3 = THEME.muted
		defaultIcon.ZIndex = 106
		defaultIcon.Parent = logoContainer
		rounded(defaultIcon, 6)
	end

	-- Nombre
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -180, 0, 18)
	name.Position = UDim2.new(0, 85, 0, 12)
	name.BackgroundTransparency = 1
	name.Text = string.upper(clanData.clanName or "CLAN SIN NOMBRE")
	name.TextColor3 = THEME.accent
	name.TextSize = 13
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 106
	name.Parent = entry

	-- Descripción
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -180, 0, 26)
	desc.Position = UDim2.new(0, 85, 0, 32)
	desc.BackgroundTransparency = 1
	desc.Text = clanData.descripcion or "Sin descripción"
	desc.TextColor3 = THEME.subtle
	desc.TextSize = 11
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.ZIndex = 106
	desc.Parent = entry

	-- Stats
	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.new(1, -180, 0, 14)
	stats.Position = UDim2.new(0, 85, 0, 62)
	stats.BackgroundTransparency = 1
	stats.Text = (clanData.miembros_count or 0) .. "/50 • Nivel " .. (clanData.nivel or 1)
	stats.TextColor3 = THEME.muted
	stats.TextSize = 10
	stats.Font = Enum.Font.Gotham
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.ZIndex = 106
	stats.Parent = entry

	-- Botón unirse
	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.new(0, 75, 0, 30)
	joinBtn.Position = UDim2.new(1, -87, 0.5, -15)
	joinBtn.BackgroundColor3 = THEME.accent
	joinBtn.Text = "UNIRSE"
	joinBtn.TextColor3 = Color3.new(1, 1, 1)
	joinBtn.TextSize = 11
	joinBtn.Font = Enum.Font.GothamBold
	joinBtn.AutoButtonColor = false
	joinBtn.ZIndex = 106
	joinBtn.Parent = entry
	rounded(joinBtn, 6)

	-- Usar datos del servidor (isPlayerMember viene del backend)
	local isPlayerMember = clanData.isPlayerMember or false

	if isPlayerMember then
		-- Ya está en este clan (datos del servidor)
		joinBtn.Text = "UNIDO"
		joinBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
		joinBtn.Active = false
		-- No agregar hover effect ni click event
	else
		-- No está en este clan
		hoverEffect(joinBtn, THEME.accent, brighten(THEME.accent, 1.15))

		joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:JoinClan(clanData.clanId)
			if success then
				Notify:Success("Unido al clan", msg or ("Te has unido a " .. clanData.clanName), 5)
				task.delay(0.3, function()
					switchTab("TuClan")
				end)
			else
				Notify:Error("Error", msg or "No se pudo unir al clan", 5)
			end
		end)
	end

	hoverEffect(entry, THEME.card, Color3.fromRGB(40, 40, 50))

	return entry
end

-- Función: Cargar clanes desde el servidor
loadClansFromServer = function()
	for _, child in ipairs(clansScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Loading
	local loadingContainer = Instance.new("Frame")
	loadingContainer.Size = UDim2.new(1, 0, 0, 80)
	loadingContainer.BackgroundTransparency = 1
	loadingContainer.ZIndex = 104
	loadingContainer.Parent = clansScroll

	local loadingDots = {}
	for i = 1, 3 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 6, 0, 6)
		dot.Position = UDim2.new(0.5, -15 + (i-1) * 12, 0.5, -3)
		dot.BackgroundColor3 = THEME.accent
		dot.ZIndex = 105
		dot.Parent = loadingContainer
		rounded(dot, 3)
		loadingDots[i] = dot
	end

	local animIndex = 1
	local animConnection
	animConnection = RunService.Heartbeat:Connect(function()
		if not loadingContainer or not loadingContainer.Parent then
			if animConnection then animConnection:Disconnect() end
			return
		end
		for i, dot in ipairs(loadingDots) do
			TweenService:Create(dot, TweenInfo.new(0.2), {
				BackgroundTransparency = (i == animIndex) and 0 or 0.6
			}):Play()
		end
		animIndex = (animIndex % 3) + 1
	end)

	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.new(1, 0, 0, 18)
	loadingText.Position = UDim2.new(0, 0, 0.5, 12)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = "Cargando clanes..."
	loadingText.TextColor3 = THEME.muted
	loadingText.TextSize = 11
	loadingText.Font = Enum.Font.Gotham
	loadingText.ZIndex = 105
	loadingText.Parent = loadingContainer

	task.spawn(function()
		local clans = ClanClient:GetClansList()

		if animConnection then animConnection:Disconnect() end
		if loadingContainer and loadingContainer.Parent then
			loadingContainer:Destroy()
		end

		availableClans = clans or {}

		if #availableClans > 0 then
			for _, clanData in ipairs(availableClans) do
				createClanEntry(clanData)
			end
		else
			local noClans = Instance.new("TextLabel")
			noClans.Size = UDim2.new(1, 0, 0, 60)
			noClans.BackgroundTransparency = 1
			noClans.Text = "No hay clanes disponibles"
			noClans.TextColor3 = THEME.muted
			noClans.TextSize = 13
			noClans.Font = Enum.Font.GothamMedium
			noClans.ZIndex = 104
			noClans.Parent = clansScroll
		end
	end)
end

-- Función: Cargar clanes en admin
loadAdminClans = function()
	if not isAdmin or not adminClansScroll then return end

	for _, child in ipairs(adminClansScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local clans = ClanClient:GetClansList()

	if not clans or #clans == 0 then
		local noClans = Instance.new("TextLabel")
		noClans.Size = UDim2.new(1, 0, 0, 50)
		noClans.BackgroundTransparency = 1
		noClans.Text = "No hay clanes registrados"
		noClans.TextColor3 = THEME.muted
		noClans.TextSize = 12
		noClans.Font = Enum.Font.Gotham
		noClans.ZIndex = 104
		noClans.Parent = adminClansScroll
		return
	end

	for _, clanData in ipairs(clans) do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, 0, 0, 65)
		entry.BackgroundColor3 = THEME.card
		entry.ZIndex = 104
		entry.Parent = adminClansScroll
		rounded(entry, 10)
		stroked(entry, 0.6)

		local clanNameLabel = Instance.new("TextLabel")
		clanNameLabel.Size = UDim2.new(1, -160, 0, 18)
		clanNameLabel.Position = UDim2.new(0, 15, 0, 12)
		clanNameLabel.BackgroundTransparency = 1
		clanNameLabel.Text = clanData.clanName or "Sin nombre"
		clanNameLabel.TextColor3 = THEME.accent
		clanNameLabel.TextSize = 13
		clanNameLabel.Font = Enum.Font.GothamBold
		clanNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		clanNameLabel.ZIndex = 105
		clanNameLabel.Parent = entry

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -160, 0, 14)
		infoLabel.Position = UDim2.new(0, 15, 0, 34)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "ID: " .. (clanData.clanId or "?") .. " • " .. (clanData.miembros_count or 0) .. " miembros"
		infoLabel.TextColor3 = THEME.muted
		infoLabel.TextSize = 10
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.ZIndex = 105
		infoLabel.Parent = entry

		local deleteBtn = Instance.new("TextButton")
		deleteBtn.Size = UDim2.new(0, 70, 0, 32)
		deleteBtn.Position = UDim2.new(1, -80, 0.5, -16)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
		deleteBtn.Text = "Eliminar"
		deleteBtn.TextColor3 = Color3.new(1, 1, 1)
		deleteBtn.TextSize = 10
		deleteBtn.Font = Enum.Font.GothamBold
		deleteBtn.ZIndex = 105
		deleteBtn.AutoButtonColor = false
		deleteBtn.Parent = entry
		rounded(deleteBtn, 6)

		hoverEffect(deleteBtn, Color3.fromRGB(160, 50, 50), Color3.fromRGB(200, 70, 70))
		hoverEffect(entry, THEME.card, Color3.fromRGB(40, 40, 50))

		deleteBtn.MouseButton1Click:Connect(function()
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Eliminar Clan",
				message = "¿Eliminar \"" .. (clanData.clanName or "Sin nombre") .. "\"?\n\nEsta acción no se puede deshacer.",
				confirmText = "Eliminar",
				cancelText = "Cancelar",
				onConfirm = function()
					local success, msg = ClanClient:AdminDissolveClan(clanData.clanId)
					if success then
						Notify:Success("Eliminado", msg or "El clan ha sido eliminado", 4)
						-- No llamar loadAdminClans() aquí, el listener lo hará
					else
						Notify:Error("Error", msg or "No se pudo eliminar", 4)
					end
				end
			})
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
switchTab = function(tabName)
	currentPage = tabName

	for name, btn in pairs(tabButtons) do
		TweenService:Create(btn, TweenInfo.new(0.2), {
			TextColor3 = (name == tabName) and THEME.accent or THEME.muted
		}):Play()
	end

	local positions = { TuClan = 20, Disponibles = 112, Crear = 204, Admin = 296 }
	if not isAdmin then
		positions = { TuClan = 20, Disponibles = 112 }
	end
	TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, positions[tabName] or 20, 0, 93)
	}):Play()

	local pageFrame = contentArea:FindFirstChild(tabName)
	if pageFrame then
		pageLayout:JumpTo(pageFrame)
	end

	if tabName == "TuClan" then
		task.spawn(loadPlayerClan)
	elseif tabName == "Disponibles" then
		task.spawn(loadClansFromServer)
	elseif tabName == "Crear" and isAdmin then
		task.spawn(function()
			-- Asegurarse de que la página existe
			if pageCrear and pageCrear.Parent then
				task.spawn(function() end) -- Página ya está lista
			end
		end)
	elseif tabName == "Admin" and isAdmin then
		task.spawn(loadAdminClans)
	end
end

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	modal:open()
	-- Inicializar ClanClient en background
	task.spawn(function()
		ClanClient:Initialize()
	end)
	switchTab("Disponibles")
end

local function closeUI()
	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(closeUI)

btnCrear.MouseButton1Click:Connect(function()
	local clanName = inputNombre.Text
	local clanTag = inputTag.Text:upper()
	local clanDesc = inputDesc.Text ~= "" and inputDesc.Text or "Sin descripción"
	local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or ""
	local customOwnerId = inputOwnerId.Text ~= "" and tonumber(inputOwnerId.Text) or nil

	if #clanName < 3 then
		Notify:Warning("Nombre inválido", "Mínimo 3 caracteres", 3)
		return
	end

	if #clanTag < 2 or #clanTag > 5 then
		Notify:Warning("TAG inválido", "Entre 2 y 5 caracteres", 3)
		return
	end

	-- Validar ID del owner si se proporcionó
	if customOwnerId and customOwnerId <= 0 then
		Notify:Warning("ID inválido", "El ID del owner debe ser un número válido", 3)
		return
	end

	btnCrear.Text = "Creando..."

	local success, clanId, msg = ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc, customOwnerId)

	if success then
		Notify:Success("Clan Creado", msg or ("Clan '" .. clanName .. "' creado exitosamente"), 5)
		inputNombre.Text = ""
		inputTag.Text = ""
		inputDesc.Text = ""
		inputLogo.Text = ""
		inputOwnerId.Text = ""
		task.wait(0.5)
		switchTab("TuClan")
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
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════

-- Listener para actualizaciones en tiempo real (como DjDashboard)
ClanClient.onClansUpdated = function(clans)
	-- Solo actualizar si estamos en la pestaña correspondiente
	if currentPage == "Disponibles" then
		loadClansFromServer()
	elseif currentPage == "Admin" and isAdmin then
		loadAdminClans()
	end
end

task.spawn(function()
	ClanClient:GetPlayerClan()
end)

print("✅ Clan System v2 - Cargado correctamente")