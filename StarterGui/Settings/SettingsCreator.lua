--[[
	SETTINGS CREATOR - Constructor de UI puro (sin instancias)
	v3 — Developer cards modernos, avatars con borde, roles, containers corregidos
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ThemeConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local SettingsConfig = require(script.Parent:WaitForChild("SettingsConfig"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local SettingsCreator = {}
local settingsState = {}

-- Constantes de layout
local CARD_HEIGHT = 74
local CARD_HEIGHT_CREDIT_SECTION = 60
local CARD_GAP = 10
local PADDING_Y = 20 -- top(10) + bottom(10)

-- ============================================
-- HELPER: Gradient sutil para cards
-- ============================================
local function applyCardGradient(frame, THEME)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.92, 0.92, 0.95))
	}
	grad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.97),
		NumberSequenceKeypoint.new(1, 0.99)
	}
	grad.Rotation = 135
	grad.Parent = frame
end

-- ============================================
-- CREAR SETTING ITEM (Toggle/Info o crédito)
-- ============================================
local function createSettingItem(parent, setting, THEME)
	local itemHeight = setting.type == "credit" and CARD_HEIGHT_CREDIT_SECTION or CARD_HEIGHT

	local container = UI.frame({
		size = UDim2.new(1, 0, 0, itemHeight),
		bg = THEME.surface,
		z = 104,
		parent = parent,
		corner = 10,
		stroke = true,
		strokeA = 0.15
	})

	-- Gradient sutil al card
	applyCardGradient(container, THEME)

	-- Texto container
	local textContainer = UI.frame({
		size = UDim2.new(1, -20, 1, 0),
		pos = UDim2.new(0, 10, 0, 0),
		bgT = 1,
		z = 105,
		parent = container
	})

	-- ── Credit items ──
	if setting.type == "credit" then
		UI.label({
			size = UDim2.new(1, 0, 0, 18),
			pos = UDim2.new(0, 0, 0, 6),
			text = setting.label,
			color = THEME.accent,
			textSize = 13,
			font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Center,
			z = 106,
			parent = textContainer
		})

		UI.label({
			size = UDim2.new(1, 0, 1, -26),
			pos = UDim2.new(0, 0, 0, 26),
			text = setting.desc or "",
			color = THEME.muted,
			textSize = 11,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Center,
			z = 106,
			parent = textContainer
		})

		-- ── Cards normales (toggle) ──
	else
		UI.label({
			size = UDim2.new(1, -60, 0, 28),
			pos = UDim2.new(0, 0, 0, 12),
			text = setting.label,
			color = THEME.text,
			textSize = 15,
			font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Left,
			z = 106,
			parent = textContainer
		})

		UI.label({
			size = UDim2.new(1, -60, 0, 22),
			pos = UDim2.new(0, 0, 0, 40),
			text = setting.desc or "",
			color = THEME.muted,
			textSize = 12,
			font = Enum.Font.Gotham,
			alignX = Enum.TextXAlignment.Left,
			z = 106,
			parent = textContainer
		})
	end

	-- ── Toggle ──
	if setting.type == "toggle" then
		local toggleBtn = UI.frame({
			size = UDim2.new(0, 46, 0, 26),
			pos = UDim2.new(1, -56, 0.5, -13),
			bg = THEME.card,
			z = 105,
			parent = container,
			corner = 13,
			stroke = true,
			strokeA = 0.25
		})

		local isActive = settingsState[setting.id] or setting.default or false

		local circle = Instance.new("Frame")
		circle.Name = "Circle"
		circle.Size = UDim2.new(0, 22, 0, 22)
		circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		circle.BorderSizePixel = 0
		circle.ZIndex = 106
		circle.Parent = toggleBtn

		local cornerCircle = Instance.new("UICorner")
		cornerCircle.CornerRadius = UDim.new(0, 11)
		cornerCircle.Parent = circle

		-- Sombra sutil en el circle
		local circleShadow = Instance.new("ImageLabel")
		circleShadow.Name = "Shadow"
		circleShadow.Size = UDim2.new(1, 6, 1, 6)
		circleShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		circleShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		circleShadow.BackgroundTransparency = 1
		circleShadow.ImageColor3 = Color3.new(0, 0, 0)
		circleShadow.ImageTransparency = 0.85
		circleShadow.ZIndex = 105
		circleShadow.Parent = circle

		local clickDetector = Instance.new("TextButton")
		clickDetector.Size = UDim2.fromScale(1, 1)
		clickDetector.BackgroundTransparency = 1
		clickDetector.TextTransparency = 1
		clickDetector.ZIndex = 107
		clickDetector.Parent = toggleBtn

		local function updateToggle(active)
			settingsState[setting.id] = active

			local bgColor = active and THEME.accent or THEME.card
			TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = bgColor
			}):Play()

			local circlePos = active and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
			TweenService:Create(circle, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = circlePos
			}):Play()

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

	-- Hover effect en el container
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3 = THEME.elevated or THEME.surface}):Play()
		end
	end)
	container.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = THEME.surface}):Play()
		end
	end)

	return container
end

-- ============================================
-- Calcular alto total del contenido
-- ============================================
local function calculateContentHeight(settingsList)
	local totalHeight = 0
	for i, setting in ipairs(settingsList) do
		local itemHeight = setting.type == "credit" and CARD_HEIGHT_CREDIT_SECTION or CARD_HEIGHT
		totalHeight = totalHeight + itemHeight
		if i < #settingsList then
			totalHeight = totalHeight + CARD_GAP
		end
	end
	return totalHeight + PADDING_Y
end

-- ============================================
-- CREAR PORTADA DE CRÉDITOS MODERNA v3
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

	-- ══════════════════════════════════════════════════════════
	-- FONDO TRANSPARENTE (imagen configurable)
	-- ══════════════════════════════════════════════════════════
	-- Inner container — SIN ScrollingFrame, centrado vertical
	local innerWrap = UI.frame({
		name = "InnerWrap",
		size = UDim2.new(1, -40, 0, 0),
		pos = UDim2.new(0.5, 0, 0.5, 0),
		bgT = 1,
		z = 104,
		parent = creditsCover
	})
	innerWrap.AnchorPoint = Vector2.new(0.5, 0.5)
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

	-- ── Párrafo principal — AutomaticSize.Y, texto más grande ──
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
	-- SECCIÓN DEVELOPERS
	-- ══════════════════════════════════════════════════════════
	if creditsList[3] then
		local devItem = creditsList[3]

		local sectionLabel = UI.label({
			size = UDim2.new(1, 0, 0, 20),
			text = "DEVELOPERS",
			color = THEME.accent,
			textSize = 12,
			font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Center,
			z = 105,
			parent = innerWrap
		})
		sectionLabel.LayoutOrder = 5

		local devNamesRaw = devItem.desc or ""
		local tokens = {}
		for token in string.gmatch(devNamesRaw, "([^|]+)") do
			local s = token:gsub("^%s*(.-)%s*$", "%1")
			table.insert(tokens, s)
		end

		local devs = {}
		local i = 1
		while i <= #tokens do
			local username = tokens[i]
			local role = nil
			if tokens[i + 1] and string.sub(tokens[i + 1], 1, 1) == "@" then
				role = string.sub(tokens[i + 1], 2)
				i = i + 2
			else
				role = "Developer"
				i = i + 1
			end
			table.insert(devs, { name = username, role = role })
		end

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
			local DEV_CARD_HEIGHT = 68
			local AVATAR_SIZE = 46

			local devCard = UI.frame({
				size = UDim2.new(1, 0, 0, DEV_CARD_HEIGHT),
				bg = THEME.surface,
				z = 106,
				parent = devsGrid,
				corner = 12,
				stroke = true,
				strokeA = 0.12
			})
			devCard.LayoutOrder = idx
			applyCardGradient(devCard, THEME)

			local accentBar = UI.frame({
				size = UDim2.new(0, 3, 0.5, 0),
				pos = UDim2.new(0, 0, 0.25, 0),
				bg = THEME.accent,
				z = 107,
				parent = devCard,
				corner = 2
			})

			local avatarRing = UI.frame({
				size = UDim2.new(0, AVATAR_SIZE + 4, 0, AVATAR_SIZE + 4),
				pos = UDim2.new(0, 14, 0.5, 0),
				bg = THEME.accent,
				z = 107,
				parent = devCard,
				corner = (AVATAR_SIZE + 4) / 2
			})
			avatarRing.AnchorPoint = Vector2.new(0, 0.5)
			avatarRing.BackgroundTransparency = 0.6

			local avatarWrapper = UI.frame({
				size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE),
				pos = UDim2.new(0.5, 0, 0.5, 0),
				bg = THEME.card,
				z = 108,
				parent = avatarRing,
				corner = AVATAR_SIZE / 2
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

			local avatarCorner = Instance.new("UICorner")
			avatarCorner.CornerRadius = UDim.new(0, AVATAR_SIZE / 2)
			avatarCorner.Parent = avatarImg

			local TEXT_LEFT = 14 + (AVATAR_SIZE + 4) + 12

			local nameLabel = UI.label({
				size = UDim2.new(1, -(TEXT_LEFT + 30), 0, 22),
				pos = UDim2.new(0, TEXT_LEFT, 0, 12),
				text = dev.name,
				color = THEME.text,
				textSize = 15,
				font = Enum.Font.GothamBold,
				alignX = Enum.TextXAlignment.Left,
				z = 108,
				parent = devCard
			})
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

			UI.label({
				size = UDim2.new(1, -(TEXT_LEFT + 30), 0, 18),
				pos = UDim2.new(0, TEXT_LEFT, 0, 36),
				text = dev.role,
				color = THEME.accent,
				textSize = 12,
				font = Enum.Font.GothamMedium,
				alignX = Enum.TextXAlignment.Left,
				z = 108,
				parent = devCard
			})

			local badge = UI.frame({
				size = UDim2.new(0, 8, 0, 8),
				pos = UDim2.new(1, -20, 0.5, 0),
				bg = THEME.accent,
				z = 108,
				parent = devCard,
				corner = 4
			})
			badge.AnchorPoint = Vector2.new(0, 0.5)
			badge.BackgroundTransparency = 0.4

			devCard.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					TweenService:Create(devCard, TweenInfo.new(0.2), {
						BackgroundColor3 = THEME.elevated or THEME.surface
					}):Play()
					TweenService:Create(accentBar, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 3, 0.7, 0),
						Position = UDim2.new(0, 0, 0.15, 0)
					}):Play()
				end
			end)
			devCard.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					TweenService:Create(devCard, TweenInfo.new(0.25), {
						BackgroundColor3 = THEME.surface
					}):Play()
					TweenService:Create(accentBar, TweenInfo.new(0.25), {
						Size = UDim2.new(0, 3, 0.5, 0),
						Position = UDim2.new(0, 0, 0.25, 0)
					}):Play()
				end
			end)
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
-- ============================================
-- CREAR MODAL PRINCIPAL
-- ============================================
function SettingsCreator.CreateSettingsModal(panel, THEME)
	-- Reset state
	settingsState = {}
	for k, v in pairs(SettingsConfig.DEFAULTS) do
		settingsState[k] = v
	end

	-- Limpiar anteriores
	local oldContent = panel:FindFirstChild("ContentArea")
	if oldContent then oldContent:Destroy() end
	local oldNav = panel:FindFirstChild("Header")
	if oldNav then oldNav:Destroy() end
	local oldTabs = panel:FindFirstChild("TabNav")
	if oldTabs then oldTabs:Destroy() end
	local oldUnderline = panel:FindFirstChild("Underline")
	if oldUnderline then oldUnderline:Destroy() end

	-- ════════════════════════════════════════════════════════════════
	-- HEADER
	-- ════════════════════════════════════════════════════════════════
	local header = UI.frame({
		name = "Header",
		size = UDim2.new(1, 0, 0, 60),
		bg = THEME.head,
		z = 101,
		parent = panel,
		corner = 12
	})

	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, THEME.panel),
		ColorSequenceKeypoint.new(1, THEME.card)
	}
	headerGradient.Rotation = 90
	headerGradient.Parent = header

	UI.label({
		size = UDim2.new(1, -100, 0, 60),
		pos = UDim2.new(0, 20, 0, 0),
		text = "AJUSTES",
		textSize = 20,
		font = Enum.Font.GothamBold,
		z = 102,
		parent = header,
		color = THEME.text
	})

	-- ════════════════════════════════════════════════════════════════
	-- TAB NAVIGATION
	-- ════════════════════════════════════════════════════════════════
	local tabNav = UI.frame({
		name = "TabNav",
		size = UDim2.new(1, 0, 0, 36),
		pos = UDim2.new(0, 0, 0, 60),
		bgT = 1,
		z = 101,
		parent = panel
	})

	local navList = Instance.new("UIListLayout")
	navList.FillDirection = Enum.FillDirection.Horizontal
	navList.Padding = UDim.new(0, 8)
	navList.Parent = tabNav

	local navPadding = Instance.new("UIPadding")
	navPadding.PaddingLeft = UDim.new(0, 12)
	navPadding.PaddingTop = UDim.new(0, 6)
	navPadding.Parent = tabNav

	local tabButtons = {}
	local State = { currentTab = "gameplay" }

	-- ════════════════════════════════════════════════════════════════
	-- CONTENT AREA
	-- ════════════════════════════════════════════════════════════════
	local contentArea = UI.frame({
		name = "ContentArea",
		size = UDim2.new(1, -20, 1, -115),
		pos = UDim2.new(0, 10, 0, 90),
		bgT = 1,
		z = 101,
		parent = panel,
		corner = 10,
		clips = true
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
	-- UNDERLINE
	-- ════════════════════════════════════════════════════════════════
	local underline = UI.frame({
		name = "Underline",
		size = UDim2.new(0, 90, 0, 3),
		pos = UDim2.new(0, 12, 0, 93),
		bg = THEME.accent,
		z = 102,
		parent = panel,
		corner = 2
	})

	-- ════════════════════════════════════════════════════════════════
	-- CREAR TABS Y PÁGINAS
	-- ════════════════════════════════════════════════════════════════
	for tabIndex, tab in ipairs(SettingsConfig.TABS) do
		local btn = UI.button({
			size = UDim2.new(0, 90, 0, 24),
			bg = THEME.panel,
			text = tab.title,
			color = THEME.muted,
			textSize = 12,
			font = Enum.Font.GothamBold,
			z = 101,
			parent = tabNav,
			corner = 0
		})
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		tabButtons[tab.id] = btn

		local page = UI.frame({
			name = tab.id,
			size = UDim2.fromScale(1, 1),
			bgT = 1,
			z = 102,
			parent = contentArea
		})
		page.LayoutOrder = tabIndex

		local pageContainer = UI.frame({
			name = "Container",
			size = UDim2.new(1, 0, 1, 0),
			pos = UDim2.new(0, 0, 0, 0),
			bgT = 1,
			z = 102,
			parent = page,
			clips = true
		})

		-- ═══════════════════════════════════════════════════════════
		-- CRÉDITOS — Portada moderna v3
		-- ═══════════════════════════════════════════════════════════
		if tab.id == "credits" then
			createCreditsPage(pageContainer, THEME)

			-- ═══════════════════════════════════════════════════════════
			-- LAYOUT NORMAL PARA OTROS TABS
			-- ═══════════════════════════════════════════════════════════
		else
			local settingsList = SettingsConfig.SETTINGS[tab.id] or {}
			local contentHeight = calculateContentHeight(settingsList)

			local scrollFrame = Instance.new("ScrollingFrame")
			scrollFrame.Name = "Scroll"
			scrollFrame.Size = UDim2.new(1, 0, 1, 0)
			scrollFrame.Position = UDim2.new(0, 0, 0, 0)
			scrollFrame.BackgroundTransparency = 1
			scrollFrame.BorderSizePixel = 0
			scrollFrame.ScrollBarThickness = 0
			scrollFrame.ScrollBarImageTransparency = 1
			scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
			scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
			scrollFrame.Parent = pageContainer

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, CARD_GAP)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = scrollFrame

			local layoutPadding = Instance.new("UIPadding")
			layoutPadding.PaddingLeft = UDim.new(0, 10)
			layoutPadding.PaddingRight = UDim.new(0, 16)
			layoutPadding.PaddingTop = UDim.new(0, 10)
			layoutPadding.PaddingBottom = UDim.new(0, 10)
			layoutPadding.Parent = scrollFrame

			for _, setting in ipairs(settingsList) do
				createSettingItem(scrollFrame, setting, THEME)
			end

			-- Scrollbar check
			task.spawn(function()
				task.wait(0.4)
				local windowHeight = scrollFrame.AbsoluteWindowSize.Y

				if contentHeight > windowHeight then
					scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)

					local scrollbar = ModernScrollbar.setup(scrollFrame, pageContainer, THEME, {
						position = "right",
						offset = -8,
						width = 6
					})

					if scrollbar then
						task.wait(0.1)
						scrollbar.update()
					end
				else
					scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
					scrollFrame.ScrollingEnabled = false
				end
			end)
		end
	end

	-- ════════════════════════════════════════════════════════════════
	-- FUNCIÓN SWITCH TAB
	-- ════════════════════════════════════════════════════════════════
	local tabPositions = {
		gameplay = 12,
		graphics = 110,
		alerts = 208,
		credits = 306,
		comments = 404
	}

	local function switchTab(tabId)
		if State.currentTab == tabId then return end
		State.currentTab = tabId

		for id, btn in pairs(tabButtons) do
			TweenService:Create(btn, TweenInfo.new(0.2), {
				TextColor3 = (id == tabId) and THEME.accent or THEME.muted
			}):Play()
		end

		if tabPositions[tabId] then
			TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, tabPositions[tabId], 0, 93)
			}):Play()
		end

		local pageFrame = contentArea:FindFirstChild(tabId)
		if pageFrame then
			pageLayout:JumpTo(pageFrame)
		end
	end

	for tabId, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			switchTab(tabId)
		end)
		UI.hover(btn, THEME.panel, THEME.elevated)
	end

	switchTab("gameplay")
end

return SettingsCreator