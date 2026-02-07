--[[
GamepassShop - Tienda de Gamepasses PREMIUM
by ignxts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Módulos
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local Configuration = require(ReplicatedStorage:WaitForChild("Panda ReplicatedStorage"):WaitForChild("Configuration"))
local CheckGamepassOwnership = ReplicatedStorage:WaitForChild("Panda ReplicatedStorage"):WaitForChild("Gamepass Gifting"):WaitForChild("Remotes"):WaitForChild("Ownership")

-- ════════════════════════════════════════════════════════════════
-- COLORES (Extendidos de THEME)
-- ════════════════════════════════════════════════════════════════
local COLORS = setmetatable({
	gold = Color3.fromRGB(255, 200, 80),
	goldGlow = Color3.fromRGB(255, 180, 50),
	cardHover = Color3.fromRGB(45, 45, 60),
	success = Color3.fromRGB(34, 197, 94),
}, { __index = THEME })

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE GRID
-- ════════════════════════════════════════════════════════════════
local GRID_CONFIG = {
	columns = 3,
	cardWidth = 160,
	cardHeight = 170,
	gap = 12,
}

-- ════════════════════════════════════════════════════════════════
-- VALIDACIÓN DE GAMEPASSES (OPTIMIZADO)
-- ════════════════════════════════════════════════════════════════
local gamepassCache = {} -- [gamePassId] = boolean

local function playerOwnsGamePass(gamePassId)
	-- Retornar del cache si existe
	if gamepassCache[gamePassId] ~= nil then
		return gamepassCache[gamePassId]
	end

	local success, ownsGamepass = pcall(function()
		return CheckGamepassOwnership:InvokeServer(gamePassId)
	end)

	local result = success and ownsGamepass
	gamepassCache[gamePassId] = result
	return result
end

local function updateGamepassAttribute(gamePassId)
	if gamePassId == Configuration.VIP then
		player:SetAttribute("HasVIP", playerOwnsGamePass(gamePassId))
	end
end

-- Listener único para todas las compras (evita memory leak)
local purchaseListenerConnected = false
local function setupGlobalPurchaseListener()
	if purchaseListenerConnected then return end
	purchaseListenerConnected = true

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasingPlayer, passId, wasPurchased)
		if purchasingPlayer == player and wasPurchased then
			-- Actualizar cache
			gamepassCache[passId] = true
			updateGamepassAttribute(passId)
			-- Notificar a todas las cards que se actualizó
			if _G.GamepassShopPurchaseCallback then
				_G.GamepassShopPurchaseCallback(passId)
			end
		end
	end)
end

setupGlobalPurchaseListener()

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE PRODUCTOS
-- ════════════════════════════════════════════════════════════════
local FEATURED_PRODUCT = {
	name = "COMANDOS",
	price = 1500,
	gamepassId = Configuration.COMMANDS,
	icon = "128637341143304",
	tag = "MÁS POPULAR",
	description = "Acceso a todos los comandos premium"
}

local PRODUCTS = {
	{name = "VIP", price = 200, gamepassId = Configuration.VIP, icon = "105371615637765", cmd = "Acceso VIP"},
	{name = "COLORES", price = 50, gamepassId = Configuration.COLORS, icon = "98089887808291", cmd = ";cl [color]"},
	{name = "POLICÍA", price = 135, gamepassId = Configuration.TOMBO, icon = "106800054163320", cmd = ";tombo"},
	{name = "LADRÓN", price = 135, gamepassId = Configuration.CHORO, icon = "84699864716808", cmd = ";choro"},
	{name = "SEGURIDAD", price = 135, gamepassId = Configuration.SERE, icon = "85734290151599", cmd = ";sere"},
}

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GamepassShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER (SIN CAMBIOS)
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "GamepassShop",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = 12,
	enableBlur = true,
	blurSize = 14
})

local panel = modal:getPanel()
panel.BackgroundColor3 = THEME.bg
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- PATRÓN DE GRID (DECORACIÓN DE FONDO)
-- ════════════════════════════════════════════════════════════════
local gridPattern = Instance.new("Frame")
gridPattern.Name = "GridPattern"
gridPattern.Size = UDim2.new(1, -20, 1, -20)
gridPattern.Position = UDim2.new(0, 10, 0, 10)
gridPattern.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
gridPattern.Transparency = 0.92
gridPattern.BorderSizePixel = 0
gridPattern.ClipsDescendants = true
gridPattern.ZIndex = 99
gridPattern.Parent = panel

-- Función para crear líneas con tamaño actual
local function createGridLines()
	-- Limpiar líneas existentes
	for _, child in ipairs(gridPattern:GetChildren()) do
		child:Destroy()
	end
	
	task.wait(0.01) -- Esperar a que se resuelva el tamaño
	
	local gridWidth = gridPattern.AbsoluteSize.X
	local gridHeight = gridPattern.AbsoluteSize.Y
	
	-- Líneas horizontales (solo del centro, sin bordes)
	for i = 1, 9 do
		local hLine = Instance.new("Frame")
		hLine.Name = "HLine_" .. i
		hLine.Size = UDim2.new(1, 0, 0, 2)
		hLine.Position = UDim2.new(0, 0, 0, (gridHeight / 10) * i)
		hLine.BackgroundColor3 = COLORS.accent
		hLine.Transparency = 0.55
		hLine.BorderSizePixel = 0
		hLine.ZIndex = 99
		hLine.Parent = gridPattern
		
		local hLineCorner = Instance.new("UICorner")
		hLineCorner.CornerRadius = UDim.new(0, 20)
		hLineCorner.Parent = hLine
	end

	-- Líneas verticales (solo del centro, sin bordes)
	for i = 1, 9 do
		local vLine = Instance.new("Frame")
		vLine.Name = "VLine_" .. i
		vLine.Size = UDim2.new(0, 2, 1, 0)
		vLine.Position = UDim2.new(0, (gridWidth / 10) * i, 0, 0)
		vLine.BackgroundColor3 = COLORS.accent
		vLine.Transparency = 0.55
		vLine.BorderSizePixel = 0
		vLine.ZIndex = 99
		vLine.Parent = gridPattern
		
		local vLineCorner = Instance.new("UICorner")
		vLineCorner.CornerRadius = UDim.new(0, 20)
		vLineCorner.Parent = vLine
	end
end

-- Crear líneas cuando el grid esté listo
task.wait(0.1)
createGridLines()

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES UTILITARIAS
-- ════════════════════════════════════════════════════════════════
local function createPremiumButton(parent, text, size, position, isPrimary)
	local btn = Instance.new("TextButton")
	btn.Name = "BuyButton"
	btn.Size = size
	btn.Position = position
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = isPrimary and COLORS.gold or COLORS.accent
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = parent.ZIndex + 5
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 240, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	gradient.Rotation = 90
	gradient.Parent = btn

	local btnText = Instance.new("TextLabel")
	btnText.Size = UDim2.new(1, 0, 1, 0)
	btnText.BackgroundTransparency = 1
	btnText.Text = text
	btnText.TextColor3 = isPrimary and Color3.fromRGB(30, 30, 30) or Color3.new(1, 1, 1)
	btnText.Font = Enum.Font.GothamBold
	btnText.TextSize = isPrimary and 16 or 13
	btnText.ZIndex = btn.ZIndex + 1
	btnText.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = UDim2.new(size.X.Scale, size.X.Offset + 4, size.Y.Scale, size.Y.Offset + 2)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = size
		}):Play()
	end)

	return btn
end

local function createIconContainer(parent, iconId, size, position, glowColor)
	local container = Instance.new("Frame")
	container.Name = "IconContainer"
	container.Size = size
	container.Position = position
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	container.ZIndex = parent.ZIndex + 2
	container.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = glowColor or COLORS.accent
	stroke.Thickness = 3
	stroke.Transparency = 0.5
	stroke.Parent = container

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.7, 0, 0.7, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://" .. iconId
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = container.ZIndex + 1
	icon.Parent = container

	return container, icon, stroke
end

-- ════════════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════════════
local header = UI.frame({name = "Header", size = UDim2.new(1, 0, 0, 70), bg = THEME.head or Color3.fromRGB(22, 22, 28), z = 101, parent = panel, corner = 12})

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.head), ColorSequenceKeypoint.new(1, THEME.card)}
headerGradient.Rotation = 90
headerGradient.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 25, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LA TIENDITA"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 102
title.Parent = header

local closeBtn = UI.button({name = "CloseBtn", size = UDim2.new(0, 44, 0, 44), pos = UDim2.new(1, -55, 0.5, -22), bg = THEME.card, text = "×", color = THEME.muted, textSize = 22, z = 103, parent = header, corner = 10})
UI.stroked(closeBtn, 0.4)

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(180, 60, 60),
		TextColor3 = Color3.new(1, 1, 1)
	}):Play()
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.card,
		TextColor3 = THEME.muted
	}):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- CONTENIDO PRINCIPAL
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({name = "ContentArea", size = UDim2.new(1, -30, 1, -100), pos = UDim2.new(0, 15, 0, 80), bgT = 1, z = 101, parent = panel, corner = 0, clips = false})

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -8, 1, 0)
content.Position = UDim2.new(0, 0, 0, 0)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 0
content.ScrollBarImageColor3 = THEME.accent
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.CanvasSize = UDim2.new(0, 0, 0, 750)
content.ZIndex = 101
content.Parent = contentArea

-- ════════════════════════════════════════════════════════════════
-- CARD DESTACADA (MEJORADA)
-- ════════════════════════════════════════════════════════════════
local featuredCard = Instance.new("Frame")
featuredCard.Name = "FeaturedCard"
featuredCard.Size = UDim2.new(1, -20, 0, 155)
featuredCard.Position = UDim2.new(0, 10, 0, 10)
featuredCard.BackgroundColor3 = THEME.card
featuredCard.BorderSizePixel = 0
featuredCard.ZIndex = 102
featuredCard.Parent = content

local featuredCorner = Instance.new("UICorner")
featuredCorner.CornerRadius = UDim.new(0, 14)
featuredCorner.Parent = featuredCard

local featuredStroke = Instance.new("UIStroke")
featuredStroke.Color = COLORS.gold
featuredStroke.Thickness = 2
featuredStroke.Transparency = 0.4
featuredStroke.Parent = featuredCard

-- Tag destacado
local featuredTag = Instance.new("TextLabel")
featuredTag.Size = UDim2.new(0, 100, 0, 22)
featuredTag.Position = UDim2.new(0, 15, 0, 18)
featuredTag.BackgroundColor3 = COLORS.gold
featuredTag.Text = FEATURED_PRODUCT.tag
featuredTag.TextColor3 = Color3.fromRGB(30, 25, 10)
featuredTag.Font = Enum.Font.GothamBlack
featuredTag.TextSize = 11
featuredTag.ZIndex = 105
featuredTag.Parent = featuredCard

local tagCorner = Instance.new("UICorner")
tagCorner.CornerRadius = UDim.new(0, 6)
tagCorner.Parent = featuredTag

-- Icono destacado
local featuredIconContainer, featuredIcon, featuredIconStroke = createIconContainer(
	featuredCard, 
	FEATURED_PRODUCT.icon, 
	UDim2.new(0, 95, 0, 95),
	UDim2.new(0, 75, 0.5, 8),
	COLORS.gold
)

-- Nombre destacado
local featuredName = Instance.new("TextLabel")
featuredName.Size = UDim2.new(0, 280, 0, 32)
featuredName.Position = UDim2.new(0, 140, 0, 45)
featuredName.BackgroundTransparency = 1
featuredName.Text = FEATURED_PRODUCT.name
featuredName.TextColor3 = THEME.text
featuredName.Font = Enum.Font.GothamBlack
featuredName.TextSize = 26
featuredName.TextXAlignment = Enum.TextXAlignment.Left
featuredName.ZIndex = 104
featuredName.Parent = featuredCard

-- Descripción
local featuredDesc = Instance.new("TextLabel")
featuredDesc.Size = UDim2.new(0, 280, 0, 18)
featuredDesc.Position = UDim2.new(0, 140, 0, 78)
featuredDesc.BackgroundTransparency = 1
featuredDesc.Text = FEATURED_PRODUCT.description
featuredDesc.TextColor3 = THEME.muted
featuredDesc.Font = Enum.Font.GothamMedium
featuredDesc.TextSize = 12
featuredDesc.TextXAlignment = Enum.TextXAlignment.Left
featuredDesc.ZIndex = 104
featuredDesc.Parent = featuredCard

-- Precio destacado
local featuredPriceBg = Instance.new("Frame")
featuredPriceBg.Size = UDim2.new(0, 100, 0, 32)
featuredPriceBg.Position = UDim2.new(0, 140, 0, 105)
featuredPriceBg.BackgroundColor3 = Color3.fromRGB(45, 42, 35)
featuredPriceBg.ZIndex = 104
featuredPriceBg.Parent = featuredCard

local priceBgCorner = Instance.new("UICorner")
priceBgCorner.CornerRadius = UDim.new(0, 8)
priceBgCorner.Parent = featuredPriceBg

local featuredPrice = Instance.new("TextLabel")
featuredPrice.Size = UDim2.new(1, 0, 1, 0)
featuredPrice.BackgroundTransparency = 1
featuredPrice.Text = "💎 " .. FEATURED_PRODUCT.price .. " R$"
featuredPrice.TextColor3 = COLORS.gold
featuredPrice.Font = Enum.Font.GothamBold
featuredPrice.TextSize = 14
featuredPrice.ZIndex = 105
featuredPrice.Parent = featuredPriceBg

-- Botón comprar destacado
local featuredBuyBtn = createPremiumButton(
	featuredCard,
	"COMPRAR AHORA",
	UDim2.new(0, 150, 0, 44),
	UDim2.new(1, -95, 0.5, 5),
	true
)

featuredBuyBtn.MouseButton1Click:Connect(function()
	if featuredBuyBtn:GetAttribute("IsPurchased") then return end
	pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, FEATURED_PRODUCT.gamepassId)
	end)
end)

-- Función para actualizar estado del botón destacado
local function updateFeaturedButton()
	if playerOwnsGamePass(FEATURED_PRODUCT.gamepassId) then
		local btnTextLabel = featuredBuyBtn:FindFirstChildOfClass("TextLabel")
		if btnTextLabel then
			btnTextLabel.Text = "PROPIETARIO"
			btnTextLabel.TextColor3 = COLORS.gold
		end
		featuredBuyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		featuredBuyBtn:SetAttribute("IsPurchased", true)
	else
		featuredBuyBtn:SetAttribute("IsPurchased", false)
	end
end

-- Verificar estado inicial
updateFeaturedButton()

-- Actualizar cuando se compra cualquier gamepass
local function setupFeaturedCallback()
	local oldCallback = _G.GamepassShopPurchaseCallback
	_G.GamepassShopPurchaseCallback = function(passId)
		if passId == FEATURED_PRODUCT.gamepassId then
			updateFeaturedButton()
		end
		if oldCallback then oldCallback(passId) end
	end
end

setupFeaturedCallback()

-- Hover en card destacada
featuredCard.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		TweenService:Create(featuredStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
		TweenService:Create(featuredIconStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
	end
end)

featuredCard.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		TweenService:Create(featuredStroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
		TweenService:Create(featuredIconStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- SEPARADOR
-- ════════════════════════════════════════════════════════════════
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, -60, 0, 1)
separator.Position = UDim2.new(0.5, 0, 0, 220)
separator.AnchorPoint = Vector2.new(0.5, 0)
separator.BackgroundColor3 = THEME.stroke
separator.BackgroundTransparency = 0.6
separator.BorderSizePixel = 0
separator.ZIndex = 102
separator.Parent = content

local separatorLabel = Instance.new("TextLabel")
separatorLabel.Size = UDim2.new(0, 180, 0, 26)
separatorLabel.Position = UDim2.new(0.5, 0, 0, 205)
separatorLabel.AnchorPoint = Vector2.new(0.5, 0)
separatorLabel.BackgroundColor3 = THEME.bg
separatorLabel.Text = "MÁS GAMEPASSES"
separatorLabel.TextColor3 = THEME.muted
separatorLabel.Font = Enum.Font.GothamBold
separatorLabel.TextSize = 13
separatorLabel.ZIndex = 103
separatorLabel.Parent = content

-- ════════════════════════════════════════════════════════════════
-- GRID DE PRODUCTOS (3 COLUMNAS + CENTRADO)
-- ════════════════════════════════════════════════════════════════
local gridContainer = Instance.new("Frame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(1, -20, 0, 450)
gridContainer.Position = UDim2.new(0, 10, 0, 250)
gridContainer.BackgroundTransparency = 1
gridContainer.ZIndex = 102
gridContainer.Parent = content

-- Almacenar cards creadas
local productCards = {}

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Crear Card de Producto (MEJORADA)
-- ════════════════════════════════════════════════════════════════
local function createProductCard(product, index)
	local card = Instance.new("Frame")
	card.Name = product.name .. "Card"
	card.Size = UDim2.new(0, GRID_CONFIG.cardWidth, 0, GRID_CONFIG.cardHeight)
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.ZIndex = 103
	card.Parent = gridContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.stroke
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card

	-- Precio badge (arriba derecha)
	-- Mantener borde visible
	local priceBadge = Instance.new("Frame")
	priceBadge.Size = UDim2.new(0, 70, 0, 24)
	priceBadge.Position = UDim2.new(1, -10, 0, 10)
	priceBadge.AnchorPoint = Vector2.new(1, 0)
	priceBadge.BackgroundColor3 = Color3.fromRGB(45, 42, 35)
	priceBadge.ZIndex = 105
	priceBadge.Parent = card

	local priceBadgeCorner = Instance.new("UICorner")
	priceBadgeCorner.CornerRadius = UDim.new(0, 6)
	priceBadgeCorner.Parent = priceBadge

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = product.price .. " R$"
	priceLabel.TextColor3 = COLORS.gold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 12
	priceLabel.ZIndex = 106
	priceLabel.Parent = priceBadge

	-- Icono del producto
	local iconContainer, icon, iconStroke = createIconContainer(
		card,
		product.icon,
		UDim2.new(0, 72, 0, 72),
		UDim2.new(0.5, 0, 0, 58),
		COLORS.accent
	)

	-- Nombre del producto
	local productName = Instance.new("TextLabel")
	productName.Size = UDim2.new(1, -16, 0, 22)
	productName.Position = UDim2.new(0.5, 0, 0, 105)
	productName.AnchorPoint = Vector2.new(0.5, 0)
	productName.BackgroundTransparency = 1
	productName.Text = product.name
	productName.TextColor3 = THEME.text
	productName.Font = Enum.Font.GothamBold
	productName.TextSize = 16
	productName.ZIndex = 105
	productName.Parent = card

	-- Comando badge
	local cmdBadge = Instance.new("Frame")
	cmdBadge.Size = UDim2.new(0, 90, 0, 22)
	cmdBadge.Position = UDim2.new(0.5, 0, 0, 130)
	cmdBadge.AnchorPoint = Vector2.new(0.5, 0)
	cmdBadge.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	cmdBadge.ZIndex = 105
	cmdBadge.Parent = card

	local cmdCorner = Instance.new("UICorner")
	cmdCorner.CornerRadius = UDim.new(0, 5)
	cmdCorner.Parent = cmdBadge

	local cmdLabel = Instance.new("TextLabel")
	cmdLabel.Size = UDim2.new(1, 0, 1, 0)
	cmdLabel.BackgroundTransparency = 1
	cmdLabel.Text = product.cmd
	cmdLabel.TextColor3 = COLORS.accent
	cmdLabel.Font = Enum.Font.GothamMedium
	cmdLabel.TextSize = 14
	cmdLabel.ZIndex = 106
	cmdLabel.Parent = cmdBadge

	-- Overlay oscuro (aparece en hover)
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 107
	overlay.Parent = card

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 12)
	overlayCorner.Parent = overlay

	-- Botón COMPRAR (centrado en overlay, invisible inicialmente)
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(0, 100, 0, 32)
	buyBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	buyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buyBtn.BackgroundColor3 = COLORS.accent
	buyBtn.BackgroundTransparency = 1
	buyBtn.Text = ""
	buyBtn.AutoButtonColor = false
	buyBtn.ZIndex = 108
	buyBtn.Parent = overlay

	local buyBtnCorner = Instance.new("UICorner")
	buyBtnCorner.CornerRadius = UDim.new(0, 8)
	buyBtnCorner.Parent = buyBtn

	local buyBtnText = Instance.new("TextLabel")
	buyBtnText.Size = UDim2.new(1, 0, 1, 0)
	buyBtnText.BackgroundTransparency = 1
	buyBtnText.Text = "COMPRAR"
	buyBtnText.TextColor3 = Color3.new(1, 1, 1)
	buyBtnText.TextTransparency = 1
	buyBtnText.Font = Enum.Font.GothamBold
	buyBtnText.TextSize = 12
	buyBtnText.ZIndex = 109
	buyBtnText.Parent = buyBtn

	-- Función para marcar como propietario
	local function markAsPurchased()
		buyBtn.BackgroundTransparency = 1
		buyBtnText.Text = "PROPIETARIO"
		buyBtnText.TextColor3 = COLORS.gold
		buyBtnText.TextTransparency = 1  -- Mantener invisible hasta hover
		card:SetAttribute("IsPurchased", true)
		-- Actualizar atributo del jugador
		updateGamepassAttribute(product.gamepassId)
	end

	-- Verificar si ya es propietario
	if playerOwnsGamePass(product.gamepassId) then
		markAsPurchased()
	end

	-- Click comprar
	buyBtn.MouseButton1Click:Connect(function()
		if card:GetAttribute("IsPurchased") then return end
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end)

	-- Escuchar actualizaciones del callback global (sin crear listener duplicado)
	task.spawn(function()
		local oldCallback = _G.GamepassShopPurchaseCallback
		_G.GamepassShopPurchaseCallback = function(passId)
			if passId == product.gamepassId then
				markAsPurchased()
			end
			if oldCallback then oldCallback(passId) end
		end
	end)

	-- Hover effects
	local isHovering = false

	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			isHovering = true
			-- Cambiar borde a accent
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = COLORS.accent,
				Transparency = 0
			}):Play()
			-- Mostrar overlay y botón
			TweenService:Create(overlay, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.4
			}):Play()
			TweenService:Create(buyBtn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0
			}):Play()
			TweenService:Create(buyBtnText, TweenInfo.new(0.2), {
				TextTransparency = 0
			}):Play()
		end
	end)

	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			isHovering = false
			-- Restaurar borde original
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = THEME.stroke,
				Transparency = 0.5
			}):Play()
			-- Ocultar overlay y botón
			TweenService:Create(overlay, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(buyBtn, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(buyBtnText, TweenInfo.new(0.2), {
				TextTransparency = 1
			}):Play()
		end
	end)

	return card
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN: Posicionar Grid (3 columnas, centrado automático)
-- ════════════════════════════════════════════════════════════════
local function layoutGrid()
	-- Limpiar cards existentes
	for _, card in ipairs(productCards) do
		if card then card:Destroy() end
	end
	productCards = {}

	-- Crear nuevas cards
	for i, product in ipairs(PRODUCTS) do
		local card = createProductCard(product, i)
		table.insert(productCards, card)
	end

	local cols = GRID_CONFIG.columns
	local cardW = GRID_CONFIG.cardWidth
	local cardH = GRID_CONFIG.cardHeight
	local gap = GRID_CONFIG.gap

	-- Obtener ancho del contenedor
	local containerWidth = gridContainer.AbsoluteSize.X
	if containerWidth == 0 then
		containerWidth = (THEME.panelWidth or 980) - 50
	end

	local totalProducts = #productCards
	local fullRows = math.floor(totalProducts / cols)
	local lastRowCount = totalProducts % cols

	-- Calcular ancho total de una fila completa (3 cards)
	local fullRowWidth = (cardW * cols) + (gap * (cols - 1))
	local fullRowStartX = (containerWidth - fullRowWidth) / 2

	for i, card in ipairs(productCards) do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols

		local xPos, yPos

		-- Si es la última fila y tiene menos de 3 cards
		if row == fullRows and lastRowCount > 0 then
			local lastRowWidth = (cardW * lastRowCount) + (gap * (lastRowCount - 1))
			local lastRowStartX = (containerWidth - lastRowWidth) / 2
			local colInLastRow = (i - 1) - (fullRows * cols)
			xPos = lastRowStartX + (colInLastRow * (cardW + gap))
		else
			xPos = fullRowStartX + (col * (cardW + gap))
		end

		yPos = row * (cardH + gap)
		card.Position = UDim2.new(0, xPos, 0, yPos)
	end

	-- Actualizar altura del grid y canvas
	local totalRows = math.ceil(totalProducts / cols)
	local gridHeight = (totalRows * cardH) + ((totalRows - 1) * gap) + 20
	gridContainer.Size = UDim2.new(1, -20, 0, gridHeight)
	content.CanvasSize = UDim2.new(0, 0, 0, 200 + gridHeight + 30)
end

-- Ejecutar layout inicial
task.wait(0.1)
layoutGrid()

-- Re-layout cuando cambie el tamaño
gridContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	task.wait(0.05)
	layoutGrid()
end)

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES PÚBLICAS
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
	task.wait(0.1)
	layoutGrid()
end

local function closeUI()
	if not modal:isModalOpen() then return end
	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTOS
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
	local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
	GlobalModalManager:closeModal("Shop")
end)

-- ════════════════════════════════════════════════════════════════
-- EXPORT GLOBAL
-- ════════════════════════════════════════════════════════════════
_G.OpenShopUI = openUI
_G.CloseShopUI = closeUI

return {
	open = openUI,
	close = closeUI
}