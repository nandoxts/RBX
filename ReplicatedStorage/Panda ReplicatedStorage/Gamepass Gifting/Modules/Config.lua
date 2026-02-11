local Configuration = require(game.ReplicatedStorage["Panda ReplicatedStorage"].Configuration)

local gamepasses = {
	{Configuration.VIP, Configuration.DEV_VIP},
	{Configuration.COMMANDS, Configuration.DEV_COMMANDS},
	{Configuration.TOMBO, Configuration.DEV_TOMBO},
	{Configuration.CHORO, Configuration.DEV_CHORO},
	{Configuration.SERE, Configuration.DEV_SERE},
	{Configuration.COLORS, Configuration.DEV_COLORS}
}

local tools = {
	
}

return {
	Gamepasses = gamepasses,
	Tools = tools
}
