-- ════════════════════════════════════════════════════════════════
-- USER PANEL CLIENT - VERSIÓN LEGIBLE
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cargar tema
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

-- Cargar remotes
local remotesFolder = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("UserPanel")
local Remotes = {
	GetUserData = remotesFolder:WaitForChild("GetUserData"),
	GetUserDonations = remotesFolder:WaitForChild("GetUserDonations"),
	GetGamePasses = remotesFolder:WaitForChild("GetGamePasses")
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN (editar aquí)
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
	-- Dimensiones del panel
	PANEL_WIDTH = 260,
	PANEL_HEIGHT = 345,
	PANEL_PADDING = 12,

	-- Sección del avatar
	AVATAR_HEIGHT = 190,
	AVATAR_ZOOM = 1.15,
	AVATAR_GRADIENT_HEIGHT = 70,

	-- Botones
	BUTTON_HEIGHT = 34,
	BUTTON_GAP = 4,

	-- Tiempos de animación (segundos)
	ANIM_FAST = 0.15,
	ANIM_NORMAL = 0.2,
	ANIM_SLOW = 0.35,

	-- Cards de donación
	CARD_CIRCLE_SIZE = 52,
}

-- ═══════════════════════════════════════════════════════════════
-- ESTADO GLOBAL
-- ═══════════════════════════════════════════════════════════════
local State = {
	ui = nil,
	container = nil,
	statsLabels = {},
	userId = nil,
	target = nil,
	closing = false,
	dragging = false,
	dragConnection = nil,
	refreshThread = nil,
	currentView = "buttons",
	buttonsFrame = nil,
	dynamicSection = nil,
	panel = nil
}

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES HELPER
-- ═══════════════════════════════════════════════════════════════

-- Crear un tween de animación
local function tween(object, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration or CONFIG.ANIM_NORMAL,
		easingStyle or Enum.EasingStyle.Quint,
		easingDirection or Enum.EasingDirection.Out
	)
	TweenService:Create(object, tweenInfo, properties):Play()
end

-- Crear una instancia con propiedades
local function create(className, properties)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	return instance
end

-- Crear un Frame con valores por defecto
local function createFrame(properties)
	properties.BackgroundTransparency = properties.BackgroundTransparency or 1
	properties.BorderSizePixel = 0
	return create("Frame", properties)
end

-- Crear un TextLabel con valores por defecto
local function createLabel(properties)
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.GothamMedium
	properties.TextColor3 = properties.TextColor3 or THEME.text
	return create("TextLabel", properties)
end

-- Agregar esquinas redondeadas
local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 12),
		Parent = parent
	})
end

-- Agregar borde
local function addStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or THEME.stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = parent
	})
end

-- Verificar si el mouse está dentro de un frame
local function isMouseInside(frame)
	if not frame then return false end

	local mouse = player:GetMouse()
	local position = frame.AbsolutePosition
	local size = frame.AbsoluteSize

	return mouse.X >= position.X 
		and mouse.X <= position.X + size.X 
		and mouse.Y >= position.Y 
		and mouse.Y <= position.Y + size.Y
end

-- Formatear precio (número completo)
local function formatPrice(price)
	return tostring(price)
end

-- Obtener avatar del usuario
local function getAvatarImage(userId)
	local thumbnailTypes = {
		Enum.ThumbnailType.AvatarThumbnail,
		Enum.ThumbnailType.HeadShot
	}

	for _, thumbnailType in ipairs(thumbnailTypes) do
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(
				userId,
				thumbnailType,
				Enum.ThumbnailSize.Size420x420
			)
		end)

		if success and result and result ~= "" then
			return result
		end
	end

	return ""
end

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE HOVER REUTILIZABLE
-- ═══════════════════════════════════════════════════════════════
local function setupHoverEffect(button, config)
	local isHovered = false

	-- Cuando el mouse entra
	button.MouseEnter:Connect(function()
		isHovered = true
		if config.onEnter then
			config.onEnter()
		end
	end)

	-- Cuando el mouse sale
	button.MouseLeave:Connect(function()
		isHovered = false
		if config.onLeave then
			config.onLeave()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- EFECTO RIPPLE (Onda al hacer click)
-- ═══════════════════════════════════════════════════════════════
local function createRippleEffect(button, container, mouseX, mouseY)
	local buttonPosition = button.AbsolutePosition

	local ripple = createFrame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, mouseX - buttonPosition.X, 0, mouseY - buttonPosition.Y),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		ZIndex = 1,
		Parent = container
	})
	addCorner(ripple, 9999)

	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5

	tween(ripple, {
		Size = UDim2.new(0, maxSize, 0, maxSize),
		BackgroundTransparency = 1
	}, 0.5, Enum.EasingStyle.Quad)

	task.delay(0.5, function()
		ripple:Destroy()
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- CERRAR PANEL
-- ═══════════════════════════════════════════════════════════════
local function closePanel()
	if State.closing or not State.ui then
		return
	end

	State.closing = true

	-- Cancelar auto-refresh
	if State.refreshThread then
		task.cancel(State.refreshThread)
	end

	-- Desconectar drag
	if State.dragConnection then
		State.dragConnection:Disconnect()
	end

	-- Animar salida
	tween(State.container, {
		Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, 50)
	}, 0.25)

	-- Destruir después de la animación
	task.delay(0.25, function()
		if State.ui then
			State.ui:Destroy()
		end

		-- Resetear estado
		State = {
			ui = nil,
			container = nil,
			statsLabels = {},
			userId = nil,
			target = nil,
			closing = false,
			dragging = false,
			dragConnection = nil,
			refreshThread = nil,
			currentView = "buttons",
			buttonsFrame = nil,
			dynamicSection = nil,
			panel = nil
		}
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO-REFRESH DE ESTADÍSTICAS
-- ═══════════════════════════════════════════════════════════════
local function startAutoRefresh()
	if State.refreshThread then
		task.cancel(State.refreshThread)
	end

	State.refreshThread = task.spawn(function()
		while State.ui and State.userId do
			task.wait(60) -- Actualizar cada 60 segundos

			if not State.ui then
				break
			end

			local data = Remotes.GetUserData:InvokeServer(State.userId)

			if data then
				for key, label in pairs(State.statsLabels) do
					if data[key] then
						label.Text = string.format('<b>%d</b> %s', data[key], key)
					end
				end
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR SECCIÓN DEL AVATAR
-- ═══════════════════════════════════════════════════════════════
local function createAvatarSection(panel, data)
	-- Contenedor principal del avatar
	local avatarSection = createFrame({
		Size = UDim2.new(1, 0, 0, CONFIG.AVATAR_HEIGHT),
		BackgroundColor3 = THEME.head,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = panel
	})
	addCorner(avatarSection, 12)

	-- Imagen del avatar
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

	-- Gradiente inferior
	local gradient = createFrame({
		Size = UDim2.new(1, 0, 0, CONFIG.AVATAR_GRADIENT_HEIGHT),
		Position = UDim2.new(0, 0, 1, -CONFIG.AVATAR_GRADIENT_HEIGHT),
		BackgroundColor3 = THEME.head,
		BackgroundTransparency = 0.15,
		ZIndex = 2,
		Parent = avatarSection
	})

	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.45, 0.55),
			NumberSequenceKeypoint.new(1, 0)
		}),
		Rotation = 90,
		Parent = gradient
	})

	-- Contenedor de información inferior
	local bottomInfo = createFrame({
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, 68),
		Position = UDim2.new(0, CONFIG.PANEL_PADDING, 1, -72),
		ZIndex = 5,
		Parent = avatarSection
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 3),
		Parent = bottomInfo
	})

	-- Contenedor de estadísticas
	local statsContainer = createFrame({
		Size = UDim2.new(1, 0, 0, 16),
		ZIndex = 5,
		Parent = bottomInfo
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = statsContainer
	})

	-- Crear labels de estadísticas
	local statKeys = {"followers", "following", "friends"}

	for _, key in ipairs(statKeys) do
		State.statsLabels[key] = createLabel({
			Size = UDim2.new(0, 70, 1, 0),
			RichText = true,
			Text = string.format('<b>%d</b> %s', data[key] or 0, key),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 10,
			ZIndex = 5,
			Parent = statsContainer
		})
	end

	-- Nombre de display
	createLabel({
		Size = UDim2.new(1, 0, 0, 20),
		Text = data.displayName,
		TextColor3 = THEME.accent,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 5,
		Parent = bottomInfo
	})

	-- Username
	createLabel({
		Size = UDim2.new(1, 0, 0, 12),
		Text = "@" .. data.username,
		TextColor3 = THEME.accent,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 5,
		Parent = bottomInfo
	})

	return avatarSection
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR BOTÓN MODERNO
-- ═══════════════════════════════════════════════════════════════
local function createModernButton(parent, text, isPrimary, layoutOrder)
	-- Contenedor del botón
	local container = createFrame({
		Size = UDim2.new(1, 0, 0, CONFIG.BUTTON_HEIGHT),
		LayoutOrder = layoutOrder,
		Parent = parent
	})

	-- Colores según si es primario o no
	local backgroundColor = isPrimary and THEME.accent or THEME.btnPrimary
	local hoverBackgroundColor = isPrimary and THEME.accentHover or THEME.btnPrimaryHover

	-- Botón principal
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = backgroundColor,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = container
	})
	addCorner(button, 8)

	local buttonStroke = addStroke(
		button,
		isPrimary and THEME.accent or THEME.stroke,
		1,
		isPrimary and 0.3 or 0.5
	)

	-- Texto del botón
	local textLabel = createLabel({
		Size = UDim2.new(1, 0, 1, 0),
		Text = text,
		TextSize = 12,
		ZIndex = 3,
		Parent = button
	})

	-- Efecto de brillo (shine)
	local shine = createFrame({
		Size = UDim2.new(0.3, 0, 2, 0),
		Position = UDim2.new(-0.4, 0, -0.5, 0),
		Rotation = 25,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.85,
		ZIndex = 2,
		Parent = button
	})

	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Parent = shine
	})

	-- Contenedor para efecto ripple
	local rippleContainer = createFrame({
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = button
	})
	addCorner(rippleContainer, 8)

	-- Indicador de hover (línea inferior)
	local hoverIndicator = createFrame({
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -2),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = isPrimary and THEME.text or THEME.accent,
		BackgroundTransparency = 0,
		ZIndex = 4,
		Parent = button
	})
	addCorner(hoverIndicator, 9999)

	-- Configurar efectos de hover
	setupHoverEffect(button, {
		onEnter = function()
			tween(shine, {
				Position = UDim2.new(1.1, 0, -0.5, 0)
			}, 0.4, Enum.EasingStyle.Quad)
		end,

		onLeave = function()
			shine.Position = UDim2.new(-0.4, 0, -0.5, 0)
		end
	})

	-- Efecto ripple al hacer click
	button.MouseButton1Click:Connect(function()
		local mouse = player:GetMouse()
		createRippleEffect(button, rippleContainer, mouse.X, mouse.Y)
	end)

	return button, textLabel
end

-- ═══════════════════════════════════════════════════════════════
-- VOLVER A VISTA DE BOTONES
-- ═══════════════════════════════════════════════════════════════
local function switchToButtonsView()
	State.currentView = "buttons"

	-- Animar salida de sección dinámica
	if State.dynamicSection then
		tween(State.dynamicSection, {
			Position = UDim2.new(1, 0, 0, State.dynamicSection.Position.Y.Offset)
		}, CONFIG.ANIM_NORMAL)

		task.delay(CONFIG.ANIM_NORMAL, function()
			if State.dynamicSection then
				State.dynamicSection:Destroy()
				State.dynamicSection = nil
			end
		end)
	end

	-- Mostrar botones
	if State.buttonsFrame then
		State.buttonsFrame.Visible = true
		tween(State.buttonsFrame, {
			Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, State.buttonsFrame.Position.Y.Offset)
		}, CONFIG.ANIM_NORMAL)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- MOSTRAR SECCIÓN DINÁMICA (Donaciones / Game Passes)
-- ═══════════════════════════════════════════════════════════════
local function showDynamicSection(viewType, items, targetName)
	State.currentView = viewType

	-- Ocultar botones
	if State.buttonsFrame then
		tween(State.buttonsFrame, {
			Position = UDim2.new(-1, 0, 0, State.buttonsFrame.Position.Y.Offset)
		}, CONFIG.ANIM_NORMAL)

		task.delay(CONFIG.ANIM_NORMAL, function()
			if State.buttonsFrame then
				State.buttonsFrame.Visible = false
			end
		end)
	end

	-- Calcular posición y tamaño
	local startY = CONFIG.AVATAR_HEIGHT + 6
	local availableHeight = math.max(80, State.panel.AbsoluteSize.Y - startY - CONFIG.PANEL_PADDING)

	-- Crear sección dinámica
	State.dynamicSection = createFrame({
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, availableHeight),
		Position = UDim2.new(1, 0, 0, startY), -- Empieza fuera de pantalla
		Parent = State.panel
	})

	-- === HEADER ===
	local header = createFrame({
		Size = UDim2.new(1, 0, 0, 24),
		Parent = State.dynamicSection
	})

	-- Botón de volver
	local backButton = create("TextButton", {
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = THEME.btnPrimary,
		Text = "<",
		TextColor3 = THEME.text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = header
	})
	addCorner(backButton, 6)

	setupHoverEffect(backButton, {
		onEnter = function()
			backButton.BackgroundColor3 = THEME.btnPrimaryHover
		end,
		onLeave = function()
			backButton.BackgroundColor3 = THEME.btnPrimary
		end
	})

	backButton.MouseButton1Click:Connect(switchToButtonsView)

	-- Título
	local titleText = viewType == "donations" 
		and ("Donar a " .. (targetName or "Usuario")) 
		or "Regalar Pase"

	createLabel({
		Size = UDim2.new(1, -32, 0, 24),
		Position = UDim2.new(0, 30, 0, 0),
		Text = titleText,
		TextColor3 = THEME.accent,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header
	})

	-- === SCROLL DE CARDS ===
	local scrollFrame = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -32),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.accent,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, CONFIG.CARD_CIRCLE_SIZE + 14),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = State.dynamicSection
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		Parent = scrollFrame
	})

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
		Parent = scrollFrame
	})

	-- === CREAR CARDS ===
	if items and #items > 0 then
		for index, item in ipairs(items) do
			-- Contenedor de la card
			local card = createFrame({
				Size = UDim2.new(0, CONFIG.CARD_CIRCLE_SIZE + 10, 0, CONFIG.CARD_CIRCLE_SIZE + 10),
				LayoutOrder = index,
				Parent = scrollFrame
			})

			-- Círculo principal
			local circle = createFrame({
				Size = UDim2.new(0, CONFIG.CARD_CIRCLE_SIZE, 0, CONFIG.CARD_CIRCLE_SIZE),
				Position = UDim2.new(0.5, -CONFIG.CARD_CIRCLE_SIZE / 2, 0.5, -CONFIG.CARD_CIRCLE_SIZE / 2),
				BackgroundColor3 = Color3.fromRGB(30, 30, 35),
				BackgroundTransparency = 0,
				ClipsDescendants = true,
				Parent = card
			})
			addCorner(circle, CONFIG.CARD_CIRCLE_SIZE / 2)

			local circleStroke = addStroke(circle, Color3.fromRGB(50, 50, 60), 1.5)

			-- Imagen del producto
			local productImage = create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Image = item.icon or "",
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 1,
				Parent = circle
			})
			addCorner(productImage, CONFIG.CARD_CIRCLE_SIZE / 2)

			-- Overlay oscuro para el precio
			local priceOverlay = createFrame({
				Size = UDim2.new(1, 0, 0.4, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				ZIndex = 2,
				Parent = circle
			})
			addCorner(priceOverlay, CONFIG.CARD_CIRCLE_SIZE / 2)

			-- Contenedor del precio
			local priceContainer = createFrame({
				Size = UDim2.new(1, 0, 0.4, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				ZIndex = 3,
				Parent = circle
			})

			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
				Parent = priceContainer
			})

			-- Ícono de Robux
			createLabel({
				Size = UDim2.new(0, 12, 0, 12),
				Text = "◎",
				TextColor3 = Color3.fromRGB(85, 255, 127),
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				ZIndex = 3,
				LayoutOrder = 1,
				Parent = priceContainer
			})

			-- Precio
			createLabel({
				Size = UDim2.new(0, 40, 0, 14),
				Text = formatPrice(item.price or 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
				LayoutOrder = 2,
				Parent = priceContainer
			})

			-- Botón clickeable
			local clickButton = create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 10,
				Parent = card
			})

			setupHoverEffect(clickButton, {
				onEnter = function()
					circleStroke.Color = Color3.fromRGB(88, 101, 242)
					circleStroke.Thickness = 2.5
				end,
				onLeave = function()
					circleStroke.Color = Color3.fromRGB(50, 50, 60)
					circleStroke.Thickness = 1.5
				end
			})

			clickButton.MouseButton1Click:Connect(function()
				if item.passId then
					pcall(function()
						MarketplaceService:PromptGamePassPurchase(player, item.passId)
					end)
				end
			end)
		end
	else
		-- Mensaje cuando no hay items
		createLabel({
			Size = UDim2.new(1, 0, 1, 0),
			Text = "No hay Game Passes disponibles",
			TextColor3 = THEME.muted,
			TextSize = 11,
			Parent = scrollFrame
		})
	end

	-- Animar entrada
	task.defer(function()
		tween(State.dynamicSection, {
			Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, startY)
		}, 0.25)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR SECCIÓN DE BOTONES
-- ═══════════════════════════════════════════════════════════════
local function createButtonsSection(panel, target)
	State.panel = panel

	-- Línea divisora
	local divider = createFrame({
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, 1),
		Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, CONFIG.AVATAR_HEIGHT + 4),
		BackgroundColor3 = THEME.stroke,
		BackgroundTransparency = 0.4,
		Parent = panel
	})

	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.8)
		}),
		Parent = divider
	})

	-- Calcular alturas
	local startY = CONFIG.AVATAR_HEIGHT + 6
	local availableHeight = CONFIG.PANEL_HEIGHT - startY - CONFIG.PANEL_PADDING - 22
	local contentHeight = (CONFIG.BUTTON_HEIGHT * 4) + (CONFIG.BUTTON_GAP * 3) + 8

	-- Scroll frame para botones
	State.buttonsFrame = create("ScrollingFrame", {
		Size = UDim2.new(1, -2 * CONFIG.PANEL_PADDING, 0, availableHeight),
		Position = UDim2.new(0, CONFIG.PANEL_PADDING, 0, startY),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.accent,
		ScrollBarImageTransparency = 0.5,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, contentHeight),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = panel
	})

	create("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 4),
		Parent = State.buttonsFrame
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, CONFIG.BUTTON_GAP),
		Parent = State.buttonsFrame
	})

	-- === BOTÓN: Ver Perfil ===
	local profileButton = createModernButton(State.buttonsFrame, "Ver Perfil", true, 1)
	profileButton.MouseButton1Click:Connect(function()
		if target then
			pcall(function()
				GuiService:InspectPlayerFromUserId(target.UserId)
			end)
		end
	end)

	-- === BOTÓN: Donar ===
	local donateButton, donateText = createModernButton(State.buttonsFrame, "Donar", false, 2)
	donateButton.MouseButton1Click:Connect(function()
		if not State.userId then return end

		donateText.Text = "Cargando..."

		task.spawn(function()
			local donations = Remotes.GetUserDonations:InvokeServer(State.userId)
			donateText.Text = "Donar"
			showDynamicSection("donations", donations, target and target.DisplayName)
		end)
	end)

	-- === BOTÓN: Regalar Pase ===
	local giftButton, giftText = createModernButton(State.buttonsFrame, "Regalar Pase", false, 3)
	giftButton.MouseButton1Click:Connect(function()
		giftText.Text = "Cargando..."

		task.spawn(function()
			local passes = Remotes.GetGamePasses:InvokeServer()
			giftText.Text = "Regalar Pase"
			showDynamicSection("passes", passes, nil)
		end)
	end)

	-- === BOTÓN: Seguir ===
	createModernButton(State.buttonsFrame, "Seguir", false, 4)
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR PANEL PRINCIPAL
-- ═══════════════════════════════════════════════════════════════
local function createPanel(data)
	State.statsLabels = {}
	State.currentView = "buttons"

	-- Eliminar panel existente
	local existingPanel = playerGui:FindFirstChild("UserPanel")
	if existingPanel then
		existingPanel:Destroy()
	end

	-- Crear ScreenGui
	local screenGui = create("ScreenGui", {
		Name = "UserPanel",
		ResetOnSpawn = false,
		DisplayOrder = 100,
		Parent = playerGui
	})

	-- Contenedor principal (para drag)
	State.container = createFrame({
		Size = UDim2.new(0, CONFIG.PANEL_WIDTH, 0, CONFIG.PANEL_HEIGHT),
		Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, 50), -- Empieza abajo
		Parent = screenGui
	})

	-- === DRAG HANDLE ===
	local dragHandle = createFrame({
		Size = UDim2.new(1, 0, 0, 18),
		Parent = State.container
	})

	local dragIndicator = createFrame({
		Size = UDim2.new(0, 44, 0, 5),
		Position = UDim2.new(0.5, -22, 0.5, -2),
		BackgroundColor3 = THEME.accent,
		BackgroundTransparency = 0.15,
		Parent = dragHandle
	})
	addCorner(dragIndicator, 9999)

	-- Lógica de drag
	local isDragging = false
	local dragStart = nil
	local startPosition = nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then

			isDragging = true
			State.dragging = true
			dragStart = input.Position
			startPosition = State.container.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false
					task.delay(0.1, function()
						State.dragging = false
					end)
				end
			end)
		end
	end)

	-- Desconectar conexión anterior si existe
	if State.dragConnection then
		State.dragConnection:Disconnect()
	end

	State.dragConnection = UserInputService.InputChanged:Connect(function(input)
		if not isDragging or not State.container or not State.container.Parent then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement 
			or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart
			State.container.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)

	-- === PANEL PRINCIPAL ===
	local panel = createFrame({
		Size = UDim2.new(1, 0, 1, -22),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = THEME.panel,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = State.container
	})
	addCorner(panel, 12)
	addStroke(panel, THEME.accent, 2)

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
		Parent = panel
	})

	-- Crear secciones
	createAvatarSection(panel, data)

	-- Buscar el jugador target
	local target = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == data.userId then
			target = p
			break
		end
	end
	State.target = target

	createButtonsSection(panel, target)

	-- Animar entrada del panel
	task.defer(function()
		tween(State.container, {
			Position = UDim2.new(0.5, -CONFIG.PANEL_WIDTH / 2, 1, -(CONFIG.PANEL_HEIGHT + 20))
		}, CONFIG.ANIM_SLOW, Enum.EasingStyle.Back)
	end)

	startAutoRefresh()

	return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- ABRIR PANEL
-- ═══════════════════════════════════════════════════════════════
local function openPanel(target)
	if not target or State.closing then
		return
	end

	-- Limpiar estado anterior
	if State.refreshThread then
		task.cancel(State.refreshThread)
	end

	if State.dragConnection then
		State.dragConnection:Disconnect()
	end

	if State.ui then
		State.ui:Destroy()
	end

	State.userId = target.UserId

	-- Obtener datos del servidor
	local serverData = Remotes.GetUserData:InvokeServer(target.UserId) or {}

	-- Crear el panel
	State.ui = createPanel({
		userId = target.UserId,
		username = target.Name,
		displayName = target.DisplayName,
		avatar = getAvatarImage(target.UserId),
		followers = serverData.followers or 0,
		following = serverData.following or 0,
		friends = serverData.friends or 0
	})
end

-- ═══════════════════════════════════════════════════════════════
-- DETECTAR CLICKS
-- ═══════════════════════════════════════════════════════════════

-- Cerrar panel al clickear fuera
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not State.ui or State.closing or State.dragging then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		task.defer(function()
			if State.container and not isMouseInside(State.container) then
				closePanel()
			end
		end)
	end
end)

-- Detectar click en jugadores
local mouse = player:GetMouse()
local lastClickTime = 0

mouse.Button1Down:Connect(function()
	-- Evitar abrir si ya hay panel o si es doble click
	if State.ui or State.closing then return end
	if tick() - lastClickTime < 0.3 then return end

	lastClickTime = tick()

	-- Raycast para detectar jugador
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	-- Obtener todos los personajes
	local characters = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(characters, p.Character)
		end
	end
	raycastParams.FilterDescendantsInstances = characters

	-- Hacer raycast
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)

	if result then
		local character = result.Instance.Parent

		-- Subir nivel si es necesario
		if not character:FindFirstChild("Humanoid") then
			character = character.Parent
		end

		-- Buscar el jugador correspondiente
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character == character then
				openPanel(p)
				return
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTAR
-- ═══════════════════════════════════════════════════════════════
return {
	open = openPanel,
	close = closePanel
}