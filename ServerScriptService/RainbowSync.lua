-- RainbowSync.lua (Optimizado y Dinámico)
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RainbowSync = {}

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DINÁMICA (Edita aquí para agregar/quitar elementos)
-- ═══════════════════════════════════════════════════════════════════
local CONFIG = {
	speed = 0.5,

	-- Blacklist GLOBAL: estos nombres NUNCA se tocan
	-- Sin "/" = solo ese nombre | Con "/" = toda la carpeta y su contenido
	globalBlacklist = {
		"Baseplate",
		"Terrain",
		"SpawnLocation",
		"LucesEstaticas/",  -- Ejemplo: ignora toda la carpeta LucesEstaticas
		-- Agrega más aquí...
	},

	-- Rutas dinámicas
	-- recursive: true = escanea todo, false = solo hijos directos
	-- blacklist: nombres a ignorar SOLO en esta ruta (opcional)
	-- Sin "/" = solo ese nombre | Con "/" = toda la carpeta y su contenido
	paths = {
		{ path = "workspace.visuals.Visualizer", recursive = false },
		{ 
			path = "workspace.SalonPro.EstructuraSalon", 
			recursive = true,
			blacklist = { 
				"Cir",           -- Solo ignora parts llamadas "Cir"
				"Cosas/",
				"B1/",        -- Ignora TODA la carpeta Cosas
			}
		},
		{ path = "workspace.Effects.Parts.SoundParts", recursive = false },
	},
	-- UI elements (SurfaceGuis, ScreenGuis, etc.)
	uiPaths = {
		{ path = "workspace.visuals.MusicPlayerUI.Main.Equalizer", pattern = "Bar" },
		{ path = "workspace.visuals.MusicPlayerUI.Main.ProgressBg.ProgressFill" },
	},
	themes = {
		verde = {
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 128, 0),
			Color3.fromRGB(144, 238, 144),
			Color3.fromRGB(34, 139, 34),
		},
		azul = {
			Color3.fromRGB(0, 191, 255),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(30, 144, 255),
			Color3.fromRGB(0, 206, 209),
		},
		rojo = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(220, 20, 60),
			Color3.fromRGB(255, 69, 0),
			Color3.fromRGB(178, 34, 52),
		},
	},
	rainbowColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 165, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(238, 130, 238),
	},
}

-- ═══════════════════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════════════════
local state = {
	mode = "disabled",
	theme = "verde",
	progress = 0,
	colorIndex = 1,
	colors = CONFIG.rainbowColors,
}

local registry = {} -- { instance = originalData }
local connections = {}

-- ═══════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════
local function resolvePath(pathString)
	local parts = string.split(pathString, ".")
	local current = _G

	for i, part in ipairs(parts) do
		if i == 1 then
			if part == "workspace" then
				current = workspace
			elseif part == "ReplicatedStorage" then
				current = ReplicatedStorage
			else
				current = game:GetService(part)
			end
		else
			local child = current:FindFirstChild(part)
			if not child then return nil end
			current = child
		end
	end
	return current
end

local function isBlacklisted(instance, localBlacklist)
	local function checkList(list)
		if not list then return false end

		for _, entry in ipairs(list) do
			-- Si termina en "/" → ignorar carpeta completa (revisar ancestros)
			if string.sub(entry, -1) == "/" then
				local folderName = string.sub(entry, 1, -2) -- Quitar el "/"
				local current = instance
				while current and current ~= workspace and current ~= game do
					if current.Name == folderName then
						return true
					end
					current = current.Parent
				end
			else
				-- Sin "/" → solo comparar nombre exacto
				if instance.Name == entry then
					return true
				end
			end
		end
		return false
	end

	-- Revisar blacklist global
	if checkList(CONFIG.globalBlacklist) then
		return true
	end
	-- Revisar blacklist local
	if checkList(localBlacklist) then
		return true
	end

	return false
end

local function getColorProperties(instance)
	local props = {}
	for _, prop in ipairs({"Color", "BackgroundColor3", "ImageColor3"}) do
		local ok, val = pcall(function() return instance[prop] end)
		if ok and typeof(val) == "Color3" then
			props[prop] = val
		end
	end
	return next(props) and props or nil
end

local function applyColor(instance, color, original)
	if not original then return end
	for prop in pairs(original) do
		pcall(function() instance[prop] = color end)
	end
	-- UIGradient especial
	local grad = instance:FindFirstChild("UIGradient")
	if grad then
		pcall(function() grad.Color = ColorSequence.new(color) end)
	end
end

local function restoreColor(instance, original)
	if not original then return end
	for prop, val in pairs(original) do
		pcall(function() instance[prop] = val end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- REGISTRO DE INSTANCIAS
-- ═══════════════════════════════════════════════════════════════════
local function registerInstance(instance, localBlacklist)
	if registry[instance] then return end

	-- Verificar blacklist (incluye carpetas con "/")
	if isBlacklisted(instance, localBlacklist) then return end

	local props = getColorProperties(instance)
	if props then
		registry[instance] = props
	end
end

local function unregisterInstance(instance)
	if registry[instance] then
		restoreColor(instance, registry[instance])
		registry[instance] = nil
	end
end

local function scanContainer(container, recursive, localBlacklist)
	if not container then return end

	local function process(inst)
		if inst:IsA("BasePart") or inst:IsA("UnionOperation") or 
			inst:IsA("GuiObject") or inst:IsA("Decal") then
			registerInstance(inst, localBlacklist)
		end
	end

	for _, child in ipairs(container:GetChildren()) do
		process(child)
		if recursive then
			for _, desc in ipairs(child:GetDescendants()) do
				process(desc)
			end
		end
	end

	-- Conexiones dinámicas
	local addConn, remConn

	if recursive then
		addConn = container.DescendantAdded:Connect(function(desc)
			task.defer(function() registerInstance(desc, localBlacklist) end)
		end)
		remConn = container.DescendantRemoving:Connect(function(desc)
			task.defer(function() unregisterInstance(desc) end)
		end)
	else
		addConn = container.ChildAdded:Connect(function(child)
			task.defer(function() registerInstance(child, localBlacklist) end)
		end)
		remConn = container.ChildRemoved:Connect(function(child)
			task.defer(function() unregisterInstance(child) end)
		end)
	end

	table.insert(connections, addConn)
	table.insert(connections, remConn)
end

-- ═══════════════════════════════════════════════════════════════════
-- COMUNICACIÓN
-- ═══════════════════════════════════════════════════════════════════
local function setupRemotes()
	local toneModeEvent = ReplicatedStorage:FindFirstChild("ToneModeChanged")
	if not toneModeEvent then
		toneModeEvent = Instance.new("BindableEvent")
		toneModeEvent.Name = "ToneModeChanged"
		toneModeEvent.Parent = ReplicatedStorage
	end

	local getModeFunction = ReplicatedStorage:FindFirstChild("GetToneMode")
	if not getModeFunction then
		getModeFunction = Instance.new("BindableFunction")
		getModeFunction.Name = "GetToneMode"
		getModeFunction.Parent = ReplicatedStorage
	end

	getModeFunction.OnInvoke = function()
		return state.mode
	end

	toneModeEvent.Event:Connect(function(mode, themeName)
		RainbowSync.SetMode(mode, themeName)
	end)

	-- Color3Value para clientes
	local rainbowValue = ReplicatedStorage:FindFirstChild("RainbowColor")
	if not rainbowValue then
		rainbowValue = Instance.new("Color3Value")
		rainbowValue.Name = "RainbowColor"
		rainbowValue.Value = CONFIG.rainbowColors[1]
		rainbowValue.Parent = ReplicatedStorage
	end

	return rainbowValue
end

-- ═══════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL (Optimizado)
-- ═══════════════════════════════════════════════════════════════════
local function startUpdateLoop(rainbowValue)
	local updateInterval = 1/30 -- 30 FPS para colores (suficiente para visual)
	local accumulator = 0

	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < updateInterval then return end
		accumulator = 0

		if state.mode == "disabled" then
			for instance, original in pairs(registry) do
				restoreColor(instance, original)
			end
			return
		end

		-- Calcular color
		state.progress += dt / CONFIG.speed
		if state.progress >= 1 then
			state.progress = 0
			state.colorIndex = state.colorIndex % #state.colors + 1
		end

		local current = state.colors[state.colorIndex]
		local nextIdx = state.colorIndex % #state.colors + 1
		local lerpedColor = current:Lerp(state.colors[nextIdx], state.progress)

		-- Aplicar a todas las instancias registradas
		for instance, original in pairs(registry) do
			applyColor(instance, lerpedColor, original)
		end

		-- Actualizar valor compartido
		pcall(function() rainbowValue.Value = lerpedColor end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════
function RainbowSync.Init()
	-- Escanear rutas configuradas
	for _, cfg in ipairs(CONFIG.paths) do
		local container = resolvePath(cfg.path)
		if container then
			scanContainer(container, cfg.recursive, cfg.blacklist)
		else
			warn("RainbowSync: Ruta no encontrada:", cfg.path)
		end
	end

	-- Escanear UI
	for _, cfg in ipairs(CONFIG.uiPaths) do
		local container = resolvePath(cfg.path)
		if container then
			if cfg.pattern then
				for _, child in ipairs(container:GetChildren()) do
					if child.Name:find(cfg.pattern) then
						registerInstance(child, cfg.blacklist)
					end
				end
			else
				registerInstance(container, cfg.blacklist)
			end
		end
	end

	local rainbowValue = setupRemotes()
	startUpdateLoop(rainbowValue)

	-- Contar instancias registradas
	local count = 0
	for _ in pairs(registry) do count += 1 end
	print("RainbowSync: Inicializado con", count, "instancias")
end

function RainbowSync.SetMode(mode, themeName)
	state.mode = mode
	state.progress = 0
	state.colorIndex = 1

	if mode == "rainbow" then
		state.colors = CONFIG.rainbowColors
	elseif mode == "theme" and themeName and CONFIG.themes[themeName] then
		state.theme = themeName
		state.colors = CONFIG.themes[themeName]
	end
end

function RainbowSync.GetCurrentMode()
	return state.mode
end

function RainbowSync.GetCurrentTheme()
	return state.theme
end

function RainbowSync.GetAvailableThemes()
	local list = {}
	for name in pairs(CONFIG.themes) do
		table.insert(list, name)
	end
	return list
end

-- Añadir rutas dinámicamente en runtime
function RainbowSync.AddPath(pathString, recursive, blacklist)
	local container = resolvePath(pathString)
	if container then
		scanContainer(container, recursive, blacklist)
		return true
	end
	return false
end

-- Auto-inicializar
RainbowSync.Init()

return RainbowSync