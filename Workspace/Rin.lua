local v1 = game:GetService("Players")
local v2 = workspace:WaitForChild("Rings")
local v3 = v2:WaitForChild("Funciones")
local v4 = v3:WaitForChild("Animations")
local v5 = v4:WaitForChild("Heating")

local v6 = Color3.fromRGB(96, 35, 209)
local v7 = Color3.fromRGB(0, 255, 0)
local v8 = Color3.fromRGB(255, 0, 0)

---------------------------------------------------
-- UTILIDADES
---------------------------------------------------
local function v9(v10, v11)
	for _, v12 in ipairs(v10:GetChildren()) do
		if v12:IsA("Beam") then
			v12.Color = ColorSequence.new(v11)
		end
	end
end

local function v13(v14, v15)
	local v16 = v14:FindFirstChildOfClass("Humanoid")
	if v16 then
		if v15 then
			v16.WalkSpeed = 16
			v16.JumpPower = 50
		else
			v16.WalkSpeed = 0
			v16.JumpPower = 0
		end
	end
end

local function v17(v18)
	if not v18 or not v18.Parent then return end

	local v19 = v18:FindFirstChildOfClass("Humanoid")
	if not v19 then return end

	local v20 = v19:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", v19)

	-- Detener TODAS las animaciones antes de cargar una nueva
	for _, v21 in ipairs(v20:GetPlayingAnimationTracks()) do
		pcall(function()
			v21:Stop()
		end)
	end

	-- Validar que la animación exista
	if not v5 or not v5.Parent then
		warn("Animación Heating no encontrada")
		return
	end

	local v22 = v20:LoadAnimation(v5)
	v22.Looped = false

	v13(v18, false)
	v22:Play()
	v22.Stopped:Wait()
	v13(v18, true)
end

---------------------------------------------------
-- RING LOGIC MEJORADO
---------------------------------------------------

local function v23(v24)
	print("[Rin.lua] v23: Inicializando ring: " .. v24.Name)
	
	-- Proteger cada WaitForChild
	local v25 = v24:WaitForChild("PlayerQueueZones", 10)
	if not v25 then print("[ERROR] PlayerQueueZones no encontrado en " .. v24.Name); return end
	
	local v26 = v24:WaitForChild("Players", 10)
	if not v26 then print("[ERROR] Players no encontrado en " .. v24.Name); return end

	local v27 = v25:WaitForChild("PlayerQueueZone1", 10)
	if not v27 then print("[ERROR] PlayerQueueZone1 no encontrado"); return end
	
	local v28 = v25:WaitForChild("PlayerQueueZone2", 10)
	if not v28 then print("[ERROR] PlayerQueueZone2 no encontrado"); return end

	local v29 = v27:WaitForChild("Player1AppearancePart", 10)
	if not v29 then print("[ERROR] Player1AppearancePart no encontrado"); return end
	
	local v30 = v28:WaitForChild("Player2AppearancePart", 10)
	if not v30 then print("[ERROR] Player2AppearancePart no encontrado"); return end

	local v31 = v26:WaitForChild("Player1", 10)
	if not v31 then print("[ERROR] Player1 no encontrado"); return end
	
	local v32 = v26:WaitForChild("Player2", 10)
	if not v32 then print("[ERROR] Player2 no encontrado"); return end

	local v33 = v24:WaitForChild("Player1Teleport", 10)
	if not v33 then print("[ERROR] Player1Teleport no encontrado"); return end
	
	local v34 = v24:WaitForChild("Player2Teleport", 10)
	if not v34 then print("[ERROR] Player2Teleport no encontrado"); return end
	
	-- Obtener Return1 (pero no es crítico si no existe - usaremos fallback)
	local v35 = v24:FindFirstChild("Return1")
	if not v35 then
		print("Info: Return1 no encontrado en " .. v24.Name .. ". Se usarán posiciones alternativas para teletransporte.")
	else
		print("[Rin.lua] v23: Return1 encontrado en " .. v24.Name)
	end

	local v36 = v29
	local v37 = v30

	local v38 = false -- pelea en preparación
	local v39 = false -- pelea en progreso
	local v40 = nil   -- timer de pelea

	local v41 = {} -- control de padres
	local v42 = {} -- conteo zona 1
	local v43 = {} -- conteo zona 2

	---------------------------------------------------
	-- FIN PELEA
	---------------------------------------------------
	local function v44()
		if not v39 then return end -- Evitar múltiples ejecuciones
		v39 = false
		v38 = false

		v31:ClearAllChildren()
		v32:ClearAllChildren()

		v9(v36, v6)
		v9(v37, v6)

		if v40 then
			pcall(function()
				task.cancel(v40)
			end)
			v40 = nil
		end
	end

	local function v45(v46, v47)
		if not v46 or not v46.Parent then return end

		local v48 = v46:FindFirstChildOfClass("Humanoid")
		if not v48 then return end

		v48.Died:Once(function()
			print("[Rin.lua] Muerte detectada - Iniciando teleport del ganador")
			if not v39 then 
				print("[Rin.lua] Pelea no está activa, cancelando teleport")
				return 
			end

			-- Esperar a que el servidor procese la muerte completamente
			task.wait(0.5)

			-- VALIDAR que el ganador aún existe
			if not v47 or not v47.Parent then
				warn("[Rin.lua] Ganador no existe o fue removido")
				v44()
				return
			end

			-- Obtener humanoid del ganador para verificar que está vivo
			local winnerHumanoid = v47:FindFirstChildOfClass("Humanoid")
			if not winnerHumanoid or winnerHumanoid.Health <= 0 then
				warn("[Rin.lua] Ganador no tiene humanoid o está muerto")
				v44()
				return
			end

			-- DETERMINAR posición de teleport con fallback
			local teleportPos = nil
			local positionSource = "unknown"
			
			if v35 and v35.Parent then
				teleportPos = v35.Position + Vector3.new(0, 10, 0) -- +10 para evitar clipping
				positionSource = "Return1"
			elseif v31 and v31.Parent then
				teleportPos = v31.Position + Vector3.new(0, 10, 0)
				positionSource = "Player1"
			elseif v32 and v32.Parent then
				teleportPos = v32.Position + Vector3.new(0, 10, 0)
				positionSource = "Player2"
			else
				warn("[Rin.lua] ERROR CRÍTICO: No hay posición válida de teleport")
				v44()
				return
			end

			print("[Rin.lua] Teletransportando ganador usando: " .. positionSource)
			print("[Rin.lua] Posición destino: " .. tostring(teleportPos))

			-- MÉTODO 1: WaitForChild para garantizar que existe (con timeout)
			local success = pcall(function()
				local hrp = v47:WaitForChild("HumanoidRootPart", 2)
				if hrp then
					-- Desactivar físicas temporalmente
					hrp.Anchored = true
					
					-- Teletransportar con CFrame completo (incluye rotación)
					hrp.CFrame = CFrame.new(teleportPos) * CFrame.Angles(0, math.rad(180), 0)
					
					-- Esperar un frame para el sync
					task.wait(0.1)
					
					-- Reactivar físicas
					hrp.Anchored = false
					hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					
					print("[Rin.lua] ✓ Teleport exitoso a " .. positionSource)
				end
			end)

			if not success then
				warn("[Rin.lua] ✗ Falló el teleport del ganador")
			end

			-- Limpiar ring
			task.wait(0.5)
			v44()
		end)
	end

	local function v49(v50, v51)
		v40 = task.delay(40, function()
			if not v39 then return end
			print("[Rin.lua] Timeout de 40s alcanzado - Expulsando ambos jugadores")

			-- Obtener posición de teletransporte con fallback
			local teleportPos = nil
			local positionSource = "unknown"
			
			if v35 and v35.Parent then
				teleportPos = v35.Position + Vector3.new(0, 10, 0)
				positionSource = "Return1"
			elseif v31 and v31.Parent then
				teleportPos = v31.Position + Vector3.new(0, 10, 0)
				positionSource = "Player1"
			elseif v32 and v32.Parent then
				teleportPos = v32.Position + Vector3.new(0, 10, 0)
				positionSource = "Player2"
			else
				warn("[Rin.lua] ERROR: No hay posición válida para timeout")
				v44()
				return
			end

			print("[Rin.lua] Teletransporte timeout usando: " .. positionSource)

			-- Teletransportar jugador 1
			if v50 and v50.Parent then
				pcall(function()
					local hrp = v50:WaitForChild("HumanoidRootPart", 2)
					if hrp then
						hrp.Anchored = true
						hrp.CFrame = CFrame.new(teleportPos)
						task.wait(0.1)
						hrp.Anchored = false
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						print("[Rin.lua] ✓ Player1 teletransportado (timeout)")
					end
				end)
			end
			
			-- Teletransportar jugador 2 (offset lateral para evitar superposición)
			if v51 and v51.Parent then
				pcall(function()
					local hrp = v51:WaitForChild("HumanoidRootPart", 2)
					if hrp then
						hrp.Anchored = true
						hrp.CFrame = CFrame.new(teleportPos + Vector3.new(5, 0, 0))
						task.wait(0.1)
						hrp.Anchored = false
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						print("[Rin.lua] ✓ Player2 teletransportado (timeout)")
					end
				end)
			end

			v44()
		end)
	end

	---------------------------------------------------
	-- INICIAR PELEA
	---------------------------------------------------
	local function v52(v53, v54)
		if v38 or v39 then return end -- No iniciar si ya hay pelea
		v38 = true

		local startTime = tick()
		while tick() - startTime < 4 do
			if not v31:FindFirstChild(v53.Name) or not v32:FindFirstChild(v54.Name) then
				v38 = false
				return
			end
			task.wait(0.1)
		end

		-- Validar que ambos existan y tengan humanoid
		if not v53 or not v53.Parent or not v54 or not v54.Parent then
			v38 = false
			return
		end

		local h53 = v53:FindFirstChildOfClass("Humanoid")
		local h54 = v54:FindFirstChildOfClass("Humanoid")
		if not h53 or not h54 then
			v38 = false
			return
		end

		v53:PivotTo(v33.CFrame)
		v54:PivotTo(v34.CFrame)

		v39 = true
		v9(v36, v8)
		v9(v37, v8)

		task.spawn(function() v17(v53) end)
		task.spawn(function() v17(v54) end)

		v45(v53, v54)
		v45(v54, v53)
		v49(v53, v54)
	end

	---------------------------------------------------
	-- CONTROL DE ZONAS
	---------------------------------------------------
	local function v55(v56, v57)
		if v39 then return false end
		if #v56:GetChildren() == 0 then
			v41[v57] = v57.Parent
			v57.Parent = v56
			return true
		end
		return false
	end

	local function v58(v59, v60, v61)
		if v41[v60] then
			v60.Parent = v41[v60]
			v41[v60] = nil
			if not v39 then
				v9(v61, v6)
			end
		end
	end

	local function v62()
		if #v31:GetChildren() > 0 and #v32:GetChildren() > 0 then
			v52(v31:GetChildren()[1], v32:GetChildren()[1])
		end
	end

	---------------------------------------------------
	-- EVENTOS ZONA 1
	---------------------------------------------------
	v29.Touched:Connect(function(v63)
		if v39 then return end
		local v64 = v63.Parent
		if not v64:FindFirstChild("Humanoid") then return end
		local v65 = v1:GetPlayerFromCharacter(v64)
		if not v65 then return end

		v42[v65] = (v42[v65] or 0) + 1
		if v32:FindFirstChild(v64.Name) then return end

		if v55(v31, v64) then
			v9(v36, v7)
			v62()
		end
	end)

	v29.TouchEnded:Connect(function(v66)
		local v67 = v66.Parent
		local v68 = v1:GetPlayerFromCharacter(v67)
		if not v68 then return end

		v42[v68] = (v42[v68] or 0) - 1
		if v42[v68] <= 0 then
			v42[v68] = nil

			-- Si está en pelea, no remover
			if not v39 then
				v58(v31, v67, v36)
				if v38 and not v39 then
					v38 = false
				end
			end
		end
	end)

	---------------------------------------------------
	-- EVENTOS ZONA 2
	---------------------------------------------------
	v30.Touched:Connect(function(v69)
		if v39 then return end
		local v70 = v69.Parent
		if not v70:FindFirstChild("Humanoid") then return end
		local v71 = v1:GetPlayerFromCharacter(v70)
		if not v71 then return end

		v43[v71] = (v43[v71] or 0) + 1
		if v31:FindFirstChild(v70.Name) then return end

		if v55(v32, v70) then
			v9(v37, v7)
			v62()
		end
	end)

	v30.TouchEnded:Connect(function(v72)
		local v73 = v72.Parent
		local v74 = v1:GetPlayerFromCharacter(v73)
		if not v74 then return end

		v43[v74] = (v43[v74] or 0) - 1
		if v43[v74] <= 0 then
			v43[v74] = nil

			-- Si está en pelea, no remover
			if not v39 then
				v58(v32, v73, v37)
				if v38 and not v39 then
					v38 = false
				end
			end
		end
	end)
end

---------------------------------------------------
-- INICIALIZAR TODOS LOS RINGS
---------------------------------------------------
print("[Rin.lua] Iniciando carga de rings...")
local ringsFound = 0
for _, v75 in ipairs(v2:GetChildren()) do
	print("[Rin.lua] Encontrado child: " .. v75.Name .. " (IsModel: " .. tostring(v75:IsA("Model")) .. ")")
	if v75:IsA("Model") then
		print("[Rin.lua] Inicializando ring: " .. v75.Name)
		ringsFound = ringsFound + 1
		v23(v75)
	end
end
print("[Rin.lua] Total rings inicializados: " .. ringsFound)

