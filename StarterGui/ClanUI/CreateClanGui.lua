local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que ClanClient esté disponible
local ClanModules = ServerStorage:WaitForChild("ClanModules")
local ClanClient = require(ClanModules:WaitForChild("ClanClient"))

-- Crear ScreenGui principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CreateClanGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Fondo de pantalla oscuro
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.7
background.BorderSizePixel = 0
background.Parent = screenGui

-- Panel principal
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 400, 0, 300)
mainPanel.Position = UDim2.new(0.5, -200, 0.5, -150)
mainPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
mainPanel.BorderSizePixel = 2
mainPanel.Parent = screenGui

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.BorderSizePixel = 0
title.Text = "Crear Clan"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = mainPanel

-- Label nombre
local labelNombre = Instance.new("TextLabel")
labelNombre.Name = "LabelNombre"
labelNombre.Size = UDim2.new(1, -20, 0, 25)
labelNombre.Position = UDim2.new(0, 10, 0, 50)
labelNombre.BackgroundTransparency = 1
labelNombre.Text = "Nombre del Clan:"
labelNombre.TextColor3 = Color3.fromRGB(200, 200, 200)
labelNombre.TextSize = 16
labelNombre.Font = Enum.Font.Gotham
labelNombre.TextXAlignment = Enum.TextXAlignment.Left
labelNombre.Parent = mainPanel

-- Input nombre
local inputNombre = Instance.new("TextBox")
inputNombre.Name = "InputNombre"
inputNombre.Size = UDim2.new(1, -20, 0, 30)
inputNombre.Position = UDim2.new(0, 10, 0, 75)
inputNombre.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
inputNombre.BorderColor3 = Color3.fromRGB(100, 100, 100)
inputNombre.BorderSizePixel = 1
inputNombre.Text = ""
inputNombre.TextColor3 = Color3.fromRGB(255, 255, 255)
inputNombre.TextSize = 16
inputNombre.Font = Enum.Font.Gotham
inputNombre.PlaceholderText = "Ej: DragonSlayers"
inputNombre.ClearTextOnFocus = false
inputNombre.Parent = mainPanel

-- Label logo
local labelLogo = Instance.new("TextLabel")
labelLogo.Name = "LabelLogo"
labelLogo.Size = UDim2.new(1, -20, 0, 25)
labelLogo.Position = UDim2.new(0, 10, 0, 120)
labelLogo.BackgroundTransparency = 1
labelLogo.Text = "Asset ID Logo (opcional):"
labelLogo.TextColor3 = Color3.fromRGB(200, 200, 200)
labelLogo.TextSize = 14
labelLogo.Font = Enum.Font.Gotham
labelLogo.TextXAlignment = Enum.TextXAlignment.Left
labelLogo.Parent = mainPanel

-- Input logo
local inputLogo = Instance.new("TextBox")
inputLogo.Name = "InputLogo"
inputLogo.Size = UDim2.new(1, -20, 0, 30)
inputLogo.Position = UDim2.new(0, 10, 0, 145)
inputLogo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
inputLogo.BorderColor3 = Color3.fromRGB(100, 100, 100)
inputLogo.BorderSizePixel = 1
inputLogo.Text = ""
inputLogo.TextColor3 = Color3.fromRGB(255, 255, 255)
inputLogo.TextSize = 14
inputLogo.Font = Enum.Font.Gotham
inputLogo.PlaceholderText = "rbxassetid://12345"
inputLogo.ClearTextOnFocus = false
inputLogo.Parent = mainPanel

-- Botón Crear
local btnCrear = Instance.new("TextButton")
btnCrear.Name = "BtnCrear"
btnCrear.Size = UDim2.new(0, 180, 0, 35)
btnCrear.Position = UDim2.new(0, 10, 0, 250)
btnCrear.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
btnCrear.BorderSizePixel = 0
btnCrear.Text = "Crear Clan"
btnCrear.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCrear.TextSize = 16
btnCrear.Font = Enum.Font.GothamBold
btnCrear.Parent = mainPanel

-- Botón Cancelar
local btnCancelar = Instance.new("TextButton")
btnCancelar.Name = "BtnCancelar"
btnCancelar.Size = UDim2.new(0, 180, 0, 35)
btnCancelar.Position = UDim2.new(0, 200, 0, 250)
btnCancelar.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
btnCancelar.BorderSizePixel = 0
btnCancelar.Text = "Cancelar"
btnCancelar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCancelar.TextSize = 16
btnCancelar.Font = Enum.Font.GothamBold
btnCancelar.Parent = mainPanel

-- Eventos
btnCrear.MouseButton1Click:Connect(function()
local clanName = inputNombre.Text
local clanLogo = inputLogo.Text ~= "" and inputLogo.Text or "rbxassetid://0"

if clanName == "" then
print("Por favor ingresa un nombre para el clan")
return
end

ClanClient:CreateClan(clanName, clanLogo)
screenGui:Destroy()
print("Clan creado: " .. clanName)
end)

btnCancelar.MouseButton1Click:Connect(function()
screenGui:Destroy()
end)

-- Efectos hover
local function hoverEffect(button, originalColor)
button.MouseEnter:Connect(function()
button.BackgroundColor3 = Color3.fromRGB(
math.min(originalColor.R * 255 + 30, 255),
math.min(originalColor.G * 255 + 30, 255),
math.min(originalColor.B * 255 + 30, 255)
) / 255
end)

button.MouseLeave:Connect(function()
button.BackgroundColor3 = originalColor
end)
end

hoverEffect(btnCrear, Color3.fromRGB(0, 150, 100))
hoverEffect(btnCancelar, Color3.fromRGB(150, 0, 0))
