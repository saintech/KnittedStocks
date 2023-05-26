local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local ClientPlayerStateService = Knit.GetService("ClientPlayerStateService")
local Component = require(Config.Knit.Component)
local Signal = require(Config.Knit.Signal)
local TableUtil = require(Config.Knit.TableUtil)

--[[
	This is a part of the global state management. This part is responsible for the player state
	and uses "Client.Player" section of the "Config.InitState". Every Player has
	this Component with four automatically generated methods for every key of
	the "Client.Player" config:
	
	- function module:GetTheKey() - returns the current value of TheKey of the bound Player.
	
	- function module:SetTheKey(value) - sets the given value for TheKey of the bound Player and
		then fires the corresponding Changed/Observe callbacks plus corresponding OnChange Signal
		of the ClientPlayerStateService. Returns nothing.
	
	- function module:TheKeyChanged(callback) - will call the provided callback whenever the value
		of TheKey is updated. The callback starts being called ONLY from the next change.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	- function module:ObserveTheKey(callback) - will call the provided callback whenever the value
		of TheKey is updated. Also, the callback is called immediately after the method call.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	Important notes:
	- "TheKey" is name of the key from the "Client.Player" section
	- the methods are available only on the server side, because this is server Component, for
		the client side use the ClientPlayerStateService
	- any value can be changed from the client side using the ClientPlayerStateService
	
	Example:
	
		local clientStateCmpt = ClientPlayerStateCmpt:FromInstance(player)
		print(clientStateCmpt:GetMoney())
		local moneyConnection = clientStateCmpt:ObserveMoney(function(money)
			print(money)
		end)
		clientStateCmpt:SetMoney(42)
		moneyConnection:Disconnect()
	
]]

local module = Component.new({
	Tag = "Player",
	Ancestors = {Players},
	Extensions = Config.CmptExtensions.ClientPlayerState,
})

function module:Construct()
	local player = self.Instance
	assert(player.ClassName == "Player", "ClientPlayerStateComponent must be attached to Player Instance only")
	for key in pairs(Config.InitState.Client.Player) do
		self["Get"..key] = function(self)
			local player = self.Instance
			return ClientPlayerStateService.Client[key]:GetFor(player)
		end
		self["Set"..key] = function(self, v)
			local player = self.Instance
			ClientPlayerStateService.OnChangeSignals[key]:Fire(player, v)
			ClientPlayerStateService.Client[key]:SetFor(player, v)
		end
		self[key.."Changed"] = function(self, callback)
			local player = self.Instance
			return ClientPlayerStateService.OnChangeSignals[key]:Connect(function(firedPlayer, v)
				if firedPlayer == player then
					callback(v)
				end
			end)
		end
		self["Observe"..key] = function(self, callback)
			callback(ClientPlayerStateService.Client[key]:GetFor(player))
			local player = self.Instance
			return ClientPlayerStateService.OnChangeSignals[key]:Connect(function(firedPlayer, v)
				if firedPlayer == player then
					callback(v)
				end
			end)
		end
	end
end

return module
