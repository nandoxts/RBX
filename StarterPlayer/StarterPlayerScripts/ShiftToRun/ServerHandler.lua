script.Parent.Parent:FindFirstChildWhichIsA("Humanoid").WalkSpeed = script.Parent.Configuration.MinimumSpeed.Value

local BOOST_SPEED = 35

script.Run.OnServerEvent:Connect(function(plr, information)
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then return end
	
	if information == "RunActive" then
		game:GetService("TweenService"):Create(hum, TweenInfo.new(script.Parent.Configuration.AccelerationTime.Value, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {WalkSpeed = script.Parent.Configuration.MaximumSpeed.Value}):Play()
	elseif information == "RunDisable" then
		game:GetService("TweenService"):Create(hum, TweenInfo.new(script.Parent.Configuration.DeaccelerationTime.Value, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {WalkSpeed = script.Parent.Configuration.MinimumSpeed.Value}):Play()
	elseif information == "ShiftActive" then
		-- SHIFT activa velocidad instantánea sin tween
		hum.WalkSpeed = BOOST_SPEED
	elseif information == "ShiftDisable" then
		-- SHIFT desactiva vuelve a velocidad normal sin tween
		hum.WalkSpeed = script.Parent.Configuration.MinimumSpeed.Value
	end
end)