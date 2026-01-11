--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM - CONFIGURACIÓN
	═══════════════════════════════════════════════════════════
	Autor: PandaISTPs
	Versión: 2.0 (Simplificado)
]]

local ClanSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- ADMINISTRADORES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ADMINS = {
	AdminUserIds = {
		8387751399,  -- nandoxts (Owner)
		9375636407,  -- Admin2
	},
	LogAdminActions = true,
}

-- ═══════════════════════════════════════════════════════════
-- BASE DE DATOS (DATASTORE)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DATABASE = {
	UseDataStore = true,
	ClanStoreName = "ClansData_v1",
	PlayerClanStoreName = "PlayerClans_v1",
	AuditStoreName = "AdminAudit_v1",
	CooldownStoreName = "ClanCooldowns_v1",
	AutoSaveInterval = 300, -- 5 minutos
}

-- ═══════════════════════════════════════════════════════════
-- LÍMITES Y RESTRICCIONES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.LIMITS = {
	MinClanNameLength = 3,
	MaxClanNameLength = 30,
	MinTagLength = 2,
	MaxTagLength = 5,
}

-- ═══════════════════════════════════════════════════════════
-- RATE LIMITING (Anti-spam)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.RATE_LIMITS = {
	GetClansList = 0,
	CreateClan = 10,
	JoinClan = 1,
	LeaveClan = 5,
	InvitePlayer = 1,
	KickPlayer = 2,
	ChangeRole = 3,
	ChangeName = 60,
	ChangeTag = 300,
	ChangeDescription = 30,
	ChangeLogo = 60,
	DissolveClan = 10,
	AdminDissolveClan = 10,
}

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE ROLES Y PERMISOS
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ROLES = {
	Hierarchy = {
		owner = 4,
		colider = 3,
		lider = 2,
		miembro = 1,
	},
	
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
}

-- ═══════════════════════════════════════════════════════════
-- CLANS POR DEFECTO (Creados automáticamente al iniciar)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DEFAULT_CLANS = {
	{
		clanName = "XYZ",
		ownerId = 10179455284, -- Tu UserId
		clanTag = "XYZ",
		clanLogo = "rbxassetid://0",
		descripcion = "Clan oficial de fundadores"
	},
	-- Puedes agregar más clans aquí
	-- {
	-- 	clanName = "Staff",
	-- 	ownerId = 8387751399,
	-- 	clanTag = "STF",
	-- 	clanLogo = "rbxassetid://0",
	-- 	descripcion = "Clan del staff del juego"
	-- },
}

-- ═══════════════════════════════════════════════════════════
-- VALIDACIÓN Y FILTRADO
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.VALIDATION = {
	BlacklistedWords = {
		"admin", "roblox", "owner", "mod", 
	},
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
