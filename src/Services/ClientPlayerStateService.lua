local Config = require(script.Parent.Parent.Config)
local Knit = require(Config.Knit.Knit)
local Signal = require(Knit.Util.Signal)

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
