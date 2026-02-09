--[[
	═══════════════════════════════════════════════════════════
	USER PANEL CLIENT - VERSIÓN MODULARIZADA
	═══════════════════════════════════════════════════════════
	Archivo principal que orquesta todos los módulos
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

-- Inicializar Remotes
local Remotes = RemotesSetup()

-- Aliases para facilitar acceso
local Services = Remotes.Services
local player = Services.Player
local playerGui = Services.PlayerGui
local camera = Services.Camera
local NotificationSystem = Remotes.Systems.NotificationSystem
local ColorEffects = Remotes.Systems.ColorEffects
local Gifting = Remotes.Gifting.GiftingRemote
local THEME = Config.THEME

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZAR MÓDULOS
-- ═══════════════════════════════════════════════════════════════
Utils.init(Config, State)
SyncSystem.init(Remotes, State)
LikesSystem.init(Remotes, State, Config)
EventListeners.init(Remotes)

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE UI (UI BUILDER INLINE)
-- ═══════════════════════════════════════════════════════════════

local function createButton(parent, text, layoutOrder, accentColor)
	local container = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, Config.BUTTON_HEIGHT),
		LayoutOrder = layoutOrder,
		Parent = parent
	})

	local btn = Utils.create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = THEME.elevated:Lerp(accentColor or THEME.accent, 0.12),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = container
	})
	Utils.addCorner(btn, Config.BUTTON_CORNER)
	Utils.addStroke(btn, accentColor or THEME.accent, 1, 0.7)

	local rippleContainer = Utils.createFrame({ Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true, Parent = btn })
	Utils.addCorner(rippleContainer, Config.BUTTON_CORNER)

	-- Tamaño de fuente responsivo
	local textSize = Config.IS_MOBILE and 13 or 14

	local label = Utils.createLabel({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text,
		TextSize = textSize,
		Font = Enum.Font.GothamBold,
		TextColor3 = THEME.text,
		Parent = btn
	})

	Utils.addConnection(btn.MouseEnter:Connect(function()
		local dark = Utils.darkenColor(accentColor or THEME.accent, 0.25)
		Utils.tween(btn, { BackgroundColor3 = dark }, Config.ANIM_FAST)
	end))
	Utils.addConnection(btn.MouseLeave:Connect(function()
		Utils.tween(btn, { BackgroundColor3 = THEME.elevated:Lerp(accentColor or THEME.accent, 0.12) }, Config.ANIM_FAST)
	end))
	Utils.addConnection(btn.MouseButton1Click:Connect(function(x, y)
		Utils.createRipple(btn, rippleContainer, x, y)
	end))

	return btn, label
end

local function renderDynamicSection(viewType, items, targetName, playerColor)
	if not State.dynamicSection or not State.dynamicSection.Parent then return end

	-- Limpiar contenido actual
	for _, child in ipairs(State.dynamicSection:GetChildren()) do
		child:Destroy()
	end

	-- Header con botón de volver
	local header = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, 28),
		Parent = State.dynamicSection
	})

	local backBtn = Utils.create("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundColor3 = THEME.elevated:Lerp(playerColor or THEME.accent, 0.12),
		Text = "‹",
		TextColor3 = THEME.text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		ZIndex = 70,
		Parent = header
	})
	Utils.addCorner(backBtn, 6)

	Utils.addConnection(backBtn.MouseEnter:Connect(function()
		local dark = Utils.darkenColor(playerColor or THEME.accent, 0.25)
		Utils.tween(backBtn, { BackgroundColor3 = dark }, Config.ANIM_FAST)
	end))
	Utils.addConnection(backBtn.MouseLeave:Connect(function()
		Utils.tween(backBtn, { BackgroundColor3 = THEME.elevated:Lerp(playerColor or THEME.accent, 0.12) }, Config.ANIM_FAST)
	end))
	Utils.addConnection(backBtn.MouseButton1Click:Connect(function()
		if State.dynamicSection then
			Utils.tween(State.dynamicSection, { Position = UDim2.new(1, 0, 0, State.dynamicSection.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
			task.delay(0.15, function()
				if State.dynamicSection then State.dynamicSection:Destroy() State.dynamicSection = nil end
				if State.buttonsFrame then
					State.buttonsFrame.Visible = true
					Utils.tween(State.buttonsFrame, { Position = UDim2.new(0, Config.PANEL_PADDING, 0, State.buttonsFrame.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
				end
				State.currentView = "buttons"
				State.isLoadingDynamic = false
			end)
		end
	end))

	local title = viewType == "donations" and ("Donar a " .. (targetName or "Usuario")) or "Regalar Pase"
	Utils.createLabel({
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.new(0, 34, 0, 0),
		Text = title,
		TextColor3 = THEME.text,
		TextSize = Config.IS_MOBILE and 14 or 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header
	})

	-- Scroll de cards
	local scroll = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = playerColor or THEME.accent,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, Config.CARD_SIZE + 10),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = State.dynamicSection
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		Parent = scroll
	})

	Utils.create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = scroll })

	if items and #items > 0 then
		for i, item in ipairs(items) do
			local card = Utils.createFrame({
				Size = UDim2.new(0, Config.CARD_SIZE + 8, 0, Config.CARD_SIZE + 8),
				LayoutOrder = i,
				Parent = scroll
			})

			local circle = Utils.createFrame({
				Size = UDim2.new(0, Config.CARD_SIZE, 0, Config.CARD_SIZE),
				Position = UDim2.new(0.5, -Config.CARD_SIZE / 2, 0.5, -Config.CARD_SIZE / 2),
				BackgroundColor3 = THEME.panel,
				BackgroundTransparency = 0,
				ClipsDescendants = true,
				Parent = card
			})
			Utils.addCorner(circle, Config.CARD_SIZE / 2)
			local circleStroke = Utils.addStroke(circle, THEME.stroke, 1.5)

			local img = Utils.create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = item.icon or "",
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 1,
				Parent = circle
			})
			Utils.addCorner(img, Config.CARD_SIZE / 2)

			local priceOverlay = Utils.createFrame({
				Size = UDim2.new(1, 0, 0.35, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = THEME.head,
				BackgroundTransparency = 0.3,
				ZIndex = 2,
				Parent = circle
			})

			local priceText = Utils.createLabel({
				Size = UDim2.new(1, 0, 1, 0),
				Text = utf8.char(0xE002) .. tostring(item.price or 0),
				TextColor3 = THEME.accent,
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				ZIndex = 3,
				Parent = priceOverlay
			})

			if item.hasPass == true then
				priceText.Text = "ADQUIRIDO"
				priceText.TextColor3 = Color3.fromRGB(100, 220, 100)
				priceOverlay.BackgroundColor3 = THEME.panel
				priceOverlay.BackgroundTransparency = 0.5
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
						priceOverlay.BackgroundColor3 = THEME.panel
						priceOverlay.BackgroundTransparency = 0.5
					end
				end)
			end

			local clickBtn = Utils.create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 10,
				Parent = card
			})

			Utils.addConnection(clickBtn.MouseEnter:Connect(function()
				Utils.tween(circleStroke, { Color = playerColor or THEME.accent, Thickness = 2.5 }, Config.ANIM_FAST)
			end))
			Utils.addConnection(clickBtn.MouseLeave:Connect(function()
				Utils.tween(circleStroke, { Color = THEME.stroke, Thickness = 1.5 }, Config.ANIM_FAST)
			end))

			Utils.addConnection(clickBtn.MouseButton1Click:Connect(function()
				if item.hasPass == true then
					if NotificationSystem then
						local message = viewType == "passes" and "Esta persona ya tiene este pase" or "Ya compraste este pase"
						NotificationSystem:Info("Game Pass", message, 2)
					end
				elseif item.passId then
					if viewType == "passes" then
						if not Gifting or not State.target or not item.productId then 
							print("[GIFTING] Falta algo - Gifting:", Gifting, "Target:", State.target, "ProductId:", item.productId)
							return 
						end
						print("[GIFTING] Enviando regalo - PassId:", item.passId, "ProductId:", item.productId, "Target:", State.target.Name)
						pcall(function()
							Gifting:FireServer(
								{item.passId, item.productId},
								State.target.UserId,
								player.Name,
								player.UserId
							)
						end)
					else
						pcall(function() Services.MarketplaceService:PromptGamePassPurchase(player, item.passId) end)
					end
				end
			end))
		end
	else
		Utils.createLabel({
			Size = UDim2.new(1, 0, 1, 0),
			Text = "No hay items disponibles",
			TextColor3 = THEME.muted,
			TextSize = 11,
			Parent = scroll
		})
	end
end

local function showDynamicSection(viewType, items, targetName, playerColor)
	State.currentView = viewType

	if State.buttonsFrame then
		Utils.tween(State.buttonsFrame, { Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
		task.delay(0.15, function()
			if State.buttonsFrame then State.buttonsFrame.Visible = false end
		end)
	end

	if State.dynamicSection then State.dynamicSection:Destroy() end

	local startY = Config.AVATAR_HEIGHT + 8
	local availableHeight = math.max(80, State.panel.AbsoluteSize.Y - startY - Config.PANEL_PADDING)

	State.dynamicSection = Utils.createFrame({
		Size = UDim2.new(1, -2 * Config.PANEL_PADDING, 0, availableHeight),
		Position = UDim2.new(1, 0, 0, startY),
		Parent = State.panel
	})

	renderDynamicSection(viewType, items, targetName, playerColor)
	Utils.tween(State.dynamicSection, { Position = UDim2.new(0, Config.PANEL_PADDING, 0, startY) }, 0.15, Enum.EasingStyle.Quad)

	task.delay(0.15, function()
		State.isLoadingDynamic = false
	end)
end

local function createButtonsSection(panel, target, playerColor)
	State.panel = panel

	local startY = Config.AVATAR_HEIGHT + Config.BUTTON_GAP
	local buttonsHeight = (Config.BUTTON_HEIGHT * 3) + (Config.BUTTON_GAP * 2)

	State.buttonsFrame = Utils.createFrame({
		Size = UDim2.new(1, -2 * Config.PANEL_PADDING, 0, buttonsHeight + 8),
		Position = UDim2.new(0, Config.PANEL_PADDING, 0, startY),
		Parent = panel
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Config.BUTTON_GAP),
		Parent = State.buttonsFrame
	})

	-- Ver Perfil
	local profileBtn = createButton(State.buttonsFrame, "Ver Perfil", 2, playerColor)
	Utils.addConnection(profileBtn.MouseButton1Click:Connect(function()
		if target then pcall(function() Services.GuiService:InspectPlayerFromUserId(target.UserId) end) end
	end))

	-- Donar
	local donateBtn, donateText = createButton(State.buttonsFrame, "Donar", 3, playerColor)
	Utils.addConnection(donateBtn.MouseButton1Click:Connect(function()
		if not State.userId or State.isLoadingDynamic or State.dynamicSection then return end
		State.isLoadingDynamic = true

		donateBtn.Active = false
		donateText.Text = "Cargando..."
		Utils.tween(donateBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

		task.spawn(function()
			local ok, donations = pcall(function()
				return Remotes.Remotes.GetUserDonations:InvokeServer(State.userId)
			end)

			if donateBtn and donateBtn.Parent then
				donateBtn.Active = true
				donateText.Text = "Donar"
				Utils.tween(donateBtn, { BackgroundTransparency = 0 }, Config.ANIM_FAST)
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

	-- Regalar Pase
	if State.userId ~= player.UserId then
		local giftBtn, giftText = createButton(State.buttonsFrame, "Regalar Pase", 4, playerColor)
		Utils.addConnection(giftBtn.MouseButton1Click:Connect(function()
			if State.isLoadingDynamic or State.dynamicSection then return end
			State.isLoadingDynamic = true

			giftBtn.Active = false
			giftText.Text = "Cargando..."
			Utils.tween(giftBtn, { BackgroundTransparency = 0.5 }, Config.ANIM_FAST)

			task.spawn(function()
				local ok, passes = pcall(function()
					return Remotes.Remotes.GetGamePasses:InvokeServer(State.userId)
				end)

				if giftBtn and giftBtn.Parent then
					giftBtn.Active = true
					giftText.Text = "Regalar Pase"
					Utils.tween(giftBtn, { BackgroundTransparency = 0 }, Config.ANIM_FAST)
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

	-- Sincronizar
	local syncBtn = createButton(State.buttonsFrame, "Sincronizar", 1, playerColor)
	local debounceSyncBtn = false
	Utils.addConnection(syncBtn.MouseButton1Click:Connect(function()
		if debounceSyncBtn or not target then return end
		debounceSyncBtn = true
		SyncSystem.syncWithPlayer(target)
		task.wait(0.5)
		debounceSyncBtn = false
	end))
end

-- ═══════════════════════════════════════════════════════════════
-- CREACION SECCION AVATAR
-- ═══════════════════════════════════════════════════════════════
local function createAvatarSection(panel, data, playerColor)
	local avatarSection = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, Config.AVATAR_HEIGHT),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = panel
	})

	-- Avatar Image
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

	-- Stats Sidebar
	local statsBar = Utils.createFrame({
		Size = UDim2.new(0, Config.STATS_WIDTH, 1, 0),
		Position = UDim2.new(1, -Config.STATS_WIDTH, 0, 0),
		BackgroundColor3 = THEME.panel,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = avatarSection
	})

	Utils.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = statsBar
	})

	-- Stats
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

		State.statsLabels[stat.key] = Utils.createLabel({
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 0, 4),
			Text = tostring(data[stat.key] or 0),
			TextColor3 = THEME.text,
			TextSize = Config.IS_MOBILE and 12 or 16,
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
			TextSize = Config.IS_MOBILE and 7 or 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 11,
			Parent = statContainer
		})
	end
	
	local displayText = data.displayName

	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == data.userId then
			displayText = displayText .. ""
			break
		end
	end

	local displayNameLabel = Utils.createLabel({
		Size = UDim2.new(1, -Config.STATS_WIDTH - 16, 0, 24),
		Position = UDim2.new(0, 10, 1, -52),
		Text = displayText,
		TextColor3 = playerColor,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 25,
		Parent = avatarSection
	})
	
	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == data.userId then

			local uiGradient = Instance.new("UIGradient")
			uiGradient.Parent = displayNameLabel

			uiGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
			})

			uiGradient.Offset = Vector2.new(-1, 0)

			local TweenService = game:GetService("TweenService")
			local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

			task.spawn(function()
				while displayNameLabel.Parent do
					local tween1 = TweenService:Create(uiGradient, tweenInfo, {
						Offset = Vector2.new(1, 0)
					})
					tween1:Play()
					tween1.Completed:Wait()

					local tween2 = TweenService:Create(uiGradient, tweenInfo, {
						Offset = Vector2.new(-1, 0)
					})
					tween2:Play()
					tween2.Completed:Wait()
				end
			end)

			break
		end
	end

	-- Username
	Utils.createLabel({
		Size = UDim2.new(1, -Config.STATS_WIDTH - 16, 0, 18),
		Position = UDim2.new(0, 10, 1, -28),
		Text = "@" .. data.username,
		TextColor3 = THEME.muted,
		TextSize = Config.IS_MOBILE and 10 or 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 25,
		Parent = avatarSection
	})

	-- Like buttons (solo si no es el propio jugador)
	if data.userId ~= player.UserId then
		local likeButtonsContainer = Utils.createFrame({
			Size = UDim2.new(0, 28, 0, 60),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			ZIndex = 15,
			Parent = avatarSection
		})

		Utils.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 4),
			Parent = likeButtonsContainer
		})

		local function createLikeButton(imageId, onClick)
			local btn = Utils.create("ImageButton", {
				Size = UDim2.new(0, Config.IS_MOBILE and 24 or 28, 0, Config.IS_MOBILE and 24 or 28),
				BackgroundTransparency = 1,
				Image = imageId,
				ScaleType = Enum.ScaleType.Fit,
				AutoButtonColor = false,
				ZIndex = 15,
				Parent = likeButtonsContainer+= 2.5
			})
			Utils.addConnection(btn.MouseButton1Click:Connect(onClick))
			Utils.addConnection(btn.MouseEnter:Connect(function() Utils.tween(btn, { ImageTransparency = 0.3 }, Config.ANIM_FAST) end))
			Utils.addConnection(btn.MouseLeave:Connect(function() Utils.tween(btn, { ImageTransparency = 0 }, Config.ANIM_FAST) end))
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

	local screenGui = Utils.createScreenGui(playerGui)
	local initialOffset = Config.IS_MOBILE and 30 or 50
	State.container = Utils.createFrame({
		Size = UDim2.new(0, Config.PANEL_WIDTH, 0, Config.PANEL_HEIGHT),
		Position = UDim2.new(0.5, -Config.PANEL_WIDTH / 2, 1, initialOffset),
		BackgroundTransparency = 1,
		Parent = screenGui
	})

	-- Obtener color del jugador seleccionado (ANTES de usarlo)
	local target
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p.UserId == data.userId then target = p break end
	end
	local playerColor = Utils.getPlayerColor(target, ColorEffects)
	State.target = target

	-- Drag Handle (barra superior para arrastrar)
	local dragHandleHeight = Config.IS_MOBILE and 24 or 18
	local dragHandle = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, dragHandleHeight),
		Parent = State.container
	})

	local dragIndicator = Utils.createFrame({
		Size = UDim2.new(0, 44, 0, Config.IS_MOBILE and 4 or 5),
		Position = UDim2.new(0.5, -22, 0.5, Config.IS_MOBILE and -2 or -2),
		BackgroundColor3 = playerColor,
		BackgroundTransparency = 0.3,
		Parent = dragHandle
	})
	Utils.addCorner(dragIndicator, 999)

	-- Drag Logic
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
			State.container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	-- Panel Container
	local panelContainerPosition = Config.IS_MOBILE and 26 or 22
	local panelContainer = Utils.createFrame({
		Size = UDim2.new(1, 0, 0, Config.PANEL_HEIGHT),
		Position = UDim2.new(0, 0, 0, panelContainerPosition),
		BackgroundColor3 = Utils.darkenFullColor(playerColor or THEME.panel, 0.93),
		BackgroundTransparency = 0.15,
		ClipsDescendants = true,
		Parent = State.container
	})
	Utils.addCorner(panelContainer, 12)
	local panelStroke = Utils.addStroke(panelContainer, playerColor, 2)
	
	local panelImage = Utils.create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.75,
		Image = "",
		ImageTransparency = 0.51,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Parent = panelContainer
	})

	Utils.addCorner(panelImage, 12)

	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == data.userId then
			panelImage.Image = "rbxassetid://79346090571461"
			panelImage.ScaleType = Enum.ScaleType.Crop
			panelImage.ImageTransparency = 0.15

			local gradient = Instance.new("UIGradient")
			gradient.Parent = panelImage
			gradient.Rotation = 90
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(64, 64, 64))
			}
			break
		end
	end


	
	Utils.addCorner(panelImage, 12)

	
	-- SOLO DEVELOPERS: borde animado blanco / negro
	for _, id in ipairs(GroupRoles.Group.DeveloperUserIds) do
		if id == data.userId then

			local gradient = Instance.new("UIGradient")
			gradient.Parent = panelStroke

			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), -- blanco
				ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)), -- negro
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)) -- blanco
			})

			task.spawn(function()
				while panelContainer.Parent do
					gradient.Rotation += 2.5
					task.wait()
				end
			end)

			break
		end
	end

	-- Shadow
	Utils.create("ImageLabel", {
		Size = UDim2.new(1, 30, 1, 30),
		Position = UDim2.new(0, -15, 0, -15),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = -1,
		Parent = panelContainer
	})

	-- Scrolling Frame
	local panel = Utils.create("ScrollingFrame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = playerColor,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		ScrollingEnabled = true,
		Active = true,
		Parent = panelContainer
	})

	-- Padding interno
	Utils.create("UIPadding", {
		PaddingTop = UDim.new(0, 0),
		PaddingBottom = UDim.new(0, 0),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
		Parent = panel
	})

	createAvatarSection(panel, data, playerColor)

	-- Listener de atributos para likes
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
					local increase = newLikes - lastLikesValue
					local sizeIncrease = increase >= 10 and 6 or 4

					Utils.tween(State.statsLabels.likes, { TextSize = originalSize + sizeIncrease }, 0.15)
					task.delay(0.15, function()
						if State.statsLabels.likes and State.statsLabels.likes.Parent then
							Utils.tween(State.statsLabels.likes, { TextSize = originalSize }, 0.15)
							task.delay(0.15, function()
								isAnimating = false
							end)
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

	-- Animación de entrada
	local initialOffset = Config.IS_MOBILE and 30 or 50
	local finalOffset = Config.IS_MOBILE and 70 or 90
	State.container.Position = UDim2.new(0.5, -Config.PANEL_WIDTH / 2, 1, initialOffset)
	State.container.Size = UDim2.new(0, Config.PANEL_WIDTH, 0, Config.PANEL_HEIGHT)

	task.defer(function()
		Utils.tween(State.container, {
			Position = UDim2.new(0.5, -Config.PANEL_WIDTH / 2, 1, -(Config.PANEL_HEIGHT + finalOffset))
		}, 0.5, Enum.EasingStyle.Quint)
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

	-- Notificar a GlobalModalManager
	pcall(function()
		if Remotes.Systems.GlobalModalManager then
			Remotes.Systems.GlobalModalManager.isUserPanelOpen = false
		end
	end)

	-- Animación de salida
	if State.container then
		local initialOffset = Config.IS_MOBILE and 30 or 50
		Utils.tween(State.container, {
			Position = UDim2.new(0.5, -Config.PANEL_WIDTH / 2, 1, initialOffset)
		}, 0.3, Enum.EasingStyle.Quad)
	end

	task.delay(0.3, function()
		Utils.clearConnections()
		Utils.detachHighlight(State)
		if State.ui then State.ui:Destroy() end

		State.ui = nil
		State.userId = nil
		State.target = nil
		State.container = nil
		State.panel = nil
		State.buttonsFrame = nil
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

	-- Desacoplar highlight del usuario anterior
	Utils.detachHighlight(State)

	Utils.clearConnections()
	if State.ui then State.ui:Destroy() end

	State.userId = target.UserId
	State.target = target

	-- Obtener color del jugador para UI del panel
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

		-- Acoplar highlight directamente (como en OLD)
		Utils.attachHighlight(target, State, ColorEffects)

		pcall(function()
			if Remotes.Systems.GlobalModalManager then
				if Remotes.Systems.GlobalModalManager.isEmoteOpen == nil then
					Remotes.Systems.GlobalModalManager.isEmoteOpen = false
				end
				Remotes.Systems.GlobalModalManager.isUserPanelOpen = true
			end
		end)

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
