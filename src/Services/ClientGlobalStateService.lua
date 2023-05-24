local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local Signal = require(Knit.Util.Signal)
local TableUtil = require(Knit.Util.TableUtil)

--[[
	This is a part of the global state management. It is responsible for
	the global non-persistent client-accessible state and uses "Client.Global" section of
	the "Config.InitState". This Knit Service has four automatically generated
	methods and one RemoteProperty for every key of the "Client.Global" config:
	
	- module.TheKey - RemoteProperty that holds the value and that is available and observebl
		on the client side. See the RemoteProperty documentation for more info.
	
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
	- "TheKey" is name of the key from the "Client.Global" section
	- the methods are available only on the server side, but RemoteProperties are available on
		the client side
	- value can NOT be changed from the client side
	
	Server Example:
	
		print(ClientGlobalStateService:GetSecondsUntilEvent())
		local secondsConnection = ClientGlobalStateService:ObserveSecondsUntilEvent(function(seconds)
			print(seconds)
		end)
		ClientGlobalStateService:SetSecondsUntilEvent(42)
		secondsConnection:Disconnect()
	
	Client Example:
		print(ClientGlobalStateService.SecondsUntilEvent:Get())
		local secondsConnection = ClientGlobalStateService.SecondsUntilEvent:Observe(function(seconds)
			print(seconds)
		end)
		secondsConnection:Disconnect()
]]

local function createService()
	local service = {
		Name = "ClientGlobalStateService",
		Client = {},
	}
	local onChangeSignals = {}

	for key, initialValue in pairs(Config.InitState.Server.Global) do
		service.Client[key] = Knit.CreateProperty(initialValue)
		onChangeSignals[key] = Signal.new()
		service["Get"..key] = function(self)
			return service.Client[key]:Get()
		end
		service["Set"..key] = function(self, v)
			onChangeSignals[key]:Fire(v)
			service.Client[key]:Set(v)
		end
		service[key.."Changed"] = function(self, callback)
			return onChangeSignals[key]:Connect(callback)
		end
		service["Observe"..key] = function(self, callback)
			callback(service.Client[key]:Get())
			return onChangeSignals[key]:Connect(callback)
		end
	end
	return Knit.CreateService(service)
end

local module = createService()

return module
