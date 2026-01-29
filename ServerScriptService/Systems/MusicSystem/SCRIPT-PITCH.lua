local SoundService = game:GetService("SoundService")

local MUSIC_SOUND_NAME = "QueueSound"
local ASSET_PREFIX = "rbxassetid://"
local DEFAULT_PITCH = 1
local DEBOUNCE_DELAY = 0.05

local sound = SoundService:FindFirstChild(MUSIC_SOUND_NAME)
if not sound then
	sound = SoundService:WaitForChild(MUSIC_SOUND_NAME, 10)
end

if not sound then return end

local pitchModule
local success = pcall(function()
	pitchModule = require(script.Parent.PitchModule)
end)

if not success then return end
if type(pitchModule) ~= "table" or not pitchModule.ids or type(pitchModule.ids) ~= "table" then return end

local pitchLookup = {}
for _, entry in ipairs(pitchModule.ids) do
	if entry.id and entry.pitch then
		pitchLookup[ASSET_PREFIX .. entry.id] = tonumber(entry.pitch) or DEFAULT_PITCH
	end
end

local function updatePitch()
	sound.PlaybackSpeed = pitchLookup[sound.SoundId] or DEFAULT_PITCH
end

local function safeUpdatePitch()
	local success = pcall(updatePitch)
	if not success then
		sound.PlaybackSpeed = DEFAULT_PITCH
	end
end

safeUpdatePitch()

local debounce = false
sound:GetPropertyChangedSignal("SoundId"):Connect(function()
	if debounce then return end
	debounce = true

	task.delay(DEBOUNCE_DELAY, function()
		safeUpdatePitch()
		debounce = false
	end)
end)