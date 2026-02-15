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

	clanEvents = ReplicatedStorage:WaitForChild("ClanEvents", 10)  -- Aumentar timeout
	if not clanEvents then
		warn("[ClanClient] ERROR: ClanEvents no encontrado después de 10s")
		return false
	end

	-- Cargar funciones críticas Y ESPERAR A QUE EXISTAN
	local criticalRemotes = {"GetClansList", "GetPlayerClan", "CreateClan"}
	for _, remoteName in ipairs(criticalRemotes) do
		local remote = getRemote(remoteName, 10)
		if not remote then
			warn("[ClanClient] ERROR: Remote " .. remoteName .. " no encontrado")
			return false
		end
	end

	-- Cargar resto en background (no bloqueador)
	task.spawn(function()
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
ClanClient._updateCallbacks = {}  -- Array de callbacks que se ejecutan
ClanClient.initialized = false

-- Registrar un nuevo callback para actualizaciones
function ClanClient:OnClansUpdated(callback)
	if type(callback) == "function" then
		table.insert(self._updateCallbacks, callback)
	end
end

-- Ejecutar todos los callbacks registrados
function ClanClient:_fireUpdateCallbacks(clans)
	for _, callback in ipairs(self._updateCallbacks) do
		pcall(callback, clans)
	end
end

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

	-- Si NO estamos en un clan, SIEMPRE traer fresco (no cachear)
	if not self.currentClanId then
		local allowed = checkThrottle("GetClansList")
		if not allowed then 
			return clansListCache or {} 
		end

		local remote = getRemote("GetClansList")
		if not remote then 
			warn("[ClanClient] GetClansList: Remote no disponible")
			return {} 
		end

		local success, clans = pcall(function()
			return remote:InvokeServer()
		end)

		if success and clans and type(clans) == "table" then
			return clans  -- No cachear si estamos sin clan
		else
			warn("[ClanClient] GetClansList: Error en InvokeServer:", clans)
			return {}
		end
	end

	-- Si ESTAMOS en un clan, usar caché de 5 segundos
	if clansListCache and (tick() - clansListCacheTime) < 5 then
		return clansListCache
	end

	local allowed = checkThrottle("GetClansList")
	if not allowed then 
		return clansListCache or {} 
	end

	local remote = getRemote("GetClansList")
	if not remote then 
		warn("[ClanClient] GetClansList: Remote no disponible")
		return clansListCache or {} 
	end

	local success, clans = pcall(function()
		return remote:InvokeServer()
	end)

	if success and clans and type(clans) == "table" then
		clansListCache = clans
		clansListCacheTime = tick()
		return clans
	else
		warn("[ClanClient] GetClansList: Error en InvokeServer:", clans)
		return clansListCache or {}
	end
end

function ClanClient:GetPlayerClan()
	ensureInitialized()

	local remote = getRemote("GetPlayerClan")
	if not remote then
		warn("[ClanClient] GetPlayerClan: Remote no disponible")
		self.currentClan = nil
		self.currentClanId = nil
		return nil
	end

	local success, clanData = pcall(function()
		return remote:InvokeServer()
	end)

	if success and clanData and type(clanData) == "table" then
		self.currentClan = clanData
		self.currentClanId = clanData.clanId
		return clanData
	else
		self.currentClan = nil
		self.currentClanId = nil
		return nil
	end
end

function ClanClient:KickPlayer(targetUserId)
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("KickPlayer")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId, targetUserId)
	return true
end

function ClanClient:ChangePlayerRole(targetUserId, newRole)
	local allowed, err = checkThrottle("ChangeRole")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("ChangeRole")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId, targetUserId, newRole)
	return true
end

-- ════════════════════════════════════════════════════════════════
-- EDICIÓN DEL CLAN
-- ════════════════════════════════════════════════════════════════
function ClanClient:ChangeClanName(newName)
	if not self.currentClanId then 
		return false, "No estás en un clan" 
	end

	local remote = getRemote("ChangeClanName")
	if not remote then 
		return false, "Función no disponible" 
	end

	remote:FireServer(self.currentClanId, newName)

	-- 🔥 INVALIDAR CACHE INMEDIATAMENTE
	clansListCache = nil
	clansListCacheTime = 0

	return true
end

function ClanClient:ChangeClanTag(newTag)
	if not self.currentClanId then 
		return false, "No estás en un clan" 
	end

	local remote = getRemote("ChangeClanTag")
	if not remote then 
		return false, "Función no disponible" 
	end

	remote:FireServer(self.currentClanId, newTag)

	-- 🔥 INVALIDAR CACHE INMEDIATAMENTE
	clansListCache = nil
	clansListCacheTime = 0

	return true
end

function ClanClient:ChangeClanDescription(newDesc)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanDescription")
	if not remote then return false, "Función no disponible" end
	remote:FireServer(self.currentClanId, newDesc)
	return true
end

function ClanClient:ChangeClanLogo(newLogoId)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanLogo")
	if not remote then return false, "Función no disponible" end
	remote:FireServer(self.currentClanId, newLogoId)
	return true
end

function ClanClient:ChangeClanEmoji(newEmoji)
	if not self.currentClanId then return false, "No estás en un clan" end
	local remote = getRemote("ChangeClanEmoji")
	if not remote then return false, "Función no disponible" end
	remote:FireServer(self.currentClanId, newEmoji)
	return true
end

function ClanClient:ChangeClanColor(newColor)
	if not self.currentClanId then return false, "No estás en un clan" end
	local allowed, err = checkThrottle("ChangeColor")
	if not allowed then return false, err end

	local remote = getRemote("ChangeClanColor")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId, newColor)
	return true
end

-- ════════════════════════════════════════════════════════════════
-- SALIR / DISOLVER
-- ════════════════════════════════════════════════════════════════
function ClanClient:LeaveClan()
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("LeaveClan")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId)

	-- LIMPIAR ESTADO INMEDIATAMENTE
	self.currentClan = nil
	self.currentClanId = nil

	-- INVALIDAR TODA LA CACHÉ para refrescar listado
	clansListCache = nil
	clansListCacheTime = 0
	pendingRequestsCache = nil
	pendingRequestsCacheTime = 0

	return true
end

function ClanClient:DissolveClan()
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("DissolveClan")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId)

	-- LIMPIAR ESTADO INMEDIATAMENTE
	self.currentClan = nil
	self.currentClanId = nil

	-- INVALIDAR TODA LA CACHÉ
	clansListCache = nil
	clansListCacheTime = 0
	pendingRequestsCache = nil
	pendingRequestsCacheTime = 0

	return true
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

	remote:FireServer(clanId)
	return true
end

-- ════════════════════════════════════════════════════════════════
-- SOLICITUDES DE UNIÓN
-- ════════════════════════════════════════════════════════════════
function ClanClient:RequestJoinClan(clanId)
	local allowed, err = checkThrottle("RequestJoinClan")
	if not allowed then 
		return false, err 
	end
	if self.currentClanId then 
		return false, "Ya perteneces a un clan" 
	end

	local remote = getRemote("RequestJoinClan")
	if not remote then 
		return false, "Función no disponible" 
	end

	-- Disparar sin esperar (la respuesta se maneja en el listener global)
	remote:FireServer(clanId)
	return true
end

function ClanClient:ApproveJoinRequest(clanId, targetUserId)
	local allowed, err = checkThrottle("ApproveJoinRequest")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("ApproveJoinRequest")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(clanId, targetUserId)
	return true
end

function ClanClient:RejectJoinRequest(clanId, targetUserId)
	local allowed, err = checkThrottle("RejectJoinRequest")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("RejectJoinRequest")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(clanId, targetUserId)
	return true
end

function ClanClient:GetJoinRequests(clanId)
	if not self.currentClanId then 
		return {} 
	end

	local remote = getRemote("GetJoinRequests")
	if not remote then 
		return {} 
	end

	local success, requests = pcall(function()
		return remote:InvokeServer(clanId)
	end)

	if success then
		return requests
	else
		return {}
	end
end

function ClanClient:CancelJoinRequest(clanId)
	local allowed, err = checkThrottle("CancelJoinRequest")
	if not allowed then return false, err end

	local remote = getRemote("CancelJoinRequest")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(clanId)
	return true
end

function ClanClient:CancelAllJoinRequests()
	ensureInitialized()

	local remote = getRemote("CancelAllJoinRequests")
	if not remote then return false, "Función no disponible" end

	remote:FireServer()
	return true
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
-- FORZAR REFRESCO DE CACHE
-- ════════════════════════════════════════════════════════════════
function ClanClient:InvalidateCache()
	clansListCache = nil
	clansListCacheTime = 0
	pendingRequestsCache = nil
	pendingRequestsCacheTime = 0
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER DE ACTUALIZACIONES
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	if not ensureInitialized() then 
		warn("[ClanClient] No se pudo inicializar listeners")
		return 
	end

	local updateEvent = clanEvents and clanEvents:WaitForChild("ClansUpdated", 5)
	if updateEvent then
		updateEvent.OnClientEvent:Connect(function(changedClanId)
			-- El servidor notifica sobre un clan que cambió
			-- Invalidar TODA la caché para forzar refrescamiento inmediato
			clansListCache = nil
			clansListCacheTime = 0
			pendingRequestsCache = nil
			pendingRequestsCacheTime = 0

			-- Si es mi clan, también refrescarlo
			if changedClanId and changedClanId == ClanClient.currentClanId then
				ClanClient:GetPlayerClan()
			end

			-- Notificar UI que algo cambió
			ClanClient:_fireUpdateCallbacks(changedClanId)
		end)
	else
		warn("[ClanClient] ERROR: ClansUpdated event no encontrado")
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

	remote:FireServer(self.currentClanId, targetUserId)
	return true
end

function ClanClient:RemoveOwner(targetUserId)
	local allowed, err = checkThrottle("ChangeRole")
	if not allowed then return false, err end
	if not self.currentClanId then return false, "No estás en un clan" end

	local remote = getRemote("RemoveOwner")
	if not remote then return false, "Función no disponible" end

	remote:FireServer(self.currentClanId, targetUserId)
	return true
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER DE SINCRONIZACIÓN - Requestas pendientes
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	if not ensureInitialized() then return end

	local folder = ReplicatedStorage:WaitForChild("ClanEvents", 5)
	if not folder then return end

	local RequestJoinResult = folder:WaitForChild("RequestJoinResult", 5)
	if RequestJoinResult then
		RequestJoinResult.OnClientEvent:Connect(function(success, clanId, msg)
			-- Invalidar caché de solicitudes pendientes
			pendingRequestsCache = nil
			pendingRequestsCacheTime = 0

			-- ✅ Manejar notificaciones AQUÍ directamente (sin callbacks acumulativos)
			local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

			if success then
				Notify:Success("Solicitud enviada", msg or "Esperando aprobación", 5)
				clansListCache = nil
				clansListCacheTime = 0
			else
				Notify:Error("Error", msg or "No se pudo enviar", 5)
			end
		end)
	end
end)

return ClanClient