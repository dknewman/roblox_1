--[[
	NPCSpawner - Spawns crowd NPCs throughout the Social Spotlight Plaza
	Builds one R6 rig template at startup, then clones it for each NPC.
]]

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local FirebaseLogger = require(script.Parent.FirebaseLogger)

local NPCSpawner = {}

local NPC_GROUP = "NPCs"

-- Set up collision groups: NPCs don't collide with each other or players
PhysicsService:RegisterCollisionGroup(NPC_GROUP)
PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, NPC_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, "Default", false)

-- Assign player characters to Default group on spawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Default"
			end
		end
	end)
end)

local DISPLAY_NAMES = {
	"Guest", "Visitor", "Explorer", "Fan", "Creator",
	"Dancer", "Gamer", "Chatter", "Viewer", "Star",
	"Patron", "Regular", "VIP", "Streamer", "DJ",
}

local function randomColor()
	return Color3.fromHSV(math.random(), 0.5 + math.random() * 0.4, 0.85 + math.random() * 0.15)
end

-- Build the R6 rig template once (never parented to workspace)
local function buildTemplate()
	local model = Instance.new("Model")

	local function makePart(name, size, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = canCollide or false
		p.CollisionGroup = NPC_GROUP
		p.Parent = model
		return p
	end

	local function makeJoint(name, parent, part0, part1, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.C1 = c1
		motor.Parent = parent
	end

	local rootPart = makePart("HumanoidRootPart", Vector3.new(2, 2, 1))
	rootPart.Transparency = 1

	local torso = makePart("Torso", Vector3.new(2, 2, 1))

	local head = makePart("Head", Vector3.new(1.2, 1.2, 1.2))
	head.TopSurface = Enum.SurfaceType.Smooth

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	makePart("Left Arm", Vector3.new(1, 2, 1))
	makePart("Right Arm", Vector3.new(1, 2, 1))
	makePart("Left Leg", Vector3.new(1, 2, 1))
	makePart("Right Leg", Vector3.new(1, 2, 1))

	local HP = math.pi / 2

	makeJoint("RootJoint", rootPart, rootPart, torso,
		CFrame.Angles(-HP, 0, math.pi), CFrame.Angles(-HP, 0, math.pi))
	makeJoint("Neck", torso, torso, head,
		CFrame.new(0, 1, 0) * CFrame.Angles(-HP, 0, math.pi),
		CFrame.new(0, -0.5, 0) * CFrame.Angles(-HP, 0, math.pi))
	makeJoint("Left Shoulder", torso, torso, model["Left Arm"],
		CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -HP, 0),
		CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -HP, 0))
	makeJoint("Right Shoulder", torso, torso, model["Right Arm"],
		CFrame.new(1, 0.5, 0) * CFrame.Angles(0, HP, 0),
		CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, HP, 0))
	makeJoint("Left Hip", torso, torso, model["Left Leg"],
		CFrame.new(-1, -1, 0) * CFrame.Angles(0, -HP, 0),
		CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -HP, 0))
	makeJoint("Right Hip", torso, torso, model["Right Leg"],
		CFrame.new(1, -1, 0) * CFrame.Angles(0, HP, 0),
		CFrame.new(0.5, 1, 0) * CFrame.Angles(0, HP, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model

	model.PrimaryPart = rootPart
	return model
end

local rigTemplate = buildTemplate()

-- Apply random colors to a cloned rig
local function colorize(model)
	local skin = randomColor()
	local shirt = randomColor()
	local pants = shirt:Lerp(Color3.new(0, 0, 0), 0.4)

	model.Head.Color = skin
	model["Left Arm"].Color = skin
	model["Right Arm"].Color = skin
	model.Torso.Color = shirt
	model["Left Leg"].Color = pants
	model["Right Leg"].Color = pants
end

local function wander(model, anchors)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	-- Stop the loop when the model is destroyed
	local alive = true
	model.Destroying:Connect(function()
		alive = false
	end)

	task.spawn(function()
		while alive and model.Parent do
			local target = anchors[math.random(1, #anchors)]
			local offset = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
			humanoid:MoveTo(target + offset)
			humanoid.MoveToFinished:Wait()
			task.wait(math.random(2, 6))
		end
	end)
end

function NPCSpawner.spawn(config)
	local info = config or { navPoints = { Vector3.new(0, 3, 0) } }
	local count = Constants.NPC.Count
	FirebaseLogger.log("npc", "spawn_start", { targetCount = count })

	local container = workspace:FindFirstChild("NPCs")
	if container then container:Destroy() end
	container = Instance.new("Folder")
	container.Name = "NPCs"
	container.Parent = workspace

	local failCount = 0
	for i = 1, count do
		task.defer(function()
			local ok, err = pcall(function()
				local rig = rigTemplate:Clone()
				rig.Name = `PlazaNPC_{i}`
				colorize(rig)

				local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
				humanoid.DisplayName = DISPLAY_NAMES[math.random(1, #DISPLAY_NAMES)]
				humanoid.WalkSpeed = 7 + math.random() * 5

				local anchor = info.navPoints[math.random(1, #info.navPoints)]
				local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
				rig:SetPrimaryPartCFrame(CFrame.new(anchor + offset + Vector3.new(0, 3, 0)))
				rig.Parent = container

				wander(rig, info.navPoints)
			end)
			if not ok then
				failCount += 1
				FirebaseLogger.log("npc", "spawn_failed", { index = i, error = tostring(err) })
				warn(`[NPCSpawner] Failed to spawn NPC {i}: {err}`)
			end
		end)
	end

	task.delay(5, function()
		FirebaseLogger.log("npc", "spawn_summary", {
			targetCount = count,
			failCount = failCount,
		})
	end)

	print(`[NPCSpawner] Spawning {count} NPCs`)
end

return NPCSpawner
