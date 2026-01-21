-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENTE: PendingCard (Reutilizable para solicitudes pendientes)
-- ══════════════════════════════════════════════════════════════════════════════

local ClanSystemConfig = require(game.ReplicatedStorage.Config.ClanSystemConfig)
local UI = require(game.ReplicatedStorage.Core.UI)
local THEME = require(game.ReplicatedStorage.Config.ThemeConfig)
local Notify = require(game.ReplicatedStorage.Systems.NotificationSystem.NotificationSystem)
local ClanClient = require(game.ReplicatedStorage.Systems.ClanSystem.ClanClient)

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local PendingCard = {}
PendingCard.__index = PendingCard

function PendingCard.new(config)
	local self = setmetatable({}, PendingCard)

	self.userId = config.userId
	self.requestData = config.requestData
	self.playerRole = config.playerRole
	self.clanData = config.clanData
	self.parent = config.parent
	self.screenGui = config.screenGui
	self.onUpdate = config.onUpdate -- Callback cuando se actualiza

	self.connections = {}
	self:_build()

	return self
end

function PendingCard:_build()
	local canApprove = ClanSystemConfig:HasPermission(self.playerRole, "aprobar_solicitudes")
	local canReject = ClanSystemConfig:HasPermission(self.playerRole, "rechazar_solicitudes")

	-- Frame principal - diseño horizontal compacto
	self.frame = UI.frame({
		size = UDim2.new(1, 0, 0, 56),
		bg = THEME.card,
		z = 108,
		parent = self.parent,
		corner = 10,
		stroke = true,
		strokeA = 0.6
	})

	-- Avatar
	local avatarContainer = UI.frame({
		size = UDim2.new(0, 44, 0, 44),
		pos = UDim2.new(0, 6, 0.5, -22),
		bg = THEME.surface,
		z = 109,
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
	avatar.ZIndex = 110
	avatar.Parent = avatarContainer
	UI.rounded(avatar, 20)

	-- Borde naranja (pendiente)
	local pendingBorder = Instance.new("UIStroke")
	pendingBorder.Color = THEME.accent
	pendingBorder.Thickness = 2
	pendingBorder.Parent = avatarContainer

	-- Info de la solicitud
	local infoContainer = UI.frame({
		size = UDim2.new(1, -160, 1, -12),
		pos = UDim2.new(0, 58, 0, 6),
		bgT = 1,
		z = 109,
		parent = self.frame
	})

	-- Nombre
	local displayName = self.requestData.nombre or "Usuario"
	if #displayName > 18 then
		displayName = displayName:sub(1, 16) .. "..."
	end

	UI.label({
		size = UDim2.new(1, 0, 0, 20),
		text = displayName,
		textSize = 14,
		font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Left,
		z = 110,
		parent = infoContainer
	})

	-- Tiempo
	local timeAgo = os.time() - (self.requestData.requestTime or os.time())
	local timeText = "Ahora"
	if timeAgo >= 86400 then
		timeText = "Hace " .. math.floor(timeAgo / 86400) .. "d"
	elseif timeAgo >= 3600 then
		timeText = "Hace " .. math.floor(timeAgo / 3600) .. "h"
	elseif timeAgo >= 60 then
		timeText = "Hace " .. math.floor(timeAgo / 60) .. "m"
	end

	UI.label({
		size = UDim2.new(1, 0, 0, 16),
		pos = UDim2.new(0, 0, 0, 20),
		text = timeText,
		color = THEME.muted,
		textSize = 11,
		alignX = Enum.TextXAlignment.Left,
		z = 110,
		parent = infoContainer
	})

	-- Botones de acción
	if canApprove then
		local acceptBtn = UI.button({
			size = UDim2.new(0, 72, 0, 38),
			pos = UDim2.new(1, -160, 0.5, -19),
			bg = THEME.success,
			text = "Aceptar",
			textSize = 12,
			z = 109,
			parent = self.frame,
			corner = 8
		})

		UI.hover(acceptBtn, THEME.success, THEME.successMuted)

		local acceptConn = acceptBtn.MouseButton1Click:Connect(function()
			acceptBtn.Text = "..."
			acceptBtn.Active = false

			local success, msg = ClanClient:ApproveJoinRequest(self.clanData.clanId, self.userId)
			if success then
				Notify:Success("Aceptado", (self.requestData.nombre or "Usuario") .. " se unió al clan", 4)
				-- Animar y remover
				TweenService:Create(self.frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				-- Esperar a que termine la animación antes de actualizar
				task.wait(0.25)
				if self.onUpdate then 
					self.onUpdate() 
				end
			else
				Notify:Error("Error", msg or "No se pudo aceptar", 4)
				acceptBtn.Text = "Aceptar"
				acceptBtn.Active = true
			end
		end)

		table.insert(self.connections, acceptConn)
	end

	if canReject then
		local rejectBtn = UI.button({
			size = UDim2.new(0, 72, 0, 38),
			pos = UDim2.new(1, -80, 0.5, -19),
			bg = THEME.danger,
			text = "Rechazar",
			textSize = 12,
			z = 109,
			parent = self.frame,
			corner = 8
		})

		UI.hover(rejectBtn, THEME.danger, THEME.btnDangerHover)

		local rejectConn = rejectBtn.MouseButton1Click:Connect(function()
			rejectBtn.Text = "..."
			rejectBtn.Active = false

			local success, msg = ClanClient:RejectJoinRequest(self.clanData.clanId, self.userId)
			if success then
				Notify:Success("Rechazado", "Solicitud rechazada", 4)
				TweenService:Create(self.frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				-- Esperar a que termine la animación antes de actualizar
				task.wait(0.25)
				if self.onUpdate then 
					self.onUpdate() 
				end
			else
				Notify:Error("Error", msg or "No se pudo rechazar", 4)
				rejectBtn.Text = "Rechazar"
				rejectBtn.Active = true
			end
		end)

		table.insert(self.connections, rejectConn)
	end
end

function PendingCard:destroy()
	for _, conn in ipairs(self.connections) do
		if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
	end
	self.connections = {}

	if self.frame then
		self.frame:Destroy()
		self.frame = nil
	end
end

return PendingCard