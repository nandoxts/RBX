-- ═══════════════════════════════════════════════════════════
-- RESTAURAR COLISIONES - EJECUTAR EN CONSOLA (F9)
-- Restaura todas las colisiones al estado normal
-- ═══════════════════════════════════════════════════════════

local restauradas = 0

print("🔧 Restaurando colisiones...")

-- Reactivar todas las colisiones
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.CanCollide = true
		obj.CustomPhysicalProperties = nil -- Volver a propiedades por defecto
		restauradas = restauradas + 1
	end
end

-- Reactivar scripts
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("LocalScript") or obj:IsA("Script") then
		obj.Disabled = false
	end
end

-- Resumen
print("✓ COLISIONES RESTAURADAS:")
print("  ├─ Partes reparadas: " .. restauradas)
print("  └─ Todo vuelto a la normalidad")
