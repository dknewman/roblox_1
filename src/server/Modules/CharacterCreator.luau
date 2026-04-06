--[[
	CharacterCreator - Applies outfits based on gender selection.
	Uses LoadCharacterWithHumanoidDescription for face/hair/colors,
	then replaces body parts with cloned DTI MeshParts and welds
	DTI clothing meshes onto the character.
]]

local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local FirebaseLogger = require(script.Parent:WaitForChild("FirebaseLogger"))
local FeatureFlags = require(script.Parent:WaitForChild("FeatureFlags"))

local CharacterCreator = {}

-- Cache built descriptions so API calls only happen once per gender
local descriptionCache: { [string]: HumanoidDescription } = {}

-- DTI rig cache
local dtiRigs: { [string]: {
	parts: { [string]: MeshPart },
	joints: { [string]: { [string]: { C0: CFrame, C1: CFrame } } },
	clothing: { { template: MeshPart, offset: CFrame, bodyPart: string } },
} } = {}

-- R15 body part names (Head kept as default R15, scaled to match DTI body)
local R15_BODY_PARTS = {
	"UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

---------------------------------------------------------------------------
-- DTI Model Loading
---------------------------------------------------------------------------

local function loadDTIModel()
	local outfitDef = Constants.Outfits.Female
	if not outfitDef or not outfitDef.DTIModelId then return end

	local ok, model = pcall(function()
		return InsertService:LoadAsset(outfitDef.DTIModelId)
	end)
	if not ok or not model then
		warn(`[CharacterCreator] Failed to load DTI model: {model}`)
		return
	end

	for _, rig in model:GetDescendants() do
		if rig:IsA("Model") and rig.Name:match("Rig$") then
			local partCache = {}
			local jointCache = {}

			for _, part in rig:GetChildren() do
				if part:IsA("MeshPart") then
					-- Template strips all children; skin color set via Color3 at spawn time
					local template = part:Clone()
					for _, child in template:GetChildren() do
						child:Destroy()
					end
					partCache[part.Name] = template

					-- Cache Motor6D C0/C1 for joint alignment
					local partJoints = {}
					for _, child in part:GetChildren() do
						if child:IsA("Motor6D") then
							partJoints[child.Name] = {
								C0 = child.C0,
								C1 = child.C1,
							}
						end
					end
					if next(partJoints) then
						jointCache[part.Name] = partJoints
					end
				end
			end

			-- Cache clothing meshes from EquippedAccessories
			local clothingCache = {}
			local accessories = rig:FindFirstChild("EquippedAccessories")
			if accessories then
				for _, meshPart in accessories:GetDescendants() do
					if meshPart:IsA("MeshPart") then
						-- Determine which body part this attaches to
						local folder = meshPart.Parent
						local bodyPartName = "UpperTorso"
						if folder:IsA("Folder") and rig:FindFirstChild(folder.Name) then
							bodyPartName = folder.Name
						end

						-- Calculate CFrame offset relative to the body part
						local bodyPart = rig:FindFirstChild(bodyPartName)
						local offset = CFrame.new()
						if bodyPart then
							offset = bodyPart.CFrame:Inverse() * meshPart.CFrame
						end

						-- Clone template, strip welds
						local template = meshPart:Clone()
						for _, child in template:GetChildren() do
							if child:IsA("WeldConstraint") or child:IsA("Weld") then
								child:Destroy()
							end
						end

						table.insert(clothingCache, {
							template = template,
							offset = offset,
							bodyPart = bodyPartName,
						})
					end
				end
			end

			dtiRigs[rig.Name] = {
				parts = partCache,
				joints = jointCache,
				clothing = clothingCache,
			}
			print(`[CharacterCreator] Cached DTI rig: {rig.Name} ({#clothingCache} clothing pieces)`)
		end
	end

	model:Destroy()
	print("[CharacterCreator] DTI model loaded and cached")
end

---------------------------------------------------------------------------
-- DTI Body Application
---------------------------------------------------------------------------

local function applyDTIBody(character: Model, rigName: string, skinColor: Color3?)
	local rigData = dtiRigs[rigName]
	if not rigData then
		warn(`[CharacterCreator] No cached DTI rig: {rigName}`)
		return
	end

	local parts = rigData.parts
	local joints = rigData.joints

	-- Phase 1: Replace each body part with a DTI clone
	local replaced = {}
	for _, partName in R15_BODY_PARTS do
		local dtiTemplate = parts[partName]
		local oldPart = character:FindFirstChild(partName)
		if not dtiTemplate or not oldPart or not oldPart:IsA("MeshPart") then continue end

		-- Clone DTI body part (MeshId baked in, no SurfaceAppearance)
		local newPart = dtiTemplate:Clone()
		newPart.Name = partName
		newPart.CFrame = oldPart.CFrame
		newPart.Transparency = oldPart.Transparency
		newPart.Anchored = false
		newPart.CanCollide = oldPart.CanCollide
		newPart.Color = skinColor or Color3.fromRGB(204, 142, 105)

		-- Move children from old part (skip SurfaceAppearance)
		for _, child in oldPart:GetChildren() do
			if not child:IsA("SurfaceAppearance") then
				child.Parent = newPart
			end
		end

		-- Fix Motor6D self-references in the new part
		for _, child in newPart:GetChildren() do
			if child:IsA("Motor6D") then
				if child.Part0 == oldPart then child.Part0 = newPart end
				if child.Part1 == oldPart then child.Part1 = newPart end
			end
		end

		-- Fix Motor6D references in other character parts
		for _, desc in character:GetDescendants() do
			if desc:IsA("Motor6D") then
				if desc.Part0 == oldPart then desc.Part0 = newPart end
				if desc.Part1 == oldPart then desc.Part1 = newPart end
			end
		end

		oldPart:Destroy()
		newPart.Parent = character
		replaced[partName] = true
	end

	-- Phase 2: Update Motor6D C0/C1 to match DTI proportions
	for _, motor in character:GetDescendants() do
		if not motor:IsA("Motor6D") then continue end

		local hostName = motor.Parent and motor.Parent.Name
		local jointData = joints[hostName] and joints[hostName][motor.Name]
		if not jointData then continue end

		local p0Name = motor.Part0 and motor.Part0.Name
		if p0Name and (replaced[p0Name] or p0Name == "HumanoidRootPart") then
			motor.C0 = jointData.C0
		end

		if hostName and replaced[hostName] then
			motor.C1 = jointData.C1
		end
	end

	-- Phase 3: Weld DTI clothing meshes onto the character
	local clothing = rigData.clothing
	if clothing then
		for _, item in clothing do
			local attachPart = character:FindFirstChild(item.bodyPart)
			if not attachPart then continue end

			local clone = item.template:Clone()
			clone.CFrame = attachPart.CFrame * item.offset
			clone.Anchored = false
			clone.CanCollide = false
			clone.Massless = true

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = clone
			weld.Part1 = attachPart
			weld.Parent = clone

			clone.Parent = character
		end
	end

	-- Match head color to DTI body skin tone
	if skinColor then
		local head = character:FindFirstChild("Head")
		if head then
			head.Color = skinColor
		end
	end

	-- Remove classic Shirt/Pants instances (they don't render on DTI meshes)
	local shirt = character:FindFirstChildOfClass("Shirt")
	if shirt then shirt:Destroy() end
	local pants = character:FindFirstChildOfClass("Pants")
	if pants then pants:Destroy() end

	print(`[CharacterCreator] Applied DTI body: {rigName}`)
end

---------------------------------------------------------------------------
-- Bundle Loading (Male)
---------------------------------------------------------------------------

local function applyBundle(desc: HumanoidDescription, bundleId: number): boolean
	local ok, info = pcall(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end)
	if not ok or not info then
		warn(`[CharacterCreator] Failed to load bundle {bundleId}: {info}`)
		return false
	end

	for _, item in info.Items do
		if item.Type == "UserOutfit" then
			local bundleOk, bundleDesc = pcall(function()
				return Players:GetHumanoidDescriptionFromOutfitId(item.Id)
			end)
			if bundleOk and bundleDesc then
				desc.Head = bundleDesc.Head
				desc.Torso = bundleDesc.Torso
				desc.LeftArm = bundleDesc.LeftArm
				desc.RightArm = bundleDesc.RightArm
				desc.LeftLeg = bundleDesc.LeftLeg
				desc.RightLeg = bundleDesc.RightLeg
				desc.BodyTypeScale = bundleDesc.BodyTypeScale
				desc.ProportionScale = bundleDesc.ProportionScale
				desc.WidthScale = bundleDesc.WidthScale
				desc.HeightScale = bundleDesc.HeightScale
				desc.DepthScale = bundleDesc.DepthScale
				desc.HeadColor = bundleDesc.HeadColor
				desc.TorsoColor = bundleDesc.TorsoColor
				desc.LeftArmColor = bundleDesc.LeftArmColor
				desc.RightArmColor = bundleDesc.RightArmColor
				desc.LeftLegColor = bundleDesc.LeftLegColor
				desc.RightLegColor = bundleDesc.RightLegColor
				desc.Face = bundleDesc.Face
				return true
			end
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Description Builder
---------------------------------------------------------------------------

function CharacterCreator.buildDescription(gender: string): HumanoidDescription?
	local outfitDef = Constants.Outfits[gender]
	if not outfitDef then return nil end

	if not descriptionCache[gender] then
		local desc = Instance.new("HumanoidDescription")

		-- Male uses bundle; Female skips bundles (DTI body applied post-spawn)
		if outfitDef.BundleId then
			applyBundle(desc, outfitDef.BundleId)
		end

		-- Classic clothing (only for non-DTI outfits; DTI uses 3D clothing meshes)
		if not outfitDef.DTIRig then
			desc.Shirt = outfitDef.ClassicShirt or 0
			desc.Pants = outfitDef.ClassicPants or 0
		end
		desc.GraphicTShirt = 0

		-- Face
		if outfitDef.Face then
			desc.Face = outfitDef.Face
		end

		-- Skin color (all body parts for consistency)
		if outfitDef.SkinColor then
			desc.HeadColor = outfitDef.SkinColor
			desc.TorsoColor = outfitDef.SkinColor
			desc.LeftArmColor = outfitDef.SkinColor
			desc.RightArmColor = outfitDef.SkinColor
			desc.LeftLegColor = outfitDef.SkinColor
			desc.RightLegColor = outfitDef.SkinColor
		end

		-- Body proportions
		if outfitDef.BodyTypeScale ~= nil then
			desc.BodyTypeScale = outfitDef.BodyTypeScale
		end
		if outfitDef.ProportionScale ~= nil then
			desc.ProportionScale = outfitDef.ProportionScale
		end
		if outfitDef.HeadScale ~= nil then
			desc.HeadScale = outfitDef.HeadScale
		end

		-- Accessories — clear all, then set hair
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

---------------------------------------------------------------------------
-- Spawn
---------------------------------------------------------------------------

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

	-- Replace body parts with DTI clones + weld clothing
	local outfitDef = Constants.Outfits[gender]
	if outfitDef and outfitDef.DTIRig and player.Character then
		applyDTIBody(player.Character, outfitDef.DTIRig, outfitDef.SkinColor)
	end
end

---------------------------------------------------------------------------
-- Persistence
---------------------------------------------------------------------------

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

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function CharacterCreator.init(spawnedPlayers: { [number]: true })
	-- Load DTI model in background (will be ready before any player clicks gender)
	task.spawn(loadDTIModel)

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
