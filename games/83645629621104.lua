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

for _, v in {'AutoClicker', 'Reach', 'MurderMystery', 'AutoRejoin', 'Killaura', 'Swim', 'TargetStrafe', 'LongJump', 'MouseTP', 'Invisible'} do
	vape:Remove(v)
end

run(function()
    local infstam
    local stamscript = require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)

    infstam = vape.Categories.Blatant:CreateModule({
        Name = "Infinite Stamina",
        Function = function(callback)
            if callback then
                -- enable
                stamscript.StaminaLossDisabled = function()
                    return 0
                end
            else
                -- disable
                stamscript.StaminaLossDisabled = nil
            end
        end
    })
end)

run(function()
    local AutoGen
    local Delay
    local Thread

    local function runAutoGen()
        if Thread then
            task.cancel(Thread)
        end

        Thread = task.spawn(function()
            repeat
                for _, obj in pairs(workspace.Map.Ingame.Map:GetChildren()) do
                    if obj.Name == "Generator" then
                        local remotes = obj:FindFirstChild("Remotes")
                        if remotes then
                            local re = remotes:FindFirstChild("RE")
                            if re then
                                re:FireServer()
                            end
                        end
                    end
                end

                task.wait(Delay.Value)
            until not AutoGen.Enabled
        end)
    end

    AutoGen = vape.Categories.Minigames:CreateModule({
        Name = "Auto Generator Fix",
        Function = function(callback)
            if callback then
                runAutoGen()
            else
                if Thread then
                    task.cancel(Thread)
                    Thread = nil
                end
            end
        end,
        Tooltip = "Automatically fires generator remotes"
    })

    Delay = AutoGen:CreateSlider({
        Name = "Delay",
        Min = 0.5,
        Max = 5,
        Default = 2.5,
        Suffix = "s"
    })
end)
