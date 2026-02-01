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


local DAMAGE = 10  -- Daño base por golpe
local PUNCH_SOUND_ID = "rbxassetid://4766118952"

-- Obtener efecto de golpe desde ReplicatedStorage (esperar a que cargue)
local effectPunch = ReplicatedStorage.Effect:WaitForChild("Part")

-- Función para crear efecto visual de golpe mejorado
local function effect(character)
	local clone = effectPunch:Clone()
	clone.Parent = character.HumanoidRootPart
	clone.CFrame = CFrame.new(character.HumanoidRootPart.Position)

	-- Efecto más vistoso: crece y se desvanece
	for i = 1, 15 do
		clone.Transparency = clone.Transparency + (1/15)
		clone.Size = clone.Size + Vector3.new(1.5, 1.5, 0)
		task.wait(0.03)
	end

	clone:Destroy()
end

-- Tabla para rastrear golpes activos (para evitar múltiples golpes en el mismo evento)
local activePunches = {}

-- Función para reproducir sonido
local function playPunchSound(character)
	local soundClone = Instance.new("Sound")
	soundClone.SoundId = PUNCH_SOUND_ID
	soundClone.Volume = 0.5
	soundClone.Parent = character.HumanoidRootPart
	soundClone:Play()
	Debris:AddItem(soundClone, 1)
end

-- Monitorear si jugadores están en ring
task.spawn(function()
	while true do
		task.wait(0.5)

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local inRing = false

					-- Buscar BaseRing directamente
					local ringsFolder = workspace:FindFirstChild("Rings")
					if ringsFolder then
						for _, ring in ipairs({"Ring1", "Ring2"}) do
							local ringObj = ringsFolder:FindFirstChild(ring)
							if ringObj then
								local baseRing = ringObj:FindFirstChild("BaseRing")
								if baseRing and baseRing:IsA("BasePart") then
									-- Distancia exacta al BaseRing (más generosa para detectar bien)
									local distance = (root.Position - baseRing.Position).Magnitude
									if distance < 20 then
										inRing = true
										break
									end
								end
							end
						end
					end

					-- Notificar al cliente
					ringNotificationRemote:FireClient(player, inRing)
				end
			end
		end
	end
end)

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

	-- Verificar que está en Ring1 o Ring2
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local isInRing = false
	local ringsFolder = workspace:FindFirstChild("Rings")

	if ringsFolder then
		for _, ring in ipairs({"Ring1", "Ring2"}) do
			local ringObj = ringsFolder:FindFirstChild(ring)
			if ringObj then
				local baseRing = ringObj:FindFirstChild("BaseRing")
				if baseRing and baseRing:IsA("BasePart") then
					local distance = (root.Position - baseRing.Position).Magnitude
					if distance < 20 then
						isInRing = true
						break
					end
				end
			end
		end
	end

	if not isInRing then return end

	-- Crear ID único para este golpe
	local punchKey = player.UserId .. "_" .. punchId

	-- Evitar múltiples golpes del mismo evento
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
