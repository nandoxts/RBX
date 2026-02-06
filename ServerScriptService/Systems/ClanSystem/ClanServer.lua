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
-- EVENTOS REMOTOS
-- ============================================
local folder = ReplicatedStorage:FindFirstChild("ClanEvents")
if folder then folder:Destroy() end

folder = Instance.new("Folder")
folder.Name = "ClanEvents"
folder.Parent = ReplicatedStorage

local function RF(name)
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = folder
	return rf
end

local function RE(name)
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = folder
	return re
end

-- Funciones (nombres compatibles con ClanClient existente)
local CreateClan = RF("CreateClan")
local GetClan = RF("GetClan")
local GetPlayerClan = RF("GetPlayerClan")
local GetClansList = RF("GetClansList") -- V1 nombre
local InvitePlayer = RF("InvitePlayer") -- V1 nombre
local KickPlayer = RF("KickPlayer") -- V1 nombre
local ChangeRole = RF("ChangeRole")
local ChangeClanName = RF("ChangeClanName") -- V1 nombre
local ChangeClanTag = RF("ChangeClanTag") -- V1 nombre
local ChangeClanDescription = RF("ChangeClanDescription") -- V1 nombre
local ChangeClanLogo = RF("ChangeClanLogo") -- V1 nombre
local ChangeClanEmoji = RF("ChangeClanEmoji") -- V1 nombre
local ChangeClanColor = RF("ChangeClanColor") -- V1 nombre
local AddOwner = RF("AddOwner")
local RemoveOwner = RF("RemoveOwner")
local DissolveClan = RF("DissolveClan")
local LeaveClan = RF("LeaveClan")
local AdminDissolveClan = RF("AdminDissolveClan") -- V1 nombre

-- Solicitudes (nombres compatibles con ClanClient)
local RequestJoinClan = RF("RequestJoinClan") -- V1 nombre
local ApproveJoinRequest = RF("ApproveJoinRequest") -- V1 nombre
local RejectJoinRequest = RF("RejectJoinRequest") -- V1 nombre
local GetJoinRequests = RF("GetJoinRequests") -- V1 nombre
local GetUserPendingRequests = RF("GetUserPendingRequests") -- V1 nombre
local CancelJoinRequest = RF("CancelJoinRequest") -- V1 nombre
local CancelAllJoinRequests = RF("CancelAllJoinRequests") -- V1 nombre

-- Eventos
local ClansUpdated = RE("ClansUpdated")
local RequestJoinResult = RE("RequestJoinResult") -- Notificación al jugador que solicitó

-- 🔥 HELPER para disparar evento con todos los clanes actualizados
local function notifyClansUpdated()
	local allClans = ClanData:GetAllClans()
	ClansUpdated:FireAllClients(allClans)
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
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	local playerClanId = playerClan and playerClan.clanId
	
	for _, clan in ipairs(clans) do
		clan.isPlayerMember = (clan.clanId == playerClanId)
	end
	
	return clans
end

-- Handlers individuales para cada campo (compatibilidad V1)
ChangeClanName.OnServerInvoke = function(player, clanId, newName)
	local ok, err = checkCooldown(player.UserId, "ChangeName", Config:GetRateLimit("ChangeName"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member then return false, "No eres miembro" end
	
	if not Config:HasPermission(member.role, "cambiar_nombre") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {name = newName})
	
	if success then
		updateAllMembers(result)
		return true, "Nombre actualizado"
	end
	
	return false, result
end

ChangeClanTag.OnServerInvoke = function(player, clanId, newTag)
	local ok, err = checkCooldown(player.UserId, "ChangeTag", Config:GetRateLimit("ChangeTag"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member then return false, "No eres miembro" end
	
	if member.role ~= Config.ROLE_NAMES.OWNER then
		return false, "Solo owner puede cambiar TAG"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {tag = newTag})
	
	if success then
		updateAllMembers(result)
		return true, "TAG actualizado"
	end
	
	return false, result
end

ChangeClanDescription.OnServerInvoke = function(player, clanId, newDesc)
	local ok, err = checkCooldown(player.UserId, "ChangeDescription", Config:GetRateLimit("ChangeDescription"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_descripcion") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {description = newDesc})
	if success then
		updateAllMembers(result)
		return true, "Descripción actualizada"
	end
	return false, result
end

ChangeClanLogo.OnServerInvoke = function(player, clanId, newLogoId)
	local ok, err = checkCooldown(player.UserId, "ChangeLogo", Config:GetRateLimit("ChangeLogo"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_logo") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {logo = newLogoId})
	if success then
		updateAllMembers(result)
		return true, "Logo actualizado"
	end
	return false, result
end

ChangeClanEmoji.OnServerInvoke = function(player, clanId, newEmoji)
	local ok, err = checkCooldown(player.UserId, "ChangeClanEmoji", Config:GetRateLimit("ChangeEmoji"))
	if not ok then return false, err end
	
	if not newEmoji or type(newEmoji) ~= "string" or #newEmoji == 0 then
		return false, "Emoji inválido"
	end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_emoji") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {emoji = newEmoji})
	if success then
		updateAllMembers(result)
		return true, "Emoji actualizado"
	end
	return false, result
end

ChangeClanColor.OnServerInvoke = function(player, clanId, newColor)
	local ok, err = checkCooldown(player.UserId, "ChangeColor", Config:GetRateLimit("ChangeColor"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "cambiar_color") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:UpdateClan(clanId, {color = newColor})
	if success then
		updateAllMembers(result)
		return true, "Color actualizado"
	end
	return false, result
end

InvitePlayer.OnServerInvoke = function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "InvitePlayer", Config:GetRateLimit("InvitePlayer"))
	if not ok then return false, err end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	if not member or not Config:HasPermission(member.role, "invitar") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:AddMember(clanId, targetUserId, Config.DEFAULTS.MemberRole)
	
	if success then
		updatePlayerAttributes(targetUserId)
		return true, "Jugador invitado"
	end
	
	return false, result
end

KickPlayer.OnServerInvoke = function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "KickPlayer", Config:GetRateLimit("KickPlayer"))
	if not ok then return false, err end
	
	if player.UserId == targetUserId then
		return false, "Usa LeaveClan para salir"
	end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	local target = clan.members[tostring(targetUserId)]
	
	if not member then return false, "No eres miembro" end
	if not target then return false, "Usuario no es miembro" end
	
	if not Config:HasPermission(member.role, "expulsar") then
		return false, "Sin permiso"
	end
	
	-- No puede expulsar a alguien de mayor o igual rango
	local memberLevel = Config:GetRoleLevel(member.role)
	local targetLevel = Config:GetRoleLevel(target.role)
	
	if memberLevel <= targetLevel then
		return false, "No puedes expulsar a este usuario"
	end
	
	local success, result = ClanData:RemoveMember(clanId, targetUserId)
	
	if success then
		updatePlayerAttributes(targetUserId)
		return true, "Jugador expulsado"
	end
	
	return false, result
end

ChangeRole.OnServerInvoke = function(player, clanId, targetUserId, newRole)
	local ok, err = checkCooldown(player.UserId, "ChangeRole", Config:GetRateLimit("ChangeRole"))
	if not ok then return false, err end
	
	-- Si clanId no se proporciona (compatibilidad), obtener del jugador
	if type(clanId) == "number" and not newRole then
		-- Firma: player, targetUserId, newRole (sin clanId)
		newRole = targetUserId
		targetUserId = clanId
		local playerClan = ClanData:GetPlayerClan(player.UserId)
		if not playerClan then return false, "No tienes clan" end
		clanId = playerClan.clanId
	end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	local member = clan.members[tostring(player.UserId)]
	local target = clan.members[tostring(targetUserId)]
	
	if not member then return false, "No eres miembro" end
	if not target then return false, "Usuario no es miembro" end
	
	-- Verificar permisos según el rol destino
	local permission = "cambiar_lideres"
	if newRole == Config.ROLE_NAMES.COLIDER then permission = "cambiar_colideres" end
	
	if not Config:HasPermission(member.role, permission) then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:ChangeRole(clanId, targetUserId, newRole)
	
	if success then
		updatePlayerAttributes(targetUserId)
		return true, "Rol cambiado"
	end
	
	return false, result
end

AddOwner.OnServerInvoke = function(player, targetUserId)
	if not player or not targetUserId then return false, "Parámetros inválidos" end
	
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	if not playerClan then return false, "No tienes clan" end
	
	local clanId = playerClan.clanId
	local member = playerClan.members[tostring(player.UserId)]
	
	if not member or not Config:HasPermission(member.role, "agregar_owner") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:AddOwner(clanId, targetUserId)
	
	if success then
		updatePlayerAttributes(targetUserId)
		return true, "Owner agregado"
	end
	
	return false, result
end

RemoveOwner.OnServerInvoke = function(player, targetUserId)
	if not player or not targetUserId then return false, "Parámetros inválidos" end
	
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	if not playerClan then return false, "No tienes clan" end
	
	local clanId = playerClan.clanId
	local member = playerClan.members[tostring(player.UserId)]
	
	if not member or not Config:HasPermission(member.role, "remover_owner") then
		return false, "Sin permiso"
	end
	
	local success, result = ClanData:RemoveOwner(clanId, targetUserId)
	
	if success then
		updatePlayerAttributes(targetUserId)
		return true, "Owner removido"
	end
	
	return false, result
end

AdminDissolveClan.OnServerInvoke = function(player, clanId)
	if not clanId then
		warn("[ClanServer] AdminDissolveClan: clanId recibido es nil para jugador", player.Name)
		return false, "ID del clan inválido"
	end
	
	local ok, err = checkCooldown(player.UserId, "AdminDissolveClan", Config:GetRateLimit("AdminDissolveClan"))
	if not ok then return false, err end
	
	if not isAdmin(player.UserId) then
		return false, "Sin permisos de administrador"
	end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then 
		warn("[ClanServer] AdminDissolveClan: Clan no encontrado con ID:", clanId)
		return false, "Clan no encontrado" 
	end
	
	-- Validar que members existe antes de iterar
	local members = {}
	if clan.members and type(clan.members) == "table" then
		for userIdStr in pairs(clan.members) do
			local userId = tonumber(userIdStr)
			if userId then
				table.insert(members, userId)
			end
		end
	else
		warn("[ClanServer] AdminDissolveClan: clan.members inválido para clanId:", clanId)
	end
	
	local success, result = ClanData:DissolveClan(clanId)
	
	if success then
		for _, userId in ipairs(members) do
			pcall(function()
				updatePlayerAttributes(userId)
			end)
		end
		return true, "Clan disuelto (Admin)"
	end
	
	return false, result or "Error desconocido"
end

DissolveClan.OnServerInvoke = function(player, clanId)
	local ok, err = checkCooldown(player.UserId, "DissolveClan", Config:GetRateLimit("DissolveClan"))
	if not ok then return false, err end
	
	if not clanId then
		return false, "ID del clan inválido"
	end
	
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	-- Solo owners pueden disolver
	if not clan.owners or not table.find(clan.owners, player.UserId) then
		return false, "Solo owners pueden disolver"
	end
	
	-- Validar que members existe antes de iterar
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
		return true, "Clan disuelto"
	end
	
	return false, result or "Error desconocido"
end

LeaveClan.OnServerInvoke = function(player, clanId)
	local clan = ClanData:GetClan(clanId)
	if not clan then return false, "Clan no encontrado" end
	
	-- Owners no pueden abandonar
	if table.find(clan.owners, player.UserId) then
		return false, "Owners no pueden abandonar. Disuelve el clan o transfiere ownership"
	end
	
	local success, result = ClanData:RemoveMember(clanId, player.UserId)
	
	if success then
		-- TAMBIÉN limpiar solicitudes pendientes del usuario en este clan
		ClanData:CancelRequest(clanId, player.UserId)
		
		updatePlayerAttributes(player.UserId)
		return true, "Has abandonado el clan"
	end
	
	return false, result
end

-- ============================================
-- SOLICITUDES (nombres compatibles V1)
-- ============================================

RequestJoinClan.OnServerInvoke = function(player, clanId)
	local ok, err = checkCooldown(player.UserId, "RequestJoinClan", Config:GetRateLimit("RequestJoinClan"))
	if not ok then return false, err end
	
	local success, result = ClanData:RequestJoin(clanId, player.UserId)
	
	if success then
		-- Notificar INMEDIATAMENTE al jugador que solicitó
		RequestJoinResult:FireClient(player, true, clanId, "Solicitud enviada")
		-- El evento ClansUpdated se dispara automáticamente desde ClanData:OnUpdate()
		return true, result
	else
		RequestJoinResult:FireClient(player, false, clanId, result)
		return false, result
	end
end

ApproveJoinRequest.OnServerInvoke = function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "ApproveJoinRequest", Config:GetRateLimit("ApproveJoinRequest"))
	if not ok then return false, err end
	
	local success, result = ClanData:ApproveRequest(clanId, player.UserId, targetUserId)
	
	if success then
		updatePlayerAttributes(targetUserId)
	end
	
	return success, result
end

RejectJoinRequest.OnServerInvoke = function(player, clanId, targetUserId)
	local ok, err = checkCooldown(player.UserId, "RejectJoinRequest", Config:GetRateLimit("RejectJoinRequest"))
	if not ok then return false, err end
	
	local success, result = ClanData:RejectRequest(clanId, player.UserId, targetUserId)
	
	return success, result
end

GetJoinRequests.OnServerInvoke = function(player, clanId)
	local result = ClanData:GetClanRequests(clanId, player.UserId)
	return result
end

GetUserPendingRequests.OnServerInvoke = function(player)
	return ClanData:GetUserRequests(player.UserId)
end

CancelJoinRequest.OnServerInvoke = function(player, clanId)
	local success, result = ClanData:CancelRequest(clanId, player.UserId)
	
	return success, result
end


CancelAllJoinRequests.OnServerInvoke = function(player)
	local success, result = ClanData:CancelAllRequests(player.UserId)
	
	return success, result
end

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
ClanData:OnUpdate():Connect(function()
	notifyClansUpdated()
end)

return {}
