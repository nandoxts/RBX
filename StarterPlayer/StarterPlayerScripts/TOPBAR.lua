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
local settingsUI = playerGui:WaitForChild("Settings")
local FrameSettings = settingsUI:WaitForChild("MainFrame")

-- Esperar a que se carguen las GUIs de sistema
task.wait(1)

-- ════════════════════════════════════════════════════════════════
-- MÓDULOS
-- ════════════════════════════════════════════════════════════════
local GlobalModalManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("GlobalModalManager"))

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

local function openGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 15}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV - 10}):Play()
end

local function closeGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 0}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV}):Play()
end

local function toggleSettingsUI()
	if guiDebounce then return end
	guiDebounce = true

	if FrameSettings.Visible then
		closeGUIAnimation()
		FrameSettings.Visible = false
	else
		openGUIAnimation()
		FrameSettings.Visible = true
	end

	guiDebounce = false
end

-- ════════════════════════════════════════════════════════════════
-- ICONOS DEL TOPBAR
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- ICONO: TIENDA
-- ════════════════════════════════════════════════════════════════
_G.ShopIcon = Icon.new()
	:setImage(9405933217)
	:setName("Tienda")
	:setCaption("Tienda")
	:bindToggleKey(Enum.KeyCode.T)
	:autoDeselect(false)

_G.ShopIcon:bindEvent("selected", function()
	GlobalModalManager:openModal("Shop")
end)

_G.ShopIcon:bindEvent("deselected", function()
	GlobalModalManager:closeModal("Shop")
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: CONFIGURACIÓN
-- ════════════════════════════════════════════════════════════════
local configIcon = Icon.new()
	:setImage(9753762469)
	:setName("Configuración")
	:setCaption("Configuración")
	:align("Right")
	:bindToggleKey(Enum.KeyCode.C)
	:autoDeselect(false)
	:oneClick()

configIcon:bindEvent("deselected", function()
	toggleSettingsUI()
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: CLANES
-- ════════════════════════════════════════════════════════════════
_G.ClanSystemIcon = Icon.new()
	:setLabel("⚔️ CLAN ⚔️ ")
	:setOrder(2)
	:autoDeselect(false)

_G.ClanSystemIcon:bindEvent("selected", function(icon)
	GlobalModalManager:openModal("Clan")
end)

_G.ClanSystemIcon:bindEvent("deselected", function(icon)
	GlobalModalManager:closeModal("Clan")
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: EMOTES
-- ════════════════════════════════════════════════════════════════
_G.EmotesIcon = Icon.new()
	:setOrder(2)
	:setImage("127784597936941")
	:autoDeselect(false)

_G.EmotesIcon:bindEvent("selected", function(icon)
	GlobalModalManager:openModal("Emotes")
end)

_G.EmotesIcon:bindEvent("deselected", function(icon)
	GlobalModalManager:closeModal("Emotes")
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: MÚSICA (Dashboard)
-- ════════════════════════════════════════════════════════════════
_G.MusicDashboardIcon = Icon.new()
	:setImage("13780950231")
	:setOrder(1)
	:autoDeselect(false)

_G.MusicDashboardIcon:bindEvent("selected", function(icon)
	GlobalModalManager:openModal("Music")
end)

_G.MusicDashboardIcon:bindEvent("deselected", function(icon)
	GlobalModalManager:closeModal("Music")
end)

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
		:autoDeselect(false)
		:oneClick()

	-- ════════════════════════════════════════════════════════════
	-- ESTADO DEL MUTE
	-- ════════════════════════════════════════════════════════════
	local isMuted = false
	local savedVolume = musicSoundGroup.Volume -- Guardar el volumen inicial

	local ICON_SOUND_ON = 166377448
	local ICON_SOUND_OFF = 14861812886

	-- Sincronizar estado global para otros scripts
	_G.MusicMutedState = false

	-- ════════════════════════════════════════════════════════════
	-- TOGGLE MUTE
	-- ════════════════════════════════════════════════════════════
	soundIcon:bindEvent("deselected", function()
		isMuted = not isMuted
		_G.MusicMutedState = isMuted  -- Actualizar estado global

		if isMuted then
			-- Guardar volumen actual del grupo y mutear
			savedVolume = musicSoundGroup.Volume
			musicSoundGroup.Volume = 0
			soundIcon:setImage(ICON_SOUND_OFF)
			print("Música: MUTEADA")
		else
			-- Restaurar volumen del grupo
			musicSoundGroup.Volume = savedVolume
			soundIcon:setImage(ICON_SOUND_ON)
			print("Música: ACTIVADA")
		end
	end)
else
	warn("[Topbar] No se encontró 'MusicSoundGroup' en SoundService - Créalo manualmente en Studio")
end

-- ════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ════════════════════════════════════════════════════════════════