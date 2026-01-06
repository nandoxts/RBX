-- ════════════════════════════════════════════════════════════════
-- DANCE PANEL MODULE v1.0
-- Configuración y funciones para panel de bailes
-- Autor: nandoxts
-- Fecha: 2025-12-21
-- ════════════════════════════════════════════════════════════════

local DanceModule = {}

-- ════════════════════════════════════════════════════════════════
-- DANCE CATALOG
-- ════════════════════════════════════════════════════════════════

DanceModule.Dances = {
	{
		id = "dance_groove",
		name = "The Groove",
		animationId = 507776879,
		price = 100,
		rarity = "common",
		description = "Un baile clásico y divertido",
		category = "Classic"
	},
	{
		id = "dance_floss",
		name = "Floss",
		animationId = 507776973,
		price = 150,
		rarity = "common",
		description = "El icónico floss dance",
		category = "Viral"
	},
	{
		id = "dance_wave",
		name = "Wave",
		animationId = 507785853,
		price = 120,
		rarity = "common",
		description = "Haz una ola con tus brazos",
		category = "Classic"
	},
	{
		id = "dance_moonwalk",
		name = "Moonwalk",
		animationId = 507786091,
		price = 200,
		rarity = "rare",
		description = "Camina hacia atrás como en la luna",
		category = "Pro"
	},
	{
		id = "dance_jump",
		name = "Jump Jump",
		animationId = 507789710,
		price = 80,
		rarity = "common",
		description = "Salta con entusiasmo",
		category = "Classic"
	},
	{
		id = "dance_tilt",
		name = "Tilt",
		animationId = 507790049,
		price = 110,
		rarity = "common",
		description = "Inclínate al ritmo",
		category = "Classic"
	},
	{
		id = "dance_shuffle",
		name = "Shuffle",
		animationId = 507790173,
		price = 180,
		rarity = "rare",
		description = "Un baile de pies rápido",
		category = "Pro"
	},
	{
		id = "dance_robot",
		name = "Robot",
		animationId = 507790506,
		price = 160,
		rarity = "rare",
		description = "Muévete como un robot",
		category = "Themed"
	}
}

-- ════════════════════════════════════════════════════════════════
-- RARITY COLORS
-- ════════════════════════════════════════════════════════════════

DanceModule.RarityColors = {
	common = Color3.fromRGB(200, 200, 200),
	rare = Color3.fromRGB(100, 150, 255),
	epic = Color3.fromRGB(200, 100, 255),
	legendary = Color3.fromRGB(255, 200, 0)
}

-- ════════════════════════════════════════════════════════════════
-- CATEGORY ICONS
-- ════════════════════════════════════════════════════════════════

DanceModule.CategoryIcons = {
	Classic = "🎭",
	Viral = "📱",
	Pro = "⭐",
	Themed = "🎪"
}

-- ════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════

function DanceModule:getDanceById(danceId)
	for _, dance in ipairs(self.Dances) do
		if dance.id == danceId then
			return dance
		end
	end
	return nil
end

function DanceModule:getDancesByCategory(category)
	local results = {}
	for _, dance in ipairs(self.Dances) do
		if dance.category == category then
			table.insert(results, dance)
		end
	end
	return results
end

function DanceModule:getDancesByRarity(rarity)
	local results = {}
	for _, dance in ipairs(self.Dances) do
		if dance.rarity == rarity then
			table.insert(results, dance)
		end
	end
	return results
end

function DanceModule:getCategories()
	local categories = {}
	local seen = {}

	for _, dance in ipairs(self.Dances) do
		if not seen[dance.category] then
			table.insert(categories, dance.category)
			seen[dance.category] = true
		end
	end

	return categories
end

function DanceModule:searchDances(term)
	local lowerTerm = term:lower()
	local results = {}

	for _, dance in ipairs(self.Dances) do
		local name = dance.name:lower()
		local description = dance.description:lower()

		if name:find(lowerTerm, 1, true) or description:find(lowerTerm, 1, true) then
			table.insert(results, dance)
		end
	end

	return results
end

function DanceModule:getDancesByPrice(minPrice, maxPrice)
	local results = {}

	for _, dance in ipairs(self.Dances) do
		if dance.price >= minPrice and dance.price <= maxPrice then
			table.insert(results, dance)
		end
	end

	return results
end

-- ════════════════════════════════════════════════════════════════
-- LOGGING FUNCTION
-- ════════════════════════════════════════════════════════════════

function DanceModule:logDanceAction(action, danceName, userId)
	print("[DANCE_ACTION] Action: " .. action .. " | Dance: " .. danceName .. " | UserId: " .. userId .. " | Timestamp: " .. os.date("%H:%M:%S"))
end

return DanceModule
