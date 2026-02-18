local MarketplaceService = game:GetService('MarketplaceService')
local ReplicatedStorage = game:GetService('ReplicatedStorage'):WaitForChild("RemotesGlobal")
local Players = game:GetService('Players')

local ProductIds = require(ReplicatedStorage.LeaderBoards.DonationsIds)

local Board = workspace.LeaderBoards:WaitForChild('Leaderboards'):WaitForChild('DonationBoard')
local Scrolling = Board.SurfaceGui.Container.ButtonsContainer.ScrollingFrame
local Template = Scrolling.Template

local Player = Players.LocalPlayer

local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return formatted
end

local function AddDonationProduct(Id)
	local NewTemplate = Template:Clone()
	NewTemplate.Name = tostring(Id)
	NewTemplate.Visible = true

	local ProductInfo
	local Success, Error = pcall(function()
		ProductInfo = MarketplaceService:GetProductInfo(Id, Enum.InfoType.Product)
	end)

	if not Success or not ProductInfo then
		warn('[DONATION LEADERBOARDS] Error -', Error)
		NewTemplate:Destroy()
		return
	end

	NewTemplate.Text = ' '..FormatNumber(ProductInfo.PriceInRobux or 0)
	NewTemplate.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(Player, Id)
	end)
	NewTemplate.LayoutOrder = ProductInfo.PriceInRobux or 0
	NewTemplate.Parent = Scrolling
end

for _, Id in pairs(ProductIds) do
	AddDonationProduct(Id)
end
