--[[
	PlayerData - Persistent player data via ProfileService.
	Wraps ProfileService with a character-creation-ready profile template.

	Usage:
	  local PlayerData = require(...)
	  local data = PlayerData.get(player) -- returns profile.Data or nil
	  data.Character.HairColor = {255, 100, 200}
]]

local Players = game:GetService("Players")

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local FirebaseLogger = require(script.Parent:WaitForChild("FirebaseLogger"))

-- Default profile template — new players start with these values
local ProfileTemplate = {
	-- Character creation
	Character = {
		Created = false, -- true once player finishes character creation
		Gender = "", -- "Male" or "Female"
		BodyType = "Default",
		SkinColor = { 255, 200, 180 },
		HairStyle = "None",
		HairColor = { 50, 30, 20 },
		FaceId = "",
		OutfitTop = "Default",
		OutfitBottom = "Default",
		OutfitTopColor = { 255, 255, 255 },
		OutfitBottomColor = { 100, 100, 100 },
		Accessories = {},
	},

	-- Player stats
	Stats = {
		Coins = 0,
		TotalPlayTime = 0,
		SessionCount = 0,
	},

	-- Player settings / preferences
	Settings = {
		MusicVolume = 0.4,
		Brightness = 0.5,
	},
}

local GameProfileStore = ProfileService.GetProfileStore("PlayerData_v4", ProfileTemplate)

local PlayerData = {}

-- Active profiles keyed by UserId
local profiles: { [number]: any } = {}

-- Load profile when player joins
function PlayerData.loadProfile(player: Player)
	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile == nil then
		player:Kick("Unable to load your data. Please rejoin!")
		FirebaseLogger.log("player_data", "load_failed", { userId = player.UserId })
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile() -- fill in any missing keys from template updates

	profile:ListenToRelease(function()
		profiles[player.UserId] = nil
		player:Kick("Your data was loaded on another server. Please rejoin!")
	end)

	if player:IsDescendantOf(Players) then
		profiles[player.UserId] = profile
		profile.Data.Stats.SessionCount += 1

		-- Sync creation status to client so it knows whether to show character creator
		local createdVal = Instance.new("BoolValue")
		createdVal.Name = "CharacterCreated"
		createdVal.Value = profile.Data.Character.Created
		createdVal.Parent = player

		FirebaseLogger.log("player_data", "loaded", {
			userId = player.UserId,
			displayName = player.DisplayName,
			characterCreated = profile.Data.Character.Created,
			sessionCount = profile.Data.Stats.SessionCount,
		})
	else
		profile:Release()
	end
end

-- Release profile when player leaves
function PlayerData.releaseProfile(player: Player)
	local profile = profiles[player.UserId]
	if profile then
		profile:Release()
		profiles[player.UserId] = nil
	end
end

-- Get a player's data table (returns nil if not loaded yet)
function PlayerData.get(player: Player): ProfileTemplate?
	local profile = profiles[player.UserId]
	return profile and profile.Data or nil
end

-- Check if a player's profile is loaded
function PlayerData.isLoaded(player: Player): boolean
	return profiles[player.UserId] ~= nil
end

-- Save all profiles on server shutdown
game:BindToClose(function()
	for userId, profile in profiles do
		profile:Release()
	end
end)

return PlayerData
