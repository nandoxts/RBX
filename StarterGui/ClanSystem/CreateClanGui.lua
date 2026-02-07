--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM UI - Refactorizado y Modular
	═══════════════════════════════════════════════════════════
	Versión 2.0 - Código organizado en módulos
	by ignxts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Módulos externos
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))

-- Módulos internos del sistema de clanes
local ClanConstants = require(script.Parent.ClanConstants)
local ClanHelpers = require(script.Parent.ClanHelpers)
local ClanNetworking = require(script.Parent.ClanNetworking)

-- Referencias locales
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CONFIG = ClanConstants.CONFIG
local State = ClanConstants.State
local Memory = ClanConstants.Memory
local isAdmin = table.find(ClanSystemConfig.ADMINS.AdminUserIds, player.UserId) ~= nil

-- Configurar el tracking de UI
UI.setTrack(function(conn) return Memory:track(conn) end)

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanSystemGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui


local UserInputService = game:GetService("UserInputService")
task.wait(0.5)
local isMobileDevice = UserInputService.TouchEnabled

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "ClanPanel",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = CONFIG.panel.corner,
	enableBlur = CONFIG.blur.enabled,
	blurSize = CONFIG.blur.size,
	isMobile = isMobileDevice,
	onClose = function() end
})

local panel = modal:getPanel()
local tabButtons = {}
local tabPages = {}

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = UI.frame({name = "Header", size = UDim2.new(1, 0, 0, 60), bg = THEME.head or Color3.fromRGB(22, 22, 28), z = 101, parent = panel, corner = 12})

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.panel), ColorSequenceKeypoint.new(1, THEME.card)}
headerGradient.Rotation = 90
headerGradient.Parent = header

UI.label({size = UDim2.new(1, -100, 0, 60), pos = UDim2.new(0, 20, 0, 0), text = "CLANES", textSize = 20, font = Enum.Font.GothamBold, z = 102, parent = header})

local closeBtn = UI.button({name = "CloseBtn", size = UDim2.new(0, 36, 0, 36), pos = UDim2.new(1, -50, 0.5, -18), bg = THEME.card, text = "×", color = THEME.muted, textSize = 22, z = 103, parent = header, corner = 8})
UI.stroked(closeBtn, 0.4)

Memory:track(closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.btnDanger, TextColor3 = THEME.text}):Play()
end))
Memory:track(closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card, TextColor3 = THEME.muted}):Play()
end))

-- ════════════════════════════════════════════════════════════════
-- TABS
-- ════════════════════════════════════════════════════════════════
local tabNav = UI.frame({size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 60), bgT = 1, z = 101, parent = panel})

local navList = Instance.new("UIListLayout")
navList.FillDirection = Enum.FillDirection.Horizontal
navList.Padding = UDim.new(0, 12)
navList.Parent = tabNav

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 20)
navPadding.PaddingTop = UDim.new(0, 6)
navPadding.Parent = tabNav

local function createTab(text)
	local btn = UI.button({size = UDim2.new(0, 90, 0, 24), bg = THEME.panel, text = text, color = THEME.muted, textSize = 13, font = Enum.Font.GothamBold, z = 101, parent = tabNav, corner = 0})
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	return btn
end

tabButtons["TuClan"] = createTab("TU CLAN")
tabButtons["Disponibles"] = createTab("DISPONIBLES")
if isAdmin then
	tabButtons["Admin"] = createTab("ADMIN")
end

local underline = UI.frame({size = UDim2.new(0, 90, 0, 3), pos = UDim2.new(0, 20, 0, 93), bg = THEME.accent, z = 102, parent = panel, corner = 2})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({name = "ContentArea", size = UDim2.new(1, -20, 1, -115), pos = UDim2.new(0, 10, 0, 90), bgT = 1, z = 101, parent = panel, corner = 10, clips = true})

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
local tuClanContainer = UI.frame({name = "Container", size = UDim2.new(1, -20, 1, -20), pos = UDim2.new(0, 10, 0, 10), bgT = 1, z = 102, parent = pageTuClan})
tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = UI.frame({name = "Disponibles", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
pageDisponibles.LayoutOrder = 2

local searchContainer, searchInput, searchCleanup = SearchModern.new(pageDisponibles, {placeholder = "Buscar clanes...", size = UDim2.new(1, -20, 0, 36), z = 104, name = "BuscarClanes"})
searchContainer.Position = UDim2.new(0, 10, 0, 10)
Memory:track({Disconnect = searchCleanup})

local clansScroll = ClanHelpers.setupScroll(pageDisponibles, {size = UDim2.new(1, -20, 1, -56), pos = UDim2.new(0, 10, 0, 52), padding = 8, z = 103})

local searchDebounce = false
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.4, function()
		if State.currentPage == "Disponibles" and State.isOpen then 
			ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG, searchInput.Text)
		end
		searchDebounce = false
	end)
end)

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin, adminClansScroll

if isAdmin then
	pageAdmin = UI.frame({name = "Admin", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
	pageAdmin.LayoutOrder = 3

	local adminHeader = UI.frame({size = UDim2.new(1, -20, 0, 40), pos = UDim2.new(0, 10, 0, 10), bg = THEME.warnMuted, z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = THEME.btnDanger})
	UI.label({size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0), text = "⚠ Panel de Administrador - Acciones irreversibles", color = THEME.warn, textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader})

	adminClansScroll = ClanHelpers.setupScroll(pageAdmin, {z = 103})
	tabPages["Admin"] = pageAdmin
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
local tabPositions = isAdmin and { TuClan = 20, Disponibles = 122, Admin = 224 } or { TuClan = 20, Disponibles = 122 }

local function switchTab(tabName, forceLoad)
	if State.currentPage == tabName and not forceLoad then return end

	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()

	State.currentPage = tabName
	State.currentView = "main"

	for name, btn in pairs(tabButtons) do
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = (name == tabName) and THEME.accent or THEME.muted}):Play()
	end

	TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, tabPositions[tabName] or 20, 0, 93)}):Play()

	local pageFrame = contentArea:FindFirstChild(tabName)
	if pageFrame then pageLayout:JumpTo(pageFrame) end

	task.delay(0.05, function()
		if State.currentPage ~= tabName then return end
		if not State.isOpen then return end

		local reloadFunc = function(v) ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, v) end

		if tabName == "TuClan" then 
			ClanNetworking.loadPlayerClan(tuClanContainer, screenGui, State, reloadFunc)
		elseif tabName == "Disponibles" then 
			ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG)
		elseif tabName == "Admin" and isAdmin then 
			ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG)
		end
	end)
end

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ════════════════════════════════════════════════════════════════
-- OPEN/CLOSE FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function openUI()
	State.isOpen = true
	State.currentPage = nil

	modal:open()

	if not ClanClient.initialized then 
		task.spawn(function() ClanClient:Initialize() end) 
	end

	switchTab("TuClan", true)
end

local function closeUI()
	State.isOpen = false
	State.loadingId = State.loadingId + 1

	Memory:cleanup()
	UI.cleanupLoading()

	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end

	State.views = {}
	State.currentView = "main"
	State.currentPage = nil
	State.clanData = nil
	State.playerRole = nil

	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
	GlobalModalManager:closeModal("Clan")
end)

-- ════════════════════════════════════════════════════════════════
-- LISTENER DEL SERVIDOR
-- ════════════════════════════════════════════════════════════════
local listenerLastTime = 0

-- Registrar callback para actualizar la UI cuando hay cambios
ClanClient:OnClansUpdated(function(clans)
	if not State.isOpen then return end
	if not screenGui or not screenGui.Parent then return end

	local now = tick()
	if (now - listenerLastTime) < CONFIG.listenerCooldown then return end
	listenerLastTime = now

	-- ✅ Incrementar loadingId INMEDIATAMENTE para cancelar refreshes anteriores pendientes
	State.loadingId = State.loadingId + 1

	-- ✅ NO usar task.defer - las funciones ya usan task.spawn internamente
	if State.currentPage == "TuClan" then 
		ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, State.currentView)
	elseif State.currentPage == "Disponibles" then 
		ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG, "", false, clans)
	elseif State.currentPage == "Admin" and isAdmin then 
		ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG)
	end
end)

-- Pre-cargar datos del cliente
task.spawn(function() 
	ClanClient:Initialize()
end)

-- ════════════════════════════════════════════════════════════════
-- EXPORT GLOBAL API
-- ════════════════════════════════════════════════════════════════
_G.OpenClanUI = openUI
_G.CloseClanUI = closeUI
