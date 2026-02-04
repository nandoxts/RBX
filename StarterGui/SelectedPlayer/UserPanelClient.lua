-- ════════════════════════════════════════════════════════════════
-- USER PANEL CLIENT - VERSION MEJORADA
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Cursores
local DEFAULT_CURSOR = "rbxassetid://13335399499"
local SELECTED_CURSOR = "rbxassetid://84923889690331"

local remotesFolder = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("UserPanel")
local Remotes = {
	GetUserData = remotesFolder:WaitForChild("GetUserData"),
	GetUserDonations = remotesFolder:WaitForChild("GetUserDonations"),
	GetGamePasses = remotesFolder:WaitForChild("GetGamePasses"),
	DonationNotify = remotesFolder:FindFirstChild("DonationNotify"),
	DonationMessage = remotesFolder:FindFirstChild("DonationMessage"),
	SendLike = remotesFolder:FindFirstChild("SendLike"),
	SendSuperLike = remotesFolder:FindFirstChild("SendSuperLike"),
	CheckGamePass = remotesFolder:WaitForChild("CheckGamePass")
}

-- Sistema de sincronización (Emotes_Sync)
local RemotesSync = ReplicatedStorage:FindFirstChild("Panda ReplicatedStorage"):FindFirstChild("Emotes_Sync")
local SyncRemote = RemotesSync and RemotesSync:FindFirstChild("Sync")
local GetSyncState = RemotesSync and RemotesSync:FindFirstChild("GetSyncState")

-- Notificación System
local NotificationSystem = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
end) and require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem")) or nil

-- Sistema de likes existente
local LikesEvents = ReplicatedStorage:FindFirstChild("LikesEvents")
local GiveLikeEvent = LikesEvents and LikesEvents:FindFirstChild("GiveLikeEvent")
local GiveSuperLikeEvent = LikesEvents and LikesEvents:FindFirstChild("GiveSuperLikeEvent")

-- Highlight del SelectedPlayer
local SelectedPlayerModule = ReplicatedStorage:FindFirstChild("Panda ReplicatedStorage"):FindFirstChild("SelectedPlayer")
local Highlight = SelectedPlayerModule and SelectedPlayerModule:FindFirstChild("Highlight")
local ColorEffects = Highlight and require(SelectedPlayerModule:FindFirstChild("COLORS")) or nil

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACION DE LIKES
-- ═══════════════════════════════════════════════════════════════
local LIKE_COOLDOWN = 60  -- 60 segundos entre likes
local SUPER_LIKE_PRODUCT_ID = require(ReplicatedStorage:WaitForChild("Panda ReplicatedStorage"):WaitForChild("Configuration")).SUPER_LIKE

-- Función para obtener color del jugador
local function getPlayerColor(targetPlayer)
	if not ColorEffects then return Color3.fromRGB(255, 255, 255) end
	local colorName = targetPlayer:GetAttribute("SelectedColor") or "default"
	return ColorEffects.colors[colorName] or ColorEffects.defaultSelectedColor or Color3.fromRGB(0, 255, 0)
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE SINCRONIZACION
-- ═══════════════════════════════════════════════════════════════
local function syncWithPlayer(targetPlayer)
	if not SyncRemote or not GetSyncState then
		return
	end
	
	-- Consultar estado actual
	local ok, syncInfo = pcall(function()
		return GetSyncState:InvokeServer()
	end)
	
	if not ok then
		if NotificationSystem then
			NotificationSystem:Error("Sync", "Error al consultar sincronización", 3)
		end
		return
	end
	
	-- Si ya estoy sincronizado con ALGUIEN, desincronizar
	if syncInfo and syncInfo.isSynced then
		SyncRemote:FireServer("unsync")
		if NotificationSystem then
			NotificationSystem:Info("Sync", "Has dejado de estar sincronizado", 4)
		end
	-- Si NO estoy sincronizado, sincronizar con el target actual
	else
		if targetPlayer and targetPlayer ~= player then
			SyncRemote:FireServer("sync", targetPlayer)
			if NotificationSystem then
				NotificationSystem:Success("Sync", "Ahora estás sincronizado con: " .. targetPlayer.DisplayName, 4)
			end
		end
	end
end
local LikesSystem = {
	Cooldowns = {
		Like = {}
	},
	IsSending = false
}

local function checkLocalCooldown(targetUserId)
	local userId = player.UserId
	local cooldownKey = userId .. "_" .. targetUserId

	local lastTime = LikesSystem.Cooldowns.Like[cooldownKey] or 0
	local elapsed = tick() - lastTime

	return elapsed >= LIKE_COOLDOWN, lastTime
end

local function updateLocalCooldown(targetUserId)
	local userId = player.UserId
	local cooldownKey = userId .. "_" .. targetUserId
	LikesSystem.Cooldowns.Like[cooldownKey] = tick()
end

local function showCooldownNotification(remainingTime)
	local minutes = math.ceil(remainingTime / 60)
	if NotificationSystem then
		NotificationSystem:Info("Like", "Espera " .. minutes .. " minuto" .. (minutes > 1 and "s" or "") .. " para dar otro like", 3)
	end
end
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACION
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
	PANEL_WIDTH = 280,
	PANEL_HEIGHT = 350,
	PANEL_PADDING = 12,

	AVATAR_HEIGHT = 200,
	AVATAR_ZOOM = 1.2,

	STATS_WIDTH = 70,
	STATS_ITEM_HEIGHT = 50,

	BUTTON_HEIGHT = 38,
	BUTTON_GAP = 8,
	BUTTON_CORNER = 10,

	CARD_SIZE = 75,

	ANIM_FAST = 0.12,
	ANIM_NORMAL = 0.2,
	ANIM_SLOW = 0.3,

	AVATAR_CACHE_TIME = 300,
	AUTO_REFRESH_INTERVAL = 60,
	MAX_RAYCAST_DISTANCE = 80,
	CLICK_DEBOUNCE = 0.3,
}

-- ═══════════════════════════════════════════════════════════════
-- ESTADO Y CACHE
-- ═══════════════════════════════════════════════════════════════
local avatarCache = {}

local State = {
	ui = nil,
	container = nil,
	panel = nil,
	statsLabels = {},
	userId = nil,
	target = nil,
	closing = false,
	dragging = false,
	connections = {},
	refreshThread = nil,
	currentView = "buttons",
	buttonsFrame = nil,
	dynamicSection = nil,
	isPanelOpening = false,
	lastClickTime = 0,
}

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════
local function tween(object, properties, duration, style)
	if not object or not object.Parent then return end
	local info = TweenInfo.new(duration or CONFIG.ANIM_NORMAL, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(object, info, properties):Play()
end

local function create(className, props)
	local instance = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then instance[k] = v end
	end
	if props.Parent then instance.Parent = props.Parent end
	return instance
end

local function createFrame(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderSizePixel = 0
	return create("Frame", props)
end

local function createLabel(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextColor3 = props.TextColor3 or THEME.text
	return create("TextLabel", props)
end

local function addCorner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

local function addStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or THEME.stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = parent
	})
end

local function addConnection(connection)
	table.insert(State.connections, connection)
	return connection
end

local function clearConnections()
	for _, conn in ipairs(State.connections) do
		if conn and conn.Connected then conn:Disconnect() end
	end
	State.connections = {}
end

local function getAvatarImage(userId)
	local cached = avatarCache[userId]
	if cached and (tick() - cached.time) < CONFIG.AVATAR_CACHE_TIME then
		return cached.image
	end

	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
	end)

	if success and result and result ~= "" then
		avatarCache[userId] = { image = result, time = tick() }
		return result
	end
	return ""
end

-- ═══════════════════════════════════════════════════════════════
-- HIGHLIGHT (Línea alrededor del jugador seleccionado)
-- ═══════════════════════════════════════════════════════════════
local function attachHighlight(targetPlayer)
	if not Highlight or not targetPlayer or not targetPlayer.Character then return end
	local color = ColorEffects and ColorEffects.colors[targetPlayer:GetAttribute("SelectedColor") or "default"] or Color3.fromRGB(0, 255, 0)
	Highlight.FillColor = color
	Highlight.OutlineColor = color
	Highlight.Adornee = targetPlayer.Character
	Highlight.Enabled = true
end

local function detachHighlight()
	if Highlight then
		Highlight.Adornee = nil
		Highlight.Enabled = false
	end
end

-- ═══════════════════════════════════════════════════════════════
-- EFECTOS Y PARTÍCULAS
-- ═══════════════════════════════════════════════════════════════
local function createHeartParticle(container, startPos, isSuperLike)
	-- Crea una partícula de corazón que flota hacia arriba
	local heart = create("TextLabel", {
		Size = UDim2.new(0, isSuperLike and 36 or 24, 0, isSuperLike and 36 or 24),
		Position = startPos,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = isSuperLike and "⭐" or "❤",
		TextColor3 = isSuperLike and THEME.accent or Color3.fromRGB(255, 105, 180),
		TextSize = isSuperLike and 32 or 22,
		Font = Enum.Font.GothamBold,
		ZIndex = 100,
		Parent = container
	})
	
	-- Animación de flotamiento y desvanecimiento
	local endY = startPos.Y.Offset - 100
	tween(heart, {
		Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + math.random(-30, 30), startPos.Y.Scale, endY),
		BackgroundTransparency = 1
	}, isSuperLike and 1.5 or 1.2, Enum.EasingStyle.Quint)
	
	task.delay(isSuperLike and 1.5 or 1.2, function()
		if heart and heart.Parent then heart:Destroy() end
	end)
end

local function createHeartEffect(avatarElement, isSuperLike)
	-- Crea múltiples corazones partiendo del avatar
	local absPos = avatarElement.AbsolutePosition
	local absSize = avatarElement.AbsoluteSize
	local centerX = absPos.X + absSize.X / 2
	local centerY = absPos.Y + absSize.Y / 2
	
	local screenGui = State.container.Parent
	
	local particleCount = isSuperLike and 12 or 8
	for i = 1, particleCount do
		local angle = (i / particleCount) * math.pi * 2
		local offsetX = math.cos(angle) * 30
		local offsetY = math.sin(angle) * 30
		
		task.delay(i * 0.05, function()
			if State.ui and screenGui then
				local startPosUDim2 = UDim2.new(0, centerX + offsetX, 0, centerY + offsetY)
				createHeartParticle(screenGui, startPosUDim2, isSuperLike)
			end
		end)
	end
end

local function createRipple(button, container, x, y)
	local pos = button.AbsolutePosition
	local ripple = createFrame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, x - pos.X, 0, y - pos.Y),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.accent,
		BackgroundTransparency = 0.5,
		ZIndex = 1,
		Parent = container
	})
	addCorner(ripple, 999)

	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
	tween(ripple, { Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1 }, 0.4, Enum.EasingStyle.Quad)
	task.delay(0.4, function() if ripple then ripple:Destroy() end end)
end

-- ═══════════════════════════════════════════════════════════════
-- CERRAR PANEL
-- ═══════════════════════════════════════════════════════════════
local function closePanel()
	if State.closing or not State.ui then return end
	State.closing = true

	-- Cancelar threads
	if State.refreshThread then task.cancel(State.refreshThread) end
	
	-- Desconectar eventos del panel
	clearConnections()
	
	-- Desattach highlight
	detachHighlight()

	-- Animación de salida
	tween(State.container, { Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, 50) }, 0.5, Enum.EasingStyle.Quint)

	task.delay(0.5, function()
		-- Destruir UI completamente
		if State.ui and State.ui.Parent then State.ui:Destroy() end
		
		-- Resetear estado
		State = {
			ui = nil, container = nil, panel = nil, statsLabels = {},
			userId = nil, target = nil, closing = false, dragging = false,
			connections = {}, refreshThread = nil, currentView = "buttons",
			buttonsFrame = nil, dynamicSection = nil, isPanelOpening = false, lastClickTime = 0
		}
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- LISTENERS DE DONACIONES Y LIKES (GLOBALES - PERSISTENTES)
-- ═══════════════════════════════════════════════════════════════
if Remotes.DonationNotify then
	Remotes.DonationNotify.OnClientEvent:Connect(function(donatorId, amount, recipientId)
		-- Notificación de donación recibida
		if NotificationSystem then
			NotificationSystem:Success("Donación", "Recibiste una donación de R$" .. amount, 4)
		end
	end)
end

if Remotes.DonationMessage then
	Remotes.DonationMessage.OnClientEvent:Connect(function(donatorName, amount, recipientName)
		-- Notificación de donación realizada
		if NotificationSystem then
			NotificationSystem:Success("Donación", "Donaste R$" .. amount .. " a " .. recipientName, 4)
		end
	end)
end

-- Listeners del sistema de likes existente (GLOBALES - PERSISTENTES)
if GiveLikeEvent then
	GiveLikeEvent.OnClientEvent:Connect(function(action, data)
		if action == "LikeSuccess" then
			if NotificationSystem then
				NotificationSystem:Success("Like", "Like enviado exitosamente", 2)
			end
		elseif action == "Error" then
			if NotificationSystem then
				NotificationSystem:Error("Like", "Error al enviar like", 3)
			end
		end
	end)
end

if GiveSuperLikeEvent then
	GiveSuperLikeEvent.OnClientEvent:Connect(function(action, data)
		if action == "SuperLikeSuccess" then
			if NotificationSystem then
				NotificationSystem:Success("Super Like", "Super Like enviado exitosamente", 3)
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO REFRESH
-- ═══════════════════════════════════════════════════════════════
local function startAutoRefresh()
	if State.refreshThread then task.cancel(State.refreshThread) end

	State.refreshThread = task.spawn(function()
		while State.ui and State.userId do
			task.wait(CONFIG.AUTO_REFRESH_INTERVAL)
			if not State.ui then break end

			local success, data = pcall(function()
				return Remotes.GetUserData:InvokeServer(State.userId)
			end)

			if success and data then
				for key, label in pairs(State.statsLabels) do
					if data[key] and label and label.Parent then
						label.Text = tostring(data[key] or 0)
					end
				end
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- SECCION AVATAR CON STATS LATERALES
-- ═══════════════════════════════════════════════════════════════
local function createAvatarSection(panel, data, playerColor)
	local avatarSection = createFrame({
		Size = UDim2.new(1, 0, 0, CONFIG.AVATAR_HEIGHT),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = panel
	})

	-- Imagen avatar
	create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(CONFIG.AVATAR_ZOOM, 0, CONFIG.AVATAR_ZOOM, 0),
		BackgroundTransparency = 1,
		Image = data.avatar,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 1,
		Parent = avatarSection
	})

	-- Barra lateral de estadisticas (derecha)
	local statsBar = createFrame({
		Size = UDim2.new(0, CONFIG.STATS_WIDTH, 1, 0),
		Position = UDim2.new(1, -CONFIG.STATS_WIDTH, 0, 0),
		BackgroundColor3 = THEME.panel,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = avatarSection
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = statsBar
	})

	-- Stats: followers, friends y likes
	local stats = {
		{ key = "followers", label = "Seguidores" },
		{ key = "friends", label = "Amigos" },
		{ key = "likes", label = "Likes" },
	}

	for _, stat in ipairs(stats) do
		local statContainer = createFrame({
			Size = UDim2.new(1, -8, 0, CONFIG.STATS_ITEM_HEIGHT),
			ZIndex = 11,
			Parent = statsBar
		})

		-- Numero
		State.statsLabels[stat.key] = createLabel({
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 0, 4),
			Text = tostring(data[stat.key] or 0),
			TextColor3 = playerColor,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 11,
			Parent = statContainer
		})

		-- Etiqueta
		createLabel({
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 26),
			Text = stat.label,
			TextColor3 = THEME.muted,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 11,
			Parent = statContainer
		})
	end

	-- Info inferior (nombre) - sin overlay
	createLabel({
		Size = UDim2.new(1, -CONFIG.STATS_WIDTH - 16, 0, 24),
		Position = UDim2.new(0, 10, 1, -52),
		Text = data.displayName,
		TextColor3 = playerColor,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		Parent = avatarSection
	})

	createLabel({
		Size = UDim2.new(1, -CONFIG.STATS_WIDTH - 16, 0, 18),
		Position = UDim2.new(0, 10, 1, -28),
		Text = "@" .. data.username,
		TextColor3 = THEME.muted,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		Parent = avatarSection
	})

	-- Botones pequeños de Like y SuperLike (parte superior izquierda - vertical)
	local likeButtonsContainer = createFrame({
		Size = UDim2.new(0, 28, 0, 60),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		ZIndex = 15,
		Parent = avatarSection
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 4),
		Parent = likeButtonsContainer
	})

	-- Botón Like (Imagen)
	local likeBtn = create("ImageButton", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundTransparency = 1,
		Image = "rbxassetid://118393090095169",  -- Reemplaza con tu ID de imagen de corazón
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		ZIndex = 15,
		Parent = likeButtonsContainer
	})

	local lastLikeClick = 0
	addConnection(likeBtn.MouseButton1Click:Connect(function()
		if not State.userId or State.userId == player.UserId then return end
		
		local now = tick()
		if now - lastLikeClick < 0.3 then return end
		lastLikeClick = now
		
		local canLike, lastLikeTime = checkLocalCooldown(State.userId)
		
		if canLike then
			-- Disparar evento de Like
			if GiveLikeEvent then
				GiveLikeEvent:FireServer("GiveLike", State.userId)
			elseif Remotes.SendLike then
				Remotes.SendLike:FireServer(State.userId)
			end
			
			-- Crear efecto de corazones
			createHeartEffect(avatarSection, false)
			updateLocalCooldown(State.userId)
		else
			local remainingTime = LIKE_COOLDOWN - (tick() - lastLikeTime)
			showCooldownNotification(remainingTime)
		end
	end))

	addConnection(likeBtn.MouseEnter:Connect(function()
		tween(likeBtn, { ImageTransparency = 0.3 }, CONFIG.ANIM_FAST)
	end))

	addConnection(likeBtn.MouseLeave:Connect(function()
		tween(likeBtn, { ImageTransparency = 0 }, CONFIG.ANIM_FAST)
	end))

	-- Botón SuperLike (Imagen)
	local superLikeBtn = create("ImageButton", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundTransparency = 1,
		Image = "rbxassetid://9412108006",  -- Reemplaza con tu ID de imagen de estrella
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		ZIndex = 15,
		Parent = likeButtonsContainer
	})

	addConnection(superLikeBtn.MouseButton1Click:Connect(function()
		if not State.userId or State.userId == player.UserId then return end
		
		if GiveSuperLikeEvent then
			GiveSuperLikeEvent:FireServer("SetSuperLikeTarget", State.userId)
		end
		
		-- Crear efecto de estrellas para super like
		createHeartEffect(avatarSection, true)
		
		-- Mostrar prompt de compra
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, SUPER_LIKE_PRODUCT_ID)
		end)
	end))

	addConnection(superLikeBtn.MouseEnter:Connect(function()
		tween(superLikeBtn, { ImageTransparency = 0.3 }, CONFIG.ANIM_FAST)
	end))

	addConnection(superLikeBtn.MouseLeave:Connect(function()
		tween(superLikeBtn, { ImageTransparency = 0 }, CONFIG.ANIM_FAST)
	end))

	return avatarSection
end

-- ═══════════════════════════════════════════════════════════════
-- BOTON (estilo EmoteUI - minimalista con hover suave)
-- ═══════════════════════════════════════════════════════════════
local function createButton(parent, text, layoutOrder, playerColor)
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, CONFIG.BUTTON_HEIGHT),
		BackgroundColor3 = THEME.elevated,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		LayoutOrder = layoutOrder,
		Parent = parent
	})
	addCorner(button, CONFIG.BUTTON_CORNER)
	local stroke = addStroke(button, playerColor or THEME.stroke, 1, 0.7)

	local textLabel = createLabel({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text,
		TextColor3 = THEME.text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ZIndex = 3,
		Parent = button
	})

	local rippleContainer = createFrame({
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = button
	})
	addCorner(rippleContainer, CONFIG.BUTTON_CORNER)

	-- Hover suave (mezcla del color elevated con playerColor)
	addConnection(button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = THEME.elevated:Lerp(playerColor or THEME.accent, 0.15) }, CONFIG.ANIM_FAST)
		tween(stroke, { Transparency = 0.3 }, CONFIG.ANIM_FAST)
	end))

	addConnection(button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = THEME.elevated }, CONFIG.ANIM_FAST)
		tween(stroke, { Transparency = 0.7 }, CONFIG.ANIM_FAST)
	end))

	-- Ripple on click
	addConnection(button.MouseButton1Click:Connect(function()
		local mouse = player:GetMouse()
		createRipple(button, rippleContainer, mouse.X, mouse.Y)
	end))

	return button, textLabel
end

-- ═══════════════════════════════════════════════════════════════
-- VISTAS DINAMICAS
-- ═══════════════════════════════════════════════════════════════
local function switchToButtons()
	State.currentView = "buttons"

	if State.dynamicSection then
		tween(State.dynamicSection, { Position = UDim2.new(1, 0, 0, State.dynamicSection.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
		task.delay(0.15, function()
			if State.dynamicSection then State.dynamicSection:Destroy() State.dynamicSection = nil end
		end)
	end

	if State.buttonsFrame then
		State.buttonsFrame.Visible = true
		tween(State.buttonsFrame, { Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, State.buttonsFrame.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
	end
end

local function renderDynamicSection(viewType, items, targetName, playerColor)
	if not State.panel or not State.panel.Parent then return end

	local startY = CONFIG.AVATAR_HEIGHT + 8
	local availableHeight = math.max(80, State.panel.AbsoluteSize.Y - startY - CONFIG.PANEL_PADDING)

	-- Crear sección
	State.dynamicSection = createFrame({
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, availableHeight),
		Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, startY),
		Parent = State.panel
	})

	-- Header
	local header = createFrame({ Size = UDim2.new(1, 0, 0, 28), Parent = State.dynamicSection })

	local backBtn = create("TextButton", {
		Size = UDim2.new(0, 28, 0, 28),
		BackgroundColor3 = THEME.elevated,
		Text = "<",
		TextColor3 = THEME.text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = header
	})
	addCorner(backBtn, 6)

	addConnection(backBtn.MouseEnter:Connect(function() tween(backBtn, { BackgroundColor3 = THEME.elevated:Lerp(playerColor or THEME.accent, 0.15) }, CONFIG.ANIM_FAST) end))
	addConnection(backBtn.MouseLeave:Connect(function() tween(backBtn, { BackgroundColor3 = THEME.elevated }, CONFIG.ANIM_FAST) end))
	addConnection(backBtn.MouseButton1Click:Connect(switchToButtons))

	local title = viewType == "donations" and ("Donar a " .. (targetName or "Usuario")) or "Regalar Pase"
	createLabel({
		Size = UDim2.new(1, -36, 0, 28),
		Position = UDim2.new(0, 34, 0, 0),
		Text = title,
		TextColor3 = playerColor or THEME.accent,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header
	})

	-- Scroll de cards
	local scroll = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = playerColor or THEME.accent,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, CONFIG.CARD_SIZE + 10),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = State.dynamicSection
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		Parent = scroll
	})

	create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = scroll })

	if items and #items > 0 then
		for i, item in ipairs(items) do
			local card = createFrame({
				Size = UDim2.new(0, CONFIG.CARD_SIZE + 8, 0, CONFIG.CARD_SIZE + 8),
				LayoutOrder = i,
				Parent = scroll
			})

			local circle = createFrame({
				Size = UDim2.new(0, CONFIG.CARD_SIZE, 0, CONFIG.CARD_SIZE),
				Position = UDim2.new(0.5, -CONFIG.CARD_SIZE / 2, 0.5, -CONFIG.CARD_SIZE / 2),
				BackgroundColor3 = THEME.panel,
				BackgroundTransparency = 0,
				ClipsDescendants = true,
				Parent = card
			})
			addCorner(circle, CONFIG.CARD_SIZE / 2)
			local circleStroke = addStroke(circle, THEME.stroke, 1.5)

			local img = create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = item.icon or "",
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 1,
				Parent = circle
			})
			addCorner(img, CONFIG.CARD_SIZE / 2)

			-- Usar valor ya validado del servidor
			local hasPass = item.hasPass == true

			-- Precio overlay
			local priceOverlay = createFrame({
				Size = UDim2.new(1, 0, 0.35, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = hasPass and THEME.panel or THEME.head,
				BackgroundTransparency = hasPass and 0.5 or 0.3,
				ZIndex = 2,
				Parent = circle
			})

			local priceText = createLabel({
				Size = UDim2.new(1, 0, 1, 0),
				Text = hasPass and "Adquirida" or (utf8.char(0xE002) .. tostring(item.price or 0)),
				TextColor3 = hasPass and Color3.fromRGB(100, 220, 100) or (playerColor or THEME.accent),
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				ZIndex = 3,
				Parent = priceOverlay
			})

			local clickBtn = create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 10,
				Parent = card
			})

			addConnection(clickBtn.MouseEnter:Connect(function()
				tween(circleStroke, { Color = playerColor or THEME.accent, Thickness = 2.5 }, CONFIG.ANIM_FAST)
			end))
			addConnection(clickBtn.MouseLeave:Connect(function()
				tween(circleStroke, { Color = THEME.stroke, Thickness = 1.5 }, CONFIG.ANIM_FAST)
			end))

			addConnection(clickBtn.MouseButton1Click:Connect(function()
				if hasPass then
					if NotificationSystem then
						NotificationSystem:Info("Game Pass", "Ya tienes este pase", 2)
					end
				elseif item.passId then
					pcall(function() MarketplaceService:PromptGamePassPurchase(player, item.passId) end)
				end
			end))
		end
	else
		createLabel({
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
		tween(State.buttonsFrame, { Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset) }, 0.15, Enum.EasingStyle.Quad)
		task.delay(0.15, function()
			if State.buttonsFrame then State.buttonsFrame.Visible = false end
		end)
	end

	-- El servidor ya devuelve los items con hasPass validado
	-- No necesitamos validación async en el cliente
	print("[UserPanel] Renderizando " .. (items and #items or 0) .. " items (ya validados por servidor)")
	renderDynamicSection(viewType, items, targetName, playerColor)
end

-- ═══════════════════════════════════════════════════════════════
-- SECCION DE BOTONES
-- ═══════════════════════════════════════════════════════════════
local function createButtonsSection(panel, target, playerColor)
	State.panel = panel

	local startY = CONFIG.AVATAR_HEIGHT + CONFIG.BUTTON_GAP
	local buttonsHeight = (CONFIG.BUTTON_HEIGHT * 3) + (CONFIG.BUTTON_GAP * 2)

	State.buttonsFrame = createFrame({
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, buttonsHeight + 8),
		Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, startY),
		Parent = panel
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, CONFIG.BUTTON_GAP),
		Parent = State.buttonsFrame
	})

	-- Ver Perfil
	local profileBtn = createButton(State.buttonsFrame, "Ver Perfil", 1, playerColor)
	addConnection(profileBtn.MouseButton1Click:Connect(function()
		if target then pcall(function() GuiService:InspectPlayerFromUserId(target.UserId) end) end
	end))

	-- Donar
	local donateBtn, donateText = createButton(State.buttonsFrame, "Donar", 2, playerColor)
	addConnection(donateBtn.MouseButton1Click:Connect(function()
		if not State.userId then return end
		donateText.Text = "Cargando..."
		task.spawn(function()
			local donations = Remotes.GetUserDonations:InvokeServer(State.userId)
			donateText.Text = "Donar"
			showDynamicSection("donations", donations, target and target.DisplayName, playerColor)
		end)
	end))

	-- Regalar Pase
	local giftBtn, giftText = createButton(State.buttonsFrame, "Regalar Pase", 3, playerColor)
	addConnection(giftBtn.MouseButton1Click:Connect(function()
		giftText.Text = "Cargando..."
		task.spawn(function()
			local passes = Remotes.GetGamePasses:InvokeServer()
			giftText.Text = "Regalar Pase"
			showDynamicSection("passes", passes, nil, playerColor)
		end)
	end))

	-- Sincronizar
	local syncBtn = createButton(State.buttonsFrame, "Sincronizar", 4, playerColor)
	local debounceSyncBtn = false
	addConnection(syncBtn.MouseButton1Click:Connect(function()
		if debounceSyncBtn or not target then return end
		debounceSyncBtn = true
		
		syncWithPlayer(target)
		
		task.wait(0.5)
		debounceSyncBtn = false
	end))
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR PANEL
-- ═══════════════════════════════════════════════════════════════
local function createPanel(data)
	State.statsLabels = {}
	State.currentView = "buttons"
	clearConnections()

	local existing = playerGui:FindFirstChild("UserPanel")
	if existing then existing:Destroy() end

	local screenGui = create("ScreenGui", {
		Name = "UserPanel",
		ResetOnSpawn = false,
		DisplayOrder = 100,
		Parent = playerGui
	})

	State.container = createFrame({
		Size = UDim2.new(0, CONFIG.PANEL_WIDTH, 0, CONFIG.PANEL_HEIGHT),
		Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, 50),
		Parent = screenGui
	})

	-- Obtener color del jugador seleccionado (ANTES de usarlo)
	local targetPlayer
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == data.userId then targetPlayer = p break end
	end
	local playerColor = targetPlayer and getPlayerColor(targetPlayer) or THEME.accent

	-- Drag handle
	local dragHandle = createFrame({ Size = UDim2.new(1, 0, 0, 18), Parent = State.container })

	local dragIndicator = createFrame({
		Size = UDim2.new(0, 44, 0, 5),
		Position = UDim2.new(0.5, -22, 0.5, -2),
		BackgroundColor3 = playerColor,
		BackgroundTransparency = 0.3,
		Parent = dragHandle
	})
	addCorner(dragIndicator, 999)

	-- Drag logic
	local isDragging = false
	local dragStart, startPos

	addConnection(dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			State.dragging = true
			dragStart = input.Position
			startPos = State.container.Position

			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false
					task.delay(0.1, function() State.dragging = false end)
					endConn:Disconnect()
				end
			end)
		end
	end))

	addConnection(UserInputService.InputChanged:Connect(function(input)
		if not isDragging or not State.container or not State.container.Parent then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			State.container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	-- Contenedor con bordes redondeados (para clip correcto)
	local panelContainer = createFrame({
		Size = UDim2.new(1, 0, 0, CONFIG.PANEL_HEIGHT),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = THEME.panel,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = State.container
	})
	addCorner(panelContainer, 12)
	addStroke(panelContainer, playerColor, 1.5)

	-- Sombra
	create("ImageLabel", {
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

	-- ScrollingFrame interno (transparente)
	local panel = create("ScrollingFrame", {
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
		Parent = panelContainer
	})
	
	-- Padding interno para respetar los bordes redondeados
	create("UIPadding", {
		PaddingTop = UDim.new(0, 0),
		PaddingBottom = UDim.new(0, 0),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
		Parent = panel
	})

	createAvatarSection(panel, data, playerColor)
	
	local target
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == data.userId then target = p break end
	end
	State.target = target

	createButtonsSection(panel, target, playerColor)

	-- Animación de entrada suave con escala y posición
	State.container.Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, 50)
	State.container.Size = UDim2.new(0, CONFIG.PANEL_WIDTH, 0, CONFIG.PANEL_HEIGHT)
	
	task.defer(function()
		-- Entrada suave: aparece desde abajo con escala y fade in
		tween(State.container, {
			Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, -(CONFIG.PANEL_HEIGHT + 90))
		}, 0.5, Enum.EasingStyle.Quint)
	end)

	startAutoRefresh()
	return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- ABRIR PANEL
-- ═══════════════════════════════════════════════════════════════
local function openPanel(target)
	if State.isPanelOpening or State.closing or not target then return end
	State.isPanelOpening = true

	if State.refreshThread then task.cancel(State.refreshThread) end
	clearConnections()
	if State.ui then State.ui:Destroy() end

	State.userId = target.UserId

	local success, result = pcall(function()
		return createPanel({
			userId = target.UserId,
			username = target.Name,
			displayName = target.DisplayName,
			avatar = getAvatarImage(target.UserId),
			followers = 0,
			friends = 0,
			likes = 0
		})
	end)

	if success and result then
		State.ui = result
		State.target = target
		attachHighlight(target)

		task.spawn(function()
			local ok, data = pcall(function() return Remotes.GetUserData:InvokeServer(target.UserId) end)
			if ok and data and State.ui then
				for key, label in pairs(State.statsLabels) do
					if data[key] and label and label.Parent then
						label.Text = tostring(data[key] or 0)
					end
				end
			end
			State.isPanelOpening = false
		end)
	else
		State.isPanelOpening = false
		warn("[UserPanel] Error creando panel:", result)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- DETECCION DE CLICS
-- ═══════════════════════════════════════════════════════════════
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local function getPlayerFromPart(part)
	if not part then return nil end
	local current = part
	while current and current ~= workspace do
		local found = Players:GetPlayerFromCharacter(current)
		if found then return found end
		current = current.Parent
	end
	return nil
end

local function trySelectAtPosition(position)
	local now = tick()
	if now - State.lastClickTime < CONFIG.CLICK_DEBOUNCE then return end
	State.lastClickTime = now

	if State.ui then
		if State.container then
			local absPos = State.container.AbsolutePosition
			local absSize = State.container.AbsoluteSize
			if position.X >= absPos.X and position.X <= absPos.X + absSize.X and position.Y >= absPos.Y and position.Y <= absPos.Y + absSize.Y then
				return
			end
		end
		closePanel()
		return
	end

	if State.isPanelOpening then return end

	local unitRay = camera:ScreenPointToRay(position.X, position.Y)
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * CONFIG.MAX_RAYCAST_DISTANCE)

	if raycast and raycast.Instance then
		local clickedPlayer = getPlayerFromPart(raycast.Instance)
		if clickedPlayer then
			if clickedPlayer == player then
				local char = clickedPlayer.Character
				if char then
					local head = char:FindFirstChild("Head")
					if head and head.LocalTransparencyModifier == 1 then return end
				end
			end

			if State.ui and State.target and clickedPlayer == State.target then
				closePanel()
				return
			end

			openPanel(clickedPlayer)
		end
	end
end

-- Input handlers
local function startPress() end
local function endPress(pos) trySelectAtPosition(pos) end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then startPress() end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then endPress(Vector2.new(mouse.X, mouse.Y)) end
end)

UserInputService.TouchStarted:Connect(function(input, processed)
	if not processed then startPress() end
end)

UserInputService.TouchEnded:Connect(function(input)
	endPress(input.Position)
end)

-- ═══════════════════════════════════════════════════════════════
-- CAMBIO DE CURSOR
-- ═══════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	if State.ui then return end -- Si panel está abierto, no cambiar cursor
	
	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * CONFIG.MAX_RAYCAST_DISTANCE)

	if raycast and raycast.Instance then
		local hoveredPlayer = getPlayerFromPart(raycast.Instance)
		if hoveredPlayer and hoveredPlayer ~= player then
			mouse.Icon = SELECTED_CURSOR
			return
		end
	end
	
	mouse.Icon = DEFAULT_CURSOR
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTAR
-- ═══════════════════════════════════════════════════════════════
return {
	open = openPanel,
	close = closePanel
}