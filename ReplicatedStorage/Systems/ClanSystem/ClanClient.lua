local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Obtener player y playerGui de forma segura (lazy loading)
local player = Players.LocalPlayer
local playerGui

-- ════════════════════════════════════════════════════════════════
-- THROTTLING & SPAM PROTECTION
-- ════════════════════════════════════════════════════════════════
local throttleConfig = {
	GetClansList = 1, -- 1 segundo
	CreateClan = 0, -- 0 segundos (sin límite)
	JoinClan = 1, -- 1 segundo
	AdminDissolveClan = 0, -- 0 segundos (sin límite)
	InvitePlayer = 1 -- 1 segundo
}

local lastCallTimes = {} -- { funcName = lastTime }

local function checkThrottle(funcName)
	local minInterval = throttleConfig[funcName] or 1
	local lastTime = lastCallTimes[funcName] or 0
	local now = tick()
	
	if (now - lastTime) < minInterval then
		local remainingTime = minInterval - (now - lastTime)
		return false, "Espera " .. string.format("%.1f", remainingTime) .. "s antes de repetir"
	end
	
	lastCallTimes[funcName] = now
	return true, nil
end

-- ════════════════════════════════════════════════════════════════
-- LAZY INITIALIZATION (para evitar dependencias circulares)
-- ════════════════════════════════════════════════════════════════
local clanEvents = nil
local CreateClanFunction = nil
local InvitePlayerFunction = nil
local KickPlayerFunction = nil
local ChangeRoleFunction = nil
local ChangeClanNameFunction = nil
local ChangeClanTagFunction = nil
local ChangeClanDescFunction = nil
local ChangeClanLogoFunction = nil
local DissolveFunction = nil
local GetClansListFunction = nil
local LeaveClanFunction = nil
local GetPlayerClanFunction = nil
local JoinClanEvent = nil
local AdminDissolveFunction = nil
local GetClanDataEvent = nil
local ClansUpdatedEvent = nil
local initialized = false

-- SOLO OBTENER REFERENCIAS A LAS REMOTEFUNCTIONS CREADAS POR EL SERVIDOR
local function WaitForFunction(name, timeout)
	if not clanEvents then return nil end
	timeout = timeout or 5 -- Reducido de 30 a 5 segundos
	local func = clanEvents:WaitForChild(name, timeout)
	if not func or not func:IsA("RemoteFunction") then
		warn("⚠️ [ClanClient] RemoteFunction no encontrada:", name)
		return nil
	end
	return func
end

-- Función de inicialización (paralela y rápida)
local function EnsureInitialized()
	if initialized then return end
	
	-- Esperar a que ClanEvents exista (máximo 5 segundos)
	clanEvents = ReplicatedStorage:WaitForChild("ClanEvents", 5)
	if not clanEvents then
		warn("[ClanClient] ❌ No se pudo obtener ClanEvents")
		return
	end
	
	-- Obtener SOLO las funciones críticas primero (más rápido)
	GetClansListFunction = WaitForFunction("GetClansList")
	GetPlayerClanFunction = WaitForFunction("GetPlayerClan")
	JoinClanEvent = WaitForFunction("JoinClan")
	CreateClanFunction = WaitForFunction("CreateClan")
	
	-- Esperar eventos (RemoteEvent)
	GetClanDataEvent = clanEvents:WaitForChild("GetClanData", 5)
	ClansUpdatedEvent = clanEvents:WaitForChild("ClansUpdated", 5)
	
	-- Cargar el resto de funciones en background (no bloquear UI)
	task.spawn(function()
		InvitePlayerFunction = WaitForFunction("InvitePlayer")
		KickPlayerFunction = WaitForFunction("KickPlayer")
		ChangeRoleFunction = WaitForFunction("ChangeRole")
		ChangeClanNameFunction = WaitForFunction("ChangeClanName")
		ChangeClanTagFunction = WaitForFunction("ChangeClanTag")
		ChangeClanDescFunction = WaitForFunction("ChangeClanDescription")
		ChangeClanLogoFunction = WaitForFunction("ChangeClanLogo")
		DissolveFunction = WaitForFunction("DissolveClan")
		LeaveClanFunction = WaitForFunction("LeaveClan")
		AdminDissolveFunction = WaitForFunction("AdminDissolveClan")
		print("✅ [ClanClient] Funciones secundarias cargadas")
	end)
	
	initialized = true
	print("✅ [ClanClient] Inicialización rápida completada")
end



local ClanClient = {}
ClanClient.currentClan = nil
ClanClient.currentClanId = nil
ClanClient.onClansUpdated = nil -- Callback para UI

-- ════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN PÚBLICA
-- ════════════════════════════════════════════════════════════════
function ClanClient:Initialize()
	EnsureInitialized()
end

-- Crear clan
function ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc, customOwnerId)
	-- Throttling
	local allowed, errMsg = checkThrottle("CreateClan")
	if not allowed then
		return false, nil, errMsg
	end
	
	-- Usar customOwnerId si se proporciona, sino usar el UserId del jugador local
	local ownerId = customOwnerId or player.UserId
	
	if CreateClanFunction then
		local success, clanId, msg = CreateClanFunction:InvokeServer(clanName, clanTag or "TAG", clanLogo or "rbxassetid://0", clanDesc or "Sin descripción", ownerId)
		if success then
			-- Actualizar el ID del clan recién creado
			self.currentClanId = clanId
			-- Obtener los datos completos del clan
			self:GetPlayerClan()
			return true, clanId, msg or "Clan creado exitosamente"
		else
			-- Retornar el mensaje de error específico
			return false, nil, msg or "No se pudo crear el clan"
		end
	else
		warn("[Clan] No se encontró función CreateClan")
		return false, nil, "Función no disponible"
	end
end

-- Invitar jugador
function ClanClient:InvitePlayer(targetUserId)
	-- Throttling
	local allowed, errMsg = checkThrottle("InvitePlayer")
	if not allowed then
		return false, errMsg
	end
	
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if InvitePlayerFunction then
		local success, msg = InvitePlayerFunction:InvokeServer(self.currentClanId, targetUserId)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Expulsar jugador
function ClanClient:KickPlayer(targetUserId)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if KickPlayerFunction then
		local success, msg = KickPlayerFunction:InvokeServer(self.currentClanId, targetUserId)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Cambiar rol
function ClanClient:ChangePlayerRole(targetUserId, newRole)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if ChangeRoleFunction then
		local success, msg = ChangeRoleFunction:InvokeServer(self.currentClanId, targetUserId, newRole)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Cambiar nombre del clan
function ClanClient:ChangeClanName(newName)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if ChangeClanNameFunction then
		local success, msg = ChangeClanNameFunction:InvokeServer(self.currentClanId, newName)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Cambiar TAG del clan
function ClanClient:ChangeClanTag(newTag)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if ChangeClanTagFunction then
		local success, msg = ChangeClanTagFunction:InvokeServer(self.currentClanId, newTag)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Cambiar descripción
function ClanClient:ChangeClanDescription(newDesc)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if ChangeClanDescFunction then
		local success, msg = ChangeClanDescFunction:InvokeServer(self.currentClanId, newDesc)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Cambiar logo
function ClanClient:ChangeClanLogo(newLogoId)
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if ChangeClanLogoFunction then
		local success, msg = ChangeClanLogoFunction:InvokeServer(self.currentClanId, newLogoId)
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Disolver clan
function ClanClient:DissolveClan()
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if DissolveFunction then
		local success, msg = DissolveFunction:InvokeServer(self.currentClanId)
		if success then
			self.currentClan = nil
			self.currentClanId = nil
		end
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Salir del clan
function ClanClient:LeaveClan()
	if not self.currentClanId then
		return false, "No estás en un clan"
	end
	if LeaveClanFunction then
		local success, msg = LeaveClanFunction:InvokeServer(self.currentClanId)
		if success then
			-- Actualizar el estado del cliente solo si el servidor confirma
			self.currentClan = nil
			self.currentClanId = nil
		end
		return success, msg
	else
		return false, "Función no disponible"
	end
end

-- Obtener datos del clan
function ClanClient:RefreshClanData()
	GetClanDataEvent:FireServer(self.currentClanId)
end

-- Unirse a un clan
function ClanClient:JoinClan(clanId)
	-- Throttling
	local allowed, errMsg = checkThrottle("JoinClan")
	if not allowed then
		return false, errMsg
	end
	
	if JoinClanEvent then
		local success, msg = JoinClanEvent:InvokeServer(clanId)
		if success then
			-- Actualizar el estado del cliente
			self.currentClanId = clanId
			self:GetPlayerClan()
		end
		return success, msg
	else
		warn("[Clan] No se encontró función JoinClan")
		return false, "Función no disponible"
	end
end

-- Obtener lista de todos los clanes (con caché inteligente)
function ClanClient:GetClansList()
	EnsureInitialized()
	
	-- Si tenemos caché reciente (menos de 3 segundos), usarla
	if self._lastClansList and self._lastClansListTime and (tick() - self._lastClansListTime) < 3 then
		return self._lastClansList
	end
	
	-- Throttling
	local allowed, errMsg = checkThrottle("GetClansList")
	if not allowed then
		-- Retornar caché si está disponible
		return self._lastClansList or {}
	end
	
	if GetClansListFunction then
		local success, clans = pcall(function()
			return GetClansListFunction:InvokeServer()
		end)

		if success then
			self._lastClansList = clans or {}
			self._lastClansListTime = tick()
			return clans or {}
		else
			warn("❌ Error obteniendo lista de clanes:", clans)
			return self._lastClansList or {}
		end
	else
		warn("❌ GetClansList RemoteFunction no encontrada")
	end
	return self._lastClansList or {}
end

-- Obtener el clan actual del jugador
function ClanClient:GetPlayerClan()
	EnsureInitialized()
	if GetPlayerClanFunction then
		local success, clanData = pcall(function()
			return GetPlayerClanFunction:InvokeServer()
		end)
		
		if success and clanData then
			-- Actualizar el estado del cliente
			self.currentClan = clanData
			self.currentClanId = clanData.clanId
			return clanData
		else
			-- El jugador no está en ningún clan
			self.currentClan = nil
			self.currentClanId = nil
			if not success then
				warn("Error obteniendo clan del jugador:", clanData)
			end
			return nil
		end
	end
	self.currentClan = nil
	self.currentClanId = nil
	return nil
end

-- Disolver clan como admin
function ClanClient:AdminDissolveClan(clanId)
	-- Throttling
	local allowed, errMsg = checkThrottle("AdminDissolveClan")
	if not allowed then
		return false, errMsg
	end
	
	if AdminDissolveFunction then
		local success, msg = AdminDissolveFunction:InvokeServer(clanId)
		return success, msg
	else
		warn("[Clan] No se encontró función AdminDissolveClan")
		return false, "Función no disponible"
	end
end

-- Listener para actualizaciones en tiempo real (como DjDashboard)
task.spawn(function()
	EnsureInitialized()
	if ClansUpdatedEvent then
		ClansUpdatedEvent.OnClientEvent:Connect(function(clans)
			-- Notificar a la UI si hay callback registrado
			if ClanClient.onClansUpdated then
				ClanClient.onClansUpdated(clans)
			end
		end)
	end
end)

return ClanClient
