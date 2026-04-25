--!strict
-- Roblox Studio plugin to batch-import the Baddies FBX avatars directly into ReplicatedStorage/Characters.
-- Requires Studio beta feature "Avatar Importer API" to be enabled.

local ToolbarName = "Baddies Tools"
local ButtonText = "Batch Import"
local ButtonTooltip = "Import Blender-exported Baddies avatars into ReplicatedStorage/Characters"

local BootButtonText = "Accessory → Boots"
local BootButtonTooltip = "Convert selected MeshParts into a boot accessory"

local BASE_PATH = "/Users/ghost/REPOS/Roblox/my-new-game/Assets/Characters"
local TARGET_FOLDER_NAME = "Characters"

local avatars = {
    { name = "Blonde", path = BASE_PATH .. "/Blonde/FBX/Blonde_R15.fbx" },
    { name = "BrunetteBlack", path = BASE_PATH .. "/BrunetteBlack/FBX/BrunetteBlack_R15.fbx" },
    { name = "LeaderPink", path = BASE_PATH .. "/LeaderPink/FBX/LeaderPink_R15.fbx" },
    { name = "LilacBucket", path = BASE_PATH .. "/LilacBucket/FBX/LilacBucket_R15.fbx" },
}

local toolbar = plugin:CreateToolbar(ToolbarName)
local importButton = toolbar:CreateButton(ButtonText, ButtonTooltip, "rbxassetid://4458901886")
local bootButton = toolbar:CreateButton(BootButtonText, BootButtonTooltip, "rbxassetid://4458901886")

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AvatarImporterService: any do
    local success, svc = pcall(game.GetService, game, "AvatarImporterService")
    if success then
        AvatarImporterService = svc
    else
        AvatarImporterService = nil
        warn("[Baddies Tools] AvatarImporterService not available (enable Avatar Importer API beta feature). Batch import button will be disabled.")
    end
end

local function ensureCharacterFolder()
    local folder = ReplicatedStorage:FindFirstChild(TARGET_FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = TARGET_FOLDER_NAME
        folder.Parent = ReplicatedStorage
    end
    return folder
end

local function importAvatar(def)
    local folder = ensureCharacterFolder()
    print(string.format("[Baddies Importer] Importing %s from %s", def.name, def.path))

    local options = AvatarImporterService:GetImportOptions(Enum.AvatarImporterRigType.R15)
    options.RigType = Enum.AvatarImporterRigType.R15
    options.Unit = Enum.AssetImportUnit.Meter
    options.RigScale = Enum.AvatarImporterRigScale.Medium
    options.Name = def.name

    local ok, resultOrErr = pcall(function()
        return AvatarImporterService:ImportRigAsync(def.path, options)
    end)

    if not ok then
        warn(string.format("Failed to import %s: %s", def.name, resultOrErr))
        return
    end

    local rigModel = resultOrErr
    rigModel.Name = def.name
    rigModel.Parent = folder
    Selection:Set({ rigModel })
    print(string.format("[Baddies Importer] %s imported successfully", def.name))
end

local function runBatch()
    if not AvatarImporterService then
        return
    end

    importButton.Enabled = false
    for _, avatar in ipairs(avatars) do
        importAvatar(avatar)
    end
    importButton.Enabled = true
end

local function convertSelectionToBootAccessory()
    local selection = Selection:Get()
    if #selection == 0 then
        warn("[Baddies Tools] Select a MeshPart or Model before converting to accessory")
        return
    end

    local source = selection[1]
    local meshPart = source:IsA("MeshPart") and source or source:FindFirstChildWhichIsA("MeshPart")
    if not meshPart then
        warn("[Baddies Tools] Selection does not contain a MeshPart")
        return
    end

    local accessory = Instance.new("Accessory")
    accessory.Name = meshPart.Name .. "Accessory"

    local handle = meshPart:Clone()
    handle.Name = "Handle"
    handle.Parent = accessory

    local bbox = meshPart.Size
    local largest = math.max(bbox.X, bbox.Y, bbox.Z)
    if largest > 6 then
        local shrink = 4 / largest
        handle.Size = bbox * shrink
    end

    local leftAttach = Instance.new("Attachment")
    leftAttach.Name = "LeftFootAttachment"
    leftAttach.Position = Vector3.new(-handle.Size.X / 4, -handle.Size.Y / 2, 0)
    leftAttach.Parent = handle

    local rightAttach = leftAttach:Clone()
    rightAttach.Name = "RightFootAttachment"
    rightAttach.Position = Vector3.new(handle.Size.X / 4, -handle.Size.Y / 2, 0)
    rightAttach.Parent = handle

    accessory.Parent = workspace
    Selection:Set({ accessory })

    local dest = ServerStorage:FindFirstChild("LayeredAccessories")
    if not dest then
        dest = Instance.new("Folder")
        dest.Name = "LayeredAccessories"
        dest.Parent = ServerStorage
    end
    accessory.Parent = dest

    local response = plugin:PromptSaveToRoblox(accessory)
    if response ~= Enum.AssetUploadStatus.Success then
        warn("[Baddies Tools] Save to Roblox canceled or failed")
    end

    print("[Baddies Tools] Boot accessory ready in ServerStorage.LayeredAccessories")
end

if not AvatarImporterService then
    importButton.Enabled = false
end

importButton.Click:Connect(runBatch)
bootButton.Click:Connect(convertSelectionToBootAccessory)
