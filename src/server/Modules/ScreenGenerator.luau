local ScreenGenerator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local AVATAR_COLORS = {
	Color3.fromRGB(255, 217, 227),
	Color3.fromRGB(255, 195, 113),
	Color3.fromRGB(177, 197, 255),
	Color3.fromRGB(255, 243, 173)
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

local function createCircle(parent, size, position, color)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	return frame
end

local function createBar(parent, size, position, color)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	return frame
end

function ScreenGenerator.decorate(part, seed)
	seed = seed or os.clock()
	math.randomseed(math.floor(seed * 1000))
	for _, face in ipairs(Constants.ScreenFaces) do
		local gui = createSurfaceGui(part, face)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Constants.Colors.ScreenBackground
		bg.BorderSizePixel = 0
		bg.Parent = gui

		local accent = Instance.new("Frame")
		accent.Size = UDim2.new(0.9, 0, 0.12, 0)
		accent.Position = UDim2.new(0.05, 0, 0.05, 0)
		accent.BackgroundColor3 = Constants.Colors.ScreenAccent
		accent.BorderSizePixel = 0
		accent.Parent = bg
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = accent

		for i = 1, 4 do
			local size = math.random(40, 60) / 100
			local x = 0.1 + (i - 1) * 0.2
			createCircle(
				bg,
				UDim2.new(size, 0, size, 0),
				UDim2.new(x, 0, 0.35, 0),
				AVATAR_COLORS[((i + math.random(1, 4)) % #AVATAR_COLORS) + 1]
			)
		end

		for i = 1, 3 do
			local width = math.random(20, 40) / 100
			createBar(
				bg,
				UDim2.new(width, 0, 0.05, 0),
				UDim2.new(0.05 + (i - 1) * 0.25, 0, 0.8, 0),
				Constants.Colors.ScreenAccent:Lerp(Constants.Colors.NeonPrimary, i / 3)
			)
		end
	end
end

return ScreenGenerator
