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

-- Crear modal (igual que GamepassShop)
local isMobile = game:GetService("UserInputService").TouchEnabled

local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "SettingsPanel",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = 14,
	enableBlur = true,
	blurSize = 20,
	isMobile = isMobile,
})

-- Igual que GamepassShop: colorear panel + usar canvas
local panel = modal:getPanel()
panel.BackgroundColor3 = THEME.bg
panel.BackgroundTransparency = THEME.mediumAlpha

local CONTAINER = modal:getCanvas()  -- recorta hijos respetando UICorner

-- Construir UI en el canvas (igual que GamepassShop usa CONTAINER)
SettingsCreator.CreateSettingsModal(CONTAINER, THEME)

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

