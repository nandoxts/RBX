local HttpService = game:GetService("HttpService")

local CentralAdminConfig = {}

-- Cache de nombres para evitar llamadas repetidas
local nameCache = {}

CentralAdminConfig.Admins = {
	[8387751399] = {
		role = "Owner",
		rank = 5,
		permissions = {"all"},
		chatTag = "OWNER",
		chatColor = Color3.fromRGB(255, 215, 0)
	},
	[9375636407] = {
		role = "HeadAdmin",
		rank = 4,
		permissions = {"all"},
		chatTag = "OWNER",
		chatColor = Color3.fromRGB(255, 215, 0)
	},
}

-- Obtener el nombre de Roblox usando la API pública
function CentralAdminConfig:getRobloxName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local url = "https://users.roblox.com/v1/users/" .. tostring(userId)
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if success then
		local data = HttpService:JSONDecode(response)
		nameCache[userId] = data.name
		return data.name
	else
		return tostring(userId)
	end
end

-- Convertir a formato HD Admin
function CentralAdminConfig:GetHDAdminRanks()
	local ranks = {
		{5, "Owner", {}},
		{4, "HeadAdmin", {}},
		{3, "Admin", {}},
		{2, "Mod", {}},
		{1, "VIP", {}},
		{0, "NonAdmin"},
	}

	for userId, admin in pairs(CentralAdminConfig.Admins) do
		local rankIndex = admin.rank or 0
		if rankIndex >= 0 and rankIndex <= 5 then
			local name = CentralAdminConfig:getRobloxName(userId)
			table.insert(ranks[6 - rankIndex][3], name)
			table.insert(ranks[6 - rankIndex][3], userId)
		end
	end

	return ranks
end

-- Generar Chat Tags para HD Admin
function CentralAdminConfig:GetChatTags()
	local chatTags = {}

	for userId, admin in pairs(CentralAdminConfig.Admins) do
		if admin.chatTag then
			chatTags[userId] = {
				TagText = admin.chatTag,
				TagColor = admin.chatColor or Color3.fromRGB(255, 255, 255)
			}
		end
	end

	return chatTags
end

function CentralAdminConfig:isAdmin(userId)
	return CentralAdminConfig.Admins[userId] ~= nil
end

function CentralAdminConfig:hasPermission(userId, permission)
	local admin = CentralAdminConfig.Admins[userId]
	if not admin then return false end

	if table.find(admin.permissions, "all") then return true end
	return table.find(admin.permissions, permission) ~= nil
end

function CentralAdminConfig:getRole(userId)
	local admin = CentralAdminConfig.Admins[userId]
	return admin and admin.role or "User"
end

function CentralAdminConfig:getRank(userId)
	local admin = CentralAdminConfig.Admins[userId]
	return admin and admin.rank or 0
end

function CentralAdminConfig:getName(userId)
	return CentralAdminConfig:getRobloxName(userId)
end

function CentralAdminConfig:getChatTag(userId)
	local admin = CentralAdminConfig.Admins[userId]
	return admin and admin.chatTag or nil
end

function CentralAdminConfig:getChatColor(userId)
	local admin = CentralAdminConfig.Admins[userId]
	return admin and admin.chatColor or Color3.fromRGB(255, 255, 255)
end

return CentralAdminConfig