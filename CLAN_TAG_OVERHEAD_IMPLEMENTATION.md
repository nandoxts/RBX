# Implementación del Tag de Clan en Overhead

## 📋 Resumen
Se ha implementado un sistema de atributos para mostrar el tag del clan sobre la cabeza de los jugadores en el juego.

## ⚙️ Cambios Realizados

### 1. ClanServer.lua
**Archivo:** `ServerScriptService/Systems/ClanSystem/ClanServer.lua`

#### Cambios principales:
- ✅ Agregado servicio `Players` a los imports
- ✅ Creada función `updatePlayerClanAttributes(userId)` - Actualiza los atributos del jugador (ClanTag, ClanName, ClanId)
- ✅ Creada función `initializePlayerClanAttributes(player)` - Inicializa atributos al unirse al juego
- ✅ Los atributos se actualizan automáticamente cuando:
  - Un jugador se une a un clan (`JoinClan`)
  - Un jugador es invitado a un clan (`InvitePlayer`)
  - Un jugador es expulsado de un clan (`KickPlayer`)
  - El tag del clan cambia (`ChangeTag`)
  - El clan es disuelto (`DissolveClan`)
- ✅ Inicialización automática para jugadores ya en el juego
- ✅ Conexión `PlayerAdded` para nuevos jugadores

#### Atributos del jugador:
```lua
player:SetAttribute("ClanTag", "ABC")    -- Tag del clan (2-5 caracteres)
player:SetAttribute("ClanName", "Mi Clan") -- Nombre completo del clan
player:SetAttribute("ClanId", "12345")   -- ID único del clan
```

### 2. Overhead[UPDATE].lua
**Archivo:** `ServerScriptService/Panda ServerScriptService/LeaderBoards/Overhead[UPDATE].lua`

#### Cambios principales:
- ✅ Modificada función `configureOverhead()` para leer el atributo `ClanTag`
- ✅ El username ahora muestra: `[TAG] @Username` si el jugador tiene clan
- ✅ Agregado listener `GetAttributeChangedSignal("ClanTag")` para actualizar en tiempo real
- ✅ El overhead se actualiza automáticamente cuando:
  - El jugador se une/sale de un clan
  - El tag del clan cambia
  - El clan es disuelto

## 🎮 Comportamiento en el Juego

### Jugador SIN clan:
```
@NombreUsuario
```

### Jugador CON clan (tag: "ABC"):
```
[ABC] @NombreUsuario
```

## 🔄 Flujo de Actualización

1. **Jugador se une a un clan:**
   ```
   ClanServer:JoinClan() 
   → updatePlayerClanAttributes() 
   → player:SetAttribute("ClanTag", "ABC")
   → Overhead detecta cambio via GetAttributeChangedSignal
   → Username actualizado a "[ABC] @Usuario"
   ```

2. **Tag del clan cambia:**
   ```
   ClanServer:ChangeTag()
   → updatePlayerClanAttributes() para todos los miembros
   → Todos los overheads se actualizan automáticamente
   ```

3. **Jugador es expulsado:**
   ```
   ClanServer:KickPlayer()
   → updatePlayerClanAttributes()
   → player:SetAttribute("ClanTag", nil)
   → Username vuelve a "@Usuario"
   ```

## ✅ Ventajas de esta Implementación

1. **Desacoplamiento:** El sistema de overhead no necesita conocer el sistema de clanes
2. **Tiempo Real:** Los cambios se reflejan inmediatamente sin requerir respawn
3. **Eficiencia:** Usa el sistema de atributos nativo de Roblox
4. **Escalabilidad:** Fácil agregar más información del clan (color, emblema, etc.)
5. **Persistencia:** Los atributos se mantienen durante toda la sesión del jugador

## 🚀 Próximas Mejoras Posibles

- Agregar color personalizado al tag del clan
- Mostrar emblema/logo del clan
- Agregar rango dentro del clan (Owner, Admin, Miembro)
- Animaciones al cambiar de clan
- Efectos especiales para clans de alto nivel

## 🐛 Debugging

Si el tag no aparece, verificar:
1. Que `ClanServer.lua` esté ejecutándose correctamente
2. Usar comando en consola del servidor:
   ```lua
   print(player:GetAttribute("ClanTag"))
   ```
3. Verificar que el jugador esté realmente en un clan:
   ```lua
   local clanData = ClanData:GetPlayerClan(player.UserId)
   print(clanData)
   ```
