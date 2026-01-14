-- ══════════════════════════════════════════════════════════════════════════════
-- MembersList.lua - Solo lista de miembros (sin tabs)
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MemberCard = require(script.Parent.MemberCard)
local ClanSystemConfig = require(ReplicatedStorage.Config.ClanSystemConfig)
local UI = require(ReplicatedStorage.Core.UI)
local THEME = require(ReplicatedStorage.Config.ThemeConfig)

local player = Players.LocalPlayer
local ROLES_CONFIG = ClanSystemConfig.ROLES.Visual

local MembersList = {}
MembersList.__index = MembersList

local CARD_HEIGHT = 52
local CARD_PADDING = 6
local VISIBLE_BUFFER = 3

function MembersList.new(config)
	local self = setmetatable({}, MembersList)
	
	self.parent = config.parent
	self.clanData = config.clanData
	self.playerRole = config.playerRole
	self.screenGui = config.screenGui
	self.onMemberUpdate = config.onMemberUpdate
	
	self.searchText = ""
	self.members = {}
	self.filteredMembers = {}
	self.cards = {}
	self.connections = {}
	
	self:_prepareMembersList()
	self:_build()
	
	return self
end

function MembersList:_prepareMembersList()
	self.members = {}
	if not self.clanData.miembros_data then return end
	
	for odI, memberData in pairs(self.clanData.miembros_data) do
		local userId = tonumber(odI)
		if userId and userId > 0 then
			table.insert(self.members, {
				userId = userId,
				data = memberData,
				priority = (ROLES_CONFIG[memberData.rol or "miembro"] or ROLES_CONFIG.miembro).priority
			})
		end
	end
	
	table.sort(self.members, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		return (a.data.nombre or "") < (b.data.nombre or "")
	end)
	
	self.filteredMembers = self.members
end

function MembersList:_build()
	self.mainFrame = UI.frame({
		size = UDim2.new(1, 0, 1, 0),
		bgT = 1,
		z = 105,
		parent = self.parent
	})
	
	-- Buscador
	self.searchFrame = UI.frame({
		size = UDim2.new(1, 0, 0, 32),
		bg = THEME.surface,
		z = 106,
		parent = self.mainFrame,
		corner = 6,
		stroke = true,
		strokeA = 0.6
	})
	
	UI.label({
		size = UDim2.new(0, 28, 1, 0),
		pos = UDim2.new(0, 4, 0, 0),
		text = ">",
		color = THEME.muted,
		textSize = 12,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Center,
		z = 107,
		parent = self.searchFrame
	})
	
	self.searchInput = Instance.new("TextBox")
	self.searchInput.Size = UDim2.new(1, -40, 1, 0)
	self.searchInput.Position = UDim2.new(0, 32, 0, 0)
	self.searchInput.BackgroundTransparency = 1
	self.searchInput.Text = ""
	self.searchInput.PlaceholderText = "Buscar miembro..."
	self.searchInput.PlaceholderColor3 = THEME.subtle
	self.searchInput.TextColor3 = THEME.text
	self.searchInput.TextSize = 12
	self.searchInput.Font = Enum.Font.Gotham
	self.searchInput.TextXAlignment = Enum.TextXAlignment.Left
	self.searchInput.ClearTextOnFocus = false
	self.searchInput.ZIndex = 107
	self.searchInput.Parent = self.searchFrame
	
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
	
	-- Scroll de miembros
	local totalHeight = #self.filteredMembers * (CARD_HEIGHT + CARD_PADDING)
	
	self.membersScroll = Instance.new("ScrollingFrame")
	self.membersScroll.Size = UDim2.new(1, 0, 1, -40)
	self.membersScroll.Position = UDim2.new(0, 0, 0, 40)
	self.membersScroll.BackgroundTransparency = 1
	self.membersScroll.ScrollBarThickness = 3
	self.membersScroll.ScrollBarImageColor3 = THEME.accent
	self.membersScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	self.membersScroll.ZIndex = 106
	self.membersScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.membersScroll.Parent = self.mainFrame
	
	self.membersContainer = UI.frame({
		size = UDim2.new(1, -4, 0, totalHeight),
		pos = UDim2.new(0, 2, 0, 0),
		bgT = 1,
		z = 106,
		parent = self.membersScroll
	})
	
	table.insert(self.connections, self.membersScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		self:_updateVisibleCards()
	end))
	
	self:_updateVisibleCards()
end

function MembersList:_applyFilter()
	if self.searchText == "" then
		self.filteredMembers = self.members
	else
		self.filteredMembers = {}
		for _, member in ipairs(self.members) do
			local nombre = (member.data.nombre or ""):lower()
			if nombre:find(self.searchText, 1, true) then
				table.insert(self.filteredMembers, member)
			end
		end
	end
	
	self:_refreshScroll()
	self:_updateVisibleCards()
end

function MembersList:_refreshScroll()
	for _, card in pairs(self.cards) do
		if card._positioner then card._positioner:Destroy() end
		card:destroy()
	end
	self.cards = {}
	
	local totalHeight = math.max(50, #self.filteredMembers * (CARD_HEIGHT + CARD_PADDING))
	self.membersScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	self.membersContainer.Size = UDim2.new(1, -4, 0, totalHeight)
	
	local noResults = self.membersContainer:FindFirstChild("NoResults")
	if noResults then noResults:Destroy() end
	
	if #self.filteredMembers == 0 then
		UI.label({
			name = "NoResults",
			size = UDim2.new(1, 0, 0, 50),
			text = self.searchText ~= "" and "Sin resultados" or "No hay miembros",
			color = THEME.muted,
			textSize = 12,
			alignX = Enum.TextXAlignment.Center,
			z = 107,
			parent = self.membersContainer
		})
	end
end

function MembersList:_updateVisibleCards()
	if #self.filteredMembers == 0 then return end
	
	local scrollPos = self.membersScroll.CanvasPosition.Y
	local viewportHeight = self.membersScroll.AbsoluteSize.Y
	
	local firstVisible = math.max(1, math.floor(scrollPos / (CARD_HEIGHT + CARD_PADDING)) - VISIBLE_BUFFER)
	local lastVisible = math.min(#self.filteredMembers, math.ceil((scrollPos + viewportHeight) / (CARD_HEIGHT + CARD_PADDING)) + VISIBLE_BUFFER)
	
	for index, card in pairs(self.cards) do
		if index < firstVisible or index > lastVisible then
			if card._positioner then card._positioner:Destroy() end
			card:destroy()
			self.cards[index] = nil
		end
	end
	
	for i = firstVisible, lastVisible do
		if not self.cards[i] and self.filteredMembers[i] then
			self:_createCardAt(i)
		end
	end
end

function MembersList:_createCardAt(index)
	local member = self.filteredMembers[index]
	if not member then return end
	
	local yPos = (index - 1) * (CARD_HEIGHT + CARD_PADDING)
	
	local positioner = UI.frame({
		size = UDim2.new(1, 0, 0, CARD_HEIGHT),
		pos = UDim2.new(0, 0, 0, yPos),
		bgT = 1,
		z = 107,
		parent = self.membersContainer
	})
	
	local card = MemberCard.new({
		userId = member.userId,
		memberData = member.data,
		playerRole = self.playerRole,
		clanData = self.clanData,
		parent = positioner,
		screenGui = self.screenGui,
		onUpdate = function()
			if self.onMemberUpdate then self.onMemberUpdate() end
		end
	})
	
	card._positioner = positioner
	self.cards[index] = card
end

function MembersList:destroy()
	for _, conn in ipairs(self.connections) do
		if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
	end
	self.connections = {}
	
	for _, card in pairs(self.cards) do
		if card._positioner then card._positioner:Destroy() end
		card:destroy()
	end
	self.cards = {}
	
	if self.mainFrame then
		self.mainFrame:Destroy()
		self.mainFrame = nil
	end
end

return MembersList