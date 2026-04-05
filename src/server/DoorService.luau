local AutoDoor = require(script.Parent:WaitForChild("AutoDoor"))

local DoorService = {}
DoorService.__index = DoorService

local registered: { [BasePart]: AutoDoor } = {}
local registeredCount = 0

local function isAutoDoor(part: Instance)
	return part:IsA("BasePart") and part:GetAttribute("AutoDoor") == true
end

local function tryRegister(part: Instance)
	if not isAutoDoor(part) then
		return
	end
	local basePart = part :: BasePart
	if registered[basePart] then
		return
	end
	local success, controller = pcall(AutoDoor.new, AutoDoor, basePart)
	if not success then
		warn("Failed to initialize auto door", basePart:GetFullName(), controller)
		return
	end
	registered[basePart] = controller
	registeredCount += 1
end

function DoorService.init()
	for _, desc in workspace:GetDescendants() do
		tryRegister(desc)
	end

	workspace.DescendantAdded:Connect(function(inst)
		tryRegister(inst)
	end)

	print(string.format("DoorService initialized (%d doors)", registeredCount))
end

return DoorService
