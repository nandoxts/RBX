--[[
GamepassShop v4 — Rediseno Profesional
by George Bellota
───────────────────────────────────────────────────────
CAMBIOS PRINCIPALES vs v3:
  [1] Grid de 2 columnas en lugar de scroll horizontal
  [2] Tabs con underline deslizante (no pills)
  [3] Hero card simplificado sin chips
  [4] Paleta refinada con mejor contraste
  [5] CERO emojis: R$ para Robux, PTS para puntos
  [6] Animaciones precisas sin bounce
  [7] Tipografia con jerarquia clara
  [8] Badge owned limpio sin mascaras
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
local NavTabs = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("NavTabs"))

-- ════════════════════════════════════════════════════════════════
-- PALETA v4 — Refinada
-- ════════════════════════════════════════════════════════════════
local C = setmetatable({
	-- Base
	bg          = Color3.fromRGB(10, 10, 16),
	surface     = Color3.fromRGB(18, 18, 28),
	surfaceHov  = Color3.fromRGB(26, 26, 38),
	surfaceAlt  = Color3.fromRGB(14, 14, 22),
	border      = Color3.fromRGB(40, 40, 56),
	borderLight = Color3.fromRGB(55, 55, 72),

	-- Texto
	text        = Color3.fromRGB(240, 240, 245),
	textSub     = Color3.fromRGB(130, 130, 155),
	textMuted   = Color3.fromRGB(80, 80, 100),
	textDark    = Color3.fromRGB(12, 12, 18),

	-- Categorias
	accentPases  = Color3.fromRGB(255, 150, 50),
	accentAuras  = Color3.fromRGB(140, 80, 255),
	accentItems  = Color3.fromRGB(255, 195, 40),

	-- Categorias soft (fondos)
	softPases    = Color3.fromRGB(40, 25, 12),
	softAuras    = Color3.fromRGB(28, 16, 50),
	softItems    = Color3.fromRGB(42, 35, 12),

	-- Estados
	owned        = Color3.fromRGB(40, 200, 100),
	ownedBg      = Color3.fromRGB(12, 35, 22),
	danger       = Color3.fromRGB(200, 50, 50),
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

local function ownsPass(id)
	if not id or type(id) ~= "number" then return false end
	return gpCache[id] or false
end

local function preloadOwnership(category)
	if not category or not category.products then return end
	local ids = {}

	for _, p in ipairs(category.products) do
		if p.gamepassId and type(p.gamepassId) == "number" and gpCache[p.gamepassId] == nil then
			table.insert(ids, p.gamepassId)
		end
	end
	if category.featured and category.featured.gamepassId and gpCache[category.featured.gamepassId] == nil then
		table.insert(ids, category.featured.gamepassId)
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
local GAMEPASSES_FEATURED = {
	name = "COMANDOS",
	price = 1500,
	gamepassId = Configuration.COMMANDS,
	icon = "128637341143304",
	tag = "MAS POPULAR",
	fondo = "79346090571461",
	description = "Acceso a todos los comandos premium del servidor",
	commands = {
		";fire [color]", ";hl [color]", ";trail [color]", ";smk [color]", ";rmv",
		";particula [id]", ";size", ";prtcl [color]"
	}
}

local GAMEPASSES = {
	{name = "VIP",        price = 200,  gamepassId = Configuration.VIP,        icon = "76721656269888",  cmd = ""},
	{name = "COLORES",    price = 50,   gamepassId = Configuration.COLORS,     icon = "91877799240345",  cmd = ";cl [color]"},
	{name = "POLICIA",    price = 135,  gamepassId = Configuration.TOMBO,      icon = "139661313218787", cmd = ";tombo"},
	{name = "LADRON",     price = 135,  gamepassId = Configuration.CHORO,      icon = "84699864716808",  cmd = ";choro"},
	{name = "SEGURIDAD",  price = 135,  gamepassId = Configuration.SERE,       icon = "85734290151599",  cmd = ";sere"},
	{name = "ARMY BOOMS", price = 80,   gamepassId = Configuration.ARMYBOOMS,  icon = "134501492548324", cmd = ""},
	{name = "LIGHTSTICK", price = 80,   gamepassId = Configuration.LIGHTSTICK, icon = "86122436659328",  cmd = ""},
}

local AURAS_FEATURED = {
	name = "AURA DEMONIO",
	price = 1200,
	gamepassId = 999999001,
	icon = "128637341143304",
	tag = "EPICA",
	fondo = "79346090571461",
	description = "Aura roja oscura con efectos demoniacos",
	commands = {
		"Efectos de fuego", "Trail rojo", "Particulas oscuras", "Sonidos especiales"
	}
}

local AURAS = {
	{name = "AURA FUEGO",     price = 600,  gamepassId = 999999002, icon = "128637341143304", cmd = ""},
	{name = "AURA HIELO",     price = 600,  gamepassId = 999999003, icon = "128637341143304", cmd = ""},
	{name = "AURA RAYO",      price = 600,  gamepassId = 999999004, icon = "128637341143304", cmd = ""},
	{name = "AURA FANTASMA",  price = 800,  gamepassId = 999999005, icon = "128637341143304", cmd = ""},
	{name = "AURA CELESTIAL", price = 1000, gamepassId = 999999006, icon = "128637341143304", cmd = ""},
	{name = "AURA SOMBRA",    price = 700,  gamepassId = 999999007, icon = "128637341143304", cmd = ""},
}

local ITEMS_FEATURED = {
	name = "CASCO LEGENDARIO",
	price = 5000,
	pointsId = "helmet_legendary",
	icon = "128637341143304",
	tag = "EXCLUSIVO",
	fondo = "79346090571461",
	description = "Casco de aspecto legendario con aura especial",
	commands = {
		"+500 HP", "Defensa mejorada", "Efecto visual epico", "Sonido especial"
	}
}

local ITEMS = {
	{name = "GAFAS DE SOL",     price = 2000, pointsId = "glasses_001",   icon = "128637341143304", cmd = ""},
	{name = "BUFANDA PREMIUM",  price = 2500, pointsId = "scarf_001",     icon = "128637341143304", cmd = ""},
	{name = "ABRIGO OSCURO",    price = 3500, pointsId = "coat_001",      icon = "128637341143304", cmd = ""},
	{name = "BOTAS DE COMBATE", price = 2800, pointsId = "boots_001",     icon = "128637341143304", cmd = ""},
	{name = "BRAZALETES ORO",   price = 3200, pointsId = "bracelets_001", icon = "128637341143304", cmd = ""},
	{name = "CORONA REAL",      price = 4500, pointsId = "crown_001",     icon = "128637341143304", cmd = ""},
}

local SHOP_CATEGORIES = {
	{
		id = "gamepasses",
		label = "Pases",
		color = C.accentPases,
		colorSoft = C.softPases,
		featured = GAMEPASSES_FEATURED,
		products = GAMEPASSES,
		currency = "robux",
	},
	{
		id = "auras",
		label = "Auras",
		color = C.accentAuras,
		colorSoft = C.softAuras,
		featured = AURAS_FEATURED,
		products = AURAS,
		currency = "robux",
	},
	{
		id = "items",
		label = "Items",
		color = C.accentItems,
		colorSoft = C.softItems,
		featured = ITEMS_FEATURED,
		products = ITEMS,
		currency = "points",
	},
}

local currentCatId = "gamepasses"

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
	cornerRadius = 14,
	enableBlur = true,
	blurSize = 20,
	isMobile = isMobile,
})

local panel = modal:getPanel()
panel.BackgroundColor3 = C.bg
panel.ClipsDescendants = true

-- Forward declarations
local selectCategory

-- ════════════════════════════════════════════════════════════════
-- HEADER (titulo + close + tabs) — SPOTIFY STYLE
-- ════════════════════════════════════════════════════════════════
local HEADER_H = 120

local header = UI.frame({
	name = "Header",
	size = UDim2.new(1, 0, 0, HEADER_H),
	bg = Color3.fromRGB(18, 18, 22),
	z = 200,
	parent = panel,
	clips = true,
	corner = 16,
})

-- Cover de fondo oscuro
local headerCoverImage = Instance.new("ImageLabel")
headerCoverImage.Name = "CoverBackground"
headerCoverImage.Size = UDim2.new(1, 0, 1, 0)
headerCoverImage.Position = UDim2.new(0, 0, 0, 0)
headerCoverImage.BackgroundTransparency = 1
headerCoverImage.Image = "rbxassetid://79346090571461"
headerCoverImage.ImageTransparency = 0.6
headerCoverImage.ScaleType = Enum.ScaleType.Crop
headerCoverImage.ZIndex = 200
headerCoverImage.Parent = header
Instance.new("UICorner", headerCoverImage).CornerRadius = UDim.new(0, 16)

-- Gradient overlay sobre el cover
local headerGradientOverlay = Instance.new("Frame")
headerGradientOverlay.Name = "GradientOverlay"
headerGradientOverlay.Size = UDim2.new(1, 0, 1, 0)
headerGradientOverlay.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
headerGradientOverlay.BackgroundTransparency = 0.2
headerGradientOverlay.BorderSizePixel = 0
headerGradientOverlay.ZIndex = 201
headerGradientOverlay.Parent = header
Instance.new("UICorner", headerGradientOverlay).CornerRadius = UDim.new(0, 16)

local overlayGradient = Instance.new("UIGradient")
overlayGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(18, 18, 22)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 38))
}
overlayGradient.Rotation = 90
overlayGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0.3),
	NumberSequenceKeypoint.new(1, 0.6)
}
overlayGradient.Parent = headerGradientOverlay

-- Container para el contenido del header
local headerContent = Instance.new("Frame")
headerContent.Name = "Content"
headerContent.Size = UDim2.new(1, -32, 1, -24)
headerContent.Position = UDim2.new(0, 16, 0, 12)
headerContent.BackgroundTransparency = 1
headerContent.ZIndex = 202
headerContent.Parent = header

-- Row superior: Titulo + Cerrar
local titleRow = Instance.new("Frame")
titleRow.Name = "TitleRow"
titleRow.Size = UDim2.new(1, 0, 0, 32)
titleRow.BackgroundTransparency = 1
titleRow.ZIndex = 203
titleRow.Parent = headerContent

-- Titulo
UI.label({
	name = "Title",
	size = UDim2.new(0, 200, 1, 0),
	pos = UDim2.new(0, 0, 0, 0),
	text = "TIENDA PREMIUM",
	color = C.text,
	font = Enum.Font.GothamBlack,
	textSize = 18,
	alignX = Enum.TextXAlignment.Left,
	z = 204, parent = titleRow,
})



-- Boton cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -40, 0, -2)
closeBtn.BackgroundColor3 = C.surface
closeBtn.BackgroundTransparency = 1
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = C.textMuted
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 205
closeBtn.Parent = titleRow

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	tw(closeBtn, TW_FAST, { BackgroundTransparency = 0, BackgroundColor3 = C.danger, TextColor3 = C.text })
end)
closeBtn.MouseLeave:Connect(function()
	tw(closeBtn, TW_FAST, { BackgroundTransparency = 1, TextColor3 = C.textMuted })
end)

-- Tabs
local tabRow = Instance.new("Frame")
tabRow.Name = "TabRow"
tabRow.Size = UDim2.new(1, 0, 0, 38)
tabRow.Position = UDim2.new(0, 0, 0, 40)
tabRow.BackgroundTransparency = 1
tabRow.ZIndex = 203
tabRow.Parent = headerContent

NavTabs.new({
	parent = tabRow,
	categories = SHOP_CATEGORIES,
	colors = C,
	UI = UI,
	TweenService = TweenService,
	isMobile = isMobile,
	onSelect = function(catId)
		if selectCategory then selectCategory(catId) end
	end,
})

-- ════════════════════════════════════════════════════════════════
-- HELPERS: Currency formatter (sin emojis)
-- ════════════════════════════════════════════════════════════════
local function priceStr(amount, currency)
	if currency == "robux" then
		return "R$ " .. tostring(amount)
	else
		return tostring(amount) .. " PTS"
	end
end



-- ════════════════════════════════════════════════════════════════
-- HELPER: Badge ADQUIRIDO
-- ════════════════════════════════════════════════════════════════
local function createOwnedBadge(parent, isHero)
	local h = isHero and 38 or 30
	local cornerR = isHero and 14 or 12

	local badge = UI.frame({
		name = "OwnedBadge",
		size = UDim2.new(1, 0, 0, h),
		pos = UDim2.new(0, 0, 1, -h),
		bg = C.ownedBg,
		z = parent.ZIndex + 15,
		parent = parent,
		corner = cornerR,
	})

	-- Mascara rectangular que tapa las esquinas superiores redondeadas
	local mask = Instance.new("Frame")
	mask.Name = "TopMask"
	mask.Size = UDim2.new(1, 0, 0, cornerR)
	mask.Position = UDim2.new(0, 0, 0, 0)
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
		font = Enum.Font.GothamBold,
		textSize = isHero and 13 or 11,
		alignX = Enum.TextXAlignment.Center,
		z = badge.ZIndex + 2,
		parent = badge,
	})

	badge.BackgroundTransparency = 1
	mask.BackgroundTransparency = 1
	tw(badge, TW_NORM, { BackgroundTransparency = 0 })
	tw(mask, TW_NORM, { BackgroundTransparency = 0 })

	return badge
end

-- ════════════════════════════════════════════════════════════════
-- HELPER: Boton de compra generico
-- ════════════════════════════════════════════════════════════════
local function createPurchaseHandler(btnFrame, btnLabel, parentCard, product, currency, isHero)
	local owned = false

	local function markOwned()
		if owned then return end
		owned = true
		tw(btnFrame, TW_FADE, { BackgroundTransparency = 1 })
		if btnLabel then
			tw(btnLabel, TW_FADE, { TextTransparency = 1 })
		end
		task.delay(0.18, function()
			btnFrame.Visible = false
			createOwnedBadge(parentCard, isHero)
		end)
	end

	-- Verificar si ya lo tiene
	if currency == "robux" and ownsPass(product.gamepassId) then
		markOwned()
	end

	-- Registrar callback de compra
	if currency == "robux" and product.gamepassId then
		onPurchase(product.gamepassId, markOwned)
	end

	return function()
		if owned then return end

		-- Press feedback (escala sutil)
		local origSize = btnFrame.Size
		tw(btnFrame, TW_PRESS, { Size = origSize + UDim2.new(0, -4, 0, -2) })
		task.delay(0.08, function()
			tw(btnFrame, TW_NORM, { Size = origSize })
		end)

		if currency == "robux" then
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, product.gamepassId)
			end)
		else
			print("[Shop] Compra item: " .. product.name .. " por " .. product.price .. " puntos")
			local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
			GlobalModalManager:showNotification("Sistema de puntos en configuracion", "warning")
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name = "ContentArea",
	size = UDim2.new(1, 0, 1, -HEADER_H),
	pos = UDim2.new(0, 0, 0, HEADER_H),
	bgT = 1, z = 100,
	parent = panel, clips = true,
})

local mainScroll
local refreshGen = 0

-- ════════════════════════════════════════════════════════════════
-- RENDER CONTENIDO
-- ════════════════════════════════════════════════════════════════
local function refreshContent(animate)
	refreshGen = refreshGen + 1
	local myGen = refreshGen
	local targetCatId = currentCatId

	-- Fade out anterior
	if mainScroll then
		if animate then
			local old = mainScroll
			tw(old, TweenInfo.new(0.12), { GroupTransparency = 1 })
			task.wait(0.12)
			if myGen ~= refreshGen then return end
			if old and old.Parent then old:Destroy() end
		else
			mainScroll:Destroy()
		end
	end

	-- Canvas group contenedor
	local holder = Instance.new("CanvasGroup")
	holder.Name = "ContentHolder"
	holder.Size = UDim2.new(1, 0, 1, 0)
	holder.BackgroundTransparency = 1
	holder.GroupTransparency = animate and 1 or 0
	holder.ZIndex = 100
	holder.Parent = contentArea
	mainScroll = holder

	-- Scroll vertical principal
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 2
	scroll.ScrollBarImageColor3 = C.border
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = 100
	scroll.Parent = holder

	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingLeft = UDim.new(0, 16)
	scrollPad.PaddingRight = UDim.new(0, 16)
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 24)
	scrollPad.Parent = scroll

	-- Buscar categoria
	local cat
	for _, c in ipairs(SHOP_CATEGORIES) do
		if c.id == targetCatId then cat = c break end
	end
	if not cat then cat = SHOP_CATEGORIES[1] end

	local featured = cat.featured
	local products = cat.products
	local currency = cat.currency
	local accent = cat.color
	local accentSoft = cat.colorSoft



	-- ═══════════════════════════════
	-- HERO CARD
	-- ═══════════════════════════════
	local heroH = isMobile and 230 or 220

	local hero = UI.frame({
		name = "HeroCard",
		size = UDim2.new(1, 0, 0, heroH),
		bg = C.surface,
		z = 102, parent = scroll, corner = 14,
	})

	-- Stroke accent
	local heroStroke = Instance.new("UIStroke")
	heroStroke.Color = accent
	heroStroke.Thickness = 1.5
	heroStroke.Transparency = 0.4
	heroStroke.Parent = hero

	-- Fondo: imagen con overlay pesado
	local heroBgImg = Instance.new("ImageLabel")
	heroBgImg.Name = "BgImg"
	heroBgImg.Size = UDim2.new(1, 0, 1, 0)
	heroBgImg.BackgroundTransparency = 1
	heroBgImg.Image = "rbxassetid://" .. featured.fondo
	heroBgImg.ScaleType = Enum.ScaleType.Crop
	heroBgImg.ImageTransparency = 0.1
	heroBgImg.ZIndex = 102
	heroBgImg.Active = false
	heroBgImg.Parent = hero
	Instance.new("UICorner", heroBgImg).CornerRadius = UDim.new(0, 14)

	-- Overlay oscuro con gradiente vertical
	local heroOverlay = UI.frame({
		name = "Overlay",
		size = UDim2.new(1, 0, 1, 0),
		bg = C.bg, z = 103, parent = hero, corner = 14,
	})
	heroOverlay.BackgroundTransparency = 0.15
	heroOverlay.Active = false

	local oGrad = Instance.new("UIGradient")
	oGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	}
	oGrad.Rotation = 90
	oGrad.Parent = heroOverlay

	-- Tag (esquina superior derecha)
	local tagW = #featured.tag * 7.5 + 24
	local tag = UI.frame({
		name = "Tag",
		size = UDim2.new(0, tagW, 0, 22),
		pos = UDim2.new(1, -tagW - 12, 0, 12),
		bg = accent, z = 110,
		parent = hero, corner = 4,
	})

	UI.label({
		text = featured.tag,
		size = UDim2.new(1, 0, 1, 0),
		color = C.textDark,
		font = Enum.Font.GothamBlack, textSize = 9,
		alignX = Enum.TextXAlignment.Center,
		z = 111, parent = tag,
	})

	-- Icono (circular, grande)
	local icoSize = isMobile and 64 or 72
	local heroIco = UI.frame({
		name = "Icon",
		size = UDim2.new(0, icoSize, 0, icoSize),
		pos = UDim2.new(0, 18, 0, 24),
		bg = Color3.fromRGB(15, 15, 24),
		z = 108, parent = hero, corner = icoSize / 2,
	})

	local icoStroke = Instance.new("UIStroke")
	icoStroke.Color = accent
	icoStroke.Thickness = 2
	icoStroke.Transparency = 0.3
	icoStroke.Parent = heroIco

	local heroIcoImg = Instance.new("ImageLabel")
	heroIcoImg.Size = UDim2.new(1, 0, 1, 0)
	heroIcoImg.BackgroundTransparency = 1
	heroIcoImg.Image = "rbxassetid://" .. featured.icon
	heroIcoImg.ScaleType = Enum.ScaleType.Crop
	heroIcoImg.ZIndex = 109
	heroIcoImg.Parent = heroIco
	Instance.new("UICorner", heroIcoImg).CornerRadius = UDim.new(1, 0)

	-- Textos (a la derecha del icono)
	local infoX = icoSize + 32

	UI.label({
		name = "Name",
		text = featured.name,
		size = UDim2.new(1, -infoX - 14, 0, 24),
		pos = UDim2.new(0, infoX, 0, 28),
		color = C.text,
		font = Enum.Font.GothamBlack, textSize = 18,
		alignX = Enum.TextXAlignment.Left,
		z = 108, parent = hero,
	})

	UI.label({
		name = "Desc",
		text = featured.description,
		size = UDim2.new(1, -infoX - 14, 0, 32),
		pos = UDim2.new(0, infoX, 0, 54),
		color = C.textSub,
		font = Enum.Font.GothamMedium, textSize = 11,
		alignX = Enum.TextXAlignment.Left,
		z = 108, parent = hero,
		textWrap = true,
	})

	-- Precio grande
	UI.label({
		name = "Price",
		text = priceStr(featured.price, currency),
		size = UDim2.new(0, 120, 0, 20),
		pos = UDim2.new(0, infoX, 0, 90),
		color = accent,
		font = Enum.Font.GothamBlack, textSize = 16,
		alignX = Enum.TextXAlignment.Left,
		z = 108, parent = hero,
	})

	-- Chips de comandos (scroll horizontal)
	if featured.commands and #featured.commands > 0 then
		local chipScroll = Instance.new("ScrollingFrame")
		chipScroll.Name = "ChipScroll"
		chipScroll.Size = UDim2.new(1, -infoX - 10, 0, 28)
		chipScroll.Position = UDim2.new(0, infoX, 0, 114)
		chipScroll.BackgroundTransparency = 1
		chipScroll.BorderSizePixel = 0
		chipScroll.ScrollBarThickness = 0
		chipScroll.ScrollingDirection = Enum.ScrollingDirection.X
		chipScroll.ElasticBehavior = Enum.ElasticBehavior.Always
		chipScroll.ZIndex = 112
		chipScroll.Active = true
		chipScroll.Parent = hero

		local chipLayout = Instance.new("UIListLayout")
		chipLayout.FillDirection = Enum.FillDirection.Horizontal
		chipLayout.Padding = UDim.new(0, 6)
		chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
		chipLayout.Parent = chipScroll

		for ci, cmd in ipairs(featured.commands) do
			local chip = UI.frame({
				name = "Chip" .. ci,
				size = UDim2.new(0, #cmd * 7 + 18, 0, 26),
				bg = accentSoft, z = 113,
				parent = chipScroll, corner = 6,
			})

			local chipStroke = Instance.new("UIStroke")
			chipStroke.Color = accent
			chipStroke.Thickness = 1
			chipStroke.Transparency = 0.6
			chipStroke.Parent = chip

			UI.label({
				text = cmd,
				size = UDim2.new(1, 0, 1, 0),
				color = accent,
				font = Enum.Font.GothamBold, textSize = 11,
				alignX = Enum.TextXAlignment.Center,
				z = 114, parent = chip,
			})
		end

		task.delay(0.1, function()
			if chipScroll and chipScroll.Parent then
				chipScroll.CanvasSize = UDim2.new(0, chipLayout.AbsoluteContentSize.X + 10, 0, 0)
			end
		end)
	end

	-- Boton comprar hero
	local heroBtnW = UDim2.new(1, -infoX - 14, 0, 38)
	local heroBtnPos = UDim2.new(0, infoX, 0, heroH - 54)

	local heroBtn = UI.frame({
		name = "BuyBtn",
		size = heroBtnW,
		pos = heroBtnPos,
		bg = accent, z = 112,
		parent = hero, corner = 8,
	})

	local heroBtnLabel = UI.label({
		text = "COMPRAR",
		size = UDim2.new(1, 0, 1, 0),
		color = C.textDark,
		font = Enum.Font.GothamBlack, textSize = 13,
		alignX = Enum.TextXAlignment.Center,
		z = 113, parent = heroBtn,
	})

	local heroBtnClick = Instance.new("TextButton")
	heroBtnClick.Size = UDim2.new(1, 0, 1, 0)
	heroBtnClick.BackgroundTransparency = 1
	heroBtnClick.Text = ""
	heroBtnClick.ZIndex = 114
	heroBtnClick.Parent = heroBtn

	local handleHeroBuy = createPurchaseHandler(heroBtn, heroBtnLabel, hero, featured, currency, true)
	heroBtnClick.MouseButton1Click:Connect(handleHeroBuy)

	-- Hover hero btn
	if not isMobile then
		heroBtnClick.MouseEnter:Connect(function()
			tw(heroBtn, TW_FAST, { BackgroundTransparency = 0.12 })
		end)
		heroBtnClick.MouseLeave:Connect(function()
			tw(heroBtn, TW_FAST, { BackgroundTransparency = 0 })
		end)
	end

	-- ═══════════════════════════════
	-- SECCION TITULO
	-- ═══════════════════════════════
	local sectionY = heroH + 20

	UI.label({
		name = "SectionTitle",
		size = UDim2.new(1, 0, 0, 18),
		pos = UDim2.new(0, 2, 0, sectionY),
		text = "TODOS",
		color = C.textMuted,
		font = Enum.Font.GothamBlack, textSize = 11,
		alignX = Enum.TextXAlignment.Left,
		z = 102, parent = scroll,
	})

	-- ═══════════════════════════════
	-- GRID DE PRODUCTOS (2 columnas)
	-- ═══════════════════════════════
	local gridY = sectionY + 28
	local GAP = 10
	local COLS = 2
	local scrollInnerW = panel.AbsoluteSize.X - 32 -- padding L+R
	local CARD_W = math.floor((scrollInnerW - GAP) / COLS)
	local CARD_H = isMobile and 190 or 195

	for i, product in ipairs(products) do
		local col = (i - 1) % COLS
		local row = math.floor((i - 1) / COLS)
		local posX = col * (CARD_W + GAP)
		local posY = gridY + row * (CARD_H + GAP)

		local card = UI.frame({
			name = product.name,
			size = UDim2.new(0, CARD_W, 0, CARD_H),
			pos = UDim2.new(0, posX, 0, posY),
			bg = C.surface,
			z = 103, parent = scroll, corner = 12,
		})
		card.ClipsDescendants = true

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = C.border
		cStroke.Thickness = 1
		cStroke.Transparency = 0.5
		cStroke.Parent = card

		-- Imagen de fondo (toda la card)
		local bgImg = Instance.new("ImageLabel")
		bgImg.Name = "BgImg"
		bgImg.Size = UDim2.new(1, 0, 1, 0)
		bgImg.BackgroundTransparency = 1
		bgImg.Image = "rbxassetid://" .. product.icon
		bgImg.ScaleType = Enum.ScaleType.Crop
		bgImg.ImageTransparency = 0.2
		bgImg.ZIndex = 103
		bgImg.Parent = card

		-- Overlay gradiente sobre la imagen
		local cardOverlay = UI.frame({
			name = "CardOverlay",
			size = UDim2.new(1, 0, 1, 0),
			pos = UDim2.new(0, 0, 0, 0),
			bg = C.surface,
			z = 104, parent = card, corner = 12,
		})

		local cardGrad = Instance.new("UIGradient")
		cardGrad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.45, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		}
		cardGrad.Rotation = 90
		cardGrad.Parent = cardOverlay

		-- Icono centrado
		local cIcoSize = 56
		local cIco = UI.frame({
			name = "Icon",
			size = UDim2.new(0, cIcoSize, 0, cIcoSize),
			pos = UDim2.new(0.5, -cIcoSize / 2, 0, 18),
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
		local nameL = UI.label({
			name = "Name",
			text = product.name,
			size = UDim2.new(1, -16, 0, 18),
			pos = UDim2.new(0.5, 0, 0, 82),
			color = C.text,
			font = Enum.Font.GothamBlack, textSize = 12,
			alignX = Enum.TextXAlignment.Center,
			z = 108, parent = card,
		})
		nameL.AnchorPoint = Vector2.new(0.5, 0)

		-- Comando chip (styled, si existe)
		if product.cmd and product.cmd ~= "" then
			local cmdW = math.min(#product.cmd * 7 + 18, CARD_W - 20)
			local cmdChip = UI.frame({
				name = "CmdChip",
				size = UDim2.new(0, cmdW, 0, 22),
				pos = UDim2.new(0.5, 0, 0, 104),
				bg = accentSoft, z = 109,
				parent = card, corner = 5,
			})
			cmdChip.AnchorPoint = Vector2.new(0.5, 0)

			local cmdStroke = Instance.new("UIStroke")
			cmdStroke.Color = accent
			cmdStroke.Thickness = 1
			cmdStroke.Transparency = 0.6
			cmdStroke.Parent = cmdChip

			UI.label({
				text = product.cmd,
				size = UDim2.new(1, 0, 1, 0),
				color = accent,
				font = Enum.Font.Code, textSize = 10,
				alignX = Enum.TextXAlignment.Center,
				z = 110, parent = cmdChip,
			})
		end

		-- Price badge (esquina superior derecha)
		local priceBadge = UI.frame({
			name = "PriceBadge",
			size = UDim2.new(0, 64, 0, 24),
			pos = UDim2.new(1, -8, 0, 8),
			bg = Color3.fromRGB(0, 0, 0),
			z = 115, parent = card, corner = 12,
		})
		priceBadge.AnchorPoint = Vector2.new(1, 0)
		priceBadge.BackgroundTransparency = 0.3

		UI.label({
			text = priceStr(product.price, currency),
			size = UDim2.new(1, 0, 1, 0),
			color = accent,
			font = Enum.Font.GothamBlack, textSize = 10,
			alignX = Enum.TextXAlignment.Center,
			z = 116, parent = priceBadge,
		})

		-- Precio (debajo del nombre/cmd)
		local priceL = UI.label({
			name = "Price",
			text = priceStr(product.price, currency),
			size = UDim2.new(1, -16, 0, 18),
			pos = UDim2.new(0.5, 0, 0, 126),
			color = accent,
			font = Enum.Font.GothamBold, textSize = 14,
			alignX = Enum.TextXAlignment.Center,
			z = 108, parent = card,
		})
		priceL.AnchorPoint = Vector2.new(0.5, 0)

		-- Boton comprar
		local buyFrame = UI.frame({
			name = "BuyFrame",
			size = UDim2.new(1, -24, 0, 34),
			pos = UDim2.new(0.5, 0, 1, -42),
			bg = accent, z = 110,
			parent = card, corner = 8,
		})
		buyFrame.AnchorPoint = Vector2.new(0.5, 0)

		-- Gradient en boton
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
			font = Enum.Font.GothamBlack, textSize = 11,
			alignX = Enum.TextXAlignment.Center,
			z = 111, parent = buyFrame,
		})

		local buyClick = Instance.new("TextButton")
		buyClick.Size = UDim2.new(1, 0, 1, 0)
		buyClick.BackgroundTransparency = 1
		buyClick.Text = ""
		buyClick.ZIndex = 112
		buyClick.Parent = buyFrame

		local handleBuy = createPurchaseHandler(buyFrame, buyLabel, card, product, currency, false)
		buyClick.MouseButton1Click:Connect(handleBuy)

		-- Hover card (desktop)
		if not isMobile then
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					tw(card, TW_FAST, { BackgroundColor3 = C.surfaceHov })
					tw(cardOverlay, TW_FAST, { BackgroundColor3 = C.surfaceHov })
					tw(cStroke, TW_FAST, { Color = accent, Transparency = 0.3 })
				end
			end)
			card.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					tw(card, TW_FAST, { BackgroundColor3 = C.surface })
					tw(cardOverlay, TW_FAST, { BackgroundColor3 = C.surface })
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
	end

	-- Canvas size
	task.defer(function()
		local totalRows = math.ceil(#products / COLS)
		local totalH = gridY + (totalRows * (CARD_H + GAP)) + 20
		scroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
	end)

	-- Fade in
	if animate and myGen == refreshGen then
		tw(holder, TweenInfo.new(0.2), { GroupTransparency = 0 })
	end
end

-- ════════════════════════════════════════════════════════════════
-- SELECT CATEGORY
-- ════════════════════════════════════════════════════════════════
selectCategory = function(catId)
	if not catId or type(catId) ~= "string" then return end
	if catId == currentCatId then return end
	currentCatId = catId

	refreshContent(true)

	local activeCat
	for _, c in ipairs(SHOP_CATEGORIES) do
		if c.id == catId then activeCat = c break end
	end
	if activeCat then
		task.spawn(function() preloadOwnership(activeCat) end)
	end
end

-- Render inicial
preloadOwnership(SHOP_CATEGORIES[1])
refreshContent(false)

-- ════════════════════════════════════════════════════════════════
-- OPEN / CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	modal:open()
	task.wait(0.1)
	for _, c in ipairs(SHOP_CATEGORIES) do
		if c.id == currentCatId then preloadOwnership(c) break end
	end
	task.spawn(function() refreshContent(false) end)
end

local function closeUI()
	if not modal:isModalOpen() then return end
	modal:close()
end

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