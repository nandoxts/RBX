--[[ SERVICES ]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")

--[[ REMOTES ]]--
local Remotes = ReplicatedStorage:WaitForChild("Emotes_Sync")
local syncremote = Remotes.Sync

local Remotos = ReplicatedStorage:WaitForChild("Eventos_Emote")
-- Usar NotificationSystem local en el cliente en vez de RemoteNoti
local NotificationSystem = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))


--[[ LOCALS ]]--

local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local GUI = script.BillboardGui
local Target

local SyncKey = Enum.KeyCode.E
local debounce = false


--[[ SYNC AIM GUI ]]--

UserInputService.InputChanged:Connect(function(Input, Processed)
	Target = nil
	if Input.UserInputType == Enum.UserInputType.MouseMovement 
		or Input.UserInputType == Enum.UserInputType.Touch then 

		local MouseTarget = Mouse.Target
		if not MouseTarget then return end

		local Humanoid = MouseTarget.Parent:FindFirstChild("Humanoid")
			or MouseTarget.Parent.Parent:FindFirstChild("Humanoid")

		if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R15 then

			local msg = (Input.UserInputType == Enum.UserInputType.MouseMovement) and "Sync E" or "Sync"

			Target = Players:GetPlayerFromCharacter(Humanoid.Parent)

			if Target then
				local upper = Humanoid.Parent:FindFirstChild("UpperTorso")
				if upper then
					GUI.Adornee = upper
					GUI.Parent = workspace
					GUI.SyncText.Text = msg
					GUI.SyncText.Visible = true
				end
			end

		else
			GUI.Adornee = nil
			GUI.Parent = nil
			GUI.SyncText.Visible = false
		end
	end
end)


-- =====================================================
--  NOTIFICACIÓN AL SINCRONIZAR 
-- =====================================================

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Input.KeyCode == SyncKey then
		if not Target then return end
		if debounce then return end
		debounce = true

		if Player.Character.SyncOnOff.Value then

			syncremote:FireServer("unsync")

			-- Enviar notificación con validación
			pcall(function()
				NotificationSystem:Info("Sync", "Has dejado de estar sincronizado", 4)
			end)

		else
			-- Validar que Target existe antes de usar
			if Target and Target.Name then
				syncremote:FireServer("sync", Target)

				-- Enviar notificación con validación de nombre
				local targetName = tostring(Target.Name):sub(1, 50) -- Limitar a 50 caracteres
				pcall(function()
					NotificationSystem:Success("Sync", "Ahora estás sincronizado con: " .. targetName, 4)
				end)
			else
				debounce = false
				return
			end
		end

		task.wait(1)
		debounce = false
	end
end)
