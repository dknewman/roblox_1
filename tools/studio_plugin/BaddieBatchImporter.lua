--!strict
-- Roblox Studio plugin to batch-import the Baddies FBX avatars directly into ReplicatedStorage/Characters.
-- Requires Studio beta feature "Avatar Importer API" to be enabled.

local ToolbarName = "Baddies Tools"
local ButtonText = "Batch Import"
local ButtonTooltip = "Import Blender-exported Baddies avatars into ReplicatedStorage/Characters"

local BASE_PATH = "/Users/ghost/REPOS/Roblox/my-new-game/Assets/Characters"
local TARGET_FOLDER_NAME = "Characters"

local avatars = {
    { name = "Blonde", path = BASE_PATH .. "/Blonde/FBX/Blonde_R15.fbx" },
    { name = "BrunetteBlack", path = BASE_PATH .. "/BrunetteBlack/FBX/BrunetteBlack_R15.fbx" },
    { name = "LeaderPink", path = BASE_PATH .. "/LeaderPink/FBX/LeaderPink_R15.fbx" },
    { name = "LilacBucket", path = BASE_PATH .. "/LilacBucket/FBX/LilacBucket_R15.fbx" },
}

local toolbar = plugin:CreateToolbar(ToolbarName)
local button = toolbar:CreateButton(ButtonText, ButtonTooltip, "rbxassetid://4458901886")

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarImporterService: any do
    local success, svc = pcall(game.GetService, game, "AvatarImporterService")
    if success then
        AvatarImporterService = svc
    else
        error("AvatarImporterService is not available. Enable the Avatar Importer API beta feature in Studio (File → Beta Features).")
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
    button.Enabled = false
    for _, avatar in ipairs(avatars) do
        importAvatar(avatar)
    end
    button.Enabled = true
end

button.Click:Connect(function()
    runBatch()
end)
