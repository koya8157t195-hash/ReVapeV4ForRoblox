local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
    local DesyncAA
    local connection
    local AAHandler
    local side = 1
    local lastFlip = 0

    DesyncAA = vape.Categories.Blatant:CreateModule({
        Name = "DesyncAA",
        Function = function(callback)
            if callback then
                local s, result = pcall(function()
                    return require(game:GetService("ReplicatedFirst"):WaitForChild("AAHandler"))
                end)
                
                if not s or not result then
                    vape:CreateNotification("DesyncAA", "Failed to load AAHandler", 3, "alert")
                    DesyncAA:Toggle()
                    return
                end
                
                AAHandler = result

                local dt = lplr:FindFirstChild("DT") or Instance.new("BoolValue", lplr)
                dt.Name = "DT"
                dt.Value = true

                connection = runService.Heartbeat:Connect(function()
                    if not DesyncAA.Enabled then return end

                    if tick() - lastFlip > 0.5 then
                        side = -side
                        lastFlip = tick()
                    end

                    pcall(function()
                        AAHandler.SendBodyYaw(nil, 74 * side)
                        AAHandler.SendYawJitter(nil, "Static", -127, 0, 0, 0, 0, 0)
                        AAHandler.SendPitchMode(nil, "Static", -90, 0, 0, 0, 0, 0)
                    end)
                end)

                DesyncAA:Clean(connection)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                if AAHandler then
                    pcall(function()
                        AAHandler.SendYawJitter(nil, "Off", 0, 0, 0, 0, 0, 0)
                        AAHandler.SendBodyYaw(nil, 0)
                        AAHandler.SendPitchMode(nil, "Off", 0, 0, 0, 0, 0, 0)
                    end)
                end
                local dt = lplr:FindFirstChild("DT")
                if dt then dt.Value = false end
            end
        end,
        Tooltip = "74 degree desync with inverter at -127 real yaw"
    })
end)

run(function()
    local Resolver
    local connection
    local playerData = {}

    local function getPlayerData(plr)
        if not playerData[plr] then
            playerData[plr] = {
                misses = 0,
                side = 1,
                lastState = "Standing",
                stateTime = 0,
                lastPos = nil,
                velocity = Vector3.zero,
                speed = 0,
                moveDirAngle = 0,
                lastMovingAngle = 0,
                lastHitAngle = nil,
                lastUpdate = 0,
                lbyProxy = 0,
            }
        end
        return playerData[plr]
    end

    local function norm(a)
        return math.atan2(math.sin(a), math.cos(a))
    end

    local function diff(a, b)
        return math.abs(norm(a - b))
    end

    local function updateData(plr)
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp then return end

        local data = getPlayerData(plr)
        local now = tick()
        local dt = now - data.lastUpdate
        data.lastUpdate = now

        local newPos = hrp.Position
        if data.lastPos and dt > 0 then
            local rawVel = (newPos - data.lastPos) / dt
            data.velocity = data.velocity:Lerp(rawVel, 0.4)
        end
        data.lastPos = newPos

        data.speed = Vector3.new(data.velocity.X, 0, data.velocity.Z).Magnitude

        -- Determine state
        local inAir = false
        if hum then
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.Jumping then
                inAir = true
            end
        end
        if math.abs(data.velocity.Y) > 5 and not inAir then inAir = true end

        local newState = "Standing"
        if inAir then
            newState = "Air"
        elseif data.speed > 3 then
            newState = "Moving"
        end

        if newState ~= data.lastState then
            data.stateTime = now
            data.lastState = newState
        end

        -- Track movement direction
        if data.speed > 1 then
            local dir = data.velocity.Unit
            data.moveDirAngle = math.deg(math.atan2(dir.X, dir.Z))
            data.lastMovingAngle = data.moveDirAngle
        end

        -- Get body yaw proxy from HRP orientation
        local _, rotY, _ = hrp.CFrame:ToOrientation()
        data.lbyProxy = math.deg(rotY)
    end

    local function resolveYaw(plr)
        local char = plr.Character
        if not char then return 0 end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return 0 end

        updateData(plr)
        local data = getPlayerData(plr)

        local _, baseYaw, _ = hrp.CFrame:ToOrientation()
        local baseAngle = math.deg(baseYaw)

        -- Get the visual yaw the enemy sees
        local realYaw = baseAngle

        if data.lastState == "Moving" and data.speed > 3 then
            -- Moving players: body follows movement direction
            local delta = norm(math.rad(data.moveDirAngle - baseAngle))
            realYaw = baseAngle + delta
        elseif data.lastState == "Air" then
            -- Air: partial movement tracking + some desync
            local delta = norm(math.rad(data.moveDirAngle - baseAngle))
            realYaw = baseAngle + delta * 0.6
        elseif data.lastState == "Standing" then
            -- Standing still = desync city. Use miss-based bruteforce with side switching.
            local maxAngle = 58
            
            -- After 2 misses, flip side. After 4 misses, try different angle.
            if data.misses >= 4 then
                -- Bruteforce: cycle through angles
                local angles = {0, maxAngle, -maxAngle, maxAngle/2, -maxAngle/2, maxAngle*0.75, -maxAngle*0.75}
                local idx = (data.misses % #angles) + 1
                realYaw = baseAngle + angles[idx]
            elseif data.misses >= 2 then
                data.side = -data.side
                realYaw = baseAngle + maxAngle * data.side
            else
                realYaw = baseAngle + maxAngle * data.side
            end
        end

        return math.rad(realYaw)
    end

    local function applyYaw(plr, yaw)
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rj = hrp:FindFirstChild("RootJoint")
        if not rj then return end

        if not rj:GetAttribute("BaseC0") then
            rj:SetAttribute("BaseC0", rj.C0)
        end

        rj.C0 = rj:GetAttribute("BaseC0") * CFrame.Angles(0, yaw, 0)
    end

    -- Miss detection: hook print for "Missed due to desync"
    local oldPrint = print
    print = function(...)
        local args = {...}
        for _, v in ipairs(args) do
            if tostring(v):find("Missed due to desync") then
                -- Find closest enemy
                local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local closest, closestDist = nil, math.huge
                    for _, plr in ipairs(playersService:GetPlayers()) do
                        if plr ~= lplr and plr.Character then
                            local ehrp = plr.Character:FindFirstChild("HumanoidRootPart")
                            if ehrp then
                                local d = (ehrp.Position - myRoot.Position).Magnitude
                                if d < closestDist then
                                    closest = plr
                                    closestDist = d
                                end
                            end
                        end
                    end
                    if closest then
                        local data = getPlayerData(closest)
                        data.misses = data.misses + 1
                    end
                end
            end
        end
        oldPrint(...)
    end

    Resolver = vape.Categories.Blatant:CreateModule({
        Name = "Resolver",
        Function = function(callback)
            if callback then
                connection = runService.Heartbeat:Connect(function()
                    if not Resolver.Enabled then return end

                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    -- Resolve the closest enemy
                    local closest, closestDist = nil, math.huge
                    for _, plr in ipairs(playersService:GetPlayers()) do
                        if plr ~= lplr and plr.Character then
                            local ehrp = plr.Character:FindFirstChild("HumanoidRootPart")
                            local ehum = plr.Character:FindFirstChildOfClass("Humanoid")
                            if ehrp and ehum and ehum.Health > 0 then
                                local d = (ehrp.Position - myRoot.Position).Magnitude
                                if d < closestDist and d < 300 then
                                    closest = plr
                                    closestDist = d
                                end
                            end
                        end
                    end

                    if closest then
                        local yaw = resolveYaw(closest)
                        applyYaw(closest, yaw)
                    end
                end)

                Resolver:Clean(connection)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                -- Clean up hook
                print = oldPrint
            end
        end,
        ExtraText = function()
            return "Better"
        end,
        Tooltip = "Better resolver with state-based logic and miss detection"
    })
end)

run(function()
    local NoSpread
    local SpreadAmount

    local function setspread(bs, ms, mjs, mins, msps, vi, hi, cm)
        bs = bs or 0.5
        ms = ms or 2.5
        mjs = mjs or 15
        mins = mins or 0.01
        msps = msps or 15
        vi = vi or 2
        hi = hi or 0.2
        cm = cm or 0.3

        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "BaseSpread") and rawget(v, "MoveSpread") and rawget(v, "MaxJumpSpread") and rawget(v, "MinSpread") and rawget(v, "MaxSpread") and rawget(v, "VelocityInfluence") and rawget(v, "HorizontalInfluence") and rawget(v, "CrouchMultiplier") then
                v.BaseSpread = bs
                v.MoveSpread = ms
                v.MaxJumpSpread = mjs
                v.MinSpread = mins
                v.MaxSpread = msps
                v.VelocityInfluence = vi
                v.HorizontalInfluence = hi
                v.CrouchMultiplier = cm
            end
        end
    end

    NoSpread = vape.Categories.Blatant:CreateModule({
        Name = "NoSpread",
        Function = function(callback)
            if callback then
                setspread(0, 0, 0, SpreadAmount.Value, SpreadAmount.Value, 0, 0, 0)
            else
                setspread(0.5, 2.5, 15, 0.01, 15, 2, 0.2, 0.3)
            end
        end,
        Tooltip = "Modifies weapon spread values"
    })

    SpreadAmount = NoSpread:CreateSlider({
        Name = "Spread Amount",
        Min = 0,
        Max = 15,
        Default = 0,
        Function = function(val)
            if NoSpread.Enabled then
                setspread(0, 0, 0, val, val, 0, 0, 0)
            end
        end,
        Tooltip = "MinSpread and MaxSpread value"
    })
end)

run(function()
    local AntiCheat

    AntiCheat = vape.Categories.Blatant:CreateModule({
        Name = "AntiCheat",
        Function = function(callback)
            if callback then
                if not checkspecificfunction("getgc") then
                    vape:CreateNotification("AntiCheat", "getgc is missing, can't disable client checks.", 3, "alert")
                    AntiCheat:Toggle()
                    return
                end

                -- Disable protection tables
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" and rawget(v, "WalkspeedProtect") then
                        v.WalkspeedProtect.enabled = false
                        v.FlyProtect.enabled = false
                        v.TeleportDetect.enabled = false
                        v.CFrameMonitor.enabled = false
                        v.NoClipProtect.enabled = false
                        v.HitboxProtect.enabled = false
                        v.PartRemoveProtect = false
                        v.PartRenameProtect = false
                    end
                end

                -- Disable kick thresholds
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" and rawget(v, "RADIUS_KICK") and rawget(v, "POS_KICK") then
                        v.RADIUS_KICK = math.huge
                        v.POS_KICK = math.huge
                        v.POS_MISMATCH_TIME = math.huge
                        v.MISMATCH_THRESHOLD = math.huge
                        v.DT_SPAM_RADIUS = math.huge
                        v.DT_RADIUS = math.huge
                        v.RADIUS = math.huge
                    end
                end

                -- Hook kick/check functions
                for _, v in pairs(getgc(true)) do
                    if type(v) == "function" and getfenv(v).script == nil then
                        local name = debug.info(v, "n")
                        if name == "sendKick" or name == "checkCFrameMovement" then
                            hookfunction(v, function() return end)
                        end
                    end
                end

                vape:CreateNotification("AntiCheat", "Client checks disabled", 3, "check")
                AntiCheat:Toggle()
            end
        end,
        ExtraText = function()
            return "w devs"
        end,
        Tooltip = "Disables client anti-cheat checks on load."
    })
end)
