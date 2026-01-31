-- AscensorPRO_Server (LIMPIO)
local ascensor = workspace.Ascensor

local tiempoViaje = 2
local cooldown = {}

local effectsEvent = Instance.new("RemoteEvent")
effectsEvent.Name = "AscensorEffects"
effectsEvent.Parent = game.ReplicatedStorage

-- Servicios y configuración (VIP)
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local okConfig, Configuration = pcall(function()
	return require(ServerScriptService:WaitForChild("Panda ServerScriptService"):WaitForChild("Configuration"))
end)
local VIP_ID = (okConfig and Configuration and Configuration.VIP) or nil
-- Crear (o obtener) RemoteEvent para comunicar al cliente que debe comprar VIP
-- Buscar `AscensorVIP` en cualquier subcarpeta de ReplicatedStorage; NO crear uno nuevo
local vipEvent = game.ReplicatedStorage:FindFirstChild("AscensorVIP", true)
if not vipEvent then
	vipEvent = nil
end

local parte1 = ascensor.Parte1
local parte2 = ascensor.Parte2
local spawnParte1 = parte1:FindFirstChild("SpawnPoint")
local spawnParte2 = parte2:FindFirstChild("SpawnPoint")

local pisos = {
	["Parte1"] = {
		parte = parte1,
		spawn = spawnParte1 or parte1:FindFirstChild("PuertaAscensor1")
	},
	["Parte2"] = {
		parte = parte2,
		spawn = spawnParte2 or parte2:FindFirstChild("PuertaAscensor1")
	}
}

local function usarAscensor(player, pisoOrigen, pisoDestino)
	if cooldown[player.UserId] then return end
	-- Restringir uso solo a propietarios del GamePass VIP (si está configurado)
	if VIP_ID then
		local success, hasVIP = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID)
		end)
		if not success or not hasVIP then
			-- Notificar al cliente para que muestre la notificación y abra el prompt de compra
			if vipEvent and vipEvent.FireClient then
				pcall(function()
					vipEvent:FireClient(player, VIP_ID)
				end)
			end
			return
		end
	end
	cooldown[player.UserId] = true

	local character = player.Character
	if not character then 
		cooldown[player.UserId] = nil
		return 
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		cooldown[player.UserId] = nil
		return 
	end

	local destino = pisos[pisoDestino]
	if not destino or not destino.spawn then 
		warn("Destino no encontrado: " .. pisoDestino)
		cooldown[player.UserId] = nil
		return 
	end

	-- 1. Pantalla negra
	effectsEvent:FireClient(player, "fadeIn")

	-- 2. Esperar viaje
	task.wait(tiempoViaje)

	-- 3. Teletransportar
	local spawnPos = destino.spawn.Position
	humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
	humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	humanoidRootPart.CFrame = CFrame.new(spawnPos.X, spawnPos.Y + 1, spawnPos.Z)
	task.wait(0.1)
	humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
	humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

	-- 4. Quitar pantalla negra
	effectsEvent:FireClient(player, "fadeOut")

	-- 5. Cooldown
	task.wait(1)
	cooldown[player.UserId] = nil
end

local function crearPrompt(parte, texto, pisoOrigen, pisoDestino)
	local boton = parte:FindFirstChild("BotonPiso1") or parte:FindFirstChild("BotonPiso2")
	if not boton then 
		warn("No se encontró botón en " .. parte.Name)
		return 
	end

	local target = boton:FindFirstChildWhichIsA("BasePart") or boton

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = target
	prompt.ActionText = texto
	prompt.ObjectText = "Ascensor"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		usarAscensor(player, pisoOrigen, pisoDestino)
	end)
end

crearPrompt(parte1, "Subir", "Parte1", "Parte2")
crearPrompt(parte2, "Bajar", "Parte2", "Parte1")