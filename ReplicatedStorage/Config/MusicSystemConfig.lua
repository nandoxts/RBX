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
	AdminUserIds = {
		8387751399,  -- nandoxts (Owner)
		9375636407,  -- Admin2
	},
	UseExternalAdminSystem = true,
	ExternalAdminModule = "CentralAdminConfig",
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
	AddToLibrary = "admin",
	RemoveFromLibrary = "admin",
	-- AddSongToDJ permission removed (feature disabled)
	RemoveSongFromDJ = "admin",
	CreateDJ = "admin",
	RemoveDJ = "admin",
	RenameDJ = "admin",
	ChangeVolume = "admin",
	ToggleShuffle = "admin",
	ToggleLoop = "admin",
}

-- ═══════════════════════════════════════════════════════════
-- DJS PREDETERMINADOS
-- ═══════════════════════════════════════════════════════════
function MusicSystemConfig:GetDJs()
	return {
		{
			name = "DJ Alex",
			cover = "rbxassetid://0",
			userId = 123456789,
			songs = {18411501, 18411502}
		},
		{
			name = "DJ Studio",
			cover = "rbxassetid://0",
			userId = 987654321,
			songs = {18411601, 18411602}
		},
		{
			name = "DJ Vibes",
			cover = "rbxassetid://0",
			userId = 111222333,
			songs = {18411701, 18411702}
		},
		{
			name = "DJ Beats",
			cover = "rbxassetid://0",
			userId = 444555666,
			songs = {18411801, 18411802}
		},
		{
			name = "DJ Chill",
			cover = "rbxassetid://0",
			userId = 777888999,
			songs = {18411901, 18411902}
		},
		{
			name = "DJ Energy",
			cover = "rbxassetid://0",
			userId = 101112131,
			songs = {18412001, 18412002}
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════

-- Verificar si un usuario es admin
function MusicSystemConfig:IsAdmin(userId)
	-- Si usa sistema externo
	if self.ADMINS.UseExternalAdminSystem then
		local success, adminModule = pcall(function()
			return require(game.ServerStorage:WaitForChild(self.ADMINS.ExternalAdminModule))
		end)
		if success and adminModule.isAdmin then
			return adminModule:isAdmin(userId)
		end
	end
	
	-- Verificar en lista local
	for _, adminId in ipairs(self.ADMINS.AdminUserIds) do
		if userId == adminId then 
			return true 
		end
	end
	return false
end

-- Verificar permiso para una acción
function MusicSystemConfig:HasPermission(userId, action)
	local permission = self.PERMISSIONS[action]
	
	if not permission then
		return false -- Acción no configurada
	end
	
	if permission == "everyone" then
		return true
	elseif permission == "admin" then
		return self:IsAdmin(userId)
	elseif permission == "vip" then
		-- Implementar lógica de VIP si es necesario
		return self:IsAdmin(userId)
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
