-- SERVICES --
local DatastoreService = game:GetService('DataStoreService')
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService('Players')

-- Módulo central
local Configuration = require(game.ServerScriptService.Systems.Configuration)

local ID_BADGE = Configuration.BADGES_TopRacha

-- VARIABLES --
local LEADERBOARD_COUNT = 50
local Datastore = DatastoreService:GetOrderedDataStore('TopRacha')
local rachaCache = {}
local lastRachaUpdate = 0
local CACHE_TTL = 300 -- 5 minutos

-- Ruta del leaderboard
local Leaderboard = workspace.LeaderBoards.Leaderboards.RachaLeaderboard
local Container = Leaderboard.SurfaceGui.Container
local Scrolling = Container.TopsContainer.TopsScrolling
local Template = Scrolling.Template

-- Modelo del top 1
local Model = workspace.LeaderBoards.Leaderboards.RachaModel
local UserTag = Model.HumanoidRootPart.UserTag
local UsernameLabel = UserTag.Username

-- Cache de badges otorgados
local TopPlayersCache = {}

-- FORMATEO DE NÚMEROS
local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then break end
	end
	return formatted
end

-- Verificar badge
local function CheckBadgeOwnership(playerUserId)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadge(playerUserId, ID_BADGE)
	end)

	return success and hasBadge
end

-- Otorgar badge top 1
local function AwardTopBadge(playerUserId)
	if TopPlayersCache[playerUserId] then return end

	if CheckBadgeOwnership(playerUserId) then
		TopPlayersCache[playerUserId] = true
		return
	end

	local player = Players:GetPlayerByUserId(playerUserId)
	if player then
		local success, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, ID_BADGE)
		end)

		if success then
			TopPlayersCache[playerUserId] = true
		end
	else
		TopPlayersCache[playerUserId] = true
	end
end

-- Añadir item al leaderboard
local function AddItem(Rank, Data)

	local keyUserId = tonumber(Data.key) or tonumber(tostring(Data.key)) or Data.key

	if not Scrolling:FindFirstChild(tostring(Data.key)) then

		local NewTemplate = Template:Clone()

		local Info = NewTemplate:WaitForChild("Info")
		local NameFrame = Info:WaitForChild("Name")
		local NameLabel = NameFrame:WaitForChild("TextLabel")

		local CountFrame = Info:WaitForChild("Count")
		local CountLabel = CountFrame:WaitForChild("TextLabel")

		local RankFrame = NewTemplate:WaitForChild("Rank")
		local RankLabel = RankFrame:WaitForChild("TextLabel")

		NameLabel.Text = "Cargando..."

		local playerName = "Jugador Desconocido"
		local success, err = pcall(function()

			if tonumber(keyUserId) then
				playerName = Players:GetNameFromUserIdAsync(tonumber(keyUserId))
			else
				playerName = Players:GetNameFromUserIdAsync(Data.key)
			end
		end)

		if not success then
			playerName = "Usuario " .. tostring(Data.key)
		end

		NameLabel.Text = playerName

		if Rank == 1 then
			UsernameLabel.Text = playerName

			local ok, humanoidDescription = pcall(function()
				if tonumber(keyUserId) then
					return Players:GetHumanoidDescriptionFromUserId(tonumber(keyUserId))
				else
					return Players:GetHumanoidDescriptionFromUserId(Data.key)
				end
			end)

			if ok and humanoidDescription then
				Model.Humanoid:ApplyDescription(humanoidDescription)
			end

			AwardTopBadge(Data.key)
		end

		CountLabel.Text = string.format("Racha: %s 🔥", FormatNumber(Data.value))

		RankLabel.Text = "#" .. tostring(Rank)

		NewTemplate.Icon.Image = string.format(
			"rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60",
			Data.key
		)

		NewTemplate.Name = tostring(Data.key)
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Visible = true
		NewTemplate.Parent = Scrolling
	end
end

local function UpdateLeaderboard()
	-- Si hay cache y es reciente, reutilizarlo
	if rachaCache[1] and (tick() - lastRachaUpdate) < CACHE_TTL then
		for rank, item in ipairs(rachaCache) do
			AddItem(rank, item)
		end
		return
	end

	for _, Child in pairs(Scrolling:GetChildren()) do
		if Child.Name ~= "Template" and Child.Name ~= "ListLayout" then
			Child:Destroy()
		end
	end

	local success, data = pcall(function()
		return Datastore:GetSortedAsync(false, LEADERBOARD_COUNT)
	end)

	if success and data then
		local currentPage = data:GetCurrentPage()
		rachaCache = currentPage
		lastRachaUpdate = tick()
		for rank, item in ipairs(currentPage) do
			AddItem(rank, item)
		end
	end
end

local function onPlayerAdded(player)
	local success, data = pcall(function()
		return Datastore:GetSortedAsync(false, 1)
	end)

	if success and data then
		local top = data:GetCurrentPage()
		if #top > 0 and top[1].key == player.UserId then
			if not CheckBadgeOwnership(player.UserId) then
				AwardTopBadge(player.UserId)
			else
				TopPlayersCache[player.UserId] = true
			end
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- INICIALIZAR
UpdateLeaderboard()

-- Auto-refresh cada 180 segundos (3 minutos) y evitar solapamientos
local isUpdating = false
local function SafeUpdateLeaderboard()
	if isUpdating then return end
	isUpdating = true
	local maxRetries = 3
	local retryDelay = 10
	for attempt = 1, maxRetries do
		local success, err = pcall(UpdateLeaderboard)
		if success then
			break
		else
			warn("[TOPRACHA] Error al actualizar leaderboard (intento "..attempt.."): ", err)
			task.wait(retryDelay * attempt) -- Espera más en cada intento
		end
	end
	isUpdating = false
end

task.spawn(function()
	while true do
		SafeUpdateLeaderboard()
		task.wait(300) -- 5 minutos
	end
end)
