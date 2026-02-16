local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Módulos
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local SettingsCreator = require(script.Parent:WaitForChild("SettingsCreator"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SettingsGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Crear modal (mismo tamaño que Clan, mismos parámetros)
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "SettingsPanel",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = 12,
	enableBlur = true,
	blurSize = 14,
    panelBackgroundImage = "rbxassetid://79346090571461",
    panelBackgroundTransparency = 0.85
})

-- Obtener panel de forma correcta
local panel = modal:getPanel()

-- Construir UI en el panel del modal
SettingsCreator.CreateSettingsModal(panel, THEME)

-- ============================================
-- OPEN/CLOSE FUNCTIONS
-- ============================================
local function openUI()
	modal:open()
end

local function closeUI()
	modal:close()
end

-- ============================================
-- EXPONER GLOBALMENTE
-- ============================================
_G.OpenSettingsUI = openUI
_G.CloseSettingsUI = closeUI

-- Ejecutable como LocalScript: no se retorna valor. Expone funciones en _G.
