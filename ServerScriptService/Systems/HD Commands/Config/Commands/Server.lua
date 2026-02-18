-- << RETRIEVE FRAMEWORK >>
local main = _G.HDAdminMain
local settings = main.settings
local Players = game:GetService("Players")

local function resolvePlayer(speaker, token)
	if not token then return nil end

	-- If it's already a Player instance
	if typeof and typeof(token) == "Instance" and token:IsA("Player") then
		return token
	end

	if type(token) == "string" then
		local s = token:gsub("^@", "")
		s = s:lower()

		-- Numeric user id
		local id = tonumber(s)
		if id then
			local p = Players:GetPlayerByUserId(id)
			if p then return p end
		end

		-- Exact name or display name (case-insensitive)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower() == s or (p.DisplayName and p.DisplayName:lower() == s) then
				return p
			end
		end
	end

	return nil
end

local function resolveTargets(speaker, token)
	-- Returns "ALL" or an array of Player instances (possibly empty)
	if not token then
		return {speaker}
	end

	-- string tokens (special selectors)
	if type(token) == "string" then
		local s = token:gsub("^@", ""):lower()
		if s == "all" or s == "everyone" or s == "*" then
			return "ALL"
		end
		if s == "others" then
			local out = {}
			for _,p in ipairs(Players:GetPlayers()) do
				if p ~= speaker then table.insert(out, p) end
			end
			return out
		end
		if s == "me" or s == "self" then
			return {speaker}
		end
	end

	-- table of tokens (list of players or names)
	if type(token) == "table" then
		local out = {}
		for _,v in ipairs(token) do
			if v then
				if typeof and typeof(v) == "Instance" and v:IsA("Player") then
					table.insert(out, v)
				else
					local p = resolvePlayer(speaker, v)
					if p then table.insert(out, p) end
				end
			end
		end
		return out
	end

	-- single instance or name
	if typeof and typeof(token) == "Instance" and token:IsA("Player") then
		return {token}
	end

	local p = resolvePlayer(speaker, token)
	if p then return {p} end

	return {speaker}
end
-- << COMMANDS >>
local module = {

	----------------------------------- (1) VIP COMMANDS -----------------------------------
	-- Valkyries
	{
		Name = "icevalkyrie";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Ice Valkyrie";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 4390891467
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "sparklevalkyrie";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Sparkle Time Valkyrie";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 1180433861
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "emeraldvalkyrie";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Emerald Valkyrie";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 2830437685
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "valkyriehelm";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Valkyrie Helm";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 1365767
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "violetvalkyrie";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Violet Valkyrie";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 1402432199
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "blackvalk";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Blackvalk";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 124730194
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "ValkyrieHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("ValkyrieHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	-- Cabezas Especiales
	{
		Name = "pumpkinhead";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Eerie Pumpkin Head";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 1158416
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "SpecialHead"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("SpecialHead")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "bitcrown";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el 8-Bit Royal Crown";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 10159600649
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "SpecialHead"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("SpecialHead")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "ghosdeeri";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Ghosdeeri";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 183468963
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "SpecialHead"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("SpecialHead")
				if hat then hat:Destroy() end
			end
		end;
	};

	-- Buckets
	{
		Name = "greenbucket";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Green Bucket of Cheer";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 102604869
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "BucketHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("BucketHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "blackbucket";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Black Iron Bucket";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 128159108
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "BucketHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("BucketHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	-- Fairies
	{
		Name = "stfairy";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el St Patrick's Day Fairy";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 226189871
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "FairyHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("FairyHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "winterfairy";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Winter Fairy";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 141742418
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "FairyHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("FairyHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	-- Dominus
	{
		Name = "dominuspittacium";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Dominus Pittacium";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 335080779
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "DominusHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("DominusHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "dominusaureus";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Dominus Aureus";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 138932314
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "DominusHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("DominusHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	{
		Name = "dominusrex";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa el Dominus Rex";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 250395631
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "DominusHat"
					hat.Parent = character
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local hat = player.Character:FindFirstChild("DominusHat")
				if hat then hat:Destroy() end
			end
		end;
	};

	-- Espada Infernal (caso especial de espalda)
	{
		Name = "infernalsword";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa la Infernal Undead Immortal Sword";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(_, args)
			local backId = 2470750640
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local back = game:GetService("InsertService"):LoadAsset(backId):GetChildren()[1]

				if back and character:FindFirstChild("Humanoid") and back:IsA("Accessory") then
					back.Name = "InfernalSword"
					back.Parent = character
					-- Asegurarse que se equipa en la espalda
					for _, v in pairs(character:GetChildren()) do
						if v:IsA("Accessory") and v.Name ~= "InfernalSword" then
							local handle = v:FindFirstChild("Handle")
							if handle then
								local weld = handle:FindFirstChildOfClass("Weld")
								if weld and weld.Part1 and weld.Part1.Name == "Torso" then
									v.Parent = nil
								end
							end
						end
					end
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]
			if player and player.Character then
				local back = player.Character:FindFirstChild("InfernalSword")
				if back then back:Destroy() end
			end
		end;
	};


	{
		Name = "hornsred";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa un sombrero en el jugador";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 215718515
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "HornHat"
					hat.Parent = character
					--print("¡Sombrero equipado para " .. player.Name .. "!")
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]

			if player and player.Character then
				local character = player.Character

				local hat = character:FindFirstChild("HornHat")
				if hat and hat:IsA("Accessory") then
					hat:Destroy()
					--print("¡Sombrero removido para " .. player.Name .. "!")
				end
			end
		end;
	};
	{
		Name = "hornspoison";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Equipa un sombrero en el jugador";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 1744060292
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "HornHat"
					hat.Parent = character
					--print("¡Sombrero equipado para " .. player.Name .. "!")
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]

			if player and player.Character then
				local character = player.Character

				local hat = character:FindFirstChild("HornHat")
				if hat and hat:IsA("Accessory") then
					hat:Destroy()
					--print("¡Sombrero removido para " .. player.Name .. "!")
				end
			end
		end;
	};

	{
		Name = "hornsfrozen";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Equipa un sombrero en el jugador";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 74891470
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "HornHat"
					hat.Parent = character
					--print("¡Sombrero equipado para " .. player.Name .. "!")
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]

			if player and player.Character then
				local character = player.Character

				local hat = character:FindFirstChild("HornHat")
				if hat and hat:IsA("Accessory") then
					hat:Destroy()
					--print("¡Sombrero removido para " .. player.Name .. "!")
				end
			end
		end;
	};

	{
		Name = "hornsreindeer";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {}; 
		Description = "Equipa un sombrero en el jugador";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(_, args)
			local hatId = 132809431
			local player = args[1]

			if player and player.Character then
				local character = player.Character
				local hat = game:GetService("InsertService"):LoadAsset(hatId):GetChildren()[1]

				if hat and character:FindFirstChild("Head") and hat:IsA("Accessory") then
					hat.Name = "HornHat"
					hat.Parent = character
					--print("¡Sombrero equipado para " .. player.Name .. "!")
				end
			end
		end;
		UnFunction = function(_, args)
			local player = args[1]

			if player and player.Character then
				local character = player.Character

				local hat = character:FindFirstChild("HornHat")
				if hat and hat:IsA("Accessory") then
					hat:Destroy()
					--print("¡Sombrero removido para " .. player.Name .. "!")
				end
			end
		end;
	};

	{
		Name = "headless"; 
		Aliases = {"headless", "hless"};
		Prefixes = {settings.Prefix};
		Rank = 1;
		RankLock = false;
		Loopable = false;
		Tags = {"character", "modification"};
		Description = "Convierte al jugador en Headless (sin cabeza)";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			if plr and plr.Character then
				local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local desc = humanoid:GetAppliedDescription()
					desc.Head = 15093053680 -- ID de Headless
					humanoid:ApplyDescription(desc)

					--[[
					-- Remover accesorios de cabeza si existen
					for _, v in ipairs(plr.Character:GetChildren()) do
						if v:IsA("Accessory") and v.Handle and v.Handle:FindFirstChildWhichIsA("Weld") 
							and v.Handle:FindFirstChildWhichIsA("Weld").Part1 == plr.Character:FindFirstChild("Head") then
							v:Destroy()
						end
					end
					]]
				end
			end
		end;
		UnFunction = function(speaker, args) -- Opcional: función para revertir
			local plr = args[1]
			if plr and plr.Character then
				local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local desc = humanoid:GetAppliedDescription()
					desc.Head = 0 -- Resetear a cabeza normal
					humanoid:ApplyDescription(desc)
				end
			end
		end;
	};

	{
		Name = "korblox"; 
		Aliases = {"korblox", "kleg"};
		Prefixes = {settings.Prefix};
		Rank = 1;
		RankLock = false;
		Loopable = false;
		Tags = {"character", "modification"};
		Description = "Reemplaza la pierna derecha por la de Korblox";
		Contributors = {"ignxts"};
		--
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			if plr and plr.Character then
				local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local desc = humanoid:GetAppliedDescription()
					desc.RightLeg = 139607718 -- ID de pierna Korblox
					humanoid:ApplyDescription(desc)

					--[[
					-- Remover accesorios de pierna si existen
					for _, v in ipairs(plr.Character:GetChildren()) do
						if v:IsA("Accessory") and v.Handle and v.Handle:FindFirstChildWhichIsA("Weld") 
							and v.Handle:FindFirstChildWhichIsA("Weld").Part1 == plr.Character:FindFirstChild("RightLeg") then
							v:Destroy()
						end
					end
					]]
				end
			end
		end;
		UnFunction = function(speaker, args) -- Opcional: función para revertir
			local plr = args[1]
			if plr and plr.Character then
				local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local desc = humanoid:GetAppliedDescription()
					desc.RightLeg = 0 -- Resetear a pierna normal
					humanoid:ApplyDescription(desc)
				end
			end
		end;
	};

	-- Efectos personalizados: fiesta, pulse, terremoto
	{
		Name = "fiesta";
		Aliases = {"fiesta"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Inicia efectos de fiesta (usa 'all' para todos)";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(player, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
			local evt = eventsFolder and eventsFolder:FindFirstChild("FiestaEvent")
			if not evt then return end

			local target = args and args[1]
			local resolved = resolveTargets(player, target)
			if resolved == "ALL" then
				evt:FireAllClients()
				return
			end

			for _,p in ipairs(resolved) do
				if p and p:IsA("Player") then
					evt:FireClient(p)
				end
			end
		end;
	};

	{
		Name = "pulse";
		Aliases = {"pulse"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Dispara efecto de pulso/rotación (usa 'all' para todos)";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(player, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
			local evt = eventsFolder and eventsFolder:FindFirstChild("RotateEffectEvent")
			if not evt then return end

			local target = args and args[1]
			local resolved = resolveTargets(player, target)
			if resolved == "ALL" then
				evt:FireAllClients()
				return
			end

			for _,p in ipairs(resolved) do
				if p and p:IsA("Player") then
					evt:FireClient(p)
				end
			end
		end;
	};

	{
		Name = "quake";
		Aliases = {"quake"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Activa efecto terremoto (usa 'all' para todos)";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(player, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
			local evt = eventsFolder and eventsFolder:FindFirstChild("TerremotoEvent")
			if not evt then return end

			local target = args and args[1]
			local resolved = resolveTargets(player, target)
			if resolved == "ALL" then
				evt:FireAllClients()
				return
			end

			for _,p in ipairs(resolved) do
				if p and p:IsA("Player") then
					evt:FireClient(p)
				end
			end
		end;
	};


	{
		Name = "acid";
		Aliases = {"acid"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Activa efecto aurora (usa 'all' para todos)";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(player, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
			local evt = eventsFolder and eventsFolder:FindFirstChild("AcidTripEvent")
			if not evt then return end

			local target = args and args[1]
			local resolved = resolveTargets(player, target)
			if resolved == "ALL" then
				evt:FireAllClients()
				return
			end

			for _,p in ipairs(resolved) do
				if p and p:IsA("Player") then
					evt:FireClient(p)
				end
			end
		end;
	};
	{
		Name = "pyscho";
		Aliases = {"pyscho"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Activa efecto pyscho (usa 'all' para todos)";
		Contributors = {"ignxts"};
		Args = {"Player"};
		Function = function(player, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local eventsFolder = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Events")
			local evt = eventsFolder and eventsFolder:FindFirstChild("PsicoSkyEvent")
			if not evt then return end

			local target = args and args[1]
			local resolved = resolveTargets(player, target)
			if resolved == "ALL" then
				evt:FireAllClients()
				return
			end

			for _,p in ipairs(resolved) do
				if p and p:IsA("Player") then
					evt:FireClient(p)
				end
			end
		end;
	};
	-- FREE CAMERA
	{
		Name = "freecam";
		Aliases = {"fc", "camera", "cam"};
		Prefixes = {settings.Prefix};
		Rank = 0;
		RankLock = false;
		Loopable = false;
		Tags = {"admin", "utility"};
		Description = "Activa/desactiva free camera - USA SHIFT+P";
		Contributors = {"SX-System"};
		Args = {};
		Function = function(speaker, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local freeCamToggle = ReplicatedStorage:FindFirstChild("FreeCamToggle")

			if not freeCamToggle then
				freeCamToggle = Instance.new("RemoteEvent")
				freeCamToggle.Name = "FreeCamToggle"
				freeCamToggle.Parent = ReplicatedStorage
			end

			freeCamToggle:FireClient(speaker)
		end;
	};


	{
		Name = "aura2";
		Aliases = {"aura2", "eff"};
		Prefixes = {settings.Prefix};
		Rank = 1.1;
		RankLock = false;
		Loopable = false;
		Tags = {"effects"};
		Description = "Aplica un aura visual a un jugador (uso: ;aura2 @usuario nombreAura)";
		Contributors = {"ignxts"};
		Args = {"Player", "String"};
		Function = function(speaker, args)
			local targetPlayer = args[1]
			local effectName = args[2] and args[2]:lower() or ""

			if not targetPlayer or not targetPlayer.Character then return end

			local ServerStorage = game:GetService("ServerStorage")
			local Auras = ServerStorage:WaitForChild("Systems"):WaitForChild("Assets"):WaitForChild("Auras")
			local character = targetPlayer.Character

			-- Buscar el aura por nombre exacto o parcial (case-insensitive)
			local auraModel = nil
			for _, child in ipairs(Auras:GetChildren()) do
				if child.Name:lower() == effectName or child.Name:lower():find(effectName, 1, true) then
					auraModel = child
					break
				end
			end

			if not auraModel then return end

			-- Tipos de instancias que son SOLO efectos visuales (sin cuerpos/humanoids)
			local VISUAL_TYPES = {
				"ParticleEmitter", "Beam", "Trail",
				"Fire", "Smoke", "Sparkles",
				"PointLight", "SpotLight", "SurfaceLight",
				"SelectionBox", "Highlight",
			}

			local function isVisualEffect(inst)
				for _, t in ipairs(VISUAL_TYPES) do
					if inst:IsA(t) then return true end
				end
				return false
			end

			-- Limpiar aura anterior si existe
			local existing = character:FindFirstChild("_AuraEffects")
			if existing then existing:Destroy() end

			-- Contenedor para fácil limpieza
			local container = Instance.new("Folder")
			container.Name = "_AuraEffects"
			container.Parent = character

			-- Mapeo de partes del aura → partes del personaje
			local PART_MAP = {
				["Torso"] = "Torso",
				["UpperTorso"] = "UpperTorso",
				["LowerTorso"] = "LowerTorso",
				["Head"] = "Head",
				["Left Arm"] = "Left Arm",
				["Right Arm"] = "Right Arm",
				["Left Leg"] = "Left Leg",
				["Right Leg"] = "Right Leg",
				["LeftUpperArm"] = "LeftUpperArm",
				["RightUpperArm"] = "RightUpperArm",
				["LeftLowerArm"] = "LeftLowerArm",
				["RightLowerArm"] = "RightLowerArm",
				["LeftUpperLeg"] = "LeftUpperLeg",
				["RightUpperLeg"] = "RightUpperLeg",
				["LeftLowerLeg"] = "LeftLowerLeg",
				["RightLowerLeg"] = "RightLowerLeg",
				["HumanoidRootPart"] = "HumanoidRootPart",
			}

			-- Copiar solo efectos visuales de cada parte a la parte equivalente del personaje
			for _, auraPart in ipairs(auraModel:GetDescendants()) do
				if isVisualEffect(auraPart) then
					local parentName = auraPart.Parent and auraPart.Parent.Name or ""
					local targetPartName = PART_MAP[parentName]
					local targetPart = character:FindFirstChild(targetPartName or "")
						or character:FindFirstChild("HumanoidRootPart")

					if targetPart then
						local cloned = auraPart:Clone()
						-- Activar el efecto
						if cloned:IsA("ParticleEmitter") or cloned:IsA("Beam") or cloned:IsA("Trail") then
							cloned.Enabled = true
						end
						cloned.Parent = targetPart
						-- Referencia en el container para limpieza
						local ref = Instance.new("ObjectValue")
						ref.Value = cloned
						ref.Parent = container
					end
				end
			end
		end;

		UnFunction = function(speaker, args)
			local targetPlayer = args[1]
			if not targetPlayer or not targetPlayer.Character then return end
			local existing = targetPlayer.Character:FindFirstChild("_AuraEffects")
			if existing then
				-- Destruir los efectos referenciados
				for _, ref in ipairs(existing:GetChildren()) do
					if ref:IsA("ObjectValue") and ref.Value and ref.Value.Parent then
						ref.Value:Destroy()
					end
				end
				existing:Destroy()
			end
		end;
	};

};


return module
