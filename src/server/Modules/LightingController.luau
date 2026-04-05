--[[
	LightingController - Sets up the atmospheric lighting for Social Spotlight Plaza
	Target: soft lavender/purple ambient with colorful neon accents that glow
	without washing out the scene. Think dimmed venue with accent lighting,
	NOT a brightly lit room.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local FirebaseLogger = require(script.Parent.FirebaseLogger)

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
	Lighting.GeographicLatitude = 0
	Lighting.Ambient = Color3.fromRGB(75, 45, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 50, 100)
	Lighting.ColorShift_Bottom = Color3.fromRGB(30, 8, 40)
	Lighting.ColorShift_Top = Color3.fromRGB(140, 50, 130)
	Lighting.Brightness = 0.6
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.15
	Lighting.Technology = Enum.Technology.Future

	-- Bloom — only the hottest neon parts bloom, and gently
	ensureEffect("BloomEffect", {
		Intensity = 0.5,
		Size = 20,
		Threshold = 0.92,
	})

	-- Color correction — pink tint, no brightness boost
	ensureEffect("ColorCorrectionEffect", {
		TintColor = Color3.fromRGB(240, 210, 240),
		Brightness = -0.02,
		Contrast = 0.14,
		Saturation = 0.25,
	})

	-- Depth of field — subtle
	ensureEffect("DepthOfFieldEffect", {
		FarIntensity = 0.12,
		FocusDistance = 100,
		InFocusRadius = 100,
		NearIntensity = 0.06,
	})

	-- Atmosphere — gentle haze
	ensureEffect("Atmosphere", {
		Density = 0.15,
		Offset = 0.4,
		Color = Color3.fromRGB(210, 185, 225),
		Decay = Color3.fromRGB(195, 170, 215),
		Glare = 0.1,
		Haze = 1.2,
	})

	-- Auto-add very dim PointLights to larger Neon parts
	local neonLightCount = 0
	local hub = workspace:FindFirstChild(Constants.HubName)
	if hub then
		for _, part in hub:GetDescendants() do
			if part:IsA("BasePart") and part.Material == Enum.Material.Neon and not part:FindFirstChildOfClass("PointLight") then
				local vol = part.Size.X * part.Size.Y * part.Size.Z
				if vol > 2 then
					local point = Instance.new("PointLight")
					point.Brightness = math.clamp(vol * 0.005, 0.1, 0.4)
					point.Range = math.clamp(vol * 0.08, 3, 12)
					point.Color = part.Color
					point.Shadows = false
					point.Parent = part
					neonLightCount += 1
				end
			end
		end
	end

	FirebaseLogger.log("lighting", "applied", { neonLightCount = neonLightCount })
	print("[LightingController] Atmosphere applied")
end

return LightingController
