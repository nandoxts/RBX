-- SERVICES --
local DatastoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- VARIABLES --
local LEADERBOARD_COUNT = 50
local TopDonators = DatastoreService:GetOrderedDataStore("TopDona")
local TopReceivers = DatastoreService:GetOrderedDataStore("TopRece")
local donatorCache = {}
local receiverCache = {}
local lastDonatorUpdate = 0
local lastReceiverUpdate = 0
local CACHE_TTL = 300 -- 5 minutos

-- REFERENCIAS DONADORES
local Leaderboard = workspace.LeaderBoards.Leaderboards.TopDonators
local Container = Leaderboard.SurfaceGui.Container
local Scrolling = Container.TopsContainer.TopsScrolling
local Template = Scrolling.Template

local Model = workspace.LeaderBoards.Leaderboards.DonatorModel
local UserTag = Model.HumanoidRootPart.UserTag
local UsernameLabel = UserTag.Username

-- REFERENCIAS RECEPTORES
local Leaderboard1 = workspace.LeaderBoards.Leaderboards.TopReceivers
local Container1 = Leaderboard1.SurfaceGui.Container
local Scrolling1 = Container1.TopsContainer.TopsScrolling
local Template1 = Scrolling1.Template

local Model1 = workspace.LeaderBoards.Leaderboards.ReceiverModel
local UserTag1 = Model1.HumanoidRootPart.UserTag
local UsernameLabel1 = UserTag1.Username

-- FUNCIONES UTILES --
local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if (k == 0) then break end
	end
	return formatted
end

-- ================== SISTEMA DONADORES ================== --

local function AddDonatorItem(Rank, Data)
	if not Scrolling:FindFirstChild(Data.key) then
		local NewTemplate = Template:Clone()
		local Info = NewTemplate:WaitForChild("Info")
		local NameLabel = Info:WaitForChild("Name"):WaitForChild("TextLabel")
		NameLabel.Text = "Error"

		local Success, Error = pcall(function()
			NameLabel.Text = Players:GetNameFromUserIdAsync(Data.key)
		end)

		if Rank == 1 then
			UsernameLabel.Text = NameLabel.Text
			local HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(Data.key)
			if HumanoidDescription then
				Model.Humanoid:ApplyDescriptionReset(HumanoidDescription)
			end
		end

		--if Error then warn(Error) end

		Info.Count.TextLabel.Text = string.format(" %s Donated", FormatNumber(Data.value))
		NewTemplate.Rank.TextLabel.Text = string.format("#%d", Rank)
		NewTemplate.Icon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", Data.key)

		NewTemplate.Parent = Scrolling
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Name = tostring(Data.key)
		NewTemplate.Visible = true
	end
end

local function UpdateDonatorBoard()
	for _, Child in pairs(Scrolling:GetChildren()) do
		if Child.Name ~= "Template" and Child.Name ~= "ListLayout" then
			Child:Destroy()
		end
	end

	local Success, Data = pcall(function()
		return TopDonators:GetSortedAsync(false, LEADERBOARD_COUNT, 1)
	end)

	if Success and Data then
		for Rank, Data in pairs(Data:GetCurrentPage()) do
			AddDonatorItem(Rank, Data)
		end
	else
		warn("[LEADERBOARD] Error al obtener datos de donadores")
	end
end

-- ================== SISTEMA RECEPTORES ================== --

local function AddReceiverItem(Rank, Data)
	if not Scrolling1:FindFirstChild(Data.key) then
		local NewTemplate = Template1:Clone()
		local Info = NewTemplate:WaitForChild("Info")
		local NameLabel = Info:WaitForChild("Name"):WaitForChild("TextLabel")
		NameLabel.Text = "Error"

		local Success, Error = pcall(function()
			NameLabel.Text = Players:GetNameFromUserIdAsync(Data.key)
		end)

		if Rank == 1 then
			UsernameLabel1.Text = NameLabel.Text
			local HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(Data.key)
			if HumanoidDescription then
				Model1.Humanoid:ApplyDescriptionReset(HumanoidDescription)
			end
		end

		--if Error then warn(Error) end

		Info.Count.TextLabel.Text = string.format(" %s Received", FormatNumber(Data.value))
		NewTemplate.Rank.TextLabel.Text = string.format("#%d", Rank)
		NewTemplate.Icon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", Data.key)

		NewTemplate.Parent = Scrolling1
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Name = tostring(Data.key)
		NewTemplate.Visible = true
	end
end

local function UpdateReceiverBoard()
	for _, Child in pairs(Scrolling1:GetChildren()) do
		if Child.Name ~= "Template" and Child.Name ~= "ListLayout" then
			Child:Destroy()
		end
	end

	local Success, Data = pcall(function()
		return TopReceivers:GetSortedAsync(false, LEADERBOARD_COUNT, 1)
	end)

	if Success and Data then
		for Rank, Data in pairs(Data:GetCurrentPage()) do
			AddReceiverItem(Rank, Data)
		end
	else
		warn("[LEADERBOARD] Error al obtener datos de receptores")
	end
end

-- ================== REFRESCAR BOARDS ================== --
UpdateDonatorBoard()
UpdateReceiverBoard()

task.spawn(function()
	while task.wait(300) do -- 5 minutos
		UpdateDonatorBoard()
		UpdateReceiverBoard()
	end
end)
