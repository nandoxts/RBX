--[[
	TEST DONATION SYSTEM - PARA PRUEBAS DEL NUEVO USERPANEL
	
	COMANDOS:
	/testdon @Usuario 100    -> Simula una donación de 100 robux a @Usuario
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatService = game:GetService("Chat")

-- Esperar a que exista UserPanel folder
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local userPanelFolder = remotesGlobal:WaitForChild("UserPanel")

local DonationNotify = userPanelFolder:WaitForChild("DonationNotify")
local DonationMessage = userPanelFolder:WaitForChild("DonationMessage")

-- Tabla de comandos
local Commands = {}

function Commands:testdon(args, player)
	if #args < 2 then
		print("❌ Uso: /testdon @Usuario cantidad")
		return
	end

	local targetName = args[1]:gsub("@", "")
	local amount = tonumber(args[2])

	if not amount or amount <= 0 then
		print("❌ Cantidad debe ser un número mayor a 0")
		return
	end

	-- Buscar jugador objetivo
	local targetPlayer = nil
	local lowerTargetName = targetName:lower()

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower():sub(1, #lowerTargetName) == lowerTargetName then
			targetPlayer = plr
			break
		end
	end

	if not targetPlayer then
		print("❌ Jugador no encontrado: " .. targetName)
		return
	end

	print("✅ Simulando donación: " .. player.Name .. " donó R$" .. amount .. " a " .. targetPlayer.Name)

	-- Notificar a todos los clientes
	DonationNotify:FireAllClients(player.UserId, amount, targetPlayer.UserId)
	DonationMessage:FireAllClients(player.Name, amount, targetPlayer.Name)
end

-- Escuchar comandos de chat
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if message:sub(1, 1) ~= "/" then return end

		local parts = message:split(" ")
		local command = parts[1]:lower():gsub("/", "")
		local args = {unpack(parts, 2)}

		if Commands[command] then
			print("[TEST] Ejecutando comando: " .. command)
			Commands[command](Commands, args, player)
		end
	end)
end)

print("[TEST DONATION] Sistema listo. Usa /testdon @Usuario cantidad para simular donaciones")
