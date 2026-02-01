-- ════════════════════════════════════════════════════════════════
-- COMBAT CLIENT - Sistema completo de combate con Ring
-- Integración de Punch system con Ring verification
-- ════════════════════════════════════════════════════════════════

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("⚙️ CombatClient iniciando...")

-- Obtener remotes desde RemotesGlobal
print("🔍 Buscando RemotesGlobal...")
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
print("✓ RemotesGlobal encontrado")

print("🔍 Buscando carpeta Combat...")
local CombatRemotes = RemotesGlobal:WaitForChild("Combat")
print("✓ Combat encontrado")

print("🔍 Buscando PunchRemote...")
local eventPunch = CombatRemotes:WaitForChild("PunchRemote")
print("✓ PunchRemote encontrado")

print("🔍 Buscando BlockRemote...")
local eventBlock = CombatRemotes:WaitForChild("BlockRemote")
print("✓ BlockRemote encontrado")

print("🔍 Buscando RingNotification...")
local ringNotificationRemote = CombatRemotes:WaitForChild("RingNotification")
print("✓ RingNotification encontrado")

print("🔍 Cargando NotificationSystem...")
-- Cargar NotificationSystem
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
print("✓ NotificationSystem cargado")


local COOLDOWN = 0.8
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid")
local rootPart = character:FindFirstChild("HumanoidRootPart")
local inRing = false
local aux = true

-- Actualizar referencias cuando muere o respawnea
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:FindFirstChild("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")
	aux = true
end)

-- Crear animaciones con IDs directos
local animPunchR = Instance.new("Animation")
animPunchR.AnimationId = "rbxassetid://73048975017223"

local animPunchL = Instance.new("Animation")
animPunchL.AnimationId = "rbxassetid://92479079749990"

local animBlock = Instance.new("Animation")
animBlock.AnimationId = "rbxassetid://125626942999742"

local animKick = Instance.new("Animation")
animKick.AnimationId = "rbxassetid://75034297494695"

print("✓ Animaciones cargadas con IDs directos")

-- Efecto rojo de golpe en la cámara (salpicadura)
local redFlashGui = Instance.new("ScreenGui")
redFlashGui.Name = "RedFlash"
redFlashGui.ResetOnSpawn = false
redFlashGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local redFlash = Instance.new("Frame")
redFlash.Name = "RedSplash"
redFlash.Size = UDim2.new(0, 150, 0, 150)
redFlash.Position = UDim2.new(0.5, -75, 0.5, -75)  -- Centro de la pantalla
redFlash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
redFlash.BackgroundTransparency = 1
redFlash.BorderSizePixel = 0
redFlash.ZIndex = 99
redFlash.Parent = redFlashGui

-- Hacer redonda la salpicadura
local splashCorner = Instance.new("UICorner")
splashCorner.CornerRadius = UDim.new(1, 0)
splashCorner.Parent = redFlash

-- Escuchar notificación del ring
local lastRingStatus = false
ringNotificationRemote.OnClientEvent:Connect(function(ringStatus)
	-- Solo mostrar notificación cuando cambia el estado
	if ringStatus ~= lastRingStatus then
		if ringStatus then
			NotificationSystem:Info("Ring", "Has ingresado al ring", 3)
		else
			NotificationSystem:Info("Ring", "Has salido del ring", 3)
		end
		lastRingStatus = ringStatus
	end
	inRing = ringStatus  -- Guardar estado del ring
end)

-- Función para efecto rojo de golpe
local function punchEffect()
	-- Rojo intenso en el centro 0.05 segundos
	local tween = TweenService:Create(redFlash, TweenInfo.new(0.05), {BackgroundTransparency = 0.3})
	tween:Play()
	tween.Completed:Connect(function()
		-- Desvanece lentamente en 0.3 segundos
		local tweenBack = TweenService:Create(redFlash, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		tweenBack:Play()
	end)
end

-- Función para detectar botones de combate
function fightButton(actionName, inputState, inputObject)
	print("🎮 Botón presionado:", actionName, "Estado:", inputState)
	-- if not inRing then return end  -- Solo funciona en el ring (deshabilitado para permitir prácticas)
	if not humanoid or humanoid.Health <= 0 then 
		print("❌ Humanoid no disponible o muerto")
		return 
	end
	
	if actionName == "leftPunch" then
		print("👊 Golpe izquierdo detectado")
		if inputState == Enum.UserInputState.Begin and aux then
			print("➡️ Iniciando golpe izquierdo...")
			aux = false
			if animPunchL then
				local anim = humanoid:LoadAnimation(animPunchL)
				anim:Play()
				print("🎬 Animación de golpe izquierdo reproducida")
			else
				print("⚠️ Animación de golpe izquierdo no disponible")
			end
			eventPunch:FireServer(1, true)
			print("📡 Evento enviado al servidor")
			punchEffect()
			task.wait(COOLDOWN)
			aux = true
		end
	elseif actionName == "rightPunch" then
		print("👊 Golpe derecho detectado")
		if inputState == Enum.UserInputState.Begin and aux then
			print("➡️ Iniciando golpe derecho...")
			aux = false
			if animPunchR then
				local anim = humanoid:LoadAnimation(animPunchR)
				anim:Play()
				print("🎬 Animación de golpe derecho reproducida")
			else
				print("⚠️ Animación de golpe derecho no disponible")
			end
			eventPunch:FireServer(0, true)
			print("📡 Evento enviado al servidor")
			punchEffect()
			task.wait(COOLDOWN)
			aux = true
		end
	elseif actionName == "block" then
		if inputState == Enum.UserInputState.Begin and aux then
			aux = false
			if animBlock then
				local anim = humanoid:LoadAnimation(animBlock)
				anim:Play()
				task.wait(COOLDOWN)
				eventBlock:FireServer(true)
				task.wait(COOLDOWN)
				eventBlock:FireServer(false)
				anim:Stop()
			else
				eventBlock:FireServer(true)
				task.wait(COOLDOWN)
				eventBlock:FireServer(false)
			end
			aux = true
		end
	elseif actionName == "Patada" then
		if inputState == Enum.UserInputState.Begin and aux then
			aux = false
			if animKick then
				local anim = humanoid:LoadAnimation(animKick)
				anim:Play()
			end
			eventPunch:FireServer(2, true)
			punchEffect()
			task.wait(COOLDOWN)
			aux = true
		end
	end
end

-- Registrar botones de combate
ContextActionService:BindAction("leftPunch", fightButton, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
ContextActionService:BindAction("rightPunch", fightButton, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
ContextActionService:BindAction("block", fightButton, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("Patada", fightButton, true, Enum.KeyCode.R, Enum.KeyCode.ButtonB)

ContextActionService:SetTitle("leftPunch", "Q")
ContextActionService:SetTitle("rightPunch", "E")
ContextActionService:SetTitle("block", "F")
ContextActionService:SetTitle("Patada", "R")

ContextActionService:SetPosition("leftPunch", UDim2.new(-0.1, 0, 0.4, 0))
ContextActionService:SetPosition("rightPunch", UDim2.new(0.2, 0, 0.4, 0))
ContextActionService:SetPosition("block", UDim2.new(0.05, 0, 0.1, 0))
ContextActionService:SetPosition("Patada", UDim2.new(0.05, 0, 0.7, 0))

