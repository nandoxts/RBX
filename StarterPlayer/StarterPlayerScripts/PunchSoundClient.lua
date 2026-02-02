-- ════════════════════════════════════════════════════════════════
-- PUNCH SOUND CLIENT - Reproduce sonidos de golpe localmente
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Obtener remote de sonido
local soundRemote = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("Combat"):WaitForChild("PunchSoundRemote")

-- Constantes
local PUNCH_SOUND_ID = "rbxassetid://4766118952"

-- Reproducir sonido cuando el servidor dispara el evento
soundRemote.OnClientEvent:Connect(function(punchPos)
	-- Crear sound object
	local sound = Instance.new("Sound")
	sound.SoundId = PUNCH_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = workspace
	
	-- Posicionar el sonido en el lugar del golpe
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = punchPos
	part.Parent = workspace
	sound.Parent = part
	
	sound:Play()
	Debris:AddItem(part, 1)
end)
