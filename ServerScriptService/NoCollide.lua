-- NoCollide.lua (Server) - colocar en ServerScriptService
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local COLLISION_GROUP = "Players"

-- Registrar el grupo (pcall para evitar errores si ya existe)
pcall(function()
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end)

-- Asegurar que el grupo no colisione consigo mismo
PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

local function SetupPart(part)
    if part:IsA("BasePart") then
        pcall(function()
            part.CollisionGroup = COLLISION_GROUP
        end)
    end
end

local function HandleDescendantAdded(descendant)
    SetupPart(descendant)
end

local function ApplyNoCollideToCharacter(char)
    -- Aplicar a todas las partes existentes
    for _,v in ipairs(char:GetDescendants()) do
        SetupPart(v)
    end

    -- Conectar para partes que se añadan después (accesorios, herramientas)
    char.DescendantAdded:Connect(HandleDescendantAdded)
end

local function OnCharacterAdded(char)
    -- Esperar HRP si es necesario (no bloquear demasiado)
    if not char:FindFirstChild("HumanoidRootPart") then
        char:WaitForChild("HumanoidRootPart", 5)
    end
    task.wait(0.05)
    ApplyNoCollideToCharacter(char)
end

local function OnPlayerAdded(player)
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
for _,p in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(p)
end

print("[NoCollide] Script iniciado en servidor. Grupo:", COLLISION_GROUP)
