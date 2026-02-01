-- AscensorPRO_Client (CORREGIDO COMPLETO)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI pantalla negra completa
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AscensorUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true  -- CUBRE TODO, INCLUSO BOTONES DE ARRIBA
screenGui.DisplayOrder = 999     -- ENCIMA DE TODO
screenGui.Parent = playerGui

local fadeFrame = Instance.new("Frame")
fadeFrame.Name = "Fade"
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.Position = UDim2.new(0, 0, 0, 0)
fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel = 0
fadeFrame.Parent = screenGui

-- Tweens
local tweenFadeIn = TweenService:Create(fadeFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0})
local tweenFadeOut = TweenService:Create(fadeFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1})

-- Escuchar eventos de fade
local effectsEvent = ReplicatedStorage:WaitForChild("AscensorEffects")
effectsEvent.OnClientEvent:Connect(function(accion)
	if accion == "fadeIn" then
		tweenFadeIn:Play()
	elseif accion == "fadeOut" then
		tweenFadeOut:Play()
	end
end)

-- Sistema de notificación (opcional)
local NotificationSystem
local okNotif, notifMod = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
end)
if okNotif then 
	NotificationSystem = notifMod 
end

-- Esperar AscensorVIP (el servidor lo crea)
local function handleVipEvent(vipEvent)
	vipEvent.OnClientEvent:Connect(function(vipId)
		-- Mostrar notificación (si existe el sistema)
		if NotificationSystem and NotificationSystem.Warning then
			pcall(function()
				NotificationSystem:Warning("VIP", "Necesitas VIP para usar el ascensor", 3)
			end)
		else
			-- Fallback: mostrar una etiqueta rápida en pantalla
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0, 300, 0, 50)
			label.Position = UDim2.new(0.5, -150, 0.2, 0)
			label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Text = "Necesitas VIP para usar el ascensor"
			label.Font = Enum.Font.GothamBold
			label.TextSize = 18
			label.BackgroundTransparency = 1
			label.Parent = screenGui
            
			local t = TweenService:Create(label, TweenInfo.new(0.2), {BackgroundTransparency = 0})
			t:Play()
            
			task.delay(3, function()
				pcall(function() 
					label:Destroy() 
				end)
			end)
		end

		-- Abrir prompt de compra (si se envió un ID válido)
		if vipId then
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, vipId)
			end)
		end
	end)
end

local vipEvent = ReplicatedStorage:FindFirstChild("AscensorVIP")
if vipEvent then
	handleVipEvent(vipEvent)
else
	-- Si se crea después del inicio, suscribirse a ChildAdded para conectarlo
	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "AscensorVIP" then
			handleVipEvent(child)
		end
	end)
end