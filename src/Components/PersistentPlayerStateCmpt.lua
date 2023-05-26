local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config)
local Component = require(Config.Knit.Component)
local Signal = require(Config.Knit.Signal)
local ProfileService = require(Config.ProfileService)

--[[
	This is a part of the global state management. This part is responsible for
	the persistent per-player state and uses "Persistent.Player" section of
	the "Config.InitState". Every Player has this Component with four automatically
	generated methods for every key of the "Persistent.Player" config:
	
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
	- "TheKey" is name of the key from the "Persistent.Player" section
	
	Example:
	
		local persistentStateCmpt = PersistentPlayerStateCmpt:FromInstance(player)
		print(persistentStateCmpt:GetMoney())
		local moneyConnection = persistentStateCmpt:ObserveMoney(function(money)
			print(money)
		end)
		persistentStateCmpt:SetMoney(42)
		moneyConnection:Disconnect()
	
]]

local profileStore = ProfileService.GetProfileStore("PlayerData", Config.InitState.Persistent.Player)

local module = Component.new({
	Tag = "Player",
	Ancestors = {Players},
	Extensions = Config.CmptExtensions.PersistentPlayerState,
})

local function loadProfileAsync(self, player)
	local profile = profileStore:LoadProfileAsync(tostring(player.UserId))
	if profile ~= nil then
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			self._profile = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			self._profile = profile
			self._isReady:Fire()
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick() 
	end
end

function module:Construct()
	self._profile = nil
	self._isReady = Signal.new()
	self._onChangeSignals = {}

	local player = self.Instance
	assert(player.ClassName == "Player", "PersistentPlayerStateComponent must be attached to Player Instance only")
	task.defer(loadProfileAsync, self, player)
	for key in pairs(Config.InitState.Persistent.Player) do
		self._onChangeSignals[key] = Signal.new()
		self["Get"..key] = function(self)
			if not self._profile then
				self._isReady:Wait()
			end
			return self._profile.Data[key]
		end
		self["Set"..key] = function(self, v)
			if not self._profile then
				return
			end
			self._onChangeSignals[key]:Fire(v)
			self._profile.Data[key] = v
		end
		self[key.."Changed"] = function(self, callback)
			return self._onChangeSignals[key]:Connect(callback)
		end
		self["Observe"..key] = function(self, callback)
			if self._profile then
				callback(self._profile.Data[key])
			else
				self._isReady:ConnectOnce(function()
					callback(self._profile.Data[key])
				end)
			end
			return self._onChangeSignals[key]:Connect(callback)
		end
	end
end

function module:WipeAndKick()
	local player = self.Instance
	local key = tostring(player.UserId)
	self._profile:Release()
	local isOk = profileStore:WipeProfileAsync(key)
	assert(isOk, "WipeAndKick: some problem with wiping data")
end

function module:Stop()
	if self._profile then
		self._profile:Release()
	end
end

return module
