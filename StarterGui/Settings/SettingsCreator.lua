--[[
	SETTINGS CREATOR - Constructor de UI puro (sin instancias)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ThemeConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local SettingsConfig = require(script.Parent:WaitForChild("SettingsConfig"))

local SettingsCreator = {}
local settingsState = {}

-- ============================================
-- CREAR SETTING ITEM (Toggle/Info)
-- ============================================
local function createSettingItem(parent, setting, THEME)
	local container = UI.frame({
		size = UDim2.new(1, -16, 0, 70),
		bg = THEME.surface,
		z = 104,
		parent = parent,
		corner = 8,
		stroke = true,
		strokeA = 0.3
	})
	
	-- Texto
	local textContainer = UI.frame({
		size = UDim2.new(0.7, -8, 1, 0),
		pos = UDim2.new(0, 8, 0, 0),
		bgT = 1,
		z = 105,
		parent = container
	})
	
	UI.label({
		size = UDim2.new(1, 0, 0, 28),
		pos = UDim2.new(0, 0, 0, 10),
		text = setting.label,
		color = THEME.text,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 106,
		parent = textContainer
	})
	
	UI.label({
		size = UDim2.new(1, 0, 0, 20),
		pos = UDim2.new(0, 0, 0, 38),
		text = setting.desc or "",
		color = THEME.muted,
		textSize = 12,
		alignX = Enum.TextXAlignment.Left,
		z = 106,
		parent = textContainer
	})
	
	-- Toggle
	if setting.type == "toggle" then
		-- Crear toggle como Frame (sin texto "Button")
		local toggleBtn = UI.frame({
			size = UDim2.new(0, 44, 0, 28),
			pos = UDim2.new(1, -52, 0, 21),
			bg = THEME.card,
			z = 105,
			parent = container,
			corner = 14,
			stroke = true,
			strokeA = 0.4
		})
		
		local isActive = settingsState[setting.id] or setting.default or false
		local circle = Instance.new("Frame")
		circle.Name = "Circle"
		circle.Size = UDim2.new(0, 24, 0, 24)
		circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circle.BorderSizePixel = 0
		circle.ZIndex = 106
		circle.Parent = toggleBtn
		
		local cornerCircle = Instance.new("UICorner")
		cornerCircle.CornerRadius = UDim.new(0, 10)
		cornerCircle.Parent = circle
		
		-- Detector de clicks (transparente)
		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.fromScale(1, 1)
		clickDetector.BackgroundTransparency = 1
		clickDetector.TextTransparency = 1
		clickDetector.ZIndex = 107
		clickDetector.Parent = toggleBtn
		
		local function updateToggle(active)
			settingsState[setting.id] = active
			
			local bgColor = active and THEME.accent or THEME.card
			
			TweenService:Create(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = bgColor}):Play()
			
			local circlePos = active and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
			TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = circlePos}):Play()
			
			-- Ejecutar acción sin pcall para ver errores
			if setting.action then
				setting.action(active)
			end
		end
		
		updateToggle(isActive)
		
		clickDetector.MouseButton1Click:Connect(function()
			local newState = not settingsState[setting.id]
			updateToggle(newState)
		end)
	end
	
	return container
end

-- ============================================
-- CREAR MODAL PRINCIPAL
-- ============================================
function SettingsCreator.CreateSettingsModal(panel, THEME)
	-- Reset state
	settingsState = {}
	for k, v in pairs(SettingsConfig.DEFAULTS) do
		settingsState[k] = v
	end
	
	-- ════════════════════════════════════════════════════════════════
	-- HEADER (igual a Clan)
	-- ════════════════════════════════════════════════════════════════
	local header = UI.frame({name = "Header", size = UDim2.new(1, 0, 0, 60), bg = THEME.head, z = 101, parent = panel, corner = 12})
	
	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.panel), ColorSequenceKeypoint.new(1, THEME.card)}
	headerGradient.Rotation = 90
	headerGradient.Parent = header
	
	UI.label({size = UDim2.new(1, -100, 0, 60), pos = UDim2.new(0, 20, 0, 0), text = "AJUSTES", textSize = 20, font = Enum.Font.GothamBold, z = 102, parent = header, color = THEME.text})
	
	-- ════════════════════════════════════════════════════════════════
	-- TAB NAVIGATION (igual a Clan)
	-- ════════════════════════════════════════════════════════════════
	local tabNav = UI.frame({size = UDim2.new(1, 0, 0, 36), pos = UDim2.new(0, 0, 0, 60), bgT = 1, z = 101, parent = panel})
	
	local navList = Instance.new("UIListLayout")
	navList.FillDirection = Enum.FillDirection.Horizontal
	navList.Padding = UDim.new(0, 8)
	navList.Parent = tabNav
	
	local navPadding = Instance.new("UIPadding")
	navPadding.PaddingLeft = UDim.new(0, 12)
	navPadding.PaddingTop = UDim.new(0, 6)
	navPadding.Parent = tabNav
	
	local tabButtons = {}
	local State = {currentTab = "gameplay"}
	
	-- ════════════════════════════════════════════════════════════════
	-- CONTENT AREA (igual a Clan)
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
	-- UNDERLINE (igual a Clan)
	-- ════════════════════════════════════════════════════════════════
	local underline = UI.frame({size = UDim2.new(0, 90, 0, 3), pos = UDim2.new(0, 12, 0, 93), bg = THEME.accent, z = 102, parent = panel, corner = 2})
	
	-- ════════════════════════════════════════════════════════════════
	-- CREAR TABS Y PÁGINAS
	-- ════════════════════════════════════════════════════════════════
	for tabIndex, tab in ipairs(SettingsConfig.TABS) do
		-- Button en tabNav
		local btn = UI.button({size = UDim2.new(0, 90, 0, 24), bg = THEME.panel, text = tab.title, color = THEME.muted, textSize = 12, font = Enum.Font.GothamBold, z = 101, parent = tabNav, corner = 0})
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		tabButtons[tab.id] = btn
		
		-- Page en contentArea
		local page = UI.frame({name = tab.id, size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
		page.LayoutOrder = tabIndex
		
		-- Scroll frame (sin scrollbar tradicional, como EmoteUI)
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "Scroll"
		scrollFrame.Size = UDim2.new(1, 0, 1, 0)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 0
		scrollFrame.ScrollBarImageTransparency = 1
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollFrame.Parent = page
		
		-- Scrollbar custom moderno (lado derecho)
		local scrollbarContainer = Instance.new("Frame")
		scrollbarContainer.Name = "ScrollbarContainer"
		scrollbarContainer.Size = UDim2.new(0, 4, 1, 0)
		scrollbarContainer.Position = UDim2.new(1, -4, 0, 0)
		scrollbarContainer.BackgroundTransparency = 1
		scrollbarContainer.ZIndex = 105
		scrollbarContainer.Parent = page
		
		local scrollbarTrack = Instance.new("Frame")
		scrollbarTrack.Name = "Track"
		scrollbarTrack.Size = UDim2.new(1, 0, 1, 0)
		scrollbarTrack.BackgroundColor3 = THEME.stroke
		scrollbarTrack.BackgroundTransparency = THEME.heavyAlpha
		scrollbarTrack.BorderSizePixel = 0
		scrollbarTrack.Parent = scrollbarContainer
		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(0, 2)
		trackCorner.Parent = scrollbarTrack
		
		local scrollbarThumb = Instance.new("Frame")
		scrollbarThumb.Name = "Thumb"
		scrollbarThumb.Size = UDim2.new(1, 0, 0.3, 0)
		scrollbarThumb.Position = UDim2.new(0, 0, 0, 0)
		scrollbarThumb.BackgroundColor3 = THEME.accent
		scrollbarThumb.BackgroundTransparency = THEME.mediumAlpha
		scrollbarThumb.BorderSizePixel = 0
		scrollbarThumb.ZIndex = 106
		scrollbarThumb.Parent = scrollbarContainer
		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(0, 2)
		thumbCorner.Parent = scrollbarThumb
		
		-- Actualizar scrollbar dinámicamente
		local function updateScrollbar()
			local canvasSize = scrollFrame.AbsoluteCanvasSize.Y
			local windowSize = scrollFrame.AbsoluteWindowSize.Y
			
			if canvasSize <= windowSize then
				scrollbarContainer.Visible = false
				return
			else
				scrollbarContainer.Visible = true
			end
			
			local scrollPercent = scrollFrame.CanvasPosition.Y / (canvasSize - windowSize)
			local thumbHeight = math.max(0.1, windowSize / canvasSize)
			local maxThumbY = 1 - thumbHeight
			
			scrollbarThumb.Size = UDim2.new(1, 0, thumbHeight, 0)
			scrollbarThumb.Position = UDim2.new(0, 0, scrollPercent * maxThumbY, 0)
		end
		
		scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollbar)
		scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollbar)
		scrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollbar)
		
		-- Hover en scrollbar
		scrollbarThumb.MouseEnter:Connect(function()
			TweenService:Create(scrollbarThumb, TweenInfo.new(0.15), {BackgroundTransparency = THEME.subtleAlpha}):Play()
		end)
		scrollbarThumb.MouseLeave:Connect(function()
			TweenService:Create(scrollbarThumb, TweenInfo.new(0.15), {BackgroundTransparency = THEME.mediumAlpha}):Play()
		end)
		
		-- Layout sin padding extra
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = scrollFrame
		
		-- Agregar settings a la página
		for settingIndex, setting in ipairs(SettingsConfig.SETTINGS[tab.id] or {}) do
			createSettingItem(scrollFrame, setting, THEME)
		end
	end
	
	-- ════════════════════════════════════════════════════════════════
	-- FUNCIÓN SWITCH TAB (patrón Clan)
	-- ════════════════════════════════════════════════════════════════
	local tabPositions = {gameplay = 12, graphics = 110, alerts = 208, credits = 306, comments = 404}
	
	local function switchTab(tabId)
		if State.currentTab == tabId then return end
		
		State.currentTab = tabId
		
		-- Actualizar colores de botones
		for id, btn in pairs(tabButtons) do
			TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = (id == tabId) and THEME.accent or THEME.muted}):Play()
		end
		
		-- Animar underline
		if tabPositions[tabId] then
			TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, tabPositions[tabId], 0, 93)}):Play()
		end
		
		-- Cambiar página
		local pageFrame = contentArea:FindFirstChild(tabId)
		if pageFrame then
			pageLayout:JumpTo(pageFrame)
		end
	end
	
	-- Conectar botones a switchTab
	for tabId, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			switchTab(tabId)
		end)
		UI.hover(btn, THEME.panel, THEME.elevated)
	end
	
	-- Seleccionar primer tab por defecto
	switchTab("gameplay")
end

return SettingsCreator
