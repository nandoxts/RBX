-- PisoDiscoLocalEffect.lua
-- LocalScript para aplicar el efecto NEON radial solo en el cliente

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local rootName = "PISODISCO"

-- Parámetros ajustables
local BASE_R, BASE_G, BASE_B = 96/255, 35/255, 209/255
local RADIAL_WAVELENGTH = 6.0
local RADIAL_SPEED = 1.2
local SPATIAL_SCALE = 1
local BRIGHT_MULT = 1.15
local BRIGHT_ADD = 0.04
local UPDATE_RATE = 1 -- usar RenderStepped

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

local function rgbToHsv(r, g, b)
    local maxv = math.max(r, g, b)
    local minv = math.min(r, g, b)
    local h, s, v = 0, 0, maxv
    local d = maxv - minv
    if maxv ~= 0 then s = d / maxv else s = 0 end
    if d == 0 then
        h = 0
    else
        if maxv == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif maxv == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

-- calculos base
local BASE_H, BASE_S, BASE_V = rgbToHsv(BASE_R, BASE_G, BASE_B)

local visualsFolder = Instance.new("Folder")
visualsFolder.Name = "_LOCAL_PISO_DISCO_VISUALS_" .. player.Name
visualsFolder.Parent = Workspace

-- Encuentra el root
local root = Workspace:FindFirstChild(rootName)
if not root then
    -- no hay piso, salir silenciosamente
    return
end

-- Colección de referencias: original -> visual clone
local clones = {}

-- Recolectar partes numeradas dentro de cada disco
local partsList = {}
for _, disc in ipairs(root:GetChildren()) do
    local discIndex = tonumber(disc.Name:match("%d+"))
    if discIndex then
        for _, obj in ipairs(disc:GetDescendants()) do
            if obj:IsA("BasePart") then
                local pi = tonumber(obj.Name)
                if pi then
                    table.insert(partsList, {orig = obj, disc = discIndex})
                end
            end
        end
    end
end

-- Crear clones visuales
for _, info in ipairs(partsList) do
    local orig = info.orig
    local c = Instance.new("Part")
    c.Size = orig.Size
    c.CFrame = orig.CFrame
    c.Anchored = true
    c.CanCollide = false
    c.CastShadow = false
    c.Material = Enum.Material.Neon
    c.Transparency = 0
    c.Parent = visualsFolder
    clones[orig] = c
end

-- Centro (se recalcula por frame)
local t0 = os.clock()

local function getCenterPos()
    local ok, cframe = pcall(function() return root:GetBoundingBox() end)
    if ok and cframe then return cframe.Position end
    -- fallback: promedio de primeras partes
    local acc = Vector3.new()
    local count = 0
    for orig, _ in pairs(clones) do
        if orig and orig.Parent then
            acc = acc + orig.Position
            count = count + 1
        end
    end
    if count > 0 then return acc / count end
    if root.PrimaryPart then return root.PrimaryPart.Position end
    return root:GetModelCFrame().p
end

RunService.RenderStepped:Connect(function(dt)
    local t = os.clock() - t0
    local center = getCenterPos()
    for orig, clone in pairs(clones) do
        if not orig or not orig.Parent then
            if clone and clone.Parent then clone:Destroy() end
            clones[orig] = nil
        else
            -- sincronizar posición
            clone.CFrame = orig.CFrame
            -- color radial
            local dist = (orig.Position - center).Magnitude * SPATIAL_SCALE
            local phase = (dist / RADIAL_WAVELENGTH) - (t * RADIAL_SPEED)
            local factor = (math.sin(phase * math.pi * 2) * 0.5 + 0.5)
            local v = math.clamp(factor * BRIGHT_MULT + BRIGHT_ADD, 0, 1)
            local r,g,b = hsvToRgb(BASE_H, BASE_S, v)
            clone.Color = Color3.new(r,g,b)
        end
    end
end)

-- Cleanup al salir
player.AncestryChanged:Connect(function()
    if not player:IsDescendantOf(game) then
        if visualsFolder and visualsFolder.Parent then visualsFolder:Destroy() end
    end
end)

root.DescendantRemoving:Connect(function(desc)
    if clones[desc] then
        clones[desc]:Destroy()
        clones[desc] = nil
    end
end)

print("PisoDiscoLocalEffect: visuales locales creados para", player.Name)
