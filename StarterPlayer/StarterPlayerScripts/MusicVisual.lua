local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ═══════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════
local okTheme, THEME = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
end)
if not okTheme then
	THEME = { accent = Color3.fromRGB(70, 30, 215) }
end

-- ═══════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════
local visuals = Workspace:WaitForChild("visuals", 15)
if not visuals then return end

local MusicPlayerUI = visuals:WaitForChild("MusicPlayerUI", 15)
if not MusicPlayerUI then return end

local Main = MusicPlayerUI:WaitForChild("Main", 15)
if not Main then return end

local UI = {
	SongTitle = Main:FindFirstChild("SongTitle"),
	Artist = Main:FindFirstChild("Artist"),
	TimeDisplay = Main:FindFirstChild("TimeDisplay"),
	ProgressBg = Main:FindFirstChild("ProgressBg"),
	ProgressFill = nil,
	Equalizer = Main:FindFirstChild("Equalizer"),
	SeparatorLine = Main:FindFirstChild("SeparatorLine"),
	EqualizerBars = {},
	Glow = nil,
}

if UI.ProgressBg then
	UI.ProgressFill = UI.ProgressBg:FindFirstChild("ProgressFill")
	if UI.ProgressFill then
		UI.Glow = UI.ProgressFill:FindFirstChild("Glow")
	end
end

local function getAllGuiObjects(parent)
	local guiObjects = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(guiObjects, child)
		end
		for _, g in ipairs(getAllGuiObjects(child)) do
			table.insert(guiObjects, g)
		end
	end
	return guiObjects
end

if UI.Equalizer then
	UI.EqualizerBars = getAllGuiObjects(UI.Equalizer)
end

-- ═══════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════
local SongHolder = nil
local displayedSongId = nil
local metadataCache = {}
local loudnessValue = 0
local loudnessAlpha = 0.18
local loudnessSensitivity = 1.6

-- ═══════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════
local function formatTime(s)
	if not s or s ~= s or s < 0 then return "0:00" end
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

local function getAssetId(soundId)
	if not soundId or soundId == "" then return nil end
	return soundId:match("rbxassetid://(%d+)")
end

local function showText(title, artist)
	if UI.SongTitle then UI.SongTitle.Text = title or "Sin música" end
	if UI.Artist then UI.Artist.Text = artist or "" end
end

local function showNoMusic()
	displayedSongId = nil
	showText("Sin música", "Esperando...")
	if UI.TimeDisplay then UI.TimeDisplay.Text = "0:00 / 0:00" end
	if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(0, 1) end
end

local function getMetadata(sound, assetId)
	if sound then
		local attrName = sound:GetAttribute("SongName")
		local attrArtist = sound:GetAttribute("SongArtist")
		if attrName and attrName ~= "" then
			return attrName, attrArtist or "Desconocido"
		end
	end

	if assetId and metadataCache[assetId] then
		local cached = metadataCache[assetId]
		return cached.name, cached.artist
	end

	if assetId then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(assetId), Enum.InfoType.Asset)
		end)
		if success and info then
			local name = info.Name or ("Audio " .. assetId)
			local artist = (info.Creator and info.Creator.Name) or "Desconocido"
			metadataCache[assetId] = { name = name, artist = artist }
			return name, artist
		end
	end

	return assetId and ("Audio " .. assetId) or "Sin música", "Desconocido"
end

local function updateSongInfo()
	if not SongHolder then showNoMusic() return end
	local soundId = ""
	pcall(function() soundId = SongHolder.SoundId end)
	if soundId == "" then showNoMusic() return end

	local assetId = getAssetId(soundId)
	if not assetId then showNoMusic() return end
	if assetId == displayedSongId then return end

	if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(0, 1) end
	if UI.TimeDisplay then UI.TimeDisplay.Text = "0:00 / 0:00" end

	local name, artist = getMetadata(SongHolder, assetId)
	showText(name, artist)
	displayedSongId = assetId
end

local function connectToSound(sound)
	SongHolder = sound
	displayedSongId = nil

	if not sound then
		showNoMusic()
		return
	end

	sound:GetPropertyChangedSignal("SoundId"):Connect(function()
		task.delay(0.05, updateSongInfo)
	end)
	sound:GetAttributeChangedSignal("SongName"):Connect(updateSongInfo)
	updateSongInfo()
end

-- ═══════════════════════════════════════════════════════
-- RUNSERVICE MANAGER (v1 style)
-- ═══════════════════════════════════════════════════════
local RunServiceManager = {}
RunServiceManager.__index = RunServiceManager

function RunServiceManager.new()
	local self = setmetatable({}, RunServiceManager)
	self._activeTasks = {}
	self._activeTasksHeartbeat = {}
	self:_listenRenderStepped()
	self:_listenHeartbeat()
	return self
end

local function remove(list, id)
	for i, v in ipairs(list) do
		if v.Id == id then
			table.remove(list, i)
			return true
		end
	end
	return false
end

local function add(list, id, func)
	for _, v in pairs(list) do
		if v.Id == id then error("Function with id "..tostring(id).." already exists") end
	end
	assert(id, "Need an id to bind function")
	assert(func, "Need a function to bind")
	table.insert(list, {Id=id, Func=func})
end

function RunServiceManager:AddRenderStepped(id, func)
	add(self._activeTasks, id, func)
end
function RunServiceManager:RemoveRenderStepped(id)
	return remove(self._activeTasks, id)
end

function RunServiceManager:AddHeartbeat(id, func)
	add(self._activeTasksHeartbeat, id, func)
end
function RunServiceManager:RemoveHeartbeat(id)
	return remove(self._activeTasksHeartbeat, id)
end

function RunServiceManager:_listenRenderStepped()
	RunService.RenderStepped:Connect(function(dt)
		for _, v in ipairs(self._activeTasks) do
			v.Func(dt)
		end
	end)
end

function RunServiceManager:_listenHeartbeat()
	local lastTick = tick()
	RunService.Heartbeat:Connect(function(dt)
		if tick() - lastTick <= 0.1 then return end
		lastTick = tick()
		for _, v in ipairs(self._activeTasksHeartbeat) do
			v.Func(dt)
		end
	end)
end

local RSM = RunServiceManager.new()

-- ═══════════════════════════════════════════════════════
-- LOOP DE PROGRESO Y TIEMPO (Heartbeat)
-- ═══════════════════════════════════════════════════════
RSM:AddHeartbeat("MusicProgress", function()
	if not SongHolder then return end
	local dur, pos = 0, 0
	pcall(function() dur = SongHolder.TimeLength pos = SongHolder.TimePosition end)

	if dur > 0 then
		if UI.TimeDisplay then UI.TimeDisplay.Text = formatTime(pos).." / "..formatTime(dur) end
		if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(math.clamp(pos/dur,0,1),1) end
	end
end)

-- ═══════════════════════════════════════════════════════
-- EQUALIZER (Heartbeat)
-- ═══════════════════════════════════════════════════════
local barHues = {}
local barCurrentHeights = {}
local barTargetHeights = {}
for i = 1, #UI.EqualizerBars do
	barHues[i] = (i-1) / math.max(#UI.EqualizerBars, 1)
	barCurrentHeights[i] = 0.08
	barTargetHeights[i] = 0.08
end

RSM:AddRenderStepped("Equalizer", function(dt)
	if #UI.EqualizerBars == 0 then return end
	local playing = false
	if SongHolder then pcall(function() playing = SongHolder.Playing end) end

	for i=1,#UI.EqualizerBars do
		barHues[i] = (barHues[i] + dt * 0.6) % 1
		pcall(function() UI.EqualizerBars[i].BackgroundColor3 = Color3.fromHSV(barHues[i],1,1) end)
	end

	if playing then
		local ok, val = pcall(function() return SongHolder.PlaybackLoudness end)
		if ok and type(val) == "number" then
			local scaled = math.clamp(val*loudnessSensitivity/100,0,1)
			loudnessValue = loudnessValue*(1-loudnessAlpha) + scaled*loudnessAlpha
		end
		local base = 0.12
		local intensity = base + (loudnessValue*0.88)
		for i = 1, #UI.EqualizerBars do
			local jitter = (i%3)*0.03
			local randomFactor = 0.6 + math.random()*0.4
			barTargetHeights[i] = math.clamp(base + randomFactor*intensity + jitter, 0.08, 1)
		end
	else
		loudnessValue = loudnessValue*0.9
		for i = 1, #UI.EqualizerBars do
			barTargetHeights[i] = 0.08
		end
	end
	-- Lerp basado en dt (framerate-independiente)
	local speed = playing and 18 or 9
	local alpha = math.min(1, dt * speed)
	for i, bar in ipairs(UI.EqualizerBars) do
		barCurrentHeights[i] = barCurrentHeights[i] + (barTargetHeights[i] - barCurrentHeights[i]) * alpha
		bar.Size = UDim2.fromScale(bar.Size.X.Scale, barCurrentHeights[i])
	end
end)

-- ═══════════════════════════════════════════════════════
-- GLOW (Heartbeat)
-- ═══════════════════════════════════════════════════════
if UI.Glow then
	local glowTweenExpand = TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {ImageTransparency=0.1, Size=UDim2.fromOffset(60,60)})
	local glowTweenShrink = TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {ImageTransparency=0.4, Size=UDim2.fromOffset(40,40)})
	local glowLastTick = 0
	local glowExpanding = false
	RSM:AddHeartbeat("GlowEffect", function()
		local playing = false
		if SongHolder then pcall(function() playing = SongHolder.Playing end) end
		if not playing then return end
		local now = tick()
		if now - glowLastTick >= 0.6 then
			glowLastTick = now
			glowExpanding = not glowExpanding
			if glowExpanding then glowTweenExpand:Play() else glowTweenShrink:Play() end
		end
	end)
end

-- ═══════════════════════════════════════════════════════
-- SEPARATOR LINE (Heartbeat)
-- ═══════════════════════════════════════════════════════
if UI.SeparatorLine then
	local gradient = UI.SeparatorLine:FindFirstChild("UIGradient")
	if gradient then
		local offset = 0
		RSM:AddRenderStepped("SeparatorRainbow", function(dt)
			offset = (offset + dt * 0.6) % 1
			gradient.Offset = Vector2.new(offset, 0)
		end)
	end
end

-- ═══════════════════════════════════════════════════════
-- BUSCAR SOUND CONTINUAMENTE (Heartbeat)
-- ═══════════════════════════════════════════════════════
RSM:AddHeartbeat("SoundFinder", function()
	local sound = Workspace:FindFirstChild("QueueSound")
	if sound and sound:IsA("Sound") then
		if SongHolder ~= sound then connectToSound(sound) end
	else
		if SongHolder ~= nil then connectToSound(nil) end
	end
end)

-- ═══════════════════════════════════════════════════════
-- START
-- ═══════════════════════════════════════════════════════
showNoMusic()
