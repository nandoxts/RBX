--[[
	Made with love by iscoru95 07/06/2021
	https://www.youtube.com/iscoru95
]]
local COOLDOWN = 1
local tool = script.Parent
local contextActionService = game:GetService("ContextActionService")
--anim
local animIdle = script:WaitForChild("Idle")
local animPunchR = script:WaitForChild("PunchR")
local animPunchL = script:WaitForChild("PunchL")
local animBlock = script:WaitForChild("Block")
local animKick = script:WaitForChild("Kick")
local animTrack
local attack = 0 -- auxiliar para las animaciones de golpe
local eventPunch = script.Parent:WaitForChild("Punch")
local eventBlock = script.Parent:WaitForChild("Block")
local modeAttack = false

local aux = true

-- al equipar la tool
tool.Equipped:Connect(function()
	local humanoid = script.Parent.Parent.Humanoid
	modeAttack = true
	animTrack = humanoid:LoadAnimation(animIdle)
	animTrack:Play()
end)

-- al desequipar la tool
tool.Unequipped:Connect(function()
	modeAttack = false
	animTrack:Stop()
end)


-- creamos la funcion que detectera los botones
function fightButton(actionName, inputState, inputObject)
	if modeAttack then
		if actionName == "leftPunch" then
			if inputState == Enum.UserInputState.Begin and aux then
				aux = false
				local humanoid = script.Parent.Parent.Humanoid
				local anim = humanoid:LoadAnimation(animPunchL)
				anim:Play()
				eventPunch:FireServer(1 , true)
				wait(COOLDOWN)
				aux = true
			end
		elseif actionName == "rightPunch" then
			if inputState == Enum.UserInputState.Begin and aux then
				aux = false
				local humanoid = script.Parent.Parent.Humanoid
				local anim = humanoid:LoadAnimation(animPunchR)
				anim:Play()
				eventPunch:FireServer(0 , true)
				wait(COOLDOWN)
				aux = true
			end
		elseif actionName == "block" then
			if inputState == Enum.UserInputState.Begin and aux then
				aux = false
				local humanoid = script.Parent.Parent.Humanoid
				local anim = humanoid:LoadAnimation(animBlock)
				anim:Play()
				eventBlock:FireServer(true)
				wait(COOLDOWN)
				eventBlock:FireServer(false)
				anim:Stop()
				aux = true
			end
		elseif actionName == "kick" then
			if inputState == Enum.UserInputState.Begin and aux then
				aux = false
				local humanoid = script.Parent.Parent.Humanoid
				local anim = humanoid:LoadAnimation(animKick)
				anim:Play()
				eventPunch:FireServer(2 , true)
				wait(COOLDOWN)
				aux = true
			end
		end	
	end
end

-- context action service para crear botones
contextActionService:BindAction("leftPunch",fightButton, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
contextActionService:BindAction("rightPunch", fightButton, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
contextActionService:BindAction("block", fightButton, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
contextActionService:BindAction("kick", fightButton, true, Enum.KeyCode.R, Enum.KeyCode.ButtonB)
warn()
contextActionService:SetTitle("leftPunch", "Q")
contextActionService:SetTitle("rightPunch", "E")
contextActionService:SetTitle("block", "F")
contextActionService:SetTitle("kick", "R")

contextActionService:SetPosition("leftPunch", UDim2.new(-0.1, 0,0.4, 0))
contextActionService:SetPosition("rightPunch", UDim2.new(0.2, 0,0.4, 0))
contextActionService:SetPosition("block", UDim2.new(0.05, 0,0.1, 0))
contextActionService:SetPosition("kick", UDim2.new(0.05, 0,0.7, 0))