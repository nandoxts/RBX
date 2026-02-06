-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENTE: MemberCard (Reutilizable)
-- ══════════════════════════════════════════════════════════════════════════════

local RoleSelectionMenu = require(script.Parent.RoleSelectionMenu)
local ClanSystemConfig = require(game.ReplicatedStorage.Config.ClanSystemConfig)
local UI = require(game.ReplicatedStorage.Core.UI)
local THEME = require(game.ReplicatedStorage.Config.ThemeConfig)
local Notify = require(game.ReplicatedStorage.Systems.NotificationSystem.NotificationSystem)
local ClanClient = require(game.ReplicatedStorage.Systems.ClanSystem.ClanClient)
local ConfirmationModal = require(game.ReplicatedStorage.Modal.ConfirmationModal)

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local MemberCard = {}
MemberCard.__index = MemberCard

-- Configuración de roles desde ClanSystemConfig
local ROLES_CONFIG = ClanSystemConfig.ROLES.Visual

function MemberCard.new(config)
	local self = setmetatable({}, MemberCard)

	self.userId = config.userId
	self.memberData = config.memberData
	self.playerRole = config.playerRole
	self.clanData = config.clanData
	self.parent = config.parent
	self.screenGui = config.screenGui
	self.onUpdate = config.onUpdate -- Callback cuando se actualiza

	self.connections = {}
	self:_build()

	return self
end

function MemberCard:_build()
	local memberRole = self.memberData.role or "miembro"
	local roleConfig = ROLES_CONFIG[memberRole] or ROLES_CONFIG.miembro
	local isCurrentPlayer = self.userId == player.UserId
	local canManageThis = self:_canManage(memberRole)

	-- Frame principal - diseño horizontal compacto
	self.frame = UI.frame({
		size = UDim2.new(1, 0, 0, 56),
		bg = THEME.card,
		z = 106,
		parent = self.parent,
		corner = 10
	})

	-- Avatar
	local avatarContainer = UI.frame({
		size = UDim2.new(0, 44, 0, 44),
		pos = UDim2.new(0, 6, 0.5, -22),
		bg = THEME.card,
		z = 107,
		parent = self.frame,
		corner = 22
	})

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(1, -4, 1, -4)
	avatar.Position = UDim2.new(0, 2, 0, 2)
	avatar.BackgroundTransparency = 1
	avatar.Image = string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
		self.userId
	)
	avatar.ZIndex = 108
	avatar.Parent = avatarContainer
	UI.rounded(avatar, 20)

	-- Indicador de rol (borde del avatar)
	local roleBorder = Instance.new("UIStroke")
	roleBorder.Color = roleConfig.color
	roleBorder.Thickness = 2
	roleBorder.Parent = avatarContainer

	-- Info del miembro
	local infoContainer = UI.frame({
		size = UDim2.new(1, -120, 1, -12),
		pos = UDim2.new(0, 58, 0, 6),
		bgT = 1,
		z = 107,
		parent = self.frame
	})

	-- Nombre
	local displayName = (self.memberData.name or "Usuario")
	if #displayName > 16 then
		displayName = displayName:sub(1, 14) .. "..."
	end

	UI.label({
		size = UDim2.new(1, 0, 0, 20),
		text = displayName .. (isCurrentPlayer and " (Tú)" or ""),
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 108,
		parent = infoContainer
	})

	-- Rol con icono
	UI.label({
		size = UDim2.new(1, 0, 0, 16),
		pos = UDim2.new(0, 0, 0, 22),
		text = roleConfig.icon .. " " .. roleConfig.display,
		color = roleConfig.color,
		textSize = 12,
		font = Enum.Font.GothamMedium,
		alignX = Enum.TextXAlignment.Left,
		z = 108,
		parent = infoContainer
	})

	-- Botones de acción (solo si puede gestionar y no es él mismo)
	if canManageThis and not isCurrentPlayer then
		-- Botón de cambiar rol
		local roleBtn = UI.button({
			size = UDim2.new(0, 44, 0, 38),
			pos = UDim2.new(1, -100, 0.5, -19),
			bg = THEME.accent,
			text = "Rol",
			textSize = 12,
			z = 107,
			parent = self.frame,
			corner = 8
		})

		UI.hover(roleBtn, THEME.accent, THEME.accent:Lerp(Color3.new(1,1,1), 0.2))

		table.insert(self.connections, roleBtn.MouseButton1Click:Connect(function()
			self:_showRoleMenu()
		end))

		-- Botón de expulsar
		local kickBtn = UI.button({
			size = UDim2.new(0, 44, 0, 38),
			pos = UDim2.new(1, -52, 0.5, -19),
			bg = THEME.danger,
			text = "Kick",
			textSize = 12,
			z = 107,
			parent = self.frame,
			corner = 8
		})

		UI.hover(kickBtn, THEME.danger, THEME.btnDangerHover)

		table.insert(self.connections, kickBtn.MouseButton1Click:Connect(function()
			self:_confirmKick()
		end))
	end
end

function MemberCard:_canManage(targetRole)
	local myRoleConfig = ROLES_CONFIG[self.playerRole]
	if not myRoleConfig then return false end

	for _, manageable in ipairs(myRoleConfig.canManage) do
		if manageable == targetRole then
			return true
		end
	end
	return false
end

function MemberCard:_showRoleMenu()
	local memberRole = self.memberData.role or "miembro"
	local myRoleConfig = ROLES_CONFIG[self.playerRole]

	-- Construir opciones disponibles
	local options = {}
	for roleName, config in pairs(ROLES_CONFIG) do
		-- Solo mostrar roles que puedo asignar y que son diferentes al actual
		if table.find(myRoleConfig.canManage, roleName) and roleName ~= memberRole then
			table.insert(options, {
				role = roleName,
				display = config.icon .. " " .. config.display,
				color = config.color,
				priority = config.priority
			})
		end
	end

	-- Ordenar por prioridad (mayor primero)
	table.sort(options, function(a, b) return a.priority > b.priority end)

	if #options == 0 then
		Notify:Warning("Sin opciones", "No hay roles disponibles para asignar", 3)
		return
	end

	-- Crear menú de selección
	RoleSelectionMenu.new({
		screenGui = self.screenGui,
		title = "Cambiar rol de " .. (self.memberData.name or "Usuario"),
		subtitle = "Rol actual: " .. (ROLES_CONFIG[memberRole].display),
		options = options,
		onSelect = function(selectedRole)
			self:_changeRole(selectedRole)
		end
	})
end

function MemberCard:_changeRole(newRole)
	local roleConfig = ROLES_CONFIG[newRole]

	ConfirmationModal.new({
		screenGui = self.screenGui,
		title = "Confirmar cambio de rol",
		message = string.format(
			"¿Cambiar a %s al rol de %s %s?",
			self.memberData.name or "Usuario",
			roleConfig.icon,
			roleConfig.display
		),
		confirmText = "Confirmar",
		cancelText = "Cancelar",
		onConfirm = function()
			local success, msg = ClanClient:ChangePlayerRole(self.userId, newRole)
			if success then
				Notify:Success("Rol actualizado", msg or "Rol actualizado exitosamente", 4)
				if self.onUpdate then self.onUpdate() end
			else
				Notify:Error("Error", msg or "No se pudo cambiar el rol", 4)
			end
		end
	})
end

function MemberCard:_confirmKick()
	ConfirmationModal.new({
		screenGui = self.screenGui,
		title = "Expulsar miembro",
		message = string.format(
			"¿Expulsar a %s del clan?\n\nEsta acción no se puede deshacer.",
			self.memberData.name or "Usuario"
		),
		confirmText = "Expulsar",
		cancelText = "Cancelar",
		confirmColor = Color3.fromRGB(200, 60, 60),
		onConfirm = function()
			local success, msg = ClanClient:KickPlayer(self.userId)
			if success then
				Notify:Success("Expulsado", "El miembro ha sido expulsado", 4)
				if self.onUpdate then self.onUpdate() end
			else
				Notify:Error("Error", msg or "No se pudo expulsar", 4)
			end
		end
	})
end

function MemberCard:destroy()
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	self.connections = {}

	if self.frame then
		self.frame:Destroy()
		self.frame = nil
	end
end

return MemberCard