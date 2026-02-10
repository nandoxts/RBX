-- ════════════════════════════════════════════════════════════════
-- RING COMBAT SYSTEM - Server
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local CombatFolder = RemotesGlobal:WaitForChild("Combat")

local function getOrCreateRemote(name)
	local remote = CombatFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = CombatFolder
	end
	return remote
end

local eventPunch = getOrCreateRemote("PunchRemote")
local eventBlock = getOrCreateRemote("BlockRemote")
local ringStateRemote = getOrCreateRemote("RingStateRemote")
local effectRemote = getOrCreateRemote("EffectRemote")

local DAMAGE = 10
local PUNCH_SOUND_ID = "rbxassetid://4766118952"

local effectPunch = ReplicatedStorage:WaitForChild("Effect"):WaitForChild("Part")

-- Tabla para rastrear estado de jugadores
local playerStates = {}  -- "FREE", "WAITING", "FIGHTING"
local activePunches = {}

---------------------------------------------------
-- EFECTO DE GOLPE
---------------------------------------------------
local function effect(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local clone = effectPunch:Clone()
	clone.Parent = hrp
	clone.CFrame = CFrame.new(hrp.Position)

	for i = 1, 15 do
		clone.Transparency = clone.Transparency + (1/15)
		clone.Size = clone.Size + Vector3.new(1.5, 1.5, 0)
		task.wait(0.03)
	end

	clone:Destroy()
end

local function playPunchSound(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local soundClone = Instance.new("Sound")
	soundClone.SoundId = PUNCH_SOUND_ID
	soundClone.Volume = 0.5
	soundClone.Parent = hrp
	soundClone:Play()
	Debris:AddItem(soundClone, 1)
end

---------------------------------------------------
-- LÓGICA DE GOLPE
---------------------------------------------------
local function hitDetection(humanoid, character)
	playPunchSound(character)

	local blockValue = character:FindFirstChild("block")
	if blockValue and blockValue.Value == true then
		print("[ServerCombat] Golpe bloqueado")
		return
	end

	humanoid:TakeDamage(DAMAGE)
	effect(character)
end

---------------------------------------------------
-- EVENTOS DE JUGADORES
---------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	playerStates[player.UserId] = "FREE"

	player.CharacterAdded:Connect(function()
		playerStates[player.UserId] = "FREE"
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerStates[player.UserId] = nil
	activePunches[player.UserId] = nil
end)

-- Sincronización de estado desde Ring Script
ringStateRemote.OnServerEvent:Connect(function(player, newState)
	if newState == "WAITING" or newState == "FIGHTING" or newState == "FREE" then
		playerStates[player.UserId] = newState
		print("[ServerCombat] Estado actualizado:", player.Name, "→", newState)
	end
end)

---------------------------------------------------
-- EVENTO DE GOLPE
---------------------------------------------------
eventPunch.OnServerEvent:Connect(function(player, num, punchId)
	local character = player.Character
	if not character then return end

	-- SOLO permitir golpes si está EN PELEA
	local currentState = playerStates[player.UserId]
	if currentState ~= "FIGHTING" then
		print("[ServerCombat] Golpe bloqueado - Estado:", currentState or "nil")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Evitar duplicados
	local punchKey = player.UserId .. "_" .. punchId
	if activePunches[punchKey] then 
		print("[ServerCombat] Golpe duplicado ignorado")
		return 
	end
	activePunches[punchKey] = true

	-- Tiempo de ventana de detección
	local waitTime = (num == 2) and 1.0 or 0.7
	local hitTargets = {}
	local connections = {}
	local detected = false

	local bodyParts = character:GetChildren()

	for _, part in ipairs(bodyParts) do
		if part:IsA("BasePart") then
			local connection = part.Touched:Connect(function(hit)
				local targetChar = hit.Parent
				if not targetChar or not targetChar:FindFirstChild("Humanoid") then return end
				if targetChar == character then return end
				if hitTargets[targetChar] then return end

				local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
				if not targetHumanoid or targetHumanoid.Health <= 0 then return end

				-- Verificar que el objetivo TAMBIÉN está en pelea
				local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
				if not targetPlayer then return end

				local targetState = playerStates[targetPlayer.UserId]
				if targetState ~= "FIGHTING" then 
					print("[ServerCombat] Objetivo no está en pelea:", targetState or "nil")
					return 
				end

				hitTargets[targetChar] = true
				detected = true

				print("[ServerCombat] GOLPE:", player.Name, "→", targetChar.Name)
				hitDetection(targetHumanoid, targetChar)

				-- Efecto visual en el cliente
				effectRemote:FireClient(targetPlayer)
			end)
			table.insert(connections, connection)
		end
	end

	-- Esperar ventana de detección
	task.wait(waitTime)

	-- Desconectar
	for _, connection in ipairs(connections) do
		pcall(function() connection:Disconnect() end)
	end

	activePunches[punchKey] = nil

	if not detected then
		print("[ServerCombat] Golpe sin impacto")
	end
end)

---------------------------------------------------
-- EVENTO DE BLOQUEO
---------------------------------------------------
eventBlock.OnServerEvent:Connect(function(player, block)
	local character = player.Character
	if not character then return end

	local blockValue = character:FindFirstChild("block")
	if not blockValue then
		blockValue = Instance.new("BoolValue")
		blockValue.Name = "block"
		blockValue.Parent = character
	end

	blockValue.Value = block

	if block then
		print("[ServerCombat] Bloqueo activado:", player.Name)
	end
end)