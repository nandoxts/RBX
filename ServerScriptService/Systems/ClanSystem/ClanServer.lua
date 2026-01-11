-- ============================================
-- CLAN SERVER - Sistema Consolidado de Clanes
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClanData = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))

-- ============================================
-- RATE LIMITING
-- ============================================
local playerRequestLimits = {}

local function checkRateLimit(userId, funcName)
	local userLimits = playerRequestLimits[tostring(userId)] or {}
	local lastTime = userLimits[funcName] or 0
	local now = os.time()
	local interval = Config:GetRateLimit(funcName) or 1

	if interval == 0 then return true, nil end

	if (now - lastTime) < interval then
		return false, "Espera " .. (interval - (now - lastTime)) .. " segundos"
	end

	playerRequestLimits[tostring(userId)] = userLimits
	userLimits[funcName] = now
	return true, nil
end

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================
local function isAdmin(userId)
	return Config:IsAdmin(userId)
end

local function hasPermission(rol, permiso)
	return Config:HasPermission(rol, permiso)
end

local function canActOn(userRole, targetRole, action)
	if userRole == "owner" then return true end
	if not hasPermission(userRole, action) then return false end
	return Config:GetRoleLevel(userRole) > Config:GetRoleLevel(targetRole)
end

-- ============================================
-- ATRIBUTOS PARA OVERHEAD
-- ============================================
local function updatePlayerClanAttributes(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local playerClan = ClanData:GetPlayerClan(userId)

	if playerClan and playerClan.clanId then
		local clanData = ClanData:GetClan(playerClan.clanId)

		if clanData then
			player:SetAttribute("ClanTag", clanData.clanTag or "")
			player:SetAttribute("ClanName", clanData.clanName or "")
			player:SetAttribute("ClanId", clanData.clanId or "")
			player:SetAttribute("ClanEmoji", clanData.clanEmoji or "")
			if clanData.clanColor and typeof(clanData.clanColor) == "table" then
				player:SetAttribute("ClanColor", Color3.fromRGB(
					tonumber(clanData.clanColor[1]) or 255,
					tonumber(clanData.clanColor[2]) or 255,
					tonumber(clanData.clanColor[3]) or 255
					))
			else
				player:SetAttribute("ClanColor", Color3.fromRGB(255, 255, 255))
			end
			return
		end
	end

	-- Limpiar atributos
	player:SetAttribute("ClanTag", nil)
	player:SetAttribute("ClanName", nil)
	player:SetAttribute("ClanId", nil)
	player:SetAttribute("ClanEmoji", nil)
	player:SetAttribute("ClanColor", nil)
end

-- ============================================
-- LÓGICA DE NEGOCIO
-- ============================================
local ClanSystem = {}

function ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	local allowed, errMsg = checkRateLimit(ownerId, "CreateClan")
	if not allowed then
		return false, nil, errMsg
	end
	return ClanData:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
end

function ClanSystem:GetClanData(clanId)
	return ClanData:GetClan(clanId)
end

function ClanSystem:GetPlayerClan(userId)
	return ClanData:GetPlayerClan(userId)
end

function ClanSystem:GetAllClans()
	return ClanData:GetAllClans()
end

function ClanSystem:JoinClan(clanId, playerId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	if clanData.miembros_data and clanData.miembros_data[tostring(playerId)] then
		return false, "Ya eres miembro de este clan"
	end

	local playerClan = ClanData:GetPlayerClan(playerId)
	if playerClan then
		return false, "Ya perteneces a otro clan"
	end

	local success, result = ClanData:AddMember(clanId, playerId, "miembro")
	if success then
		updatePlayerClanAttributes(playerId)
	end
	return success, success and "Te has unido al clan" or result
end

function ClanSystem:InvitePlayer(clanId, inviterId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local inviterData = clanData.miembros_data and clanData.miembros_data[tostring(inviterId)]
	if not inviterData then
		return false, "No eres miembro del clan"
	end

	if not hasPermission(inviterData.rol, "invitar") then
		return false, "No tienes permiso para invitar"
	end

	local success, result = ClanData:AddMember(clanId, targetUserId, "miembro")
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Jugador invitado" or result
end

function ClanSystem:KickPlayer(clanId, kickerId, targetUserId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	if kickerId == targetUserId then
		return false, "No puedes expulsarte a ti mismo"
	end

	local kickerData = clanData.miembros_data and clanData.miembros_data[tostring(kickerId)]
	local targetData = clanData.miembros_data and clanData.miembros_data[tostring(targetUserId)]

	if not kickerData then return false, "No eres miembro del clan" end
	if not targetData then return false, "El usuario no es miembro" end

	if not canActOn(kickerData.rol, targetData.rol, "expulsar") then
		return false, "No tienes permiso para expulsar a este usuario"
	end

	local success, result = ClanData:RemoveMember(clanId, targetUserId)
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Jugador expulsado" or result
end

function ClanSystem:ChangeRole(clanId, requesterId, targetUserId, newRole)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	local targetData = clanData.miembros_data and clanData.miembros_data[tostring(targetUserId)]

	if not requesterData then return false, "No eres miembro del clan" end
	if not targetData then return false, "El usuario no es miembro" end

	if not canActOn(requesterData.rol, targetData.rol, "cambiar_" .. newRole .. "s") then
		return false, "No tienes permiso para cambiar roles"
	end

	local success, result = ClanData:ChangeRole(clanId, targetUserId, newRole)
	if success then
		updatePlayerClanAttributes(targetUserId)
	end
	return success, success and "Rol actualizado" or result
end

function ClanSystem:ChangeName(clanId, requesterId, newName)
	if not newName or newName == "" then
		return false, "El nombre no puede estar vacío"
	end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_nombre") then
		return false, "No tienes permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanName = newName})
	if success then
		clanData = ClanData:GetClan(clanId)
		if clanData and clanData.miembros_data then
			for memberIdStr in pairs(clanData.miembros_data) do
				updatePlayerClanAttributes(tonumber(memberIdStr))
			end
		end
	end
	return success, success and "Nombre actualizado" or result
end

function ClanSystem:ChangeTag(clanId, requesterId, newTag)
	if not newTag or newTag == "" or #newTag < 2 or #newTag > 5 then
		return false, "El TAG debe tener entre 2 y 5 caracteres"
	end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or requesterData.rol ~= "owner" then
		return false, "Solo el owner puede cambiar el TAG"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanTag = string.upper(newTag)})
	if success then
		clanData = ClanData:GetClan(clanId)
		if clanData and clanData.miembros_data then
			for memberIdStr in pairs(clanData.miembros_data) do
				updatePlayerClanAttributes(tonumber(memberIdStr))
			end
		end
	end
	return success, success and "TAG actualizado" or result
end

function ClanSystem:ChangeDescription(clanId, requesterId, newDesc)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_descripcion") then
		return false, "No tienes permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {descripcion = newDesc})
	return success, success and "Descripción actualizada" or result
end

function ClanSystem:ChangeLogo(clanId, requesterId, newLogoId)
	if not newLogoId or newLogoId == "" then
		return false, "Logo inválido"
	end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local requesterData = clanData.miembros_data and clanData.miembros_data[tostring(requesterId)]
	if not requesterData or not hasPermission(requesterData.rol, "cambiar_logo") then
		return false, "No tienes permiso"
	end

	local success, result = ClanData:UpdateClan(clanId, {clanLogo = newLogoId})
	return success, success and "Logo actualizado" or result
end

function ClanSystem:DissolveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	if clanData.owner ~= requesterId then
		return false, "Solo el owner puede disolver el clan"
	end

	local members = clanData.miembros_data
	local success, err = ClanData:DissolveClan(clanId)

	if success and members then
		for memberIdStr in pairs(members) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Clan disuelto" or err
end

function ClanSystem:AdminDissolveClan(adminId, clanId)
	local allowed, errMsg = checkRateLimit(adminId, "AdminDissolveClan")
	if not allowed then
		return false, errMsg
	end

	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local adminName = Players:GetNameFromUserIdAsync(adminId)
	ClanData:LogAdminAction(adminId, adminName, "delete_clan", clanId, clanData.clanName, {
		memberCount = clanData.miembros and #clanData.miembros or 0,
		ownerUserId = clanData.owner
	})

	local members = clanData.miembros_data
	local success, err = ClanData:DissolveClan(clanId)

	if success and members then
		for memberIdStr in pairs(members) do
			updatePlayerClanAttributes(tonumber(memberIdStr))
		end
	end
	return success, success and "Clan disuelto por admin" or err
end

function ClanSystem:LeaveClan(clanId, requesterId)
	local clanData = ClanData:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	if clanData.owner == requesterId then
		return false, "El owner no puede abandonar el clan. Disuelve el clan si deseas"
	end

	local success, err = ClanData:RemoveMember(clanId, requesterId)
	if success then
		updatePlayerClanAttributes(requesterId)
	end
	return success, success and "Has abandonado el clan" or err
end

-- ============================================
-- EVENTOS
-- ============================================
local existingEvents = ReplicatedStorage:FindFirstChild("ClanEvents")
if existingEvents then existingEvents:Destroy() end

local clanEvents = Instance.new("Folder")
clanEvents.Name = "ClanEvents"
clanEvents.Parent = ReplicatedStorage

local CreateClanEvent = Instance.new("RemoteFunction", clanEvents)
CreateClanEvent.Name = "CreateClan"

local InvitePlayerEvent = Instance.new("RemoteFunction", clanEvents)
InvitePlayerEvent.Name = "InvitePlayer"

local KickPlayerEvent = Instance.new("RemoteFunction", clanEvents)
KickPlayerEvent.Name = "KickPlayer"

local ChangeRoleEvent = Instance.new("RemoteFunction", clanEvents)
ChangeRoleEvent.Name = "ChangeRole"

local ChangeClanNameEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanNameEvent.Name = "ChangeClanName"

local ChangeClanTagEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanTagEvent.Name = "ChangeClanTag"

local ChangeClanDescEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanDescEvent.Name = "ChangeClanDescription"

local ChangeClanLogoEvent = Instance.new("RemoteFunction", clanEvents)
ChangeClanLogoEvent.Name = "ChangeClanLogo"

local DissolveEvent = Instance.new("RemoteFunction", clanEvents)
DissolveEvent.Name = "DissolveClan"

local LeaveClanEvent = Instance.new("RemoteFunction", clanEvents)
LeaveClanEvent.Name = "LeaveClan"

local JoinClanEvent = Instance.new("RemoteFunction", clanEvents)
JoinClanEvent.Name = "JoinClan"

local AdminDissolveClanEvent = Instance.new("RemoteFunction", clanEvents)
AdminDissolveClanEvent.Name = "AdminDissolveClan"

local GetClanDataEvent = Instance.new("RemoteEvent", clanEvents)
GetClanDataEvent.Name = "GetClanData"

local ClansUpdatedEvent = Instance.new("RemoteEvent", clanEvents)
ClansUpdatedEvent.Name = "ClansUpdated"

local GetClansListFunction = Instance.new("RemoteFunction", clanEvents)
GetClansListFunction.Name = "GetClansList"

local GetPlayerClanFunction = Instance.new("RemoteFunction", clanEvents)
GetPlayerClanFunction.Name = "GetPlayerClan"

-- Evento de actualización
ClanData:OnClanDataUpdated():Connect(function()
	ClansUpdatedEvent:FireAllClients(ClanData:GetAllClans())
end)

-- ============================================
-- HANDLERS
-- ============================================
CreateClanEvent.OnServerInvoke = function(player, clanName, clanTag, clanLogo, clanDesc, customOwnerId)
	local ownerId = player.UserId
	if customOwnerId and isAdmin(player.UserId) then
		ownerId = customOwnerId
	end

	local success, clanId, result = ClanSystem:CreateClan(clanName, ownerId, clanTag, clanLogo, clanDesc)
	if success then
		updatePlayerClanAttributes(ownerId)
		return true, clanId, "Clan creado exitosamente"
	end
	return false, nil, tostring(result or "Error desconocido")
end

InvitePlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	return ClanSystem:InvitePlayer(clanId, player.UserId, targetPlayerId)
end

KickPlayerEvent.OnServerInvoke = function(player, clanId, targetPlayerId)
	return ClanSystem:KickPlayer(clanId, player.UserId, targetPlayerId)
end

ChangeRoleEvent.OnServerInvoke = function(player, clanId, targetPlayerId, newRole)
	return ClanSystem:ChangeRole(clanId, player.UserId, targetPlayerId, newRole)
end

ChangeClanNameEvent.OnServerInvoke = function(player, clanId, newName)
	return ClanSystem:ChangeName(clanId, player.UserId, newName)
end

ChangeClanTagEvent.OnServerInvoke = function(player, clanId, newTag)
	return ClanSystem:ChangeTag(clanId, player.UserId, newTag)
end

ChangeClanDescEvent.OnServerInvoke = function(player, clanId, newDesc)
	return ClanSystem:ChangeDescription(clanId, player.UserId, newDesc)
end

ChangeClanLogoEvent.OnServerInvoke = function(player, clanId, newLogoId)
	return ClanSystem:ChangeLogo(clanId, player.UserId, newLogoId)
end

DissolveEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:DissolveClan(clanId, player.UserId)
end

AdminDissolveClanEvent.OnServerInvoke = function(player, clanId)
	if not isAdmin(player.UserId) then
		return false, "No autorizado"
	end
	return ClanSystem:AdminDissolveClan(player.UserId, clanId)
end

GetClanDataEvent.OnServerEvent:Connect(function(player, clanId)
	GetClanDataEvent:FireClient(player, ClanSystem:GetClanData(clanId))
end)

JoinClanEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:JoinClan(clanId, player.UserId)
end

LeaveClanEvent.OnServerInvoke = function(player, clanId)
	return ClanSystem:LeaveClan(clanId, player.UserId)
end

GetClansListFunction.OnServerInvoke = function(player)
	local allClans = ClanData:GetAllClans()
	local playerClan = ClanData:GetPlayerClan(player.UserId)
	local playerClanId = playerClan and playerClan.clanId or nil

	for _, clan in ipairs(allClans) do
		clan.isPlayerMember = (clan.clanId == playerClanId)
	end

	return allClans
end

GetPlayerClanFunction.OnServerInvoke = function(player)
	local playerClan = ClanSystem:GetPlayerClan(player.UserId)
	if playerClan and playerClan.clanId then
		return ClanSystem:GetClanData(playerClan.clanId)
	end
	return nil
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================
task.spawn(function()
	-- Limpiar registros huérfanos de owners de DEFAULT_CLANS
	-- (esto se hace automáticamente en GetPlayerClan, pero lo hacemos explícito)
	for _, defaultClan in ipairs(Config.DEFAULT_CLANS or {}) do
		ClanData:GetPlayerClan(defaultClan.ownerId) -- Limpia automáticamente si es huérfano
	end

	-- Crear clanes por defecto
	local created = ClanData:CreateDefaultClans()

	-- Obtener todos los clanes
	local allClans = ClanData:GetAllClans()

	-- Notificar clientes
	ClansUpdatedEvent:FireAllClients(allClans)
end)

-- Inicializar atributos para jugadores conectados
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(updatePlayerClanAttributes, player.UserId)
end

Players.PlayerAdded:Connect(function(player)
	updatePlayerClanAttributes(player.UserId)
end)

return {}