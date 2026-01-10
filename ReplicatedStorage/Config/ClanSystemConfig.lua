--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM - CONFIGURACIÓN GLOBAL
	═══════════════════════════════════════════════════════════
	Sistema de configuración modular para clanes
	Permite adaptar el sistema a diferentes juegos
	
	Autor: PandaISTPs
	Versión: 2.0
	Última actualización: 2025
]]

local ClanSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- CONFIGURACIÓN GENERAL DEL SISTEMA
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.SYSTEM = {
	-- Habilitar/deshabilitar sistema completo
	Enabled = true,
	
	-- Permitir a jugadores crear clanes
	AllowClanCreation = true,
	
	-- Permitir switching entre clanes
	AllowClanSwitching = false, -- Si false, deben salir antes de unirse a otro
	
	-- Cooldown después de salir de un clan (en segundos)
	ClanSwitchCooldown = 604800, -- 7 días
}

-- ═══════════════════════════════════════════════════════════
-- ADMINISTRADORES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ADMINS = {
	-- IDs de administradores con permisos totales
	AdminUserIds = {
		8387751399,  -- nandoxts (Owner)
		9375636407,  -- Admin2
	},
	
	-- ¿Los admins pueden crear clanes para otros usuarios?
	AllowAdminCreateForOthers = true,
	
	-- ¿Los admins pueden disolver cualquier clan?
	AllowAdminDissolveAnyClan = true,
	
	-- Registrar acciones de admin en auditoría
	LogAdminActions = true,
}

-- ═══════════════════════════════════════════════════════════
-- BASE DE DATOS (DATASTORE)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DATABASE = {
	-- ⚠️ IMPORTANTE: Cambiar estos nombres por juego para evitar conflictos
	UseDataStore = true, -- Si false, solo memoria (testing)
	
	ClanStoreName = "ClansData_v1",
	PlayerClanStoreName = "PlayerClans_v1",
	AuditStoreName = "AdminAudit_v1",
	CooldownStoreName = "ClanCooldowns_v1",
	
	-- Auto-guardar cada X minutos (0 = solo manual)
	AutoSaveInterval = 300, -- 5 minutos
}

-- ═══════════════════════════════════════════════════════════
-- LÍMITES Y RESTRICCIONES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.LIMITS = {
	-- Miembros
	MinLevelToJoin = 5, -- Nivel mínimo para unirse a clanes
	MaxMembersPerClan = 50,
	
	-- Nombres y tags
	MinClanNameLength = 3,
	MaxClanNameLength = 30,
	MinTagLength = 2,
	MaxTagLength = 5,
	
	-- Descripción
	MaxDescriptionLength = 200,
	
	-- Logos
	AllowCustomLogos = true,
	RequireApprovedLogos = false, -- Si true, logos deben ser aprobados
}

-- ═══════════════════════════════════════════════════════════
-- RATE LIMITING (Anti-spam)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.RATE_LIMITS = {
	-- Tiempo en segundos entre acciones
	GetClansList = 0, -- Sin límite para obtener lista
	CreateClan = 10,
	JoinClan = 1,
	LeaveClan = 5,
	InvitePlayer = 1,
	KickPlayer = 2,
	ChangeRole = 3,
	ChangeName = 60, -- 1 minuto
	ChangeTag = 300, -- 5 minutos
	ChangeDescription = 30,
	ChangeLogo = 60,
	DissolveClan = 10,
	AdminDissolveClan = 10,
}

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE ROLES Y PERMISOS
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ROLES = {
	-- Jerarquía de roles (mayor número = mayor poder)
	Hierarchy = {
		owner = 4,
		colider = 3,
		lider = 2,
		miembro = 1,
	},
	
	-- Permisos por rol
	Permissions = {
		owner = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = true,
			cambiar_colideres = true,
			cambiar_descripcion = true,
			cambiar_nombre = true,
			cambiar_tag = true,
			cambiar_logo = true,
			disolver_clan = true,
			ver_estadisticas = true,
		},
		colider = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = true,
			cambiar_descripcion = true,
			cambiar_nombre = true,
			cambiar_logo = true,
			ver_estadisticas = true,
		},
		lider = {
			invitar = true,
			expulsar = true,
			cambiar_descripcion = true,
			ver_estadisticas = false,
		},
		miembro = {
			ver_estadisticas = false,
		}
	},
	
	-- Límites de roles por clan
	MaxColideres = 3,
	MaxLideres = 5,
}

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE NIVELES Y EXPERIENCIA
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.PROGRESSION = {
	-- Habilitar sistema de niveles
	EnableLevels = true,
	
	-- XP por acción
	XPPerMemberJoin = 50,
	XPPerDailyLogin = 10,
	XPPerClanActivity = 5,
	
	-- XP necesario por nivel
	XPPerLevel = 1000,
	MaxLevel = 100,
	
	-- Recompensas por nivel
	RewardsEnabled = false,
}

-- ═══════════════════════════════════════════════════════════
-- INTERFAZ Y VISUALIZACIÓN
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.UI = {
	-- Mostrar TAG en nombre del jugador
	ShowClanTag = true,
	ClanTagFormat = "%s %s", -- "[TAG] PlayerName"
	
	-- Mostrar emoji de clan
	ShowClanEmoji = true,
	
	-- Colores por defecto
	DefaultClanColor = Color3.fromRGB(99, 102, 241),
	
	-- Logo por defecto si no tiene
	DefaultLogoAssetId = "rbxassetid://0",
}

-- ═══════════════════════════════════════════════════════════
-- CARACTERÍSTICAS OPCIONALES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.FEATURES = {
	-- Chat de clan
	EnableClanChat = false,
	
	-- Invitaciones
	EnableInvitations = true,
	InvitationExpireTime = 86400, -- 24 horas
	
	-- Alianzas entre clanes
	EnableAlliances = false,
	MaxAlliances = 3,
	
	-- Guerras de clanes
	EnableClanWars = false,
	
	-- Banco de clan (recursos compartidos)
	EnableClanBank = false,
	
	-- Base de clan (territorio en el juego)
	EnableClanBase = false,
}

-- ═══════════════════════════════════════════════════════════
-- NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.NOTIFICATIONS = {
	-- Usar sistema de notificaciones personalizado
	UseCustomNotifications = true,
	
	-- Notificar cuando alguien se une
	NotifyOnMemberJoin = true,
	
	-- Notificar cuando alguien sale
	NotifyOnMemberLeave = true,
	
	-- Notificar cambios de rol
	NotifyOnRoleChange = true,
}

-- ═══════════════════════════════════════════════════════════
-- VALIDACIÓN Y FILTRADO
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.VALIDATION = {
	-- Filtrar nombres con TextService
	FilterClanNames = true,
	
	-- Palabras prohibidas (blacklist)
	BlacklistedWords = {
		"admin", "roblox", "owner", "mod", 
		-- Agregar más según necesidad
	},
	
	-- Permitir números en nombres
	AllowNumbersInNames = true,
	
	-- Permitir símbolos especiales
	AllowSpecialCharacters = false,
}

-- ═══════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════

-- Verificar si un usuario es admin
function ClanSystemConfig:IsAdmin(userId)
	for _, adminId in ipairs(self.ADMINS.AdminUserIds) do
		if userId == adminId then 
			return true 
		end
	end
	return false
end

-- Obtener límite de rate para una acción
function ClanSystemConfig:GetRateLimit(action)
	return self.RATE_LIMITS[action] or 1
end

-- Verificar si tiene permiso
function ClanSystemConfig:HasPermission(rol, permiso)
	local rolePerms = self.ROLES.Permissions[rol]
	return rolePerms and rolePerms[permiso] or false
end

-- Obtener jerarquía de rol
function ClanSystemConfig:GetRoleLevel(rol)
	return self.ROLES.Hierarchy[rol] or 0
end

-- Validar nombre de clan
function ClanSystemConfig:ValidateClanName(name)
	if not name or type(name) ~= "string" then
		return false, "Nombre inválido"
	end
	
	local len = #name
	if len < self.LIMITS.MinClanNameLength then
		return false, "Nombre muy corto (mínimo " .. self.LIMITS.MinClanNameLength .. " caracteres)"
	end
	
	if len > self.LIMITS.MaxClanNameLength then
		return false, "Nombre muy largo (máximo " .. self.LIMITS.MaxClanNameLength .. " caracteres)"
	end
	
	-- Verificar blacklist
	local lowerName = name:lower()
	for _, word in ipairs(self.VALIDATION.BlacklistedWords) do
		if lowerName:find(word:lower()) then
			return false, "Nombre contiene palabras prohibidas"
		end
	end
	
	return true
end

-- Validar TAG
function ClanSystemConfig:ValidateTag(tag)
	if not tag or type(tag) ~= "string" then
		return false, "TAG inválido"
	end
	
	local len = #tag
	if len < self.LIMITS.MinTagLength then
		return false, "TAG muy corto (mínimo " .. self.LIMITS.MinTagLength .. " caracteres)"
	end
	
	if len > self.LIMITS.MaxTagLength then
		return false, "TAG muy largo (máximo " .. self.LIMITS.MaxTagLength .. " caracteres)"
	end
	
	return true
end

return ClanSystemConfig
