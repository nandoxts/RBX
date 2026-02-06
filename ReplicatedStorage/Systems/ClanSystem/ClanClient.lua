--[[
	CLAN CLIENT - Sistema Optimizado
	Soporta: emoji, color, solicitudes, roles
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════
-- THROTTLING
-- ════════════════════════════════════════════════════════════════
local throttleConfig = {
	GetClansList = 1,
	CreateClan = 3,
	AdminDissolveClan = 2,
	InvitePlayer = 1,
	RequestJoinClan = 5,
	ApproveJoinRequest = 1,
	RejectJoinRequest = 1,
	CancelJoinRequest = 1,
	GetJoinRequests = 2,
	ChangeRole = 2
}

local lastCallTimes = {}

local function checkThrottle(funcName)
	local interval = throttleConfig[funcName] or 1
	local last = lastCallTimes[funcName] or 0
	local now = tick()

	if (now - last) < interval then
		return false, string.format("Espera %.1fs", interval - (now - last))
	end

	lastCallTimes[funcName] = now
	return true
end

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN LAZY
-- ════════════════════════════════════════════════════════════════
local clanEvents = nil
local remoteFunctions = {}
local initialized = false

local function getRemote(name, timeout)
	if remoteFunctions[name] then return remoteFunctions[name] end
	if not clanEvents then return nil end

	local remote = clanEvents:WaitForChild(name, timeout or 5)
	if remote then
		remoteFunctions[name] = remote
	end
	return remote
end

local function ensureInitialized()
	if initialized then return true end

	clanEvents = ReplicatedStorage:WaitForChild("ClanEvents", 5)
	if not clanEvents then
		warn("[ClanClient] ClanEvents no encontrado")
		return false
	end

	-- Cargar funciones críticas
	getRemote("GetClansList")
	getRemote("GetPlayerClan")
	getRemote("CreateClan")

	-- Cargar resto en background
	task.spawn(function()
		getRemote("InvitePlayer")
		getRemote("KickPlayer")
		getRemote("ChangeRole")
		getRemote("ChangeClanName")
		getRemote("ChangeClanTag")
		getRemote("ChangeClanDescription")
		getRemote("ChangeClanLogo")
		getRemote("ChangeClanEmoji")
		getRemote("ChangeClanColor")
		getRemote("DissolveClan")
		getRemote("LeaveClan")
		getRemote("AdminDissolveClan")
		getRemote("RequestJoinClan")
		getRemote("ApproveJoinRequest")
		getRemote("RejectJoinRequest")
		getRemote("GetJoinRequests")
		getRemote("CancelJoinRequest")
		getRemote("CancelAllJoinRequests")
		getRemote("GetUserPendingRequests")
		getRemote("AddOwner")
		getRemote("RemoveOwner")
	end)

	initialized = true
	return true
end

-- ════════════════════════════════════════════════════════════════
-- CLAN CLIENT
-- ════════════════════════════════════════════════════════════════
local ClanClient = {}
ClanClient.currentClan = nil
ClanClient.currentClanId = nil
ClanClient.onClansUpdated = nil
ClanClient.initialized = false

-- Cache
local clansListCache = nil
local clansListCacheTime = 0
local pendingRequestsCache = nil
local pendingRequestsCacheTime = 0

function ClanClient:Initialize()
	if ensureInitialized() then
		self.initialized = true
	end
end

-- ════════════════════════════════════════════════════════════════
-- CREAR CLAN (con emoji y color)
-- ════════════════════════════════════════════════════════════════
function ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc, customOwnerId, clanEmoji, clanColor)
	local allowed, err = checkThrottle("CreateClan")
	if not allowed then return false, nil, err end

	local remote = getRemote("CreateClan")
	if not remote then return false, nil, "Función no disponible" end

	local success, clanId, msg = remote:InvokeServer(
		clanName,
		clanTag or "TAG",
		clanLogo or "rbxassetid://0",
		clanDesc or "Sin descripción",
		customOwnerId,
		clanEmoji or "⚔️",
		clanColor or {255, 255, 255}
	)

	if success then
		self.currentClanId = clanId
		self:GetPlayerClan()
	end

	return success, clanId, msg
end

-- ════════════════════════════════════════════════════════════════
-- OBTENER DATOS
-- ════════════════════════════════════════════════════════════════
function ClanClient:GetClansList()
	ensureInitialized()

	-- Cache de 5 segundos (más eficiente)
	if clansListCache and (tick() - clansListCacheTime) < 5 then
		return clansListCache
	end

	local allowed = checkThrottle("GetClansList")
	if not allowed then return clansListCache or {} end

	local remote = getRemote("GetClansList")
	if not remote then return clansListCache or {} end

	local success, clans = pcall(function()
		return remote:InvokeServer()
	end)

	if success and clans then
		clansListCache = clans
		clansListCacheTime = tick()
		return clans
	end

	return clansListCache or {}
end

function ClanClient:GetPlayerClan()
	ensureInitialized()

	local remote = getRemote("GetPlayerClan")
	if not remote then
		self.currentClan = nil
		self.currentClanId = nil
		return nil
	end

	local success, clanData = pcall(function()
		return remote:InvokeServer()
	end)

	if success and clanData then
		self.currentClan = clanData
		self.currentClanId = clanData.clanId
		return clanData
	end

	self.currentClan = nil
	self.currentClanId = nil
	return nil
end

-- ════════════════════════════════════════════════════════════════
-- GESTIÓN DE MIEMBROS
-- ════════════════════════════════════════════════════════════════
function ClanClient:InvitePlayer(targetUserId)
	local allowed, err = checkThrottle("InvitePlayer")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("InvitePlayer")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, targetUserId)
end

function ClanClient:KickPlayer(targetUserId)
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("KickPlayer")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, targetUserId)
end

function ClanClient:ChangePlayerRole(targetUserId, newRole)
	local allowed, err = checkThrottle("ChangeRole")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("ChangeRole")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, targetUserId, newRole)
end

-- ════════════════════════════════════════════════════════════════
-- EDICIÓN DEL CLAN
-- ════════════════════════════════════════════════════════════════
function ClanClient:ChangeClanName(newName)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanName")
	if not remote then return false, "Función no disponible" end
	return remote:InvokeServer(self.currentClanId, newName)
end

function ClanClient:ChangeClanTag(newTag)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanTag")
	if not remote then return false, "Función no disponible" end
	return remote:InvokeServer(self.currentClanId, newTag)
end

function ClanClient:ChangeClanDescription(newDesc)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanDescription")
	if not remote then return false, "Función no disponible" end
	return remote:InvokeServer(self.currentClanId, newDesc)
end

function ClanClient:ChangeClanLogo(newLogoId)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanLogo")
	if not remote then return false, "Función no disponible" end
	return remote:InvokeServer(self.currentClanId, newLogoId)
end

function ClanClient:ChangeClanEmoji(newEmoji)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanEmoji")
	if not remote then return false, "Función no disponible" end
	return remote:InvokeServer(self.currentClanId, newEmoji)
end

function ClanClient:ChangeClanColor(newColor)
	if not self.currentClanId then return false, "No estás en un clan" end
	local allowed, err = checkThrottle("ChangeColor")
	if not allowed then return false, err end

	local remote = getRemote("ChangeClanColor")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, newColor)
end

-- ════════════════════════════════════════════════════════════════
-- SALIR / DISOLVER
-- ════════════════════════════════════════════════════════════════
function ClanClient:LeaveClan()
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("LeaveClan")
	if not remote then return false, "Función no disponible" end

	local success, msg = remote:InvokeServer(self.currentClanId)
	if success then
		self.currentClan = nil
		self.currentClanId = nil
	end
	return success, msg
end

function ClanClient:DissolveClan()
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("DissolveClan")
	if not remote then return false, "Función no disponible" end

	local success, msg = remote:InvokeServer(self.currentClanId)
	if success then
		self.currentClan = nil
		self.currentClanId = nil
	end
	return success, msg
end

function ClanClient:AdminDissolveClan(clanId)
	if not clanId then 
		warn("[ClanClient] AdminDissolveClan: clanId es nil")
		return false, "ID del clan inválido" 
	end
	
	local allowed, err = checkThrottle("AdminDissolveClan")
	if not allowed then return false, err end

	local remote = getRemote("AdminDissolveClan")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(clanId)
end

-- ════════════════════════════════════════════════════════════════
-- SOLICITUDES DE UNIÓN
-- ════════════════════════════════════════════════════════════════
function ClanClient:RequestJoinClan(clanId)
	local allowed, err = checkThrottle("RequestJoinClan")
	if not allowed then return false, err end
	if self.currentClanId then return false, "Ya perteneces a un clan" end

	local remote = getRemote("RequestJoinClan")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(clanId)
end

function ClanClient:ApproveJoinRequest(clanId, targetUserId)
	local allowed, err = checkThrottle("ApproveJoinRequest")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("ApproveJoinRequest")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(clanId, targetUserId)
end

function ClanClient:RejectJoinRequest(clanId, targetUserId)
	local allowed, err = checkThrottle("RejectJoinRequest")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("RejectJoinRequest")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(clanId, targetUserId)
end

function ClanClient:GetJoinRequests(clanId)
	if not self.currentClanId then return {} end

	local remote = getRemote("GetJoinRequests")
	if not remote then return {} end

	local success, requests = pcall(function()
		return remote:InvokeServer(clanId)
	end)

	return (success and requests) or {}
end

function ClanClient:CancelJoinRequest(clanId)
	local allowed, err = checkThrottle("CancelJoinRequest")
	if not allowed then return false, err end

	local remote = getRemote("CancelJoinRequest")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(clanId)
end

function ClanClient:CancelAllJoinRequests()
	ensureInitialized()

	local remote = getRemote("CancelAllJoinRequests")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer()
end

function ClanClient:GetUserPendingRequests()
	ensureInitialized()

	-- Cache de 2 segundos
	if pendingRequestsCache and (tick() - pendingRequestsCacheTime) < 2 then
		return pendingRequestsCache
	end

	local remote = getRemote("GetUserPendingRequests")
	if not remote then return {} end

	local success, result = pcall(function()
		return remote:InvokeServer()
	end)

	if success and type(result) == "table" then
		pendingRequestsCache = result
		pendingRequestsCacheTime = tick()
		return result
	end

	return {}
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER DE ACTUALIZACIONES
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	ensureInitialized()

	local updateEvent = clanEvents and clanEvents:WaitForChild("ClansUpdated", 5)
	if updateEvent then
		updateEvent.OnClientEvent:Connect(function(clans)
			-- Actualizar cache
			clansListCache = clans
			clansListCacheTime = tick()

			-- Notificar UI
			if ClanClient.onClansUpdated then
				ClanClient.onClansUpdated(clans)
			end
		end)
	end
end)

-- ════════════════════════════════════════════════════════════════
-- MÚLTIPLES OWNERS
-- ════════════════════════════════════════════════════════════════
function ClanClient:AddOwner(targetUserId)
	local allowed, err = checkThrottle("ChangeRole")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("AddOwner")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, targetUserId)
end

function ClanClient:RemoveOwner(targetUserId)
	local allowed, err = checkThrottle("ChangeRole")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("RemoveOwner")
	if not remote then return false, "Función no disponible" end

	return remote:InvokeServer(self.currentClanId, targetUserId)
end

return ClanClient