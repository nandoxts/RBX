--[[
SpeedBoost - Aumenta velocidad con SHIFT (PC) o botón (Móvil)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuración de velocidad
local NORMAL_SPEED = 16
local BOOST_SPEED = 35
local isShiftPressed = false
-- Detectar si es REALMENTE móvil (no PC con pantalla táctil)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ════════════════════════════════════════════════════════════════
-- CREAR BOTÓN PARA MÓVIL
-- ════════════════════════════════════════════════════════════════
local speedButton = nil

local function createMobileButton()
	if speedButton then speedButton:Destroy() end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedBoostGUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Botón circular estilo Roblox (TRANSPARENTE)
	speedButton = Instance.new("TextButton")
	speedButton.Name = "SpeedBoostBtn"
	speedButton.Size = UDim2.new(0, 70, 0, 70)
	speedButton.Position = UDim2.new(1, -178, 1, -85)
	speedButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	speedButton.BackgroundTransparency = 0.5
	speedButton.Text = ""
	speedButton.ZIndex = 10
	speedButton.Parent = screenGui
	
	-- Hacer el botón circular
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = speedButton
	
	-- Borde exterior blanco como el botón de salto
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 3
	stroke.Transparency = 0
	stroke.Parent = speedButton
	
	-- Texto SHIFT sin borde
	local shiftText = Instance.new("TextLabel")
	shiftText.Size = UDim2.new(1, 0, 1, 0)
	shiftText.Position = UDim2.new(0, 0, 0, 0)
	shiftText.BackgroundTransparency = 1
	shiftText.Text = "SHIFT"
	shiftText.TextColor3 = Color3.fromRGB(255, 255, 255)
	shiftText.Font = Enum.Font.GothamBold
	shiftText.TextSize = 12
	shiftText.ZIndex = 11
	shiftText.Parent = speedButton
	
	-- Eventos del botón
	local function activateSpeed()
		isShiftPressed = true
		speedButton.BackgroundTransparency = 0.3
		stroke.Transparency = 0
	end
	
	local function deactivateSpeed()
		isShiftPressed = false
		speedButton.BackgroundTransparency = 0.5
		stroke.Transparency = 0
	end
	
	speedButton.MouseButton1Down:Connect(activateSpeed)
	speedButton.MouseButton1Up:Connect(deactivateSpeed)
	speedButton.TouchBegan:Connect(activateSpeed)
	speedButton.TouchEnded:Connect(deactivateSpeed)
end

-- Crear botón solo si es móvil
if isMobile then
	createMobileButton()
	print("✓ SpeedBoost activado - Botón móvil creado")
else
	print("✓ SpeedBoost activado - Modo PC (usa SHIFT)")
end

task.wait(0.1)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if not isMobile and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
		isShiftPressed = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not isMobile and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
		isShiftPressed = false
	end
end)

-- Detectar cambio entre PC y Móvil
UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
	isMobile = lastInputType == Enum.UserInputType.Touch
	if isMobile and not speedButton then
		createMobileButton()
	elseif not isMobile and speedButton then
		speedButton.Parent.Parent:Destroy()
		speedButton = nil
	end
end)

-- ════════════════════════════════════════════════════════════════
-- APLICAR VELOCIDAD
-- ════════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	
	if isShiftPressed then
		humanoid.WalkSpeed = BOOST_SPEED
	else
		humanoid.WalkSpeed = NORMAL_SPEED
	end
end)

-- ════════════════════════════════════════════════════════════════
-- RECARGAR AL REAPARECE EL PERSONAJE
-- ════════════════════════════════════════════════════════════════
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	isShiftPressed = false
end)

