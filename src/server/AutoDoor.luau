local TweenService = game:GetService("TweenService")

export type AutoDoor = {
	door: BasePart,
	sensor: BasePart?,
	isOpen: boolean,
	isTweening: boolean,
	lastTouchTime: number,
	closeTask: thread?,
	closedCFrame: CFrame,
	openCFrame: CFrame,
	autoCloseDelay: number,
}

local AutoDoor = {}
AutoDoor.__index = AutoDoor

local DEFAULT_SENSOR_NAME = "DoorSensor"

local function getPivotCFrame(door: BasePart, hingeSide: number)
	local hingeOffsetWorld = door.CFrame.RightVector * hingeSide * (door.Size.X / 2)
	local hingePosition = door.Position + hingeOffsetWorld
	return CFrame.new(hingePosition)
end

function AutoDoor.new(doorPart: BasePart)
	local sensorName = doorPart:GetAttribute("DoorSensorName") or DEFAULT_SENSOR_NAME
	local sensor = doorPart.Parent and doorPart.Parent:FindFirstChild(sensorName)
	if sensor and not sensor:IsA("BasePart") then
		sensor = nil
	end

	local openAngle = doorPart:GetAttribute("OpenAngle") or 90
	local openDirection = doorPart:GetAttribute("OpenDirection") or -1
	local hingeSide = doorPart:GetAttribute("HingeSide") or -1
	local autoCloseDelay = doorPart:GetAttribute("AutoCloseDelay") or 3

	local closedCFrame = doorPart.CFrame
	local pivot = getPivotCFrame(doorPart, hingeSide)
	local rotation = CFrame.Angles(0, math.rad(openDirection * openAngle), 0)
	local openCFrame = (pivot * rotation * pivot:Inverse()) * closedCFrame

	local self: AutoDoor = setmetatable({
		door = doorPart,
		sensor = sensor and sensor :: BasePart,
		isOpen = false,
		isTweening = false,
		lastTouchTime = 0,
		closeTask = nil,
		closedCFrame = closedCFrame,
		openCFrame = openCFrame,
		autoCloseDelay = autoCloseDelay,
	}, AutoDoor)

	self:bind()
	return self
end

function AutoDoor:bind()
	local doorConnection = self.door.Touched:Connect(function(hit)
		self:onTouched(hit)
	end)

	if self.sensor then
		self.sensor.Touched:Connect(function(hit)
			self:onTouched(hit)
		end)
	end

	self._doorConnection = doorConnection
end

function AutoDoor:onTouched(hit: BasePart)
	local character = hit.Parent
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	self.lastTouchTime = os.clock()
	self:open()
end

function AutoDoor:open()
	if self.isOpen or self.isTweening then
		return
	end
	self.isOpen = true
	self:tweenTo(self.openCFrame)
	self:scheduleClose()
end

function AutoDoor:scheduleClose()
	if self.closeTask then
		task.cancel(self.closeTask)
		self.closeTask = nil
	end
	self.closeTask = task.delay(self.autoCloseDelay, function()
		if os.clock() - self.lastTouchTime < self.autoCloseDelay then
			self:scheduleClose()
			return
		end
		self:close()
		self.closeTask = nil
	end)
end

function AutoDoor:close()
	if not self.isOpen or self.isTweening then
		return
	end
	self.isOpen = false
	self:tweenTo(self.closedCFrame)
	if self.closeTask then
		task.cancel(self.closeTask)
		self.closeTask = nil
	end
end

function AutoDoor:tweenTo(target: CFrame)
	self.isTweening = true
	local tween = TweenService:Create(self.door, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = target })
	tween.Completed:Once(function()
		self.isTweening = false
	end)
	tween:Play()
end

return AutoDoor
