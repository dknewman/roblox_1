local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local NPCSpawner = {}

local HEIGHT_OFFSET = Vector3.new(0, 3, 0)

local function randomColor()
	return Color3.fromHSV(math.random(), 0.6 + math.random() * 0.3, 1)
end

local function createDescription()
	local desc = Instance.new("HumanoidDescription")
	local baseColor = randomColor()
	desc.HeadColor = baseColor
	desc.LeftArmColor = baseColor
	desc.RightArmColor = baseColor
	desc.LeftLegColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
	desc.RightLegColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
	desc.TorsoColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
	desc.HairAccessory = ""
	desc.Face = 707472834 -- friendly face
	return desc
end

local function playAnimation(humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = Constants.NPC.AnimationIds[math.random(1, #Constants.NPC.AnimationIds)]
	local track = humanoid:LoadAnimation(animation)
	track.Looped = true
	track:Play()
end

local function wander(model, anchors)
	task.spawn(function()
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		while model.Parent do
			local target = anchors[math.random(1, #anchors)]
			humanoid:MoveTo(target)
			humanoid.MoveToFinished:Wait()
			task.wait(math.random(1, 4))
		end
	end)
end

function NPCSpawner.spawn(config)
	local info = config or { navPoints = { Vector3.new() } }
	local container = workspace:FindFirstChild("NPCs")
	if container then
		container:Destroy()
	end
	container = Instance.new("Folder")
	container.Name = "NPCs"
	container.Parent = workspace

	for i = 1, Constants.NPC.Count do
		task.defer(function()
			local desc = createDescription()
			local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
			rig.Name = "PlazaNPC"
			rig.Parent = container
			local anchor = info.navPoints[math.random(1, #info.navPoints)] + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
			rig:MoveTo(anchor)
			local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				humanoid.DisplayName = "Guest"
				humanoid.WalkSpeed = 8 + math.random() * 4
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				playAnimation(humanoid)
			end
			wander(rig, info.navPoints)
		end)
	end
end

return NPCSpawner
