# 📋 ARQUITECTURA DEL SISTEMA DE CLANES

**Versión:** 2.0 (Simplificada)  
**Autor:** by ignxts  
**Fecha de análisis:** 5 de febrero de 2026

---

## 🏗️ ESTRUCTURA GENERAL

```
ClanSystem/
│
├── 📁 ServerStorage/Systems/ClanSystem/
│   ├── ClanData.lua              [CAPA DE DATOS - DataStore]
│   └── ClanData_OLD.lua          [Backup versión anterior]
│
├── 📁 ServerScriptService/Systems/ClanSystem/
│   ├── ClanServer.lua            [HANDLERS DEL SERVIDOR]
│   └── ClanServer_OLD.lua        [Backup versión anterior]
│
├── 📁 ReplicatedStorage/
│   ├── Config/
│   │   └── ClanSystemConfig.lua  [CONFIGURACIÓN GLOBAL]
│   └── Systems/ClanSystem/
│       ├── ClanClient.lua        [CONTROLADOR DEL CLIENTE]
│       └── SetupClanEvents.lua   [Opcional]
│
└── 📁 StarterGui/ClanSystem/
    └── CreateClanGui.lua         [INTERFAZ DE USUARIO]
```

---

## 🔄 FLUJO DE DATOS

```
[CreateClanGui.lua]  →  [ClanClient.lua]  →  [RemoteFunction]  →  [ClanServer.lua]  →  [ClanData.lua]  →  [DataStore]
     (UI)                 (Cliente)            (Comunicación)        (Servidor)          (Datos)           (DB)
       ↑                                                                                                      |
       └──────────────────────────────── [RemoteEvent: ClansUpdated] ←──────────────────────────────────────┘
```

---

## 📦 ESTRUCTURA DE DATOS EN DATASTORE

### 🔑 Keys Pattern:

```lua
-- DataStore único: "ClanData"

"clan:{clanId}"         → Datos completos del clan
"player:{userId}"       → {clanId, role} minimal
"index:names"           → {[lowerName] = clanId}
"index:tags"            → {[upperTag] = clanId}
"request:{userId}"      → {[clanId] = {time, status, clanName}}
```

### 📊 Estructura de un Clan (V2):

```lua
{
    clanId = "abc123",                -- ID único generado
    name = "Los Guerreros",           -- Nombre del clan
    tag = "GRR",                      -- TAG en mayúsculas
    logo = "rbxassetid://12345",     -- ID del logo
    emoji = "⚔️",                     -- Emoji del clan
    color = {255, 0, 0},             -- Color RGB [r, g, b]
    description = "Descripción...",   -- Texto descriptivo
    createdAt = 1234567890,          -- Timestamp de creación
    
    owners = {8387751399},           -- Array de userIds (soporta múltiples)
    
    members = {                      -- Tabla flat de miembros
        ["8387751399"] = {
            name = "nandoxts",
            role = "owner",
            joinedAt = 1234567890
        },
        ["12345678"] = {
            name = "Usuario2",
            role = "miembro",
            joinedAt = 1234567891
        }
    }
}
```

### 👤 Estructura de Player Data:

```lua
-- Key: "player:{userId}"
{
    clanId = "abc123",    -- ID del clan al que pertenece
    role = "owner"        -- Rol en el clan
}
```

### 📝 Estructura de Solicitud:

```lua
-- Key: "request:{userId}"
{
    ["clanId123"] = {
        time = 1234567890,
        status = "pending",
        clanName = "Los Guerreros"
    }
}
```

---

## 🎯 COMPONENTES PRINCIPALES

### 1️⃣ **ClanData.lua** (ServerStorage/Systems/ClanSystem/)

**Responsabilidad:** Capa de abstracción de DataStore

**Funciones Públicas:**

#### 📖 Lectura
- `GetClan(clanId)` → Obtener datos de un clan
- `GetPlayerClan(userId)` → Obtener clan del jugador
- `GetPlayerRole(userId, clanId)` → Obtener rol del jugador
- `GetAllClans()` → Listar todos los clanes

#### ✏️ Escritura
- `CreateClan(name, ownerId, tag, logo, desc, emoji, color)` → Crear clan
- `UpdateClan(clanId, updates)` → Actualizar propiedades
- `DissolveClan(clanId)` → Eliminar clan

#### 👥 Miembros
- `AddMember(clanId, userId, role)` → Agregar miembro
- `RemoveMember(clanId, userId)` → Expulsar miembro
- `ChangeRole(clanId, userId, newRole)` → Cambiar rol

#### 👑 Owners (Múltiples)
- `AddOwner(clanId, userId)` → Agregar owner
- `RemoveOwner(clanId, userId)` → Remover owner

#### 📩 Solicitudes
- `RequestJoin(clanId, userId)` → Enviar solicitud
- `ApproveRequest(clanId, approverId, targetUserId)` → Aprobar
- `RejectRequest(clanId, rejecterId, targetUserId)` → Rechazar
- `GetClanRequests(clanId, requesterId)` → Obtener solicitudes del clan
- `GetUserRequests(userId)` → Obtener solicitudes del usuario
- `CancelRequest(clanId, userId)` → Cancelar una solicitud
- `CancelAllRequests(userId)` → Cancelar todas

#### 🔧 Helpers Internos
- `genId()` → Genera ID único para clan
- `getPlayerName(userId)` → Obtiene nombre del jugador
- `addToNameIndex(name, clanId)` → Agrega a índice de nombres
- `removeFromNameIndex(name)` → Elimina de índice
- `addToTagIndex(tag, clanId)` → Agrega a índice de tags
- `removeFromTagIndex(tag)` → Elimina de índice
- `nameExists(name)` → Verifica si nombre existe
- `tagExists(tag)` → Verifica si tag existe

**Operaciones Atómicas:**
- Usa `UpdateAsync()` para operaciones concurrentes seguras
- Usa `RemoveAsync()` para eliminar datos (NO `SetAsync(key, nil)`)
- Usa `pcall()` para manejar errores de DataStore

---

### 2️⃣ **ClanServer.lua** (ServerScriptService/Systems/ClanSystem/)

**Responsabilidad:** Handlers de peticiones del cliente + Validación + Permisos

**RemoteFunctions creadas:**

#### 🏗️ CRUD Básico
- `CreateClan` → Crear clan nuevo
- `GetClan` → Obtener datos de clan por ID
- `GetPlayerClan` → Obtener clan del jugador actual
- `GetClansList` → Listar todos los clanes

#### ⚙️ Modificación
- `ChangeClanName` → Cambiar nombre
- `ChangeClanTag` → Cambiar TAG
- `ChangeClanDescription` → Cambiar descripción
- `ChangeClanLogo` → Cambiar logo
- `ChangeClanColor` → Cambiar color

#### 👥 Gestión Miembros
- `InvitePlayer` → Invitar jugador (agrega directamente)
- `KickPlayer` → Expulsar miembro
- `ChangeRole` → Cambiar rol de miembro
- `LeaveClan` → Salir del clan

#### 👑 Gestión Owners
- `AddOwner` → Agregar owner (requiere ser owner)
- `RemoveOwner` → Remover owner (requiere múltiples owners)

#### 🗑️ Eliminación
- `DissolveClan` → Disolver clan (requiere ser owner)
- `AdminDissolveClan` → Admin elimina clan (sin validación de permisos)

#### 📩 Solicitudes
- `RequestJoinClan` → Enviar solicitud para unirse
- `ApproveJoinRequest` → Aprobar solicitud pendiente
- `RejectJoinRequest` → Rechazar solicitud
- `GetJoinRequests` → Obtener solicitudes del clan
- `GetUserPendingRequests` → Obtener solicitudes del usuario
- `CancelJoinRequest` → Cancelar una solicitud
- `CancelAllJoinRequests` → Cancelar todas

**RemoteEvent:**
- `ClansUpdated` → Notifica a clientes cuando hay cambios

**Funciones Auxiliares:**
- `checkCooldown(userId, action, seconds)` → Rate limiting
- `isAdmin(userId)` → Verifica si es admin
- `updatePlayerAttributes(userId)` → Actualiza atributos del player
- `updateAllMembers(clan)` → Actualiza atributos de todos los miembros

**Rate Limits (Config.RATE_LIMITS):**
```lua
GetClansList = 0            -- Sin throttle
CreateClan = 10             -- 10 segundos
LeaveClan = 5               -- 5 segundos
InvitePlayer = 1            -- 1 segundo
KickPlayer = 2              -- 2 segundos
ChangeRole = 3              -- 3 segundos
ChangeName = 60             -- 60 segundos
ChangeTag = 300             -- 5 minutos
ChangeDescription = 30      -- 30 segundos
ChangeLogo = 60             -- 60 segundos
ChangeColor = 10            -- 10 segundos
DissolveClan = 10           -- 10 segundos
AdminDissolveClan = 10      -- 10 segundos
RequestJoinClan = 5         -- 5 segundos
ApproveJoinRequest = 1      -- 1 segundo
RejectJoinRequest = 1       -- 1 segundo
CancelJoinRequest = 1       -- 1 segundo
GetJoinRequests = 0         -- Sin throttle
```

---

### 3️⃣ **ClanClient.lua** (ReplicatedStorage/Systems/ClanSystem/)

**Responsabilidad:** Interfaz del cliente para llamar al servidor

**Funciones Públicas:**

Todas las funciones son wrappers que:
1. Verifican throttling local
2. Inicializan RemoteFunctions lazy
3. Invocan servidor con `pcall()`
4. Retornan `(success, result)`

**Categorías:**

#### 📖 Consultas
- `GetClansList()` → Lista de clanes
- `GetPlayerClan()` → Clan del jugador
- `GetClan(clanId)` → Datos de clan específico

#### 👤 Acciones del jugador
- `CreateClan(name, tag, logo, desc, emoji, color)`
- `LeaveClan(clanId)`
- `RequestJoinClan(clanId)`
- `CancelJoinRequest(clanId)`
- `CancelAllRequests()`
- `GetUserPendingRequests()`

#### 👑 Acciones de owner/líder
- `InvitePlayer(clanId, targetUserId)`
- `KickPlayer(clanId, targetUserId)`
- `ChangeRole(clanId, targetUserId, newRole)`
- `ChangeClanName(clanId, newName)`
- `ChangeClanTag(clanId, newTag)`
- `ChangeClanDescription(clanId, newDesc)`
- `ChangeClanLogo(clanId, newLogoId)`
- `ChangeClanColor(clanId, newColor)`
- `DissolveClan(clanId)`
- `AddOwner(targetUserId)`
- `RemoveOwner(targetUserId)`

#### 📩 Gestión Solicitudes
- `GetJoinRequests(clanId)`
- `ApproveJoinRequest(clanId, targetUserId)`
- `RejectJoinRequest(clanId, targetUserId)`

#### 🛡️ Admin
- `AdminDissolveClan(clanId)`

**Throttling Local:**
- Evita spam antes de llamar al servidor
- Configurado en `throttleConfig`

---

### 4️⃣ **CreateClanGui.lua** (StarterGui/ClanSystem/)

**Responsabilidad:** Interfaz de usuario completa

**Estructura de la UI:**

```
ScreenGui
 └── ClanFrame (main)
      ├── TopBar (header)
      │   ├── Title
      │   ├── CloseButton
      │   └── TabButtons
      │       ├── Tab_Clanes (Lista de clanes)
      │       ├── Tab_MiClan (Mi clan)
      │       ├── Tab_Solicitudes (Pendientes)
      │       └── Tab_Admin (Panel admin) [solo admins]
      │
      ├── Content_Clanes (Lista de todos los clanes)
      │   ├── SearchBar
      │   └── ScrollingFrame → ClanCard (template)
      │
      ├── Content_MiClan (Detalles del clan del jugador)
      │   ├── ClanInfo (nombre, tag, emoji, miembros)
      │   ├── LeaveButton / DissolveClanButton
      │   ├── EditSection (cambiar nombre, tag, color, logo, desc)
      │   └── MembersList
      │       └── MemberCard (template)
      │
      ├── Content_Solicitudes (Solicitudes pendientes del usuario)
      │   └── ScrollingFrame → RequestCard (template)
      │
      └── Content_Admin (Panel de administrador)
          └── ScrollingFrame → AdminClanCard (template)
```

**Módulo ClanActions:**
- `refreshClanList()` → Actualiza lista de clanes
- `refreshMyClan()` → Actualiza vista de "Mi Clan"
- `refreshPendingRequests()` → Actualiza solicitudes pendientes
- `refreshAdminPanel()` → Actualiza panel admin
- `openClan(clanData)` → Abre vista detallada de clan
- `leaveClan()` → Salir del clan
- `dissolveClan()` → Disolver clan
- `requestJoin(clanId)` → Enviar solicitud
- `cancelRequest(clanId)` → Cancelar solicitud
- `editName()` → Editar nombre
- `editTag()` → Editar TAG
- `editColor()` → Editar color (usa paleta de colores)
- `editLogo()` → Editar logo
- `editDescription()` → Editar descripción
- `kickMember(userId)` → Expulsar miembro
- `changeRole(userId, newRole)` → Cambiar rol
- `deleteClanAdmin(clanId)` → Admin elimina clan

**Sistema de Pestañas:**
- Solo se muestra el contenido de la pestaña activa
- La pestaña "Admin" solo es visible para administradores
- Las posiciones de las pestañas se ajustan dinámicamente

**Paleta de Colores:**
```lua
local colorPalette = {
    {name = "dorado", rgb = {255, 215, 0}},
    {name = "plateado", rgb = {192, 192, 192}},
    {name = "bronce", rgb = {205, 127, 50}},
    {name = "rojo", rgb = {255, 0, 0}},
    {name = "azul", rgb = {0, 100, 255}},
    {name = "verde", rgb = {0, 255, 0}},
    {name = "morado", rgb = {128, 0, 128}},
    {name = "naranja", rgb = {255, 165, 0}},
    {name = "rosa", rgb = {255, 192, 203}},
    {name = "celeste", rgb = {135, 206, 235}}
}
```

---

### 5️⃣ **ClanSystemConfig.lua** (ReplicatedStorage/Config/)

**Responsabilidad:** Configuración global del sistema

**Secciones:**

#### 👨‍💼 ADMINS
```lua
ADMINS = {
    AdminUserIds = { 8387751399 },
    LogAdminActions = true
}
```

#### 💾 DATABASE
```lua
DATABASE = {
    UseDataStore = true,
    ClanStoreName = "ClanData",
    InitDelay = 2,
    CreateClanDelay = 0.1
}
```

#### 📏 LIMITS
```lua
LIMITS = {
    MinClanNameLength = 3,
    MaxClanNameLength = 30,
    MinTagLength = 2,
    MaxTagLength = 5
}
```

#### 🎨 DEFAULTS
```lua
DEFAULTS = {
    Logo = "rbxassetid://0",
    Emoji = "⚔️",
    Color = {255, 255, 255},
    Description = "Sin descripción",
    MemberRole = "miembro"
}
```

#### 👥 ROLE_NAMES
```lua
ROLE_NAMES = {
    OWNER = "owner",
    LIDER = "lider",
    COLIDER = "colider",
    MIEMBRO = "miembro"
}
```

#### ⏱️ RATE_LIMITS
Ver sección de ClanServer.lua

#### 🔐 ROLES (Jerarquía y Permisos)
```lua
ROLES = {
    Hierarchy = {
        owner = 4,
        lider = 3,
        colider = 2,
        miembro = 1
    },
    
    Permissions = {
        owner = {
            invitar = true,
            expulsar = true,
            cambiar_lideres = true,
            cambiar_colideres = true,
            cambiar_descripcion = true,
            cambiar_nombre = true,
            cambiar_tag = true,
            cambiar_logo = true,
            cambiar_emoji = true,
            cambiar_color = true,
            disolver_clan = true,
            aprobar_solicitudes = true,
            rechazar_solicitudes = true,
            ver_solicitudes = true,
            agregar_owner = true,
            remover_owner = true
        },
        colider = {
            -- Similar pero sin agregar_owner/remover_owner
        },
        lider = {
            -- Permisos reducidos
        },
        miembro = {
            -- Sin permisos administrativos
        }
    }
}
```

**Funciones del Config:**
- `IsAdmin(userId)` → Verifica si es admin
- `ValidateClanName(name)` → Valida nombre
- `ValidateTag(tag)` → Valida TAG
- `HasPermission(role, permission)` → Verifica permisos
- `GetRateLimit(action)` → Obtiene rate limit
- `GetRoleHierarchy(role)` → Obtiene nivel de jerarquía

---

## 🔄 FLUJOS PRINCIPALES

### ➕ Crear Clan

1. **UI:** Usuario llena formulario en CreateClanGui
2. **Cliente:** `ClanClient:CreateClan()` → Valida throttling
3. **Servidor:** `CreateClan.OnServerInvoke` → Verifica cooldown
4. **Datos:** `ClanData:CreateClan()` → Valida nombre/tag, crea clan, actualiza índices
5. **Notificación:** `ClansUpdated:FireAllClients()` → Refresca UIs
6. **Atributos:** `updatePlayerAttributes()` → Actualiza atributos del player

### 👥 Invitar Jugador

1. **UI:** Owner hace click en botón "Invitar" (ingresa userId)
2. **Cliente:** `ClanClient:InvitePlayer(clanId, targetUserId)`
3. **Servidor:** Valida permisos con `Config:HasPermission(role, "invitar")`
4. **Datos:** `ClanData:AddMember(clanId, targetUserId, role)`
5. **Notificación:** Actualiza atributos del nuevo miembro

### 📩 Solicitud de Unión

1. **UI:** Usuario ve clan y hace click en "Solicitar Unirse"
2. **Cliente:** `ClanClient:RequestJoinClan(clanId)`
3. **Servidor:** Verifica que usuario no tenga clan
4. **Datos:** `ClanData:RequestJoin(clanId, userId)` → Guarda en `request:{userId}`
5. **Aprobación:** Owner aprueba desde pestaña "Solicitudes"
   - `ClanClient:ApproveJoinRequest(clanId, targetUserId)`
   - Agrega miembro con `AddMember()`
   - Elimina solicitud

### 🗑️ Eliminar Clan (Admin)

1. **UI:** Admin hace click en botón "Eliminar" en panel admin
2. **Cliente:** `ClanClient:AdminDissolveClan(clanId)`
3. **Servidor:** Verifica con `isAdmin(player.UserId)`
4. **Datos:** `ClanData:DissolveClan(clanId)`
   - Limpia datos de miembros: `DS:RemoveAsync("player:{userId}")`
   - Elimina clan: `DS:RemoveAsync("clan:{clanId}")`
   - Limpia índices: `removeFromNameIndex()`, `removeFromTagIndex()`
5. **Notificación:** Actualiza atributos de todos los ex-miembros

### 🎨 Cambiar Color

1. **UI:** Usuario selecciona color de la paleta o ingresa nombre
2. **Cliente:** `ClanActions:editColor()` → Convierte nombre a RGB
3. **Servidor:** Valida permisos
4. **Datos:** `ClanData:UpdateClan(clanId, {color = {r, g, b}})`
5. **Notificación:** Actualiza atributos de todos los miembros

---

## ⚠️ ERRORES COMUNES Y SOLUCIONES

### ❌ "Argument 2 missing or nil"
**Causa:** Llamar `SetAsync(key, nil)` o pasar parámetros faltantes
**Solución:** Usar `RemoveAsync(key)` para eliminar datos

### ❌ "clanId es nil"
**Causa:** No validar parámetros antes de usarlos
**Solución:** Agregar checks `if not clanId then return false, "error" end`

### ❌ Colores no se guardan
**Causa:** Enviar string en lugar de array RGB
**Solución:** Usar paleta y convertir a `{r, g, b}`

### ❌ UI muestra "undefined" o nil
**Causa:** Usar nombres de campos V1 (`clanName`, `miembros_data`, `rol`)
**Solución:** Usar nombres V2 (`name`, `members`, `role`)

### ❌ Admin no puede eliminar clan
**Causa:** Índices no se limpian o funciones reciben parámetros incorrectos
**Solución:** Asegurar que `removeFromNameIndex/Tag` solo reciban nombre/tag (no clanId)

---

## 📊 ATRIBUTOS DE PLAYER

Cuando un jugador está en un clan, se le asignan estos atributos:

```lua
player:SetAttribute("ClanTag", "GRR")
player:SetAttribute("ClanName", "Los Guerreros")
player:SetAttribute("ClanId", "abc123")
player:SetAttribute("ClanEmoji", "⚔️")
player:SetAttribute("ClanColor", Color3.fromRGB(255, 0, 0))
```

Cuando sale/es expulsado, todos se limpian a `nil`.

---

## 🔧 HERRAMIENTAS DE DIAGNÓSTICO

### CHECK_CLAN_STATUS.lua
Script temporal en `ServerScriptService` que:
- Lista todos los clanes en el sistema
- Verifica si un clan específico existe
- Muestra detalles completos de cada clan

---

## 📝 NOTAS IMPORTANTES

1. **DataStore único:** Todo se guarda en `"ClanData"`
2. **Nombres V2:** Usar `name`, `tag`, `members`, `role` (no V1)
3. **Índices:** Se mantienen automáticamente para búsquedas rápidas
4. **Múltiples Owners:** Soportado en `clan.owners` array
5. **Rate Limiting:** Doble capa (cliente throttling + servidor cooldown)
6. **Permisos:** Sistema robusto con `Config:HasPermission()`
7. **Atómico:** Usa `UpdateAsync` para operaciones concurrentes
8. **RemoveAsync:** Siempre usar para eliminar (NO `SetAsync(nil)`)

---

## 🎯 PRÓXIMAS MEJORAS POTENCIALES

- [ ] Sistema de niveles/XP para clanes
- [ ] Guerra entre clanes
- [ ] Tienda de mejoras para clanes
- [ ] Logs de actividad del clan
- [ ] Sistema de alianzas
- [ ] Chat privado del clan
- [ ] Emblemas/insignias desbloqueables
- [ ] Ranking global de clanes
- [ ] Eventos exclusivos para clanes

---

**FIN DEL DOCUMENTO**
