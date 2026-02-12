-- NoCollide.lua (Server) - colocar en ServerScriptService
-- Utilizando las nuevas APIs de Roblox para Collision Groups
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local COLLISION_GROUP = "Players"

-- Registrar el grupo usando la nueva API
pcall(function()
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end)

-- Asegurar que el grupo no colisione consigo mismo
pcall(function()
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
end)

-- Función mejorada para aplicar nocollide a una parte
local function SetupPart(part)
    if part:IsA("BasePart") then
        -- Usar la nueva propiedad CollisionGroup directamente
        pcall(function()
            part.CollisionGroup = COLLISION_GROUP
        end)
    end
end

local function HandleDescendantAdded(descendant)
    -- Pequeño delay para asegurar que la parte esté completamente creada
    task.wait(0.001)
    SetupPart(descendant)
end

local function ApplyNoCollideToCharacter(char)
    -- Aplicar a todas las partes existentes (recursivo y seguro)
    for _, v in ipairs(char:GetDescendants()) do
        SetupPart(v)
    end

    -- Conectar para partes que se añadan después (accesorios, herramientas, etc)
    -- Usar una sola conexión para evitar múltiples conexiones
    if not char:GetAttribute("NoCollideSetup") then
        char:SetAttribute("NoCollideSetup", true)
        char.DescendantAdded:Connect(HandleDescendantAdded)
    end
end

local function OnCharacterAdded(char)
    -- Esperar HRP con timeout
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        hrp = char:WaitForChild("HumanoidRootPart", 5)
    end
    
    -- Pequeño delay para asegurar que todas las partes iniciales están listas
    task.wait(0.1)
    ApplyNoCollideToCharacter(char)
end

local function OnPlayerAdded(player)
    -- Conectar para futuros personajes
    player.CharacterAdded:Connect(OnCharacterAdded)

    -- Si el personaje ya existe (jugadores reconectando al iniciar el script)
    if player.Character then
        task.spawn(function()
            OnCharacterAdded(player.Character)
        end)
    end
end

-- Conectar nuevos jugadores
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Aplicar a los que ya están en el servidor
for _, p in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(p)
end
