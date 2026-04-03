local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local collectionService = cloneref(game:GetService('CollectionService'))
local runService = cloneref(game:GetService('RunService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local prediction = vape.Libraries.prediction

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
    local infstam
    local connection
    local stamscript = require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)
    infstam = vape.Categories.Blatant:CreateModule({
        Name = "Infinte stamina",
        Function = function(callback)
            if callback then
              connection = game:GetService("RunService").Heartbeat:Connect(function()
                  connection:Disconnect()
                  stamscript.StaminaLossDisabled = function()
                        return 0
					end
                end)
			else
				if connection then
                connection:Disconnect()
                connection = nil
                end		

							
                stamscript.StaminaLossDisabled = nil
				end
            end
        end
    })
end)
