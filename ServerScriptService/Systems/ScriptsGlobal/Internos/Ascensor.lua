-- AscensorPRO_Server (CORREGIDO COMPLETO)

local ascensor = workspace.Ascensor
local tiempoViaje = 2
local cooldown = {}
local COOLDOWN_TIMEOUT = 10  -- Timeout de seguridad en segundos

-- Servicios y configuración (VIP)
local ServerScriptService = game:GetService("ServerScriptService")
local PandaSSS = ServerScriptService:WaitForChild("Panda ServerScriptService")
local Configuration = require(PandaSSS:WaitForChild("Configuration"))
local GamepassManager = require(PandaSSS:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))

local VIP_ID = Configuration.VIP

-- Obtener referencias a RemotesGlobal/Ascensor
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local ascensorFolder = remotesGlobal:WaitForChild("Ascensor")
local effectsEvent = ascensorFolder:WaitForChild("AscensorEffects")
local vipEvent = ascensorFolder:WaitForChild("AscensorVIP")

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

-- Función para establecer cooldown con timeout automático
local function setCooldownConTimeout(userId)
	cooldown[userId] = true

	-- Auto-limpiar después de timeout por seguridad (evita bloqueos permanentes)
	task.delay(COOLDOWN_TIMEOUT, function()
		if cooldown[userId] then
			cooldown[userId] = nil
			warn("[Ascensor] Cooldown auto-limpiado para userId: " .. userId)
		end
	end)
end

local function usarAscensor(player, pisoOrigen, pisoDestino)
	-- Check de cooldown personal
	if cooldown[player.UserId] then 
		return 
	end

	-- Establecer cooldown con timeout automático
	setCooldownConTimeout(player.UserId)

	-- ENVOLVER TODO EN PCALL PARA SIEMPRE LIMPIAR EL COOLDOWN
	local success, errorMsg = pcall(function()

		-- Restringir uso solo a propietarios del GamePass VIP (si está configurado)
		if VIP_ID and GamepassManager then
			local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)

			-- Si no tiene VIP
			if not hasVIP then
				-- Notificar al cliente para que muestre la notificación y abra el prompt de compra
				if vipEvent then
					pcall(function()
						vipEvent:FireClient(player, VIP_ID)
					end)
				end
				return -- Sale del pcall, el cooldown se limpiará al final
			end
		end

		local character = player.Character
		if not character then 
			return 
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")

		if not humanoidRootPart or not humanoid then 
			return 
		end

		-- Verificar que el jugador esté vivo
		if humanoid.Health <= 0 then
			return
		end

		local destino = pisos[pisoDestino]
		if not destino or not destino.spawn then 
			warn("[Ascensor] Destino no encontrado: " .. pisoDestino)
			return 
		end

		-- 1. Pantalla negra
		pcall(function()
			effectsEvent:FireClient(player, "fadeIn")
		end)

		-- 2. Esperar viaje
		task.wait(tiempoViaje)

		-- Verificar que el character y humanoid sigan existiendo después del wait
		if not character.Parent or not humanoidRootPart.Parent or not humanoid.Parent then
			return
		end

		-- Verificar que el jugador siga vivo
		if humanoid.Health <= 0 then
			return
		end

		-- 3. Teletransportar
		local spawnPos = destino.spawn.Position
		humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		humanoidRootPart.CFrame = CFrame.new(spawnPos.X, spawnPos.Y + 1, spawnPos.Z)

		task.wait(0.1)

		-- Verificar nuevamente que siga existiendo
		if humanoidRootPart.Parent then
			humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end

		-- 4. Quitar pantalla negra
		pcall(function()
			effectsEvent:FireClient(player, "fadeOut")
		end)

		-- 5. Esperar antes de permitir uso nuevamente
		task.wait(1)

	end)

	-- SIEMPRE LIMPIAR EL COOLDOWN, SIN IMPORTAR QUÉ PASÓ
	cooldown[player.UserId] = nil

	-- Log de errores (opcional, para debugging)
	if not success then
		warn("[Ascensor] Error para " .. player.Name .. ": " .. tostring(errorMsg))
	end
end

local function crearPrompt(parte, texto, pisoOrigen, pisoDestino)
	local boton = parte:FindFirstChild("BotonPiso1") or parte:FindFirstChild("BotonPiso2")
	if not boton then 
		warn("[Ascensor] No se encontró botón en " .. parte.Name)
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

-- Crear prompts
crearPrompt(parte1, "Subir", "Parte1", "Parte2")
crearPrompt(parte2, "Bajar", "Parte2", "Parte1")