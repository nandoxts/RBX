-- NoCollide.lua - DESACTIVADO
-- Esta lógica está centralizada en:
-- ServerScriptService/Systems/ScriptsGlobal/Generales/CancelJugadores.lua
-- Tener ambos activos causaba condiciones de carrera con HD Admin (fly/noclip).
return

-- Aplicar nocollide a una parte
local function SetupPart(part)
    if part:IsA("BasePart") then
        pcall(function() part.CollisionGroup = COLLISION_GROUP end)
    end
end

-- Aplicar nocollide a todas las partes
local function ApplyNoCollideToCharacter(char)
    for _, part in ipairs(char:GetDescendants()) do
        SetupPart(part)
    end
end

-- Cuando un jugador se une y crea un personaje
local function OnCharacterAdded(char)
    task.wait(0.1)
    ApplyNoCollideToCharacter(char)
    
    -- Para accesorios/herramientas/ApplyDescription que se añadan después
    char.DescendantAdded:Connect(SetupPart)
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
