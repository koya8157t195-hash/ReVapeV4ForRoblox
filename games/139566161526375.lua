local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool')
end

run(function()
	local Killaura = {Enabled = false}
	local AutoBlock = {Enabled = true}
	local Angle = {Value = 360}
	local Range = {Value = 18}
	local Wallcheck = {Enabled = false}
	local Swing = {Enabled = true}
	
	local AttackDelay = tick()
	local SwingDelay = tick()
	local target = nil

	local function getTarget()
		local entitylib = vape.Libraries.entity
		if not (entitylib and entitylib.List) then return nil end
		
		local closest, maxdist = nil, Range.Value
		for _, v in entitylib.List do
			if not v.Targetable then continue end
			if not entitylib.isVulnerable(v) then continue end
			
			local root = v.RootPart
			if not (root and lplr.Character and lplr.Character.PrimaryPart) then continue end

			local dist = (root.Position - lplr.Character.PrimaryPart.Position).Magnitude
			if dist > maxdist then continue end
			
			if Angle.Value < 360 then
				local gameCamera = workspace.CurrentCamera
				local dot = gameCamera.CFrame.LookVector:Dot((root.Position - gameCamera.CFrame.Position).Unit)
				if dot < math.cos(math.rad(Angle.Value / 2)) then continue end
			end
			
			if Wallcheck.Enabled and entitylib.Wallcheck then
				if entitylib.Wallcheck(lplr.Character.PrimaryPart.Position, root.Position) then continue end
			end
			
			closest = v
			maxdist = dist
		end
		return closest
	end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.01)
						local entitylib = vape.Libraries.entity
						if not (entitylib and entitylib.isAlive) then continue end

						local tool = getTool()
						if tool and tool:HasTag('Sword') then
							target = getTarget()

							if target then
								-- AutoBlock
								replicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(AutoBlock.Enabled, tool)

								-- Swing
								if Swing.Enabled and SwingDelay < tick() then
									SwingDelay = tick() + 0.25
									local anim = tool:WaitForChild('Animations', 2):WaitForChild('Swing', 2)
									if anim then
										local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
										if hum and hum.Animator then
											hum.Animator:LoadAnimation(anim):Play()
										end
									end

									pcall(function()
										local deps = shared.Dependencies
										if deps and deps.Controllers and deps.Controllers.Viewmodel then
											if setthreadidentity then setthreadidentity(2) end
											deps.Controllers.Viewmodel:PlayAnimation(tool.Name)
											if setthreadidentity then setthreadidentity(8) end
										end
									end)
								end

								-- Attack
								if AttackDelay < tick() then
									AttackDelay = tick() + 0.1
									pcall(function()
										local deps = shared.Dependencies
										if deps and deps.Blink and deps.Blink.item_action and deps.Blink.item_action.attack_entity then
											local bdplr = deps.Modules.Entity.FindByCharacter(target.Character)
											if bdplr and bdplr.Id and deps.Constants.Extra then
												task.spawn(deps.Blink.item_action.attack_entity.fire, {
													target_entity_id = bdplr.Id,
													is_crit = lplr.Character.PrimaryPart.AssemblyLinearVelocity.Y < 0,
													weapon_name = tool.Name,
													extra = deps.Constants.Extra
												})
											end
										end
									end)
								end
							else
								if tool then
									replicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(false, tool)
								end
							end
						end
					until not Killaura.Enabled
				end)
			else
				local tool = getTool()
				if tool and tool:HasTag('Sword') then
					replicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(false, tool)
				end
			end
		end
	})

	AutoBlock = Killaura:CreateToggle({
		Name = 'AutoBlock',
		Enabled = true
	})
	Angle = Killaura:CreateSlider({
		Name = 'Max Angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	Range = Killaura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 18,
		Default = 16
	})
	Wallcheck = Killaura:CreateToggle({
		Name = 'Wallcheck'
	})
	Swing = Killaura:CreateToggle({
		Name = 'Swing',
		Enabled = true
	})
end)
