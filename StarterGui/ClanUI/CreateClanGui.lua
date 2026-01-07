--[[ Clan System - Professional Edition
     • Sistema completo de clanes con roles
     • Layout moderno usando ThemeConfig
     • Roles: Owner, Colideres, Lideres, Miembros
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

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local R_PANEL, R_CTRL = 12, 8
local ENABLE_BLUR, BLUR_SIZE = true, 14

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

local function stroked(inst, alpha)
local s = Instance.new("UIStroke")
s.Color = THEME.stroke
s.Thickness = 1
s.Transparency = alpha or 0.5
s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
s.Parent = inst
return s
end

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanSystemGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
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
overlay.BackgroundColor3 = THEME.bg
overlay.AutoButtonColor = false
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
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
panel.Position = UDim2.new(0.5, 0, 1, 40)
panel.BackgroundColor3 = THEME.panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 100
panel.ClipsDescendants = true
panel.Size = UDim2.new(0.5, 0, 0.86, 0)
panel.Parent = screenGui
rounded(panel, R_PANEL)
stroked(panel, 0.25)

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 80)
header.BackgroundColor3 = THEME.head
header.BorderSizePixel = 0
header.ZIndex = 102
header.Parent = panel
rounded(header, R_PANEL)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 28)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22))
}
gradient.Rotation = 90
gradient.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -80, 0, 24)
title.Position = UDim2.new(0, 20, 0, 16)
title.Text = "SISTEMA DE CLANES"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -80, 0, 16)
subtitle.Position = UDim2.new(0, 20, 0, 44)
subtitle.Text = "Crea o únete a un clan"
subtitle.TextColor3 = THEME.muted
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(1, -60, 0, 15)
closeBtn.BackgroundColor3 = THEME.btnDanger
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = THEME.text
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 103
closeBtn.Parent = header
rounded(closeBtn, R_CTRL)

-- ════════════════════════════════════════════════════════════════
-- TABS NAVIGATION
-- ════════════════════════════════════════════════════════════════
local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(1, -40, 0, 50)
tabNav.Position = UDim2.new(0, 20, 0, 90)
tabNav.BackgroundColor3 = THEME.card
tabNav.BorderSizePixel = 0
tabNav.ZIndex = 101
tabNav.Parent = panel
rounded(tabNav, R_CTRL)
stroked(tabNav, 0.3)

local tabButtons = {}
local tabPages = {}

local function createTabButton(text, index)
local btn = Instance.new("TextButton")
btn.Name = text
btn.Size = UDim2.new(0.33, -6, 1, -10)
btn.Position = UDim2.new((index - 1) * 0.33, 3 + (index - 1) * 6, 0, 5)
btn.BackgroundColor3 = THEME.btnSecondary
btn.BorderSizePixel = 0
btn.Text = text
btn.TextColor3 = THEME.muted
btn.TextSize = 14
btn.Font = Enum.Font.GothamBold
btn.ZIndex = 102
btn.Parent = tabNav
rounded(btn, R_CTRL - 2)

return btn
end

tabButtons["TuClan"] = createTabButton("Tu Clan", 1)
tabButtons["Disponibles"] = createTabButton("Disponibles", 2)
tabButtons["Crear"] = createTabButton("Crear", 3)

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -40, 1, -160)
contentArea.Position = UDim2.new(0, 20, 0, 150)
contentArea.BackgroundTransparency = 1
contentArea.ZIndex = 101
contentArea.Parent = panel

-- ════════════════════════════════════════════════════════════════
-- PAGE: TU CLAN
-- ════════════════════════════════════════════════════════════════
local pageTuClan = Instance.new("Frame")
pageTuClan.Name = "TuClan"
pageTuClan.Size = UDim2.fromScale(1, 1)
pageTuClan.BackgroundTransparency = 1
pageTuClan.Visible = false
pageTuClan.ZIndex = 101
pageTuClan.Parent = contentArea

local noClanCard = Instance.new("Frame")
noClanCard.Size = UDim2.new(1, 0, 0, 120)
noClanCard.Position = UDim2.new(0, 0, 0.3, 0)
noClanCard.BackgroundColor3 = THEME.card
noClanCard.BorderSizePixel = 0
noClanCard.Parent = pageTuClan
rounded(noClanCard, R_CTRL)
stroked(noClanCard, 0.3)

local noClanIcon = Instance.new("TextLabel")
noClanIcon.Size = UDim2.new(0, 40, 0, 40)
noClanIcon.Position = UDim2.new(0.5, -20, 0, 20)
noClanIcon.BackgroundTransparency = 1
noClanIcon.Text = "���"
noClanIcon.TextSize = 32
noClanIcon.Parent = noClanCard

local noClanText = Instance.new("TextLabel")
noClanText.Size = UDim2.new(1, -20, 0, 20)
noClanText.Position = UDim2.new(0, 10, 0, 65)
noClanText.BackgroundTransparency = 1
noClanText.Text = "No estás en ningún clan"
noClanText.TextColor3 = THEME.text
noClanText.TextSize = 14
noClanText.Font = Enum.Font.GothamBold
noClanText.Parent = noClanCard

local noClanHint = Instance.new("TextLabel")
noClanHint.Size = UDim2.new(1, -20, 0, 15)
noClanHint.Position = UDim2.new(0, 10, 0, 88)
noClanHint.BackgroundTransparency = 1
noClanHint.Text = "Únete a uno o crea el tuyo"
noClanHint.TextColor3 = THEME.muted
noClanHint.TextSize = 12
noClanHint.Font = Enum.Font.Gotham
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
pageDisponibles.ZIndex = 101
pageDisponibles.Parent = contentArea

local clansScroll = Instance.new("ScrollingFrame")
clansScroll.Size = UDim2.fromScale(1, 1)
clansScroll.BackgroundColor3 = THEME.elevated
clansScroll.BorderSizePixel = 0
clansScroll.ScrollBarThickness = 6
clansScroll.ScrollBarImageColor3 = THEME.accent
clansScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
clansScroll.ZIndex = 101
clansScroll.Parent = pageDisponibles
rounded(clansScroll, R_CTRL)
stroked(clansScroll, 0.3)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = clansScroll

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = clansScroll

-- Ejemplo de clan entry
local function createClanEntry(clanData)
local entry = Instance.new("Frame")
entry.Size = UDim2.new(1, -20, 0, 90)
entry.BackgroundColor3 = THEME.card
entry.BorderSizePixel = 0
entry.ZIndex = 102
entry.Parent = clansScroll
rounded(entry, R_CTRL - 2)
stroked(entry, 0.4)

-- Logo
local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 70, 0, 70)
logo.Position = UDim2.new(0, 10, 0, 10)
logo.BackgroundColor3 = THEME.surface
logo.BorderSizePixel = 0
	logo.Image = clanData.clanLogo or "rbxassetid://0"
info.Size = UDim2.new(1, -95, 1, -10)
info.Position = UDim2.new(0, 90, 0, 5)
info.BackgroundTransparency = 1
info.ZIndex = 103
info.Parent = entry

-- Nombre
local name = Instance.new("TextLabel")
name.Size = UDim2.new(1, -110, 0, 18)
name.Position = UDim2.new(0, 0, 0, 5)
name.BackgroundTransparency = 1
	name.Text = string.upper(clanData.clanName or "CLAN")
	name.TextColor3 = THEME.accent
	name.TextSize = 15
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 104
	name.Parent = info

	-- ID
	local clanId = Instance.new("TextLabel")
	clanId.Size = UDim2.new(0, 80, 0, 14)
	clanId.Position = UDim2.new(0, 0, 0, 24)
	clanId.BackgroundTransparency = 1
	clanId.Text = "[" .. (clanData.clanId or "???"):sub(1, 4) .. "]"
clanId.Parent = info

-- Descripción
local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, -110, 0, 14)
desc.Position = UDim2.new(0, 0, 0, 42)
desc.BackgroundTransparency = 1
desc.Text = clanData.description or "Sin descripción"
desc.TextColor3 = THEME.subtle
desc.TextSize = 10
desc.Font = Enum.Font.Gotham
desc.TextXAlignment = Enum.TextXAlignment.Left
desc.ZIndex = 104
desc.Parent = info

-- Stats container
local stats = Instance.new("Frame")
stats.Size = UDim2.new(1, -110, 0, 14)
stats.Position = UDim2.new(0, 0, 1, -20)
stats.BackgroundTransparency = 1
stats.ZIndex = 104
stats.Parent = info

local members = Instance.new("TextLabel")
members.Size = UDim2.new(0.5, 0, 1, 0)
members.BackgroundTransparency = 1
members.Text = "��� " .. (clanData.members or 0) .. "/50"
members.TextColor3 = THEME.muted
members.TextSize = 10
members.Font = Enum.Font.Gotham
members.TextXAlignment = Enum.TextXAlignment.Left
members.ZIndex = 105
members.Parent = stats

local level = Instance.new("TextLabel")
level.Size = UDim2.new(0.5, 0, 1, 0)
level.Position = UDim2.fromScale(0.5, 0)
level.BackgroundTransparency = 1
level.Text = "��� Nivel " .. (clanData.level or 1)
level.TextColor3 = THEME.muted
level.TextSize = 10
level.Font = Enum.Font.Gotham
level.TextXAlignment = Enum.TextXAlignment.Left
level.ZIndex = 105
level.Parent = stats

-- Botón unirse
local joinBtn = Instance.new("TextButton")
joinBtn.Size = UDim2.new(0, 90, 0, 30)
joinBtn.Position = UDim2.new(1, -100, 0.5, -15)
joinBtn.BackgroundColor3 = THEME.accent
joinBtn.BorderSizePixel = 0
joinBtn.Text = "Unirse"
joinBtn.TextColor3 = THEME.text
joinBtn.TextSize = 12
joinBtn.Font = Enum.Font.GothamBold
joinBtn.ZIndex = 104
joinBtn.Parent = entry
rounded(joinBtn, R_CTRL - 2)

return entry
end

-- Función para cargar clanes desde el servidor
local function loadClansFromServer()
	-- Limpiar lista actual
	for _, child in ipairs(clansScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Obtener clanes del servidor
	local clans = ClanClient:GetClansList()
	
	if clans and #clans > 0 then
		for _, clanData in ipairs(clans) do
			createClanEntry(clanData)
		end
	else
		-- Mostrar mensaje de no hay clanes
		local noClansLabel = Instance.new("TextLabel")
		noClansLabel.Size = UDim2.new(1, -20, 0, 60)
		noClansLabel.Position = UDim2.new(0, 10, 0, 50)
		noClansLabel.BackgroundTransparency = 1
		noClansLabel.Text = "No hay clanes disponibles\n\n¡Sé el primero en crear uno!"
		noClansLabel.TextColor3 = THEME.muted
		noClansLabel.TextSize = 14
		noClansLabel.Font = Enum.Font.Gotham
		noClansLabel.ZIndex = 102
		noClansLabel.Parent = clansScroll
	end
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
clansScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: CREAR
-- ════════════════════════════════════════════════════════════════
local pageCrear = Instance.new("Frame")
pageCrear.Name = "Crear"
pageCrear.Size = UDim2.fromScale(1, 1)
pageCrear.BackgroundTransparency = 1
pageCrear.Visible = false
pageCrear.ZIndex = 101
pageCrear.Parent = contentArea

local createCard = Instance.new("Frame")
createCard.Size = UDim2.new(1, 0, 0, 300)
createCard.Position = UDim2.new(0, 0, 0, 20)
createCard.BackgroundColor3 = THEME.card
createCard.BorderSizePixel = 0
createCard.Parent = pageCrear
rounded(createCard, R_CTRL)
stroked(createCard, 0.3)

local createPadding = Instance.new("UIPadding")
createPadding.PaddingTop = UDim.new(0, 20)
createPadding.PaddingBottom = UDim.new(0, 20)
createPadding.PaddingLeft = UDim.new(0, 20)
createPadding.PaddingRight = UDim.new(0, 20)
createPadding.Parent = createCard

-- Label nombre
local labelNombre = Instance.new("TextLabel")
labelNombre.Size = UDim2.new(1, 0, 0, 18)
labelNombre.Position = UDim2.new(0, 0, 0, 0)
labelNombre.BackgroundTransparency = 1
labelNombre.Text = "Nombre del Clan"
labelNombre.TextColor3 = THEME.text
labelNombre.TextSize = 13
labelNombre.Font = Enum.Font.GothamBold
labelNombre.TextXAlignment = Enum.TextXAlignment.Left
labelNombre.Parent = createCard

-- Input nombre
local inputNombre = Instance.new("TextBox")
inputNombre.Size = UDim2.new(1, 0, 0, 40)
inputNombre.Position = UDim2.new(0, 0, 0, 25)
inputNombre.BackgroundColor3 = THEME.surface
inputNombre.BorderSizePixel = 0
inputNombre.Text = ""
inputNombre.TextColor3 = THEME.text
inputNombre.TextSize = 14
inputNombre.Font = Enum.Font.Gotham
inputNombre.PlaceholderText = "Ej: Guardianes del Fuego"
inputNombre.PlaceholderColor3 = THEME.subtle
inputNombre.ClearTextOnFocus = false
inputNombre.Parent = createCard
rounded(inputNombre, R_CTRL - 2)
stroked(inputNombre, 0.5)

-- Label descripción
local labelDesc = Instance.new("TextLabel")
labelDesc.Size = UDim2.new(1, 0, 0, 18)
labelDesc.Position = UDim2.new(0, 0, 0, 80)
labelDesc.BackgroundTransparency = 1
labelDesc.Text = "Descripción"
labelDesc.TextColor3 = THEME.text
labelDesc.TextSize = 13
labelDesc.Font = Enum.Font.GothamBold
labelDesc.TextXAlignment = Enum.TextXAlignment.Left
labelDesc.Parent = createCard

-- Input descripción
local inputDesc = Instance.new("TextBox")
inputDesc.Size = UDim2.new(1, 0, 0, 60)
inputDesc.Position = UDim2.new(0, 0, 0, 105)
inputDesc.BackgroundColor3 = THEME.surface
inputDesc.BorderSizePixel = 0
inputDesc.Text = ""
inputDesc.TextColor3 = THEME.text
inputDesc.TextSize = 12
inputDesc.Font = Enum.Font.Gotham
inputDesc.PlaceholderText = "Describe tu clan..."
inputDesc.PlaceholderColor3 = THEME.subtle
inputDesc.TextWrapped = true
inputDesc.TextYAlignment = Enum.TextYAlignment.Top
inputDesc.MultiLine = true
inputDesc.ClearTextOnFocus = false
inputDesc.Parent = createCard
rounded(inputDesc, R_CTRL - 2)
stroked(inputDesc, 0.5)

local inputDescPad = Instance.new("UIPadding")
inputDescPad.PaddingTop = UDim.new(0, 8)
inputDescPad.PaddingLeft = UDim.new(0, 8)
inputDescPad.Parent = inputDesc

-- Label logo
local labelLogo = Instance.new("TextLabel")
labelLogo.Size = UDim2.new(1, 0, 0, 18)
labelLogo.Position = UDim2.new(0, 0, 0, 180)
labelLogo.BackgroundTransparency = 1
labelLogo.Text = "Logo (Asset ID - Opcional)"
labelLogo.TextColor3 = THEME.text
labelLogo.TextSize = 13
labelLogo.Font = Enum.Font.GothamBold
labelLogo.TextXAlignment = Enum.TextXAlignment.Left
labelLogo.Parent = createCard

-- Input logo
local inputLogo = Instance.new("TextBox")
inputLogo.Size = UDim2.new(1, 0, 0, 40)
inputLogo.Position = UDim2.new(0, 0, 0, 205)
inputLogo.BackgroundColor3 = THEME.surface
inputLogo.BorderSizePixel = 0
inputLogo.Text = ""
inputLogo.TextColor3 = THEME.text
inputLogo.TextSize = 14
inputLogo.Font = Enum.Font.Gotham
inputLogo.PlaceholderText = "rbxassetid://12345"
inputLogo.PlaceholderColor3 = THEME.subtle
inputLogo.ClearTextOnFocus = false
inputLogo.Parent = createCard
rounded(inputLogo, R_CTRL - 2)
stroked(inputLogo, 0.5)

-- Botón crear
local btnCrear = Instance.new("TextButton")
btnCrear.Size = UDim2.new(1, 0, 0, 45)
btnCrear.Position = UDim2.new(0, 0, 1, -45)
btnCrear.BackgroundColor3 = THEME.accent
btnCrear.BorderSizePixel = 0
btnCrear.Text = "Crear Clan"
btnCrear.TextColor3 = THEME.text
btnCrear.TextSize = 15
btnCrear.Font = Enum.Font.GothamBold
btnCrear.Parent = createCard
rounded(btnCrear, R_CTRL - 2)

tabPages["Crear"] = pageCrear

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
local function switchTab(tabName)
currentPage = tabName

for name, btn in pairs(tabButtons) do
if name == tabName then
btn.BackgroundColor3 = THEME.accent
btn.TextColor3 = THEME.text
else
btn.BackgroundColor3 = THEME.btnSecondary
btn.TextColor3 = THEME.muted
end
end

for name, page in pairs(tabPages) do
page.Visible = (name == tabName)
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

	TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
	TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	-- Cargar clanes del servidor
	loadClansFromServer()
	
	switchTab("Disponibles")
end

local function closeUI()
	if not uiOpen then return end
	uiOpen = false

	if blur then
		TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.3, function()
			blur.Enabled = false
		end)
	end

	TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1, 40)
	}):Play()

	task.delay(0.3, function()
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
	local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or "rbxassetid://0"

	if clanName == "" or #clanName < 3 then
		print("El nombre del clan debe tener al menos 3 caracteres")
		return
	end

	print("Creando clan:", clanName)
	ClanClient:CreateClan(clanName, clanLogo, clanDesc)

	inputNombre.Text = ""
	inputDesc.Text = ""
	inputLogo.Text = ""

	-- Esperar un poco y recargar la lista
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

print("✓ Clan System UI cargada - Estilo moderno")
