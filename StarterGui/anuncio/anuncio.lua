-- SISTEMA DE ANUNCIOS GLOBALES - LocalScript (StarterGui)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local THEME = require(ReplicatedStorage.Config.ThemeConfig)

local COLORS = {
	Background = THEME.bg,
	BackgroundDark = THEME.panel,
	TextPrimary = THEME.text,
	TextSecondary = THEME.muted,
	Accent = THEME.accent,
	Border = THEME.stroke,
	Verified = THEME.text,
}

-- ScreenGui (DisplayOrder alto para estar encima de todo)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnuncioGlobalGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 640, 0, 140) -- ANCHO/ALTO BASE AUMENTADO (MÁS GRANDE)
mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
mainContainer.AnchorPoint = Vector2.new(0.5, 0)
mainContainer.BackgroundColor3 = COLORS.Background
mainContainer.BackgroundTransparency = 0.1
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ZIndex = 100
mainContainer.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainContainer

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Border
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = mainContainer

-- Avatar del usuario
local userImage = Instance.new("ImageLabel")
userImage.Name = "UserImage"
userImage.Size = UDim2.new(0, 96, 0, 96) -- AUMENTADO
userImage.Position = UDim2.new(0, 20, 0.5, 0)
userImage.AnchorPoint = Vector2.new(0, 0.5)
userImage.BackgroundColor3 = COLORS.BackgroundDark
userImage.BorderSizePixel = 0
userImage.Image = ""
userImage.ZIndex = 101
userImage.Parent = mainContainer

local userImageCorner = Instance.new("UICorner")
userImageCorner.CornerRadius = UDim.new(0, 20) -- RADIO AJUSTADO
userImageCorner.Parent = userImage

local userImageStroke = Instance.new("UIStroke")
userImageStroke.Color = COLORS.Border
userImageStroke.Thickness = 3 -- MÁS VISIBLE
userImageStroke.Parent = userImage

-- Contenedor de texto
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -126, 1, -20)
textContainer.Position = UDim2.new(0, 126, 0, 10)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 101
textContainer.Parent = mainContainer

-- Contenedor del nombre + check
local nameContainer = Instance.new("Frame")
nameContainer.Name = "NameContainer"
nameContainer.Size = UDim2.new(1, 0, 0, 22)
nameContainer.Position = UDim2.new(0, 0, 0, 5)
nameContainer.BackgroundTransparency = 1
nameContainer.ZIndex = 101
nameContainer.Parent = textContainer

local nameLayout = Instance.new("UIListLayout")
nameLayout.FillDirection = Enum.FillDirection.Horizontal
nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
nameLayout.Padding = UDim.new(0, 6)
nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
nameLayout.Parent = nameContainer

-- Nombre de usuario
local displayNameLabel = Instance.new("TextLabel")
displayNameLabel.Name = "DisplayName"
displayNameLabel.Size = UDim2.new(0, 0, 0, 26)
displayNameLabel.AutomaticSize = Enum.AutomaticSize.X
displayNameLabel.BackgroundTransparency = 1
displayNameLabel.Text = "DisplayName"
displayNameLabel.TextSize = 18
displayNameLabel.Font = Enum.Font.GothamBold
displayNameLabel.TextColor3 = COLORS.TextPrimary
displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
displayNameLabel.LayoutOrder = 1
displayNameLabel.ZIndex = 102
displayNameLabel.Parent = nameContainer

local userHandle = Instance.new("TextLabel")
userHandle.Name = "UserHandle"
userHandle.Size = UDim2.new(0, 0, 0, 20)
userHandle.AutomaticSize = Enum.AutomaticSize.X
userHandle.BackgroundTransparency = 1
userHandle.Text = "@usuario"
userHandle.TextSize = 14
userHandle.Font = Enum.Font.GothamMedium
userHandle.TextColor3 = COLORS.TextSecondary
userHandle.TextXAlignment = Enum.TextXAlignment.Left
userHandle.LayoutOrder = 2
userHandle.ZIndex = 102
userHandle.Parent = nameContainer

-- Check de verificado (Roblox verified badge)
local verifiedCheck = Instance.new("ImageLabel")
verifiedCheck.Name = "VerifiedCheck"
verifiedCheck.Size = UDim2.new(0, 18, 0, 18)
verifiedCheck.BackgroundTransparency = 1
verifiedCheck.Image = "rbxassetid://102611300733289"
verifiedCheck.ImageColor3 = COLORS.Verified
verifiedCheck.LayoutOrder = 2
verifiedCheck.ZIndex = 102
verifiedCheck.Parent = nameContainer

-- Mensaje
local messageText = Instance.new("TextLabel")
messageText.Name = "MessageText"
messageText.Size = UDim2.new(1, 0, 0, 45)
messageText.Position = UDim2.new(0, 0, 0, 28)
messageText.BackgroundTransparency = 1
messageText.Text = ""
messageText.TextSize = 26
messageText.Font = Enum.Font.GothamBold
messageText.TextColor3 = COLORS.TextPrimary
messageText.TextXAlignment = Enum.TextXAlignment.Left
messageText.TextYAlignment = Enum.TextYAlignment.Top
messageText.TextWrapped = true
messageText.TextTruncate = Enum.TextTruncate.AtEnd
messageText.ZIndex = 102
messageText.AutomaticSize = Enum.AutomaticSize.Y
messageText.Parent = textContainer

-- Barra de progreso
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Size = UDim2.new(1, -30, 0, 4)
progressBarBg.Position = UDim2.new(0.5, 0, 1, -12)
progressBarBg.AnchorPoint = Vector2.new(0.5, 0)
progressBarBg.BackgroundColor3 = COLORS.BackgroundDark
progressBarBg.BorderSizePixel = 0
progressBarBg.ZIndex = 101
progressBarBg.Parent = mainContainer

local progressBarBgCorner = Instance.new("UICorner")
progressBarBgCorner.CornerRadius = UDim.new(1, 0)
progressBarBgCorner.Parent = progressBarBg

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(1, 0, 1, 0)
progressBar.BackgroundColor3 = COLORS.Accent
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 102
progressBar.Parent = progressBarBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

-- Animaciones
local function animateIn()
	mainContainer.Position = UDim2.new(0.5, 0, 0, -150)
	mainContainer.Visible = true

	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 25)
	})
	tween:Play()
end

local function animateOut()
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -150)
	})
	tween:Play()

	tween.Completed:Connect(function()
		mainContainer.Visible = false
	end)
end

local function animateProgress(duration)
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()
end

-- Evento Remoto
local crearAnuncio = ReplicatedStorage:WaitForChild("CrearAnuncio")

crearAnuncio.OnClientEvent:Connect(function(creatorName, msg, duration)
	local userId
	local targetPlayer = Players:FindFirstChild(creatorName)

	if targetPlayer then
		userId = targetPlayer.UserId
	else
		local success, result = pcall(function()
			return Players:GetUserIdFromNameAsync(creatorName)
		end)
		if success then
			userId = result
		end
	end


messageText.Text = msg

   -- Obtener nombres: display (si existe) y handle (username)
   local displayName = creatorName
   local handleName = creatorName
   if userId then
       local ok1, dname = pcall(function() return Players:GetDisplayNameAsync(userId) end)
       if ok1 and dname and dname ~= "" then displayName = dname end
       local ok2, uname = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
       if ok2 and uname and uname ~= "" then handleName = uname end
   end

   local displayLabel = nameContainer:FindFirstChild("DisplayName")
   local handleLabel = nameContainer:FindFirstChild("UserHandle")
   if displayLabel then displayLabel.Text = displayName end
   if handleLabel then handleLabel.Text = "@" .. handleName end

   -- Ajuste preciso usando TextService:GetTextSize
   local maxWidth = 640
   local minFontSize = 6
   local baseFontSize = 26
   local maxContainerHeight = 380
   local minContainerHeight = 140
   local maxLines = 5
   local lineHeightFactor = 1.15 -- estimación del alto por línea

   -- Asegurar que el tamaño absoluto esté disponible
   if mainContainer.AbsoluteSize.X == 0 then
       repeat task.wait() until mainContainer.AbsoluteSize.X > 0
   end
   local availableWidth = math.max(10, maxWidth - 110 - 12) -- padding extra (usar maxWidth para consistencia)
   local function textHeightFor(size, text)
       local ok, sizeVec = pcall(function()
           return TextService:GetTextSize(text or msg, size, messageText.Font, Vector2.new(availableWidth, 10000))
       end)
       return (ok and sizeVec.Y) or 0
   end

   -- Elegir el tamaño de fuente más grande que quepa en maxLines
   local chosenSize = baseFontSize
   for s = baseFontSize, minFontSize, -1 do
       local h = textHeightFor(s, msg)
       local maxAllowed = maxLines * s * lineHeightFactor
       if h <= maxAllowed then
           chosenSize = s
           break
       end
   end

   -- Si el mensaje es corto (cabe en una línea al baseFontSize), intentar agrandar la fuente hasta baseFontSize+8
   local hBase = textHeightFor(baseFontSize, msg)
   local singleLineHeight = baseFontSize * lineHeightFactor
   if hBase <= singleLineHeight then
       for s = baseFontSize + 1, baseFontSize + 8 do
           if textHeightFor(s, msg) <= singleLineHeight then
               chosenSize = s
           else
               break
           end
       end
   end

   -- Aplicar tamaño elegido y calcular altura requerida
   messageText.TextSize = chosenSize
   local requiredHeight = textHeightFor(chosenSize, messageText.Text)
   local desiredHeight = math.clamp(requiredHeight + 55, minContainerHeight, maxContainerHeight)

   -- Si no cabe en desiredHeight, intentar expandir contenedor hasta maxContainerHeight
   local targetSize = UDim2.new(0, maxWidth, 0, math.min(desiredHeight, maxContainerHeight))
   TweenService:Create(mainContainer, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
   if textHeightFor(chosenSize, messageText.Text) > (mainContainer.AbsoluteSize.Y - 55) then
       -- Truncar progresivamente
       local truncated = msg
       while textHeightFor(chosenSize, truncated .. "...") > (mainContainer.AbsoluteSize.Y - 55) and #truncated > 0 do
           truncated = truncated:sub(1, -2)
       end
       messageText.Text = truncated .. (truncated ~= msg and "..." or "")
       requiredHeight = textHeightFor(chosenSize, messageText.Text)
       local finalSize = UDim2.new(0, maxWidth, 0, math.clamp(requiredHeight + 55, minContainerHeight, maxContainerHeight))
       TweenService:Create(mainContainer, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = finalSize}):Play()
   end
   -- Asegurar que el TextLabel refleje el tamaño final
   messageText.TextSize = chosenSize

   if userId then
       local success, thumb = pcall(function()
           return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
       end)
       if success then
           userImage.Image = thumb
       end
   end

   animateIn()
   animateProgress(duration or 4)

   -- Esperar la duración (o 4s por defecto) antes de ocultar
   task.wait(duration or 4)
   animateOut()
end)