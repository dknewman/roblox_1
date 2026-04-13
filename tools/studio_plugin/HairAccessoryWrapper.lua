--!strict
-- Roblox Studio plugin that wraps selected MeshParts into hair accessories.
-- Requires AvatarImporterService beta feature only if you also script imports,
-- but this tool just automates Accessory creation + storage.

local Toolbar = plugin:CreateToolbar("Baddies Tools")
local Button = Toolbar:CreateButton(
    "Wrap Hair Mesh",
    "Turn selected MeshParts into ServerStorage hair accessories",
    "rbxassetid://4458901886"
)

local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local function ensureFolder()
    local folder = ServerStorage:FindFirstChild("HairAccessories")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "HairAccessories"
        folder.Parent = ServerStorage
    end
    return folder
end

local function addAttachment(handle: MeshPart)
    local attach = handle:FindFirstChildOfClass("Attachment")
    if attach and attach.Name == "HairAttachment" then
        return attach
    end

    if attach and attach.Name ~= "HairAttachment" then
        attach.Name = "HairAttachment"
        return attach
    end

    attach = Instance.new("Attachment")
    attach.Name = "HairAttachment"
    attach.Parent = handle
    attach.CFrame = CFrame.new() -- Blender fitter already set the origin
    return attach
end

local function wrapMesh(meshPart: MeshPart)
    local accessory = Instance.new("Accessory")
    accessory.Name = meshPart.Name .. "_Accessory"

    local handle = meshPart:Clone()
    handle.Name = "Handle"
    handle.Anchored = false
    handle.CanCollide = false
    handle.Parent = accessory

    addAttachment(handle)
    accessory.AttachmentPoint = CFrame.new()

    accessory.Parent = ensureFolder()
    meshPart:Destroy()
    return accessory
end

local function run()
    local selection = Selection:Get()
    if #selection == 0 then
        warn("[Hair Wrapper] Select one or more MeshParts first.")
        return
    end

    local created = {}
    for _, inst in selection do
        if inst:IsA("MeshPart") then
            table.insert(created, wrapMesh(inst))
        else
            warn(string.format("[Hair Wrapper] Skipping %s (%s)", inst.Name, inst.ClassName))
        end
    end

    if #created > 0 then
        Selection:Set(created)
        print(string.format("[Hair Wrapper] Wrapped %d accessories", #created))
    else
        warn("[Hair Wrapper] No MeshParts were wrapped.")
    end
end

Button.Click:Connect(run)
