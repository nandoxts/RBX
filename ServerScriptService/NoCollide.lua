-- NoCollide.lua (Server) - VERSIÓN SIMPLE Y CONFIABLE
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local COLLISION_GROUP = "Players"

-- Registrar grupo (mejor si lo haces en Studio, pero así también funciona)
pcall(function() PhysicsService:RegisterCollisionGroup(COLLISION_GROUP) end)
pcall(function() PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false) end)

-- Aplicar nocollide a todas las partes
local function ApplyNoCollideToCharacter(char)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUP
        end
    end
    
    -- Para accesorios/herramientas que se añadan después
    char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUP
        end
    end)
end

-- Cuando un jugador se une y crea un personaje
local function OnCharacterAdded(char)
    task.wait(0.1) -- Pequeño delay para que todo esté listo
    ApplyNoCollideToCharacter(char)
end

local function OnPlayerAdded(player)
    player.CharacterAdded:Connect(OnCharacterAdded)
    if player.Character then
        task.spawn(function() OnCharacterAdded(player.Character) end)
    end
end

-- Conectar nuevos jugadores
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Aplicar a jugadores que ya están en el servidor
for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end
