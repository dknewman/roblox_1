local Constants = {}

Constants.HubName = "SocialHub"

Constants.Colors = {
	Floor = Color3.fromRGB(250, 244, 250),
	Border = Color3.fromRGB(237, 160, 214),
	NeonPrimary = Color3.fromRGB(255, 140, 220),
	NeonSecondary = Color3.fromRGB(180, 90, 255),
	WallLight = Color3.fromRGB(212, 183, 241),
	Kiosk = Color3.fromRGB(240, 174, 220),
	Vehicle = Color3.fromRGB(255, 94, 188),
	ScreenBackground = Color3.fromRGB(67, 46, 110),
	ScreenAccent = Color3.fromRGB(102, 196, 255)
}

Constants.Dimensions = {
	FloorSize = Vector3.new(220, 1, 220),
	StagePosition = Vector3.new(0, 2.5, -20),
	CenterY = 0.5,
	RunwayArmLength = 40,
	BalconyHeight = 23
}

Constants.NPC = {
	Count = 38,
	AnimationIds = {
		"rbxassetid://507771019", -- dance
		"rbxassetid://507770818", -- wave
		"rbxassetid://33796059", -- cheer
		"rbxassetid://180435571", -- applaud
	}
}

Constants.ScreenFaces = {
	Enum.NormalId.Front,
	Enum.NormalId.Back
}

return Constants
