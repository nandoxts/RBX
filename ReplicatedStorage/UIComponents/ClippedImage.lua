--[[
    ClippedImage.lua - Componente genérico de imagen con clipping automático
    Uso: Cualquier lugar que necesite una imagen sin bordes salientes (avatar, cover, thumbnail, etc)
    
    Ejemplo:
    local clipped = ClippedImage.new({
        size = UDim2.new(0, 48, 0, 48),
        position = UDim2.new(0, 8, 0.5, -24),
        image = "rbxassetid://123456",
        corner = 6,
        parent = parentFrame
    })
]]

local ClippedImage = {}

function ClippedImage.new(config)
    -- Contenedor con CanvasGroup para evitar bordes salientes respetando UICorner
    local container = Instance.new("CanvasGroup")
    container.Name = config.name or "ClippedImage"
    container.Size = config.size or UDim2.new(0, 48, 0, 48)
    container.Position = config.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = config.bgColor or Color3.fromRGB(30, 30, 35)
    container.BackgroundTransparency = config.bgTransparency or 0
    container.BorderSizePixel = 0
    container.GroupTransparency = 0
    container.ZIndex = (config.z or 100) + 1
    container.Parent = config.parent
    
    -- Aplicar corner radius al contenedor
    local cornerRadius = config.corner or 6
    if cornerRadius > 0 then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, cornerRadius)
        corner.Parent = container
    end
    
    -- Imagen al 100% del contenedor (sin padding, sin radius extra)
    local image = Instance.new("ImageLabel")
    image.Name = "Image"
    image.Size = UDim2.new(1, 0, 1, 0)
    image.Position = UDim2.new(0, 0, 0, 0)
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    image.ScaleType = config.scaleType or Enum.ScaleType.Crop
    image.Image = config.image or ""
    image.ImageTransparency = config.imageTransparency or 0
    image.ZIndex = (config.z or 100) + 2
    image.Parent = container
    
    -- Retornar referencias para acceso/modificación posterior
    return {
        container = container,
        image = image,
        
        -- Métodos útiles
        setImage = function(self, imageId)
            self.image.Image = imageId
        end,
        
        setSize = function(self, newSize)
            self.container.Size = newSize
        end,
        
        setPosition = function(self, newPos)
            self.container.Position = newPos
        end,
        
        setVisible = function(self, visible)
            self.container.Visible = visible
        end,
        
        destroy = function(self)
            self.container:Destroy()
        end,
    }
end

return ClippedImage
