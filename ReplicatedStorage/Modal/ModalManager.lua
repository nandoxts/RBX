--[[
	ModalManager - Sistema centralizado de modales
	Maneja overlay, blur, panel y animaciones
	Utilizado por DjDashboard y CreateClanGui
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- ════════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

-- ════════════════════════════════════════════════════════════════
-- DETECCIÓN DE DISPOSITIVO
-- ════════════════════════════════════════════════════════════════
local function isMobileDevice()
	-- Detectar por touch o tamaño de pantalla
	return UserInputService.TouchEnabled
end

local function calculateResponsiveDimensions(screenGui, baseWidth, baseHeight)
	local screenSize = screenGui.AbsoluteSize
	local isMobile = isMobileDevice()

	if isMobile then
		-- En celular: usa 90% del ancho, máximo 85% del alto con padding
		local width = screenSize.X * 0.9
		local height = math.min(screenSize.Y * 0.85, baseHeight * 0.8)
		return width, height
	else
		-- En desktop: usa tamaño base pero respeta pantalla mínima
		local width = math.min(baseWidth, screenSize.X * 0.95)
		local height = math.min(baseHeight, screenSize.Y * 0.9)
		return width, height
	end
end

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function rounded(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function stroked(inst, alpha, color)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.stroke
	s.Thickness = 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════
local ModalManager = {}
ModalManager.__index = ModalManager

function ModalManager.new(config)
	local self = setmetatable({}, ModalManager)

	-- Configuración
	self.screenGui = config.screenGui
	self.panelName = config.panelName or "ModalPanel"

	-- Calcular dimensiones responsivas
	local baseWidth = config.panelWidth or (THEME.panelWidth or 980)
	local baseHeight = config.panelHeight or (THEME.panelHeight or 620)
	self.panelWidth, self.panelHeight = calculateResponsiveDimensions(self.screenGui, baseWidth, baseHeight)

	self.cornerRadius = config.cornerRadius or 12
	self.enableBlur = config.enableBlur ~= false
	self.blurSize = config.blurSize or 14
	self.onOpen = config.onOpen
	self.onClose = config.onClose
	self.isMobile = isMobileDevice()

	-- Estado
	self.isOpen = false
	self.activeTweens = {} -- Rastrear tweens para limpiarlos

	-- Crear componentes
	self:_createOverlay()
	self:_createBlur()
	self:_createPanel()

	return self
end

function ModalManager:_createOverlay()
	self.overlay = Instance.new("Frame")
	self.overlay.Name = "Overlay"
	self.overlay.BackgroundColor3 = THEME.bg
	self.overlay.BorderSizePixel = 0
	self.overlay.Size = UDim2.fromScale(1, 1)
	self.overlay.Position = UDim2.fromScale(0, 0)
	self.overlay.BackgroundTransparency = 1
	self.overlay.Visible = false
	self.overlay.ZIndex = 95
	self.overlay.Parent = self.screenGui
	
	-- Overlay solo visual - NO detecta clics
	-- Los modales se cierran SOLO con el botón que los abrió o el botón X
end

function ModalManager:_createBlur()
	if not self.enableBlur then return end

	self.blur = Instance.new("BlurEffect")
	self.blur.Size = 0
	self.blur.Enabled = false
	self.blur.Parent = Lighting
end

function ModalManager:_createPanel()
	self.panel = Instance.new("Frame")
	self.panel.Name = self.panelName
	self.panel.AnchorPoint = Vector2.new(0.5, 0.5)
	self.panel.Position = UDim2.new(0.5, 0, 1.5, 0)
	self.panel.BackgroundColor3 = THEME.panel or Color3.fromRGB(18, 18, 22)
	self.panel.BorderSizePixel = 0
	self.panel.Visible = false
	self.panel.ZIndex = 100
	self.panel.Size = UDim2.new(0, self.panelWidth, 0, self.panelHeight)
	self.panel.Parent = self.screenGui
	rounded(self.panel, self.cornerRadius)
	stroked(self.panel, 0.7)
end

function ModalManager:open()
	if self.isOpen then return end
	self.isOpen = true

	self.panel.Visible = true
	self.overlay.Visible = true

	-- Animar overlay
	local overlayTween = TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = 0.45})
	table.insert(self.activeTweens, overlayTween)
	overlayTween:Play()

	-- Animar blur
	if self.blur then
		self.blur.Enabled = true
		local blurTween = TweenService:Create(self.blur, TweenInfo.new(0.22), {Size = self.blurSize})
		table.insert(self.activeTweens, blurTween)
		blurTween:Play()
	end

	-- Animar panel
	self.panel.Position = UDim2.fromScale(0.5, 1.1)
	local panelTween = TweenService:Create(self.panel, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
	table.insert(self.activeTweens, panelTween)
	panelTween:Play()

	-- Callback
	if self.onOpen then
		self.onOpen()
	end
end

function ModalManager:close()
	if not self.isOpen then return end
	self.isOpen = false

	-- Cancelar tweens activos
	for _, tween in ipairs(self.activeTweens) do
		if tween then
			pcall(function() tween:Cancel() end)
		end
	end
	self.activeTweens = {}

	-- Animar panel
	local panelTween = TweenService:Create(self.panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 1.1)
	})
	table.insert(self.activeTweens, panelTween)
	panelTween:Play()

	-- Animar overlay
	local overlayTween = TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1})
	table.insert(self.activeTweens, overlayTween)
	overlayTween:Play()

	-- Ocultar después de la animación
	task.delay(0.22, function()
		self.overlay.Visible = false
		self.panel.Visible = false
	end)

	-- Animar blur
	if self.blur then
		local blurTween = TweenService:Create(self.blur, TweenInfo.new(0.22), {Size = 0})
		table.insert(self.activeTweens, blurTween)
		blurTween:Play()
		task.delay(0.22, function()
			if self.blur then 
				self.blur.Enabled = false 
			end
		end)
	end

	-- Callback
	if self.onClose then
		self.onClose()
	end
end

function ModalManager:getPanel()
	return self.panel
end

function ModalManager:isModalOpen()
	return self.isOpen
end

return ModalManager