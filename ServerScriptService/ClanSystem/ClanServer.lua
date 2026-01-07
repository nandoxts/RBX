local ClanAPI = require(game:GetService("ServerStorage"):WaitForChild("ClanModules"):WaitForChild("ClanAPI"))

-- Script principal que gestiona el sistema de clanes
-- Este script debería ser puesto en ServerScriptService

print("Sistema de Clanes cargado correctamente")

-- Asegurarse de que ClanEvents no exista ya
local existingEvents = game.ReplicatedStorage:FindFirstChild("ClanEvents")
if existingEvents then
	existingEvents:Destroy()
end

-- Variables globales
local ClanSystem = {}

-- Funciones de inicialización
function ClanSystem:Init()
	print("Iniciando sistema de clanes...")
end

-- Crear RemoteEvents para comunicación cliente-servidor
local clanEvents = Instance.new("Folder")
clanEvents.Name = "ClanEvents"
clanEvents.Parent = game:GetService("ReplicatedStorage")

-- Crear RemoteEvents
local CreateClanEvent = Instance.new("RemoteEvent")
CreateClanEvent.Name = "CreateClan"
CreateClanEvent.Parent = clanEvents

local InvitePlayerEvent = Instance.new("RemoteEvent")
InvitePlayerEvent.Name = "InvitePlayer"
InvitePlayerEvent.Parent = clanEvents

local KickPlayerEvent = Instance.new("RemoteEvent")
KickPlayerEvent.Name = "KickPlayer"
KickPlayerEvent.Parent = clanEvents

local ChangeRoleEvent = Instance.new("RemoteEvent")
ChangeRoleEvent.Name = "ChangeRole"
ChangeRoleEvent.Parent = clanEvents

local ChangeClanNameEvent = Instance.new("RemoteEvent")
ChangeClanNameEvent.Name = "ChangeClanName"
ChangeClanNameEvent.Parent = clanEvents

local ChangeClanDescEvent = Instance.new("RemoteEvent")
ChangeClanDescEvent.Name = "ChangeClanDescription"
ChangeClanDescEvent.Parent = clanEvents

local ChangeClanLogoEvent = Instance.new("RemoteEvent")
ChangeClanLogoEvent.Name = "ChangeClanLogo"
ChangeClanLogoEvent.Parent = clanEvents

local DissolveEvent = Instance.new("RemoteEvent")
DissolveEvent.Name = "DissolveClan"
DissolveEvent.Parent = clanEvents

local GetClanDataEvent = Instance.new("RemoteEvent")
GetClanDataEvent.Name = "GetClanData"
GetClanDataEvent.Parent = clanEvents

-- RemoteFunction para obtener lista de clanes
local GetClansListFunction = Instance.new("RemoteFunction")
GetClansListFunction.Name = "GetClansList"
GetClansListFunction.Parent = clanEvents

-- Event handlers
CreateClanEvent.OnServerEvent:Connect(function(player, clanName, clanLogo, clanDesc)
	local success, clanId, clanData = ClanAPI:CreateClan(clanName, player.UserId, clanLogo, clanDesc)
	if success then
		print(player.Name .. " creó el clan: " .. clanName)
	else
		print("Error creando clan: " .. tostring(clanId))
	end
end)

InvitePlayerEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId)
	local success, msg = ClanAPI:InvitePlayerToClan(clanId, player.UserId, targetPlayerId)

	if success then
		print(player.Name .. " invitó a un jugador al clan")
	else
		print("Error invitando jugador: " .. msg)
	end
end)

KickPlayerEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId)
	local success, msg = ClanAPI:KickPlayerFromClan(clanId, player.UserId, targetPlayerId)

	if success then
		print(player.Name .. " expulsó a un jugador del clan")
	else
		print("Error expulsando jugador: " .. msg)
	end
end)

ChangeRoleEvent.OnServerEvent:Connect(function(player, clanId, targetPlayerId, newRole)
	local success, msg = ClanAPI:ChangePlayerRole(clanId, player.UserId, targetPlayerId, newRole)

	if success then
		print(player.Name .. " cambió el rol de un miembro")
	else
		print("Error cambiando rol: " .. msg)
	end
end)

ChangeClanNameEvent.OnServerEvent:Connect(function(player, clanId, newName)
	local success, msg = ClanAPI:ChangeClanName(clanId, player.UserId, newName)

	if success then
		print("Nombre del clan actualizado a: " .. newName)
	else
		print("Error actualizando nombre: " .. msg)
	end
end)

ChangeClanDescEvent.OnServerEvent:Connect(function(player, clanId, newDesc)
	local success, msg = ClanAPI:ChangeClanDescription(clanId, player.UserId, newDesc)

	if success then
		print("Descripción del clan actualizada")
	else
		print("Error actualizando descripción: " .. msg)
	end
end)

ChangeClanLogoEvent.OnServerEvent:Connect(function(player, clanId, newLogoId)
	local success, msg = ClanAPI:ChangeClanLogo(clanId, player.UserId, newLogoId)

	if success then
		print("Logo del clan actualizado")
	else
		print("Error actualizando logo: " .. msg)
	end
end)

DissolveEvent.OnServerEvent:Connect(function(player, clanId)
	local success, msg = ClanAPI:DissolveClan(clanId, player.UserId)

	if success then
		print("Clan disuelto por: " .. player.Name)
	else
		print("Error disolviendo clan: " .. msg)
	end
end)

GetClanDataEvent.OnServerEvent:Connect(function(player, clanId)
	local clanData = ClanAPI:GetClanData(clanId)

	if clanData then
		GetClanDataEvent:FireClient(player, clanData)
	else
		GetClanDataEvent:FireClient(player, nil)
	end
end)

-- Función para obtener lista de clanes
GetClansListFunction.OnServerInvoke = function(player)
	local clansList = ClanAPI:GetAllClans()
	print("🔍 [GetClansList] Se solicitó lista de clanes. Total encontrados: " .. (clansList and #clansList or 0))
	if clansList and #clansList > 0 then
		for i, clan in ipairs(clansList) do
			print("  " .. i .. ". " .. clan.clanName .. " (ID: " .. clan.clanId .. ")")
		end
	end
	return clansList
end

-- Debug: Verificar que todo está conectado
print("✅ Sistema de Clanes inicializado correctamente")
print("   - ClanAPI cargado")
print("   - Carpeta ClanEvents creada")
print("   - Todos los RemoteEvents registrados")
print("   - RemoteFunction GetClansList lista")

return ClanSystem
