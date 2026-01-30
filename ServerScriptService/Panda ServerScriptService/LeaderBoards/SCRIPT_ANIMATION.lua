
-- SERVICES --

local InsertService = game:GetService('InsertService')
local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)

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

local Boards = workspace.LeaderBoards.Leaderboards

local DonationsModel = Boards.DonationsModel
local DonatorModel = Boards.DonatorModel
local ReceiverModel = Boards.ReceiverModel
local LikesModel = Boards.LikesModel
local RachaModel = Boards.RachaModel

local Users = Boards.Users
local U01 = Users.ignxts
local U02 = Users.AngeloGarciia
local U03 = Users.bvwdhfv
local U04 = Users.xlm_brem

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