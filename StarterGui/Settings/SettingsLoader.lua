--[[
	SETTINGS LOADER - LocalScript que carga el módulo de Settings
	Va en: StarterGui/Settings (LocalScript)
	
	Este script simplemente carga el módulo SettingsUI para que exponga
	las funciones globales _G.OpenSettingsUI y _G.CloseSettingsUI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que los servicios estén listos
task.wait(0.3)

-- Cargar el módulo (esto automáticamente expone _G.OpenSettingsUI)
local SettingsUI = require(script.Parent:WaitForChild("SettingsUI"))

-- Verificar que se expuso correctamente
task.wait(0.1)

if _G.OpenSettingsUI and _G.CloseSettingsUI then
	print("✅ [Settings] Sistema completamente cargado")
	print("   Usa: _G.OpenSettingsUI() para abrir")
	print("   Usa: _G.CloseSettingsUI() para cerrar")
else
	error("❌ [Settings] Falló la carga del módulo - revisa la estructura")
end
