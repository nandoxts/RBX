local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Panda ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

-- Modules
local Configuration = require(ServerScriptService.Configuration)
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)
local ColorEffects = require(ServerScriptService.Effects.ColorEffectsModule)

-- Gamepass ID VIP
local PROFILECOLORS = Configuration.COLORS 

-- DataStore para guardar color seleccionado
local colorDataStore = DataStoreService:GetDataStore("PlayerHighlightColors")

-- Cache en memoria {UserId = "rojo"}
local playerColorCache = {}

--------------------------------------------------------------------
-- Cargar color de DataStore al entrar
--------------------------------------------------------------------
local function loadPlayerColor(player)
	local success, data = pcall(function()
		return colorDataStore:GetAsync(player.UserId)
	end)

	local colorName = "default"
	if success and data then
		colorName = data
	end

	playerColorCache[player.UserId] = colorName
	player:SetAttribute("SelectedColor", colorName)
end

--------------------------------------------------------------------
-- Guardar color en DataStore al salir
--------------------------------------------------------------------
local function savePlayerColor(player)
	local colorName = playerColorCache[player.UserId]
	if colorName then
		pcall(function()
			colorDataStore:SetAsync(player.UserId, colorName)
		end)
	end
end

--------------------------------------------------------------------
-- Comando ;sl <color>
--------------------------------------------------------------------
local function handleChatCommand(player, message)
	-- Solo VIP
	if not GamepassManager.HasGamepass(player, PROFILECOLORS) then return end

	local args = string.split(string.lower(message), " ")
	if args[1] == ";cl" and args[2] then
		local colorName = args[2]

		if ColorEffects.colors[colorName] then
			-- Actualizar cache y atributo
			playerColorCache[player.UserId] = colorName
			player:SetAttribute("SelectedColor", colorName)
			-- El cliente detectará el cambio de atributo y aplicará el highlight
		end
	end
end

--------------------------------------------------------------------
-- Eventos de jugadores
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	loadPlayerColor(player)

	player.Chatted:Connect(function(msg)
		handleChatCommand(player, msg)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerColor(player)
	playerColorCache[player.UserId] = nil
end)
