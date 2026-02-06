--[[
	═══════════════════════════════════════════════════════════
	INPUT HANDLER - Manejo de input y selección
	═══════════════════════════════════════════════════════════
	Maneja detección de jugadores, clics y cursores
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local InputHandler = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- SETUP (VERSIÓN SIMPLIFICADA)
-- ═══════════════════════════════════════════════════════════════

function InputHandler.setupListeners(openPanelFunc, closePanelFunc, State)
	local Config = require(script.Parent.Config)
	local Utils = require(script.Parent.Utils)
	local playerGui = player:WaitForChild("PlayerGui")
	local camera = workspace.CurrentCamera

	local function trySelectAtPosition(position)
		local now = tick()
		if now - State.lastClickTime < Config.CLICK_DEBOUNCE then return end
		State.lastClickTime = now

		if State.ui then
			-- Verificar si el clic fue en CUALQUIER GUI
			local guiObjects = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)

			if #guiObjects > 0 then
				local isUserPanel = false
				for _, obj in ipairs(guiObjects) do
					if obj:IsDescendantOf(State.ui) then
						isUserPanel = true
						break
					end
				end

				if isUserPanel then return end

				closePanelFunc()
				return
			end

			closePanelFunc()
			return
		end

		if State.isPanelOpening then return end

		local unitRay = camera:ScreenPointToRay(position.X, position.Y)
		local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * Config.MAX_RAYCAST_DISTANCE)

		if raycast and raycast.Instance then
			local clickedPlayer = Utils.getPlayerFromPart(raycast.Instance)
			if clickedPlayer then
				if clickedPlayer == player then
					local char = clickedPlayer.Character
					if char then
						local head = char:FindFirstChild("Head")
						if head and head.LocalTransparencyModifier == 1 then return end
					end
				end

				if State.ui and State.target and clickedPlayer == State.target then
					closePanelFunc()
					return
				end

				openPanelFunc(clickedPlayer)
			end
		end
	end

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if State.dragging then return end
			trySelectAtPosition(Vector2.new(mouse.X, mouse.Y))
		end
	end)

	UserInputService.TouchEnded:Connect(function(input, processed)
		if not processed and not State.dragging then
			trySelectAtPosition(input.Position)
		end
	end)
end

function InputHandler.setupCursor(State, Services)
	local Config = require(script.Parent.Config)
	local Utils = require(script.Parent.Utils)
	Services = Services or {}

	local camera = workspace.CurrentCamera

	RunService.RenderStepped:Connect(function()
		if State.ui then return end

		local mousePos = UserInputService:GetMouseLocation()
		local unitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
		local raycast = workspace:Raycast(unitRay.Origin, unitRay.Direction * Config.MAX_RAYCAST_DISTANCE)

		if raycast and raycast.Instance then
			local hoveredPlayer = Utils.getPlayerFromPart(raycast.Instance)
			if hoveredPlayer and hoveredPlayer ~= player then
				mouse.Icon = Config.SELECTED_CURSOR
				return
			end
		end

		mouse.Icon = Config.DEFAULT_CURSOR
	end)
end

return InputHandler
