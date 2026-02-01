--[[
	Made with love by iscoru95 07/06/2021
	https://www.youtube.com/iscoru95
]]
local DAMAGE = 10 -- MODIFICAR DEPENDIENDO DEL DAÑO QUE SE QUIERA HACER
--
local eventPunch = script.Parent:WaitForChild("Punch")
local eventBlock = script.Parent:WaitForChild("Block")
local effectPunch = game.ReplicatedStorage.Effect:WaitForChild("Part")
--
local players = game:GetService("Players")

local soundPunch = script.Sound

function effect(character)
	local clone = effectPunch:Clone()
	clone.Parent = character.HumanoidRootPart
	clone.CFrame = CFrame.new(character.HumanoidRootPart.Position)
	repeat
		clone.Transparency += 0.1
		clone.Size += Vector3.new(1,1,0)
		wait()
	until clone.Transparency == 1
	clone:Destroy()
end

-- aqui detecta si esta bloqueando ataques
function hitDetection(humanoid, character)
	local soundClone = soundPunch:Clone()
	soundClone.Parent = character.HumanoidRootPart
	soundClone:Play()
	game.Debris:AddItem(soundClone, 1)
	
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

-- ver el evento para hacer daño dependiendo del numero es el objeto que tomara de referencia
-- para hacer daño
eventPunch.OnServerEvent:Connect(function(player, num, aux)
	if num == 0 then
		-- objetener mano derecha
		local rightHand = player.Character.RightHand
		local connection = rightHand.Touched:Connect(function(hit)
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid and aux then
				aux = false
				hitDetection(humanoid,hit.Parent)
			end
		end) -- si la mano que golpea nos toca
		wait(0.5)
		connection:Disconnect()
	elseif num == 1 then
		-- objetener mano izquierda
		local leftHand = player.Character.LeftHand
		local connection = leftHand.Touched:Connect(function(hit)
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid and aux then
				aux = false
				hitDetection(humanoid,hit.Parent)
			end
		end) -- si la mano que golpea nos toca
		wait(0.5)
		connection:Disconnect()
	elseif num == 2 then
		-- objetener pie derecho
		local rightFood = player.Character.RightFoot
		local connection = rightFood.Touched:Connect(function(hit)
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid and aux then
				aux = false
				hitDetection(humanoid,hit.Parent)
			end
		end) -- si la mano que golpea nos toca
		wait(0.5)
		connection:Disconnect()
	end
end)

-- activa o desactiva el bool value
eventBlock.OnServerEvent:Connect(function(player, block)
	if block then
		player.Character.block.Value = true
	else 
		player.Character.block.Value = false
	end
end)