# 🎁 Admin Gift Gamepass - Guía de Uso

Scripts administrativos para regalar gamepasses directamente a usuarios sin necesidad de compra.

## 📁 Archivos Creados

### 1. `AdminGiftGamepass.lua` - Regalo Simple
Para regalar **UN** gamepass a **UN** usuario.

**Ubicación:** `ServerScriptService/Panda ServerScriptService/Gamepass Gifting/AdminGiftGamepass.lua`

**Cómo usar:**
```lua
-- Edita estas líneas en el script:
local USER_ID = 10179455284        -- ← ID del usuario
local GAMEPASS_ID = 123456789      -- ← ID del gamepass
```

**Pasos:**
1. Abre `AdminGiftGamepass.lua`
2. Cambia `USER_ID` por el ID del usuario receptor
3. Cambia `GAMEPASS_ID` por el ID del gamepass a regalar
4. Guarda y ejecuta el juego
5. Verás un log detallado en la consola

---

### 2. `AdminGiftMultiple.lua` - Regalo Múltiple
Para regalar **MÚLTIPLES** gamepasses a **MÚLTIPLES** usuarios en batch.

**Ubicación:** `ServerScriptService/Panda ServerScriptService/Gamepass Gifting/AdminGiftMultiple.lua`

**Cómo usar:**
```lua
-- Edita la lista REGALOS:
local REGALOS = {
    {userId = 10179455284, gamepassId = 123456789},
    {userId = 987654321, gamepassId = 111111111},
    {userId = 111222333, gamepassId = 222222222},
}
```

**Pasos:**
1. Abre `AdminGiftMultiple.lua`
2. Agrega entradas a la tabla `REGALOS`
3. Guarda y ejecuta el juego
4. Se procesarán todos automáticamente con un resumen final

---

## ✅ Qué Hacen los Scripts

1. **Validan** que el usuario y gamepass existan
2. **Verifican** si ya tiene el gamepass (comprado o regalado)
3. **Guardan** en el DataStore `Gifting.1` con la key `{userId}-{gamepassId}`
4. **Actualizan** la carpeta `Gamepasses` del jugador si está conectado
5. **Notifican** a HD-CONNECT para actualizar rangos al instante
6. **Actualizan** el atributo `HasVIP` si es el gamepass VIP

---

## 📊 Ejemplo de Output

### Regalo Simple:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎁 INICIANDO REGALO DE GAMEPASS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Usuario: nandoxts (10179455284)
🎫 Gamepass: VIP Premium
💾 Guardando en DataStore...
✅ Guardado en DataStore exitoso
🔄 Actualizando jugador conectado...
👑 Atributo HasVIP actualizado
🔗 HD-CONNECT notificado
✅ Jugador actualizado en tiempo real
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GAMEPASS REGALADO EXITOSAMENTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Regalo Múltiple:
```
═══════════════════════════════════════════════════
🎁 PROCESANDO REGALOS DE GAMEPASSES
═══════════════════════════════════════════════════
Total de regalos en la lista: 3
═══════════════════════════════════════════════════

[1/3] Procesando...
✅ Regalado: nandoxts - VIP Premium

[2/3] Procesando...
⚠️  Ya regalado: Player2 - Ultra VIP

[3/3] Procesando...
✅ Regalado: Player3 - DJ Pass

═══════════════════════════════════════════════════
📊 RESUMEN FINAL
═══════════════════════════════════════════════════
✅ Exitosos: 2
⚠️  Omitidos (ya tenían): 1
❌ Fallidos: 0
📦 Total procesados: 3
═══════════════════════════════════════════════════
```

---

## 🔍 Cómo Obtener IDs

### User ID:
1. Ve al perfil del usuario en Roblox
2. La URL será: `https://www.roblox.com/users/10179455284/profile`
3. El número es el User ID: `10179455284`

### Gamepass ID:
1. Ve a la página del gamepass en Creator Dashboard
2. La URL será algo como: `https://www.roblox.com/game-pass/123456789`
3. El número es el Gamepass ID: `123456789`

O revisa el archivo `Config.lua` en:
```
ReplicatedStorage/Panda ReplicatedStorage/Gamepass Gifting/Modules/Config
```

---

## ⚙️ Configuración Técnica

- **DataStore usado:** `Gifting.1`
- **Key format:** `{userId}-{gamepassId}` (ejemplo: `10179455284-123456789`)
- **Queue delay:** 0.15-0.2 segundos entre operaciones
- **Timeout guardado:** 10 segundos máximo
- **Compatible con:** Sistema de regalos normal, HD-CONNECT, VIP system

---

## 🚨 Notas Importantes

1. **Los scripts se ejecutan automáticamente** 3 segundos después de cargar
2. **Solo funcionan en el servidor** (ServerScriptService)
3. **Usa el DataStoreQueue** para evitar throttling
4. **Verifica antes de regalar** si ya tienen el gamepass
5. **Es permanente** - no se puede deshacer desde estos scripts

---

## 🔧 Troubleshooting

**Error: "Usuario inválido"**
- Verifica que el User ID sea correcto
- Asegúrate que la cuenta existe

**Error: "Gamepass inválido"**
- Verifica que el Gamepass ID sea correcto
- Asegúrate que el gamepass existe en tu juego

**Error: "Error guardando"**
- Problema de DataStore throttling
- Espera unos minutos e intenta de nuevo
- Reduce el número de regalos simultáneos

**"Ya regalado" pero el jugador no lo tiene**
- El jugador debe reconectar al juego
- O usa el script de verificación para confirmar

---

## 📝 Ejemplo Práctico

Quieres regalar VIP a 5 usuarios:

```lua
-- En AdminGiftMultiple.lua
local REGALOS = {
    {userId = 10179455284, gamepassId = 123456789},  -- nandoxts - VIP
    {userId = 111222333, gamepassId = 123456789},    -- User2 - VIP
    {userId = 444555666, gamepassId = 123456789},    -- User3 - VIP
    {userId = 777888999, gamepassId = 123456789},    -- User4 - VIP
    {userId = 123123123, gamepassId = 123456789},    -- User5 - VIP
}
```

Guardar → Ejecutar → ¡Listo! 🎉
