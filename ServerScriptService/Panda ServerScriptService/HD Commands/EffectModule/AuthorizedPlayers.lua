local module = {}

-- Lista de jugadores autorizados
module.AuthorizedPlayers = {
	["xlm_brem"] = true,
	["AngeloGarciia"] = true,
	["VALLEIDS"] = true,
	["ignxts"] = true,
}

function module:IsAuthorized(player)
	return self.AuthorizedPlayers[player.Name] == true
end

return module
