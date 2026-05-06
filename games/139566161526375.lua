--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo

local bd = {}
local store = {
	blocks = {},
	serverBlocks = {}
}

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local writefile = writefile or function() end

run(function()
	local function download(path, localpath)
		local repo = 'Koya50/ReVapeV4ForRoblox'
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/'..repo..'/main/'..path, true)
		end)
		if suc and res ~= '404: Not Found' then
			pcall(function() writefile(localpath, res) end)
		end
	end

	if not isfile('newvape/libraries/blink.lua') then download('libraries/blink.lua', 'newvape/libraries/blink.lua') end
	if not isfile('newvape/libraries/construct.lua') then download('libraries/construct.lua', 'newvape/libraries/construct.lua') end

	local constructCode = isfile('newvape/libraries/construct.lua') and readfile('newvape/libraries/construct.lua')
	if constructCode then
		local suc, res = pcall(function()
			return loadstring(constructCode)()
		end)
		if suc then bd = res end
	end
end)


run(function()
	local oldstart = entitylib.start
	local function teamcheck(ent)
		local suc, res = pcall(function()
			if ent.Team or (ent.Character and ent.Character:FindFirstChild('Humanoid') and ent.Character.Humanoid.Team) then
				return lplr.Team ~= (ent.Team or ent.Character.Humanoid.Team)
			end
		end)
		return (suc and res) or true
	end
	local function customEntity(ent)
		if not ent:HasTag('NPC') then return end
		if ent:IsDescendantOf(workspace) then
			entitylib.addEntity(ent, nil, function(self)
				return teamcheck(self)
			end)
		end
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('NPC') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('NPC'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('NPC'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
	end
end)
entitylib.start()

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool')
end

local Criticals = {Enabled = false}
run(function()
	Criticals = vape.Categories.Blatant:CreateModule({
		Name = 'Criticals',
		Tooltip = 'Always hit criticals (with KillAura on)'
	})
end)

run(function()
	local Killaura
	local Targets
	local AttackRange
	local SwingRange
	local AngleSlider
	local AutoBlock
	local Mouse
	local Swing
	local Block
	local Max
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local LegitAura
	local Particles, Boxes, AttackDelay, SwingDelay, ClickDelay = {}, {}, tick(), tick(), tick()
	
	local function getAttackData()
		if Mouse and Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if LegitAura and LegitAura.Enabled then
			if ClickDelay < tick() then return false end
		end
		return getTool()
	end

	local function blockSword(bool, sword)
		if bd.ToolService and bd.ToolService.ToggleBlockSword then
			task.spawn(function()
				bd.ToolService:ToggleBlockSword(bool, sword)
			end)
		end
	end
	
	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			local gameCamera = workspace.CurrentCamera
			if callback then
				if LegitAura and LegitAura.Enabled then
					Killaura:Clean(inputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							ClickDelay = tick() + 0.1
						end
					end))
				end
					
				repeat
					local tool = getAttackData()
					local attacked = {}
					
					-- GitHub targeting logic requires a Sword tag (checking if we should force it)
					if entitylib and entitylib.AllPosition and tool and tool:HasTag('Sword') then
						local plrs = entitylib.AllPosition({
							Range = SwingRange and SwingRange.Value or 16,
							Wallcheck = (Targets and Targets.Walls and Targets.Walls.Enabled) or nil,
							Part = 'RootPart',
							Players = (Targets and Targets.Players and Targets.Players.Enabled),
							NPCs = (Targets and Targets.NPCs and Targets.NPCs.Enabled),
							Limit = Max and Max.Value or 10
						})
		
						if #plrs > 0 then
							local selfpos = entitylib.character and entitylib.character.RootPart and entitylib.character.RootPart.Position
							local localfacing = entitylib.character and entitylib.character.RootPart and entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

							if selfpos and localfacing then
								if AutoBlock and AutoBlock.Enabled and tool then
									blockSword(true, tool.Name)
								end
			
								for _, v in plrs do
									-- Prediction and Angle check from GitHub
									local delta = ((v.RootPart.Position + v.Humanoid.MoveDirection) - selfpos)
									local flatdelta = delta * Vector3.new(1, 0, 1)
									local angle = 0
									if flatdelta.Magnitude > 0 then
										angle = math.acos(localfacing:Dot(flatdelta.Unit))
									end
									
									if AngleSlider and angle > (math.rad(AngleSlider.Value) / 2) then continue end
									
									table.insert(attacked, {
										Entity = v,
										Check = (AttackRange and delta.Magnitude > AttackRange.Value) and BoxSwingColor or BoxAttackColor
									})
									
									if targetinfo and targetinfo.Targets then
										targetinfo.Targets[v] = tick() + 1
									end
				
									-- Swing animation logic
									if Swing and not Swing.Enabled and SwingDelay < tick() then
										SwingDelay = tick() + 0.25
										if tool:FindFirstChild('Animations') and tool.Animations:FindFirstChild('Swing') then
											entitylib.character.Humanoid.Animator:LoadAnimation(tool.Animations.Swing):Play()
										end
			
										if vape.ThreadFix then setthreadidentity(2) end
										if bd.ViewmodelController then
											bd.ViewmodelController:PlayAnimation(tool.Name)
										end
										if vape.ThreadFix then setthreadidentity(8) end
									end
				
									-- THE GITHUB HIT (Blink protocol with rizz payload)
									if AttackRange and delta.Magnitude > AttackRange.Value then continue end
									if AttackDelay < tick() then
										AttackDelay = tick() + 0.1
										
										-- Lookup the internal entity ID required for Blink
										local bdent = bd.Entity and bd.Entity.FindByCharacter and bd.Entity.FindByCharacter(v.Character)
										
										task.spawn(function()
											if bdent and bd.Blink and bd.Blink.item_action and bd.Blink.item_action.attack_entity then
												bd.Blink.item_action.attack_entity.fire({
													target_entity_id = bdent.Id,
													is_crit = (Criticals.Enabled and true) or (entitylib.character.RootPart and entitylib.character.RootPart.AssemblyLinearVelocity.Y < 0),
													weapon_name = tool.Name,
													extra = {
														rizz = 'Bro.',
														owo = 'What\'s this? OwO ',
														those = workspace.Name == 'Ok'
													}
												})
											else
												-- Fallback to standard remote if Blink isn't ready
												if bd.ToolService and bd.ToolService.AttackPlayerWithSword then
													bd.ToolService:AttackPlayerWithSword(v.Character, (Criticals.Enabled and true) or (entitylib.character.RootPart and entitylib.character.RootPart.AssemblyLinearVelocity.Y < 0), tool.Name)
												end
											end
										end)
									end
								end
							end
						elseif AutoBlock and AutoBlock.Enabled and tool then
							blockSword(false, tool.Name)
						end
					end
	
					-- Visuals (Boxes & Particles)
					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end
					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end
	
					task.wait()
				until not Killaura.Enabled
			else
				local atdata = getAttackData()
				if atdata and AutoBlock and AutoBlock.Enabled then
					blockSword(false, atdata.Name)
				end
				for _, v in Boxes do v.Adornee = nil end
				for _, v in Particles do v.Parent = nil end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({Players = true})
	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 16,
		Default = 16,
		Suffix = function(val) return val == 1 and 'stud' or 'studs' end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 16,
		Default = 16,
		Suffix = function(val) return val == 1 and 'stud' or 'studs' end
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	Max = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10
	})
	AutoBlock = Killaura:CreateToggle({
		Name = 'AutoBlock',
		Tooltip = 'Automatically blocks for you'
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	Block = Killaura:CreateToggle({Name = 'No Block'})
	
	--Visual setup (Show target & Particles)
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do v:Destroy() end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and workspace.CurrentCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do v:Destroy() end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function() for _, v in Particles do v.ParticleEmitter.Texture = ParticleTexture.Value end end,
		Darker = true, Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true, Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true, Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size', Min = 0, Max = 1, Default = 0.14, Decimal = 100,
		Function = function(val) for _, v in Particles do v.ParticleEmitter.Size = NumberSequence.new(val) end end,
		Darker = true, Visible = false
	})
	LegitAura = Killaura:CreateToggle({
		Name = 'Swing only',
		Function = function() if Killaura.Enabled then Killaura:Toggle() Killaura:Toggle() end end,
		Tooltip = 'Only attacks while swinging manually'
	})
end)

run(function()
	local AutoPlay
	AutoPlay = vape.Categories.Utility:CreateModule({
		Name = 'AutoPlay',
		Function = function(callback)
			if callback then
				repeat
					if bd.ServerData and bd.ServerData.Submode ~= 'Playground' and lplr.PlayerGui.Hotbar.MainFrame.GameEndFrame.Visible == true and lplr.PlayerGui.Hotbar.MainFrame.MatchmakingFrame.Visible == false then
						bd.MatchController:EnterQueue(bd.ServerData.Submode)
					end
					task.wait()
				until not AutoPlay.Enabled
			end
		end,
		Tooltip = 'Automatically queues after the match ends.'
	})
end)

run(function()
	local NoFall
	NoFall = vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.character and entitylib.character.Humanoid and entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and (entitylib.character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall or entitylib.character.Humanoid:GetState() == Enum.HumanoidStateType.FallingDown) then
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
					end
					task.wait()
				until not NoFall.Enabled
			end
		end,
		Tooltip = 'Prevents taking fall damage.'
	})
end)
