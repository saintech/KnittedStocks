local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config)
local Component = require(Config.Knit.Component)
local Signal = require(Config.Knit.Signal)
local TableUtil = require(Config.Knit.TableUtil)

--[[
	This is a part of the global state management. This part is responsible for
	the non-persistent per-player state and uses "Server.Player" section of
	the "Config.InitState". Every Player has this Component with four automatically
	generated methods for every key of the "Server.Player" config:
	
	- function module:GetTheKey() - returns the current value of TheKey of the bound Player.
	
	- function module:SetTheKey(value) - sets the given value for TheKey of the bound Player and
		then fires the corresponding Changed/Observe callbacks. Returns nothing.
	
	- function module:TheKeyChanged(callback) - will call the provided callback whenever the value
		of TheKey is updated. The callback starts being called ONLY from the next change.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	- function module:ObserveTheKey(callback) - will call the provided callback whenever the value
		of TheKey is updated. Also, the callback is called immediately after the method call.
		The callback is called with one param - the value after the change.
		Returns Signal connection.
	
	Important notes:
	- "TheKey" is name of the key from the "Server.Player" section
	
	Example:
	
		local serverStateCmpt = ServerPlayerStateCmpt:FromInstance(player)
		print(serverStateCmpt:GetMoney())
		local moneyConnection = serverStateCmpt:ObserveMoney(function(money)
			print(money)
		end)
		serverStateCmpt:SetMoney(42)
		moneyConnection:Disconnect()
	
]]

local module = Component.new({
	Tag = "Player",
	Ancestors = {Players},
})

function module:Construct()
	self._state = TableUtil.Copy(Config.InitState.Server.Player, true)
	self._onChangeSignals = {}

	local player = self.Instance
	assert(player.ClassName == "Player", "ServerPlayerStateComponent must be attached to Player Instance only")
	for key in pairs(self._state) do
		self._onChangeSignals[key] = Signal.new()
		self["Get"..key] = function(self)
			return self._state[key]
		end
		self["Set"..key] = function(self, v)
			self._onChangeSignals[key]:Fire(v)
			self._state[key] = v
		end
		self[key.."Changed"] = function(self, callback)
			return self._onChangeSignals[key]:Connect(callback)
		end
		self["Observe"..key] = function(self, callback)
			callback(self._state[key])
			return self._onChangeSignals[key]:Connect(callback)
		end
	end
end

return module
