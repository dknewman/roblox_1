--[[
	CharacterCreator - Applies outfits based on gender selection.
	Uses LoadCharacterWithHumanoidDescription so the character spawns
	with the correct look instantly (no flash/double-load).
]]

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local FirebaseLogger = require(script.Parent:WaitForChild("FirebaseLogger"))
local FeatureFlags = require(script.Parent:WaitForChild("FeatureFlags"))

local CharacterCreator = {}

-- Cache built descriptions so bundle API calls only happen once per gender
local descriptionCache: { [string]: HumanoidDescription } = {}

-- Apply body bundle to a HumanoidDescription
-- If useDefaultHead is true, skips the bundle's head mesh (keeps normal Roblox head)
local function applyBundle(desc: HumanoidDescription, bundleId: number, useDefaultHead: boolean?)
	local ok, info = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	if not ok or not info then
		warn(`[CharacterCreator] Failed to load bundle {bundleId}: {info}`)
		return
	end

	for _, item in info.Items do
		if item.Type == "UserOutfit" then
			local bundleOk, bundleDesc = pcall(function()
				return Players:GetHumanoidDescriptionFromOutfitId(item.Id)
			end)
			if bundleOk and bundleDesc then
				-- Body parts (skip Head if using default)
				if not useDefaultHead then
					desc.Head = bundleDesc.Head
					desc.HeadScale = bundleDesc.HeadScale
					desc.Face = bundleDesc.Face
				end
				desc.Torso = bundleDesc.Torso
				desc.LeftArm = bundleDesc.LeftArm
				desc.RightArm = bundleDesc.RightArm
				desc.LeftLeg = bundleDesc.LeftLeg
				desc.RightLeg = bundleDesc.RightLeg
				-- Body scales
				desc.BodyTypeScale = bundleDesc.BodyTypeScale
				desc.ProportionScale = bundleDesc.ProportionScale
				desc.WidthScale = bundleDesc.WidthScale
				desc.HeightScale = bundleDesc.HeightScale
				desc.DepthScale = bundleDesc.DepthScale
				-- Body colors (all parts, including head for consistent skin tone)
				desc.HeadColor = bundleDesc.HeadColor
				desc.TorsoColor = bundleDesc.TorsoColor
				desc.LeftArmColor = bundleDesc.LeftArmColor
				desc.RightArmColor = bundleDesc.RightArmColor
				desc.LeftLegColor = bundleDesc.LeftLegColor
				desc.RightLegColor = bundleDesc.RightLegColor
				return
			end
		end
	end
end

-- Build a HumanoidDescription for the given gender (cached after first call)
function CharacterCreator.buildDescription(gender: string): HumanoidDescription?
	local outfitDef = Constants.Outfits[gender]
	if not outfitDef then return nil end

	if not descriptionCache[gender] then
		local desc = Instance.new("HumanoidDescription")

		if outfitDef.BundleId then
			applyBundle(desc, outfitDef.BundleId, outfitDef.UseDefaultHead)
		end

		-- Classic clothing
		desc.Shirt = outfitDef.ClassicShirt or 0
		desc.Pants = outfitDef.ClassicPants or 0
		desc.GraphicTShirt = 0

		-- Clear accessories, then set hair if specified
		desc.HatAccessory = ""
		desc.FaceAccessory = ""
		desc.NeckAccessory = ""
		desc.ShouldersAccessory = ""
		desc.FrontAccessory = ""
		desc.BackAccessory = ""
		desc.WaistAccessory = ""
		desc.HairAccessory = outfitDef.HairAccessory or ""

		descriptionCache[gender] = desc
	end

	return descriptionCache[gender]:Clone()
end

-- Spawn a player with the outfit already applied — no flash
function CharacterCreator.spawnWithOutfit(player: Player, gender: string)
	local desc = CharacterCreator.buildDescription(gender)
	if desc then
		local ok, err = pcall(function()
			player:LoadCharacterWithHumanoidDescription(desc)
		end)
		if not ok then
			warn(`[CharacterCreator] LoadCharacterWithHumanoidDescription failed: {err}`)
			player:LoadCharacter()
		end
	else
		player:LoadCharacter()
	end
end

-- Save the gender choice to the player's profile
function CharacterCreator.saveGender(player: Player, gender: string): boolean
	local data = PlayerData.get(player)
	if not data then return false end

	data.Character.Gender = gender
	data.Character.Created = true

	local createdVal = player:FindFirstChild("CharacterCreated")
	if createdVal then
		createdVal.Value = true
	end

	return true
end

-- Initialize: create RemoteEvent and handle gender selection
function CharacterCreator.init(spawnedPlayers: { [number]: true })
	local genderEvent = Instance.new("RemoteEvent")
	genderEvent.Name = "GenderSelected"
	genderEvent.Parent = ReplicatedStorage

	genderEvent.OnServerEvent:Connect(function(player, gender)
		if gender ~= "Male" and gender ~= "Female" then return end

		local data = PlayerData.get(player)
		if not data then
			player:LoadCharacter()
			return
		end
		-- Block re-selection unless NewPlayer flag is on
		if data.Character.Created and not FeatureFlags.get("NewPlayer") then return end
		if spawnedPlayers[player.UserId] then return end
		spawnedPlayers[player.UserId] = true

		CharacterCreator.saveGender(player, gender)
		CharacterCreator.spawnWithOutfit(player, gender)

		FirebaseLogger.log("character", "created", {
			userId = player.UserId,
			displayName = player.DisplayName,
			gender = gender,
		})
	end)
end

return CharacterCreator
