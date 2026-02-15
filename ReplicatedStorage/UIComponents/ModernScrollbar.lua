--[[
	MODERN SCROLLBAR - Componente reutilizable de scrollbar personalizado
	Autor: ignxts
	
	Uso:
	local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
	
	Forma simple:
	ModernScrollbar.setup(scrollFrame, parentFrame, THEME)
	
	Con opciones:
	ModernScrollbar.setup(scrollFrame, parentFrame, THEME, {
		position = "right",
		offset = -2,
		width = 4,
	})
]]

local TweenService = game:GetService("TweenService")

local ModernScrollbar = {}

function ModernScrollbar.setup(scrollFrame, parentPage, THEME, options)
	options = options or {}

	local position = options.position or "right"
	local offset = options.offset or -2
	local width = options.width or 4

	if not scrollFrame or not parentPage or not THEME then
		warn("[ModernScrollbar] Error: scrollFrame, parentPage y THEME son requeridos")
		return
	end

	-- Scrollbar container
	local scrollbarContainer = Instance.new("Frame")
	scrollbarContainer.Name = "ScrollbarContainer"
	scrollbarContainer.Size = UDim2.new(0, width, 1, 0)

	if position == "left" then
		scrollbarContainer.Position = UDim2.new(0, offset, 0, 0)
	else
		scrollbarContainer.Position = UDim2.new(1, offset, 0, 0)
	end

	scrollbarContainer.BackgroundTransparency = 1
	scrollbarContainer.ZIndex = 105
	scrollbarContainer.Visible = false
	scrollbarContainer.Parent = parentPage

	-- Track
	local scrollbarTrack = Instance.new("Frame")
	scrollbarTrack.Name = "Track"
	scrollbarTrack.Size = UDim2.new(1, 0, 1, 0)
	scrollbarTrack.BackgroundColor3 = THEME.stroke
	scrollbarTrack.BackgroundTransparency = THEME.heavyAlpha
	scrollbarTrack.BorderSizePixel = 0
	scrollbarTrack.Parent = scrollbarContainer

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 2)
	trackCorner.Parent = scrollbarTrack

	-- Thumb
	local scrollbarThumb = Instance.new("Frame")
	scrollbarThumb.Name = "Thumb"
	scrollbarThumb.Size = UDim2.new(1, 0, 0.3, 0)
	scrollbarThumb.Position = UDim2.new(0, 0, 0, 0)
	scrollbarThumb.BackgroundColor3 = THEME.accent
	scrollbarThumb.BackgroundTransparency = THEME.mediumAlpha
	scrollbarThumb.BorderSizePixel = 0
	scrollbarThumb.ZIndex = 106
	scrollbarThumb.Parent = scrollbarContainer

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(0, 2)
	thumbCorner.Parent = scrollbarThumb

	local function updateScrollbar()
		local canvasSize = scrollFrame.AbsoluteCanvasSize.Y
		local windowSize = scrollFrame.AbsoluteWindowSize.Y

		-- Si el canvas es 0 o no hay overflow real, ocultar
		if canvasSize <= 0 or canvasSize <= windowSize + 1 then
			scrollbarContainer.Visible = false
			return
		end

		scrollbarContainer.Visible = true

		-- Calcular thumb proporcional
		local thumbHeight = math.clamp(windowSize / canvasSize, 0.1, 1)
		local maxScroll = canvasSize - windowSize

		local scrollPercent = 0
		if maxScroll > 0 then
			scrollPercent = math.clamp(scrollFrame.CanvasPosition.Y / maxScroll, 0, 1)
		end

		local thumbY = scrollPercent * (1 - thumbHeight)

		scrollbarThumb.Size = UDim2.new(1, 0, thumbHeight, 0)
		scrollbarThumb.Position = UDim2.new(0, 0, thumbY, 0)
	end

	-- Señales
	scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollbar)
	scrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollbar)
	scrollFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollbar)

	-- Hover effects
	scrollbarThumb.MouseEnter:Connect(function()
		TweenService:Create(scrollbarThumb, TweenInfo.new(0.15), {BackgroundTransparency = THEME.subtleAlpha}):Play()
	end)

	scrollbarThumb.MouseLeave:Connect(function()
		TweenService:Create(scrollbarThumb, TweenInfo.new(0.15), {BackgroundTransparency = THEME.mediumAlpha}):Play()
	end)

	updateScrollbar()

	return {
		container = scrollbarContainer,
		track = scrollbarTrack,
		thumb = scrollbarThumb,
		update = updateScrollbar
	}
end

return ModernScrollbar