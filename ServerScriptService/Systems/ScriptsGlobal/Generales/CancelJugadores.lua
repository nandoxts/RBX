-- CancelJugadores.lua - VERSIÓN ROBUSTA (compatible con HD Admin fly/noclip)
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local COLLISION_GROUP = "Players"

-- Registrar grupo de colisión
pcall(function()
	PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
end)
pcall(function()
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
end)

-- Aplica el grupo a un BasePart (todos, incluyendo accesorios)
local function SetupPart(part)
	if part:IsA("BasePart") then
		pcall(function()
			if part.CollisionGroup ~= COLLISION_GROUP then
				part.CollisionGroup = COLLISION_GROUP
			end
		end)
	end
end

-- Aplica a todo el personaje inmediatamente + vuelve a aplicar tras 0.5s
-- (la segunda pasada captura accesorios que carga Roblox tarde)
local function ApplyToCharacter(char)
	for _, part in ipairs(char:GetDescendants()) do
		SetupPart(part)
	end
end

local function OnCharacterAdded(char)
	-- Sin task.wait: aplicar de inmediato para no dejar ventana de colisión
	ApplyToCharacter(char)

	-- Segunda pasada tras 0.5 s: captura accesorios que Roblox carga tarde
	task.delay(0.5, function()
		if char and char.Parent then
			ApplyToCharacter(char)
		end
	end)

	-- Captura partes añadidas en tiempo real (herramientas, accesorios, etc.)
	char.DescendantAdded:Connect(SetupPart)
end

local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(OnCharacterAdded)
	if player.Character then
		task.spawn(function() OnCharacterAdded(player.Character) end)
	end
end

-- Conectar jugadores nuevos
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Aplicar a jugadores ya conectados
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end
