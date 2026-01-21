--[[
	Clan System UI - VERSIÓN FINAL CORREGIDA
	- Sin doble actualización
	- Tab inicial correcta
	- Loading estable
	
	by ignxts
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
	panel = { width = THEME.panelWidth or 980, height = THEME.panelHeight or 620, corner = 12 },
	blur = { enabled = true, size = 14 },
	cooldown = 1.5,
	listenerCooldown = 3, -- Cooldown más largo para el listener del servidor
	colors = {
		{name = "Dorado", rgb = {255, 215, 0}},
		{name = "Rojo", rgb = {255, 69, 0}},
		{name = "Morado", rgb = {128, 0, 128}},
		{name = "Azul", rgb = {0, 122, 255}},
		{name = "Verde", rgb = {34, 177, 76}},
		{name = "Rosa", rgb = {255, 105, 180}},
		{name = "Cian", rgb = {0, 255, 255}},
		{name = "Blanco", rgb = {255, 255, 255}},
	},
	emojis = {"🔱", "⚔️", "🛡️", "👑", "💀", "🔥", "😈", "🦁", "🐉", "⭐", "💎", "🎯"}
}

local isAdmin = table.find(ClanSystemConfig.ADMINS.AdminUserIds, player.UserId) ~= nil

-- ════════════════════════════════════════════════════════════════
-- ESTADO CENTRALIZADO
-- ════════════════════════════════════════════════════════════════
local State = {
	-- Página/Vista actual
	currentPage = nil, -- IMPORTANTE: nil al inicio para que switchTab funcione
	currentView = "main",

	-- Control de operaciones
	isUpdating = false,
	lastUpdateTime = 0,
	loadingId = 0,

	-- UI abierta
	isOpen = false,

	-- Selección en crear
	selectedColor = 1,
	selectedEmoji = 1,

	-- Cache de datos
	clanData = nil,
	playerRole = nil,

	-- Referencias a vistas
	views = {},

	-- Instancias de listas
	membersList = nil,
	pendingList = nil,
}

-- ════════════════════════════════════════════════════════════════
-- MEMORY MANAGER
-- ════════════════════════════════════════════════════════════════
local Memory = { connections = {} }

function Memory:track(conn)
	if conn then table.insert(self.connections, conn) end
	return conn
end

function Memory:cleanup()
	for i, conn in ipairs(self.connections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	self.connections = {}
	UI.cleanupLoading()
end

function Memory:destroyChildren(parent, except)
	if not parent then return end
	for _, child in ipairs(parent:GetChildren()) do
		if not except or not child:IsA(except) then 
			child:Destroy() 
		end
	end
end

UI.setTrack(function(conn) return Memory:track(conn) end)

-- ════════════════════════════════════════════════════════════════
-- LOADING SEGURO
-- ════════════════════════════════════════════════════════════════
local function safeLoading(container, asyncFn, onComplete)
	if not State.isOpen then return end

	State.loadingId = State.loadingId + 1
	local myId = State.loadingId
	local expectedPage = State.currentPage

	Memory:destroyChildren(container, "UIListLayout")
	local loadingFrame = UI.loading(container)

	task.spawn(function()
		local results = {pcall(asyncFn)}
		local success = table.remove(results, 1)

		-- Verificar validez
		if myId ~= State.loadingId then return end
		if expectedPage ~= State.currentPage then return end
		if not State.isOpen then return end

		-- Limpiar loading
		UI.cleanupLoading()
		if loadingFrame and loadingFrame.Parent then
			loadingFrame:Destroy()
		end

		if container and container.Parent then
			Memory:destroyChildren(container, "UIListLayout")
		end

		if success and onComplete then
			onComplete(table.unpack(results))
		elseif not success then
			warn("[ClanUI] Error async:", results[1])
		end
	end)

	return myId
end

-- ════════════════════════════════════════════════════════════════
-- VALIDADOR
-- ════════════════════════════════════════════════════════════════
local Validator = {
	rules = {
		clanName = { min = 3, msg = "Nombre inválido - Mínimo 3 caracteres" },
		clanTag = { min = 2, max = 5, msg = "TAG inválido - Entre 2 y 5 caracteres" },
		ownerId = { isNumber = true, positive = true, msg = "ID inválido - Debe ser un número positivo" }
	}
}

function Validator:check(field, value)
	local rule = self.rules[field]
	if not rule then return true end

	if rule.isNumber then
		local num = tonumber(value)
		if value ~= "" and (not num or (rule.positive and num <= 0)) then
			Notify:Warning("Validación", rule.msg, 3)
			return false
		end
		return true
	end

	local len = #(value or "")
	if rule.min and len < rule.min then Notify:Warning("Validación", rule.msg, 3) return false end
	if rule.max and len > rule.max then Notify:Warning("Validación", rule.msg, 3) return false end
	return true
end

function Validator:validateClanCreation(name, tag, ownerId)
	return self:check("clanName", name) and self:check("clanTag", tag) and self:check("ownerId", ownerId)
end

-- ════════════════════════════════════════════════════════════════
-- MODAL HELPER
-- ════════════════════════════════════════════════════════════════
local function showModal(gui, opts)
	ConfirmationModal.new({
		screenGui = gui,
		title = opts.title,
		message = opts.message,
		inputText = opts.input ~= nil,
		inputPlaceholder = opts.inputPlaceholder,
		inputDefault = opts.inputDefault,
		confirmText = opts.confirm or "Confirmar",
		cancelText = opts.cancel or "Cancelar",
		confirmColor = opts.confirmColor,
		onConfirm = function(value)
			if opts.validate and not opts.validate(value) then return end
			local success, msg = opts.action(value)
			if success then
				Notify:Success(opts.successTitle or "Éxito", msg or opts.successMsg, 4)
				if opts.onSuccess then opts.onSuccess() end
			else
				Notify:Error("Error", msg or opts.errorMsg or "Operación fallida", 4)
			end
		end
	})
end

-- ════════════════════════════════════════════════════════════════
-- CLAN ACTIONS
-- ════════════════════════════════════════════════════════════════
local ClanActions = {}

function ClanActions:editName(gui, clanData, onSuccess)
	showModal(gui, {
		title = "Cambiar Nombre", message = "Ingresa el nuevo nombre:",
		input = true, inputPlaceholder = "Nuevo nombre", inputDefault = clanData.clanName,
		confirm = "Cambiar",
		validate = function(v) return Validator:check("clanName", v) end,
		action = function(v) return ClanClient:ChangeClanName(v) end,
		successTitle = "Actualizado", successMsg = "Nombre cambiado",
		onSuccess = onSuccess
	})
end

function ClanActions:editTag(gui, clanData, onSuccess)
	showModal(gui, {
		title = "Cambiar TAG", message = "Ingresa el nuevo TAG (2-5 caracteres):",
		input = true, inputPlaceholder = "Ej: XYZ", inputDefault = clanData.clanTag,
		confirm = "Cambiar",
		validate = function(v) return Validator:check("clanTag", (v or ""):upper()) end,
		action = function(v) return ClanClient:ChangeClanTag(v:upper()) end,
		successTitle = "Actualizado", successMsg = "TAG cambiado",
		onSuccess = onSuccess
	})
end

function ClanActions:editColor(gui, onSuccess)
	showModal(gui, {
		title = "Cambiar Color", message = "Ingresa nombre de color (ej: azul, dorado):",
		input = true, inputPlaceholder = "ej: dorado", inputDefault = "",
		confirm = "Cambiar",
		validate = function(v) 
			if not v or v == "" then Notify:Warning("Inválido", "Ingresa un nombre de color", 3) return false end
			return true 
		end,
		action = function(v) return ClanClient:ChangeClanColor(v:lower():gsub("%s+", "")) end,
		successTitle = "Actualizado", successMsg = "Color cambiado",
		onSuccess = onSuccess
	})
end

function ClanActions:leave(gui, onSuccess)
	showModal(gui, {
		title = "Salir del Clan", message = "¿Estás seguro de que quieres salir?",
		confirm = "Salir",
		action = function() return ClanClient:LeaveClan() end,
		successTitle = "Abandonado", successMsg = "Has salido del clan",
		onSuccess = onSuccess
	})
end

function ClanActions:dissolve(gui, clanName, onSuccess)
	showModal(gui, {
		title = "Disolver Clan", 
		message = string.format('¿Disolver "%s"?\n\nEsta acción es IRREVERSIBLE.', clanName),
		confirm = "Disolver", confirmColor = THEME.btnDanger,
		action = function() return ClanClient:DissolveClan() end,
		successTitle = "Clan Disuelto", successMsg = "El clan ha sido eliminado",
		onSuccess = onSuccess
	})
end

function ClanActions:adminDelete(gui, clanData, onSuccess)
	showModal(gui, {
		title = "Eliminar Clan",
		message = string.format('¿Eliminar "%s"?', clanData.clanName or "Sin nombre"),
		confirm = "Eliminar", confirmColor = THEME.btnDanger,
		action = function() return ClanClient:AdminDissolveClan(clanData.clanId) end,
		successTitle = "Eliminado", successMsg = "Clan eliminado",
		onSuccess = onSuccess
	})
end

-- ════════════════════════════════════════════════════════════════
-- NAVEGACIÓN ENTRE VISTAS
-- ════════════════════════════════════════════════════════════════
local Navigation = { 
	tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) 
}

function Navigation:goto(viewName)
	if State.currentView == viewName then return end
	if not State.views[viewName] then return end

	local fromView = State.views[State.currentView]
	local toView = State.views[viewName]
	local direction = viewName == "main" and "back" or "forward"

	local outPos = direction == "forward" and UDim2.new(-1, 0, 0, 0) or UDim2.new(1, 0, 0, 0)
	local inPos = direction == "forward" and UDim2.new(1, 0, 0, 0) or UDim2.new(-1, 0, 0, 0)

	if fromView then 
		TweenService:Create(fromView, self.tweenInfo, {Position = outPos}):Play() 
	end

	if toView then
		toView.Position = inPos
		toView.Visible = true
		TweenService:Create(toView, self.tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
	end

	local oldView = State.currentView
	State.currentView = viewName

	task.delay(0.3, function()
		if fromView and fromView.Parent and State.currentView ~= oldView then
			fromView.Visible = false
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- HELPERS UI
-- ════════════════════════════════════════════════════════════════
local function setupScroll(parent, options)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = options.size or UDim2.new(1, -20, 1, -60)
	scroll.Position = options.pos or UDim2.new(0, 10, 0, 58)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = THEME.accent
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = options.z or 103
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, options.padding or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	return scroll
end

local function createSelector(items, config)
	local container = UI.frame({
		size = config.size or UDim2.new(1, 0, 0, 36),
		pos = config.pos, bg = THEME.surface, z = config.z or 105,
		parent = config.parent, corner = 8
	})

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, config.spacing or 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = container

	Instance.new("UIPadding", container).PaddingLeft = UDim.new(0, 6)

	local selectedIdx, buttons = 1, {}

	local function updateSelection(newIdx)
		selectedIdx = newIdx
		for j, data in ipairs(buttons) do
			local isSelected = j == newIdx
			if config.isEmoji then
				data.frame.BackgroundColor3 = isSelected and THEME.accent or THEME.card
			else
				local stroke = data.indicator and data.indicator:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Transparency = isSelected and 0 or 1 end
			end
		end
		if config.onSelect then config.onSelect(newIdx) end
	end

	for i, item in ipairs(items) do
		local itemSize = config.itemSize or 28
		local btn = UI.frame({
			size = UDim2.new(0, itemSize, 0, itemSize),
			bg = config.isEmoji and (i == 1 and THEME.accent or THEME.card) or Color3.fromRGB(item[1], item[2], item[3]),
			z = (config.z or 105) + 1, parent = container, corner = config.itemCorner or 6
		})

		local indicator = nil
		if config.isEmoji then
			UI.label({size = UDim2.new(1, 0, 1, 0), text = item, textSize = 16, alignX = Enum.TextXAlignment.Center, z = (config.z or 105) + 2, parent = btn})
		else
			indicator = UI.frame({
				size = UDim2.new(1, -6, 1, -6), pos = UDim2.new(0, 3, 0, 3), bgT = 1,
				z = (config.z or 105) + 2, parent = btn, corner = 4,
				stroke = true, strokeA = i == 1 and 0 or 1, strokeC = Color3.new(1, 1, 1)
			})
		end

		local clickBtn = Instance.new("TextButton")
		clickBtn.Size, clickBtn.BackgroundTransparency, clickBtn.Text = UDim2.new(1, 0, 1, 0), 1, ""
		clickBtn.ZIndex = (config.z or 105) + 3
		clickBtn.Parent = btn

		buttons[i] = {frame = btn, indicator = indicator}
		Memory:track(clickBtn.MouseButton1Click:Connect(function() updateSelection(i) end))
	end

	return container, function() return selectedIdx end
end

local function createNavCard(config)
	local card = UI.frame({
		size = config.size or UDim2.new(1, 0, 0, 60),
		pos = config.pos, bg = THEME.card, z = 104,
		parent = config.parent, corner = 10, stroke = true, strokeA = 0.6
	})

	UI.label({size = UDim2.new(0, 40, 0, 40), pos = UDim2.new(0, 12, 0.5, -20), text = config.icon or "👥", textSize = 22, alignX = Enum.TextXAlignment.Center, z = 105, parent = card})
	UI.label({size = UDim2.new(1, -120, 0, 20), pos = UDim2.new(0, 60, 0, 12), text = config.title or "Título", color = THEME.text, textSize = 14, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 105, parent = card})

	local subtitleLabel = UI.label({name = "Subtitle", size = UDim2.new(1, -120, 0, 16), pos = UDim2.new(0, 60, 0, 32), text = config.subtitle or "", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Left, z = 105, parent = card})
	UI.label({size = UDim2.new(0, 30, 1, 0), pos = UDim2.new(1, -40, 0, 0), text = "›", color = THEME.muted, textSize = 24, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 105, parent = card})

	local notificationDot = nil
	if config.showNotification then
		notificationDot = UI.frame({name = "NotificationDot", size = UDim2.new(0, 10, 0, 10), pos = UDim2.new(1, -50, 0, 10), bg = THEME.btnDanger, z = 106, parent = card, corner = 5})
		notificationDot.Visible = false
	end

	local avatarPreview = nil
	if config.showAvatarPreview then
		avatarPreview = UI.frame({name = "AvatarPreview", size = UDim2.new(0, 70, 0, 28), pos = UDim2.new(1, -115, 0.5, -14), bgT = 1, z = 105, parent = card})
	end

	UI.hover(card, THEME.card, THEME.hover)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size, clickBtn.BackgroundTransparency, clickBtn.Text, clickBtn.ZIndex = UDim2.new(1, 0, 1, 0), 1, "", 107
	clickBtn.Parent = card

	return card, clickBtn, subtitleLabel, notificationDot, avatarPreview
end

local function createViewHeader(parent, title, onBack)
	local header = UI.frame({size = UDim2.new(1, 0, 0, 44), bg = THEME.surface, z = 106, parent = parent, corner = 10})

	local backBtn = UI.button({size = UDim2.new(0, 36, 0, 36), pos = UDim2.new(0, 4, 0.5, -18), bg = THEME.card, text = "‹", color = THEME.text, textSize = 22, font = Enum.Font.GothamBold, z = 107, parent = header, corner = 8})
	UI.hover(backBtn, THEME.card, THEME.accent)
	Memory:track(backBtn.MouseButton1Click:Connect(onBack))

	UI.label({size = UDim2.new(1, -90, 1, 0), pos = UDim2.new(0, 48, 0, 0), text = title, color = THEME.text, textSize = 15, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 107, parent = header})

	return header
end

-- ════════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS
-- ════════════════════════════════════════════════════════════════
local loadPlayerClan, loadClansFromServer, loadAdminClans, createClanEntry, switchTab
local refreshMembersList, refreshPendingList, reloadAndKeepView

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
-- TOPBAR ICON
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
	panelWidth = CONFIG.panel.width,
	panelHeight = CONFIG.panel.height,
	cornerRadius = CONFIG.panel.corner,
	enableBlur = CONFIG.blur.enabled,
	blurSize = CONFIG.blur.size,
	onOpen = function() if clanIcon then clanIcon:select() end end,
	onClose = function() if clanIcon then clanIcon:deselect() end end
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
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 60, 60), TextColor3 = Color3.new(1, 1, 1)}):Play()
end))
Memory:track(closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.card, TextColor3 = THEME.muted}):Play()
end))

-- ════════════════════════════════════════════════════════════════
-- TABS
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
	local btn = UI.button({size = UDim2.new(0, 90, 0, 24), bg = THEME.panel, text = text, color = THEME.muted, textSize = 13, font = Enum.Font.GothamBold, z = 101, parent = tabNav, corner = 0})
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

local underline = UI.frame({size = UDim2.new(0, 90, 0, 3), pos = UDim2.new(0, 20, 0, 93), bg = THEME.accent, z = 102, parent = panel, corner = 2})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({name = "ContentArea", size = UDim2.new(1, -20, 1, -125), pos = UDim2.new(0, 10, 0, 106), bgT = 1, z = 101, parent = panel, corner = 10, clips = true})

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

local clansScroll = setupScroll(pageDisponibles, {size = UDim2.new(1, -20, 1, -56), pos = UDim2.new(0, 10, 0, 52), padding = 8, z = 103})

local searchDebounce = false
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.4, function()
		if State.currentPage == "Disponibles" and State.isOpen then 
			loadClansFromServer(searchInput.Text) 
		end
		searchDebounce = false
	end)
end)

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: CREAR
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

local createCard = UI.frame({size = UDim2.new(1, 0, 0, 600), bg = THEME.card, z = 104, parent = createScroll, corner = 12, stroke = true, strokeA = 0.6})

local createPadding = Instance.new("UIPadding")
createPadding.PaddingTop, createPadding.PaddingBottom = UDim.new(0, 18), UDim.new(0, 18)
createPadding.PaddingLeft, createPadding.PaddingRight = UDim.new(0, 18), UDim.new(0, 18)
createPadding.Parent = createCard

UI.label({size = UDim2.new(1, 0, 0, 20), text = "Crear Nuevo Clan", color = THEME.accent, textSize = 15, font = Enum.Font.GothamBold, z = 105, parent = createCard})

local inputNombre = UI.input("NOMBRE DEL CLAN", "Ej: Guardianes del Fuego", 40, createCard)
local inputTag = UI.input("TAG DEL CLAN (2-5 caracteres)", "Ej: FGT", 106, createCard)
local inputDesc = UI.input("DESCRIPCIÓN", "Describe tu clan...", 172, createCard, true)
local inputLogo = UI.input("LOGO (Asset ID - Opcional)", "rbxassetid://123456789", 258, createCard)

inputTag:GetPropertyChangedSignal("Text"):Connect(function() inputTag.Text = string.upper(inputTag.Text) end)

UI.label({size = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 0, 324), text = "EMOJI DEL CLAN", textSize = 10, font = Enum.Font.GothamBold, z = 105, parent = createCard})
local _, getEmojiIndex = createSelector(CONFIG.emojis, {size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 342), parent = createCard, isEmoji = true, itemSize = 28, spacing = 4, onSelect = function(idx) State.selectedEmoji = idx end})

UI.label({size = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 0, 388), text = "COLOR DEL CLAN", textSize = 10, font = Enum.Font.GothamBold, z = 105, parent = createCard})
local colorItems = {}
for _, c in ipairs(CONFIG.colors) do table.insert(colorItems, c.rgb) end
local _, getColorIndex = createSelector(colorItems, {size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 406), parent = createCard, isEmoji = false, itemSize = 28, spacing = 6, onSelect = function(idx) State.selectedColor = idx end})

local inputOwnerId = UI.input("ID DEL OWNER (Opcional - Solo Admin)", "Ej: 123456789", 452, createCard)

local btnCrear = UI.button({size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 528), bg = THEME.accent, text = "CREAR CLAN", textSize = 13, z = 105, parent = createCard, corner = 8, hover = true})

tabPages["Crear"] = pageCrear

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin, adminClansScroll

if isAdmin then
	pageAdmin = UI.frame({name = "Admin", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
	pageAdmin.LayoutOrder = 4

	local adminHeader = UI.frame({size = UDim2.new(1, -20, 0, 40), pos = UDim2.new(0, 10, 0, 10), bg = THEME.warnMuted, z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = THEME.btnDanger})
	UI.label({size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0), text = "⚠ Panel de Administrador - Acciones irreversibles", color = THEME.warn, textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader})

	adminClansScroll = setupScroll(pageAdmin, {z = 103})
	tabPages["Admin"] = pageAdmin
end

-- ════════════════════════════════════════════════════════════════
-- CREAR VISTA PRINCIPAL
-- ════════════════════════════════════════════════════════════════
local function createMainView(parent, clanData, playerRole)
	local mainView = UI.frame({name = "MainView", size = UDim2.new(1, 0, 1, 0), bgT = 1, z = 103, parent = parent, clips = true})

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size, scrollFrame.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
	scrollFrame.ScrollBarThickness, scrollFrame.ScrollBarImageColor3 = 3, THEME.accent
	scrollFrame.CanvasSize, scrollFrame.ZIndex = UDim2.new(0, 0, 0, 0), 103
	scrollFrame.Parent = mainView

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding, contentLayout.SortOrder = UDim.new(0, 12), Enum.SortOrder.LayoutOrder
	contentLayout.Parent = scrollFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop, contentPadding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	contentPadding.PaddingLeft, contentPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
	contentPadding.Parent = scrollFrame

	local layoutOrder = 0
	local function nextOrder() layoutOrder = layoutOrder + 1 return layoutOrder end

	-- INFO CARD
	local infoCard = UI.frame({size = UDim2.new(1, -8, 0, 160), bg = THEME.card, z = 104, parent = scrollFrame, corner = 12, stroke = true, strokeA = 0.6, clips = true})
	infoCard.LayoutOrder = nextOrder()

	local bannerImage = Instance.new("ImageLabel")
	bannerImage.Size, bannerImage.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
	bannerImage.Image = clanData.clanLogo or ""
	bannerImage.ScaleType, bannerImage.ImageTransparency, bannerImage.ZIndex = Enum.ScaleType.Crop, 0.4, 104
	bannerImage.Parent = infoCard
	UI.rounded(bannerImage, 12)

	local bannerGradient = Instance.new("UIGradient")
	bannerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(0.06, 0.06, 0.08)), ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.12))}
	bannerGradient.Rotation = 90
	bannerGradient.Parent = bannerImage

	local logoFrame = UI.frame({size = UDim2.new(0, 74, 0, 74), pos = UDim2.new(0, 16, 0, 24), bg = THEME.surface, z = 106, parent = infoCard, corner = 37, stroke = true, strokeA = 0.3})

	if clanData.clanLogo and clanData.clanLogo ~= "" and clanData.clanLogo ~= "rbxassetid://0" then
		local logoImg = Instance.new("ImageLabel")
		logoImg.Size, logoImg.Position = UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4)
		logoImg.BackgroundTransparency, logoImg.Image = 1, clanData.clanLogo
		logoImg.ScaleType, logoImg.ZIndex = Enum.ScaleType.Fit, 107
		logoImg.Parent = logoFrame
		UI.rounded(logoImg, 33)
	else
		UI.label({size = UDim2.new(1, 0, 1, 0), text = clanData.clanEmoji or "⚔️", textSize = 36, alignX = Enum.TextXAlignment.Center, z = 107, parent = logoFrame})
	end

	local clanColor = clanData.clanColor and Color3.fromRGB(clanData.clanColor[1] or 255, clanData.clanColor[2] or 255, clanData.clanColor[3] or 255) or THEME.accent
	local membersCount = 0
	if clanData.miembros_data then for _ in pairs(clanData.miembros_data) do membersCount = membersCount + 1 end end

	UI.label({size = UDim2.new(1, -110, 0, 26), pos = UDim2.new(0, 100, 0, 30), text = (clanData.clanEmoji or "") .. " " .. (clanData.clanName or "Clan"), color = clanColor, textSize = 18, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})
	UI.label({size = UDim2.new(0, 80, 0, 20), pos = UDim2.new(0, 100, 0, 56), text = "[" .. (clanData.clanTag or "TAG") .. "]", color = THEME.accent, textSize = 14, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})

	local roleData = ClanSystemConfig.ROLES.Visual[playerRole] or ClanSystemConfig.ROLES.Visual["miembro"]
	UI.label({size = UDim2.new(0, 100, 0, 20), pos = UDim2.new(1, -116, 0, 56), text = roleData.display, color = roleData.color, textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Right, z = 106, parent = infoCard})
	UI.label({size = UDim2.new(1, -32, 0, 36), pos = UDim2.new(0, 16, 0, 108), text = clanData.descripcion or "Sin descripción", color = THEME.muted, textSize = 13, wrap = true, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})

	-- MIEMBROS CARD
	local membersCard, membersBtn, _, _, membersAvatarPreview = createNavCard({size = UDim2.new(1, -8, 0, 60), parent = scrollFrame, icon = "👥", title = "MIEMBROS", subtitle = membersCount .. " miembros en el clan", showAvatarPreview = true})
	membersCard.LayoutOrder = nextOrder()

	if membersAvatarPreview and clanData.miembros_data then
		local avatarLayout = Instance.new("UIListLayout")
		avatarLayout.FillDirection, avatarLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, -8)
		avatarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		avatarLayout.Parent = membersAvatarPreview

		local count = 0
		for odI, _ in pairs(clanData.miembros_data) do
			if count >= 3 then break end
			local odINum = tonumber(odI)
			if odINum and odINum > 0 then
				local miniAvatar = UI.frame({size = UDim2.new(0, 26, 0, 26), bg = THEME.surface, z = 106, parent = membersAvatarPreview, corner = 13})
				local avatarImg = Instance.new("ImageLabel")
				avatarImg.Size, avatarImg.Position = UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2)
				avatarImg.BackgroundTransparency = 1
				avatarImg.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", odINum)
				avatarImg.ZIndex = 107
				avatarImg.Parent = miniAvatar
				UI.rounded(avatarImg, 11)
				count = count + 1
			end
		end
	end

	Memory:track(membersBtn.MouseButton1Click:Connect(function() Navigation:goto("members") end))

	-- SOLICITUDES CARD
	local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")

	if canManageRequests then
		local pendingCard, pendingBtn, pendingSubtitle, pendingDot = createNavCard({size = UDim2.new(1, -8, 0, 60), parent = scrollFrame, icon = "📩", title = "SOLICITUDES", subtitle = "Cargando...", showNotification = true})
		pendingCard.LayoutOrder = nextOrder()

		Memory:track(pendingBtn.MouseButton1Click:Connect(function() Navigation:goto("pending") end))

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

	-- BOTONES DE EDICIÓN
	local permissions = ClanSystemConfig.ROLES.Permissions[playerRole] or {}
	local canEditName, canEditTag = permissions.cambiar_nombre or false, permissions.cambiar_tag or (playerRole == "owner")
	local canChangeColor = permissions.cambiar_color or false

	if canEditName or canEditTag then
		local editRowContainer = UI.frame({size = UDim2.new(1, -8, 0, 42), bgT = 1, z = 104, parent = scrollFrame})
		editRowContainer.LayoutOrder = nextOrder()

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection, rowLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 8)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = editRowContainer

		local buttonCount = (canEditName and 1 or 0) + (canEditTag and 1 or 0)
		local buttonWidth = buttonCount == 2 and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 1, 0)

		if canEditName then
			local btnEditName = UI.button({size = buttonWidth, bg = THEME.surface, text = "EDITAR NOMBRE", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 105, parent = editRowContainer, corner = 10})
			btnEditName.LayoutOrder = 1
			UI.hover(btnEditName, THEME.surface, THEME.stroke)
			Memory:track(btnEditName.MouseButton1Click:Connect(function() ClanActions:editName(screenGui, clanData, loadPlayerClan) end))
		end

		if canEditTag then
			local btnEditTag = UI.button({size = buttonWidth, bg = THEME.surface, text = "EDITAR TAG", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 105, parent = editRowContainer, corner = 10})
			btnEditTag.LayoutOrder = 2
			UI.hover(btnEditTag, THEME.surface, THEME.stroke)
			Memory:track(btnEditTag.MouseButton1Click:Connect(function() ClanActions:editTag(screenGui, clanData, loadPlayerClan) end))
		end
	end

	if canChangeColor then
		local btnEditColor = UI.button({size = UDim2.new(1, -8, 0, 42), bg = THEME.surface, text = "EDITAR COLOR", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 104, parent = scrollFrame, corner = 10})
		btnEditColor.LayoutOrder = nextOrder()
		UI.hover(btnEditColor, THEME.surface, THEME.stroke)
		Memory:track(btnEditColor.MouseButton1Click:Connect(function() ClanActions:editColor(screenGui, loadPlayerClan) end))
	end

	-- BOTÓN SALIR/DISOLVER
	local actionBtnText = playerRole == "owner" and "DISOLVER CLAN" or "SALIR DEL CLAN"
	local actionBtn = UI.button({size = UDim2.new(1, -8, 0, 44), bg = THEME.warn, text = actionBtnText, color = Color3.new(1, 1, 1), textSize = 13, font = Enum.Font.GothamBold, z = 104, parent = scrollFrame, corner = 8})
	actionBtn.LayoutOrder = nextOrder()
	UI.hover(actionBtn, THEME.warn, THEME.btnDanger)

	Memory:track(actionBtn.MouseButton1Click:Connect(function()
		if playerRole == "owner" then
			ClanActions:dissolve(screenGui, clanData.clanName, loadPlayerClan)
		else
			ClanActions:leave(screenGui, loadPlayerClan)
		end
	end))

	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
	end)

	return mainView
end

-- ════════════════════════════════════════════════════════════════
-- CREAR VISTA DE MIEMBROS
-- ════════════════════════════════════════════════════════════════
local function createMembersView(parent, clanData, playerRole)
	local membersView = UI.frame({name = "MembersView", size = UDim2.new(1, 0, 1, 0), pos = UDim2.new(1, 0, 0, 0), bgT = 1, z = 103, parent = parent, clips = true})
	membersView.Visible = false

	createViewHeader(membersView, "👥 MIEMBROS", function() Navigation:goto("main") end)

	local listContainer = UI.frame({name = "MembersListContainer", size = UDim2.new(1, -8, 1, -56), pos = UDim2.new(0, 4, 0, 52), bgT = 1, z = 104, parent = membersView})

	-- Callback cuando se hace una acción (kick, cambio de rol, etc.)
	local function onMembersAction()
		-- Recargar toda la página pero volver a la vista de miembros
		reloadAndKeepView("members")
	end

	State.membersList = MembersList.new({
		parent = listContainer, 
		screenGui = screenGui, 
		mode = "members",
		clanData = clanData, 
		playerRole = playerRole,
		onUpdate = onMembersAction
	})

	return membersView
end

-- ════════════════════════════════════════════════════════════════
-- CREAR VISTA DE PENDIENTES
-- ════════════════════════════════════════════════════════════════
local function createPendingView(parent, clanData, playerRole)
	local pendingView = UI.frame({name = "PendingView", size = UDim2.new(1, 0, 1, 0), pos = UDim2.new(1, 0, 0, 0), bgT = 1, z = 103, parent = parent, clips = true})
	pendingView.Visible = false

	createViewHeader(pendingView, "📩 SOLICITUDES", function() Navigation:goto("main") end)

	local listContainer = UI.frame({name = "PendingListContainer", size = UDim2.new(1, -8, 1, -56), pos = UDim2.new(0, 4, 0, 52), bgT = 1, z = 104, parent = pendingView})

	-- Callback cuando se acepta/rechaza una solicitud
	local function onPendingAction()
		-- Recargar toda la página pero volver a la vista de solicitudes
		reloadAndKeepView("pending")
	end

	-- Cargar inicial
	task.spawn(function()
		local requests = ClanClient:GetJoinRequests(clanData.clanId) or {}

		if not State.isOpen then return end

		State.pendingList = MembersList.new({
			parent = listContainer, 
			screenGui = screenGui, 
			mode = "pending",
			clanData = clanData, 
			playerRole = playerRole, 
			requests = requests,
			onUpdate = onPendingAction
		})
	end)

	return pendingView
end

-- ════════════════════════════════════════════════════════════════
-- LOAD PLAYER CLAN
-- ════════════════════════════════════════════════════════════════
loadPlayerClan = function()
	if not State.isOpen then return end

	-- Limpiar
	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end
	State.views = {}
	State.currentView = "main"

	safeLoading(tuClanContainer, function()
		return ClanClient:GetPlayerClan()
	end, function(clanData)
		if not State.isOpen then return end

		if clanData then
			State.clanData = clanData

			local playerRole = "miembro"
			if clanData.miembros_data and clanData.miembros_data[tostring(player.UserId)] then
				playerRole = clanData.miembros_data[tostring(player.UserId)].rol or "miembro"
			end
			State.playerRole = playerRole

			State.views.main = createMainView(tuClanContainer, clanData, playerRole)
			State.views.members = createMembersView(tuClanContainer, clanData, playerRole)

			local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
			if canManageRequests then
				State.views.pending = createPendingView(tuClanContainer, clanData, playerRole)
			end

			State.views.main.Position = UDim2.new(0, 0, 0, 0)
			State.views.main.Visible = true
		else
			local noClanCard = UI.frame({size = UDim2.new(0, 280, 0, 140), pos = UDim2.new(0.5, -140, 0.5, -70), bg = THEME.card, z = 103, parent = tuClanContainer, corner = 12, stroke = true, strokeA = 0.6})
			UI.label({size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 30), text = "⚔️", textSize = 32, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 75), text = "No perteneces a ningún clan", textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 100), text = "Explora clanes en 'Disponibles'", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- RELOAD AND KEEP VIEW (Recarga todo pero vuelve a la vista actual)
-- ════════════════════════════════════════════════════════════════
reloadAndKeepView = function(targetView)
	if not State.isOpen then return end

	local viewToRestore = targetView or State.currentView

	-- Limpiar
	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end
	State.views = {}
	State.currentView = "main"

	-- Cancelar operaciones previas
	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()
	Memory:destroyChildren(tuClanContainer, "UIListLayout")

	local loadingFrame = UI.loading(tuClanContainer)
	local myId = State.loadingId

	task.spawn(function()
		local success, clanData = pcall(function()
			return ClanClient:GetPlayerClan()
		end)

		-- Verificar validez
		if myId ~= State.loadingId then return end
		if not State.isOpen then return end

		-- Limpiar loading
		UI.cleanupLoading()
		if loadingFrame and loadingFrame.Parent then loadingFrame:Destroy() end
		Memory:destroyChildren(tuClanContainer, "UIListLayout")

		if not success or not clanData then
			-- Usuario ya no tiene clan
			local noClanCard = UI.frame({size = UDim2.new(0, 280, 0, 140), pos = UDim2.new(0.5, -140, 0.5, -70), bg = THEME.card, z = 103, parent = tuClanContainer, corner = 12, stroke = true, strokeA = 0.6})
			UI.label({size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 30), text = "⚔️", textSize = 32, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 75), text = "No perteneces a ningún clan", textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 100), text = "Explora clanes en 'Disponibles'", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			return
		end

		-- Actualizar cache
		State.clanData = clanData

		local playerRole = "miembro"
		if clanData.miembros_data and clanData.miembros_data[tostring(player.UserId)] then
			playerRole = clanData.miembros_data[tostring(player.UserId)].rol or "miembro"
		end
		State.playerRole = playerRole

		-- Recrear vistas
		State.views.main = createMainView(tuClanContainer, clanData, playerRole)
		State.views.members = createMembersView(tuClanContainer, clanData, playerRole)

		local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
		if canManageRequests then
			State.views.pending = createPendingView(tuClanContainer, clanData, playerRole)
		end

		-- Mostrar vista correcta
		for _, v in pairs(State.views) do 
			if v then v.Visible = false end 
		end

		-- Si la vista a restaurar existe, mostrarla
		if viewToRestore ~= "main" and State.views[viewToRestore] then
			State.views[viewToRestore].Position = UDim2.new(0, 0, 0, 0)
			State.views[viewToRestore].Visible = true
			State.currentView = viewToRestore
		else
			State.views.main.Position = UDim2.new(0, 0, 0, 0)
			State.views.main.Visible = true
			State.currentView = "main"
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- CREATE CLAN ENTRY
-- ════════════════════════════════════════════════════════════════
createClanEntry = function(clanData, pendingList)
	local entry = UI.frame({name = "ClanEntry_" .. (clanData.clanId or "unknown"), size = UDim2.new(1, 0, 0, 85), bg = THEME.card, z = 104, parent = clansScroll, corner = 10, stroke = true, strokeA = 0.6})

	local logoContainer = UI.frame({size = UDim2.new(0, 60, 0, 60), pos = UDim2.new(0, 12, 0.5, -30), bgT = 1, z = 105, parent = entry, corner = 10})

	if clanData.clanLogo and clanData.clanLogo ~= "" and clanData.clanLogo ~= "rbxassetid://0" then
		local logo = Instance.new("ImageLabel")
		logo.Size, logo.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
		logo.Image, logo.ScaleType, logo.ZIndex = clanData.clanLogo, Enum.ScaleType.Fit, 106
		logo.Parent = logoContainer
		UI.rounded(logo, 8)
	else
		UI.label({size = UDim2.new(1, 0, 1, 0), text = clanData.clanEmoji or "⚔️", textSize = 30, alignX = Enum.TextXAlignment.Center, z = 106, parent = logoContainer})
	end

	local clanColor = clanData.clanColor and Color3.fromRGB(clanData.clanColor[1] or 255, clanData.clanColor[2] or 255, clanData.clanColor[3] or 255) or THEME.accent

	UI.label({size = UDim2.new(1, -180, 0, 18), pos = UDim2.new(0, 85, 0, 12), text = (clanData.clanEmoji or "") .. " " .. string.upper(clanData.clanName or "CLAN"), color = clanColor, textSize = 14, font = Enum.Font.GothamBold, z = 106, parent = entry})
	UI.label({size = UDim2.new(1, -180, 0, 26), pos = UDim2.new(0, 85, 0, 32), text = clanData.descripcion or "Sin descripción", color = THEME.subtle, textSize = 11, wrap = true, truncate = Enum.TextTruncate.AtEnd, z = 106, parent = entry})
	UI.label({size = UDim2.new(1, -180, 0, 28), pos = UDim2.new(0, 85, 0, 54), text = string.format("%d MIEMBROS [%s]", clanData.miembros_count or 0, clanData.clanTag or "?"), color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 106, parent = entry, alignX = Enum.TextXAlignment.Left})

	local joinBtn = UI.button({size = UDim2.new(0, 75, 0, 30), pos = UDim2.new(1, -87, 0.5, -15), bg = THEME.accent, text = "UNIRSE", textSize = 11, z = 106, parent = entry, corner = 6})

	local isPlayerMember = clanData.isPlayerMember or false
	local isPending = false
	if pendingList then
		for _, req in ipairs(pendingList) do
			if req.clanId == clanData.clanId then isPending = true break end
		end
	end

	if isPlayerMember then
		joinBtn.Text, joinBtn.BackgroundColor3, joinBtn.Active = "MIEMBRO", Color3.fromRGB(60, 100, 60), false
	elseif isPending then
		joinBtn.Text, joinBtn.BackgroundColor3 = "PENDIENTE", Color3.fromRGB(220, 180, 60)
		Memory:track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:CancelAllJoinRequests()
			if success then 
				Notify:Success("Cancelado", msg or "Solicitud cancelada", 5)
				loadClansFromServer() -- Recargar para actualizar estado
			end
		end))
	else
		UI.hover(joinBtn, THEME.accent, UI.brighten(THEME.accent, 1.15))
		Memory:track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:RequestJoinClan(clanData.clanId)
			if success then 
				Notify:Success("Solicitud enviada", msg or "Esperando aprobación", 5)
				loadClansFromServer() -- Recargar para actualizar estado
			else 
				Notify:Error("Error", msg or "No se pudo enviar", 5) 
			end
		end))
	end

	UI.hover(entry, THEME.card, Color3.fromRGB(40, 40, 50))
	return entry
end

-- ════════════════════════════════════════════════════════════════
-- LOAD CLANS FROM SERVER
-- ════════════════════════════════════════════════════════════════
loadClansFromServer = function(filtro)
	if not State.isOpen then return end

	local now = tick()
	if State.isUpdating or (now - State.lastUpdateTime) < CONFIG.cooldown then return end
	State.isUpdating = true
	State.lastUpdateTime = now

	filtro = filtro or ""
	local filtroLower = filtro:lower()

	safeLoading(clansScroll, function()
		return ClanClient:GetClansList(), ClanClient:GetUserPendingRequests()
	end, function(clans, pendingList)
		clans = clans or {}

		if #clans > 0 then
			local hayResultados = false
			for _, clanData in ipairs(clans) do
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

		State.isUpdating = false
	end)
end

-- ════════════════════════════════════════════════════════════════
-- LOAD ADMIN CLANS
-- ════════════════════════════════════════════════════════════════
loadAdminClans = function()
	if not isAdmin or not adminClansScroll then return end
	if not State.isOpen then return end

	local now = tick()
	if State.isUpdating or (now - State.lastUpdateTime) < CONFIG.cooldown then return end
	State.isUpdating = true
	State.lastUpdateTime = now

	safeLoading(adminClansScroll, function()
		return ClanClient:GetClansList()
	end, function(clans)
		if not clans or #clans == 0 then
			UI.label({size = UDim2.new(1, 0, 0, 50), text = "No hay clanes registrados", color = THEME.muted, textSize = 12, alignX = Enum.TextXAlignment.Center, z = 104, parent = adminClansScroll})
			State.isUpdating = false
			return
		end

		for _, clanData in ipairs(clans) do
			local entry = UI.frame({size = UDim2.new(1, 0, 0, 65), bg = THEME.card, z = 104, parent = adminClansScroll, corner = 10, stroke = true, strokeA = 0.6})

			UI.label({size = UDim2.new(1, -160, 0, 18), pos = UDim2.new(0, 15, 0, 12), text = (clanData.clanEmoji or "") .. " " .. (clanData.clanName or "Sin nombre"), color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 105, parent = entry})
			UI.label({size = UDim2.new(1, -160, 0, 14), pos = UDim2.new(0, 15, 0, 34), text = "ID: " .. (clanData.clanId or "?") .. " • " .. (clanData.miembros_count or 0) .. " miembros", color = THEME.muted, textSize = 10, z = 105, parent = entry})

			local deleteBtn = UI.button({size = UDim2.new(0, 70, 0, 32), pos = UDim2.new(1, -80, 0.5, -16), bg = Color3.fromRGB(160, 50, 50), text = "Eliminar", textSize = 10, z = 105, parent = entry, corner = 6, hover = true, hoverBg = Color3.fromRGB(200, 70, 70)})
			UI.hover(entry, THEME.card, Color3.fromRGB(40, 40, 50))

			Memory:track(deleteBtn.MouseButton1Click:Connect(function()
				ClanActions:adminDelete(screenGui, clanData, loadAdminClans)
			end))
		end

		State.isUpdating = false
	end)
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
local tabPositions = isAdmin and { TuClan = 20, Disponibles = 122, Crear = 224, Admin = 326 } or { TuClan = 20, Disponibles = 122 }

switchTab = function(tabName, forceLoad)
	-- Si ya estamos en la tab y no forzamos carga, no hacer nada
	if State.currentPage == tabName and not forceLoad then return end

	-- Cancelar operaciones async
	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()

	State.currentPage = tabName
	State.currentView = "main"
	State.isUpdating = false -- Reset para permitir carga

	-- Actualizar estilo de tabs
	for name, btn in pairs(tabButtons) do
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = (name == tabName) and THEME.accent or THEME.muted}):Play()
	end

	TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, tabPositions[tabName] or 20, 0, 93)}):Play()

	-- Cambiar página
	local pageFrame = contentArea:FindFirstChild(tabName)
	if pageFrame then pageLayout:JumpTo(pageFrame) end

	-- Cargar contenido
	task.delay(0.05, function()
		if State.currentPage ~= tabName then return end
		if not State.isOpen then return end

		if tabName == "TuClan" then 
			loadPlayerClan()
		elseif tabName == "Disponibles" then 
			loadClansFromServer()
		elseif tabName == "Admin" and isAdmin then 
			loadAdminClans() 
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
	State.isOpen = true
	State.currentPage = nil -- IMPORTANTE: Reset para que switchTab funcione

	modal:open()

	if not ClanClient.initialized then 
		task.spawn(function() ClanClient:Initialize() end) 
	end

	-- Ir a la primera tab (forzar carga)
	switchTab("TuClan", true)
end

local function closeUI()
	State.isOpen = false

	-- Cancelar operaciones
	State.loadingId = State.loadingId + 1

	-- Limpiar
	Memory:cleanup()
	UI.cleanupLoading()

	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end

	-- Reset estado
	State.views = {}
	State.currentView = "main"
	State.currentPage = nil
	State.clanData = nil
	State.playerRole = nil
	State.isUpdating = false

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
	local clanEmoji = CONFIG.emojis[State.selectedEmoji] or "⚔️"
	local clanColor = CONFIG.colors[State.selectedColor].rgb
	local customOwnerId = inputOwnerId.Text ~= "" and tonumber(inputOwnerId.Text) or nil

	if not Validator:validateClanCreation(clanName, clanTag, inputOwnerId.Text) then return end

	btnCrear.Text = "Creando..."

	local success, clanId, msg = ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc, customOwnerId, clanEmoji, clanColor)

	if success then
		Notify:Success("Clan Creado", msg or "Clan creado exitosamente", 5)
		inputNombre.Text, inputTag.Text, inputDesc.Text, inputLogo.Text, inputOwnerId.Text = "", "", "", "", ""
		task.delay(0.5, function() switchTab("TuClan", true) end)
	else
		Notify:Error("Error", msg or "No se pudo crear el clan", 5)
	end

	btnCrear.Text = "CREAR CLAN"
end)

-- ════════════════════════════════════════════════════════════════
-- ICON BINDING
-- ════════════════════════════════════════════════════════════════
if clanIcon then
	clanIcon:bindEvent("selected", openUI)
	clanIcon:bindEvent("deselected", closeUI)
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER DEL SERVIDOR (Con control estricto)
-- ════════════════════════════════════════════════════════════════
local listenerLastTime = 0

ClanClient.onClansUpdated = function(clans)
	-- Ignorar si UI no está abierta
	if not State.isOpen then return end
	if not screenGui or not screenGui.Parent then return end

	-- Cooldown estricto para evitar spam del servidor
	local now = tick()
	if (now - listenerLastTime) < CONFIG.listenerCooldown then 
		return 
	end
	listenerLastTime = now

	-- Solo actualizar la página actual si ya terminó de cargar
	if State.isUpdating then return end

	-- Actualizar según la página actual
	if State.currentPage == "Disponibles" then 
		task.defer(loadClansFromServer)
	elseif State.currentPage == "Admin" and isAdmin then 
		task.defer(loadAdminClans)
	end
	-- NO actualizar TuClan automáticamente para evitar perder el estado de la vista
end

-- Pre-cargar datos del cliente (sin abrir UI)
task.spawn(function() 
	ClanClient:Initialize()
end)