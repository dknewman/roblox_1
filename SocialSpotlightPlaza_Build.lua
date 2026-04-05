--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         SOCIAL SPOTLIGHT PLAZA — MASTER BUILD SCRIPT        ║
    ║                                                              ║
    ║  Run in Roblox Studio Command Bar to generate the complete   ║
    ║  Social Spotlight Plaza central hub.                         ║
    ║                                                              ║
    ║  WARNING: Removes any existing "SocialSpotlightPlaza"        ║
    ║  folder in Workspace before building.                        ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ================================================================
-- CLEANUP
-- ================================================================
local existing = workspace:FindFirstChild("SocialSpotlightPlaza")
if existing then
	existing:Destroy()
	wait(0.1)
end

-- ================================================================
-- ROOT HIERARCHY
-- ================================================================
local Root = Instance.new("Folder")
Root.Name = "SocialSpotlightPlaza"
Root.Parent = workspace

local function makeFolder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or Root
	return f
end

local Foundation   = makeFolder("Foundation")
local Structure    = makeFolder("Structure")
local RunwayFolder = makeFolder("Runway")
local StageFolder  = makeFolder("Stage")
local ScreensFolder = makeFolder("Screens")
local SocialRing   = makeFolder("SocialRing")
local Activities   = makeFolder("ActivityZones")
local LightingFolder = makeFolder("Lighting")
local SpawnsFolder = makeFolder("Spawns")

-- ================================================================
-- COLOR PALETTE
-- ================================================================
local C = {
	Floor         = Color3.fromRGB(248, 240, 252),   -- soft lavender-white
	WallBase      = Color3.fromRGB(242, 236, 248),   -- light pastel wall
	WallUpper     = Color3.fromRGB(235, 228, 242),   -- slightly darker upper
	NeonPink      = Color3.fromRGB(255, 70, 165),    -- primary neon pink
	NeonHotPink   = Color3.fromRGB(255, 40, 140),    -- intense pink accents
	NeonPurple    = Color3.fromRGB(155, 70, 255),    -- purple accents
	NeonSoftPink  = Color3.fromRGB(255, 150, 200),   -- soft pink glow
	NeonBlue      = Color3.fromRGB(50, 160, 255),    -- screen glow blue
	StageWhite    = Color3.fromRGB(255, 255, 255),   -- bright white surfaces
	SeatPink      = Color3.fromRGB(255, 120, 175),   -- furniture pink
	SeatDarkPink  = Color3.fromRGB(200, 60, 120),    -- deeper seat accent
	ScreenBlue    = Color3.fromRGB(30, 140, 220),    -- screen background
	ScreenFrame   = Color3.fromRGB(60, 50, 80),      -- screen bezel
	DarkAccent    = Color3.fromRGB(70, 35, 110),     -- dark purple accent
	Metal         = Color3.fromRGB(175, 175, 185),   -- metallic grey
	MetalDark     = Color3.fromRGB(100, 100, 110),   -- darker metal
	Glass         = Color3.fromRGB(200, 215, 250),   -- glass tint
	RunwayGlow    = Color3.fromRGB(255, 180, 220),   -- runway edge glow
	WarmPink      = Color3.fromRGB(255, 100, 155),   -- warm pink
	CoolPurple    = Color3.fromRGB(115, 55, 195),    -- cool purple
	Lavender      = Color3.fromRGB(215, 195, 240),   -- soft lavender
	ArcadeDark    = Color3.fromRGB(40, 25, 60),      -- arcade cabinet
	FoodTruckPink = Color3.fromRGB(255, 130, 180),   -- food truck body
	RailingGrey   = Color3.fromRGB(190, 190, 200),   -- railing color
	StairBase     = Color3.fromRGB(220, 215, 230),   -- stair surface
	SignGold      = Color3.fromRGB(255, 215, 100),   -- signage gold
}

-- ================================================================
-- DIMENSION CONSTANTS
-- ================================================================
local D = {
	HUB_SIZE         = 220,
	WALL_HEIGHT      = 55,
	WALL_THICKNESS   = 2,
	CEILING_HEIGHT   = 55,
	-- Runway
	RUNWAY_CENTER    = 20,     -- center platform size
	RUNWAY_ARM_W     = 10,     -- arm width
	RUNWAY_ARM_L     = 30,     -- arm length
	RUNWAY_HEIGHT    = 2.5,    -- raised height
	-- Stage
	STAGE_WIDTH      = 30,
	STAGE_DEPTH      = 16,
	STAGE_HEIGHT     = 4,
	-- Screens
	SCREEN_W         = 20,
	SCREEN_H         = 12,
	SCREEN_DIST      = 48,     -- from center
	SCREEN_ELEV      = 14,     -- bottom edge height
	-- Balcony
	BALCONY_HEIGHT   = 22,
	BALCONY_DEPTH    = 18,
	BALCONY_RAIL_H   = 4,
	-- VIP
	VIP_HEIGHT       = 42,
	-- Stairs
	STAIR_WIDTH      = 16,
	STAIR_RISE       = 22,     -- matches balcony height
	-- Social
	SELFIE_SIZE      = 12,
	SQUAD_PAD_SIZE   = 8,
	-- Buildings (outer ring facades)
	BUILDING_W       = 40,
	BUILDING_H       = 35,
	BUILDING_D       = 10,     -- facade depth (not full buildings)
	BUILDING_DIST    = 95,     -- from center
	-- Spawns
	SPAWN_RADIUS     = 70,
	SPAWN_COUNT      = 8,
	-- Entrance
	ENTRANCE_WIDTH   = 44,
}

-- ================================================================
-- HELPER: Create Part
-- ================================================================
local function createPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = (props.CanCollide ~= false)
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(1, 1, 1)
	p.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	p.Color = props.Color or C.WallBase
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = (props.CastShadow ~= false)
	if props.Shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	elseif props.Shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	end
	p.Parent = props.Parent or Root
	return p
end

-- ================================================================
-- HELPER: Create Wedge
-- ================================================================
local function createWedge(props)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = (props.CanCollide ~= false)
	w.Name = props.Name or "Wedge"
	w.Size = props.Size or Vector3.new(1, 1, 1)
	w.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	w.Color = props.Color or C.WallBase
	w.Material = props.Material or Enum.Material.SmoothPlastic
	w.Transparency = props.Transparency or 0
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = props.Parent or Root
	return w
end

-- ================================================================
-- HELPER: Attach Light
-- ================================================================
local function addLight(part, lightType, props)
	local light = Instance.new(lightType)
	light.Color = props.Color or Color3.new(1, 1, 1)
	light.Brightness = props.Brightness or 1
	if lightType == "SpotLight" then
		light.Angle = props.Angle or 45
		light.Face = props.Face or Enum.NormalId.Bottom
		light.Range = props.Range or 40
	elseif lightType == "SurfaceLight" then
		light.Face = props.Face or Enum.NormalId.Front
		light.Range = props.Range or 20
		light.Brightness = props.Brightness or 0.6
	elseif lightType == "PointLight" then
		light.Range = props.Range or 25
		light.Brightness = props.Brightness or 1
	end
	light.Parent = part
	return light
end

-- ================================================================
-- HELPER: SurfaceGui with text
-- ================================================================
local function addSurfaceGui(part, config)
	local sg = Instance.new("SurfaceGui")
	sg.Face = config.Face or Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.Brightness = 1.5
	sg.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = config.BgColor or C.ScreenBlue
	bg.BorderSizePixel = 0
	bg.Parent = sg

	-- Gradient overlay for visual interest
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 200, 255)),
	}
	grad.Rotation = 45
	grad.Parent = bg

	if config.Title then
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.9, 0, 0.25, 0)
		title.Position = UDim2.new(0.05, 0, 0.08, 0)
		title.BackgroundTransparency = 1
		title.Text = config.Title
		title.TextColor3 = config.TextColor or Color3.new(1, 1, 1)
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title.Parent = bg
	end

	if config.Subtitle then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(0.8, 0, 0.15, 0)
		sub.Position = UDim2.new(0.1, 0, 0.38, 0)
		sub.BackgroundTransparency = 1
		sub.Text = config.Subtitle
		sub.TextColor3 = config.TextColor or Color3.new(1, 1, 1)
		sub.TextScaled = true
		sub.Font = Enum.Font.Gotham
		sub.Parent = bg
	end

	-- Silhouette placeholders (represent character art on screens)
	if config.ShowSilhouettes then
		for i = 1, 3 do
			local sil = Instance.new("Frame")
			sil.Size = UDim2.new(0.18, 0, 0.4, 0)
			sil.Position = UDim2.new(0.12 + (i - 1) * 0.28, 0, 0.5, 0)
			sil.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			sil.BackgroundTransparency = 0.7
			sil.BorderSizePixel = 0
			sil.Parent = bg
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.15, 0)
			corner.Parent = sil
		end
	end

	return sg
end

-- ================================================================
-- HELPER: Create neon strip
-- ================================================================
local function createNeonStrip(name, size, cframe, color, parent)
	local strip = createPart({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = color or C.NeonPink,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	return strip
end

-- ================================================================
-- HELPER: Create a column/pillar
-- ================================================================
local function createPillar(name, pos, height, radius, color, parent)
	return createPart({
		Name = name,
		Shape = "Cylinder",
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color or C.Metal,
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

-- ################################################################
--                    PHASE 1: FOUNDATION & SHELL
-- ################################################################

-- === MAIN FLOOR ===
createPart({
	Name = "MainFloor",
	Size = Vector3.new(D.HUB_SIZE, 1, D.HUB_SIZE),
	CFrame = CFrame.new(0, -0.5, 0),
	Color = C.Floor,
	Parent = Foundation,
})

-- Decorative floor border ring (inset neon line)
for _, data in ipairs({
	{ Vector3.new(200, 0.2, 0.4), CFrame.new(0, 0.01, -96) },
	{ Vector3.new(200, 0.2, 0.4), CFrame.new(0, 0.01, 96) },
	{ Vector3.new(0.4, 0.2, 192), CFrame.new(-96, 0.01, 0) },
	{ Vector3.new(0.4, 0.2, 192), CFrame.new(96, 0.01, 0) },
}) do
	createNeonStrip("FloorBorderStrip", data[1], data[2], C.NeonSoftPink, Foundation)
end

-- === PERIMETER WALLS ===
local wH = D.WALL_HEIGHT
local wT = D.WALL_THICKNESS
local half = D.HUB_SIZE / 2

-- Back wall (North, -Z)
createPart({
	Name = "WallNorth",
	Size = Vector3.new(D.HUB_SIZE, wH, wT),
	CFrame = CFrame.new(0, wH / 2, -half),
	Color = C.WallBase,
	Parent = Structure,
})

-- Side walls
createPart({
	Name = "WallWest",
	Size = Vector3.new(wT, wH, D.HUB_SIZE),
	CFrame = CFrame.new(-half, wH / 2, 0),
	Color = C.WallBase,
	Parent = Structure,
})
createPart({
	Name = "WallEast",
	Size = Vector3.new(wT, wH, D.HUB_SIZE),
	CFrame = CFrame.new(half, wH / 2, 0),
	Color = C.WallBase,
	Parent = Structure,
})

-- Front wall (South, +Z) — split for entrance
local sideW = (D.HUB_SIZE - D.ENTRANCE_WIDTH) / 2
createPart({
	Name = "WallSouth_Left",
	Size = Vector3.new(sideW, wH, wT),
	CFrame = CFrame.new(-(D.ENTRANCE_WIDTH / 2 + sideW / 2), wH / 2, half),
	Color = C.WallBase,
	Parent = Structure,
})
createPart({
	Name = "WallSouth_Right",
	Size = Vector3.new(sideW, wH, wT),
	CFrame = CFrame.new((D.ENTRANCE_WIDTH / 2 + sideW / 2), wH / 2, half),
	Color = C.WallBase,
	Parent = Structure,
})
-- Entrance header
createPart({
	Name = "WallSouth_Header",
	Size = Vector3.new(D.ENTRANCE_WIDTH, wH - 22, wT),
	CFrame = CFrame.new(0, 22 + (wH - 22) / 2, half),
	Color = C.WallBase,
	Parent = Structure,
})

-- === CEILING (partial — open skylight center) ===
local ceilY = D.CEILING_HEIGHT
for _, cp in ipairs({
	{ "CeilingNorth", Vector3.new(220, 1, 65), CFrame.new(0, ceilY, -77.5) },
	{ "CeilingSouth", Vector3.new(220, 1, 65), CFrame.new(0, ceilY, 77.5) },
	{ "CeilingWest",  Vector3.new(45, 1, 90),  CFrame.new(-87.5, ceilY, 0) },
	{ "CeilingEast",  Vector3.new(45, 1, 90),  CFrame.new(87.5, ceilY, 0) },
}) do
	createPart({
		Name = cp[1],
		Size = cp[2],
		CFrame = cp[3],
		Color = C.WallUpper,
		Parent = Structure,
	})
end

-- === NEON TRIM ALONG WALL TOPS ===
local trimY = wH - 1.5
for _, td in ipairs({
	{ "TrimNorth", Vector3.new(220, 1, 0.5), CFrame.new(0, trimY, -half + 1) },
	{ "TrimWest",  Vector3.new(0.5, 1, 220), CFrame.new(-half + 1, trimY, 0) },
	{ "TrimEast",  Vector3.new(0.5, 1, 220), CFrame.new(half - 1, trimY, 0) },
}) do
	local strip = createNeonStrip(td[1], td[2], td[3], C.NeonPink, Structure)
	addLight(strip, "SurfaceLight", {
		Color = C.NeonPink,
		Brightness = 0.4,
		Range = 12,
		Face = Enum.NormalId.Bottom,
	})
end

-- Mid-wall accent neon line (~15 studs high)
for _, td in ipairs({
	{ "MidAccentNorth", Vector3.new(220, 0.4, 0.3), CFrame.new(0, 16, -half + 1.2) },
	{ "MidAccentWest",  Vector3.new(0.3, 0.4, 220), CFrame.new(-half + 1.2, 16, 0) },
	{ "MidAccentEast",  Vector3.new(0.3, 0.4, 220), CFrame.new(half - 1.2, 16, 0) },
}) do
	createNeonStrip(td[1], td[2], td[3], C.NeonPurple, Structure)
end


-- ################################################################
--                 PHASE 2: VERTICAL LAYERS
-- ################################################################

local balcH = D.BALCONY_HEIGHT
local balcD = D.BALCONY_DEPTH
local railH = D.BALCONY_RAIL_H

-- === LEFT (WEST) BALCONY ===
createPart({
	Name = "BalconyWest_Floor",
	Size = Vector3.new(balcD, 1, 140),
	CFrame = CFrame.new(-half + balcD / 2, balcH, 0),
	Color = C.StairBase,
	Parent = Structure,
})
-- Railing
createPart({
	Name = "BalconyWest_Rail",
	Size = Vector3.new(1, railH, 140),
	CFrame = CFrame.new(-half + balcD, balcH + railH / 2, 0),
	Color = C.RailingGrey,
	Material = Enum.Material.Glass,
	Transparency = 0.3,
	Parent = Structure,
})
-- Rail top bar
createPart({
	Name = "BalconyWest_RailTop",
	Size = Vector3.new(1.5, 0.5, 140),
	CFrame = CFrame.new(-half + balcD, balcH + railH + 0.25, 0),
	Color = C.Metal,
	Material = Enum.Material.SmoothPlastic,
	Parent = Structure,
})
-- Neon strip under balcony edge
createNeonStrip("BalconyWest_NeonEdge",
	Vector3.new(0.4, 0.4, 140),
	CFrame.new(-half + balcD - 0.5, balcH - 0.5, 0),
	C.NeonPink, Structure)

-- === RIGHT (EAST) BALCONY ===
createPart({
	Name = "BalconyEast_Floor",
	Size = Vector3.new(balcD, 1, 140),
	CFrame = CFrame.new(half - balcD / 2, balcH, 0),
	Color = C.StairBase,
	Parent = Structure,
})
createPart({
	Name = "BalconyEast_Rail",
	Size = Vector3.new(1, railH, 140),
	CFrame = CFrame.new(half - balcD, balcH + railH / 2, 0),
	Color = C.RailingGrey,
	Material = Enum.Material.Glass,
	Transparency = 0.3,
	Parent = Structure,
})
createPart({
	Name = "BalconyEast_RailTop",
	Size = Vector3.new(1.5, 0.5, 140),
	CFrame = CFrame.new(half - balcD, balcH + railH + 0.25, 0),
	Color = C.Metal,
	Parent = Structure,
})
createNeonStrip("BalconyEast_NeonEdge",
	Vector3.new(0.4, 0.4, 140),
	CFrame.new(half - balcD + 0.5, balcH - 0.5, 0),
	C.NeonPink, Structure)

-- === BACK (NORTH) BALCONY ===
createPart({
	Name = "BalconyNorth_Floor",
	Size = Vector3.new(D.HUB_SIZE - 2 * balcD, 1, balcD),
	CFrame = CFrame.new(0, balcH, -half + balcD / 2),
	Color = C.StairBase,
	Parent = Structure,
})
createPart({
	Name = "BalconyNorth_Rail",
	Size = Vector3.new(D.HUB_SIZE - 2 * balcD, railH, 1),
	CFrame = CFrame.new(0, balcH + railH / 2, -half + balcD),
	Color = C.RailingGrey,
	Material = Enum.Material.Glass,
	Transparency = 0.3,
	Parent = Structure,
})

-- === GRAND STAIRCASES (wide ramps, one per side) ===
-- Each staircase: ramp from ground to balcony height
local stairW = D.STAIR_WIDTH
local stairRun = 40  -- horizontal length of ramp

-- West staircase (going up toward -Z along west wall)
local stairFolder = makeFolder("Staircases", Structure)

-- Ramp surface (using a series of steps for visual fidelity)
local stepCount = 16
local stepH = balcH / stepCount
local stepD = stairRun / stepCount

for i = 0, stepCount - 1 do
	local yPos = (i + 0.5) * stepH
	local zPos = -30 + i * stepD  -- starts at z=-30, goes toward +Z

	-- West staircase step
	createPart({
		Name = "StairWest_Step" .. i,
		Size = Vector3.new(stairW, stepH, stepD),
		CFrame = CFrame.new(-half + balcD / 2, yPos, zPos),
		Color = C.StairBase,
		Parent = stairFolder,
	})

	-- East staircase step (mirrored)
	createPart({
		Name = "StairEast_Step" .. i,
		Size = Vector3.new(stairW, stepH, stepD),
		CFrame = CFrame.new(half - balcD / 2, yPos, zPos),
		Color = C.StairBase,
		Parent = stairFolder,
	})
end

-- Staircase side walls / railings
for _, xSign in ipairs({-1, 1}) do
	local side = xSign == -1 and "West" or "East"
	local xBase = xSign * (half - balcD / 2)
	local railX = xBase + xSign * (stairW / 2 + 0.5)
	-- Inner railing runs alongside staircase
	-- Simplified: a single angled railing using a tall part
	createPart({
		Name = "StairRail_" .. side .. "_Inner",
		Size = Vector3.new(0.8, railH, stairRun + 4),
		CFrame = CFrame.new(
			xBase - xSign * (stairW / 2 + 0.5),
			balcH / 2 + railH / 2,
			-30 + stairRun / 2
		),
		Color = C.RailingGrey,
		Material = Enum.Material.Glass,
		Transparency = 0.4,
		Parent = stairFolder,
	})
end

-- Neon strips on stair edges
for _, xSign in ipairs({-1, 1}) do
	local side = xSign == -1 and "West" or "East"
	createNeonStrip(
		"StairNeon_" .. side,
		Vector3.new(0.3, 0.3, stairRun),
		CFrame.new(xSign * (half - balcD / 2), 0.2, -30 + stairRun / 2),
		C.NeonPink, stairFolder
	)
end

-- === VIP LEVEL (upper back, +40 studs) ===
local vipFolder = makeFolder("VIPLevel", Structure)
createPart({
	Name = "VIP_Floor",
	Size = Vector3.new(80, 1, 20),
	CFrame = CFrame.new(0, D.VIP_HEIGHT, -half + 10),
	Color = C.Lavender,
	Parent = vipFolder,
})
createPart({
	Name = "VIP_Rail",
	Size = Vector3.new(80, railH, 1),
	CFrame = CFrame.new(0, D.VIP_HEIGHT + railH / 2, -half + 20),
	Color = C.RailingGrey,
	Material = Enum.Material.Glass,
	Transparency = 0.3,
	Parent = vipFolder,
})
-- VIP neon accent
createNeonStrip("VIP_NeonEdge",
	Vector3.new(80, 0.4, 0.4),
	CFrame.new(0, D.VIP_HEIGHT - 0.3, -half + 20),
	C.NeonPurple, vipFolder)

-- VIP access stairs (small ramp from back balcony up to VIP)
local vipRise = D.VIP_HEIGHT - balcH
local vipSteps = 8
for i = 0, vipSteps - 1 do
	createPart({
		Name = "VIPStair_Step" .. i,
		Size = Vector3.new(10, vipRise / vipSteps, 2),
		CFrame = CFrame.new(0, balcH + (i + 0.5) * (vipRise / vipSteps), -half + balcD - i * 1.5),
		Color = C.Lavender,
		Parent = vipFolder,
	})
end


-- ################################################################
--                   PHASE 3: RUNWAY ZONE
-- ################################################################

local rH = D.RUNWAY_HEIGHT
local rC = D.RUNWAY_CENTER
local rW = D.RUNWAY_ARM_W
local rL = D.RUNWAY_ARM_L

-- === CENTER PLATFORM (circular feel via octagon of parts) ===
-- Main center square
createPart({
	Name = "RunwayCenter",
	Size = Vector3.new(rC, rH, rC),
	CFrame = CFrame.new(0, rH / 2, 0),
	Color = C.StageWhite,
	Material = Enum.Material.SmoothPlastic,
	Parent = RunwayFolder,
})

-- Center glow disc (thin neon circle on top)
createPart({
	Name = "RunwayCenter_Glow",
	Shape = "Cylinder",
	Size = Vector3.new(0.3, rC - 2, rC - 2),
	CFrame = CFrame.new(0, rH + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = C.NeonSoftPink,
	Material = Enum.Material.Neon,
	CanCollide = false,
	CastShadow = false,
	Parent = RunwayFolder,
})

-- Corner fills to soften the center into a more rounded shape
for _, offset in ipairs({
	{rC/2 - 2, rC/2 - 2}, {-rC/2 + 2, rC/2 - 2},
	{rC/2 - 2, -rC/2 + 2}, {-rC/2 + 2, -rC/2 + 2},
}) do
	createPart({
		Name = "RunwayCenter_Corner",
		Shape = "Cylinder",
		Size = Vector3.new(rH, 6, 6),
		CFrame = CFrame.new(offset[1], rH / 2, offset[2]) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.StageWhite,
		Parent = RunwayFolder,
	})
end

-- === FOUR RUNWAY ARMS ===
local armData = {
	{ name = "ArmNorth", size = Vector3.new(rW, rH, rL), pos = CFrame.new(0, rH/2, -(rC/2 + rL/2)) },
	{ name = "ArmSouth", size = Vector3.new(rW, rH, rL), pos = CFrame.new(0, rH/2, (rC/2 + rL/2)) },
	{ name = "ArmWest",  size = Vector3.new(rL, rH, rW), pos = CFrame.new(-(rC/2 + rL/2), rH/2, 0) },
	{ name = "ArmEast",  size = Vector3.new(rL, rH, rW), pos = CFrame.new((rC/2 + rL/2), rH/2, 0) },
}
for _, arm in ipairs(armData) do
	createPart({
		Name = arm.name,
		Size = arm.size,
		CFrame = arm.pos,
		Color = C.StageWhite,
		Parent = RunwayFolder,
	})
end

-- === LED NEON EDGE STRIPS (along all runway edges) ===
local neonThick = 0.4
local neonH = 0.5

-- Center platform edge neons
for _, nd in ipairs({
	-- North edge of center
	{ Vector3.new(rC + 2, neonH, neonThick), CFrame.new(0, rH + 0.1, -rC/2) },
	-- South edge
	{ Vector3.new(rC + 2, neonH, neonThick), CFrame.new(0, rH + 0.1, rC/2) },
	-- West edge
	{ Vector3.new(neonThick, neonH, rC + 2), CFrame.new(-rC/2, rH + 0.1, 0) },
	-- East edge
	{ Vector3.new(neonThick, neonH, rC + 2), CFrame.new(rC/2, rH + 0.1, 0) },
}) do
	createNeonStrip("RunwayEdge", nd[1], nd[2], C.NeonPink, RunwayFolder)
end

-- Arm edge neons (both long edges of each arm)
local armNeons = {
	-- North arm: left & right edges
	{ Vector3.new(neonThick, neonH, rL), CFrame.new(-rW/2, rH + 0.1, -(rC/2 + rL/2)) },
	{ Vector3.new(neonThick, neonH, rL), CFrame.new(rW/2, rH + 0.1, -(rC/2 + rL/2)) },
	-- North arm: far end
	{ Vector3.new(rW, neonH, neonThick), CFrame.new(0, rH + 0.1, -(rC/2 + rL)) },
	-- South arm
	{ Vector3.new(neonThick, neonH, rL), CFrame.new(-rW/2, rH + 0.1, (rC/2 + rL/2)) },
	{ Vector3.new(neonThick, neonH, rL), CFrame.new(rW/2, rH + 0.1, (rC/2 + rL/2)) },
	{ Vector3.new(rW, neonH, neonThick), CFrame.new(0, rH + 0.1, (rC/2 + rL)) },
	-- West arm
	{ Vector3.new(rL, neonH, neonThick), CFrame.new(-(rC/2 + rL/2), rH + 0.1, -rW/2) },
	{ Vector3.new(rL, neonH, neonThick), CFrame.new(-(rC/2 + rL/2), rH + 0.1, rW/2) },
	{ Vector3.new(neonThick, neonH, rW), CFrame.new(-(rC/2 + rL), rH + 0.1, 0) },
	-- East arm
	{ Vector3.new(rL, neonH, neonThick), CFrame.new((rC/2 + rL/2), rH + 0.1, -rW/2) },
	{ Vector3.new(rL, neonH, neonThick), CFrame.new((rC/2 + rL/2), rH + 0.1, rW/2) },
	{ Vector3.new(neonThick, neonH, rW), CFrame.new((rC/2 + rL), rH + 0.1, 0) },
}
for _, an in ipairs(armNeons) do
	createNeonStrip("ArmEdge", an[1], an[2], C.NeonPink, RunwayFolder)
end

-- === CENTER RUNWAY GLOW LINE (thin strip down center of each arm) ===
for _, gl in ipairs({
	{ Vector3.new(1, 0.2, rL), CFrame.new(0, rH + 0.05, -(rC/2 + rL/2)) },
	{ Vector3.new(1, 0.2, rL), CFrame.new(0, rH + 0.05, (rC/2 + rL/2)) },
	{ Vector3.new(rL, 0.2, 1), CFrame.new(-(rC/2 + rL/2), rH + 0.05, 0) },
	{ Vector3.new(rL, 0.2, 1), CFrame.new((rC/2 + rL/2), rH + 0.05, 0) },
}) do
	createNeonStrip("RunwayCenterLine", gl[1], gl[2], C.RunwayGlow, RunwayFolder)
end

-- === ENTRY RAMPS (one at each arm end) ===
local rampLen = 5
local rampData = {
	{ "RampNorth", Vector3.new(rW, rH, rampLen), CFrame.new(0, rH/2, -(rC/2 + rL + rampLen/2)), CFrame.Angles(0, 0, 0) },
	{ "RampSouth", Vector3.new(rW, rH, rampLen), CFrame.new(0, rH/2, (rC/2 + rL + rampLen/2)), CFrame.Angles(0, math.rad(180), 0) },
	{ "RampWest",  Vector3.new(rampLen, rH, rW), CFrame.new(-(rC/2 + rL + rampLen/2), rH/2, 0), CFrame.Angles(0, math.rad(90), 0) },
	{ "RampEast",  Vector3.new(rampLen, rH, rW), CFrame.new((rC/2 + rL + rampLen/2), rH/2, 0), CFrame.Angles(0, math.rad(-90), 0) },
}
for _, rd in ipairs(rampData) do
	createWedge({
		Name = rd[1],
		Size = Vector3.new(rd[2].X, rd[2].Y, rd[2].Z),
		CFrame = rd[3] * rd[4],
		Color = C.StageWhite,
		Parent = RunwayFolder,
	})
end


-- ################################################################
--              PHASE 4: PERFORMANCE STAGE
-- ################################################################

local stgW = D.STAGE_WIDTH
local stgD = D.STAGE_DEPTH
local stgH = D.STAGE_HEIGHT
local stgZ = -(rC/2 + rL + 2)  -- just beyond north arm

-- Main stage platform
createPart({
	Name = "StagePlatform",
	Size = Vector3.new(stgW, stgH, stgD),
	CFrame = CFrame.new(0, stgH / 2, stgZ - stgD / 2),
	Color = C.StageWhite,
	Parent = StageFolder,
})

-- Stage front neon edge
createNeonStrip("StageFrontNeon",
	Vector3.new(stgW, 0.6, 0.4),
	CFrame.new(0, stgH + 0.1, stgZ),
	C.NeonHotPink, StageFolder)

-- Stage side neon edges
for _, xSign in ipairs({-1, 1}) do
	createNeonStrip("StageSideNeon",
		Vector3.new(0.4, 0.6, stgD),
		CFrame.new(xSign * stgW / 2, stgH + 0.1, stgZ - stgD / 2),
		C.NeonHotPink, StageFolder)
end

-- === BACKDROP SCREEN (large, behind stage) ===
local backdropW = stgW + 10
local backdropH = 18
local backdropY = stgH + backdropH / 2
local backdropZ = stgZ - stgD + 0.5

-- Screen bezel
createPart({
	Name = "StageBackdrop_Bezel",
	Size = Vector3.new(backdropW + 2, backdropH + 2, 1.5),
	CFrame = CFrame.new(0, backdropY, backdropZ),
	Color = C.ScreenFrame,
	Parent = StageFolder,
})

-- Screen surface
local backdropScreen = createPart({
	Name = "StageBackdrop_Screen",
	Size = Vector3.new(backdropW, backdropH, 0.5),
	CFrame = CFrame.new(0, backdropY, backdropZ + 1),
	Color = C.ScreenBlue,
	Material = Enum.Material.SmoothPlastic,
	Parent = StageFolder,
})
addSurfaceGui(backdropScreen, {
	Face = Enum.NormalId.Front,
	BgColor = C.ScreenBlue,
	Title = "SOCIAL SPOTLIGHT",
	Subtitle = "Now Performing",
	ShowSilhouettes = true,
	TextColor = Color3.new(1, 1, 1),
})

-- Screen glow
addLight(backdropScreen, "SurfaceLight", {
	Color = C.NeonBlue,
	Brightness = 0.8,
	Range = 25,
	Face = Enum.NormalId.Front,
})

-- === CIRCULAR MEDALLION (above backdrop) ===
local medalY = backdropY + backdropH / 2 + 6
local medalRadius = 6

-- Outer ring
createPart({
	Name = "Medallion_Outer",
	Shape = "Cylinder",
	Size = Vector3.new(1.5, medalRadius * 2, medalRadius * 2),
	CFrame = CFrame.new(0, medalY, backdropZ) * CFrame.Angles(0, math.rad(90), 0),
	Color = C.DarkAccent,
	Parent = StageFolder,
})

-- Inner disc (neon)
createPart({
	Name = "Medallion_Inner",
	Shape = "Cylinder",
	Size = Vector3.new(0.5, medalRadius * 1.4, medalRadius * 1.4),
	CFrame = CFrame.new(0, medalY, backdropZ + 0.8) * CFrame.Angles(0, math.rad(90), 0),
	Color = C.NeonPurple,
	Material = Enum.Material.Neon,
	Parent = StageFolder,
})

-- Crosshairs inside medallion (4 thin bars)
for _, rot in ipairs({0, 90, 45, 135}) do
	createPart({
		Name = "Medallion_Cross",
		Size = Vector3.new(medalRadius * 1.2, 0.5, 0.3),
		CFrame = CFrame.new(0, medalY, backdropZ + 1.2) * CFrame.Angles(0, 0, math.rad(rot)),
		Color = C.DarkAccent,
		CanCollide = false,
		Parent = StageFolder,
	})
end

-- Stage spotlights (3 overhead spots)
for _, xOff in ipairs({-8, 0, 8}) do
	local spotMount = createPart({
		Name = "StageSpotMount",
		Size = Vector3.new(2, 3, 2),
		CFrame = CFrame.new(xOff, 35, stgZ - stgD / 2),
		Color = C.MetalDark,
		Parent = StageFolder,
	})
	addLight(spotMount, "SpotLight", {
		Color = C.NeonSoftPink,
		Brightness = 2,
		Range = 50,
		Angle = 35,
		Face = Enum.NormalId.Bottom,
	})
end


-- ################################################################
--              PHASE 5: SCREEN RING
-- ################################################################

local scrW = D.SCREEN_W
local scrH = D.SCREEN_H
local scrDist = D.SCREEN_DIST
local scrElev = D.SCREEN_ELEV

-- Screen data: position, rotation, title
local screenData = {
	{
		name = "Screen_NW",
		pos = CFrame.new(-scrDist, scrElev + scrH/2, -scrDist) * CFrame.Angles(0, math.rad(45), 0),
		title = "TOP SQUADS",
		subtitle = "#1 Squad Loading...",
	},
	{
		name = "Screen_NE",
		pos = CFrame.new(scrDist, scrElev + scrH/2, -scrDist) * CFrame.Angles(0, math.rad(-45), 0),
		title = "TRENDING NOW",
		subtitle = "Most Popular Fits",
	},
	{
		name = "Screen_SW",
		pos = CFrame.new(-scrDist, scrElev + scrH/2, scrDist) * CFrame.Angles(0, math.rad(135), 0),
		title = "LEADERBOARD",
		subtitle = "Top REP Earners",
	},
	{
		name = "Screen_SE",
		pos = CFrame.new(scrDist, scrElev + scrH/2, scrDist) * CFrame.Angles(0, math.rad(-135), 0),
		title = "NOW ON STAGE",
		subtitle = "Spotlight Active",
	},
}

for _, sd in ipairs(screenData) do
	-- Bezel
	createPart({
		Name = sd.name .. "_Bezel",
		Size = Vector3.new(scrW + 1.5, scrH + 1.5, 1.2),
		CFrame = sd.pos,
		Color = C.ScreenFrame,
		Parent = ScreensFolder,
	})

	-- Screen face
	local screenPart = createPart({
		Name = sd.name .. "_Face",
		Size = Vector3.new(scrW, scrH, 0.3),
		CFrame = sd.pos * CFrame.new(0, 0, -0.5),
		Color = C.ScreenBlue,
		Parent = ScreensFolder,
	})
	addSurfaceGui(screenPart, {
		Face = Enum.NormalId.Front,
		BgColor = C.ScreenBlue,
		Title = sd.title,
		Subtitle = sd.subtitle,
		ShowSilhouettes = true,
	})
	addLight(screenPart, "SurfaceLight", {
		Color = C.NeonBlue,
		Brightness = 0.5,
		Range = 18,
		Face = Enum.NormalId.Front,
	})

	-- Support column
	createPillar(sd.name .. "_Pillar",
		Vector3.new(sd.pos.X, scrElev / 2, sd.pos.Z),
		scrElev, 1, C.MetalDark, ScreensFolder)
end


-- ################################################################
--              PHASE 6: INNER SOCIAL RING
-- ################################################################

-- === SELFIE SPOTS (6, evenly distributed around center) ===
local selfieR = 55  -- radius from center
local selfieCount = 6

for i = 1, selfieCount do
	local angle = (i - 1) * (360 / selfieCount) + 15  -- offset to avoid runway arms
	local rad = math.rad(angle)
	local x = math.cos(rad) * selfieR
	local z = math.sin(rad) * selfieR

	local sfFolder = makeFolder("SelfieSpot_" .. i, SocialRing)

	-- Base pad
	createPart({
		Name = "SelfiePad",
		Size = Vector3.new(D.SELFIE_SIZE, 0.5, D.SELFIE_SIZE),
		CFrame = CFrame.new(x, 0.25, z),
		Color = C.Lavender,
		Parent = sfFolder,
	})

	-- Neon border
	for _, edge in ipairs({
		{ Vector3.new(D.SELFIE_SIZE, 0.3, 0.3), CFrame.new(x, 0.6, z - D.SELFIE_SIZE/2) },
		{ Vector3.new(D.SELFIE_SIZE, 0.3, 0.3), CFrame.new(x, 0.6, z + D.SELFIE_SIZE/2) },
		{ Vector3.new(0.3, 0.3, D.SELFIE_SIZE), CFrame.new(x - D.SELFIE_SIZE/2, 0.6, z) },
		{ Vector3.new(0.3, 0.3, D.SELFIE_SIZE), CFrame.new(x + D.SELFIE_SIZE/2, 0.6, z) },
	}) do
		createNeonStrip("SelfieBorder", edge[1], edge[2], C.NeonSoftPink, sfFolder)
	end

	-- Ring light prop (tall hoop)
	local rlX = x + math.cos(rad) * 4
	local rlZ = z + math.sin(rad) * 4
	-- Pole
	createPart({
		Name = "RingLight_Pole",
		Size = Vector3.new(0.6, 8, 0.6),
		CFrame = CFrame.new(rlX, 4, rlZ),
		Color = C.MetalDark,
		Parent = sfFolder,
	})
	-- Ring (cylinder turned sideways)
	local ring = createPart({
		Name = "RingLight_Ring",
		Shape = "Cylinder",
		Size = Vector3.new(0.5, 5, 5),
		CFrame = CFrame.new(rlX, 8, rlZ) * CFrame.Angles(0, rad, 0),
		Color = C.StageWhite,
		Material = Enum.Material.Neon,
		Parent = sfFolder,
	})
	addLight(ring, "PointLight", {
		Color = Color3.new(1, 0.95, 0.9),
		Brightness = 1.5,
		Range = 15,
	})
end

-- === SQUAD FORMATION PADS (6, in a tighter ring) ===
local squadR = 38  -- closer to runway
local squadCount = 6

for i = 1, squadCount do
	local angle = (i - 1) * (360 / squadCount) + 45
	local rad = math.rad(angle)
	local x = math.cos(rad) * squadR
	local z = math.sin(rad) * squadR

	-- Glowing pad (cylinder for circle shape)
	local pad = createPart({
		Name = "SquadPad_" .. i,
		Shape = "Cylinder",
		Size = Vector3.new(0.3, D.SQUAD_PAD_SIZE, D.SQUAD_PAD_SIZE),
		CFrame = CFrame.new(x, 0.15, z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.NeonPurple,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = SocialRing,
	})
	addLight(pad, "PointLight", {
		Color = C.NeonPurple,
		Brightness = 0.6,
		Range = 10,
	})
end

-- === SEATING CLUSTERS (4 clusters in the social ring) ===
local seatPositions = {
	Vector3.new(-65, 0, 30),
	Vector3.new(65, 0, 30),
	Vector3.new(-65, 0, -25),
	Vector3.new(65, 0, -25),
}

for idx, seatPos in ipairs(seatPositions) do
	local cFolder = makeFolder("SeatingCluster_" .. idx, SocialRing)

	-- Curved couch (approximated with 3 parts)
	for j = -1, 1 do
		createPart({
			Name = "Couch_" .. j,
			Size = Vector3.new(6, 3, 3),
			CFrame = CFrame.new(seatPos.X + j * 5, 1.5, seatPos.Z),
			Color = C.SeatPink,
			Parent = cFolder,
		})
		-- Seat cushion top
		createPart({
			Name = "CouchCushion_" .. j,
			Size = Vector3.new(5.5, 0.5, 2.5),
			CFrame = CFrame.new(seatPos.X + j * 5, 2.8, seatPos.Z),
			Color = C.NeonSoftPink,
			Parent = cFolder,
		})
	end

	-- Low coffee table
	createPart({
		Name = "CoffeeTable",
		Size = Vector3.new(4, 1.5, 4),
		CFrame = CFrame.new(seatPos.X, 0.75, seatPos.Z + 5),
		Color = C.StageWhite,
		Parent = cFolder,
	})

	-- Ambient light
	local ambLight = createPart({
		Name = "AmbientGlow",
		Size = Vector3.new(1, 0.3, 1),
		CFrame = CFrame.new(seatPos.X, 1.6, seatPos.Z + 5),
		Color = C.NeonSoftPink,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.3,
		Parent = cFolder,
	})
	addLight(ambLight, "PointLight", {
		Color = C.NeonSoftPink,
		Brightness = 0.8,
		Range = 12,
	})
end


-- ################################################################
--            PHASE 7: ACTIVITY ZONES
-- ################################################################

-- === ARCADE CLUSTER (West side) ===
local arcadeFolder = makeFolder("ArcadeZone", Activities)
local arcadeBaseX = -75
local arcadeBaseZ = 15

-- Arcade signage
local arcadeSign = createPart({
	Name = "ArcadeSign",
	Size = Vector3.new(16, 4, 1),
	CFrame = CFrame.new(arcadeBaseX, 14, arcadeBaseZ - 8),
	Color = C.NeonPink,
	Material = Enum.Material.Neon,
	Parent = arcadeFolder,
})
addSurfaceGui(arcadeSign, {
	Face = Enum.NormalId.Front,
	BgColor = C.NeonPink,
	Title = "ARCADE",
	TextColor = Color3.new(1, 1, 1),
})

-- 4 arcade cabinets
for i = 0, 3 do
	local cabX = arcadeBaseX - 8 + i * 6
	local cabZ = arcadeBaseZ

	local cabFolder = makeFolder("ArcadeCab_" .. i, arcadeFolder)

	-- Cabinet body
	createPart({
		Name = "CabinetBody",
		Size = Vector3.new(4, 7, 3),
		CFrame = CFrame.new(cabX, 3.5, cabZ),
		Color = C.ArcadeDark,
		Parent = cabFolder,
	})

	-- Screen area
	local cabScreen = createPart({
		Name = "CabinetScreen",
		Size = Vector3.new(3, 3, 0.3),
		CFrame = CFrame.new(cabX, 5.5, cabZ + 1.5),
		Color = C.ScreenBlue,
		Parent = cabFolder,
	})
	addSurfaceGui(cabScreen, {
		Face = Enum.NormalId.Front,
		BgColor = Color3.fromRGB(20, 20, 40),
		Title = "PLAY",
		TextColor = C.NeonPink,
	})
	addLight(cabScreen, "SurfaceLight", {
		Color = C.NeonBlue,
		Brightness = 0.4,
		Range = 6,
		Face = Enum.NormalId.Front,
	})

	-- Control panel (angled)
	createPart({
		Name = "ControlPanel",
		Size = Vector3.new(3.5, 0.5, 2),
		CFrame = CFrame.new(cabX, 3.2, cabZ + 2) * CFrame.Angles(math.rad(-20), 0, 0),
		Color = C.MetalDark,
		Parent = cabFolder,
	})

	-- Cabinet top (slight overhang)
	createPart({
		Name = "CabinetTop",
		Size = Vector3.new(4.5, 0.5, 3.5),
		CFrame = CFrame.new(cabX, 7.25, cabZ),
		Color = C.ArcadeDark,
		Parent = cabFolder,
	})

	-- Neon accent strip on top
	createNeonStrip("CabinetNeon",
		Vector3.new(3.5, 0.3, 0.3),
		CFrame.new(cabX, 7.6, cabZ + 1.5),
		C.NeonPink, cabFolder)
end

-- === GAMING TABLE (near arcade) ===
local tableFolder = makeFolder("GamingTable", Activities)
local tablePos = Vector3.new(arcadeBaseX + 5, 0, arcadeBaseZ + 12)

createPart({
	Name = "TableTop",
	Size = Vector3.new(10, 0.5, 6),
	CFrame = CFrame.new(tablePos.X, 3.25, tablePos.Z),
	Color = C.SeatDarkPink,
	Parent = tableFolder,
})
-- Table legs
for _, off in ipairs({{-4, -2}, {4, -2}, {-4, 2}, {4, 2}}) do
	createPart({
		Name = "TableLeg",
		Size = Vector3.new(0.8, 3, 0.8),
		CFrame = CFrame.new(tablePos.X + off[1], 1.5, tablePos.Z + off[2]),
		Color = C.MetalDark,
		Parent = tableFolder,
	})
end
-- Chairs around table
for _, off in ipairs({{-5.5, 0}, {5.5, 0}, {0, -3.5}, {0, 3.5}}) do
	createPart({
		Name = "Chair",
		Size = Vector3.new(2.5, 2.5, 2.5),
		CFrame = CFrame.new(tablePos.X + off[1], 1.25, tablePos.Z + off[2]),
		Color = C.SeatPink,
		Parent = tableFolder,
	})
end

-- === FOOD TRUCK (East side) ===
local truckFolder = makeFolder("FoodTruck", Activities)
local truckX = 72
local truckZ = 25

-- Truck body
createPart({
	Name = "TruckBody",
	Size = Vector3.new(8, 7, 14),
	CFrame = CFrame.new(truckX, 3.5, truckZ),
	Color = C.FoodTruckPink,
	Parent = truckFolder,
})

-- Truck roof (slightly larger)
createPart({
	Name = "TruckRoof",
	Size = Vector3.new(9, 0.5, 15),
	CFrame = CFrame.new(truckX, 7.25, truckZ),
	Color = C.WarmPink,
	Parent = truckFolder,
})

-- Serving window
createPart({
	Name = "ServingWindow",
	Size = Vector3.new(0.3, 3.5, 6),
	CFrame = CFrame.new(truckX - 4, 4.5, truckZ),
	Color = C.StageWhite,
	Material = Enum.Material.Glass,
	Transparency = 0.4,
	Parent = truckFolder,
})

-- Counter shelf
createPart({
	Name = "Counter",
	Size = Vector3.new(2, 0.4, 6),
	CFrame = CFrame.new(truckX - 5, 3, truckZ),
	Color = C.StageWhite,
	Parent = truckFolder,
})

-- Truck wheels (4 cylinders)
for _, wOff in ipairs({{-3, -5.5}, {-3, 5.5}, {3, -5.5}, {3, 5.5}}) do
	createPart({
		Name = "TruckWheel",
		Shape = "Cylinder",
		Size = Vector3.new(1.5, 2.5, 2.5),
		CFrame = CFrame.new(truckX + wOff[1], 1.25, truckZ + wOff[2]) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.MetalDark,
		Parent = truckFolder,
	})
end

-- Truck sign
local truckSign = createPart({
	Name = "TruckSign",
	Size = Vector3.new(0.3, 2, 8),
	CFrame = CFrame.new(truckX - 4.2, 6, truckZ),
	Color = C.NeonPink,
	Material = Enum.Material.Neon,
	Parent = truckFolder,
})
addSurfaceGui(truckSign, {
	Face = Enum.NormalId.Left,
	BgColor = C.NeonPink,
	Title = "SNACKS",
	TextColor = Color3.new(1, 1, 1),
})

-- === LOUNGE AREA (East side, near truck) ===
local loungeFolder = makeFolder("LoungeZone", Activities)
local loungeX = 72
local loungeZ = -20

-- Circular seating arrangement
for i = 1, 5 do
	local angle = math.rad((i - 1) * 72)
	local bx = loungeX + math.cos(angle) * 6
	local bz = loungeZ + math.sin(angle) * 6

	createPart({
		Name = "LoungeChair_" .. i,
		Size = Vector3.new(4, 2.5, 4),
		CFrame = CFrame.new(bx, 1.25, bz),
		Color = C.SeatPink,
		Parent = loungeFolder,
	})
end

-- Center low table
createPart({
	Name = "LoungeTable",
	Shape = "Cylinder",
	Size = Vector3.new(1.5, 5, 5),
	CFrame = CFrame.new(loungeX, 0.75, loungeZ) * CFrame.Angles(0, 0, math.rad(90)),
	Color = C.StageWhite,
	Parent = loungeFolder,
})


-- ################################################################
--          PHASE 8: LIGHTING & SPAWNS
-- ################################################################

-- === OVERHEAD SPOTLIGHTS (ring around runway) ===
local spotR = 45
local spotCount = 8

for i = 1, spotCount do
	local angle = math.rad((i - 1) * (360 / spotCount))
	local sx = math.cos(angle) * spotR
	local sz = math.sin(angle) * spotR

	local mount = createPart({
		Name = "SpotlightMount_" .. i,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(sx, 40, sz),
		Color = C.MetalDark,
		CanCollide = false,
		Parent = LightingFolder,
	})
	addLight(mount, "SpotLight", {
		Color = (i % 2 == 0) and C.NeonSoftPink or C.StageWhite,
		Brightness = 1.5,
		Range = 45,
		Angle = 40,
		Face = Enum.NormalId.Bottom,
	})
end

-- === AMBIENT POINT LIGHTS (scattered for fill) ===
local ambientPositions = {
	Vector3.new(0, 30, 0),     -- center overhead
	Vector3.new(-50, 25, 0),   -- west
	Vector3.new(50, 25, 0),    -- east
	Vector3.new(0, 25, -50),   -- north
	Vector3.new(0, 25, 50),    -- south
}
for idx, apos in ipairs(ambientPositions) do
	local amb = createPart({
		Name = "AmbientLight_" .. idx,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(apos),
		Transparency = 1,
		CanCollide = false,
		Parent = LightingFolder,
	})
	addLight(amb, "PointLight", {
		Color = C.NeonSoftPink,
		Brightness = 0.4,
		Range = 60,
	})
end

-- === WALL SCONCE LIGHTS ===
local sconceSpacing = 30
for z = -90, 90, sconceSpacing do
	for _, xSign in ipairs({-1, 1}) do
		local sconce = createPart({
			Name = "WallSconce",
			Size = Vector3.new(2, 2, 1),
			CFrame = CFrame.new(xSign * (half - 1.5), 12, z),
			Color = C.Metal,
			Parent = LightingFolder,
		})
		addLight(sconce, "PointLight", {
			Color = C.NeonSoftPink,
			Brightness = 0.6,
			Range = 20,
		})
		-- Neon backing
		createPart({
			Name = "SconceGlow",
			Size = Vector3.new(0.3, 3, 2),
			CFrame = CFrame.new(xSign * (half - 0.5), 12, z),
			Color = C.NeonPink,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = LightingFolder,
		})
	end
end

-- === SPAWN LOCATIONS ===
for i = 1, D.SPAWN_COUNT do
	local angle = math.rad((i - 1) * (360 / D.SPAWN_COUNT) + 22.5)
	local sx = math.cos(angle) * D.SPAWN_RADIUS
	local sz = math.sin(angle) * D.SPAWN_RADIUS

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPoint_" .. i
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(sx, 0.5, sz) * CFrame.Angles(0, math.atan2(-sx, -sz), 0)
	spawn.Color = C.Lavender
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Transparency = 0.5
	spawn.CanCollide = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Parent = SpawnsFolder

	-- Subtle neon ring around spawn
	createPart({
		Name = "SpawnGlow_" .. i,
		Shape = "Cylinder",
		Size = Vector3.new(0.2, 7, 7),
		CFrame = CFrame.new(sx, 0.1, sz) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.NeonPurple,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Transparency = 0.4,
		Parent = SpawnsFolder,
	})
end


-- ################################################################
--          SOCIAL SPOTLIGHT PLAZA SIGN (top, above back wall)
-- ################################################################

local signFolder = makeFolder("Signage", Structure)

-- Main sign backing
createPart({
	Name = "MainSign_Back",
	Size = Vector3.new(60, 6, 2),
	CFrame = CFrame.new(0, wH - 3, -half + 1),
	Color = C.DarkAccent,
	Parent = signFolder,
})

-- Sign text (neon)
local signText = createPart({
	Name = "MainSign_Text",
	Size = Vector3.new(58, 5, 0.5),
	CFrame = CFrame.new(0, wH - 3, -half + 2.3),
	Color = C.SignGold,
	Material = Enum.Material.Neon,
	Parent = signFolder,
})
addSurfaceGui(signText, {
	Face = Enum.NormalId.Front,
	BgColor = C.DarkAccent,
	Title = "SOCIAL SPOTLIGHT PLAZA",
	TextColor = C.SignGold,
})
addLight(signText, "SurfaceLight", {
	Color = C.SignGold,
	Brightness = 1,
	Range = 20,
	Face = Enum.NormalId.Front,
})


-- ################################################################
--          BUILDING FACADES (outer ring entrances)
-- ################################################################

local facadeFolder = makeFolder("BuildingFacades", Structure)

local facades = {
	{
		name = "FashionStudio",
		label = "FASHION STUDIO",
		pos = CFrame.new(0, 0, -D.BUILDING_DIST),
		rot = 0,
		accentColor = C.NeonHotPink,
	},
	{
		name = "TalentStage",
		label = "TALENT STAGE",
		pos = CFrame.new(D.BUILDING_DIST, 0, 0),
		rot = -90,
		accentColor = C.NeonPurple,
	},
	{
		name = "Arcade",
		label = "ARCADE",
		pos = CFrame.new(-D.BUILDING_DIST, 0, 0),
		rot = 90,
		accentColor = C.NeonBlue,
	},
	{
		name = "ChallengeZone",
		label = "CHALLENGE LAB",
		pos = CFrame.new(0, 0, D.BUILDING_DIST),
		rot = 180,
		accentColor = C.NeonSoftPink,
	},
}

for _, f in ipairs(facades) do
	local ff = makeFolder(f.name, facadeFolder)
	local rotCF = CFrame.Angles(0, math.rad(f.rot), 0)
	local baseCF = f.pos * rotCF

	-- Main facade wall
	createPart({
		Name = "FacadeWall",
		Size = Vector3.new(D.BUILDING_W, D.BUILDING_H, D.BUILDING_D),
		CFrame = baseCF * CFrame.new(0, D.BUILDING_H / 2, 0),
		Color = C.WallBase,
		Parent = ff,
	})

	-- Entrance opening (dark inset to suggest doorway)
	createPart({
		Name = "EntranceDoor",
		Size = Vector3.new(12, 14, D.BUILDING_D + 1),
		CFrame = baseCF * CFrame.new(0, 7, 0),
		Color = C.DarkAccent,
		Transparency = 0.3,
		Parent = ff,
	})

	-- Neon sign above entrance
	local facadeSign = createPart({
		Name = "FacadeSign",
		Size = Vector3.new(20, 4, 0.5),
		CFrame = baseCF * CFrame.new(0, 18, -D.BUILDING_D / 2 - 0.5),
		Color = f.accentColor,
		Material = Enum.Material.Neon,
		Parent = ff,
	})
	addSurfaceGui(facadeSign, {
		Face = Enum.NormalId.Front,
		BgColor = f.accentColor,
		Title = f.label,
		TextColor = Color3.new(1, 1, 1),
	})
	addLight(facadeSign, "SurfaceLight", {
		Color = f.accentColor,
		Brightness = 1,
		Range = 15,
		Face = Enum.NormalId.Front,
	})

	-- Neon accent frame around entrance
	-- Top
	createNeonStrip("EntranceNeon_Top",
		Vector3.new(14, 0.4, 0.4),
		baseCF * CFrame.new(0, 14.5, -D.BUILDING_D / 2 - 0.3),
		f.accentColor, ff)
	-- Sides
	for _, xOff in ipairs({-6.5, 6.5}) do
		createNeonStrip("EntranceNeon_Side",
			Vector3.new(0.4, 14, 0.4),
			baseCF * CFrame.new(xOff, 7, -D.BUILDING_D / 2 - 0.3),
			f.accentColor, ff)
	end

	-- Pillar columns flanking entrance
	for _, xOff in ipairs({-10, 10}) do
		createPillar("FacadePillar",
			baseCF * CFrame.new(xOff, D.BUILDING_H / 2, -D.BUILDING_D / 2 - 1).Position,
			D.BUILDING_H, 1.2, C.Metal, ff)
	end
end


-- ################################################################
--                     BUILD COMPLETE
-- ################################################################

print("═══════════════════════════════════════════")
print("  ✅ SOCIAL SPOTLIGHT PLAZA BUILD COMPLETE")
print("  📁 Folder: Workspace > SocialSpotlightPlaza")
print("  📊 Total zones: 9 sub-folders")
print("═══════════════════════════════════════════")
