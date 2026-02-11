--[[
GamepassShop - Tienda de Gamepasses PREMIUM v2
by ignxts (rediseño)
─────────────────────────────────────────────
• Scroll horizontal para pases
• Compatible con móvil (tap en vez de hover)
• Card destacada muestra todos los comandos
• Sin fondo de rayas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Módulos
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local Configuration = require(ReplicatedStorage:WaitForChild("Panda ReplicatedStorage"):WaitForChild("Configuration"))
local CheckGamepassOwnership = ReplicatedStorage:WaitForChild("Panda ReplicatedStorage"):WaitForChild("Gamepass Gifting"):WaitForChild("Remotes"):WaitForChild("Ownership")

-- ════════════════════════════════════════════════════════════════
-- COLORES EXTENDIDOS
-- ════════════════════════════════════════════════════════════════
local COLORS = setmetatable({
	gold = Color3.fromRGB(255, 200, 80),
	goldDark = Color3.fromRGB(80, 65, 20),
	success = Color3.fromRGB(34, 197, 94),
	owned = Color3.fromRGB(34, 197, 94),
	ownedBg = Color3.fromRGB(20, 50, 30),
}, { __index = THEME })

-- ════════════════════════════════════════════════════════════════
-- GAMEPASS OWNERSHIP (cache + listener)
-- ════════════════════════════════════════════════════════════════
local gamepassCache = {}
local purchaseCallbacks = {} -- {[gamepassId] = {func, func, ...}}

local function playerOwnsGamePass(gamePassId)
	if not gamePassId or type(gamePassId) ~= "number" then return false end
	if gamepassCache[gamePassId] ~= nil then return gamepassCache[gamePassId] end

	local ok, owns = pcall(function()
		return CheckGamepassOwnership:InvokeServer(gamePassId)
	end)
	local result = ok and owns
	gamepassCache[gamePassId] = result
	return result
end

local function onPurchase(gamePassId, callback)
	if not purchaseCallbacks[gamePassId] then
		purchaseCallbacks[gamePassId] = {}
	end
	table.insert(purchaseCallbacks[gamePassId], callback)
end

-- Listener global único
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId, bought)
	if who ~= player or not bought then return end
	gamepassCache[passId] = true

	if passId == Configuration.VIP then
		player:SetAttribute("HasVIP", true)
	end

	if purchaseCallbacks[passId] then
		for _, cb in ipairs(purchaseCallbacks[passId]) do
			task.spawn(cb)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- PRODUCTOS
-- ════════════════════════════════════════════════════════════════
local FEATURED_PRODUCT = {
	name = "COMANDOS",
	price = 1500,
	gamepassId = Configuration.COMMANDS,
	icon = "128637341143304",
	tag = "MÁS POPULAR",
	fondo = "79346090571461",
	description = "Acceso a todos los comandos premium",
	commands = {
		";fire [color]", ";hl [color]", ";trail [color]", ";smk [color]", ";rmv",
		";particula [id]", ";size", ";prtcl [color]"
		-- Agrega aquí todos los comandos reales que incluye el pase
	}
}

local PRODUCTS = {
	{name = "VIP",       price = 200, gamepassId = Configuration.VIP,       icon = "76721656269888", cmd = ""},
	{name = "COLORES",   price = 50,  gamepassId = Configuration.COLORS,    icon = "91877799240345",  cmd = ";cl [color]"},
	{name = "POLICÍA",   price = 135, gamepassId = Configuration.TOMBO,     icon = "106800054163320", cmd = ";tombo"},
	{name = "LADRÓN",    price = 135, gamepassId = Configuration.CHORO,     icon = "84699864716808",  cmd = ";choro"},
	{name = "SEGURIDAD", price = 135, gamepassId = Configuration.SERE,      icon = "85734290151599",  cmd = ";sere"},
	{name = "ARMY BOOMS",price = 100, gamepassId = Configuration.ARMYBOOMS, icon = "134501492548324", cmd = ""},
}

-- ════════════════════════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GamepassShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

task.wait(0.5)
local isMobile = UserInputService.TouchEnabled

-- ════════════════════════════════════════════════════════════════
-- MODAL
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "GamepassShop",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = 12,
	enableBlur = true,
	blurSize = 14,
	isMobile = isMobile,
})

local panel = modal:getPanel()
panel.BackgroundColor3 = THEME.bg
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- HEADER (sin cambios, tal como lo pediste)
-- ════════════════════════════════════════════════════════════════
local header = UI.frame({
	name = "Header", size = UDim2.new(1, 0, 0, 70),
	bg = THEME.head or Color3.fromRGB(22, 22, 28),
	z = 101, parent = panel, corner = 12
})

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, THEME.head),
	ColorSequenceKeypoint.new(1, THEME.card)
}
headerGradient.Rotation = 90
headerGradient.Parent = header

UI.label({
	name = "Title", size = UDim2.new(0, 300, 1, 0),
	pos = UDim2.new(0, 25, 0, 0), text = "TIENDA",
	color = THEME.text, font = Enum.Font.GothamBold,
	textSize = 20, alignX = Enum.TextXAlignment.Left,
	z = 102, parent = header
})

local closeBtn = UI.button({
	name = "CloseBtn", size = UDim2.new(0, 44, 0, 44),
	pos = UDim2.new(1, -55, 0.5, -22), bg = THEME.card,
	text = "×", color = THEME.muted, textSize = 22,
	z = 103, parent = header, corner = 10
})
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
-- HELPER: Badge de "PROPIETARIO" visible siempre (no depende de hover)
-- ════════════════════════════════════════════════════════════════
local function createOwnedBadge(parent)
	local badge = UI.frame({
		name = "OwnedBadge",
		size = UDim2.new(1, 0, 0, 28),
		pos = UDim2.new(0, 0, 1, -28),
		bg = COLORS.ownedBg,
		z = parent.ZIndex + 10,
		parent = parent,
	})
	-- Solo redondear abajo
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = badge

	-- Clip para que las esquinas superiores sean rectas
	local mask = Instance.new("Frame")
	mask.Size = UDim2.new(1, 0, 0.5, 0)
	mask.Position = UDim2.new(0, 0, 0, 0)
	mask.BackgroundColor3 = COLORS.ownedBg
	mask.BorderSizePixel = 0
	mask.ZIndex = badge.ZIndex
	mask.Parent = badge

	UI.label({
		name = "OwnedText",
		size = UDim2.new(1, 0, 1, 0),
		text = "PROPIETARIO",
		color = COLORS.owned,
		font = Enum.Font.GothamBold,
		textSize = 11,
		alignX = Enum.TextXAlignment.Center,
		z = badge.ZIndex + 1,
		parent = badge,
	})

	return badge
end

-- ════════════════════════════════════════════════════════════════
-- HELPER: Botón de compra (usado en featured y cards)
-- ════════════════════════════════════════════════════════════════
local function createBuyButton(parent, product, size, pos, isPrimary)
	local btnColor = isPrimary and COLORS.gold or COLORS.accent
	local textColor = isPrimary and Color3.fromRGB(25, 20, 10) or Color3.new(1, 1, 1)

	local btn = UI.button({
		name = "BuyBtn",
		size = size,
		pos = pos,
		bg = btnColor,
		text = isPrimary and (product.price .. " " .. utf8.char(0xE002) .. " - COMPRAR") or (utf8.char(0xE002) .. " " .. product.price),
		color = textColor,
		textSize = isPrimary and 16 or 14,
		font = Enum.Font.GothamBold,
		z = parent.ZIndex + 6,
		parent = parent,
		corner = 8,
	})

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 210, 210)),
	}
	gradient.Rotation = 90
	gradient.Parent = btn

	local owned = false

	local function markOwned()
		if owned then return end
		owned = true
		btn.Visible = false
		createOwnedBadge(parent)
	end

	-- Check inicial
	if playerOwnsGamePass(product.gamepassId) then
		markOwned()
	end

	-- Listener de compra
	onPurchase(product.gamepassId, markOwned)

	btn.MouseButton1Click:Connect(function()
		if owned then return end
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end)

	return btn
end

-- ════════════════════════════════════════════════════════════════
-- ÁREA DE CONTENIDO (scroll vertical principal)
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name = "ContentArea",
	size = UDim2.new(1, 0, 1, -70),
	pos = UDim2.new(0, 0, 0, 70),
	bgT = 1, z = 100,
	parent = panel, clips = true,
})

local mainScroll = Instance.new("ScrollingFrame")
mainScroll.Name = "MainScroll"
mainScroll.Size = UDim2.new(1, 0, 1, 0)
mainScroll.BackgroundTransparency = 1
mainScroll.BorderSizePixel = 0
mainScroll.ScrollBarThickness = 0
mainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
mainScroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- se calcula después
mainScroll.ZIndex = 100
mainScroll.Parent = contentArea

local mainPad = Instance.new("UIPadding")
mainPad.PaddingLeft = UDim.new(0, 16)
mainPad.PaddingRight = UDim.new(0, 16)
mainPad.PaddingTop = UDim.new(0, 14)
mainPad.PaddingBottom = UDim.new(0, 14)
mainPad.Parent = mainScroll

-- ════════════════════════════════════════════════════════════════
-- CARD DESTACADA — COMANDOS (muestra lista de comandos)
-- ════════════════════════════════════════════════════════════════
local featuredCard = UI.frame({
	name = "FeaturedCard",
	size = UDim2.new(1, 0, 0, 200),
	pos = UDim2.new(0, 0, 0, 0),
	bg = THEME.card, z = 102,
	parent = mainScroll, corner = 14,
})

-- Background image 100%
local featBgImg = Instance.new("ImageLabel")
featBgImg.Name = "BgImage"
featBgImg.Size = UDim2.new(1, 0, 1, 0)
featBgImg.Position = UDim2.new(0, 0, 0, 0)
featBgImg.BackgroundTransparency = 1
featBgImg.Image = "rbxassetid://" .. FEATURED_PRODUCT.fondo
featBgImg.ScaleType = Enum.ScaleType.Crop
featBgImg.ZIndex = 102
featBgImg.Parent = featuredCard

-- Agregar UICorner al background image
local bgImgCorner = Instance.new("UICorner")
bgImgCorner.CornerRadius = UDim.new(0, 14)
bgImgCorner.Parent = featBgImg

-- Overlay transparente
local featBgOverlay = UI.frame({
	name = "BgOverlay",
	size = UDim2.new(1, 0, 1, 0),
	pos = UDim2.new(0, 0, 0, 0),
	bg = Color3.fromRGB(0, 0, 0),
	z = 103, parent = featuredCard, corner = 14,
})
featBgOverlay.BackgroundTransparency = 0.75

-- Agregar UICorner al overlay para border radius
local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0, 14)
overlayCorner.Parent = featBgOverlay

-- Borde para el fondo
local bgStroke = Instance.new("UIStroke")
bgStroke.Color = Color3.fromRGB(60, 60, 80)
bgStroke.Thickness = 1.5
bgStroke.Transparency = 0.5
bgStroke.Parent = featuredCard

-- Tag "MÁS POPULAR"
local tag = UI.frame({
	name = "Tag",
	size = UDim2.new(0, 105, 0, 22),
	pos = UDim2.new(0, 12, 0, 12),
	bg = COLORS.gold, z = 107,
	parent = featuredCard, corner = 6,
})
UI.label({
	text = FEATURED_PRODUCT.tag,
	size = UDim2.new(1, 0, 1, 0),
	color = Color3.fromRGB(30, 25, 10),
	font = Enum.Font.GothamBlack, textSize = 10,
	alignX = Enum.TextXAlignment.Center,
	z = 108, parent = tag,
})

-- Icono
local iconFrame = UI.frame({
	name = "IconFrame",
	size = UDim2.new(0, 80, 0, 80),
	pos = UDim2.new(0, 20, 0, 48),
	bg = Color3.fromRGB(35, 35, 50),
	z = 105, parent = featuredCard, corner = 40,
})

-- Borde para el icono
local iconStroke = UI.stroked(iconFrame, 1.5, COLORS.accent)
iconStroke.ZIndex = 109

local iconImg = Instance.new("ImageLabel")
	iconImg.Size = UDim2.new(1, 0, 1, 0)
	iconImg.Position = UDim2.new(0, 0, 0, 0)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = "rbxassetid://" .. FEATURED_PRODUCT.icon
	iconImg.ScaleType = Enum.ScaleType.Crop
	iconImg.ZIndex = 106
	iconImg.Parent = iconFrame

-- Info lado derecho
local infoX = 115 -- offset desde la izquierda

UI.label({
	name = "FeatName", text = FEATURED_PRODUCT.name,
	size = UDim2.new(1, -infoX - 10, 0, 28),
	pos = UDim2.new(0, infoX, 0, 42),
	color = THEME.text, font = Enum.Font.GothamBlack,
	textSize = 22, alignX = Enum.TextXAlignment.Left,
	z = 106, parent = featuredCard,
})

UI.label({
	name = "FeatDesc", text = FEATURED_PRODUCT.description,
	size = UDim2.new(1, -infoX - 10, 0, 16),
	pos = UDim2.new(0, infoX, 0, 70),
	color = THEME.muted, font = Enum.Font.GothamMedium,
	textSize = 11, alignX = Enum.TextXAlignment.Left,
	z = 106, parent = featuredCard,
})

-- Scroll horizontal de comandos
local cmdScroll = Instance.new("ScrollingFrame")
cmdScroll.Name = "CmdScroll"
cmdScroll.Size = UDim2.new(1, -infoX - 10, 0, 26)
cmdScroll.Position = UDim2.new(0, infoX, 0, 92)
cmdScroll.BackgroundTransparency = 1
cmdScroll.BorderSizePixel = 0
cmdScroll.ScrollBarThickness = 0
cmdScroll.ScrollingDirection = Enum.ScrollingDirection.X
cmdScroll.ZIndex = 107
cmdScroll.Parent = featuredCard

local cmdLayout = Instance.new("UIListLayout")
cmdLayout.FillDirection = Enum.FillDirection.Horizontal
cmdLayout.Padding = UDim.new(0, 6)
cmdLayout.SortOrder = Enum.SortOrder.LayoutOrder
cmdLayout.Parent = cmdScroll

for i, cmd in ipairs(FEATURED_PRODUCT.commands) do
	local chip = UI.frame({
		name = "Cmd" .. i,
		size = UDim2.new(0, #cmd * 7 + 16, 0, 24),
		bg = Color3.fromRGB(0, 0, 0),
		z = 108, parent = cmdScroll, corner = 5,
	})
	chip.BackgroundTransparency = 0.4
	UI.label({
		text = cmd, size = UDim2.new(1, 0, 1, 0),
		color = Color3.fromRGB(255, 255, 255), font = Enum.Font.GothamBold,
		textSize = 11, alignX = Enum.TextXAlignment.Center,
		z = 109, parent = chip,
	})
end

-- Actualizar CanvasSize de los chips
task.defer(function()
	cmdScroll.CanvasSize = UDim2.new(0, cmdLayout.AbsoluteContentSize.X + 4, 0, 0)
end)

-- Botón comprar destacado
createBuyButton(
	featuredCard, FEATURED_PRODUCT,
	UDim2.new(1, -infoX - 10, 0, 38),
	UDim2.new(0, infoX, 0, 148),
	true
)

-- ════════════════════════════════════════════════════════════════
-- SECCIÓN: "MÁS GAMEPASSES" — scroll horizontal
-- ════════════════════════════════════════════════════════════════
local sectionY = 224 -- debajo de featured

UI.label({
	name = "SectionTitle",
	size = UDim2.new(1, 0, 0, 20),
	pos = UDim2.new(0, 2, 0, sectionY),
	text = "MÁS GAMEPASSES",
	color = THEME.muted, font = Enum.Font.GothamBold,
	textSize = 12, alignX = Enum.TextXAlignment.Left,
	z = 102, parent = mainScroll,
})

-- Contenedor del scroll horizontal
local hScrollFrame = Instance.new("ScrollingFrame")
hScrollFrame.Name = "HScroll"
hScrollFrame.Size = UDim2.new(1, 0, 0, 210)
hScrollFrame.Position = UDim2.new(0, 0, 0, sectionY + 28)
hScrollFrame.BackgroundTransparency = 1
hScrollFrame.BorderSizePixel = 0
hScrollFrame.ScrollBarThickness = 0
hScrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
hScrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
hScrollFrame.ZIndex = 102
hScrollFrame.Parent = mainScroll

local hLayout = Instance.new("UIListLayout")
hLayout.FillDirection = Enum.FillDirection.Horizontal
hLayout.Padding = UDim.new(0, 12)
hLayout.SortOrder = Enum.SortOrder.LayoutOrder
hLayout.VerticalAlignment = Enum.VerticalAlignment.Top
hLayout.Parent = hScrollFrame

local hPad = Instance.new("UIPadding")
hPad.PaddingLeft = UDim.new(0, 4)
hPad.PaddingRight = UDim.new(0, 20)
hPad.Parent = hScrollFrame

-- ════════════════════════════════════════════════════════════════
-- CREAR CARDS DE PRODUCTO (horizontal, más grandes, mobile-first)
-- ════════════════════════════════════════════════════════════════
local CARD_W = isMobile and 155 or 165
local CARD_H = 200

for i, product in ipairs(PRODUCTS) do
	local card = UI.frame({
		name = product.name .. "Card",
		size = UDim2.new(0, CARD_W, 0, CARD_H),
		bg = Color3.fromRGB(35, 35, 50), z = 103,
		parent = hScrollFrame, corner = 12,
	})
	card.LayoutOrder = i

	local cStroke = UI.stroked(card, 1.5)
	cStroke.ZIndex = 104

	-- Background image 100%
	local bgImg = Instance.new("ImageLabel")
	bgImg.Name = "BgImage"
	bgImg.Size = UDim2.new(1, 0, 1, 0)
	bgImg.Position = UDim2.new(0, 0, 0, 0)
	bgImg.BackgroundTransparency = 1
	bgImg.Image = "rbxassetid://" .. product.icon
	bgImg.ScaleType = Enum.ScaleType.Crop
	bgImg.ZIndex = 103
	bgImg.Parent = card

	-- Overlay transparente
	local bgOverlay = UI.frame({
		name = "BgOverlay",
		size = UDim2.new(1, 0, 1, 0),
		pos = UDim2.new(0, 0, 0, 0),
		bg = Color3.fromRGB(0, 0, 0),
		z = 104, parent = card, corner = 12,
	})
	bgOverlay.BackgroundTransparency = 0.75

	-- Precio
	local priceBg = UI.frame({
		name = "Price",
		size = UDim2.new(0, 62, 0, 24),
		pos = UDim2.new(1, -10, 0, 10),
		bg = COLORS.goldDark,
		z = 106, parent = card, corner = 6,
	})
	priceBg.AnchorPoint = Vector2.new(1, 0)

	UI.label({
		text = utf8.char(0xE002) .. " " .. product.price,
		size = UDim2.new(1, 0, 1, 0),
		color = COLORS.gold, font = Enum.Font.GothamBlack,
		textSize = 13, alignX = Enum.TextXAlignment.Center,
		z = 107, parent = priceBg,
	})

	-- Icono circular 100%
	local cIcon = UI.frame({
		name = "Icon",
		size = UDim2.new(0, 100, 0, 100),
		pos = UDim2.new(0.5, -50, 0.5, -50),
		bg = Color3.fromRGB(30, 30, 45),
		z = 106, parent = card, corner = 50,
	})

	local cImg = Instance.new("ImageLabel")
	cImg.Size = UDim2.new(1, 0, 1, 0)
	cImg.Position = UDim2.new(0, 0, 0, 0)
	cImg.BackgroundTransparency = 1
	cImg.Image = "rbxassetid://" .. product.icon
	cImg.ScaleType = Enum.ScaleType.Crop
	cImg.ZIndex = 107
	cImg.Parent = cIcon

	local cImgCorner = Instance.new("UICorner")
	cImgCorner.CornerRadius = UDim.new(1, 0)
	cImgCorner.Parent = cImg

	local cIconStroke = UI.stroked(cIcon, 1.5, COLORS.accent)
	cIconStroke.ZIndex = 108

	-- Nombre
	UI.label({
		name = "Name", text = product.name,
		size = UDim2.new(1, -12, 0, 30),
		pos = UDim2.new(0.5, 0, 0, 160),
		color = THEME.text, font = Enum.Font.GothamBlack,
		textSize = 15, alignX = Enum.TextXAlignment.Center,
		z = 110, parent = card,
	}).AnchorPoint = Vector2.new(0.5, 0)

	-- Comando chip (solo si existe)
	if product.cmd and product.cmd ~= "" then
		local cmdChip = UI.frame({
			name = "CmdChip",
			size = UDim2.new(0, math.min(#product.cmd * 6 + 18, CARD_W - 14), 0, 24),
			pos = UDim2.new(0.5, 0, 0.5, 0),
			bg = Color3.fromRGB(0, 0, 0),
			z = 115, parent = card, corner = 4,
		})
		cmdChip.AnchorPoint = Vector2.new(0.5, 0.5)
		cmdChip.BackgroundTransparency = 0.4

		UI.label({
			text = product.cmd,
			size = UDim2.new(1, 0, 1, 0),
			color = Color3.fromRGB(255, 255, 255), font = Enum.Font.GothamBold,
			textSize = 12, alignX = Enum.TextXAlignment.Center,
			z = 116, parent = cmdChip,
		})
	end

	-- Botón de compra
	local btnBg = UI.frame({
		name = "BtnBg",
		size = UDim2.new(1, -16, 0, 32),
		pos = UDim2.new(0, 8, 1, -40),
		bg = COLORS.accent,
		z = 110, parent = card, corner = 6,
	})

	local btn = Instance.new("TextButton")
	btn.Name = "BuyBtn"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 111
	btn.Parent = btnBg

	local btnLabel = Instance.new("TextLabel")
	btnLabel.Size = UDim2.new(1, 0, 1, 0)
	btnLabel.BackgroundTransparency = 1
	btnLabel.Text = utf8.char(0xE002) .. " " .. product.price
	btnLabel.TextColor3 = Color3.new(1, 1, 1)
	btnLabel.Font = Enum.Font.GothamBlack
	btnLabel.TextSize = 13
	btnLabel.ZIndex = 112
	btnLabel.Parent = btn

	local owned = false

	local function markOwned()
		if owned then return end
		owned = true
		btnBg.Visible = false
		createOwnedBadge(card)
	end

	if playerOwnsGamePass(product.gamepassId) then
		markOwned()
	end

	onPurchase(product.gamepassId, markOwned)

	btn.MouseButton1Click:Connect(function()
		if owned then return end
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end)

	if not isMobile then
		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(cIconStroke, TweenInfo.new(0.18), {
					Transparency = 0
				}):Play()
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(cIconStroke, TweenInfo.new(0.18), {
					Transparency = 0.5
				}):Play()
			end
		end)
	end
end

-- Actualizar CanvasSize horizontal
task.defer(function()
	hScrollFrame.CanvasSize = UDim2.new(0, hLayout.AbsoluteContentSize.X + 24, 0, 0)
end)

-- ════════════════════════════════════════════════════════════════
-- AJUSTAR CANVAS VERTICAL
-- ════════════════════════════════════════════════════════════════
task.defer(function()
	local totalH = sectionY + 28 + CARD_H + 30
	mainScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
end)

-- ════════════════════════════════════════════════════════════════
-- ABRIR / CERRAR
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
	-- Refresh canvas sizes después de que todo esté visible
	task.wait(0.1)
	task.spawn(function()
		cmdScroll.CanvasSize = UDim2.new(0, cmdScroll:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.X + 4, 0, 0)
		hScrollFrame.CanvasSize = UDim2.new(0, hLayout.AbsoluteContentSize.X + 24, 0, 0)
	end)
end

local function closeUI()
	if not modal:isModalOpen() then return end
	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- EVENTO CERRAR
-- ════════════════════════════════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
	local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
	GlobalModalManager:closeModal("Shop")
end)

-- ════════════════════════════════════════════════════════════════
-- EXPORT
-- ════════════════════════════════════════════════════════════════
_G.OpenShopUI = openUI
_G.CloseShopUI = closeUI

return {
	open = openUI,
	close = closeUI,
}