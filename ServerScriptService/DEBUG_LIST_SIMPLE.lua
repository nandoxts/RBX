-- ============================================
-- DEBUG SIMPLE - LISTAR CLANES
-- ============================================
print("\n" .. string.rep("=", 100))
print("📊 DEBUG SIMPLE - LISTAR TODOS LOS CLANES")
print(string.rep("=", 100) .. "\n")

local clanStore = game:GetService("DataStoreService"):GetDataStore("ClansData_v2")
local HttpService = game:GetService("HttpService")

-- Intentar listar
print("🔍 Llamando a ListKeysAsync...")

local success, pages = pcall(function()
	return clanStore:ListKeysAsync("clan:")
end)

print("Success: " .. tostring(success))
print("Pages type: " .. type(pages))
print("Pages: " .. tostring(pages))

if success and pages then
	print("\n📄 Propiedades de pages:")
	print("  IsFinished: " .. tostring(pages.IsFinished))
	print("  GetCurrentPage type: " .. type(pages.GetCurrentPage))
	
	print("\n🔄 Llamando GetCurrentPage()...")
	local keys = pages:GetCurrentPage()
	print("Keys type: " .. type(keys))
	print("Keys count: " .. #keys)
	print("Keys: " .. HttpService:JSONEncode(keys))
	
	if #keys > 0 then
		print("\n✅ Se encontraron clanes:")
		for i, key in ipairs(keys) do
			print("  [" .. i .. "] " .. tostring(key))
		end
	else
		print("\n❌ No se encontraron clanes en la primera página")
	end
else
	print("\n❌ Error en ListKeysAsync")
end

print("\n" .. string.rep("=", 100) .. "\n")
