local module = {
	Knit = "REQUIRED!",
	ProfileService = "REQUIRED!",
	CmptExtensions = {
		ClientPlayerState = nil,
		PersistentPlayerState = nil,
		ServerPlayerState = nil,
	},
	InitState = {
		Client = {
			Player = { -- self:GetComponent(ClientPlayerStateCmpt)
				ExampleState = 0,
			},
			Global = { -- Knit.GetService("ClientGlobalStateService")
			},
		},
		Server = {
			Player = { -- self:GetComponent(ServerPlayerStateCmpt)
			},
			Global = { -- Knit.GetService("ServerGlobalStateService")
			},
		},
		Persistent = {
			Player = { -- self:GetComponent(PersistentPlayerStateCmpt)
				ExampleState = 0,
			},
			Global = { -- Knit.GetService("PersistentGlobalStateService")
			},
		},
	},
}

return module
