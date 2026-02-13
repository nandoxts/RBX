-- ═══════════════════════════════════════════════════════════
-- SUITE DE RESETEO DE CÁMARA - OPCIONES AVANZADAS
-- ═══════════════════════════════════════════════════════════
-- Ejecutar snippets individuales en la consola de Roblox (F9)
-- ═══════════════════════════════════════════════════════════

--[[ 
📋 OPCIÓN 1: RESETEO SIMPLE (RECOMENDADO)
Copia esto en la consola:
]]
local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
workspace.CurrentCamera.CFrame = h.CFrame + h.CFrame.LookVector * 15
workspace.CurrentCamera.Focus = h.CFrame
print("✓ Cámara reseteada (Opción Simple)")

--[[
📋 OPCIÓN 2: RESETEO CON DISTANCIA PERSONALIZADA
Copia esto en la consola (cambia el 20 por la distancia que quieras):
]]
local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
local distancia = 20 -- Cambiar valor aquí
workspace.CurrentCamera.CFrame = h.CFrame + h.CFrame.LookVector * distancia + Vector3.new(0, 3, 0)
workspace.CurrentCamera.Focus = h.CFrame
print("✓ Cámara reseteada a distancia: " .. distancia)

--[[
📋 OPCIÓN 3: RESETEO COMPLETO (Limpia movimientos extraños)
Copia esto en la consola:
]]
local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- Resetear todas las propiedades
cam.CFrame = h.CFrame
cam.Focus = h.CFrame
cam.FieldOfView = 70 -- FOV por defecto
cam.Parent = workspace

print("✓ Cámara completamente reseteada")

--[[
📋 OPCIÓN 4: RESETEO DESDE VENTAJA PANORÁMICA (Vista aérea)
Copia esto en la consola:
]]
local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
workspace.CurrentCamera.CFrame = h.CFrame + Vector3.new(0, 30, 20)
workspace.CurrentCamera.Focus = h.CFrame
print("✓ Cámara: Vista panorámica")

--[[
📋 OPCIÓN 5: SOLO RESETEAR POSICIÓN (Sin Look)
Copia esto en la consola:
]]
local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("HumanoidRootPart")
workspace.CurrentCamera.Focus = h.CFrame
print("✓ Cámara: Focus reseteado")

--[[
📋 OPCIÓN 6: RESETEO DE EMERGENCIA (Si todo falla)
Copia esto en la consola:
]]
workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 50, 0), Vector3.new(0, 0, 0))
workspace.CurrentCamera.FieldOfView = 70
print("✓ Cámara: Reset de emergencia aplicado")
