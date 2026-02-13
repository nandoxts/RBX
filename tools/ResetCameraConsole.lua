-- ═══════════════════════════════════════════════════════════
-- RESETEAR CÁMARA - EJECUTABLE POR CONSOLA DE ROBLOX
-- ═══════════════════════════════════════════════════════════
-- Uso: Copiar y pegar en la consola de Roblox (F9)
-- ═══════════════════════════════════════════════════════════

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Camera = workspace.CurrentCamera
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Reset básico de cámara
Camera.CFrame = HRP.CFrame + HRP.CFrame.LookVector * 10 + Vector3.new(0, 2, 0)
Camera.Focus = HRP.CFrame + Vector3.new(0, 5, 0)

print("✓ Cámara reseteada exitosamente")
