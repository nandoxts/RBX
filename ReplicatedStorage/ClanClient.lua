local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crear o esperar a que ClanEvents exista
local clanEvents = ReplicatedStorage:FindFirstChild("ClanEvents")
if not clanEvents then
	clanEvents = Instance.new("Folder")
	clanEvents.Name = "ClanEvents"
	clanEvents.Parent = ReplicatedStorage
end

-- Crear eventos si no existen
local function GetOrCreateEvent(name)
	local event = clanEvents:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = clanEvents
	end
	return event
end

local function GetOrCreateFunction(name)
	local func = clanEvents:FindFirstChild(name)
	if not func then
		func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = clanEvents
	end
	return func
end

local CreateClanEvent = GetOrCreateEvent("CreateClan")
local InvitePlayerEvent = GetOrCreateEvent("InvitePlayer")
local KickPlayerEvent = GetOrCreateEvent("KickPlayer")
local ChangeRoleEvent = GetOrCreateEvent("ChangeRole")
local ChangeClanNameEvent = GetOrCreateEvent("ChangeClanName")
local ChangeClanDescEvent = GetOrCreateEvent("ChangeClanDescription")
local ChangeClanLogoEvent = GetOrCreateEvent("ChangeClanLogo")
local DissolveEvent = GetOrCreateEvent("DissolveClan")
local GetClanDataEvent = GetOrCreateEvent("GetClanData")
local GetClansListFunction = GetOrCreateFunction("GetClansList")

local ClanClient = {}
ClanClient.currentClan = nil
ClanClient.currentClanId = nil

-- Crear clan
function ClanClient:CreateClan(clanName, clanLogo, clanDesc)
	local func = clanEvents:FindFirstChild("CreateClan")
	if func then
		local success, clanId, msg = func:InvokeServer(clanName, clanLogo or "rbxassetid://0", clanDesc or "Sin descripción")
		if success then
			self:RefreshClanData()
		end
		return success, clanId, msg
	else
		warn("[Clan] No se encontró función CreateClan")
		return false, nil, "Función no disponible"
	end
end

-- Invitar jugador
function ClanClient:InvitePlayer(targetUserId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("InvitePlayer")
	if event then
		event:FireServer(self.currentClanId, targetUserId)
	end
end

-- Expulsar jugador
function ClanClient:KickPlayer(targetUserId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("KickPlayer")
	if event then
		event:FireServer(self.currentClanId, targetUserId)
	end
end

-- Cambiar rol
function ClanClient:ChangePlayerRole(targetUserId, newRole)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("ChangeRole")
	if event then
		event:FireServer(self.currentClanId, targetUserId, newRole)
	end
end

-- Cambiar nombre del clan
function ClanClient:ChangeClanName(newName)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("ChangeClanName")
	if event then
		event:FireServer(self.currentClanId, newName)
	end
end

-- Cambiar descripción
function ClanClient:ChangeClanDescription(newDesc)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("ChangeClanDescription")
	if event then
		event:FireServer(self.currentClanId, newDesc)
	end
end

-- Cambiar logo
function ClanClient:ChangeClanLogo(newLogoId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("ChangeClanLogo")
	if event then
		event:FireServer(self.currentClanId, newLogoId)
	end
end

-- Disolver clan
function ClanClient:DissolveClan()
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	local event = clanEvents:FindFirstChild("DissolveClan")
	if event then
		event:FireServer(self.currentClanId)
	end
end

-- Obtener datos del clan
function ClanClient:RefreshClanData()
	GetClanDataEvent:FireServer(self.currentClanId)
end

-- Unirse a un clan
function ClanClient:JoinClan(clanId)
	local func = clanEvents:FindFirstChild("JoinClan")
	if func then
		local success, msg = func:InvokeServer(clanId)
		if success then
			self:RefreshClanData()
		end
		return success, msg
	else
		warn("[Clan] No se encontró función JoinClan")
		return false, "Función no disponible"
	end
end

-- Obtener lista de todos los clanes
function ClanClient:GetClansList()
	local GetClansListFunc = clanEvents:FindFirstChild("GetClansList")
	if GetClansListFunc then
		local success, clans = pcall(function()
			return GetClansListFunc:InvokeServer()
		end)

		if success then
			return clans or {}
		else
			warn("Error obteniendo lista de clanes:", clans)
			return {}
		end
	end
	return {}
end

-- Obtener el clan actual del jugador
function ClanClient:GetPlayerClan()
	local GetPlayerClanFunc = clanEvents:FindFirstChild("GetPlayerClan")
	if GetPlayerClanFunc then
		local success, clanData = pcall(function()
			return GetPlayerClanFunc:InvokeServer()
		end)
		
		if success then
			return clanData
		else
			warn("Error obteniendo clan del jugador:", clanData)
			return nil
		end
	end
	return nil
end

-- Disolver clan como admin
function ClanClient:AdminDissolveClan(clanId)
	local func = clanEvents:FindFirstChild("AdminDissolveClan")
	if func then
		local success, msg = func:InvokeServer(clanId)
		return success, msg
	else
		warn("[Clan] No se encontró función AdminDissolveClan")
		return false, "Función no disponible"
	end
end

return ClanClient
