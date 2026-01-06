local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que ClanClient esté disponible
local ClanClient = require(ReplicatedStorage:WaitForChild("ClanClient"))

-- Crear botón de CLAN en la parte superior (similar a MUSIC)
local topGui = playerGui:FindFirstChild("TopButtonsGui") or Instance.new("ScreenGui")
if not playerGui:FindFirstChild("TopButtonsGui") then
	topGui.Name = "TopButtonsGui"
	topGui.ResetOnSpawn = false
	topGui.Parent = playerGui
end

local clanButton = Instance.new("TextButton")
clanButton.Name = "ClanButton"
clanButton.Size = UDim2.new(0, 100, 0, 40)
clanButton.Position = UDim2.new(0, 350, 0, 10)
clanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
clanButton.BorderSizePixel = 0
clanButton.Text = "CLAN"
clanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clanButton.TextSize = 16
clanButton.Font = Enum.Font.GothamBold
clanButton.Parent = topGui

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
)
end)

button.MouseLeave:Connect(function()
button.BackgroundColor3 = originalColor
end)
end

hoverEffect(btnCrear, Color3.fromRGB(0, 150, 100))
hoverEffect(btnCancelar, Color3.fromRGB(150, 0, 0))

-- Evento del botón CLAN
local panelOpen = false
clanButton.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	
	if panelOpen then
		-- Mostrar modal de clanes
		local clansModal = Instance.new("ScreenGui")
		clansModal.Name = "ClansModal"
		clansModal.ResetOnSpawn = false
		clansModal.Parent = playerGui
		
		-- Fondo oscuro
		local darkBg = Instance.new("Frame")
		darkBg.Size = UDim2.new(1, 0, 1, 0)
		darkBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		darkBg.BackgroundTransparency = 0.7
		darkBg.BorderSizePixel = 0
		darkBg.Parent = clansModal
		
		-- Panel modal
		local modalPanel = Instance.new("Frame")
		modalPanel.Size = UDim2.new(0, 600, 0, 500)
		modalPanel.Position = UDim2.new(0.5, -300, 0.5, -250)
		modalPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		modalPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
		modalPanel.BorderSizePixel = 2
		modalPanel.Parent = clansModal
		
		-- Título
		local titleModal = Instance.new("TextLabel")
		titleModal.Size = UDim2.new(1, 0, 0, 50)
		titleModal.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
		titleModal.BorderSizePixel = 0
		titleModal.Text = "Clanes Disponibles"
		titleModal.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleModal.TextSize = 24
		titleModal.Font = Enum.Font.GothamBold
		titleModal.Parent = modalPanel
		
		-- Cerrar botón
		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.new(0, 40, 0, 40)
		closeBtn.Position = UDim2.new(1, -45, 0, 5)
		closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		closeBtn.BorderSizePixel = 0
		closeBtn.Text = "X"
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeBtn.TextSize = 20
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.Parent = modalPanel
		
		closeBtn.MouseButton1Click:Connect(function()
			clansModal:Destroy()
			panelOpen = false
			clanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
		end)
		
		-- ScrollingFrame de clanes
		local clansList = Instance.new("ScrollingFrame")
		clansList.Size = UDim2.new(1, -20, 1, -80)
		clansList.Position = UDim2.new(0, 10, 0, 60)
		clansList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		clansList.BorderColor3 = Color3.fromRGB(80, 80, 80)
		clansList.BorderSizePixel = 1
		clansList.ScrollingDirection = Enum.ScrollingDirection.Y
		clansList.CanvasSize = UDim2.new(0, 0, 0, 0)
		clansList.Parent = modalPanel
		
		-- Mensaje por ahora
		local msgLabel = Instance.new("TextLabel")
		msgLabel.Size = UDim2.new(1, 0, 1, 0)
		msgLabel.BackgroundTransparency = 1
		msgLabel.Text = "Haz clic en 'Crear Clan' para crear uno nuevo"
		msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		msgLabel.TextSize = 16
		msgLabel.Font = Enum.Font.Gotham
		msgLabel.Parent = clansList
		
		-- Botón para crear clan
		local btnCreateClan = Instance.new("TextButton")
		btnCreateClan.Size = UDim2.new(0.9, 0, 0, 40)
		btnCreateClan.Position = UDim2.new(0.05, 0, 1, -50)
		btnCreateClan.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
		btnCreateClan.BorderSizePixel = 0
		btnCreateClan.Text = "Crear Nuevo Clan"
		btnCreateClan.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnCreateClan.TextSize = 16
		btnCreateClan.Font = Enum.Font.GothamBold
		btnCreateClan.Parent = modalPanel
		
		btnCreateClan.MouseButton1Click:Connect(function()
			clansModal:Destroy()
			-- Crear nuevo formulario de crear clan
			local createGui = Instance.new("ScreenGui")
			createGui.Name = "CreateClanGuiForm"
			createGui.ResetOnSpawn = false
			createGui.Parent = playerGui
			
			-- Copiar el contenido de screenGui al nuevo
			for _, child in pairs(screenGui:GetChildren()) do
				local clone = child:Clone()
				clone.Parent = createGui
			end
			
			createGui.MainPanel.Visible = true
		end)
		
		clanButton.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
	else
		-- Cerrar modal
		local existingModal = playerGui:FindFirstChild("ClansModal")
		if existingModal then
			existingModal:Destroy()
		end
		clanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	end
end)

clanButton.MouseEnter:Connect(function()
	clanButton.BackgroundColor3 = Color3.fromRGB(0, 180, 130)
end)

clanButton.MouseLeave:Connect(function()
	if not panelOpen then
		clanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	end
end)
