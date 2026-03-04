--[[
	GamepassShop — Rediseño v8
	by ignxts- Nando | Refactored by George Bellota

	Cambios v8:
	  • Configuración unificada en CONFIG
	  • Funciones de renderizado encapsuladas
	  • Nueva sección TITLES en el sidebar
	  • Código modularizado sin alterar el diseño visual
]]

-- ════════════════════════════════════════════════════════════════
--  SERVICIOS
-- ════════════════════════════════════════════════════════════════
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
--  MÓDULOS
-- ════════════════════════════════════════════════════════════════
local ModalManager          = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local UI                    = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME                 = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local SidebarNav            = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SidebarNav"))
local ModernScrollbar       = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local Configuration         = require(ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("Configuration"))
local TitleConfig           = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("TitleConfig"))
local CheckGamepassOwnership = ReplicatedStorage
	:WaitForChild("RemotesGlobal")
	:WaitForChild("Gamepass Gifting")
	:WaitForChild("Remotes")
	:WaitForChild("Ownership")

-- ════════════════════════════════════════════════════════════════
--  CONFIGURACIÓN UNIFICADA
-- ════════════════════════════════════════════════════════════════
local CONFIG = {
	-- ── Paleta (sincronizada con THEME) ──
	colors = {
		bg          = THEME.bg,
		surface     = THEME.card,
		surfaceHov  = THEME.elevated,
		surfaceAlt  = THEME.card,
		border      = THEME.stroke,
		borderLight = THEME.stroke,

		text        = THEME.text,
		textSub     = THEME.muted,
		textMuted   = THEME.muted,
		textDark    = THEME.bg,

		accentPases  = THEME.accent,
		accentAuras  = Color3.fromRGB(140, 80, 255),
		accentItems  = Color3.fromRGB(255, 195, 40),
		accentTitles = Color3.fromRGB(60, 180, 220),

		softPases   = Color3.fromRGB(40, 25, 12),
		softAuras   = Color3.fromRGB(28, 16, 50),
		softItems   = Color3.fromRGB(42, 35, 12),

		owned       = Color3.fromRGB(40, 200, 100),
		ownedBg     = Color3.fromRGB(12, 35, 22),
		danger      = Color3.fromRGB(200, 50, 50),

		sidebarBg   = THEME.card,
	},

	-- ── Transparencias ──
	alpha = {
		frame  = THEME.frameAlpha,
		light  = THEME.lightAlpha,
		stroke = 0.5,
	},

	-- ── Layout ──
	layout = {
		panelWidth  = THEME.panelWidth,
		panelHeight = THEME.panelHeight,
		cornerRadius = 14,
		headerHeight = 52,
		cardGap      = 10,
		cardColumns  = 3,
		cardMinWidth = 95,
		cardHeight   = 220,          -- desktop
		cardHeightMobile = 210,
		scrollPadding = { left = 12, right = 12, top = 10, bottom = 24 },
		sidebarWidth        = 130,
		sidebarWidthMobile  = 100,
	},

	-- ── Tweens ──
	tweens = {
		fast  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		norm  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		fade  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},

	-- ── Iconos / Símbolos ──
	robuxIcon = utf8.char(0xE002),
}

local C  = CONFIG.colors
local TW = CONFIG.tweens
local LY = CONFIG.layout

-- ════════════════════════════════════════════════════════════════
--  UTILIDADES
-- ════════════════════════════════════════════════════════════════
local function tw(obj, info, props)
	if not obj then return nil end
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function priceStr(amount)
	return CONFIG.robuxIcon .. " " .. tostring(amount)
end

-- ════════════════════════════════════════════════════════════════
--  OWNERSHIP CACHE
-- ════════════════════════════════════════════════════════════════
local gpCache     = {}
local purchaseCbs = {}

local function preloadOwnership(products)
	if not products then return end
	local pending = {}
	for _, p in ipairs(products) do
		if p.gamepassId and type(p.gamepassId) == "number" and gpCache[p.gamepassId] == nil then
			table.insert(pending, p.gamepassId)
		end
	end
	for _, gid in ipairs(pending) do
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
--  PRODUCTOS
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
	{ name = "VIP",        price = 200,  gamepassId = Configuration.VIP,        icon = "76721656269888",  fondo = "76721656269888",  cmd = "",            accent = C.accentPases },
	{ name = "COMANDOS",   price = 1500, gamepassId = Configuration.COMMANDS,   icon = "128637341143304", fondo = "122601403333222", cmd = "",            accent = C.accentPases },
	{ name = "COLORES",    price = 50,   gamepassId = Configuration.COLORS,     icon = "91877799240345",  fondo = "91877799240345",  cmd = ";cl [color]", accent = C.accentPases },
	{ name = "POLICIA",    price = 135,  gamepassId = Configuration.TOMBO,      icon = "139661313218787", fondo = "139661313218787", cmd = ";tombo",      accent = C.accentPases },
	{ name = "LADRON",     price = 135,  gamepassId = Configuration.CHORO,      icon = "84699864716808",  fondo = "84699864716808",  cmd = ";choro",      accent = C.accentPases },
	{ name = "SEGURIDAD",  price = 135,  gamepassId = Configuration.SERE,       icon = "85734290151599",  fondo = "85734290151599",  cmd = ";sere",       accent = C.accentPases },
	{ name = "ARMY BOOMS", price = 80,   gamepassId = Configuration.ARMYBOOMS,  icon = "134501492548324", fondo = "134501492548324", cmd = "",            accent = C.accentPases },
	{ name = "LIGHTSTICK", price = 80,   gamepassId = Configuration.LIGHTSTICK, icon = "86122436659328",  fondo = "86122436659328",  cmd = "",            accent = C.accentPases },
	{
		name       = "AURA PACK",
		price      = 2500,
		gamepassId = Configuration.AURA_PACK,
		icon       = "129517460766852",
		fondo      = "79346090571461",
		cmd        = "",
		accent     = C.accentAuras,
		isAuraPack = true,
	},
}

-- Items para la sección TITLES — construidos desde TitleConfig (fuente única)
-- Solo edita ReplicatedStorage/Config/TitleConfig para cambiar títulos
local TITLE_PRODUCTS = (function()
	local items = {}
	for _, t in ipairs(TitleConfig) do
		table.insert(items, {
			id         = t.id,
			name       = t.name,
			price      = t.price,
			gamepassId = t.gamepassId,
			icon       = t.icon,
			fondo      = t.fondo,
			cmd        = "",
			accent     = C.accentTitles,
			isTitle    = true,
		})
	end
	return items
end)()

-- ════════════════════════════════════════════════════════════════
--  SIDEBAR TABS
-- ════════════════════════════════════════════════════════════════
local SIDEBAR_ITEMS = {
	{ id = "Gamepasses", label = "GAMEPASSES", image = "94571429612275" },
	{ id = "Titles",     label = "TITLES",     image = "103185544418844" },
}

local TAB_TITLES = {
	Gamepasses = "GAMEPASSES",
	Titles     = "TITLES",
}

-- ════════════════════════════════════════════════════════════════
--  SCREEN GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "GamepassShopUI"
screenGui.ResetOnSpawn      = false
screenGui.IgnoreGuiInset    = true
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Parent            = playerGui

task.wait(0.5)
local isMobile  = UserInputService.TouchEnabled
local SIDEBAR_W = isMobile and LY.sidebarWidthMobile or LY.sidebarWidth
local CARD_H    = isMobile and LY.cardHeightMobile or LY.cardHeight

-- ════════════════════════════════════════════════════════════════
--  MODAL
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui   = screenGui,
	panelName   = "GamepassShop",
	panelWidth  = LY.panelWidth,
	panelHeight = LY.panelHeight,
	cornerRadius = LY.cornerRadius,
	enableBlur  = true,
	blurSize    = 20,
	isMobile    = isMobile,
})

local panel = modal:getPanel()
panel.BackgroundColor3       = THEME.bg
panel.BackgroundTransparency = THEME.mediumAlpha

local CONTAINER = modal:getCanvas()

-- ════════════════════════════════════════════════════════════════
--  BADGE "ADQUIRIDO" (encapsulado)
-- ════════════════════════════════════════════════════════════════
local function createOwnedBadge(parent)
	local h = 32
	local badge = UI.frame({
		name = "OwnedBadge",
		size = UDim2.new(1, 0, 0, h),
		pos  = UDim2.new(0, 0, 1, -h),
		bg   = C.ownedBg,
		z    = parent.ZIndex + 15,
		parent = parent, corner = 10,
	})

	local mask = Instance.new("Frame")
	mask.Name                 = "TopMask"
	mask.Size                 = UDim2.new(1, 0, 0, 10)
	mask.BackgroundColor3     = C.ownedBg
	mask.BackgroundTransparency = 0
	mask.BorderSizePixel      = 0
	mask.ZIndex               = badge.ZIndex
	mask.Parent               = badge

	UI.label({
		name   = "OwnedText",
		size   = UDim2.new(1, 0, 1, 0),
		text   = "ADQUIRIDO",
		color  = C.owned,
		font   = Enum.Font.GothamBold, textSize = 11,
		alignX = Enum.TextXAlignment.Center,
		z = badge.ZIndex + 2, parent = badge,
	})

	badge.BackgroundTransparency = 1
	mask.BackgroundTransparency  = 1
	tw(badge, TW.norm, { BackgroundTransparency = 0 })
	tw(mask,  TW.norm, { BackgroundTransparency = 0 })
	return badge
end

-- ════════════════════════════════════════════════════════════════
--  PURCHASE HANDLER (encapsulado)
-- ════════════════════════════════════════════════════════════════
local function createPurchaseHandler(btnFrame, btnLabel, parentCard, product)
	local owned = false

	local function markOwned()
		if owned then return end
		owned = true
		tw(btnFrame, TW.fade, { BackgroundTransparency = 1 })
		if btnLabel then tw(btnLabel, TW.fade, { TextTransparency = 1 }) end
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
		tw(btnFrame, TW.press, { Size = origSize + UDim2.new(0, -4, 0, -2) })
		task.delay(0.08, function() tw(btnFrame, TW.norm, { Size = origSize }) end)
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
--  EQUIP HANDLER (exclusivo para títulos)
-- ════════════════════════════════════════════════════════════════
local function createTitleEquipHandler(btnFrame, btnLabel, card, product)
	local equipRemote = ReplicatedStorage
		:WaitForChild("RemotesGlobal")
		:WaitForChild("Title")
		:WaitForChild("Titles")

	local equipMode = false

	local function refreshBtn()
		local current = player:GetAttribute("EquippedTitle") or ""
		if current == product.id then
			btnLabel.Text             = "DESEQUIPAR"
			btnFrame.BackgroundColor3 = C.danger
		else
			btnLabel.Text             = "EQUIPAR"
			btnFrame.BackgroundColor3 = product.accent or C.accentTitles
		end
	end

	local function activateEquipMode()
		if equipMode then return end
		equipMode = true
		local priceBadge = card:FindFirstChild("PriceBadge")
		if priceBadge then priceBadge.Visible = false end
		refreshBtn()
		player:GetAttributeChangedSignal("EquippedTitle"):Connect(refreshBtn)
	end

	if product.gamepassId and product.gamepassId ~= 0 then
		local gid = product.gamepassId
		if gpCache[gid] == true then
			activateEquipMode()
		elseif gpCache[gid] == nil then
			task.spawn(function()
				local deadline = tick() + 12
				while gpCache[gid] == nil and tick() < deadline do task.wait(0.15) end
				if gpCache[gid] == true then activateEquipMode() end
			end)
		end
		onPurchase(gid, activateEquipMode)
	else
		-- gamepassId = 0: siempre accesible (dev/gratis)
		activateEquipMode()
	end

	return function()
		if equipMode then
			equipRemote:FireServer(product.id)
		else
			local origSize = btnFrame.Size
			tw(btnFrame, TW.press, { Size = origSize + UDim2.new(0, -4, 0, -2) })
			task.delay(0.08, function() tw(btnFrame, TW.norm, { Size = origSize }) end)
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
--  HOVER BINDINGS (encapsulado)
-- ════════════════════════════════════════════════════════════════
local function bindCardHover(card, cardOverlay, cStroke, buyFrame, buyClick)
	if isMobile then return end

	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tw(card,        TW.fast, { BackgroundTransparency = THEME.subtleAlpha })
			tw(cardOverlay, TW.fast, { BackgroundTransparency = THEME.lightAlpha })
			tw(cStroke,     TW.fast, { Color = THEME.accent, Transparency = THEME.lightAlpha })
		end
	end)
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tw(card,        TW.fast, { BackgroundTransparency = 0 })
			tw(cardOverlay, TW.fast, { BackgroundTransparency = THEME.frameAlpha })
			tw(cStroke,     TW.fast, { Color = THEME.stroke, Transparency = THEME.mediumAlpha })
		end
	end)

	buyClick.MouseEnter:Connect(function()
		tw(buyFrame, TW.fast, { BackgroundTransparency = THEME.subtleAlpha })
	end)
	buyClick.MouseLeave:Connect(function()
		tw(buyFrame, TW.fast, { BackgroundTransparency = 0 })
	end)
end

-- ════════════════════════════════════════════════════════════════
--  CARD BUILDERS
-- ════════════════════════════════════════════════════════════════

--- Crea los elementos base compartidos por toda card (fondo, overlay, stroke, precio, botón comprar)
local function createCardBase(product, cardW, cardH, posX, posY, parentScroll, handlerFn)
	local accent = product.accent or C.accentPases

	local card = UI.frame({
		name   = product.name,
		size   = UDim2.new(0, cardW, 0, cardH),
		pos    = UDim2.new(0, posX, 0, posY),
		bg     = THEME.card, bgT = 0,
		z      = 103, parent = parentScroll, corner = 12,
	})
	card.ClipsDescendants = true

	local cStroke = Instance.new("UIStroke")
	cStroke.Color        = THEME.stroke
	cStroke.Thickness    = 1
	cStroke.Transparency = THEME.mediumAlpha
	cStroke.Parent       = card

	-- Fondo imagen
	local bgImg = Instance.new("ImageLabel")
	bgImg.Name                 = "BgImg"
	bgImg.Size                 = UDim2.new(1, 0, 1, 0)
	bgImg.BackgroundTransparency = 1
	bgImg.Image                = "rbxassetid://" .. (product.fondo or product.icon)
	bgImg.ScaleType            = Enum.ScaleType.Crop
	bgImg.ImageTransparency    = THEME.lightAlpha
	bgImg.ZIndex               = 103
	bgImg.Parent               = card
	Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0, 12)

	-- Overlay
	local cardOverlay = UI.frame({
		name = "CardOverlay",
		size = UDim2.new(1, 0, 1, 0),
		bg   = THEME.card, bgT = THEME.mediumAlpha, z = 104,
		parent = card, corner = 12,
	})

	-- Tag badge (opcional)
	if product.tag and product.tag ~= "" then
		local tagW     = #product.tag * 6.5 + 18
		local tagBadge = UI.frame({
			name = "Tag",
			size = UDim2.new(0, tagW, 0, 18),
			pos  = UDim2.new(0, 8, 0, 8),
			bg   = accent, z = 115,
			parent = card, corner = 4,
		})
		UI.label({
			text   = product.tag,
			size   = UDim2.new(1, 0, 1, 0),
			color  = THEME.bg,
			font   = Enum.Font.GothamBlack, textSize = 8,
			alignX = Enum.TextXAlignment.Center,
			z = 116, parent = tagBadge,
		})
	end

	-- Precio badge
	local priceBadge = UI.frame({
		name = "PriceBadge",
		size = UDim2.new(0, 76, 0, 26),
		pos  = UDim2.new(1, -8, 0, 8),
		bg   = THEME.elevated, z = 115,
		parent = card, corner = 10,
	})
	priceBadge.AnchorPoint            = Vector2.new(1, 0)
	priceBadge.BackgroundTransparency = CONFIG.alpha.frame

	UI.label({
		text   = priceStr(product.price),
		size   = UDim2.new(1, 0, 1, 0),
		color  = THEME.accent,
		font   = Enum.Font.GothamBlack, textSize = 15,
		alignX = Enum.TextXAlignment.Center,
		z = 116, parent = priceBadge,
	})

	-- Botón COMPRAR
	local buyFrame = UI.frame({
		name = "BuyFrame",
		size = UDim2.new(1, -16, 0, 34),
		pos  = UDim2.new(0.5, 0, 1, -42),
		bg   = accent, z = 110,
		parent = card, corner = 8,
	})
	buyFrame.AnchorPoint = Vector2.new(0.5, 0)

	local buyLabel = UI.label({
		text   = "COMPRAR",
		size   = UDim2.new(1, 0, 1, 0),
		color  = THEME.bg,
		font   = Enum.Font.GothamBlack, textSize = 14,
		alignX = Enum.TextXAlignment.Center,
		z = 111, parent = buyFrame,
	})

	local buyClick = Instance.new("TextButton")
	buyClick.Size                 = UDim2.new(1, 0, 1, 0)
	buyClick.BackgroundTransparency = 1
	buyClick.Text                 = ""
	buyClick.ZIndex               = 112
	buyClick.Parent               = buyFrame

	-- Conectar compra y hover
	local handleBuy = handlerFn
		and handlerFn(buyFrame, buyLabel, card, product)
		or  createPurchaseHandler(buyFrame, buyLabel, card, product)
	buyClick.MouseButton1Click:Connect(handleBuy)
	bindCardHover(card, cardOverlay, cStroke, buyFrame, buyClick)

	return card, accent
end

--- Renderiza el contenido interior de una card NORMAL (icono + nombre + comando)
local function renderNormalCardContent(card, product, cardW, accent)
	local cIcoSize = 58
	local cIco = UI.frame({
		name = "Icon",
		size = UDim2.new(0, cIcoSize, 0, cIcoSize),
		pos  = UDim2.new(0.5, -cIcoSize / 2, 0, 14),
		bg   = THEME.bg, bgT = 0,
		z    = 106, parent = card, corner = cIcoSize / 2,
	})

	local cIcoStroke = Instance.new("UIStroke")
	cIcoStroke.Color        = accent
	cIcoStroke.Thickness    = 1
	cIcoStroke.Transparency = THEME.mediumAlpha
	cIcoStroke.Parent       = cIco

	local cIcoImg = Instance.new("ImageLabel")
	cIcoImg.Size                 = UDim2.new(1, 0, 1, 0)
	cIcoImg.BackgroundTransparency = 1
	cIcoImg.Image                = "rbxassetid://" .. product.icon
	cIcoImg.ScaleType            = Enum.ScaleType.Crop
	cIcoImg.ZIndex               = 107
	cIcoImg.Parent               = cIco
	Instance.new("UICorner", cIcoImg).CornerRadius = UDim.new(1, 0)

	-- Nombre
	local nameY = cIcoSize + 20
	local nameL = UI.label({
		name   = "Name",
		text   = product.name,
		size   = UDim2.new(1, -10, 0, 20),
		pos    = UDim2.new(0.5, 0, 0, nameY),
		color  = THEME.text,
		font   = Enum.Font.GothamBlack, textSize = 16,
		alignX = Enum.TextXAlignment.Center,
		z = 108, parent = card,
	})
	nameL.AnchorPoint = Vector2.new(0.5, 0)

	-- Comando chip
	if product.cmd and product.cmd ~= "" then
		local cmdW    = math.min(#product.cmd * 6 + 16, cardW - 14)
		local cmdChip = UI.frame({
			name = "CmdChip",
			size = UDim2.new(0, cmdW, 0, 20),
			pos  = UDim2.new(0.5, 0, 0, nameY + 20),
			bg   = THEME.elevated, z = 115,
			parent = card, corner = 4,
		})
		cmdChip.AnchorPoint            = Vector2.new(0.5, 0)
		cmdChip.BackgroundTransparency = THEME.lightAlpha

		UI.label({
			text   = product.cmd,
			size   = UDim2.new(1, 0, 1, 0),
			color  = THEME.text,
			font   = Enum.Font.GothamBold, textSize = 11,
			alignX = Enum.TextXAlignment.Center,
			z = 116, parent = cmdChip,
		})
	end
end

--- Renderiza el contenido interior de la card AURA PACK (icono pequeño + miniaturas)
local function renderAuraPackContent(card, product, cardW, accent)
	local aIcoSize = 44
	local aIco = UI.frame({
		name = "Icon",
		size = UDim2.new(0, aIcoSize, 0, aIcoSize),
		pos  = UDim2.new(0.5, -aIcoSize / 2, 0, 12),
		bg   = THEME.bg, bgT = 0,
		z    = 106, parent = card, corner = aIcoSize / 2,
	})

	local aIcoStroke = Instance.new("UIStroke")
	aIcoStroke.Color        = accent
	aIcoStroke.Thickness    = 1
	aIcoStroke.Transparency = THEME.mediumAlpha
	aIcoStroke.Parent       = aIco

	local aIcoImg = Instance.new("ImageLabel")
	aIcoImg.Size                 = UDim2.new(1, 0, 1, 0)
	aIcoImg.BackgroundTransparency = 1
	aIcoImg.Image                = "rbxassetid://" .. product.icon
	aIcoImg.ScaleType            = Enum.ScaleType.Crop
	aIcoImg.ZIndex               = 107
	aIcoImg.Parent               = aIco
	Instance.new("UICorner", aIcoImg).CornerRadius = UDim.new(1, 0)

	-- Nombre
	local aNameL = UI.label({
		name   = "Name",
		text   = product.name,
		size   = UDim2.new(1, -10, 0, 18),
		pos    = UDim2.new(0.5, 0, 0, 60),
		color  = THEME.text,
		font   = Enum.Font.GothamBlack, textSize = 15,
		alignX = Enum.TextXAlignment.Center,
		z = 108, parent = card,
	})
	aNameL.AnchorPoint = Vector2.new(0.5, 0)

	-- "Incluye X auras:"
	UI.label({
		name   = "IncludesLabel",
		text   = "Incluye " .. tostring(#AURA_THUMBNAILS) .. " auras:",
		size   = UDim2.new(1, -8, 0, 12),
		pos    = UDim2.new(0, 4, 0, 78),
		color  = THEME.muted,
		font   = Enum.Font.GothamMedium, textSize = 9,
		alignX = Enum.TextXAlignment.Center,
		z = 108, parent = card,
	})

	-- Miniaturas 2×3
	local thumbSize = 32
	local thumbGap  = 5
	local thumbCols = 3
	local totalThumbRowW = (thumbCols * (thumbSize + thumbGap)) - thumbGap
	local thumbStartX    = (cardW - totalThumbRowW) / 2
	local thumbStartY    = 94

	for ti, aura in ipairs(AURA_THUMBNAILS) do
		local tc = (ti - 1) % thumbCols
		local tr = math.floor((ti - 1) / thumbCols)
		local tx = thumbStartX + tc * (thumbSize + thumbGap)
		local ty = thumbStartY + tr * (thumbSize + thumbGap)

		local thumbFrame = UI.frame({
			name = "Thumb_" .. aura.name,
			size = UDim2.new(0, thumbSize, 0, thumbSize),
			pos  = UDim2.new(0, tx, 0, ty),
			bg   = THEME.bg, bgT = 0,
			z    = 109, parent = card, corner = thumbSize / 2,
		})

		local thumbStroke = Instance.new("UIStroke")
		thumbStroke.Color        = C.accentAuras
		thumbStroke.Thickness    = 1.5
		thumbStroke.Transparency = THEME.lightAlpha
		thumbStroke.Parent       = thumbFrame

		local thumbImg = Instance.new("ImageLabel")
		thumbImg.Size                 = UDim2.new(1, 0, 1, 0)
		thumbImg.BackgroundTransparency = 1
		thumbImg.Image                = "rbxassetid://" .. aura.icon
		thumbImg.ScaleType            = Enum.ScaleType.Crop
		thumbImg.ZIndex               = 110
		thumbImg.Parent               = thumbFrame
		Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)
	end
end

-- ════════════════════════════════════════════════════════════════
--  GRID RENDERER (genérico para cualquier lista de productos)
-- ════════════════════════════════════════════════════════════════

--- Calcula columnas y ancho de card según el espacio disponible
local function computeGrid()
	local contentW = LY.panelWidth - SIDEBAR_W - 24
	local cols     = LY.cardColumns
	local gap      = LY.cardGap
	local cardW    = math.floor((contentW - (gap * (cols - 1))) / cols)

	if cardW < LY.cardMinWidth then
		cols  = 2
		cardW = math.floor((contentW - gap) / cols)
	end

	return cols, cardW, gap
end

--- Crea un ScrollingFrame estándar dentro de un parent
local function createScrollFrame(parent)
	local scrollContainer = UI.frame({
		name = "ScrollContainer",
		size = UDim2.new(1, 0, 1, 0),
		bgT  = 1, z = 100,
		parent = parent, clips = false,
	})

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                   = "Scroll"
	scroll.Size                   = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 0
	scroll.ScrollBarImageTransparency = 1
	scroll.ScrollingDirection     = Enum.ScrollingDirection.Y
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 100
	scroll.Parent                 = scrollContainer
	-- parentFrame = scrollContainer (sin clips), offset negativo = scrollbar queda DENTRO de los bounds
	ModernScrollbar.setup(scroll, scrollContainer, THEME, {transparency = 0, offset = -6})

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, LY.scrollPadding.left)
	pad.PaddingRight  = UDim.new(0, LY.scrollPadding.right)
	pad.PaddingTop    = UDim.new(0, LY.scrollPadding.top)
	pad.PaddingBottom = UDim.new(0, LY.scrollPadding.bottom)
	pad.Parent        = scroll

	return scroll
end

--- Renderiza la grilla de gamepasses en el scroll dado
local function renderGamepassGrid(scroll, products)
	local cols, cardW, gap = computeGrid()
	local gridMaxY = 0

	for i, product in ipairs(products) do
		local col  = (i - 1) % cols
		local row  = math.floor((i - 1) / cols)
		local posX = col * (cardW + gap)
		local posY = row * (CARD_H + gap)

		local card, accent = createCardBase(
			product, cardW, CARD_H, posX, posY, scroll,
			product.isTitle and createTitleEquipHandler or nil
		)

		if product.isAuraPack then
			renderAuraPackContent(card, product, cardW, accent)
		else
			renderNormalCardContent(card, product, cardW, accent)
		end

		gridMaxY = math.max(gridMaxY, posY + CARD_H)
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, gridMaxY + 20)
end

-- ════════════════════════════════════════════════════════════════
--  SIDEBAR
-- ════════════════════════════════════════════════════════════════
local switchTab
local contentTitle

local totalItems = #ALL_PRODUCTS + #TITLE_PRODUCTS

local shopSidebar = SidebarNav.new({
	parent     = CONTAINER,
	UI         = UI,
	THEME      = THEME,
	title      = "SHOP",
	items      = SIDEBAR_ITEMS,
	width      = SIDEBAR_W,
	isMobile   = isMobile,
	footerText = tostring(totalItems) .. " ITEMS",
	onSelect   = function(id) switchTab(id) end,
})
shopSidebar:selectItem("Gamepasses")

-- ════════════════════════════════════════════════════════════════
--  CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name = "ContentArea",
	size = UDim2.new(1, -SIDEBAR_W, 1, 0),
	pos  = UDim2.new(0, SIDEBAR_W, 0, 0),
	bgT  = 1, z = 100,
	parent = CONTAINER, clips = true,
})

-- Header
local contentHeader = UI.frame({
	name = "ContentHeader",
	size = UDim2.new(1, 0, 0, LY.headerHeight),
	bg   = THEME.deep, bgT = THEME.lightAlpha, z = 150,
	parent = contentArea,
})

contentTitle = UI.label({
	name   = "Title",
	size   = UDim2.new(1, -60, 0, LY.headerHeight),
	pos    = UDim2.new(0, 18, 0, 0),
	text   = "GAMEPASSES",
	color  = THEME.text,
	font   = Enum.Font.GothamBlack, textSize = 20,
	alignX = Enum.TextXAlignment.Left,
	z = 152, parent = contentHeader,
})

local headerLine = Instance.new("Frame")
headerLine.Size                 = UDim2.new(1, -20, 0, 1)
headerLine.Position             = UDim2.new(0, 10, 1, -1)
headerLine.BackgroundColor3     = THEME.stroke
headerLine.BackgroundTransparency = THEME.mediumAlpha
headerLine.BorderSizePixel      = 0
headerLine.ZIndex               = 152
headerLine.Parent               = contentHeader

-- ════════════════════════════════════════════════════════════════
--  PAGES CONTAINER
-- ════════════════════════════════════════════════════════════════
local pagesContainer = UI.frame({
	name   = "PagesContainer",
	size   = UDim2.new(1, 0, 1, -LY.headerHeight),
	pos    = UDim2.new(0, 0, 0, LY.headerHeight),
	bgT    = 1, z = 101,
	parent = contentArea, clips = true,
})

local pageLayout = Instance.new("UIPageLayout")
pageLayout.FillDirection           = Enum.FillDirection.Vertical
pageLayout.SortOrder               = Enum.SortOrder.LayoutOrder
pageLayout.HorizontalAlignment    = Enum.HorizontalAlignment.Center
pageLayout.EasingStyle             = Enum.EasingStyle.Sine
pageLayout.EasingDirection         = Enum.EasingDirection.InOut
pageLayout.TweenTime               = 0.35
pageLayout.ScrollWheelInputEnabled = false
pageLayout.TouchInputEnabled       = false
pageLayout.Parent                  = pagesContainer

-- ════════════════════════════════════════════════════════════════
--  PAGE: GAMEPASSES
-- ════════════════════════════════════════════════════════════════
local pageGamepasses = UI.frame({
	name = "Gamepasses",
	size = UDim2.fromScale(1, 1),
	bgT  = 1, z = 102,
	parent = pagesContainer,
})
pageGamepasses.LayoutOrder = 1

local gpScroll = createScrollFrame(pageGamepasses)
renderGamepassGrid(gpScroll, ALL_PRODUCTS)

-- ════════════════════════════════════════════════════════════════
--  PAGE: TITLES
-- ════════════════════════════════════════════════════════════════
local pageTitles = UI.frame({
	name = "Titles",
	size = UDim2.fromScale(1, 1),
	bgT  = 1, z = 102,
	parent = pagesContainer,
})
pageTitles.LayoutOrder = 2

local titlesScroll = createScrollFrame(pageTitles)
renderGamepassGrid(titlesScroll, TITLE_PRODUCTS)

-- ════════════════════════════════════════════════════════════════
--  PRELOAD
-- ════════════════════════════════════════════════════════════════
preloadOwnership(ALL_PRODUCTS)
preloadOwnership(TITLE_PRODUCTS)

-- ════════════════════════════════════════════════════════════════
--  TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
switchTab = function(tabName)
	shopSidebar:selectItem(tabName)
	if contentTitle then contentTitle.Text = TAB_TITLES[tabName] or tabName end
	local pageFrame = pagesContainer:FindFirstChild(tabName)
	if pageFrame then pageLayout:JumpTo(pageFrame) end
end

-- ════════════════════════════════════════════════════════════════
--  OPEN / CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
	task.wait(0.1)
	preloadOwnership(ALL_PRODUCTS)
	preloadOwnership(TITLE_PRODUCTS)
end

local function closeUI()
	if not modal:isModalOpen() then return end
	modal:close()
end

_G.OpenShopUI  = openUI
_G.CloseShopUI = closeUI

return {
	open  = openUI,
	close = closeUI,
}