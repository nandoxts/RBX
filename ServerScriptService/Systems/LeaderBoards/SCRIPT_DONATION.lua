-- SERVICES --
local DatastoreService = game:GetService('DataStoreService')
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService('Players')

-- Módulo central
local CentralPurchaseHandler = require(game:GetService("ServerScriptService").Systems["Gamepass Gifting"]["GiftGamepass"].ManagerProcess)
local Configuration = require(game.ServerScriptService.Systems.Configuration)

--local ID_BADGE = Configuration.BADGES_Bug

local SUPER_LIKE_PRODUCT_ID  = Configuration.SUPER_LIKE

-- VARIABLES --
local LEADERBOARD_COUNT = 50
local Datastore = DatastoreService:GetOrderedDataStore('TopDonators')
local donationCache = {}
local lastDonationUpdate = 0
local CACHE_TTL = 300 -- 5 minutos

local Leaderboard = workspace.LeaderBoards.Leaderboards.DonatedLeaderboard
local Container = Leaderboard.SurfaceGui.Container
local Scrolling = Container.TopsContainer.TopsScrolling
local Template = Scrolling.Template

local Model = workspace.LeaderBoards.Leaderboards.DonationsModel
local UserTag = Model.HumanoidRootPart.UserTag
local UsernameLabel = UserTag.Username

-- FUNCIONES UTILES --
local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do  
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return formatted
end

-- Actualizar un item en el leaderboard
local function AddItem(Rank, Data)
	if not Scrolling:FindFirstChild(Data.key) then
		local NewTemplate = Template:Clone()
		local Info = NewTemplate:WaitForChild('Info')
		local NameLabel = Info:WaitForChild('Name'):WaitForChild('TextLabel')
		NameLabel.Text = 'Error'

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

		Info.Count.TextLabel.Text = string.format(' %s Donated', FormatNumber(Data.value))
		NewTemplate.Rank.TextLabel.Text = string.format('#%d', Rank)
		NewTemplate.Icon.Image = string.format('rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60', Data.key)

		NewTemplate.Parent = Scrolling
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Name = tostring(Data.key)
		NewTemplate.Visible = true
	end
end

-- Refrescar leaderboard
local function UpdateLeaderboard()
	for _, Child in pairs(Scrolling:GetChildren()) do
		if Child.Name ~= 'Template' and Child.Name ~= 'ListLayout' then
			Child:Destroy()
		end
	end

	local Success, Data = pcall(function()
		return Datastore:GetSortedAsync(false, LEADERBOARD_COUNT, 1)
	end)

	if Success and Data then
		for Rank, Data in pairs(Data:GetCurrentPage()) do
			AddItem(Rank, Data)
		end
	else
		warn("[LEADERBOARD] Error al obtener datos")
	end
end

-- 🔹 Registrar handler de donaciones
CentralPurchaseHandler.registerDonationHandler(function(receiptInfo)
	local productId = receiptInfo.ProductId

	-- Evitar procesar el producto de Super Like
	if productId == SUPER_LIKE_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- A partir de aquí se procesan SOLO productos de donación
	local userId = receiptInfo.PlayerId
	local price = 0

	local MarketplaceService = game:GetService("MarketplaceService")
	local info
	local success, err = pcall(function()
		info = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and info then
		price = info.PriceInRobux or 0
	end

	-- Guardar en DataStore
	local tries = 0
	while tries < 5 do
		tries = tries + 1
		local ok = pcall(function()
			local current = Datastore:GetAsync(userId) or 0
			Datastore:SetAsync(userId, current + price)
		end)
		if ok then break end
		task.wait(0.2)
	end

	-- Badge de donador
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local ok, hasBadge = pcall(function()
			--return BadgeService:UserHasBadgeAsync(userId, ID_BADGE)
		end)

		if ok and not hasBadge then
			pcall(function()
				--BadgeService:AwardBadge(userId, ID_BADGE)
			end)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end)


-- INICIALIZAR
UpdateLeaderboard()

task.spawn(function()
	while task.wait(300) do -- 5 minutos
		UpdateLeaderboard()
	end
end)
