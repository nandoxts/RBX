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

-- ════════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

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
	self.panelWidth = config.panelWidth or (THEME.panelWidth or 980)
	self.panelHeight = config.panelHeight or (THEME.panelHeight or 620)
	self.cornerRadius = config.cornerRadius or 12
	self.enableBlur = config.enableBlur ~= false
	self.blurSize = config.blurSize or 14
	self.onOpen = config.onOpen
	self.onClose = config.onClose
	
	-- Estado
	self.isOpen = false
	
	-- Crear componentes
	self:_createOverlay()
	self:_createBlur()
	self:_createPanel()
	
	return self
end

function ModalManager:_createOverlay()
	self.overlay = Instance.new("TextButton")
	self.overlay.Name = "Overlay"
	self.overlay.BackgroundColor3 = THEME.bg
	self.overlay.AutoButtonColor = false
	self.overlay.BorderSizePixel = 0
	self.overlay.Size = UDim2.fromScale(1, 1)
	self.overlay.Position = UDim2.fromScale(0, 0)
	self.overlay.BackgroundTransparency = 1
	self.overlay.Visible = false
	self.overlay.ZIndex = 95
	self.overlay.Text = ""
	self.overlay.Parent = self.screenGui
	
	-- Click en overlay cierra el modal solo si es fuera del panel
	self.overlay.MouseButton1Click:Connect(function()
		local mousePos = game:GetService("UserInputService"):GetMouseLocation()
		local panelPos = self.panel.AbsolutePosition
		local panelSize = self.panel.AbsoluteSize
		
		-- Verificar si el click fue fuera del panel
		if mousePos.X < panelPos.X or mousePos.X > panelPos.X + panelSize.X or
			mousePos.Y < panelPos.Y or mousePos.Y > panelPos.Y + panelSize.Y then
			self:close()
		end
	end)
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
	TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = 0.45}):Play()
	
	-- Animar blur
	if self.blur then
		self.blur.Enabled = true
		TweenService:Create(self.blur, TweenInfo.new(0.22), {Size = self.blurSize}):Play()
	end
	
	-- Animar panel
	self.panel.Position = UDim2.fromScale(0.5, 1.1)
	TweenService:Create(self.panel, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 0.5)
	}):Play()
	
	-- Callback
	if self.onOpen then
		self.onOpen()
	end
end

function ModalManager:close()
	if not self.isOpen then return end
	self.isOpen = false
	
	-- Animar panel
	TweenService:Create(self.panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 1.1)
	}):Play()
	
	-- Animar overlay
	TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
	
	-- Ocultar después de la animación
	task.delay(0.22, function()
		self.overlay.Visible = false
		self.panel.Visible = false
	end)
	
	-- Animar blur
	if self.blur then
		TweenService:Create(self.blur, TweenInfo.new(0.22), {Size = 0}):Play()
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
