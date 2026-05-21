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

for _, v in {'AutoClicker', 'Reach', 'MurderMystery', 'AutoRejoin', 'Killaura', 'SilentAim', 'MouseTP'} do
	vape:Remove(v)
end

run(function()
    local SilentAim
    local Target
    local Mode
    local Range
    local HitChance
    local HeadshotChance
    local AutoFire
    local AutoFireShootDelay
    local AutoFireMode
    local AutoFirePosition
    local Wallbang
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleObject
    local RaycastWhitelist = RaycastParams.new()
    RaycastWhitelist.FilterType = Enum.RaycastFilterType.Include
    local fireoffset, rand, delayCheck = CFrame.identity, Random.new(), tick()
    local oldnamecall
    local mouseClicked

    local function getTarget(origin, obj)
        if rand.NextNumber(rand, 0, 100) > (AutoFire.Enabled and 100 or HitChance.Value) then return end
        local targetPart = (rand.NextNumber(rand, 0, 100) < (AutoFire.Enabled and 100 or HeadshotChance.Value)) and 'Head' or 'RootPart'
        local ent = entitylib['Entity'..Mode.Value]({
            Range = Range.Value,
            Wallcheck = Target.Walls.Enabled and (obj or true) or nil,
            Part = targetPart,
            Origin = origin,
            Players = Target.Players.Enabled,
            NPCs = Target.NPCs.Enabled
        })

        if ent then
            targetinfo.Targets[ent] = tick() + 1
        end

        return ent, ent and ent[targetPart], origin
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if CircleObject then
                CircleObject.Visible = callback and Mode.Value == 'Mouse'
            end
            if callback then
                oldnamecall = hookmetamethod(game, '__namecall', function(...)
                    if getnamecallmethod() ~= 'Raycast' then
                        return oldnamecall(...)
                    end
                    if checkcaller() then
                        return oldnamecall(...)
                    end

                    local self, args = ..., {select(2, ...)}
                    local ent, targetPart, origin = getTarget(args[1])
                    if not ent then return oldnamecall(self, unpack(args)) end

                    args[2] = CFrame.lookAt(origin, targetPart.Position).LookVector * args[2].Magnitude
                    if Wallbang.Enabled then
                        RaycastWhitelist.FilterDescendantsInstances = {targetPart}
                        args[3] = RaycastWhitelist
                    end

                    return oldnamecall(self, unpack(args))
                end)

                repeat
                    if CircleObject then
                        CircleObject.Position = inputService:GetMouseLocation()
                    end

                    if AutoFire.Enabled then
                        local origin = AutoFireMode.Value == 'Camera' and gameCamera.CFrame or entitylib.isAlive and entitylib.character.RootPart.CFrame or CFrame.identity
                        local ent = entitylib['Entity'..Mode.Value]({
                            Range = Range.Value,
                            Wallcheck = Target.Walls.Enabled or nil,
                            Part = 'Head',
                            Origin = (origin * fireoffset).Position,
                            Players = Target.Players.Enabled,
                            NPCs = Target.NPCs.Enabled
                        })

                        if mouse1click and (isrbxactive or iswindowactive)() then
                            if ent and canClick() then
                                if delayCheck < tick() then
                                    if mouseClicked then
                                        mouse1release()
                                        delayCheck = tick() + AutoFireShootDelay.Value
                                    else
                                        mouse1press()
                                    end
                                    mouseClicked = not mouseClicked
                                end
                            else
                                if mouseClicked then
                                    mouse1release()
                                end
                                mouseClicked = false
                            end
                        end
                    end

                    task.wait()
                until not SilentAim.Enabled
            else
                if oldnamecall then
                    hookmetamethod(game, '__namecall', oldnamecall)
                end
                oldnamecall = nil
            end
        end,
        Tooltip = 'Silently adjusts your aim towards the enemy using Raycast'
    })
    Target = SilentAim:CreateTargets({Players = true})
    Mode = SilentAim:CreateDropdown({
        Name = 'Mode',
        List = {'Mouse', 'Position'},
        Function = function(val)
            if CircleObject then
                CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
            end
        end,
        Tooltip = 'Mouse - Checks for entities near the mouses position\nPosition - Checks for entities near the local character'
    })
    Range = SilentAim:CreateSlider({
        Name = 'Range',
        Min = 1,
        Max = 1000,
        Default = 150,
        Function = function(val)
            if CircleObject then
                CircleObject.Radius = val
            end
        end,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
    HitChance = SilentAim:CreateSlider({
        Name = 'Hit Chance',
        Min = 0,
        Max = 100,
        Default = 85,
        Suffix = '%'
    })
    HeadshotChance = SilentAim:CreateSlider({
        Name = 'Headshot Chance',
        Min = 0,
        Max = 100,
        Default = 65,
        Suffix = '%'
    })
    AutoFire = SilentAim:CreateToggle({
        Name = 'AutoFire',
        Function = function(callback)
            AutoFireShootDelay.Object.Visible = callback
            AutoFireMode.Object.Visible = callback
            AutoFirePosition.Object.Visible = callback
        end
    })
    AutoFireShootDelay = SilentAim:CreateSlider({
        Name = 'Next Shot Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Visible = false,
        Darker = true,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })
    AutoFireMode = SilentAim:CreateDropdown({
        Name = 'Origin',
        List = {'RootPart', 'Camera'},
        Visible = false,
        Darker = true,
        Tooltip = 'Determines the position to check for before shooting'
    })
    AutoFirePosition = SilentAim:CreateTextBox({
        Name = 'Offset',
        Function = function()
            local suc, res = pcall(function()
                return CFrame.new(unpack(AutoFirePosition.Value:split(',')))
            end)
            if suc then fireoffset = res end
        end,
        Default = '0, 0, 0',
        Visible = false,
        Darker = true
    })
    Wallbang = SilentAim:CreateToggle({Name = 'Wallbang'})
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = Range.Value
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - CircleTransparency.Value
                CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
            else
                pcall(function()
                    CircleObject.Visible = false
                    CircleObject:Remove()
                end)
            end
            CircleColor.Object.Visible = callback
            CircleTransparency.Object.Visible = callback
            CircleFilled.Object.Visible = callback
        end
    })
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color',
        Function = function(hue, sat, val)
            if CircleObject then
                CircleObject.Color = Color3.fromHSV(hue, sat, val)
            end
        end,
        Darker = true,
        Visible = false
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Decimal = 10,
        Default = 0.5,
        Function = function(val)
            if CircleObject then
                CircleObject.Transparency = 1 - val
            end
        end,
        Darker = true,
        Visible = false
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled',
        Function = function(callback)
            if CircleObject then
                CircleObject.Filled = callback
            end
        end,
        Darker = true,
        Visible = false
    })
end)

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

        if model and model:IsA('Model') then
            local antiJumpScript = model:FindFirstChild('AntiJump', true)
            if antiJumpScript and antiJumpScript:IsA('LocalScript') then
                antiJumpScript:Destroy()
            end
        end

        -- Also check StarterCharacterScripts
        local char = playersService.LocalPlayer.Character
        if char then
            local antiJumpScript = char:FindFirstChild('AntiJump', true)
            if antiJumpScript and antiJumpScript:IsA('LocalScript') then
                antiJumpScript:Destroy()
            end
        end
    end

    DeleteAntiJump = vape.Categories.World:CreateModule({
        Name = 'Antijump disabler :3',
        Function = function(callback)
            if callback then
                removeAntiJump()

                charConnection = playersService.LocalPlayer.CharacterAdded:Connect(function(char)
                    char.ChildAdded:Connect(function(child)
                        if child.Name == 'AntiJump' and child:IsA('LocalScript') then
                            child:Destroy()
                        end
                    end)
                    task.wait(0.5)
                    removeAntiJump()
                end)
            else
                if charConnection then
                    charConnection:Disconnect()
                    charConnection = nil
                end
            end
        end,
        Tooltip = 'Deletes the AntiJump LocalScript from your character model and character on spawn/respawn'
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
                task.wait(0.1)
                game:GetService('ReplicatedStorage'):WaitForChild('Remotes'):WaitForChild('InteractWithItem'):InvokeServer(remington)
                task.wait(0.1)
                local mp5 = workspace:WaitForChild('Prison_ITEMS'):WaitForChild('giver'):WaitForChild('MP5'):WaitForChild('Meshes/MP5 (2)')
                playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = mp5.CFrame
                task.wait(0.1)
                game:GetService('ReplicatedStorage'):WaitForChild('Remotes'):WaitForChild('InteractWithItem'):InvokeServer(mp5)
                task.wait(0.1)
                playersService.LocalPlayer.Character.HumanoidRootPart.CFrame = savedCFrame
                GunGrabber:Toggle()
            end
        end,
        Tooltip = 'Grabs Remington 870 and MP5 then returns you back'
    })
end)

run(function()
    local AntiTase
    local taseConnection

    local function checkTased()
        local char = playersService.LocalPlayer.Character
        if not char then return end

        local model = workspace:FindFirstChild(tostring(lplr))
        if model and model:IsA('Model') then
            if model:GetAttribute('Tased') then
                local root = char:FindFirstChild('HumanoidRootPart')
                if root then
                    local pos = root.Position
                    root.CFrame = CFrame.new(pos.X, pos.Y - 100, pos.Z)
                end
            end
        end
    end

    AntiTase = vape.Categories.World:CreateModule({
        Name = 'Anti Tase',
        Function = function(callback)
            if callback then
                checkTased()

                taseConnection = playersService.LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.1)
                    checkTased()
                end)

                task.spawn(function()
                    while AntiTase.Enabled do
                        checkTased()
                        task.wait(0.1)
                    end
                end)
            else
                if taseConnection then
                    taseConnection:Disconnect()
                    taseConnection = nil
                end
            end
        end,
        Tooltip = 'Teleports you down -100 studs while keeping X and Z when tased'
    })
end)

run(function()
    local KillPlayer
    local TargetDropdown
    local RefreshBtn

    local function getPlayers()
        local list = {}
        for _, player in pairs(playersService:GetPlayers()) do
            if player ~= playersService.LocalPlayer then
                table.insert(list, player.Name)
            end
        end
        return #list > 0 and list or {'No players'}
    end

    local function refreshDropdown()
        local list = getPlayers()
        TargetDropdown:SetList(list)
        TargetDropdown:SetValue(list[1])
    end

    KillPlayer = vape.Categories.Combat:CreateModule({
        Name = 'Kill Player',
        Function = function(callback)
            if callback then
                local targetName = TargetDropdown.Value
                if targetName == 'No players' then return end

                -- Start holding shoot
                mouse1press()

                task.spawn(function()
                    while KillPlayer.Enabled do
                        local target = playersService:FindFirstChild(targetName)
                        if not target then
                            task.wait(0.3)
                            continue
                        end

                        local targetChar = target.Character
                        if not targetChar or not targetChar:FindFirstChild('HumanoidRootPart') then
                            task.wait(0.3)
                            continue
                        end

                        local char = playersService.LocalPlayer.Character
                        if not char or not char:FindFirstChild('HumanoidRootPart') then
                            task.wait(0.3)
                            continue
                        end

                        local targetRoot = targetChar.HumanoidRootPart

                        -- Teleport 1 stud behind them
                        char.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)

                        task.wait()
                    end
                end)
            else
                -- Release shoot when disabled
                mouse1release()
            end
        end,
        Tooltip = 'Teleports behind the selected player and holds shoot constantly'
    })

    TargetDropdown = KillPlayer:CreateDropdown({
        Name = 'Target',
        List = getPlayers(),
        Default = getPlayers()[1],
        Tooltip = 'Select the player to kill'
    })

    RefreshBtn = KillPlayer:CreateButton({
        Name = 'Refresh Players',
        Function = function()
            refreshDropdown()
        end
    })
end)
