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

-- Obtener referencias a RemotesGlobal/Ascensor
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local ascensorFolder = remotesGlobal:WaitForChild("Ascensor")
local effectsEvent = ascensorFolder:WaitForChild("AscensorEffects")

-- Escuchar eventos de fade
effectsEvent.OnClientEvent:Connect(function(accion)
	if accion == "fadeIn" then
		tweenFadeIn:Play()
	elseif accion == "fadeOut" then
		tweenFadeOut:Play()
	end
end)

-- Sistema de notificación
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- Obtener referencias a RemotesGlobal/Ascensor
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local ascensorFolder = remotesGlobal:WaitForChild("Ascensor")
local vipEvent = ascensorFolder:WaitForChild("AscensorVIP")

if vipEvent then
	vipEvent.OnClientEvent:Connect(function(vipId)
		-- Mostrar notificación
		if NotificationSystem.Warning then
			pcall(function()
				NotificationSystem:Warning("VIP", "Necesitas VIP para usar el ascensor", 3)
			end)
		end

		-- Abrir prompt de compra (si se envió un ID válido)
		if vipId then
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, vipId)
			end)
		end
	end)
else
	warn("[AscensorClient] No se encontró AscensorVIP después de 10 segundos")
end