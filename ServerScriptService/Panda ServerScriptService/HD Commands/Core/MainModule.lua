-- MainModule: punto de entrada para HD Commands
local PackageLink = require(script:FindFirstChild("PackageLink") or script.PackageLink)

local MainModule = {}

function MainModule.Init(context)
    -- context puede incluir servicios, settings, etc.
    MainModule.Context = context or {}
    -- Inicialización mínima; extender según necesidades
    return true
end

function MainModule.GetInfo()
    return { name = PackageLink.Name, version = PackageLink.Version }
end

return MainModule
