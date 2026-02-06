--[[
	═══════════════════════════════════════════════════════════
	LIKES SYSTEM - Sistema de likes y super likes
	═══════════════════════════════════════════════════════════
	Maneja likes, cooldowns y super likes
]]

local LikesSystem = {
	Cooldowns = {
		Like = {}
	}
}

local Remotes, State, Config, NotificationSystem, player, SUPER_LIKE_PRODUCT_ID

function LikesSystem.init(remotes, state, config)
	Remotes = remotes
	State = state
	Config = config
	NotificationSystem = remotes.Systems.NotificationSystem
	player = remotes.Services.Player
	SUPER_LIKE_PRODUCT_ID = remotes.Systems.Configuration.SUPER_LIKE
end

-- ═══════════════════════════════════════════════════════════════
-- COOLDOWNS
-- ═══════════════════════════════════════════════════════════════

function LikesSystem.checkLocalCooldown(targetUserId)
	local userId = player.UserId
	local cooldownKey = userId .. "_" .. targetUserId

	local lastTime = LikesSystem.Cooldowns.Like[cooldownKey] or 0
	local elapsed = tick() - lastTime

	return elapsed >= Config.LIKE_COOLDOWN, lastTime
end

function LikesSystem.updateLocalCooldown(targetUserId)
	local userId = player.UserId
	local cooldownKey = userId .. "_" .. targetUserId
	LikesSystem.Cooldowns.Like[cooldownKey] = tick()
end

function LikesSystem.showCooldownNotification(remainingTime)
	local minutes = math.ceil(remainingTime / 60)
	if NotificationSystem then
		NotificationSystem:Info("Like", "Espera " .. minutes .. " minuto" .. (minutes > 1 and "s" or "") .. " para dar otro like", 3)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- ACCIONES
-- ═══════════════════════════════════════════════════════════════

function LikesSystem.giveLike(targetPlayer)
	if not targetPlayer or targetPlayer == player then return end
	
	local canLike, lastLikeTime = LikesSystem.checkLocalCooldown(targetPlayer.UserId)
	
	if canLike then
		LikesSystem.updateLocalCooldown(targetPlayer.UserId)
		Remotes.Likes.GiveLikeEvent:FireServer("GiveLike", targetPlayer.UserId)
		
		-- Notificación local inmediata
		if NotificationSystem then
			NotificationSystem:Success("Like", "¡Like enviado a " .. targetPlayer.DisplayName .. "!", 2)
		end
	else
		local remainingTime = Config.LIKE_COOLDOWN - (tick() - lastLikeTime)
		LikesSystem.showCooldownNotification(remainingTime)
	end
end

function LikesSystem.giveSuperLike(targetPlayer)
	if not targetPlayer or targetPlayer == player then return end
	
	player:SetAttribute("SuperLikeTarget", targetPlayer.UserId)
	
	local success = pcall(function()
		Remotes.Likes.GiveSuperLikeEvent:FireServer("SetSuperLikeTarget", targetPlayer.UserId)
	end)
	
	if success then
		pcall(function()
			Remotes.Services.MarketplaceService:PromptProductPurchase(player, SUPER_LIKE_PRODUCT_ID)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- LISTENERS
-- ═══════════════════════════════════════════════════════════════

function LikesSystem.setupLikeListeners(soundsFolder)
	if Remotes.Likes.GiveLikeEvent then
		Remotes.Likes.GiveLikeEvent.OnClientEvent:Connect(function(action, data)
			if action == "LikeSuccess" then
				if State.target then
					LikesSystem.updateLocalCooldown(State.target.UserId)
				end
				
				if soundsFolder and soundsFolder:FindFirstChild("Like") then
					soundsFolder.Like:Play()
				end
			elseif action == "Error" then
				if NotificationSystem then
					NotificationSystem:Error("Like", data or "Error al dar like", 3)
				end
				
				if soundsFolder and soundsFolder:FindFirstChild("Error") then
					soundsFolder.Error:Play()
				end
			end
		end)
	end
	
	if Remotes.Likes.GiveSuperLikeEvent then
		Remotes.Likes.GiveSuperLikeEvent.OnClientEvent:Connect(function(action, data)
			if action == "SuperLikeSuccess" then
				if soundsFolder and soundsFolder:FindFirstChild("Like") then
					soundsFolder.Like:Play()
				end
			end
		end)
	end
end

return LikesSystem
