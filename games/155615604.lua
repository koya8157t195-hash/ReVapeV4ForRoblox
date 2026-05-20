local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert') end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function() return game:HttpGet('https://raw.githubusercontent.com/Koya50/ReVapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true) end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local tweenService = cloneref(game:GetService('TweenService'))
local teamsService = cloneref(game:GetService('Teams'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextService = cloneref(game:GetService('ContextActionService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local vm = loadstring(downloadFile('newvape/libraries/vm.lua'), 'vm')()

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
    local GunModifications
    local charConnection
    local backpackConnection

    local function mod(v)
        if v:IsA('Tool') and v:GetAttribute('FireRate') then
            v:SetAttribute('FireRate', 0.03)
            v:SetAttribute('AutoFire', true)
            v:SetAttribute('SpreadRadius', 0)
        end
    end

    local function modAll()
        -- Mod tools in backpack
        local backpack = playersService.LocalPlayer:FindFirstChild('Backpack')
        if backpack then
            for _, v in pairs(backpack:GetChildren()) do
                mod(v)
            end
        end

        -- Mod tools in character
        local char = playersService.LocalPlayer.Character
        if char then
            for _, v in pairs(char:GetChildren()) do
                mod(v)
            end
        end
    end

    GunModifications = vape.Categories.Combat:CreateModule({
        Name = 'GunModifications',
        Function = function(callback)
            if callback then
                modAll()

                charConnection = playersService.LocalPlayer.CharacterAdded:Connect(function(char)
                    for _, v in pairs(char:GetChildren()) do
                        mod(v)
                    end
                    charConnection = char.ChildAdded:Connect(mod)
                end)

                backpackConnection = playersService.LocalPlayer.Backpack.ChildAdded:Connect(mod)
            else
                if charConnection then
                    charConnection:Disconnect()
                    charConnection = nil
                end
                if backpackConnection then
                    backpackConnection:Disconnect()
                    backpackConnection = nil
                end
            end
        end,
        Tooltip = 'Modifications to empower the firearm'
    })
end)

run(function()
    local DeleteAntiJump
    local charConnection

    local function removeAntiJump()
        local model = workspace:FindFirstChild(tostring(lplr))

        if model then
            if model:IsA('Model') then
                local antiJumpScript = model:FindFirstChild('AntiJump', true)
                if antiJumpScript and antiJumpScript:IsA('LocalScript') then
                    antiJumpScript:Destroy()
                end
            end
        end
    end

    DeleteAntiJump = vape.Categories.World:CreateModule({
        Name = 'Delete AntiJump',
        Function = function(callback)
            if callback then
                removeAntiJump()

                charConnection = playersService.LocalPlayer.CharacterAdded:Connect(function()
                    task.wait()
                    removeAntiJump()
                end)
            else
                if charConnection then
                    charConnection:Disconnect()
                    charConnection = nil
                end
            end
        end,
        Tooltip = 'Deletes the AntiJump LocalScript from your character model on spawn and respawn'
    })
end)

run(function()
    local PlaceTeleportation
    local TPLocation
    local lastTP = 0

    local function notif(...)
        return vape:CreateNotification(...)
    end

    local function CanTeleport()
        local char = playersService.LocalPlayer.Character
        return char and char:FindFirstChild('HumanoidRootPart')
    end

    PlaceTeleportation = vape.Categories.World:CreateModule({
        Name = 'Place Teleportation',
        Function = function(callback)
            if callback then
                if tick() - lastTP < 1.6 then
                    notif('Teleport', 'On cooldown! Wait ' .. string.format('%.1f', 1.6 - (tick() - lastTP)) .. 's', 2)
                    PlaceTeleportation:Toggle()
                    return
                end

                local location = TPLocation.Value

                if location == 'Criminal Base' then
                    local spawn = workspace:FindFirstChild('Criminals Spawn')
                    if spawn and spawn:FindFirstChild('SpawnLocation') then
                        if CanTeleport() then
                            playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.SpawnLocation.CFrame
                            lastTP = tick()
                        end
                    end
                elseif location == 'Prison' then
                    if CanTeleport() then
                        playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(916, 100, 2369)
                        lastTP = tick()
                    end
                elseif location == 'Guard Room' then
                    if CanTeleport() then
                        playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(828, 100, 2303)
                        lastTP = tick()
                    end
                end

                PlaceTeleportation:Toggle()
            end
        end,
        Tooltip = 'Teleport to key Jailbreak locations'
    })

    TPLocation = PlaceTeleportation:CreateDropdown({
        Name = 'Location',
        List = {'Criminal Base', 'Prison', 'Guard Room'},
        Default = 'Criminal Base',
        Tooltip = 'Choose where to teleport'
    })
end)

run(function()
    local GunGrabber
    local savedCFrame

    local function CanTeleport()
        local char = playersService.LocalPlayer.Character
        return char and char:FindFirstChild('HumanoidRootPart')
    end

    GunGrabber = vape.Categories.World:CreateModule({
        Name = 'Gun Grabber',
        Function = function(callback)
            if callback then
                if not CanTeleport() then
                    GunGrabber:Toggle()
                    return
                end
                savedCFrame = playersService.LocalPlayer.Character.HumanoidRootPart.CFrame
                local remington = workspace:WaitForChild('Prison_ITEMS'):WaitForChild('giver'):WaitForChild('Remington 870'):WaitForChild('Meshes/r870_2')
                playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = remington.CFrame
                task.wait(0.5)
                game:GetService('ReplicatedStorage'):WaitForChild('Remotes'):WaitForChild('InteractWithItem'):InvokeServer(remington)
                task.wait(0.3)
                local mp5 = workspace:WaitForChild('Prison_ITEMS'):WaitForChild('giver'):WaitForChild('MP5'):WaitForChild('Meshes/MP5 (2)')
                playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = mp5.CFrame
                task.wait(0.5)
                game:GetService('ReplicatedStorage'):WaitForChild('Remotes'):WaitForChild('InteractWithItem'):InvokeServer(mp5)
                task.wait(0.3)
                playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = savedCFrame
                GunGrabber:Toggle()
            end
        end,
        Tooltip = 'Grabs Remington 870 and MP5 then returns you back'
    })
end)
