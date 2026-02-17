local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local SPEED = 0.0009

-- GLOBAL CONTROL: Por defecto ciclo día/noche HABILITADO
_G.ClockEnabled = _G.ClockEnabled or true
Lighting.ClockTime = 12

RunService.Heartbeat:Connect(function(dt)
	-- Solo avanzar el tiempo si está habilitado
	if _G.ClockEnabled then
		Lighting.ClockTime = Lighting.ClockTime + SPEED * dt * 20

		if Lighting.ClockTime >= 24 then
			Lighting.ClockTime = Lighting.ClockTime - 24
		end
	end
end)
