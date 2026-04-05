local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local ScreenGenerator = require(script.Parent.ScreenGenerator)

local MapBuilder = {}

local function clearBaseplate()
	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and child.Name == "Baseplate" then
			child:Destroy()
		end
	end
end

local function applySurfaceLight(part, color, brightness, range)
	local light = Instance.new("SurfaceLight")
	light.Color = color
	light.Brightness = brightness or 5
	light.Range = range or 32
	light.Face = Enum.NormalId.Top
	light.Parent = part
end

local function createPart(props, parent)
	local partClass = props.ClassName or "Part"
	local part = Instance.new(partClass)
	part.Anchored = true
	part.Name = props.Name or partClass
	part.Size = props.Size or Vector3.new(4, 1, 4)
	part.CFrame = props.CFrame or CFrame.new()
	part.Color = props.Color or Constants.Colors.Floor
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Transparency = props.Transparency or 0
	if props.Shape then
		part.Shape = props.Shape
	end
	part.Parent = parent
	if props.CanCollide ~= nil then
		part.CanCollide = props.CanCollide
	else
		part.CanCollide = true
	end
	if props.SurfaceLight then
		applySurfaceLight(part, props.SurfaceLight.Color, props.SurfaceLight.Brightness, props.SurfaceLight.Range)
	end
	if props.PointLight then
		local point = Instance.new("PointLight")
		point.Color = props.PointLight.Color
		point.Range = props.PointLight.Range or 25
		point.Brightness = props.PointLight.Brightness or 2
		point.Shadows = true
		point.Parent = part
	end
	return part
end

local function createCylinder(props, parent)
	props.ClassName = "Part"
	props.Shape = Enum.PartType.Cylinder
	local part = createPart(props, parent)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function createStep(stairModel, origin, width, height, depth, count)
	for i = 1, count do
		local step = createPart({
			Name = `Step_{i}`,
			Size = Vector3.new(width, height, depth),
			CFrame = origin * CFrame.new(0, (i - 1) * height, -(i - 1) * depth),
			Color = Constants.Colors.Floor,
		}, stairModel)
		step.Material = Enum.Material.SmoothPlastic
	end
end

local function addNeonTrim(part, thickness, color)
	local trim = Instance.new("SelectionBox")
	trim.Name = "NeonTrim"
	trim.LineThickness = thickness or 0.1
	trim.Color3 = color or Constants.Colors.NeonPrimary
	trim.Adornee = part
	trim.Parent = part
end

local function createRingLight(parent, position, radius)
	radius = radius or 10
	local ring = createPart({
		Name = "RingLight",
		Size = Vector3.new(radius, 0.4, radius),
		CFrame = CFrame.new(position),
		Color = Constants.Colors.NeonPrimary,
		Material = Enum.Material.Neon,
		CanCollide = false
	}, parent)
	return ring
end

local function createVehicle(parent)
	local model = Instance.new("Model")
	model.Name = "RefreshTruck"
	model.Parent = parent

	local body = createPart({
		Name = "Body",
		Size = Vector3.new(16, 5, 6),
		CFrame = CFrame.new(60, 2.5, 25),
		Color = Constants.Colors.Vehicle
	}, model)

	createPart({
		Name = "Cab",
		Size = Vector3.new(6, 4, 6),
		CFrame = body.CFrame * CFrame.new(-5, 2, 0),
		Color = Constants.Colors.Vehicle:Lerp(Color3.new(1, 1, 1), 0.2)
	}, model)

	createPart({
		Name = "Roof",
		Size = Vector3.new(16, 1, 6),
		CFrame = body.CFrame * CFrame.new(0, 3, 0),
		Color = Constants.Colors.Floor
	}, model)

	for _, offset in ipairs({Vector3.new(-6, -2.5, -2.5), Vector3.new(6, -2.5, -2.5), Vector3.new(-6, -2.5, 2.5), Vector3.new(6, -2.5, 2.5)}) do
		local wheel = createPart({
			Name = "Wheel",
			Size = Vector3.new(1.2, 3, 3),
			CFrame = body.CFrame * CFrame.new(offset),
			Color = Color3.fromRGB(40, 40, 40),
		}, model)
		wheel.Shape = Enum.PartType.Cylinder
	end

	return model
end

local function createKiosk(parent, position)
	local kiosk = Instance.new("Model")
	kiosk.Name = "Kiosk"
	kiosk.Parent = parent

	local base = createCylinder({
		Name = "Base",
		Size = Vector3.new(3, 16, 16),
		CFrame = CFrame.new(position),
		Color = Constants.Colors.Kiosk,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true
	}, kiosk)
	base.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))

	createPart({
		Name = "Table",
		Size = Vector3.new(12, 1, 12),
		CFrame = CFrame.new(position + Vector3.new(0, 4, 0)),
		Color = Constants.Colors.Floor
	}, kiosk)

	local screen = createPart({
		Name = "Console",
		Size = Vector3.new(6, 4, 0.5),
		CFrame = CFrame.new(position + Vector3.new(0, 6, -3)),
		Color = Constants.Colors.ScreenBackground,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false
	}, kiosk)
	ScreenGenerator.decorate(screen, math.random())

	return kiosk
end

function MapBuilder.build()
	clearBaseplate()

	local existing = workspace:FindFirstChild(Constants.HubName)
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Model")
	hub.Name = Constants.HubName
	hub.Parent = workspace

	local navPoints: { Vector3 } = {}

	local floor = createPart({
		Name = "Floor",
		Size = Constants.Dimensions.FloorSize,
		CFrame = CFrame.new(0, Constants.Dimensions.CenterY, 0),
		Color = Constants.Colors.Floor
	}, hub)

	createPart({
		Name = "Border",
		Size = Constants.Dimensions.FloorSize + Vector3.new(6, 0.4, 6),
		CFrame = floor.CFrame + Vector3.new(0, 0.6, 0),
		Color = Constants.Colors.Border,
		Material = Enum.Material.SmoothPlastic
	}, hub)

	local stem = createPart({
		Name = "KeyStem",
		Size = Vector3.new(8, 0.2, 110),
		CFrame = CFrame.new(0, 1.4, 0),
		Color = Constants.Colors.NeonPrimary,
		Material = Enum.Material.Neon,
		SurfaceLight = { Color = Constants.Colors.NeonPrimary, Brightness = 5, Range = 48 }
	}, hub)

	local head = createCylinder({
		Name = "KeyHead",
		Size = Vector3.new(0.4, 20, 20),
		CFrame = CFrame.new(0, 1.45, -42) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Constants.Colors.NeonPrimary,
		Material = Enum.Material.Neon
	}, hub)

	local stageModel = Instance.new("Model")
	stageModel.Name = "Stage"
	stageModel.Parent = hub

	local stageBase = createPart({
		Name = "StageBase",
		Size = Vector3.new(40, 5, 20),
		CFrame = CFrame.new(Constants.Dimensions.StagePosition),
		Color = Constants.Colors.Kiosk
	}, stageModel)

	createPart({
		Name = "StageTier2",
		Size = Vector3.new(32, 4, 14),
		CFrame = stageBase.CFrame * CFrame.new(0, 2.2, -2),
		Color = Constants.Colors.Vehicle:Lerp(Constants.Colors.Floor, 0.3)
	}, stageModel)

	createPart({
		Name = "StageTier3",
		Size = Vector3.new(20, 3, 10),
		CFrame = stageBase.CFrame * CFrame.new(0, 4.2, -4),
		Color = Constants.Colors.NeonSecondary:Lerp(Constants.Colors.Floor, 0.5)
	}, stageModel)

	local podium = createPart({
		Name = "Podium",
		Size = Vector3.new(6, 3, 6),
		CFrame = stageBase.CFrame * CFrame.new(0, 5.3, -4),
		Color = Constants.Colors.Floor
	}, stageModel)
	addNeonTrim(podium, 0.01, Constants.Colors.NeonPrimary)

	local frame = createPart({
		Name = "BackdropFrame",
		Size = Vector3.new(34, 16, 1),
		CFrame = stageBase.CFrame * CFrame.new(0, 12, -15),
		Color = Constants.Colors.NeonSecondary,
		Material = Enum.Material.Neon
	}, stageModel)

	local frameInner = createPart({
		Name = "BackdropInner",
		Size = Vector3.new(28, 12, 0.6),
		CFrame = frame.CFrame * CFrame.new(0, 0, -0.6),
		Color = Constants.Colors.WallLight
	}, stageModel)

	local circle = createCylinder({
		Name = "BackdropCircle",
		Size = Vector3.new(1, 12, 12),
		CFrame = frame.CFrame * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Constants.Colors.NeonPrimary,
		Material = Enum.Material.Neon,
		CanCollide = false
	}, stageModel)

	local screenMain = createPart({
		Name = "MainScreen",
		Size = Vector3.new(30, 16, 1.2),
		CFrame = frameInner.CFrame * CFrame.new(0, 0, -1),
		Color = Constants.Colors.ScreenBackground
	}, stageModel)
	ScreenGenerator.decorate(screenMain, 1.23)

	for _, offset in ipairs({Vector3.new(-18, 0, 0), Vector3.new(18, 0, 0)}) do
		local pillar = createPart({
			Name = "StagePillar",
			Size = Vector3.new(3, 12, 3),
			CFrame = stageBase.CFrame * CFrame.new(offset.X, 6, -8),
			Color = Constants.Colors.Floor
		}, stageModel)
		applySurfaceLight(pillar, Constants.Colors.NeonPrimary, 4, 20)
	end

	local function createScreen(position, orientation)
		local panel = createPart({
			Name = "Billboard",
			Size = Vector3.new(26, 14, 1),
			CFrame = CFrame.new(position) * orientation,
			Color = Constants.Colors.ScreenBackground
		}, hub)
		ScreenGenerator.decorate(panel, math.random())
		return panel
	end

	createScreen(Vector3.new(-70, 20, -20), CFrame.Angles(0, math.rad(90), 0))
	createScreen(Vector3.new(70, 20, -20), CFrame.Angles(0, -math.rad(90), 0))
	createScreen(Vector3.new(-50, 15, 35), CFrame.new())
	createScreen(Vector3.new(50, 15, 35), CFrame.new())

	local function addRunwayArm(direction)
		local axis = direction.X ~= 0 and "X" or "Z"
		local distance = Constants.Dimensions.RunwayArmLength
		local position = Vector3.new(direction.X * distance, 2.3, direction.Z * distance)
		local size = Vector3.new(
			direction.Z == 0 and 40 or 8,
			4,
			direction.X == 0 and 40 or 8
		)
		createPart({
			Name = `RunwayArm_{axis}`,
			Size = size,
			CFrame = CFrame.new(position),
			Color = Constants.Colors.Floor,
			SurfaceLight = { Color = Constants.Colors.NeonPrimary, Brightness = 4, Range = 32 }
		}, hub)
	end

	addRunwayArm(Vector3.new(1, 0, 0))
	addRunwayArm(Vector3.new(-1, 0, 0))
	addRunwayArm(Vector3.new(0, 0, 1))
	addRunwayArm(Vector3.new(0, 0, -1))

	local stairs = Instance.new("Model")
	stairs.Name = "GrandStairs"
	stairs.Parent = hub

	createStep(stairs, CFrame.new(-35, 0.6, -40), 12, 0.8, 3.2, 12)
	createStep(stairs, CFrame.new(35, 0.6, -40), 12, 0.8, 3.2, 12)

	local balconys = Instance.new("Model")
	balconys.Name = "Balconies"
	balconys.Parent = hub

	createPart({
		Name = "LeftBalcony",
		Size = Vector3.new(50, 3, 80),
		CFrame = CFrame.new(-70, Constants.Dimensions.BalconyHeight, -15),
		Color = Constants.Colors.Floor
	}, balconys)
	createPart({
		Name = "RightBalcony",
		Size = Vector3.new(50, 3, 80),
		CFrame = CFrame.new(70, Constants.Dimensions.BalconyHeight, -15),
		Color = Constants.Colors.Floor
	}, balconys)

	local ringFolder = Instance.new("Folder")
	ringFolder.Name = "RingLights"
	ringFolder.Parent = hub

	createRingLight(ringFolder, Vector3.new(0, 1.8, 60), 16)
	createRingLight(ringFolder, Vector3.new(0, 1.8, -70), 18)
	createRingLight(ringFolder, Vector3.new(60, 1.8, 0), 14)
	createRingLight(ringFolder, Vector3.new(-60, 1.8, 0), 14)

	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = hub

	local kioskLeft = createKiosk(props, Vector3.new(-25, 1.5, 8))
	local kioskRight = createKiosk(props, Vector3.new(25, 1.5, 8))

	createVehicle(props)

	for _, anchor in ipairs({
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, -30),
		Vector3.new(18, 0, -5),
		Vector3.new(-18, 0, -5),
		Vector3.new(35, 0, 18),
		Vector3.new(-35, 0, 18),
		Vector3.new(50, 0, -18),
		Vector3.new(-50, 0, -18)
	}) do
		table.insert(navPoints, anchor + Vector3.new(0, 3, 0))
	end

	return {
		hub = hub,
		navPoints = navPoints,
		floor = floor,
		stage = stageBase
	}
end

return MapBuilder
