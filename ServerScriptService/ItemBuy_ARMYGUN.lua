local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Cargar configuración
local PandaSSS = ServerScriptService:WaitForChild("Panda ServerScriptService")
local Configuration = require(PandaSSS:WaitForChild("Configuration"))
local GamepassManager = require(PandaSSS:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))

local ITEM_CONFIG = {
	itemFolder = "ARMYBOOMS",
	gamepassId = Configuration.ARMYBOOMS
}

local purchaseDebounce = {}
local COOLDOWN_TIME = 2

-- Buscar BOOMS desde Workspace
local itemBuy = game.Workspace:FindFirstChild("ItemBuy")
if not itemBuy then 
	return 
end

local booms = itemBuy:FindFirstChild("BOOMS")
if not booms then 
	return 
end

-- Buscar la parte principal o BasePart en BOOMS
local targetPart = booms:FindFirstChildWhichIsA("BasePart") or booms
if not targetPart then
	return
end

-- Crear ProximityPrompt desde código
local prompt = Instance.new("ProximityPrompt")
prompt.Parent = targetPart
prompt.ActionText = "Comprar"
prompt.ObjectText = "BOOMS"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0.3
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false

-- Función para actualizar el estado del prompt
local function updatePromptState(player)
	local hasGamepass = GamepassManager.HasGamepass(player, ITEM_CONFIG.gamepassId)
	prompt.Enabled = not hasGamepass -- Desactivar si ya lo tiene
end

prompt.Triggered:Connect(function(player)
	-- Check de cooldown personal
	if purchaseDebounce[player.UserId] then 
		return 
	end

	purchaseDebounce[player.UserId] = true

	-- Verificar si ya tiene el gamepass (comprado o regalado)
	local hasGamepass = GamepassManager.HasGamepass(player, ITEM_CONFIG.gamepassId)

	if hasGamepass then
		-- Ya lo tiene, desactivar el prompt
		prompt.Enabled = false
		purchaseDebounce[player.UserId] = nil
		return
	end

	-- No lo tiene, mostrar prompt de compra
	MarketplaceService:PromptGamePassPurchase(player, ITEM_CONFIG.gamepassId)

	-- Limpiar cooldown después del tiempo especificado
	task.wait(COOLDOWN_TIME)
	purchaseDebounce[player.UserId] = nil
end)

-- Monitorear cuando los jugadores compran el gamepass
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased and gamepassId == ITEM_CONFIG.gamepassId then
		task.wait(0.5) -- Esperar a que se sincronice
		prompt.Enabled = false -- Desactivar el prompt después de comprar
	end
end)

-- Monitorear cuando nuevos jugadores entran
Players.PlayerAdded:Connect(function(player)
	task.wait(0.5) -- Esperar a que el jugador se carge completamente
	updatePromptState(player)
end)
