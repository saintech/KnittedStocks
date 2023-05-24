# KnittedStocks
Roblox global state management modules for projects that use Knit framework

## Download
https://github.com/saintech/KnittedStocks/releases/latest

## Dependencies
* [Knit](https://github.com/Sleitnick/Knit) framework
* [ProfileService](https://github.com/MadStudioRoblox/ProfileService/) for storing per-player persistent state

All dependencies should be setted using Config script, see example below.

## Using

### Initialization

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.ExternalReplicatedScripts.Knit.Knit)
local KnittedStocksConfig = require(ServerScriptService.ExternalServerScripts.KnittedStocks.Config)
local ServerConfig = require(ServerScriptService.ServerConfig)

-- configure KnittedStocks
KnittedStocksConfig.Knit = ReplicatedStorage.ExternalReplicatedScripts.Knit
KnittedStocksConfig.ProfileService = ServerScriptService.ExternalServerScripts.ProfileService
KnittedStocksConfig.InitState = ServerConfig.InitState

-- import KnittedStocks required services
require(ServerScriptService.ExternalServerScripts.KnittedStocks.Services.ClientGlobalStateService)
require(ServerScriptService.ExternalServerScripts.KnittedStocks.Services.ServerGlobalStateService)
require(ServerScriptService.ExternalServerScripts.KnittedStocks.Services.PersistentGlobalStateService)
require(ServerScriptService.ExternalServerScripts.KnittedStocks.Services.ClientPlayerStateService)

local function init()
	-- import KnittedStocks required components
	require(ServerScriptService.ExternalServerScripts.KnittedStocks.Components.ClientPlayerStateCmpt)
	require(ServerScriptService.ExternalServerScripts.KnittedStocks.Components.ServerPlayerStateCmpt)
	require(ServerScriptService.ExternalServerScripts.KnittedStocks.Components.PersistentPlayerStateCmpt)
	
	-- add required Player tag
	for i, player in ipairs(Players:GetPlayers()) do
		CollectionService:AddTag(player, "Player")
	end
	Players.PlayerAdded:Connect(function(player)
		CollectionService:AddTag(player, "Player")
	end)
end

Knit.Start():andThen(init):catch(warn)

```

### Using server modules

```lua
local ClientPlayerStateCmpt = require(ServerScriptService.ExternalServerScripts.KnittedStocks.Components.ClientPlayerStateCmpt)
local clientStateCmpt = ClientPlayerStateCmpt:FromInstance(player)
print(clientStateCmpt:GetMoney())
local moneyConnection = clientStateCmpt:ObserveMoney(function(money)
	print(money)
end)
clientStateCmpt:SetMoney(42)
moneyConnection:Disconnect()
```
