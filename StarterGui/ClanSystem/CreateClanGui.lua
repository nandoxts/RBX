--[[
	Clan System UI - COMPLETO Y OPTIMIZADO
	- Gestión de solicitudes de unión
	- Cambio de roles (owner/colider/lider)
	- Emoji y color del clan
	- Código centralizado y limpio
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

local ADMIN_IDS = { 8387751399, 9375636407 }
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
local loadingConnection = nil

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
	if loadingConnection then
		pcall(function() loadingConnection:Disconnect() end)
		loadingConnection = nil
	end
end

function Memory.destroyChildren(parent, exceptClass)
	if not parent then return end
	for _, child in ipairs(parent:GetChildren()) do
		if not exceptClass or not child:IsA(exceptClass) then
			child:Destroy()
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- UI HELPERS CENTRALIZADOS
-- ════════════════════════════════════════════════════════════════
local UI = {}

function UI.rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

function UI.stroked(inst, alpha, color)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.stroke
	s.Thickness = 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

function UI.brighten(color, factor)
	return Color3.fromRGB(
		math.min(255, color.R * 255 * factor),
		math.min(255, color.G * 255 * factor),
		math.min(255, color.B * 255 * factor)
	)
end

function UI.hover(btn, normalColor, hoverColor)
	Memory.track(btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end))
	Memory.track(btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
	end))
end

function UI.frame(props)
	local f = Instance.new("Frame")
	f.Name = props.name or "Frame"
	f.Size = props.size or UDim2.new(1, 0, 1, 0)
	f.Position = props.pos or UDim2.new(0, 0, 0, 0)
	f.BackgroundColor3 = props.bg or THEME.card
	f.BackgroundTransparency = props.bgT or 0
	f.BorderSizePixel = 0
	f.ZIndex = props.z or 100
	f.ClipsDescendants = props.clips or false
	if props.parent then f.Parent = props.parent end
	if props.corner then UI.rounded(f, props.corner) end
	if props.stroke then UI.stroked(f, props.strokeA, props.strokeC) end
	return f
end

function UI.label(props)
	local l = Instance.new("TextLabel")
	l.Name = props.name or "Label"
	l.Size = props.size or UDim2.new(1, 0, 0, 20)
	l.Position = props.pos or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = props.text or ""
	l.TextColor3 = props.color or THEME.text
	l.TextSize = props.textSize or 12
	l.Font = props.font or Enum.Font.Gotham
	l.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
	l.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
	l.TextWrapped = props.wrap or false
	l.TextTruncate = props.truncate or Enum.TextTruncate.None
	l.ZIndex = props.z or 100
	if props.parent then l.Parent = props.parent end
	return l
end

function UI.button(props)
	local b = Instance.new("TextButton")
	b.Name = props.name or "Button"
	b.Size = props.size or UDim2.new(0, 100, 0, 36)
	b.Position = props.pos or UDim2.new(0, 0, 0, 0)
	b.BackgroundColor3 = props.bg or THEME.accent
	b.Text = props.text or "Button"
	b.TextColor3 = props.color or Color3.new(1, 1, 1)
	b.TextSize = props.textSize or 12
	b.Font = props.font or Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.ZIndex = props.z or 100
	if props.parent then b.Parent = props.parent end
	if props.corner then UI.rounded(b, props.corner) end
	if props.hover then UI.hover(b, props.bg or THEME.accent, props.hoverBg or UI.brighten(props.bg or THEME.accent, 1.15)) end
	return b
end

function UI.input(labelText, placeholder, yPos, parent, multiLine)
	UI.label({
		size = UDim2.new(1, 0, 0, 14),
		pos = UDim2.new(0, 0, 0, yPos),
		text = labelText,
		textSize = 10,
		font = Enum.Font.GothamBold,
		z = 105,
		parent = parent
	})

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
	UI.rounded(input, 8)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	if multiLine then pad.PaddingTop = UDim.new(0, 8) end
	pad.Parent = input

	return input
end

function UI.loading(parent)
	local container = UI.frame({size = UDim2.new(1, 0, 0, 80), bgT = 1, z = 104, parent = parent})
	local dots = {}
	for i = 1, 3 do
		dots[i] = UI.frame({
			size = UDim2.new(0, 6, 0, 6),
			pos = UDim2.new(0.5, -15 + (i-1) * 12, 0.5, -3),
			bg = THEME.accent, z = 105, parent = container, corner = 3
		})
	end

	local animIndex = 1
	if loadingConnection then pcall(function() loadingConnection:Disconnect() end) end
	loadingConnection = RunService.Heartbeat:Connect(function()
		if not container or not container.Parent then
			if loadingConnection then loadingConnection:Disconnect() end
			return
		end
		for i, dot in ipairs(dots) do
			if dot and dot.Parent then
				TweenService:Create(dot, TweenInfo.new(0.2), {
					BackgroundTransparency = (i == animIndex) and 0 or 0.6
				}):Play()
			end
		end
		animIndex = (animIndex % 3) + 1
	end)

	UI.label({
		size = UDim2.new(1, 0, 0, 18),
		pos = UDim2.new(0, 0, 0.5, 12),
		text = "Cargando...",
		color = THEME.muted, textSize = 11,
		alignX = Enum.TextXAlignment.Center, z = 105, parent = container
	})

	return container
end

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
	clanIcon = Icon.new():setLabel("⚔️"):setOrder(2):setEnabled(true)
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
	ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 24))
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
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 0, 24)
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

local underline = UI.frame({
	size = UDim2.new(0, 90, 0, 3), pos = UDim2.new(0, 20, 0, 93),
	bg = THEME.accent, z = 102, parent = panel, corner = 2
})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name = "ContentArea", size = UDim2.new(1, -40, 1, -125), pos = UDim2.new(0, 20, 0, 106),
	bg = THEME.elevated, z = 101, parent = panel, corner = 10, stroke = true, strokeA = 0.6, clips = true
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
	name = "Container", size = UDim2.new(1, -30, 1, -30), pos = UDim2.new(0, 15, 0, 15),
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
	local emojiBtn = UI.button({
		size = UDim2.new(0, 28, 0, 28),
		bg = i == 1 and THEME.accent or THEME.card,
		text = emoji, textSize = 16, z = 106, parent = emojiFrame, corner = 6
	})
	emojiButtons[i] = emojiBtn
	Memory.track(emojiBtn.MouseButton1Click:Connect(function()
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
		bg = Color3.fromRGB(50, 35, 35), z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = Color3.fromRGB(180, 70, 70)
	})

	UI.label({
		size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0),
		text = "⚠ Panel de Administrador - Acciones irreversibles",
		color = Color3.fromRGB(255, 160, 160), textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader
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
-- FUNCIONES DE CARGA
-- ════════════════════════════════════════════════════════════════

-- Función para crear tarjeta de miembro con gestión de roles
local function createMemberCard(memberData, odI, clanData, playerRole, membersScroll)
	local userId = tonumber(odI) or 0
	if userId <= 0 then return nil end

	local memberFrame = UI.frame({
		size = UDim2.new(0, 100, 0, 110),
		bg = THEME.surface, z = 106, parent = membersScroll, corner = 8
	})

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 55, 0, 55)
	avatar.Position = UDim2.new(0.5, -27, 0, 8)
	avatar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
	avatar.ZIndex = 107
	avatar.ImageTransparency = 0.1
	avatar.Parent = memberFrame
	UI.rounded(avatar, 8)

	-- Nombre más grande
	UI.label({
		size = UDim2.new(1, -6, 0, 16),
		pos = UDim2.new(0, 3, 0, 66),
		text = (memberData.nombre or "Usuario"):sub(1, 12),
		textSize = 11, font = Enum.Font.GothamMedium,
		alignX = Enum.TextXAlignment.Center,
		truncate = Enum.TextTruncate.AtEnd, z = 107, parent = memberFrame
	})

	-- Rol con color
	local rolColor = THEME.accent
	if memberData.rol == "owner" then rolColor = Color3.fromRGB(255, 215, 0)
	elseif memberData.rol == "colider" then rolColor = Color3.fromRGB(180, 100, 255)
	elseif memberData.rol == "lider" then rolColor = Color3.fromRGB(100, 200, 255)
	end

	UI.label({
		size = UDim2.new(1, -6, 0, 14),
		pos = UDim2.new(0, 3, 0, 84),
		text = (memberData.rol and (memberData.rol:sub(1,1):upper() .. memberData.rol:sub(2))) or "Miembro",
		color = rolColor, textSize = 10, font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Center, z = 107, parent = memberFrame
	})

	-- Botón para cambiar rol
	local canManageRoles = (playerRole == "owner") or (playerRole == "colider" and memberData.rol ~= "owner" and memberData.rol ~= "colider")

	if canManageRoles and memberData.rol ~= "owner" and userId ~= player.UserId then
		local manageBtn = UI.button({
			size = UDim2.new(1, -10, 0, 18),
			pos = UDim2.new(0, 5, 1, -22),
			bg = THEME.card, text = "⚙", textSize = 10, z = 108, parent = memberFrame, corner = 4
		})

		Memory.track(manageBtn.MouseButton1Click:Connect(function()
			local currentRole = memberData.rol or "miembro"
			local nextRole = "miembro"
			local actionText = ""

			if currentRole == "miembro" then
				nextRole = "lider"
				actionText = "Promover a Líder"
			elseif currentRole == "lider" then
				if playerRole == "owner" then
					nextRole = "colider"
					actionText = "Promover a Co-Líder"
				else
					nextRole = "miembro"
					actionText = "Degradar a Miembro"
				end
			elseif currentRole == "colider" and playerRole == "owner" then
				nextRole = "miembro"
				actionText = "Degradar a Miembro"
			end

			ConfirmationModal.new({
				screenGui = screenGui,
				title = "Gestionar: " .. (memberData.nombre or "Usuario"),
				message = "¿" .. actionText .. "?\n\nRol actual: " .. currentRole:sub(1,1):upper() .. currentRole:sub(2),
				confirmText = actionText,
				cancelText = "Cancelar",
				onConfirm = function()
					local success, msg = ClanClient:ChangePlayerRole(userId, nextRole)
					if success then
						Notify:Success("Rol Actualizado", "Ahora es " .. nextRole, 4)
						-- El listener actualizará la UI
					else
						Notify:Error("Error", msg or "No se pudo cambiar el rol", 4)
					end
				end
			})
		end))
	end

	return memberFrame
end

-- Función para crear sección de solicitudes pendientes
local function createJoinRequestsSection(clanData, playerRole, parentScroll, yOffset)
	local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
	if not canManageRequests then return yOffset end

	local requests = ClanClient:GetJoinRequests(clanData.clanId)
	if not requests or #requests == 0 then return yOffset end

	local requestsCard = UI.frame({
		size = UDim2.new(1, 0, 0, 50 + #requests * 55),
		pos = UDim2.new(0, 0, 0, yOffset),
		bg = THEME.card, z = 105, parent = parentScroll, corner = 12, stroke = true, strokeA = 0.6
	})

	UI.label({
		size = UDim2.new(1, -20, 0, 20),
		pos = UDim2.new(0, 10, 0, 10),
		text = "📩 Solicitudes Pendientes (" .. #requests .. ")",
		color = Color3.fromRGB(255, 200, 100), textSize = 13, font = Enum.Font.GothamBold, z = 106, parent = requestsCard
	})

	for i, request in ipairs(requests) do
		local reqFrame = UI.frame({
			size = UDim2.new(1, -20, 0, 45),
			pos = UDim2.new(0, 10, 0, 35 + (i-1) * 50),
			bg = THEME.surface, z = 106, parent = requestsCard, corner = 8
		})

		local avatar = Instance.new("ImageLabel")
		avatar.Size = UDim2.new(0, 35, 0, 35)
		avatar.Position = UDim2.new(0, 5, 0.5, -17)
		avatar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. request.playerId .. "&width=420&height=420&format=png"
		avatar.ZIndex = 107
		avatar.Parent = reqFrame
		UI.rounded(avatar, 6)

		UI.label({
			size = UDim2.new(0, 150, 0, 18),
			pos = UDim2.new(0, 48, 0, 6),
			text = request.playerName or "Usuario",
			textSize = 12, font = Enum.Font.GothamMedium, z = 107, parent = reqFrame
		})

		local timeAgo = os.time() - (request.requestTime or os.time())
		local timeText = timeAgo < 60 and "Hace un momento" or (timeAgo < 3600 and math.floor(timeAgo/60) .. " min" or math.floor(timeAgo/3600) .. " hrs")
		UI.label({
			size = UDim2.new(0, 100, 0, 14),
			pos = UDim2.new(0, 48, 0, 26),
			text = timeText, color = THEME.muted, textSize = 10, z = 107, parent = reqFrame
		})

		local acceptBtn = UI.button({
			size = UDim2.new(0, 60, 0, 28),
			pos = UDim2.new(1, -135, 0.5, -14),
			bg = Color3.fromRGB(60, 150, 60), text = "✓ Aceptar", textSize = 10, z = 107, parent = reqFrame, corner = 6, hover = true, hoverBg = Color3.fromRGB(80, 180, 80)
		})

		Memory.track(acceptBtn.MouseButton1Click:Connect(function()
			acceptBtn.Text = "..."
			acceptBtn.Active = false

			local success, msg = ClanClient:ApproveJoinRequest(clanData.clanId, request.playerId)
			if success then
				Notify:Success("Aceptado", (request.playerName or "Usuario") .. " se unió al clan", 4)
				-- Solo animar - el listener del servidor actualizará la UI
				TweenService:Create(reqFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				task.delay(0.35, function()
					if reqFrame and reqFrame.Parent then reqFrame:Destroy() end
				end)
				-- NO llamar loadPlayerClan aquí - el servidor lo hará via onClansUpdated
			else
				Notify:Error("Error", msg or "No se pudo aceptar", 4)
				acceptBtn.Text = "✓ Aceptar"
				acceptBtn.Active = true
			end
		end))

		local rejectBtn = UI.button({
			size = UDim2.new(0, 60, 0, 28),
			pos = UDim2.new(1, -70, 0.5, -14),
			bg = Color3.fromRGB(150, 60, 60), text = "✗ Rechazar", textSize = 10, z = 107, parent = reqFrame, corner = 6, hover = true, hoverBg = Color3.fromRGB(180, 80, 80)
		})

		Memory.track(rejectBtn.MouseButton1Click:Connect(function()
			rejectBtn.Text = "..."
			rejectBtn.Active = false

			local success, msg = ClanClient:RejectJoinRequest(clanData.clanId, request.playerId)
			if success then
				Notify:Success("Rechazado", "Solicitud rechazada", 4)
				-- Solo animar - el listener actualizará
				TweenService:Create(reqFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				task.delay(0.35, function()
					if reqFrame and reqFrame.Parent then reqFrame:Destroy() end
				end)
			else
				Notify:Error("Error", msg or "No se pudo rechazar", 4)
				rejectBtn.Text = "✗ Rechazar"
				rejectBtn.Active = true
			end
		end))
	end

	return yOffset + 60 + #requests * 55
end

-- Función: Cargar clan del jugador
loadPlayerClan = function()
	Memory.cleanup()

	-- Solo destruir si no hay loading ya visible
	local hasLoading = tuClanContainer:FindFirstChild("Frame") and tuClanContainer:FindFirstChild("Frame"):FindFirstChild("Label")
	if not hasLoading then
		Memory.destroyChildren(tuClanContainer)
	end

	-- Obtener datos en background
	task.spawn(function()
		local clanData = ClanClient:GetPlayerClan()

		-- Ahora sí limpiar completamente
		Memory.destroyChildren(tuClanContainer)

		if clanData then
			local clanScroll = Instance.new("ScrollingFrame")
			clanScroll.Size = UDim2.new(1, 0, 1, 0)
			clanScroll.BackgroundTransparency = 1
			clanScroll.ScrollBarThickness = 4
			clanScroll.ScrollBarImageColor3 = THEME.accent
			clanScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
			clanScroll.ZIndex = 103
			clanScroll.Parent = tuClanContainer

			local clanCard = UI.frame({
				size = UDim2.new(1, 0, 0, 300),
				bg = THEME.card, z = 104, parent = clanScroll, corner = 12, stroke = true, strokeA = 0.6
			})

			local logoContainer = UI.frame({size = UDim2.new(1, 0, 1, 0), bgT = 1, z = 103, parent = clanCard, corner = 12})

			local logo = Instance.new("ImageLabel")
			logo.Size = UDim2.new(1, 0, 1, 0)
			logo.BackgroundTransparency = 1
			logo.Image = clanData.clanLogo or ""
			logo.ScaleType = Enum.ScaleType.Crop
			logo.ImageTransparency = 0.3
			logo.ZIndex = 103
			logo.Parent = logoContainer
			UI.rounded(logo, 12)

			local fadeGradient = Instance.new("UIGradient")
			fadeGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.new(0.2, 0.2, 0.2)),
				ColorSequenceKeypoint.new(1, Color3.new(0.15, 0.15, 0.17))
			}
			fadeGradient.Rotation = 45
			fadeGradient.Parent = logo

			UI.frame({size = UDim2.new(1, 0, 1, 0), bg = Color3.fromRGB(30, 30, 35), bgT = 0.6, z = 103, parent = logoContainer, corner = 12})

			local logoFront = UI.frame({size = UDim2.new(0, 70, 0, 70), pos = UDim2.new(0.5, -35, 0, 18), bgT = 1, z = 105, parent = clanCard, corner = 12})

			local logoImage = Instance.new("ImageLabel")
			logoImage.Size = UDim2.new(1, 0, 1, 0)
			logoImage.BackgroundTransparency = 1
			logoImage.Image = clanData.clanLogo or ""
			logoImage.ScaleType = Enum.ScaleType.Fit
			logoImage.ZIndex = 106
			logoImage.Parent = logoFront
			UI.rounded(logoImage, 10)

			if not clanData.clanLogo or clanData.clanLogo == "" or clanData.clanLogo == "rbxassetid://0" then
				logoImage.Visible = false
				UI.label({
					size = UDim2.new(1, 0, 1, 0), text = clanData.clanEmoji or "⚔️",
					textSize = 40, alignX = Enum.TextXAlignment.Center, z = 106, parent = logoFront
				})
			end

			local clanColor = clanData.clanColor and Color3.fromRGB(clanData.clanColor[1] or 255, clanData.clanColor[2] or 255, clanData.clanColor[3] or 255) or THEME.accent

			UI.label({
				size = UDim2.new(1, -20, 0, 24),
				pos = UDim2.new(0, 10, 0, 96),
				text = (clanData.clanEmoji or "") .. " " .. (clanData.clanName or "Clan"),
				color = clanColor, textSize = 18, font = Enum.Font.GothamBold,
				alignX = Enum.TextXAlignment.Center, z = 104, parent = clanCard
			})

			UI.label({
				size = UDim2.new(1, -20, 0, 16),
				pos = UDim2.new(0, 10, 0, 122),
				text = "[" .. (clanData.clanTag or "TAG") .. "]",
				color = THEME.accent, textSize = 14, font = Enum.Font.GothamBold,
				alignX = Enum.TextXAlignment.Center, z = 104, parent = clanCard
			})

			UI.label({
				size = UDim2.new(1, -20, 0, 36),
				pos = UDim2.new(0, 10, 0, 144),
				text = clanData.descripcion or "Sin descripción",
				color = THEME.muted, textSize = 12, wrap = true,
				alignX = Enum.TextXAlignment.Center, z = 104, parent = clanCard
			})

			local statsFrame = UI.frame({size = UDim2.new(1, -20, 0, 22), pos = UDim2.new(0, 10, 0, 186), bgT = 1, z = 104, parent = clanCard})

			local playerRole = "miembro"
			if clanData.miembros_data and clanData.miembros_data[tostring(player.UserId)] then
				playerRole = clanData.miembros_data[tostring(player.UserId)].rol or "miembro"
			end

			UI.label({size = UDim2.new(0.33, 0, 1, 0), text = ((clanData.miembros and #clanData.miembros) or 1) .. " Miembros", textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = statsFrame})
			UI.label({size = UDim2.new(0.33, 0, 1, 0), pos = UDim2.new(0.33, 0, 0, 0), text = "Nivel " .. (clanData.nivel or 1), textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = statsFrame})

			local roleColor = THEME.accent
			if playerRole == "owner" then roleColor = Color3.fromRGB(255, 215, 0)
			elseif playerRole == "colider" then roleColor = Color3.fromRGB(180, 100, 255)
			elseif playerRole == "lider" then roleColor = Color3.fromRGB(100, 200, 255)
			end

			UI.label({size = UDim2.new(0.33, 0, 1, 0), pos = UDim2.new(0.66, 0, 0, 0), text = playerRole:sub(1,1):upper() .. playerRole:sub(2), color = roleColor, textSize = 11, font = Enum.Font.GothamMedium, alignX = Enum.TextXAlignment.Center, z = 104, parent = statsFrame})

			local canEdit = (playerRole == "owner" or playerRole == "colider")

			if canEdit then
				local editFrame = UI.frame({size = UDim2.new(1, -20, 0, 28), pos = UDim2.new(0, 10, 0, 216), bgT = 1, z = 104, parent = clanCard})

				local btnEditName = UI.button({
					size = UDim2.new(0.48, 0, 1, 0), bg = THEME.surface, text = "Editar Nombre",
					color = THEME.text, textSize = 10, font = Enum.Font.GothamMedium, z = 104, parent = editFrame, corner = 6
				})

				local btnEditTag = UI.button({
					size = UDim2.new(0.48, 0, 1, 0), pos = UDim2.new(0.52, 0, 0, 0),
					bg = THEME.surface, text = "Editar TAG", color = THEME.text, textSize = 10,
					font = Enum.Font.GothamMedium, z = 104, parent = editFrame, corner = 6
				})

				Memory.track(btnEditName.MouseButton1Click:Connect(function()
					ConfirmationModal.new({
						screenGui = screenGui, title = "Cambiar Nombre", message = "Ingresa el nuevo nombre:",
						inputText = true, inputPlaceholder = "Nuevo nombre", inputDefault = clanData.clanName,
						confirmText = "Cambiar", cancelText = "Cancelar",
						onConfirm = function(newName)
							if newName and #newName >= 3 then
								local success, msg = ClanClient:ChangeClanName(newName)
								if success then
									Notify:Success("Actualizado", "Nombre cambiado", 4)
								else Notify:Error("Error", msg or "No se pudo cambiar", 4) end
							else Notify:Warning("Inválido", "Mínimo 3 caracteres", 3) end
						end
					})
				end))

				Memory.track(btnEditTag.MouseButton1Click:Connect(function()
					ConfirmationModal.new({
						screenGui = screenGui, title = "Cambiar TAG", message = "Ingresa el nuevo TAG (2-5 caracteres):",
						inputText = true, inputPlaceholder = "Ej: XYZ", inputDefault = clanData.clanTag,
						confirmText = "Cambiar", cancelText = "Cancelar",
						onConfirm = function(newTag)
							newTag = newTag and newTag:upper() or ""
							if #newTag >= 2 and #newTag <= 5 then
								local success, msg = ClanClient:ChangeClanTag(newTag)
								if success then
									Notify:Success("Actualizado", "TAG cambiado", 4)
								else Notify:Error("Error", msg or "No se pudo cambiar", 4) end
							else Notify:Warning("Inválido", "Entre 2 y 5 caracteres", 3) end
						end
					})
				end))
			end

			local actionBtnY = canEdit and 252 or 216

			if playerRole == "owner" then
				local btnDissolve = UI.button({
					size = UDim2.new(1, -20, 0, 28), pos = UDim2.new(0, 10, 0, actionBtnY),
					bg = Color3.fromRGB(180, 50, 50), text = "DISOLVER CLAN", textSize = 12, z = 104, parent = clanCard, corner = 6
				})

				Memory.track(btnDissolve.MouseButton1Click:Connect(function()
					ConfirmationModal.new({
						screenGui = screenGui, title = "Disolver Clan",
						message = "¿Disolver \"" .. clanData.clanName .. "\"?\n\nEsta acción es IRREVERSIBLE.",
						confirmText = "Disolver", cancelText = "Cancelar",
						onConfirm = function()
							local success, msg = ClanClient:DissolveClan()
							if success then
								Notify:Success("Clan Disuelto", "El clan ha sido eliminado", 4)
							else Notify:Error("Error", msg or "No se pudo disolver", 3) end
						end
					})
				end))
			else
				local btnLeave = UI.button({
					size = UDim2.new(1, -20, 0, 28), pos = UDim2.new(0, 10, 0, actionBtnY),
					bg = THEME.danger or Color3.fromRGB(200, 60, 60), text = "SALIR DEL CLAN", textSize = 12, z = 104, parent = clanCard, corner = 6
				})

				Memory.track(btnLeave.MouseButton1Click:Connect(function()
					ConfirmationModal.new({
						screenGui = screenGui, title = "Salir del Clan",
						message = "¿Estás seguro?", confirmText = "Salir", cancelText = "Cancelar",
						onConfirm = function()
							local success, msg = ClanClient:LeaveClan()
							if success then
								Notify:Success("Abandonado", "Has salido del clan", 4)
							else Notify:Error("Error", msg or "No se pudo salir", 3) end
						end
					})
				end))
			end

			local nextY = createJoinRequestsSection(clanData, playerRole, clanScroll, 310)

			local membersCard = UI.frame({
				size = UDim2.new(1, 0, 0, 150),
				pos = UDim2.new(0, 0, 0, nextY),
				bg = THEME.card, z = 105, parent = clanScroll, corner = 12, stroke = true, strokeA = 0.6
			})

			UI.label({
				size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 10),
				text = "👥 Miembros", textSize = 13, font = Enum.Font.GothamBold, z = 105, parent = membersCard
			})

			local membersScroll = Instance.new("ScrollingFrame")
			membersScroll.Size = UDim2.new(1, -20, 1, -45)
			membersScroll.Position = UDim2.new(0, 10, 0, 35)
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
					createMemberCard(memberData, odI, clanData, playerRole, membersScroll)
				end
			end

			task.defer(function()
				membersScroll.CanvasSize = UDim2.new(0, membersLayout.AbsoluteContentSize.X + 16, 0, 0)
				clanScroll.CanvasSize = UDim2.new(0, 0, 0, nextY + 170)
			end)
		else
			local noClanCard = UI.frame({
				size = UDim2.new(0, 300, 0, 160), pos = UDim2.new(0.5, -150, 0.5, -80),
				bg = THEME.card, z = 103, parent = tuClanContainer, corner = 12, stroke = true, strokeA = 0.6
			})

			UI.label({size = UDim2.new(0, 60, 0, 60), pos = UDim2.new(0.5, -30, 0, 15), text = "🛡️", textSize = 40, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 82), text = "No perteneces a ningún clan", textSize = 14, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 32), pos = UDim2.new(0, 10, 0, 106), text = "Únete a un clan en 'Disponibles'", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Center, wrap = true, z = 104, parent = noClanCard})
		end
	end) -- Cierre de task.spawn
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
		size = UDim2.new(1, -180, 0, 14), pos = UDim2.new(0, 85, 0, 62),
		text = (clanData.miembros_count or 0) .. "/50 • Nivel " .. (clanData.nivel or 1) .. " • [" .. (clanData.clanTag or "?") .. "]",
		color = THEME.muted, textSize = 10, z = 106, parent = entry
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

		if loadingConnection then loadingConnection:Disconnect() end
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

		if loadingConnection then loadingConnection:Disconnect() end
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