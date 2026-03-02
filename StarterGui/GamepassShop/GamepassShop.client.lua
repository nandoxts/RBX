--[[
GamepassShop — Rediseño v7
by ignxts- Nando
Layout: Sidebar decorativo + Grid unico + Cards misma altura + Panel mas ancho
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modulos
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local Configuration = require(ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("Configuration"))
local CheckGamepassOwnership = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("Gamepass Gifting"):WaitForChild("Remotes"):WaitForChild("Ownership")

-- ════════════════════════════════════════════════════════════════
-- PALETA v4
-- ════════════════════════════════════════════════════════════════
local C = setmetatable({
	bg          = Color3.fromRGB(10, 10, 16),
	surface     = Color3.fromRGB(18, 18, 28),
	surfaceHov  = Color3.fromRGB(26, 26, 38),
	surfaceAlt  = Color3.fromRGB(14, 14, 22),
	border      = Color3.fromRGB(40, 40, 56),
	borderLight = Color3.fromRGB(55, 55, 72),

	text        = Color3.fromRGB(240, 240, 245),
	textSub     = Color3.fromRGB(130, 130, 155),
	textMuted   = Color3.fromRGB(80, 80, 100),
	textDark    = Color3.fromRGB(12, 12, 18),

	accentPases  = Color3.fromRGB(255, 150, 50),
	accentAuras  = Color3.fromRGB(140, 80, 255),
	accentItems  = Color3.fromRGB(255, 195, 40),

	softPases    = Color3.fromRGB(40, 25, 12),
	softAuras    = Color3.fromRGB(28, 16, 50),
	softItems    = Color3.fromRGB(42, 35, 12),

	owned        = Color3.fromRGB(40, 200, 100),
	ownedBg      = Color3.fromRGB(12, 35, 22),
	danger       = Color3.fromRGB(200, 50, 50),

	sidebarBg    = Color3.fromRGB(14, 14, 22),
}, { __index = THEME })

-- ════════════════════════════════════════════════════════════════
-- TWEENS
-- ════════════════════════════════════════════════════════════════
local TW_FAST  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_NORM  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_FADE  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tw(obj, info, props)
	if not obj then return nil end
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- ════════════════════════════════════════════════════════════════
-- OWNERSHIP CACHE
-- ════════════════════════════════════════════════════════════════
local gpCache = {}
local purchaseCbs = {}

local function preloadOwnership(products)
	if not products then return end
	local ids = {}
	for _, p in ipairs(products) do
		if p.gamepassId and type(p.gamepassId) == "number" and gpCache[p.gamepassId] == nil then
			table.insert(ids, p.gamepassId)
		end
	end
	if #ids == 0 then return end
	for _, gid in ipairs(ids) do
		task.spawn(function()
			if gpCache[gid] == nil then
				pcall(function()
					gpCache[gid] = CheckGamepassOwnership:InvokeServer(gid) or false
				end)
			end
		end)
	end
end

local function onPurchase(gid, cb)
	if not purchaseCbs[gid] then purchaseCbs[gid] = {} end
	table.insert(purchaseCbs[gid], cb)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId, bought)
	if who ~= player or not bought then return end
	gpCache[passId] = true
	if passId == Configuration.VIP then
		player:SetAttribute("HasVIP", true)
	end
	if purchaseCbs[passId] then
		for _, cb in ipairs(purchaseCbs[passId]) do
			task.spawn(cb)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════
-- PRODUCTOS
-- ════════════════════════════════════════════════════════════════

local AURA_THUMBNAILS = {
	{ name = "Dragon",    icon = "96767553403764"  },
	{ name = "Atomic",    icon = "83009199157541"  },
	{ name = "Blazing",   icon = "117387885139799" },
	{ name = "Nano",      icon = "94554178589687"  },
	{ name = "Red Heart", icon = "126464363919641" },
	{ name = "Snow",      icon = "122129911643253" },
}

local ALL_PRODUCTS = {
	{name = "VIP",        price = 200,  gamepassId = Configuration.VIP,        icon = "76721656269888",  fondo = "76721656269888",  cmd = "",            accent = C.accentPases},
	{name = "COMANDOS",   price = 1500, gamepassId = Configuration.COMMANDS,   icon = "128637341143304", fondo = "122601403333222", cmd = "",            accent = C.accentPases},
	{name = "COLORES",    price = 50,   gamepassId = Configuration.COLORS,     icon = "91877799240345",  fondo = "91877799240345",  cmd = ";cl [color]", accent = C.accentPases},
	{name = "POLICIA",    price = 135,  gamepassId = Configuration.TOMBO,      icon = "139661313218787", fondo = "139661313218787", cmd = ";tombo",      accent = C.accentPases},
	{name = "LADRON",     price = 135,  gamepassId = Configuration.CHORO,      icon = "84699864716808",  fondo = "84699864716808",  cmd = ";choro",      accent = C.accentPases},
	{name = "SEGURIDAD",  price = 135,  gamepassId = Configuration.SERE,       icon = "85734290151599",  fondo = "85734290151599",  cmd = ";sere",       accent = C.accentPases},
	{name = "ARMY BOOMS", price = 80,   gamepassId = Configuration.ARMYBOOMS,  icon = "134501492548324", fondo = "134501492548324", cmd = "",            accent = C.accentPases},
	{name = "LIGHTSTICK", price = 80,   gamepassId = Configuration.LIGHTSTICK, icon = "86122436659328",  fondo = "86122436659328",  cmd = "",            accent = C.accentPases},

	{
		name       = "AURA PACK",
		price      = 1000,
		gamepassId = Configuration.AURA_DRAGON,
		icon       = "129517460766852",
		fondo      = "79346090571461",
		cmd        = "",
		accent     = C.accentAuras,
		isAuraPack = true,
	},
}

--[[
	═══ CATEGORIAS (futuro) ═══
	local SHOP_CATEGORIES = {
		{ id = "gamepasses", label = "Pases",      color = C.accentPases },
		{ id = "auras",      label = "Auras",      color = C.accentAuras },
		{ id = "exclusivas", label = "Exclusivas", color = C.accentItems },
	}
]]

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
-- PANEL MAS ANCHO
-- ════════════════════════════════════════════════════════════════
local PANEL_W = isMobile and THEME.panelWidth or math.max(THEME.panelWidth, 780)
local PANEL_H = THEME.panelHeight

-- ════════════════════════════════════════════════════════════════
-- MODAL
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "GamepassShop",
	panelWidth = PANEL_W,
	panelHeight = PANEL_H,
	cornerRadius = 14,
	enableBlur = true,
	blurSize = 20,
	isMobile = isMobile,
})

local panel = modal:getPanel()
panel.BackgroundColor3 = C.bg
panel.ClipsDescendants = true

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local ROBUX_ICON = utf8.char(0xE002)

local function priceStr(amount)
	return ROBUX_ICON .. " " .. tostring(amount)
end

-- ════════════════════════════════════════════════════════════════
-- BADGE ADQUIRIDO
-- ════════════════════════════════════════════════════════════════
local function createOwnedBadge(parent)
	local h = 32
	local badge = UI.frame({
		name = "OwnedBadge",
		size = UDim2.new(1, 0, 0, h),
		pos = UDim2.new(0, 0, 1, -h),
		bg = C.ownedBg,
		z = parent.ZIndex + 15,
		parent = parent, corner = 10,
	})

	local mask = Instance.new("Frame")
	mask.Name = "TopMask"
	mask.Size = UDim2.new(1, 0, 0, 10)
	mask.BackgroundColor3 = C.ownedBg
	mask.BackgroundTransparency = 0
	mask.BorderSizePixel = 0
	mask.ZIndex = badge.ZIndex
	mask.Parent = badge

	UI.label({
		name = "OwnedText",
		size = UDim2.new(1, 0, 1, 0),
		text = "ADQUIRIDO",
		color = C.owned,
		font = Enum.Font.GothamBold, textSize = 11,
		alignX = Enum.TextXAlignment.Center,
		z = badge.ZIndex + 2, parent = badge,
	})

	badge.BackgroundTransparency = 1
	mask.BackgroundTransparency = 1
	tw(badge, TW_NORM, { BackgroundTransparency = 0 })
	tw(mask, TW_NORM, { BackgroundTransparency = 0 })
	return badge
end

-- ════════════════════════════════════════════════════════════════
-- PURCHASE HANDLER
-- ════════════════════════════════════════════════════════════════
local function createPurchaseHandler(btnFrame, btnLabel, parentCard, product)
	local owned = false

	local function markOwned()
		if owned then return end
		owned = true
		tw(btnFrame, TW_FADE, { BackgroundTransparency = 1 })
		if btnLabel then tw(btnLabel, TW_FADE, { TextTransparency = 1 }) end
		task.delay(0.18, function()
			btnFrame.Visible = false
			createOwnedBadge(parentCard)
		end)
	end

	if product.gamepassId then
		local gid = product.gamepassId
		if gpCache[gid] == true then
			markOwned()
		elseif gpCache[gid] == nil then
			task.spawn(function()
				local deadline = tick() + 12
				while gpCache[gid] == nil and tick() < deadline do task.wait(0.15) end
				if gpCache[gid] == true then markOwned() end
			end)
		end
		onPurchase(gid, markOwned)
	end

	return function()
		if owned then return end
		local origSize = btnFrame.Size
		tw(btnFrame, TW_PRESS, { Size = origSize + UDim2.new(0, -4, 0, -2) })
		task.delay(0.08, function() tw(btnFrame, TW_NORM, { Size = origSize }) end)
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- SIDEBAR DECORATIVO
-- ════════════════════════════════════════════════════════════════
local SIDEBAR_W = isMobile and 100 or 130

local sidebar = UI.frame({
	name = "Sidebar",
	size = UDim2.new(0, SIDEBAR_W, 1, 0),
	bg = C.sidebarBg,
	z = 200, parent = panel, clips = true, corner = 14,
})

-- Mascara derecha
local sidebarMaskR = Instance.new("Frame")
sidebarMaskR.Name = "MaskRight"
sidebarMaskR.Size = UDim2.new(0, 14, 1, 0)
sidebarMaskR.Position = UDim2.new(1, -14, 0, 0)
sidebarMaskR.BackgroundColor3 = C.sidebarBg
sidebarMaskR.BorderSizePixel = 0
sidebarMaskR.ZIndex = 200
sidebarMaskR.Parent = sidebar

-- Separador vertical
local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, -24)
sidebarLine.Position = UDim2.new(1, -1, 0, 12)
sidebarLine.BackgroundColor3 = C.border
sidebarLine.BackgroundTransparency = 0.5
sidebarLine.BorderSizePixel = 0
sidebarLine.ZIndex = 201
sidebarLine.Parent = sidebar

-- Titulo SHOP
UI.label({
	name = "ShopTitle",
	size = UDim2.new(1, -16, 0, 36),
	pos = UDim2.new(0, 8, 0, 20),
	text = "SHOP",
	color = C.text,
	font = Enum.Font.GothamBlack,
	textSize = 22,
	alignX = Enum.TextXAlignment.Center,
	z = 202, parent = sidebar,
})

-- (ShopSub eliminado)

-- Linea decorativa
local decoLine1 = Instance.new("Frame")
decoLine1.Size = UDim2.new(0.6, 0, 0, 1)
decoLine1.Position = UDim2.new(0.2, 0, 0, 80)
decoLine1.BackgroundColor3 = C.accentPases
decoLine1.BackgroundTransparency = 0.5
decoLine1.BorderSizePixel = 0
decoLine1.ZIndex = 202
decoLine1.Parent = sidebar

-- Icono decorativo
local decoIconSize = isMobile and 52 or 64
local decoIcon = UI.frame({
	name = "DecoIcon",
	size = UDim2.new(0, decoIconSize, 0, decoIconSize),
	pos = UDim2.new(0.5, -decoIconSize / 2, 0, 96),
	bg = C.surface,
	z = 203, parent = sidebar, corner = decoIconSize / 2,
})

local decoIconStroke = Instance.new("UIStroke")
decoIconStroke.Color = C.accentPases
decoIconStroke.Thickness = 1.5
decoIconStroke.Transparency = 0.4
decoIconStroke.Parent = decoIcon

local decoIconImg = Instance.new("ImageLabel")
decoIconImg.Size = UDim2.new(0.65, 0, 0.65, 0)
decoIconImg.Position = UDim2.new(0.175, 0, 0.175, 0)
decoIconImg.BackgroundTransparency = 1
decoIconImg.Image = "rbxassetid://76721656269888"
decoIconImg.ScaleType = Enum.ScaleType.Fit
decoIconImg.ZIndex = 204
decoIconImg.Parent = decoIcon

UI.label({
	name = "DecoText",
	size = UDim2.new(1, -8, 0, 36),
	pos = UDim2.new(0, 4, 0, decoIconSize + 108),
	text = "GAMEPASSES",
	color = C.accentPases,
	font = Enum.Font.GothamBlack,
	textSize = 14,
	alignX = Enum.TextXAlignment.Center,
	z = 202, parent = sidebar,
})

-- Linea decorativa 2
local decoLine2 = Instance.new("Frame")
decoLine2.Size = UDim2.new(0.4, 0, 0, 1)
decoLine2.Position = UDim2.new(0.3, 0, 0, decoIconSize + 150)
decoLine2.BackgroundColor3 = C.border
decoLine2.BackgroundTransparency = 0.4
decoLine2.BorderSizePixel = 0
decoLine2.ZIndex = 202
decoLine2.Parent = sidebar

-- Items count (abajo)
UI.label({
	name = "BottomInfo",
	size = UDim2.new(1, -12, 0, 30),
	pos = UDim2.new(0, 6, 1, -46),
	text = tostring(#ALL_PRODUCTS) .. " ITEMS",
	color = C.textSub,
	font = Enum.Font.GothamBold,
	textSize = 12,
	alignX = Enum.TextXAlignment.Center,
	z = 202, parent = sidebar,
})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local HEADER_H = 52

local contentArea = UI.frame({
	name = "ContentArea",
	size = UDim2.new(1, -SIDEBAR_W, 1, 0),
	pos = UDim2.new(0, SIDEBAR_W, 0, 0),
	bgT = 1, z = 100,
	parent = panel, clips = true,
})

-- Header
local contentHeader = UI.frame({
	name = "ContentHeader",
	size = UDim2.new(1, 0, 0, HEADER_H),
	bg = C.bg, z = 150,
	parent = contentArea,
})

UI.label({
	name = "Title",
	size = UDim2.new(1, -60, 0, HEADER_H),
	pos = UDim2.new(0, 18, 0, 0),
	text = "GAMEPASSES",
	color = C.text,
	font = Enum.Font.GothamBlack, textSize = 20,
	alignX = Enum.TextXAlignment.Left,
	z = 152, parent = contentHeader,
})

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, -20, 0, 1)
headerLine.Position = UDim2.new(0, 10, 1, -1)
headerLine.BackgroundColor3 = C.border
headerLine.BackgroundTransparency = 0.5
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 152
headerLine.Parent = contentHeader



-- ════════════════════════════════════════════════════════════════
-- SCROLL + GRID
-- ════════════════════════════════════════════════════════════════
local scrollContainer = UI.frame({
	name = "ScrollContainer",
	size = UDim2.new(1, 0, 1, -HEADER_H),
	pos = UDim2.new(0, 0, 0, HEADER_H),
	bgT = 1, z = 100,
	parent = contentArea, clips = true,
})

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = C.border
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ZIndex = 100
scroll.Parent = scrollContainer

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingLeft = UDim.new(0, 12)
scrollPad.PaddingRight = UDim.new(0, 12)
scrollPad.PaddingTop = UDim.new(0, 10)
scrollPad.PaddingBottom = UDim.new(0, 24)
scrollPad.Parent = scroll

-- ════════════════════════════════════════════════════════════════
-- RENDER CARDS — TODAS MISMA ALTURA
-- ════════════════════════════════════════════════════════════════
local GAP = 10
local COLS = 3
local contentW = PANEL_W - SIDEBAR_W - 24
local CARD_W = math.floor((contentW - (GAP * (COLS - 1))) / COLS)
local CARD_H = isMobile and 210 or 220

if CARD_W < 95 then
	COLS = 2
	CARD_W = math.floor((contentW - GAP) / COLS)
end

local gridMaxY = 0

for i, product in ipairs(ALL_PRODUCTS) do
	local col = (i - 1) % COLS
	local row = math.floor((i - 1) / COLS)
	local accent = product.accent or C.accentPases
	local isAura = product.isAuraPack

	local posX = col * (CARD_W + GAP)
	local posY = row * (CARD_H + GAP)

	-- ─── Card ───
	local card = UI.frame({
		name = product.name,
		size = UDim2.new(0, CARD_W, 0, CARD_H),
		pos = UDim2.new(0, posX, 0, posY),
		bg = THEME.card, bgT = THEME.frameAlpha,
		z = 103, parent = scroll, corner = 12,
	})
	card.ClipsDescendants = true

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = C.border
	cStroke.Thickness = 1
	cStroke.Transparency = 0.5
	cStroke.Parent = card

	-- Fondo imagen
	local bgImg = Instance.new("ImageLabel")
	bgImg.Name = "BgImg"
	bgImg.Size = UDim2.new(1, 0, 1, 0)
	bgImg.BackgroundTransparency = 1
	bgImg.Image = "rbxassetid://" .. (product.fondo or product.icon)
	bgImg.ScaleType = Enum.ScaleType.Crop
	bgImg.ImageTransparency = 0.15
	bgImg.ZIndex = 103
	bgImg.Parent = card
	Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0, 12)

	-- Overlay gradiente
	local cardOverlay = UI.frame({
		name = "CardOverlay",
		size = UDim2.new(1, 0, 1, 0),
		bg = THEME.card, bgT = THEME.frameAlpha, z = 104,
		parent = card, corner = 12,
	})

	local cardGrad = Instance.new("UIGradient")
	cardGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	}
	cardGrad.Rotation = 90
	cardGrad.Parent = cardOverlay

	-- Tag badge
	if product.tag and product.tag ~= "" then
		local tagW = #product.tag * 6.5 + 18
		local tagBadge = UI.frame({
			name = "Tag",
			size = UDim2.new(0, tagW, 0, 18),
			pos = UDim2.new(0, 8, 0, 8),
			bg = accent, z = 115,
			parent = card, corner = 4,
		})

		UI.label({
			text = product.tag,
			size = UDim2.new(1, 0, 1, 0),
			color = C.textDark,
			font = Enum.Font.GothamBlack, textSize = 8,
			alignX = Enum.TextXAlignment.Center,
			z = 116, parent = tagBadge,
		})
	end

	-- ─── Layout diferente para Aura Pack (compacto, misma altura) ───
	if isAura then
		-- Icono mas pequeño arriba
		local aIcoSize = 44
		local aIco = UI.frame({
			name = "Icon",
			size = UDim2.new(0, aIcoSize, 0, aIcoSize),
			pos = UDim2.new(0.5, -aIcoSize / 2, 0, 12),
			bg = Color3.fromRGB(14, 14, 22),
			z = 106, parent = card, corner = aIcoSize / 2,
		})

		local aIcoStroke = Instance.new("UIStroke")
		aIcoStroke.Color = accent
		aIcoStroke.Thickness = 1
		aIcoStroke.Transparency = 0.5
		aIcoStroke.Parent = aIco

		local aIcoImg = Instance.new("ImageLabel")
		aIcoImg.Size = UDim2.new(1, 0, 1, 0)
		aIcoImg.BackgroundTransparency = 1
		aIcoImg.Image = "rbxassetid://" .. product.icon
		aIcoImg.ScaleType = Enum.ScaleType.Crop
		aIcoImg.ZIndex = 107
		aIcoImg.Parent = aIco
		Instance.new("UICorner", aIcoImg).CornerRadius = UDim.new(1, 0)

		-- Nombre
		local aNameL = UI.label({
			name = "Name",
			text = product.name,
			size = UDim2.new(1, -10, 0, 18),
			pos = UDim2.new(0.5, 0, 0, 60),
			color = C.text,
			font = Enum.Font.GothamBlack, textSize = 15,
			alignX = Enum.TextXAlignment.Center,
			z = 108, parent = card,
		})
		aNameL.AnchorPoint = Vector2.new(0.5, 0)

		-- "Incluye X auras:"
		UI.label({
			name = "IncludesLabel",
			text = "Incluye " .. tostring(#AURA_THUMBNAILS) .. " auras:",
			size = UDim2.new(1, -8, 0, 12),
			pos = UDim2.new(0, 4, 0, 78),
			color = C.textSub,
			font = Enum.Font.GothamMedium, textSize = 9,
			alignX = Enum.TextXAlignment.Center,
			z = 108, parent = card,
		})

		-- Miniaturas en 2 filas de 3
		local thumbSize = 32
		local thumbGap = 5
		local thumbCols = 3
		local thumbRows = math.ceil(#AURA_THUMBNAILS / thumbCols)
		local totalThumbRowW = (thumbCols * (thumbSize + thumbGap)) - thumbGap
		local thumbStartX = (CARD_W - totalThumbRowW) / 2
		local thumbStartY = 94

		for ti, aura in ipairs(AURA_THUMBNAILS) do
			local tc = (ti - 1) % thumbCols
			local tr = math.floor((ti - 1) / thumbCols)
			local tx = thumbStartX + tc * (thumbSize + thumbGap)
			local ty = thumbStartY + tr * (thumbSize + thumbGap)

			local thumbFrame = UI.frame({
				name = "Thumb_" .. aura.name,
				size = UDim2.new(0, thumbSize, 0, thumbSize),
				pos = UDim2.new(0, tx, 0, ty),
				bg = Color3.fromRGB(10, 10, 18),
				z = 109, parent = card, corner = thumbSize / 2,
			})

			local thumbStroke = Instance.new("UIStroke")
			thumbStroke.Color = C.accentAuras
			thumbStroke.Thickness = 1.5
			thumbStroke.Transparency = 0.4
			thumbStroke.Parent = thumbFrame

			local thumbImg = Instance.new("ImageLabel")
			thumbImg.Size = UDim2.new(1, 0, 1, 0)
			thumbImg.BackgroundTransparency = 1
			thumbImg.Image = "rbxassetid://" .. aura.icon
			thumbImg.ScaleType = Enum.ScaleType.Crop
			thumbImg.ZIndex = 110
			thumbImg.Parent = thumbFrame
			Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)
		end

	else
		-- ─── Layout normal para las demas cards ───
		local cIcoSize = 58
		local cIco = UI.frame({
			name = "Icon",
			size = UDim2.new(0, cIcoSize, 0, cIcoSize),
			pos = UDim2.new(0.5, -cIcoSize / 2, 0, 14),
			bg = Color3.fromRGB(14, 14, 22),
			z = 106, parent = card, corner = cIcoSize / 2,
		})

		local cIcoStroke = Instance.new("UIStroke")
		cIcoStroke.Color = accent
		cIcoStroke.Thickness = 1
		cIcoStroke.Transparency = 0.5
		cIcoStroke.Parent = cIco

		local cIcoImg = Instance.new("ImageLabel")
		cIcoImg.Size = UDim2.new(1, 0, 1, 0)
		cIcoImg.BackgroundTransparency = 1
		cIcoImg.Image = "rbxassetid://" .. product.icon
		cIcoImg.ScaleType = Enum.ScaleType.Crop
		cIcoImg.ZIndex = 107
		cIcoImg.Parent = cIco
		Instance.new("UICorner", cIcoImg).CornerRadius = UDim.new(1, 0)

		-- Nombre
		local nameY = cIcoSize + 20
		local nameL = UI.label({
			name = "Name",
			text = product.name,
			size = UDim2.new(1, -10, 0, 20),
			pos = UDim2.new(0.5, 0, 0, nameY),
			color = C.text,
			font = Enum.Font.GothamBlack, textSize = 16,
			alignX = Enum.TextXAlignment.Center,
			z = 108, parent = card,
		})
		nameL.AnchorPoint = Vector2.new(0.5, 0)

		-- Comando chip
		if product.cmd and product.cmd ~= "" then
			local cmdW = math.min(#product.cmd * 6 + 16, CARD_W - 14)
			local cmdChip = UI.frame({
				name = "CmdChip",
				size = UDim2.new(0, cmdW, 0, 20),
				pos = UDim2.new(0.5, 0, 0, nameY + 20),
				bg = Color3.fromRGB(0, 0, 0),
				z = 115, parent = card, corner = 4,
			})
			cmdChip.AnchorPoint = Vector2.new(0.5, 0)
			cmdChip.BackgroundTransparency = 0.4

			UI.label({
				text = product.cmd,
				size = UDim2.new(1, 0, 1, 0),
				color = Color3.fromRGB(255, 255, 255),
				font = Enum.Font.GothamBold, textSize = 11,
				alignX = Enum.TextXAlignment.Center,
				z = 116, parent = cmdChip,
			})
		end
	end

	-- Precio badge (todas las cards)
	local priceBadge = UI.frame({
		name = "PriceBadge",
		size = UDim2.new(0, 76, 0, 26),
		pos = UDim2.new(1, -8, 0, 8),
		bg = Color3.fromRGB(0, 0, 0),
		z = 115, parent = card, corner = 10,
	})
	priceBadge.AnchorPoint = Vector2.new(1, 0)
	priceBadge.BackgroundTransparency = 0.3

	UI.label({
		text = priceStr(product.price),
		size = UDim2.new(1, 0, 1, 0),
		color = accent,
		font = Enum.Font.GothamBlack, textSize = 15,
		alignX = Enum.TextXAlignment.Center,
		z = 116, parent = priceBadge,
	})

	-- Boton COMPRAR (todas las cards)
	local buyFrame = UI.frame({
		name = "BuyFrame",
		size = UDim2.new(1, -16, 0, 34),
		pos = UDim2.new(0.5, 0, 1, -42),
		bg = accent, z = 110,
		parent = card, corner = 8,
	})
	buyFrame.AnchorPoint = Vector2.new(0.5, 0)

	local buyGrad = Instance.new("UIGradient")
	buyGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 190)),
	}
	buyGrad.Rotation = 90
	buyGrad.Parent = buyFrame

	local buyLabel = UI.label({
		text = "COMPRAR",
		size = UDim2.new(1, 0, 1, 0),
		color = C.textDark,
		font = Enum.Font.GothamBlack, textSize = 14,
		alignX = Enum.TextXAlignment.Center,
		z = 111, parent = buyFrame,
	})

	local buyClick = Instance.new("TextButton")
	buyClick.Size = UDim2.new(1, 0, 1, 0)
	buyClick.BackgroundTransparency = 1
	buyClick.Text = ""
	buyClick.ZIndex = 112
	buyClick.Parent = buyFrame

	local handleBuy = createPurchaseHandler(buyFrame, buyLabel, card, product)
	buyClick.MouseButton1Click:Connect(handleBuy)

	-- Hover (desktop)
	if not isMobile then
		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tw(card, TW_FAST, { BackgroundTransparency = THEME.lightAlpha })
				tw(cardOverlay, TW_FAST, { BackgroundTransparency = THEME.lightAlpha })
				tw(cStroke, TW_FAST, { Color = accent, Transparency = 0.2 })
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tw(card, TW_FAST, { BackgroundTransparency = THEME.frameAlpha })
				tw(cardOverlay, TW_FAST, { BackgroundTransparency = THEME.frameAlpha })
				tw(cStroke, TW_FAST, { Color = C.border, Transparency = 0.5 })
			end
		end)

		buyClick.MouseEnter:Connect(function()
			tw(buyFrame, TW_FAST, { BackgroundTransparency = 0.12 })
		end)
		buyClick.MouseLeave:Connect(function()
			tw(buyFrame, TW_FAST, { BackgroundTransparency = 0 })
		end)
	end

	gridMaxY = math.max(gridMaxY, posY + CARD_H)
end

-- Canvas size
scroll.CanvasSize = UDim2.new(0, 0, 0, gridMaxY + 20)

-- Preload
preloadOwnership(ALL_PRODUCTS)

-- ════════════════════════════════════════════════════════════════
-- OPEN / CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
	task.wait(0.1)
	preloadOwnership(ALL_PRODUCTS)
end

local function closeUI()
	if not modal:isModalOpen() then return end
	modal:close()
end

_G.OpenShopUI = openUI
_G.CloseShopUI = closeUI

return {
	open = openUI,
	close = closeUI,
}