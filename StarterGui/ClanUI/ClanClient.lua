local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que los eventos estén listos
local clanEvents = ReplicatedStorage:WaitForChild("ClanEvents")
local CreateClanEvent = clanEvents:WaitForChild("CreateClan")
local InvitePlayerEvent = clanEvents:WaitForChild("InvitePlayer")
local KickPlayerEvent = clanEvents:WaitForChild("KickPlayer")
local ChangeRoleEvent = clanEvents:WaitForChild("ChangeRole")
local ChangeClanNameEvent = clanEvents:WaitForChild("ChangeClanName")
local ChangeClanDescEvent = clanEvents:WaitForChild("ChangeClanDescription")
local ChangeClanLogoEvent = clanEvents:WaitForChild("ChangeClanLogo")
local DissolveEvent = clanEvents:WaitForChild("DissolveClan")
local GetClanDataEvent = clanEvents:WaitForChild("GetClanData")

local ClanClient = {}
ClanClient.currentClan = nil
ClanClient.currentClanId = nil

-- Crear clan
function ClanClient:CreateClan(clanName, clanLogo)
CreateClanEvent:FireServer(clanName, clanLogo or "rbxassetid://0")
wait(0.5)
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

return ClanClient
