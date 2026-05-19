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


run(function()
	local charConnection
    local GunModifications
	local function mod(v)
		if v:IsA("Tool") and v:GetAttribute("FireRate") then
			v:SetAttribute("FireRate", 0.03)
			v:SetAttribute("AutoFire", true)
			v:SetAttribute("SpreadRadius", 0)
		end
	end

GunModifications = vape.Categories.Combat:CreateModule({
		Name = 'GunModifications',
		Function = function(callback)
			if callback then
				for _, v in pairs(lplr.Backpack:GetChildren()) do mod(v) end
				if lplr.Character then
					for _, v in pairs(lplr.Character:GetChildren()) do mod(v) end
					charConnection = lplr.Character.ChildAdded:Connect(mod)
				end
			else
				if charConnection then charConnection:Disconnect() charConnection = nil end
			end
		end,
		Tooltip = 'Modifies gun attributes.'
	})
end)

run(function()
    local DeleteAntiJump

    DeleteAntiJump = vape.Categories.World:CreateModule({
        Name = 'Delete AntiJump',
        Function = function(callback)
            if callback then
                local model = workspace:FindFirstChild(lplr)
                if model and model:IsA('Model') then
                    local antiJumpScript = model:FindFirstChild('AntiJump', true)
                    if antiJumpScript and antiJumpScript:IsA('LocalScript') then
                        antiJumpScript:Destroy()
                    end
                end

                DeleteAntiJump:Toggle()
            end
        end,
        Tooltip = 'Auto-detects your name and deletes the AntiJump LocalScript'
    })
end)
