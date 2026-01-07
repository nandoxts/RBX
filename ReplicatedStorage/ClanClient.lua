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
	CreateClanEvent:FireServer(clanName, clanLogo or "rbxassetid://0", clanDesc or "Sin descripción")
	self:RefreshClanData()
end

-- Invitar jugador
function ClanClient:InvitePlayer(targetUserId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	InvitePlayerEvent:FireServer(self.currentClanId, targetUserId)
end

-- Expulsar jugador
function ClanClient:KickPlayer(targetUserId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	KickPlayerEvent:FireServer(self.currentClanId, targetUserId)
end

-- Cambiar rol
function ClanClient:ChangePlayerRole(targetUserId, newRole)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	ChangeRoleEvent:FireServer(self.currentClanId, targetUserId, newRole)
end

-- Cambiar nombre del clan
function ClanClient:ChangeClanName(newName)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	ChangeClanNameEvent:FireServer(self.currentClanId, newName)
end

-- Cambiar descripción
function ClanClient:ChangeClanDescription(newDesc)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	ChangeClanDescEvent:FireServer(self.currentClanId, newDesc)
end

-- Cambiar logo
function ClanClient:ChangeClanLogo(newLogoId)
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	ChangeClanLogoEvent:FireServer(self.currentClanId, newLogoId)
end

-- Disolver clan
function ClanClient:DissolveClan()
	if not self.currentClanId then
		print("No estás en un clan")
		return
	end
	DissolveEvent:FireServer(self.currentClanId)
end

-- Obtener datos del clan
function ClanClient:RefreshClanData()
	GetClanDataEvent:FireServer(self.currentClanId)
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

return ClanClient
