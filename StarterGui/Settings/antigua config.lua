local TweenService = game:GetService("TweenService")
local TweenSpeed = 0.1
local Info = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0)

local function setupButton(button)
	local frame = button.Parent
	local textLabel = frame:FindFirstChild("Text")

	-- Eventos del Mouse
	button.MouseEnter:Connect(function()
		TweenService:Create(frame, Info, {BackgroundColor3 = Color3.fromRGB(72, 72, 72)}):Play()
		if textLabel then
			TweenService:Create(textLabel, Info, {TextColor3 = Color3.fromRGB(17, 17, 17)}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(frame, Info, {BackgroundColor3 = Color3.fromRGB(17, 17, 17)}):Play()
		if textLabel then
			TweenService:Create(textLabel, Info, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end
	end)

	-- Evento de clic (adaptar a cada botón)
	button.MouseButton1Click:Connect(function()
		local parent = frame.Parent.Parent.Parent
		if parent:FindFirstChild("Settings") then
			local settings = parent.Settings
			-- Ajustar visibilidad con base en el botón
			for _, child in ipairs(settings:GetChildren()) do
				if child:IsA("Frame") then
					child.Visible = child.Name == frame.Name
				end
			end
		end
	end)
end

-- Itera sobre los botones bajo SettingsOptions
for _, category in ipairs(script.Parent:GetChildren()) do
	if category:IsA("Frame") then
		local button = category:FindFirstChild("Button")
		if button then
			setupButton(button)
		end
	end
end
