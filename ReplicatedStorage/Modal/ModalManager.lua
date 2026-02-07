--[[
	ModalManager - Sistema centralizado de modales
]]

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local function calculateResponsiveDimensions(screenGui, baseWidth, baseHeight, isMobile)
	local screenSize = screenGui.AbsoluteSize
	
	if screenSize.X == 0 or screenSize.Y == 0 then
		task.wait(0.15)
		screenSize = screenGui.AbsoluteSize
	end
	
	if screenSize.X == 0 or screenSize.Y == 0 then
		screenSize = workspace.CurrentCamera.ViewportSize
	end
	
	if screenSize.X == 0 or screenSize.Y == 0 then
		screenSize = Vector2.new(1920, 1080)
	end

	if isMobile then
		local minMarginWidth = 20
		local minMarginHeight = 60
		
		if screenSize.X < 400 then
			minMarginWidth = 10
		end
		if screenSize.Y < 600 then
			minMarginHeight = 40
		end
		
		local width = screenSize.X - (minMarginWidth * 2)
		local height = screenSize.Y - minMarginHeight
		
		width = math.max(width, math.min(280, screenSize.X * 0.85))
		height = math.max(height, math.min(300, screenSize.Y * 0.75))
		
		return width, height
	else
		local width = math.min(baseWidth or 980, screenSize.X * 0.90)
		local height = math.min(baseHeight or 620, screenSize.Y * 0.85)
		return width, height
	end
end

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
	s.Transparency = alpha or THEME.mediumAlpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local ModalManager = {}
ModalManager.__index = ModalManager

function ModalManager.new(config)
	local self = setmetatable({}, ModalManager)

	self.screenGui = config.screenGui
	self.panelName = config.panelName or "ModalPanel"

	local isMobile = config.isMobile or false
	local baseWidth = config.panelWidth
	local baseHeight = config.panelHeight
	self.panelWidth, self.panelHeight = calculateResponsiveDimensions(self.screenGui, baseWidth, baseHeight, isMobile)

	self.cornerRadius = config.cornerRadius or 12
	self.enableBlur = config.enableBlur ~= false
	self.blurSize = config.blurSize or 14
	self.onOpen = config.onOpen
	self.onClose = config.onClose
	self.isMobile = isMobile

	self.isOpen = false
	self.activeTweens = {}

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
	self.panel.BackgroundTransparency = THEME.lightAlpha or 0.2
	self.panel.BorderSizePixel = 0
	self.panel.Visible = false
	self.panel.ZIndex = 100
	self.panel.Size = UDim2.new(0, self.panelWidth, 0, self.panelHeight)
	self.panel.Parent = self.screenGui
	rounded(self.panel, self.cornerRadius)
	stroked(self.panel, THEME.mediumAlpha or 0.5)
end

function ModalManager:open()
	if self.isOpen then return end
	self.isOpen = true

	self.panel.Visible = true
	self.overlay.Visible = true

	local overlayTween = TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = THEME.mediumAlpha or 0.5})
	table.insert(self.activeTweens, overlayTween)
	overlayTween:Play()

	if self.blur then
		self.blur.Enabled = true
		local blurTween = TweenService:Create(self.blur, TweenInfo.new(0.22), {Size = self.blurSize})
		table.insert(self.activeTweens, blurTween)
		blurTween:Play()
	end

	self.panel.Position = UDim2.fromScale(0.5, 1.1)
	local panelTween = TweenService:Create(self.panel, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
	table.insert(self.activeTweens, panelTween)
	panelTween:Play()

	if self.onOpen then
		self.onOpen()
	end
end

function ModalManager:close()
	if not self.isOpen then return end
	self.isOpen = false

	for _, tween in ipairs(self.activeTweens) do
		if tween then
			pcall(function() tween:Cancel() end)
		end
	end
	self.activeTweens = {}

	local panelTween = TweenService:Create(self.panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 1.1)
	})
	table.insert(self.activeTweens, panelTween)
	panelTween:Play()

	local overlayTween = TweenService:Create(self.overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1})
	table.insert(self.activeTweens, overlayTween)
	overlayTween:Play()

	task.delay(0.22, function()
		self.overlay.Visible = false
		self.panel.Visible = false
	end)

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