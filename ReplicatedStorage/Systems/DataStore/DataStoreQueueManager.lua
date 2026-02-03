--[[ 
	DataStoreQueueManager.lua - MINIMALISTA
	Solo GetAsync y SetAsync con reintentos
	Ubicación: ReplicatedStorage/Systems/DataStore/
	Usado en: GiftGamepass.lua, HD-CONNECT.lua
]]

local DataStoreQueueManager = {}
DataStoreQueueManager.__index = DataStoreQueueManager

local CONFIG = {
	DEFAULT_DELAY = 0.1,    -- 100ms entre requests
	MAX_RETRIES = 3,        -- Reintentos
	RETRY_DELAY = 2,        -- Espera entre reintentos
}

function DataStoreQueueManager.new(dataStore, queueName, customDelay)
	local self = setmetatable({}, DataStoreQueueManager)
	self.dataStore = dataStore
	self.delay = customDelay or CONFIG.DEFAULT_DELAY
	self.queue = {}
	self.isProcessing = false
	return self
end

function DataStoreQueueManager:processQueue()
	if self.isProcessing then return end
	self.isProcessing = true
	
	while #self.queue > 0 do
		local request = table.remove(self.queue, 1)
		local success = false
		local result = nil
		
		-- Reintentos automáticos
		for attempt = 1, CONFIG.MAX_RETRIES do
			success, result = pcall(function()
				if request.operation == "get" then
					return self.dataStore:GetAsync(request.key)
				elseif request.operation == "set" then
					self.dataStore:SetAsync(request.key, request.value)
					return true
				end
			end)
			
			if success then break end
			if attempt < CONFIG.MAX_RETRIES then
				task.wait(CONFIG.RETRY_DELAY)
			end
		end
		
		-- Ejecutar callback
		if request.callback then
			task.spawn(function() request.callback(success, result) end)
		end
		
		-- Control de rate limit
		if #self.queue > 0 then
			task.wait(self.delay)
		end
	end
	
	self.isProcessing = false
end

-- ÚNICA FUNCIÓN PÚBLICA: GetAsync
function DataStoreQueueManager:GetAsync(key, callback)
	table.insert(self.queue, {
		operation = "get",
		key = key,
		callback = callback
	})
	if not self.isProcessing then
		task.spawn(function() self:processQueue() end)
	end
end

-- ÚNICA FUNCIÓN PÚBLICA: SetAsync
function DataStoreQueueManager:SetAsync(key, value, callback)
	table.insert(self.queue, {
		operation = "set",
		key = key,
		value = value,
		callback = callback
	})
	if not self.isProcessing then
		task.spawn(function() self:processQueue() end)
	end
end

return DataStoreQueueManager
