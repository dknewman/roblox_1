local InsertService = game:GetService("InsertService")

local AccessoryUtil = {}

local function findAccessory(container: Instance): Accessory?
	local accessory = container:FindFirstChildWhichIsA("Accessory")
	if accessory then
		return accessory
	end
	for _, desc in container:GetDescendants() do
		if desc:IsA("Accessory") then
			return desc
		end
	end
	return nil
end

function AccessoryUtil.loadAccessory(assetId: string): Accessory?
	local numericId = tonumber(assetId)
	if not numericId then
		warn(`[AccessoryUtil] Invalid accessory asset ID: {assetId}`)
		return nil
	end

	local ok, asset = pcall(function()
		return InsertService:LoadAsset(numericId)
	end)
	if not ok or not asset then
		warn(`[AccessoryUtil] Failed to load asset {assetId}: {asset}`)
		return nil
	end

	local accessory = findAccessory(asset)
	if not accessory then
		warn(`[AccessoryUtil] Asset {assetId} did not contain an Accessory`)
		asset:Destroy()
		return nil
	end

	local clone = accessory:Clone()
	asset:Destroy()
	return clone
end

function AccessoryUtil.addAccessory(character: Model, accessory: Accessory, label: string?)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		accessory:Destroy()
		warn(`[AccessoryUtil] Humanoid missing when adding accessory {label or accessory.Name}`)
		return false
	end

	local ok, err = pcall(function()
		humanoid:AddAccessory(accessory)
	end)
	if not ok then
		accessory:Destroy()
		warn(`[AccessoryUtil] Failed to AddAccessory {label or accessory.Name}: {err}`)
		return false
	end

	return true
end

function AccessoryUtil.applyAccessoryAsset(character: Model, assetId: string, label: string?)
	if type(assetId) ~= "string" or assetId == "" then
		return false
	end
	local accessory = AccessoryUtil.loadAccessory(assetId)
	if not accessory then
		return false
	end
	return AccessoryUtil.addAccessory(character, accessory, label or assetId)
end

return AccessoryUtil
