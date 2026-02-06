--[[
	═══════════════════════════════════════════════════════════
	REMOTES SETUP - Inicialización de servicios y remotes
	═══════════════════════════════════════════════════════════
	Setup centralizado de todos los servicios y remotes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

return function()
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 2)
	local mouse = player:GetMouse()
	local camera = workspace.CurrentCamera
	
	-- Remotes folder
	local remoteGlobal = ReplicatedStorage:FindFirstChild("RemotesGlobal") or ReplicatedStorage:WaitForChild("RemotesGlobal", 2)
	local remotesFolder = remoteGlobal:FindFirstChild("UserPanel") or remoteGlobal:WaitForChild("UserPanel", 2)
	
	-- Panda ReplicatedStorage
	local PandaRS = ReplicatedStorage:FindFirstChild("Panda ReplicatedStorage") or ReplicatedStorage:WaitForChild("Panda ReplicatedStorage", 2)
	
	-- Sistema de sincronización
	local RemotesSync = PandaRS and PandaRS:FindFirstChild("Emotes_Sync")
	
	-- Sistema de likes
	local LikesEvents = PandaRS and (PandaRS:FindFirstChild("LikesEvents") or PandaRS:WaitForChild("LikesEvents", 2))
	
	-- Sistema de regalos
	local GiftingRemotes = PandaRS and PandaRS:FindFirstChild("Gamepass Gifting") and PandaRS:FindFirstChild("Gamepass Gifting"):FindFirstChild("Remotes")
	
	-- Sistema de SelectedPlayer
	local SelectedPlayerModule = PandaRS and PandaRS:FindFirstChild("SelectedPlayer")
	
	-- GlobalModalManager
	local GlobalModalManager = nil
	pcall(function()
		local Systems = ReplicatedStorage:FindFirstChild("Systems") or ReplicatedStorage:WaitForChild("Systems", 2)
		GlobalModalManager = require(Systems:FindFirstChild("GlobalModalManager") or Systems:WaitForChild("GlobalModalManager", 2))
	end)
	
	-- NotificationSystem
	local NotificationSystem = nil
	pcall(function()
		local Systems = ReplicatedStorage:FindFirstChild("Systems") or ReplicatedStorage:WaitForChild("Systems", 2)
		local NotifSys = Systems:FindFirstChild("NotificationSystem") or Systems:WaitForChild("NotificationSystem", 2)
		local NotifModule = NotifSys:FindFirstChild("NotificationSystem") or NotifSys:WaitForChild("NotificationSystem", 2)
		NotificationSystem = require(NotifModule)
	end)
	
	-- ColorEffects
	local Highlight = SelectedPlayerModule and SelectedPlayerModule:FindFirstChild("Highlight")
	local ColorEffects = Highlight and require(SelectedPlayerModule:FindFirstChild("COLORS")) or nil
	
	-- Configuration
	local Configuration = pcall(function()
		return require(PandaRS:FindFirstChild("Configuration") or PandaRS:WaitForChild("Configuration", 2))
	end) and require(PandaRS:FindFirstChild("Configuration") or PandaRS:WaitForChild("Configuration", 2)) or {}
	
	return {
		-- Servicios
		Services = {
			Players = Players,
			PlayerGui = playerGui,
			Mouse = mouse,
			Camera = camera,
			ReplicatedStorage = ReplicatedStorage,
			MarketplaceService = MarketplaceService,
			TweenService = TweenService,
			GuiService = GuiService,
			UserInputService = UserInputService,
			RunService = RunService,
			TextChatService = TextChatService,
			Player = player
		},
		
		-- Remotes de UserPanel
		Remotes = {
			GetUserData = remotesFolder:FindFirstChild("GetUserData") or remotesFolder:WaitForChild("GetUserData", 2),
			GetUserDonations = remotesFolder:FindFirstChild("GetUserDonations") or remotesFolder:WaitForChild("GetUserDonations", 2),
			GetGamePasses = remotesFolder:FindFirstChild("GetGamePasses") or remotesFolder:WaitForChild("GetGamePasses", 2),
			DonationNotify = remotesFolder:FindFirstChild("DonationNotify"),
			DonationMessage = remotesFolder:FindFirstChild("DonationMessage"),
			CheckGamePass = remotesFolder:FindFirstChild("CheckGamePass") or remotesFolder:WaitForChild("CheckGamePass", 2)
		},
		
		-- Sistema de Sync
		Sync = {
			SyncRemote = RemotesSync and RemotesSync:FindFirstChild("Sync"),
			GetSyncState = RemotesSync and RemotesSync:FindFirstChild("GetSyncState"),
			SyncUpdate = RemotesSync and RemotesSync:FindFirstChild("SyncUpdate")
		},
		
		-- Sistema de Likes
		Likes = {
			GiveLikeEvent = LikesEvents and (LikesEvents:FindFirstChild("GiveLikeEvent") or LikesEvents:WaitForChild("GiveLikeEvent", 2)),
			GiveSuperLikeEvent = LikesEvents and (LikesEvents:FindFirstChild("GiveSuperLikeEvent") or LikesEvents:WaitForChild("GiveSuperLikeEvent", 2)),
			BroadcastEvent = LikesEvents and (LikesEvents:FindFirstChild("BroadcastEvent") or LikesEvents:WaitForChild("BroadcastEvent", 2))
		},
		
		-- Sistema de Regalos
		Gifting = {
			GiftingRemote = GiftingRemotes and GiftingRemotes:FindFirstChild("Gifting"),
			GiftBroadcastEvent = GiftingRemotes and (GiftingRemotes:FindFirstChild("GiftBroadcastEvent") or GiftingRemotes:WaitForChild("GiftBroadcastEvent", 2))
		},
		
		-- Sistemas
		Systems = {
			GlobalModalManager = GlobalModalManager,
			NotificationSystem = NotificationSystem,
			ColorEffects = ColorEffects,
			Configuration = Configuration
		}
	}
end
