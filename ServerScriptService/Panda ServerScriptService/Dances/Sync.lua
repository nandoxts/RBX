local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local Animaciones =  require(ReplicatedStorage:WaitForChild("Emotes_Sync"):WaitForChild("Emotes_Modules"):WaitForChild("Animaciones"))
local Settings = require(script.Settings)

local Remotes = ReplicatedStorage:WaitForChild("Emotes_Sync")
local SyncRemote = Remotes.Sync
local PlayAnimationRemote = Remotes.PlayAnimation
local StopAnimationRemote = Remotes.StopAnimation

local SyncData = {}

-- Configuración de transición suave
local FADE_TIME = 0.3 -- Duración del fade in/out en segundos

local Dances = {}
local DancesByAssetId = {} -- Mapeo inverso: assetId -> nombre

for _,anim in pairs(Animaciones.Ids) do
	Dances[anim.Nombre] = "rbxassetid://"..tostring(anim.ID)
	DancesByAssetId["rbxassetid://"..tostring(anim.ID)] = anim.Nombre
end

for _,anim in pairs(Animaciones.Recomendado) do
	Dances[anim.Nombre] = "rbxassetid://"..tostring(anim.ID)
	DancesByAssetId["rbxassetid://"..tostring(anim.ID)] = anim.Nombre
end

for _,anim in pairs(Animaciones.Vip) do
	Dances[anim.Nombre] = "rbxassetid://"..tostring(anim.ID)
	DancesByAssetId["rbxassetid://"..tostring(anim.ID)] = anim.Nombre
end





local Commands = {
	["Sync"] = function(Plr,SyncPlayer)
		if SyncData[SyncPlayer]["StoredAnimation"] ~= nil then
			if SyncData[Plr]["StoredAnimation"] ~= nil then
				SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
				SyncData[Plr]["StoredAnimation"]:Destroy()
				SyncData[Plr]["StoredAnimation"] = nil
			end
			local Character = Plr.Character
			local Humanoid = Character.Humanoid
			local Animation = Character.Baile
			Animation.AnimationId = SyncData[SyncPlayer]["StoredAnimation"].Animation.AnimationId
			local animator = Humanoid:FindFirstChild("Animator")
			if animator then
				local AnimationTrack = animator:LoadAnimation(Animation)

				AnimationTrack:Play(FADE_TIME)
				AnimationTrack.TimePosition = SyncData[SyncPlayer]["StoredAnimation"].TimePosition
				AnimationTrack:AdjustSpeed(SyncData[SyncPlayer]["StoredAnimation"].Speed)

				SyncData[Plr]["StoredAnimation"] = AnimationTrack

			end
		end
	end;
	["SetSync"] = function(Plr,SyncPlayer)
		if SyncData[Plr]["SyncDebounce"] == false then
			SyncData[Plr]["SyncDebounce"] = true
			if SyncData[SyncPlayer]["StoredAnimation"] ~= nil then
				if SyncData[Plr]["StoredAnimation"]  ~= nil then
					SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
					SyncData[Plr]["StoredAnimation"]:Destroy()
					SyncData[Plr]["StoredAnimation"] = nil
				end
				local Character = Plr.Character
				local Humanoid = Character.Humanoid
				local Animation = Character.Baile

				Animation.AnimationId = SyncData[SyncPlayer]["StoredAnimation"].Animation.AnimationId
				local animator = Humanoid:FindFirstChild("Animator")
				if animator then
					local AnimationTrack = animator:LoadAnimation(Animation)
					AnimationTrack.Priority = Enum.AnimationPriority.Action
					AnimationTrack:Play(FADE_TIME)
					AnimationTrack.TimePosition = SyncData[SyncPlayer]["StoredAnimation"].TimePosition
					AnimationTrack:AdjustSpeed(SyncData[SyncPlayer]["StoredAnimation"].Speed)

					SyncData[Plr]["StoredAnimation"] = AnimationTrack
					if not table.find(SyncData[SyncPlayer]["SyncPlayers"],Plr) then
						table.insert(SyncData[SyncPlayer]["SyncPlayers"],Plr)
					end

				end
			elseif Settings.CopyActualAnimation then
				if SyncData[Plr]["StoredAnimation"]  ~= nil then
					SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
					SyncData[Plr]["StoredAnimation"]:Destroy()
					SyncData[Plr]["StoredAnimation"] = nil
				end
				-- play animation
				local humanoid = Plr.Character:WaitForChild("Humanoid")
				local humanoid2 = SyncPlayer.Character:WaitForChild("Humanoid")
				local animator = humanoid:WaitForChild("Animator")
				local animator2 = humanoid2:WaitForChild("Animator")

				local AnimTracks1 = animator:GetPlayingAnimationTracks()

				for _,v in pairs(AnimTracks1) do
					v:Stop(FADE_TIME)
				end

				local Animation = Plr.Character.Baile
				local AnimationTracks = animator2:GetPlayingAnimationTracks()
				local anim
				local animator = humanoid:WaitForChild("Animator")

				for _, v in pairs(AnimationTracks) do
					Animation.AnimationId = v.Animation.AnimationId

					anim = animator:LoadAnimation(Animation)
					anim.Priority = Enum.AnimationPriority.Action
					anim:Play(FADE_TIME)
					anim.TimePosition = v.TimePosition
					anim:AdjustSpeed(v.Speed)

				end
				SyncData[Plr]["StoredAnimation"] = anim
				if not table.find(SyncData[SyncPlayer]["SyncPlayers"],Plr) then
					table.insert(SyncData[SyncPlayer]["SyncPlayers"],Plr)
				end

			end
		elseif SyncData[Plr]["SyncDebounce"] == true then
			if SyncData[SyncPlayer]["StoredAnimation"] ~= nil then
				for i,PlayerTable in pairs(SyncData)do
					for Index,v in pairs(PlayerTable["SyncPlayers"])do
						if v == Plr then
							table.remove(PlayerTable["SyncPlayers"],Index)
						end
					end
				end
				if SyncData[Plr]["StoredAnimation"]  ~= nil then
					SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
					SyncData[Plr]["StoredAnimation"]:Destroy()
					SyncData[Plr]["StoredAnimation"] = nil
				end
				local Character = Plr.Character
				local Humanoid = Character.Humanoid
				local Animation = Character.Baile
				Animation.AnimationId = SyncData[SyncPlayer]["StoredAnimation"].Animation.AnimationId
				local animator = Humanoid:FindFirstChild("Animator")
				if animator then
					local AnimationTrack = animator:LoadAnimation(Animation)
					AnimationTrack.Priority = Enum.AnimationPriority.Action
					AnimationTrack:Play(FADE_TIME)
					AnimationTrack.TimePosition = SyncData[SyncPlayer]["StoredAnimation"].TimePosition
					AnimationTrack:AdjustSpeed(SyncData[SyncPlayer]["StoredAnimation"].Speed)
					SyncData[Plr]["StoredAnimation"] = AnimationTrack
					if not table.find(SyncData[SyncPlayer]["SyncPlayers"],Plr) then
						table.insert(SyncData[SyncPlayer]["SyncPlayers"],Plr)
					end

				end
			end
		end
	end;
	["Unsync"] = function(Plr)
		if SyncData[Plr]["SyncDebounce"] == true then
			SyncData[Plr]["SyncDebounce"] = false 
			if SyncData[Plr]["StoredAnimation"] ~= nil then
				SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
				SyncData[Plr]["StoredAnimation"]:Destroy()
				SyncData[Plr]["StoredAnimation"] = nil
			end
			for i,PlayerTable in pairs(SyncData)do
				for Index,v in pairs(PlayerTable["SyncPlayers"])do
					if v == Plr then
						table.remove(PlayerTable["SyncPlayers"],Index)
					end
				end
			end
			if #SyncData[Plr]["SyncPlayers"] >= 1 then
				for _,Player in pairs(SyncData[Plr]["SyncPlayers"])do
					if SyncData[Player]["StoredAnimation"] ~= nil then
						SyncData[Player]["StoredAnimation"]:Stop(FADE_TIME)
						SyncData[Player]["StoredAnimation"]:Destroy()
						SyncData[Player]["StoredAnimation"] = nil

						if Plr.Character ~= nil then
							local SyncOnOff = Plr.Character:FindFirstChild("SyncOnOff")
							if SyncOnOff then
								SyncOnOff.Value = false
							end
						end	
					end
				end
			end

		end
	end;
	["Reset"] = function(Plr)
		if SyncData[Plr]["StoredAnimation"] ~= nil then
			SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
			SyncData[Plr]["StoredAnimation"]:Destroy()
			SyncData[Plr]["StoredAnimation"] = nil
		end
	end;
	["Disconnect"] = function(Plr)
		for _,Player in pairs(SyncData[Plr]["SyncPlayers"])do
			if SyncData[Player]["StoredAnimation"] ~= nil then
				SyncData[Player]["StoredAnimation"]:Stop(FADE_TIME)
				SyncData[Player]["StoredAnimation"]:Destroy()
				SyncData[Player]["StoredAnimation"] = nil
			end
			for Index,SyncPlr in pairs(SyncData[Player]["SyncPlayers"])do
				if SyncData[SyncPlr]["StoredAnimation"] ~= nil then
					SyncData[SyncPlr]["StoredAnimation"]:Stop(FADE_TIME)
					SyncData[SyncPlr]["StoredAnimation"]:Destroy()
					SyncData[SyncPlr]["StoredAnimation"] = nil
				end
			end
			SyncData[Player]["SyncDebounce"] = false

		end
		for i,PlayerTable in pairs(SyncData)do
			for Index,v in pairs(PlayerTable["SyncPlayers"])do
				if v == Plr then
					table.remove(PlayerTable["SyncPlayers"],Index)
				end
			end
		end
		for Index, Connection in pairs(SyncData[Plr]["Connections"]) do
			if Connection then
				Connection:Disconnect()
				Connection = nil
			end
		end
		SyncData[Plr]["Connections"] = nil
		SyncData[Plr]["StoredAnimation"] = nil
		SyncData[Plr]["SyncPlayers"] = nil
		SyncData[Plr]["SyncDebounce"] = nil
		SyncData[Plr] = nil
	end;
	["Respawn"] = function(Plr)
		if SyncData[Plr]["StoredAnimation"] ~= nil then
			SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
			SyncData[Plr]["StoredAnimation"]:Destroy()
			SyncData[Plr]["StoredAnimation"] = nil
		end
		SyncData[Plr]["SyncDebounce"] = false

		if Settings.ResetAnimationOnRespawn then
			if #SyncData[Plr]["SyncPlayers"] >= 1 then
				for _,Player in pairs(SyncData[Plr]["SyncPlayers"])do
					if SyncData[Player]["StoredAnimation"] ~= nil then
						SyncData[Player]["StoredAnimation"]:Stop(FADE_TIME)
						SyncData[Player]["StoredAnimation"]:Destroy()
						SyncData[Player]["StoredAnimation"] = nil
					end
					for Index,SyncPlr in pairs(SyncData[Player]["SyncPlayers"])do
						if SyncData[SyncPlr]["StoredAnimation"] ~= nil then
							SyncData[SyncPlr]["StoredAnimation"]:Stop(FADE_TIME)
							SyncData[SyncPlr]["StoredAnimation"]:Destroy()
							SyncData[SyncPlr]["StoredAnimation"] = nil
						end
					end
					SyncData[Player]["SyncDebounce"] = false

				end
			end
			SyncData[Plr]["SyncPlayers"] = {}
		end
		for i,PlayerTable in pairs(SyncData)do
			for Index,v in pairs(PlayerTable["SyncPlayers"])do
				if v == Plr then
					table.remove(PlayerTable["SyncPlayers"],Index)
				end
			end
		end
	end;
}

local function GetPlr(Plr)
	if Plr ~= "" then
		Plr = Plr.Name:lower()
		for _, player in ipairs(Players:GetPlayers()) do
			if Plr == player.Name:lower():sub(1, #Plr) then
				return player
			end
		end
		return nil
	end
end

local NotifyAnimationToClient = function(Plr, animationName)
	if animationName then
		SyncData[Plr]["CurrentAnimationName"] = animationName
		pcall(function()
			PlayAnimationRemote:FireClient(Plr, "playAnim", animationName)
		end)
	else
		SyncData[Plr]["CurrentAnimationName"] = nil
		pcall(function()
			StopAnimationRemote:FireClient(Plr)
		end)
	end
end

local StopAnimation = function(Plr)
	if SyncData[Plr]["StoredAnimation"] ~= nil then
		SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
		SyncData[Plr]["StoredAnimation"]:Destroy()
		SyncData[Plr]["StoredAnimation"] = nil
	end
	SyncData[Plr]["CurrentAnimationName"] = nil
	NotifyAnimationToClient(Plr, nil) -- Limpiar UI del jugador principal
	if #SyncData[Plr]["SyncPlayers"] >= 1 then
		for _,Player in pairs(SyncData[Plr]["SyncPlayers"])do
			Commands.Reset(Player)
			NotifyAnimationToClient(Player, nil) -- Limpiar UI del jugador sincronizado
			for index,SyncPlayer in pairs(SyncData[Player]["SyncPlayers"])do
				Commands.Reset(SyncPlayer)
				NotifyAnimationToClient(SyncPlayer, nil) -- Limpiar UI de sync anidados
			end
		end
	end
end

local PlayAnimation = function(Plr,func,AnimationData)
	if func == "playAnim" and AnimationData and Dances[AnimationData] ~= nil then
		-- Guardar los seguidores antes de cualquier operación
		local myFollowers = {}
		if SyncData[Plr] and SyncData[Plr]["SyncPlayers"] then
			for _, follower in pairs(SyncData[Plr]["SyncPlayers"]) do
				table.insert(myFollowers, follower)
			end
		end

		-- Si está sincronizado con alguien, desincronizarse de ese líder
		if SyncData[Plr]["SyncDebounce"] == true then
			SyncData[Plr]["SyncDebounce"] = false

			-- Remover de la lista de seguidores de otros líderes
			for i, PlayerTable in pairs(SyncData) do
				if i ~= Plr then
					for Index, v in pairs(PlayerTable["SyncPlayers"]) do
						if v == Plr then
							table.remove(PlayerTable["SyncPlayers"], Index)
							break
						end
					end
				end
			end

			-- Actualizar SyncOnOff
			if Plr.Character and Plr.Character:FindFirstChild("SyncOnOff") then
				Plr.Character.SyncOnOff.Value = false
			end
		end

		-- Restaurar la lista de seguidores
		SyncData[Plr]["SyncPlayers"] = myFollowers

		-- Detener animación actual si existe
		if SyncData[Plr]["StoredAnimation"] then
			SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
			SyncData[Plr]["StoredAnimation"]:Destroy()
			SyncData[Plr]["StoredAnimation"] = nil
		end

		local Character = Plr.Character
		local Humanoid = Character.Humanoid
		local Animation = Character.Baile
		Animation.AnimationId = Dances[AnimationData]
		local animator = Humanoid:FindFirstChild("Animator")
		if animator then
			local AnimationTrack = animator:LoadAnimation(Animation)
			AnimationTrack.Priority = Enum.AnimationPriority.Action
			AnimationTrack:Play(FADE_TIME)
			AnimationTrack.TimePosition = 0
			SyncData[Plr]["StoredAnimation"] = AnimationTrack
			NotifyAnimationToClient(Plr, AnimationData)

			-- Actualizar a los seguidores con el nuevo baile
			if #myFollowers >= 1 then
				for _, Player in pairs(myFollowers) do
					if Player and SyncData[Player] then
						Commands.Sync(Player, Plr)
						NotifyAnimationToClient(Player, AnimationData)
						-- Actualizar seguidores anidados
						if SyncData[Player]["SyncPlayers"] then
							for _, SyncPlr in pairs(SyncData[Player]["SyncPlayers"]) do
								Commands.Sync(SyncPlr, Plr)
								NotifyAnimationToClient(SyncPlr, AnimationData)
							end
						end
					end
				end
			end
		end	
	elseif func == "speed" then
		if SyncData[Plr]["StoredAnimation"] ~= nil then
			local Character = Plr.Character
			local Humanoid = Character.Humanoid
			local Animation = Character.Baile
			Animation.AnimationId =  SyncData[Plr]["StoredAnimation"].Animation.AnimationId
			local animator = Humanoid:FindFirstChild("Animator")
			if animator then
				local AnimationTrack = animator:LoadAnimation(Animation)
				AnimationTrack.Priority = Enum.AnimationPriority.Action
				AnimationTrack:Play(FADE_TIME)
				AnimationTrack.TimePosition = SyncData[Plr]["StoredAnimation"].TimePosition
				AnimationTrack:AdjustSpeed(AnimationData)
				SyncData[Plr]["StoredAnimation"] = AnimationTrack
				if #SyncData[Plr]["SyncPlayers"] >= 1 then
					for _,Player in pairs(SyncData[Plr]["SyncPlayers"])do
						Commands.Sync(Player,Plr)
						for index,SyncPlr in pairs(SyncData[Player]["SyncPlayers"])do
							Commands.Sync(SyncPlr,Plr)
						end
					end
				end
			end	

		end
	end
end

local SyncAction = function(Plr,action,Name)
	if action == "sync" then
		local PlayerSync = GetPlr(Name)
		if PlayerSync then
			if Plr ~= PlayerSync then
				if Plr and Plr.Character and Plr.Character.SyncOnOff then
					-- Guardar los seguidores actuales (ellos siguen siendo seguidores de Plr)
					local myFollowers = {}
					if SyncData[Plr] and SyncData[Plr]["SyncPlayers"] then
						for _, follower in pairs(SyncData[Plr]["SyncPlayers"]) do
							table.insert(myFollowers, follower)
						end
					end

					-- Detener la animación actual del jugador
					if SyncData[Plr]["StoredAnimation"] ~= nil then
						SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
						SyncData[Plr]["StoredAnimation"]:Destroy()
						SyncData[Plr]["StoredAnimation"] = nil
					end
					SyncData[Plr]["CurrentAnimationName"] = nil

					-- Restaurar la lista de seguidores (NO la limpiamos)
					SyncData[Plr]["SyncPlayers"] = myFollowers

					-- Sincronizar al jugador con el objetivo
					Plr.Character.SyncOnOff.Value = true
					Commands.SetSync(Plr, PlayerSync)

					-- Notificar al cliente qué animación está sincronizada
					local syncedAnimName = SyncData[PlayerSync]["CurrentAnimationName"]
					if syncedAnimName then
						NotifyAnimationToClient(Plr, syncedAnimName)
					end

					-- Actualizar a los seguidores de Plr con la nueva animación
					-- Ellos siguen a Plr (su líder original), reciben lo que Plr tenga
					if #myFollowers > 0 and SyncData[Plr]["StoredAnimation"] then
						for _, follower in pairs(myFollowers) do
							if follower and follower.Character and SyncData[follower] then
								-- Detener animación actual del seguidor
								if SyncData[follower]["StoredAnimation"] ~= nil then
									SyncData[follower]["StoredAnimation"]:Stop(FADE_TIME)
									SyncData[follower]["StoredAnimation"]:Destroy()
									SyncData[follower]["StoredAnimation"] = nil
								end

								-- Sincronizar seguidor con su líder (Plr), NO con PlayerSync
								local Character = follower.Character
								local Humanoid = Character:FindFirstChild("Humanoid")
								local Animation = Character:FindFirstChild("Baile")

								if Humanoid and Animation and SyncData[Plr]["StoredAnimation"] then
									Animation.AnimationId = SyncData[Plr]["StoredAnimation"].Animation.AnimationId
									local animator = Humanoid:FindFirstChild("Animator")
									if animator then
										local AnimationTrack = animator:LoadAnimation(Animation)
										AnimationTrack.Priority = Enum.AnimationPriority.Action
										AnimationTrack:Play(FADE_TIME)
										AnimationTrack.TimePosition = SyncData[Plr]["StoredAnimation"].TimePosition
										AnimationTrack:AdjustSpeed(SyncData[Plr]["StoredAnimation"].Speed)

										SyncData[follower]["StoredAnimation"] = AnimationTrack

										-- Notificar al seguidor
										if syncedAnimName then
											NotifyAnimationToClient(follower, syncedAnimName)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	elseif action == "unsync" then
		if Plr and Plr.Character and Plr.Character.SyncOnOff then
			Plr.Character.SyncOnOff.Value = false

			-- Detener solo la animación del jugador
			if SyncData[Plr]["StoredAnimation"] ~= nil then
				SyncData[Plr]["StoredAnimation"]:Stop(FADE_TIME)
				SyncData[Plr]["StoredAnimation"]:Destroy()
				SyncData[Plr]["StoredAnimation"] = nil
			end
			SyncData[Plr]["SyncDebounce"] = false

			-- Remover de la lista de seguidores de otros líderes
			for i, PlayerTable in pairs(SyncData) do
				if i ~= Plr then -- No tocar su propia lista de seguidores
					for Index, v in pairs(PlayerTable["SyncPlayers"]) do
						if v == Plr then
							table.remove(PlayerTable["SyncPlayers"], Index)
							break
						end
					end
				end
			end

			NotifyAnimationToClient(Plr, nil)

			-- Los seguidores de Plr también pierden la animación porque su líder dejó de bailar
			if SyncData[Plr]["SyncPlayers"] and #SyncData[Plr]["SyncPlayers"] >= 1 then
				for _, follower in pairs(SyncData[Plr]["SyncPlayers"]) do
					if follower and SyncData[follower] then
						if SyncData[follower]["StoredAnimation"] ~= nil then
							SyncData[follower]["StoredAnimation"]:Stop(FADE_TIME)
							SyncData[follower]["StoredAnimation"]:Destroy()
							SyncData[follower]["StoredAnimation"] = nil
						end
						NotifyAnimationToClient(follower, nil)
					end
				end
			end
		end
	end
end

local PlayerRemoving = function(Plr)
	Commands.Disconnect(Plr)
end

local CharacterAdded = function(Character)
	local Animation = Instance.new("Animation")
	Animation.Name = "Baile"
	Animation.Parent = Character
	local SyncOnOFf = Instance.new("BoolValue")
	SyncOnOFf.Name = "SyncOnOff"
	SyncOnOFf.Parent = Character

	local Plr = Players:GetPlayerFromCharacter(Character)
	local Humanoid = Character.Humanoid
	if Humanoid then
		local connectiondie
		connectiondie = Humanoid.Died:Connect(function()
			Commands.Respawn(Plr)
			connectiondie:Disconnect()
		end)
	end
end

local PlayerAdded = function(Plr)
	SyncData[Plr] = {
		["Connections"] = {};
		["StoredAnimation"] = nil;
		["SyncPlayers"] = {};
		["SyncDebounce"] = false;
		["CurrentAnimationName"] = nil;
	}
	local charLoadConnection = Plr.CharacterAdded:Connect(CharacterAdded)
	table.insert(SyncData[Plr]["Connections"], charLoadConnection)

	local Character = Plr.Character
	if Character then
		CharacterAdded(Character)
	end
	local playerChattedConnection = Plr.Chatted:Connect(function(Msg)
		local Args = Msg:split(" ")
		if Args[1] ~= nil and  Args[1]:lower() == "sync" then
			if Args[2] ~= nil then
				local PlayerSync = GetPlr(Args[2])
				if PlayerSync then
					if Plr ~= PlayerSync then
						if Plr and Plr.Character and Plr.Character.SyncOnOff then
							Plr.Character.SyncOnOff.Value = true
							Commands.SetSync(Plr,PlayerSync)
						end
					end
				end
			end
		elseif Args[1] ~= nil and Args[1]:lower() == "unsync" then
			if Plr and Plr.Character and Plr.Character.SyncOnOff then
				Plr.Character.SyncOnOff.Value = false
				Commands.Unsync(Plr)
			end
		end
	end)
	table.insert(SyncData[Plr]["Connections"], playerChattedConnection)
end

--Event Handlers--
Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)
PlayAnimationRemote.OnServerEvent:Connect(PlayAnimation)
StopAnimationRemote.OnServerEvent:Connect(StopAnimation)
SyncRemote.OnServerEvent:Connect(SyncAction)

for _,Player in pairs(Players:GetPlayers())do
	PlayerAdded(Player)
end