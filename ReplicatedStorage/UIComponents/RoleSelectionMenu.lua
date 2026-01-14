-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENTE: RoleSelectionMenu (Menú desplegable de roles)
-- ══════════════════════════════════════════════════════════════════════════════

local UI = require(game.ReplicatedStorage.Core.UI)
local THEME = require(game.ReplicatedStorage.Config.ThemeConfig)
local TweenService = game:GetService("TweenService")

local RoleSelectionMenu = {}
RoleSelectionMenu.__index = RoleSelectionMenu

function RoleSelectionMenu.new(config)
	local self = setmetatable({}, RoleSelectionMenu)
	
	self.screenGui = config.screenGui
	self.title = config.title
	self.subtitle = config.subtitle
	self.options = config.options
	self.onSelect = config.onSelect
	
	self.connections = {}
	self:_build()
	
	return self
end

function RoleSelectionMenu:_build()
	-- Overlay oscuro
	self.overlay = UI.frame({
		size = UDim2.new(1, 0, 1, 0),
		bg = Color3.new(0, 0, 0),
		bgT = 0.6,
		z = 200,
		parent = self.screenGui
	})
	
	-- Contenedor del menú
	local menuHeight = 80 + (#self.options * 44)
	self.menu = UI.frame({
		size = UDim2.new(0, 280, 0, menuHeight),
		pos = UDim2.new(0.5, -140, 0.5, -menuHeight/2),
		bg = THEME.card,
		z = 201,
		parent = self.screenGui,
		corner = 12,
		stroke = true,
		strokeA = 0.6
	})
	
	-- Título
	UI.label({
		size = UDim2.new(1, -20, 0, 22),
		pos = UDim2.new(0, 10, 0, 12),
		text = self.title,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Center,
		z = 202,
		parent = self.menu
	})
	
	-- Subtítulo
	UI.label({
		size = UDim2.new(1, -20, 0, 16),
		pos = UDim2.new(0, 10, 0, 36),
		text = self.subtitle,
		color = THEME.muted,
		textSize = 11,
		alignX = Enum.TextXAlignment.Center,
		z = 202,
		parent = self.menu
	})
	
	-- Separador
	UI.frame({
		size = UDim2.new(1, -20, 0, 1),
		pos = UDim2.new(0, 10, 0, 58),
		bg = THEME.surface,
		z = 202,
		parent = self.menu
	})
	
	-- Opciones
	for i, option in ipairs(self.options) do
		local optionBtn = UI.button({
			size = UDim2.new(1, -20, 0, 38),
			pos = UDim2.new(0, 10, 0, 64 + (i-1) * 44),
			bg = THEME.surface,
			text = option.display,
			color = option.color,
			textSize = 13,
			font = Enum.Font.GothamMedium,
			z = 202,
			parent = self.menu,
			corner = 8
		})
		
		table.insert(self.connections, optionBtn.MouseButton1Click:Connect(function()
			self:destroy()
			if self.onSelect then
				self.onSelect(option.role)
			end
		end))
	end
	
	-- Cerrar al hacer clic fuera
	table.insert(self.connections, self.overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self:destroy()
		end
	end))
	
	-- Animación de entrada
	self.menu.Size = UDim2.new(0, 280, 0, 0)
	TweenService:Create(self.menu, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 280, 0, menuHeight)
	}):Play()
end

function RoleSelectionMenu:destroy()
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	
	if self.overlay then self.overlay:Destroy() end
	if self.menu then self.menu:Destroy() end
end

return RoleSelectionMenu