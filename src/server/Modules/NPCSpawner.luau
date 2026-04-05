--[[
	NPCSpawner - Spawns crowd NPCs throughout the Social Spotlight Plaza
	Creates R15 humanoid rigs with random colors and idle animations.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local FirebaseLogger = require(script.Parent.FirebaseLogger)

local NPCSpawner = {}

local DISPLAY_NAMES = {
	"Guest", "Visitor", "Explorer", "Fan", "Creator",
	"Dancer", "Gamer", "Chatter", "Viewer", "Star",
}

local function randomColor()
	return Color3.fromHSV(math.random(), 0.5 + math.random() * 0.4, 0.85 + math.random() * 0.15)
end

local function createDescription()
	local desc = Instance.new("HumanoidDescription")
	local baseColor = randomColor()
	desc.HeadColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.3)
	desc.LeftArmColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.3)
	desc.RightArmColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.3)
	desc.TorsoColor = baseColor
	desc.LeftLegColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.3)
	desc.RightLegColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.3)
	desc.HairAccessory = ""
	desc.Face = 0
	return desc
end

local function playAnimation(humanoid)
	local animId = Constants.NPC.AnimationIds[math.random(1, #Constants.NPC.AnimationIds)]
	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	local ok, track = pcall(function()
		return humanoid:LoadAnimation(animation)
	end)
	if ok and track then
		track.Looped = true
		track:Play()
	end
end

local function wander(model, anchors)
	task.spawn(function()
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then return end

		while model.Parent do
			local target = anchors[math.random(1, #anchors)]
			-- Add some random offset so NPCs don't all cluster on the exact same point
			local offset = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
			humanoid:MoveTo(target + offset)
			humanoid.MoveToFinished:Wait()
			task.wait(math.random(2, 6))
		end
	end)
end

function NPCSpawner.spawn(config)
	local info = config or { navPoints = { Vector3.new(0, 3, 0) } }
	FirebaseLogger.log("npc", "spawn_start", { targetCount = Constants.NPC.Count })

	local container = workspace:FindFirstChild("NPCs")
	if container then container:Destroy() end
	container = Instance.new("Folder")
	container.Name = "NPCs"
	container.Parent = workspace

	local failCount = 0
	for i = 1, Constants.NPC.Count do
		task.defer(function()
			local ok, err = pcall(function()
				local desc = createDescription()
				local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
				rig.Name = "PlazaNPC"
				rig.Parent = container

				-- Spawn at a random nav point with offset
				local anchor = info.navPoints[math.random(1, #info.navPoints)]
				local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
				rig:MoveTo(anchor + offset)

				local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.DisplayName = DISPLAY_NAMES[math.random(1, #DISPLAY_NAMES)]
					humanoid.WalkSpeed = 7 + math.random() * 5
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
					playAnimation(humanoid)
				end

				wander(rig, info.navPoints)
			end)
			if not ok then
				failCount += 1
				FirebaseLogger.log("npc", "spawn_failed", { index = i, error = tostring(err) })
				warn(`[NPCSpawner] Failed to spawn NPC {i}: {err}`)
			end
		end)
	end

	-- Log summary after all deferred spawns have had time to start
	task.delay(5, function()
		FirebaseLogger.log("npc", "spawn_summary", {
			targetCount = Constants.NPC.Count,
			failCount = failCount,
		})
	end)

	print(`[NPCSpawner] Spawning {Constants.NPC.Count} NPCs`)
end

return NPCSpawner
