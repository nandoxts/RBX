# Sistema de Dance Leader (Líder de Danza)

## Descripción
Sistema que detecta automáticamente a jugadores que tienen 10 o más seguidores y les muestra una UI decorativa encima del jugador indicando que son un "Dance Leader".

## Características

### 1. Detección Automática
- **Umbral**: Un jugador se convierte en Dance Leader cuando tiene >= 10 seguidores
- **Verificación**: Se realiza cada 5 minutos automáticamente
- **Tiempo Real**: También se verifica cuando cambia el atributo `followers` de un jugador

### 2. UI Visual
Cuando un jugador es Dance Leader, se muestra:
- **Billboard** (3D UI) encima de la cabeza
- **Contenedor** con fondo oscuro semitransparente y borde dorado
- **Texto**: "⭐ DANCE LEADER ⭐" 
- **Nombre del jugador** en color azul
- **Efecto Visual**: Ligera rotación suave (oscilación) para llamar atención

### 3. Configuración
Las siguientes variables se pueden modificar en `Configuration.lua`:

```lua
FOLLOWER_DANCE = 10              -- Cantidad de seguidores para ser Dance Leader
CHECK_TIME_FOLLOWER = 300        -- Tiempo entre verificaciones (en segundos)
BILLBOARD_NAME = "Dance_Leader"  -- Nombre del billboard
```

## Archivos

### Servidor
- **DanceLeaderSystem.lua**: Script servidor que detecta cambios y notifica a clientes
  - Ubicación: `ServerScriptService/Panda ServerScriptService/`
  - Responsabilidades:
    - Monitorear cantidad de seguidores de cada jugador
    - Detectar cambios de estado (se convierte en / deja de ser líder)
    - Enviar eventos a clientes

### Cliente
- **DanceLeaderUI.lua**: Script cliente que crea y gestiona la UI visual
  - Ubicación: `StarterPlayer/StarterPlayerScripts/`
  - Responsabilidades:
    - Crear billboards para Dance Leaders
    - Aplicar efectos visuales
    - Remover billboards cuando el jugador deja de ser líder

## Cómo Funciona

### Flujo de Funcionamiento

1. **Servidor**: Verifica periódicamente quién tiene >= 10 seguidores
2. **Servidor**: Cuando detecta un cambio, envía evento `DanceLeaderEvent`
3. **Cliente**: Recibe el evento y crea/remueve la UI visual
4. **Resultado**: Se muestra el billboard encima del jugador

### Eventos Disponibles

#### DanceLeaderEvent (RemoteEvent)

**Eventos Servidor → Cliente:**

```lua
-- Cuando el jugador local se convierte en/deja de ser líder
DanceLeaderEvent:FireClient(player, "setLeader", isLeader)

-- Cuando otro jugador se convierte en líder
DanceLeaderEvent:FireAllClients("leaderAdded", player)

-- Cuando otro jugador deja de ser líder
DanceLeaderEvent:FireAllClients("leaderRemoved", player)
```

## Personalización

### Cambiar el Umbral de Seguidores
En `Configuration.lua`:
```lua
FOLLOWER_DANCE = 5  -- Ahora con 5 seguidores se es Dance Leader
```

### Cambiar la Frecuencia de Verificación
En `Configuration.lua`:
```lua
CHECK_TIME_FOLLOWER = 60  -- Verificar cada minuto en lugar de cada 5 minutos
```

### Personalizar la Apariencia del Billboard
En `DanceLeaderUI.lua`, editar la función `CreateDanceLeaderBillboard`:

```lua
-- Cambiar color del fondo
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

-- Cambiar color del borde
stroke.Color = Color3.fromRGB(255, 0, 0)

-- Cambiar transparencia
frame.BackgroundTransparency = 0.5

-- Cambiar tamaño
billboard.Size = UDim2.new(6, 0, 3, 0)

-- Cambiar offset (altura)
billboard.StudsOffset = Vector3.new(0, 5, 0)
```

### Cambiar el Texto
```lua
titleLabel.Text = "��� MAESTRO DE BAILE ���"
```

### Cambiar la Animación
La rotación suave se controla aquí:
```lua
local rotationConnection = RunService.RenderStepped:Connect(function()
    rotation = (rotation + 1) % 360
    frame.Rotation = math.sin(rotation * math.pi / 180) * 3  -- Ajustar el 3 para más/menos rotación
end)
```

## Troubleshooting

### El billboard no aparece
1. Verificar que `DanceLeaderSystem.lua` está en `ServerScriptService`
2. Verificar que `DanceLeaderUI.lua` está en `StarterPlayer/StarterPlayerScripts`
3. Verificar que el atributo `followers` se está actualizando correctamente
4. Revisar la consola para mensajes de error

### El billboard no se actualiza
1. Verificar que `CHECK_TIME_FOLLOWER` no es muy alto
2. Asegurarse de que el sistema de seguidores está funcionando correctamente

### Performance
Si hay muchos Dance Leaders:
- Aumentar `CHECK_TIME_FOLLOWER` para verificar menos frecuentemente
- Reducir `MaxDistance` en el billboard para que no se vea desde muy lejos

## Notas Técnicas

- El sistema usa `BillboardGui` con `RunService.RenderStepped` para la animación
- Los cambios se detectan mediante atributos del jugador (`followers`)
- La comunicación servidor-cliente se realiza mediante `RemoteEvent`
- Se implementa limpieza automática de conexiones al desconectarse jugadores

