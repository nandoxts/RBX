--[[
	═══════════════════════════════════════════════════════════
	PANEL VIEW - Construcción visual del UserPanel
	═══════════════════════════════════════════════════════════
	• Glassmorphism, DevSystem, Avatar, Botones, Dynamic Section
	• Panel creation/destruction centralizado
	• Optimizado: cache de layout, batch tweens, defer visual
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PanelView = {}

-- ═══════════════════════════════════════════════════════════════
-- DEPENDENCIAS (inyectadas via init)
-- ═══════════════════════════════════════════════════════════════
local Config, State, Utils, GroupRoles, Remotes
local Services, NotificationSystem, ColorEffects, Gifting, THEME
local player, playerGui

-- Cache de layout por sesión de panel (evita recalcular)
local cachedLayout = nil
local activeTweens = {}
local devRotationConns = {}

function PanelView.init(config, state, utils, groupRoles, remotes)
	Config = config
	State = state
	Utils = utils
	GroupRoles = groupRoles
	Remotes = remotes
	Services = remotes.Services
	NotificationSystem = remotes.Systems.NotificationSystem
	ColorEffects = remotes.Systems.ColorEffects
	Gifting = remotes.Gifting.GiftingRemote
	THEME = config.THEME
	player = Services.Player
	playerGui = Services.PlayerGui
end

-- ═══════════════════════════════════════════════════════════════
-- LAYOUT CACHE (solo recalcula si cambia dispositivo)
-- ═══════════════════════════════════════════════════════════════
local lastDeviceType = nil

local function detectDevice()
	local UIS = game:GetService("UserInputService")
	local touch = UIS.TouchEnabled
	local mouseOn = UIS.MouseEnabled
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if touch and not mouseOn then
		return vp.X >= 1024 and "tablet" or "mobile"
	end
	return "desktop"
end

local function getLayout()
	local device = detectDevice()
	if cachedLayout and device == lastDeviceType then return cachedLayout end
	lastDeviceType = device

	if device == "mobile" then
		cachedLayout = {
			panelWidth = math.min(Config.PANEL_WIDTH, 280),
			panelHeight = Config.PANEL_HEIGHT - 20,
			avatarHeight = Config.AVATAR_HEIGHT - 10,
			buttonHeight = Config.BUTTON_HEIGHT - 2,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = math.max(Config.PANEL_PADDING - 2, 6),
			fontSize = { title = 14, subtitle = 9, stat = 11, statLabel = 7, button = 12 },
			dragHandleH = 24, cardSize = Config.CARD_SIZE - 4,
			statsWidth = Config.STATS_WIDTH - 8, cornerRadius = 14,
			bottomOffset = 60, likeButtonSize = 22,
		}
	elseif device == "tablet" then
		cachedLayout = {
			panelWidth = Config.PANEL_WIDTH + 20,
			panelHeight = Config.PANEL_HEIGHT,
			avatarHeight = Config.AVATAR_HEIGHT,
			buttonHeight = Config.BUTTON_HEIGHT,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = Config.PANEL_PADDING,
			fontSize = { title = 17, subtitle = 11, stat = 14, statLabel = 8, button = 13 },
			dragHandleH = 20, cardSize = Config.CARD_SIZE,
			statsWidth = Config.STATS_WIDTH, cornerRadius = 14,
			bottomOffset = 80, likeButtonSize = 26,
		}
	else
		cachedLayout = {
			panelWidth = Config.PANEL_WIDTH,
			panelHeight = Config.PANEL_HEIGHT,
			avatarHeight = Config.AVATAR_HEIGHT,
			buttonHeight = Config.BUTTON_HEIGHT,
			buttonGap = Config.BUTTON_GAP,
			panelPadding = Config.PANEL_PADDING,
			fontSize = { title = 18, subtitle = 13, stat = 16, statLabel = 9, button = 14 },
			dragHandleH = 18, cardSize = Config.CARD_SIZE,
			statsWidth = Config.STATS_WIDTH, cornerRadius = 12,
			bottomOffset = 90, likeButtonSize = 28,
		}
	end
	return cachedLayout
end

PanelView.getLayout = getLayout

-- ═══════════════════════════════════════════════════════════════
-- TWEEN HELPER (cancelación automática por instancia)
-- ═══════════════════════════════════════════════════════════════
local function safeTween(inst, props, duration, style, dir)
	if not inst or not inst.Parent then return end
	local key = tostring(inst)
	local prev = activeTweens[key]
	if prev then prev:Cancel() end
	local tw = Utils.tween(inst, props, duration or Config.ANIM_FAST, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut)
	activeTweens[key] = tw
	return tw
end

PanelView.safeTween = safeTween

-- ═══════════════════════════════════════════════════════════════
-- DEVELOPER SYSTEM
-- ═══════════════════════════════════════════════════════════════
local Dev = {}

function Dev.isDeveloper(userId)
	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == userId then return true end
	end
	return false
end

function Dev.getBadgeInfo(userId, baseColor)
	if not Dev.isDeveloper(userId) then return nil end
	baseColor = baseColor or THEME.accent
	return {
		text = "OWNER", color = baseColor,
		glowColor = baseColor, icon = "rbxassetid://79346090571461",
	}
end

function Dev.applyBorderGradient(stroke, speed, baseColor)
	speed = speed or 1.5
	baseColor = baseColor or Color3.new(1, 1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = stroke
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, baseColor),
		ColorSequenceKeypoint.new(0.33, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.66, baseColor),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	local elapsed = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not stroke.Parent then return end
		elapsed = elapsed + (dt * speed * 60)
		gradient.Rotation = elapsed % 360
	end)
	table.insert(devRotationConns, conn)
	Utils.addConnection(conn)
	return gradient
end

function Dev.applyTextShimmer(label, baseColor)
	baseColor = baseColor or THEME.accent
	local dark = Color3.new(baseColor.R * 0.5, baseColor.G * 0.5, baseColor.B * 0.5)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = label
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, baseColor),
		ColorSequenceKeypoint.new(0.4, dark),
		ColorSequenceKeypoint.new(0.6, baseColor),
		ColorSequenceKeypoint.new(1, baseColor),
	})
	gradient.Offset = Vector2.new(-1, 0)
	TweenService:Create(gradient, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1, 0) }):Play()
	return gradient
end

function Dev.createBadge(parent, badgeInfo, L)
	local badge = Utils.createFrame({ Size = UDim2.new(0, 48, 0, 18), BackgroundColor3 = badgeInfo.color, BackgroundTransparency = 0.45, Parent = parent })
	Utils.addCorner(badge, 9)
	Utils.addStroke(badge, badgeInfo.glowColor, 1, 0.4)
	Utils.createLabel({ Size = UDim2.new(1, 0, 1, 0), Text = badgeInfo.text, TextColor3 = THEME.text, TextSize = L.fontSize.statLabel + 1, Font = Enum.Font.GothamBlack, Parent = badge })
	return badge
end

function Dev.applyPanelBackground(panelImage, _, badgeInfo)
	panelImage.Image = badgeInfo.icon
	panelImage.ScaleType = Enum.ScaleType.Crop
	panelImage.ImageTransparency = 0.35
	panelImage.BackgroundTransparency = 1
	local g = Instance.new("UIGradient")
	g.Parent = panelImage
	g.Rotation = 90
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 0.75),
	})
end

PanelView.Dev = Dev

-- ═══════════════════════════════════════════════════════════════
-- GLASSMORPHISM
-- ═══════════════════════════════════════════════════════════════
local function applyGlass(container, playerColor, L, isDev)
	local baseT = isDev and 0.65 or 0.35
	local colorT = isDev and 0.95 or 0.88

	local base = Utils.createFrame({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(12, 12, 18), BackgroundTransparency = baseT, ZIndex = 0, Parent = container })
	Utils.addCorner(base, L.cornerRadius)

	local cLayer = Utils.createFrame({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = playerColor, BackgroundTransparency = colorT, ZIndex = 0, Parent = container })
	Utils.addCorner(cLayer, L.cornerRadius)

	local g = Instance.new("UIGradient")
	g.Parent = cLayer
	g.Rotation = 160
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.95),
		NumberSequenceKeypoint.new(1, 0.85),
	})
end

-- ═══════════════════════════════════════════════════════════════
-- BOTÓN CON GLASS EFFECT
-- ═══════════════════════════════════════════════════════════════
local function createButton(parent, text, layoutOrder, accentColor)
	local L = getLayout()
	local container = Utils.createFrame({ Size = UDim2.new(1, 0, 0, L.buttonHeight), LayoutOrder = layoutOrder, Parent = parent })

	local btnColor = THEME.elevated:Lerp(accentColor or THEME.accent, 0.08)
	local btn = Utils.create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = btnColor, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = container
	})
	Utils.addCorner(btn, 10)
	Utils.addStroke(btn, accentColor or THEME.accent, 1, 0.75)

	local g = Instance.new("UIGradient")
	g.Parent = btn; g.Rotation = 90
	g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.25) })

	local rippleCont = Utils.createFrame({ Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true, Parent = btn })
	Utils.addCorner(rippleCont, 10)

	local label = Utils.createLabel({ Size = UDim2.new(1, 0, 1, 0), Text = text, TextSize = L.fontSize.button, Font = Enum.Font.GothamBold, TextColor3 = THEME.text, Parent = btn })

	local hoverColor = Utils.darkenColor(accentColor or THEME.accent, 0.25)
	Utils.addConnection(btn.MouseEnter:Connect(function() safeTween(btn, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.05 }, Config.ANIM_FAST) end))
	Utils.addConnection(btn.MouseLeave:Connect(function() safeTween(btn, { BackgroundColor3 = btnColor, BackgroundTransparency = 0.15 }, Config.ANIM_FAST) end))
	Utils.addConnection(btn.MouseButton1Click:Connect(function(x, y) Utils.createRipple(btn, rippleCont, x, y) end))

	return btn, label
end

-- ═══════════════════════════════════════════════════════════════
-- DYNAMIC SECTION (Donaciones / Regalar Pase)
-- ═══════════════════════════════════════════════════════════════
local function renderDynamicSection(viewType, items, targetName, playerColor)
	if not State.dynamicSection or not State.dynamicSection.Parent then return end
	local L = getLayout()

	for _, child in ipairs(State.dynamicSection:GetChildren()) do child:Destroy() end

	-- Header + Back
	local header = Utils.createFrame({ Size = UDim2.new(1, 0, 0, L.fontSize.title + 14), Parent = State.dynamicSection })
	Utils.addCorner(header, 8)

	local backBase = THEME.elevated:Lerp(playerColor or THEME.accent, 0.15)
	local backBtn = Utils.create("TextButton", {
		Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = backBase, BackgroundTransparency = 0.1,
		Text = "‹", TextColor3 = THEME.text, TextSize = 16, Font = Enum.Font.GothamBold,
		AutoButtonColor = false, ZIndex = 70, Parent = header
	})
	Utils.addCorner(backBtn, 8)
	Utils.addStroke(backBtn, playerColor or THEME.accent, 1, 0.8)

	local backHover = Utils.darkenColor(playerColor or THEME.accent, 0.25)
	Utils.addConnection(backBtn.MouseEnter:Connect(function() safeTween(backBtn, { BackgroundColor3 = backHover }, Config.ANIM_FAST) end))
	Utils.addConnection(backBtn.MouseLeave:Connect(function() safeTween(backBtn, { BackgroundColor3 = backBase }, Config.ANIM_FAST) end))

	Utils.addConnection(backBtn.MouseButton1Click:Connect(function()
		if not State.dynamicSection then return end
		safeTween(State.dynamicSection, { Position = UDim2.new(1, 0, 0, State.dynamicSection.Position.Y.Offset) }, 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		if State.buttonsFrame then
			State.buttonsFrame.Visible = true
			State.buttonsFrame.Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset)
			safeTween(State.buttonsFrame, { Position = UDim2.new(0, L.panelPadding, 0, State.buttonsFrame.Position.Y.Offset) }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end
		task.delay(0.25, function()
			if State.dynamicSection then State.dynamicSection:Destroy(); State.dynamicSection = nil end
			State.currentView = "buttons"
			State.isLoadingDynamic = false
		end)
	end))

	local title = viewType == "donations" and ("Donar a " .. (targetName or "Usuario")) or "Regalar Pase"
	Utils.createLabel({
		Size = UDim2.new(1, -36, 0, L.fontSize.title + 14), Position = UDim2.new(0, 34, 0, 0),
		Text = title, TextColor3 = THEME.text, TextSize = L.fontSize.title - 2,
		Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = header
	})

	-- Scroll horizontal
	local scrollTop = L.fontSize.title + 20
	local scroll = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -scrollTop), Position = UDim2.new(0, 0, 0, scrollTop),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = playerColor or THEME.accent, ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, L.cardSize + 14), ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = State.dynamicSection
	})
	Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 10), Parent = scroll })
	Utils.create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = scroll })

	if not items or #items == 0 then
		Utils.createLabel({ Size = UDim2.new(1, 0, 1, 0), Text = "No hay items disponibles", TextColor3 = THEME.muted, TextSize = L.fontSize.statLabel + 2, Parent = scroll })
		return
	end

	for i, item in ipairs(items) do
		local cardOuter = Utils.createFrame({ Size = UDim2.new(0, L.cardSize + 10, 0, L.cardSize + 10), LayoutOrder = i, Parent = scroll })
		Utils.addCorner(cardOuter, L.cardSize / 2)

		local circle = Utils.createFrame({
			Size = UDim2.new(0, L.cardSize, 0, L.cardSize), Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0,
			ClipsDescendants = true, Parent = cardOuter
		})
		Utils.addCorner(circle, L.cardSize / 2)
		local circleStroke = Utils.addStroke(circle, THEME.stroke, 1.5)

		local img = Utils.create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = item.icon or "", ScaleType = Enum.ScaleType.Crop, ZIndex = 1, Parent = circle })
		Utils.addCorner(img, L.cardSize / 2)

		-- Precio overlay
		local priceOverlay = Utils.createFrame({
			Size = UDim2.new(1, 0, 0.32, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.fromRGB(10, 10, 15), BackgroundTransparency = 0.25, ZIndex = 2, ClipsDescendants = true, Parent = circle
		})
		Utils.addCorner(priceOverlay, 6)

		local priceText = Utils.createLabel({ Size = UDim2.new(1, 0, 1, 0), Text = utf8.char(0xE002) .. tostring(item.price or 0), TextColor3 = THEME.accent, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 3, Parent = priceOverlay })

		-- Check pass (async)
		if item.hasPass == true then
			priceText.Text = "ADQUIRIDO"
			priceText.TextColor3 = Color3.fromRGB(100, 220, 100)
			priceOverlay.BackgroundTransparency = 0.4
		elseif item.hasPass == nil and item.passId then
			task.spawn(function()
				local ok, result = pcall(function()
					return viewType == "passes"
						and Remotes.Remotes.CheckGamePass:InvokeServer(item.passId, State.userId)
						or Remotes.Remotes.CheckGamePass:InvokeServer(item.passId)
				end)
				item.hasPass = (ok and result) or false
				if item.hasPass and priceText.Parent then
					priceText.Text = "ADQUIRIDO"
					priceText.TextColor3 = Color3.fromRGB(100, 220, 100)
					priceOverlay.BackgroundTransparency = 0.4
				end
			end)
		end

		-- Click
		local clickBtn = Utils.create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = cardOuter })
		local strokeHover = playerColor or THEME.accent

		Utils.addConnection(clickBtn.MouseEnter:Connect(function()
			safeTween(circleStroke, { Color = strokeHover, Thickness = 2.5 }, Config.ANIM_FAST)
			safeTween(circle, { Size = UDim2.new(0, L.cardSize + 4, 0, L.cardSize + 4) }, Config.ANIM_FAST)
		end))
		Utils.addConnection(clickBtn.MouseLeave:Connect(function()
			safeTween(circleStroke, { Color = THEME.stroke, Thickness = 1.5 }, Config.ANIM_FAST)
			safeTween(circle, { Size = UDim2.new(0, L.cardSize, 0, L.cardSize) }, Config.ANIM_FAST)
		end))

		Utils.addConnection(clickBtn.MouseButton1Click:Connect(function()
			if item.hasPass == true then
				if NotificationSystem then
					local msg = viewType == "passes" and "Esta persona ya tiene este pase" or "Ya compraste este pase"
					NotificationSystem:Info("Game Pass", msg, 2)
				end
			elseif item.passId then
				if viewType == "passes" then
					if not Gifting or not State.target or not State.target.UserId or not item.productId then return end
					local tid = State.target.UserId
					if type(tid) ~= "number" or tid == 0 then return end
					pcall(function() Gifting:FireServer({ item.passId, item.productId }, tid, State.target.Name, player.UserId) end)
				else
					pcall(function() Services.MarketplaceService:PromptGamePassPurchase(player, item.passId) end)
				end
			end
		end))
	end
end

local function showDynamicSection(viewType, items, targetName, playerColor)
	local L = getLayout()
	State.currentView = viewType

	if State.buttonsFrame then
		safeTween(State.buttonsFrame, { Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset) }, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		task.delay(0.3, function() if State.buttonsFrame then State.buttonsFrame.Visible = false end end)
	end

	if State.dynamicSection then State.dynamicSection:Destroy() end

	local startY = L.avatarHeight + 8
	local availH = math.max(80, State.panel.AbsoluteSize.Y - startY - L.panelPadding)

	State.dynamicSection = Utils.createFrame({ Size = UDim2.new(1, -2 * L.panelPadding, 0, availH), Position = UDim2.new(1, 0, 0, startY), ZIndex = 10, Parent = State.panel })
	renderDynamicSection(viewType, items, targetName, playerColor)
	safeTween(State.dynamicSection, { Position = UDim2.new(0, L.panelPadding, 0, startY) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	task.delay(0.3, function() State.isLoadingDynamic = false end)
end

-- ═══════════════════════════════════════════════════════════════
-- BUTTONS SECTION
-- ═══════════════════════════════════════════════════════════════
local function createButtonsSection(panel, target, playerColor)
	local L = getLayout()
	State.panel = panel

	local startY = L.avatarHeight + L.buttonGap
	local numBtns = (State.userId ~= player.UserId) and 4 or 3
	local btnsH = (L.buttonHeight * numBtns) + (L.buttonGap * (numBtns - 1))

	-- Overlay
	local overlayExt = 40
	local overlayY = L.avatarHeight - overlayExt
	local overlay = Utils.createFrame({ Size = UDim2.new(1, 0, 1, -overlayY), Position = UDim2.new(0, 0, 0, overlayY), BackgroundColor3 = Color3.fromRGB(6, 6, 10), BackgroundTransparency = 0.2, ZIndex = 2, ClipsDescendants = false, Parent = panel })
	Utils.addCorner(overlay, L.cornerRadius)
	State.buttonsOverlay = overlay

	local fade = Instance.new("UIGradient")
	fade.Parent = overlay; fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.4),
		NumberSequenceKeypoint.new(0.3, 0), NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(0.9, 0.4), NumberSequenceKeypoint.new(1, 1),
	})

	State.buttonsFrame = Utils.createFrame({ Size = UDim2.new(1, -2 * L.panelPadding, 0, btnsH + 8), Position = UDim2.new(0, L.panelPadding, 0, startY), ZIndex = 5, Parent = panel })
	Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, L.buttonGap), Parent = State.buttonsFrame })

	local SyncSystem = require(script.Parent.SyncSystem)
	local LikesSystem = require(script.Parent.LikesSystem)

	-- 1. Sincronizar
	local syncBtn = createButton(State.buttonsFrame, "Sincronizar", 1, playerColor)
	local syncDebounce = false
	Utils.addConnection(syncBtn.MouseButton1Click:Connect(function()
		if syncDebounce or not target then return end
		syncDebounce = true
		SyncSystem.syncWithPlayer(target)
		task.wait(0.5); syncDebounce = false
	end))

	-- 2. Ver Perfil
	local profileBtn = createButton(State.buttonsFrame, "Ver Perfil", 2, playerColor)
	Utils.addConnection(profileBtn.MouseButton1Click:Connect(function()
		if target then pcall(function() Services.GuiService:InspectPlayerFromUserId(target.UserId) end) end
	end))

	-- 3. Donar
	local donateBtn, donateLabel = createButton(State.buttonsFrame, "Donar", 3, playerColor)
	Utils.addConnection(donateBtn.MouseButton1Click:Connect(function()
		if not State.userId or State.isLoadingDynamic or State.dynamicSection then return end
		State.isLoadingDynamic = true
		donateBtn.Active = false; donateLabel.Text = "Cargando..."
		safeTween(donateBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

		task.spawn(function()
			local ok, donations = pcall(function() return Remotes.Remotes.GetUserDonations:InvokeServer(State.userId) end)
			if donateBtn and donateBtn.Parent then
				donateBtn.Active = true; donateLabel.Text = "Donar"
				safeTween(donateBtn, { BackgroundTransparency = 0.15 }, Config.ANIM_FAST)
			end
			if ok and donations then
				showDynamicSection("donations", donations, target and target.DisplayName, playerColor)
			else
				State.isLoadingDynamic = false
				if NotificationSystem then NotificationSystem:Error("Error", "No se pudo cargar donaciones", 2) end
			end
		end)
	end))

	-- 4. Regalar Pase
	if State.userId ~= player.UserId then
		local giftBtn, giftLabel = createButton(State.buttonsFrame, "Regalar Pase", 4, playerColor)
		Utils.addConnection(giftBtn.MouseButton1Click:Connect(function()
			if State.isLoadingDynamic or State.dynamicSection then return end
			State.isLoadingDynamic = true
			giftBtn.Active = false; giftLabel.Text = "Cargando..."
			safeTween(giftBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

			task.spawn(function()
				local ok, passes = pcall(function() return Remotes.Remotes.GetGamePasses:InvokeServer(State.userId) end)
				if giftBtn and giftBtn.Parent then
					giftBtn.Active = true; giftLabel.Text = "Regalar Pase"
					safeTween(giftBtn, { BackgroundTransparency = 0.15 }, Config.ANIM_FAST)
				end
				if ok and passes then
					showDynamicSection("passes", passes, nil, playerColor)
				else
					State.isLoadingDynamic = false
					if NotificationSystem then NotificationSystem:Error("Error", "No se pudieron cargar pases", 2) end
				end
			end)
		end))
	end
end

-- ═══════════════════════════════════════════════════════════════
-- AVATAR SECTION
-- ═══════════════════════════════════════════════════════════════
local function createAvatarSection(panel, data, playerColor)
	local L = getLayout()
	local isDev = Dev.isDeveloper(data.userId)
	local badgeInfo = Dev.getBadgeInfo(data.userId, playerColor)
	local LikesSystem = require(script.Parent.LikesSystem)

	local avatarSection = Utils.createFrame({ Size = UDim2.new(1, 0, 0, L.avatarHeight), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3, Parent = panel })

	-- Avatar
	local avatarImage = Utils.create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(Config.AVATAR_ZOOM, 0, Config.AVATAR_ZOOM, 0), BackgroundTransparency = 1,
		Image = data.avatar or "", ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = avatarSection
	})
	Utils.asyncLoadAvatar(data.userId, avatarImage)

	-- Stats sidebar
	local statsBar = Utils.createFrame({
		Size = UDim2.new(0, L.statsWidth, 1, 0), Position = UDim2.new(1, -L.statsWidth, 0, 0),
		BackgroundColor3 = Color3.fromRGB(8, 8, 12), BackgroundTransparency = 0.3, ZIndex = 10,
		ClipsDescendants = true, Parent = avatarSection
	})
	Utils.addCorner(statsBar, L.cornerRadius)

	local sg = Instance.new("UIGradient")
	sg.Parent = statsBar; sg.Rotation = 180
	sg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(0.85, 0.6), NumberSequenceKeypoint.new(1, 1),
	})

	Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), Parent = statsBar })

	for _, stat in ipairs({ { key = "followers", label = "Seguidores" }, { key = "friends", label = "Amigos" }, { key = "likes", label = "Likes" } }) do
		local sc = Utils.createFrame({ Size = UDim2.new(1, -8, 0, Config.STATS_ITEM_HEIGHT), ZIndex = 11, Parent = statsBar })
		Utils.addCorner(sc, 6)
		State.statsLabels[stat.key] = Utils.createLabel({ Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 4), Text = tostring(data[stat.key] or 0), TextColor3 = THEME.text, TextSize = L.fontSize.stat, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 11, Parent = sc })
		Utils.createLabel({ Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 26), Text = stat.label, TextColor3 = THEME.muted, TextSize = L.fontSize.statLabel, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 11, Parent = sc })
	end

	-- Nombres
	local nameY = isDev and -50 or -46
	local nameMain = Utils.createFrame({ Size = UDim2.new(1, -L.statsWidth - 16, 0, 36), Position = UDim2.new(0, 10, 1, nameY), BackgroundTransparency = 1, ZIndex = 25, Parent = avatarSection })
	Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 0), Parent = nameMain })

	local nameCont = Utils.createFrame({ Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1, Parent = nameMain })
	Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), Parent = nameCont })

	local dnLabel = Utils.createLabel({ Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = data.displayName, TextColor3 = playerColor, TextSize = L.fontSize.title, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, Parent = nameCont })

	if isDev then
		Dev.applyTextShimmer(dnLabel, playerColor)
		Utils.createLabel({ Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextColor3 = playerColor, TextSize = L.fontSize.title, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = nameCont })
	end

	Utils.createLabel({ Size = UDim2.new(1, 0, 0, 16), Text = "@" .. data.username, TextColor3 = THEME.muted, TextSize = L.fontSize.subtitle + 1, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2, Parent = nameMain })

	if isDev and badgeInfo then
		local badge = Dev.createBadge(avatarSection, badgeInfo, L)
		badge.Position = UDim2.new(0, 10, 1, nameY - 20); badge.ZIndex = 26
	end

	-- Like buttons
	if data.userId ~= player.UserId then
		local likeCont = Utils.createFrame({ Size = UDim2.new(0, L.likeButtonSize + 4, 0, (L.likeButtonSize * 2) + 8), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, ZIndex = 15, Parent = avatarSection })
		Utils.create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 6), Parent = likeCont })

		local function mkLikeBtn(imgId, onClick)
			local b = Utils.create("ImageButton", { Size = UDim2.new(0, L.likeButtonSize, 0, L.likeButtonSize), BackgroundColor3 = Color3.fromRGB(20, 20, 25), BackgroundTransparency = 0.3, Image = imgId, ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, ZIndex = 15, Parent = likeCont })
			Utils.addCorner(b, L.likeButtonSize / 2)
			Utils.addConnection(b.MouseButton1Click:Connect(onClick))
			Utils.addConnection(b.MouseEnter:Connect(function() safeTween(b, { ImageTransparency = 0.3, BackgroundTransparency = 0.1 }, Config.ANIM_FAST) end))
			Utils.addConnection(b.MouseLeave:Connect(function() safeTween(b, { ImageTransparency = 0, BackgroundTransparency = 0.3 }, Config.ANIM_FAST) end))
			return b
		end

		mkLikeBtn("rbxassetid://118393090095169", function()
			if State.target and State.userId ~= player.UserId then LikesSystem.giveLike(State.target) end
		end)
		mkLikeBtn("rbxassetid://9412108006", function()
			if State.target and State.userId ~= player.UserId then LikesSystem.giveSuperLike(State.target) end
		end)
	end

	return avatarSection
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR PANEL COMPLETO
-- ═══════════════════════════════════════════════════════════════
function PanelView.createPanel(data)
	if State.closing or not data or not data.userId then return nil end

	local L = getLayout()
	local isDev = Dev.isDeveloper(data.userId)

	local screenGui = Utils.createScreenGui(playerGui)

	State.container = Utils.createFrame({ Size = UDim2.new(0, L.panelWidth, 0, L.panelHeight), Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50), BackgroundTransparency = 1, Parent = screenGui })

	local target
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p.UserId == data.userId then target = p; break end
	end
	local playerColor = Utils.getPlayerColor(target, ColorEffects)
	State.target = target

	local badgeInfo = Dev.getBadgeInfo(data.userId, playerColor)

	-- Drag Handle
	local dragHandle = Utils.createFrame({ Size = UDim2.new(1, 0, 0, L.dragHandleH), Parent = State.container })
	Utils.addCorner(dragHandle, L.cornerRadius)

	local dragInd = Utils.createFrame({ Size = UDim2.new(0, 44, 0, 4), Position = UDim2.new(0.5, -22, 0.5, -2), BackgroundColor3 = playerColor, BackgroundTransparency = 0.25, Parent = dragHandle })
	Utils.addCorner(dragInd, 999)

	-- Drag logic
	local isDragging = false
	local dragStart, startPos

	Utils.addConnection(dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true; State.dragging = true
			dragStart = input.Position; startPos = State.container.Position
			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false; task.delay(0.15, function() State.dragging = false end); endConn:Disconnect()
				end
			end)
		end
	end))

	Utils.addConnection(Services.UserInputService.InputChanged:Connect(function(input)
		if not isDragging or not State.container or not State.container.Parent then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
			State.container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))

	-- Panel container
	local pY = L.dragHandleH + 4
	local pBgT = isDev and 0.45 or 0.25
	local panelContainer = Utils.createFrame({ Size = UDim2.new(1, 0, 0, L.panelHeight), Position = UDim2.new(0, 0, 0, pY), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BackgroundTransparency = pBgT, ClipsDescendants = true, Parent = State.container })
	Utils.addCorner(panelContainer, L.cornerRadius)

	applyGlass(panelContainer, playerColor, L, isDev)

	local panelStroke = Utils.addStroke(panelContainer, playerColor, 1.5, 0.3)

	local panelImage = Utils.create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Image = "", ImageTransparency = 0.6, ScaleType = Enum.ScaleType.Crop, ZIndex = 1, ClipsDescendants = true, Parent = panelContainer })
	Utils.addCorner(panelImage, L.cornerRadius)

	if isDev and badgeInfo then
		Dev.applyPanelBackground(panelImage, panelContainer, badgeInfo)
		Dev.applyBorderGradient(panelStroke, 1.5, playerColor)
	end

	-- Shadow (defer - no crítico para primer frame)
	task.defer(function()
		if not panelContainer.Parent then return end
		Utils.create("ImageLabel", { Size = UDim2.new(1, 30, 1, 30), Position = UDim2.new(0, -15, 0, -15), BackgroundTransparency = 1, Image = "rbxassetid://5554236805", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(23, 23, 277, 277), ZIndex = -1, Parent = panelContainer })
	end)

	-- ScrollingFrame
	local panel = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = playerColor,
		ScrollBarImageTransparency = 0.5, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0), ClipsDescendants = true, ScrollingEnabled = true,
		Active = true, ZIndex = 5, Parent = panelContainer
	})
	Utils.create("UIPadding", { PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), Parent = panel })

	createAvatarSection(panel, data, playerColor)

	-- Likes listener
	if State.target then
		local lastLikes = State.target:GetAttribute("TotalLikes") or 0
		local animating = false

		Utils.addConnection(State.target:GetAttributeChangedSignal("TotalLikes"):Connect(function()
			local nl = State.target:GetAttribute("TotalLikes") or 0
			if nl == lastLikes then return end
			if State.statsLabels and State.statsLabels.likes and State.statsLabels.likes.Parent then
				State.statsLabels.likes.Text = tostring(nl)
				if nl > lastLikes and not animating then
					animating = true
					local orig = State.statsLabels.likes.TextSize
					local bump = (nl - lastLikes >= 10) and 6 or 4
					safeTween(State.statsLabels.likes, { TextSize = orig + bump }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					task.delay(0.2, function()
						if State.statsLabels.likes and State.statsLabels.likes.Parent then
							safeTween(State.statsLabels.likes, { TextSize = orig }, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
							task.delay(0.2, function() animating = false end)
						else animating = false end
					end)
				end
			end
			lastLikes = nl
		end))

		if State.statsLabels and State.statsLabels.likes then
			State.statsLabels.likes.Text = tostring(lastLikes)
		end
	end

	createButtonsSection(panel, State.target, playerColor)

	-- Entrada animada
	State.container.Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50)
	task.defer(function()
		safeTween(State.container, { Position = UDim2.new(0.5, -L.panelWidth / 2, 1, -(L.panelHeight + L.bottomOffset)) }, 0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end)

	Utils.startAutoRefresh(State, Remotes)
	return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════
function PanelView.cleanupTweens()
	for k, tw in pairs(activeTweens) do
		pcall(function() tw:Cancel() end)
		activeTweens[k] = nil
	end
	for _, conn in ipairs(devRotationConns) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(devRotationConns)
end

function PanelView.invalidateLayoutCache()
	cachedLayout = nil
	lastDeviceType = nil
end

return PanelView