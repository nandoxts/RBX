local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")

-- Servicios de sincronización
local RemotesSync = ReplicatedStorage:WaitForChild("Emotes_Sync")
local SyncRemote = RemotesSync:WaitForChild("Sync")

-- Sistema de jugador seleccionado
local SelectedPlayer = ReplicatedStorage:WaitForChild("SelectedPlayer")
local Ev_DonationMessage = SelectedPlayer.Events.donation_message
local Ev_UpdateStatus = SelectedPlayer.Events.update_status
local Highlight = SelectedPlayer:WaitForChild("Highlight")
local ColorEffects = require(SelectedPlayer.COLORS)

-- `ReplicatedStorage` variable above points to `Panda ReplicatedStorage` folder.
-- Use the actual root ReplicatedStorage to find shared `Systems` folder.
local _GlobalReplicated = game:GetService("ReplicatedStorage")
local NotificationSystem = require(_GlobalReplicated:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- Sistema de regalos
local Gifting = ReplicatedStorage["Gamepass Gifting"].Remotes.Gifting
local Config = require(ReplicatedStorage["Gamepass Gifting"].Modules.Config)
local Configuration = require(ReplicatedStorage.Configuration)

-- Sistema de likes
local LikesEvents = ReplicatedStorage:WaitForChild("LikesEvents")
local GiveLikeEvent = LikesEvents:WaitForChild("GiveLikeEvent")
local GiveSuperLikeEvent = LikesEvents:WaitForChild("GiveSuperLikeEvent")
local BroadcastEvent = LikesEvents:WaitForChild("BroadcastEvent")

-- Referencias al jugador local
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local camera = workspace.CurrentCamera

-- Elementos de la interfaz
local MainFrame = script.Parent.MainFrame

-- Colores cambiantes
local COLOR_GiftUserGamePass = MainFrame.GiftUserGamePass.Container.SelectedColor
local COLOR_UserGamePass = MainFrame.UserGamePass.Container.SelectedColor
local COLOR_UserInformation = MainFrame.UserInformation.Container.SelectedColor
local COLOR_GiftUserGamePass_UserN = MainFrame.GiftUserGamePass.User_Name
local COLOR_UserGamePass_UserN = MainFrame.UserGamePass.User_Name
local COLOR_UserInformation_UserN = MainFrame.UserInformation.User_Name

-- Botones principales
local SYNC_BUTTON = MainFrame.SYNC_BUTTON
local VA_Button = MainFrame.VA_BUTTON
local GP_Button = MainFrame.Gamepass_BUTTON
local DNT_Button = MainFrame.Donate_BUTTON

local debounceSync = false

-- Información del usuario
local MainFrameInformation = MainFrame.UserInformation
local Description = MainFrameInformation.Description
local UserIMG = MainFrameInformation.User_IMG
local UserName = MainFrameInformation.User_Name

-- Elementos de likes
local LikeButton = MainFrameInformation:FindFirstChild("LikeButton")
local SuperLikeButton = MainFrameInformation:FindFirstChild("SuperLikeButton")
local NumTotalLikes = MainFrameInformation:FindFirstChild("NumTotalLikes")

local SUPER_LIKE_PRODUCT_ID = Configuration.SUPER_LIKE
local LIKE_COOLDOWN = Configuration.LIKE_COOLDOWN

local isGuiOpen = false

-- Paneles de gamepasses
local UserGamePass = MainFrame:FindFirstChild("UserGamePass")
local GiftUserGamePass = MainFrame:FindFirstChild("GiftUserGamePass")

-- Plantilla para gamepasses
local TemplateGamePass = script.Template
local Lock = TemplateGamePass.Lock
local Icon = TemplateGamePass.Icon
local Price = TemplateGamePass.Price

-- Variables de estado
local currentTarget = LocalPlayer
local syncedPlayer = nil
local MAX_ACTIVATION_DISTANCE = 80
local isDonateMenuOpen = false
local isGiftMenuOpen = false
local isSynced = false

-- Variables para el press prolongado
local activado_press = false
local isPressing = false
local pressStartTime = 0
local PRESS_DURATION = 1

-- ============================================
-- 💾 SISTEMA DE LIKES OPTIMIZADO
-- ============================================

local LikesSystem = {
	Cooldowns = {
		Like = {}
	},
	IsSending = false
}

-- Actualizar visualización de likes
local function updateLikesDisplay()
	if not currentTarget then return end

	if NumTotalLikes then
		NumTotalLikes.Text = "Total Likes: " .. tostring(currentTarget:GetAttribute("TotalLikes") or 0)
	end

	if LikeButton then
		LikeButton.Visible = (currentTarget ~= LocalPlayer)
	end

	if SuperLikeButton then
		SuperLikeButton.Visible = (currentTarget ~= LocalPlayer)
	end
end

-- Verificar cooldown local (UI feedback)
local function checkLocalCooldown(targetPlayer)
	local userId = LocalPlayer.UserId
	local targetId = targetPlayer.UserId
	local cooldownKey = userId .. "_" .. targetId

	local lastTime = LikesSystem.Cooldowns.Like[cooldownKey] or 0
	local elapsed = tick() - lastTime

	return elapsed >= LIKE_COOLDOWN, lastTime
end

-- Actualizar cooldown local
local function updateLocalCooldown(targetPlayer)
	local userId = LocalPlayer.UserId
	local targetId = targetPlayer.UserId
	local cooldownKey = userId .. "_" .. targetId

	LikesSystem.Cooldowns.Like[cooldownKey] = tick()
end

-- Mostrar notificación de cooldown
local function showCooldownNotification(remainingTime)
	local minutes = math.ceil(remainingTime / 60)
	StarterGui:SetCore("SendNotification", {
		Title = "Enfriamiento",
		Text = string.format("Espera %d minuto%s", minutes, minutes > 1 and "s" or ""),
		Duration = 3
	})
end

-- ============================================
-- 🎨 SISTEMA DE COLORES Y HIGHLIGHT
-- ============================================

local function updateHighlightColor(player)
	local colorName = player:GetAttribute("SelectedColor") or "default"
	local color = ColorEffects.colors[colorName] or ColorEffects.defaultSelectedColor

	Highlight.FillColor = color
	Highlight.OutlineColor = color
	COLOR_GiftUserGamePass.ImageColor3 = color
	COLOR_UserGamePass.ImageColor3 = color
	COLOR_UserInformation.ImageColor3 = color
	COLOR_GiftUserGamePass_UserN.TextColor3 = color
	COLOR_UserGamePass_UserN.TextColor3 = color
	COLOR_UserInformation_UserN.TextColor3 = color
end

local function attachHighlight(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	updateHighlightColor(targetPlayer)
	Highlight.Adornee = targetPlayer.Character
	Highlight.Enabled = true
end

local function detachHighlight()
	if Highlight then
		Highlight.Adornee = nil
		Highlight.Enabled = false
	end
end

-- ============================================
-- 🎮 GAMEPASS SYSTEM
-- ============================================

local gamepassCache = {}

local function playerHasGamepass(player, gamepassId)
	local cacheKey = player.UserId .. "_" .. gamepassId
	if gamepassCache[cacheKey] ~= nil then
		return gamepassCache[cacheKey]
	end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	gamepassCache[cacheKey] = success and hasPass
	return success and hasPass
end

local function clearGamepassCache()
	gamepassCache = {}
end

local function clearGamepassList(listFrame)
	if not listFrame then return end

	for _, child in pairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and (child.Name:find("Gamepass_") or child.Name:find("GiftGamepass_")) then
			child:Destroy()
		end
	end
end

local function clearAllGamepassLists()
	if UserGamePass then clearGamepassList(UserGamePass.ListGamePass) end
	if GiftUserGamePass then clearGamepassList(GiftUserGamePass.ListGamePass) end
end

-- ============================================
-- 📊 INFORMACIÓN DEL JUGADOR
-- ============================================

local function updatePlayerInfo(targetPlayer)
	UserName.Text = "<b>" .. targetPlayer.DisplayName .. "</b><br /><font size=\"4\"><i>@" .. targetPlayer.Name .. "</i></font>"
	UserIMG.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=420&h=420"

	local status = targetPlayer:GetAttribute("status") or "No se proporcionó ningún estado"
	Description.Text = '"' .. status .. '"'

	if targetPlayer == LocalPlayer then
		Description.TextEditable = true
		SYNC_BUTTON.Visible = false
		DNT_Button.Visible = false
		GP_Button.Visible = false
		LikeButton.Visible = false
		SuperLikeButton.Visible = false
	else
		Description.TextEditable = false
		SYNC_BUTTON.Visible = true
		DNT_Button.Visible = true
		GP_Button.Visible = true
		LikeButton.Visible = false
		SuperLikeButton.Visible = true
	end

	updateLikesDisplay()
end

-- ============================================
-- 🎬 ANIMACIONES DE GUI
-- ============================================

local function toggleGui(visible, targetPlayer)
	if targetPlayer then
		currentTarget = targetPlayer
		updatePlayerInfo(targetPlayer)

		if targetPlayer.Character then
			attachHighlight(targetPlayer)
		end

		if UserGamePass then UserGamePass.Visible = false end
		if GiftUserGamePass then GiftUserGamePass.Visible = false end
		isDonateMenuOpen = false
		isGiftMenuOpen = false
	end

	if visible then
		isGuiOpen = true
		MainFrame.Visible = true
		MainFrame.Position = UDim2.new(0, 0, 1, 0)

		TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
	else
		isGuiOpen = false
		detachHighlight()

		local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 0, 1, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if MainFrame.Position == UDim2.new(0, 0, 1, 0) then
				MainFrame.Visible = false
			end
		end)
	end

	clearGamepassCache()
end

local function animatePanel(panel, open)
	if not panel then return end

	if open then
		panel.Visible = true
		panel.Position = UDim2.new(1, 0, 0, 0)
		TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
	else
		local tween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			panel.Visible = false
		end)
	end
end

-- ============================================
-- ❤️ BOTONES DE LIKES
-- ============================================

if LikeButton then
	LikeButton.MouseButton1Click:Connect(function()
		if currentTarget == LocalPlayer or not currentTarget then return end
		if LikesSystem.IsSending then return end

		local canLike, lastLikeTime = checkLocalCooldown(currentTarget)

		if canLike then
			LikesSystem.IsSending = true

			GiveLikeEvent:FireServer("GiveLike", currentTarget.UserId)

			task.delay(1, function()
				LikesSystem.IsSending = false
			end)
		else
			local remainingTime = LIKE_COOLDOWN - (tick() - lastLikeTime)
			showCooldownNotification(remainingTime)
		end
	end)
end

if SuperLikeButton then
	SuperLikeButton.MouseButton1Click:Connect(function()
		if currentTarget and currentTarget ~= LocalPlayer then
			LocalPlayer:SetAttribute("SuperLikeTarget", currentTarget.UserId)

			local success = pcall(function()
				GiveSuperLikeEvent:FireServer("SetSuperLikeTarget", currentTarget.UserId)
			end)

			if success then
				pcall(function()
					MarketplaceService:PromptProductPurchase(LocalPlayer, SUPER_LIKE_PRODUCT_ID)
				end)
			end
		end
	end)
end

-- ============================================
-- 📡 EVENTOS DEL SERVIDOR
-- ============================================

if GiveLikeEvent then
	GiveLikeEvent.OnClientEvent:Connect(function(action, data)
		if action == "LikeSuccess" then
			updateLocalCooldown(currentTarget)

			if script:FindFirstChild("Sounds") and script.Sounds:FindFirstChild("Like") then
				script.Sounds.Like:Play()
			end

			updateLikesDisplay()

		elseif action == "Error" then
			StarterGui:SetCore("SendNotification", {
				Title = "Error",
				Text = data,
				Duration = 3
			})

			if script:FindFirstChild("Sounds") and script.Sounds:FindFirstChild("Error") then
				script.Sounds.Error:Play()
			end
		end
	end)
end

if GiveSuperLikeEvent then
	GiveSuperLikeEvent.OnClientEvent:Connect(function(action, data)
		if action == "SuperLikeSuccess" then
			if script:FindFirstChild("Sounds") and script.Sounds:FindFirstChild("Like") then
				script.Sounds.Like:Play()
			end

			updateLikesDisplay()
		end
	end)
end

BroadcastEvent.OnClientEvent:Connect(function(action, data)
	if action == "LikeNotification" then
		local message
		if data.IsSuperLike then
			message = '<font color="#F7004D"><b>' .. data.Sender .. ' dio un ❤️‍🔥 Super Like (+' .. data.Amount .. ') a ' .. data.Target .. '</b></font>'
		else
			message = '<font color="#FFFF7F"><b>' .. data.Sender .. ' dio un 👍 a ' .. data.Target .. '</b></font>'
		end

		local TextChannels = TextChatService:WaitForChild("TextChannels")
		local RBXSystem = TextChannels:WaitForChild("RBXSystem")
		RBXSystem:DisplaySystemMessage(message)
	end
end)

-- ============================================
-- 🎯 SISTEMA DE SELECCIÓN DE JUGADORES
-- ============================================

if LocalPlayer:GetAttribute("SelectedUser") == nil then
	LocalPlayer:SetAttribute("SelectedUser", true)
end

local function hasToolEquipped()
	local char = LocalPlayer.Character
	if char and char:FindFirstChildOfClass("Tool") then
		return true
	end
	return false
end

local function canSelectPlayer()
	return LocalPlayer:GetAttribute("SelectedUser") and not hasToolEquipped()
end

LocalPlayer:GetAttributeChangedSignal("SelectedUser"):Connect(function()
	if not LocalPlayer:GetAttribute("SelectedUser") then
		toggleGui(false)
	end
end)

-- ============================================
-- 🖱️ CURSOR Y DETECCIÓN
-- ============================================

local DEFAULT_CURSOR = "rbxassetid://13335399499"
local SELECTED_CURSOR = "rbxassetid://84923889690331"

RunService.RenderStepped:Connect(function()
	if not canSelectPlayer() then
		mouse.Icon = DEFAULT_CURSOR
		return
	end

	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * MAX_ACTIVATION_DISTANCE)

	if raycast and raycast.Instance then
		local hoveredPlayer = Players:GetPlayerFromCharacter(raycast.Instance.Parent) or 
			Players:GetPlayerFromCharacter(raycast.Instance.Parent.Parent)

		if hoveredPlayer 
			and hoveredPlayer ~= LocalPlayer 
			and hoveredPlayer:GetAttribute("SelectedUser") ~= false then
			mouse.Icon = SELECTED_CURSOR
			return
		end
	end

	mouse.Icon = DEFAULT_CURSOR
end)

-- ============================================
-- 🎮 GAMEPASSES
-- ============================================

local function loadDonationGamepasses()
	if not UserGamePass then return end
	clearGamepassList(UserGamePass.ListGamePass)

	local gamepassesOnSale = {}
	local success, result = pcall(function()
		return HttpService:JSONDecode(currentTarget:GetAttribute("gamepassesOnSale") or "[]")
	end)

	if success then
		gamepassesOnSale = result
	end

	for _, assetId in ipairs(gamepassesOnSale) do
		local success, response = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId, Enum.InfoType.GamePass)

		if success and response.PriceInRobux then
			local gamepassFrame = TemplateGamePass:Clone()
			gamepassFrame.Name = "Gamepass_" .. assetId
			gamepassFrame.Icon.Image = "rbxthumb://type=GamePass&id=" .. assetId .. "&w=150&h=150"
			gamepassFrame.Price.Text = utf8.char(0xE002) .. tostring(response.PriceInRobux)
			gamepassFrame.Lock.Visible = playerHasGamepass(LocalPlayer, assetId)

			gamepassFrame.Icon.MouseButton1Click:Connect(function()
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, assetId)
			end)

			gamepassFrame.Parent = UserGamePass.ListGamePass
			gamepassFrame.Visible = true
		end
	end

	if UserGamePass.User_IMG then
		UserGamePass.User_IMG.Image = "rbxthumb://type=AvatarHeadShot&id=" .. currentTarget.UserId .. "&w=150&h=150"
	end

	if UserGamePass.User_Name then
		UserGamePass.User_Name.Text = currentTarget.DisplayName
	end
end

local function loadGiftGamepasses()
	if not GiftUserGamePass then return end
	clearGamepassList(GiftUserGamePass.ListGamePass)

	for i, gamepass in pairs(Config.Gamepasses) do
		local gamepassId = gamepass[1]
		local productId = gamepass[2]

		local success, passInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, gamepassId, Enum.InfoType.GamePass)

		if success then
			local gamepassFrame = TemplateGamePass:Clone()
			gamepassFrame.Name = "GiftGamepass_" .. gamepassId
			gamepassFrame.Icon.Image = "rbxassetid://" .. passInfo.IconImageAssetId
			gamepassFrame.Price.Text = utf8.char(0xE002) .. tostring(passInfo.PriceInRobux)

			gamepassFrame.Icon.MouseButton1Click:Connect(function()
				pcall(function()
					Gifting:FireServer(
						{gamepassId, productId},
						currentTarget.UserId,
						LocalPlayer.Name, 
						LocalPlayer.UserId
					)
				end)
			end)

			gamepassFrame.Parent = GiftUserGamePass.ListGamePass
			gamepassFrame.Visible = true
		end
	end

	if GiftUserGamePass.User_IMG then
		GiftUserGamePass.User_IMG.Image = "rbxthumb://type=AvatarHeadShot&id=" .. currentTarget.UserId .. "&w=150&h=150"
	end

	if GiftUserGamePass.User_Name then
		GiftUserGamePass.User_Name.Text = currentTarget.DisplayName
	end
end

-- ============================================
-- Sistema de SYNC
-- ============================================

SYNC_BUTTON.MouseButton1Click:Connect(function()
	if debounceSync or not currentTarget then return end
	debounceSync = true

	if LocalPlayer.Character:FindFirstChild("SyncOnOff") 
		and LocalPlayer.Character.SyncOnOff.Value then


		SyncRemote:FireServer("unsync")

		pcall(function()
			NotificationSystem:Info("Sync", "Has dejado de estar sincronizado", 4)
		end)


		toggleGui(false)
	else

		SyncRemote:FireServer("sync", currentTarget)

		pcall(function()
			NotificationSystem:Success("Sync", "Ahora estás sincronizado con: " .. tostring(currentTarget.Name), 4)
		end)
	end

	task.wait(0.5)
	debounceSync = false
end)

-- ============================================
-- 🔘 EVENTOS DE BOTONES
-- ============================================

DNT_Button.MouseButton1Click:Connect(function()
	if currentTarget == LocalPlayer then return end
	isDonateMenuOpen = not isDonateMenuOpen
	animatePanel(UserGamePass, isDonateMenuOpen)
	if isDonateMenuOpen then
		loadDonationGamepasses()
	end
end)

GP_Button.MouseButton1Click:Connect(function()
	if currentTarget == LocalPlayer then return end
	isGiftMenuOpen = not isGiftMenuOpen
	animatePanel(GiftUserGamePass, isGiftMenuOpen)
	if isGiftMenuOpen then
		loadGiftGamepasses()
	end
end)

VA_Button.MouseButton1Click:Connect(function()
	GuiService:InspectPlayerFromUserId(currentTarget.UserId)
end)

-- ============================================
-- 📝 INPUT Y SELECCIÓN
-- ============================================

local function trySelectAtPosition(position)
	if isGuiOpen then
		local guiObjects = MainFrame:GetDescendants()
		for _, obj in ipairs(guiObjects) do
			if obj:IsA("GuiObject") then
				local absPos = obj.AbsolutePosition
				local absSize = obj.AbsoluteSize
				if position.X >= absPos.X
					and position.X <= absPos.X + absSize.X
					and position.Y >= absPos.Y
					and position.Y <= absPos.Y + absSize.Y then
					return
				end
			end
		end
		toggleGui(false)
		return
	end

	if not canSelectPlayer() then return end

	local unitRay = camera:ScreenPointToRay(position.X, position.Y)
	local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * MAX_ACTIVATION_DISTANCE)

	if raycast and raycast.Instance then
		local clickedPlayer = Players:GetPlayerFromCharacter(raycast.Instance.Parent) or 
			Players:GetPlayerFromCharacter(raycast.Instance.Parent.Parent)

		if clickedPlayer then
			if clickedPlayer == LocalPlayer then
				local character = clickedPlayer.Character
				if character then
					local Head = character:FindFirstChild("Head")
					if Head and Head.LocalTransparencyModifier == 1 then
						return
					end 
				end
			end

			if clickedPlayer == currentTarget and MainFrame.Visible then
				toggleGui(false)
				return
			end

			toggleGui(true, clickedPlayer)
			return
		end
	end

	toggleGui(false)
end

local function startPress(position)
	isPressing = true
	pressStartTime = tick()

	if activado_press then
		task.spawn(function()
			while isPressing do
				if tick() - pressStartTime >= PRESS_DURATION then
					trySelectAtPosition(position)
					break
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end
end

local function endPress(position)
	if not activado_press then
		trySelectAtPosition(position)
	end
	isPressing = false
end

UserInputService.TouchStarted:Connect(function(input, gameProcessed)
	if not gameProcessed and canSelectPlayer() then
		startPress(input.Position)
	end
end)

UserInputService.TouchEnded:Connect(function(input)
	endPress(input.Position)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 and canSelectPlayer() then
		startPress(Vector2.new(mouse.X, mouse.Y))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		endPress(Vector2.new(mouse.X, mouse.Y))
	end
end)

-- ============================================
-- 💬 OTROS EVENTOS
-- ============================================

Description.FocusLost:Connect(function()
	if currentTarget == LocalPlayer then
		local sanitizedText = string.sub(Description.Text, 1, 30)
		Ev_UpdateStatus:FireServer(sanitizedText)
	end
end)

Ev_DonationMessage.OnClientEvent:Connect(function(donatingPlayer, amount, donatedPlayer)
	local TextChannels = TextChatService:WaitForChild("TextChannels")
	local RBXSystem = TextChannels:WaitForChild("RBXSystem")

	-- Verificar si el receptor de la donación debe ser reemplazado
	local displayName = donatedPlayer
	if donatedPlayer == "Panda Mania' [Games]" or donatedPlayer == "Panda15Fps" or donatedPlayer == "Panda Mania' [UGC]" then
		displayName = "Zona Peruana"
	end

	-- Mostrar mensaje de donación en el chat del sistema
	RBXSystem:DisplaySystemMessage(
		'<font color="#8762FF"><b>' .. donatingPlayer .. " donó " .. utf8.char(0xE002) .. tostring(amount) .. " a " .. displayName .. "</b></font>"
	)
end)

Gifting.OnClientEvent:Connect(function(action, message)
	if action == "Purchase" then
		script.Sounds.Confirm:Play()
	elseif action == "Error" then
		script.Sounds.Error:Play()
		StarterGui:SetCore("SendNotification", {
			Title = "ERROR",
			Text = message,
			Duration = 5
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player == currentTarget then
		toggleGui(false)
		currentTarget = LocalPlayer
		syncedPlayer = nil
	end
end)

-- ⚡ Listener para cambios en TotalLikes
LocalPlayer:GetAttributeChangedSignal("TotalLikes"):Connect(updateLikesDisplay)

-- ============================================
-- 🚀 INICIALIZACIÓN
-- ============================================

if UserGamePass then UserGamePass.Visible = false end
if GiftUserGamePass then GiftUserGamePass.Visible = false end
toggleGui(false)
updatePlayerInfo(LocalPlayer)