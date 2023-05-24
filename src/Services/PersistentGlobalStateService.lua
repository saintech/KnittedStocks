local DataStoreService = game:GetService("DataStoreService")
local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local Signal = require(Knit.Util.Signal)

--[[
	This is a part of the global state management. This part is responsible for
	the global persistent server-only state and uses "Persistent.Global" section of
	the "Config.InitState". This Knit Service has four automatically generated methods
	for every key of the "Persistent.Global" config:
		
	- function module:GetTheKey() - returns the current value of TheKey.
	
	- function module:SetTheKey(value) - sets the given value for TheKey and then fires
		the corresponding Changed/Observe callbacks. Returns nothing.
	
	- function module:TheKeyChanged(callback) - will call the provided callback whenever the value
		of TheKey is updated. The callback starts being called ONLY from the next change.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	- function module:ObserveTheKey(callback) - will call the provided callback whenever the value
		of TheKey is updated. Also, the callback is called immediately after the method call.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	Important notes:
	- "TheKey" is name of the key from the "Persistent.Global" section
	- the methods are available only on the server side
	- DO NOT ABUSE this service, it uses DataStoreService without any improvements and has
		all its limitations
	- the service does not yet have cross-server synchronization, be careful!
	
	Example:
	
		print(PersistentGlobalStateService:GetMetaInfo())
		local metaInfoConnection = PersistentGlobalStateService:ObserveMetaInfo(function(metaInfo)
			print(metaInfo)
		end)
		PersistentGlobalStateService:SetMetaInfo({SomeInfo = 42})
		metaInfoConnection:Disconnect()
	
]]

local globalDataStore = DataStoreService:GetGlobalDataStore()

local function knitInit(self)
	for key, initialValue in pairs(Config.InitState.Persistent.Global) do
		local storedVal = globalDataStore:GetAsync(key)
		if storedVal == nil then
			globalDataStore:SetAsync(key, initialValue)
		end
	end
end

local function createService()
	local service = {
		Name = "PersistentStateService",
	}
	local onChangeSignals = {}

	service.KnitInit = knitInit
	for key in pairs(Config.InitState.Persistent.Global) do
		onChangeSignals[key] = Signal.new()
		service["Get"..key] = function(self)
			return globalDataStore:GetAsync(key)
		end
		service["Set"..key] = function(self, v)
			onChangeSignals[key]:Fire(v)
			task.defer(globalDataStore.SetAsync, globalDataStore, key, v)
		end
		service[key.."Changed"] = function(self, callback)
			return onChangeSignals[key]:Connect(callback)
		end
		service["Observe"..key] = function(self, player, callback)
			task.defer(callback, globalDataStore:GetAsync(key))
			return onChangeSignals[key]:Connect(callback)
		end
	end
	return Knit.CreateService(service)
end

local module = createService()

return module
