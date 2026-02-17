local Players = game:GetService("Players")

local toolsFolder = script:WaitForChild("Tools")

local adminUserIds = {
	5819550352,
	8387751399,
	1836329833,
	4074563891,
}

local function isAdmin(player)
	for _, id in ipairs(adminUserIds) do
		if player.UserId == id then
			return true
		end
	end
	return false
end

local function giveAdminTools(player)
	local backpack = player:WaitForChild("Backpack")

	for _, tool in ipairs(toolsFolder:GetChildren()) do
		if tool:IsA("Tool") then
			local clone = tool:Clone()
			clone.Parent = backpack
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	if not isAdmin(player) then return end

	player.CharacterAdded:Connect(function()
		giveAdminTools(player)
	end)
end)
