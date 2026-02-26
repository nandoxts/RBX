--[[
	═══════════════════════════════════════════════════════════
	CLAN NETWORKING - Funciones de carga y actualización de datos
	═══════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

local ClanConstants = require(script.Parent.ClanConstants)
local ClanHelpers = require(script.Parent.ClanHelpers)
local ClanViews = require(script.Parent.ClanViews)
local ClanActions = require(script.Parent.ClanActions)

local Memory = ClanConstants.Memory
local player = Players.LocalPlayer

local ClanNetworking = {}

-- Load player clan
function ClanNetworking.loadPlayerClan(tuClanContainer, screenGui, State, reloadAndKeepView)
	if not State.isOpen then return end
	if State.isUpdating then return end
	State.isUpdating = true

	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end
	State.views = {}
	State.viewFactories = {}
	State.currentView = "main"

	ClanHelpers.safeLoading(tuClanContainer, function()
		return ClanClient:GetPlayerClan()
	end, function(clanData)
		State.isUpdating = false
		if not State.isOpen then return end

		if clanData then
			State.clanData = clanData

			local playerRole = "miembro"
			if clanData.members and clanData.members[tostring(player.UserId)] then
				playerRole = clanData.members[tostring(player.UserId)].role or "miembro"
			end
			State.playerRole = playerRole

			local reloadFunc = reloadAndKeepView

			-- Crear solo main, las demás se crean al navegar (lazy)
			State.views.main = ClanViews.createMainView(tuClanContainer, clanData, playerRole, screenGui, function() ClanNetworking.loadPlayerClan(tuClanContainer, screenGui, State, reloadFunc) end, State)
			State.viewFactories.members = function() return ClanViews.createMembersView(tuClanContainer, clanData, playerRole, screenGui, reloadFunc, State) end

			local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
			if canManageRequests then
				State.viewFactories.pending = function() return ClanViews.createPendingView(tuClanContainer, clanData, playerRole, screenGui, reloadFunc, State) end
			end

			State.views.main.Position = UDim2.new(0, 0, 0, 0)
			State.views.main.Visible = true
		else
			local noClanCard = UI.frame({size = UDim2.new(0, 280, 0, 140), pos = UDim2.new(0.5, -140, 0.5, -70), bg = THEME.card, z = 103, parent = tuClanContainer, corner = 12, stroke = true, strokeA = 0.6})
			UI.label({size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 30), text = "⚔️", textSize = 32, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 75), text = "No perteneces a ningún clan", textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 100), text = "Explora clanes en 'Disponibles'", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
		end
	end, State)
end

-- Reload and keep view
function ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, targetView)
	if not State.isOpen then return end
	if State.isUpdating then return end
	State.isUpdating = true

	local viewToRestore = targetView or State.currentView

	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end
	State.views = {}
	State.currentView = "main"

	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()
	Memory:destroyChildren(tuClanContainer, "UIListLayout")

	local loadingFrame = UI.loading(tuClanContainer)
	local myId = State.loadingId

	task.spawn(function()
		local success, clanData = pcall(function()
			return ClanClient:GetPlayerClan()
		end)

		if myId ~= State.loadingId then return end
		if not State.isOpen then return end

		UI.cleanupLoading()
		if loadingFrame and loadingFrame.Parent then loadingFrame:Destroy() end
		Memory:destroyChildren(tuClanContainer, "UIListLayout")

		if not success or not clanData then
			local noClanCard = UI.frame({size = UDim2.new(0, 280, 0, 140), pos = UDim2.new(0.5, -140, 0.5, -70), bg = THEME.card, z = 103, parent = tuClanContainer, corner = 12, stroke = true, strokeA = 0.6})
			UI.label({size = UDim2.new(1, 0, 0, 40), pos = UDim2.new(0, 0, 0, 30), text = "⚔️", textSize = 32, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 20), pos = UDim2.new(0, 10, 0, 75), text = "No perteneces a ningún clan", textSize = 13, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			UI.label({size = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 100), text = "Explora clanes en 'Disponibles'", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Center, z = 104, parent = noClanCard})
			State.isUpdating = false
			return
		end

		State.clanData = clanData

		local playerRole = "miembro"
		if clanData.members and clanData.members[tostring(player.UserId)] then
			playerRole = clanData.members[tostring(player.UserId)].role or "miembro"
		end
		State.playerRole = playerRole

		local reloadFunc = function(v) ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, v) end

		State.viewFactories = {}
		State.views.main = ClanViews.createMainView(tuClanContainer, clanData, playerRole, screenGui, function() ClanNetworking.loadPlayerClan(tuClanContainer, screenGui, State, reloadFunc) end, State)
		State.viewFactories.members = function() return ClanViews.createMembersView(tuClanContainer, clanData, playerRole, screenGui, reloadFunc, State) end

		local canManageRequests = (playerRole == "owner" or playerRole == "colider" or playerRole == "lider")
		if canManageRequests then
			State.viewFactories.pending = function() return ClanViews.createPendingView(tuClanContainer, clanData, playerRole, screenGui, reloadFunc, State) end
		end

		-- Si hay que restaurar una vista no-main, crearla ahora
		if viewToRestore ~= "main" and State.viewFactories[viewToRestore] then
			State.views[viewToRestore] = State.viewFactories[viewToRestore]()
			State.viewFactories[viewToRestore] = nil
		end

		for _, v in pairs(State.views) do
			if v then v.Visible = false end
		end

		if viewToRestore ~= "main" and State.views[viewToRestore] then
			State.views[viewToRestore].Position = UDim2.new(0, 0, 0, 0)
			State.views[viewToRestore].Visible = true
			State.currentView = viewToRestore
		else
			State.views.main.Position = UDim2.new(0, 0, 0, 0)
			State.views.main.Visible = true
			State.currentView = "main"
		end
		State.isUpdating = false
	end)
end

-- Create clan entry
function ClanNetworking.createClanEntry(clanData, pendingList, clansScroll, loadClansFromServerFn)
	local entry = UI.frame({name = "ClanEntry_" .. (clanData.clanId or "unknown"), size = UDim2.new(1, 0, 0, 85), bg = THEME.card, z = 104, parent = clansScroll, corner = 10, stroke = true, strokeA = 0.6})

	local logoContainer = UI.frame({size = UDim2.new(0, 60, 0, 60), pos = UDim2.new(0, 12, 0.5, -30), bgT = 1, z = 105, parent = entry, corner = 10})

	if clanData.logo and clanData.logo ~= "" and clanData.logo ~= "rbxassetid://0" then
		local logo = Instance.new("ImageLabel")
		logo.Size, logo.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
		logo.Image, logo.ScaleType, logo.ZIndex = clanData.logo, Enum.ScaleType.Fit, 106
		logo.Parent = logoContainer
		UI.rounded(logo, 8)
	else
		UI.label({size = UDim2.new(1, 0, 1, 0), text = clanData.emoji or "⚔️", textSize = 30, alignX = Enum.TextXAlignment.Center, z = 106, parent = logoContainer})
	end

	local clanColor = clanData.color and Color3.fromRGB(clanData.color[1] or 255, clanData.color[2] or 255, clanData.color[3] or 255) or THEME.accent

	UI.label({size = UDim2.new(1, -180, 0, 18), pos = UDim2.new(0, 85, 0, 12), text = (clanData.emoji or "") .. " " .. string.upper(clanData.name or "CLAN"), color = clanColor, textSize = 14, font = Enum.Font.GothamBold, z = 106, parent = entry})
	UI.label({size = UDim2.new(1, -180, 0, 26), pos = UDim2.new(0, 85, 0, 32), text = clanData.description or "Sin descripción", color = THEME.subtle, textSize = 11, wrap = true, truncate = Enum.TextTruncate.AtEnd, z = 106, parent = entry})
	UI.label({size = UDim2.new(1, -180, 0, 28), pos = UDim2.new(0, 85, 0, 54), text = string.format("%d MIEMBROS [%s]", clanData.memberCount or 0, clanData.tag or "?"), color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 106, parent = entry, alignX = Enum.TextXAlignment.Left})

	local joinBtn = UI.button({size = UDim2.new(0, 75, 0, 30), pos = UDim2.new(1, -87, 0.5, -15), bg = THEME.accent, text = "UNIRSE", textSize = 11, z = 106, parent = entry, corner = 6})

	local isPlayerMember = clanData.isPlayerMember or false
	local isPending = false
	if pendingList then
		for _, req in ipairs(pendingList) do
			if req.clanId == clanData.clanId then isPending = true break end
		end
	end

	if isPlayerMember then
		joinBtn.Text, joinBtn.BackgroundColor3, joinBtn.Active = "MIEMBRO", THEME.accent, false
	elseif isPending then
		joinBtn.Text, joinBtn.BackgroundColor3 = "PENDIENTE", THEME.warn
		Memory:track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:CancelAllJoinRequests()
			if success then 
				Notify:Success("Cancelado", msg or "Solicitud cancelada", 5)
				-- 🔥 NO hacer loadClansFromServerFn() - el evento ClansUpdated ya actualiza automáticamente
			end
		end))
	else
		UI.hover(joinBtn, THEME.accent, UI.brighten(THEME.accent, 1.15))
		Memory:track(joinBtn.MouseButton1Click:Connect(function()
			local success, msg = ClanClient:RequestJoinClan(clanData.clanId)
			if not success and msg then
				Notify:Warning("No disponible", msg, 4)
			end
		end))
	end

	UI.hover(entry, THEME.card, THEME.elevated)
	return entry
end

-- Load clans from server
function ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG, filtro, forceUpdate)
	if not State.isOpen then return end

	-- Permitir actualización forzada aunque esté ocupado
	if not forceUpdate and State.isUpdating then return end
	State.isUpdating = true

	filtro = filtro or ""
	local filtroLower = filtro:lower()

	ClanHelpers.safeLoading(clansScroll, function()
		-- Peticiones en paralelo para reducir tiempo de espera
		local clans, pending
		local done = 0
		task.spawn(function() clans = ClanClient:GetClansList() done += 1 end)
		task.spawn(function() pending = ClanClient:GetUserPendingRequests() done += 1 end)
		while done < 2 do task.wait() end
		return clans, pending
	end, function(clans, pendingList)
		-- ✅ Protección: Limpiar State.isUpdating SIEMPRE
		pcall(function()
			clans = clans or {}

			if #clans > 0 then
				local hayResultados = false
				for _, clanData in ipairs(clans) do
					local nombre = (clanData.name or ""):lower()
					local tag = (clanData.tag or ""):lower()

					if filtroLower == "" or nombre:find(filtroLower, 1, true) or tag:find(filtroLower, 1, true) then
						ClanNetworking.createClanEntry(clanData, pendingList, clansScroll, function() ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG) end)
						hayResultados = true
					end
				end

				if not hayResultados and filtroLower ~= "" then
					UI.label({size = UDim2.new(1, 0, 0, 60), text = "No se encontraron clanes", color = THEME.muted, textSize = 13, font = Enum.Font.GothamMedium, alignX = Enum.TextXAlignment.Center, z = 104, parent = clansScroll})
				end
			else
				UI.label({size = UDim2.new(1, 0, 0, 60), text = "No hay clanes disponibles", color = THEME.muted, textSize = 13, font = Enum.Font.GothamMedium, alignX = Enum.TextXAlignment.Center, z = 104, parent = clansScroll})
			end
		end)

		State.isUpdating = false  -- ✅ Siempre limpiar, incluso si hay error
	end, State)
end

-- Load admin clans
function ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG)
	if not adminClansScroll then return end
	if not State.isOpen then return end

	if State.isUpdating then return end
	State.isUpdating = true

	ClanHelpers.safeLoading(adminClansScroll, function()
		return ClanClient:GetClansList()
	end, function(clans)
		-- ✅ Protección: Limpiar State.isUpdating SIEMPRE
		pcall(function()
			if not clans or #clans == 0 then
				UI.label({size = UDim2.new(1, 0, 0, 50), text = "No hay clanes registrados", color = THEME.muted, textSize = 12, alignX = Enum.TextXAlignment.Center, z = 104, parent = adminClansScroll})
				return
			end

			for _, clanData in ipairs(clans) do
				if not clanData.clanId then
					warn("[CreateClanGui] Clan sin clanId:", clanData)
				end

				local entry = UI.frame({size = UDim2.new(1, 0, 0, 65), bg = THEME.card, z = 104, parent = adminClansScroll, corner = 10, stroke = true, strokeA = 0.6})

				UI.label({size = UDim2.new(1, -160, 0, 18), pos = UDim2.new(0, 15, 0, 12), text = (clanData.emoji or "") .. " " .. (clanData.name or "Sin nombre"), color = THEME.accent, textSize = 13, font = Enum.Font.GothamBold, z = 105, parent = entry})
				UI.label({size = UDim2.new(1, -160, 0, 14), pos = UDim2.new(0, 15, 0, 34), text = "ID: " .. (clanData.clanId or "?") .. " • " .. (clanData.memberCount or 0) .. " miembros", color = THEME.muted, textSize = 10, z = 105, parent = entry})

				local deleteBtn = UI.button({size = UDim2.new(0, 70, 0, 32), pos = UDim2.new(1, -80, 0.5, -16), bg = THEME.btnDanger, text = "Eliminar", textSize = 10, z = 105, parent = entry, corner = 6, hover = true, hoverBg = UI.brighten(THEME.btnDanger, 1.15)})
				UI.hover(entry, THEME.card, THEME.elevated)

				Memory:track(deleteBtn.MouseButton1Click:Connect(function()
					ClanActions:adminDelete(screenGui, clanData, function() ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG) end)
				end))
			end
		end)

		State.isUpdating = false  -- ✅ Siempre limpiar, incluso si hay error
	end, State)
end

return ClanNetworking
