# ��� Sistema de Notificaciones - Documentación

Sistema profesional de notificaciones para Roblox, completamente integrado con ThemeConfig.

## ��� Ubicación

```
ReplicatedStorage/
  └─ NotificationSystem.lua
```

## ✨ Características

- ✅ **5 tipos de notificaciones** (Success, Error, Warning, Info, Clan)
- ✅ **Diseño moderno** usando ThemeConfig
- ✅ **Animaciones suaves** con TweenService
- ✅ **Auto-posicionamiento** dinámico
- ✅ **Notificaciones clickeables**
- ✅ **Barra de progreso** animada
- ✅ **Máximo 5 notificaciones** simultáneas
- ✅ **Sistema de cola** automático

## ��� Tipos de Notificaciones

### 1. Success (✓)
```lua
Notify:Success("¡Éxito!", "Operación completada correctamente", 5)
```
- **Color**: Verde (#34A853)
- **Uso**: Acciones exitosas, confirmaciones

### 2. Error (✕)
```lua
Notify:Error("Error", "Algo salió mal", 5)
```
- **Color**: Rojo (#DC5F5F)
- **Uso**: Errores, fallos de operación

### 3. Warning (⚠)
```lua
Notify:Warning("Advertencia", "Ten cuidado con esto", 5)
```
- **Color**: Amarillo (#FFC107)
- **Uso**: Avisos importantes, precauciones

### 4. Info (ℹ)
```lua
Notify:Info("Información", "Datos útiles para el usuario", 5)
```
- **Color**: Azul (#4285F4)
- **Uso**: Información general, tips

### 5. Clan (⚔)
```lua
Notify:Clan("Sistema de Clanes", "Acción relacionada con clanes", 5)
```
- **Color**: Índigo (Accent)
- **Uso**: Notificaciones específicas de clanes

## ��� Uso Básico

### Importar el módulo

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Notify = require(ReplicatedStorage:WaitForChild("NotificationSystem"))
```

### Notificación simple

```lua
Notify:Success("¡Genial!", "Completaste la misión", 4)
```

### Notificación con duración personalizada

```lua
Notify:Info("Título", "Mensaje", 8)  -- 8 segundos
```

### Notificación clickeable

```lua
Notify:Notify({
title = "Nueva Misión",
message = "Haz click para ver detalles",
type = "info",
duration = 10,
onClick = function()
print("El usuario clickeó la notificación!")
-- Abrir UI de misiones, etc.
end
})
```

### Notificación avanzada

```lua
Notify:Notify({
title = "Título Personalizado",
message = "Mensaje personalizado más largo",
type = "success",  -- success, error, warning, info, clan
duration = 6,      -- segundos (0 = no auto-cerrar)
onClick = function()
-- Acción al hacer click
end
})
```

## ��� Ejemplos de Integración

### En el Sistema de Clanes

```lua
-- Cuando un jugador se une a un clan
Notify:Clan("¡Bienvenido!", "Te has unido a " .. clanName, 5)

-- Cuando se crea un clan
Notify:Success("¡Clan Creado!", "Tu clan '" .. clanName .. "' está listo", 5)

-- Error al crear clan
Notify:Error("Error", "No se pudo crear el clan", 5)
```

### En un Sistema de Tienda

```lua
-- Compra exitosa
Notify:Success("Compra Exitosa", "Has comprado: " .. itemName, 4)

-- Sin dinero
Notify:Warning("Fondos Insuficientes", "Necesitas " .. price .. " monedas", 5)
```

### En un Sistema de Chat

```lua
-- Nuevo mensaje privado
Notify:Info("Nuevo Mensaje", playerName .. " te envió un mensaje", 6, function()
-- Abrir chat
ChatUI:Open(playerName)
end)
```

## ⚙️ Configuración

Puedes modificar la configuración en `NotificationSystem.lua`:

```lua
local CONFIG = {
POSITION_START = UDim2.new(1, -20, 1, -20),  -- Posición inicial
NOTIFICATION_WIDTH = 320,                     -- Ancho
NOTIFICATION_HEIGHT = 80,                     -- Alto
SPACING = 10,                                 -- Espaciado entre notificaciones
DURATION_SHORT = 3,                           -- Duración corta
DURATION_MEDIUM = 5,                          -- Duración media
DURATION_LONG = 8,                            -- Duración larga
ANIMATION_TIME = 0.3,                         -- Tiempo de animación
MAX_NOTIFICATIONS = 5                         -- Máximo simultáneo
}
```

## ��� Métodos Disponibles

| Método | Parámetros | Descripción |
|--------|-----------|-------------|
| `Notify:Success()` | title, message, duration | Notificación de éxito |
| `Notify:Error()` | title, message, duration | Notificación de error |
| `Notify:Warning()` | title, message, duration | Notificación de advertencia |
| `Notify:Info()` | title, message, duration | Notificación informativa |
| `Notify:Clan()` | title, message, duration, onClick | Notificación de clan |
| `Notify:Notify()` | options{} | Notificación personalizada |
| `Notify:ClearAll()` | - | Eliminar todas las notificaciones |

## ��� Personalización de Colores

Los colores se toman automáticamente de `ThemeConfig.lua`:

```lua
NOTIFICATION_TYPES = {
success = {
icon = "✓",
color = THEME.success,        -- Verde
bgColor = THEME.successMuted,
borderColor = THEME.success
},
-- ... otros tipos
}
```

## ��� Mejores Prácticas

1. **Usa el tipo correcto**: No uses Success para errores
2. **Mensajes concisos**: Máximo 2 líneas de texto
3. **Duración apropiada**: 
   - Info rápida: 3-4 segundos
   - Avisos: 5-6 segundos  
   - Errores importantes: 8+ segundos
4. **No abuses**: Máximo 2-3 notificaciones por acción
5. **onClick solo cuando sea útil**: No fuerces clicks innecesarios

## ��� Integración en Nuevos Módulos

### Paso 1: Importar
```lua
local Notify = require(ReplicatedStorage:WaitForChild("NotificationSystem"))
```

### Paso 2: Usar en eventos
```lua
-- Ejemplo en un sistema de logros
AchievementSystem.OnAchievement:Connect(function(achievementName)
Notify:Success(
"¡Logro Desbloqueado!",
achievementName,
6
)
end)
```

## ��� Responsive Design

El sistema es completamente responsive:
- Se adapta a diferentes resoluciones
- Posición fija en esquina inferior derecha
- Stack automático de notificaciones
- Animaciones suaves de entrada/salida

## ��� Debugging

Para ver logs de notificaciones:

```lua
-- Activar modo debug (agregar al inicio de NotificationSystem.lua)
local DEBUG = true

if DEBUG then
print("[Notification] Showing:", title, "-", message)
end
```

## ��� Eliminar Todas las Notificaciones

```lua
Notify:ClearAll()
```

Útil para:
- Cambios de escena
- Teleports
- Resets de UI

---

**Creado para:** Sistema SX  
**Versión:** 1.0  
**Compatible con:** Roblox Studio 2026  
**Dependencias:** ThemeConfig.lua

