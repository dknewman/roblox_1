--[[
	MapBuilder - Procedurally constructs the Social Spotlight Plaza
	Reference image analysis:
	  - Two grand staircases flank the stage, going UP+BACK to upper balconies
	  - Balconies wrap LEFT, BACK, and RIGHT at Y=24
	  - Screens mounted on stage towers and staircase walls, NOT far side walls
	  - Soft lavender/purple ambient — neon accents glow but don't wash out
	  - Keyhole floor design with gentle lavender glow
	  - "SOCIAL SPOTLIGHT PLAZA" stacked 3-line sign at top center
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local ScreenGenerator = require(script.Parent.ScreenGenerator)
local FirebaseLogger = require(script.Parent.FirebaseLogger)

local MapBuilder = {}

local C = Constants.Colors
local D = Constants.Dimensions

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function makePart(props, parent)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.Name = props.Name or "Part"
	part.Size = props.Size or Vector3.new(4, 1, 4)
	if props.CFrame then
		part.CFrame = props.CFrame
	elseif props.Position then
		part.CFrame = CFrame.new(props.Position)
	end
	part.Color = props.Color or C.Floor
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Transparency = props.Transparency or 0
	part.CanCollide = props.CanCollide ~= false
	part.CastShadow = props.CastShadow ~= false
	if props.Shape then
		part.Shape = props.Shape
	end
	part.Parent = parent
	return part
end

local function makeNeon(props, parent)
	props.Material = Enum.Material.Neon
	return makePart(props, parent)
end

local function makeCylinder(props, parent)
	props.Shape = Enum.PartType.Cylinder
	return makePart(props, parent)
end

local function makeWedge(props, parent)
	props.ClassName = "WedgePart"
	return makePart(props, parent)
end

local function addPointLight(part, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color or C.NeonPink
	light.Brightness = brightness or 0.4
	light.Range = range or 12
	light.Shadows = false
	light.Parent = part
end

local function addSurfaceLight(part, color, brightness, range, face)
	local light = Instance.new("SurfaceLight")
	light.Color = color or C.NeonPink
	light.Brightness = brightness or 0.5
	light.Range = range or 10
	light.Face = face or Enum.NormalId.Top
	light.Shadows = false
	light.Parent = part
end

local function addSpotLight(part, color, brightness, range, angle, face)
	local light = Instance.new("SpotLight")
	light.Color = color or C.NeonPink
	light.Brightness = brightness or 1.5
	light.Range = range or 30
	light.Angle = angle or 45
	light.Face = face or Enum.NormalId.Bottom
	light.Shadows = true
	light.Parent = part
end

local function addTextGui(part, text, textColor, bgColor, textSize, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = bgColor and 0 or 1
	label.BackgroundColor3 = bgColor or Color3.new(0, 0, 0)
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return gui
end

--------------------------------------------------------------------------------
-- PHASE 1: FOUNDATION
--------------------------------------------------------------------------------

local function buildFoundation(hub)
	local foundation = Instance.new("Model")
	foundation.Name = "Foundation"
	foundation.Parent = hub

	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(220, 1, 220),
		Position = Vector3.new(0, 0.5, 0),
		Color = C.Floor,
	}, foundation)

	-- Subtle floor grid
	for i = -100, 100, 20 do
		makePart({
			Name = "GridX",
			Size = Vector3.new(220, 0.05, 0.3),
			Position = Vector3.new(0, 1.03, i),
			Color = C.FloorGrid,
			CanCollide = false, CastShadow = false,
		}, foundation)
		makePart({
			Name = "GridZ",
			Size = Vector3.new(0.3, 0.05, 220),
			Position = Vector3.new(i, 1.03, 0),
			Color = C.FloorGrid,
			CanCollide = false, CastShadow = false,
		}, foundation)
	end

	-- Walls
	makePart({ Name = "WallBack", Size = Vector3.new(220, D.WallHeight, 3), Position = Vector3.new(0, D.WallHeight / 2, -110), Color = C.WallPrimary }, foundation)
	makePart({ Name = "WallLeft", Size = Vector3.new(3, D.WallHeight, 220), Position = Vector3.new(-110, D.WallHeight / 2, 0), Color = C.WallPrimary }, foundation)
	makePart({ Name = "WallRight", Size = Vector3.new(3, D.WallHeight, 220), Position = Vector3.new(110, D.WallHeight / 2, 0), Color = C.WallPrimary }, foundation)
	makePart({ Name = "WallFrontL", Size = Vector3.new(80, D.WallHeight, 3), Position = Vector3.new(-70, D.WallHeight / 2, 110), Color = C.WallPrimary }, foundation)
	makePart({ Name = "WallFrontR", Size = Vector3.new(80, D.WallHeight, 3), Position = Vector3.new(70, D.WallHeight / 2, 110), Color = C.WallPrimary }, foundation)
	makePart({ Name = "WallFrontTop", Size = Vector3.new(60, 14, 3), Position = Vector3.new(0, D.WallHeight - 7, 110), Color = C.WallPrimary }, foundation)

	-- Ceiling
	makePart({ Name = "Ceiling", Size = Vector3.new(220, 1, 220), Position = Vector3.new(0, D.CeilingHeight, 0), Color = C.Ceiling }, foundation)

	-- Floor-edge neon strips (dim)
	for _, cfg in ipairs({
		{Vector3.new(0, 1.15, 108.5), Vector3.new(218, 0.3, 0.5)},
		{Vector3.new(0, 1.15, -108.5), Vector3.new(218, 0.3, 0.5)},
		{Vector3.new(-108.5, 1.15, 0), Vector3.new(0.5, 0.3, 218)},
		{Vector3.new(108.5, 1.15, 0), Vector3.new(0.5, 0.3, 218)},
	}) do
		makeNeon({ Name = "FloorBorderNeon", Size = cfg[2], Position = cfg[1], Color = C.NeonPink, CanCollide = false }, foundation)
	end

	return floor
end

--------------------------------------------------------------------------------
-- PHASE 2: KEYHOLE FLOOR DESIGN
--------------------------------------------------------------------------------

local function buildKeyhole(hub)
	local keyhole = Instance.new("Model")
	keyhole.Name = "KeyholeDesign"
	keyhole.Parent = hub

	local nY = 1.15
	local thick = 0.6
	local stemW = 10
	local stemFrontZ = 58
	local stemBackZ = -28
	local stemLen = stemFrontZ - stemBackZ
	local stemCenterZ = (stemFrontZ + stemBackZ) / 2

	-- Stem edges
	makeNeon({ Name = "KeyStemL", Size = Vector3.new(thick, 0.2, stemLen), Position = Vector3.new(-stemW / 2, nY, stemCenterZ), Color = C.NeonWhite, CanCollide = false }, keyhole)
	makeNeon({ Name = "KeyStemR", Size = Vector3.new(thick, 0.2, stemLen), Position = Vector3.new(stemW / 2, nY, stemCenterZ), Color = C.NeonWhite, CanCollide = false }, keyhole)
	makeNeon({ Name = "KeyStemFront", Size = Vector3.new(stemW + thick, 0.2, thick), Position = Vector3.new(0, nY, stemFrontZ), Color = C.NeonWhite, CanCollide = false }, keyhole)
	makeNeon({ Name = "KeyBridge", Size = Vector3.new(stemW + thick, 0.2, thick), Position = Vector3.new(0, nY, stemBackZ), Color = C.NeonWhite, CanCollide = false }, keyhole)

	-- Circle head (ring = outer disc + inner mask)
	local circR = 16
	local circZ = stemBackZ - circR + 2

	makeCylinder({ Name = "KeyCircleOuter", Size = Vector3.new(0.25, circR * 2, circR * 2),
		CFrame = CFrame.new(0, nY, circZ) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.NeonWhite, Material = Enum.Material.Neon, CanCollide = false }, keyhole)
	makeCylinder({ Name = "KeyCircleInner", Size = Vector3.new(0.3, (circR - 2.5) * 2, (circR - 2.5) * 2),
		CFrame = CFrame.new(0, nY + 0.05, circZ) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Floor, CanCollide = false }, keyhole)

	-- Cross inside circle
	makeNeon({ Name = "CircleCrossH", Size = Vector3.new(circR * 2 - 4, 0.15, thick * 0.7), Position = Vector3.new(0, nY + 0.08, circZ), Color = C.NeonPurple, CanCollide = false }, keyhole)
	makeNeon({ Name = "CircleCrossV", Size = Vector3.new(thick * 0.7, 0.15, circR * 2 - 4), Position = Vector3.new(0, nY + 0.08, circZ), Color = C.NeonPurple, CanCollide = false }, keyhole)
end

--------------------------------------------------------------------------------
-- PHASE 3: STAGE & BACK WALL
--------------------------------------------------------------------------------

local function buildStage(hub)
	local stage = Instance.new("Model")
	stage.Name = "Stage"
	stage.Parent = hub

	local sz = D.StageZ -- -76

	-- Base tier
	local stageBase = makePart({ Name = "StageBase", Size = Vector3.new(60, 4, 26), Position = Vector3.new(0, 2, sz), Color = C.StagePink }, stage)

	-- Front approach steps
	for i = 1, 3 do
		makePart({ Name = `StageStep_{i}`, Size = Vector3.new(40 + (3 - i) * 8, 1, 2.5),
			Position = Vector3.new(0, i * 0.8, sz + 13 + (3 - i) * 2.5), Color = C.StagePink:Lerp(C.Floor, (3 - i) * 0.2) }, stage)
	end

	-- Neon front edge
	makeNeon({ Name = "StageNeonFront", Size = Vector3.new(60, 0.4, 0.4), Position = Vector3.new(0, 4.2, sz + 13), Color = C.NeonPink, CanCollide = false }, stage)

	-- Tier 2
	makePart({ Name = "StageTier2", Size = Vector3.new(46, 3.5, 18), Position = Vector3.new(0, 5.75, sz - 3), Color = C.StageHotPink }, stage)
	makeNeon({ Name = "Tier2Neon", Size = Vector3.new(46, 0.3, 0.3), Position = Vector3.new(0, 7.6, sz + 6), Color = C.NeonCyan, CanCollide = false }, stage)

	-- Top performance platform
	makePart({ Name = "StageTop", Size = Vector3.new(32, 2.5, 12), Position = Vector3.new(0, 8.75, sz - 6), Color = C.StagePink:Lerp(Color3.new(1, 1, 1), 0.35) }, stage)
	makeNeon({ Name = "TopNeon", Size = Vector3.new(32, 0.3, 0.3), Position = Vector3.new(0, 10.1, sz), Color = C.NeonPink, CanCollide = false }, stage)

	-- Back wall panel (large pink structure)
	local panelZ = sz - 20
	makePart({ Name = "BackPanel", Size = Vector3.new(72, 36, 4), Position = Vector3.new(0, 22, panelZ), Color = C.StagePink }, stage)

	-- Side towers flanking back panel
	for _, side in ipairs({-1, 1}) do
		local px = side * 40
		local tag = side > 0 and "R" or "L"
		makePart({ Name = `BackTower_{tag}`, Size = Vector3.new(10, 36, 14), Position = Vector3.new(px, 22, panelZ + 3), Color = C.WallSecondary }, stage)
		makePart({ Name = `TowerPanel_{tag}`, Size = Vector3.new(6, 28, 1), Position = Vector3.new(px, 20, panelZ - 2.5), Color = C.WallPrimary }, stage)
		makeNeon({ Name = `TowerNeon_{tag}`, Size = Vector3.new(0.4, 32, 0.4), Position = Vector3.new(px - side * 5.2, 22, panelZ - 0.5), Color = C.NeonPink, CanCollide = false }, stage)
		-- Small vertical light accent
		makeNeon({ Name = `StageLightPanel_{tag}`, Size = Vector3.new(1, 8, 0.5), Position = Vector3.new(side * 22, 10, sz - 8), Color = C.NeonCyan, CanCollide = false }, stage)
	end

	-- Portal circle (decorative round window)
	local portalY = 33
	local portalZ = panelZ - 2
	local portalR = 8

	makeCylinder({ Name = "PortalCircle", Size = Vector3.new(1.2, portalR * 2, portalR * 2),
		CFrame = CFrame.new(0, portalY, portalZ) * CFrame.Angles(0, math.rad(90), 0), Color = C.CircleDark }, stage)
	makePart({ Name = "PortalCrossH", Size = Vector3.new(portalR * 2 - 2, 1.4, 1.5), Position = Vector3.new(0, portalY, portalZ - 0.8), Color = C.CircleDivider }, stage)
	makePart({ Name = "PortalCrossV", Size = Vector3.new(1.4, portalR * 2 - 2, 1.5), Position = Vector3.new(0, portalY, portalZ - 0.8), Color = C.CircleDivider }, stage)

	-- Neon ring around portal
	for i = 1, 24 do
		local a = (i / 24) * math.pi * 2
		local midA = a + math.pi / 24
		local segLen = 2 * (portalR + 0.6) * math.sin(math.pi / 24)
		makeNeon({ Name = `PortalRing_{i}`, Size = Vector3.new(segLen + 0.15, 0.5, 0.5),
			CFrame = CFrame.new(math.cos(midA) * (portalR + 0.6), portalY + math.sin(midA) * (portalR + 0.6), portalZ - 1.3) * CFrame.Angles(0, 0, midA),
			Color = C.NeonPurple, CanCollide = false }, stage)
	end

	-- Main screen
	local mainScreen = makePart({ Name = "MainScreen", Size = Vector3.new(30, 16, 1.2), Position = Vector3.new(0, 19, panelZ - 3), Color = C.ScreenFrame }, stage)
	ScreenGenerator.decorate(mainScreen, 1)

	-- Main screen neon frame
	for _, e in ipairs({
		{Vector3.new(0, 27.3, panelZ - 3.5), Vector3.new(32, 0.4, 0.4)},
		{Vector3.new(0, 10.7, panelZ - 3.5), Vector3.new(32, 0.4, 0.4)},
		{Vector3.new(-15.3, 19, panelZ - 3.5), Vector3.new(0.4, 16, 0.4)},
		{Vector3.new(15.3, 19, panelZ - 3.5), Vector3.new(0.4, 16, 0.4)},
	}) do
		makeNeon({ Name = "ScreenNeon", Size = e[2], Position = e[1], Color = C.NeonCyan, CanCollide = false }, stage)
	end

	-- Stage spotlights (ceiling-mounted, modest brightness)
	for _, sx in ipairs({-14, 0, 14}) do
		local mount = makePart({ Name = "SpotMount", Size = Vector3.new(2.5, 2.5, 2.5), Position = Vector3.new(sx, D.CeilingHeight - 2, sz), Color = C.RailMetal, CanCollide = false }, stage)
		addSpotLight(mount, C.NeonPink, 1.5, 35, 35)
	end

	return stageBase
end

--------------------------------------------------------------------------------
-- PHASE 4: GRAND STAIRCASES
-- Positioned to flank the stage and connect to balconies.
-- Left stair: X center=-55, width=18, inner edge at X=-46
-- Right stair: mirror
-- Bottom at Z=-18, Y=1 → Top at Z=-66, Y=24
--------------------------------------------------------------------------------

local function buildStaircases(hub)
	local stairs = Instance.new("Model")
	stairs.Name = "GrandStairs"
	stairs.Parent = hub

	local stairWidth = 18
	local stepCount = 16
	local stepH = 1.5
	local stepD = 3.0

	for _, side in ipairs({-1, 1}) do
		local stairModel = Instance.new("Model")
		stairModel.Name = side > 0 and "StairRight" or "StairLeft"
		stairModel.Parent = stairs

		local stairX = side * 55
		local startZ = -18
		local rampH = stepCount * stepH -- 24
		local rampD = stepCount * stepD -- 48
		local topZ = startZ - rampD      -- -66

		-- Solid body under steps
		makePart({ Name = "StairBody", Size = Vector3.new(stairWidth + 2, rampH, rampD),
			Position = Vector3.new(stairX, rampH / 2, startZ - rampD / 2), Color = C.StairRiser }, stairModel)

		-- Outer wall of staircase (visible from center)
		local innerX = stairX + (-side) * (stairWidth / 2 + 1)
		makePart({ Name = "StairInnerWall", Size = Vector3.new(1.5, rampH + 4, rampD + 2),
			Position = Vector3.new(innerX, rampH / 2 + 2, startZ - rampD / 2), Color = C.WallSecondary }, stairModel)

		-- Individual step treads
		for i = 1, stepCount do
			makePart({ Name = `Step_{i}`, Size = Vector3.new(stairWidth, 0.5, stepD),
				Position = Vector3.new(stairX, (i - 0.25) * stepH, startZ - (i - 0.5) * stepD),
				Color = C.StairTread }, stairModel)
		end

		-- Railing posts + continuous handrail on both edges
		for _, railSide in ipairs({-1, 1}) do
			local railX = stairX + railSide * (stairWidth / 2 + 1.2)
			local tag = railSide > 0 and "O" or "I"

			for i = 1, stepCount, 3 do
				makePart({ Name = `Post_{tag}_{i}`, Size = Vector3.new(0.5, 4, 0.5),
					Position = Vector3.new(railX, i * stepH + 2, startZ - (i - 0.5) * stepD),
					Color = C.RailMetal }, stairModel)
			end

			local barLen = math.sqrt(rampH * rampH + rampD * rampD)
			local barAng = math.atan2(rampH, rampD)
			makePart({ Name = `Handrail_{tag}`, Size = Vector3.new(1, 1, barLen),
				CFrame = CFrame.new(railX, rampH / 2 + 3.2, startZ - rampD / 2) * CFrame.Angles(barAng, 0, 0),
				Color = C.RailMetal }, stairModel)

			-- Neon accent under handrail
			makeNeon({ Name = `RailNeon_{tag}`, Size = Vector3.new(0.3, 0.3, barLen),
				CFrame = CFrame.new(railX, rampH / 2 + 2.2, startZ - rampD / 2) * CFrame.Angles(barAng, 0, 0),
				Color = C.NeonPink, CanCollide = false }, stairModel)
		end

		-- Bottom neon edge
		makeNeon({ Name = "StairNeonEdge", Size = Vector3.new(stairWidth + 2, 0.3, 0.3),
			Position = Vector3.new(stairX, 1.2, startZ + 0.5), Color = C.NeonPink, CanCollide = false }, stairModel)

		-- Screen mounted on stair inner wall (faces toward center)
		local screenX = innerX + (-side) * 1
		local screenFrame = makePart({ Name = `StairScreen_${side > 0 and "R" or "L"}`,
			Size = Vector3.new(16, 12, 1),
			CFrame = CFrame.new(screenX, 14, startZ - rampD * 0.35) * CFrame.Angles(0, side * math.rad(90), 0),
			Color = C.ScreenFrame }, stairModel)
		ScreenGenerator.decorate(screenFrame, 10 + side)
	end
end

--------------------------------------------------------------------------------
-- PHASE 5: BALCONIES & UPPER LEVEL
-- Inner edges at X=±46 align with staircase inner edges.
-- Back balcony bridges above the stage structure.
--------------------------------------------------------------------------------

local function buildBalconies(hub)
	local balconies = Instance.new("Model")
	balconies.Name = "Balconies"
	balconies.Parent = hub

	local balcY = D.BalconyHeight -- 24
	local innerX = 46
	local railH = 4

	-- Left platform
	makePart({ Name = "BalconyLeft", Size = Vector3.new(110 - innerX, 2, 90),
		Position = Vector3.new(-(innerX + (110 - innerX) / 2), balcY, -22), Color = C.Floor }, balconies)

	-- Right platform
	makePart({ Name = "BalconyRight", Size = Vector3.new(110 - innerX, 2, 90),
		Position = Vector3.new(innerX + (110 - innerX) / 2, balcY, -22), Color = C.Floor }, balconies)

	-- Back balcony (connecting, above stage)
	makePart({ Name = "BalconyBack", Size = Vector3.new(innerX * 2, 2, 24),
		Position = Vector3.new(0, balcY + 6, -97), Color = C.Floor }, balconies)

	-- Glass railings on inner edges
	for _, side in ipairs({-1, 1}) do
		local rx = side * innerX
		-- Long railing along inner edge
		makePart({ Name = `RailGlass_{side > 0 and "R" or "L"}`, Size = Vector3.new(1, railH, 90),
			Position = Vector3.new(rx, balcY + railH / 2 + 1, -22), Color = C.RailGlass, Transparency = 0.5 }, balconies)
		makeNeon({ Name = `RailNeonTop_{side > 0 and "R" or "L"}`, Size = Vector3.new(0.4, 0.4, 90),
			Position = Vector3.new(rx, balcY + railH + 1.2, -22), Color = C.NeonPink, CanCollide = false }, balconies)

		-- Front edge railing
		local bCenterX = side * (innerX + (110 - innerX) / 2)
		local bWidth = 110 - innerX
		makePart({ Name = `RailFront_{side > 0 and "R" or "L"}`, Size = Vector3.new(bWidth, railH, 1),
			Position = Vector3.new(bCenterX, balcY + railH / 2 + 1, 23), Color = C.RailGlass, Transparency = 0.5 }, balconies)
		makeNeon({ Name = `RailFrontNeon_{side > 0 and "R" or "L"}`, Size = Vector3.new(bWidth, 0.4, 0.4),
			Position = Vector3.new(bCenterX, balcY + railH + 1.2, 23), Color = C.NeonPink, CanCollide = false }, balconies)
	end

	-- Balcony underside neon glow (very subtle)
	for _, cfg in ipairs({
		{Vector3.new(-78, balcY - 0.5, 23), Vector3.new(64, 0.3, 0.3)},
		{Vector3.new(78, balcY - 0.5, 23), Vector3.new(64, 0.3, 0.3)},
		{Vector3.new(-innerX, balcY - 0.5, -22), Vector3.new(0.3, 0.3, 90)},
		{Vector3.new(innerX, balcY - 0.5, -22), Vector3.new(0.3, 0.3, 90)},
	}) do
		makeNeon({ Name = "BalcNeon", Size = cfg[2], Position = cfg[1], Color = C.NeonPurple, CanCollide = false }, balconies)
	end

	-- Support columns
	for _, side in ipairs({-1, 1}) do
		for _, zp in ipairs({-55, -22, 10}) do
			makePart({ Name = "BalcColumn", Size = Vector3.new(3, balcY, 3),
				Position = Vector3.new(side * (innerX + 4), balcY / 2, zp), Color = C.WallSecondary }, balconies)
		end
	end

	-- Upper level equipment (cameras / speakers near ceiling above stairs)
	for _, side in ipairs({-1, 1}) do
		makePart({ Name = `UpperEquip_${side > 0 and "R" or "L"}`, Size = Vector3.new(3, 2, 3),
			Position = Vector3.new(side * 55, D.CeilingHeight - 3, -40), Color = C.RailMetal, CanCollide = false }, balconies)
	end
end

--------------------------------------------------------------------------------
-- PHASE 6: SCREENS (mounted on stage towers + upper back wall)
--------------------------------------------------------------------------------

local function buildScreens(hub)
	local screens = Instance.new("Model")
	screens.Name = "BillboardScreens"
	screens.Parent = hub

	local screenConfigs = {
		-- Flanking the stage back panel (angled toward crowd)
		{pos = Vector3.new(-34, 17, -90), rot = CFrame.Angles(0, math.rad(28), 0), sz = Vector3.new(20, 14, 1)},
		{pos = Vector3.new(34, 17, -90), rot = CFrame.Angles(0, -math.rad(28), 0), sz = Vector3.new(20, 14, 1)},
		-- Upper back wall (flanking sign)
		{pos = Vector3.new(-38, 33, -107), rot = CFrame.new(), sz = Vector3.new(16, 10, 1)},
		{pos = Vector3.new(38, 33, -107), rot = CFrame.new(), sz = Vector3.new(16, 10, 1)},
	}

	for idx, cfg in ipairs(screenConfigs) do
		makePart({ Name = `ScreenFrame_{idx}`, Size = cfg.sz + Vector3.new(4, 3, 0.6),
			CFrame = CFrame.new(cfg.pos) * cfg.rot, Color = C.ScreenFrame }, screens)
		local panel = makePart({ Name = `ScreenPanel_{idx}`, Size = cfg.sz,
			CFrame = CFrame.new(cfg.pos) * cfg.rot * CFrame.new(0, 0, -0.9), Color = C.ScreenCyan }, screens)
		ScreenGenerator.decorate(panel, idx * 3.14)
	end
end

--------------------------------------------------------------------------------
-- PHASE 7: SIDE PROPS
--------------------------------------------------------------------------------

local function buildProps(hub)
	local props = Instance.new("Model")
	props.Name = "Props"
	props.Parent = hub

	-- ARCADE STATION (left)
	local arcade = Instance.new("Model"); arcade.Name = "ArcadeStation"; arcade.Parent = props
	makeCylinder({ Name = "ArcadeBase", Size = Vector3.new(3.5, 14, 14),
		CFrame = CFrame.new(-58, 1.75, 42) * CFrame.Angles(0, 0, math.rad(90)), Color = C.KioskPink }, arcade)
	makePart({ Name = "ArcadeTop", Size = Vector3.new(14, 1, 14), Position = Vector3.new(-58, 4.5, 42), Color = Color3.new(1, 1, 1) }, arcade)
	local arcScreen = makePart({ Name = "ArcadeScreen", Size = Vector3.new(6, 4, 0.5), Position = Vector3.new(-58, 7.5, 42), Color = C.ScreenFrame }, arcade)
	ScreenGenerator.decorate(arcScreen, 7.77)
	for i = 0, 5 do
		local a = (i / 6) * math.pi * 2
		makePart({ Name = `Chair_{i}`, Size = Vector3.new(3, 3, 3),
			Position = Vector3.new(-58 + math.cos(a) * 10, 1.5, 42 + math.sin(a) * 10), Color = C.SeatingPurple }, arcade)
	end

	-- GAMING KIOSKS
	for _, cfg in ipairs({
		{x = -80, z = 55},
		{x = 80, z = 55},
	}) do
		local k = Instance.new("Model"); k.Name = "GamingKiosk"; k.Parent = props
		makePart({ Name = "KioskStand", Size = Vector3.new(2, 6, 2), Position = Vector3.new(cfg.x, 3, cfg.z), Color = C.KioskPink }, k)
		local ks = makePart({ Name = "KioskDisplay", Size = Vector3.new(5, 4, 0.4), Position = Vector3.new(cfg.x, 7, cfg.z), Color = C.ScreenFrame }, k)
		ScreenGenerator.decorate(ks, cfg.x + cfg.z)
		makeCylinder({ Name = "KioskGlow", Size = Vector3.new(0.3, 4, 4),
			CFrame = CFrame.new(cfg.x, 1.15, cfg.z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.NeonPink, Material = Enum.Material.Neon, CanCollide = false }, k)
	end

	-- FOOD TRUCK (right)
	local truck = Instance.new("Model"); truck.Name = "FoodTruck"; truck.Parent = props
	local truckX, truckZ = 65, 42
	makePart({ Name = "TruckBody", Size = Vector3.new(16, 6, 8), Position = Vector3.new(truckX, 3, truckZ), Color = C.VehiclePink }, truck)
	makePart({ Name = "TruckCab", Size = Vector3.new(5, 5, 8), Position = Vector3.new(truckX - 8, 3.5, truckZ), Color = C.VehiclePink:Lerp(Color3.new(1, 1, 1), 0.2) }, truck)
	makePart({ Name = "TruckRoof", Size = Vector3.new(16, 1.5, 8), Position = Vector3.new(truckX, 6.75, truckZ), Color = Color3.new(1, 1, 1) }, truck)
	makeNeon({ Name = "ServingWindow", Size = Vector3.new(8, 3, 0.3), Position = Vector3.new(truckX, 4, truckZ - 4.2), Color = C.NeonCyan, Transparency = 0.2 }, truck)
	for _, off in ipairs({ Vector3.new(-6, -2.5, -3.5), Vector3.new(6, -2.5, -3.5), Vector3.new(-6, -2.5, 3.5), Vector3.new(6, -2.5, 3.5) }) do
		makeCylinder({ Name = "Wheel", Size = Vector3.new(1.5, 3, 3),
			CFrame = CFrame.new(truckX + off.X, 3 + off.Y, truckZ + off.Z) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(40, 40, 40) }, truck)
	end

	-- CURVED SEATING (right)
	local seating = Instance.new("Model"); seating.Name = "Seating"; seating.Parent = props
	for i = 0, 5 do
		local angle = math.rad(-40 + i * 16)
		makePart({ Name = `CouchSeg_{i}`, Size = Vector3.new(5, 3.5, 3),
			CFrame = CFrame.new(78 + math.cos(angle) * 12, 1.75, 68 + math.sin(angle) * 12) * CFrame.Angles(0, angle, 0),
			Color = C.SeatingPurple }, seating)
	end
	makeCylinder({ Name = "CoffeeTable", Size = Vector3.new(2, 5, 5),
		CFrame = CFrame.new(78, 2, 68) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(1, 1, 1) }, seating)

	-- SELFIE BOOTHS (both sides)
	for _, side in ipairs({-1, 1}) do
		local sx, sz = side * 42, 72
		makePart({ Name = `SelfiePole_${side}`, Size = Vector3.new(0.6, 10, 0.6), Position = Vector3.new(sx, 5, sz), Color = C.RailMetal }, props)
		makeCylinder({ Name = `RingLight_${side}`, Size = Vector3.new(0.6, 6, 6),
			CFrame = CFrame.new(sx, 9.5, sz) * CFrame.Angles(math.rad(15), 0, 0),
			Color = C.NeonWhite, Material = Enum.Material.Neon, CanCollide = false }, props)
		makeCylinder({ Name = `SelfieBase_${side}`, Size = Vector3.new(0.4, 5, 5),
			CFrame = CFrame.new(sx, 1.2, sz) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 200, 50), Material = Enum.Material.Neon, CanCollide = false }, props)
	end

	-- SPEAKERS
	for _, side in ipairs({-1, 1}) do
		makePart({ Name = `Speaker_${side}`, Size = Vector3.new(2.5, 7, 2.5), Position = Vector3.new(side * 16, 3.5, -60), Color = C.Floor }, props)
		makeNeon({ Name = `SpeakerGlow_${side}`, Size = Vector3.new(1.5, 1.5, 0.3), Position = Vector3.new(side * 16, 5, -60 + 1.3), Color = C.NeonCyan, CanCollide = false }, props)
	end

	-- BOLLARDS
	for _, pos in ipairs({ Vector3.new(-30, 0, 80), Vector3.new(30, 0, 80), Vector3.new(-20, 0, 95), Vector3.new(20, 0, 95) }) do
		makePart({ Name = "Bollard", Size = Vector3.new(1, 4, 1), Position = pos + Vector3.new(0, 2, 0), Color = C.RailMetal }, props)
		makeNeon({ Name = "BollardCap", Size = Vector3.new(1.5, 0.5, 1.5), Position = pos + Vector3.new(0, 4.25, 0), Color = C.NeonPink, CanCollide = false }, props)
	end
end

--------------------------------------------------------------------------------
-- PHASE 8: SCENE LIGHTING (very subdued — neon material glows on its own)
--------------------------------------------------------------------------------

local function buildLighting(hub)
	local lighting = Instance.new("Model")
	lighting.Name = "SceneLighting"
	lighting.Parent = hub

	-- Wall base neon strips (no extra lights — neon material self-illuminates)
	for _, cfg in ipairs({
		{Vector3.new(-108, 2, 0), Vector3.new(0.5, 0.4, 216)},
		{Vector3.new(108, 2, 0), Vector3.new(0.5, 0.4, 216)},
		{Vector3.new(0, 2, -108), Vector3.new(216, 0.4, 0.5)},
	}) do
		makeNeon({ Name = "WallBaseNeon", Size = cfg[2], Position = cfg[1], Color = C.NeonPink, CanCollide = false }, lighting)
	end

	-- Wall mid neon strips
	for _, cfg in ipairs({
		{Vector3.new(-108, 16, 0), Vector3.new(0.5, 0.3, 216)},
		{Vector3.new(108, 16, 0), Vector3.new(0.5, 0.3, 216)},
	}) do
		makeNeon({ Name = "WallMidNeon", Size = cfg[2], Position = cfg[1], Color = C.NeonPurple, CanCollide = false }, lighting)
	end

	-- Wall top neon strips
	for _, cfg in ipairs({
		{Vector3.new(-108, D.WallHeight - 3, 0), Vector3.new(0.5, 0.3, 216)},
		{Vector3.new(108, D.WallHeight - 3, 0), Vector3.new(0.5, 0.3, 216)},
		{Vector3.new(0, D.WallHeight - 3, -108), Vector3.new(216, 0.3, 0.5)},
	}) do
		makeNeon({ Name = "WallTopNeon", Size = cfg[2], Position = cfg[1], Color = C.NeonPurple, CanCollide = false }, lighting)
	end

	-- Sparse ceiling light panels (fewer, dimmer)
	for x = -70, 70, 70 do
		for z = -50, 80, 65 do
			local panel = makeNeon({ Name = "CeilingPanel", Size = Vector3.new(8, 0.3, 8),
				Position = Vector3.new(x, D.CeilingHeight - 0.7, z),
				Color = C.NeonPurple:Lerp(C.NeonPink, 0.3), CanCollide = false }, lighting)
			addSurfaceLight(panel, C.NeonPurple, 0.3, 15, Enum.NormalId.Bottom)
		end
	end

	-- Corner ambient fill (gentle)
	for _, corner in ipairs({
		Vector3.new(-100, 14, -100),
		Vector3.new(100, 14, -100),
		Vector3.new(-100, 14, 100),
		Vector3.new(100, 14, 100),
	}) do
		local glow = makePart({ Name = "AmbientGlow", Size = Vector3.new(2, 2, 2), Position = corner,
			Color = C.NeonPurple, Material = Enum.Material.Neon, CanCollide = false, Transparency = 0.9 }, lighting)
		addPointLight(glow, C.NeonPurple, 0.4, 20)
	end
end

--------------------------------------------------------------------------------
-- PHASE 9: SIGN ("SOCIAL SPOTLIGHT PLAZA" — stacked 3 lines)
--------------------------------------------------------------------------------

local function buildSign(hub)
	local signModel = Instance.new("Model")
	signModel.Name = "PlazaSign"
	signModel.Parent = hub

	local backing = makePart({ Name = "SignBacking", Size = Vector3.new(32, 10, 1.5),
		Position = Vector3.new(0, 36, -97), Color = C.WallSecondary, Transparency = 0.15 }, signModel)

	addTextGui(backing, "SOCIAL\nSPOTLIGHT\nPLAZA", C.SignGold, nil, nil, Enum.NormalId.Front)
	addTextGui(backing, "SOCIAL\nSPOTLIGHT\nPLAZA", C.SignGold, nil, nil, Enum.NormalId.Back)

	makeNeon({ Name = "SignNeonTop", Size = Vector3.new(34, 0.4, 0.4), Position = Vector3.new(0, 41.2, -97), Color = C.SignGold, CanCollide = false }, signModel)
	makeNeon({ Name = "SignNeonBot", Size = Vector3.new(34, 0.4, 0.4), Position = Vector3.new(0, 30.8, -97), Color = C.SignGold, CanCollide = false }, signModel)
end

--------------------------------------------------------------------------------
-- PHASE 10: SPAWN LOCATIONS
--------------------------------------------------------------------------------

local function buildSpawns(hub)
	local spawns = Instance.new("Model")
	spawns.Name = "Spawns"
	spawns.Parent = hub

	for i, pos in ipairs({
		Vector3.new(0, 1, 85), Vector3.new(-15, 1, 90), Vector3.new(15, 1, 90),
		Vector3.new(-25, 1, 80), Vector3.new(25, 1, 80),
	}) do
		local s = Instance.new("SpawnLocation")
		s.Name = `Spawn_{i}`; s.Anchored = true; s.Size = Vector3.new(6, 1, 6)
		s.Position = pos; s.Color = C.Floor; s.Material = Enum.Material.SmoothPlastic
		s.Transparency = 0.8; s.CanCollide = true; s.TopSurface = Enum.SurfaceType.Smooth
		s.Duration = 0; s.Parent = spawns
	end
end

--------------------------------------------------------------------------------
-- MAIN BUILD
--------------------------------------------------------------------------------

function MapBuilder.build()
	FirebaseLogger.log("map", "build_start")
	local buildDone = FirebaseLogger.startTimer("map", "build")

	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and child.Name == "Baseplate" then child:Destroy() end
	end
	local existing = workspace:FindFirstChild(Constants.HubName)
	if existing then existing:Destroy() end
	local staticPlaza = workspace:FindFirstChild("SocialPlaza")
	if staticPlaza then staticPlaza:Destroy() end

	local hub = Instance.new("Model")
	hub.Name = Constants.HubName
	hub.Parent = workspace

	local floor = buildFoundation(hub)
	buildKeyhole(hub)
	local stageBase = buildStage(hub)
	buildStaircases(hub)
	buildBalconies(hub)
	buildScreens(hub)
	buildProps(hub)
	buildLighting(hub)
	buildSign(hub)
	buildSpawns(hub)

	local navPoints = {
		Vector3.new(0, 3, 0), Vector3.new(0, 3, 25), Vector3.new(0, 3, 50),
		Vector3.new(0, 3, 75), Vector3.new(0, 3, -25), Vector3.new(0, 3, -50),
		Vector3.new(20, 3, 15), Vector3.new(-20, 3, 15),
		Vector3.new(20, 3, 45), Vector3.new(-20, 3, 45),
		Vector3.new(40, 3, 30), Vector3.new(-40, 3, 30),
		Vector3.new(40, 3, 60), Vector3.new(-40, 3, 60),
		Vector3.new(60, 3, 15), Vector3.new(-60, 3, 15),
		Vector3.new(60, 3, 55), Vector3.new(-60, 3, 55),
		Vector3.new(75, 3, 40), Vector3.new(-75, 3, 40),
		Vector3.new(15, 3, -40), Vector3.new(-15, 3, -40),
		Vector3.new(30, 3, 80), Vector3.new(-30, 3, 80),
		Vector3.new(10, 3, 65), Vector3.new(-10, 3, 65),
	}

	local instanceCount = #hub:GetDescendants()
	buildDone({ instanceCount = instanceCount, navPointCount = #navPoints })
	print(`[MapBuilder] Built Social Spotlight Plaza: {instanceCount} instances`)

	return { hub = hub, navPoints = navPoints, floor = floor, stage = stageBase }
end

return MapBuilder
