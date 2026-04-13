local Constants = {}

Constants.HubName = "SocialHub"

Constants.Colors = {
	-- Floor & Structure
	Floor = Color3.fromRGB(248, 240, 252),
	FloorGrid = Color3.fromRGB(238, 228, 244),
	WallPrimary = Color3.fromRGB(210, 185, 230),
	WallSecondary = Color3.fromRGB(188, 158, 215),
	Ceiling = Color3.fromRGB(232, 222, 242),

	-- Neon accents
	NeonPink = Color3.fromRGB(255, 100, 200),
	NeonHotPink = Color3.fromRGB(255, 50, 170),
	NeonPurple = Color3.fromRGB(180, 80, 255),
	NeonCyan = Color3.fromRGB(80, 200, 255),
	NeonWhite = Color3.fromRGB(210, 185, 225),

	-- Stage
	StagePink = Color3.fromRGB(255, 130, 200),
	StageHotPink = Color3.fromRGB(240, 60, 170),
	StageAccent = Color3.fromRGB(220, 100, 190),

	-- Screens
	ScreenFrame = Color3.fromRGB(55, 38, 90),
	ScreenCyan = Color3.fromRGB(60, 190, 255),
	ScreenAccent = Color3.fromRGB(100, 210, 255),

	-- Props
	KioskPink = Color3.fromRGB(245, 130, 200),
	VehiclePink = Color3.fromRGB(255, 90, 180),
	SeatingPurple = Color3.fromRGB(160, 90, 175),

	-- Stairs & Rails
	StairTread = Color3.fromRGB(155, 118, 88),
	StairRiser = Color3.fromRGB(195, 172, 218),
	RailMetal = Color3.fromRGB(185, 185, 198),
	RailGlass = Color3.fromRGB(215, 225, 255),

	-- Sign
	SignGold = Color3.fromRGB(255, 210, 100),

	-- Portal circle
	CircleDark = Color3.fromRGB(58, 28, 88),
	CircleDivider = Color3.fromRGB(120, 80, 165),

	-- Border/trim
	BorderPink = Color3.fromRGB(237, 160, 214),
	TrimNeon = Color3.fromRGB(255, 180, 240),
}

Constants.Dimensions = {
	FloorSize = Vector3.new(220, 1, 220),
	WallHeight = 42,
	CeilingHeight = 42,
	BalconyHeight = 24,
	StageZ = -76,
	CenterY = 0.5,
}

Constants.NPC = {
	Count = 20,
}

Constants.ScreenFaces = {
	Enum.NormalId.Front,
	Enum.NormalId.Back
}

-- Intro screen: upload pts_intro.png to Roblox and paste the asset ID here
Constants.IntroScreen = {
	ImageId = "rbxassetid://87062994599591",
}

-- Background music: upload eliveta-motivation-474064.mp3 and paste the asset ID
Constants.Music = {
	SoundId = "rbxassetid://84449759831841", -- Replace 0 with your uploaded audio asset ID
	Volume = 0.4,
}

-- Default outfits for character creation
-- All IDs verified via economy.roblox.com/v2/assets/{id}/details
Constants.Outfits = {
	Female = {
		DTIRig = "BaddieFemale",     -- R15 rig from ServerStorage (Avatar Auto-Setup)
		DTIModelId = 76767800092615, -- Roblox asset ID (fallback if not in ServerStorage)
		UseServerStorage = true,     -- load from ServerStorage instead of InsertService
		UseDefaultHead = false,      -- use the model's own head
		HeadAssetId = 113842569610805, -- catalog head mesh to override the custom sculpt
		CatalogHeadScale = 0.92,    -- uniform scale applied to catalog head MeshPart
		HairAccessory = "140198630246272",  -- Voxlore Long Hair (catalog asset)
		LayeredAccessories = {
			"139099128619770", -- tie front top
			"103286965048329", -- ruffle skirt white
		},
		Face = 86487766,             -- Woman Face (feminine, eyelashes)
		SkinColor = Color3.fromRGB(204, 142, 105), -- warm caramel / nougat
		BodyTypeScale = 1,           -- fully proportioned R15 body
		ProportionScale = 0,         -- wider proportions
		HeadScale = 0.50,            -- smaller head to match body proportions
	},
	Male = {
		BundleId = 238,              -- "Man" body bundle (free, official)
		ClassicShirt = 607785314,    -- ROBLOX Jacket (AssetTypeId 11, free)
		ClassicPants = 398633812,    -- Black Jeans with White Shoes (AssetTypeId 12, free)
	},
}

-- Customization catalog
-- Each face entry: { Id = string key, Name = display name, TextureId = Roblox asset ID }
Constants.Faces = {
	{ Id = "baddie_glam", Name = "Baddie Glam", TextureId = "rbxassetid://106110901976339" },
	-- Add more faces here as they are created:
	-- { Id = "soft_doll", Name = "Soft Doll", TextureId = "rbxassetid://XXXXXXXXXX" },
	-- { Id = "fierce_cat", Name = "Fierce Cat", TextureId = "rbxassetid://XXXXXXXXXX" },
}

Constants.DefaultFaceId = "baddie_glam"

-- Feature flags: defaults used when Firebase is unreachable.
-- Remote overrides are fetched from Firebase at /config/featureFlags.json
Constants.FeatureFlags = {
	NPCsEnabled = true,
	MusicEnabled = true,
	IntroScreenEnabled = true,
	NewPlayer = false, -- show new-player onboarding / welcome flow
	Maintenance = false, -- kick players and block joins when true
}

-- Firebase config has moved to src/server/Modules/FirebaseConfig.luau
-- (server-only — never replicated to clients)

return Constants
