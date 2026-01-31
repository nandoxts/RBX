-- PurpleFloor_Controller.lua
-- ServerScriptService
-- SOLO anima un piso YA EXISTENTE: Workspace.DYNAMIC_PURPLE_FLOOR.Tiles
-- No crea, no destruye, no renombra.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CFG = {
	MODEL_NAME = "DYNAMIC_PURPLE_FLOOR",
	TILES_FOLDER = "Tiles",

	-- Morado fijo
	HUE = 0.80,
	SAT = 0.92,

	-- Base (centro->borde) sin negro (excepto esquinas)
	V_CENTER = 0.78,
	V_EDGE   = 0.36,
	CENTER_FALLOFF = 1.18,

	-- Esquinas negras
	V_CORNER = 0.02,
	CORNER_K = 2.3,
	CORNER_POWER = 2.7,

	-- Ondas
	WAVE_SPEED = 5,
	WAVE_LENGTH = 24.0,
	WAVE_STRENGTH = 0.16,
	WAVE_POWER = 1.35,
	WAVE_CENTER_BIAS = 0.88,

	-- Highlight central
	HIGHLIGHT_ENABLE = true,
	HIGHLIGHT_RADIUS = 0.45,
	HIGHLIGHT_BOOST = 0.10,

	-- Ruido mínimo
	NOISE_STRENGTH = 0.012,
	NOISE_SCALE = 0.08,

	-- Performance
	UPDATE_EVERY = 1,
}

-- ===== Utils =====
local function hsvToRgb(h, s, v)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	return r, g, b
end

local function lerp(a,b,t) return a + (b-a)*t end
local function clamp01(x) return math.clamp(x, 0, 1) end

-- ===== Encontrar modelo y tiles =====
local model = Workspace:FindFirstChild(CFG.MODEL_NAME)
if not model then
	warn("PurpleFloor_Controller: No existe el modelo en Workspace:", CFG.MODEL_NAME)
	return
end

local tilesFolder = model:FindFirstChild(CFG.TILES_FOLDER)
if not tilesFolder then
	warn("PurpleFloor_Controller: No existe la carpeta Tiles:", CFG.TILES_FOLDER)
	return
end

-- Centro y medidas del modelo (para normalizar sin depender de cómo fue creado)
local ok, cframe, size = pcall(function() return model:GetBoundingBox() end)
local origin = ok and cframe.Position or Vector3.new()

local maxX = math.max(size.X * 0.5, 0.001)
local maxZ = math.max(size.Z * 0.5, 0.001)
local maxR = math.sqrt(maxX*maxX + maxZ*maxZ)

-- Cache de tiles (para no recalcular todo)
local tiles = {}
for _, inst in ipairs(tilesFolder:GetChildren()) do
	if inst:IsA("BasePart") then
		local pos = inst.Position
		local rel = pos - origin
		local x, z = rel.X, rel.Z
		local r = Vector3.new(x,0,z).Magnitude / maxR
		local ax = math.abs(x) / maxX
		local az = math.abs(z) / maxZ
		tiles[#tiles+1] = { part = inst, pos = pos, r=r, ax=ax, az=az }
	end
end

if #tiles == 0 then
	warn("PurpleFloor_Controller: No hay tiles dentro de Tiles/")
	return
end

print(("PurpleFloor_Controller: tiles cargados=%d, origin=(%.1f,%.1f,%.1f)"):format(
	#tiles, origin.X, origin.Y, origin.Z
	))

-- ===== Animación =====
local t0 = os.clock()
local frame = 0

RunService.Heartbeat:Connect(function()
	frame += 1
	if (frame % math.max(1, CFG.UPDATE_EVERY)) ~= 0 then return end

	local t = os.clock() - t0

	for _, it in ipairs(tiles) do
		local part = it.part
		if part and part.Parent then
			-- Base degradado centro->borde
			local centerT = (clamp01(it.r)) ^ CFG.CENTER_FALLOFF
			local vBase = lerp(CFG.V_CENTER, CFG.V_EDGE, centerT)

			-- Ondas
			local w = math.sin((it.r * maxR / CFG.WAVE_LENGTH) * math.pi * 2 - t * CFG.WAVE_SPEED) * 0.5 + 0.5
			local crest = w ^ CFG.WAVE_POWER
			local centerMask = (1 - it.r) ^ (1 / CFG.WAVE_CENTER_BIAS)
			local vWave = (crest - 0.5) * 2 * CFG.WAVE_STRENGTH * centerMask

			-- Highlight centro
			local vHigh = 0
			if CFG.HIGHLIGHT_ENABLE then
				local rr = clamp01(it.r / math.max(CFG.HIGHLIGHT_RADIUS, 0.001))
				local hmask = 1 - (rr ^ 2.2)
				vHigh = hmask * CFG.HIGHLIGHT_BOOST
			end

			-- Esquinas negras
			local cornerMask = (it.ax ^ CFG.CORNER_K) * (it.az ^ CFG.CORNER_K)
			local vCorner = lerp(vBase + vWave + vHigh, CFG.V_CORNER, cornerMask ^ CFG.CORNER_POWER)

			-- Ruido mínimo
			local noise = 0
			if CFG.NOISE_STRENGTH > 0 then
				noise = (math.noise(it.pos.X * CFG.NOISE_SCALE, it.pos.Z * CFG.NOISE_SCALE, t*0.2)*2-1) * CFG.NOISE_STRENGTH
			end

			local v = math.clamp(vCorner + noise, 0, 1)
			local r,g,b = hsvToRgb(CFG.HUE, CFG.SAT, v)
			part.Color = Color3.new(r,g,b)
		end
	end
end)
