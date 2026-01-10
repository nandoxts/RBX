-- ════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM DEMO
-- Demo de todas las notificaciones disponibles
-- Para probar: Solo ejecuta este script en StarterPlayerScripts
-- ════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- Esperar un poco para que todo cargue
task.wait(2)

-- ════════════════════════════════════════════════════════════════
-- DEMO DE NOTIFICACIONES
-- ════════════════════════════════════════════════════════════════

-- Notificación de bienvenida
Notify:Info(
"Sistema de Notificaciones",
"Bienvenido! Este es el nuevo sistema de notificaciones.",
4
)

-- Mostrar todas las notificaciones con delay
task.wait(1.5)

Notify:Success(
"¡Éxito!",
"Esta es una notificación de éxito. Se usa para acciones completadas.",
4
)

task.wait(1.5)

Notify:Error(
"Error",
"Esta es una notificación de error. Se muestra cuando algo sale mal.",
4
)

task.wait(1.5)

Notify:Warning(
"Advertencia",
"Esta es una notificación de advertencia. Úsala para avisos importantes.",
4
)

task.wait(1.5)

Notify:Clan(
"Sistema de Clanes",
"Notificaciones especiales para el sistema de clanes.",
4
)

task.wait(2)

-- Notificación con click
Notify:Notify({
title = "Notificación Clickeable",
message = "Haz click en esta notificación para ver una acción!",
type = "info",
duration = 8,
onClick = function()
print("¡Notificación clickeada!")
Notify:Success("¡Click!", "Acabas de clickear una notificación", 3)
end
})

task.wait(3)

-- Notificación de larga duración
Notify:Info(
"Sistema Listo",
"El sistema de notificaciones está completamente operativo y listo para usar en todo el juego!",
6
)

-- Comentar esta línea para desactivar el demo automático
-- Para usar en producción, elimina este archivo o comenta todo el código

