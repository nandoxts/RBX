local PhysService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Crear el grupo de colisión
pcall(function()
	PhysService:RegisterCollisionGroup("Players")
end)

PhysService:CollisionGroupSetCollidable("Players", "Players", false)

local function SetupPart(part)
	if part:IsA("BasePart") then
		pcall(function()
			part.CollisionGroup = "Players"
		end)
	end
end

local function NoCollide(char)
	-- Aplicar a todas las partes existentes
	for _, v in ipairs(char:GetDescendants()) do
		SetupPart(v)
	end

	-- Manejar partes que se añadan después (accesorios, herramientas, etc.)
	char.DescendantAdded:Connect(function(v)
		SetupPart(v)
	end)
end

local function SetupPlayer(player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		NoCollide(char)
	end)

	-- Manejar personaje existente si ya está cargado
	if player.Character then
		task.spawn(function()
			local char = player.Character
			if char:FindFirstChild("HumanoidRootPart") then
				NoCollide(char)
			else
				char:WaitForChild("HumanoidRootPart")
				task.wait(0.1)
				NoCollide(char)
			end
		end)
	end
end

-- Manejar jugadores nuevos
Players.PlayerAdded:Connect(SetupPlayer)

-- Manejar jugadores que ya están en el servidor
for _, player in ipairs(Players:GetPlayers()) do
	SetupPlayer(player)
end
