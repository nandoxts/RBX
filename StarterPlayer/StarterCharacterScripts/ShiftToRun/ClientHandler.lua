-- // Servicios
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- // Variables de estado
local isRunning = false
local isShiftActive = false
local speedButton = nil
local cameraConnection = nil

-- // Configuración de cámara para SHIFT
local NORMAL_FOV = 70
local SHIFT_FOV = 90
local CAMERA_TILT = 15 -- Inclinación hacia adelante en grados

-- // Función para activar animación de cámara SHIFT
local function activateShiftCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end

	local startFOV = camera.FieldOfView
	local targetFOV = SHIFT_FOV
	local lerpSpeed = 0.08

	cameraConnection = RunService.RenderStepped:Connect(function()
		if isShiftActive and camera then
			-- Transición suave del FOV
			local newFOV = startFOV + (targetFOV - startFOV) * lerpSpeed
			camera.FieldOfView = newFOV
			startFOV = newFOV
		end
	end)
end

-- // Función para desactivar animación de cámara SHIFT
local function deactivateShiftCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	-- Restaurar FOV de forma suave
	local startFOV = camera.FieldOfView
	local targetFOV = NORMAL_FOV
	local lerpSpeed = 0.06

	cameraConnection = RunService.RenderStepped:Connect(function()
		if not isShiftActive and camera then
			local newFOV = startFOV + (targetFOV - startFOV) * lerpSpeed
			camera.FieldOfView = newFOV
			startFOV = newFOV

			-- Si casi llegamos al FOV normal, desconectar
			if math.abs(newFOV - NORMAL_FOV) < 0.5 then
				camera.FieldOfView = NORMAL_FOV
				cameraConnection:Disconnect()
				cameraConnection = nil
			end
		end
	end)
end

-- // CREAR BOTÓN PARA MÓVIL (SHIFT)
local speedButtonGui = nil  -- Referencia al ScreenGui específico

local function createMobileButton()
	if speedButton then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedBoostGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	speedButtonGui = screenGui  -- Guardar referencia

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

	-- Eventos del botón SHIFT
	speedButton.MouseButton1Down:Connect(function()
		-- Si Q está activo, desactivarlo
		if isRunning then
			isRunning = false
			script.Parent.ServerHandler.Run:FireServer("RunDisable")
		end
		isShiftActive = true
		script.Parent.ServerHandler.Run:FireServer("ShiftActive")
		activateShiftCamera()
		speedButton.BackgroundTransparency = 0.3
	end)

	speedButton.MouseButton1Up:Connect(function()
		isShiftActive = false
		script.Parent.ServerHandler.Run:FireServer("ShiftDisable")
		deactivateShiftCamera()
		speedButton.BackgroundTransparency = 0.5
	end)
end

-- Crear botón si es móvil
if UserInputService.TouchEnabled then
	createMobileButton()
else
	print("Sistema de velocidad cargado")
end

-- // Detectar teclas (Q y SHIFT - SOLO PC)
UserInputService.InputBegan:Connect(function(key, processed)
	-- Respetar teclas procesadas por otros sistemas (TOPBAR, chat, etc)
	if processed then return end
	-- Solo procesar si NO hay botón móvil activo
	if not speedButton then
		-- Q para correr
		if key.KeyCode == Enum.KeyCode.Q then
			-- Si SHIFT está activo, desactivarlo
			if isShiftActive then
				isShiftActive = false
				script.Parent.ServerHandler.Run:FireServer("ShiftDisable")
			end
			isRunning = not isRunning
			if isRunning then
				script.Parent.ServerHandler.Run:FireServer("RunActive")
			else
				script.Parent.ServerHandler.Run:FireServer("RunDisable")
			end
		end
		-- SHIFT para velocidad rápida
		if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
			-- Si Q está activo, desactivarlo
			if isRunning then
				isRunning = false
				script.Parent.ServerHandler.Run:FireServer("RunDisable")
			end
			isShiftActive = true
			script.Parent.ServerHandler.Run:FireServer("ShiftActive")
			activateShiftCamera()
		end
	end
end)

UserInputService.InputEnded:Connect(function(key, processed)
	-- Solo procesar si NO hay botón móvil activo
	if not speedButton then
		-- SHIFT soltar
		if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
			isShiftActive = false
			script.Parent.ServerHandler.Run:FireServer("ShiftDisable")
			deactivateShiftCamera()
		end
	end
end)

-- Detectar cambio entre PC y Móvil
UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
	if lastInputType == Enum.UserInputType.Touch and not speedButton then
		createMobileButton()
	elseif lastInputType ~= Enum.UserInputType.Touch and speedButton then
		-- Solo destruir el ScreenGui específico del botón SHIFT
		if speedButtonGui and speedButtonGui.Parent then
			speedButtonGui:Destroy()
		end
		speedButtonGui = nil
		speedButton = nil
	end
end)
