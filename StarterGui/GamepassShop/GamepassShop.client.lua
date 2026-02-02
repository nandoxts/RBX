--[[
GamepassShop - Tienda de Gamepasses PREMIUM
Diseño moderno con card destacada y grid uniforme
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

-- ════════════════════════════════════════════════════════════════
-- COLORES (Extendidos de THEME)
-- ════════════════════════════════════════════════════════════════
local COLORS = setmetatable({
	gold = Color3.fromRGB(255, 200, 80),
	goldGlow = Color3.fromRGB(255, 180, 50),
}, { __index = THEME })

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE PRODUCTOS
-- ════════════════════════════════════════════════════════════════
local FEATURED_PRODUCT = {
	name = "COMANDOS",
	price = 1500,
	gamepassId = Configuration.COMMANDS,
	icon = "128637341143304",
	tag = "MÁS POPULAR"
}

local PRODUCTS = {
	{
		name = "VIP",
		price = 200,
		gamepassId = Configuration.VIP,
		icon = "105371615637765",
		cmd = "Acceso VIP"
	},
	{
		name = "COLORES",
		price = 50,
		gamepassId = Configuration.COLORS,
		icon = "98089887808291",
		cmd = ":cl [color]"
	},
	{
		name = "POLICÍA",
		price = 135,
		gamepassId = Configuration.TOMBO,
		icon = "106800054163320",
		cmd = ":tombo"
	},
	{
		name = "LADRÓN",
		price = 135,
		gamepassId = Configuration.CHORO,
		icon = "84699864716808",
		cmd = ":choro"
	},
	{
		name = "SEGURIDAD",
		price = 135,
		gamepassId = Configuration.SERE,
		icon = "85734290151599",
		cmd = ":sere"
	}
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
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "GamepassShop",
	panelWidth = THEME.panelWidth or 980,
	panelHeight = THEME.panelHeight or 620,
	cornerRadius = 12,
	enableBlur = true,
	blurSize = 14
})

local panel = modal:getPanel()
panel.BackgroundColor3 = THEME.bg

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
	btnText.TextSize = isPrimary and 18 or 14
	btnText.ZIndex = btn.ZIndex + 1
	btnText.Parent = btn
	
	-- Hover effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(size.X.Scale, size.X.Offset + 6, size.Y.Scale, size.Y.Offset + 4)
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
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
	icon.Size = UDim2.new(0.75, 0, 0.75, 0)
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

-- Icono de tienda
local shopIcon = Instance.new("TextLabel")
shopIcon.Size = UDim2.new(0, 50, 0, 50)
shopIcon.Position = UDim2.new(0, 25, 0.5, 0)
shopIcon.AnchorPoint = Vector2.new(0, 0.5)
shopIcon.BackgroundTransparency = 1
shopIcon.Text = ""
shopIcon.TextSize = 32
shopIcon.ZIndex = 102
shopIcon.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 75, 0, 0)
title.BackgroundTransparency = 1
title.Text = "LA TIENDITA"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 102
title.Parent = header

-- Botón cerrar premium
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
content.ScrollBarThickness = 8
content.ScrollBarImageColor3 = THEME.accent
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.CanvasSize = UDim2.new(0, 0, 0, 750)
content.ZIndex = 101
content.Parent = contentArea

-- ════════════════════════════════════════════════════════════════
-- CARD DESTACADA (COMANDOS)
-- ════════════════════════════════════════════════════════════════
local featuredCard = Instance.new("Frame")
featuredCard.Name = "FeaturedCard"
featuredCard.Size = UDim2.new(1, -20, 0, 180)
featuredCard.Position = UDim2.new(0, 10, 0, 15)
featuredCard.BackgroundColor3 = THEME.card
featuredCard.BorderSizePixel = 0
featuredCard.ZIndex = 102
featuredCard.Parent = content

local featuredCorner = Instance.new("UICorner")
featuredCorner.CornerRadius = UDim.new(0, 16)
featuredCorner.Parent = featuredCard

local featuredStroke = Instance.new("UIStroke")
featuredStroke.Color = COLORS.gold
featuredStroke.Thickness = 2
featuredStroke.Transparency = 0.3
featuredStroke.Parent = featuredCard

-- Gradiente dorado sutil
local featuredGradient = Instance.new("Frame")
featuredGradient.Size = UDim2.new(1, 0, 1, 0)
featuredGradient.BackgroundTransparency = 0.85
featuredGradient.BackgroundColor3 = COLORS.gold
featuredGradient.ZIndex = 102
featuredGradient.Parent = featuredCard

local fgCorner = Instance.new("UICorner")
fgCorner.CornerRadius = UDim.new(0, 16)
fgCorner.Parent = featuredGradient

local fgGradient = Instance.new("UIGradient")
fgGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.7),
	NumberSequenceKeypoint.new(1, 1)
})
fgGradient.Rotation = 45
fgGradient.Parent = featuredGradient

-- Tag destacado
local featuredTag = Instance.new("TextLabel")
featuredTag.Size = UDim2.new(0, 140, 0, 32)
featuredTag.Position = UDim2.new(0, 20, 0, 20)
featuredTag.BackgroundColor3 = COLORS.gold
featuredTag.Text = FEATURED_PRODUCT.tag
featuredTag.TextColor3 = Color3.fromRGB(30, 30, 30)
featuredTag.Font = Enum.Font.GothamBold
featuredTag.TextSize = 13
featuredTag.ZIndex = 105
featuredTag.Parent = featuredCard

local tagCorner = Instance.new("UICorner")
tagCorner.CornerRadius = UDim.new(0, 8)
tagCorner.Parent = featuredTag

-- Icono destacado
local featuredIconContainer, featuredIcon = createIconContainer(
	featuredCard, 
	FEATURED_PRODUCT.icon, 
	UDim2.new(0, 120, 0, 120),
	UDim2.new(0, 100, 0.5, 5),
	COLORS.gold
)

-- Información destacada
local featuredInfo = Instance.new("Frame")
featuredInfo.Size = UDim2.new(1, -300, 1, -40)
featuredInfo.Position = UDim2.new(0, 180, 0, 20)
featuredInfo.BackgroundTransparency = 1
featuredInfo.ZIndex = 103
featuredInfo.Parent = featuredCard

local featuredName = Instance.new("TextLabel")
featuredName.Size = UDim2.new(1, 0, 0, 40)
featuredName.Position = UDim2.new(0, 0, 0, 10)
featuredName.BackgroundTransparency = 1
featuredName.Text = FEATURED_PRODUCT.name
	featuredName.TextColor3 = THEME.text

local featuredPriceContainer = Instance.new("Frame")
featuredPriceContainer.Size = UDim2.new(0, 120, 0, 40)
featuredPriceContainer.Position = UDim2.new(0, 0, 0, 105)
featuredPriceContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
featuredPriceContainer.ZIndex = 104
featuredPriceContainer.Parent = featuredInfo

local priceCorner = Instance.new("UICorner")
priceCorner.CornerRadius = UDim.new(0, 10)
priceCorner.Parent = featuredPriceContainer

local featuredPrice = Instance.new("TextLabel")
featuredPrice.Size = UDim2.new(1, 0, 1, 0)
featuredPrice.BackgroundTransparency = 1
featuredPrice.Text = FEATURED_PRODUCT.price .. " R$"
featuredPrice.TextColor3 = COLORS.gold
featuredPrice.Font = Enum.Font.GothamBold
featuredPrice.TextSize = 18
featuredPrice.ZIndex = 105
featuredPrice.Parent = featuredPriceContainer

-- Botón comprar destacado
local featuredBuyBtn = createPremiumButton(
	featuredCard,
	"COMPRAR AHORA",
	UDim2.new(0, 180, 0, 50),
	UDim2.new(1, -120, 0.5, 5),
	true
)

featuredBuyBtn.MouseButton1Click:Connect(function()
	pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, FEATURED_PRODUCT.gamepassId)
	end)
end)

-- Hover en card destacada
featuredCard.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		TweenService:Create(featuredStroke, TweenInfo.new(0.2), {
			Transparency = 0
		}):Play()
	end
end)

featuredCard.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		TweenService:Create(featuredStroke, TweenInfo.new(0.2), {
			Transparency = 0.3
		}):Play()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- GRID DE PRODUCTOS
-- ════════════════════════════════════════════════════════════════
local gridContainer = Instance.new("Frame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(1, -20, 0, 500)
gridContainer.Position = UDim2.new(0, 10, 0, 210)
gridContainer.BackgroundTransparency = 1
gridContainer.ZIndex = 102
gridContainer.Parent = content

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 230, 0, 150)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.Parent = gridContainer

-- Función para crear cards de producto
local function createProductCard(product, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = product.name .. "Card"
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.ZIndex = 103
	card.LayoutOrder = layoutOrder
	card.Parent = gridContainer
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = THEME.stroke
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card
	
	-- Icono del producto
	local iconContainer, icon, iconStroke = createIconContainer(
		card,
		product.icon,
		UDim2.new(0, 70, 0, 70),
		UDim2.new(0.5, 0, 0, 40),
		COLORS.accent
	)
	
	-- Precio encima del icono
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 60, 0, 20)
	priceLabel.Position = UDim2.new(0.5, -30, 0, 15)
	priceLabel.AnchorPoint = Vector2.new(0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = product.price .. " R$"
	priceLabel.TextColor3 = COLORS.gold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 14
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.ZIndex = 105
	priceLabel.Parent = card
	
	-- Información del producto
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(1, -12, 0, 60)
	infoContainer.Position = UDim2.new(0, 6, 0, 115)
	infoContainer.BackgroundTransparency = 1
	infoContainer.ZIndex = 104
	infoContainer.Parent = card
	
	local productName = Instance.new("TextLabel")
	productName.Size = UDim2.new(1, 0, 0, 20)
	productName.Position = UDim2.new(0, 0, 0, 0)
	productName.BackgroundTransparency = 1
	productName.Text = product.name
	productName.TextColor3 = THEME.text
	productName.Font = Enum.Font.GothamBold
	productName.TextSize = 18
	productName.TextXAlignment = Enum.TextXAlignment.Center
	productName.ZIndex = 105
	productName.Parent = infoContainer
	
	-- Comando
	local cmdLabel = Instance.new("TextLabel")
	cmdLabel.Size = UDim2.new(1, 0, 0, 22)
	cmdLabel.Position = UDim2.new(0, 0, 0, 24)
	cmdLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	cmdLabel.Text = product.cmd
	cmdLabel.TextColor3 = THEME.accent
	cmdLabel.Font = Enum.Font.GothamMedium
	cmdLabel.TextSize = 12
	cmdLabel.TextXAlignment = Enum.TextXAlignment.Center
	cmdLabel.TextYAlignment = Enum.TextYAlignment.Center
	cmdLabel.ZIndex = 105
	cmdLabel.Parent = infoContainer
	
	local cmdCorner = Instance.new("UICorner")
	cmdCorner.CornerRadius = UDim.new(0, 6)
	cmdCorner.Parent = cmdLabel
	
	-- Botón COMPRAR (invisible por defecto)
	local buyBtn = createPremiumButton(
		card,
		"COMPRAR",
		UDim2.new(0, 100, 0, 36),
		UDim2.new(0.5, 0, 0.5, 35),
		false
	)
	buyBtn.BackgroundTransparency = 1
	buyBtn.TextTransparency = 1
	
	-- Hacer el texto invisible también
	for _, child in pairs(buyBtn:GetChildren()) do
		if child:IsA("TextLabel") then
			child.TextTransparency = 1
		end
	end
	
	buyBtn.MouseButton1Click:Connect(function()
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end)
	
	-- Hover effects en la card
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TweenInfo.new(0.2), {
				BackgroundColor3 = THEME.elevated
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = THEME.accent,
				Transparency = 0
			}):Play()
			TweenService:Create(iconStroke, TweenInfo.new(0.2), {
				Transparency = 0
			}):Play()
			
			-- Mostrar botón
			TweenService:Create(buyBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0
			}):Play()
			
			-- Mostrar texto del botón
			for _, child in pairs(buyBtn:GetChildren()) do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
						TextTransparency = 0
					}):Play()
				end
			end
		end
	end)
	
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TweenInfo.new(0.2), {
				BackgroundColor3 = THEME.card
			}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {
				Color = THEME.stroke,
				Transparency = 0.5
			}):Play()
			TweenService:Create(iconStroke, TweenInfo.new(0.2), {
				Transparency = 0.5
			}):Play()
			
			-- Ocultar botón
			TweenService:Create(buyBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1
			}):Play()
			
			-- Ocultar texto del botón
			for _, child in pairs(buyBtn:GetChildren()) do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
						TextTransparency = 1
					}):Play()
				end
			end
		end
	end)
	
	return card
end

-- Crear todas las cards de productos
for i, product in ipairs(PRODUCTS) do
	createProductCard(product, i)
end

-- Actualizar tamaño del canvas
task.wait(0.1)
content.CanvasSize = UDim2.new(0, 0, 0, gridContainer.Position.Y.Offset + gridLayout.AbsoluteContentSize.Y + 50)

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES PÚBLICAS
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
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