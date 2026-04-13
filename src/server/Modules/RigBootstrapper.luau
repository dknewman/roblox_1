local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local RigBootstrapper = {}

local function loadAsset(assetId: number): Model?
	local ok, asset = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not asset then
		warn(`[RigBootstrapper] Failed to load asset {assetId}: {asset}`)
		return nil
	end

	local model = asset:FindFirstChildWhichIsA("Model")
	if not model then
		warn(`[RigBootstrapper] Asset {assetId} does not contain a Model instance`)
		asset:Destroy()
		return nil
	end

	model.Parent = nil
	asset:Destroy()
	return model
end

function RigBootstrapper.ensureServerStorageRig(rigName: string, assetId: number?): Model?
	local existing = ServerStorage:FindFirstChild(rigName)
	if existing and existing:IsA("Model") then
		return existing
	end

	if not assetId then
		warn(`[RigBootstrapper] Missing asset ID for rig {rigName}`)
		return nil
	end

	local rig = loadAsset(assetId)
	if not rig then
		return nil
	end

	rig.Name = rigName
	rig.Parent = ServerStorage
	return rig
end

return RigBootstrapper
