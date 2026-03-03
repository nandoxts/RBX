--[[
	SETTINGS CREATOR - v5
	Rediseño completo: Sidebar vertical + estilo DJ Dashboard
	ModernScrollbar en sidebar y contenido
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI             = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ThemeConfig    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local SidebarNav     = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SidebarNav"))
local SettingsConfig = require(script.Parent:WaitForChild("SettingsConfig"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local SettingsCreator = {}
local settingsState = {}

-- Constantes de layout
local CARD_GAP  = 8

-- ════════════════════════════════════════════════════════════════
-- CREAR SETTING ITEM (Toggle o Credit)
-- ════════════════════════════════════════════════════════════════
local function createSettingItem(parent, setting, THEME)
	local itemHeight = setting.type == "credit" and 54 or 72

	local container = UI.frame({
		size    = UDim2.new(1, 0, 0, itemHeight),
		bg      = THEME.card,
		bgT     = 0,
		z       = 104,
		parent  = parent,
		corner  = 10,
		stroke  = true,
		strokeA = 0.5,
		strokeC = THEME.stroke,
	})

	local textContainer = UI.frame({
		size   = UDim2.new(1, -20, 1, 0),
		pos    = UDim2.new(0, 12, 0, 0),
		bgT    = 1,
		z      = 105,
		parent = container,
	})

	if setting.type == "credit" then
		UI.label({
			size     = UDim2.new(1, 0, 0, 18),
			pos      = UDim2.new(0, 0, 0, 6),
			text     = setting.label,
			color    = THEME.accent,
			textSize = 13,
			font     = Enum.Font.GothamBold,
			alignX   = Enum.TextXAlignment.Center,
			z        = 106,
			parent   = textContainer,
		})
		UI.label({
			size     = UDim2.new(1, 0, 1, -26),
			pos      = UDim2.new(0, 0, 0, 26),
			text     = setting.desc or "",
			color    = THEME.muted,
			textSize = 11,
			alignX   = Enum.TextXAlignment.Center,
			z        = 106,
			parent   = textContainer,
		})
	else
		UI.label({
			size     = UDim2.new(1, -60, 0, 26),
			pos      = UDim2.new(0, 0, 0, 10),
			text     = setting.label,
			color    = THEME.text,
			textSize = 14,
			font     = Enum.Font.GothamBold,
			alignX   = Enum.TextXAlignment.Left,
			z        = 106,
			parent   = textContainer,
		})
		UI.label({
			size     = UDim2.new(1, -60, 0, 20),
			pos      = UDim2.new(0, 0, 0, 38),
			text     = setting.desc or "",
			color    = THEME.muted,
			textSize = 11,
			font     = Enum.Font.Gotham,
			alignX   = Enum.TextXAlignment.Left,
			z        = 106,
			parent   = textContainer,
		})
	end

	if setting.type == "toggle" then
		local toggleBtn = UI.frame({
			size    = UDim2.new(0, 44, 0, 24),
			pos     = UDim2.new(1, -54, 0.5, -12),
			bg      = THEME.card,
			z       = 105,
			parent  = container,
			corner  = 12,
			stroke  = true,
			strokeA = 0.35,
			strokeC = THEME.stroke,
		})

		local isActive = settingsState[setting.id]
		if isActive == nil then isActive = setting.default or false end

		local circle = Instance.new("Frame")
		circle.Name = "Circle"
		circle.Size = UDim2.new(0, 20, 0, 20)
		circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circle.BorderSizePixel = 0
		circle.ZIndex = 106
		circle.Parent = toggleBtn
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 10)
		cc.Parent = circle

		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.fromScale(1, 1)
		clickDetector.BackgroundTransparency = 1
		clickDetector.TextTransparency = 1
		clickDetector.ZIndex = 107
		clickDetector.Parent = toggleBtn

		local function updateToggle(active)
			settingsState[setting.id] = active
			TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = active and THEME.accent or THEME.card,
			}):Play()
			local cPos = active and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
			TweenService:Create(circle, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = cPos,
			}):Play()
			if setting.action then setting.action(active) end
		end

		updateToggle(isActive)
		clickDetector.MouseButton1Click:Connect(function()
			updateToggle(not settingsState[setting.id])
		end)
	end

	UI.hover(container, THEME.card, THEME.elevated)
	return container
end

-- ============================================
-- CREDITS PAGE
-- ============================================
local function createCreditsPage(container, THEME)
	local creditsList = SettingsConfig.SETTINGS["credits"] or {}
	local Players = game:GetService("Players")

	-- Wrapper principal
	local creditsCover = UI.frame({
		name = "CreditsCover",
		size = UDim2.new(1, 0, 1, 0),
		bgT = 1,
		z = 103,
		parent = container,
		clips = true
	})

	-- ScrollingFrame para créditos (responsive)
	local creditsScroll = Instance.new("ScrollingFrame")
	creditsScroll.Name = "CreditsScroll"
	creditsScroll.Size = UDim2.fromScale(1, 1)
	creditsScroll.Position = UDim2.fromScale(0, 0)
	creditsScroll.BackgroundTransparency = 1
	creditsScroll.BorderSizePixel = 0
	creditsScroll.ScrollBarThickness = 0
	creditsScroll.ScrollBarImageTransparency = 1
	creditsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	creditsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	creditsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	creditsScroll.ZIndex = 103
	creditsScroll.Parent = creditsCover

	-- Inner container dentro del scroll
	local innerWrap = UI.frame({
		name = "InnerWrap",
		size = UDim2.new(1, -40, 0, 0),
		pos = UDim2.new(0.5, 0, 0, 20),
		bgT = 1,
		z = 104,
		parent = creditsScroll
	})
	innerWrap.AnchorPoint = Vector2.new(0.5, 0)
	innerWrap.AutomaticSize = Enum.AutomaticSize.Y

	local innerLayout = Instance.new("UIListLayout")
	innerLayout.FillDirection = Enum.FillDirection.Vertical
	innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Padding = UDim.new(0, 14)
	innerLayout.Parent = innerWrap

	-- ── Línea decorativa superior ──
	local topLine = UI.frame({
		size = UDim2.new(0.25, 0, 0, 2),
		bg = THEME.accent,
		z = 105,
		parent = innerWrap,
		corner = 1
	})
	topLine.BackgroundTransparency = 0.5
	topLine.LayoutOrder = 1

	-- ── Título principal ──
	if creditsList[1] then
		local titleLabel = UI.label({
			size = UDim2.new(1, 0, 0, 36),
			text = creditsList[1].label,
			color = THEME.accent,
			textSize = 28,
			font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Center,
			z = 105,
			parent = innerWrap
		})
		titleLabel.LayoutOrder = 2
	end

	-- ── Línea separadora bajo título ──
	local divider = UI.frame({
		size = UDim2.new(0.12, 0, 0, 2),
		bg = THEME.accent,
		z = 105,
		parent = innerWrap,
		corner = 1
	})
	divider.BackgroundTransparency = 0.4
	divider.LayoutOrder = 3

	-- ── Párrafo principal ──
	if creditsList[2] then
		local paragraphLabel = UI.label({
			size = UDim2.new(1, 0, 0, 0),
			text = creditsList[2].label,
			color = THEME.text,
			textSize = 16,
			font = Enum.Font.Gotham,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Top,
			z = 105,
			parent = innerWrap,
			wrappedText = true
		})
		paragraphLabel.AutomaticSize = Enum.AutomaticSize.Y
		paragraphLabel.TextWrapped = true
		paragraphLabel.RichText = true
		paragraphLabel.LayoutOrder = 4
	end

	-- ══════════════════════════════════════════════════════════
	-- SECCIÓN CONTRIBUIDORES
	-- ══════════════════════════════════════════════════════════
	local devs = {}

	if SettingsConfig.CONTRIBUTORS and type(SettingsConfig.CONTRIBUTORS) == "table" then
		for _, entry in ipairs(SettingsConfig.CONTRIBUTORS) do
			if type(entry) == "table" then
				table.insert(devs, {
					name = tostring(entry.name or ""),
					role = tostring(entry.role or "Developer")
				})
			end
		end
	end

	if #devs > 0 then
		local sectionLabel = UI.label({
			size = UDim2.new(1, 0, 0, 20),
			text = "CONTRIBUIDORES",
			color = THEME.accent,
			textSize = 12,
			font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Center,
			z = 105,
			parent = innerWrap
		})
		sectionLabel.LayoutOrder = 5

		local devsGrid = UI.frame({
			name = "DevsGrid",
			size = UDim2.new(1, 0, 0, 0),
			bgT = 1,
			z = 105,
			parent = innerWrap
		})
		devsGrid.AutomaticSize = Enum.AutomaticSize.Y
		devsGrid.LayoutOrder = 6

		local gridLayout = Instance.new("UIListLayout")
		gridLayout.FillDirection = Enum.FillDirection.Vertical
		gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Padding = UDim.new(0, 8)
		gridLayout.Parent = devsGrid

		for idx, dev in ipairs(devs) do
			local AVATAR_SIZE = 44
			local devCard = UI.frame({
				size    = UDim2.new(1, 0, 0, 66),
				bg      = THEME.card,
				bgT     = 0,
				z       = 106,
				parent  = devsGrid,
				corner  = 12,
				stroke  = true,
				strokeA = 0.5,
				strokeC = THEME.stroke,
			})
			devCard.LayoutOrder = idx

			local accentBar = UI.frame({
				size   = UDim2.new(0, 3, 0.5, 0),
				pos    = UDim2.new(0, 0, 0.25, 0),
				bg     = THEME.accent,
				z      = 107,
				parent = devCard,
				corner = 2,
			})

			local avatarRing = UI.frame({
				size   = UDim2.new(0, AVATAR_SIZE + 4, 0, AVATAR_SIZE + 4),
				pos    = UDim2.new(0, 12, 0.5, 0),
				bg     = THEME.accent,
				z      = 107,
				parent = devCard,
				corner = (AVATAR_SIZE + 4) / 2,
			})
			avatarRing.AnchorPoint = Vector2.new(0, 0.5)
			avatarRing.BackgroundTransparency = 0.6

			local avatarWrapper = UI.frame({
				size   = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE),
				pos    = UDim2.new(0.5, 0, 0.5, 0),
				bg     = THEME.surface,
				z      = 108,
				parent = avatarRing,
				corner = AVATAR_SIZE / 2,
			})
			avatarWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
			avatarWrapper.ClipsDescendants = true

			local success, userId = pcall(function()
				return Players:GetUserIdFromNameAsync(dev.name)
			end)
			userId = (success and userId) and userId or 0

			local avatarImg = Instance.new("ImageLabel")
			avatarImg.Size = UDim2.fromScale(1, 1)
			avatarImg.Position = UDim2.new(0, 0, 0, 0)
			avatarImg.BackgroundTransparency = 1
			avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
			avatarImg.ZIndex = 109
			avatarImg.ScaleType = Enum.ScaleType.Crop
			avatarImg.Parent = avatarWrapper
			local ac = Instance.new("UICorner")
			ac.CornerRadius = UDim.new(0, AVATAR_SIZE / 2)
			ac.Parent = avatarImg

			local TEXT_LEFT = 12 + (AVATAR_SIZE + 4) + 12
			local nameLabel = UI.label({
				size     = UDim2.new(1, -(TEXT_LEFT + 20), 0, 22),
				pos      = UDim2.new(0, TEXT_LEFT, 0, 11),
				text     = dev.name,
				color    = THEME.text,
				textSize = 14,
				font     = Enum.Font.GothamBold,
				alignX   = Enum.TextXAlignment.Left,
				z        = 108,
				parent   = devCard,
			})
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

			UI.label({
				size     = UDim2.new(1, -(TEXT_LEFT + 20), 0, 16),
				pos      = UDim2.new(0, TEXT_LEFT, 0, 35),
				text     = dev.role,
				color    = THEME.accent,
				textSize = 11,
				font     = Enum.Font.GothamMedium,
				alignX   = Enum.TextXAlignment.Left,
				z        = 108,
				parent   = devCard,
			})

			UI.hover(devCard, THEME.card, THEME.elevated)
		end
	end

	-- ── Línea decorativa inferior ──
	local bottomLine = UI.frame({
		size = UDim2.new(0.15, 0, 0, 1),
		bg = THEME.muted,
		z = 105,
		parent = innerWrap,
		corner = 1
	})
	bottomLine.BackgroundTransparency = 0.7
	bottomLine.LayoutOrder = 7
end

-- ════════════════════════════════════════════════════════════════
-- CREAR MODAL PRINCIPAL
-- ════════════════════════════════════════════════════════════════
function SettingsCreator.CreateSettingsModal(panel, THEME)
	-- Reset state
	settingsState = {}
	for k, v in pairs(SettingsConfig.DEFAULTS) do
		settingsState[k] = v
	end

	-- Limpiar anteriores
	for _, child in ipairs(panel:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIGradient") then
			if child.Name ~= "CloseBtn" then
				child:Destroy()
			end
		end
	end

	-- ════════════════════════════════════════════════════════════════
	-- ÁREA PRINCIPAL (full size — igual que GamepassShop CONTAINER)
	-- ════════════════════════════════════════════════════════════════
	local isMobile  = UserInputService.TouchEnabled
	local SIDEBAR_W = isMobile and 100 or 130
	local HEADER_H  = 52

	local mainArea = UI.frame({
		name   = "MainArea",
		size   = UDim2.new(1, 0, 1, 0),
		bgT    = 1,
		z      = 101,
		parent = panel,  -- panel aquí es CONTAINER (getCanvas)
		clips  = true,
	})

	-- ════════════════════════════════════════════════════════════════
	-- SIDEBAR (SidebarNav component — igual que GamepassShop)
	-- ════════════════════════════════════════════════════════════════
	local TAB_IMAGES = {
		gameplay = "76721656269888",
		graphics = "91877799240345",
		alerts   = "128637341143304",
		credits  = "129517460766852",
	}
	local sidebarItems = {}
	for _, tab in ipairs(SettingsConfig.TABS) do
		table.insert(sidebarItems, {
			id    = tab.id,
			label = tab.title,
			image = TAB_IMAGES[tab.id] or "79346090571461",
		})
	end

	local switchTab  -- forward-declare (se asigna más abajo)

	local nav = SidebarNav.new({
		parent   = mainArea,
		UI       = UI,
		THEME    = THEME,
		title    = "SETTINGS",
		items    = sidebarItems,
		width    = SIDEBAR_W,
		isMobile = UserInputService.TouchEnabled,
		onSelect = function(id) switchTab(id) end,
	})

	-- ════════════════════════════════════════════════════════════════
	-- ÁREA DE CONTENIDO (igual que GamepassShop)
	-- ════════════════════════════════════════════════════════════════
	local contentArea = UI.frame({
		name   = "ContentArea",
		size   = UDim2.new(1, -SIDEBAR_W, 1, 0),
		pos    = UDim2.new(0, SIDEBAR_W, 0, 0),
		bgT    = 1,
		z      = 100,
		parent = mainArea,
		clips  = true,
	})

	-- Header de contenido (igual que GamepassShop contentHeader)
	local contentHeader = UI.frame({
		name = "ContentHeader",
		size = UDim2.new(1, 0, 0, HEADER_H),
		bg   = THEME.deep, bgT = THEME.lightAlpha, z = 150,
		parent = contentArea,
	})

	local contentTitle = UI.label({
		name     = "Title",
		size     = UDim2.new(1, -60, 0, HEADER_H),
		pos      = UDim2.new(0, 18, 0, 0),
		text     = "",
		color    = THEME.text,
		font     = Enum.Font.GothamBlack, textSize = 20,
		alignX   = Enum.TextXAlignment.Left,
		z        = 152, parent = contentHeader,
	})

	local headerLine = Instance.new("Frame")
	headerLine.Size                   = UDim2.new(1, -20, 0, 1)
	headerLine.Position               = UDim2.new(0, 10, 1, -1)
	headerLine.BackgroundColor3       = THEME.stroke
	headerLine.BackgroundTransparency = THEME.mediumAlpha
	headerLine.BorderSizePixel        = 0
	headerLine.ZIndex                 = 152
	headerLine.Parent                 = contentHeader

	-- Wrapper de páginas (debajo del header)
	local pagesArea = UI.frame({
		name   = "PagesArea",
		size   = UDim2.new(1, 0, 1, -HEADER_H),
		pos    = UDim2.new(0, 0, 0, HEADER_H),
		bgT    = 1,
		z      = 101,
		parent = contentArea,
		clips  = true,
	})

	-- UIPageLayout con animación igual que el clan
	local pageLayout = Instance.new("UIPageLayout")
	pageLayout.FillDirection           = Enum.FillDirection.Vertical
	pageLayout.SortOrder               = Enum.SortOrder.LayoutOrder
	pageLayout.HorizontalAlignment     = Enum.HorizontalAlignment.Center
	pageLayout.EasingStyle             = Enum.EasingStyle.Sine
	pageLayout.EasingDirection         = Enum.EasingDirection.InOut
	pageLayout.TweenTime               = 0.35
	pageLayout.ScrollWheelInputEnabled = false
	pageLayout.TouchInputEnabled       = false
	pageLayout.Parent                  = pagesArea

	-- ════════════════════════════════════════════════════════════════
	-- CREAR TABS
	-- ════════════════════════════════════════════════════════════════
	local tabPages = {}
	local State    = { currentTab = "" }

	for tabIndex, tab in ipairs(SettingsConfig.TABS) do
		-- Página de contenido
		local page = UI.frame({
			name   = tab.id,
			size   = UDim2.fromScale(1, 1),
			bgT    = 1,
			z      = 103,
			parent = pagesArea,
			clips  = true,
		})
		page.LayoutOrder = tabIndex
		tabPages[tab.id] = page

		if tab.id == "credits" then
			createCreditsPage(page, THEME)
		else
			local settingsList = SettingsConfig.SETTINGS[tab.id] or {}

			local scrollFrame = Instance.new("ScrollingFrame")
			scrollFrame.Name = "Scroll"
			scrollFrame.Size = UDim2.new(1, 0, 1, 0)
			scrollFrame.BackgroundTransparency = 1
			scrollFrame.BorderSizePixel = 0
			scrollFrame.ScrollBarThickness = 0
			scrollFrame.ScrollBarImageTransparency = 1
			scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			scrollFrame.ZIndex = 104
			scrollFrame.Parent = page
			ModernScrollbar.setup(scrollFrame, page, THEME, {transparency = 0})

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, CARD_GAP)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = scrollFrame

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft   = UDim.new(0, 4)
			pad.PaddingRight  = UDim.new(0, 10)
			pad.PaddingTop    = UDim.new(0, 8)
			pad.PaddingBottom = UDim.new(0, 8)
			pad.Parent = scrollFrame

			for _, setting in ipairs(settingsList) do
				createSettingItem(scrollFrame, setting, THEME)
			end
		end
	end

	-- ════════════════════════════════════════════════════════════════
	-- SWITCH TAB
	-- ════════════════════════════════════════════════════════════════
	switchTab = function(tabId)
		if State.currentTab == tabId then return end
		State.currentTab = tabId
		nav:selectItem(tabId)
		-- Actualizar título del content header
		for _, tab in ipairs(SettingsConfig.TABS) do
			if tab.id == tabId then
				contentTitle.Text = tab.title
				break
			end
		end
		-- Animación de deslizamiento igual que el clan
		local page = tabPages[tabId]
		if page then pageLayout:JumpTo(page) end
	end

	-- Abrir primer tab (sin animación, salto directo)
	if #SettingsConfig.TABS > 0 then
		local firstId = SettingsConfig.TABS[1].id
		State.currentTab = firstId
		nav:selectItem(firstId)
		contentTitle.Text = SettingsConfig.TABS[1].title
		local firstPage = tabPages[firstId]
		if firstPage then pageLayout:JumpTo(firstPage) end
	end
end

return SettingsCreator