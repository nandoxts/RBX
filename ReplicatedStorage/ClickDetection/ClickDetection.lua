-- ════════════════════════════════════════════════════════════════
-- CLICK DETECTION MODULE v3.0
-- Módulo reutilizable para detectar clicks en jugadores
-- Ubicación: ReplicatedStorage/Modules/ClickDetection.lua
-- ════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- No cache de LocalPlayer en top-level; obtener dinámicamente cuando haga falta

local function getLocalPlayer()
	return Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════════
-- MÓDULO
-- ═══════════════════════════════════════════════════════════════

local ClickDetection = {}
ClickDetection.__index = ClickDetection

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN POR DEFECTO
-- ═══════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
	-- Distancia máxima de detección (en studs)
	MaxDistance = 10000,

	-- Tiempo mínimo entre clicks (segundos)
	Cooldown = 0.25,

	-- Tolerancia en pantalla (pixels)
	ScreenTolerance = 50,

	-- Incluir jugador local en la detección
	IncludeLocalPlayer = false,

	-- Modo debug
	Debug = false,
}

-- ═══════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════════════

function ClickDetection.new(config)
	local self = setmetatable({}, ClickDetection)

	-- Mezclar config con defaults
	self.Config = {}
	for key, defaultValue in pairs(DEFAULT_CONFIG) do
		if config and config[key] ~= nil then
			self.Config[key] = config[key]
		else
			self.Config[key] = defaultValue
		end
	end

	-- Estado interno
	self._lastClickTime = 0
	self._connections = {}
	self._callbacks = {}
	self._enabled = true

	return self
end

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES INTERNAS
-- ═══════════════════════════════════════════════════════════════

function ClickDetection:_log(...)
	if self.Config.Debug then
		print("[ClickDetection]", ...)
	end
end

-- Obtener todos los personajes de jugadores
function ClickDetection:_getAllCharacters()
	local characters = {}

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		local shouldInclude = true
		local localPlayer = getLocalPlayer()

		-- Excluir jugador local si está configurado así
		if not self.Config.IncludeLocalPlayer and localPlayer and otherPlayer == localPlayer then
			shouldInclude = false
		end

		if shouldInclude and otherPlayer.Character then
			table.insert(characters, otherPlayer.Character)
		end
	end

	-- Debug: listar nombres de jugadores incluidos
	local names = {}
	for _, char in ipairs(characters) do
		local pl = Players:GetPlayerFromCharacter(char)
		if pl then table.insert(names, pl.Name) end
	end
	self:_log("_getAllCharacters -> count:", #characters, "players:", table.concat(names, ", "))

	return characters
end

-- Encontrar jugador desde una parte
function ClickDetection:_findPlayerFromPart(part)
	if not part then
		return nil
	end

	-- Intento directo: buscar el ancestro que sea un Model y que tenga Humanoid
	local ancestorModel = part:FindFirstAncestorWhichIsA("Model")
	if ancestorModel then
		local humanoid = ancestorModel:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local pl = Players:GetPlayerFromCharacter(ancestorModel)
			if pl then
				local localPlayer = getLocalPlayer()
				if localPlayer and pl == localPlayer and not self.Config.IncludeLocalPlayer then
					return nil
				end
				return pl
			end
		end
	end

	-- Manejar casos donde el hit sea el Handle de una Accessory
	-- (por ejemplo: Workspace.SomeModel.Accessory.Handle)
	if part and part.Parent and part.Parent:IsA("Accessory") then
		local accessory = part.Parent
		local charCandidate = accessory.Parent
		if charCandidate and charCandidate:IsA("Model") then
			local humanoid = charCandidate:FindFirstChildOfClass("Humanoid")
			local pl = nil
			if humanoid then
				pl = Players:GetPlayerFromCharacter(charCandidate)
			end

			-- Si no encontramos Humanoid o GetPlayerFromCharacter falló,
			-- intentar resolver por nombre (Workspace.ModelName -> Player named ModelName)
			if not pl then
				local maybePlayer = Players:FindFirstChild(charCandidate.Name)
				if maybePlayer and maybePlayer:IsA("Player") then
					-- Asegurarse que el jugador tenga Character (opcional)
					if maybePlayer.Character then
						pl = maybePlayer
					else
						-- Si no tiene Character, aún devolver el Player para que el caller decida
						pl = maybePlayer
					end
				end
			end

			if pl then
				self:_log("Accessory parent resolved to player:", pl.Name, "from model:", charCandidate:GetFullName())
				local localPlayer = getLocalPlayer()
				if localPlayer and pl == localPlayer and not self.Config.IncludeLocalPlayer then
					return nil
				end
				return pl
			end
		end
	end

	-- Fallback: recorrer hacia arriba (compatibilidad adicional)
	local current = part
	while current and current ~= workspace do
		if current:IsA("Model") then
			local humanoid = current:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local pl = Players:GetPlayerFromCharacter(current)
				if pl then
					local localPlayer = getLocalPlayer()
					if localPlayer and pl == localPlayer and not self.Config.IncludeLocalPlayer then
						return nil
					end
					return pl
				end
			end
		end
		current = current.Parent
	end

	return nil
end

-- Raycast simple
function ClickDetection:_performRaycast(screenX, screenY)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local unitRay = camera:ViewportPointToRay(screenX, screenY)

	-- Usar FilterType = Exclude y excluir el character local (más robusto)
	local excludeList = {}
	local localPlayer = getLocalPlayer()
	-- Excluir personaje local sólo si la configuración indica lo contrario
	if not self.Config.IncludeLocalPlayer and localPlayer and localPlayer.Character then
		table.insert(excludeList, localPlayer.Character)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = excludeList
	raycastParams.IgnoreWater = true

	self:_log("_performRaycast -> casting with Exclude count:", #excludeList)
	-- Log adicional para depuración: origen y dirección del ray
	self:_log("unitRay Origin:", unitRay.Origin, "Direction:", unitRay.Direction)

	local result = workspace:Raycast(
		unitRay.Origin,
		unitRay.Direction * self.Config.MaxDistance,
		raycastParams
	)


	if result and result.Instance then
		self:_log("Raycast hit:", result.Instance:GetFullName())
	else
		self:_log("Raycast no hit at", screenX, screenY)

		-- Fallback debug: intentar raycast sin filtro para ver qué hay en la dirección
		local fallback = workspace:Raycast(
			unitRay.Origin,
			unitRay.Direction * self.Config.MaxDistance
		)
		if fallback and fallback.Instance then
			self:_log("Fallback raycast hit:", fallback.Instance:GetFullName())
		else
			self:_log("Fallback raycast no hit también")
		end
	end

	return result
end



-- Raycast expandido (múltiples puntos)
function ClickDetection:_performExpandedRaycast(screenX, screenY)
	-- Intento directo primero
	local directResult = self:_performRaycast(screenX, screenY)

	if directResult then
		local targetPlayer = self:_findPlayerFromPart(directResult.Instance)
		if targetPlayer then
			self:_log("Click directo en:", targetPlayer.Name)
			return targetPlayer, directResult
		end
	end

	-- Offsets para intentar si falla el directo
	local offsets = {
		{-5, 0}, {5, 0}, {0, -5}, {0, 5},
		{-3, -3}, {3, -3}, {-3, 3}, {3, 3},
		{-8, 0}, {8, 0}, {0, -8}, {0, 8},
		{-10, -10}, {10, -10}, {-10, 10}, {10, 10},
	}

	for _, offset in ipairs(offsets) do
		local result = self:_performRaycast(screenX + offset[1], screenY + offset[2])

		if result then
			local targetPlayer = self:_findPlayerFromPart(result.Instance)
			if targetPlayer then
				self:_log("Click con offset", offset[1], offset[2], "en:", targetPlayer.Name)
				return targetPlayer, result
			end
		end
	end

	return nil, nil
end

-- Buscar jugador más cercano al punto en pantalla
function ClickDetection:_findNearestPlayerToScreen(screenX, screenY)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local closestPlayer = nil
	local closestDistance = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		-- Verificar si debemos incluir este jugador
		local shouldCheck = true
		local localPlayer = getLocalPlayer()
		if localPlayer and otherPlayer == localPlayer and not self.Config.IncludeLocalPlayer then
			shouldCheck = false
		end

		if shouldCheck and otherPlayer.Character then
			-- Buscar parte de referencia (cabeza o torso)
			local head = otherPlayer.Character:FindFirstChild("Head")
			local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			local targetPart = head or hrp

			if targetPart then
				local screenPos, onScreen = camera:WorldToScreenPoint(targetPart.Position)

				if onScreen then
					-- Calcular distancia en pantalla
					local screenDistance = math.sqrt(
						(screenPos.X - screenX)^2 + 
							(screenPos.Y - screenY)^2
					)

					-- Verificar si está dentro de la tolerancia
					if screenDistance < self.Config.ScreenTolerance and screenDistance < closestDistance then
						-- Verificar que no haya obstáculos
						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						rayParams.FilterDescendantsInstances = {
							(getLocalPlayer() and getLocalPlayer().Character) or nil,
							otherPlayer.Character
						}

						local direction = (targetPart.Position - camera.CFrame.Position)
						local obstacleCheck = workspace:Raycast(
							camera.CFrame.Position,
							direction,
							rayParams
						)

						-- Si no hay obstáculo, es válido
						if not obstacleCheck then
							closestPlayer = otherPlayer
							closestDistance = screenDistance
						end
					end
				end
			end
		end
	end

	if closestPlayer then
		self:_log("Jugador más cercano:", closestPlayer.Name, "a", math.floor(closestDistance), "px")
	end

	return closestPlayer
end

-- Handler principal de click
function ClickDetection:_handleClick(screenX, screenY)
	-- Verificar si está habilitado
	if not self._enabled then
		return nil
	end

	-- Verificar cooldown
	local currentTime = tick()
	if currentTime - self._lastClickTime < self.Config.Cooldown then
		return nil
	end
	self._lastClickTime = currentTime

	self:_log("_handleClick at", screenX, screenY)

	-- Método 1: Raycast expandido
	local targetPlayer, rayResult = self:_performExpandedRaycast(screenX, screenY)

	-- Método 2: Buscar más cercano en pantalla
	if not targetPlayer then
		targetPlayer = self:_findNearestPlayerToScreen(screenX, screenY)
	end

	-- Disparar callbacks si encontramos un jugador
	if targetPlayer then
		self:_log("¡Click detectado en:", targetPlayer.Name, "!", "rayResult=", rayResult and tostring(rayResult.Instance) or "nil")

		for _, callback in ipairs(self._callbacks) do
			task.spawn(function()
				callback(targetPlayer, rayResult)
			end)
		end
	else
		self:_log("No se detectó jugador en click")
	end

	return targetPlayer, rayResult
end

-- ═══════════════════════════════════════════════════════════════
-- MÉTODOS PÚBLICOS
-- ═══════════════════════════════════════════════════════════════

-- Conectar callback cuando se detecta click en un jugador
-- Retorna una función para desconectar
function ClickDetection:OnPlayerClicked(callback)
	table.insert(self._callbacks, callback)

	-- Retornar función para desconectar
	return function()
		for i, cb in ipairs(self._callbacks) do
			if cb == callback then
				table.remove(self._callbacks, i)
				break
			end
		end
	end
end

-- Iniciar detección automática de clicks
function ClickDetection:Start()
	-- Evitar múltiples starts
	if #self._connections > 0 then
		self:_log("Ya está iniciado")
		return
	end

	local lp = getLocalPlayer()
	if not lp then
		warn("[ClickDetection] No LocalPlayer found when starting detection")
		return
	end

	local mouse = lp:GetMouse()
    local clickRemote = ReplicatedStorage:FindFirstChild("PlayerClickEvent")

	-- Conexión para click del mouse
	local mouseConnection = mouse.Button1Down:Connect(function()
		self:_log("Mouse.Button1Down fired at", mouse.X, mouse.Y)
		-- Intento rápido usando mouse.Target (más fiable en algunos casos)
		local targetPart = mouse.Target
		if targetPart then
			local okFind, targetPlayer = pcall(function()
				return self:_findPlayerFromPart(targetPart)
			end)
			if okFind and targetPlayer then
				self:_log("Mouse.Target detected player:", targetPlayer.Name)
				for _, callback in ipairs(self._callbacks) do
					task.spawn(function()
						callback(targetPlayer, nil)
					end)
				end
				-- Fire server event if available
				if clickRemote then
					local hitPos = (mouse.Hit and mouse.Hit.p) or nil
					pcall(function()
						clickRemote:FireServer(targetPart, hitPos, tick())
					end)
				end
				return
			end
		end

		local ok, tp, rr = pcall(function()
			return self:_handleClick(mouse.X, mouse.Y)
		end)
		if not ok then
			warn("[ClickDetection] Error handling mouse click:", tp)
			return
		end

		local targetPlayer = tp
		local rayResult = rr
		if targetPlayer then
			-- Fire server event with best-available info
			if clickRemote then
				pcall(function()
					if rayResult and rayResult.Instance then
						clickRemote:FireServer(rayResult.Instance, rayResult.Position, tick())
					else
						-- Fallback: send character and approximate position
						local char = (targetPlayer and targetPlayer.Character) or nil
						local pos = nil
						if char then
							local head = char:FindFirstChild("Head")
							local hrp = char:FindFirstChild("HumanoidRootPart")
							pos = (head and head.Position) or (hrp and hrp.Position) or nil
						end
						clickRemote:FireServer(char, pos, tick())
					end
				end)
			end
		end
	end)
	table.insert(self._connections, mouseConnection)

	-- Conexión para touch
	local touchConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.Touch then
			self:_log("Touch input at", input.Position.X, input.Position.Y)
			local ok, res = pcall(function()
				return self:_handleClick(input.Position.X, input.Position.Y)
			end)
			if not ok then
				warn("[ClickDetection] Error handling touch input:", res)
			end
		end
	end)
	table.insert(self._connections, touchConnection)

	self:_log("Detección iniciada")
end

-- Detener detección
function ClickDetection:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self._connections = {}

	self:_log("Detección detenida")
end

-- Habilitar/deshabilitar temporalmente
function ClickDetection:SetEnabled(enabled)
	self._enabled = enabled
	self:_log("Enabled:", enabled)
end

function ClickDetection:IsEnabled()
	return self._enabled
end

-- Simular click (útil para testing o integración)
function ClickDetection:SimulateClick(screenX, screenY)
	return self:_handleClick(screenX, screenY)
end

-- Actualizar configuración
function ClickDetection:SetConfig(key, value)
	if DEFAULT_CONFIG[key] ~= nil then
		self.Config[key] = value
		self:_log("Config actualizada:", key, "=", value)
	else
		warn("[ClickDetection] Config key no válida:", key)
	end
end

function ClickDetection:GetConfig(key)
	return self.Config[key]
end

-- Destruir el módulo
function ClickDetection:Destroy()
	self:Stop()
	self._callbacks = {}
	self:_log("Destruido")
end

-- ═══════════════════════════════════════════════════════════════
-- RETORNAR MÓDULO
-- ═══════════════════════════════════════════════════════════════

return ClickDetection