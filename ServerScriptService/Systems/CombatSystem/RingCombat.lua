-- ════════════════════════════════════════════════════════════════
-- RING COMBAT - VERSIÓN SIMPLE
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Crear RemotesGlobal si no existe
local RemotesGlobal = ReplicatedStorage:FindFirstChild("RemotesGlobal")
if not RemotesGlobal then
	RemotesGlobal = Instance.new("Folder")
	RemotesGlobal.Name = "RemotesGlobal"
	RemotesGlobal.Parent = ReplicatedStorage
end

-- Crear carpeta Combat si no existe
local CombatFolder = RemotesGlobal:FindFirstChild("Combat")
if not CombatFolder then
	CombatFolder = Instance.new("Folder")
	CombatFolder.Name = "Combat"
	CombatFolder.Parent = RemotesGlobal
end

-- Crear remotes de combate si no existen
local eventPunch = CombatFolder:FindFirstChild("PunchRemote")
if not eventPunch then
	eventPunch = Instance.new("RemoteEvent")
	eventPunch.Name = "PunchRemote"
	eventPunch.Parent = CombatFolder
end

local eventBlock = CombatFolder:FindFirstChild("BlockRemote")
if not eventBlock then
	eventBlock = Instance.new("RemoteEvent")
	eventBlock.Name = "BlockRemote"
	eventBlock.Parent = CombatFolder
end

local ringNotificationRemote = CombatFolder:FindFirstChild("RingNotification")
if not ringNotificationRemote then
	ringNotificationRemote = Instance.new("RemoteEvent")
	ringNotificationRemote.Name = "RingNotification"
	ringNotificationRemote.Parent = CombatFolder
end

-- Crear remote para efectos de golpe
local effectRemote = CombatFolder:FindFirstChild("EffectRemote")
if not effectRemote then
	effectRemote = Instance.new("RemoteEvent")
	effectRemote.Name = "EffectRemote"
	effectRemote.Parent = CombatFolder
end


local DAMAGE = 10
local PUNCH_SOUND_ID = "rbxassetid://4766118952"

local effectPunch = ReplicatedStorage.Effect:WaitForChild("Part")

-- Tabla para rastrear quién está en ring
local playersInRing = {}
local lastNotification = {} -- Debounce para notificaciones

-- Función para crear efecto visual de golpe
local function effect(character)
	local clone = effectPunch:Clone()
	clone.Parent = character.HumanoidRootPart
	clone.CFrame = CFrame.new(character.HumanoidRootPart.Position)

	for i = 1, 15 do
		clone.Transparency = clone.Transparency + (1/15)
		clone.Size = clone.Size + Vector3.new(1.5, 1.5, 0)
		task.wait(0.03)
	end

	clone:Destroy()
end

local activePunches = {}

local function playPunchSound(character)
	local soundClone = Instance.new("Sound")
	soundClone.SoundId = PUNCH_SOUND_ID
	soundClone.Volume = 0.5
	soundClone.Parent = character.HumanoidRootPart
	soundClone:Play()
	Debris:AddItem(soundClone, 1)
end

-- Setup de BaseRingUpdate para detectar jugadores en ring (MEJORADO con detección periódica)
local function setupRingDetection()
	local ringsFolder = workspace:WaitForChild("Rings", 10)
	if not ringsFolder then 
		warn("[RingCombat] Rings folder no encontrado")
		return 
	end

	local ringData = {}

	for _, ringName in ipairs({"Ring1", "Ring2"}) do
		local ring = ringsFolder:FindFirstChild(ringName)
		if ring then
			local baseRing = ring:FindFirstChild("BaseRingUpdate")
			if baseRing and baseRing:IsA("BasePart") then
				ringData[ringName] = {
					basePart = baseRing,
					size = baseRing.Size,
					position = baseRing.Position
				}
			else
				warn("[RingCombat] BaseRingUpdate NO encontrado en " .. ringName)
			end
		else
			warn("[RingCombat] Ring " .. ringName .. " NO encontrado")
		end
	end

	-- Función para verificar si un jugador está dentro del ring
	local function isPlayerInRing(character, baseRing)
		if not baseRing or not character then return false end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return false end

		-- Calcular distancia al centro del ring (solo en eje Y para altura)
		local basePos = baseRing.Position
		local playerPos = rootPart.Position

		-- Distancia horizontal (ignorar altura)
		local horizontalDistance = math.sqrt(
			(playerPos.X - basePos.X)^2 + 
				(playerPos.Z - basePos.Z)^2
		)

		-- Usar el radio más pequeño de la parte para mayor compatibilidad
		local ringRadius = math.min(baseRing.Size.X, baseRing.Size.Z) / 2

		-- Sumar un margen para evitar salidas falsas
		return horizontalDistance <= (ringRadius + 2)
	end

	-- Verificación periódica cada 0.3 segundos
	task.spawn(function()
		while true do
			task.wait(0.3)

			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local uid = player.UserId
					local inRingNow = false

					-- Verificar si está en alguno de los rings
					for _, data in pairs(ringData) do
						if isPlayerInRing(player.Character, data.basePart) then
							inRingNow = true
							break
						end
					end

					-- Detectar cambios de estado
					local wasInRing = playersInRing[uid] or false
					if inRingNow and not wasInRing then
						-- Entró al ring
						playersInRing[uid] = true
						ringNotificationRemote:FireClient(player, true)
					elseif not inRingNow and wasInRing then
						-- Salió del ring
						playersInRing[uid] = nil
						ringNotificationRemote:FireClient(player, false)
					end
				end
			end
		end
	end)
end

task.wait(1)
setupRingDetection()

-- Función para detectar golpe y aplicar daño
local function hitDetection(humanoid, character)
	playPunchSound(character)

	local blockValue = character:FindFirstChild("block")
	if blockValue then
		if blockValue.Value == false then
			humanoid:TakeDamage(DAMAGE)
			effect(character)
		end
	else
		humanoid:TakeDamage(DAMAGE)
		effect(character)
	end
end

-- Evento de golpe (mano derecha = 0, mano izquierda = 1, patada = 2)
eventPunch.OnServerEvent:Connect(function(player, num, punchId)
	if not player.Character then return end

	-- Verificar si está en ring (simple)
	if not playersInRing[player.UserId] then return end

	local punchKey = player.UserId .. "_" .. punchId
	if activePunches[punchKey] then return end
	activePunches[punchKey] = true

	-- Usar todas las partes del cuerpo para detectar contacto
	local bodyParts = player.Character:GetChildren()
	local hitTargets = {}
	local connections = {}

	for _, part in ipairs(bodyParts) do
		if part:IsA("BasePart") then
			local connection
			connection = part.Touched:Connect(function(hit)
				local targetChar = hit.Parent

				-- Validar que targetChar es un Character válido
				if not targetChar or not targetChar:FindFirstChild("Humanoid") then return end

				local humanoid = targetChar:FindFirstChild("Humanoid")

				-- Verificar que es un enemigo y no lo hemos golpeado ya
				if humanoid and targetChar ~= player.Character and not hitTargets[targetChar] then
					hitTargets[targetChar] = true
					hitDetection(humanoid, targetChar)

					-- Obtener el Player asociado al Character golpeado
					local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
					if targetPlayer then
						effectRemote:FireClient(targetPlayer)
					end
				end
			end)
			table.insert(connections, connection)
		end
	end

	-- Solo escuchar durante la animación del golpe (menos tiempo = menos contacto accidental)
	local waitTime = (num == 2) and 0.6 or 0.4
	task.wait(waitTime)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	activePunches[punchKey] = nil
end)

-- Evento de bloqueo
eventBlock.OnServerEvent:Connect(function(player, block)
	if not player.Character then return end

	local blockValue = player.Character:FindFirstChild("block")
	if not blockValue then
		blockValue = Instance.new("BoolValue")
		blockValue.Name = "block"
		blockValue.Parent = player.Character
	end

	if block then
		blockValue.Value = true
	else
		blockValue.Value = false
	end
end)
