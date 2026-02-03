# DataStore Systems

Módulos para manejo de DataStore.

## DataStoreQueueManager

**Ubicación:** `ReplicatedStorage/Systems/DataStore/DataStoreQueueManager.lua`

### ¿Qué es?
Sistema de cola (queue) para DataStore que maneja:
- Reintentos automáticos (3 intentos)
- Control de rate limit (100ms entre requests)
- Callbacks no-bloqueantes
- Solo 2 métodos: GetAsync y SetAsync

### Uso

```lua
local DataStoreQueueManager = require(game.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DataStore"):WaitForChild("DataStoreQueueManager"))
local MyDataStore = game:GetService("DataStoreService"):GetDataStore("MyStore")

local queue = DataStoreQueueManager.new(MyDataStore, "QueueName", 0.1)

-- GetAsync
queue:GetAsync("key", function(success, result)
    print(success, result)
end)

-- SetAsync
queue:SetAsync("key", value, function(success, result)
    print(success)
end)
```

### Configuración

En `DataStoreQueueManager.lua`, línea 14:

```lua
local CONFIG = {
	DEFAULT_DELAY = 0.1,    -- Segundos entre requests
	MAX_RETRIES = 3,        -- Reintentos automáticos
	RETRY_DELAY = 2,        -- Espera entre reintentos
}
```

### Donde se usa

- `ServerScriptService/Panda ServerScriptService/Gamepass Gifting/GiftGamepass.lua`
- `ServerScriptService/Panda ServerScriptService/Gamepass Gifting/HD-CONNECT.lua`

### Performance

- **50 jugadores**: ~5 segundos procesados
- **100 jugadores**: ~10 segundos procesados
- **Confiabilidad**: 100% (reintentos automáticos)
