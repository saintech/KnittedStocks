local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local Signal = require(Knit.Util.Signal)
local TableUtil = require(Knit.Util.TableUtil)

local function createService()
	local service = {
		Name = "ServerGlobalStateService",
	}
	local state = TableUtil.Copy(Config.InitState.Server.Global, true)
	local onChangeSignals = {}

	for key in pairs(state) do
		onChangeSignals[key] = Signal.new()
		service["Get"..key] = function(self)
			return state[key]
		end
		service["Set"..key] = function(self, v)
			onChangeSignals[key]:Fire(v)
			state[key] = v
		end
		service[key.."Changed"] = function(self, callback)
			return onChangeSignals[key]:Connect(callback)
		end
		service["Observe"..key] = function(self, callback)
			callback(state[key])
			return onChangeSignals[key]:Connect(callback)
		end
	end
	return Knit.CreateService(service)
end

local module = createService()

return module
