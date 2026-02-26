--[[
NavTabs Component v4 — Tabs minimalistas con underline animado
by George Bellota
─────────────────────────────────────────────────────────
Reemplaza NavPills con un sistema mas limpio:
  - Solo texto + underline deslizante
  - Sin fondos de pill, sin strokes pesados
  - Indicador de 2px que se mueve entre tabs

Uso:
	local NavTabs = require(...)
	local nav = NavTabs.new({
		parent = container,
		categories = SHOP_CATEGORIES,
		colors = COLORS,
		onSelect = function(catId) end,
		isMobile = boolean,
		UI = UI,
		TweenService = TweenService,
	})
]]

local NavTabs = {}

function NavTabs.new(config)
	local parent = config.parent
	local categories = config.categories
	local colors = config.colors
	local onSelect = config.onSelect or function() end
	local isMobile = config.isMobile
	local UI = config.UI
	local TweenService = config.TweenService

	local TWEEN_SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local TWEEN_FADE  = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function tween(obj, info, props)
		if not obj then return nil end
		local t = TweenService:Create(obj, info, props)
		t:Play()
		return t
	end

	-- ══════════════════════════════════════════════
	-- STATE
	-- ══════════════════════════════════════════════
	local self = {
		_refs = {},
		_currentId = categories[1].id,
		_parent = parent,
		_onSelect = onSelect,
		_indicator = nil,
	}

	-- ══════════════════════════════════════════════
	-- CONTAINER
	-- ══════════════════════════════════════════════
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 1, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = parent.ZIndex + 1
	tabContainer.Parent = parent

	-- Layout horizontal centrado
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = tabContainer

	-- ══════════════════════════════════════════════
	-- UNDERLINE INDICATOR (se posiciona absoluto)
	-- ══════════════════════════════════════════════
	local tabWidth = isMobile and 80 or 100

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, tabWidth, 0, 3)
	indicator.Position = UDim2.new(0, 0, 1, -3)
	indicator.BackgroundColor3 = categories[1].color
	indicator.BackgroundTransparency = 0
	indicator.BorderSizePixel = 0
	indicator.ZIndex = parent.ZIndex + 10
	indicator.Parent = parent

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 2)
	indicatorCorner.Parent = indicator

	self._indicator = indicator

	-- ══════════════════════════════════════════════
	-- CREAR TABS
	-- ══════════════════════════════════════════════

	for i, category in ipairs(categories) do
		local isActive = (i == 1)

		local tab = Instance.new("TextButton")
		tab.Name = category.id .. "Tab"
		tab.Size = UDim2.new(0, tabWidth, 0, 36)
		tab.BackgroundTransparency = 1
		tab.BorderSizePixel = 0
		tab.Text = ""
		tab.AutoButtonColor = false
		tab.ZIndex = parent.ZIndex + 2
		tab.LayoutOrder = i
		tab.Parent = tabContainer

		-- Label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = string.upper(category.label)
		label.TextColor3 = isActive and category.color or colors.textMuted
		label.TextSize = 13
		label.Font = isActive and Enum.Font.GothamBlack or Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.ZIndex = parent.ZIndex + 3
		label.Parent = tab

		-- Guardar refs
		self._refs[category.id] = {
			tab = tab,
			label = label,
			category = category,
			index = i,
		}

		-- Posicionar indicador inicial
		if isActive then
			task.defer(function()
				local absPos = tab.AbsolutePosition
				local absSize = tab.AbsoluteSize
				local parentAbsPos = parent.AbsolutePosition
				local posX = absPos.X - parentAbsPos.X
				indicator.Position = UDim2.new(0, posX, 1, -3)
				indicator.Size = UDim2.new(0, absSize.X, 0, 3)
			end)
		end

		-- Click
		tab.MouseButton1Click:Connect(function()
			self:selectTab(category.id)
			if onSelect then
				onSelect(category.id)
			end
		end)

		-- Hover (desktop)
		if not isMobile then
			tab.MouseEnter:Connect(function()
				if category.id ~= self._currentId then
					tween(label, TWEEN_FADE, { TextColor3 = colors.textSecondary })
				end
			end)
			tab.MouseLeave:Connect(function()
				if category.id ~= self._currentId then
					tween(label, TWEEN_FADE, { TextColor3 = colors.textMuted })
				end
			end)
		end
	end

	-- ══════════════════════════════════════════════
	-- METODOS
	-- ══════════════════════════════════════════════

	function self:selectTab(catId)
		if catId == self._currentId then return end
		self._currentId = catId

		local activeRef = self._refs[catId]
		if not activeRef then return end

		-- Animar labels
		for id, ref in pairs(self._refs) do
			if id == catId then
				tween(ref.label, TWEEN_FADE, { TextColor3 = ref.category.color })
				ref.label.Font = Enum.Font.GothamBlack
			else
				tween(ref.label, TWEEN_FADE, { TextColor3 = colors.textMuted })
				ref.label.Font = Enum.Font.GothamBold
			end
		end

		-- Animar indicador (deslizar hacia el tab activo)
		tween(indicator, TWEEN_SLIDE, { BackgroundColor3 = activeRef.category.color })

		task.defer(function()
			local absPos = activeRef.tab.AbsolutePosition
			local absSize = activeRef.tab.AbsoluteSize
			local parentAbsPos = parent.AbsolutePosition
			local posX = absPos.X - parentAbsPos.X
			tween(indicator, TWEEN_SLIDE, {
				Position = UDim2.new(0, posX, 1, -3),
				Size = UDim2.new(0, absSize.X, 0, 3),
			})
		end)
	end

	function self:getCurrentId()
		return self._currentId
	end

	function self:destroy()
		for _, ref in pairs(self._refs) do
			ref.tab:Destroy()
		end
		if self._indicator then
			self._indicator:Destroy()
		end
		self._refs = {}
	end

	return self
end

return NavTabs