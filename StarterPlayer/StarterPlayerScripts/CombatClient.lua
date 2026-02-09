-- ════════════════════════════════════════════════════════════════
-- COMBAT CLIENT - Sistema completo de combate con Ring
-- Integración de Punch system con Ring verification
-- ════════════════════════════════════════════════════════════════

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Obtener remotes desde RemotesGlobal con manejo robusto
local function getRemotes()
	local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 30)
	if not RemotesGlobal then 
		error("[CombatClient] RemotesGlobal no encontrado después de 30s")
	end

	local CombatRemotes = RemotesGlobal:WaitForChild("Combat", 30)
	if not CombatRemotes then 
		error("[CombatClient] Carpeta Combat no encontrada")
	end

	local eventPunch = CombatRemotes:WaitForChild("PunchRemote", 30)
	local eventBlock = CombatRemotes:WaitForChild("BlockRemote", 30)
	local ringNotificationRemote = CombatRemotes:WaitForChild("RingNotification", 30)
	local effectRemote = CombatRemotes:WaitForChild("EffectRemote", 30)

	return {
		eventPunch = eventPunch,
		eventBlock = eventBlock,
		ringNotificationRemote = ringNotificationRemote,
		effectRemote = effectRemote
	}
end

local remotes = getRemotes()
local eventPunch = remotes.eventPunch
local eventBlock = remotes.eventBlock
local ringNotificationRemote = remotes.ringNotificationRemote
local effectRemote = remotes.effectRemote

-- Cargar NotificationSystem con manejo de errores
local NotificationSystem
pcall(function()
	NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems", 10):WaitForChild("NotificationSystem", 10):WaitForChild("NotificationSystem", 10))
end)

-- Inicializar variables de jugador
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid", 10)
local rootPart = character:WaitForChild("HumanoidRootPart", 10)

if not humanoid or not rootPart then
	error("[CombatClient] No se pudo obtener Humanoid o HumanoidRootPart")
end

local COOLDOWN = 0.8
local inRing = false
local aux = true
local punchCounter = 0  -- Contador para IDs únicos de golpes

-- Actualizar referencias cuando muere o respawnea
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 10)
	rootPart = character:WaitForChild("HumanoidRootPart", 10)
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
animKick.AnimationId = "rbxassetid://138408477594658"

-- Efecto rojo de golpe en la cámara (salpicadura) - MEJORADO
local redFlashGui = Instance.new("ScreenGui")
redFlashGui.Name = "RedFlash"
redFlashGui.ResetOnSpawn = false
redFlashGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local redFlash = Instance.new("Frame")
redFlash.Name = "RedSplash"
redFlash.Size = UDim2.new(0, 200, 0, 200)
redFlash.Position = UDim2.new(0.5, -100, 0.5, -100)  -- Centro de la pantalla
redFlash.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
redFlash.BackgroundTransparency = 1
redFlash.BorderSizePixel = 0
redFlash.ZIndex = 99
redFlash.Parent = redFlashGui

-- Hacer redonda la salpicadura
local splashCorner = Instance.new("UICorner")
splashCorner.CornerRadius = UDim.new(1, 0)
splashCorner.Parent = redFlash

-- Función para efecto rojo de golpe mejorado
local function punchEffect()
	-- Rojo más intenso y más grande
	local tween = TweenService:Create(redFlash, TweenInfo.new(0.08), {BackgroundTransparency = 0.2})
	tween:Play()
	tween.Completed:Connect(function()
		-- Desvanece rápido
		local tweenBack = TweenService:Create(redFlash, TweenInfo.new(0.25), {BackgroundTransparency = 1})
		tweenBack:Play()
	end)
end

-- Escuchar cuando el servidor envía confirmación de golpe
effectRemote.OnClientEvent:Connect(function()
	punchEffect()
end)

-- Función para detectar botones de combate
function fightButton(actionName, inputState, inputObject)
	if not inRing then return end  -- Solo funciona en el ring
	if not humanoid or humanoid.Health <= 0 then return end  -- Validar humanoid

	if actionName == "leftPunch" then
		if inputState == Enum.UserInputState.Begin and aux then
			aux = false
			punchCounter = punchCounter + 1
			if animPunchL then
				local anim = humanoid:LoadAnimation(animPunchL)
				anim:Play()
			end
			eventPunch:FireServer(1, punchCounter)
			task.wait(COOLDOWN)
			aux = true
		end
	elseif actionName == "rightPunch" then
		if inputState == Enum.UserInputState.Begin and aux then
			aux = false
			punchCounter = punchCounter + 1
			if animPunchR then
				local anim = humanoid:LoadAnimation(animPunchR)
				anim:Play()
			end
			eventPunch:FireServer(0, punchCounter)
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
			punchCounter = punchCounter + 1
			if animKick then
				local anim = humanoid:LoadAnimation(animKick)
				anim:Play()
			end
			eventPunch:FireServer(2, punchCounter)
			-- Cooldown más largo para el kick (1.2s)
			task.wait(1.2)
			aux = true
		end
	end
end

-- Función para mostrar botones de combate
local function showCombatButtons()
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
end

-- Función para ocultar botones de combate
local function hideCombatButtons()
	pcall(function()
		ContextActionService:UnbindAction("leftPunch")
		ContextActionService:UnbindAction("rightPunch")
		ContextActionService:UnbindAction("block")
		ContextActionService:UnbindAction("Patada")
	end)
end

-- Escuchar notificación del ring DESPUÉS de asegurar que existe
task.spawn(function()
	local lastRingStatus = false
	
	while not ringNotificationRemote do
		task.wait(0.5)
		ringNotificationRemote = remotes.ringNotificationRemote
	end
	
	ringNotificationRemote.OnClientEvent:Connect(function(ringStatus)
		-- Solo mostrar notificación cuando cambia el estado
		if ringStatus ~= lastRingStatus then
			if ringStatus then
				if NotificationSystem then
					NotificationSystem:Info("Ring", "Has ingresado al ring", 3)
				end
				showCombatButtons()  -- Mostrar botones cuando entra
			else
				if NotificationSystem then
					NotificationSystem:Info("Ring", "Has salido del ring", 3)
				end
				hideCombatButtons()  -- Ocultar botones cuando sale
			end
			lastRingStatus = ringStatus
		end
		inRing = ringStatus  -- Guardar estado del ring
	end)
end)