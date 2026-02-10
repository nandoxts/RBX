-- ════════════════════════════════════════════════════════════════
-- RING COMBAT SYSTEM
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RemotesGlobal = ReplicatedStorage:FindFirstChild("RemotesGlobal")
if not RemotesGlobal then
	RemotesGlobal = Instance.new("Folder")
	RemotesGlobal.Name = "RemotesGlobal"
	RemotesGlobal.Parent = ReplicatedStorage
end

local CombatFolder = RemotesGlobal:FindFirstChild("Combat")
if not CombatFolder then
	CombatFolder = Instance.new("Folder")
	CombatFolder.Name = "Combat"
	CombatFolder.Parent = RemotesGlobal
end

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
local ringNotificationRemote = getOrCreateRemote("RingNotification")
local effectRemote = getOrCreateRemote("EffectRemote")

local DAMAGE = 10
local PUNCH_SOUND_ID = "rbxassetid://4766118952"
local NOTIFICATION_COOLDOWN = 1

local effectPunch = ReplicatedStorage.Effect:WaitForChild("Part")
local playersInRing = {}
local lastNotification = {}
local activePunches = {}

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

local function playPunchSound(character)
	local soundClone = Instance.new("Sound")
	soundClone.SoundId = PUNCH_SOUND_ID
	soundClone.Volume = 0.5
	soundClone.Parent = character.HumanoidRootPart
	soundClone:Play()
	Debris:AddItem(soundClone, 1)
end

local function isPlayerInRingPhysically(character)
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end
	
	local hrp = character.HumanoidRootPart
	local ringsFolder = workspace:FindFirstChild("Rings")
	if not ringsFolder then return false end
	
	for _, ringName in ipairs({"Ring1", "Ring2"}) do
		local ring = ringsFolder:FindFirstChild(ringName)
		if ring then
			local baseRing = ring:FindFirstChild("BaseRingUpdate")
			if baseRing and baseRing:IsA("BasePart") then
				local hrpPos = hrp.Position
				local basePos = baseRing.Position
				local baseSize = baseRing.Size
				
				local deltaX = math.abs(hrpPos.X - basePos.X)
				local deltaZ = math.abs(hrpPos.Z - basePos.Z)
				local halfSizeX = baseSize.X / 2
				local halfSizeZ = baseSize.Z / 2
				local baseTop = basePos.Y + (baseSize.Y / 2)
				
				if deltaX <= halfSizeX and deltaZ <= halfSizeZ and hrpPos.Y >= (baseTop - 3) then
					return true
				end
			end
		end
	end
	
	return false
end

task.spawn(function()
	while true do
		task.wait(0.5)

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local uid = player.UserId
				local isInFight = player.Character.Parent and 
					(player.Character.Parent.Name == "Player1" or player.Character.Parent.Name == "Player2")
				
				if not isInFight then
					local isInRingNow = isPlayerInRingPhysically(player.Character)
					local wasInRing = playersInRing[uid] == true
					
					if isInRingNow and not wasInRing then
						playersInRing[uid] = true
						local now = os.clock()
						if not lastNotification[uid] or (now - lastNotification[uid]) > NOTIFICATION_COOLDOWN then
							lastNotification[uid] = now
							ringNotificationRemote:FireClient(player, true)
							print("[RingCombat] Entró:", player.Name)
						end
					elseif not isInRingNow and wasInRing then
						playersInRing[uid] = nil
						local now = os.clock()
						if not lastNotification[uid] or (now - lastNotification[uid]) > NOTIFICATION_COOLDOWN then
							lastNotification[uid] = now
							ringNotificationRemote:FireClient(player, false)
							print("[RingCombat] Salió:", player.Name)
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	playersInRing[uid] = nil
	lastNotification[uid] = nil
end)

local function hitDetection(humanoid, character)
	playPunchSound(character)

	local blockValue = character:FindFirstChild("block")
	if blockValue and blockValue.Value == false then
		humanoid:TakeDamage(DAMAGE)
		effect(character)
	elseif not blockValue then
		humanoid:TakeDamage(DAMAGE)
		effect(character)
	end
end

eventPunch.OnServerEvent:Connect(function(player, num, punchId)
	if not player.Character then return end
	if not playersInRing[player.UserId] then return end
	
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if not isPlayerInRingPhysically(player.Character) then
		print("[RingCombat] Golpe bloqueado:", player.Name)
		return
	end

	local punchKey = player.UserId .. "_" .. punchId
	if activePunches[punchKey] then return end
	activePunches[punchKey] = true

	local bodyParts = player.Character:GetChildren()
	local hitTargets = {}
	local connections = {}

	for _, part in ipairs(bodyParts) do
		if part:IsA("BasePart") then
			local connection = part.Touched:Connect(function(hit)
				local targetChar = hit.Parent
				if not targetChar or not targetChar:FindFirstChild("Humanoid") then return end

				local targetHumanoid = targetChar:FindFirstChild("Humanoid")

				if targetHumanoid and targetHumanoid.Health > 0 and targetChar ~= player.Character and not hitTargets[targetChar] then
					if not isPlayerInRingPhysically(targetChar) then return end
					
					hitTargets[targetChar] = true
					hitDetection(targetHumanoid, targetChar)

					local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
					if targetPlayer then
						effectRemote:FireClient(targetPlayer)
					end
				end
			end)
			table.insert(connections, connection)
		end
	end

	local waitTime = (num == 2) and 0.6 or 0.4
	task.wait(waitTime)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	activePunches[punchKey] = nil
end)

eventBlock.OnServerEvent:Connect(function(player, block)
	if not player.Character then return end

	local blockValue = player.Character:FindFirstChild("block")
	if not blockValue then
		blockValue = Instance.new("BoolValue")
		blockValue.Name = "block"
		blockValue.Parent = player.Character
	end

	blockValue.Value = block
end)