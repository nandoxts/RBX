-- Dentro de un LocalScript en StarterPlayerScripts y asumiendo que el paquete Icon está en ReplicatedStorage
local Icon = require(game:GetService("ReplicatedStorage").Icon)
local player = game.Players.LocalPlayer

-- Obtenemos el PlayerGui del jugador local
local playerGui = player:WaitForChild("PlayerGui")

local systemMusicUI = playerGui:WaitForChild("SystemMusic")
local FrameMusic = systemMusicUI:WaitForChild("MusicGui")

local gamepassUI = playerGui:WaitForChild("GamepassUI")
local FrameGamepass = gamepassUI:WaitForChild("MainFrame")

local settingsUI = playerGui:WaitForChild("Settings")
local FrameSettings = settingsUI:WaitForChild("MainFrame")


-- Servicios
local TweenService = game:GetService("TweenService")
local Debounce = false

-- Configuración de TweenInfo
local Info = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)

-- Crear efecto de desenfoque
local Blur = Instance.new('BlurEffect')
Blur.Parent = game.Lighting
Blur.Size = 0

-- Configuración de la cámara
local Camera = game.Workspace.CurrentCamera
local FOV = Camera.FieldOfView

-- Función para cerrar todas las GUIs excepto la especificada
local function closeAllGUIsExcept(exception)
	if exception ~= "MusicUI" then FrameMusic.Visible = false end
	if exception ~= "GMUI" then FrameGamepass.Visible = false end
	if exception ~= "SettingsUI" then FrameSettings.Visible = false end
	-- Nota: EmoteUI no se cierra nunca
end

-- Función para aplicar animaciones al abrir una GUI
local function openGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 15}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV - 10}):Play()
end

-- Función para aplicar animaciones al cerrar una GUI
local function closeGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 0}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV}):Play()
end

-- Función para abrir o cerrar la interfaz de MusicUI
local function toggleMusicUI()
	if Debounce then return end
	Debounce = true

	if FrameMusic.Visible then
		closeGUIAnimation()
		FrameMusic.Visible = false
	else
		closeAllGUIsExcept("MusicUI")
		openGUIAnimation()
		FrameMusic.Visible = true
	end

	Debounce = false
end

local function toggleGMUI()
	if Debounce then return end
	Debounce = true

	if FrameGamepass.Visible then
		closeGUIAnimation()
		FrameGamepass.Visible = false
	else
		closeAllGUIsExcept("GMUI")
		openGUIAnimation()
		FrameGamepass.Visible = true
	end

	Debounce = false
end

-- Función para abrir o cerrar la interfaz de MusicUI
local function toggleSettingsUI()
	if Debounce then return end
	Debounce = true

	if FrameSettings.Visible then
		closeGUIAnimation()
		FrameSettings.Visible = false
	else
		closeAllGUIsExcept("SettingsUI")
		openGUIAnimation()
		FrameSettings.Visible = true
	end

	Debounce = false
end

local StarterGui = game:GetService("StarterGui")
local CoreGuiType = Enum.CoreGuiType.Backpack
local Debounce = false

-- Función para abrir o cerrar la interfaz de Inventario
local function toggleInventoryUI()
	if Debounce then return end
	Debounce = true

	-- Verificar si el inventario está activo y alternar su estado
	local isBackpackEnabled = StarterGui:GetCoreGuiEnabled(CoreGuiType)
	StarterGui:SetCoreGuiEnabled(CoreGuiType, not isBackpackEnabled)

	Debounce = false
end

-- Función para abrir el cuadro de agregar a juego favorito
local function setFavoriteOnButtonClick()
	local success, errorInfo = pcall(function()
		game:GetService("AvatarEditorService"):PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end


Icon.new()
	:setImage(13780950231)
	:setName("Musica")
	:setCaption("Música")
	:bindToggleKey(Enum.KeyCode.M)
	:bindEvent("deselected", toggleMusicUI)
	:oneClick()

Icon.new()
	:setImage(9405933217)
	:setName("Tienda")
	:setCaption("Tienda")
	:bindToggleKey(Enum.KeyCode.T)
	:bindEvent("deselected", toggleGMUI)
	:oneClick()

Icon.new()
	:setImage(9753762469)
	:setName("Configuración")
	:setCaption("Configuración")
	:align("Right")
	:bindToggleKey(Enum.KeyCode.C)
	:bindEvent("deselected", toggleSettingsUI)
	:oneClick()



-- Referencia al SoundService y al sonido THEME
local SoundService = game:GetService("SoundService")
local themeSound = SoundService:FindFirstChild("THEME")

if themeSound then
	-- Crear el icono para silenciar/activar el sonido
	local soundIcon = Icon.new()
		:setImage(166377448) -- Estado inicial (activado)
		:setName("SoundToggle")
		:setCaption("Música")
		:bindToggleKey(Enum.KeyCode.N)
		--:align("Right")
		:oneClick()

	-- Variables para controlar el estado del volumen
	local isMuted = false
	local lastVolumeBeforeMute = themeSound.Volume -- Guarda el último volumen antes de mutear

	-- Función para alternar el estado del sonido y cambiar el icono
	soundIcon:bindEvent("deselected", function()
		isMuted = not isMuted

		if isMuted then
			-- Si se está silenciando, guarda el volumen actual
			lastVolumeBeforeMute = themeSound.Volume
			themeSound.Volume = 0 -- Silencia el sonido
			soundIcon:setImage(14861812886) -- Cambia el icono a "mute"
		else
			-- Si se está reactivando, restaura el último volumen guardado
			themeSound.Volume = lastVolumeBeforeMute
			soundIcon:setImage(166377448) -- Cambia el icono a "activado"
		end
	end)
else
	--warn("No se encontró el sonido 'THEME' en SoundService")
end

------------------------------------




