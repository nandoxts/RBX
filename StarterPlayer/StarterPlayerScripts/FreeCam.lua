--[[
    FREECAM PRO - REPLICA DEL NATIVO DE STUDIO
    ACTIVAR: Solo desde servidor (RemoteEvent)
    DESACTIVAR: F6
    
    CONTROLES:
    WASD = Movimiento | E/Q = Subir/Bajar | Ctrl = Rápido | Alt = Lento
    RMB = Rotar | Scroll = Velocidad | Ctrl+Scroll = FOV | R = Reset FOV | F = Focus
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local CONFIG = {
	ExitKey = Enum.KeyCode.F6,
	BaseSpeed = 2,           -- Velocidad aumentada
	SpeedMin = 0.5,
	SpeedMax = 20,
	FastMultiplier = 3,
	SlowMultiplier = 0.3,
	PanSensitivity = 0.25,
	MovementSmoothing = 0.9,
	RotationSmoothing = 0.75,
	DefaultFOV = 70,
	MinFOV = 10,
	MaxFOV = 120,
	FOVStep = 5,
}

local State = {
	Active = false,
	OriginalCameraType = nil,
	OriginalCameraSubject = nil,
	OriginalCFrame = nil,
	OriginalFOV = nil,
	Velocity = Vector3.new(0, 0, 0),
	AngularVelocity = Vector2.new(0, 0),
	MoveInput = Vector3.new(0, 0, 0),
	RotateInput = Vector2.new(0, 0),
	CurrentSpeed = CONFIG.BaseSpeed,
	CurrentFOV = CONFIG.DefaultFOV,
	IsRotating = false,
	CtrlHeld = false,
	AltHeld = false,
	CharacterConnection = nil,
	HiddenGuis = {},
}

-- Ocultar todas las UIs
local function HideGuis()
	State.HiddenGuis = {}
	
	-- Ocultar PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled then
			State.HiddenGuis[gui] = true
			gui.Enabled = false
		end
	end
	
	-- Ocultar CoreGuis
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)
end

-- Mostrar UIs de nuevo
local function ShowGuis()
	-- Restaurar PlayerGui
	for gui, _ in pairs(State.HiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	State.HiddenGuis = {}
	
	-- Restaurar CoreGuis
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
	end)
end

-- Desactivar control del personaje
local function DisableCharacter()
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Detener cualquier movimiento
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
		
		-- Anclar el personaje para que no caiga
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.Anchored = true
		end
	end
end

-- Reactivar control del personaje
local function EnableCharacter()
	if not player.Character then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Restaurar valores normales
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
		humanoid.AutoRotate = true
		
		-- Desanclar el personaje
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.Anchored = false
		end
	end
end

local function EnableFreeCam()
	if State.Active then return end
	State.Active = true

	State.OriginalCameraType = camera.CameraType
	State.OriginalCameraSubject = camera.CameraSubject
	State.OriginalCFrame = camera.CFrame
	State.OriginalFOV = camera.FieldOfView

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil
	State.CurrentFOV = camera.FieldOfView

	State.Velocity = Vector3.new(0, 0, 0)
	State.AngularVelocity = Vector2.new(0, 0)
	State.MoveInput = Vector3.new(0, 0, 0)
	
	-- Ocultar UIs y desactivar personaje
	HideGuis()
	DisableCharacter()
	
	print("[FreeCam] ✓ ACTIVADO - RMB para rotar | F6 para salir")
	print("[FreeCam] WASD=Mover | E/Q=Arriba/Abajo | Ctrl=Rápido | Scroll=Velocidad")
end

local function DisableFreeCam()
	if not State.Active then return end
	State.Active = false

	camera.CameraType = State.OriginalCameraType or Enum.CameraType.Custom
	camera.FieldOfView = State.OriginalFOV or CONFIG.DefaultFOV

	if State.OriginalCameraSubject then
		camera.CameraSubject = State.OriginalCameraSubject
	elseif player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	State.Velocity = Vector3.new(0, 0, 0)
	State.AngularVelocity = Vector2.new(0, 0)
	State.MoveInput = Vector3.new(0, 0, 0)
	State.IsRotating = false
	
	-- Restaurar UIs y personaje
	ShowGuis()
	EnableCharacter()
	
	print("[FreeCam] ✗ Desactivado")
end

local function FocusOnMouse()
	if not State.Active then return end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}

	local mouseRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 10000, raycastParams)

	if result then
		local targetPos = result.Position + result.Normal * 10
		local targetCFrame = CFrame.lookAt(targetPos, result.Position)
		TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCFrame
		}):Play()
	end
end

local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
	if not State.Active then return end

	local now = tick()
	local dt = now - lastUpdate
	lastUpdate = now

	local frameMultiplier = dt * 60

	-- Determinar multiplicador de velocidad
	local speedMultiplier = 1
	if State.CtrlHeld then
		speedMultiplier = CONFIG.FastMultiplier
	elseif State.AltHeld then
		speedMultiplier = CONFIG.SlowMultiplier
	end

	local finalSpeed = State.CurrentSpeed * speedMultiplier

	-- MOVIMIENTO: Convertir input local a dirección mundial
	if State.MoveInput.Magnitude > 0 then
		local camCF = camera.CFrame
		
		-- Vectores de dirección de la cámara
		local forward = camCF.LookVector
		local right = camCF.RightVector
		local up = Vector3.new(0, 1, 0)  -- Arriba siempre global
		
		-- Calcular movimiento en espacio mundo
		local worldMove = Vector3.new(0, 0, 0)
		worldMove = worldMove + (forward * -State.MoveInput.Z)  -- W/S (negativo porque -Z es adelante)
		worldMove = worldMove + (right * State.MoveInput.X)     -- A/D
		worldMove = worldMove + (up * State.MoveInput.Y)        -- E/Q
		
		-- Normalizar y aplicar velocidad
		if worldMove.Magnitude > 0 then
			worldMove = worldMove.Unit * finalSpeed * frameMultiplier
		end
		
		-- Aplicar con smoothing
		State.Velocity = State.Velocity:Lerp(worldMove, 0.3)
		camera.CFrame = camera.CFrame + State.Velocity
	else
		-- Desacelerar cuando no hay input
		State.Velocity = State.Velocity:Lerp(Vector3.new(0, 0, 0), 0.2)
		if State.Velocity.Magnitude > 0.001 then
			camera.CFrame = camera.CFrame + State.Velocity
		end
	end

	-- ROTACIÓN
	if State.AngularVelocity.Magnitude > 0.001 then
		local camCF = camera.CFrame
		local yawRotation = CFrame.Angles(0, -State.AngularVelocity.X, 0)
		local pitchRotation = CFrame.Angles(-State.AngularVelocity.Y, 0, 0)
		camera.CFrame = CFrame.new(camCF.Position) * yawRotation * camCF.Rotation * pitchRotation
	end
	
	State.AngularVelocity = State.AngularVelocity:Lerp(State.RotateInput, 1 - CONFIG.RotationSmoothing)
	State.RotateInput = Vector2.new(0, 0)
end)

UserInputService.InputChanged:Connect(function(input)
	if not State.Active then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement and State.IsRotating then
		local delta = input.Delta
		State.RotateInput = Vector2.new(delta.X * CONFIG.PanSensitivity * 0.01, delta.Y * CONFIG.PanSensitivity * 0.01)
	end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local scroll = input.Position.Z
		if State.CtrlHeld then
			State.CurrentFOV = math.clamp(State.CurrentFOV - scroll * CONFIG.FOVStep, CONFIG.MinFOV, CONFIG.MaxFOV)
			camera.FieldOfView = State.CurrentFOV
		else
			State.CurrentSpeed = math.clamp(State.CurrentSpeed + scroll * 0.2, CONFIG.SpeedMin, CONFIG.SpeedMax)
		end
	end
end)

local moveKeys = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1),  -- Adelante (hacia donde miras)
	[Enum.KeyCode.S] = Vector3.new(0, 0, 1),   -- Atrás
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),  -- Izquierda
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),   -- Derecha
	[Enum.KeyCode.E] = Vector3.new(0, 1, 0),   -- Arriba
	[Enum.KeyCode.Q] = Vector3.new(0, -1, 0),  -- Abajo
}

local keysHeld = {}

local function UpdateMoveInput()
	local input = Vector3.new(0, 0, 0)
	for keyCode, direction in pairs(moveKeys) do
		if keysHeld[keyCode] then
			input = input + direction
		end
	end
	State.MoveInput = input
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Salir del free cam con F6 incluso si está procesado
	if input.KeyCode == CONFIG.ExitKey and State.Active then
		DisableFreeCam()
		return
	end

	-- Si el free cam está activo, bloquear atajos de teclado del sistema
	if State.Active then
		-- Bloquear Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X, etc.
		if State.CtrlHeld and input.KeyCode == Enum.KeyCode.A then
			return -- Bloquear "Seleccionar todo"
		end
		if State.CtrlHeld and input.KeyCode == Enum.KeyCode.C then
			return -- Bloquear "Copiar"
		end
		if State.CtrlHeld and input.KeyCode == Enum.KeyCode.V then
			return -- Bloquear "Pegar"
		end
		if State.CtrlHeld and input.KeyCode == Enum.KeyCode.X then
			return -- Bloquear "Cortar"
		end
	end

	if not State.Active then return end

	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		State.CtrlHeld = true
	end

	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		State.AltHeld = true
	end

	if moveKeys[input.KeyCode] then
		keysHeld[input.KeyCode] = true
		UpdateMoveInput()
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		State.IsRotating = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end

	if input.KeyCode == Enum.KeyCode.R then
		State.CurrentFOV = CONFIG.DefaultFOV
		camera.FieldOfView = CONFIG.DefaultFOV
	end

	if input.KeyCode == Enum.KeyCode.F and not gameProcessed then
		FocusOnMouse()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		State.CtrlHeld = false
	end

	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		State.AltHeld = false
	end

	if moveKeys[input.KeyCode] then
		keysHeld[input.KeyCode] = false
		UpdateMoveInput()
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		State.IsRotating = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

task.spawn(function()
	while true do
		local remote = ReplicatedStorage:FindFirstChild("FreeCamToggle")
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(EnableFreeCam)
			print("[FreeCam] ✓ Script cargado correctamente")
			break
		end
		task.wait(1)
	end
end)

player.CharacterAdded:Connect(function(character)
	if State.Active then
		-- Desactivar y volver a activar después de que el personaje esté listo
		DisableFreeCam()
		task.wait(0.5)
		EnableFreeCam()
	end
end)