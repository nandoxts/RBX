-- ════════════════════════════════════════════════════════════════
--  TitleSystem  |  ServerScriptService/Systems/TitleSystem
--  Escucha el RemoteEvent EquipTitle y setea atributos en el Player.
--
--  Atributos escritos:
--    EquippedTitle      → id activo  (string, "" = ninguno)
--    EquippedTitleLabel → texto para overhead/chat
--    EquippedTitleColor → hex del color
-- ════════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local TitleConfig = require(
	ReplicatedStorage:WaitForChild("Config"):WaitForChild("TitleConfig")
)

-- ── Obtener remote existente (RemotesGlobal/Title/Titles) ──────
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local equipTitleRemote = remotesGlobal
	:WaitForChild("Title")
	:WaitForChild("Titles")

-- ── Lookup por id ────────────────────────────────────────────────
local titleById = {}
for _, t in ipairs(TitleConfig) do
	titleById[t.id] = t
end

-- ── Helpers ──────────────────────────────────────────────────────
local function clearTitle(player)
	player:SetAttribute("EquippedTitle",      "")
	player:SetAttribute("EquippedTitleLabel", "")
	player:SetAttribute("EquippedTitleColor", "")
end

local function applyTitle(player, t)
	player:SetAttribute("EquippedTitle",      t.id)
	player:SetAttribute("EquippedTitleLabel", t.label)
	player:SetAttribute("EquippedTitleColor", t.color)
end

local function playerOwnsTitle(player, t)
	if not t.gamepassId or t.gamepassId == 0 then return true end
	local ok, owns = pcall(
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		player.UserId,
		t.gamepassId
	)
	return ok and owns == true
end

-- ── Handler ──────────────────────────────────────────────────────
equipTitleRemote.OnServerEvent:Connect(function(player, titleId)
	if not titleId or titleId == "" then
		clearTitle(player)
		return
	end

	local t = titleById[titleId]
	if not t then
		warn("[TitleSystem] ID desconocido:", tostring(titleId))
		return
	end

	if not playerOwnsTitle(player, t) then
		warn("[TitleSystem]", player.Name, "no posee el gamepass del título:", titleId)
		return
	end

	-- Toggle: mismo id → desequipar
	if player:GetAttribute("EquippedTitle") == titleId then
		clearTitle(player)
	else
		applyTitle(player, t)
	end
end)
