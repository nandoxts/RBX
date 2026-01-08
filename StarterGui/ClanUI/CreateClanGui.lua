--[[
	Clan System - Professional Edition
	Sistema completo de clanes con roles
	Layout moderno usando ThemeConfig
	Roles: Owner, Colideres, Lideres, Miembros
	VERSION CORREGIDA - Sin overlay doble
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ClanClient = require(ReplicatedStorage:WaitForChild("ClanClient"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local Notify = require(ReplicatedStorage:WaitForChild("NotificationSystem"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("ConfirmationModal"))

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local R_PANEL = 12
local ENABLE_BLUR, BLUR_SIZE = true, 14

-- ════════════════════════════════════════════════════════════════
-- ADMIN CONFIG
-- ════════════════════════════════════════════════════════════════
local ADMIN_IDS = {
	8387751399,
	9375636407,
}

local function isAdminUser(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then
			return true
		end
	end
	return false
end

local isAdmin = isAdminUser(player.UserId)

-- ════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════
local currentPage = "Disponibles"
local uiOpen = false

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

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local PANEL_W_PX = THEME.panelWidth or 980
local PANEL_H_PX = THEME.panelHeight or 620
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
if _G.HDAdminMain then
	local main = _G.HDAdminMain
	if main.client and main.client.Assets then
		local iconModule = main.client.Assets:FindFirstChild("Icon")
		if iconModule then
			Icon = require(iconModule)
		end
	end
end

local clanIcon = nil
if Icon then
	if _G.ClanSystemIcon then
		pcall(function() _G.ClanSystemIcon:destroy() end)
		_G.ClanSystemIcon = nil
	end

	clanIcon = Icon.new()
		:setLabel("CLAN")
		:setOrder(2)
		:bindEvent("selected", function() end)
		:bindEvent("deselected", function() end)
		:setEnabled(true)

	_G.ClanSystemIcon = clanIcon
end

-- ════════════════════════════════════════════════════════════════
-- OVERLAY + BLUR
-- ════════════════════════════════════════════════════════════════
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = THEME.bg
overlay.AutoButtonColor = false
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 95
overlay.Text = ""
overlay.Parent = screenGui

local blur = nil
if ENABLE_BLUR then
	blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting
end

-- ════════════════════════════════════════════════════════════════
-- PANEL PRINCIPAL
-- ════════════════════════════════════════════════════════════════
local panel = Instance.new("Frame")
panel.Name = "ClanPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 1.5, 0)
panel.BackgroundColor3 = THEME.panel or Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 100
panel.Size = UDim2.new(0, PANEL_W_PX, 0, PANEL_H_PX)
panel.Parent = screenGui
rounded(panel, R_PANEL)
stroked(panel, 0.7)

local tabButtons = {}
local tabPages = {}

-- ════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════
-- HEADER COMPLETO (incluye título, botón y separador)
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = THEME.head or Color3.fromRGB(22, 22, 28)
header.BorderSizePixel = 0
header.ZIndex = 101
header.Parent = panel
rounded(header, 12)

-- Gradiente moderno en el header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 24))
}
headerGradient.Rotation = 90
headerGradient.Parent = header

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -100, 0, 60)
title.Position = UDim2.new(0, 20, 0, 0)
title.Text = "CLANES"
title.TextColor3 = THEME.text or Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.ZIndex = 102
title.Parent = header

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -50, 0.5, -18)
closeBtn.BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 45)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 103
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
rounded(closeBtn, 8)
stroked(closeBtn, 0.4)

-- Hover effects para closeBtn
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(180, 60, 60),
		BackgroundTransparency = 0
	}):Play()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		TextColor3 = Color3.new(1, 1, 1)
	}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 45),
		BackgroundTransparency = 0
	}):Play()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- TABS NAVIGATION (Parte de la sección superior)
-- ════════════════════════════════════════════════════════════════
local tabNav = Instance.new("Frame")
tabNav.Name = "TabNavigation"
tabNav.Size = UDim2.new(1, 0, 0, 36)
tabNav.Position = UDim2.new(0, 0, 0, 60)
tabNav.BackgroundColor3 = THEME.panel or Color3.fromRGB(18, 18, 22)
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
	btn.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Parent = tabNav
	return btn
end

tabButtons["TuClan"] = createTab("TU CLAN")
tabButtons["Disponibles"] = createTab("DISPONIBLES")
tabButtons["Crear"] = createTab("CREAR")

if isAdmin then
	tabButtons["Admin"] = createTab("ADMIN")
end

-- Underline indicator
local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 80, 0, 3)
underline.Position = UDim2.new(0, 20, 0, 60 + 33)
underline.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
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
contentArea.BackgroundColor3 = THEME.elevated or Color3.fromRGB(24, 24, 30)
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.ZIndex = 101
contentArea.Parent = panel
rounded(contentArea, 10)
stroked(contentArea, 0.6)

-- Agregar UIPageLayout para navegación CON animación
local pageLayout = Instance.new("UIPageLayout")
pageLayout.FillDirection = Enum.FillDirection.Horizontal
pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pageLayout.EasingStyle = Enum.EasingStyle.Quad
pageLayout.EasingDirection = Enum.EasingDirection.Out
pageLayout.TweenTime = 0.25
pageLayout.Padding = UDim.new(0, 0)
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
pageTuClan.Visible = false
pageTuClan.LayoutOrder = 1
pageTuClan.ZIndex = 102
pageTuClan.Parent = contentArea

local noClanContainer = Instance.new("Frame")
noClanContainer.Size = UDim2.new(1, -30, 1, -30)
noClanContainer.Position = UDim2.new(0, 15, 0, 15)
noClanContainer.BackgroundTransparency = 1
noClanContainer.ZIndex = 102
noClanContainer.Parent = pageTuClan

local noClanCard = Instance.new("Frame")
noClanCard.Size = UDim2.new(0, 300, 0, 160)
noClanCard.Position = UDim2.new(0.5, -150, 0.5, -80)
noClanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
noClanCard.BorderSizePixel = 0
noClanCard.ZIndex = 103
noClanCard.Parent = noClanContainer
rounded(noClanCard, 12)
stroked(noClanCard, 0.6)

local noClanIconBg = Instance.new("Frame")
noClanIconBg.Size = UDim2.new(0, 50, 0, 50)
noClanIconBg.Position = UDim2.new(0.5, -25, 0, 20)
noClanIconBg.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
noClanIconBg.BorderSizePixel = 0
noClanIconBg.ZIndex = 104
noClanIconBg.Parent = noClanCard
rounded(noClanIconBg, 25)

local shieldIcon = Instance.new("Frame")
shieldIcon.Size = UDim2.new(0, 18, 0, 20)
shieldIcon.Position = UDim2.new(0.5, -9, 0.5, -10)
shieldIcon.BackgroundColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
shieldIcon.BorderSizePixel = 0
shieldIcon.ZIndex = 105
shieldIcon.Parent = noClanIconBg
rounded(shieldIcon, 4)

local noClanText = Instance.new("TextLabel")
noClanText.Size = UDim2.new(1, -20, 0, 20)
noClanText.Position = UDim2.new(0, 10, 0, 82)
noClanText.BackgroundTransparency = 1
noClanText.Text = "No perteneces a ningun clan"
noClanText.TextColor3 = THEME.text or Color3.new(1, 1, 1)
noClanText.TextSize = 14
noClanText.Font = Enum.Font.GothamBold
noClanText.ZIndex = 104
noClanText.Parent = noClanCard

local noClanHint = Instance.new("TextLabel")
noClanHint.Size = UDim2.new(1, -20, 0, 32)
noClanHint.Position = UDim2.new(0, 10, 0, 106)
noClanHint.BackgroundTransparency = 1
noClanHint.Text = "Unete a un clan en 'Disponibles' o crea uno en 'Crear'"
noClanHint.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
noClanHint.TextSize = 11
noClanHint.Font = Enum.Font.Gotham
noClanHint.TextWrapped = true
noClanHint.ZIndex = 104
noClanHint.Parent = noClanCard

tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = Instance.new("Frame")
pageDisponibles.Name = "Disponibles"
pageDisponibles.Size = UDim2.fromScale(1, 1)
pageDisponibles.BackgroundTransparency = 1
pageDisponibles.Visible = true
pageDisponibles.LayoutOrder = 2
pageDisponibles.ZIndex = 102
pageDisponibles.Parent = contentArea

-- Barra de busqueda
local searchBar = Instance.new("Frame")
searchBar.Size = UDim2.new(1, -20, 0, 36)
searchBar.Position = UDim2.new(0, 10, 0, 10)
searchBar.BackgroundColor3 = THEME.surface or Color3.fromRGB(32, 32, 40)
searchBar.BorderSizePixel = 0
searchBar.ZIndex = 103
searchBar.Parent = pageDisponibles
rounded(searchBar, 8)
stroked(searchBar, 0.6)

-- Icono de busqueda
local searchIconFrame = Instance.new("Frame")
searchIconFrame.Size = UDim2.new(0, 36, 1, 0)
searchIconFrame.BackgroundTransparency = 1
searchIconFrame.ZIndex = 104
searchIconFrame.Parent = searchBar

local searchCircle = Instance.new("Frame")
searchCircle.Size = UDim2.new(0, 11, 0, 11)
searchCircle.Position = UDim2.new(0.5, -7, 0.5, -7)
searchCircle.BackgroundTransparency = 1
searchCircle.BorderSizePixel = 0
searchCircle.ZIndex = 105
searchCircle.Parent = searchIconFrame
rounded(searchCircle, 6)

local searchCircleStroke = Instance.new("UIStroke")
searchCircleStroke.Color = THEME.muted or Color3.fromRGB(100, 100, 110)
searchCircleStroke.Thickness = 2
searchCircleStroke.Parent = searchCircle

local searchHandle = Instance.new("Frame")
searchHandle.Size = UDim2.new(0, 5, 0, 2)
searchHandle.Position = UDim2.new(0.5, 3, 0.5, 4)
searchHandle.Rotation = 45
searchHandle.BackgroundColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
searchHandle.BorderSizePixel = 0
searchHandle.ZIndex = 105
searchHandle.Parent = searchIconFrame
rounded(searchHandle, 1)

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, -46, 1, 0)
searchInput.Position = UDim2.new(0, 36, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = ""
searchInput.PlaceholderText = "Buscar clanes..."
searchInput.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(80, 80, 90)
searchInput.TextColor3 = THEME.text or Color3.new(1, 1, 1)
searchInput.TextSize = 13
searchInput.Font = Enum.Font.Gotham
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
searchInput.ZIndex = 104
searchInput.Parent = searchBar

-- ScrollingFrame para clanes
local clansScroll = Instance.new("ScrollingFrame")
clansScroll.Size = UDim2.new(1, -20, 1, -56)
clansScroll.Position = UDim2.new(0, 10, 0, 52)
clansScroll.BackgroundTransparency = 1
clansScroll.BorderSizePixel = 0
clansScroll.ScrollBarThickness = 4
clansScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
clansScroll.ScrollBarImageTransparency = 0.3
clansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
clansScroll.ZIndex = 103
clansScroll.Parent = pageDisponibles

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = clansScroll

-- Funcion para crear entrada de clan
local function createClanEntry(clanData)
	local entry = Instance.new("Frame")
	entry.Name = "ClanEntry_" .. (clanData.clanId or "unknown")
	entry.Size = UDim2.new(1, 0, 0, 85)
	entry.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
	entry.BorderSizePixel = 0
	entry.ZIndex = 104
	entry.Parent = clansScroll
	rounded(entry, 10)
	stroked(entry, 0.6)

	-- Logo container
	local logoContainer = Instance.new("Frame")
	logoContainer.Size = UDim2.new(0, 60, 0, 60)
	logoContainer.Position = UDim2.new(0, 12, 0.5, -30)
	logoContainer.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
	logoContainer.BorderSizePixel = 0
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

	if clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
		logo.Visible = false
		local defaultIcon = Instance.new("Frame")
		defaultIcon.Size = UDim2.new(0, 22, 0, 22)
		defaultIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
		defaultIcon.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		defaultIcon.BorderSizePixel = 0
		defaultIcon.ZIndex = 106
		defaultIcon.Parent = logoContainer
		rounded(defaultIcon, 6)
	end

	-- Info container
	local info = Instance.new("Frame")
	info.Size = UDim2.new(1, -180, 0, 65)
	info.Position = UDim2.new(0, 85, 0, 10)
	info.BackgroundTransparency = 1
	info.ZIndex = 105
	info.Parent = entry

	-- Nombre del clan
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -50, 0, 18)
	name.BackgroundTransparency = 1
	name.Text = string.upper(clanData.clanName or "CLAN SIN NOMBRE")
	name.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
	name.TextSize = 13
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 106
	name.Parent = info

	-- Tag
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(0, 45, 0, 14)
	tag.Position = UDim2.new(1, -45, 0, 2)
	tag.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
	tag.BorderSizePixel = 0
	tag.Text = string.upper((clanData.clanId or "????"):sub(1, 4))
	tag.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
	tag.TextSize = 9
	tag.Font = Enum.Font.GothamBold
	tag.ZIndex = 106
	tag.Parent = info
	rounded(tag, 4)

	-- Descripcion
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 26)
	desc.Position = UDim2.new(0, 0, 0, 22)
	desc.BackgroundTransparency = 1
	desc.Text = clanData.descripcion or "Sin descripcion disponible"
	desc.TextColor3 = THEME.subtle or Color3.fromRGB(90, 90, 100)
	desc.TextSize = 11
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.ZIndex = 106
	desc.Parent = info

	-- Stats
	local stats = Instance.new("Frame")
	stats.Size = UDim2.new(1, 0, 0, 16)
	stats.Position = UDim2.new(0, 0, 1, -18)
	stats.BackgroundTransparency = 1
	stats.ZIndex = 106
	stats.Parent = info

	local membersLabel = Instance.new("TextLabel")
	membersLabel.Size = UDim2.new(0, 60, 1, 0)
	membersLabel.BackgroundTransparency = 1
	membersLabel.Text = (clanData.miembros_count or 0) .. "/50"
	membersLabel.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
	membersLabel.TextSize = 10
	membersLabel.Font = Enum.Font.Gotham
	membersLabel.TextXAlignment = Enum.TextXAlignment.Left
	membersLabel.ZIndex = 107
	membersLabel.Parent = stats

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0, 60, 1, 0)
	levelLabel.Position = UDim2.new(0, 65, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Nivel " .. (clanData.nivel or 1)
	levelLabel.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
	levelLabel.TextSize = 10
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.ZIndex = 107
	levelLabel.Parent = stats

	-- Boton unirse
	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.new(0, 75, 0, 30)
	joinBtn.Position = UDim2.new(1, -87, 0.5, -15)
	joinBtn.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
	joinBtn.BorderSizePixel = 0
	joinBtn.Text = "UNIRSE"
	joinBtn.TextColor3 = Color3.new(1, 1, 1)
	joinBtn.TextSize = 11
	joinBtn.Font = Enum.Font.GothamBold
	joinBtn.AutoButtonColor = false
	joinBtn.ZIndex = 106
	joinBtn.Parent = entry
	rounded(joinBtn, 6)

	local originalColor = joinBtn.BackgroundColor3
	joinBtn.MouseEnter:Connect(function()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(
				math.min(255, originalColor.R * 255 * 1.15),
				math.min(255, originalColor.G * 255 * 1.15),
				math.min(255, originalColor.B * 255 * 1.15)
			)
		}):Play()
	end)

	joinBtn.MouseLeave:Connect(function()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {BackgroundColor3 = originalColor}):Play()
	end)

	entry.MouseEnter:Connect(function()
		TweenService:Create(entry, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		}):Play()
	end)

	entry.MouseLeave:Connect(function()
		TweenService:Create(entry, TweenInfo.new(0.2), {
			BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
		}):Play()
	end)

	joinBtn.MouseButton1Click:Connect(function()
		local success, msg = ClanClient:JoinClan(clanData.clanId)
		if success then
			Notify:Success("Unido al clan", msg or ("Te has unido a " .. clanData.clanName), 5)
			task.delay(0.3, loadPlayerClan)
		else
			Notify:Error("Error", msg or "No se pudo unir al clan", 5)
		end
	end)

	return entry
end

local function createNoClansMessage()
	local container = Instance.new("Frame")
	container.Name = "NoClansMessage"
	container.Size = UDim2.new(1, 0, 0, 100)
	container.BackgroundTransparency = 1
	container.ZIndex = 104
	container.Parent = clansScroll

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -40, 0, 40)
	text.Position = UDim2.new(0, 20, 0, 30)
	text.BackgroundTransparency = 1
	text.Text = "No hay clanes disponibles"
	text.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
	text.TextSize = 13
	text.Font = Enum.Font.GothamMedium
	text.ZIndex = 105
	text.Parent = container

	return container
end

local function loadClansFromServer()
	for _, child in ipairs(clansScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local loadingContainer = Instance.new("Frame")
	loadingContainer.Name = "LoadingContainer"
	loadingContainer.Size = UDim2.new(1, 0, 0, 80)
	loadingContainer.BackgroundTransparency = 1
	loadingContainer.ZIndex = 104
	loadingContainer.Parent = clansScroll

	local loadingDots = {}
	for i = 1, 3 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 6, 0, 6)
		dot.Position = UDim2.new(0.5, -15 + (i-1) * 12, 0.5, -3)
		dot.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		dot.BorderSizePixel = 0
		dot.ZIndex = 105
		dot.Parent = loadingContainer
		rounded(dot, 3)
		loadingDots[i] = dot
	end

	local animConnection
	local animIndex = 1
	animConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if not loadingContainer or not loadingContainer.Parent then
			if animConnection then animConnection:Disconnect() end
			return
		end
		for i, dot in ipairs(loadingDots) do
			local targetTransp = (i == animIndex) and 0 or 0.6
			TweenService:Create(dot, TweenInfo.new(0.2), {BackgroundTransparency = targetTransp}):Play()
		end
		animIndex = (animIndex % 3) + 1
	end)

	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.new(1, 0, 0, 18)
	loadingText.Position = UDim2.new(0, 0, 0.5, 12)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = "Cargando clanes..."
	loadingText.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
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

		if clans and #clans > 0 then
			for _, clanData in ipairs(clans) do
				createClanEntry(clanData)
			end
		else
			createNoClansMessage()
		end

		task.wait()
		clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

tabPages["Disponibles"] = pageDisponibles

-- Funcion para cargar el clan del jugador
local function loadPlayerClan()
	for _, child in ipairs(noClanContainer:GetChildren()) do
		child:Destroy()
	end

	local clanData = ClanClient:GetPlayerClan()

	if clanData then
		local clanScroll = Instance.new("ScrollingFrame")
		clanScroll.Size = UDim2.new(1, 0, 1, 0)
		clanScroll.BackgroundTransparency = 1
		clanScroll.BorderSizePixel = 0
		clanScroll.ScrollBarThickness = 4
		clanScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		clanScroll.CanvasSize = UDim2.new(0, 0, 0, 280)
		clanScroll.ZIndex = 103
		clanScroll.Parent = noClanContainer

		local clanCard = Instance.new("Frame")
		clanCard.Size = UDim2.new(1, 0, 0, 260)
		clanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
		clanCard.BorderSizePixel = 0
		clanCard.ZIndex = 104
		clanCard.Parent = clanScroll
		rounded(clanCard, 12)
		stroked(clanCard, 0.6)

		local logoContainer = Instance.new("Frame")
		logoContainer.Size = UDim2.new(0, 70, 0, 70)
		logoContainer.Position = UDim2.new(0.5, -35, 0, 18)
		logoContainer.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
		logoContainer.BorderSizePixel = 0
		logoContainer.ZIndex = 105
		logoContainer.Parent = clanCard
		rounded(logoContainer, 12)

		local logo = Instance.new("ImageLabel")
		logo.Size = UDim2.new(1, 0, 1, 0)
		logo.BackgroundTransparency = 1
		logo.Image = clanData.clanLogo or ""
		logo.ScaleType = Enum.ScaleType.Fit
		logo.ZIndex = 106
		logo.Parent = logoContainer

		if clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
			logo.Visible = false
			local defaultIcon = Instance.new("Frame")
			defaultIcon.Size = UDim2.new(0, 26, 0, 26)
			defaultIcon.Position = UDim2.new(0.5, -13, 0.5, -13)
			defaultIcon.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
			defaultIcon.BorderSizePixel = 0
			defaultIcon.ZIndex = 106
			defaultIcon.Parent = logoContainer
			rounded(defaultIcon, 8)
		end

		local clanName = Instance.new("TextLabel")
		clanName.Size = UDim2.new(1, -20, 0, 20)
		clanName.Position = UDim2.new(0, 10, 0, 96)
		clanName.BackgroundTransparency = 1
		clanName.Text = clanData.clanName or "Clan"
		clanName.TextColor3 = THEME.text or Color3.new(1, 1, 1)
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
		clanTag.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		clanTag.TextSize = 12
		clanTag.Font = Enum.Font.GothamBold
		clanTag.TextXAlignment = Enum.TextXAlignment.Center
		clanTag.ZIndex = 104
		clanTag.Parent = clanCard

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -20, 0, 36)
		desc.Position = UDim2.new(0, 10, 0, 140)
		desc.BackgroundTransparency = 1
		desc.Text = clanData.descripcion or "Sin descripcion"
		desc.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
		desc.TextSize = 11
		desc.Font = Enum.Font.Gotham
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Center
		desc.ZIndex = 104
		desc.Parent = clanCard

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
		memberCount.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		memberCount.TextSize = 10
		memberCount.Font = Enum.Font.Gotham
		memberCount.ZIndex = 104
		memberCount.Parent = statsFrame

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(0.33, 0, 1, 0)
		levelLabel.Position = UDim2.new(0.33, 0, 0, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "Nivel " .. (clanData.nivel or 1)
		levelLabel.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		levelLabel.TextSize = 10
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.ZIndex = 104
		levelLabel.Parent = statsFrame

		local ownerLabel = Instance.new("TextLabel")
		ownerLabel.Size = UDim2.new(0.33, 0, 1, 0)
		ownerLabel.Position = UDim2.new(0.66, 0, 0, 0)
		ownerLabel.BackgroundTransparency = 1
		ownerLabel.Text = "Owner"
		ownerLabel.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		ownerLabel.TextSize = 10
		ownerLabel.Font = Enum.Font.GothamMedium
		ownerLabel.ZIndex = 104
		ownerLabel.Parent = statsFrame

		local editButtonsFrame = Instance.new("Frame")
		editButtonsFrame.Size = UDim2.new(1, -20, 0, 28)
		editButtonsFrame.Position = UDim2.new(0, 10, 0, 212)
		editButtonsFrame.BackgroundTransparency = 1
		editButtonsFrame.ZIndex = 104
		editButtonsFrame.Parent = clanCard

		local btnEditName = Instance.new("TextButton")
		btnEditName.Size = UDim2.new(0.48, 0, 1, 0)
		btnEditName.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
		btnEditName.BorderSizePixel = 0
		btnEditName.Text = "Editar Nombre"
		btnEditName.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		btnEditName.TextSize = 10
		btnEditName.Font = Enum.Font.GothamMedium
		btnEditName.AutoButtonColor = false
		btnEditName.ZIndex = 105
		btnEditName.Parent = editButtonsFrame
		rounded(btnEditName, 6)

		local btnEditTag = Instance.new("TextButton")
		btnEditTag.Size = UDim2.new(0.48, 0, 1, 0)
		btnEditTag.Position = UDim2.new(0.52, 0, 0, 0)
		btnEditTag.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
		btnEditTag.BorderSizePixel = 0
		btnEditTag.Text = "Editar TAG"
		btnEditTag.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		btnEditTag.TextSize = 10
		btnEditTag.Font = Enum.Font.GothamMedium
		btnEditTag.AutoButtonColor = false
		btnEditTag.ZIndex = 105
		btnEditTag.Parent = editButtonsFrame
		rounded(btnEditTag, 6)

		btnEditName.MouseButton1Click:Connect(function()
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Cambiar Nombre del Clan",
				message = "Ingresa el nuevo nombre:",
				inputText = true,
				inputPlaceholder = "Nuevo nombre del clan",
				inputDefault = clanData.clanName,
				confirmText = "Cambiar",
				cancelText = "Cancelar",
				onConfirm = function(newName)
					if newName and #newName >= 3 then
						ClanClient:ChangeClanName(newName)
						Notify:Success("Nombre Actualizado", "El nombre ha sido cambiado a: " .. newName, 4)
						task.wait(1)
						loadPlayerClan()
					else
						Notify:Warning("Nombre invalido", "El nombre debe tener al menos 3 caracteres", 3)
					end
				end
			})
		end)

		btnEditTag.MouseButton1Click:Connect(function()
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Cambiar TAG del Clan",
				message = "Ingresa el nuevo TAG (3-5 caracteres):",
				inputText = true,
				inputPlaceholder = "Ej: XYZ",
				inputDefault = clanData.clanTag or "TAG",
				confirmText = "Cambiar",
				cancelText = "Cancelar",
				onConfirm = function(inputValue)
					local newTag = inputValue and inputValue:upper() or ""
					if newTag and #newTag >= 3 and #newTag <= 5 then
						ClanClient:ChangeClanTag(newTag)
						Notify:Success("TAG Actualizado", "El TAG ha sido cambiado a: [" .. newTag .. "]", 4)
						task.wait(1)
						loadPlayerClan()
					else
						Notify:Warning("TAG invalido", "El TAG debe tener entre 3 y 5 caracteres", 3)
					end
				end
			})
		end)
	else
		local noClanCard = Instance.new("Frame")
		noClanCard.Size = UDim2.new(0, 300, 0, 160)
		noClanCard.Position = UDim2.new(0.5, -150, 0.5, -80)
		noClanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
		noClanCard.BorderSizePixel = 0
		noClanCard.ZIndex = 103
		noClanCard.Parent = noClanContainer
		rounded(noClanCard, 12)
		stroked(noClanCard, 0.6)

		local noClanIconBg = Instance.new("Frame")
		noClanIconBg.Size = UDim2.new(0, 50, 0, 50)
		noClanIconBg.Position = UDim2.new(0.5, -25, 0, 20)
		noClanIconBg.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
		noClanIconBg.BorderSizePixel = 0
		noClanIconBg.ZIndex = 104
		noClanIconBg.Parent = noClanCard
		rounded(noClanIconBg, 25)

		local shieldIcon = Instance.new("Frame")
		shieldIcon.Size = UDim2.new(0, 18, 0, 20)
		shieldIcon.Position = UDim2.new(0.5, -9, 0.5, -10)
		shieldIcon.BackgroundColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
		shieldIcon.BorderSizePixel = 0
		shieldIcon.ZIndex = 105
		shieldIcon.Parent = noClanIconBg
		rounded(shieldIcon, 4)

		local noClanText = Instance.new("TextLabel")
		noClanText.Size = UDim2.new(1, -20, 0, 20)
		noClanText.Position = UDim2.new(0, 10, 0, 82)
		noClanText.BackgroundTransparency = 1
		noClanText.Text = "No perteneces a ningun clan"
		noClanText.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		noClanText.TextSize = 14
		noClanText.Font = Enum.Font.GothamBold
		noClanText.ZIndex = 104
		noClanText.Parent = noClanCard

		local noClanHint = Instance.new("TextLabel")
		noClanHint.Size = UDim2.new(1, -20, 0, 32)
		noClanHint.Position = UDim2.new(0, 10, 0, 106)
		noClanHint.BackgroundTransparency = 1
		noClanHint.Text = "Unete a un clan en 'Disponibles' o crea uno en 'Crear'"
		noClanHint.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
		noClanHint.TextSize = 11
		noClanHint.Font = Enum.Font.Gotham
		noClanHint.TextWrapped = true
		noClanHint.ZIndex = 104
		noClanHint.Parent = noClanCard
	end
end

-- ════════════════════════════════════════════════════════════════
-- PAGE: CREAR
-- ════════════════════════════════════════════════════════════════
local pageCrear = Instance.new("Frame")
pageCrear.Name = "Crear"
pageCrear.Size = UDim2.fromScale(1, 1)
pageCrear.BackgroundTransparency = 1
pageCrear.Visible = false
pageCrear.LayoutOrder = 3
pageCrear.ZIndex = 102
pageCrear.Parent = contentArea

local createScroll = Instance.new("ScrollingFrame")
createScroll.Size = UDim2.new(1, -20, 1, -20)
createScroll.Position = UDim2.new(0, 10, 0, 10)
createScroll.BackgroundTransparency = 1
createScroll.BorderSizePixel = 0
createScroll.ScrollBarThickness = 4
createScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
createScroll.CanvasSize = UDim2.new(0, 0, 0, 440)
createScroll.ZIndex = 103
createScroll.Parent = pageCrear

local createCard = Instance.new("Frame")
createCard.Size = UDim2.new(1, 0, 0, 420)
createCard.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
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
createTitle.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
createTitle.TextSize = 15
createTitle.Font = Enum.Font.GothamBold
createTitle.TextXAlignment = Enum.TextXAlignment.Left
createTitle.ZIndex = 105
createTitle.Parent = createCard

local createSubtitle = Instance.new("TextLabel")
createSubtitle.Size = UDim2.new(1, 0, 0, 14)
createSubtitle.Position = UDim2.new(0, 0, 0, 22)
createSubtitle.BackgroundTransparency = 1
createSubtitle.Text = "Completa los campos para crear tu clan"
createSubtitle.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
createSubtitle.TextSize = 10
createSubtitle.Font = Enum.Font.Gotham
createSubtitle.TextXAlignment = Enum.TextXAlignment.Left
createSubtitle.ZIndex = 105
createSubtitle.Parent = createCard

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 0, 46)
separator.BackgroundColor3 = THEME.stroke or Color3.fromRGB(50, 50, 60)
separator.BackgroundTransparency = 0.5
separator.BorderSizePixel = 0
separator.ZIndex = 105
separator.Parent = createCard

-- Campo: Nombre
local labelNombre = Instance.new("TextLabel")
labelNombre.Size = UDim2.new(1, 0, 0, 14)
labelNombre.Position = UDim2.new(0, 0, 0, 58)
labelNombre.BackgroundTransparency = 1
labelNombre.Text = "NOMBRE DEL CLAN"
labelNombre.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelNombre.TextSize = 10
labelNombre.Font = Enum.Font.GothamBold
labelNombre.TextXAlignment = Enum.TextXAlignment.Left
labelNombre.ZIndex = 105
labelNombre.Parent = createCard

local inputNombre = Instance.new("TextBox")
inputNombre.Size = UDim2.new(1, 0, 0, 36)
inputNombre.Position = UDim2.new(0, 0, 0, 76)
inputNombre.BackgroundColor3 = THEME.surface or Color3.fromRGB(40, 40, 50)
inputNombre.BorderSizePixel = 0
inputNombre.Text = ""
inputNombre.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputNombre.TextSize = 12
inputNombre.Font = Enum.Font.Gotham
inputNombre.PlaceholderText = "Ej: Guardianes del Fuego"
inputNombre.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(80, 80, 90)
inputNombre.ClearTextOnFocus = false
inputNombre.ZIndex = 105
inputNombre.Parent = createCard
rounded(inputNombre, 8)

local inputNombrePad = Instance.new("UIPadding")
inputNombrePad.PaddingLeft = UDim.new(0, 10)
inputNombrePad.PaddingRight = UDim.new(0, 10)
inputNombrePad.Parent = inputNombre

-- Campo: TAG
local labelTag = Instance.new("TextLabel")
labelTag.Size = UDim2.new(1, 0, 0, 14)
labelTag.Position = UDim2.new(0, 0, 0, 124)
labelTag.BackgroundTransparency = 1
labelTag.Text = "TAG DEL CLAN (3-5 caracteres)"
labelTag.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelTag.TextSize = 10
labelTag.Font = Enum.Font.GothamBold
labelTag.TextXAlignment = Enum.TextXAlignment.Left
labelTag.ZIndex = 105
labelTag.Parent = createCard

local inputTag = Instance.new("TextBox")
inputTag.Size = UDim2.new(1, 0, 0, 36)
inputTag.Position = UDim2.new(0, 0, 0, 142)
inputTag.BackgroundColor3 = THEME.surface or Color3.fromRGB(40, 40, 50)
inputTag.BorderSizePixel = 0
inputTag.Text = ""
inputTag.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputTag.TextSize = 12
inputTag.Font = Enum.Font.GothamBold
inputTag.PlaceholderText = "Ej: FGT, CLAN"
inputTag.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(80, 80, 90)
inputTag.ClearTextOnFocus = false
inputTag.ZIndex = 105
inputTag.Parent = createCard
rounded(inputTag, 8)

local inputTagPad = Instance.new("UIPadding")
inputTagPad.PaddingLeft = UDim.new(0, 10)
inputTagPad.PaddingRight = UDim.new(0, 10)
inputTagPad.Parent = inputTag

inputTag:GetPropertyChangedSignal("Text"):Connect(function()
	local text = inputTag.Text
	if text ~= string.upper(text) then
		inputTag.Text = string.upper(text)
	end
end)

-- Campo: Descripcion
local labelDesc = Instance.new("TextLabel")
labelDesc.Size = UDim2.new(1, 0, 0, 14)
labelDesc.Position = UDim2.new(0, 0, 0, 190)
labelDesc.BackgroundTransparency = 1
labelDesc.Text = "DESCRIPCION"
labelDesc.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelDesc.TextSize = 10
labelDesc.Font = Enum.Font.GothamBold
labelDesc.TextXAlignment = Enum.TextXAlignment.Left
labelDesc.ZIndex = 105
labelDesc.Parent = createCard

local inputDesc = Instance.new("TextBox")
inputDesc.Size = UDim2.new(1, 0, 0, 55)
inputDesc.Position = UDim2.new(0, 0, 0, 208)
inputDesc.BackgroundColor3 = THEME.surface or Color3.fromRGB(40, 40, 50)
inputDesc.BorderSizePixel = 0
inputDesc.Text = ""
inputDesc.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputDesc.TextSize = 11
inputDesc.Font = Enum.Font.Gotham
inputDesc.PlaceholderText = "Describe tu clan..."
inputDesc.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(80, 80, 90)
inputDesc.TextWrapped = true
inputDesc.TextYAlignment = Enum.TextYAlignment.Top
inputDesc.MultiLine = true
inputDesc.ClearTextOnFocus = false
inputDesc.ZIndex = 105
inputDesc.Parent = createCard
rounded(inputDesc, 8)

local inputDescPad = Instance.new("UIPadding")
inputDescPad.PaddingTop = UDim.new(0, 8)
inputDescPad.PaddingLeft = UDim.new(0, 10)
inputDescPad.PaddingRight = UDim.new(0, 10)
inputDescPad.Parent = inputDesc

-- Campo: Logo
local labelLogo = Instance.new("TextLabel")
labelLogo.Size = UDim2.new(1, 0, 0, 14)
labelLogo.Position = UDim2.new(0, 0, 0, 276)
labelLogo.BackgroundTransparency = 1
labelLogo.Text = "LOGO (Asset ID - Opcional)"
labelLogo.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelLogo.TextSize = 10
labelLogo.Font = Enum.Font.GothamBold
labelLogo.TextXAlignment = Enum.TextXAlignment.Left
labelLogo.ZIndex = 105
labelLogo.Parent = createCard

local inputLogo = Instance.new("TextBox")
inputLogo.Size = UDim2.new(1, 0, 0, 36)
inputLogo.Position = UDim2.new(0, 0, 0, 294)
inputLogo.BackgroundColor3 = THEME.surface or Color3.fromRGB(40, 40, 50)
inputLogo.BorderSizePixel = 0
inputLogo.Text = ""
inputLogo.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputLogo.TextSize = 12
inputLogo.Font = Enum.Font.Gotham
inputLogo.PlaceholderText = "rbxassetid://123456789"
inputLogo.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(80, 80, 90)
inputLogo.ClearTextOnFocus = false
inputLogo.ZIndex = 105
inputLogo.Parent = createCard
rounded(inputLogo, 8)

local inputLogoPad = Instance.new("UIPadding")
inputLogoPad.PaddingLeft = UDim.new(0, 10)
inputLogoPad.PaddingRight = UDim.new(0, 10)
inputLogoPad.Parent = inputLogo

-- Boton crear
local btnCrear = Instance.new("TextButton")
btnCrear.Size = UDim2.new(1, 0, 0, 40)
btnCrear.Position = UDim2.new(0, 0, 0, 348)
btnCrear.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
btnCrear.BorderSizePixel = 0
btnCrear.Text = "CREAR CLAN"
btnCrear.TextColor3 = Color3.new(1, 1, 1)
btnCrear.TextSize = 13
btnCrear.Font = Enum.Font.GothamBold
btnCrear.AutoButtonColor = false
btnCrear.ZIndex = 105
btnCrear.Parent = createCard
rounded(btnCrear, 8)

local btnOriginalColor = btnCrear.BackgroundColor3
btnCrear.MouseEnter:Connect(function()
	TweenService:Create(btnCrear, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(
			math.min(255, btnOriginalColor.R * 255 * 1.15),
			math.min(255, btnOriginalColor.G * 255 * 1.15),
			math.min(255, btnOriginalColor.B * 255 * 1.15)
		)
	}):Play()
end)

btnCrear.MouseLeave:Connect(function()
	TweenService:Create(btnCrear, TweenInfo.new(0.15), {
		BackgroundColor3 = btnOriginalColor
	}):Play()
end)

tabPages["Crear"] = pageCrear

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin = nil
local adminClansScroll = nil

if isAdmin then
	pageAdmin = Instance.new("Frame")
	pageAdmin.Name = "Admin"
	pageAdmin.Size = UDim2.fromScale(1, 1)
	pageAdmin.BackgroundTransparency = 1
	pageAdmin.Visible = false
	pageAdmin.ZIndex = 102
	pageAdmin.Parent = contentArea

	local adminHeader = Instance.new("Frame")
	adminHeader.Size = UDim2.new(1, -20, 0, 40)
	adminHeader.Position = UDim2.new(0, 10, 0, 10)
	adminHeader.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
	adminHeader.BorderSizePixel = 0
	adminHeader.ZIndex = 103
	adminHeader.Parent = pageAdmin
	rounded(adminHeader, 8)
	stroked(adminHeader, 0.5, Color3.fromRGB(180, 70, 70))

	local adminWarning = Instance.new("TextLabel")
	adminWarning.Size = UDim2.new(1, -16, 1, 0)
	adminWarning.Position = UDim2.new(0, 8, 0, 0)
	adminWarning.BackgroundTransparency = 1
	adminWarning.Text = "Panel de Administrador - Acciones irreversibles"
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
	adminClansScroll.BorderSizePixel = 0
	adminClansScroll.ScrollBarThickness = 4
	adminClansScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
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

local function loadAdminClans()
	if not isAdmin or not adminClansScroll then return end

	for _, child in ipairs(adminClansScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local clans = ClanClient:GetClansList()
	if not clans then return end

	if not clans or #clans == 0 then
		local noClansLabel = Instance.new("TextLabel")
		noClansLabel.Size = UDim2.new(1, 0, 0, 50)
		noClansLabel.BackgroundTransparency = 1
		noClansLabel.Text = "No hay clanes registrados"
		noClansLabel.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
		noClansLabel.TextSize = 12
		noClansLabel.Font = Enum.Font.Gotham
		noClansLabel.ZIndex = 104
		noClansLabel.Parent = adminClansScroll
		return
	end

	for _, clanData in ipairs(clans) do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, 0, 0, 65)
		entry.BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)
		entry.BorderSizePixel = 0
		entry.ZIndex = 104
		entry.Parent = adminClansScroll
		rounded(entry, 10)
		stroked(entry, 0.6)

		local miniLogo = Instance.new("Frame")
		miniLogo.Size = UDim2.new(0, 42, 0, 42)
		miniLogo.Position = UDim2.new(0, 10, 0.5, -21)
		miniLogo.BackgroundColor3 = THEME.surface or Color3.fromRGB(45, 45, 55)
		miniLogo.BorderSizePixel = 0
		miniLogo.ZIndex = 105
		miniLogo.Parent = entry
		rounded(miniLogo, 8)

		local logoIcon = Instance.new("Frame")
		logoIcon.Size = UDim2.new(0, 16, 0, 16)
		logoIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
		logoIcon.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		logoIcon.BorderSizePixel = 0
		logoIcon.ZIndex = 106
		logoIcon.Parent = miniLogo
		rounded(logoIcon, 4)

		local clanNameLabel = Instance.new("TextLabel")
		clanNameLabel.Size = UDim2.new(1, -160, 0, 18)
		clanNameLabel.Position = UDim2.new(0, 62, 0, 12)
		clanNameLabel.BackgroundTransparency = 1
		clanNameLabel.Text = clanData.clanName or "Sin nombre"
		clanNameLabel.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		clanNameLabel.TextSize = 13
		clanNameLabel.Font = Enum.Font.GothamBold
		clanNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		clanNameLabel.ZIndex = 105
		clanNameLabel.Parent = entry

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -160, 0, 14)
		infoLabel.Position = UDim2.new(0, 62, 0, 34)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "ID: " .. (clanData.clanId or "?") .. " | " .. (clanData.miembros_count or 0) .. " miembros"
		infoLabel.TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
		infoLabel.TextSize = 10
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.ZIndex = 105
		infoLabel.Parent = entry

		local deleteBtn = Instance.new("TextButton")
		deleteBtn.Size = UDim2.new(0, 70, 0, 32)
		deleteBtn.Position = UDim2.new(1, -80, 0.5, -16)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
		deleteBtn.BorderSizePixel = 0
		deleteBtn.Text = "Eliminar"
		deleteBtn.TextColor3 = Color3.new(1, 1, 1)
		deleteBtn.TextSize = 10
		deleteBtn.Font = Enum.Font.GothamBold
		deleteBtn.ZIndex = 105
		deleteBtn.AutoButtonColor = false
		deleteBtn.Parent = entry
		rounded(deleteBtn, 6)

		deleteBtn.MouseEnter:Connect(function()
			TweenService:Create(deleteBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 70, 70)}):Play()
		end)

		deleteBtn.MouseLeave:Connect(function()
			TweenService:Create(deleteBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 50, 50)}):Play()
		end)

		deleteBtn.MouseButton1Click:Connect(function()
			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Eliminar Clan",
				message = "Eliminar \"" .. (clanData.clanName or "Sin nombre") .. "\"?\n\nEsta accion no se puede deshacer.",
				confirmText = "Eliminar",
				cancelText = "Cancelar",
				onConfirm = function()
					local success = ClanClient:AdminDissolveClan(clanData.clanId)
					if success then
						Notify:Success("Clan Eliminado", "El clan ha sido eliminado", 4)
					else
						Notify:Error("Error", "No se pudo eliminar el clan", 4)
					end
					task.wait(0.3)
					loadAdminClans()
				end
			})
		end)

		entry.MouseEnter:Connect(function()
			TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
		end)

		entry.MouseLeave:Connect(function()
			TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card or Color3.fromRGB(32, 32, 40)}):Play()
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
local function switchTab(tabName)
	currentPage = tabName

	for name, btn in pairs(tabButtons) do
		if name == tabName then
			TweenService:Create(btn, TweenInfo.new(0.2), {
				TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
			}):Play()
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {
				TextColor3 = THEME.muted or Color3.fromRGB(100, 100, 110)
			}):Play()
		end
	end

	-- Animar el underline
	local newX = 20
	if tabName == "TuClan" then newX = 20
	elseif tabName == "Disponibles" then newX = 20 + 80 + 12
	elseif tabName == "Crear" then newX = 20 + (80 + 12) * 2
	elseif tabName == "Admin" and isAdmin then newX = 20 + (80 + 12) * 3
	end

	TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, newX, 0, 60 + 33)
	}):Play()

	local pageFrame = contentArea:FindFirstChild(tabName)
	if pageFrame then
		pageFrame.Visible = true
		pageLayout:JumpTo(pageFrame)
	end

	if tabName == "TuClan" then
		task.spawn(loadPlayerClan)
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
	if uiOpen then return end
	uiOpen = true
	panel.Visible = true
	overlay.Visible = true

	TweenService:Create(overlay, TweenInfo.new(0.22), {BackgroundTransparency = 0.45}):Play()
	if blur then
		blur.Enabled = true
		TweenService:Create(blur, TweenInfo.new(0.22), {Size = BLUR_SIZE}):Play()
	end

	panel.Position = UDim2.fromScale(0.5, 1.1)
	TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

	task.spawn(loadClansFromServer)
	switchTab("Disponibles")
end

local function closeUI()
	if not uiOpen then return end
	uiOpen = false

	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = UDim2.fromScale(0.5, 1.1)}):Play()
	TweenService:Create(overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()

	task.delay(0.22, function()
		overlay.Visible = false
		panel.Visible = false
	end)

	if blur then
		TweenService:Create(blur, TweenInfo.new(0.22), {Size = 0}):Play()
		task.delay(0.22, function()
			if blur then blur.Enabled = false end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
	closeUI()
	if clanIcon then
		clanIcon:deselect()
	end
end)

overlay.MouseButton1Click:Connect(function()
	closeUI()
	if clanIcon then
		clanIcon:deselect()
	end
end)

btnCrear.MouseButton1Click:Connect(function()
	local clanName = inputNombre.Text
	local clanTag = inputTag.Text:upper()
	local clanDesc = inputDesc.Text ~= "" and inputDesc.Text or "Sin descripcion"
	local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or ""

	if clanName == "" or #clanName < 3 then
		Notify:Warning("Nombre invalido", "El nombre debe tener al menos 3 caracteres", 3)
		local originalColor = inputNombre.BackgroundColor3
		TweenService:Create(inputNombre, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(160, 50, 50)}):Play()
		task.wait(0.2)
		TweenService:Create(inputNombre, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
		return
	end

	if clanTag == "" or #clanTag < 3 or #clanTag > 5 then
		Notify:Warning("TAG invalido", "El TAG debe tener entre 3 y 5 caracteres", 3)
		local originalColor = inputTag.BackgroundColor3
		TweenService:Create(inputTag, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(160, 50, 50)}):Play()
		task.wait(0.2)
		TweenService:Create(inputTag, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
		return
	end

	btnCrear.Text = "Creando..."

	local success, clanId, msg = ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc)

	if success then
		Notify:Success("Clan Creado", msg or ("Tu clan '" .. clanName .. "' ha sido creado"), 5)
	else
		Notify:Error("Error", msg or "No se pudo crear el clan", 5)
	end

	btnCrear.Text = "CREAR CLAN"
	inputNombre.Text = ""
	inputTag.Text = ""
	inputDesc.Text = ""
	inputLogo.Text = ""

	task.wait(0.5)
	loadClansFromServer()
	switchTab("Disponibles")
end)

if clanIcon then
	clanIcon:bindEvent("selected", function()
		openUI()
	end)

	clanIcon:bindEvent("deselected", function()
		closeUI()
	end)
end

-- Inicializar el estado del clan del jugador
task.spawn(function()
	ClanClient:GetPlayerClan()
end)

print("Clan System UI - Version corregida cargada")
