-- Script para agregar efecto de brillo parpadeante a los bloques de texto (MeshParts)
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Buscar el contenedor de texto
local contenedor = Workspace:WaitForChild("TextoJenifer3D")

-- Colores para el efecto
local ROSA_PASTEL = Color3.fromRGB(255, 192, 203)
local ROSA_BRILLANTE = Color3.fromRGB(255, 105, 180)
local ROSA_BLANCO = Color3.fromRGB(255, 220, 230)

-- Función para crear efecto de parpadeo en un MeshPart
local function agregarEfectoParpadeo(parte)
	-- Agregar PointLight si no existe
	local luz = parte:FindFirstChild("PointLight")
	if not luz then
		luz = Instance.new("PointLight")
		luz.Color = ROSA_PASTEL
		luz.Brightness = 2
		luz.Range = 30
		luz.Parent = parte
	end
	
	-- Animación de parpadeo aleatorio
	local function animarParpadeo()
		while parte and parte.Parent do
			-- Espera aleatoria entre parpadeos
			local espera = math.random(10, 30) / 10 -- Entre 1 y 3 segundos
			task.wait(espera)
			
			-- Guardar color original
			local colorOriginal = parte.Color
			local tweenInfo = TweenInfo.new(
				0.15,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut
			)
			
			-- Destello brillante (cambio de color)
			local tweenBrillo = TweenService:Create(parte, tweenInfo, {Color = ROSA_BRILLANTE})
			tweenBrillo:Play()
			
			-- Aumentar brillo del PointLight
			if luz then
				local tweenLuz = TweenService:Create(luz, tweenInfo, {Brightness = 5})
				tweenLuz:Play()
			end
			
			task.wait(0.15)
			
			-- Volver al color original
			local tweenVuelta = TweenService:Create(parte, tweenInfo, {Color = colorOriginal})
			tweenVuelta:Play()
			
			-- Reducir brillo del PointLight
			if luz then
				local tweenLuzVuelta = TweenService:Create(luz, TweenInfo.new(0.15), {Brightness = 2})
				tweenLuzVuelta:Play()
			end
		end
	end
	
	task.spawn(animarParpadeo)
end

-- Aplicar efecto a todas las partes/meshparts en el contenedor
for _, parte in ipairs(contenedor:GetDescendants()) do
	if parte:IsA("BasePart") then
		agregarEfectoParpadeo(parte)
	end
end

-- Agregar efecto a nuevas partes que se creen
contenedor.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") then
		task.wait(0.1)
		agregarEfectoParpadeo(descendant)
	end
end)

print("✨ Efecto de brillo parpadeante agregado a los MeshParts ✨")
