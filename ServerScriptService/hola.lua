local PhysService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

pcall(function() 
	PhysService:CreateCollisionGroup("Players")
end)
PhysService:CollisionGroupSetCollidable("Players", "Players", false)

local function NoCollide(char)
	for _, v in ipairs(char:FindDescendants()) do
		if v:IsA("BasePart") then
			pcall(function()
				PhysService:CollisionGroupAddMember("Players", v)
			end)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		NoCollide(char)
	end)
	
	if player.Character then
		NoCollide(player.Character)
	end
end)