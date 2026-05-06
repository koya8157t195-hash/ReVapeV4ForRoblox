local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local lplr = playersService.LocalPlayer

local function loadLocalFile(path)
	local suc, res = pcall(function()
		return readfile(path)
	end)
	return suc and res or nil
end


local bd = {
	Http = {
		Get = function(self, url)
			return game:HttpGet(url, true)
		end
	},
	ToolService = {
		ToggleBlockSword = function(self, tog, tool)
			return replicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(tog, tool)
		end,
		AttackPlayerWithSword = function(self, target, isCrit, toolName)
			return replicatedStorage.Modules.Knit.Services.ToolService.RF.AttackPlayerWithSword:InvokeServer(target, isCrit, toolName, "\226\128\139")
		end
	},
	Entity = {
		GetEntities = function(self)
			local suc, res = pcall(function()
				return replicatedStorage.Modules.Knit.Services.EntityService.RF.GetEntities:InvokeServer()
			end)
			return (suc and res) or {}
		end,
		FindByCharacter = function(self, char)
			for _, v in self:GetEntities() do
				if v.Character == char then
					return v
				end
			end

			return nil
		end
	},
	MatchController = {
		EnterQueue = function(self, mode)
			return replicatedStorage.Modules.Knit.Services.MatchmakingService.RF.EnterQueue:InvokeServer(mode)
		end,
		LeaveQueue = function(self)
			return replicatedStorage.Modules.Knit.Services.MatchmakingService.RF.LeaveQueue:InvokeServer()
		end
	},
	Blink = loadstring(loadLocalFile('newvape/libraries/blink.lua'))(),
	ServerData = {},
	CombatConstants = {},
	ViewmodelController = nil
}

task.spawn(function()
	local suc, res = pcall(function()
		return replicatedStorage.Modules.Knit.Services.MatchmakingService.RF.GetQueueData:InvokeServer()
	end)
	if suc then
		bd.ServerData = res
	end
end)

task.spawn(function()
	local suc, res = pcall(function()
		return replicatedStorage.Modules.Knit.Services.ToolService.RF.GetCombatConstants:InvokeServer()
	end)
	if suc then
		bd.CombatConstants = res
	end
end)

return bd
