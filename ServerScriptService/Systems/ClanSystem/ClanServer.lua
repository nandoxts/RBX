-- ============================================
-- CLAN SERVER - Simplificado y Rápido
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ClanData = require(ServerStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

-- ============================================
-- RATE LIMITING SIMPLE
-- ============================================
local cooldowns = {}

local function checkCooldown(userId, action, seconds)
	seconds = seconds or 2
	local key = userId .. "_" .. action
	local now = os.clock()
	local last = cooldowns[key] or 0

	if now - last < seconds then
		return false, "Espera " .. math.ceil(seconds - (now - last)) .. "s"
	end

	cooldowns[key] = now
	return true
end

-- ============================================
-- HELPERS
-- ============================================
local function isAdmin(userId)
	return Config:IsAdmin(userId)
end

local function updatePlayerAttributes(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local clan = ClanData:GetPlayerClan(userId)

	if clan then
		player:SetAttribute("ClanTag", clan.tag)
		player:SetAttribute("ClanName", clan.name)
		player:SetAttribute("ClanId", clan.clanId)
		player:SetAttribute("ClanEmoji", clan.emoji or "")

		if clan.color then
			player:SetAttribute("ClanColor", Color3.fromRGB(
				clan.color[1] or 255,
				clan.color[2] or 255,
				clan.color[3] or 255
				))
		end
	else
		player:SetAttribute("ClanTag", nil)
		player:SetAttribute("ClanName", nil)
		player:SetAttribute("ClanId", nil)
		player:SetAttribute("ClanEmoji", nil)
		player:SetAttribute("ClanColor", nil)
	end
end

local function updateAllMembers(clan)
	if not clan or not clan.members then return end
	for userIdStr in pairs(clan.members) do
		updatePlayerAttributes(tonumber(userIdStr))
	end
end

-- ============================================
-- EVENTOS REMOTOS (pre-creados en RemotesGlobal/ClanEvents)
-- ============================================
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local folder = remotesGlobal:WaitForChild("ClanEvents")

-- RemoteFunctions (síncronas, necesitan respuesta)
local CreateClan = folder:WaitForChild("CreateClan")
local GetClan = folder:WaitForChild("GetClan")
local GetPlayerClan = folder:WaitForChild("GetPlayerClan")
local GetClansList = folder:WaitForChild("GetClansList")
local GetJoinRequests = folder:WaitForChild("GetJoinRequests")
local GetUserPendingRequests = folder:WaitForChild("GetUserPendingRequests")

-- RemoteEvents (asincrónicas, NO bloquean)
local InvitePlayer = folder:WaitForChild("InvitePlayer")
local KickPlayer = folder:WaitForChild("KickPlayer")
local ChangeRole = folder:WaitForChild("ChangeRole")
local ChangeClanName = folder:WaitForChild("ChangeClanName")
local ChangeClanTag = folder:WaitForChild("ChangeClanTag")
local ChangeClanDescription = folder:WaitForChild("ChangeClanDescription")
local ChangeClanLogo = folder:WaitForChild("ChangeClanLogo")
local ChangeClanEmoji = folder:WaitForChild("ChangeClanEmoji")
local ChangeClanColor = folder:WaitForChild("ChangeClanColor")
local AddOwner = folder:WaitForChild("AddOwner")
local RemoveOwner = folder:WaitForChild("RemoveOwner")
local DissolveClan = folder:WaitForChild("DissolveClan")
local LeaveClan = folder:WaitForChild("LeaveClan")
local AdminDissolveClan = folder:WaitForChild("AdminDissolveClan")
local RequestJoinClan = folder:WaitForChild("RequestJoinClan")
local ApproveJoinRequest = folder:WaitForChild("ApproveJoinRequest")
local RejectJoinRequest = folder:WaitForChild("RejectJoinRequest")
local CancelJoinRequest = folder:WaitForChild("CancelJoinRequest")
local CancelAllJoinRequests = folder:WaitForChild("CancelAllJoinRequests")

-- Eventos
local ClansUpdated = folder:WaitForChild("ClansUpdated")
local RequestJoinResult = folder:WaitForChild("RequestJoinResult") -- Notificación al jugador que solicitó

-- ============================================
-- NOTIFICACIÓN OPTIMIZADA (solo miembros afectados + lista global)
-- ============================================
local function notifyChanged(changedClanId)
	if changedClanId then
		local clan = ClanData:GetClan(changedClanId)
		if clan and clan.members then
			-- Notificar a miembros del clan
			for userIdStr in pairs(clan.members) do
				local userId = tonumber(userIdStr)
				local player = Players:GetPlayerByUserId(userId)
				if player then
					ClansUpdated:FireClient(player, changedClanId)
				end
			end
		end
	end

	-- TAMBIÉN notificar a TODOS los players para refrescar lista global
	-- (usuarios viendo lista de clanes para unirse)
	for _, player in ipairs(Players:GetPlayers()) do
		ClansUpdated:FireAllClients(changedClanId)
		break  -- Una sola vez a todos
	end
end

-- ============================================
-- HANDLERS
-- ============================================

CreateClan.OnServerInvoke = function(player, name, tag, logo, desc, emoji, color)
	local ok, err = checkCooldown(player.UserId, "CreateClan", Config:GetRateLimit("CreateClan"))
	if not ok then return false, err end

	local success, clanId, result = ClanData:CreateClan(
		name, player.UserId, tag, logo, desc, emoji, color
	)

	if success then
		updatePlayerAttributes(player.UserId)
		return true, clanId, "Clan creado"
	end

	return false, nil, result
end

GetClan.OnServerInvoke = function(player, clanId)
	return ClanData:GetClan(clanId)
end

GetPlayerClan.OnServerInvoke = function(player)
	return ClanData:GetPlayerClan(player.UserId)
end

GetClansList.OnServerInvoke = function(player)
	local clans = ClanData:GetAllClans()
	if not clans or #clans == 0 then
		return {}  -- Devolver tabla vacía, no nil
	end

	local playerClan = ClanData:GetPlayerClan(player.UserId)
	local playerClanId = playerClan and playerClan.clanId

	for _, clan in ipairs(clans) do
		clan.isPlayerMember = (clan.clanId == playerClanId)
	end

	return clans
end

-- Handlers individuales para cada campo (compatibilidad V1)
ChangeClanName.OnServerEvent:Connect(function(player, clanId, newName)
	local ok, err = checkCooldown(player.UserId, "ChangeName", Config:GetRateLimit("ChangeName"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_nombre") then return end

	ClanData:UpdateClan(clanId, {name = newName})
end)

ChangeClanTag.OnServerEvent:Connect(function(player, clanId, newTag)
	local ok, err = checkCooldown(player.UserId, "ChangeTag", Config:GetRateLimit("ChangeTag"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or member.role ~= Config.ROLE_NAMES.OWNER then return end

	ClanData:UpdateClan(clanId, {tag = newTag})
end)

ChangeClanDescription.OnServerEvent:Connect(function(player, clanId, newDesc)
	local ok, err = checkCooldown(player.UserId, "ChangeDescription", Config:GetRateLimit("ChangeDescription"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_descripcion") then return end

	ClanData:UpdateClan(clanId, {description = newDesc})
end)

ChangeClanLogo.OnServerEvent:Connect(function(player, clanId, newLogoId)
	local ok, err = checkCooldown(player.UserId, "ChangeLogo", Config:GetRateLimit("ChangeLogo"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_logo") then return end

	ClanData:UpdateClan(clanId, {logo = newLogoId})
end)

ChangeClanEmoji.OnServerEvent:Connect(function(player, clanId, newEmoji)
	local ok, err = checkCooldown(player.UserId, "ChangeClanEmoji", Config:GetRateLimit("ChangeEmoji"))
	if not ok then return end

	if not newEmoji or type(newEmoji) ~= "string" or #newEmoji == 0 then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_emoji") then return end

	ClanData:UpdateClan(clanId, {emoji = newEmoji})
end)

ChangeClanColor.OnServerEvent:Connect(function(player, clanId, newColor)
	local ok, err = checkCooldown(player.UserId, "ChangeColor", Config:GetRateLimit("ChangeColor"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_color") then return end

	ClanData:UpdateClan(clanId, {color = newColor})
end)

InvitePlayer.OnServerEvent:Connect(function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "InvitePlayer", Config:GetRateLimit("InvitePlayer"))
	if not ok then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "invitar") then return end

	local success, result = ClanData:AddMember(clanId, targetUserId, Config.DEFAULTS.MemberRole)

	if success then
		updatePlayerAttributes(targetUserId)
	end
end)

KickPlayer.OnServerEvent:Connect(function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "KickPlayer", Config:GetRateLimit("KickPlayer"))
	if not ok then return end

	if player.UserId == targetUserId then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	local target = clan.members[tostring(targetUserId)]

	if not member then return end
	if not target then return end

	if not Config:HasPermission(member.role, "expulsar") then return end

	local memberLevel = Config:GetRoleLevel(member.role)
	local targetLevel = Config:GetRoleLevel(target.role)

	if memberLevel <= targetLevel then return end

	local success, result = ClanData:RemoveMember(clanId, targetUserId)

	if success then
		updatePlayerAttributes(targetUserId)
	end
end)

ChangeRole.OnServerEvent:Connect(function(player, clanId, targetUserId, newRole)
	local ok, err = checkCooldown(player.UserId, "ChangeRole", Config:GetRateLimit("ChangeRole"))
	if not ok then return end

	if type(clanId) == "number" and not newRole then
		newRole = targetUserId
		targetUserId = clanId
		local playerClan = ClanData:GetPlayerClan(player.UserId)
		if not playerClan then return end
		clanId = playerClan.clanId
	end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local member = clan.members[tostring(player.UserId)]
	local target = clan.members[tostring(targetUserId)]

	if not member then return end
	if not target then return end

	local permission = "cambiar_lideres"
	if newRole == Config.ROLE_NAMES.COLIDER then permission = "cambiar_colideres" end

	if not Config:HasPermission(member.role, permission) then return end

	local success, result = ClanData:ChangeRole(clanId, targetUserId, newRole)

	if success then
		updatePlayerAttributes(targetUserId)
	end
end)

AddOwner.OnServerEvent:Connect(function(player, targetUserId)
	if not player or not targetUserId then return end

	local playerClan = ClanData:GetPlayerClan(player.UserId)
	if not playerClan then return end

	local clanId = playerClan.clanId
	local member = playerClan.members[tostring(player.UserId)]

	if not member or not Config:HasPermission(member.role, "agregar_owner") then return end

	local success, result = ClanData:AddOwner(clanId, targetUserId)

	if success then
		updatePlayerAttributes(targetUserId)
	end
end)

RemoveOwner.OnServerEvent:Connect(function(player, targetUserId)
	if not player or not targetUserId then return end

	local playerClan = ClanData:GetPlayerClan(player.UserId)
	if not playerClan then return end

	local clanId = playerClan.clanId
	local member = playerClan.members[tostring(player.UserId)]

	if not member or not Config:HasPermission(member.role, "remover_owner") then return end

	local success, result = ClanData:RemoveOwner(clanId, targetUserId)

	if success then
		updatePlayerAttributes(targetUserId)
	end
end)

AdminDissolveClan.OnServerEvent:Connect(function(player, clanId)
	if not clanId then return end

	local ok, err = checkCooldown(player.UserId, "AdminDissolveClan", Config:GetRateLimit("AdminDissolveClan"))
	if not ok then return end

	if not isAdmin(player.UserId) then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	local members = {}
	if clan.members and type(clan.members) == "table" then
		for userIdStr in pairs(clan.members) do
			local userId = tonumber(userIdStr)
			if userId then
				table.insert(members, userId)
			end
		end
	end

	local success, result = ClanData:DissolveClan(clanId)

	if success then
		for _, userId in ipairs(members) do
			pcall(function()
				updatePlayerAttributes(userId)
			end)
		end
	end
end)

DissolveClan.OnServerEvent:Connect(function(player, clanId)
	local ok, err = checkCooldown(player.UserId, "DissolveClan", Config:GetRateLimit("DissolveClan"))
	if not ok then return end

	if not clanId then return end

	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	if not clan.owners or not table.find(clan.owners, player.UserId) then return end

	local members = {}
	if clan.members and type(clan.members) == "table" then
		for userIdStr in pairs(clan.members) do
			local userId = tonumber(userIdStr)
			if userId then
				table.insert(members, userId)
			end
		end
	end

	local success, result = ClanData:DissolveClan(clanId)

	if success then
		for _, userId in ipairs(members) do
			pcall(function()
				updatePlayerAttributes(userId)
			end)
		end
	end
end)

LeaveClan.OnServerEvent:Connect(function(player, clanId)
	local clan = ClanData:GetClan(clanId)
	if not clan then return end

	if table.find(clan.owners, player.UserId) then return end

	local success, result = ClanData:RemoveMember(clanId, player.UserId)

	if success then
		ClanData:CancelRequest(clanId, player.UserId)
		updatePlayerAttributes(player.UserId)
	end
end)

-- ============================================
-- SOLICITUDES (nombres compatibles V1)
-- ============================================

RequestJoinClan.OnServerEvent:Connect(function(player, clanId)
	local ok, err = checkCooldown(player.UserId, "RequestJoinClan", Config:GetRateLimit("RequestJoinClan"))
	if not ok then return end

	local success, result = ClanData:RequestJoin(clanId, player.UserId)

	if success then
		RequestJoinResult:FireClient(player, true, clanId, "Solicitud enviada")
	else
		RequestJoinResult:FireClient(player, false, clanId, result)
	end
end)

ApproveJoinRequest.OnServerEvent:Connect(function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "ApproveJoinRequest", Config:GetRateLimit("ApproveJoinRequest"))
	if not ok then return end

	local success, result = ClanData:ApproveRequest(clanId, player.UserId, targetUserId)

	if success then
		updatePlayerAttributes(targetUserId)

		-- 🔥 Notificar al usuario aprobado para que limpie su caché
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then
			ClansUpdated:FireClient(targetPlayer, clanId)
		end
	end
end)

RejectJoinRequest.OnServerEvent:Connect(function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "RejectJoinRequest", Config:GetRateLimit("RejectJoinRequest"))
	if not ok then return end

	local success = ClanData:RejectRequest(clanId, player.UserId, targetUserId)

	if success then
		-- 🔥 Notificar al usuario rechazado para que limpie su caché
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then
			ClansUpdated:FireClient(targetPlayer, clanId)
		end
	end
end)

GetJoinRequests.OnServerInvoke = function(player, clanId)
	local result = ClanData:GetClanRequests(clanId, player.UserId)
	return result
end

GetUserPendingRequests.OnServerInvoke = function(player)
	return ClanData:GetUserRequests(player.UserId)
end

CancelJoinRequest.OnServerEvent:Connect(function(player, clanId)
	local ok, err = checkCooldown(player.UserId, "CancelJoinRequest", 1)
	if not ok then return end

	ClanData:CancelRequest(clanId, player.UserId)

	-- 🔥 Notificar al cliente que sus solicitudes cambiaron
	ClansUpdated:FireClient(player, clanId)
end)

CancelAllJoinRequests.OnServerEvent:Connect(function(player)
	local ok, err = checkCooldown(player.UserId, "CancelAllJoinRequests", 1)
	if not ok then return end

	ClanData:CancelAllRequests(player.UserId)

	-- 🔥 Notificar a TODOS los players que algo cambió en solicitudes
	ClansUpdated:FireAllClients(nil)
end)

-- ============================================
-- INICIALIZACIÓN
-- ============================================
task.spawn(function()
	task.wait(Config.DATABASE.InitDelay)
	ClanData:CreateDefaultClans()
	-- El evento ClansUpdated se dispara automáticamente desde ClanData:OnUpdate()
end)

-- Atributos para jugadores conectados
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(updatePlayerAttributes, player.UserId)
end

Players.PlayerAdded:Connect(function(player)
	updatePlayerAttributes(player.UserId)
end)

-- Limpiar solicitudes cuando un jugador se desconecta
Players.PlayerRemoving:Connect(function(player)
	-- Limpiar todas las solicitudes pendientes del jugador
	ClanData:CancelAllRequests(player.UserId)
end)

-- Actualizar cuando cambian datos
ClanData:OnUpdate():Connect(function(changedClanId)
	notifyChanged(changedClanId)
end)

return {}
