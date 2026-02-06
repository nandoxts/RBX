--[[
	═══════════════════════════════════════════════════════════
	STATE - Estado compartido del UserPanel
	═══════════════════════════════════════════════════════════
	Estado global compartido entre todos los módulos
]]

local player = game:GetService("Players").LocalPlayer

-- Crear highlight persistente
local highlight = Instance.new("Highlight")
highlight.Name = "PlayerHighlight"
highlight.Enabled = false
highlight.FillTransparency = 1
highlight.OutlineTransparency = 0.3
highlight.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 2)

return {
	-- UI
	ui = nil,
	container = nil,
	panel = nil,
	statsLabels = {},
	
	-- Target
	userId = nil,
	target = nil,
	playerColor = nil,
	
	-- Flags
	closing = false,
	dragging = false,
	isPanelOpening = false,
	isLoadingDynamic = false,
	
	-- Vistas
	currentView = "buttons",
	buttonsFrame = nil,
	dynamicSection = nil,
	
	-- Conexiones
	connections = {},
	refreshThread = nil,
	
	-- Cache
	avatarCache = {},
	userDataCache = {},
	
	-- Input
	lastClickTime = 0,
	
	-- Highlight
	highlight = highlight
}
