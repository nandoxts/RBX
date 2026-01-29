local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = {}

-- Lista de admins por nombre de usuario ONLY (sin UserIds)
AdminConfig.AdminUserNames = {
    "xlm_brem",
    "AngeloGarciia",
    "bvwdhfv",
    "ignxts",
}

function AdminConfig:IsAdminByName(name)
    if not name then return false end
    return table.find(self.AdminUserNames, name) ~= nil
end

-- Acepta un Instance (Player) o un string (nombre)
function AdminConfig:IsAdmin(playerOrName)
    if typeof(playerOrName) == "Instance" and playerOrName.Name then
        return self:IsAdminByName(playerOrName.Name)
    elseif type(playerOrName) == "string" then
        return self:IsAdminByName(playerOrName)
    end
    return false
end

return AdminConfig
