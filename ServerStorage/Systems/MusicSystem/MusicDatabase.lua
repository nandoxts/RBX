-- ModuleScript en ServerStorage > MusicDatabase
-- Sistema basado en DJs
-- NOTA: Este módulo se mantiene por compatibilidad
-- La configuración principal ahora está en ReplicatedStorage/Config/MusicSystemConfig

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

local MusicDatabase = {}

-- Estructura de DJs con sus canciones y portadas
-- Ahora se obtiene desde MusicConfig.DEFAULT_DJS
MusicDatabase.djs = {}

-- Cargar DJs desde configuración
for _, djData in ipairs(MusicConfig:GetDJs()) do
	MusicDatabase.djs[djData.name] = {
		cover = djData.cover,
		userId = djData.userId,
		songs = djData.songs
	}
end

MusicDatabase.metadata = {
	version = "3.0",
	lastUpdated = "2025-01-01",
	totalSongs = 0,
	djs = {}
}

return MusicDatabase