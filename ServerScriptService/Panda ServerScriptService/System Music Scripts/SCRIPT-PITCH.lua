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

-- Configuración
local MUSIC_SOUND_NAME = "THEME"
local ASSET_PREFIX = "rbxassetid://"
local DEFAULT_PITCH = 1
local DEBOUNCE_DELAY = 0.05

-- Obtener referencia al sonido
local sound = SoundService:FindFirstChild(MUSIC_SOUND_NAME)
if not sound then
	--warn(`No se encontró el sonido llamado '{MUSIC_SOUND_NAME}' en SoundService`)
	return
end

-- Cargar módulo con manejo de errores
local pitchModule
local success, err = pcall(function()
	pitchModule = require(script.MODULESCRIPT)
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

-- Imprimir contenido del módulo para debug
--[[
print("Contenido del módulo cargado:")
print(pitchModule)
for i, entry in ipairs(pitchModule.ids) do
	print(`Entry {i}: ID={entry.id}, Pitch={entry.pitch}`)
end
]]

-- Optimización: Crear tabla de búsqueda
local pitchLookup = {}
for _, entry in ipairs(pitchModule.ids) do
	if entry.id and entry.pitch then
		pitchLookup[ASSET_PREFIX .. entry.id] = tonumber(entry.pitch) or DEFAULT_PITCH
	end
end

-- Función para actualizar el pitch
local function updatePitch()
	local pitch = pitchLookup[sound.SoundId] or DEFAULT_PITCH
	sound.PlaybackSpeed = pitch

	-- Debug (opcional)
	--print(`Sound ID: {sound.SoundId}, Pitch set to: {pitch}`)
end

-- Función con manejo de errores
local function safeUpdatePitch()
	local success, err = pcall(updatePitch)
	if not success then
		--warn("Error al actualizar el pitch:", err)
		sound.PlaybackSpeed = DEFAULT_PITCH
	end
end

-- Llamar inicialmente
safeUpdatePitch()

-- Conectar evento de cambio con debounce
local debounce = false
sound:GetPropertyChangedSignal("SoundId"):Connect(function()
	if debounce then return end
	debounce = true

	task.delay(DEBOUNCE_DELAY, function()
		safeUpdatePitch()
		debounce = false
	end)
end)