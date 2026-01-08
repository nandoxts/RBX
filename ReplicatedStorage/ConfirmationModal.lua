--[[
    ConfirmationModal.luau
    Sistema de modales de confirmación reutilizable
    Autor: nandoxts
    Fecha: 2025-10-11
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cargar ThemeConfig
local ThemeConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local ConfirmationModal = {}
ConfirmationModal.__index = ConfirmationModal

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
	s.Color = color or ThemeConfig.stroke
	s.Thickness = 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

-- ════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════
function ConfirmationModal.new(config)
	local self = setmetatable({}, ConfirmationModal)

	-- Configuración
	self.screenGui = config.screenGui or error("ScreenGui is required")
	self.theme = config.theme or ThemeConfig
	self.title = config.Title or config.title or "Confirm Action"
	self.message = config.Message or config.message or "Are you sure?"
	self.confirmText = config.ConfirmText or config.confirmText or "Confirm"
	self.cancelText = config.CancelText or config.cancelText or "Cancel"
	self.onConfirm = config.OnConfirm or config.onConfirm or function() end
	self.onCancel = config.OnCancel or config.onCancel or function() end

	-- Input opcional
	self.inputText = config.InputText or config.inputText or nil
	self.inputPlaceholder = config.InputPlaceholder or config.inputPlaceholder or ""
	self.inputDefault = config.InputDefault or config.inputDefault or ""
	self.inputValue = self.inputDefault

	-- Referencias
	self.modalOverlay = nil
	self.modal = nil
	self.inputBox = nil
	self.isOpen = false

	-- Abrir automáticamente
	self:open()

	return self
end

-- ════════════════════════════════════════════════════════════════
-- CREAR MODAL
-- ════════════════════════════════════════════════════════════════
function ConfirmationModal:_createModal()
	-- Overlay
	self.modalOverlay = Instance.new("Frame")
	self.modalOverlay.Name = "ModalOverlay"
	self.modalOverlay.Size = UDim2.fromScale(1, 1)
	self.modalOverlay.Position = UDim2.fromScale(0, 0)
	self.modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.modalOverlay.BackgroundTransparency = 1
	self.modalOverlay.BorderSizePixel = 0
	self.modalOverlay.ZIndex = 300
	self.modalOverlay.Active = true
	self.modalOverlay.Selectable = false
	self.modalOverlay.Parent = self.screenGui

	-- Modal principal
	self.modal = Instance.new("Frame")
	self.modal.Size = UDim2.new(0, 380, 0, 180)
	self.modal.Position = UDim2.new(0.5, -190, 0.5, -120)
	self.modal.BackgroundColor3 = self.theme.panel
	self.modal.BorderSizePixel = 0
	self.modal.ZIndex = 301
	self.modal.Parent = self.modalOverlay
	rounded(self.modal, 12)
	stroked(self.modal, 0.3)

	-- Título
	local modalTitle = Instance.new("TextLabel")
	modalTitle.Size = UDim2.new(1, -32, 0, 40)
	modalTitle.Position = UDim2.new(0, 16, 0, 16)
	modalTitle.BackgroundTransparency = 1
	modalTitle.Text = self.title
	modalTitle.TextColor3 = self.theme.text
	modalTitle.Font = Enum.Font.GothamBold
	modalTitle.TextSize = 16
	modalTitle.TextXAlignment = Enum.TextXAlignment.Left
	modalTitle.ZIndex = 302
	modalTitle.Parent = self.modal

	-- Mensaje
	local modalMsg = Instance.new("TextLabel")
	modalMsg.Size = UDim2.new(1, -32, 0, 44)
	modalMsg.Position = UDim2.new(0, 16, 0, 56)
	modalMsg.BackgroundTransparency = 1
	modalMsg.Text = self.message
	modalMsg.TextColor3 = self.theme.muted
	modalMsg.Font = Enum.Font.Gotham
	modalMsg.TextSize = 15
	modalMsg.TextXAlignment = Enum.TextXAlignment.Left
	modalMsg.TextYAlignment = Enum.TextYAlignment.Top
	modalMsg.TextWrapped = true
	modalMsg.ZIndex = 302
	modalMsg.Parent = self.modal

	-- Input opcional
	if self.inputText ~= nil then
		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, -32, 0, 36)
		inputBox.Position = UDim2.new(0, 16, 0, 56)
		inputBox.BackgroundColor3 = self.theme.elevated
		inputBox.Text = self.inputDefault
		inputBox.PlaceholderText = self.inputPlaceholder
		inputBox.TextColor3 = self.theme.text
		inputBox.Font = Enum.Font.Gotham
		inputBox.TextSize = 15
		inputBox.BorderSizePixel = 0
		inputBox.ZIndex = 302
		inputBox.Parent = self.modal
		rounded(inputBox, 8)
		stroked(inputBox, 0.4)
		self.inputBox = inputBox
		inputBox:GetPropertyChangedSignal("Text"):Connect(function()
			self.inputValue = inputBox.Text
		end)
		inputBox:CaptureFocus()
	end

	-- Container de botones
	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(1, -32, 0, 36)
	btnContainer.Position = UDim2.new(0, 16, 1, -44)
	btnContainer.BackgroundTransparency = 1
	btnContainer.ZIndex = 302
	btnContainer.Parent = self.modal

	-- Botón Cancelar
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 170, 1, 0)
	cancelBtn.Position = UDim2.new(0, 0, 0, 0)
	cancelBtn.BackgroundColor3 = self.theme.head
	cancelBtn.Text = self.cancelText
	cancelBtn.TextColor3 = self.theme.text
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 15
	cancelBtn.BorderSizePixel = 0
	cancelBtn.ZIndex = 303
	cancelBtn.Parent = btnContainer
	rounded(cancelBtn, 8)
	stroked(cancelBtn, 0.5)

	-- Botón Confirmar
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0, 170, 1, 0)
	confirmBtn.Position = UDim2.new(1, -170, 0, 0)
	-- Si el modal tiene input (edición), usar color accent; si no, usar danger
	if self.inputText ~= nil then
		confirmBtn.BackgroundColor3 = self.theme.accent
	else
		confirmBtn.BackgroundColor3 = self.theme.danger
	end
	confirmBtn.Text = self.confirmText
	confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 15
	confirmBtn.BorderSizePixel = 0
	confirmBtn.ZIndex = 303
	confirmBtn.Parent = btnContainer
	rounded(confirmBtn, 8)

	-- Eventos
	cancelBtn.MouseButton1Click:Connect(function()
		self:close()
		self.onCancel()
	end)

	confirmBtn.MouseButton1Click:Connect(function()
		self:close()
		if self.inputText ~= nil then
			self.onConfirm(self.inputValue)
		else
			self.onConfirm()
		end
	end)

	-- Cerrar al hacer click en overlay
	self.modalOverlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = input.Position
			local modalPos = self.modal.AbsolutePosition
			local modalSize = self.modal.AbsoluteSize

			-- Solo cerrar si está fuera del modal
			if mousePos.X < modalPos.X or mousePos.X > modalPos.X + modalSize.X or
				mousePos.Y < modalPos.Y or mousePos.Y > modalPos.Y + modalSize.Y then
				self:close()
				self.onCancel()
			end
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- ABRIR MODAL
-- ════════════════════════════════════════════════════════════════
function ConfirmationModal:open()
	if self.isOpen then return end
	self.isOpen = true

	self:_createModal()

	-- Animación de entrada
	TweenService:Create(self.modalOverlay, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.7
	}):Play()

	TweenService:Create(self.modal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -190, 0.5, -90)
	}):Play()
end

-- ════════════════════════════════════════════════════════════════
-- CERRAR MODAL
-- ════════════════════════════════════════════════════════════════
function ConfirmationModal:close()
	if not self.isOpen then return end
	self.isOpen = false

	-- Animación de salida
	TweenService:Create(self.modalOverlay, TweenInfo.new(0.2), {
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(self.modal, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, -190, 0.5, -120)
	}):Play()

	task.wait(0.2)
	if self.modalOverlay then
		self.modalOverlay:Destroy()
		self.modalOverlay = nil
		self.modal = nil
	end
end

-- ════════════════════════════════════════════════════════════════
-- FUNCIÓN DE UTILIDAD RÁPIDA
-- ════════════════════════════════════════════════════════════════
function ConfirmationModal.show(config)
	local modal = ConfirmationModal.new(config)
	modal:open()
	return modal
end

return ConfirmationModal