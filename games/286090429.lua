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

    local actors = (getactorthreads or getactors)()
    local actor = actors and actors[1]

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = "SilentAim",
        Function = function(enabled)
            if not actor then return end

            if enabled then
                (run_on_thread or run_on_actor)(actor, ([[
                    getgenv().SilentAimSettings = {
                        fov = %d,
                        team = %s,
                        visible = %s,
                        closest = %s
                    }

                    if getgenv().SilentAimLoaded then return end
                    getgenv().SilentAimLoaded = true

                    local players = game:GetService("Players")
                    local lplr = players.LocalPlayer
                    local cam = workspace.CurrentCamera
                    local mouse = lplr:GetMouse()

                    local hitboxes = {
                        "Head","UpperTorso","LowerTorso",
                        "LeftUpperArm","RightUpperArm",
                        "LeftLowerArm","RightLowerArm",
                        "LeftHand","RightHand",
                        "LeftUpperLeg","RightUpperLeg",
                        "LeftLowerLeg","RightLowerLeg",
                        "LeftFoot","RightFoot"
                    }

                    local params = RaycastParams.new()
                    params.RespectCanCollide = true

                    local function getTarget()
                        local best, dist = nil, math.huge
                        local settings = getgenv().SilentAimSettings

                        for _, plr in pairs(players:GetPlayers()) do
                            if plr ~= lplr and plr.Character then
                                if settings.team and plr.Team == lplr.Team then continue end

                                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 then
                                    local parts = settings.closest and hitboxes or {"Head"}

                                    for _, name in pairs(parts) do
                                        local part = plr.Character:FindFirstChild(name)
                                        if part then
                                            local screen, vis = cam:WorldToScreenPoint(part.Position)
                                            if vis then
                                                local mag = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screen.X, screen.Y)).Magnitude
                                                if mag < settings.fov and mag < dist then

                                                    if settings.visible then
                                                        local origin = cam.CFrame.Position
                                                        local dir = (part.Position - origin).Unit * 1000

                                                        params.FilterDescendantsInstances = {lplr.Character}
                                                        params.FilterType = Enum.RaycastFilterType.Exclude

                                                        local res = workspace:Raycast(origin, dir, params)
                                                        if res and res.Instance:IsDescendantOf(plr.Character) then
                                                            dist = mag
                                                            best = part
                                                        end
                                                    else
                                                        dist = mag
                                                        best = part
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        return best
                    end

                    for _, func in pairs(getgc()) do
                        if typeof(func) == "function" then
                            local info = debug.getinfo(func)

                            if info and info.name and string.find(string.lower(info.name), "raycast") then
                                local old
                                old = hookfunction(func, function(self, ...)
                                    local args = {...}
                                    local target = getTarget()

                                    if target then
                                        args[2] = (target.Position - args[1]).Unit * 1000
                                    end

                                    return old(self, unpack(args))
                                end)
                            end
                        end
                    end
                ]]):format(
                    FOV.Value,
                    tostring(TeamCheck.Enabled),
                    tostring(VisibleCheck.Enabled),
                    tostring(ClosestHitbox.Enabled)
                ))
            else
                if getgenv then
                    getgenv().SilentAimLoaded = false
                end
            end
        end
    })

    FOV = SilentAim:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 120,
        Function = function(val)
            if getgenv and getgenv().SilentAimSettings then
                getgenv().SilentAimSettings.fov = val
            end
        end
    })

    TeamCheck = SilentAim:CreateToggle({
        Name = "Team Check",
        Default = true,
        Function = function(val)
            if getgenv and getgenv().SilentAimSettings then
                getgenv().SilentAimSettings.team = val
            end
        end
    })

    VisibleCheck = SilentAim:CreateToggle({
        Name = "Visible Check",
        Default = true,
        Function = function(val)
            if getgenv and getgenv().SilentAimSettings then
                getgenv().SilentAimSettings.visible = val
            end
        end
    })

    ClosestHitbox = SilentAim:CreateToggle({
        Name = "Closest Hitbox",
        Default = true,
        Function = function(val)
            if getgenv and getgenv().SilentAimSettings then
                getgenv().SilentAimSettings.closest = val
            end
        end
    })
end)
