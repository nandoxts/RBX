-- ════════════════════════════════════════════════════════════════
-- RING COMBAT - VERSIÓN SIMPLE
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local DAMAGE = 10  -- Daño base por golpe
local PUNCH_SOUND_ID = "rbxassetid://4766118952"

-- Obtener efecto de golpe desde ReplicatedStorage (esperar a que cargue)
local effectPunch = ReplicatedStorage.Effect:WaitForChild("Part")

-- Función para crear efecto visual de golpe
local function effect(character)
	local clone = effectPunch:Clone()
	clone.Parent = character.HumanoidRootPart
	clone.CFrame = CFrame.new(character.HumanoidRootPart.Position)
	repeat
		clone.Transparency += 0.1
		clone.Size += Vector3.new(1, 1, 0)
		wait()
	until clone.Transparency == 1
	clone:Destroy()
end

-- Función para reproducir sonido
local function playPunchSound(character)
	local soundClone = Instance.new("Sound")
	soundClone.SoundId = PUNCH_SOUND_ID
	soundClone.Volume = 0.5
	soundClone.Parent = character.HumanoidRootPart
	soundClone:Play()
	Debris:AddItem(soundClone, 1)
end

-- Obtener remotes que ya fueron creados manualmente
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local CombatRemotes = RemotesGlobal:WaitForChild("Combat")
local eventPunch = CombatRemotes:WaitForChild("PunchRemote")
local eventBlock = CombatRemotes:WaitForChild("BlockRemote")
local ringNotificationRemote = CombatRemotes:WaitForChild("RingNotification")

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
eventPunch.OnServerEvent:Connect(function(player, num, aux)
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
	
	-- Determinar qué parte del cuerpo golpea
	local bodyPart
	if num == 0 then
		bodyPart = player.Character:FindFirstChild("RightHand")
	elseif num == 1 then
		bodyPart = player.Character:FindFirstChild("LeftHand")
	elseif num == 2 then
		bodyPart = player.Character:FindFirstChild("RightFoot")
	end
	
	if not bodyPart then return end
	
	-- Conectar detección de toque
	local connection
	connection = bodyPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid and aux and hit.Parent ~= player.Character then
			aux = false
			hitDetection(humanoid, hit.Parent)
		end
	end)
	
	task.wait(0.5)
	connection:Disconnect()
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
