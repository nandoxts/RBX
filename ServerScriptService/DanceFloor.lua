-- MODERN DANCE FLOOR v9 - MÍNIMO ABSOLUTO
-- 1 Part, 1 línea central, diagonales densas, 0 loops

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local W, D = 84, 84
local SPACING = 6
local activeFloor

local COLOR = ColorSequence.new(Color3.new(1, 1, 1))
local TRANSP = NumberSequence.new(0)

local function clip(x1, z1, x2, z2, hW, hD)
	local function c(x, z)
		local r = 0
		if x < -hW then r = r + 1 elseif x > hW then r = r + 2 end
		if z < -hD then r = r + 4 elseif z > hD then r = r + 8 end
		return r
	end
	local c1, c2 = c(x1, z1), c(x2, z2)
	for _ = 1, 10 do
		if c1 == 0 and c2 == 0 then return x1, z1, x2, z2 end
		if bit32.band(c1, c2) ~= 0 then return nil end
		local cc = c1 ~= 0 and c1 or c2
		local x, z
		if bit32.band(cc, 8) ~= 0 then x = x1+(x2-x1)*(hD-z1)/(z2-z1); z = hD
		elseif bit32.band(cc, 4) ~= 0 then x = x1+(x2-x1)*(-hD-z1)/(z2-z1); z = -hD
		elseif bit32.band(cc, 2) ~= 0 then z = z1+(z2-z1)*(hW-x1)/(x2-x1); x = hW
		else z = z1+(z2-z1)*(-hW-x1)/(x2-x1); x = -hW end
		if cc == c1 then x1, z1, c1 = x, z, c(x, z) else x2, z2, c2 = x, z, c(x, z) end
	end
	return nil
end

local function beam(base, pA, pB, w)
	local a0 = Instance.new("Attachment"); a0.Position = pA; a0.Parent = base
	local a1 = Instance.new("Attachment"); a1.Position = pB; a1.Parent = base
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Brightness = 3
	b.Color = COLOR
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Texture = "rbxassetid://7928096707"
	b.TextureLength = 28.154
	b.TextureMode = Enum.TextureMode.Wrap
	b.TextureSpeed = 1.4
	b.Transparency = TRANSP
	b.FaceCamera = false
	b.Segments = 3
	b.Width0 = w or 0.23
	b.Width1 = w or 0.23
	b.CurveSize0, b.CurveSize1, b.ZOffset = 0, 0, 0
	b.Parent = base
end

local function build()
	if activeFloor then activeFloor:Destroy(); task.wait(0.1) end

	-- Posición cerca del jugador
	local origin = Vector3.new(0, 2, 0)
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		if ch then
			local h = ch:FindFirstChild("HumanoidRootPart")
			if h then
				local lk = h.CFrame.LookVector
				origin = Vector3.new(h.Position.X + lk.X * 15, h.Position.Y - 3, h.Position.Z + lk.Z * 15)
				break
			end
		end
	end

	-- 1 SOLA PART
	local base = Instance.new("Part")
	base.Name = "ModernDanceFloor"
	base.Size = Vector3.new(W, 0.2, D)
	base.Position = origin
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(6, 6, 10)
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Reflectance = 0.08
	base.CastShadow = false

	local hW, hD = W / 2, D / 2
	local y = 0.15
	local n = 0

	-- DIAGONALES
	local off = -(hW + hD)
	while off <= hW + hD do
		local cx1, cz1, cx2, cz2 = clip(off - hD, -hD, off + hD, hD, hW, hD)
		if cx1 and (cx2-cx1)^2+(cz2-cz1)^2 > 1 then
			beam(base, Vector3.new(cx1, y, cz1), Vector3.new(cx2, y, cz2))
			n = n + 1
		end
		cx1, cz1, cx2, cz2 = clip(off - hD, hD, off + hD, -hD, hW, hD)
		if cx1 and (cx2-cx1)^2+(cz2-cz1)^2 > 1 then
			beam(base, Vector3.new(cx1, y, cz1), Vector3.new(cx2, y, cz2))
			n = n + 1
		end
		off = off + SPACING
	end

	-- BORDE
	local c = {Vector3.new(-hW,y,-hD), Vector3.new(hW,y,-hD), Vector3.new(hW,y,hD), Vector3.new(-hW,y,hD)}
	for i = 1, 4 do beam(base, c[i], c[i%4+1], 0.3); n = n + 1 end

	base.Parent = Workspace
	activeFloor = base
	print("✅ Pista: 1 Part, " .. n .. " beams, 0 loops")
end

-- Esperar jugador y crear
task.spawn(function()
	local w = 0
	while w < 30 do
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				task.wait(1)
				build()
				return
			end
		end
		task.wait(1); w = w + 1
	end
	build()
end)

_G.DestroyDanceFloor = function()
	if activeFloor then activeFloor:Destroy(); activeFloor = nil end
end

_G.RecreateDanceFloor = function()
	_G.DestroyDanceFloor(); task.wait(0.2); build()
end