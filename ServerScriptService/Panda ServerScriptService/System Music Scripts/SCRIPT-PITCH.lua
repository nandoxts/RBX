--[[
▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

██╗     ██╗ ██████╗███████╗███╗   ██╗███████╗███████╗
██║     ██║██╔════╝██╔════╝████╗  ██║██╔════╝██╔════╝
██║     ██║██║     █████╗  ██╔██╗ ██║███████╗█████╗  
██║     ██║██║     ██╔══╝  ██║╚██╗██║╚════██║██╔══╝  
███████╗██║╚██████╗███████╗██║ ╚████║███████║███████╗
╚══════╝╚═╝ ╚═════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝
-- www.panda15fps.com
▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

/* Copyright (C) 2025 Panda - All rights reserved
 * You only have the right to modify the file.
 *
 * It is strictly forbidden to resell the code,
 * copy the code, distribute the code and above
 * all to make an image of the code.
 * If you want to do this, contact Panda15Fps
 *
 * Remember that any violation will result in a report
 * for unauthorized use of copyright and the ban for
 * this is permanent as well as the closure of the game.
 *
 * https://discord.gg/jmQCcC28Fd
 */

▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
]]

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

-- Configuración
local MUSIC_SOUND_NAME = "THEME"
local QUEUE_SOUND_NAME = "QueueSound"
local ASSET_PREFIX = "rbxassetid://"
local DEFAULT_PITCH = 1
local DEBOUNCE_DELAY = 0.05

-- Obtener referencias al sonido
local sound = SoundService:FindFirstChild(MUSIC_SOUND_NAME)
local queueSound = SoundService:FindFirstChild(QUEUE_SOUND_NAME)

-- Cargar módulo con manejo de errores
local pitchModule
local success, err = pcall(function()
	pitchModule = require(script.PitchModule)
end)

if not success then
	--warn("Error al cargar el módulo de pitch:", err)
	return
end

-- Verificación mejorada del módulo
if type(pitchModule) ~= "table" or not pitchModule.ids or type(pitchModule.ids) ~= "table" then
	--warn("El módulo de pitch no tiene la estructura esperada. Contenido:", pitchModule)
	return
end

-- Optimización: Crear tabla de búsqueda
local pitchLookup = {}
for _, entry in ipairs(pitchModule.ids) do
	if entry.id and entry.pitch then
		pitchLookup[ASSET_PREFIX .. entry.id] = tonumber(entry.pitch) or DEFAULT_PITCH
	end
end

-- Función para actualizar el pitch
local function updatePitch(targetSound)
	if not targetSound or not targetSound:IsA("Sound") then return end
	local pitch = pitchLookup[targetSound.SoundId] or DEFAULT_PITCH
	targetSound.PlaybackSpeed = pitch
end

-- Función con manejo de errores
local function safeUpdatePitch(targetSound)
	local success, err = pcall(function()
		updatePitch(targetSound)
	end)
	if not success then
		--warn("Error al actualizar el pitch:", err)
		if targetSound then targetSound.PlaybackSpeed = DEFAULT_PITCH end
	end
end

-- Conectar evento de cambio para THEME sound
if sound then
	safeUpdatePitch(sound)
	
	local debounce = false
	sound:GetPropertyChangedSignal("SoundId"):Connect(function()
		if debounce then return end
		debounce = true
		task.delay(DEBOUNCE_DELAY, function()
			safeUpdatePitch(sound)
			debounce = false
		end)
	end)
end

-- Monitorear QueueSound en SoundService (DjDashboard)
if queueSound then
	safeUpdatePitch(queueSound)
	
	local debounce = false
	queueSound:GetPropertyChangedSignal("SoundId"):Connect(function()
		if debounce then return end
		debounce = true
		task.delay(DEBOUNCE_DELAY, function()
			safeUpdatePitch(queueSound)
			debounce = false
		end)
	end)
else
	-- Si no existe aún, intentar encontrarlo periódicamente
	game:GetService("RunService").Heartbeat:Connect(function()
		if not queueSound then
			queueSound = SoundService:FindFirstChild(QUEUE_SOUND_NAME)
			if queueSound and not queueSound:GetAttribute("PitchMonitored") then
				queueSound:SetAttribute("PitchMonitored", true)
				safeUpdatePitch(queueSound)
				
				local debounce = false
				queueSound:GetPropertyChangedSignal("SoundId"):Connect(function()
					if debounce then return end
					debounce = true
					task.delay(DEBOUNCE_DELAY, function()
						safeUpdatePitch(queueSound)
						debounce = false
					end)
				end)
			end
		end
	end)
end