--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM - CONFIGURACIÓN
	═══════════════════════════════════════════════════════════
	Autor: by ignxts
	Versión: 2.0 (Simplificado)
]]

local ClanSystemConfig = {}

-- ═══════════════════════════════════════════════════════════
-- ADMINISTRADORES
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ADMINS = {
	AdminUserIds = {
		8387751399,  -- nandoxts (Owner)
	},
	LogAdminActions = true,
}

-- ═══════════════════════════════════════════════════════════
-- BASE DE DATOS (DATASTORE)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DATABASE = {
	UseDataStore = true,
	ClanStoreName = "ClansData_v2",
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
	LeaveClan = 5,
	InvitePlayer = 1,
	KickPlayer = 2,
	ChangeRole = 3,
	ChangeName = 60,
	ChangeTag = 300,
	ChangeDescription = 30,
	ChangeLogo = 60,
	ChangeColor = 10,
	DissolveClan = 10,
	AdminDissolveClan = 10,
	-- NUEVOS RATE LIMITS PARA SOLICITUDES
	RequestJoinClan = 5,      -- 5 segundos entre solicitudes
	ApproveJoinRequest = 1,   -- 1 segundo entre aprobaciones
	RejectJoinRequest = 1,    -- 1 segundo entre rechazos
	CancelJoinRequest = 1,    -- 1 segundo entre cancelaciones
	GetJoinRequests = 0,       -- Sin throttle para consultas de lectura
}

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE ROLES Y PERMISOS
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.ROLES = {
	Hierarchy = {
		owner = 4,
		lider = 3,
		colider = 2,
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
			cambiar_color = true,
			disolver_clan = true,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- NUEVOS PERMISOS PARA MÚLTIPLES OWNERS
			agregar_owner = true,
			remover_owner = true
		},
		colider = {
			invitar = true,
			expulsar = true,
			cambiar_lideres = true,
			cambiar_descripcion = true,
			cambiar_nombre = true,
			cambiar_logo = true,
			cambiar_color = false,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- NO puede cambiar owners
			agregar_owner = false,
			remover_owner = false
		},
		lider = {
			invitar = true,
			expulsar = true,
			cambiar_descripcion = true,
			cambiar_color = false,
			-- PERMISOS PARA SOLICITUDES
			aprobar_solicitudes = true,
			rechazar_solicitudes = true,
			ver_solicitudes = true,
			-- NO puede cambiar owners
			agregar_owner = false,
			remover_owner = false
		},
		miembro = {
			-- MIEMBROS NO PUEDEN GESTIONAR SOLICITUDES
			aprobar_solicitudes = false,
			rechazar_solicitudes = false,
			ver_solicitudes = false,
			cambiar_color = false,
			agregar_owner = false,
			remover_owner = false
		}
	},

	-- Configuración visual y jerarquía para UI
	Visual = {
		owner = {
			display = "Owner",
			color = Color3.fromRGB(255, 215, 0),
			icon = "👑",
			priority = 4,
			canManage = {"lider", "colider", "miembro"}
		},
		lider = {
			display = "Líder",
			color = Color3.fromRGB(100, 200, 255),
			icon = "🔹",
			priority = 3,
			canManage = {"colider", "miembro"}
		},
		colider = {
			display = "Co-Líder", 
			color = Color3.fromRGB(180, 100, 255),
			icon = "⚜️",
			priority = 2,
			canManage = {"miembro"}
		},
		miembro = {
			display = "Miembro",
			color = Color3.fromRGB(200, 200, 200), -- Usar un color muted en lugar de THEME.muted
			icon = "•",
			priority = 1,
			canManage = {}
		}
	},
}

-- ═══════════════════════════════════════════════════════════
-- CLANS POR DEFECTO (Creados automáticamente al iniciar)
-- ═══════════════════════════════════════════════════════════
ClanSystemConfig.DEFAULT_CLANS = {
	{
		clanName = "Shadow Garden",
		ownerId = 8659516822, -- Asignar ownerId
		clanTag = "SG",
		clanLogo = "rbxassetid://112234631634424",
		descripcion = "Clan Shadow Garden",
		clanEmoji = "🔱",
		clanColor = {255, 215, 0}, -- Dorado
	},
	{
		clanName = "TH4",
		ownerId = 3186256515, -- Asignar ownerId
		clanTag = "TH4",
		clanLogo = "rbxassetid://116232400811020",
		descripcion = "Clan TH4",
		clanEmoji = "🔥",
		clanColor = {255, 69, 0}, -- Color sugerido (naranja)
	},
	{
		clanName = "ETA",
		ownerId = 9167247137,
		clanTag = "ETA",
		clanLogo ="rbxassetid://139899084429788",
		descripcion = "Entrelazados todos somos una alianza",
		clanEmoji = "⚔️",
		clanColor = {0, 0, 255}, -- Azul
	},
	{
		clanName = "King of Darkness",
		ownerId = 8109061566, -- Asignar ownerId
		clanTag = "DK",
		clanLogo = "rbxassetid://110433791728647",
		descripcion = "Clan King of Darkness",
		clanEmoji = "💀",
		clanColor = {138, 43, 226}, -- Morado/Púrpura (BlueViolet)
	},
	{

		clanName = "DOLLYS",
		ownerId = 437675178,
		clanTag = "DLS",
		clanLogo = "rbxassetid://98191040674306",
		descripcion = "Clan DOLLYS",
		clanEmoji = "😹",
		clanColor = {34, 177, 76}, -- Verde elegante
	},
	{
		clanName = "DZN",
		ownerId = 7904861114,
		clanTag = "DZN",
		clanLogo = "rbxassetid://134988933629013",
		descripcion = "Clan DZN",
		clanEmoji = "👑",
		clanColor = {0, 122, 255}, -- Azul
	},
	{
		clanName = "Supreme Legacy",
		ownerId = 9764396115,
		clanTag = "SL",
		clanLogo = "rbxassetid://93259920027853",
		descripcion = "Clan Supreme Legacy",
		clanEmoji = "🔱",
		clanColor = {255, 215, 0}, -- Dorado
	},
	{
		clanName = "AMERI",
		ownerId = 4074563891,
		clanTag = "SSJ",
		clanLogo = "rbxassetid://72377979178497",
		descripcion = "solo para sabios",
		clanEmoji = "🔝",
		clanColor = {151, 0, 0}, -- rojo
	},
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

-- Validar color RGB (tabla {r,g,b} con valores 0-255)
function ClanSystemConfig:ValidateColor(color)
	if type(color) ~= "table" then
		return false, "Color inválido: se espera una tabla {r,g,b}"
	end
	if #color ~= 3 then
		return false, "Color inválido: se esperan 3 componentes RGB"
	end
	for i = 1, 3 do
		local v = color[i]
		if type(v) ~= "number" or v < 0 or v > 255 then
			return false, "Color inválido: cada componente debe ser número entre 0 y 255"
		end
	end
	return true
end

return ClanSystemConfig
