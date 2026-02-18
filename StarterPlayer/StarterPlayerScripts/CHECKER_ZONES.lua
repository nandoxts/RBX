-- SU FUNCIONA VIP Y VIPPLUS
local config = require(game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal").Configuration)
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("RemotesGlobal")
local CheckGamepassOwnership = ReplicatedStorage:WaitForChild("Gamepass Gifting"):WaitForChild("Remotes"):WaitForChild("Ownership")
local MarketplaceService = game:GetService("MarketplaceService")

local _VIP = config.VIP
local _VIPPLUS = config.VIPPLUS
local player = game.Players.LocalPlayer

-- Variables globales para las carpetas VIP
local FolderzonaVIP = nil
local FolderzonaVIPPLUS = nil
--local FolderChecker = nil

--local changingMapFolder = game:GetService("Workspace"):WaitForChild("Map"):WaitForChild("ChangingMap")

-- Función para buscar y configurar las carpetas VIP iniciales
local function setupInitialVIPFolders()
	-- Buscar en el workspace principal
	local mainZoneVIP = workspace:FindFirstChild("ZoneVIP")
	if mainZoneVIP then
		FolderzonaVIP = mainZoneVIP:FindFirstChild("VIP")
		FolderzonaVIPPLUS = mainZoneVIP:FindFirstChild("VIPPLUS")
		--FolderChecker = mainZoneVIP:FindFirstChild("Checkers")
	end
end

-- Función para bloquear/desbloquear partes en una carpeta
local function setPartsCollision(folder, shouldCollide)
	if not folder then return end

	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = shouldCollide
			-- Opcional: cambiar transparencia para indicar estado
			-- part.Transparency = shouldCollide and 0 or 0.5
		end
	end
end

-- Función para bloquear/desbloquear múltiples carpetas
local function setMultipleFoldersCollision(folders, shouldCollide)
	for _, folder in ipairs(folders) do
		setPartsCollision(folder, shouldCollide)
	end
end

-- Función segura para verificar gamepass con reintentos
local function safeCheckGamepassOwnership(gamepassId)
	for i = 1, 3 do  -- 3 intentos máximos
		local success, ownsGamepass = pcall(function()
			return CheckGamepassOwnership:InvokeServer(gamepassId)
		end)

		if success then
			return ownsGamepass
		else
			--warn(`Intento {i} fallido al verificar gamepass {gamepassId}`)
			task.wait(1)  -- Esperar 1 segundo entre intentos
		end
	end
	--warn("No se pudo verificar el gamepass después de 3 intentos")
	return false
end

-- Función principal para manejar todas las zonas VIP
local function handleVIPZones()
	-- Verificar ambos gamepasses con manejo de errores
	local hasVIP = safeCheckGamepassOwnership(_VIP)
	local hasVIPPlus = safeCheckGamepassOwnership(_VIPPLUS)

	-- Debug opcional
	--print(`VIP Status - VIP: {hasVIP}, VIP+: {hasVIPPlus}`)

	-- Buscar carpetas VIP en modelos Map-*

	-- Manejar zona VIP principal
	setPartsCollision(FolderzonaVIP, not (hasVIP or hasVIPPlus))  -- Colisión = false si tiene VIP

	-- Manejar zona VIP PLUS principal
	setPartsCollision(FolderzonaVIPPLUS, not hasVIPPlus)  -- Colisión = false si tiene VIP+
end


-- Esperar a que el jugador y su interfaz estén listos
player:WaitForChild("PlayerGui")

-- Esperar a que el personaje exista o llegue
if not player.Character then
	player.CharacterAdded:Wait()
end

-- Pequeña espera adicional para asegurar estabilidad
task.wait(2)

-- Configuración inicial
setupInitialVIPFolders()

-- Verificación inicial
handleVIPZones()

-- Conexión para cambios de personaje con pequeño retraso
player.CharacterAdded:Connect(function()
	task.wait(1)  -- Esperar 1 segundo para asegurar estabilidad
	handleVIPZones()
end)

-- Opcional: Escuchar cambios en el workspace por si se agregan zonas VIP principales
workspace.ChildAdded:Connect(function(child)
	if child.Name == "ZoneVIP" then
		task.wait(0.5)
		setupInitialVIPFolders()
		handleVIPZones()
	end
end)