--[[
DANCE LEADER UI CLIENT - MEJORADO
Muestra un billboard/UI encima del jugador cuando es Dance Leader
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local Emotes_Sync = ReplicatedStorage:WaitForChild("Emotes_Sync")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Esperar a que el RemoteEvent esté disponible
local DanceLeaderEvent
local maxWaitTime = 10  -- Esperar máximo 10 segundos
local elapsedTime = 0

while not DanceLeaderEvent and elapsedTime < maxWaitTime do
	DanceLeaderEvent = Emotes_Sync:FindFirstChild("DanceLeaderEvent")
	if DanceLeaderEvent then break end
	wait(0.2)
	elapsedTime = elapsedTime + 0.2
end

if not DanceLeaderEvent then
	warn("[DanceLeaderUI] No se pudo encontrar DanceLeaderEvent después de " .. maxWaitTime .. " segundos")
	warn("[DanceLeaderUI] Verificar que DanceLeaderEvent está en Panda ReplicatedStorage > Emotes_Sync")
	return
end

-- Billboard cache para líderes de danza
local DanceLeaderBillboards = {}

-- Crear billboard para un Dance Leader
local function CreateDanceLeaderBillboard(targetPlayer)
if not targetPlayer or not targetPlayer.Character then return end

-- Si ya existe, removerlo
if DanceLeaderBillboards[targetPlayer] then
if DanceLeaderBillboards[targetPlayer].connection then
DanceLeaderBillboards[targetPlayer].connection:Disconnect()
end
if DanceLeaderBillboards[targetPlayer].billboard then
DanceLeaderBillboards[targetPlayer].billboard:Destroy()
end
end

local character = targetPlayer.Character
local head = character:FindFirstChild("Head")
if not head then return end

-- Crear BillboardGui
local billboard = Instance.new("BillboardGui")
billboard.Name = "DanceLeaderBillboard"
billboard.Size = UDim2.new(5, 0, 3, 0)
billboard.MaxDistance = 250
billboard.StudsOffset = Vector3.new(0, 4, 0)
billboard.Parent = head

-- Frame principal con fondo degradado
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = billboard

-- Esquinas redondeadas
local cornerRadius = Instance.new("UICorner")
cornerRadius.CornerRadius = UDim.new(0, 12)
cornerRadius.Parent = mainFrame

-- Borde exterior dorado
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(255, 215, 0)
outerStroke.Thickness = 3
outerStroke.Transparency = 0.1
outerStroke.Parent = mainFrame

-- Label de corona (emoji)
local crownLabel = Instance.new("TextLabel")
crownLabel.Name = "Crown"
crownLabel.Size = UDim2.new(1, 0, 0.25, 0)
crownLabel.Position = UDim2.new(0, 0, 0, 0)
crownLabel.BackgroundTransparency = 1
crownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
crownLabel.TextSize = 18
crownLabel.Font = Enum.Font.GothamBold
crownLabel.Text = "���"
crownLabel.Parent = mainFrame

-- Label principal
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
titleLabel.Position = UDim2.new(0, 0, 0.2, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "DANCE LEADER"
titleLabel.TextScaled = true
titleLabel.Parent = mainFrame

-- Label de nombre
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "Name"
nameLabel.Size = UDim2.new(1, -4, 0.35, 0)
nameLabel.Position = UDim2.new(0, 2, 0.6, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
nameLabel.TextSize = 12
nameLabel.Font = Enum.Font.Gotham
nameLabel.Text = targetPlayer.Name
nameLabel.TextScaled = true
nameLabel.TextWrapped = true
nameLabel.Parent = mainFrame

-- Efecto de escala suave (pulse)
local scaleValue = 1
local scaleDirection = 1
local scaleConnection = RunService.RenderStepped:Connect(function()
scaleValue = scaleValue + (0.008 * scaleDirection)
if scaleValue >= 1.1 then
scaleDirection = -1
elseif scaleValue <= 0.95 then
scaleDirection = 1
end
mainFrame.Size = UDim2.new(scaleValue, 0, scaleValue, 0)
end)

DanceLeaderBillboards[targetPlayer] = {
billboard = billboard,
connection = scaleConnection
}
end

-- Remover billboard de un Dance Leader
local function RemoveDanceLeaderBillboard(targetPlayer)
if DanceLeaderBillboards[targetPlayer] then
local data = DanceLeaderBillboards[targetPlayer]
if data.connection then
data.connection:Disconnect()
end
if data.billboard then
data.billboard:Destroy()
end
DanceLeaderBillboards[targetPlayer] = nil
end
end

-- Conectar al evento del servidor
DanceLeaderEvent.OnClientEvent:Connect(function(action, ...)
if action == "setLeader" then
local isLeader = (...)
if isLeader then
CreateDanceLeaderBillboard(player)
else
RemoveDanceLeaderBillboard(player)
end
elseif action == "leaderAdded" then
local targetPlayer = (...)
if targetPlayer ~= player then
CreateDanceLeaderBillboard(targetPlayer)
end
elseif action == "leaderRemoved" then
local targetPlayer = (...)
RemoveDanceLeaderBillboard(targetPlayer)
end
end)

-- Limpiar cuando el jugador se va
player.CharacterRemoving:Connect(function()
for _, data in pairs(DanceLeaderBillboards) do
if data.connection then
data.connection:Disconnect()
end
if data.billboard then
data.billboard:Destroy()
end
end
DanceLeaderBillboards = {}
end)

print("[DanceLeaderUI] Sistema de Dance Leader activado")
