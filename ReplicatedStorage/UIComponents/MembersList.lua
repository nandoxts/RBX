-- ══════════════════════════════════════════════════════════════════════════════
-- MembersList.lua - Lista reutilizable para miembros y solicitudes pendientes
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MemberCard = require(script.Parent.MemberCard)
local PendingCard = require(script.Parent.PendingCard)
local ClanSystemConfig = require(ReplicatedStorage.Config.ClanSystemConfig)
local UI = require(ReplicatedStorage.Core.UI)
local THEME = require(ReplicatedStorage.Config.ThemeConfig)
local Notify = require(ReplicatedStorage.Systems.NotificationSystem.NotificationSystem)
local ClanClient = require(ReplicatedStorage.Systems.ClanSystem.ClanClient)

local player = Players.LocalPlayer
local ROLES_CONFIG = ClanSystemConfig.ROLES.Visual

local MembersList = {}
MembersList.__index = MembersList

local CARD_HEIGHT = 56
local CARD_PADDING = 8
local VISIBLE_BUFFER = 3

--[[
	Configuración:
	- parent: Frame contenedor
	- screenGui: ScreenGui para modales
	- mode: "members" | "pending"
	- clanData: datos del clan
	- playerRole: rol del jugador actual
	- requests: array de solicitudes (para mode="pending")
	- onUpdate / onMemberUpdate: callback cuando hay cambios
	- searchPlaceholder: texto del buscador (opcional)
	- emptyText: texto cuando no hay items (opcional)
]]

function MembersList.new(config)
	local self = setmetatable({}, MembersList)

	self.parent = config.parent
	self.screenGui = config.screenGui
	self.mode = config.mode or "members"
	self.clanData = config.clanData
	self.playerRole = config.playerRole
	self.requests = config.requests or {}
	self.onUpdate = config.onUpdate or config.onMemberUpdate
	self.searchPlaceholder = config.searchPlaceholder or (self.mode == "members" and "Buscar miembro..." or "Buscar solicitud...")
	self.emptyText = config.emptyText or (self.mode == "members" and "No hay miembros" or "📭 No hay solicitudes pendientes")

	self.searchText = ""
	self.items = {}
	self.filteredItems = {}
	self.cards = {}
	self.connections = {}

	self:_prepareItems()
	self:_build()

	return self
end

function MembersList:_prepareItems()
	self.items = {}

	if self.mode == "members" then
		-- Preparar lista de miembros
		if not self.clanData or not self.clanData.miembros_data then return end

		for odI, memberData in pairs(self.clanData.miembros_data) do
			local odI_num = tonumber(odI)
			if odI_num and odI_num > 0 then
				table.insert(self.items, {
					odI = odI_num,
					data = memberData,
					priority = (ROLES_CONFIG[memberData.rol or "miembro"] or ROLES_CONFIG.miembro).priority,
					type = "member"
				})
			end
		end

		-- Ordenar por prioridad de rol
		table.sort(self.items, function(a, b)
			if a.priority ~= b.priority then
				return a.priority > b.priority
			end
			return (a.data.nombre or "") < (b.data.nombre or "")
		end)
	else
		-- Preparar lista de solicitudes pendientes
		for i, request in ipairs(self.requests) do
			table.insert(self.items, {
				odI = request.playerId,
				data = {
					nombre = request.playerName or "Usuario",
					requestTime = request.requestTime
				},
				priority = i,
				type = "pending"
			})
		end
	end

	self.filteredItems = self.items
end

function MembersList:_build()
	self.mainFrame = UI.frame({
		size = UDim2.new(1, 0, 1, 0),
		bgT = 1,
		z = 105,
		parent = self.parent
	})

	-- Buscador (usar componente SearchModern)
	local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))
	local searchContainer, searchInput = SearchModern.new(self.mainFrame, {
		placeholder = self.searchPlaceholder,
		size = UDim2.new(1, 0, 0, 36),
		z = 106,
		inputName = (self.mode == "members" and "SearchMembersInput") or "SearchPendingInput"
	})
	-- Asegurar posición coherente
	searchContainer.Position = UDim2.new(0, 0, 0, 0)
	self.searchInput = searchInput

	local searchDebounce = false
	table.insert(self.connections, self.searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounce then return end
		searchDebounce = true
		task.delay(0.25, function()
			self.searchText = self.searchInput.Text:lower()
			self:_applyFilter()
			searchDebounce = false
		end)
	end))

	-- Scroll
	local totalHeight = math.max(60, #self.filteredItems * (CARD_HEIGHT + CARD_PADDING))

	self.scroll = Instance.new("ScrollingFrame")
	self.scroll.Size = UDim2.new(1, 0, 1, -44)
	self.scroll.Position = UDim2.new(0, 0, 0, 44)
	self.scroll.BackgroundTransparency = 1
	self.scroll.ScrollBarThickness = 3
	self.scroll.ScrollBarImageColor3 = THEME.accent
	self.scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	self.scroll.ZIndex = 106
	self.scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.scroll.Parent = self.mainFrame

	self.container = UI.frame({
		size = UDim2.new(1, -4, 0, totalHeight),
		pos = UDim2.new(0, 2, 0, 0),
		bgT = 1,
		z = 106,
		parent = self.scroll
	})

	table.insert(self.connections, self.scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		self:_updateVisibleCards()
	end))

	self:_updateVisibleCards()
end

function MembersList:_applyFilter()
	if self.searchText == "" then
		self.filteredItems = self.items
	else
		self.filteredItems = {}
		for _, item in ipairs(self.items) do
			local nombre = (item.data.nombre or ""):lower()
			if nombre:find(self.searchText, 1, true) then
				table.insert(self.filteredItems, item)
			end
		end
	end

	self:_refreshScroll()
	self:_updateVisibleCards()
end

function MembersList:_refreshScroll()
	-- Limpiar cards existentes
	for _, card in pairs(self.cards) do
		if card.positioner then card.positioner:Destroy() end
		if card.instance and card.instance.destroy then
			card.instance:destroy()
		elseif card.frame then
			card.frame:Destroy()
		end
	end
	self.cards = {}

	local totalHeight = math.max(60, #self.filteredItems * (CARD_HEIGHT + CARD_PADDING))
	self.scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	self.container.Size = UDim2.new(1, -4, 0, totalHeight)

	-- Limpiar mensaje de no resultados
	local noResults = self.container:FindFirstChild("NoResults")
	if noResults then noResults:Destroy() end

	if #self.filteredItems == 0 then
		UI.label({
			name = "NoResults",
			size = UDim2.new(1, 0, 0, 60),
			text = self.searchText ~= "" and "🔍 Sin resultados" or self.emptyText,
			color = THEME.muted,
			textSize = 13,
			alignX = Enum.TextXAlignment.Center,
			z = 107,
			parent = self.container
		})
	end
end

function MembersList:_updateVisibleCards()
	if #self.filteredItems == 0 then return end

	local scrollPos = self.scroll.CanvasPosition.Y
	local viewportHeight = self.scroll.AbsoluteSize.Y

	local firstVisible = math.max(1, math.floor(scrollPos / (CARD_HEIGHT + CARD_PADDING)) - VISIBLE_BUFFER)
	local lastVisible = math.min(#self.filteredItems, math.ceil((scrollPos + viewportHeight) / (CARD_HEIGHT + CARD_PADDING)) + VISIBLE_BUFFER)

	-- Eliminar cards fuera de vista
	for index, card in pairs(self.cards) do
		if index < firstVisible or index > lastVisible then
			if card.positioner then card.positioner:Destroy() end
			if card.instance and card.instance.destroy then
				card.instance:destroy()
			elseif card.frame then
				card.frame:Destroy()
			end
			self.cards[index] = nil
		end
	end

	-- Crear cards visibles
	for i = firstVisible, lastVisible do
		if not self.cards[i] and self.filteredItems[i] then
			self:_createCardAt(i)
		end
	end
end

function MembersList:_createCardAt(index)
	local item = self.filteredItems[index]
	if not item then return end

	local yPos = (index - 1) * (CARD_HEIGHT + CARD_PADDING)

	local positioner = UI.frame({
		size = UDim2.new(1, 0, 0, CARD_HEIGHT),
		pos = UDim2.new(0, 0, 0, yPos),
		bgT = 1,
		z = 107,
		parent = self.container
	})

	if self.mode == "members" then
		-- Usar MemberCard para miembros
		local card = MemberCard.new({
			userId = item.odI,
			memberData = item.data,
			playerRole = self.playerRole,
			clanData = self.clanData,
			parent = positioner,
			screenGui = self.screenGui,
			onUpdate = function()
				if self.onUpdate then self.onUpdate() end
			end
		})

		self.cards[index] = {
			positioner = positioner,
			instance = card
		}
	else
		-- Crear card de solicitud pendiente usando PendingCard reutilizable
		local pending = PendingCard.new({
			userId = item.odI,
			requestData = item.data,
			playerRole = self.playerRole,
			clanData = self.clanData,
			parent = positioner,
			screenGui = self.screenGui,
			onUpdate = function()
				if self.onUpdate then self.onUpdate() end
			end
		})

		self.cards[index] = {
			positioner = positioner,
			instance = pending
		}
	end
end

function MembersList:_createPendingCard(parent, item)
	local card = UI.frame({
		size = UDim2.new(1, 0, 1, 0),
		bg = THEME.card,
		z = 108,
		parent = parent,
		corner = 10,
		stroke = true,
		strokeA = 0.6
	})

	-- Avatar
	local avatarFrame = UI.frame({
		size = UDim2.new(0, 44, 0, 44),
		pos = UDim2.new(0, 6, 0.5, -22),
		bg = THEME.surface,
		z = 109,
		parent = card,
		corner = 22
	})

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(1, -4, 1, -4)
	avatar.Position = UDim2.new(0, 2, 0, 2)
	avatar.BackgroundTransparency = 1
	avatar.Image = string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
		item.odI
	)
	avatar.ZIndex = 110
	avatar.Parent = avatarFrame
	UI.rounded(avatar, 20)

	-- Borde naranja (pendiente)
	local pendingBorder = Instance.new("UIStroke")
	pendingBorder.Color = THEME.accent
	pendingBorder.Thickness = 2
	pendingBorder.Parent = avatarFrame

	-- Nombre
	local displayName = item.data.nombre or "Usuario"
	if #displayName > 18 then
		displayName = displayName:sub(1, 16) .. "..."
	end

	UI.label({
		size = UDim2.new(1, -160, 0, 20),
		pos = UDim2.new(0, 58, 0, 10),
		text = displayName,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 109,
		parent = card
	})

	-- Tiempo
	local timeAgo = os.time() - (item.data.requestTime or os.time())
	local timeText = "Ahora"
	if timeAgo >= 86400 then
		timeText = "Hace " .. math.floor(timeAgo / 86400) .. "d"
	elseif timeAgo >= 3600 then
		timeText = "Hace " .. math.floor(timeAgo / 3600) .. "h"
	elseif timeAgo >= 60 then
		timeText = "Hace " .. math.floor(timeAgo / 60) .. "m"
	end

	UI.label({
		size = UDim2.new(1, -160, 0, 16),
		pos = UDim2.new(0, 58, 0, 30),
		text = timeText,
		color = THEME.muted,
		textSize = 11,
		alignX = Enum.TextXAlignment.Left,
		z = 109,
		parent = card
	})

	-- Botones de acción
	local acceptBtn = UI.button({
		size = UDim2.new(0, 44, 0, 38),
		pos = UDim2.new(1, -100, 0.5, -19),
		bg = THEME.success,
		text = "✓",
		textSize = 18,
		z = 109,
		parent = card,
		corner = 8
	})

	local rejectBtn = UI.button({
		size = UDim2.new(0, 44, 0, 38),
		pos = UDim2.new(1, -52, 0.5, -19),
		bg = THEME.warn,
		text = "✕",
		textSize = 18,
		z = 109,
		parent = card,
		corner = 8
	})

	UI.hover(acceptBtn, THEME.success, THEME.successMuted)
	UI.hover(rejectBtn, THEME.warn, THEME.warnMuted)

	-- Conexiones de botones
	local acceptConn = acceptBtn.MouseButton1Click:Connect(function()
		acceptBtn.Text = "..."
		acceptBtn.Active = false

		local success, msg = ClanClient:ApproveJoinRequest(self.clanData.clanId, item.odI)
		if success then
			Notify:Success("Aceptado", (item.data.nombre or "Usuario") .. " se unió al clan", 4)
			-- Animar y remover
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			task.delay(0.25, function()
				if self.onUpdate then self.onUpdate() end
			end)
		else
			Notify:Error("Error", msg or "No se pudo aceptar", 4)
			acceptBtn.Text = "✓"
			acceptBtn.Active = true
		end
	end)

	local rejectConn = rejectBtn.MouseButton1Click:Connect(function()
		rejectBtn.Text = "..."
		rejectBtn.Active = false

		local success, msg = ClanClient:RejectJoinRequest(self.clanData.clanId, item.odI)
		if success then
			Notify:Success("Rechazado", "Solicitud rechazada", 4)
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			task.delay(0.25, function()
				if self.onUpdate then self.onUpdate() end
			end)
		else
			Notify:Error("Error", msg or "No se pudo rechazar", 4)
			rejectBtn.Text = "✕"
			rejectBtn.Active = true
		end
	end)

	table.insert(self.connections, acceptConn)
	table.insert(self.connections, rejectConn)

	return card
end

-- Método para actualizar datos externamente
function MembersList:updateData(newData)
	if self.mode == "members" then
		self.clanData = newData.clanData or self.clanData
	else
		self.requests = newData.requests or self.requests
	end

	self:_prepareItems()
	self:_refreshScroll()
	self:_updateVisibleCards()
end

function MembersList:destroy()
	for _, conn in ipairs(self.connections) do
		if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
	end
	self.connections = {}

	for _, card in pairs(self.cards) do
		if card.positioner then card.positioner:Destroy() end
		if card.instance and card.instance.destroy then
			card.instance:destroy()
		elseif card.frame then
			card.frame:Destroy()
		end
	end
	self.cards = {}

	if self.mainFrame then
		self.mainFrame:Destroy()
		self.mainFrame = nil
	end
end

return MembersList