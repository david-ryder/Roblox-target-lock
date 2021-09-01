-- SERVICES
local uis = game:GetService("UserInputService")

local tween_service = game:GetService("TweenService")



-- VARIABLES
local tab = Enum.KeyCode.Tab

local right_click = Enum.UserInputType.MouseButton2

local max_distance = 50

local targeting = false

local player = game.Players.LocalPlayer

local character = player.Character

local humanoid = character.Humanoid

local humanoidRootPart = character.HumanoidRootPart

local camera = workspace.CurrentCamera

camera.CameraType = "Follow"

local focus_point

local cam_speed = .3

local cam_offset = CFrame.new(0, 5, 10)

local enemy

local midpoint



-- FUNCTIONS

-- Initializes settings for the lock on
local function initializeLock()

	targeting = true

	camera.CameraSubject = focus_point

	camera.CameraType = "Scriptable"

	camera.FieldOfView = 70

	humanoid.AutoRotate = false

end


-- 
local function specialReset()

	targeting = false

	focus_point:Destroy()
	
end


-- Resets to default settings for camera and player
local function reset()
	
	targeting = false
	
	camera.CameraType = "Follow"
	
	camera.CameraSubject = character.Humanoid

	humanoid.AutoRotate = true

	focus_point:Destroy()

end


-- Creates a focus point for the camera
local function createFocusPoint(enemy)

	-- Create invisible part between the enemy and player positions
	focus_point = Instance.new("Part", workspace)

	focus_point.Anchored = true

	focus_point.Size = Vector3.new(1,1,1)

	focus_point.CanCollide = false

	focus_point.Transparency = 1

	focus_point.Color = Color3.fromRGB(255, 0, 251)

	midpoint = (humanoidRootPart.Position + enemy.HumanoidRootPart.Position) / 2

	focus_point.Position = midpoint

	return

end


-- Rotate camera around focus point
local function rotateCamera(enemy)

	midpoint = (humanoidRootPart.Position + enemy.HumanoidRootPart.Position) / 2

	focus_point.Position = midpoint
	
	--camera:Interpolate(humanoidRootPart.CFrame:ToWorldSpace(cam_offset), focus_point.CFrame, cam_speed)

	-- Get final point that the camera needs to turn to
	
	local tween = tween_service:Create(
		camera,
		TweenInfo.new(cam_speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			CFrame = humanoidRootPart.CFrame:ToWorldSpace(cam_offset) * CFrame.Angles(math.rad(-25), 0, 0),
			Focus = focus_point.CFrame
		}
	)

	tween:Play()
	
end


-- Rotate the player to face enemy
local function rotatePlayer(enemy)

	local angle = Vector3.new(enemy.HumanoidRootPart.Position.X, humanoidRootPart.Position.Y, enemy.HumanoidRootPart.Position.Z)

	humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, angle)

end


-- Finds all enemies within range
local function getEnemiesInRange(list)

	local inRange = {}

	local my_position = game.Players.LocalPlayer.Character.HumanoidRootPart.Position

	-- Loop through each humanoid in game
	for i, humanoids in pairs(list) do 

		-- Get location of enemy
		local enemy_position = list[i].HumanoidRootPart.Position

		-- Check if enemy is within max_distance
		if (enemy_position - humanoidRootPart.Position).Magnitude < max_distance then

			-- Add current enemy to list of enemies in range
			table.insert(inRange, list[i])

		end

	end

	return inRange

end


-- Switches targets to sequentially farther targets
local function switchTargets(inRange, enemy)

	if #inRange == 1 then

		return enemy

	elseif #inRange > 1 then

		-- Get angle that player is currently facing
		local facing = humanoidRootPart.CFrame

		-- All enemies right of player
		local enemies_right_of_player = {}
		
		-- All enemies left of player
		local enemies_left_of_player = {}

		-- Find enemies to the right of the player position
		for i, humanoids in pairs(inRange) do

			if humanoids == enemy then

				continue

			end

			local cframe = humanoidRootPart.CFrame:ToObjectSpace(inRange[i].HumanoidRootPart.CFrame)

			if cframe.X > 0 then

				table.insert(enemies_right_of_player, inRange[i])

			end

		end
		
		-- Find enemies to the left of the player
		for i, humanoids in pairs(inRange) do

			if humanoids == enemy then

				continue

			end

			local cframe = humanoidRootPart.CFrame:ToObjectSpace(inRange[i].HumanoidRootPart.CFrame)

			if cframe.X < 0 then

				table.insert(enemies_left_of_player, inRange[i])

			end

		end
		
		local player_vector = humanoidRootPart.Position - enemy.HumanoidRootPart.Position

		local min_angle_enemy

		local smallest_angle

		local enemy_vector
		
		-- Check if enemies right
		if enemies_right_of_player[1] then
			
			
			-- Loop through each possible enemy to find the one with the smallest angle relative to the player
			for x, something in pairs(enemies_right_of_player) do

				-- Current enemy's vector
				enemy_vector = humanoidRootPart.Position - enemies_right_of_player[x].HumanoidRootPart.Position

				-- Set default angle and enemy to compare to
				if x == 1 then

					min_angle_enemy = enemies_right_of_player[x]

					smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

					continue

				end

				-- Update angle and enemy if needed
				if math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude)) < smallest_angle then

					min_angle_enemy = enemies_right_of_player[x]

					smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

				end

			end
		
		
		-- Check if enemies left
		elseif enemies_left_of_player[1] then
			
			-- Loop through each possible enemy to find the one with the smallest angle relative to the player
			for x, something in pairs(enemies_left_of_player) do

				-- Current enemy's vector
				enemy_vector = humanoidRootPart.Position - enemies_left_of_player[x].HumanoidRootPart.Position

				-- Set default angle and enemy to compare to
				if x == 1 then

					min_angle_enemy = enemies_left_of_player[x]

					smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

					continue

				end

				-- Update angle and enemy if needed
				if math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude)) > smallest_angle then

					min_angle_enemy = enemies_left_of_player[x]

					smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

				end

			end

		end

		return min_angle_enemy

	end

end


-- Lock onto enemy
local function lockOn(enemy)

	initializeLock()

	while targeting do

		if (enemy.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude > max_distance then

			reset()
			
		elseif enemy.Humanoid.Health <= 0 then
			
			local inRange = getEnemiesInRange(workspace.Enemies:GetChildren())
			
			if #inRange > 1 then
				
				enemy = switchTargets(inRange, enemy)

				specialReset()

				wait()

				createFocusPoint(enemy)

				initializeLock()

				lockOn(enemy)
				
			else
				
				reset()
				
				return
				
			end
			
		end
			
		rotatePlayer(enemy)

		rotateCamera(enemy)
			
		wait()

	end

	return

end


-- Finds enemy that is most center to the player from their current view direction
local function mostCenter(inRange)
	
	-- Get direction that player is currently facing
	local player_vector = humanoidRootPart.CFrame.LookVector

	local min_angle_enemy

	local smallest_angle

	local enemy_vector
	
	-- Loop through each possible enemy to find the one with the smallest angle relative to the player
	for x, something in pairs(inRange) do

		-- Current enemy's vector
		enemy_vector = humanoidRootPart.Position - inRange[x].HumanoidRootPart.Position

		-- Set default angle and enemy to compare to
		if x == 1 then

			min_angle_enemy = inRange[x]

			smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

			continue

		end

		-- Update angle and enemy if needed
		if math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude)) > smallest_angle then

			min_angle_enemy = inRange[x]

			smallest_angle = math.acos((player_vector:Dot(enemy_vector)) / (player_vector.Magnitude * enemy_vector.Magnitude))

		end

	end
	
	return min_angle_enemy
	
end


-- User presses button
local function button()

	-- User is not already targeting
	if not targeting then

		if uis:IsKeyDown(tab) then

			local inRange = getEnemiesInRange(workspace.Enemies:GetChildren())

			enemy = mostCenter(inRange)

			if enemy then

				createFocusPoint(enemy)

				initializeLock()

				lockOn(enemy)

			end

		end

		-- User is already targeting
	elseif targeting then

		-- User presses tab
		if uis:IsKeyDown(tab) then

			reset()

			-- User right clicks
		elseif uis:IsMouseButtonPressed(right_click) then

			local inRange = getEnemiesInRange(workspace.Enemies:GetChildren())

			if #inRange > 0 then

				enemy = switchTargets(inRange, enemy)

				specialReset()

				wait()

				createFocusPoint(enemy)

				initializeLock()

				lockOn(enemy)

			end

		end

	end

end


-- EVENTS

-- User right clicks
uis.InputBegan:Connect(button)
