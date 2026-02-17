-- ════════════════════════════════════════════════════════════════
-- TOPBAR CONTROLLER - LocalScript en StarterPlayerScripts
-- Usando SoundGroup para mute LOCAL sin entrecortes
-- ════════════════════════════════════════════════════════════════

local Icon = require(game:GetService("ReplicatedStorage").Icon)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
-- ICONO: CONFIGURACIÓN (SETTINGS MODAL)
-- ════════════════════════════════════════════════════════════════
_G.SettingsIcon = Icon.new()
	:setImage(9753762469)
	:setName("Configuración")
	:setCaption("Configuración")
	:align("Right")
	:bindToggleKey(Enum.KeyCode.C)
	:autoDeselect(false)

_G.SettingsIcon:bindEvent("selected", function()
	if _G.OpenSettingsUI then
		_G.OpenSettingsUI()
	else
		warn("[Topbar] OpenSettingsUI no está disponible")
	end
end)

_G.SettingsIcon:bindEvent("deselected", function()
	if _G.CloseSettingsUI then
		_G.CloseSettingsUI()
	end
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: CLANES
-- ════════════════════════════════════════════════════════════════
_G.ClanSystemIcon = Icon.new()
	:setImage(15909461117)
	:setImageRatio(1)
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
local soundIcon = nil

if musicSoundGroup then
	-- Crear el icono de sonido
	soundIcon = Icon.new()
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
-- ICONO: FREECAM (DINÁMICO) - MEJORES PRÁCTICAS
-- ════════════════════════════════════════════════════════════════

-- Crear BindableEvent para comunicación eficiente (mejor que _G polling)
local FreeCamEvent = Instance.new("BindableEvent")
_G.FreeCamEvent = FreeCamEvent

local FreeCamIcon = nil
local iconsHidden = false

-- Lista de todos los iconos a gestionar
local topbarIcons = {
	_G.ShopIcon,
	_G.SettingsIcon,
	_G.ClanSystemIcon,
	_G.EmotesIcon,
	_G.MusicDashboardIcon,
	soundIcon
}

-- Función optimizada para ocultar todos los iconos
local function HideAllIcons()
	if iconsHidden then return end

	for _, icon in ipairs(topbarIcons) do
		if icon then
			pcall(function()
				icon:setEnabled(false)
			end)
		end
	end

	iconsHidden = true
end

-- Función optimizada para mostrar todos los iconos
local function ShowAllIcons()
	if not iconsHidden then return end

	for _, icon in ipairs(topbarIcons) do
		if icon then
			pcall(function()
				icon:setEnabled(true)
			end)
		end
	end

	iconsHidden = false
end

-- Función para activar FreeCam UI
local function EnableFreeCamUI()
	if FreeCamIcon then return end

	-- Ocultar todos los botones del TopBar
	HideAllIcons()

	-- Crear icono de FreeCam
	FreeCamIcon = Icon.new()
		:setLabel("F6 DESACTIVAR")
		:setCaption("Presiona para desactivar (F6)")
		:align("Right")
		:setOrder(0)
		:select()

	-- Evento para desactivar
	FreeCamIcon:bindEvent("deselected", function()
		-- Notificar a FreeCam.lua que debe desactivarse
		FreeCamEvent:Fire(false)
	end)
end

-- Función para desactivar FreeCam UI
local function DisableFreeCamUI()
	if not FreeCamIcon then return end

	-- Destruir icono
	pcall(function()
		FreeCamIcon:destroy()
	end)
	FreeCamIcon = nil

	-- Restaurar todos los botones del TopBar
	ShowAllIcons()
end

-- Escuchar eventos de FreeCam (mejor que polling)
FreeCamEvent.Event:Connect(function(isActive)
	if isActive then
		EnableFreeCamUI()
	else
		DisableFreeCamUI()
	end
end)

-- Variable global solo para compatibilidad (se usa BindableEvent internamente)
_G.FreeCamActive = false
_G.FreeCamIcon = FreeCamIcon

-- ════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ════════════════════════════════════════════════════════════════