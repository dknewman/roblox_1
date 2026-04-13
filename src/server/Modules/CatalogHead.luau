local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CatalogHead = {}

local cachedHead: BasePart?
local femaleOutfit = Constants.Outfits.Female

local function findHead(instance: Instance): BasePart?
	if instance:IsA("BasePart") and instance.Name == "Head" then
		return instance
	end
	for _, child in instance:GetChildren() do
		local found = findHead(child)
		if found then
			return found
		end
	end
	return nil
end

local function loadHeadTemplate(): BasePart?
	if cachedHead then
		return cachedHead
	end

	local assetId = femaleOutfit and femaleOutfit.HeadAssetId
	if not assetId then
		warn("[CatalogHead] Constants.Outfits.Female.HeadAssetId missing")
		return nil
	end

	local ok, asset = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not asset then
		warn(`[CatalogHead] Failed to load asset {assetId}: {asset}`)
		return nil
	end

	local container = asset:FindFirstChildWhichIsA("Model") or asset
	local head = container and findHead(container)
	if head then
		cachedHead = head:Clone()
	else
		warn(`[CatalogHead] Could not find Head in asset {assetId}`)
	end

	asset:Destroy()
	return cachedHead
end

function CatalogHead.apply(character: Model): boolean
	local template = loadHeadTemplate()
	if not template then
		return false
	end

	local oldHead = character:FindFirstChild("Head")
	if not oldHead or not oldHead:IsA("BasePart") then
		return false
	end

	local newHead = template:Clone()
	local scale = femaleOutfit and femaleOutfit.CatalogHeadScale or 1
	if scale and math.abs(scale - 1) > 1e-3 then
		newHead.Size = Vector3.new(
			newHead.Size.X * scale,
			newHead.Size.Y * scale,
			newHead.Size.Z * scale
		)
	end
	newHead.Name = "Head"
	newHead.CFrame = oldHead.CFrame
	newHead.Anchored = false
	newHead.CanCollide = oldHead.CanCollide
	newHead.Massless = oldHead.Massless
	newHead.Transparency = oldHead.Transparency
	local skinColor = femaleOutfit and femaleOutfit.SkinColor
	if skinColor then
		newHead.Color = skinColor
		newHead.Material = Enum.Material.SmoothPlastic
	else
		newHead.Color = oldHead.Color
		newHead.Material = oldHead.Material
	end

	-- Move attachments/Motor6Ds from the old head so cameras/faces still align
	for _, child in oldHead:GetChildren() do
		if child:IsA("Motor6D") or child:IsA("Attachment") then
			child.Parent = newHead
			if child:IsA("Motor6D") then
				if child.Part0 == oldHead then child.Part0 = newHead end
				if child.Part1 == oldHead then child.Part1 = newHead end
			end
		elseif child:IsA("Decal") or child:IsA("SurfaceAppearance") then
			child:Destroy()
		else
			child:Destroy()
		end
	end

	-- Rewire any Motor6Ds elsewhere that reference the old head
	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") then
			if desc.Part0 == oldHead then desc.Part0 = newHead end
			if desc.Part1 == oldHead then desc.Part1 = newHead end
		end
	end

	oldHead:Destroy()
	newHead.Parent = character
	return true
end

return CatalogHead
