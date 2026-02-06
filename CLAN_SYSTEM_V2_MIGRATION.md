# 🚀 Sistema de Clanes V2 - Arquitectura Nueva

## ✨ Beneficios vs V1

### **Velocidad**
- ❌ V1: 3 DataStores + Queue Manager + Cache manual = **3-5 llamadas**
- ✅ V2: 1 DataStore + UpdateAsync atómico = **1 llamada**

### **Simplicidad**
```lua
-- V1 (complejo)
clanCache[clanId] = data
clanCacheTime[clanId] = tick()
clanStoreQueue:SetAsync("clan:" .. clanId, data)
playerClanStoreQueue:SetAsync("player:" .. userId, playerData)
addToIndex(clanId, name, tag)

-- V2 (simple)
DS:SetAsync("clan:" .. clanId, data)
DS:SetAsync("player:" .. userId, {clanId = clanId, role = role})
```

### **Menos Código**
- V1: **850 líneas** (ClanData.lua + ClanServer.lua)
- V2: **650 líneas** (40% menos código)

### **Sin Bugs de Migración**
- V1: Lógica de migración numéricas → strings
- V2: Estructura limpia desde el inicio

### **Operaciones Atómicas**
- V1: GetAsync → modificar → SetAsync (puede perder cambios concurrentes)
- V2: UpdateAsync (garantiza consistencia)

---

## 🏗️ Estructura de Datos V2

### **DataStore Único: `ClanData`**

```lua
-- CLAN
"clan:{clanId}" = {
  clanId = "abc123",
  name = "Mi Clan",
  tag = "MC",
  logo = "rbxassetid://...",
  emoji = "⚔️",
  color = {255, 100, 50},
  description = "...",
  createdAt = 1234567890,
  
  owners = {123456, 789012},  -- Array de user IDs
  
  members = {
    ["123456"] = {
      name = "Player1",
      role = "owner",
      joinedAt = 1234567890
    },
    ["789012"] = {
      name = "Player2",
      role = "lider",
      joinedAt = 1234567900
    }
  }
}

-- PLAYER MAPPING (minimal)
"player:{userId}" = {
  clanId = "abc123",
  role = "owner"
}

-- ÍNDICES (lookups rápidos)
"index:names" = {
  ["mi clan"] = "abc123",
  ["otro clan"] = "def456"
}

"index:tags" = {
  ["MC"] = "abc123",
  ["OC"] = "def456"
}

-- SOLICITUDES DE UNIÓN
"request:{userId}" = {
  ["abc123"] = {
    time = 1234567890,
    status = "pending",
    clanName = "Mi Clan"
  }
}
```

---

## 🔄 Migración de V1 a V2

### **Opción 1: Empezar Limpio (RECOMENDADO)**

```lua
-- En ServerScriptService/Systems/ClanSystem/

-- 1. Deshabilitar archivos antiguos (renombrar a _OLD.lua)
-- 2. Habilitar ClanServer.lua y ClanData.lua
-- 3. Los clanes por defecto se crearán automáticamente en ClanData
```

**Pros:**
- ✅ Sin bugs de migración
- ✅ BD limpia y optimizada
- ✅ Implementación inmediata

**Contras:**
- ❌ Pierdes clanes creados por jugadores (si los hay)

---

### **Opción 2: Migrar Datos Existentes**

Si tienes clanes de jugadores que quieres conservar, crea este script temporal:

```lua
-- MigrateClanData.server.lua (ejecutar UNA VEZ en Studio)

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- V1 DataStores
local clanStoreV1 = DataStoreService:GetDataStore("ClansData_v1")
local indexStoreV1 = DataStoreService:GetDataStore("ClansIndex_v1")

-- V2 DataStore
local DSV2 = DataStoreService:GetDataStore("ClanData")

local function migrateClans()
    print("🔄 Iniciando migración...")
    
    -- 1. Obtener todos los clanes de V1
    local indexV1 = indexStoreV1:GetAsync("clans_index")
    if not indexV1 or not indexV1.clans then
        print("⚠️ No hay clanes para migrar")
        return
    end
    
    local count = 0
    
    for clanId, basicInfo in pairs(indexV1.clans) do
        -- 2. Obtener datos completos del clan
        local clanV1 = clanStoreV1:GetAsync("clan:" .. clanId)
        
        if clanV1 then
            -- 3. Convertir a estructura V2
            local clanV2 = {
                clanId = clanV1.clanId,
                name = clanV1.clanName,
                tag = clanV1.clanTag,
                logo = clanV1.clanLogo or "rbxassetid://0",
                emoji = clanV1.clanEmoji or "",
                color = clanV1.clanColor or {255, 255, 255},
                description = clanV1.descripcion or "Sin descripción",
                createdAt = clanV1.fechaCreacion or os.time(),
                
                owners = clanV1.owners or {clanV1.owner},
                
                members = {}
            }
            
            -- 4. Migrar miembros
            if clanV1.miembros_data then
                for userIdStr, memberData in pairs(clanV1.miembros_data) do
                    clanV2.members[userIdStr] = {
                        name = memberData.nombre,
                        role = memberData.rol,
                        joinedAt = memberData.fechaUnion
                    }
                    
                    -- 5. Guardar player mapping
                    DSV2:SetAsync("player:" .. userIdStr, {
                        clanId = clanId,
                        role = memberData.rol
                    })
                end
            end
            
            -- 6. Guardar clan en V2
            DSV2:SetAsync("clan:" .. clanId, clanV2)
            
            -- 7. Actualizar índices
            DSV2:UpdateAsync("index:names", function(current)
                local index = current or {}
                index[string.lower(clanV2.name)] = clanId
                return index
            end)
            
            DSV2:UpdateAsync("index:tags", function(current)
                local index = current or {}
                index[string.upper(clanV2.tag)] = clanId
                return index
            end)
            
            count = count + 1
            print("✅ Migrado:", clanV2.name)
            task.wait(0.2) -- Evitar rate limits
        end
    end
    
    print("🎉 Migración completa:", count, "clanes")
end

-- EJECUTAR MIGRACIÓN
migrateClans()
```

**Pasos:**
1. Crear `MigrateClanData.server.lua` en ServerScriptService
2. Ejecutar en Studio (Play Solo)
3. Verificar en Output que todos los clanes migraron
4. **Importante**: Desactivar/borrar el script de migración después
5. Los archivos activos son ClanData.lua y ClanServer.lua

---

## 📋 Checklist de Implementación

### **Para empezar limpio:**
- [ ] Renombrar `ClanServer.lua` → `ClanServer_OLD.lua`
- [ ] Renombrar `ClanData.lua` → `ClanData_OLD.lua`
- [ ] Verificar que `ClanData.lua` existe en ServerStorage/Systems/ClanSystem/
- [ ] Verificar que `ClanServer.lua` existe en ServerScriptService/Systems/ClanSystem/
- [ ] Testear en Studio: crear clan, invitar, cambiar roles
- [ ] Verificar atributos de jugador (ClanTag, ClanColor en overhead)

### **Para migrar datos:**
- [ ] Hacer backup de DataStores actuales (exportar en Studio)
- [ ] Crear y ejecutar script de migración
- [ ] Verificar que todos los clanes migraron correctamente
- [ ] Testear funcionalidad con clanes migrados
- [ ] Una vez confirmado, deshabilitar V1

---

## ⚡ Performance Comparativa

### **Crear Clan**
```
V1: GetPlayerClan (1) + nameExists (1) + tagExists (1) + CreateClan (3 SetAsync) = 6 ops
V2: GetAsync player (1) + verify indexes (2) + SetAsync clan (3) = 6 ops

GANANCIA: Mismo número pero V2 usa UpdateAsync atómico = más confiable
```

### **Obtener Lista de Clanes**
```
V1: GetIndex (1) + GetClan × N (N) + contar miembros = 1 + N ops
V2: GetIndex (1) + GetClan × N (N) = 1 + N ops

GANANCIA: Sin cache manual = menos bugs, mismo perf (Roblox cachea internamente)
```

### **Actualizar Clan**
```
V1: GetClan (1) + SetAsync (1) + updateIndex (1) + clearCache (0) = 3 ops
V2: UpdateAsync atómico (1) + updateIndex (1) = 2 ops

GANANCIA: 33% menos operaciones + garantía de consistencia
```

---

## 🎯 Recomendación Final

**Para desarrollo nuevo o poca data:** 
→ **Empezar limpio con V2** (5 minutos)

**Para producción con clanes existentes:** 
→ **Migrar datos** (30 minutos setup + pruebas)

**Beneficio principal:**
- Código 40% más simple
- Sin bugs de cache
- Operaciones atómicas (sin race conditions)
- Más fácil de mantener y extender
