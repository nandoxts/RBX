
-- SERVICES --

local InsertService = game:GetService('InsertService')
local Configuration = require(game.ServerScriptService.Systems.Configuration)

-- VARIABLES --
local DONATIONS_EMOTE = Configuration.DONATIONS_EMOTE
local DONATOR_EMOTE = Configuration.DONATOR_EMOTE
local RECEIVER_EMOTE = Configuration.RECEIVER_EMOTE
local LIKES_EMOTE = Configuration.LIKES_EMOTE
local Racha_EMOTE = Configuration.Racha_EMOTE

local USER_01 = Configuration.USER01_EMOTE
local USER_02 = Configuration.USER02_EMOTE
local USER_03 = Configuration.USER03_EMOTE
local USER_04 = Configuration.USER04_EMOTE
local USER_05 = Configuration.USER05_EMOTE
local USER_06 = Configuration.USER06_EMOTE

local LeaderBoardsRoot = workspace:WaitForChild("LeaderBoards")
local LeaderboardsFolder = LeaderBoardsRoot:WaitForChild("Leaderboards")
local DonationsModel = LeaderboardsFolder:WaitForChild("DonationsModel")
local DonatorModel = LeaderboardsFolder:WaitForChild("DonatorModel")
local ReceiverModel = LeaderboardsFolder:WaitForChild("ReceiverModel")
local LikesModel = LeaderboardsFolder:WaitForChild("LikesModel")
local RachaModel = LeaderboardsFolder:WaitForChild("RachaModel")

local Users = LeaderBoardsRoot:WaitForChild("Users")
local U01 = Users:WaitForChild("ignxts")
local U02 = Users:WaitForChild("AngeloGarciia")
local U03 = Users:WaitForChild("ClasicSans738")
local U04 = Users:WaitForChild("xlm_brem")
local U05 = Users:WaitForChild("UserJL11")
local U06 = Users:WaitForChild("bvwdhfv")

local ModelMapping = {
	[DonationsModel] = DONATIONS_EMOTE;
	[DonatorModel] = DONATOR_EMOTE;
	[ReceiverModel] = RECEIVER_EMOTE;
	[LikesModel] = LIKES_EMOTE;
	[RachaModel] = Racha_EMOTE;

	[U01] = USER_01;
	[U02] = USER_02;
	[U03] = USER_03;
	[U04] = USER_04;
	[U05] = USER_05;
	[U06] = USER_06;
}

-- INITIALIZATION --

for Model, EmoteId in pairs(ModelMapping) do
	local AnimModel
	local Success, Error = pcall(function()
		AnimModel = InsertService:LoadAsset(EmoteId)
	end)

	if Error then warn(Error) end

	if AnimModel then
		local Animation = AnimModel:FindFirstChildWhichIsA('Animation', true)
		if Animation then
			local AnimationTrack = Model.Humanoid.Animator:LoadAnimation(Animation)
			AnimationTrack.Looped = true
			AnimationTrack:Play()
		end

		AnimModel:Destroy()
	end
end