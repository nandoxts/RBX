--[[
	═══════════════════════════════════════════════════════════
	CLAN VIEWS - Vistas del clan (Main, Members, Pending)
	═══════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))
local MembersList = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("MembersList"))
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))

local ClanConstants = require(script.Parent.ClanConstants)
local ClanHelpers = require(script.Parent.ClanHelpers)
local ClanActions = require(script.Parent.ClanActions)

local Memory = ClanConstants.Memory
local player = Players.LocalPlayer

local ClanViews = {}

-- Navegación entre vistas
ClanViews.Navigation = {
	tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

function ClanViews.Navigation:navigateTo(viewName, State)
	if State.currentView == viewName then return end
	if not State.views[viewName] then return end

	local fromView = State.views[State.currentView]
	local toView = State.views[viewName]
	local direction = viewName == "main" and "back" or "forward"

	local outPos = direction == "forward" and UDim2.new(-1, 0, 0, 0) or UDim2.new(1, 0, 0, 0)
	local inPos = direction == "forward" and UDim2.new(1, 0, 0, 0) or UDim2.new(-1, 0, 0, 0)

	if fromView then 
		TweenService:Create(fromView, self.tweenInfo, {Position = outPos}):Play() 
	end

	if toView then
		toView.Position = inPos
		toView.Visible = true
		TweenService:Create(toView, self.tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
	end

	local oldView = State.currentView
	State.currentView = viewName

	task.delay(0.3, function()
		if fromView and fromView.Parent and State.currentView ~= oldView then
			fromView.Visible = false
		end
	end)
end

-- Vista principal
function ClanViews.createMainView(parent, clanData, playerRole, screenGui, loadPlayerClan, State)
	local mainView = UI.frame({name = "MainView", size = UDim2.new(1, 0, 1, 0), bgT = 1, z = 103, parent = parent, clips = true})

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size, scrollFrame.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
	scrollFrame.ScrollBarThickness, scrollFrame.ScrollBarImageColor3 = 3, THEME.accent
	scrollFrame.CanvasSize, scrollFrame.ZIndex = UDim2.new(0, 0, 0, 0), 103
	scrollFrame.Parent = mainView

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding, contentLayout.SortOrder = UDim.new(0, 12), Enum.SortOrder.LayoutOrder
	contentLayout.Parent = scrollFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop, contentPadding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	contentPadding.PaddingLeft, contentPadding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
	contentPadding.Parent = scrollFrame

	local layoutOrder = 0
	local function nextOrder() layoutOrder = layoutOrder + 1 return layoutOrder end

	-- INFO CARD
	local infoCard = UI.frame({size = UDim2.new(1, -8, 0, 160), bg = THEME.card, z = 104, parent = scrollFrame, corner = 12, stroke = true, strokeA = 0.6, clips = true})
	infoCard.LayoutOrder = nextOrder()

	local bannerImage = Instance.new("ImageLabel")
	bannerImage.Size, bannerImage.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
	bannerImage.Image = clanData.logo or ""
	bannerImage.ScaleType, bannerImage.ImageTransparency, bannerImage.ZIndex = Enum.ScaleType.Crop, THEME.mediumAlpha, 104
	bannerImage.Parent = infoCard
	UI.rounded(bannerImage, 12)

	local bannerGradient = Instance.new("UIGradient")
	bannerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.bg), ColorSequenceKeypoint.new(1, THEME.card)}
	bannerGradient.Rotation = 90
	bannerGradient.Parent = bannerImage

	local logoFrame = UI.frame({size = UDim2.new(0, 74, 0, 74), pos = UDim2.new(0, 16, 0, 24), bg = THEME.surface, z = 106, parent = infoCard, corner = 37, stroke = true, strokeA = 0.3})

	if clanData.logo and clanData.logo ~= "" and clanData.logo ~= "rbxassetid://0" then
		local logoImg = Instance.new("ImageLabel")
		logoImg.Size, logoImg.Position = UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4)
		logoImg.BackgroundTransparency, logoImg.Image = 1, clanData.logo
		logoImg.ScaleType, logoImg.ZIndex = Enum.ScaleType.Fit, 107
		logoImg.Parent = logoFrame
		UI.rounded(logoImg, 33)
	else
		UI.label({size = UDim2.new(1, 0, 1, 0), text = clanData.emoji or "⚔️", textSize = 36, alignX = Enum.TextXAlignment.Center, z = 107, parent = logoFrame})
	end

	local clanColor = clanData.color and Color3.fromRGB(clanData.color[1] or 255, clanData.color[2] or 255, clanData.color[3] or 255) or THEME.accent
	local membersCount = 0
	if clanData.members then for _ in pairs(clanData.members) do membersCount = membersCount + 1 end end

	UI.label({size = UDim2.new(1, -110, 0, 26), pos = UDim2.new(0, 100, 0, 30), text = (clanData.emoji or "") .. " " .. (clanData.name or "Clan"), color = clanColor, textSize = 18, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})
	UI.label({size = UDim2.new(0, 80, 0, 20), pos = UDim2.new(0, 100, 0, 56), text = "[" .. (clanData.tag or "TAG") .. "]", color = THEME.accent, textSize = 14, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})

	local roleData = ClanSystemConfig.ROLES.Visual[playerRole] or ClanSystemConfig.ROLES.Visual["miembro"]
	UI.label({size = UDim2.new(0, 100, 0, 20), pos = UDim2.new(1, -116, 0, 56), text = roleData.display, color = roleData.color, textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Right, z = 106, parent = infoCard})
	UI.label({size = UDim2.new(1, -32, 0, 36), pos = UDim2.new(0, 16, 0, 108), text = clanData.description or "Sin descripción", color = THEME.muted, textSize = 13, wrap = true, alignX = Enum.TextXAlignment.Left, z = 106, parent = infoCard})

	-- MIEMBROS CARD
	local membersCard, membersBtn, _, _, membersAvatarPreview = ClanHelpers.createNavCard({size = UDim2.new(1, -8, 0, 60), parent = scrollFrame, icon = "👥", title = "MIEMBROS", subtitle = membersCount .. " miembros en el clan", showAvatarPreview = true})
	membersCard.LayoutOrder = nextOrder()

	if membersAvatarPreview and clanData.members then
		local avatarLayout = Instance.new("UIListLayout")
		avatarLayout.FillDirection, avatarLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, -8)
		avatarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		avatarLayout.Parent = membersAvatarPreview

		local count = 0
		for odI, _ in pairs(clanData.members) do
			if count >= 3 then break end
			local odINum = tonumber(odI)
			if odINum and odINum > 0 then
				local miniAvatar = UI.frame({size = UDim2.new(0, 26, 0, 26), bg = THEME.surface, z = 106, parent = membersAvatarPreview, corner = 13})
				local avatarImg = Instance.new("ImageLabel")
				avatarImg.Size, avatarImg.Position = UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2)
				avatarImg.BackgroundTransparency = 1
				avatarImg.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", odINum)
				avatarImg.ZIndex = 107
				avatarImg.Parent = miniAvatar
				UI.rounded(avatarImg, 11)
				count = count + 1
			end
		end
	end

	Memory:track(membersBtn.MouseButton1Click:Connect(function() ClanViews.Navigation:navigateTo("members", State) end))

	-- SOLICITUDES CARD
	local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")

	if canManageRequests then
		local pendingCard, pendingBtn, pendingSubtitle, pendingDot = ClanHelpers.createNavCard({size = UDim2.new(1, -8, 0, 60), parent = scrollFrame, icon = "📩", title = "SOLICITUDES", subtitle = "Cargando...", showNotification = true})
		pendingCard.LayoutOrder = nextOrder()

		Memory:track(pendingBtn.MouseButton1Click:Connect(function() ClanViews.Navigation:navigateTo("pending", State) end))

		task.spawn(function()
			local requests = ClanClient:GetJoinRequests(clanData.clanId) or {}
			local requestCount = #requests
			if pendingSubtitle and pendingSubtitle.Parent then 
				pendingSubtitle.Text = requestCount > 0 and (requestCount .. " solicitudes pendientes") or "No hay solicitudes" 
			end
			if pendingDot and pendingDot.Parent then 
				pendingDot.Visible = requestCount > 0 
			end
		end)
	end

	-- BOTONES DE EDICIÓN
	local permissions = ClanSystemConfig.ROLES.Permissions[playerRole] or {}
	local canEditName, canEditTag = permissions.cambiar_nombre or false, permissions.cambiar_tag or (playerRole == "owner")
	local canChangeColor = permissions.cambiar_color or false
	local canChangeEmoji = permissions.cambiar_emoji or false

	if canEditName or canEditTag then
		local editRowContainer = UI.frame({size = UDim2.new(1, -8, 0, 42), bgT = 1, z = 104, parent = scrollFrame})
		editRowContainer.LayoutOrder = nextOrder()

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection, rowLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 8)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = editRowContainer

		local buttonCount = (canEditName and 1 or 0) + (canEditTag and 1 or 0)
		local buttonWidth = buttonCount == 2 and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 1, 0)

		if canEditName then
			local btnEditName = UI.button({size = buttonWidth, bg = THEME.card, text = "EDITAR NOMBRE", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 105, parent = editRowContainer, corner = 10})
			btnEditName.LayoutOrder = 1
			UI.hover(btnEditName, THEME.card, THEME.elevated)
			Memory:track(btnEditName.MouseButton1Click:Connect(function() ClanActions:editName(screenGui, clanData, loadPlayerClan) end))
		end

		if canEditTag then
			local btnEditTag = UI.button({size = buttonWidth, bg = THEME.card, text = "EDITAR TAG", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 105, parent = editRowContainer, corner = 10})
			btnEditTag.LayoutOrder = 2
			UI.hover(btnEditTag, THEME.card, THEME.elevated)
			Memory:track(btnEditTag.MouseButton1Click:Connect(function() ClanActions:editTag(screenGui, clanData, loadPlayerClan) end))
		end
	end

	if canChangeColor then
		local btnEditColor = UI.button({size = UDim2.new(1, -8, 0, 42), bg = THEME.card, text = "EDITAR COLOR", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 104, parent = scrollFrame, corner = 10})
		btnEditColor.LayoutOrder = nextOrder()
		UI.hover(btnEditColor, THEME.card, THEME.elevated)
		Memory:track(btnEditColor.MouseButton1Click:Connect(function() ClanActions:editColor(screenGui, loadPlayerClan) end))
	end

	if canChangeEmoji then
		local btnEditEmoji = UI.button({size = UDim2.new(1, -8, 0, 42), bg = THEME.card, text = "EDITAR EMOJI", color = THEME.text, textSize = 12, font = Enum.Font.GothamBold, z = 104, parent = scrollFrame, corner = 10})
		btnEditEmoji.LayoutOrder = nextOrder()
		UI.hover(btnEditEmoji, THEME.card, THEME.elevated)
		Memory:track(btnEditEmoji.MouseButton1Click:Connect(function() ClanActions:editEmoji(screenGui, loadPlayerClan) end))
	end

	-- BOTÓN SALIR/DISOLVER
	local actionBtnText = playerRole == "owner" and "DISOLVER CLAN" or "SALIR DEL CLAN"
	local actionBtn = UI.button({size = UDim2.new(1, -8, 0, 44), bg = THEME.warn, text = actionBtnText, color = THEME.text, textSize = 13, font = Enum.Font.GothamBold, z = 104, parent = scrollFrame, corner = 8})
	actionBtn.LayoutOrder = nextOrder()
	UI.hover(actionBtn, THEME.warn, THEME.btnDanger)

	Memory:track(actionBtn.MouseButton1Click:Connect(function()
		if playerRole == "owner" then
			ClanActions:dissolve(screenGui, clanData.name, loadPlayerClan)
		else
			ClanActions:leave(screenGui, loadPlayerClan)
		end
	end))

	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
	end)

	return mainView
end

-- Vista de miembros
function ClanViews.createMembersView(parent, clanData, playerRole, screenGui, reloadAndKeepView, State)
	local membersView = UI.frame({name = "MembersView", size = UDim2.new(1, 0, 1, 0), pos = UDim2.new(1, 0, 0, 0), bgT = 1, z = 103, parent = parent, clips = true})
	membersView.Visible = false

	ClanHelpers.createViewHeader(membersView, "👥 MIEMBROS", function() ClanViews.Navigation:navigateTo("main", State) end)

	local listContainer = UI.frame({name = "MembersListContainer", size = UDim2.new(1, -8, 1, -56), pos = UDim2.new(0, 4, 0, 52), bgT = 1, z = 104, parent = membersView})

	local function onMembersAction()
		reloadAndKeepView("members")
	end

	State.membersList = MembersList.new({
		parent = listContainer, 
		screenGui = screenGui, 
		mode = "members",
		clanData = clanData, 
		playerRole = playerRole,
		onUpdate = onMembersAction
	})

	return membersView
end

-- Vista de solicitudes pendientes
function ClanViews.createPendingView(parent, clanData, playerRole, screenGui, reloadAndKeepView, State)
	local pendingView = UI.frame({name = "PendingView", size = UDim2.new(1, 0, 1, 0), pos = UDim2.new(1, 0, 0, 0), bgT = 1, z = 103, parent = parent, clips = true})
	pendingView.Visible = false

	ClanHelpers.createViewHeader(pendingView, "📩 SOLICITUDES", function() ClanViews.Navigation:navigateTo("main", State) end)

	local listContainer = UI.frame({name = "PendingListContainer", size = UDim2.new(1, -8, 1, -56), pos = UDim2.new(0, 4, 0, 52), bgT = 1, z = 104, parent = pendingView})

	local function onPendingAction()
		reloadAndKeepView("pending")
	end

	task.spawn(function()
		local requests = ClanClient:GetJoinRequests(clanData.clanId) or {}

		if not State.isOpen then return end

		State.pendingList = MembersList.new({
			parent = listContainer, 
			screenGui = screenGui, 
			mode = "pending",
			clanData = clanData, 
			playerRole = playerRole, 
			requests = requests,
			onUpdate = onPendingAction
		})
	end)

	return pendingView
end

return ClanViews
