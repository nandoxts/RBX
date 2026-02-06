--[[
	═══════════════════════════════════════════════════════════
	CLAN ACTIONS - Acciones del clan (editar, eliminar, etc.)
	═══════════════════════════════════════════════════════════
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanConstants = require(script.Parent.ClanConstants)
local CONFIG = ClanConstants.CONFIG

local ClanActions = {}

-- Validador
local Validator = {
	rules = {
		clanName = { min = 3, msg = "Nombre inválido - Mínimo 3 caracteres" },
		clanTag = { min = 2, max = 5, msg = "TAG inválido - Entre 2 y 5 caracteres" },
		ownerId = { isNumber = true, positive = true, msg = "ID inválido - Debe ser un número positivo" }
	}
}

function Validator:check(field, value)
	local rule = self.rules[field]
	if not rule then return true end

	if rule.isNumber then
		local num = tonumber(value)
		if value ~= "" and (not num or (rule.positive and num <= 0)) then
			Notify:Warning("Validación", rule.msg, 3)
			return false
		end
		return true
	end

	local len = #(value or "")
	if rule.min and len < rule.min then Notify:Warning("Validación", rule.msg, 3) return false end
	if rule.max and len > rule.max then Notify:Warning("Validación", rule.msg, 3) return false end
	return true
end

-- Helper para mostrar modales
local function showModal(gui, opts)
	ConfirmationModal.new({
		screenGui = gui,
		title = opts.title,
		message = opts.message,
		inputText = opts.input ~= nil,
		inputPlaceholder = opts.inputPlaceholder,
		inputDefault = opts.inputDefault,
		confirmText = opts.confirm or "Confirmar",
		cancelText = opts.cancel or "Cancelar",
		confirmColor = opts.confirmColor,
		onConfirm = function(value)
			if opts.validate and not opts.validate(value) then return end
			local success, msg = opts.action(value)
			if success then
				Notify:Success(opts.successTitle or "Éxito", msg or opts.successMsg, 4)
				if opts.onSuccess then opts.onSuccess() end
			else
				Notify:Error("Error", msg or opts.errorMsg or "Operación fallida", 4)
			end
		end
	})
end

-- Editar nombre
function ClanActions:editName(gui, clanData, onSuccess)
	showModal(gui, {
		title = "Cambiar Nombre", message = "Ingresa el nuevo nombre:",
		input = true, inputPlaceholder = "Nuevo nombre", inputDefault = clanData.name,
		confirm = "Cambiar",
		validate = function(v) return Validator:check("clanName", v) end,
		action = function(v) return ClanClient:ChangeClanName(v) end,
		successTitle = "Actualizado", successMsg = "Nombre cambiado",
		onSuccess = onSuccess
	})
end

-- Editar tag
function ClanActions:editTag(gui, clanData, onSuccess)
	showModal(gui, {
		title = "Cambiar TAG", message = "Ingresa el nuevo TAG (2-5 caracteres):",
		input = true, inputPlaceholder = "Ej: XYZ", inputDefault = clanData.tag,
		confirm = "Cambiar",
		validate = function(v) return Validator:check("clanTag", (v or ""):upper()) end,
		action = function(v) return ClanClient:ChangeClanTag(v:upper()) end,
		successTitle = "Actualizado", successMsg = "TAG cambiado",
		onSuccess = onSuccess
	})
end

-- Editar color
function ClanActions:editColor(gui, onSuccess)
	local colorList = {}
	for _, c in ipairs(CONFIG.colors) do
		table.insert(colorList, c.name:lower())
	end
	local colorNames = table.concat(colorList, ", ")
	
	showModal(gui, {
		title = "Cambiar Color", 
		message = "Colores disponibles:\n" .. colorNames,
		input = true, inputPlaceholder = "ej: dorado", inputDefault = "",
		confirm = "Cambiar",
		validate = function(v) 
			if not v or v == "" then 
				Notify:Warning("Inválido", "Ingresa un nombre de color", 3) 
				return false 
			end
			
			local colorName = v:lower():gsub("%s+", "")
			local found = false
			for _, c in ipairs(CONFIG.colors) do
				if c.name:lower() == colorName then
					found = true
					break
				end
			end
			
			if not found then
				Notify:Warning("Color inválido", "Usa uno de: " .. colorNames, 4)
				return false
			end
			
			return true 
		end,
		action = function(v) 
			local colorName = v:lower():gsub("%s+", "")
			local colorRGB = nil
			
			for _, c in ipairs(CONFIG.colors) do
				if c.name:lower() == colorName then
					colorRGB = c.rgb
					break
				end
			end
			
			if colorRGB then
				return ClanClient:ChangeClanColor(colorRGB)
			else
				return false, "Color no encontrado"
			end
		end,
		successTitle = "Actualizado", successMsg = "Color cambiado",
		onSuccess = onSuccess
	})
end

-- Editar emoji
function ClanActions:editEmoji(gui, onSuccess)
	showModal(gui, {
		title = "Cambiar Emoji", 
		message = "Ingresa el nuevo emoji del clan:",
		input = true, inputPlaceholder = "Ejemplo: ⚔️ 🔥 👑", inputDefault = "",
		confirm = "Cambiar",
		validate = function(v)
			if not v or #v == 0 then
				Notify:Warning("Emoji vacío", "Debes ingresar un emoji", 3)
				return false
			end
			return true
		end,
		action = function(v) return ClanClient:ChangeClanEmoji(v) end,
		successTitle = "Actualizado", successMsg = "Emoji cambiado",
		onSuccess = onSuccess
	})
end

-- Salir del clan
function ClanActions:leave(gui, onSuccess)
	showModal(gui, {
		title = "Salir del Clan", message = "¿Estás seguro de que quieres salir?",
		confirm = "Salir",
		action = function() return ClanClient:LeaveClan() end,
		successTitle = "Abandonado", successMsg = "Has salido del clan",
		onSuccess = onSuccess
	})
end

-- Disolver clan
function ClanActions:dissolve(gui, clanName, onSuccess)
	showModal(gui, {
		title = "Disolver Clan", 
		message = string.format('¿Disolver "%s"?\n\nEsta acción es IRREVERSIBLE.', clanName),
		confirm = "Disolver", confirmColor = THEME.btnDanger,
		action = function() return ClanClient:DissolveClan() end,
		successTitle = "Clan Disuelto", successMsg = "El clan ha sido eliminado",
		onSuccess = onSuccess
	})
end

-- Eliminar clan (admin)
function ClanActions:adminDelete(gui, clanData, onSuccess)
	if not clanData or not clanData.clanId then
		Notify:Error("Error", "Datos del clan inválidos", 3)
		return
	end
	
	showModal(gui, {
		title = "Eliminar Clan",
		message = string.format('¿Eliminar "%s"?\nID: %s', clanData.name or "Sin nombre", clanData.clanId),
		confirm = "Eliminar", confirmColor = THEME.btnDanger,
		action = function() return ClanClient:AdminDissolveClan(clanData.clanId) end,
		successTitle = "Eliminado", successMsg = "Clan eliminado",
		onSuccess = onSuccess
	})
end

return ClanActions
