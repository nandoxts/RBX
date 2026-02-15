--[[
	═══════════════════════════════════════════════════════════
	CLAN HELPERS - Funciones auxiliares para UI
	═══════════════════════════════════════════════════════════
]] local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ClanConstants = require(script.Parent.ClanConstants)
local Memory = ClanConstants.Memory

local ClanHelpers = {}

-- Loading seguro con validación de estado
function ClanHelpers.safeLoading(container, asyncFn, onComplete, State)
	if not State.isOpen then return end

	State.loadingId = State.loadingId + 1
	local myId = State.loadingId
	local expectedPage = State.currentPage

	Memory:destroyChildren(container, "UIListLayout")
	local loadingFrame = UI.loading(container)

	task.spawn(function()
		local results = {pcall(asyncFn)}
		local success = table.remove(results, 1)

		if myId ~= State.loadingId then return end
		if expectedPage ~= State.currentPage then return end
		if not State.isOpen then return end

		UI.cleanupLoading()
		if loadingFrame and loadingFrame.Parent then loadingFrame:Destroy() end
		if container and container.Parent then Memory:destroyChildren(container, "UIListLayout") end

		if success and onComplete then
			onComplete(table.unpack(results))
		elseif not success then
			warn("[ClanUI] Error async:", results[1])
		end
	end)

	return myId
end

-- Setup scroll
function ClanHelpers.setupScroll(parent, options)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = options.size or UDim2.new(1, -20, 1, -60)
	scroll.Position = options.pos or UDim2.new(0, 10, 0, 58)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = THEME.accent
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = options.z or 103
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, options.padding or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	return scroll
end

-- Crear selector
function ClanHelpers.createSelector(items, config)
	local container = UI.frame({
		size = config.size or UDim2.new(1, 0, 0, 36),
		pos = config.pos, bg = THEME.surface, z = config.z or 105,
		parent = config.parent, corner = 8
	})

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, config.spacing or 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = container

	Instance.new("UIPadding", container).PaddingLeft = UDim.new(0, 6)

	local selectedIdx, buttons = 1, {}

	local function updateSelection(newIdx)
		selectedIdx = newIdx
		for j, data in ipairs(buttons) do
			local isSelected = j == newIdx
			if config.isEmoji then
				data.frame.BackgroundColor3 = isSelected and THEME.accent or THEME.card
			else
				local stroke = data.indicator and data.indicator:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Transparency = isSelected and 0 or 1 end
			end
		end
		if config.onSelect then config.onSelect(newIdx) end
	end

	for i, item in ipairs(items) do
		local itemSize = config.itemSize or 28
		local btn = UI.frame({
			size = UDim2.new(0, itemSize, 0, itemSize),
			bg = config.isEmoji and (i == 1 and THEME.accent or THEME.card) or Color3.fromRGB(item[1], item[2], item[3]),
			z = (config.z or 105) + 1, parent = container, corner = config.itemCorner or 6
		})

		local indicator = nil
		if config.isEmoji then
			UI.label({size = UDim2.new(1, 0, 1, 0), text = item, textSize = 16, alignX = Enum.TextXAlignment.Center, z = (config.z or 105) + 2, parent = btn})
		else
			indicator = UI.frame({
				size = UDim2.new(1, -6, 1, -6), pos = UDim2.new(0, 3, 0, 3), bgT = 1,
				z = (config.z or 105) + 2, parent = btn, corner = 4,
				stroke = true, strokeA = i == 1 and 0 or 1, strokeC = THEME.text
			})
		end

		local clickBtn = Instance.new("TextButton")
		clickBtn.Size, clickBtn.BackgroundTransparency, clickBtn.Text = UDim2.new(1, 0, 1, 0), 1, ""
		clickBtn.ZIndex = (config.z or 105) + 3
		clickBtn.Parent = btn

		buttons[i] = {frame = btn, indicator = indicator}
		Memory:track(clickBtn.MouseButton1Click:Connect(function() updateSelection(i) end))
	end

	return container, function() return selectedIdx end
end

-- Crear tarjeta de navegación
function ClanHelpers.createNavCard(config)
	local card = UI.frame({
		size = config.size or UDim2.new(1, 0, 0, 60),
		pos = config.pos, bg = THEME.card, z = 104,
		parent = config.parent, corner = 10, stroke = true, strokeA = 0.6
	})

	UI.label({size = UDim2.new(0, 40, 0, 40), pos = UDim2.new(0, 12, 0.5, -20), text = config.icon or "👥", textSize = 22, alignX = Enum.TextXAlignment.Center, z = 105, parent = card})
	UI.label({size = UDim2.new(1, -120, 0, 20), pos = UDim2.new(0, 60, 0, 12), text = config.title or "Título", color = THEME.text, textSize = 14, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 105, parent = card})

	local subtitleLabel = UI.label({name = "Subtitle", size = UDim2.new(1, -120, 0, 16), pos = UDim2.new(0, 60, 0, 32), text = config.subtitle or "", color = THEME.muted, textSize = 11, alignX = Enum.TextXAlignment.Left, z = 105, parent = card})
	UI.label({size = UDim2.new(0, 30, 1, 0), pos = UDim2.new(1, -40, 0, 0), text = "›", color = THEME.muted, textSize = 24, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Center, z = 105, parent = card})

	local notificationDot = nil
	if config.showNotification then
		notificationDot = UI.frame({name = "NotificationDot", size = UDim2.new(0, 10, 0, 10), pos = UDim2.new(1, -50, 0, 10), bg = THEME.btnDanger, z = 106, parent = card, corner = 5})
		notificationDot.Visible = false
	end

	local avatarPreview = nil
	if config.showAvatarPreview then
		avatarPreview = UI.frame({name = "AvatarPreview", size = UDim2.new(0, 70, 0, 28), pos = UDim2.new(1, -115, 0.5, -14), bgT = 1, z = 105, parent = card})
	end

	UI.hover(card, THEME.card, THEME.elevated)

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size, clickBtn.BackgroundTransparency, clickBtn.Text, clickBtn.ZIndex = UDim2.new(1, 0, 1, 0), 1, "", 107
	clickBtn.Parent = card

	return card, clickBtn, subtitleLabel, notificationDot, avatarPreview
end

-- Crear header de vista
function ClanHelpers.createViewHeader(parent, title, onBack)
	local header = UI.frame({size = UDim2.new(1, 0, 0, 44), bg = THEME.surface, z = 106, parent = parent, corner = 10})

	local backBtn = UI.button({size = UDim2.new(0, 36, 0, 36), pos = UDim2.new(0, 4, 0.5, -18), bg = THEME.card, text = "‹", color = THEME.text, textSize = 22, font = Enum.Font.GothamBold, z = 107, parent = header, corner = 8})
	UI.hover(backBtn, THEME.card, THEME.accent)
	Memory:track(backBtn.MouseButton1Click:Connect(onBack))

	UI.label({size = UDim2.new(1, -90, 1, 0), pos = UDim2.new(0, 48, 0, 0), text = title, color = THEME.text, textSize = 15, font = Enum.Font.GothamBold, alignX = Enum.TextXAlignment.Left, z = 107, parent = header})

	return header
end

-- Validar emojis (solo emojis, máximo 2)
function ClanHelpers.validateEmoji(text)
	if not text or #text == 0 then
		return false, "El emoji no puede estar vacío"
	end

	-- Contar emojis válidos
	local emojiCount = 0
	local hasRegularText = false

	-- Recorrer cada caracter UTF-8
	for _, codepoint in utf8.codes(text) do
		-- Los emojis están en rangos Unicode específicos
		-- Rango principal de emojis: 0x1F300 - 0x1FAF8
		-- Otros símbolos comunes: 0x2000 - 0x3299
		if (codepoint >= 0x1F300 and codepoint <= 0x1FAF8) or 
			(codepoint >= 0x2000 and codepoint <= 0x3299) or
			(codepoint >= 0x1F900 and codepoint <= 0x1F9FF) then
			emojiCount = emojiCount + 1
		elseif codepoint > 127 then
			-- Otros caracteres Unicode (pueden ser emojis no comunes)
			emojiCount = emojiCount + 1
		elseif codepoint ~= 32 and codepoint ~= 9 and codepoint ~= 10 then
			-- Caracter ASCII regular (no espacio, tab, o newline) = texto no permitido
			hasRegularText = true
			break
		end
	end

	if hasRegularText then
		return false, "Solo se permiten emojis, sin texto"
	end

	if emojiCount == 0 then
		return false, "Debes ingresar al menos un emoji"
	end

	if emojiCount > 2 then
		return false, "Máximo 2 emojis permitidos"
	end

	return true
end

return ClanHelpers
