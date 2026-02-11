-- ════════════════════════════════════════════════════════════════
-- COMBAT CLIENT - Sistema mejorado sin redundancia
-- ════════════════════════════════════════════════════════════════

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 30)
local CombatRemotes = RemotesGlobal:WaitForChild("Combat", 30)

local eventPunch = CombatRemotes:WaitForChild("PunchRemote", 30)
local eventBlock = CombatRemotes:WaitForChild("BlockRemote", 30)
local ringStateRemote = CombatRemotes:WaitForChild("RingStateRemote", 30)
local effectRemote = CombatRemotes:WaitForChild("EffectRemote", 30)

-- Cargar sistema de notificaciones
local NotificationSystem
pcall(function()
	NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems", 10):WaitForChild("NotificationSystem", 10):WaitForChild("NotificationSystem", 10))
end)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 10)
local rootPart = character:WaitForChild("HumanoidRootPart", 10)

local COOLDOWN = 0.8
local currentState = "FREE"  -- Estados: FREE, WAITING, FIGHTING
local aux = true
local punchCounter = 0
local lastNotificationState = nil  -- Para evitar notificaciones duplicadas

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 10)
	rootPart = character:WaitForChild("HumanoidRootPart", 10)
	aux = true
	currentState = "FREE"
	lastNotificationState = nil
	hideCombatButtons()
end)

---------------------------------------------------
-- ANIMACIONES
---------------------------------------------------
local animPunchR = Instance.new("Animation")
animPunchR.AnimationId = "rbxassetid://73048975017223"

local animPunchL = Instance.new("Animation")
animPunchL.AnimationId = "rbxassetid://92479079749990"

local animBlock = Instance.new("Animation")
animBlock.AnimationId = "rbxassetid://125626942999742"

local animKick = Instance.new("Animation")
animKick.AnimationId = "rbxassetid://138408477594658"

---------------------------------------------------
-- EFECTO ROJO DE GOLPE
---------------------------------------------------
local redFlashGui = Instance.new("ScreenGui")
redFlashGui.Name = "RedFlash"
redFlashGui.ResetOnSpawn = false
redFlashGui.Parent = player:WaitForChild("PlayerGui")

local redFlash = Instance.new("Frame")
redFlash.Name = "RedSplash"
redFlash.Size = UDim2.new(0, 200, 0, 200)
redFlash.Position = UDim2.new(0.5, -100, 0.5, -100)
redFlash.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
redFlash.BackgroundTransparency = 1
redFlash.BorderSizePixel = 0
redFlash.ZIndex = 99
redFlash.Parent = redFlashGui

local splashCorner = Instance.new("UICorner")
splashCorner.CornerRadius = UDim.new(1, 0)
splashCorner.Parent = redFlash

local function punchEffect()
	local tween = TweenService:Create(redFlash, TweenInfo.new(0.08), {BackgroundTransparency = 0.2})
	tween:Play()
	tween.Completed:Connect(function()
		local tweenBack = TweenService:Create(redFlash, TweenInfo.new(0.25), {BackgroundTransparency = 1})
		tweenBack:Play()
	end)
end

effectRemote.OnClientEvent:Connect(function()
	punchEffect()
end)

---------------------------------------------------
-- BOTONES DE COMBATE
---------------------------------------------------
function fightButton(actionName, inputState, inputObject)
	-- SOLO funciona si está EN PELEA
	if currentState ~= "FIGHTING" then return end
	if not humanoid or humanoid.Health <= 0 then return end

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
			task.wait(1.2)
			aux = true
		end
	end
end

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

function hideCombatButtons()
	pcall(function()
		ContextActionService:UnbindAction("leftPunch")
		ContextActionService:UnbindAction("rightPunch")
		ContextActionService:UnbindAction("block")
		ContextActionService:UnbindAction("Patada")
	end)
end

---------------------------------------------------
-- ESCUCHAR CAMBIOS DE ESTADO (MEJORADO)
---------------------------------------------------
ringStateRemote.OnClientEvent:Connect(function(newState)
	-- IGNORAR si el estado no cambió realmente
	if currentState == newState then
		return
	end

	-- IGNORAR notificaciones duplicadas del mismo estado
	if lastNotificationState == newState then
		return
	end

	local oldState = currentState
	currentState = newState
	lastNotificationState = newState

	-- ══════════════════════════════════════════════════════════════
	-- CRÍTICO: Notificar al servidor del cambio de estado
	-- ══════════════════════════════════════════════════════════════
	-- El CombatServer NECESITA saber que estás en "FIGHTING" para
	-- permitir que tus golpes hagan daño. Sin esta línea, todos los
	-- golpes serán bloqueados con el mensaje:
	-- "[ServerCombat] Golpe bloqueado - Estado: nil"
	-- ══════════════════════════════════════════════════════════════
	ringStateRemote:FireServer(newState)

	-- Acciones según el nuevo estado
	if newState == "WAITING" then
		if NotificationSystem then
			NotificationSystem:Info("Ring", "Esperando oponente...", 3)
		end
		hideCombatButtons()

	elseif newState == "FIGHTING" then
		if NotificationSystem then
			NotificationSystem:Info("Ring", "PELEA INICIADA", 2)
		end
		showCombatButtons()

	elseif newState == "FREE" then
		if NotificationSystem then
			NotificationSystem:Info("Ring", "Saliste del ring", 2)
		end
		hideCombatButtons()
		lastNotificationState = nil  -- Reset para permitir nueva entrada
	end
end)