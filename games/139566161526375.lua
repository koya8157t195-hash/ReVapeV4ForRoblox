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

for _, v in {'Reach', 'MurderMystery', 'AutoRejoin', 'Killaura', 'Swim', 'TargetStrafe', 'LongJump', 'MouseTP', 'Invisible'} do
	vape:Remove(v)
end
run(function()
local EntityCFrame
local Killaura, Flight = {Enabled = false}, {Enabled = false}
	local AutoBlock = {Enabled = true}
	local Angle = {Value = 360}
	local Range = {Value = 16}
	local TargetHUD = {Enabled = false}
	local Wallcheck = {Enabled = false}
	local Swing, SwingDelay = {Enabled = true}, tick()
	local AttackDelay = tick()
	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				repeat
					task.wait()

					if Entitylib.isAlive(lplr) then
						local tool = Entity.tool.getTool(lplr)

						if tool and tool:HasTag('Sword') then
							task.spawn(function()
								local suc, res = pcall(function()
									return Entity:GetClosestPlayer(Range.Value, Angle.Value, Wallcheck.Enabled)
								end)

								local plr
								if suc and res then
									plr = res
								end

								if plr and Entity.isAlive(plr) then
									EntityCFrame = CFrame.lookAt(lplr.Character.PrimaryPart.Position, Vector3.new(plr.Character.PrimaryPart.Position.X, lplr.Character.PrimaryPart.Position.Y, plr.Character.PrimaryPart.Position.Z))
								
									ReplicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(AutoBlock.Enabled, tool)
									if Swing.Enabled and SwingDelay < tick() then
										SwingDelay = tick() + 0.25
										lplr.Character.Humanoid.Animator:LoadAnimation(tool:WaitForChild('Animations'):WaitForChild('Swing')):Play()

										if setthreadidentity then
											setthreadidentity(2)
										end
										pcall(Dependencies.Controllers.Viewmodel.PlayAnimation, Dependencies.Controllers.Viewmodel, tool.Name)
										if setthreadidentity then
											setthreadidentity(8)
										end
									end

									local suc, res = pcall(function()
										return Dependencies.Modules.Entity.FindByCharacter(plr.Character)
									end)

									local bdplr
									if suc and res ~= nil then
										bdplr = res
									end

									if bdplr and bdplr.Id and Dependencies.Constants.Extra and AttackDelay < tick() then -- (not Dependencies.Modules.Detections.Logs.SwordH)
										AttackDelay = tick() + 0.1
										task.spawn(Dependencies.Blink.item_action.attack_entity.fire, {
											target_entity_id = bdplr.Id,
											is_crit = (AuraCrits and true) or lplr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y < 0,
											weapon_name = tool.Name,
											extra = Dependencies.Constants.Extra
										})
									end
								else
									EntityCFrame = nil
								
									if Entity.isAlive(lplr) then
										local tool = Entity.tool.getTool(lplr)
										if tool and tool:HasTag('Sword') then
											ReplicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(false, tool)
										end
									end
								end
							end)
						end
					end
				until not Killaura.Enabled
			else
				EntityCFrame = nil

				if Entity.isAlive(lplr) then
					local tool = Entity.tool.getTool(lplr)
					if tool and tool:HasTag('Sword') then
						ReplicatedStorage.Modules.Knit.Services.ToolService.RF.ToggleBlockSword:InvokeServer(false, tool)
					end
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


run(function()
local Disabler
	Disabler = vape.Categories.Utility:CreateModule({
		Name = 'Disabler',
    Tooltip = 'report disabler?',
		Function = function(callback)
			if callback then
				Dependencies.Paths.AimbotDtc.Parent = nil
				Dependencies.Paths.SendReport.Parent = nil
			else
				Dependencies.Paths.AimbotDtc.Parent = ReplicatedStorage.Remotes
				Dependencies.Paths.SendReport.Parent = ReplicatedStorage.Modules.Knit.Services.NetworkService.RF
			end
		end
	})
end)
