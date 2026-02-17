

-- Módulo central
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)

local ID_BADGE = Configuration.BADGES_TopLikes

-- VARIABLES --
local LEADERBOARD_COUNT = 50
local Datastore = DatastoreService:GetOrderedDataStore('TopLikes')
local likesCache = {}
local lastLikesUpdate = 0
local CACHE_TTL = 300 -- 5 minutos

local Leaderboard = workspace.LeaderBoards.Leaderboards.LikesLeaderboard
local Container = Leaderboard.SurfaceGui.Container
local Scrolling = Container.TopsContainer.TopsScrolling
local Template = Scrolling.Template

local Model = workspace.LeaderBoards.Leaderboards.LikesModel
local UserTag = Model.HumanoidRootPart.UserTag
local UsernameLabel = UserTag.Username

local TopPlayersCache = {}

local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do  
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return formatted
end

local function CheckBadgeOwnership(playerUserId)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadge(playerUserId, ID_BADGE)
	end)
	return success and hasBadge
end

local function AwardTopBadge(playerUserId)
	if TopPlayersCache[playerUserId] then return end
	if CheckBadgeOwnership(playerUserId) then
		TopPlayersCache[playerUserId] = true
		return
	end
	local player = Players:GetPlayerByUserId(playerUserId)
	if player then
		local success, error = pcall(function()
			BadgeService:AwardBadge(player.UserId, ID_BADGE)
		end)
		if success then
			TopPlayersCache[playerUserId] = true
		end
	else
		TopPlayersCache[playerUserId] = true
	end
end

local function AddItem(Rank, Data)
	if not Scrolling:FindFirstChild(tostring(Data.key)) then
		local NewTemplate = Template:Clone()
		local Info = NewTemplate:WaitForChild('Info')
		local NameLabel = Info:WaitForChild('Name'):WaitForChild('TextLabel')
		NameLabel.Text = 'Cargando...'

		local playerName = "Jugador Desconocido"
		local success, error = pcall(function()
			playerName = Players:GetNameFromUserIdAsync(Data.key)
		end)
		if not success then
			playerName = "Usuario " .. tostring(Data.key)
		end
		NameLabel.Text = playerName

		if Rank == 1 then
			UsernameLabel.Text = playerName
			local success, humanoidDescription = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(Data.key)
			end)
			if success and humanoidDescription then
				Model.Humanoid:ApplyDescription(humanoidDescription)
			end
			AwardTopBadge(Data.key)
		end

		Info.Count.TextLabel.Text = string.format("Likes totales: %s 👍", FormatNumber(Data.value))
		NewTemplate.Rank.TextLabel.Text = string.format('#%d', Rank)
		NewTemplate.Icon.Image = string.format('rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60', Data.key)
		NewTemplate.Parent = Scrolling
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Name = tostring(Data.key)
		NewTemplate.Visible = true
	end
end

local function UpdateLeaderboard()
	for _, Child in pairs(Scrolling:GetChildren()) do
		if Child.Name ~= 'Template' and Child.Name ~= 'ListLayout' then
			Child:Destroy()
		end
	end
	local success, data = pcall(function()
		return Datastore:GetSortedAsync(false, LEADERBOARD_COUNT)
	end)
	if success and data then
		local currentPage = data:GetCurrentPage()
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
		local topPlayers = data:GetCurrentPage()
		if #topPlayers > 0 and topPlayers[1].key == player.UserId then
			if not CheckBadgeOwnership(player.UserId) then
				AwardTopBadge(player.UserId)
			else
				TopPlayersCache[player.UserId] = true
			end
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

UpdateLeaderboard()

task.spawn(function()
	while task.wait(300) do
		UpdateLeaderboard()
	end
end)
