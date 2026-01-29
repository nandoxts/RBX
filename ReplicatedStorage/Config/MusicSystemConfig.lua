--[[
	═══════════════════════════════════════════════════════════
	MUSIC SYSTEM - CONFIGURACIÓN
	═══════════════════════════════════════════════════════════
	Autor: nandoxts
	Versión: 3.2 (Simplificado)
]]

local MusicSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- CONFIGURACIÓN GENERAL
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.SYSTEM = {
	Version = "3.2",
}

-- ═══════════════════════════════════════════════════════════
-- ADMINISTRADORES
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.ADMINS = {
	-- Ahora el sistema de administración usa nombres de usuario (strings).
	AdminUserNames = {
		"nandoxts", -- ejemplo
		"AngeloGarciia",
	},
	-- Si se quiere usar un módulo externo (en ReplicatedStorage/Config/AdminConfig), dejar true.
	UseExternalAdminSystem = true,
}

-- ═══════════════════════════════════════════════════════════
-- BASE DE DATOS (DATASTORE)
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.DATABASE = {
	UseDataStore = true,
	MusicLibraryStoreName = "MusicLibrary_ULTRA_v1",
}

-- ═══════════════════════════════════════════════════════════
-- LÍMITES Y RESTRICCIONES
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.LIMITS = {
	MaxQueueSize = 100,
	MaxSongsPerDJ = 500,
	AllowDuplicatesInQueue = false,
	MinAudioDuration = 10,
	MaxAudioDuration = 600,
}

-- ═══════════════════════════════════════════════════════════
-- REPRODUCCIÓN Y AUDIO
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.PLAYBACK = {
	DefaultVolume = 0.8,
	AllowVolumeControl = true,
	MinVolume = 0.1,
	MaxVolume = 1.0,
	LoopQueue = false,
}

-- ═══════════════════════════════════════════════════════════
-- VALIDACIÓN DE MÚSICA
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.VALIDATION = {
	BlacklistedAudioIds = {},
}

-- ═══════════════════════════════════════════════════════════
-- PERMISOS POR ACCIÓN
-- ═══════════════════════════════════════════════════════════
MusicSystemConfig.PERMISSIONS = {
	AddToQueue = "everyone",
	RemoveFromQueue = "admin",
	ClearQueue = "admin",
	MoveInQueue = "admin",
	PlaySong = "admin",
	PauseSong = "admin",
	StopSong = "admin",
	NextSong = "everyone",
	ChangeVolume = "everyone",
	ToggleShuffle = "admin",
	ToggleLoop = "admin",
}

-- ═══════════════════════════════════════════════════════════
-- DJS PREDETERMINADOS
-- ═══════════════════════════════════════════════════════════
--[[ FORMATO DE EJEMPLO:
	["NOMBRE DJ"] = {          -- NOMBRE DJ
		ImageId = "rbxassetid://123456789", -- IMAGEN DJ
		SongIds = {            -- IDs de canciones separadas por coma
			18411501,
			18411502,
			18411503,
			18411504
		}
	}
]]

function MusicSystemConfig:GetDJs()
	return {
		["Cumbia"] = {
			ImageId = "rbxassetid://82820894229931",
			SongIds = {
				},
		},

		["Salsa"] = { -- NOMBRE DJ
			ImageId = "rbxassetid://73115458503706",-- IMAGEN DJ
			SongIds = { -- IDs separadas por id,id,id,id............
				140506188286449, 120649766410203, 94850419745898, 122340610856520, 103152861754174, 129361136126231, 105346792761065, 109329374692164, 117545675995330, 86448088429823, 92163101233862, 118511172466432, 91697248735668, 126551515888884, 85527232277037, 79343388378585, 83695295034599, 74257756654407, 114483787919937, 99845441516508, 133048336551434, 85427246506569, 70782468787906, 80442137918200, 111951092239695, 136516482282348, 134521117439600, 136110744165152, 129683779602929, 125243070282754, 79928505400448, 120599497074675, 90810190033114, 109719973130780, 76991972751085, 115467965801325, 112283187344137, 139753325350965, 87013026375437, 71175635510424, 124730068307804, 77390618785111,
			
			},
		},

		["Mix Brazil"] = { -- NOMBRE DJ
			ImageId = "rbxassetid://133333429110190",-- IMAGEN DJ
			SongIds = { -- IDs separadas por id,id,id,id............
				118475929781897, 100162022613648, 105071061028509, 139441579804929, 98253761476816, 129917123815497, 87458599882787, 104683317035212, 114871460534604, 138767601772707, 84442802153489, 114778363080229, 117113990967417, 123313324448889, 99574568346974, 85325798989617, 71292544810269, 90107564509940, 72314143736902, 103619280117583, 136386334399837, 76971939215142, 79444446276275, 107944809834572, 139401242053336, 138554969621712, 106927068291003, 104644613949445, 128723385133929, 74214056983597, 78007588887565, 105881470191142

			},
		},

		["Kpop Army"] = { -- NOMBRE DJ
			ImageId = "rbxassetid://80104537952891",-- IMAGEN DJ
			SongIds = { -- IDs separadas por id,id,id,id............
				138938512309640, 75956052996399, 84354203386250, 121523590923056, 111117996632596, 96849535576718, 97213218951425, 136881133516344, 97400650950900, 140462626806183, 121328550130922, 80065900108600, 72324207136429
			},
		},

		["DJ Angelisai"] = { -- NOMBRE DJ
			ImageId = "rbxassetid://71898911209825",-- IMAGEN DJ
			SongIds = { -- IDs separadas por id,id,id,id............
			
			},
		},

	}
end

-- ═══════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════

-- Verificar si un usuario es admin
function MusicSystemConfig:IsAdmin(user)
	-- Acepta Player instance o nombre string. Convertir a nombre.
	local name
	if typeof(user) == "Instance" and user.Name then
		name = user.Name
	elseif type(user) == "string" then
		name = user
	else
		return false
	end

	-- Intentar usar AdminConfig en ReplicatedStorage (más moderno)
	if self.ADMINS.UseExternalAdminSystem then
		local ok, adminModule = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("AdminConfig"))
		end)
		if ok and adminModule and adminModule.IsAdmin then
			return adminModule:IsAdmin(name)
		end
	end

	-- Fallback a lista local de nombres
	for _, adminName in ipairs(self.ADMINS.AdminUserNames or {}) do
		if adminName == name then
			return true
		end
	end
	return false
end

-- Verificar permiso para una acción
function MusicSystemConfig:HasPermission(userOrPlayer, action)
	local permission = self.PERMISSIONS[action]

	if not permission then
		return false -- Acción no configurada
	end

	if permission == "everyone" then
		return true
	elseif permission == "admin" then
		-- userOrPlayer puede ser UserId (number), Player (Instance) o nombre (string)
		if type(userOrPlayer) == "number" then
			local Players = game:GetService("Players")
			local plr = Players:GetPlayerByUserId(userOrPlayer)
			return self:IsAdmin(plr)
		else
			return self:IsAdmin(userOrPlayer)
		end
	elseif permission == "vip" then
		-- Implementar lógica de VIP si es necesario; por ahora tratar como admin
		if type(userOrPlayer) == "number" then
			local Players = game:GetService("Players")
			local plr = Players:GetPlayerByUserId(userOrPlayer)
			return self:IsAdmin(plr)
		else
			return self:IsAdmin(userOrPlayer)
		end
	end

	return false
end

-- Validar Audio ID
function MusicSystemConfig:ValidateAudioId(audioId)
	if not audioId or audioId <= 0 then
		return false, "ID de audio inválido"
	end

	-- Verificar blacklist
	for _, blacklistedId in ipairs(self.VALIDATION.BlacklistedAudioIds) do
		if audioId == blacklistedId then
			return false, "Este audio está en la lista negra"
		end
	end

	return true
end

-- Validar duración de audio
function MusicSystemConfig:ValidateDuration(duration)
	if duration < self.LIMITS.MinAudioDuration then
		return false, "Audio muy corto (mínimo " .. self.LIMITS.MinAudioDuration .. "s)"
	end

	if duration > self.LIMITS.MaxAudioDuration then
		return false, "Audio muy largo (máximo " .. self.LIMITS.MaxAudioDuration .. "s)"
	end

	return true
end

-- Obtener volumen predeterminado
function MusicSystemConfig:GetDefaultVolume()
	return self.PLAYBACK.DefaultVolume
end

-- Validar volumen
function MusicSystemConfig:ValidateVolume(volume)
	if not self.PLAYBACK.AllowVolumeControl then
		return false, "Control de volumen deshabilitado"
	end

	if volume < self.PLAYBACK.MinVolume or volume > self.PLAYBACK.MaxVolume then
		return false, string.format("Volumen debe estar entre %.1f y %.1f", 
			self.PLAYBACK.MinVolume, self.PLAYBACK.MaxVolume)
	end

	return true
end

-- Obtener configuración de DJs por defecto
-- Backwards-compatible alias
function MusicSystemConfig:GetDefaultDJs()
	return self:GetDJs()
end

return MusicSystemConfig
