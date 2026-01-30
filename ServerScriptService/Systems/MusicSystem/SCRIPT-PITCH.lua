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

-- Build a lookup by numeric id (normalized) so we match regardless of SoundId prefix
local pitchLookup = {}
for _, entry in ipairs(pitchModule.ids) do
	if entry.id then
		local idStr = tostring(entry.id)
		local digits = idStr:match("(%d+)")
		if digits then
			-- Prefer explicit 'speed' field (playback speed), fall back to legacy 'pitch'
			local val = tonumber(entry.speed) or tonumber(entry.pitch)
			if val then
				pitchLookup[digits] = val
			end
		end
	end
end

local function getCurrentSoundIdDigits()
	local sid = tostring(sound.SoundId or "")
	-- extract first sequence of digits found in the SoundId
	return sid:match("(%d+)")
end

local function updatePitch()
	local idDigits = getCurrentSoundIdDigits()
	if idDigits and pitchLookup[idDigits] then
		sound.PlaybackSpeed = pitchLookup[idDigits]
	else
		sound.PlaybackSpeed = DEFAULT_PITCH
	end
end

local function safeUpdatePitch()
	local ok = true
	ok = pcall(updatePitch)
	if not ok then
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