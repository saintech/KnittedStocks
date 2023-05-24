local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local Signal = require(Knit.Util.Signal)

--[[
	This is a part of the global state management. It is responsible fore
	the per-player non-persistent client-accessible state and uses "Client.Player" section of
	the "Config.InitState". This Knit Service has one automatically generated client method
	for setting a value and one RemoteProperty for every key of the "Client.Player" config:
	
	- module.TheKey - RemoteProperty that holds the value for each Player and that is available
		and observebl on the client side. See the RemoteProperty documentation for more info.
	
	- function module:SetTheKey(value) - client method that sets the given value for TheKey for
		the calling Player and then fires the corresponding OnChange Signal. Returns nothing.
	
	Important notes:
	- "TheKey" is name of the key from the "Client.Player" section
	- this service is needed only for client communication and should only be used on
		the client side, for the server side use the ClientPlayerStateCmpt
	
	Client Example:

		print(ClientPlayerStateService.Money:Get())
		local moneyConnection = ClientPlayerStateService.Money:Observe(function(money)
			print(money)
		end)
		ClientPlayerStateService:SetMoney(42)
		moneyConnection:Disconnect()
	
]]

local function createService()
	local service = {
		Name = "ClientPlayerStateService",
		Client = {},
		OnChangeSignals = {}
	}
	for key, initialValue in pairs(Config.InitState.Client.Player) do
		service.Client[key] = Knit.CreateProperty(initialValue)
		service.OnChangeSignals[key] = Signal.new()
		service.Client["Set"..key] = function(self, player, v)
			self[key]:SetFor(player, v)
			self.Server.OnChangeSignals[key]:Fire(player, v)
		end
	end
	return Knit.CreateService(service)
end

local module = createService()

return module
