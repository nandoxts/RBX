--[[
	Icons.lua - UIComponents
	Crea íconos vectoriales con frames puros de Roblox (sin imágenes ni texto).
	Patrón similar a SearchModern.lua.

	API:
		Icons.plus(parent, options)   → "+" añadir
		Icons.check(parent, options)  → "✓" confirmado
		Icons.cross(parent, options)  → "×" eliminar
		Icons.play(parent, options)   → "▷" reproducir / chevron

	options: {
		color        -- Color3, default blanco
		size         -- UDim2, default 60%×60% del padre
		position     -- UDim2, default centrado (0.5, 0, 0.5, 0)
		anchorPoint  -- Vector2, default (0.5, 0.5)
		thickness    -- number 0-1 (relativo), default 0.12
		z            -- ZIndex base, default 1
		name         -- nombre del frame raíz
		visible      -- bool, default true
	}
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

local Icons = {}

-- ────────────────────────────────────────────────────────────────
-- INTERNOS
-- ────────────────────────────────────────────────────────────────
local function makeContainer(parent, options)
	local f = Instance.new("Frame")
	f.AnchorPoint = options.anchorPoint or Vector2.new(0.5, 0.5)
	f.Size       = options.size       or UDim2.new(0.58, 0, 0.58, 0)
	f.Position   = options.position   or UDim2.new(0.5, 0, 0.5, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = options.z or 1
	f.Visible = options.visible ~= false
	f.Name = options.name or "IconContainer"
	f.Parent = parent
	return f
end

-- bar: barra redondeada, posicionada relativa al contenedor
-- ax,ay = anchorPoint;  rx,ry = posición relativa;  rw,rh = tamaño relativo;  rot = rotación
local function makeBar(parent, ax, ay, rx, ry, rw, rh, rot, color, z)
	local f = Instance.new("Frame")
	f.AnchorPoint    = Vector2.new(ax, ay)
	f.Size           = UDim2.new(rw, 0, rh, 0)
	f.Position       = UDim2.new(rx, 0, ry, 0)
	f.Rotation       = rot
	f.BackgroundColor3 = color
	f.BorderSizePixel  = 0
	f.ZIndex = z
	f.Parent = parent
	UI.rounded(f, 99)
	return f
end

-- ────────────────────────────────────────────────────────────────
-- Icons.plus  →  "+"
-- ────────────────────────────────────────────────────────────────
function Icons.plus(parent, options)
	options = options or {}
	local color = options.color or Color3.new(1, 1, 1)
	local z     = options.z or 1
	local thick = options.thickness or 0.13

	local c = makeContainer(parent, options)
	c.Name = options.name or "PlusIcon"

	-- barra horizontal
	makeBar(c,  0.5, 0.5,  0.5, 0.5,  1,     thick, 0,  color, z + 1)
	-- barra vertical
	makeBar(c,  0.5, 0.5,  0.5, 0.5,  thick, 1,     0,  color, z + 1)

	return c
end

-- ────────────────────────────────────────────────────────────────
-- Icons.check  →  "✓"
-- ────────────────────────────────────────────────────────────────
function Icons.check(parent, options)
	options = options or {}
	local color = options.color or Color3.new(1, 1, 1)
	local z     = options.z or 1
	local thick = options.thickness or 0.13

	local c = makeContainer(parent, options)
	c.Name = options.name or "CheckIcon"

	-- Pierna corta (abajo-izquierda del check), inclinada hacia abajo-derecha
	makeBar(c,  1,   0.5,  0.44, 0.64,  0.38, thick, 45,  color, z + 1)
	-- Pierna larga (arriba-derecha del check), inclinada hacia arriba-derecha
	makeBar(c,  0,   0.5,  0.36, 0.52,  0.68, thick, -52, color, z + 1)

	return c
end

-- ────────────────────────────────────────────────────────────────
-- Icons.cross  →  "×"
-- ────────────────────────────────────────────────────────────────
function Icons.cross(parent, options)
	options = options or {}
	local color = options.color or Color3.new(1, 1, 1)
	local z     = options.z or 1
	local thick = options.thickness or 0.13

	local c = makeContainer(parent, options)
	c.Name = options.name or "CrossIcon"

	makeBar(c,  0.5, 0.5,  0.5, 0.5,  1, thick,  45,  color, z + 1)
	makeBar(c,  0.5, 0.5,  0.5, 0.5,  1, thick, -45,  color, z + 1)

	return c
end

-- ────────────────────────────────────────────────────────────────
-- Icons.play  →  "▷"  (dos barras formando un chevron >)
-- ────────────────────────────────────────────────────────────────
function Icons.play(parent, options)
	options = options or {}
	local color = options.color or Color3.new(1, 1, 1)
	local z     = options.z or 1
	local thick = options.thickness or 0.13

	local c = makeContainer(parent, options)
	c.Name = options.name or "PlayIcon"

	-- Mitad superior del chevron ">"
	makeBar(c,  0,   0.5,  0.14, 0.30,  0.62, thick, -42, color, z + 1)
	-- Mitad inferior
	makeBar(c,  0,   0.5,  0.14, 0.70,  0.62, thick,  42, color, z + 1)

	return c
end

return Icons
