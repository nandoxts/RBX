local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local MI_USERID = 197012474 
local tool = ServerStorage:WaitForChild("GrabTool")

Players.PlayerAdded:Connect(function(player)
	if player.UserId == MI_USERID then
		player.CharacterAdded:Connect(function(character)
			local backpack = player:WaitForChild("Backpack")
			local toolClone = tool:Clone()
			toolClone.Parent = backpack
		end)
	end
end)print("Hello world!")
