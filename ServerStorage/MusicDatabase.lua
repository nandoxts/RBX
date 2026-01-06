-- ModuleScript en ServerStorage > MusicDatabase
-- Sistema basado en DJs
local MusicDatabase = {}

-- Estructura de DJs con sus canciones y portadas
MusicDatabase.djs = {
	["DJ Alex"] = {
		cover = "rbxassetid://0", -- Reemplazar con ID de imagen real
		userId = 123456789,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false}, -- Template
		}
	},

	["DJ Studio"] = {
		cover = "rbxassetid://0",
		userId = 987654321,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false},
		}
	},

	["DJ Vibes"] = {
		cover = "rbxassetid://0",
		userId = 111222333,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false},
		}
	},

	["DJ Beats"] = {
		cover = "rbxassetid://0",
		userId = 444555666,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false},
		}
	},

	["DJ Chill"] = {
		cover = "rbxassetid://0",
		userId = 777888999,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false},
		}
	},

	["DJ Energy"] = {
		cover = "rbxassetid://0",
		userId = 101112131,
		songs = {
			{id = 0, name = "", artist = "", duration = 0, verified = false},
		}
	}
}

-- Metadatos del sistema
MusicDatabase.metadata = {
	version = "3.0",
	lastUpdated = "2025-01-01",
	totalSongs = 0,
	djs = {}
}

-- Función para obtener canciones por DJ
function MusicDatabase:getSongsByDJ(djName)
	if self.djs[djName] then
		return self.djs[djName].songs or {}
	end
	return {}
end

-- Función para obtener todos los DJs
function MusicDatabase:getDJs()
	local djsList = {}
	for djName, djData in pairs(self.djs) do
		table.insert(djsList, {
			name = djName,
			cover = djData.cover,
			userId = djData.userId,
			songCount = #(djData.songs or {})
		})
	end
	return djsList
end

-- Función para agregar nueva canción a un DJ
function MusicDatabase:addSongToDJ(djName, songData)
	if not self.djs[djName] then
		self.djs[djName] = {
			cover = "rbxassetid://0",
			userId = 0,
			songs = {}
		}
	end

	-- Verificar que no exista ya
	for _, song in ipairs(self.djs[djName].songs) do
		if song.id == songData.id then
			return false -- Ya existe
		end
	end

	table.insert(self.djs[djName].songs, songData)
	return true
end

-- Función para obtener todas las canciones (flat)
function MusicDatabase:getAllSongs()
	local allSongs = {}
	for djName, djData in pairs(self.djs) do
		for _, song in ipairs(djData.songs) do
			if song.id > 0 then -- Solo canciones válidas
				song.djName = djName
				table.insert(allSongs, song)
			end
		end
	end
	return allSongs
end

-- Función para buscar canción por ID
function MusicDatabase:findSongById(audioId)
	for djName, djData in pairs(self.djs) do
		for _, song in ipairs(djData.songs) do
			if song.id == audioId then
				song.djName = djName
				return song
			end
		end
	end
	return nil
end

-- Función para generar estadísticas
function MusicDatabase:getStats()
	local stats = {
		totalCategories = 0,
		totalSongs = 0,
		categoriesData = {}
	}

	for djName, djData in pairs(self.djs) do
		local validSongs = 0
		for _, song in ipairs(djData.songs or {}) do
			if song.id > 0 then
				validSongs = validSongs + 1
			end
		end

		stats.djsData[djName] = {
			count = validSongs,
			songs = djData.songs or {}
		}

		stats.totalDJs = stats.totalDJs + 1
		stats.totalSongs = stats.totalSongs + validSongs
	end

	return stats
end

return MusicDatabase