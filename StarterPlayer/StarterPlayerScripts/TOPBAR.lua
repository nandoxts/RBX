-- ════════════════════════════════════════════════════════════════
-- TOPBAR CONTROLLER - LocalScript en StarterPlayerScripts
-- Usando SoundGroup para mute LOCAL sin entrecortes
-- ════════════════════════════════════════════════════════════════

local Icon = require(game:GetService("ReplicatedStorage").Icon)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════════════
-- REFERENCIAS A GUIs
-- ════════════════════════════════════════════════════════════════
local gamepassUI = playerGui:WaitForChild("GamepassUI")
local FrameGamepass = gamepassUI:WaitForChild("MainFrame")

local settingsUI = playerGui:WaitForChild("Settings")
local FrameSettings = settingsUI:WaitForChild("MainFrame")

-- ════════════════════════════════════════════════════════════════
-- SERVICIOS
-- ════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE ANIMACIONES
-- ════════════════════════════════════════════════════════════════
local Info = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)

-- Crear efecto de desenfoque
local Blur = Instance.new('BlurEffect')
Blur.Parent = game.Lighting
Blur.Size = 0

-- Configuración de la cámara
local Camera = game.Workspace.CurrentCamera
local FOV = Camera.FieldOfView

-- Debounce para las GUIs
local guiDebounce = false

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES DE GUI
-- ════════════════════════════════════════════════════════════════

local function closeAllGUIsExcept(exception)
	if exception ~= "GMUI" then FrameGamepass.Visible = false end
	if exception ~= "SettingsUI" then FrameSettings.Visible = false end
end

local function openGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 15}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV - 10}):Play()
end

local function closeGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 0}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV}):Play()
end

local function toggleGMUI()
	if guiDebounce then return end
	guiDebounce = true

	if FrameGamepass.Visible then
		closeGUIAnimation()
		FrameGamepass.Visible = false
	else
		closeAllGUIsExcept("GMUI")
		openGUIAnimation()
		FrameGamepass.Visible = true
	end

	guiDebounce = false
end

local function toggleSettingsUI()
	if guiDebounce then return end
	guiDebounce = true

	if FrameSettings.Visible then
		closeGUIAnimation()
		FrameSettings.Visible = false
	else
		closeAllGUIsExcept("SettingsUI")
		openGUIAnimation()
		FrameSettings.Visible = true
	end

	guiDebounce = false
end

local function toggleInventoryUI()
	local CoreGuiType = Enum.CoreGuiType.Backpack
	local isBackpackEnabled = StarterGui:GetCoreGuiEnabled(CoreGuiType)
	StarterGui:SetCoreGuiEnabled(CoreGuiType, not isBackpackEnabled)
end

local function setFavoriteOnButtonClick()
	local success, errorInfo = pcall(function()
		game:GetService("AvatarEditorService"):PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- ICONOS DEL TOPBAR
-- ════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════
-- SISTEMA DE MÚSICA CON SOUNDGROUP (MUTE LOCAL)
-- ════════════════════════════════════════════════════════════════

-- Obtener el SoundGroup (creado manualmente en Studio dentro de SoundService)
local musicSoundGroup = SoundService:WaitForChild("MusicSoundGroup", 10)

if musicSoundGroup then
	-- Crear el icono de sonido
	local soundIcon = Icon.new()
		:setImage(166377448)
		:setName("SoundToggle")
		:setCaption("Música")
		:bindToggleKey(Enum.KeyCode.M)
		:oneClick()

	-- ════════════════════════════════════════════════════════════
	-- ESTADO DEL MUTE
	-- ════════════════════════════════════════════════════════════
	local isMuted = false
	local savedVolume = musicSoundGroup.Volume -- Guardar el volumen inicial

	local ICON_SOUND_ON = 166377448
	local ICON_SOUND_OFF = 14861812886

	-- ════════════════════════════════════════════════════════════
	-- TOGGLE MUTE (SIMPLE Y LIMPIO)
	-- ════════════════════════════════════════════════════════════
	soundIcon:bindEvent("deselected", function()
		isMuted = not isMuted

		if isMuted then
			-- Guardar volumen actual del grupo y mutear
			savedVolume = musicSoundGroup.Volume
			musicSoundGroup.Volume = 0
			soundIcon:setImage(ICON_SOUND_OFF)
		else
			-- Restaurar volumen del grupo
			musicSoundGroup.Volume = savedVolume
			soundIcon:setImage(ICON_SOUND_ON)
		end

		print(" Música:", isMuted and "MUTEADA" or "ACTIVADA")
	end)
else
	warn("[Topbar] No se encontró 'MusicSoundGroup' en SoundService - Créalo manualmente en Studio")
end

-- ════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ════════════════════════════════════════════════════════════════