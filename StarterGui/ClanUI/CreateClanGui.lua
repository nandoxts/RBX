--[[ Clan System - Professional Edition FIXED
     • Sistema completo de clanes con roles
     • Layout moderno usando ThemeConfig
     • Roles: Owner, Colideres, Lideres, Miembros
     • VERSIÓN CORREGIDA - UI visible y funcional
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

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local R_PANEL, R_CTRL = 12, 8
local ENABLE_BLUR, BLUR_SIZE = true, 14

-- ════════════════════════════════════════════════════════════════
-- ADMIN CONFIG
-- ════════════════════════════════════════════════════════════════
local ADMIN_IDS = {
	8387751399,  -- nandoxts (Owner)
	9375636407,  -- Admin2
}

local function isAdminUser(userId)
	for _, adminId in ipairs(ADMIN_IDS) do
		if userId == adminId then return true end
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

local function addShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = parent
	return shadow
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
		pcall(function()
			_G.ClanSystemIcon:destroy()
		end)
		_G.ClanSystemIcon = nil
	end

	clanIcon = Icon.new()
		:setLabel("CLAN")
		:setOrder(2)
		:bindEvent("selected", function()
			-- Open UI
		end)
		:bindEvent("deselected", function()
			-- Close UI
		end)
		:setEnabled(true)

	_G.ClanSystemIcon = clanIcon
end

-- ════════════════════════════════════════════════════════════════
-- OVERLAY + BLUR
-- ════════════════════════════════════════════════════════════════
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.AutoButtonColor = false
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 1
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
panel.Position = UDim2.new(0.5, 0, 1.5, 0) -- Fuera de pantalla inicialmente
panel.BackgroundColor3 = THEME.panel or Color3.fromRGB(25, 25, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.Size = UDim2.new(0, 750, 0, 550)
panel.Parent = screenGui
rounded(panel, R_PANEL)
stroked(panel, 0.3)
addShadow(panel)

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 70)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = THEME.head or Color3.fromRGB(20, 20, 25)
header.BorderSizePixel = 0
header.ZIndex = 11
header.Parent = panel

-- Esquinas redondeadas solo arriba
local headerCorner = Instance.new("Frame")
headerCorner.Size = UDim2.new(1, 0, 0, 20)
headerCorner.Position = UDim2.new(0, 0, 1, -10)
headerCorner.BackgroundColor3 = header.BackgroundColor3
headerCorner.BorderSizePixel = 0
headerCorner.ZIndex = 11
headerCorner.Parent = header

rounded(header, R_PANEL)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
}
gradient.Rotation = 90
gradient.Parent = header

-- Icono de clan
local clanIconLabel = Instance.new("TextLabel")
clanIconLabel.Name = "ClanIcon"
clanIconLabel.Size = UDim2.new(0, 40, 0, 40)
clanIconLabel.Position = UDim2.new(0, 20, 0.5, -20)
clanIconLabel.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
clanIconLabel.BorderSizePixel = 0
clanIconLabel.Text = "⚔"
clanIconLabel.TextColor3 = Color3.new(1, 1, 1)
clanIconLabel.TextSize = 20
clanIconLabel.Font = Enum.Font.GothamBold
clanIconLabel.ZIndex = 12
clanIconLabel.Parent = header
rounded(clanIconLabel, 8)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -150, 0, 24)
title.Position = UDim2.new(0, 75, 0, 14)
title.Text = "SISTEMA DE CLANES"
title.TextColor3 = THEME.text or Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -150, 0, 16)
subtitle.Position = UDim2.new(0, 75, 0, 40)
subtitle.Text = "Crea, únete y gestiona tu clan"
subtitle.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 12
subtitle.Parent = header

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -55, 0.5, -20)
closeBtn.BackgroundColor3 = THEME.btnDanger or Color3.fromRGB(200, 80, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 13
closeBtn.AutoButtonColor = true
closeBtn.Parent = header
rounded(closeBtn, 8)

-- ════════════════════════════════════════════════════════════════
-- TABS NAVIGATION
-- ════════════════════════════════════════════════════════════════
local tabNav = Instance.new("Frame")
tabNav.Name = "TabNavigation"
tabNav.Size = UDim2.new(1, -40, 0, 45)
tabNav.Position = UDim2.new(0, 20, 0, 85)
tabNav.BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 42)
tabNav.BorderSizePixel = 0
tabNav.ZIndex = 11
tabNav.Parent = panel
rounded(tabNav, 10)
stroked(tabNav, 0.4)

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 5)
tabPadding.PaddingRight = UDim.new(0, 5)
tabPadding.PaddingTop = UDim.new(0, 5)
tabPadding.PaddingBottom = UDim.new(0, 5)
tabPadding.Parent = tabNav

local tabButtons = {}
local tabPages = {}

-- Calcular cantidad de tabs según si es admin o no
local totalTabs = isAdmin and 4 or 3

local function createTabButton(text, icon, index, total)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(1/total, -5, 1, 0)
	btn.Position = UDim2.new((index - 1) / total, (index - 1) * 2.5, 0, 0)
	btn.BackgroundColor3 = THEME.btnSecondary or Color3.fromRGB(45, 45, 55)
	btn.BorderSizePixel = 0
	btn.Text = icon .. "  " .. text
	btn.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 12
	btn.AutoButtonColor = false
	btn.Parent = tabNav
	rounded(btn, 8)

	-- Hover effect
	btn.MouseEnter:Connect(function()
		if btn.BackgroundColor3 ~= (THEME.accent or Color3.fromRGB(138, 99, 210)) then
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(55, 55, 65)
			}):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		if btn.BackgroundColor3 ~= (THEME.accent or Color3.fromRGB(138, 99, 210)) then
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = THEME.btnSecondary or Color3.fromRGB(45, 45, 55)
			}):Play()
		end
	end)

	return btn
end

tabButtons["TuClan"] = createTabButton("Tu Clan", "🏠", 1, totalTabs)
tabButtons["Disponibles"] = createTabButton("Disponibles", "🔍", 2, totalTabs)
tabButtons["Crear"] = createTabButton("Crear", "➕", 3, totalTabs)
if isAdmin then
	tabButtons["Admin"] = createTabButton("Admin", "🔨", 4, totalTabs)
end

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -40, 1, -155)
contentArea.Position = UDim2.new(0, 20, 0, 140)
contentArea.BackgroundColor3 = THEME.elevated or Color3.fromRGB(30, 30, 38)
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.ZIndex = 11
contentArea.Parent = panel
rounded(contentArea, 10)
stroked(contentArea, 0.3)

-- ════════════════════════════════════════════════════════════════
-- PAGE: TU CLAN
-- ════════════════════════════════════════════════════════════════
local pageTuClan = Instance.new("Frame")
pageTuClan.Name = "TuClan"
pageTuClan.Size = UDim2.fromScale(1, 1)
pageTuClan.BackgroundTransparency = 1
pageTuClan.Visible = false
pageTuClan.ZIndex = 12
pageTuClan.Parent = contentArea

-- Contenedor centrado
local noClanContainer = Instance.new("Frame")
noClanContainer.Size = UDim2.new(1, -40, 1, -40)
noClanContainer.Position = UDim2.new(0, 20, 0, 20)
noClanContainer.BackgroundTransparency = 1
noClanContainer.ZIndex = 12
noClanContainer.Parent = pageTuClan

local noClanCard = Instance.new("Frame")
noClanCard.Size = UDim2.new(0, 350, 0, 200)
noClanCard.Position = UDim2.new(0.5, -175, 0.5, -100)
noClanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
noClanCard.BorderSizePixel = 0
noClanCard.ZIndex = 13
noClanCard.Parent = noClanContainer
rounded(noClanCard, 12)
stroked(noClanCard, 0.4)

-- Icono grande
local noClanIcon = Instance.new("TextLabel")
noClanIcon.Size = UDim2.new(0, 70, 0, 70)
noClanIcon.Position = UDim2.new(0.5, -35, 0, 25)
noClanIcon.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
noClanIcon.BorderSizePixel = 0
noClanIcon.Text = "🛡️"
noClanIcon.TextSize = 35
noClanIcon.ZIndex = 14
noClanIcon.Parent = noClanCard
rounded(noClanIcon, 35)

local noClanText = Instance.new("TextLabel")
noClanText.Size = UDim2.new(1, -30, 0, 24)
noClanText.Position = UDim2.new(0, 15, 0, 110)
noClanText.BackgroundTransparency = 1
noClanText.Text = "No perteneces a ningún clan"
noClanText.TextColor3 = THEME.text or Color3.new(1, 1, 1)
noClanText.TextSize = 16
noClanText.Font = Enum.Font.GothamBold
noClanText.ZIndex = 14
noClanText.Parent = noClanCard

local noClanHint = Instance.new("TextLabel")
noClanHint.Size = UDim2.new(1, -30, 0, 40)
noClanHint.Position = UDim2.new(0, 15, 0, 138)
noClanHint.BackgroundTransparency = 1
noClanHint.Text = "Únete a un clan existente en 'Disponibles'\no crea tu propio clan en 'Crear'"
noClanHint.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
noClanHint.TextSize = 12
noClanHint.Font = Enum.Font.Gotham
noClanHint.TextWrapped = true
noClanHint.ZIndex = 14
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
pageDisponibles.ZIndex = 12
pageDisponibles.Parent = contentArea

-- Barra de búsqueda
local searchBar = Instance.new("Frame")
searchBar.Size = UDim2.new(1, -20, 0, 40)
searchBar.Position = UDim2.new(0, 10, 0, 10)
searchBar.BackgroundColor3 = THEME.surface or Color3.fromRGB(40, 40, 50)
searchBar.BorderSizePixel = 0
searchBar.ZIndex = 13
searchBar.Parent = pageDisponibles
rounded(searchBar, 8)
stroked(searchBar, 0.5)

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 40, 1, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextSize = 16
searchIcon.ZIndex = 14
searchIcon.Parent = searchBar

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, -50, 1, 0)
searchInput.Position = UDim2.new(0, 40, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = ""
searchInput.PlaceholderText = "Buscar clanes..."
searchInput.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(100, 100, 110)
searchInput.TextColor3 = THEME.text or Color3.new(1, 1, 1)
searchInput.TextSize = 13
searchInput.Font = Enum.Font.Gotham
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
searchInput.ZIndex = 14
searchInput.Parent = searchBar

-- ScrollingFrame para clanes
local clansScroll = Instance.new("ScrollingFrame")
clansScroll.Size = UDim2.new(1, -20, 1, -65)
clansScroll.Position = UDim2.new(0, 10, 0, 60)
clansScroll.BackgroundTransparency = 1
clansScroll.BorderSizePixel = 0
clansScroll.ScrollBarThickness = 5
clansScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
clansScroll.ScrollBarImageTransparency = 0.3
clansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
clansScroll.ZIndex = 13
clansScroll.Parent = pageDisponibles

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = clansScroll

-- Función para crear entrada de clan
local function createClanEntry(clanData)
	local entry = Instance.new("Frame")
	entry.Name = "ClanEntry_" .. (clanData.clanId or "unknown")
	entry.Size = UDim2.new(1, 0, 0, 100)
	entry.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
	entry.BorderSizePixel = 0
	entry.ZIndex = 14
	entry.Parent = clansScroll
	rounded(entry, 10)
	stroked(entry, 0.4)

	-- Logo container
	local logoContainer = Instance.new("Frame")
	logoContainer.Size = UDim2.new(0, 75, 0, 75)
	logoContainer.Position = UDim2.new(0, 12, 0.5, -37)
	logoContainer.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
	logoContainer.BorderSizePixel = 0
	logoContainer.ZIndex = 15
	logoContainer.Parent = entry
	rounded(logoContainer, 10)
	stroked(logoContainer, 0.4)

	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(1, -10, 1, -10)
	logo.Position = UDim2.new(0, 5, 0, 5)
	logo.BackgroundTransparency = 1
	logo.Image = clanData.clanLogo or ""
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 16
	logo.Parent = logoContainer

	-- Si no hay logo, mostrar emoji
	if clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
		logo.Visible = false
		local logoText = Instance.new("TextLabel")
		logoText.Size = UDim2.fromScale(1, 1)
		logoText.BackgroundTransparency = 1
		logoText.Text = "⚔️"
		logoText.TextSize = 30
		logoText.ZIndex = 16
		logoText.Parent = logoContainer
	end

	-- Info container
	local info = Instance.new("Frame")
	info.Size = UDim2.new(1, -200, 0, 80)
	info.Position = UDim2.new(0, 100, 0, 10)
	info.BackgroundTransparency = 1
	info.ZIndex = 15
	info.Parent = entry

	-- Nombre del clan
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 22)
	name.BackgroundTransparency = 1
	name.Text = string.upper(clanData.clanName or "CLAN SIN NOMBRE")
	name.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
	name.TextSize = 15
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 16
	name.Parent = info

	-- Tag/ID
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(0, 60, 0, 18)
	tag.Position = UDim2.new(1, -60, 0, 2)
	tag.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
	tag.BorderSizePixel = 0
	tag.Text = "[" .. string.upper((clanData.clanId or "????"):sub(1, 4)) .. "]"
	tag.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	tag.TextSize = 10
	tag.Font = Enum.Font.GothamBold
	tag.ZIndex = 16
	tag.Parent = info
	rounded(tag, 4)

	-- Descripción
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 30)
	desc.Position = UDim2.new(0, 0, 0, 26)
	desc.BackgroundTransparency = 1
	desc.Text = clanData.descripcion or "Sin descripción disponible"
	desc.TextColor3 = THEME.subtle or Color3.fromRGB(120, 120, 130)
	desc.TextSize = 11
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.ZIndex = 16
	desc.Parent = info

	-- Stats container
	local stats = Instance.new("Frame")
	stats.Size = UDim2.new(1, 0, 0, 20)
	stats.Position = UDim2.new(0, 0, 1, -22)
	stats.BackgroundTransparency = 1
	stats.ZIndex = 16
	stats.Parent = info

	-- Miembros
	local membersLabel = Instance.new("TextLabel")
	membersLabel.Size = UDim2.new(0, 80, 1, 0)
	membersLabel.BackgroundTransparency = 1
	membersLabel.Text = "👥 " .. (clanData.miembros_count or 0) .. "/50"
	membersLabel.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	membersLabel.TextSize = 11
	membersLabel.Font = Enum.Font.Gotham
	membersLabel.TextXAlignment = Enum.TextXAlignment.Left
	membersLabel.ZIndex = 17
	membersLabel.Parent = stats

	-- Nivel
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0, 80, 1, 0)
	levelLabel.Position = UDim2.new(0, 85, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "⭐ Nivel " .. (clanData.nivel or 1)
	levelLabel.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	levelLabel.TextSize = 11
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.ZIndex = 17
	levelLabel.Parent = stats

	-- Botón unirse
	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.new(0, 90, 0, 36)
	joinBtn.Position = UDim2.new(1, -100, 0.5, -18)
	joinBtn.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
	joinBtn.BorderSizePixel = 0
	joinBtn.Text = "UNIRSE"
	joinBtn.TextColor3 = Color3.new(1, 1, 1)
	joinBtn.TextSize = 12
	joinBtn.Font = Enum.Font.GothamBold
	joinBtn.AutoButtonColor = false
	joinBtn.ZIndex = 16
	joinBtn.Parent = entry
	rounded(joinBtn, 8)

	-- Hover effect para el botón
	local originalColor = joinBtn.BackgroundColor3
	joinBtn.MouseEnter:Connect(function()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(
				math.min(255, originalColor.R * 255 * 1.15),
				math.min(255, originalColor.G * 255 * 1.15),
				math.min(255, originalColor.B * 255 * 1.15)
			)
		}):Play()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 95, 0, 38)}):Play()
	end)

	joinBtn.MouseLeave:Connect(function()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {BackgroundColor3 = originalColor}):Play()
		TweenService:Create(joinBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 90, 0, 36)}):Play()
	end)

	-- Hover effect para la entry completa
	entry.MouseEnter:Connect(function()
		TweenService:Create(entry, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		}):Play()
	end)

	entry.MouseLeave:Connect(function()
		TweenService:Create(entry, TweenInfo.new(0.2), {
			BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
		}):Play()
	end)

	-- Click event
	joinBtn.MouseButton1Click:Connect(function()
		print("Intentando unirse al clan:", clanData.clanId)
		
		local success, msg = ClanClient:JoinClan(clanData.clanId)
		
		if success then
			Notify:Success("¡Unido al clan!", msg or ("Te has unido a " .. clanData.clanName), 5)
			task.delay(0.3, loadPlayerClan)
		else
			Notify:Error("Error", msg or "No se pudo unir al clan", 5)
		end
	end)

	return entry
end

-- Mensaje cuando no hay clanes
local function createNoClansMessage()
	local container = Instance.new("Frame")
	container.Name = "NoClansMessage"
	container.Size = UDim2.new(1, 0, 0, 150)
	container.BackgroundTransparency = 1
	container.ZIndex = 14
	container.Parent = clansScroll

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -40, 0, 50)
	text.Position = UDim2.new(0, 20, 0, 50)
	text.BackgroundTransparency = 1
	text.Text = "Clanes no disponibles"
	text.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	text.TextSize = 16
	text.Font = Enum.Font.GothamBold
	text.TextWrapped = true
	text.ZIndex = 15
	text.Parent = container

	return container
end

-- Función para cargar clanes
local function loadClansFromServer()
	-- Limpiar lista actual (excepto UIListLayout)
	for _, child in ipairs(clansScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Mostrar loading
	local loadingContainer = Instance.new("Frame")
	loadingContainer.Name = "LoadingContainer"
	loadingContainer.Size = UDim2.new(1, 0, 0, 120)
	loadingContainer.BackgroundTransparency = 1
	loadingContainer.ZIndex = 14
	loadingContainer.Parent = clansScroll
	
	local loadingSpinner = Instance.new("TextLabel")
	loadingSpinner.Size = UDim2.new(0, 60, 0, 60)
	loadingSpinner.Position = UDim2.new(0.5, -30, 0, 15)
	loadingSpinner.BackgroundTransparency = 1
	loadingSpinner.Text = "⏳"
	loadingSpinner.TextSize = 40
	loadingSpinner.ZIndex = 15
	loadingSpinner.Parent = loadingContainer
	
	-- Animación de rotación
	local rotation = 0
	local spinConnection
	spinConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if loadingSpinner and loadingSpinner.Parent then
			rotation = rotation + 5
			loadingSpinner.Rotation = rotation
		else
			if spinConnection then spinConnection:Disconnect() end
		end
	end)
	
	local loadingText = Instance.new("TextLabel")
	loadingText.Size = UDim2.new(1, 0, 0, 25)
	loadingText.Position = UDim2.new(0, 0, 0, 80)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = "Cargando clanes..."
	loadingText.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
	loadingText.TextSize = 13
	loadingText.Font = Enum.Font.Gotham
	loadingText.ZIndex = 15
	loadingText.Parent = loadingContainer

	-- Obtener clanes de forma asíncrona
	task.spawn(function()
		local clans = ClanClient:GetClansList()
		print("📊 Clanes obtenidos:", clans and #clans or 0)
		
		-- Destruir loading
		if spinConnection then spinConnection:Disconnect() end
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

		-- Actualizar canvas size
		task.wait()
		clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

tabPages["Disponibles"] = pageDisponibles

-- Función para cargar el clan del jugador
local function loadPlayerClan()
	-- Limpiar contenedor completamente
	for _, child in ipairs(noClanContainer:GetChildren()) do
		child:Destroy()
	end
	
	local clanData = ClanClient:GetPlayerClan()
	
	if clanData then
		-- Crear un ScrollingFrame para mostrar el clan
		local clanScroll = Instance.new("ScrollingFrame")
		clanScroll.Size = UDim2.new(1, 0, 1, 0)
		clanScroll.Position = UDim2.new(0, 0, 0, 0)
		clanScroll.BackgroundTransparency = 1
		clanScroll.BorderSizePixel = 0
		clanScroll.ScrollBarThickness = 5
		clanScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		clanScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
		clanScroll.ZIndex = 13
		clanScroll.Parent = noClanContainer
		
		-- Crear la estructura del clan dentro del scroll
		local clanCard = Instance.new("Frame")
		clanCard.Name = "ClanCard_" .. clanData.clanId
		clanCard.Size = UDim2.new(1, 0, 0, 280)
		clanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
		clanCard.BorderSizePixel = 0
		clanCard.ZIndex = 14
		clanCard.Parent = clanScroll
		rounded(clanCard, 12)
		stroked(clanCard, 0.4)
		
		-- Logo del clan
		local logoContainer = Instance.new("Frame")
		logoContainer.Size = UDim2.new(0, 100, 0, 100)
		logoContainer.Position = UDim2.new(0.5, -50, 0, 15)
		logoContainer.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
		logoContainer.BorderSizePixel = 0
		logoContainer.ZIndex = 15
		logoContainer.Parent = clanCard
		rounded(logoContainer, 10)
		stroked(logoContainer, 0.4)
		
		local logo = Instance.new("ImageLabel")
		logo.Size = UDim2.new(1, -10, 1, -10)
		logo.Position = UDim2.new(0, 5, 0, 5)
		logo.BackgroundTransparency = 1
		logo.Image = clanData.clanLogo or ""
		logo.ScaleType = Enum.ScaleType.Fit
		logo.ZIndex = 16
		logo.Parent = logoContainer
		
		if clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
			logo.Visible = false
			local logoText = Instance.new("TextLabel")
			logoText.Size = UDim2.fromScale(1, 1)
			logoText.BackgroundTransparency = 1
			logoText.Text = "⚔️"
			logoText.TextSize = 40
			logoText.ZIndex = 16
			logoText.Parent = logoContainer
		end
		
		-- Nombre del clan
		local clanName = Instance.new("TextLabel")
		clanName.Size = UDim2.new(1, -30, 0, 24)
		clanName.Position = UDim2.new(0, 15, 0, 130)
		clanName.BackgroundTransparency = 1
		clanName.Text = clanData.clanName or "Clan"
		clanName.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		clanName.TextSize = 18
		clanName.Font = Enum.Font.GothamBold
		clanName.TextXAlignment = Enum.TextXAlignment.Center
		clanName.ZIndex = 14
		clanName.Parent = clanCard
		
		-- Descripción
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -30, 0, 50)
		desc.Position = UDim2.new(0, 15, 0, 160)
		desc.BackgroundTransparency = 1
		desc.Text = clanData.descripcion or "Sin descripción"
		desc.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
		desc.TextSize = 12
		desc.Font = Enum.Font.Gotham
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Center
		desc.ZIndex = 14
		desc.Parent = clanCard
		
		-- Stats
		local statsFrame = Instance.new("Frame")
		statsFrame.Size = UDim2.new(1, -30, 0, 25)
		statsFrame.Position = UDim2.new(0, 15, 0, 220)
		statsFrame.BackgroundTransparency = 1
		statsFrame.ZIndex = 14
		statsFrame.Parent = clanCard
		
		local memberCount = Instance.new("TextLabel")
		memberCount.Size = UDim2.new(0.33, 0, 1, 0)
		memberCount.BackgroundTransparency = 1
		memberCount.Text = "👥 " .. ((clanData.miembros and #clanData.miembros) or 1) .. " Miembros"
		memberCount.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		memberCount.TextSize = 11
		memberCount.Font = Enum.Font.Gotham
		memberCount.ZIndex = 14
		memberCount.Parent = statsFrame
		
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(0.33, 0, 1, 0)
		levelLabel.Position = UDim2.new(0.33, 0, 0, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "⭐ Nivel " .. (clanData.nivel or 1)
		levelLabel.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		levelLabel.TextSize = 11
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.ZIndex = 14
		levelLabel.Parent = statsFrame
		
		local ownerLabel = Instance.new("TextLabel")
		ownerLabel.Size = UDim2.new(0.33, 0, 1, 0)
		ownerLabel.Position = UDim2.new(0.66, 0, 0, 0)
		ownerLabel.BackgroundTransparency = 1
		ownerLabel.Text = "👑 Owner"
		ownerLabel.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		ownerLabel.TextSize = 11
		ownerLabel.Font = Enum.Font.Gotham
		ownerLabel.ZIndex = 14
		ownerLabel.Parent = statsFrame
		
	else
		-- Mostrar el mensaje original "No tienes clan"
		local noClanCard = Instance.new("Frame")
		noClanCard.Size = UDim2.new(0, 350, 0, 200)
		noClanCard.Position = UDim2.new(0.5, -175, 0.5, -100)
		noClanCard.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
		noClanCard.BorderSizePixel = 0
		noClanCard.ZIndex = 13
		noClanCard.Parent = noClanContainer
		rounded(noClanCard, 12)
		stroked(noClanCard, 0.4)
		
		local noClanIcon = Instance.new("TextLabel")
		noClanIcon.Size = UDim2.new(0, 70, 0, 70)
		noClanIcon.Position = UDim2.new(0.5, -35, 0, 25)
		noClanIcon.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
		noClanIcon.BorderSizePixel = 0
		noClanIcon.Text = "🛡️"
		noClanIcon.TextSize = 35
		noClanIcon.ZIndex = 14
		noClanIcon.Parent = noClanCard
		rounded(noClanIcon, 35)
		
		local noClanText = Instance.new("TextLabel")
		noClanText.Size = UDim2.new(1, -30, 0, 24)
		noClanText.Position = UDim2.new(0, 15, 0, 110)
		noClanText.BackgroundTransparency = 1
		noClanText.Text = "No perteneces a ningún clan"
		noClanText.TextColor3 = THEME.text or Color3.new(1, 1, 1)
		noClanText.TextSize = 16
		noClanText.Font = Enum.Font.GothamBold
		noClanText.ZIndex = 14
		noClanText.Parent = noClanCard
		
		local noClanHint = Instance.new("TextLabel")
		noClanHint.Size = UDim2.new(1, -30, 0, 40)
		noClanHint.Position = UDim2.new(0, 15, 0, 138)
		noClanHint.BackgroundTransparency = 1
		noClanHint.Text = "Únete a un clan existente en 'Disponibles'\no crea tu propio clan en 'Crear'"
		noClanHint.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
		noClanHint.TextSize = 12
		noClanHint.Font = Enum.Font.Gotham
		noClanHint.TextWrapped = true
		noClanHint.ZIndex = 14
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
pageCrear.ZIndex = 12
pageCrear.Parent = contentArea

local createScroll = Instance.new("ScrollingFrame")
createScroll.Size = UDim2.new(1, -20, 1, -20)
createScroll.Position = UDim2.new(0, 10, 0, 10)
createScroll.BackgroundTransparency = 1
createScroll.BorderSizePixel = 0
createScroll.ScrollBarThickness = 5
createScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
createScroll.CanvasSize = UDim2.new(0, 0, 0, 420)
createScroll.ZIndex = 13
createScroll.Parent = pageCrear

-- Card principal de creación
local createCard = Instance.new("Frame")
createCard.Size = UDim2.new(1, 0, 0, 400)
createCard.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
createCard.BorderSizePixel = 0
createCard.ZIndex = 14
createCard.Parent = createScroll
rounded(createCard, 12)
stroked(createCard, 0.4)

local createPadding = Instance.new("UIPadding")
createPadding.PaddingTop = UDim.new(0, 20)
createPadding.PaddingBottom = UDim.new(0, 20)
createPadding.PaddingLeft = UDim.new(0, 20)
createPadding.PaddingRight = UDim.new(0, 20)
createPadding.Parent = createCard

-- Título de la sección
local createTitle = Instance.new("TextLabel")
createTitle.Size = UDim2.new(1, 0, 0, 25)
createTitle.Position = UDim2.new(0, 0, 0, 0)
createTitle.BackgroundTransparency = 1
createTitle.Text = "✨ Crear Nuevo Clan"
createTitle.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
createTitle.TextSize = 16
createTitle.Font = Enum.Font.GothamBold
createTitle.TextXAlignment = Enum.TextXAlignment.Left
createTitle.ZIndex = 15
createTitle.Parent = createCard

local createSubtitle = Instance.new("TextLabel")
createSubtitle.Size = UDim2.new(1, 0, 0, 18)
createSubtitle.Position = UDim2.new(0, 0, 0, 28)
createSubtitle.BackgroundTransparency = 1
createSubtitle.Text = "Completa los campos para crear tu clan"
createSubtitle.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
createSubtitle.TextSize = 11
createSubtitle.Font = Enum.Font.Gotham
createSubtitle.TextXAlignment = Enum.TextXAlignment.Left
createSubtitle.ZIndex = 15
createSubtitle.Parent = createCard

-- Separador
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 0, 55)
separator.BackgroundColor3 = THEME.stroke or Color3.fromRGB(60, 60, 70)
separator.BorderSizePixel = 0
separator.ZIndex = 15
separator.Parent = createCard

-- Campo: Nombre
local labelNombre = Instance.new("TextLabel")
labelNombre.Size = UDim2.new(1, 0, 0, 18)
labelNombre.Position = UDim2.new(0, 0, 0, 70)
labelNombre.BackgroundTransparency = 1
labelNombre.Text = "NOMBRE DEL CLAN *"
labelNombre.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelNombre.TextSize = 11
labelNombre.Font = Enum.Font.GothamBold
labelNombre.TextXAlignment = Enum.TextXAlignment.Left
labelNombre.ZIndex = 15
labelNombre.Parent = createCard

local inputNombre = Instance.new("TextBox")
inputNombre.Size = UDim2.new(1, 0, 0, 42)
inputNombre.Position = UDim2.new(0, 0, 0, 92)
inputNombre.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
inputNombre.BorderSizePixel = 0
inputNombre.Text = ""
inputNombre.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputNombre.TextSize = 14
inputNombre.Font = Enum.Font.Gotham
inputNombre.PlaceholderText = "Ej: Guardianes del Fuego"
inputNombre.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(100, 100, 110)
inputNombre.ClearTextOnFocus = false
inputNombre.ZIndex = 15
inputNombre.Parent = createCard
rounded(inputNombre, 8)
stroked(inputNombre, 0.5)

local inputNombrePad = Instance.new("UIPadding")
inputNombrePad.PaddingLeft = UDim.new(0, 12)
inputNombrePad.PaddingRight = UDim.new(0, 12)
inputNombrePad.Parent = inputNombre

-- Campo: Descripción
local labelDesc = Instance.new("TextLabel")
labelDesc.Size = UDim2.new(1, 0, 0, 18)
labelDesc.Position = UDim2.new(0, 0, 0, 150)
labelDesc.BackgroundTransparency = 1
labelDesc.Text = "DESCRIPCIÓN"
labelDesc.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelDesc.TextSize = 11
labelDesc.Font = Enum.Font.GothamBold
labelDesc.TextXAlignment = Enum.TextXAlignment.Left
labelDesc.ZIndex = 15
labelDesc.Parent = createCard

local inputDesc = Instance.new("TextBox")
inputDesc.Size = UDim2.new(1, 0, 0, 70)
inputDesc.Position = UDim2.new(0, 0, 0, 172)
inputDesc.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
inputDesc.BorderSizePixel = 0
inputDesc.Text = ""
inputDesc.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputDesc.TextSize = 12
inputDesc.Font = Enum.Font.Gotham
inputDesc.PlaceholderText = "Describe tu clan y su propósito..."
inputDesc.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(100, 100, 110)
inputDesc.TextWrapped = true
inputDesc.TextYAlignment = Enum.TextYAlignment.Top
inputDesc.MultiLine = true
inputDesc.ClearTextOnFocus = false
inputDesc.ZIndex = 15
inputDesc.Parent = createCard
rounded(inputDesc, 8)
stroked(inputDesc, 0.5)

local inputDescPad = Instance.new("UIPadding")
inputDescPad.PaddingTop = UDim.new(0, 10)
inputDescPad.PaddingLeft = UDim.new(0, 12)
inputDescPad.PaddingRight = UDim.new(0, 12)
inputDescPad.Parent = inputDesc

-- Campo: Logo
local labelLogo = Instance.new("TextLabel")
labelLogo.Size = UDim2.new(1, 0, 0, 18)
labelLogo.Position = UDim2.new(0, 0, 0, 258)
labelLogo.BackgroundTransparency = 1
labelLogo.Text = "LOGO (Asset ID - Opcional)"
labelLogo.TextColor3 = THEME.text or Color3.new(1, 1, 1)
labelLogo.TextSize = 11
labelLogo.Font = Enum.Font.GothamBold
labelLogo.TextXAlignment = Enum.TextXAlignment.Left
labelLogo.ZIndex = 15
labelLogo.Parent = createCard

local inputLogo = Instance.new("TextBox")
inputLogo.Size = UDim2.new(1, 0, 0, 42)
inputLogo.Position = UDim2.new(0, 0, 0, 280)
inputLogo.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
inputLogo.BorderSizePixel = 0
inputLogo.Text = ""
inputLogo.TextColor3 = THEME.text or Color3.new(1, 1, 1)
inputLogo.TextSize = 14
inputLogo.Font = Enum.Font.Gotham
inputLogo.PlaceholderText = "rbxassetid://123456789"
inputLogo.PlaceholderColor3 = THEME.subtle or Color3.fromRGB(100, 100, 110)
inputLogo.ClearTextOnFocus = false
inputLogo.ZIndex = 15
inputLogo.Parent = createCard
rounded(inputLogo, 8)
stroked(inputLogo, 0.5)

local inputLogoPad = Instance.new("UIPadding")
inputLogoPad.PaddingLeft = UDim.new(0, 12)
inputLogoPad.PaddingRight = UDim.new(0, 12)
inputLogoPad.Parent = inputLogo

-- Botón crear
local btnCrear = Instance.new("TextButton")
btnCrear.Size = UDim2.new(1, 0, 0, 48)
btnCrear.Position = UDim2.new(0, 0, 0, 340)
btnCrear.BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
btnCrear.BorderSizePixel = 0
btnCrear.Text = "⚔️  CREAR CLAN"
btnCrear.TextColor3 = Color3.new(1, 1, 1)
btnCrear.TextSize = 15
btnCrear.Font = Enum.Font.GothamBold
btnCrear.AutoButtonColor = false
btnCrear.ZIndex = 15
btnCrear.Parent = createCard
rounded(btnCrear, 10)

-- Hover effect
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
-- PAGE: ADMIN (Solo visible para admins)
-- ════════════════════════════════════════════════════════════════
local pageAdmin = nil
local adminClansScroll = nil

if isAdmin then
	pageAdmin = Instance.new("Frame")
	pageAdmin.Name = "Admin"
	pageAdmin.Size = UDim2.fromScale(1, 1)
	pageAdmin.BackgroundTransparency = 1
	pageAdmin.Visible = false
	pageAdmin.ZIndex = 12
	pageAdmin.Parent = contentArea
	
	-- Header de admin
	local adminHeader = Instance.new("Frame")
	adminHeader.Size = UDim2.new(1, -20, 0, 50)
	adminHeader.Position = UDim2.new(0, 10, 0, 10)
	adminHeader.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	adminHeader.BorderSizePixel = 0
	adminHeader.ZIndex = 13
	adminHeader.Parent = pageAdmin
	rounded(adminHeader, 8)
	stroked(adminHeader, 0.4, Color3.fromRGB(200, 80, 80))
	
	local adminWarning = Instance.new("TextLabel")
	adminWarning.Size = UDim2.new(1, -20, 1, 0)
	adminWarning.Position = UDim2.new(0, 10, 0, 0)
	adminWarning.BackgroundTransparency = 1
	adminWarning.Text = "⚠️ Panel de Administrador - Las acciones aquí son irreversibles"
	adminWarning.TextColor3 = Color3.fromRGB(255, 180, 180)
	adminWarning.TextSize = 12
	adminWarning.Font = Enum.Font.GothamBold
	adminWarning.TextXAlignment = Enum.TextXAlignment.Left
	adminWarning.ZIndex = 14
	adminWarning.Parent = adminHeader
	
	-- ScrollingFrame para clanes
	adminClansScroll = Instance.new("ScrollingFrame")
	adminClansScroll.Name = "AdminClansScroll"
	adminClansScroll.Size = UDim2.new(1, -20, 1, -75)
	adminClansScroll.Position = UDim2.new(0, 10, 0, 70)
	adminClansScroll.BackgroundTransparency = 1
	adminClansScroll.BorderSizePixel = 0
	adminClansScroll.ScrollBarThickness = 5
	adminClansScroll.ScrollBarImageColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
	adminClansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	adminClansScroll.ZIndex = 13
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

-- Función para cargar clanes en el panel admin
local function loadAdminClans()
	if not isAdmin or not adminClansScroll then return end
	
	-- Limpiar lista
	for _, child in ipairs(adminClansScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	local clans = ClanClient:GetClansList()
	
	if not clans or #clans == 0 then
		local noClansLabel = Instance.new("TextLabel")
		noClansLabel.Size = UDim2.new(1, 0, 0, 60)
		noClansLabel.BackgroundTransparency = 1
		noClansLabel.Text = "📭 No hay clanes registrados"
		noClansLabel.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
		noClansLabel.TextSize = 14
		noClansLabel.Font = Enum.Font.Gotham
		noClansLabel.ZIndex = 14
		noClansLabel.Parent = adminClansScroll
		return
	end
	
	for _, clanData in ipairs(clans) do
		local entry = Instance.new("Frame")
		entry.Name = "AdminClanEntry_" .. (clanData.clanId or "unknown")
		entry.Size = UDim2.new(1, 0, 0, 80)
		entry.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
		entry.BorderSizePixel = 0
		entry.ZIndex = 14
		entry.Parent = adminClansScroll
		rounded(entry, 10)
		stroked(entry, 0.4)
		
		-- Logo pequeño
		local miniLogo = Instance.new("Frame")
		miniLogo.Size = UDim2.new(0, 55, 0, 55)
		miniLogo.Position = UDim2.new(0, 12, 0.5, -27)
		miniLogo.BackgroundColor3 = THEME.surface or Color3.fromRGB(50, 50, 60)
		miniLogo.BorderSizePixel = 0
		miniLogo.ZIndex = 15
		miniLogo.Parent = entry
		rounded(miniLogo, 8)
		
		local logoText = Instance.new("TextLabel")
		logoText.Size = UDim2.fromScale(1, 1)
		logoText.BackgroundTransparency = 1
		logoText.Text = "⚔️"
		logoText.TextSize = 24
		logoText.ZIndex = 16
		logoText.Parent = miniLogo
		
		-- Nombre clan
		local clanNameLabel = Instance.new("TextLabel")
		clanNameLabel.Size = UDim2.new(1, -200, 0, 22)
		clanNameLabel.Position = UDim2.new(0, 80, 0, 12)
		clanNameLabel.BackgroundTransparency = 1
		clanNameLabel.Text = clanData.clanName or "Sin nombre"
		clanNameLabel.TextColor3 = THEME.accent or Color3.fromRGB(138, 99, 210)
		clanNameLabel.TextSize = 15
		clanNameLabel.Font = Enum.Font.GothamBold
		clanNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		clanNameLabel.ZIndex = 15
		clanNameLabel.Parent = entry
		
		-- Info
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -200, 0, 18)
		infoLabel.Position = UDim2.new(0, 80, 0, 38)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "🆔 " .. (clanData.clanId or "?") .. "  |  👥 " .. (clanData.miembros_count or 0) .. " miembros  |  ⭐ Nivel " .. (clanData.nivel or 1)
		infoLabel.TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
		infoLabel.TextSize = 11
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.ZIndex = 15
		infoLabel.Parent = entry
		
		-- Botón eliminar
		local deleteBtn = Instance.new("TextButton")
		deleteBtn.Size = UDim2.new(0, 90, 0, 45)
		deleteBtn.Position = UDim2.new(1, -102, 0.5, -22)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		deleteBtn.BorderSizePixel = 0
		deleteBtn.Text = "🗑️ Eliminar"
		deleteBtn.TextColor3 = Color3.new(1, 1, 1)
		deleteBtn.TextSize = 12
		deleteBtn.Font = Enum.Font.GothamBold
		deleteBtn.ZIndex = 15
		deleteBtn.AutoButtonColor = false
		deleteBtn.Parent = entry
		rounded(deleteBtn, 8)
		
		-- Hover effect
		deleteBtn.MouseEnter:Connect(function()
			TweenService:Create(deleteBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(220, 70, 70)
			}):Play()
		end)
		
		deleteBtn.MouseLeave:Connect(function()
			TweenService:Create(deleteBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			}):Play()
		end)
		
		deleteBtn.MouseButton1Click:Connect(function()
			-- Crear overlay de confirmación (TextButton transparente para detectar clicks)
			local confirmOverlay = Instance.new("TextButton")
			confirmOverlay.Name = "ConfirmOverlay"
			confirmOverlay.Size = UDim2.fromScale(1, 1)
			confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
			confirmOverlay.BackgroundTransparency = 0.5
			confirmOverlay.BorderSizePixel = 0
			confirmOverlay.Text = ""
			confirmOverlay.AutoButtonColor = false
			confirmOverlay.ZIndex = 250
			confirmOverlay.Parent = screenGui
			
			local modal = Instance.new("Frame")
			modal.Name = "ConfirmModal"
			modal.Size = UDim2.new(0, 340, 0, 190)
			modal.Position = UDim2.new(0.5, -170, 0.5, -95)
			modal.BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
			modal.BorderSizePixel = 0
			modal.ZIndex = 251
			modal.Parent = confirmOverlay
			rounded(modal, 12)
			stroked(modal, 0.3)
			addShadow(modal)
			
			local warningIcon = Instance.new("TextLabel")
			warningIcon.Size = UDim2.new(1, 0, 0, 45)
			warningIcon.Position = UDim2.new(0, 0, 0, 15)
			warningIcon.BackgroundTransparency = 1
			warningIcon.Text = "⚠️"
			warningIcon.TextSize = 35
			warningIcon.ZIndex = 252
			warningIcon.Parent = modal
			
			local confirmText = Instance.new("TextLabel")
			confirmText.Size = UDim2.new(1, -30, 0, 55)
			confirmText.Position = UDim2.new(0, 15, 0, 60)
			confirmText.BackgroundTransparency = 1
			confirmText.Text = "¿Estás seguro de eliminar el clan\n\"" .. (clanData.clanName or "Sin nombre") .. "\"?\n\nEsta acción NO se puede deshacer."
			confirmText.TextColor3 = THEME.text or Color3.new(1, 1, 1)
			confirmText.TextSize = 13
			confirmText.Font = Enum.Font.Gotham
			confirmText.TextWrapped = true
			confirmText.ZIndex = 252
			confirmText.Parent = modal
			
			local btnConfirm = Instance.new("TextButton")
			btnConfirm.Size = UDim2.new(0, 120, 0, 40)
			btnConfirm.Position = UDim2.new(0, 25, 1, -55)
			btnConfirm.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
			btnConfirm.BorderSizePixel = 0
			btnConfirm.Text = "Sí, Eliminar"
			btnConfirm.TextColor3 = Color3.new(1, 1, 1)
			btnConfirm.TextSize = 13
			btnConfirm.Font = Enum.Font.GothamBold
			btnConfirm.ZIndex = 252
			btnConfirm.Parent = modal
			rounded(btnConfirm, 8)
			
			local btnCancel = Instance.new("TextButton")
			btnCancel.Size = UDim2.new(0, 120, 0, 40)
			btnCancel.Position = UDim2.new(1, -145, 1, -55)
			btnCancel.BackgroundColor3 = THEME.btnSecondary or Color3.fromRGB(60, 60, 70)
			btnCancel.BorderSizePixel = 0
			btnCancel.Text = "Cancelar"
			btnCancel.TextColor3 = THEME.text or Color3.new(1, 1, 1)
			btnCancel.TextSize = 13
			btnCancel.Font = Enum.Font.GothamBold
			btnCancel.ZIndex = 252
			btnCancel.Parent = modal
			rounded(btnCancel, 8)
			
			btnConfirm.MouseButton1Click:Connect(function()
				btnConfirm.Text = "⏳ Eliminando..."
				local success = ClanClient:AdminDissolveClan(clanData.clanId)
				confirmOverlay:Destroy()
				
				if success then
					Notify:Success("Clan Eliminado", "El clan '" .. clanData.clanName .. "' ha sido eliminado", 4)
				else
					Notify:Error("Error", "No se pudo eliminar el clan", 4)
				end
				
				-- Recargar lista
				task.wait(0.3)
				loadAdminClans()
			end)
			
			btnCancel.MouseButton1Click:Connect(function()
				confirmOverlay:Destroy()
			end)
			
			-- Click en overlay para cerrar (solo fuera del modal)
			confirmOverlay.MouseButton1Click:Connect(function()
				confirmOverlay:Destroy()
			end)
			
			-- Evitar que clicks dentro del modal cierren el overlay
			modal.MouseButton1Click:Connect(function()
				-- No hacer nada, solo prevenir la propagación
			end)
		end)
		
		-- Hover en entry
		entry.MouseEnter:Connect(function()
			TweenService:Create(entry, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			}):Play()
		end)
		
		entry.MouseLeave:Connect(function()
			TweenService:Create(entry, TweenInfo.new(0.15), {
				BackgroundColor3 = THEME.card or Color3.fromRGB(40, 40, 50)
			}):Play()
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
				BackgroundColor3 = THEME.accent or Color3.fromRGB(138, 99, 210),
				TextColor3 = Color3.new(1, 1, 1)
			}):Play()
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {
				BackgroundColor3 = THEME.btnSecondary or Color3.fromRGB(45, 45, 55),
				TextColor3 = THEME.muted or Color3.fromRGB(140, 140, 150)
			}):Play()
		end
	end

	for name, page in pairs(tabPages) do
		if name == tabName then
			page.Visible = true
			-- Animación de entrada
			page.Position = UDim2.new(0.02, 0, 0, 0)
			TweenService:Create(page, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
			
			-- Cargar contenido según la tab
			if tabName == "TuClan" then
				task.spawn(loadPlayerClan)
			elseif tabName == "Admin" and isAdmin then
				task.spawn(loadAdminClans)
			end
		else
			page.Visible = false
		end
	end
end

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- OPEN/CLOSE FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if uiOpen then return end
	uiOpen = true

	overlay.Visible = true
	panel.Visible = true

	if blur then
		blur.Enabled = true
		TweenService:Create(blur, TweenInfo.new(0.3), {Size = BLUR_SIZE}):Play()
	end

	TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
	
	-- Animación de entrada suave
	panel.Position = UDim2.new(0.5, 0, 0.6, 0)
	panel.Size = UDim2.new(0, 700, 0, 500)
	
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 750, 0, 550)
	}):Play()

	-- Cargar clanes
	task.spawn(loadClansFromServer)
	switchTab("Disponibles")
end

local function closeUI()
	if not uiOpen then return end
	uiOpen = false

	if blur then
		TweenService:Create(blur, TweenInfo.new(0.25), {Size = 0}):Play()
		task.delay(0.25, function()
			blur.Enabled = false
		end)
	end

	TweenService:Create(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.6, 0),
		Size = UDim2.new(0, 700, 0, 500)
	}):Play()

	task.delay(0.25, function()
		overlay.Visible = false
		panel.Visible = false
	end)
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
	local clanDesc = inputDesc.Text ~= "" and inputDesc.Text or "Sin descripción"
	local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or ""

	-- Validación
	if clanName == "" or #clanName < 3 then
		-- Efecto de error
		Notify:Warning("Nombre inválido", "El nombre del clan debe tener al menos 3 caracteres", 3)
		local originalColor = inputNombre.BackgroundColor3
		TweenService:Create(inputNombre, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		}):Play()
		task.wait(0.2)
		TweenService:Create(inputNombre, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor
		}):Play()
		return
	end

	-- Efecto de loading
	btnCrear.Text = "⏳ Creando..."
	btnCrear.AutoButtonColor = false

	print("Creando clan:", clanName)
	local success, clanId, msg = ClanClient:CreateClan(clanName, clanLogo, clanDesc)

	if success then
		Notify:Success("¡Clan Creado!", msg or ("Tu clan '" .. clanName .. "' ha sido creado exitosamente"), 5)
	else
		Notify:Error("Error", msg or "No se pudo crear el clan. Inténtalo de nuevo.", 5)
	end

	-- Reset
	btnCrear.Text = "⚔️  CREAR CLAN"
	btnCrear.AutoButtonColor = false
	inputNombre.Text = ""
	inputDesc.Text = ""
	inputLogo.Text = ""

	task.wait(0.5)
	loadClansFromServer()
	switchTab("Disponibles")
end)

-- Conectar Icon si existe
if clanIcon then
	clanIcon:bindEvent("selected", function()
		openUI()
	end)

	clanIcon:bindEvent("deselected", function()
		closeUI()
	end)
end

-- Test: Abrir automáticamente para debug (comentar en producción)
-- task.wait(2)
-- openUI()

print("✓ Clan System UI FIXED - Versión mejorada cargada")