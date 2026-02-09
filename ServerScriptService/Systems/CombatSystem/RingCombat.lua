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
local touchCount = {} -- Contar cuántas partes del cuerpo están tocando

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

-- Setup de Wall_Barrier para detectar jugadores en ring
local function setupRingDetection()
	local ringsFolder = workspace:FindFirstChild("Rings")
	if not ringsFolder then return end

	for _, ringName in ipairs({"Ring1", "Ring2"}) do
		local ring = ringsFolder:FindFirstChild(ringName)
		if ring then
			local wallBarrier = ring:FindFirstChild("Wall_Barrier")
			if wallBarrier and wallBarrier:IsA("BasePart") then
				wallBarrier.CanCollide = false
				wallBarrier.Transparency = 1

				wallBarrier.Touched:Connect(function(hit)
					local char = hit.Parent
					if not char or not char:FindFirstChild("Humanoid") then return end
					
					local player = Players:GetPlayerFromCharacter(char)
					if player then
						local uid = player.UserId
						touchCount[uid] = (touchCount[uid] or 0) + 1
						
						if not playersInRing[uid] then
							playersInRing[uid] = true
							ringNotificationRemote:FireClient(player, true)
						end
					end
				end)

				wallBarrier.TouchEnded:Connect(function(hit)
					local char = hit.Parent
					if not char or not char:FindFirstChild("Humanoid") then return end
					
					local player = Players:GetPlayerFromCharacter(char)
					if player then
						local uid = player.UserId
						touchCount[uid] = (touchCount[uid] or 0) - 1
						
						if touchCount[uid] <= 0 then
							touchCount[uid] = nil
							playersInRing[uid] = nil
							ringNotificationRemote:FireClient(player, false)
						end
					end
				end)
			end
		end
	end
end

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
