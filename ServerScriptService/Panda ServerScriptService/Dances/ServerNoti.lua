-- ============================================
--   SISTEMA DE NOTIFICACIONES (SERVER)
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")

local Remotos = ReplicatedStorage:WaitForChild("Eventos_Emote")
local RemoteNoti = Remotos:WaitForChild("RemoteNoti")

RemoteNoti.OnServerEvent:Connect(function(player, mensaje, modo, tiempo)

	RemoteNoti:FireClient(player, mensaje, modo, tiempo)

end)
