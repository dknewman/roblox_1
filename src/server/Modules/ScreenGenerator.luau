--[[
	ScreenGenerator - Creates stylized social media content on billboard screens
	Generates cyan-blue backgrounds with avatar silhouettes and social content
	matching the reference image's digital display aesthetic.
]]

local ScreenGenerator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- Avatar accent colors (pastel tones for character silhouettes)
local AVATAR_COLORS = {
	Color3.fromRGB(255, 195, 215),  -- pink
	Color3.fromRGB(255, 210, 130),  -- gold
	Color3.fromRGB(165, 195, 255),  -- blue
	Color3.fromRGB(255, 235, 165),  -- yellow
	Color3.fromRGB(190, 255, 200),  -- mint
	Color3.fromRGB(220, 180, 255),  -- lavender
}

-- Skin/body tones for avatar silhouettes
local SKIN_TONES = {
	Color3.fromRGB(255, 220, 185),
	Color3.fromRGB(210, 170, 130),
	Color3.fromRGB(165, 120, 85),
	Color3.fromRGB(240, 200, 160),
	Color3.fromRGB(190, 145, 105),
}

local function createSurfaceGui(part, face)
	local gui = Instance.new("SurfaceGui")
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Face = face or Enum.NormalId.Front
	gui.ClipsDescendants = true
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Parent = part
	return gui
end

local function makeFrame(parent, size, position, color, transparency)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local function makeRounded(parent, size, position, color, radius)
	local frame = makeFrame(parent, size, position, color)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 8)
	corner.Parent = frame
	return frame
end

local function makeCircle(parent, size, position, color)
	local frame = makeFrame(parent, size, position, color)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	return frame
end

local function makeText(parent, size, position, text, textColor, fontSize)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = text
	label.TextScaled = fontSize == nil
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- Creates an avatar silhouette (head circle + body rectangle)
local function makeAvatarSilhouette(parent, xPos, scale, rng)
	local skinIdx = rng:NextInteger(1, #SKIN_TONES)
	local accentIdx = rng:NextInteger(1, #AVATAR_COLORS)
	local skinColor = SKIN_TONES[skinIdx]
	local shirtColor = AVATAR_COLORS[accentIdx]

	local headSize = 0.08 * scale
	local bodyW = 0.07 * scale
	local bodyH = 0.12 * scale

	-- Body (rounded rect)
	makeRounded(
		parent,
		UDim2.new(bodyW, 0, bodyH, 0),
		UDim2.new(xPos - bodyW / 2, 0, 0.55, 0),
		shirtColor,
		UDim.new(0.15, 0)
	)

	-- Head (circle)
	makeCircle(
		parent,
		UDim2.new(headSize, 0, headSize, 0),
		UDim2.new(xPos - headSize / 2, 0, 0.55 - headSize - 0.01, 0),
		skinColor
	)

	-- Hair (smaller circle on top)
	local hairSize = headSize * 0.7
	makeCircle(
		parent,
		UDim2.new(hairSize, 0, hairSize * 0.5, 0),
		UDim2.new(xPos - hairSize / 2, 0, 0.55 - headSize - 0.01 - hairSize * 0.15, 0),
		AVATAR_COLORS[(accentIdx % #AVATAR_COLORS) + 1]:Lerp(Color3.new(0, 0, 0), 0.3)
	)
end

function ScreenGenerator.decorate(part, seed)
	seed = seed or os.clock()
	local rng = Random.new(math.floor(seed * 1000))

	for _, face in ipairs(Constants.ScreenFaces) do
		local gui = createSurfaceGui(part, face)

		-- Bright cyan background (matching reference screens)
		local bg = makeFrame(
			gui,
			UDim2.fromScale(1, 1),
			UDim2.new(),
			Constants.Colors.ScreenCyan
		)

		-- Subtle gradient overlay
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 180, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 210, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 160, 240)),
		})
		gradient.Rotation = rng:NextInteger(0, 1) * 180
		gradient.Parent = bg

		-- Top banner bar
		local bannerColor = Color3.fromRGB(
			rng:NextInteger(200, 255),
			rng:NextInteger(50, 120),
			rng:NextInteger(150, 220)
		)
		makeRounded(
			bg,
			UDim2.new(0.85, 0, 0.08, 0),
			UDim2.new(0.075, 0, 0.04, 0),
			bannerColor,
			UDim.new(0.3, 0)
		)

		-- Banner text
		makeText(
			bg,
			UDim2.new(0.7, 0, 0.07, 0),
			UDim2.new(0.12, 0, 0.045, 0),
			rng:NextInteger(1, 3) == 1 and "FEATURED CREATORS" or
			rng:NextInteger(1, 2) == 1 and "NOW TRENDING" or "SPOTLIGHT",
			Color3.new(1, 1, 1)
		)

		-- Avatar silhouettes (3-5 characters)
		local avatarCount = rng:NextInteger(3, 5)
		for i = 1, avatarCount do
			local xPos = 0.1 + (i - 1) * (0.8 / avatarCount) + (0.8 / avatarCount) / 2
			local scale = 0.8 + rng:NextNumber() * 0.4
			makeAvatarSilhouette(bg, xPos, scale, rng)
		end

		-- Bottom info bars
		for i = 1, 3 do
			local barW = 0.12 + rng:NextNumber() * 0.15
			local barColor = Constants.Colors.ScreenAccent:Lerp(Color3.new(1, 1, 1), 0.3 + i * 0.1)
			makeRounded(
				bg,
				UDim2.new(barW, 0, 0.04, 0),
				UDim2.new(0.05 + (i - 1) * 0.22, 0, 0.88, 0),
				barColor,
				UDim.new(0.4, 0)
			)
		end

		-- Decorative corner accents
		for _, corner in ipairs({
			UDim2.new(0.02, 0, 0.02, 0),
			UDim2.new(0.93, 0, 0.02, 0),
			UDim2.new(0.02, 0, 0.93, 0),
			UDim2.new(0.93, 0, 0.93, 0),
		}) do
			makeCircle(
				bg,
				UDim2.new(0.03, 0, 0.03, 0),
				corner,
				Color3.new(1, 1, 1)
			)
		end
	end
end

return ScreenGenerator
