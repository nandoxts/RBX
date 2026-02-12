-- Developer check icon (separado, no afecta gradient)
if isDev then
Utils.create("ImageLabel", {
Size = UDim2.new(0, 18, 0, 18),
Position = UDim2.new(1, -L.statsWidth - 12, 1, nameYOffset + 4),
AnchorPoint = Vector2.new(1, 0),
BackgroundTransparency = 1,
Image = "rbxasset://textures/Ui/CoreGui/Checkmark.png",
ImageColor3 = playerColor,
ImageTransparency = 0.1,
ZIndex = 26,
Parent = avatarSection
})
end
