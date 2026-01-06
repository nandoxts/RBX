wait(1) -- Esperar a que el juego cargue completamente

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que ClanClient esté disponible
local ClanClient = require(ReplicatedStorage:WaitForChild("ClanClient"))

-- Crear ScreenGui principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Panel principal (al lado izquierdo)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 500, 0, 600)
mainPanel.Position = UDim2.new(0, 20, 0.5, -300)
mainPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
mainPanel.BorderSizePixel = 2
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
title.BorderSizePixel = 0
title.Text = "Mi Clan"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.Parent = mainPanel

-- Cerrar botón
local btnClose = Instance.new("TextButton")
btnClose.Name = "CloseBtn"
btnClose.Size = UDim2.new(0, 40, 0, 40)
btnClose.Position = UDim2.new(1, -45, 0, 5)
btnClose.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
btnClose.BorderSizePixel = 0
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClose.TextSize = 20
btnClose.Font = Enum.Font.GothamBold
btnClose.Parent = mainPanel

btnClose.MouseButton1Click:Connect(function()
mainPanel.Visible = false
end)

-- ScrollingFrame para miembros
local scrollMembers = Instance.new("ScrollingFrame")
scrollMembers.Name = "MembersScroll"
scrollMembers.Size = UDim2.new(1, -20, 0, 300)
scrollMembers.Position = UDim2.new(0, 10, 0, 70)
scrollMembers.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollMembers.BorderColor3 = Color3.fromRGB(80, 80, 80)
scrollMembers.BorderSizePixel = 1
scrollMembers.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollMembers.ScrollingDirection = Enum.ScrollingDirection.Y
scrollMembers.Parent = mainPanel

-- Título Miembros
local titleMembers = Instance.new("TextLabel")
titleMembers.Name = "TitleMembers"
titleMembers.Size = UDim2.new(1, 0, 0, 25)
titleMembers.Position = UDim2.new(0, 0, 0, 55)
titleMembers.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleMembers.BorderSizePixel = 0
titleMembers.Text = "Miembros (" .. "0" .. ")"
titleMembers.TextColor3 = Color3.fromRGB(200, 200, 200)
titleMembers.TextSize = 14
titleMembers.Font = Enum.Font.GothamBold
titleMembers.Parent = mainPanel

-- Panel de información
local infoPanel = Instance.new("Frame")
infoPanel.Name = "InfoPanel"
infoPanel.Size = UDim2.new(1, -20, 0, 120)
infoPanel.Position = UDim2.new(0, 10, 0, 380)
infoPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
infoPanel.BorderColor3 = Color3.fromRGB(80, 80, 80)
infoPanel.BorderSizePixel = 1
infoPanel.Parent = mainPanel

-- Descripción label
local descLabel = Instance.new("TextLabel")
descLabel.Name = "DescLabel"
descLabel.Size = UDim2.new(1, -10, 0, 20)
descLabel.Position = UDim2.new(0, 5, 0, 5)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Descripción:"
descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
descLabel.TextSize = 12
descLabel.Font = Enum.Font.GothamBold
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.Parent = infoPanel

-- Descripción texto
local descText = Instance.new("TextLabel")
descText.Name = "DescText"
descText.Size = UDim2.new(1, -10, 0, 50)
descText.Position = UDim2.new(0, 5, 0, 25)
descText.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
descText.BorderColor3 = Color3.fromRGB(60, 60, 60)
descText.BorderSizePixel = 1
descText.Text = "Descripción del clan"
descText.TextColor3 = Color3.fromRGB(150, 150, 150)
descText.TextSize = 11
descText.Font = Enum.Font.Gotham
descText.TextWrapped = true
descText.Parent = infoPanel

-- Botones inferiores
local btnContainer = Instance.new("Frame")
btnContainer.Name = "ButtonContainer"
btnContainer.Size = UDim2.new(1, -20, 0, 50)
btnContainer.Position = UDim2.new(0, 10, 0, 520)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = mainPanel

-- Botón Invitar
local btnInvitar = Instance.new("TextButton")
btnInvitar.Name = "BtnInvitar"
btnInvitar.Size = UDim2.new(0.45, 0, 1, 0)
btnInvitar.Position = UDim2.new(0, 0, 0, 0)
btnInvitar.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
btnInvitar.BorderSizePixel = 0
btnInvitar.Text = "Invitar"
btnInvitar.TextColor3 = Color3.fromRGB(255, 255, 255)
btnInvitar.TextSize = 14
btnInvitar.Font = Enum.Font.GothamBold
btnInvitar.Parent = btnContainer

-- Botón Configurar
local btnConfig = Instance.new("TextButton")
btnConfig.Name = "BtnConfig"
btnConfig.Size = UDim2.new(0.45, 0, 1, 0)
btnConfig.Position = UDim2.new(0.55, 0, 0, 0)
btnConfig.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
btnConfig.BorderSizePixel = 0
btnConfig.Text = "Configurar"
btnConfig.TextColor3 = Color3.fromRGB(255, 255, 255)
btnConfig.TextSize = 14
btnConfig.Font = Enum.Font.GothamBold
btnConfig.Parent = btnContainer

-- Función para mostrar miembros
local function displayMembers(clanData)
scrollMembers:ClearAllChildren()

if clanData and clanData.miembros_data then
local memberCount = 0

for userId, memberData in pairs(clanData.miembros_data) do
memberCount = memberCount + 1

local memberFrame = Instance.new("Frame")
memberFrame.Name = "Member_" .. userId
memberFrame.Size = UDim2.new(1, 0, 0, 40)
memberFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
memberFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
memberFrame.BorderSizePixel = 1
memberFrame.LayoutOrder = memberCount
memberFrame.Parent = scrollMembers

-- Nombre y rol
local memberLabel = Instance.new("TextLabel")
memberLabel.Size = UDim2.new(0.6, 0, 1, 0)
memberLabel.Position = UDim2.new(0, 5, 0, 0)
memberLabel.BackgroundTransparency = 1
memberLabel.Text = memberData.nombre .. " [" .. string.upper(memberData.rol) .. "]"
memberLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
memberLabel.TextSize = 12
memberLabel.Font = Enum.Font.Gotham
memberLabel.TextXAlignment = Enum.TextXAlignment.Left
memberLabel.Parent = memberFrame

-- Botón acciones
if userId ~= player.UserId then
local btnAccion = Instance.new("TextButton")
btnAccion.Size = UDim2.new(0.35, -5, 0.8, 0)
btnAccion.Position = UDim2.new(0.65, 0, 0.1, 0)
btnAccion.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
btnAccion.BorderSizePixel = 0
btnAccion.Text = "Expulsar"
btnAccion.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAccion.TextSize = 11
btnAccion.Font = Enum.Font.Gotham
btnAccion.Parent = memberFrame

btnAccion.MouseButton1Click:Connect(function()
ClanClient:KickPlayer(userId)
wait(0.5)
ClanClient:RefreshClanData()
end)
end
end

titleMembers.Text = "Miembros (" .. memberCount .. ")"
scrollMembers.CanvasSize = UDim2.new(0, 0, 0, memberCount * 45)
end
end

-- Mostrar panel
function ClanClient:ShowPanel(clanData)
if clanData then
self.currentClan = clanData
self.currentClanId = clanData.clanId

title.Text = clanData.clanName
descText.Text = clanData.descripcion or "Sin descripción"

displayMembers(clanData)
mainPanel.Visible = true
end
end

print("Panel de clan cargado")
