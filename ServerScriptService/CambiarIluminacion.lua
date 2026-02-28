-- Script para cambiar la iluminación a noche fría rosada (sin niebla)
local Lighting = game:GetService("Lighting")

-- Configurar iluminación para noche fría rosada
Lighting.ClockTime = 20 -- Hora del día (20 = 8 PM, noche)
Lighting.Ambient = Color3.fromRGB(150, 150, 200) -- Luz ambiente azul fría (más clara)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 200)
Lighting.Brightness = 2.2 -- Más brillo para ver los colores

-- Colores fríos rosados para la noche
Lighting.ColorShift_Top = Color3.fromRGB(160, 100, 180) -- Púrpura/rosado para el cielo
Lighting.ColorShift_Bottom = Color3.fromRGB(100, 120, 160) -- Azul profundo para abajo

-- Sin niebla - solo atmósfera clara
Lighting.FogEnd = 100000 -- Niebla muy lejana (prácticamente invisible)
Lighting.FogStart = 100000

print("🌙 Iluminación ajustada a noche fría rosada (colores visibles) 💕")
