--[[
	═══════════════════════════════════════════════════════════
	USER PANEL CLIENT - v3.0 (Optimizado)
	═══════════════════════════════════════════════════════════
	• Lógica principal slim: open/close/input
	• Vista delegada a PanelView module
	• Carga rápida con defer de datos async
]]

-- ═══════════════════════════════════════════════════════════════
-- MÓDULOS
-- ═══════════════════════════════════════════════════════════════
local Modules = script.Parent.Modules

local Config = require(Modules.Config)
local State = require(Modules.State)
local RemotesSetup = require(Modules.RemotesSetup)
local GroupRoles = require(Modules.GroupEfectModule)
local Utils = require(Modules.Utils)
local SyncSystem = require(Modules.SyncSystem)
local LikesSystem = require(Modules.LikesSystem)
local EventListeners = require(Modules.EventListeners)
local InputHandler = require(Modules.InputHandler)
local PanelView = require(Modules.PanelView)

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════
local Remotes = RemotesSetup()
local Services = Remotes.Services
local player = Services.Player
local ColorEffects = Remotes.Systems.ColorEffects

Utils.init(Config, State)
SyncSystem.init(Remotes, State)
LikesSystem.init(Remotes, State, Config)
EventListeners.init(Remotes)
PanelView.init(Config, State, Utils, GroupRoles, Remotes)

-- ═══════════════════════════════════════════════════════════════
-- CERRAR PANEL
-- ═══════════════════════════════════════════════════════════════
local function closePanel()
	if State.closing or not State.ui then return end
	State.closing = true

	if State.refreshThread then task.cancel(State.refreshThread) end

	pcall(function()
		if Remotes.Systems.GlobalModalManager then
			Remotes.Systems.GlobalModalManager.isUserPanelOpen = false
		end
	end)

	local L = PanelView.getLayout()

	if State.container then
		PanelView.safeTween(State.container, {
			Position = UDim2.new(0.5, -L.panelWidth / 2, 1, 50)
		}, 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	task.delay(0.45, function()
		PanelView.cleanupTweens()
		Utils.clearConnections()
		Utils.detachHighlight(State)

		if State.ui then State.ui:Destroy() end

		State.ui = nil
		State.userId = nil
		State.target = nil
		State.container = nil
		State.panel = nil
		State.buttonsFrame = nil
		State.buttonsOverlay = nil
		State.dynamicSection = nil
		State.statsLabels = {}
		State.currentView = "buttons"
		State.isLoadingDynamic = false
		State.dragging = false
		State.closing = false
		State.isPanelOpening = false
		State.playerColor = nil
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- ABRIR PANEL
-- ═══════════════════════════════════════════════════════════════
local function openPanel(target)
	if State.isPanelOpening or State.closing or not target then return end
	State.isPanelOpening = true

	if State.refreshThread then task.cancel(State.refreshThread) end

	-- Cleanup previo
	Utils.detachHighlight(State)
	Utils.clearConnections()
	PanelView.cleanupTweens()

	if State.ui then State.ui:Destroy() end

	State.userId = target.UserId
	State.target = target

	-- Datos iniciales (instantáneos, sin esperar red)
	local cached = State.userDataCache[target.UserId]
	local hasCached = cached and (tick() - cached.lastUpdate) < 30

	local initialData = {
		userId = target.UserId,
		username = target.Name,
		displayName = target.DisplayName,
		avatar = Utils.getAvatarImage(target.UserId),
		followers = hasCached and cached.followers or 0,
		friends = hasCached and cached.friends or 0,
		likes = 0,
	}

	-- Crear panel con datos locales (frame 1 visible)
	local success, result = pcall(PanelView.createPanel, initialData)

	if success and result then
		State.ui = result
		State.target = target

		Utils.attachHighlight(target, State, ColorEffects)

		pcall(function()
			local gmm = Remotes.Systems.GlobalModalManager
			if gmm then
				if gmm.isEmoteOpen == nil then gmm.isEmoteOpen = false end
				gmm.isUserPanelOpen = true
			end
		end)

		-- Fetch real data async (no bloquea apertura)
		task.spawn(function()
			local ok, data = pcall(function()
				return Remotes.Remotes.GetUserData:InvokeServer(target.UserId)
			end)
			if ok and data and State.ui then
				State.userDataCache[target.UserId] = {
					followers = data.followers or 0,
					friends = data.friends or 0,
					lastUpdate = tick(),
				}
				Utils.updateStats(data, true, State)
			end
		end)

		State.isPanelOpening = false
	else
		State.isPanelOpening = false
		warn("[UserPanel] Error creando panel:", result)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- INPUT & CURSOR
-- ═══════════════════════════════════════════════════════════════
InputHandler.setupListeners(openPanel, closePanel, State)
InputHandler.setupCursor(State, Services)

-- ═══════════════════════════════════════════════════════════════
-- EXPORT
-- ═══════════════════════════════════════════════════════════════
_G.CloseUserPanel = closePanel

return {
	open = openPanel,
	close = closePanel,
}