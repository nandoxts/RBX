-- ============================================
-- DEBUG LEER TODOS LOS CLANES DE LA BD
-- ============================================
print("\n" .. string.rep("=", 100))
print("📊 LEYENDO TODOS LOS CLANES DIRECTAMENTE DE LA BD")
print(string.rep("=", 100) .. "\n")

local clanStore = game:GetService("DataStoreService"):GetDataStore("ClansData_v2")
local HttpService = game:GetService("HttpService")

-- Leer el índice primero
local indexStore = game:GetService("DataStoreService"):GetDataStore("ClansIndex_v1")
local indexSuccess, indexData = pcall(function()
	return indexStore:GetAsync("clans_index")
end)

local indexedClans = {}
local indexedCount = 0
if indexSuccess and indexData and indexData.clans then
	for clanId, _ in pairs(indexData.clans) do
		indexedClans[clanId] = true
		indexedCount = indexedCount + 1
	end
end

print("✅ Índice cargado. Clanes indexados: " .. indexedCount .. "\n")
print(string.rep("=", 100))
print("🏰 TODOS LOS CLANES EN LA BD (usando ListKeysAsync mejorado)")
print(string.rep("=", 100) .. "\n")

-- Leer todos con ListKeysAsync sin cursor problemático
local allClans = {}

local success, pages = pcall(function()
	return clanStore:ListKeysAsync("clan:")
end)

if success then
	while pages do
		local keys = pages:GetCurrentPage()
		
		for _, keyInfo in ipairs(keys) do
			-- keyInfo es un DataStoreKey, el nombre está en tostring
			local keyName = tostring(keyInfo)
			local clanId = keyName:gsub("^clan:", "")
			
			-- Leer datos del clan
			local clanSuccess, clanData = pcall(function()
				return clanStore:GetAsync(keyName)
			end)
			
			if clanSuccess and clanData then
				local isIndexed = indexedClans[clanId] and "✅" or "❌"
				local clanName = clanData.clanName or clanData.clanId or "SIN NOMBRE"
				local clanTag = clanData.clanTag or "N/A"
				
				print("\n" .. isIndexed .. " [" .. clanName .. " - " .. clanTag .. "]")
				print("   ID: " .. clanId)
				print("   Dueño: " .. tostring(clanData.owner or clanData.dueno or "DESCONOCIDO"))
				print("   Descripción: " .. (clanData.descripcion or clanData.description or "N/A"))
				
				-- Contar miembros
				local memberCount = 0
				if clanData.miembros_data then
					for _ in pairs(clanData.miembros_data) do
						memberCount = memberCount + 1
					end
				end
				print("   Miembros: " .. memberCount)
				
				-- Mostrar JSON
				print("   📄 JSON: " .. HttpService:JSONEncode(clanData))
				
				table.insert(allClans, {
					id = clanId,
					name = clanName,
					tag = clanTag,
					indexed = indexedClans[clanId] ~= nil,
					data = clanData
				})
			end
		end
		
		-- Pasar a la siguiente página
		if pages.IsFinished then
			break
		end
		pages:AdvanceToNextPageAsync()
	end
else
	warn("Error al listar clanes: " .. tostring(pages))
end

print("\n\n" .. string.rep("=", 100))
print("📊 RESUMEN FINAL")
print(string.rep("=", 100))
print("\nTotal de clanes en BD: " .. #allClans)

local indexedCount = 0
local orphanCount = 0
for _, clan in ipairs(allClans) do
	if clan.indexed then
		indexedCount = indexedCount + 1
	else
		orphanCount = orphanCount + 1
	end
end

print("✅ Clanes indexados: " .. indexedCount)
print("❌ Clanes orphaned (no indexados): " .. orphanCount)

if orphanCount > 0 then
	print("\n⚠️ CLANES ORPHANED ENCONTRADOS:")
	for _, clan in ipairs(allClans) do
		if not clan.indexed then
			print("  • " .. clan.name .. " (" .. clan.tag .. ") - ID: " .. clan.id)
		end
	end
end

print("\n" .. string.rep("=", 100) .. "\n")
