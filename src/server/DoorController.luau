local TweenService = game:GetService("TweenService")

local DoorController = {}

local DOOR_MODEL_PATH = workspace:WaitForChild("DemoHouse")
local DOOR_PART_NAME = "Door"
local SENSOR_PART_NAME = "DoorSensor"
local OPEN_ANGLE_DEGREES = 90
local OPEN_DIRECTION = -1 -- rotate outward
local TWEEN_TIME = 0.8
local AUTO_CLOSE_DELAY = 3

local function getDoorParts()
	local door = DOOR_MODEL_PATH:FindFirstChild(DOOR_PART_NAME)
	local sensor = DOOR_MODEL_PATH:FindFirstChild(SENSOR_PART_NAME)
	assert(door and door:IsA("BasePart"), "Door part missing in DemoHouse")
	return door :: BasePart, sensor :: BasePart?
end

function DoorController.init()
	local door, sensor = getDoorParts()
	local hingeOffset = Vector3.new(-door.Size.X / 2, 0, 0)
	local closedCFrame = door.CFrame
	local openCFrame = closedCFrame * CFrame.new(hingeOffset) * CFrame.Angles(0, math.rad(OPEN_DIRECTION * OPEN_ANGLE_DEGREES), 0) * CFrame.new(-hingeOffset)

	local isOpen = false
	local isTweening = false
	local lastTouchTime = 0
	local closeTask: thread? = nil

	local function tweenDoor(targetCFrame)
		isTweening = true
		local tween = TweenService:Create(door, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = targetCFrame })
		tween:Play()
		tween.Completed:Once(function()
			isTweening = false
		end)
	end

	local function scheduleClose()
		if closeTask then
			task.cancel(closeTask)
		end
		closeTask = task.delay(AUTO_CLOSE_DELAY, function()
			if not isOpen then
				return
			end
			if os.clock() - lastTouchTime < AUTO_CLOSE_DELAY then
				scheduleClose()
				return
			end
			isOpen = false
			tweenDoor(closedCFrame)
			closeTask = nil
		end)
	end

	local function openDoor()
		if isOpen or isTweening then
			return
		end
		isOpen = true
		tweenDoor(openCFrame)
		scheduleClose()
	end

	local function onTouched(part)
		local character = part.Parent
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		lastTouchTime = os.clock()
		openDoor()
	end

	door.Touched:Connect(onTouched)
	if sensor then
		sensor.Touched:Connect(onTouched)
	end

	print("DoorController initialized")
end

return DoorController
