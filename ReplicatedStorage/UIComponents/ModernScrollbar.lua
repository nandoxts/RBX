--[[
	MODERN SCROLLBAR - Componente reutilizable de scrollbar personalizado
	Autor: ignxts

	Uso básico:
		ModernScrollbar.setup(scrollFrame, parentFrame, THEME)

	Con opciones:
		ModernScrollbar.setup(scrollFrame, parentFrame, THEME, {
			position    = "right" | "left",   -- lado donde aparece (default: "right")
			offset      = 0,                  -- px de separación extra desde el borde (default: 0)
			width       = 4,                  -- ancho base en px (default: 4)
			widthHover  = 6,                  -- ancho al hacer hover (default: width + 2)
			paddingV    = 12,                 -- padding vertical en px (default: 12)
			color       = Color3,             -- color del thumb (default: THEME.accent)
			colorHover  = Color3,             -- color del thumb en hover (default: THEME.accent)
			transparency     = 0.3,           -- transparencia base del thumb
			transparencyHover = 0,            -- transparencia en hover
			zIndex      = 115,                -- ZIndex base (default: 115)
		})

	Retorna:
		{ container, track, thumb, update }
]]

local TweenService = game:GetService("TweenService")

local ModernScrollbar = {}

function ModernScrollbar.setup(scrollFrame, parentFrame, THEME, options)
	if not scrollFrame or not parentFrame or not THEME then
		warn("[ModernScrollbar] scrollFrame, parentFrame y THEME son requeridos")
		return
	end

	options = options or {}

	local position          = options.position          or "right"
	local offset            = options.offset            or 0
	local width             = options.width             or 4
	local widthHover        = options.widthHover        or (width + 2)
	local paddingV          = options.paddingV          or 12
	local color             = options.color             or THEME.accent
	local colorHover        = options.colorHover        or THEME.accent
	local transparency      = options.transparency      or 0.3
	local transparencyHover = options.transparencyHover or 0
	local zIndex            = options.zIndex            or 115

	-- ── Container ─────────────────────────────────────────────────
	local container = Instance.new("Frame")
	container.Name = "ScrollbarContainer"
	container.Size = UDim2.new(0, width, 1, -paddingV * 2)
	container.AnchorPoint = Vector2.new(0, 0)

	if position == "left" then
		container.Position = UDim2.new(0, -width - offset, 0, paddingV)
	else
		container.Position = UDim2.new(1, offset, 0, paddingV)
	end

	container.BackgroundTransparency = 1
	container.ZIndex = zIndex
	container.Visible = false
	container.Parent = parentFrame

	-- ── Track ──────────────────────────────────────────────────────
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 1, 0)
	track.BackgroundColor3 = THEME.stroke
	track.BackgroundTransparency = 0.7
	track.BorderSizePixel = 0
	track.ZIndex = zIndex
	track.Parent = container

	-- ── Thumb ──────────────────────────────────────────────────────
	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.new(1, 0, 0.3, 0)
	thumb.Position = UDim2.new(0, 0, 0, 0)
	thumb.BackgroundColor3 = color
	thumb.BackgroundTransparency = transparency
	thumb.BorderSizePixel = 0
	thumb.ZIndex = zIndex + 1
	thumb.Parent = container

	-- ── Update logic ───────────────────────────────────────────────
	local function update()
		local canvasH = scrollFrame.AbsoluteCanvasSize.Y
		local windowH = scrollFrame.AbsoluteWindowSize.Y

		if canvasH <= windowH + 1 then
			container.Visible = false
			return
		end
		container.Visible = true

		local thumbRatio = math.clamp(windowH / canvasH, 0.08, 1)
		local maxScroll  = canvasH - windowH
		local scrollPct  = maxScroll > 0 and math.clamp(scrollFrame.CanvasPosition.Y / maxScroll, 0, 1) or 0

		thumb.Size     = UDim2.new(1, 0, thumbRatio, 0)
		thumb.Position = UDim2.new(0, 0, scrollPct * (1 - thumbRatio), 0)
	end

	scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
	scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
	scrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(update)

	-- ── Hover ──────────────────────────────────────────────────────
	local function onHoverEnter()
		TweenService:Create(container, TweenInfo.new(0.15), {
			Size = UDim2.new(0, widthHover, 1, -paddingV * 2)
		}):Play()
		TweenService:Create(thumb, TweenInfo.new(0.15), {
			BackgroundColor3 = colorHover,
			BackgroundTransparency = transparencyHover
		}):Play()
	end

	local function onHoverLeave()
		TweenService:Create(container, TweenInfo.new(0.2), {
			Size = UDim2.new(0, width, 1, -paddingV * 2)
		}):Play()
		TweenService:Create(thumb, TweenInfo.new(0.2), {
			BackgroundColor3 = color,
			BackgroundTransparency = transparency
		}):Play()
	end

	track.MouseEnter:Connect(onHoverEnter)
	thumb.MouseEnter:Connect(onHoverEnter)
	track.MouseLeave:Connect(onHoverLeave)
	thumb.MouseLeave:Connect(onHoverLeave)

	update()

	return {
		container = container,
		track     = track,
		thumb     = thumb,
		update    = update,
	}
end

return ModernScrollbar
