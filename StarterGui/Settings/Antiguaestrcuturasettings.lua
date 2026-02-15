-- // - REFERENCIAS - // --

-- /////////// GAMEPLAY /////////// --
-- Botón para activar/desactivar observar chat
local chatFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Gameplay"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Chat")
local chatButton = chatFrame:WaitForChild("BChat")
-- Botón para activar/desactivar Tags jugadores
local viewTagsUsersFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Gameplay"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("ViewTagsUsers")
local viewTagsUsersButton = viewTagsUsersFrame:WaitForChild("BViewTagsUsers")
-- Botón para activar/desactivar la bandera propia
local ViewFlagUserFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Gameplay"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("ViewFlagUser")
local ViewFlagUserButton = ViewFlagUserFrame:WaitForChild("BViewFlagUser")
-- Botón para activar/desactivar observar jugadores
local viewUsersFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Gameplay"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("ViewUsers")
local viewUsersButton = viewUsersFrame:WaitForChild("BViewUsers")
-- Botón para activar/desactivar el gui de seleccion
local viewSelected = script.Parent:WaitForChild("Settings"):WaitForChild("Gameplay"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("ViewSelected")
local viewSelectedButton = viewSelected:WaitForChild("BViewSelected")
------------------------------------------------------------------------------------------------------------------
-- /////////// PERFORMANCE /////////// --
-- Botón para activar/desactivar atmosfera
local atmosphereFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Atmosphere")
local atmosphereButton = atmosphereFrame:WaitForChild("BAtmosphere")
-- Botón para activar/desactivar desenfoque
local blurFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Blur")
local blurButton = blurFrame:WaitForChild("BBlur")
-- Botón para activar/desactivar las nubes
local cloudsFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Clouds")
local cloudsButton = cloudsFrame:WaitForChild("BClouds")
local lightingclouds = game:GetService("Workspace"):WaitForChild("Terrain").Clouds
-- Botón para activar/desactivar las Correcion de colores
local cCorrectionFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("ColorCorrection")
local cCorrectionButton = cCorrectionFrame:WaitForChild("BCCorrection")
-- Botón para activar/desactivar la profundidad de campo
local DoFFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("DepthOfField")
local DoFButton = DoFFrame:WaitForChild("BDoF")
-- Botón para activar/desactivar difuciones
local diffuseFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Diffuse")
local diffuseButton = diffuseFrame:WaitForChild("BDiffuse")
-- Botón para activar/desactivar partículas
local particlesFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Particles")
local particlesButton = particlesFrame:WaitForChild("BParticles")
-- Botón para activar/desactivar reflejos
local reflectionsFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Reflections")
local reflectionsButton = reflectionsFrame:WaitForChild("BReflections")
-- Botón para activar/desactivar sombras
local shadowsFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Shadows")
local shadowsButton = shadowsFrame:WaitForChild("BShadows")
-- Botón para activar/desactivar texturas
local texturesFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Textures")
local texturesButton = texturesFrame:WaitForChild("BTextures")
-- Botón para activar/desactivar partículas
local effectsFrame = script.Parent:WaitForChild("Settings"):WaitForChild("Performance"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("Effects")
local effectsButton = effectsFrame:WaitForChild("BEffects")
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- /////////// SOUNDS /////////// --
local SoundService = game:GetService("SoundService")
local MainSounds = SoundService:FindFirstChild("MainSounds")
-- Botón para activar/desactivar sonido de cargado
--local SCarry = script.Parent:WaitForChild("Settings"):WaitForChild("Sounds"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("SoundCarry")
--local BSCarry = SCarry:WaitForChild("BCarry")
--local SoundC = MainSounds.Notify
-- Botón para activar/desactivar sonido de Discord
local SDiscord = script.Parent:WaitForChild("Settings"):WaitForChild("Sounds"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("SoundDiscord")
local BSDiscord = SDiscord:WaitForChild("BDiscord")
local SoundD = MainSounds.NDC
-- Botón para activar/desactivar twitter
local STwitter = script.Parent:WaitForChild("Settings"):WaitForChild("Sounds"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("SoundTwitter")
local BSTwitter = STwitter:WaitForChild("BTwitter")
local SoundT = MainSounds.NX
-- Botón para activar/desactivar sonido de whatsapp
local SWhatsApp = script.Parent:WaitForChild("Settings"):WaitForChild("Sounds"):WaitForChild("Container"):WaitForChild("List"):WaitForChild("SoundWhatsApp")
local BSWhatsApp = SWhatsApp:WaitForChild("BWhatsApp")
local SoundW = MainSounds.NWSP
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

-- // - INICIALIZADORES - // --

-- /////////// GAMEPLAY /////////// --
local initialChat = true -- Ver la burbuja de chat
--local initialViewDeviceUser = true -- Ver dispositivo
local initialViewFlagUser = false -- Ver bandera
--local initialViewRankUser = true -- Ver el rank
local initialSelected = true -- Ver cuadro de seleccion
--local initialViewTagUser = true -- Ver el tag
local initialViewTagsUsers = true -- Ver los tags de los usuarios
local initialViewUsers = true -- Ver a los usuarios
------------------------------------------
-- /////////// PERFORMANCE /////////// --
local initialAtmosphere = true
local initialBlur = true
local initialClouds = true
local initialCCorrection = false
local initialDoF = false
local initialDiffuse = true
local initialParticles = true
local initialReflections = true
local initialShadows = true
local initialTextures = true
------------------------------------------
local SpecialEffects = true  -- Esta variable controlará el atributo para todos los usuarios
------------------------------------------
-- /////////// SOUNDS /////////// --
local initialSDiscord = true
local initialSCarry = true
local initialSWhatsApp = true
local initialSTwitter = true
------------------------------------------------------------------------------------------------------------------

-- Función para actualizar el atributo SpecialEffects en todos los jugadores
local function updateSpecialEffectsAttribute(value)
	for _, player in pairs(game.Players:GetPlayers()) do
		if value then
			player:SetAttribute("SpecialEffects", true)
		else
			player:SetAttribute("SpecialEffects", nil)  -- o false, dependiendo de lo que prefieras
		end
	end
end

-- Función para manejar nuevos jugadores
local function handleNewPlayer(player)
	if SpecialEffects then
		player:SetAttribute("SpecialEffects", true)
	else
		player:SetAttribute("SpecialEffects", nil)
	end
end

-- Configuración inicial
updateSpecialEffectsAttribute(SpecialEffects)

-- Manejar jugadores existentes al iniciar
for _, player in pairs(game.Players:GetPlayers()) do
	handleNewPlayer(player)
end

-- Manejar nuevos jugadores que se unan
game.Players.PlayerAdded:Connect(handleNewPlayer)

------------------------------------------------------------------------------------------------------------------

-- /////////// BOTON GENERAL - COLORES /////////// --
-- Función para cambiar estado del botón y su color
local function toggleButton(button, isActive)
	if isActive then
		button.ImageColor3 = Color3.fromHex('#484848') -- ON
		button.Rotation = 0
	else
		button.ImageColor3 = Color3.fromHex('#606060') -- OFF
		button.Rotation = 180
	end
end
------------------------------------------
-- Lista de clases de efectos visuales que se desactivarán
local visualEffects = {
	"ParticleEmitter",
	--"PointLight",
	--"SurfaceLight",
	"Fire",
	"Smoke",
	"Sparkles",
	"Trail"
}

-- // - BOTONES INICIALES - // --

-- /////////// GAMEPLAY /////////// --
-- Configuración inicial para la burbuja de chat
game.Chat.BubbleChatEnabled = initialChat
toggleButton(chatButton, initialChat) -- Actualizar el botón al iniciar
-- Configuración inicial para observar Tags jugadores
toggleButton(viewTagsUsersButton, initialViewTagsUsers)
-- Configuración inicial para observar jugadores
toggleButton(viewUsersButton, initialViewUsers)
-- Configuración inicial para el gui de seleccion
toggleButton(viewSelectedButton, initialSelected)
-- Configuración inicial para observar la bandera de tu personaje
toggleButton(ViewFlagUserButton, initialViewFlagUser)
------------------------------------------
-- /////////// PERFORMANCE /////////// --
-- Configuración inicial para la atmosfera
game.Lighting.Atmosphere.Density = initialAtmosphere and 0.3 or 0
toggleButton(atmosphereButton, initialAtmosphere)
-- Configuración inicial para el desenfoque
game.Lighting.Desenfoque.Size = initialBlur and 2 or 0
toggleButton(blurButton, initialBlur)
-- Configuración inicial para las nubes
game.Workspace.Terrain.Clouds.Enabled = initialClouds
toggleButton(cloudsButton, initialClouds)
-- Configuración inicial para la correcion de colores
toggleButton(cCorrectionButton, initialCCorrection)
-- Configuración inicial para la profundidad de campo
toggleButton(DoFButton, initialDoF)
-- Configuración inicial para difusiones
game.Lighting.EnvironmentDiffuseScale = initialDiffuse and 1 or 0
toggleButton(diffuseButton, initialDiffuse)

-- Configuración inicial para las particulas
toggleButton(particlesButton, initialParticles)
-- Configuración inicial para reflejos
game.Lighting.EnvironmentSpecularScale = initialReflections and 1 or 0
toggleButton(reflectionsButton, initialReflections)
-- Configuración inicial para sombras
game.Lighting.GlobalShadows = initialShadows
toggleButton(shadowsButton, initialShadows)
-- Configuración inicial para las texturas
toggleButton(texturesButton, initialTextures)

------------------------------------------
-- Configuración inicial para las particulas
toggleButton(effectsButton, SpecialEffects)
------------------------------------------
-- /////////// SOUNDS /////////// --
--toggleButton(BSCarry, initialSCarry)
toggleButton(BSDiscord, initialSDiscord)
toggleButton(BSTwitter, initialSTwitter)
toggleButton(BSWhatsApp, initialSWhatsApp)
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- Conectar los botones a sus funciones
--[[
BSCarry.MouseButton1Click:Connect(function()
	initialSCarry = not initialSCarry
	toggleButton(BSCarry, initialSCarry)
	SoundC.Volume = initialSCarry and 1 or 0
end)
]]

BSDiscord.MouseButton1Click:Connect(function()
	initialSDiscord = not initialSDiscord
	toggleButton(BSDiscord, initialSDiscord)
	SoundD.Volume = initialSDiscord and 0.5 or 0
end)

BSTwitter.MouseButton1Click:Connect(function()
	initialSTwitter = not initialSTwitter
	toggleButton(BSTwitter, initialSTwitter)
	SoundT.Volume = initialSTwitter and 0.5 or 0
end)

BSWhatsApp.MouseButton1Click:Connect(function()
	initialSWhatsApp = not initialSWhatsApp
	toggleButton(BSWhatsApp, initialSWhatsApp)
	SoundW.Volume = initialSWhatsApp and 0.5 or 0
end)
------------------------------------------------------------------------------------------------------------------


-- Función para activar o desactivar efectos visuales
local function SetVisualEffects(container, activate)
	for _, descendant in pairs(container:GetDescendants()) do
		for _, effect in pairs(visualEffects) do
			if descendant:IsA(effect) then
				descendant.Enabled = activate
			end
		end
	end
end

-- Función para manejar los efectos visuales de los ítems de los jugadores
local function HandlePlayerItems(player, activate)
	if player.Character then
		SetVisualEffects(player.Character, activate)
	end
end

-- Configuración inicial para los efectos visuales en función de `initialParticles`
if SpecialEffects then
	SetVisualEffects(game.Workspace, true)
	for _, player in pairs(game.Players:GetPlayers()) do
		HandlePlayerItems(player, true)
	end
else
	SetVisualEffects(game.Workspace, false)
	for _, player in pairs(game.Players:GetPlayers()) do
		HandlePlayerItems(player, false)
	end
end


------------------------------------------------------------------------------------------------------------------
viewSelectedButton.MouseButton1Click:Connect(function()
	-- Cambiar el estado (toggle)
	initialSelected = not initialSelected  

	-- Aplicar el atributo a todos los jugadores
	for _, player in pairs(game.Players:GetPlayers()) do
		player:SetAttribute("SelectedUser", initialSelected)
	end

	-- Actualizar el botón
	toggleButton(viewSelectedButton, initialSelected)
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para alternar sombras
shadowsButton.MouseButton1Click:Connect(function()
	game.Lighting.GlobalShadows = not game.Lighting.GlobalShadows
	toggleButton(shadowsButton, game.Lighting.GlobalShadows)
end)
------------------------------------------------------------------------------------------------------------------
-- Tabla para almacenar materiales originales
local originalMaterials = {}

-- Función para cambiar materiales
local function toggleMaterials(isReduced)
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			if isReduced then
				-- Guardar el material original y cambiar a SmoothPlastic
				if not originalMaterials[part] then
					originalMaterials[part] = part.Material
				end
				part.Material = Enum.Material.SmoothPlastic
			else
				-- Restaurar el material original
				if originalMaterials[part] then
					part.Material = originalMaterials[part]
					originalMaterials[part] = nil -- Limpiar la tabla
				end
			end
		end
	end
end

-- Inicializar el estado de los materiales
toggleMaterials(not initialTextures) -- Cambiar materiales si initialTextures es false
toggleButton(texturesButton, initialTextures) -- Actualizar el botón al iniciar

-- Evento de clic en el botón para alternar texturas
texturesButton.MouseButton1Click:Connect(function()
	initialTextures = not initialTextures -- Cambia el estado
	toggleMaterials(not initialTextures) -- Cambia los materiales
	toggleButton(texturesButton, initialTextures) -- Actualiza el botón
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para alternar reflejos
reflectionsButton.MouseButton1Click:Connect(function()
	game.Lighting.EnvironmentSpecularScale = game.Lighting.EnvironmentSpecularScale > 0 and 0 or 1
	toggleButton(reflectionsButton, game.Lighting.EnvironmentSpecularScale > 0)
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para alternar difusiones
diffuseButton.MouseButton1Click:Connect(function()
	game.Lighting.EnvironmentDiffuseScale = game.Lighting.EnvironmentDiffuseScale > 0 and 0 or 1
	toggleButton(diffuseButton, game.Lighting.EnvironmentDiffuseScale > 0)
end)
------------------------------------------------------------------------------------------------------------------
-- Tabla para almacenar el estado original de cada efecto de partículas
local originalParticleStates = {}

-- Función para guardar el estado original de los efectos de partículas
local function saveOriginalParticleStates()
	originalParticleStates = {}
	for _, descendant in pairs(workspace:GetDescendants()) do
		for _, effect in pairs(visualEffects) do
			if descendant:IsA(effect) then
				originalParticleStates[descendant] = descendant.Enabled
			end
		end
	end
end

-- Función para restaurar solo los efectos que estaban activos originalmente
local function restoreOriginalParticleStates()
	for particle, wasEnabled in pairs(originalParticleStates) do
		if particle:IsDescendantOf(workspace) then  -- Verificar que la partícula aún existe
			particle.Enabled = wasEnabled
		end
	end
end

-- Configuración inicial para las partículas
toggleButton(particlesButton, initialParticles)
if initialParticles then
	saveOriginalParticleStates()  -- Guardar estados iniciales
else
	SetVisualEffects(game.Workspace, false)
end

-- Evento de clic en el botón para alternar efectos visuales
particlesButton.MouseButton1Click:Connect(function()
	initialParticles = not initialParticles

	if initialParticles then
		-- Al activar: restaurar solo los efectos que estaban activos
		restoreOriginalParticleStates()
	else
		-- Al desactivar: guardar estados actuales y desactivar todo
		saveOriginalParticleStates()
		SetVisualEffects(game.Workspace, false)
	end

	toggleButton(particlesButton, initialParticles)
end)

effectsButton.MouseButton1Click:Connect(function()
	SpecialEffects = not SpecialEffects
	
	for _, player in pairs(game.Players:GetPlayers()) do
		player:SetAttribute("SpecialEffects", SpecialEffects)
	end
	
	toggleButton(effectsButton, SpecialEffects)
end)

-- Función para manejar nuevos personajes
local function onCharacterAdded(player)
	if not initialParticles then
		HandlePlayerItems(player, false)
	else
		-- Para nuevos personajes, activar solo si el estado global está activo
		HandlePlayerItems(player, true)
		-- Guardar el estado de las nuevas partículas
		saveOriginalParticleStates()
	end
end

------------------------------------------------------------------------------------------------------------------
-- Función para cambiar la visibilidad de otros jugadores para el activador
local function setPlayerVisibilityForActivator(activator, isVisible)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= activator and player.Character then
            for _, descendant in pairs(player.Character:GetDescendants()) do
                -- Cambiar transparencia de partes visibles
                if descendant:IsA("BasePart") or descendant:IsA("MeshPart") or descendant:IsA("Decal") then
                    descendant.LocalTransparencyModifier = isVisible and 0 or 1
                end

                -- Desactivar/activar efectos
                if descendant:IsA("ParticleEmitter") 
                    or descendant:IsA("PointLight") 
                    or descendant:IsA("SurfaceLight") 
                    or descendant:IsA("Fire") 
                    or descendant:IsA("Smoke") 
                    or descendant:IsA("Sparkles") 
                    or descendant:IsA("Trail") then
                    descendant.Enabled = isVisible
                end
            end

            -- Buscar el Overhead en la cabeza (Head)
            local head = player.Character:FindFirstChild("Head")
            if head then
                local nameTag = head:FindFirstChild("Overhead")
                if nameTag and nameTag:IsA("BillboardGui") then
                    nameTag.Enabled = isVisible
                end
            end

            -- Configuración del Humanoid para nombres
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.DisplayDistanceType = isVisible and Enum.HumanoidDisplayDistanceType.Viewer or Enum.HumanoidDisplayDistanceType.None
                humanoid.NameDisplayDistance = isVisible and 20 or 0
            end
        end
    end
end

-- Inicializar el estado de visibilidad de jugadores según la configuración inicial
setPlayerVisibilityForActivator(game.Players.LocalPlayer, initialViewUsers)

-- Evento de clic en el botón para alternar visibilidad de jugadores
viewUsersButton.MouseButton1Click:Connect(function()
	initialViewUsers = not initialViewUsers
	setPlayerVisibilityForActivator(game.Players.LocalPlayer, initialViewUsers) -- Aplica el estado de visibilidad
	toggleButton(viewUsersButton, initialViewUsers) -- Actualiza el botón
end)

-- Aplicar configuración de visibilidad para nuevos jugadores que se unan al servidor
game.Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer.CharacterAdded:Connect(function(character)
		-- Asegura que la visibilidad para nuevos jugadores coincida con el estado actual
		if not initialViewUsers then
			for _, descendant in pairs(character:GetDescendants()) do
				-- Cambiar transparencia de partes visibles
				if descendant:IsA("BasePart") or descendant:IsA("MeshPart") or descendant:IsA("Decal")then
					descendant.LocalTransparencyModifier = 1
				end

				-- Desactivar efectos
				if descendant:IsA("ParticleEmitter") 
					or descendant:IsA("PointLight") 
					or descendant:IsA("SurfaceLight") 
					or descendant:IsA("Fire") 
					or descendant:IsA("Smoke") 
					or descendant:IsA("Sparkles") 
					--or descendant:IsA("Sound") 
					or descendant:IsA("Trail") then
					descendant.Enabled = false
				end
			end

			-- Desactivar NameTag en HumanoidRootPart
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local nameTag = humanoidRootPart:FindFirstChild("Overhead")
				if nameTag and nameTag:IsA("BillboardGui") then
					nameTag.Enabled = false
				end
			end

			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				humanoid.NameDisplayDistance = 0
			end
		end
		
		
	end)
end)
------------------------------------------------------------------------------------------------------------------

local distanceThreshold = 1 -- Distancia en studs (1 bloque = 4 studs por defecto en Roblox)

-- Función para actualizar la visibilidad de los NameTags
local function updateNameTagsVisibility()
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character then
			local head = player.Character:FindFirstChild("Head")
			local nameTag = head and head:FindFirstChild("Overhead")
			if nameTag and nameTag:IsA("BillboardGui") then
				if initialViewTagsUsers then
					nameTag.Enabled = true
				else
					local localPlayer = game.Players.LocalPlayer
					local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
					local localHead = localCharacter:WaitForChild("Head")
					if player == localPlayer then
						nameTag.Enabled = false
					else
						local distance = (head.Position - localHead.Position).Magnitude
						nameTag.Enabled = distance <= distanceThreshold
					end
				end
			end
		end
	end
end

-- Función para manejar el cambio en la opción
viewTagsUsersButton.MouseButton1Click:Connect(function()
	initialViewTagsUsers = not initialViewTagsUsers
	updateNameTagsVisibility()
	toggleButton(viewTagsUsersButton, initialViewTagsUsers) 
end)

-- Aplicar la lógica a nuevos jugadores
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 20):WaitForChild("Overhead", 20)
		updateNameTagsVisibility()
	end)
end)

-- Controlar la visibilidad continuamente si la opción está desactivada
game:GetService("RunService").RenderStepped:Connect(function()
	if not initialViewTagsUsers then
		updateNameTagsVisibility()
	end
end)

-- Configuración inicial
updateNameTagsVisibility()

------------------------------------------------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage"):WaitForChild("SettingsEvents")
local updateFlagVisibilityEvent = ReplicatedStorage:WaitForChild("UpdateFlagsVibility")

-- Función para actualizar la visibilidad del Flag de un jugador para los demás
local function updateFlagVisibility(playerWhoToggled)
	for _, otherPlayer in pairs(game.Players:GetPlayers()) do
		-- Excluir al jugador que activó/desactivó el Flag
		if otherPlayer ~= playerWhoToggled then
			local character = otherPlayer.Character
			if character then
				-- Navegar en la jerarquía para encontrar el Device
				local flag = character:FindFirstChild("Head"):FindFirstChild("Template"):FindFirstChild("OtherFrame"):FindFirstChild("Country")
				-- Si se encuentra el CountryFlag y es un TextLabel, ajustar su visibilidad
				if flag and flag:IsA("TextLabel") then
					flag.Visible = initialViewFlagUser -- Mostrar u ocultar el CountryFlag
				end
			end
		end
	end
end

-- Manejar el evento del botón
ViewFlagUserButton.MouseButton1Click:Connect(function()
	initialViewFlagUser = not initialViewFlagUser
	toggleButton(ViewFlagUserButton, initialViewFlagUser)

	-- Notificar al servidor si el "Flag" debe ser visible o no
	updateFlagVisibilityEvent:FireServer(initialViewFlagUser)
end)

------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------

-- Evento de clic en el botón para activar o desactivar la burbuja de chat
local textChatService = game:GetService("TextChatService")
--[[ Para la version Actual]]
chatButton.MouseButton1Click:Connect(function()
	initialChat = not initialChat -- Cambia el estado
	textChatService.BubbleChatConfiguration.Enabled =  initialChat-- Activar o desactivar burbujas
	toggleButton(chatButton, initialChat) -- Actualizar el texto del botón
end)

------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para activar o desactivar las nubes
cloudsButton.MouseButton1Click:Connect(function()
	initialClouds = not initialClouds -- Cambia el estado
	lightingclouds.Enabled =  initialClouds -- Activar o desactivar nubes
	toggleButton(cloudsButton, initialClouds) -- Actualizar el texto del botón
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para activar o desactivar la correcion de color
cCorrectionButton.MouseButton1Click:Connect(function()
	initialCCorrection = not initialCCorrection -- Cambia el estado
	game.Lighting.ColorCorrection.Enabled =  initialCCorrection-- Activar o desactivar nubes
	toggleButton(cCorrectionButton, initialCCorrection) -- Actualizar el texto del botón
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para activar o desactivar la profundidad de campo
DoFButton.MouseButton1Click:Connect(function()
	initialDoF = not initialDoF -- Cambia el estado
	game.Lighting.DepthOfField.Enabled =  initialDoF-- Activar o desactivar nubes
	toggleButton(DoFButton, initialDoF) -- Actualizar el texto del botón
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para alternar atmósfera
atmosphereButton.MouseButton1Click:Connect(function()
	initialAtmosphere = not initialAtmosphere -- Cambia el estado
	game.Lighting.Atmosphere.Density = initialAtmosphere and 0.3 or 0 -- Cambia la densidad de la atmósfera
	toggleButton(atmosphereButton, initialAtmosphere) -- Actualiza el botón
end)
------------------------------------------------------------------------------------------------------------------
-- Evento de clic en el botón para alternar desenfoque
blurButton.MouseButton1Click:Connect(function()
	initialBlur = not initialBlur -- Cambia el estado
	game.Lighting.Desenfoque.Size = initialBlur and 2 or 0 -- Cambia el tamaño del desenfoque
	toggleButton(blurButton, initialBlur) -- Actualiza el botón
end)

---------------------------------------------------------------------------------------------------------------




---------------------------------------------------------------------------------------------------------------
