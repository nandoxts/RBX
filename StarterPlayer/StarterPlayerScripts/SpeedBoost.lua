--[[
SpeedBoost - SHIFT para velocidad (PC y Móvil)
Envía eventos al servidor a través de ShiftToRun
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CREAR BOTÓN PARA MÓVIL
local speedButton = nil

local function createMobileButton()
if speedButton then return end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedBoostGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

speedButton = Instance.new("TextButton")
speedButton.Name = "SpeedBoostBtn"
speedButton.Size = UDim2.new(0, 70, 0, 70)
speedButton.Position = UDim2.new(1, -178, 1, -85)
speedButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
speedButton.BackgroundTransparency = 0.5
speedButton.Text = ""
speedButton.ZIndex = 10
speedButton.Parent = screenGui

-- Esquinas redondas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = speedButton

-- Borde blanco
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 3
stroke.Parent = speedButton

-- Texto SIN borde
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text = "SHIFT"
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.Font = Enum.Font.GothamBold
textLabel.TextSize = 12
textLabel.ZIndex = 11
textLabel.Parent = speedButton

-- Eventos del botón
local shiftHandler = game.StarterPlayer.StarterPlayerScripts.ShiftToRun.ServerHandler.Run

speedButton.MouseButton1Down:Connect(function()
shiftHandler:FireServer("ShiftActive")
speedButton.BackgroundTransparency = 0.3
end)

speedButton.MouseButton1Up:Connect(function()
shiftHandler:FireServer("ShiftDisable")
speedButton.BackgroundTransparency = 0.5
end)
end

-- Crear botón si es móvil
if UserInputService.TouchEnabled then
createMobileButton()
print("✓ SpeedBoost: Botón SHIFT para móvil")
else
print("✓ SpeedBoost: Modo PC (SHIFT)")
end

task.wait(0.1)

-- DETECTAR SHIFT EN PC
local shiftHandler = game.StarterPlayer.StarterPlayerScripts.ShiftToRun.ServerHandler.Run

UserInputService.InputBegan:Connect(function(input, processed)
if processed then return end
if not UserInputService.TouchEnabled then
if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
shiftHandler:FireServer("ShiftActive")
end
end
end)

UserInputService.InputEnded:Connect(function(input)
if not UserInputService.TouchEnabled then
if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
shiftHandler:FireServer("ShiftDisable")
end
end
end)

-- Detectar cambio PC <-> Móvil
UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
if lastInputType == Enum.UserInputType.Touch and not speedButton then
createMobileButton()
elseif lastInputType ~= Enum.UserInputType.Touch and speedButton then
if speedButton.Parent and speedButton.Parent.Parent then
speedButton.Parent.Parent:Destroy()
end
speedButton = nil
end
end)
