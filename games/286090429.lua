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
    local FOV
    local TeamCheck
    local VisibleCheck
    local UseClosestHitbox
    local BodyPart
    local cache = { hitboxes = {'Head', 'UpperTorso', 'LowerTorso', 'LeftUpperArm', 'RightUpperArm', 'LeftLowerArm', 'RightLowerArm', 'LeftHand', 'RightHand', 'LeftUpperLeg', 'RightUpperLeg', 'LeftLowerLeg', 'RightLowerLeg', 'LeftFoot', 'RightFoot'} }
    local raycastParams = RaycastParams.new()
    raycastParams.RespectCanCollide = true
    local oldHooks = {}

    local function getClosestHitbox()
        local closestHitbox = nil
        local shortestDistance = math.huge
        local mouse = playersService.LocalPlayer:GetMouse()

        for _, player in pairs(playersService:GetPlayers()) do
            local character = player.Character
            if character and player ~= playersService.LocalPlayer then
                if TeamCheck.Enabled and player.Team == playersService.LocalPlayer.Team then
                    continue
                end

                local humanoid = character:FindFirstChildOfClass('Humanoid')
                if humanoid and humanoid.Health > 0 then
                    local parts = UseClosestHitbox.Enabled and cache.hitboxes or {BodyPart.Value}

                    for _, partName in pairs(parts) do
                        local hitbox = character:FindFirstChild(partName)
                        if hitbox then
                            local screenPosition, onScreen = gameCamera:WorldToScreenPoint(hitbox.Position)
                            if onScreen then
                                local mousePos = Vector2.new(mouse.X, mouse.Y)
                                local hitboxPos = Vector2.new(screenPosition.X, screenPosition.Y)
                                local distance = (mousePos - hitboxPos).Magnitude

                                if distance <= FOV.Value and distance < shortestDistance then
                                    if VisibleCheck.Enabled then
                                        local rayOrigin = gameCamera.CFrame.Position
                                        local rayDirection = (hitbox.Position - rayOrigin).Unit * 1000

                                        raycastParams.FilterDescendantsInstances = {playersService.LocalPlayer.Character}
                                        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

                                        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

                                        while raycastResult and raycastResult.Instance do
                                            local hitPart = raycastResult.Instance
                                            local isCharacterPart = false

                                            for _, p in pairs(playersService:GetPlayers()) do
                                                if p.Character and hitPart:IsDescendantOf(p.Character) then
                                                    isCharacterPart = true
                                                    break
                                                end
                                            end

                                            if not isCharacterPart and (hitPart.Transparency >= 0.5 or not hitPart.CanCollide) then
                                                table.insert(raycastParams.FilterDescendantsInstances, hitPart)
                                                rayOrigin = raycastResult.Position + rayDirection.Unit * 0.01
                                                raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                                            else
                                                break
                                            end
                                        end

                                        if raycastResult and raycastResult.Instance:IsDescendantOf(character) then
                                            shortestDistance = distance
                                            closestHitbox = hitbox
                                        end
                                    else
                                        shortestDistance = distance
                                        closestHitbox = hitbox
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return closestHitbox
    end

    local function hookAllRaycasts()
        -- Hook workspace.Raycast
        oldHooks.workspace = hookfunction(workspace.Raycast, function(self, origin, direction, params)
            local closestHitbox = getClosestHitbox()
            if closestHitbox then
                direction = (closestHitbox.Position - origin).Unit * direction.Magnitude
            end
            return oldHooks.workspace(self, origin, direction, params)
        end)

        -- Hook any GC function named raycast
        for _, func in pairs(getgc()) do
            if func and typeof(func) == 'function' and not oldHooks[func] then
                local info = debug.getinfo(func)
                if info and info.name and string.lower(info.name) == 'raycast' then
                    oldHooks[func] = hookfunction(func, function(self, ...)
                        local args = {...}
                        local closestHitbox = getClosestHitbox()
                        if closestHitbox then
                            args[2] = (closestHitbox.Position - args[1]).Unit * 1000
                        end
                        return oldHooks[func](self, table.unpack(args, 1, #args))
                    end)
                end
            end
        end

        -- Hook __namecall for Raycast
        oldHooks.namecall = hookmetamethod(game, '__namecall', function(...)
            local method = getnamecallmethod()
            if method == 'Raycast' then
                local self, args = ..., {select(2, ...)}
                local closestHitbox = getClosestHitbox()
                if closestHitbox and args[1] then
                    args[2] = (closestHitbox.Position - args[1]).Unit * args[2].Magnitude
                end
                return oldHooks.namecall(self, unpack(args))
            end
            return oldHooks.namecall(...)
        end)
    end

    local function unhookAll()
        for key, old in pairs(oldHooks) do
            if key == 'workspace' then
                hookfunction(workspace.Raycast, old)
            elseif key == 'namecall' then
                hookmetamethod(game, '__namecall', old)
            elseif typeof(key) == 'function' then
                for _, func in pairs(getgc()) do
                    if func and typeof(func) == 'function' then
                        local info = debug.getinfo(func)
                        if info and info.name and string.lower(info.name) == 'raycast' then
                            hookfunction(func, old)
                            break
                        end
                    end
                end
            end
        end
        oldHooks = {}
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if callback then
                hookAllRaycasts()
            else
                unhookAll()
            end
        end,
        Tooltip = 'Silent aim that redirects bullets to the closest player hitbox'
    })

    Target = SilentAim:CreateTargets({Players = true})

    FOV = SilentAim:CreateSlider({
        Name = 'FOV',
        Min = 10,
        Max = 500,
        Default = 90,
        Suffix = 'px',
        Tooltip = 'Field of view radius in pixels'
    })

    TeamCheck = SilentAim:CreateToggle({
        Name = 'Team Check',
        Default = true,
        Tooltip = 'Ignores players on your team'
    })

    VisibleCheck = SilentAim:CreateToggle({
        Name = 'Visible Check',
        Default = true,
        Tooltip = 'Only targets players that are visible'
    })

    BodyPart = SilentAim:CreateDropdown({
        Name = 'Body Part',
        List = cache.hitboxes,
        Default = 'Head',
        Visible = false,
        Darker = true,
        Tooltip = 'Choose which body part to target'
    })

    UseClosestHitbox = SilentAim:CreateToggle({
        Name = 'Closest Hitbox',
        Default = true,
        Function = function(callback)
            if BodyPart and BodyPart.Object then
                BodyPart.Object.Visible = not callback
            end
        end,
        Tooltip = 'Targets the closest body part instead of a specific one'
    })
end)
