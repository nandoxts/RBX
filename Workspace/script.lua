local tool = script.Parent
local part = tool:WaitForChild("Part")
local handle = tool:WaitForChild("Handle")
local particleEmitter = part:WaitForChild("ParticleEmitter")
local sound = handle:WaitForChild("Sound")

tool.Activated:Connect(function()
	particleEmitter.Enabled = true
	sound:Play()
	script.Disabled = true
	wait(2)
	particleEmitter.Enabled = false
	wait(5)
	script.Disabled = false
end)
