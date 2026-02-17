local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Cargar configuración
local Systems = ServerScriptService:WaitForChild("Systems")
local Configuration = require(Systems:WaitForChild("Configuration"))
local GamepassManager = require(Systems:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))

local ITEM_CONFIG_ARMYBOOMS = {
	gamepassId = Configuration.ARMYBOOMS
}

local ITEM_CONFIG_PINK = {
	gamepassId = Configuration.LIGHTSTICK
}

local purchaseDebounce = {}
local COOLDOWN_TIME = 2

-- Función para actualizar el estado del prompt
local function updatePromptState(player, prompt, configItems)
	local hasGamepass = GamepassManager.HasGamepass(player, configItems.gamepassId)
	prompt.Enabled = not hasGamepass -- Desactivar si ya lo tiene
end

-- ════════════════════════════════════════════════════════════════
-- PROMPT ARMYBOOMS (BOOMS)
-- ════════════════════════════════════════════════════════════════
-- Buscar BOOMS desde Workspace
local itemBuyArmy = game.Workspace:FindFirstChild("ItemBuyArmy")
if itemBuyArmy then
	local booms = itemBuyArmy:FindFirstChild("BOOMS")
	if booms then
		local targetPart = booms:FindFirstChildWhichIsA("BasePart") or booms
		if targetPart then
			-- Crear ProximityPrompt desde código
			local promptArmybooms = Instance.new("ProximityPrompt")
			promptArmybooms.Parent = targetPart
			promptArmybooms.ActionText = "Comprar"
			promptArmybooms.ObjectText = "BOOMS"
			promptArmybooms.KeyboardKeyCode = Enum.KeyCode.E
			promptArmybooms.HoldDuration = 0.3
			promptArmybooms.MaxActivationDistance = 8
			promptArmybooms.RequiresLineOfSight = false

			promptArmybooms.Triggered:Connect(function(player)
				if purchaseDebounce[player.UserId] then return end
				purchaseDebounce[player.UserId] = true

				local hasGamepass = GamepassManager.HasGamepass(player, ITEM_CONFIG_ARMYBOOMS.gamepassId)
				if hasGamepass then
					promptArmybooms.Enabled = false
					purchaseDebounce[player.UserId] = nil
					return
				end

				MarketplaceService:PromptGamePassPurchase(player, ITEM_CONFIG_ARMYBOOMS.gamepassId)
				task.wait(COOLDOWN_TIME)
				purchaseDebounce[player.UserId] = nil
			end)

			MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
				if wasPurchased and gamepassId == ITEM_CONFIG_ARMYBOOMS.gamepassId then
					task.wait(0.5)
					promptArmybooms.Enabled = false
				end
			end)

			Players.PlayerAdded:Connect(function(player)
				task.wait(0.5)
				updatePromptState(player, promptArmybooms, ITEM_CONFIG_ARMYBOOMS)
			end)
		end
	end
end

-- ════════════════════════════════════════════════════════════════
-- PROMPT PINK
-- ════════════════════════════════════════════════════════════════
local itemBuyPink = game.Workspace:FindFirstChild("ItemBuyPink")
if itemBuyPink then
	local pink = itemBuyPink:FindFirstChild("PINK")
	if pink then
		local targetPartPink = pink:FindFirstChildWhichIsA("BasePart") or pink
		if targetPartPink then
			local promptPink = Instance.new("ProximityPrompt")
			promptPink.Parent = targetPartPink
			promptPink.ActionText = "Comprar"
			promptPink.ObjectText = "PINK"
			promptPink.KeyboardKeyCode = Enum.KeyCode.E
			promptPink.HoldDuration = 0.3
			promptPink.MaxActivationDistance = 8
			promptPink.RequiresLineOfSight = false

			promptPink.Triggered:Connect(function(player)
				if purchaseDebounce[player.UserId] then return end
				purchaseDebounce[player.UserId] = true

				local hasGamepass = GamepassManager.HasGamepass(player, ITEM_CONFIG_PINK.gamepassId)
				if hasGamepass then
					promptPink.Enabled = false
					purchaseDebounce[player.UserId] = nil
					return
				end

				MarketplaceService:PromptGamePassPurchase(player, ITEM_CONFIG_PINK.gamepassId)
				task.wait(COOLDOWN_TIME)
				purchaseDebounce[player.UserId] = nil
			end)

			MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
				if wasPurchased and gamepassId == ITEM_CONFIG_PINK.gamepassId then
					task.wait(0.5)
					promptPink.Enabled = false
				end
			end)

			Players.PlayerAdded:Connect(function(player)
				task.wait(0.5)
				updatePromptState(player, promptPink, ITEM_CONFIG_PINK)
			end)
		end
	end
end
