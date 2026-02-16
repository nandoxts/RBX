--[[
	═══════════════════════════════════════════════════════════
	USER PANEL CLIENT - REDISEÑO v2.0
	═══════════════════════════════════════════════════════════
	• Glassmorphism refinado con capas sutiles
	• Layout responsivo real (mobile / tablet / desktop)
	• Developer mode dinámico con efectos premium
	• Prevención de lag: pool de tweens, batch updates, debounce
	• Estructura modular limpia
]]

-- ═══════════════════════════════════════════════════════════════
-- IMPORTAR MÓDULOS
-- ═══════════════════════════════════════════════════════════════
local Modules = script.Parent.Modules

local Config = require(Modules.Config)
local State = require(Modules.State)
local RemotesSetup = require(Modules.RemotesSetup)
local GroupRoles = require(Modules.GroupEfectModule)
local Utils = require(Modules.Utils)
local SyncSystem = require(Modules.SyncSystem)
local LikesSystem = require(Modules.LikesSystem)
local EventListeners = require(Modules.EventListeners)
local InputHandler = require(Modules.InputHandler)

-- ═══════════════════════════════════════════════════════════════
-- SERVICIOS & DETECCIÓN DE DISPOSITIVO
-- ═══════════════════════════════════════════════════════════════
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DeviceType = "desktop" -- "mobile" | "tablet" | "desktop"

local function detectDevice()
	local isTouchEnabled = UserInputService.TouchEnabled
	local isMouseEnabled = UserInputService.MouseEnabled
	local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	if isTouchEnabled and not isMouseEnabled then
		if screenSize.X >= 1024 then
			DeviceType = "tablet"
		else
			DeviceType = "mobile"
		end
	else
		DeviceType = "desktop"
	end

	return DeviceType
end

-- ═══════════════════════════════════════════════════════════════
-- LAYOUT RESPONSIVO
-- ═══════════════════════════════════════════════════════════════
local Layout = {}

function Layout.get()
	detectDevice()

	if DeviceType == "mobile" then
		return {
			panelWidth = math.min(Config.PANEL_WIDTH, 280),
			panelHeight = Config.PANEL_HEIGHT - 20,
			avatarHeight = Config.AVATAR_HEIGHT - 10,
			buttonHeight = Config.BUTTON_HEIGHT - 2,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = math.max(Config.PANEL_PADDING - 2, 6),
			fontSize = { title = 14, subtitle = 9, stat = 11, statLabel = 7, button = 12 },
			dragHandleH = 24,
			cardSize = Config.CARD_SIZE - 4,
			statsWidth = Config.STATS_WIDTH - 8,
			cornerRadius = 14,
			bottomOffset = 60,
			likeButtonSize = 22,
		}
	elseif DeviceType == "tablet" then
		return {
			panelWidth = Config.PANEL_WIDTH + 20,
			panelHeight = Config.PANEL_HEIGHT,
			avatarHeight = Config.AVATAR_HEIGHT,
			buttonHeight = Config.BUTTON_HEIGHT,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = Config.PANEL_PADDING,
			fontSize = { title = 17, subtitle = 11, stat = 14, statLabel = 8, button = 13 },
			dragHandleH = 20,
			cardSize = Config.CARD_SIZE,
			statsWidth = Config.STATS_WIDTH,
			cornerRadius = 14,
			bottomOffset = 80,
			likeButtonSize = 26,
		}
	else
		return {
			panelWidth = Config.PANEL_WIDTH,
			panelHeight = Config.PANEL_HEIGHT,
			avatarHeight = Config.AVATAR_HEIGHT,
			buttonHeight = Config.BUTTON_HEIGHT,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = Config.PANEL_PADDING,
			fontSize = { title = 18, subtitle = 13, stat = 16, statLabel = 9, button = 14 },
			dragHandleH = 18,
			cardSize = Config.CARD_SIZE,
			statsWidth = Config.STATS_WIDTH,
			cornerRadius = 12,
			bottomOffset = 90,
			likeButtonSize = 28,
		}
	end
end

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZAR REMOTES Y MÓDULOS
-- ═══════════════════════════════════════════════════════════════
local Remotes = RemotesSetup()
local Services = Remotes.Services
local player = Services.Player
local playerGui = Services.PlayerGui
local camera = Services.Camera
local NotificationSystem = Remotes.Systems.NotificationSystem
local ColorEffects = Remotes.Systems.ColorEffects
local Gifting = Remotes.Gifting.GiftingRemote
local THEME = Config.THEME

Utils.init(Config, State)
SyncSystem.init(Remotes, State)
LikesSystem.init(Remotes, State, Config)
EventListeners.init(Remotes)

-- ═══════════════════════════════════════════════════════════════
-- DEVELOPER SYSTEM - Detección y efectos premium
-- ═══════════════════════════════════════════════════════════════
local DevSystem = {}

function DevSystem.isDeveloper(userId)
	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == userId then return true end
	end
	return false
end

-- Badge info según developer (adapta al color base del jugador)
function DevSystem.getBadgeInfo(userId, baseColor)
	if DevSystem.isDeveloper(userId) then
		baseColor = baseColor or THEME.accent
		return {
			text = "OWNER",
			color = baseColor,
			glowColor = baseColor,
			icon = "rbxassetid://79346090571461",
		}
	end
	return nil
end

-- Gradiente animado para bordes developer (optimizado con RenderStepped limitado)
local devRotationConns = {} -- para limpieza

function DevSystem.applyBorderGradient(strokeInstance, speed, baseColor)
	speed = speed or 1.5
	baseColor = baseColor or Color3.new(1, 1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = strokeInstance
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, baseColor),
		ColorSequenceKeypoint.new(0.33, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.66, baseColor),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})

	-- Usar heartbeat con throttle en vez de task.spawn + task.wait()
	local elapsed = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not strokeInstance.Parent then return end
		elapsed = elapsed + (dt * speed * 60)
		gradient.Rotation = elapsed % 360
	end)

	table.insert(devRotationConns, conn)
	Utils.addConnection(conn)
	return gradient
end

-- Gradiente shimmer para texto developer (optimizado)
function DevSystem.applyTextShimmer(label, baseColor)
	baseColor = baseColor or THEME.accent
	local r, g, b = baseColor.R, baseColor.G, baseColor.B
	local darkColor = Color3.new(r * 0.5, g * 0.5, b * 0.5)

	local gradient = Instance.new("UIGradient")
	gradient.Parent = label
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, baseColor),
		ColorSequenceKeypoint.new(0.4, darkColor),
		ColorSequenceKeypoint.new(0.6, baseColor),
		ColorSequenceKeypoint.new(1, baseColor),
	})
	gradient.Offset = Vector2.new(-1, 0)

	-- Tween loop (más eficiente que manual)
	local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(gradient, tweenInfo, { Offset = Vector2.new(1, 0) })
	tween:Play()

	return gradient
end

-- Badge visual de developer
function DevSystem.createBadge(parent, badgeInfo, L)
	local badge = Utils.createFrame({
		Size = UDim2.new(0, 48, 0, 18),
		BackgroundColor3 = badgeInfo.color,
		BackgroundTransparency = 0.45,
		Parent = parent,
	})
	Utils.addCorner(badge, 9)

	-- Glow sutil
	Utils.addStroke(badge, badgeInfo.glowColor, 1, 0.4)

	Utils.createLabel({
		Size = UDim2.new(1, 0, 1, 0),
		Text = badgeInfo.text,
		TextColor3 = THEME.text,
		TextSize = L.fontSize.statLabel + 1,
		Font = Enum.Font.GothamBlack,
		Parent = badge
	})

	return badge
end

-- Fondo especial para developers (semi-transparente limpio, sin tinte de color)
function DevSystem.applyPanelBackground(panelImage, panelContainer, badgeInfo)
	panelImage.Image = badgeInfo.icon
	panelImage.ScaleType = Enum.ScaleType.Crop
	panelImage.ImageTransparency = 0.35
	panelImage.BackgroundTransparency = 1

	-- Solo un fade vertical suave (arriba visible → abajo se desvanece)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = panelImage
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 0.75),
	})
end

-- ═══════════════════════════════════════════════════════════════
-- TWEEN HELPER (prevención de lag: reusar tweens)
-- ═══════════════════════════════════════════════════════════════
local activeTweens = {}

local function safeTween(instance, props, duration, style, dir)
	if not instance or not instance.Parent then return end

	-- Cancelar tween previo en misma instancia
	local key = tostring(instance)
	if activeTweens[key] then
		activeTweens[key]:Cancel()
	end

	local tween = Utils.tween(instance, props, duration or Config.ANIM_FAST, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut)
	activeTweens[key] = tween

	return tween
end

-- ═══════════════════════════════════════════════════════════════
-- GLASSMORPHISM LAYER BUILDER
-- ═══════════════════════════════════════════════════════════════
local Glass = {}

-- Capa base de glass con blur simulado
function Glass.applyToPanel(container, playerColor, L, isDev)
	-- En modo dev, las capas son más transparentes para que se vea la imagen
	local baseTransparency = isDev and 0.65 or 0.35
	local colorTransparency = isDev and 0.95 or 0.88

	-- Capa base oscura semitransparente
	local baseLayer = Utils.createFrame({
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(12, 12, 18),
		BackgroundTransparency = baseTransparency,
		ZIndex = 0,
		Parent = container
	})
	Utils.addCorner(baseLayer, L.cornerRadius)

	-- Capa de color del jugador (sutil)
	local colorLayer = Utils.createFrame({
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = playerColor,
		BackgroundTransparency = colorTransparency,
		ZIndex = 0,
		Parent = container
	})
	Utils.addCorner(colorLayer, L.cornerRadius)

	-- Gradiente interno para profundidad
	local innerGradient = Instance.new("UIGradient")
	innerGradient.Parent = colorLayer
	innerGradient.Rotation = 160
	innerGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.95),
		NumberSequenceKeypoint.new(1, 0.85),
	})

	return baseLayer, colorLayer
end

-- Separador glass sutil
function Glass.createDivider(parent, playerColor, layoutOrder)
	local divider = Utils.createFrame({
		Size = UDim2.new(0.85, 0, 0, 1),
		BackgroundColor3 = playerColor or THEME.accent,
		BackgroundTransparency = 0.7,
		LayoutOrder = layoutOrder or 0,
		Parent = parent
	})
	return divider
end

-- ═══════════════════════════════════════════════════════════════
-- UI COMPONENTS
-- ═══════════════════════════════════════════════════════════════

-- Botón rediseñado con glass effect
local function createButton(parent, text, layoutOrder, accentColor)
	local L = Layout.get()

	local container = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, L.buttonHeight),
		LayoutOrder = layoutOrder,
		Parent = parent
	})

	-- Botón con glass
	local btnColor = THEME.elevated:Lerp(accentColor or THEME.accent, 0.08)
	local btn = Utils.create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = btnColor,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = container
	})
	Utils.addCorner(btn, 10)
	Utils.addStroke(btn, accentColor or THEME.accent, 1, 0.75)

	-- Gradiente glass sobre el botón
	local btnGradient = Instance.new("UIGradient")
	btnGradient.Parent = btn
	btnGradient.Rotation = 90
	btnGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.25),
	})

	local rippleContainer = Utils.createFrame({
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		Parent = btn
	})
	Utils.addCorner(rippleContainer, 10)

	local label = Utils.createLabel({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text,
		TextSize = L.fontSize.button,
		Font = Enum.Font.GothamBold,
		TextColor3 = THEME.text,
		Parent = btn
	})

	-- Hover / Leave con color cacheado
	local hoverColor = Utils.darkenColor(accentColor or THEME.accent, 0.25)

	Utils.addConnection(btn.MouseEnter:Connect(function()
		safeTween(btn, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.05 }, Config.ANIM_FAST)
	end))
	Utils.addConnection(btn.MouseLeave:Connect(function()
		safeTween(btn, { BackgroundColor3 = btnColor, BackgroundTransparency = 0.15 }, Config.ANIM_FAST)
	end))
	Utils.addConnection(btn.MouseButton1Click:Connect(function(x, y)
		Utils.createRipple(btn, rippleContainer, x, y)
	end))

	return btn, label
end

-- ═══════════════════════════════════════════════════════════════
-- DYNAMIC SECTION (Donaciones / Regalar Pase)
-- ═══════════════════════════════════════════════════════════════
local function renderDynamicSection(viewType, items, targetName, playerColor)
	if not State.dynamicSection or not State.dynamicSection.Parent then return end
	local L = Layout.get()

	-- Limpiar contenido actual
	for _, child in ipairs(State.dynamicSection:GetChildren()) do
		child:Destroy()
	end

	-- Header con botón volver
	local header = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, L.fontSize.title + 14),
		Parent = State.dynamicSection
	})
	Utils.addCorner(header, 8)

	local backBtn = Utils.create("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundColor3 = THEME.elevated:Lerp(playerColor or THEME.accent, 0.15),
		BackgroundTransparency = 0.1,
		Text = "‹",
		TextColor3 = THEME.text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 70,
		Parent = header
	})
	Utils.addCorner(backBtn, 8)
	Utils.addStroke(backBtn, playerColor or THEME.accent, 1, 0.8)

	local backHoverColor = Utils.darkenColor(playerColor or THEME.accent, 0.25)
	local backBaseColor = THEME.elevated:Lerp(playerColor or THEME.accent, 0.15)

	Utils.addConnection(backBtn.MouseEnter:Connect(function()
		safeTween(backBtn, { BackgroundColor3 = backHoverColor }, Config.ANIM_FAST)
	end))
	Utils.addConnection(backBtn.MouseLeave:Connect(function()
		safeTween(backBtn, { BackgroundColor3 = backBaseColor }, Config.ANIM_FAST)
	end))

	Utils.addConnection(backBtn.MouseButton1Click:Connect(function()
		if State.dynamicSection then
			-- Animaciones simultáneas para transición más rápida
			safeTween(State.dynamicSection, {
				Position = UDim2.new(1, 0, 0, State.dynamicSection.Position.Y.Offset)
			}, 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

			-- Mostrar y animar botones inmediatamente
			if State.buttonsFrame then
				State.buttonsFrame.Visible = true
				State.buttonsFrame.Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset)
				safeTween(State.buttonsFrame, {
					Position = UDim2.new(0, L.panelPadding, 0, State.buttonsFrame.Position.Y.Offset)
				}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end

			-- Limpiar después de la animación
			task.delay(0.25, function()
				if State.dynamicSection then
					State.dynamicSection:Destroy()
					State.dynamicSection = nil
				end
				State.currentView = "buttons"
				State.isLoadingDynamic = false
			end)
		end
	end))

	local title = viewType == "donations"
		and ("Donar a " .. (targetName or "Usuario"))
		or "Regalar Pase"

	Utils.createLabel({
		Size = UDim2.new(1, -36, 0, L.fontSize.title + 14),
		Position = UDim2.new(0, 34, 0, 0),
		Text = title,
		TextColor3 = THEME.text,
		TextSize = L.fontSize.title - 2,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header
	})

	-- Scroll horizontal de cards
	local scrollTopOffset = L.fontSize.title + 20
	local scroll = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -scrollTopOffset),
		Position = UDim2.new(0, 0, 0, scrollTopOffset),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = playerColor or THEME.accent,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, L.cardSize + 14),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = State.dynamicSection
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 10),
		Parent = scroll
	})
	Utils.create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = scroll })

	if items and #items > 0 then
		for i, item in ipairs(items) do
			local cardOuter = Utils.createFrame({
				Size = UDim2.new(0, L.cardSize + 10, 0, L.cardSize + 10),
				LayoutOrder = i,
				Parent = scroll
			})
			Utils.addCorner(cardOuter, L.cardSize / 2)

			-- Círculo con glass border
			local circle = Utils.createFrame({
				Size = UDim2.new(0, L.cardSize, 0, L.cardSize),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = THEME.panel,
				BackgroundTransparency = 0,
				ClipsDescendants = true,
				Parent = cardOuter
			})
			Utils.addCorner(circle, L.cardSize / 2)
			local circleStroke = Utils.addStroke(circle, THEME.stroke, 1.5)

			local img = Utils.create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = item.icon or "",
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 1,
				Parent = circle
			})
			Utils.addCorner(img, L.cardSize / 2)

			-- Overlay de precio con glass
			local priceOverlay = Utils.createFrame({
				Size = UDim2.new(1, 0, 0.32, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(10, 10, 15),
				BackgroundTransparency = 0.25,
				ZIndex = 2,
				ClipsDescendants = true,
				Parent = circle
			})
			Utils.addCorner(priceOverlay, 6)

			local priceText = Utils.createLabel({
				Size = UDim2.new(1, 0, 1, 0),
				Text = utf8.char(0xE002) .. tostring(item.price or 0),
				TextColor3 = THEME.accent,
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				ZIndex = 3,
				Parent = priceOverlay
			})

			-- Check de pase (batch friendly)
			if item.hasPass == true then
				priceText.Text = "ADQUIRIDO"
				priceText.TextColor3 = Color3.fromRGB(100, 220, 100)
				priceOverlay.BackgroundTransparency = 0.4
			elseif item.hasPass == nil and item.passId then
				task.spawn(function()
					local ok, result = pcall(function()
						if viewType == "passes" then
							return Remotes.Remotes.CheckGamePass:InvokeServer(item.passId, State.userId)
						else
							return Remotes.Remotes.CheckGamePass:InvokeServer(item.passId)
						end
					end)
					item.hasPass = (ok and result) or false

					if item.hasPass and priceText.Parent then
						priceText.Text = "ADQUIRIDO"
						priceText.TextColor3 = Color3.fromRGB(100, 220, 100)
						priceOverlay.BackgroundTransparency = 0.4
					end
				end)
			end

			-- Click handler
			local clickBtn = Utils.create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 10,
				Parent = cardOuter
			})

			local strokeHoverColor = playerColor or THEME.accent

			Utils.addConnection(clickBtn.MouseEnter:Connect(function()
				safeTween(circleStroke, { Color = strokeHoverColor, Thickness = 2.5 }, Config.ANIM_FAST)
				safeTween(circle, { Size = UDim2.new(0, L.cardSize + 4, 0, L.cardSize + 4) }, Config.ANIM_FAST)
			end))
			Utils.addConnection(clickBtn.MouseLeave:Connect(function()
				safeTween(circleStroke, { Color = THEME.stroke, Thickness = 1.5 }, Config.ANIM_FAST)
				safeTween(circle, { Size = UDim2.new(0, L.cardSize, 0, L.cardSize) }, Config.ANIM_FAST)
			end))

			Utils.addConnection(clickBtn.MouseButton1Click:Connect(function()
				if item.hasPass == true then
					if NotificationSystem then
						local msg = viewType == "passes"
							and "Esta persona ya tiene este pase"
							or "Ya compraste este pase"
						NotificationSystem:Info("Game Pass", msg, 2)
					end
				elseif item.passId then
					if viewType == "passes" then
						if not Gifting or not State.target or not item.productId then
							return
						end
						pcall(function()
							Gifting:FireServer(
								{item.passId, item.productId},
								State.target.UserId,
								player.Name,
								player.UserId
							)
						end)
					else
						pcall(function()
							Services.MarketplaceService:PromptGamePassPurchase(player, item.passId)
						end)
					end
				end
			end))
		end
	else
		Utils.createLabel({
			Size = UDim2.new(1, 0, 1, 0),
			Text = "No hay items disponibles",
			TextColor3 = THEME.muted,
			TextSize = L.fontSize.statLabel + 2,
			Parent = scroll
		})
	end
end

local function showDynamicSection(viewType, items, targetName, playerColor)
	local L = Layout.get()
	State.currentView = viewType

	if State.buttonsFrame then
		safeTween(State.buttonsFrame, {
			Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset)
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		task.delay(0.3, function()
			if State.buttonsFrame then State.buttonsFrame.Visible = false end
		end)
	end

	-- NO ocultar el overlay - debe permanecer visible como fondo

	if State.dynamicSection then State.dynamicSection:Destroy() end

	local startY = L.avatarHeight + 8
	local availableHeight = math.max(80, State.panel.AbsoluteSize.Y - startY - L.panelPadding)

	State.dynamicSection = Utils.createFrame({
		Size = UDim2.new(1, -2 * L.panelPadding, 0, availableHeight),
		Position = UDim2.new(1, 0, 0, startY),
		ZIndex = 10,
		Parent = State.panel
	})

	renderDynamicSection(viewType, items, targetName, playerColor)

	safeTween(State.dynamicSection, {
		Position = UDim2.new(0, L.panelPadding, 0, startY)
	}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	task.delay(0.3, function()
		State.isLoadingDynamic = false
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- BOTONES SECTION
-- ═══════════════════════════════════════════════════════════════
local function createButtonsSection(panel, target, playerColor)
	local L = Layout.get()
	State.panel = panel

	local startY = L.avatarHeight + L.buttonGap
	local numButtons = (State.userId ~= player.UserId) and 4 or 3
	local buttonsHeight = (L.buttonHeight * numButtons) + (L.buttonGap * (numButtons - 1))

	-- ─── Overlay detrás de nombres + botones (extendido para cubrir todo el contenido) ───
	-- Empieza arriba de los nombres y se extiende hasta el final del panel
	local overlayTopExtend = 40 -- cuánto sube por encima del avatar bottom (cubre nombres)
	local overlayStartY = L.avatarHeight - overlayTopExtend

	local buttonsOverlay = Utils.createFrame({
		Size = UDim2.new(1, 0, 1, -overlayStartY), -- Se extiende hasta el final
		Position = UDim2.new(0, 0, 0, overlayStartY),
		BackgroundColor3 = Color3.fromRGB(6, 6, 10),
		BackgroundTransparency = 0.2,
		ZIndex = 2,
		ClipsDescendants = false,
		Parent = panel
	})
	Utils.addCorner(buttonsOverlay, L.cornerRadius)
	State.buttonsOverlay = buttonsOverlay

	-- Fade: arriba se desvanece ↑ centro sólido ↓ abajo se desvanece
	local overlayFade = Instance.new("UIGradient")
	overlayFade.Parent = buttonsOverlay
	overlayFade.Rotation = 90
	overlayFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),       -- arriba: invisible
		NumberSequenceKeypoint.new(0.15, 0.4),  -- transición suave
		NumberSequenceKeypoint.new(0.3, 0),     -- empieza sólido (zona de nombres)
		NumberSequenceKeypoint.new(0.75, 0),    -- sólido (zona de botones)
		NumberSequenceKeypoint.new(0.9, 0.4),   -- transición abajo
		NumberSequenceKeypoint.new(1, 1),       -- abajo: invisible
	})

	-- ─── Buttons Frame (encima del overlay) ───
	State.buttonsFrame = Utils.createFrame({
		Size = UDim2.new(1, -2 * L.panelPadding, 0, buttonsHeight + 8),
		Position = UDim2.new(0, L.panelPadding, 0, startY),
		ZIndex = 5,
		Parent = panel
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, L.buttonGap),
		Parent = State.buttonsFrame
	})

	-- 1. Sincronizar
	local syncBtn = createButton(State.buttonsFrame, "Sincronizar", 1, playerColor)
	local debounceSyncBtn = false
	Utils.addConnection(syncBtn.MouseButton1Click:Connect(function()
		if debounceSyncBtn or not target then return end
		debounceSyncBtn = true
		SyncSystem.syncWithPlayer(target)
		task.wait(0.5)
		debounceSyncBtn = false
	end))

	-- 2. Ver Perfil
	local profileBtn = createButton(State.buttonsFrame, "Ver Perfil", 2, playerColor)
	Utils.addConnection(profileBtn.MouseButton1Click:Connect(function()
		if target then
			pcall(function() Services.GuiService:InspectPlayerFromUserId(target.UserId) end)
		end
	end))

	-- 3. Donar
	local donateBtn, donateLabel = createButton(State.buttonsFrame, "Donar", 3, playerColor)
	Utils.addConnection(donateBtn.MouseButton1Click:Connect(function()
		if not State.userId or State.isLoadingDynamic or State.dynamicSection then return end
		State.isLoadingDynamic = true

		donateBtn.Active = false
		donateLabel.Text = "Cargando..."
		safeTween(donateBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

		task.spawn(function()
			local ok, donations = pcall(function()
				return Remotes.Remotes.GetUserDonations:InvokeServer(State.userId)
			end)

			if donateBtn and donateBtn.Parent then
				donateBtn.Active = true
				donateLabel.Text = "Donar"
				safeTween(donateBtn, { BackgroundTransparency = 0.15 }, Config.ANIM_FAST)
			end

			if ok and donations then
				showDynamicSection("donations", donations, target and target.DisplayName, playerColor)
			else
				State.isLoadingDynamic = false
				if NotificationSystem then
					NotificationSystem:Error("Error", "No se pudo cargar donaciones", 2)
				end
			end
		end)
	end))

	-- 4. Regalar Pase (solo si no es el jugador actual)
	if State.userId ~= player.UserId then
		local giftBtn, giftLabel = createButton(State.buttonsFrame, "Regalar Pase", 4, playerColor)
		Utils.addConnection(giftBtn.MouseButton1Click:Connect(function()
			if State.isLoadingDynamic or State.dynamicSection then return end
			State.isLoadingDynamic = true

			giftBtn.Active = false
			giftLabel.Text = "Cargando..."
			safeTween(giftBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

			task.spawn(function()
				local ok, passes = pcall(function()
					return Remotes.Remotes.GetGamePasses:InvokeServer(State.userId)
				end)

				if giftBtn and giftBtn.Parent then
					giftBtn.Active = true
					giftLabel.Text = "Regalar Pase"
					safeTween(giftBtn, { BackgroundTransparency = 0.15 }, Config.ANIM_FAST)
				end

				if ok and passes then
					showDynamicSection("passes", passes, nil, playerColor)
				else
					State.isLoadingDynamic = false
					if NotificationSystem then
						NotificationSystem:Error("Error", "No se pudieron cargar pases", 2)
					end
				end
			end)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════
-- AVATAR SECTION (rediseñada)
-- ═══════════════════════════════════════════════════════════════
local function createAvatarSection(panel, data, playerColor)
	local L = Layout.get()
	local isDev = DevSystem.isDeveloper(data.userId)
	local badgeInfo = DevSystem.getBadgeInfo(data.userId, playerColor)

	local avatarSection = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, L.avatarHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = panel
	})

	-- Avatar centrado
	local avatarImage = Utils.create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(Config.AVATAR_ZOOM, 0, Config.AVATAR_ZOOM, 0),
		BackgroundTransparency = 1,
		Image = data.avatar or "",
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
		Parent = avatarSection
	})
	Utils.asyncLoadAvatar(data.userId, avatarImage)

	-- Stats Sidebar (desvanecido hacia el lado del avatar)
	local statsBar = Utils.createFrame({
		Size = UDim2.new(0, L.statsWidth, 1, 0),
		Position = UDim2.new(1, -L.statsWidth, 0, 0),
		BackgroundColor3 = Color3.fromRGB(8, 8, 12),
		BackgroundTransparency = 0.3,
		ZIndex = 10,
		ClipsDescendants = true,
		Parent = avatarSection
	})
	Utils.addCorner(statsBar, L.cornerRadius)

	-- Gradiente: lado izquierdo (avatar) se desvanece → lado derecho sólido
	local statsGradient = Instance.new("UIGradient")
	statsGradient.Parent = statsBar
	statsGradient.Rotation = 180 -- derecha a izquierda
	statsGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),      -- derecho: visible
		NumberSequenceKeypoint.new(0.5, 0.15), -- medio: casi visible
		NumberSequenceKeypoint.new(0.85, 0.6), -- casi al borde: se desvanece
		NumberSequenceKeypoint.new(1, 1),      -- izquierdo (avatar): invisible
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = statsBar
	})

	-- Stats items
	local stats = {
		{ key = "followers", label = "Seguidores" },
		{ key = "friends", label = "Amigos" },
		{ key = "likes", label = "Likes" },
	}

	for _, stat in ipairs(stats) do
		local statContainer = Utils.createFrame({
			Size = UDim2.new(1, -8, 0, Config.STATS_ITEM_HEIGHT),
			ZIndex = 11,
			Parent = statsBar
		})
		Utils.addCorner(statContainer, 6)

		State.statsLabels[stat.key] = Utils.createLabel({
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 0, 4),
			Text = tostring(data[stat.key] or 0),
			TextColor3 = THEME.text,
			TextSize = L.fontSize.stat,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 11,
			Parent = statContainer
		})

		Utils.createLabel({
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 26),
			Text = stat.label,
			TextColor3 = THEME.muted,
			TextSize = L.fontSize.statLabel,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 11,
			Parent = statContainer
		})
	end

	-- Display Name (sobre el overlay)
	local nameYOffset = isDev and -50 or -46

	-- Contenedor vertical principal para nombre completo + username
	local nameMainContainer = Utils.createFrame({
		Size = UDim2.new(1, -L.statsWidth - 16, 0, 36),
		Position = UDim2.new(0, 10, 1, nameYOffset),
		BackgroundTransparency = 1,
		ZIndex = 25,
		Parent = avatarSection
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 0),
		Parent = nameMainContainer
	})

	-- Contenedor horizontal para displayName + check
	local nameContainer = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = nameMainContainer
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = nameContainer
	})

	local displayNameLabel = Utils.createLabel({
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = data.displayName,
		TextColor3 = playerColor,
		TextSize = L.fontSize.title,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = nameContainer
	})

	-- Developer shimmer en nombre (usa color base del jugador)
	if isDev then
		DevSystem.applyTextShimmer(displayNameLabel, playerColor)

		-- Check separado (NO recibe gradient)
		Utils.createLabel({
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "",
			TextColor3 = playerColor,
			TextSize = L.fontSize.title,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
			Parent = nameContainer
		})
	end

	-- Username (dentro del mismo contenedor vertical)
	Utils.createLabel({
		Size = UDim2.new(1, 0, 0, 16),
		Text = "@" .. data.username,
		TextColor3 = THEME.muted,
		TextSize = L.fontSize.subtitle + 1,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = nameMainContainer
	})


	-- Badge de developer junto al nombre
	if isDev and badgeInfo then
		local badge = DevSystem.createBadge(avatarSection, badgeInfo, L)
		badge.Position = UDim2.new(0, 10, 1, nameYOffset - 20)
		badge.ZIndex = 26
	end

	-- Like buttons (solo si no es el propio jugador)
	if data.userId ~= player.UserId then
		local likeContainer = Utils.createFrame({
			Size = UDim2.new(0, L.likeButtonSize + 4, 0, (L.likeButtonSize * 2) + 8),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			ZIndex = 15,
			Parent = avatarSection
		})

		Utils.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 6),
			Parent = likeContainer
		})

		local function createLikeButton(imageId, onClick)
			local btn = Utils.create("ImageButton", {
				Size = UDim2.new(0, L.likeButtonSize, 0, L.likeButtonSize),
				BackgroundColor3 = Color3.fromRGB(20, 20, 25),
				BackgroundTransparency = 0.3,
				Image = imageId,
				ScaleType = Enum.ScaleType.Fit,
				AutoButtonColor = false,
				ZIndex = 15,
				Parent = likeContainer
			})
			Utils.addCorner(btn, L.likeButtonSize / 2)

			Utils.addConnection(btn.MouseButton1Click:Connect(onClick))
			Utils.addConnection(btn.MouseEnter:Connect(function()
				safeTween(btn, { ImageTransparency = 0.3, BackgroundTransparency = 0.1 }, Config.ANIM_FAST)
			end))
			Utils.addConnection(btn.MouseLeave:Connect(function()
				safeTween(btn, { ImageTransparency = 0, BackgroundTransparency = 0.3 }, Config.ANIM_FAST)
			end))
			return btn
		end

		createLikeButton("rbxassetid://118393090095169", function()
			if State.target and State.userId ~= player.UserId then
				LikesSystem.giveLike(State.target)
			end
		end)

		createLikeButton("rbxassetid://9412108006", function()
			if State.target and State.userId ~= player.UserId then
				LikesSystem.giveSuperLike(State.target)
			end
		end)
	end

	return avatarSection
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR PANEL PRINCIPAL
-- ═══════════════════════════════════════════════════════════════
local function createPanel(data)
	if State.closing or not data or not data.userId then return end

	local L = Layout.get()
	local isDev = DevSystem.isDeveloper(data.userId)

	local screenGui = Utils.createScreenGui(playerGui)

	State.container = Utils.createFrame({
		Size = UDim2.new(0, L.panelWidth, 0, L.panelHeight),
		Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50),
		BackgroundTransparency = 1,
		Parent = screenGui
	})

	-- Obtener target y color
	local target
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p.UserId == data.userId then target = p break end
	end
	local playerColor = Utils.getPlayerColor(target, ColorEffects)
	State.target = target

	-- Badge info DESPUÉS de tener playerColor
	local badgeInfo = DevSystem.getBadgeInfo(data.userId, playerColor)

	-- ─── Drag Handle ───
	local dragHandle = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, L.dragHandleH),
		Parent = State.container
	})
	Utils.addCorner(dragHandle, L.cornerRadius)

	local dragIndicator = Utils.createFrame({
		Size = UDim2.new(0, 44, 0, 4),
		Position = UDim2.new(0.5, -22, 0.5, -2),
		BackgroundColor3 = playerColor,
		BackgroundTransparency = 0.25,
		Parent = dragHandle
	})
	Utils.addCorner(dragIndicator, 999)

	-- Drag logic
	local isDragging = false
	local dragStart, startPos

	Utils.addConnection(dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			State.dragging = true
			dragStart = input.Position
			startPos = State.container.Position

			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false
					task.delay(0.15, function() State.dragging = false end)
					endConn:Disconnect()
				end
			end)
		end
	end))

	Utils.addConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if not isDragging or not State.container or not State.container.Parent then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			State.container.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))

	-- ─── Panel Container (glassmorphism) ───
	local panelContainerY = L.dragHandleH + 4
	local panelBgTransparency = isDev and 0.45 or 0.25
	local panelContainer = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, L.panelHeight),
		Position = UDim2.new(0, 0, 0, panelContainerY),
		BackgroundColor3 = Color3.fromRGB(14, 14, 20),
		BackgroundTransparency = panelBgTransparency,
		ClipsDescendants = true,
		Parent = State.container
	})
	Utils.addCorner(panelContainer, L.cornerRadius)

	-- Glass layers
	Glass.applyToPanel(panelContainer, playerColor, L, isDev)

	-- Borde principal
	local panelStroke = Utils.addStroke(panelContainer, playerColor, 1.5, 0.3)

	-- Imagen de fondo (developer o vacía)
	local panelImage = Utils.create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 1,
		ClipsDescendants = true,
		Parent = panelContainer
	})
	Utils.addCorner(panelImage, L.cornerRadius)

	-- Developer: fondo + borde animado
	if isDev and badgeInfo then
		DevSystem.applyPanelBackground(panelImage, panelContainer, badgeInfo)
		DevSystem.applyBorderGradient(panelStroke, 1.5, playerColor)
	end

	-- Shadow
	Utils.create("ImageLabel", {
		Size = UDim2.new(1, 30, 1, 30),
		Position = UDim2.new(0, -15, 0, -15),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = -1,
		Parent = panelContainer
	})

	-- ─── Scrolling Content ───
	local panel = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = playerColor,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		ScrollingEnabled = true,
		Active = true,
		ZIndex = 5,
		Parent = panelContainer
	})

	Utils.create("UIPadding", {
		PaddingTop = UDim.new(0, 0),
		PaddingBottom = UDim.new(0, 0),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
		Parent = panel
	})

	-- Secciones
	createAvatarSection(panel, data, playerColor)

	-- Listener de likes
	if State.target then
		local lastLikesValue = State.target:GetAttribute("TotalLikes") or 0
		local isAnimating = false

		Utils.addConnection(State.target:GetAttributeChangedSignal("TotalLikes"):Connect(function()
			local newLikes = State.target:GetAttribute("TotalLikes") or 0
			if newLikes == lastLikesValue then return end

			if State.statsLabels and State.statsLabels.likes and State.statsLabels.likes.Parent then
				State.statsLabels.likes.Text = tostring(newLikes)

				if newLikes > lastLikesValue and not isAnimating then
					isAnimating = true
					local originalSize = State.statsLabels.likes.TextSize
					local sizeIncrease = (newLikes - lastLikesValue >= 10) and 6 or 4

					safeTween(State.statsLabels.likes, { TextSize = originalSize + sizeIncrease }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					task.delay(0.2, function()
						if State.statsLabels.likes and State.statsLabels.likes.Parent then
							safeTween(State.statsLabels.likes, { TextSize = originalSize }, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
							task.delay(0.2, function() isAnimating = false end)
						else
							isAnimating = false
						end
					end)
				end
			end
			lastLikesValue = newLikes
		end))

		if State.statsLabels and State.statsLabels.likes then
			State.statsLabels.likes.Text = tostring(lastLikesValue)
		end
	end

	createButtonsSection(panel, State.target, playerColor)

	-- ─── Animación de entrada ───
	State.container.Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50)

	task.defer(function()
		safeTween(State.container, {
			Position = UDim2.new(0.5, -L.panelWidth / 2, 1, -(L.panelHeight + L.bottomOffset))
		}, 0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end)

	Utils.startAutoRefresh(State, Remotes)
	return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- CERRAR PANEL
-- ═══════════════════════════════════════════════════════════════
function closePanel()
	if State.closing or not State.ui then return end
	State.closing = true

	if State.refreshThread then task.cancel(State.refreshThread) end

	pcall(function()
		if Remotes.Systems.GlobalModalManager then
			Remotes.Systems.GlobalModalManager.isUserPanelOpen = false
		end
	end)

	local L = Layout.get()

	if State.container then
		safeTween(State.container, {
			Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50)
		}, 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	task.delay(0.45, function()
		-- Limpiar tweens activos
		for k, tw in pairs(activeTweens) do
			pcall(function() tw:Cancel() end)
			activeTweens[k] = nil
		end

		-- Limpiar conexiones de developer rotations
		for _, conn in ipairs(devRotationConns) do
			pcall(function() conn:Disconnect() end)
		end
		table.clear(devRotationConns)

		Utils.clearConnections()
		Utils.detachHighlight(State)
		if State.ui then State.ui:Destroy() end

		State.ui = nil
		State.userId = nil
		State.target = nil
		State.container = nil
		State.panel = nil
		State.buttonsFrame = nil
		State.buttonsOverlay = nil
		State.dynamicSection = nil
		State.statsLabels = {}
		State.currentView = "buttons"
		State.isLoadingDynamic = false
		State.dragging = false
		State.closing = false
		State.isPanelOpening = false
		State.playerColor = nil
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- ABRIR PANEL
-- ═══════════════════════════════════════════════════════════════
local function openPanel(target)
	if State.isPanelOpening or State.closing or not target then return end
	State.isPanelOpening = true

	if State.refreshThread then task.cancel(State.refreshThread) end

	Utils.detachHighlight(State)
	Utils.clearConnections()

	-- Limpiar tweens previos
	for k, tw in pairs(activeTweens) do
		pcall(function() tw:Cancel() end)
		activeTweens[k] = nil
	end
	for _, conn in ipairs(devRotationConns) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(devRotationConns)

	if State.ui then State.ui:Destroy() end

	State.userId = target.UserId
	State.target = target

	local playerColor = Utils.getPlayerColor(target, ColorEffects)

	local cachedData = State.userDataCache[target.UserId]
	local hasCachedData = cachedData and (tick() - cachedData.lastUpdate) < 30

	local initialData = {
		userId = target.UserId,
		username = target.Name,
		displayName = target.DisplayName,
		avatar = Utils.getAvatarImage(target.UserId),
		followers = hasCachedData and cachedData.followers or 0,
		friends = hasCachedData and cachedData.friends or 0,
		likes = 0
	}

	local success, result = pcall(function()
		return createPanel(initialData)
	end)

	if success and result then
		State.ui = result
		State.target = target

		Utils.attachHighlight(target, State, ColorEffects)

		pcall(function()
			if Remotes.Systems.GlobalModalManager then
				if Remotes.Systems.GlobalModalManager.isEmoteOpen == nil then
					Remotes.Systems.GlobalModalManager.isEmoteOpen = false
				end
				Remotes.Systems.GlobalModalManager.isUserPanelOpen = true
			end
		end)

		-- Fetch async de datos reales
		task.spawn(function()
			local ok, data = pcall(function()
				return Remotes.Remotes.GetUserData:InvokeServer(target.UserId)
			end)

			if ok and data and State.ui then
				State.userDataCache[target.UserId] = {
					followers = data.followers or 0,
					friends = data.friends or 0,
					lastUpdate = tick()
				}
				Utils.updateStats(data, true, State)
			end
		end)

		State.isPanelOpening = false
	else
		State.isPanelOpening = false
		warn("[UserPanel] Error creando panel:", result)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- SETUP INPUT Y CURSOR
-- ═══════════════════════════════════════════════════════════════
InputHandler.setupListeners(openPanel, closePanel, State)
InputHandler.setupCursor(State, Services)

-- ═══════════════════════════════════════════════════════════════
-- EXPORT
-- ═══════════════════════════════════════════════════════════════
_G.CloseUserPanel = closePanel

return {
	open = openPanel,
	close = closePanel
}