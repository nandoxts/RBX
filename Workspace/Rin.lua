local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent para sincronizar estado del ring
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local CombatFolder = RemotesGlobal:WaitForChild("Combat")
local ringStateRemote = CombatFolder:WaitForChild("RingStateRemote") or Instance.new("RemoteEvent")
ringStateRemote.Name = "RingStateRemote"
ringStateRemote.Parent = CombatFolder

local RingsWorkspace = workspace:WaitForChild("Rings")
local Funciones = RingsWorkspace:WaitForChild("Funciones")
local Animations = Funciones:WaitForChild("Animations")
local HeatingAnim = Animations:WaitForChild("Heating")

local COLOR_WAITING = Color3.fromRGB(96, 35, 209)  -- Morado: esperando
local COLOR_READY = Color3.fromRGB(0, 255, 0)      -- Verde: listo
local COLOR_FIGHTING = Color3.fromRGB(255, 0, 0)   -- Rojo: peleando

---------------------------------------------------
-- UTILIDADES
---------------------------------------------------
local function changeBeamColor(appearancePart, color)
	for _, beam in ipairs(appearancePart:GetChildren()) do
		if beam:IsA("Beam") then
			beam.Color = ColorSequence.new(color)
		end
	end
end

local function setMovement(character, enabled)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if enabled then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		else
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
end

local function playHeatingAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoid)

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation == HeatingAnim then
			track:Stop()
		end
	end

	local animTrack = animator:LoadAnimation(HeatingAnim)
	animTrack.Looped = false

	setMovement(character, false)
	animTrack:Play()
	animTrack.Stopped:Wait()
	setMovement(character, true)
end

---------------------------------------------------
-- VERSIÓN ULTRA-SIMPLE (SOLO DESHABILITA VUELO)
---------------------------------------------------
local function createAntiEscapeZone(ring, player1Char, player2Char, teleport1Pos, teleport2Pos)
	print("[Ring] ✓ Solo deshabilitando vuelo - SIN anti-escape")

	-- Deshabilitar vuelo
	local function disableFlying(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		end
	end

	local function enableFlying(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
		end
	end

	-- Aplicar
	disableFlying(player1Char)
	disableFlying(player2Char)

	-- Thread simple - solo esperar a que termine
	local antiEscapeThread = task.spawn(function()
		while player1Char and player2Char and player1Char.Parent and player2Char.Parent do
			task.wait(1)
			-- NO hace nada más - solo espera
		end

		-- Restaurar vuelo al terminar
		enableFlying(player1Char)
		enableFlying(player2Char)
		print("[Ring] ✓ Vuelo restaurado")
	end)

	return antiEscapeThread
end

---------------------------------------------------
-- SISTEMA DE NOTIFICACIÓN CON DEBOUNCE (ANTI-SPAM)
---------------------------------------------------
-- Este sistema evita notificaciones molestas cuando alguien:
-- - Pasa rápidamente por encima de las zonas
-- - Entra y sale repetidamente
-- 
-- DELAYS:
-- - WAITING: 1.5 segundos (solo notifica si se queda en la zona)
-- - FREE: 0.5 segundos (pequeño delay al salir)
-- - FIGHTING: INMEDIATO (sin delay)
---------------------------------------------------
local pendingNotifications = {}  -- {[playerUserId] = {state, thread}}

local function notifyPlayerState(player, newState, immediate)
	if not player then return end

	local userId = player.UserId

	-- Cancelar notificación pendiente anterior
	if pendingNotifications[userId] then
		task.cancel(pendingNotifications[userId].thread)
		pendingNotifications[userId] = nil
	end

	-- Verificar si ya fue notificado (evitar duplicados)
	local lastNotification = player:GetAttribute("LastRingNotification")

	if lastNotification == newState then
		return  -- Ya fue notificado de este estado
	end

	-- FIGHTING siempre es inmediato
	if newState == "FIGHTING" or immediate then
		ringStateRemote:FireClient(player, newState)
		player:SetAttribute("LastRingNotification", newState)
		print("[Ring] Notificacion:", player.Name, "→", newState)
		return
	end

	-- Para WAITING y FREE: delay para evitar spam
	local delay = (newState == "WAITING") and 1.5 or 0.5

	pendingNotifications[userId] = {
		state = newState,
		thread = task.delay(delay, function()
			-- Verificar que el estado sigue siendo relevante
			local currentNotification = player:GetAttribute("LastRingNotification")
			if currentNotification ~= newState then
				ringStateRemote:FireClient(player, newState)
				player:SetAttribute("LastRingNotification", newState)
				print("[Ring] Notificacion (delayed):", player.Name, "→", newState)
			end
			pendingNotifications[userId] = nil
		end)
	}
end

---------------------------------------------------
-- RING LOGIC
---------------------------------------------------
local function initializeRing(ring)
	local PlayerQueueZones = ring:WaitForChild("PlayerQueueZones")
	local PlayersContainer = ring:WaitForChild("Players")

	local Zone1 = PlayerQueueZones:WaitForChild("PlayerQueueZone1")
	local Zone2 = PlayerQueueZones:WaitForChild("PlayerQueueZone2")

	local Appearance1 = Zone1:WaitForChild("Player1AppearancePart")
	local Appearance2 = Zone2:WaitForChild("Player2AppearancePart")

	local Player1Container = PlayersContainer:WaitForChild("Player1")
	local Player2Container = PlayersContainer:WaitForChild("Player2")

	local Teleport1 = ring:WaitForChild("Player1Teleport")
	local Teleport2 = ring:WaitForChild("Player2Teleport")
	local ReturnPoint = ring:WaitForChild("Return1")

	local preparingFight = false
	local fightActive = false
	local fightTimer = nil
	local antiEscapeThread = nil

	local parentBackup = {}
	local touchCount1 = {}
	local touchCount2 = {}

	-- Limpiar notificaciones pendientes cuando jugador se desconecta
	local cleanupConnection = Players.PlayerRemoving:Connect(function(player)
		if pendingNotifications[player.UserId] then
			task.cancel(pendingNotifications[player.UserId].thread)
			pendingNotifications[player.UserId] = nil
		end
	end)

	---------------------------------------------------
	-- FIN DE PELEA
	---------------------------------------------------
	local function endFight(reason)
		-- ═══════════════════════════════════════════════════════════
		-- DEBUG: Rastrear exactamente por qué termina la pelea
		-- ═══════════════════════════════════════════════════════════
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("[Ring] endFight() llamado")
		print("[Ring] Razón:", reason or "DESCONOCIDA")
		print("[Ring] fightActive ANTES:", fightActive)
		print("[Ring] preparingFight ANTES:", preparingFight)
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

		if not fightActive then 
			print("[Ring] ⚠️ WARNING: endFight llamado pero fightActive = false")
			print("[Ring] Stack trace disponible en logs")
			return 
		end

		fightActive = false
		preparingFight = false

		-- 1. CANCELAR ANTI-ESCAPE (esto restaura el vuelo)
		if antiEscapeThread then
			task.cancel(antiEscapeThread)
			antiEscapeThread = nil
			print("[Ring] Anti-escape cancelado")
		end

		-- 2. OBTENER JUGADORES
		local char1 = Player1Container:FindFirstChildOfClass("Model")
		local char2 = Player2Container:FindFirstChildOfClass("Model")

		print("[Ring] Char1:", char1 and char1.Name or "nil")
		print("[Ring] Char2:", char2 and char2.Name or "nil")

		local player1 = char1 and Players:GetPlayerFromCharacter(char1)
		local player2 = char2 and Players:GetPlayerFromCharacter(char2)

		-- 3. RESTAURAR VUELO MANUALMENTE (por si acaso)
		if char1 then
			local hum1 = char1:FindFirstChildOfClass("Humanoid")
			if hum1 then
				hum1:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
				print("[Ring] Vuelo restaurado para char1")
			end
		end
		if char2 then
			local hum2 = char2:FindFirstChildOfClass("Humanoid")
			if hum2 then
				hum2:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
				print("[Ring] Vuelo restaurado para char2")
			end
		end

		-- 4. CANCELAR NOTIFICACIONES PENDIENTES
		if player1 and pendingNotifications[player1.UserId] then
			task.cancel(pendingNotifications[player1.UserId].thread)
			pendingNotifications[player1.UserId] = nil
		end
		if player2 and pendingNotifications[player2.UserId] then
			task.cancel(pendingNotifications[player2.UserId].thread)
			pendingNotifications[player2.UserId] = nil
		end

		-- 5. MOVER A RETURN POINT
		if char1 and char1:FindFirstChild("HumanoidRootPart") then
			char1.Parent = workspace
			char1:PivotTo(ReturnPoint.CFrame * CFrame.new(2, 0, 0))
			print("[Ring] Char1 movido a ReturnPoint")
		end

		if char2 and char2:FindFirstChild("HumanoidRootPart") then
			char2.Parent = workspace
			char2:PivotTo(ReturnPoint.CFrame * CFrame.new(-2, 0, 0))
			print("[Ring] Char2 movido a ReturnPoint")
		end

		-- 6. ESPERAR Y NOTIFICAR FREE (con delay corto)
		task.wait(0.2)
		if player1 then 
			notifyPlayerState(player1, "FREE")
		end
		if player2 then 
			notifyPlayerState(player2, "FREE")
		end

		-- 7. LIMPIAR CONTENEDORES
		Player1Container:ClearAllChildren()
		Player2Container:ClearAllChildren()
		print("[Ring] Contenedores limpiados")

		-- 8. RESTAURAR COLORES
		changeBeamColor(Appearance1, COLOR_WAITING)
		changeBeamColor(Appearance2, COLOR_WAITING)

		-- 9. CANCELAR TIMER
		if fightTimer then
			task.cancel(fightTimer)
			fightTimer = nil
			print("[Ring] Timer de pelea cancelado")
		end

		print("[Ring] ✅ Pelea finalizada correctamente")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	end

	---------------------------------------------------
	-- DETECCIÓN DE MUERTE
	---------------------------------------------------
	local function setupDeathDetection(attacker, victim)
		local humanoid = attacker:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		humanoid.Died:Once(function()
			if not fightActive then return end
			print("[Ring] Jugador murio:", attacker.Name)

			-- Mover ganador ANTES de terminar pelea
			if victim and victim.Parent then
				victim.Parent = workspace
				victim:PivotTo(ReturnPoint.CFrame)
			end

			task.wait(0.1)
			endFight("muerte")
		end)
	end

	---------------------------------------------------
	-- SIN TIMER - PELEA HASTA LA MUERTE
	---------------------------------------------------
	local function startFightTimer(char1, char2)
		print("[Ring] ✓ Pelea sin límite de tiempo - Solo termina por muerte")

		-- NO crear timer - la pelea solo termina cuando alguien muere
		fightTimer = nil
	end

	---------------------------------------------------
	-- INICIAR PELEA
	---------------------------------------------------
	local function startFight(char1, char2)
		if preparingFight or fightActive then return end
		preparingFight = true

		print("[Ring] Iniciando pelea:", char1.Name, "vs", char2.Name)

		-- Esperar 4 segundos de cuenta regresiva
		local startTime = tick()
		while tick() - startTime < 4 do
			-- Solo verificar durante la cuenta regresiva
			if not Player1Container:FindFirstChild(char1.Name) or 
				not Player2Container:FindFirstChild(char2.Name) then
				print("[Ring] Alguien salio durante cuenta regresiva")
				preparingFight = false
				return
			end
			task.wait(0.1)
		end

		-- ═══════════════════════════════════════════════════════════
		-- IMPORTANTE: Una vez que llegamos aquí, la pelea está CONFIRMADA
		-- Ya NO verificamos más si salen de los contenedores
		-- ═══════════════════════════════════════════════════════════

		-- Activar pelea ANTES de teleportar (importante)
		fightActive = true

		-- Teleportar a posiciones de pelea
		local teleport1Pos = Teleport1.Position
		local teleport2Pos = Teleport2.Position

		char1:PivotTo(Teleport1.CFrame)
		char2:PivotTo(Teleport2.CFrame)

		-- Cambiar colores
		changeBeamColor(Appearance1, COLOR_FIGHTING)
		changeBeamColor(Appearance2, COLOR_FIGHTING)

		-- Notificar FIGHTING (INMEDIATO - sin delay)
		local player1 = Players:GetPlayerFromCharacter(char1)
		local player2 = Players:GetPlayerFromCharacter(char2)

		if player1 then notifyPlayerState(player1, "FIGHTING", true) end
		if player2 then notifyPlayerState(player2, "FIGHTING", true) end

		-- Animaciones
		task.spawn(function() playHeatingAnimation(char1) end)
		task.spawn(function() playHeatingAnimation(char2) end)

		-- Anti-escape con posiciones dinámicas
		antiEscapeThread = createAntiEscapeZone(ring, char1, char2, teleport1Pos, teleport2Pos)

		-- Detección de muerte
		setupDeathDetection(char1, char2)
		setupDeathDetection(char2, char1)

		-- Timer de pelea
		startFightTimer(char1, char2)

		print("[Ring] PELEA ACTIVA - Ya no se verifica si salen de contenedores")
	end

	---------------------------------------------------
	-- CONTROL DE ZONAS
	---------------------------------------------------
	local function addToZone(container, character)
		if fightActive then return false end
		if #container:GetChildren() == 0 then
			parentBackup[character] = character.Parent
			character.Parent = container
			return true
		end
		return false
	end

	local function removeFromZone(container, character, appearance)
		if parentBackup[character] then
			-- NO restaurar si está en pelea
			if not fightActive then
				character.Parent = parentBackup[character]
				parentBackup[character] = nil
				changeBeamColor(appearance, COLOR_WAITING)
			end
		end
	end

	local function tryMatchPlayers()
		if #Player1Container:GetChildren() > 0 and #Player2Container:GetChildren() > 0 then
			startFight(Player1Container:GetChildren()[1], Player2Container:GetChildren()[1])
		end
	end

	---------------------------------------------------
	-- ZONA 1: TOUCHED/TOUCHENDED (ORIGINAL)
	---------------------------------------------------
	Appearance1.Touched:Connect(function(hit)
		if fightActive then return end

		local character = hit.Parent
		if not character:FindFirstChild("Humanoid") then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		touchCount1[player] = (touchCount1[player] or 0) + 1

		if Player2Container:FindFirstChild(character.Name) then return end

		if addToZone(Player1Container, character) then
			changeBeamColor(Appearance1, COLOR_READY)

			-- Notificar WAITING (UNA SOLA VEZ)
			notifyPlayerState(player, "WAITING")

			print("[Ring] Player1 en espera:", character.Name)
			tryMatchPlayers()
		end
	end)

	Appearance1.TouchEnded:Connect(function(hit)
		-- CRÍTICO: NO procesar si hay pelea activa
		if fightActive then 
			-- DEBUG: Registrar si esto se dispara durante pelea
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				print("[Ring] ⚠️ TouchEnded disparado durante pelea activa para:", character.Name)
			end
			return 
		end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		touchCount1[player] = math.max(0, (touchCount1[player] or 1) - 1)

		if touchCount1[player] == 0 then
			removeFromZone(Player1Container, character, Appearance1)

			-- Notificar FREE
			notifyPlayerState(player, "FREE")

			print("[Ring] Player1 salio:", character.Name)

			-- Solo cancelar preparación si no hay pelea activa
			if preparingFight and not fightActive then
				preparingFight = false
				print("[Ring] Preparacion cancelada - Player1 salio")
			end
		end
	end)

	---------------------------------------------------
	-- ZONA 2: TOUCHED/TOUCHENDED (ORIGINAL)
	---------------------------------------------------
	Appearance2.Touched:Connect(function(hit)
		if fightActive then return end

		local character = hit.Parent
		if not character:FindFirstChild("Humanoid") then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		touchCount2[player] = (touchCount2[player] or 0) + 1

		if Player1Container:FindFirstChild(character.Name) then return end

		if addToZone(Player2Container, character) then
			changeBeamColor(Appearance2, COLOR_READY)

			-- Notificar WAITING (UNA SOLA VEZ)
			notifyPlayerState(player, "WAITING")

			print("[Ring] Player2 en espera:", character.Name)
			tryMatchPlayers()
		end
	end)

	Appearance2.TouchEnded:Connect(function(hit)
		-- CRÍTICO: NO procesar si hay pelea activa
		if fightActive then 
			-- DEBUG: Registrar si esto se dispara durante pelea
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				print("[Ring] ⚠️ TouchEnded disparado durante pelea activa para:", character.Name)
			end
			return 
		end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		touchCount2[player] = math.max(0, (touchCount2[player] or 1) - 1)

		if touchCount2[player] == 0 then
			removeFromZone(Player2Container, character, Appearance2)

			-- Notificar FREE
			notifyPlayerState(player, "FREE")

			print("[Ring] Player2 salio:", character.Name)

			-- Solo cancelar preparación si no hay pelea activa
			if preparingFight and not fightActive then
				preparingFight = false
				print("[Ring] Preparacion cancelada - Player2 salio")
			end
		end
	end)
end

---------------------------------------------------
-- INICIALIZAR TODOS LOS RINGS
---------------------------------------------------
for _, ring in ipairs(RingsWorkspace:GetChildren()) do
	if ring:IsA("Model") then
		task.spawn(function()
			initializeRing(ring)
		end)
	end
end