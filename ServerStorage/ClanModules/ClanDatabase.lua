local DataStoreService = game:GetService("DataStoreService")
local ClanDatabase = {}

-- Inicializar DataStore
local clanStore = DataStoreService:GetDataStore("ClansData")
local playerClanStore = DataStoreService:GetDataStore("PlayerClans")

-- Crear un nuevo clan
function ClanDatabase:CreateClan(clanName, ownerId, clanLogo, clanDesc)
	local clanId = tostring(game:GetService("HttpService"):GenerateGUID(false)):sub(1, 12)

	local clanData = {
		clanId = clanId,
		clanName = clanName,
		clanLogo = clanLogo or "rbxassetid://0",
		owner = ownerId,
		colideres = {},
		lideres = {},
		miembros = {ownerId},
		descripcion = clanDesc or "Sin descripción",
		nivel = 1,
		fechaCreacion = os.time(),
		miembros_data = {
			[ownerId] = {
				nombre = game:GetService("Players"):GetNameFromUserIdAsync(ownerId),
				rol = "owner",
				fechaUnion = os.time()
			}
		}
	}

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. ownerId, {clanId = clanId, rol = "owner"})
	end)

	if success then
		return true, clanId, clanData
	else
		return false, err
	end
end

-- Obtener datos del clan
function ClanDatabase:GetClan(clanId)
	local success, data = pcall(function()
		return clanStore:GetAsync("clan:" .. clanId)
	end)

	if success and data then
		return data
	else
		return nil
	end
end

-- Obtener clan del jugador
function ClanDatabase:GetPlayerClan(userId)
	local success, data = pcall(function()
		return playerClanStore:GetAsync("player:" .. userId)
	end)

	if success and data then
		return data
	else
		return nil
	end
end

-- Actualizar clan
function ClanDatabase:UpdateClan(clanId, newData)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Merge de datos
	for k, v in pairs(newData) do
		clanData[k] = v
	end

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
	end)

	if success then
		return true, clanData
	else
		return false, err
	end
end

-- Agregar miembro
function ClanDatabase:AddMember(clanId, userId, rol)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Evitar duplicados
	for _, memberId in pairs(clanData.miembros) do
		if memberId == userId then
			return false, "Ya es miembro del clan"
		end
	end

	table.insert(clanData.miembros, userId)
	clanData.miembros_data[userId] = {
		nombre = game:GetService("Players"):GetNameFromUserIdAsync(userId),
		rol = rol or "miembro",
		fechaUnion = os.time()
	}

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. userId, {clanId = clanId, rol = rol or "miembro"})
	end)

	if success then
		return true, clanData
	else
		return false, err
	end
end

-- Remover miembro
function ClanDatabase:RemoveMember(clanId, userId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	-- Remover de la lista
	for i, memberId in pairs(clanData.miembros) do
		if memberId == userId then
			table.remove(clanData.miembros, i)
			break
		end
	end

	-- Limpiar datos del miembro
	clanData.miembros_data[userId] = nil

	-- Remover de colideres
	for i, id in pairs(clanData.colideres) do
		if id == userId then
			table.remove(clanData.colideres, i)
			break
		end
	end

	-- Remover de lideres
	for i, id in pairs(clanData.lideres) do
		if id == userId then
			table.remove(clanData.lideres, i)
			break
		end
	end

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. userId, nil)
	end)

	if success then
		return true, clanData
	else
		return false, err
	end
end

-- Cambiar rol de miembro
function ClanDatabase:ChangeMemberRole(clanId, userId, newRole)
	local clanData = self:GetClan(clanId)
	if not clanData or not clanData.miembros_data[userId] then
		return false, "Miembro no encontrado"
	end

	local oldRole = clanData.miembros_data[userId].rol

	-- Remover de listas antiguas
	if oldRole == "colider" then
		for i, id in pairs(clanData.colideres) do
			if id == userId then
				table.remove(clanData.colideres, i)
				break
			end
		end
	elseif oldRole == "lider" then
		for i, id in pairs(clanData.lideres) do
			if id == userId then
				table.remove(clanData.lideres, i)
				break
			end
		end
	end

	-- Agregar a lista nueva
	if newRole == "colider" then
		table.insert(clanData.colideres, userId)
	elseif newRole == "lider" then
		table.insert(clanData.lideres, userId)
	end

	-- Actualizar datos
	clanData.miembros_data[userId].rol = newRole

	local success, err = pcall(function()
		clanStore:SetAsync("clan:" .. clanId, clanData)
		playerClanStore:SetAsync("player:" .. userId, {clanId = clanId, rol = newRole})
	end)

	if success then
		return true, clanData
	else
		return false, err
	end
end

-- Disolver clan
function ClanDatabase:DissolveClan(clanId)
	local clanData = self:GetClan(clanId)
	if not clanData then
		return false, "Clan no encontrado"
	end

	local success, err = pcall(function()
		-- Remover de todos los jugadores
		for userId, _ in pairs(clanData.miembros_data) do
			playerClanStore:SetAsync("player:" .. userId, nil)
		end
		-- Remover clan
		clanStore:SetAsync("clan:" .. clanId, nil)
	end)

	if success then
		return true
	else
		return false, err
	end
end

-- Obtener lista de todos los clanes
function ClanDatabase:GetAllClans()
	local allClans = {}

	-- Usar ListKeysAsync para obtener todas las keys del datastore
	local success, result = pcall(function()
		local pages = clanStore:ListKeysAsync()
		print("🔍 [ClanDatabase] Obteniendo lista de clanes...")

		while true do
			local keys = pages:GetCurrentPage()
			print("  - Página con " .. #keys .. " keys encontradas")

			for _, key in ipairs(keys) do
				if key.KeyName:match("^clan:") then
					print("  ✓ Encontrado clan: " .. key.KeyName)
					local clanData = self:GetClan(key.KeyName:gsub("^clan:", ""))
					if clanData then
						-- Contar miembros
						local memberCount = 0
						for _ in pairs(clanData.miembros_data or {}) do
							memberCount = memberCount + 1
						end

						table.insert(allClans, {
							clanId = clanData.clanId,
							clanName = clanData.clanName,
							clanLogo = clanData.clanLogo,
							descripcion = clanData.descripcion or "Sin descripción",
							nivel = clanData.nivel or 1,
							miembros_count = memberCount,
							fechaCreacion = clanData.fechaCreacion
						})
						print("    → Clan cargado: " .. clanData.clanName)
					end
				end
			end

			if pages.IsFinished then
				break
			end

			pages:AdvanceToNextPageAsync()
		end
	end)

	if success then
		print("✅ [ClanDatabase] Se encontraron " .. #allClans .. " clanes en total")
		return allClans
	else
		warn("❌ [ClanDatabase] Error obteniendo lista de clanes:", result)
		return {}
	end
end

return ClanDatabase

