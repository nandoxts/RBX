-- ModuleScript: GamepassManager
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")

local GamepassManager = {}

-- Función privada para verificar gamepass con manejo de errores
local function checkGamepassOwnership(player, gamepassId)
	-- 1. Verificar compra directa
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	if success and owns then
		return true
	end

	-- 2. Verificar en DataStore (regalado)
	success, owns = pcall(function()
		return GiftedGamepassesData:GetAsync(player.UserId .. "-" .. gamepassId)
	end)

	return success and owns or false
end

-- Función pública para verificar múltiples gamepasses
function GamepassManager.HasGamepass(player, gamepassId)
	if not player or not gamepassId then return false end
	return checkGamepassOwnership(player, gamepassId)
end

-- Función para verificar varios gamepasses a la vez
function GamepassManager.HasAnyGamepass(player, gamepassIds)
	if not player or not gamepassIds then return false end

	for _, gamepassId in ipairs(gamepassIds) do
		if checkGamepassOwnership(player, gamepassId) then
			return true
		end
	end

	return false
end

-- Función para obtener todos los gamepasses que tiene un jugador
function GamepassManager.GetPlayerGamepasses(player, gamepassList)
	local ownedGamepasses = {}

	if not player or not gamepassList then return ownedGamepasses end

	for gamepassId, gamepassName in pairs(gamepassList) do
		if checkGamepassOwnership(player, gamepassId) then
			table.insert(ownedGamepasses, {
				id = gamepassId,
				name = gamepassName
			})
		end
	end

	return ownedGamepasses
end

return GamepassManager