local Datastore = game:GetService("DataStoreService")
local Replicated = game:GetService("ReplicatedStorage"):WaitForChild("Panda ReplicatedStorage")
local Players = game:GetService("Players")

local Favoritos = Datastore:GetDataStore("Favoritos2")

local Remotos = Replicated:WaitForChild("Eventos_Emote")
local ObtenerFavs  = Remotos:WaitForChild("ObtenerFavs")
local AnadirFav = Remotos:WaitForChild("AnadirFav")
local Trending = Remotos:WaitForChild("Trending")
local DarTrending = Remotos:WaitForChild("ObtenerTrending")
local Sync = Remotos:WaitForChild("Sync")



local EmotesTrending = {}

Trending.OnServerEvent:Connect(function(jug, id)
	local Jugador = jug
	local ID = id
	local EstaId = false

	for i,v in pairs(EmotesTrending) do
		if v.ID == ID then
			EstaId = true
			if not table.find(v.JugadoresQueYaUsaron, Jugador) then
				table.insert(v.JugadoresQueYaUsaron, Jugador)
				v.VecesUsada = v.VecesUsada + 1
				break
			end
		end
	end

	if not EstaId then
		table.insert(EmotesTrending, {ID = ID, VecesUsada = 1, JugadoresQueYaUsaron = {Jugador}})
	end

	--Ordenar la array
	table.sort(EmotesTrending, function(a,b)
		return a.VecesUsada > b.VecesUsada
	end)

	print(EmotesTrending)
end)


DarTrending.OnServerInvoke = function(jugador)
	local Trendings = {}
	for i = 1, 10 do
		if EmotesTrending[i] then
			table.insert(Trendings, EmotesTrending[i].ID)
		end
	end
	return Trendings
end

AnadirFav.OnServerInvoke = function(jugador, id) 
	local Jugador = jugador
	local ID = id
	local FavoritosJugador = Favoritos:GetAsync(Jugador.UserId)
	local FavoritosJugador = FavoritosJugador or {}
	local EstaId = false
	for i,v in pairs(FavoritosJugador) do
		if v == ID then
			EstaId = true
			table.remove(FavoritosJugador, i)
			break
		end
	end
	if not EstaId then
		table.insert(FavoritosJugador, ID)
	end

	local succ, err = pcall(function()
		Favoritos:SetAsync(Jugador.UserId, FavoritosJugador)
	end)

	if err then
		return false
	end

	if EstaId then
		return "Eliminada"
	else
		return "Anadido"
	end
end

ObtenerFavs.OnServerInvoke = function(jugador)
	local Jugador = jugador
	local FavoritosJugador = Favoritos:GetAsync(Jugador.UserId)
	local FavoritosJugador = FavoritosJugador or {}
	return FavoritosJugador
end