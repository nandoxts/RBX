-- Script para pegar en CONSOLA DEL SERVIDOR (Command Bar)
-- Copia TODO esto y pégalo en la consola del servidor

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local COLLISION_GROUP = "Players"

-- Registrar grupo
pcall(function()
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end)

-- Configurar colisiones
pcall(function()
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
end)

-- Función para aplicar
local function ApplyToCharacter(char)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function()
                v.CollisionGroup = COLLISION_GROUP
            end)
        end
    end
end

-- Aplicar a todos los jugadores actuales
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        ApplyToCharacter(player.Character)
        print("✓ NoCollide aplicado a: " .. player.Name)
    end
end

print("✓ NoCollide activado en el servidor")
