-- ════════════════════════════════════════════════════════════════
-- MODERN INVENTORY SYSTEM
-- Interfaz personalizada en la parte inferior de la pantalla
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

-- Ocultar backpack estándar
StarterGui:SetCoreGuiEnabled(Enum.CoreGui.Backpack, false)

-- ════════════════════════════════════════════════════════════════
-- CREAR GUI PRINCIPAL
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernInventory"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndex = 50
screenGui.Parent = playerGui

-- Container principal (parte inferior)
local inventoryContainer = Instance.new("Frame")
inventoryContainer.Name = "InventoryContainer"
inventoryContainer.Size = UDim2.new(1, 0, 0, 100)
inventoryContainer.Position = UDim2.new(0, 0, 1, -100)
inventoryContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
inventoryContainer.BorderSizePixel = 0
inventoryContainer.ZIndex = 50
inventoryContainer.Parent = screenGui

-- Borde superior
local topBorder = Instance.new("Frame")
topBorder.Name = "TopBorder"
topBorder.Size = UDim2.new(1, 0, 0, 2)
topBorder.Position = UDim2.new(0, 0, 0, 0)
topBorder.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
topBorder.BorderSizePixel = 0
topBorder.ZIndex = 51
topBorder.Parent = inventoryContainer

-- Layout para items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemsScroll"
scrollFrame.Size = UDim2.new(1, -20, 1, -35)
scrollFrame.Position = UDim2.new(0, 10, 0, 25)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollDirection = Enum.ScrollDirection.Horizontal
scrollFrame.ScrollBarThickness = 0
scrollFrame.ZIndex = 50
scrollFrame.Parent = inventoryContainer

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 5)
padding.Parent = scrollFrame

-- Label "Inventario"
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0, 80, 0, 20)
titleLabel.Position = UDim2.new(0, 10, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "INVENTARIO"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.GothamBold
titleLabel.ZIndex = 51
titleLabel.Parent = inventoryContainer

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES
-- ════════════════════════════════════════════════════════════════

local function createToolButton(tool)
local button = Instance.new("Frame")
button.Name = tool.Name
button.Size = UDim2.new(0, 70, 0, 70)
button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
button.BorderColor3 = Color3.fromRGB(100, 200, 255)
button.BorderSizePixel = 2
button.ZIndex = 50

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Icono (usando texto si no hay imagen)
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(1, -4, 1, -4)
icon.Position = UDim2.new(0, 2, 0, 2)
icon.BackgroundTransparency = 1
icon.Text = "���️"
icon.TextSize = 24
icon.ZIndex = 51
icon.Parent = button

-- Nombre del item
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 14)
nameLabel.Position = UDim2.new(0, 0, 1, -14)
nameLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
nameLabel.BorderSizePixel = 0
nameLabel.Text = tool.Name
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 10
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
nameLabel.ZIndex = 51
nameLabel.Parent = button

local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 6)
nameCorner.Parent = nameLabel

-- Interactividad
local mouseEnter = false
button.MouseEnter:Connect(function()
mouseEnter = true
local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 100, 140)})
tween:Play()
end)

button.MouseLeave:Connect(function()
mouseEnter = false
local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
tween:Play()
end)

button.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

-- Equipar/desequipar herramienta
if tool.Parent == player.Backpack then
tool.Parent = character:FindFirstChild("Humanoid") and character or player.Backpack
else
tool.Parent = player.Backpack
end
end)

button.Parent = scrollFrame
return button
end

local function updateInventory()
-- Limpiar botones actuales
for _, child in ipairs(scrollFrame:GetChildren()) do
if child:IsA("Frame") and child ~= listLayout and child ~= padding then
child:Destroy()
end
end

-- Crear botones para cada herramienta
local backpack = player:FindFirstChild("Backpack")
if backpack then
for _, tool in ipairs(backpack:GetChildren()) do
if tool:IsA("Tool") then
createToolButton(tool)
end
end
end

-- Actualizar canvas size
task.wait(0.1)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
scrollFrame.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X + 10, 0, 0)
end)
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════

local backpack = player:WaitForChild("Backpack")

-- Escuchar cuando se agregan herramientas
backpack.ChildAdded:Connect(function(child)
if child:IsA("Tool") then
task.wait(0.1)
updateInventory()
end
end)

-- Escuchar cuando se remueven herramientas
backpack.ChildRemoved:Connect(function(child)
if child:IsA("Tool") then
updateInventory()
end
end)

-- Actualizar cuando cambia de character
player.CharacterAdded:Connect(function(newCharacter)
character = newCharacter
updateInventory()
end)

-- ════════════════════════════════════════════════════════════════
-- INIT
-- ════════════════════════════════════════════════════════════════
updateInventory()

print("✓ Modern Inventory System loaded")
