local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local LightingController = {}

local function ensureEffect(className, props)
	local effect = Lighting:FindFirstChild(className)
	if not effect then
		effect = Instance.new(className)
		effect.Name = className
		effect.Parent = Lighting
	end
	for key, value in pairs(props) do
		effect[key] = value
	end
	return effect
end

function LightingController.apply()
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(40, 10, 60)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 20, 60)
	Lighting.ColorShift_Bottom = Color3.fromRGB(20, 0, 30)
	Lighting.ColorShift_Top = Color3.fromRGB(120, 0, 100)
	Lighting.Brightness = 3

	ensureEffect("BloomEffect", {
		Intensity = 1.8,
		Size = 24,
		Threshold = 0.8
	})

	ensureEffect("ColorCorrectionEffect", {
		TintColor = Color3.fromRGB(255, 180, 255),
		Brightness = 0.05,
		Contrast = 0.12,
		Saturation = 0.25
	})

	ensureEffect("DepthOfFieldEffect", {
		FarIntensity = 0.2,
		FocusDistance = 80,
		InFocusRadius = 80,
		NearIntensity = 0.1
	})

	local stageLight = workspace:FindFirstChild(Constants.HubName)
	if stageLight then
		for _, part in stageLight:GetDescendants() do
			if part:IsA("BasePart") and part.Material == Enum.Material.Neon and not part:FindFirstChildOfClass("PointLight") then
				local point = Instance.new("PointLight")
				point.Brightness = 1.5
				point.Range = 30
				point.Color = part.Color
				point.Parent = part
			end
		end
	end
end

return LightingController
