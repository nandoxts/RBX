local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
-- THROTTLING & SPAM PROTECTION
-- ════════════════════════════════════════════════════════════════
local throttleConfig = {
	GetClansList = 1, -- 1 segundo
	CreateClan = 2, -- 2 segundos
	JoinClan = 1, -- 1 segundo
	AdminDissolveClan = 3, -- 3 segundos
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

-- Esperar a que ClanEvents exista (creado por el servidor)
local clanEvents = ReplicatedStorage:WaitForChild("ClanEvents")

-- SOLO OBTENER REFERENCIAS A LAS REMOTEFUNCTIONS CREADAS POR EL SERVIDOR
-- NO CREARLAS AQUÍ
local function WaitForFunction(name, timeout)
	timeout = timeout or 30
	local startTime = tick()
	while tick() - startTime < timeout do
		local func = clanEvents:FindFirstChild(name)
		if func and func:IsA("RemoteFunction") then
			return func
		end
		task.wait(0.1)
	end
	warn("⚠️ [ClanClient] RemoteFunction no encontrada:", name)
	return nil
end

-- Obtener referencias (esperar al servidor)
local CreateClanFunction = WaitForFunction("CreateClan")
local InvitePlayerFunction = WaitForFunction("InvitePlayer")
local KickPlayerFunction = WaitForFunction("KickPlayer")
local ChangeRoleFunction = WaitForFunction("ChangeRole")
local ChangeClanNameFunction = WaitForFunction("ChangeClanName")
local ChangeClanTagFunction = WaitForFunction("ChangeClanTag")
local ChangeClanDescFunction = WaitForFunction("ChangeClanDescription")
local ChangeClanLogoFunction = WaitForFunction("ChangeClanLogo")
local DissolveFunction = WaitForFunction("DissolveClan")
local GetClansListFunction = WaitForFunction("GetClansList")
local LeaveClanFunction = WaitForFunction("LeaveClan")
local GetPlayerClanFunction = WaitForFunction("GetPlayerClan")
local JoinClanEvent = WaitForFunction("JoinClan")
local AdminDissolveFunction = WaitForFunction("AdminDissolveClan")

-- Esperar por GetClanDataEvent (RemoteEvent)
local GetClanDataEvent = clanEvents:WaitForChild("GetClanData", 30)
local ClansUpdatedEvent = clanEvents:WaitForChild("ClansUpdated", 30)

local ClanClient = {}
ClanClient.currentClan = nil
ClanClient.currentClanId = nil
ClanClient.onClansUpdated = nil -- Callback para UI

-- Crear clan
function ClanClient:CreateClan(clanName, clanTag, clanLogo, clanDesc)
	-- Throttling
	local allowed, errMsg = checkThrottle("CreateClan")
	if not allowed then
		return false, nil, errMsg
	end
	
	if CreateClanFunction then
		local success, clanId, msg = CreateClanFunction:InvokeServer(clanName, clanTag or "TAG", clanLogo or "rbxassetid://0", clanDesc or "Sin descripción")
		if success then
			-- Actualizar el ID del clan recién creado
			self.currentClanId = clanId
			-- Obtener los datos completos del clan
			self:GetPlayerClan()
		end
		return success, clanId, msg
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

-- Obtener lista de todos los clanes (directo desde servidor, sin caché)
function ClanClient:GetClansList()
	-- Throttling
	local allowed, errMsg = checkThrottle("GetClansList")
	if not allowed then
		warn("[Throttle] GetClansList: " .. errMsg)
		return self._lastClansList or {}
	end
	
	if GetClansListFunction then
		local success, clans = pcall(function()
			return GetClansListFunction:InvokeServer()
		end)

		if success then
			self._lastClansList = clans or {}
			return clans or {}
		else
			warn("❌ Error obteniendo lista de clanes:", clans)
			return self._lastClansList or {}
		end
	else
		warn("❌ GetClansList RemoteFunction no encontrada. ClanEvents:", clanEvents)
	end
	return {}
end

-- Obtener el clan actual del jugador
function ClanClient:GetPlayerClan()
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
if ClansUpdatedEvent then
	ClansUpdatedEvent.OnClientEvent:Connect(function(clans)
		-- Notificar a la UI si hay callback registrado
		if ClanClient.onClansUpdated then
			ClanClient.onClansUpdated(clans)
		end
	end)
end

return ClanClient
