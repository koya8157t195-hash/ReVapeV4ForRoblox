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
    local FOV, TeamCheck, VisibleCheck, ClosestHitbox

    local hooked = false
    local oldHooks = {}

    local players = game:GetService("Players")
    local lplr = players.LocalPlayer
    local camera = workspace.CurrentCamera

    local cache = {
        hitboxes = {
            "Head","UpperTorso","LowerTorso",
            "LeftUpperArm","RightUpperArm",
            "LeftLowerArm","RightLowerArm",
            "LeftHand","RightHand",
            "LeftUpperLeg","RightUpperLeg",
            "LeftLowerLeg","RightLowerLeg",
            "LeftFoot","RightFoot"
        }
    }

    local raycastParams = RaycastParams.new()
    raycastParams.RespectCanCollide = true

    local function getClosestHitbox()
        local closest, dist = nil, math.huge
        local mouse = lplr:GetMouse()

        for _, plr in pairs(players:GetPlayers()) do
            if plr ~= lplr and plr.Character then
                if TeamCheck.Enabled and plr.Team == lplr.Team then continue end

                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local parts = ClosestHitbox.Enabled and cache.hitboxes or {"Head"}

                    for _, name in pairs(parts) do
                        local part = plr.Character:FindFirstChild(name)
                        if part then
                            local screen, visible = camera:WorldToScreenPoint(part.Position)
                            if visible then
                                local mag = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screen.X, screen.Y)).Magnitude

                                if mag < FOV.Value and mag < dist then
                                    if VisibleCheck.Enabled then
                                        local origin = camera.CFrame.Position
                                        local dir = (part.Position - origin).Unit * 1000

                                        raycastParams.FilterDescendantsInstances = {lplr.Character}
                                        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

                                        local result = workspace:Raycast(origin, dir, raycastParams)
                                        if result and result.Instance:IsDescendantOf(plr.Character) then
                                            dist = mag
                                            closest = part
                                        end
                                    else
                                        dist = mag
                                        closest = part
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return closest
    end

    local function hook()
        if hooked then return end
        hooked = true

        for _, func in pairs(getgc()) do
            if typeof(func) == "function" then
                local info = debug.getinfo(func)

                if info and info.name and string.find(string.lower(info.name), "raycast") then
                    local old
                    old = hookfunction(func, function(self, ...)
                        local args = {...}
                        local target = getClosestHitbox()

                        if target then
                            args[2] = (target.Position - args[1]).Unit * 1000
                        end

                        return old(self, unpack(args))
                    end)

                    table.insert(oldHooks, {func, old})
                end

                if info and info.name and string.find(string.lower(info.name), "projectile") then
                    local old
                    old = hookfunction(func, function(...)
                        local args = {...}
                        local target = getClosestHitbox()

                        if target and args[4] then
                            local origin = args[4]
                            if typeof(origin) == "Vector3" then
                                args[5] = (target.Position - origin).Unit * 1000
                            end
                        end

                        return old(unpack(args))
                    end)

                    table.insert(oldHooks, {func, old})
                end
            end
        end
    end

    local function unhook()
        for _, v in pairs(oldHooks) do
            hookfunction(v[1], v[2])
        end
        oldHooks = {}
        hooked = false
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = "SilentAim",
        Function = function(enabled)
            if enabled then
                hook()
            else
                unhook()
            end
        end
    })

    FOV = SilentAim:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 120
    })

    TeamCheck = SilentAim:CreateToggle({
        Name = "Team Check",
        Default = true
    })

    VisibleCheck = SilentAim:CreateToggle({
        Name = "Visible Check",
        Default = true
    })

    ClosestHitbox = SilentAim:CreateToggle({
        Name = "Closest Hitbox",
        Default = true
    })
end)
