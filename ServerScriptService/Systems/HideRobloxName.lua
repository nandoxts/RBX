game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end)
end)