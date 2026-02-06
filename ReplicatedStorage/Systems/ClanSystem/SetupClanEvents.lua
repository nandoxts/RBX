--[[
	SETUP CLAN EVENTS
	Ejecuta este script UNA VEZ en el servidor para crear todos los RemoteFunction y RemoteEvent
	Luego puedes eliminarlo o deshabilitarlo
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Crear carpeta principal
local clanEvents = ReplicatedStorage:FindFirstChild("ClanEvents")
if not clanEvents then
	clanEvents = Instance.new("Folder")
	clanEvents.Name = "ClanEvents"
	clanEvents.Parent = ReplicatedStorage
	print("✓ Carpeta ClanEvents creada")
else
	print("✓ ClanEvents ya existe")
end

-- Lista de RemoteFunctions necesarias
local remoteFunctions = {
	"GetClansList",
	"GetPlayerClan",
	"CreateClan",
	"InvitePlayer",
	"KickPlayer",
	"ChangeRole",
	"ChangeClanName",
	"ChangeClanTag",
	"ChangeClanDescription",
	"ChangeClanLogo",
	"ChangeClanColor",
	"DissolveClan",
	"LeaveClan",
	"AdminDissolveClan",
	"RequestJoinClan",
	"ApproveJoinRequest",
	"RejectJoinRequest",
	"GetJoinRequests",
	"CancelJoinRequest",
	"CancelAllJoinRequests",
	"GetUserPendingRequests",
	"AddOwner",
	"RemoveOwner"
}

-- Crear RemoteFunctions
for _, name in ipairs(remoteFunctions) do
	if not clanEvents:FindFirstChild(name) then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = clanEvents
		print("✓ RemoteFunction creada: " .. name)
	else
		print("  " .. name .. " ya existe")
	end
end

-- Lista de RemoteEvents necesarios
local remoteEvents = {
	"ClansUpdated"
}

-- Crear RemoteEvents
for _, name in ipairs(remoteEvents) do
	if not clanEvents:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = clanEvents
		print("✓ RemoteEvent creado: " .. name)
	else
		print("  " .. name .. " ya existe")
	end
end

print("═══════════════════════════════════════")
print("✓ SETUP COMPLETADO")
print("Ahora puedes deshabilitar este script")
print("═══════════════════════════════════════")
