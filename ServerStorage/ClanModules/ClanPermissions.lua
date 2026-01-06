local ClanPermissions = {}

-- Tabla de permisos por rol
local PERMISOS = {
owner = {
invitar = true,
expulsar = true,
cambiar_lideres = true,
cambiar_colideres = true,
cambiar_descripcion = true,
cambiar_nombre = true,
cambiar_logo = true,
disolver_clan = true,
transferir_ownership = true
},
colideres = {
invitar = true,
expulsar = true,
cambiar_lideres = true,
cambiar_descripcion = true,
cambiar_nombre = true,
cambiar_logo = true
},
lideres = {
invitar = true,
expulsar = true,
cambiar_descripcion = true
},
miembro = {}
}

-- Verificar si un usuario tiene permiso
function ClanPermissions:HasPermission(userRole, permission)
if not PERMISOS[userRole] then
return false
end

return PERMISOS[userRole][permission] or false
end

-- Obtener todos los permisos de un rol
function ClanPermissions:GetRolePermissions(role)
return PERMISOS[role] or {}
end

-- Obtener la jerarquía de roles
function ClanPermissions:GetRoleHierarchy()
return {
owner = 4,
colideres = 3,
lideres = 2,
miembro = 1
}
end

-- Comparar jerarquía entre dos roles
function ClanPermissions:CompareRoles(role1, role2)
local hierarchy = self:GetRoleHierarchy()
local level1 = hierarchy[role1] or 0
local level2 = hierarchy[role2] or 0

if level1 > level2 then
return 1 -- role1 es superior
elseif level1 < level2 then
return -1 -- role2 es superior
else
return 0 -- roles iguales
end
end

-- Verificar si un usuario puede hacer una acción sobre otro
function ClanPermissions:CanActOn(userRole, targetRole, action)
-- El owner puede hacer cualquier cosa
if userRole == "owner" then
return true
end

-- Verificar si tiene el permiso
if not self:HasPermission(userRole, action) then
return false
end

-- Verificar jerarquía (no puede actuar sobre alguien de igual o mayor rango)
local comparison = self:CompareRoles(userRole, targetRole)

return comparison > 0 -- Solo si es superior en jerarquía
end

return ClanPermissions
