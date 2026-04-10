--[[
	NPCSpawner - Spawns crowd NPCs throughout the Social Spotlight Plaza
	Clones the BaddieFemale R15 rig from ServerStorage for each NPC.
]]

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local FirebaseLogger = require(script.Parent.FirebaseLogger)

local NPCSpawner = {}

local NPC_GROUP = "NPCs"
local PLAYER_GROUP = "Players"

-- NPCs don't collide with each other or players, but DO collide with environment (Default)
PhysicsService:RegisterCollisionGroup(NPC_GROUP)
PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, NPC_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(NPC_GROUP, PLAYER_GROUP, false)

-- Assign player characters to the Players group so they pass through NPCs
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = PLAYER_GROUP
			end
		end
		character.DescendantAdded:Connect(function(part)
			if part:IsA("BasePart") then
				part.CollisionGroup = PLAYER_GROUP
			end
		end)
	end)
end)

local DISPLAY_NAMES = {
	"Guest", "Visitor", "Explorer", "Fan", "Creator",
	"Dancer", "Gamer", "Chatter", "Viewer", "Star",
	"Patron", "Regular", "VIP", "Streamer", "DJ",
}

-- Get the R15 character template from ServerStorage
local rigTemplate = ServerStorage:WaitForChild("BaddieFemale", 10)
if not rigTemplate then
	warn("[NPCSpawner] BaddieFemale model not found in ServerStorage! Place your Avatar Setup model there.")
end

-- Apply NPC collision group to all BaseParts in a cloned rig
local function applyCollisionGroup(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = NPC_GROUP
		end
	end
end

-- R15 animation asset IDs
local ANIM_IDS = {
	Idle1 = "rbxassetid://507766388",  -- subtle breathing idle
	Idle2 = "rbxassetid://507766666",  -- weight-shift idle (more movement)
	Walk  = "rbxassetid://507777826",  -- standard walk
	Wave  = "rbxassetid://507770239",  -- friendly wave
	Laugh = "rbxassetid://507770818",  -- laughing gesture
	Cheer = "rbxassetid://507770677",  -- cheer / excited
	Point = "rbxassetid://507770453",  -- pointing gesture
}

-- Gesture pool for conversations (played on top of idle)
local GESTURE_IDS = { ANIM_IDS.Wave, ANIM_IDS.Laugh, ANIM_IDS.Cheer, ANIM_IDS.Point }

-- Per-NPC animation state returned by setupAnimations
type AnimState = {
	animator: Animator,
	idleTrack: AnimationTrack,
	walkTrack: AnimationTrack,
	gestureTracks: { AnimationTrack },
	playGesture: () -> (),
	stopAll: () -> (),
}

-- Track which NPCs are currently in a conversation (model -> true)
local inConversation: { [Model]: boolean } = {}

-- Set up server-side animations for an NPC rig
local function setupAnimations(rig): AnimState?
	local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return nil end

	-- Remove any Animate LocalScript (won't work for NPCs)
	local animateScript = rig:FindFirstChild("Animate")
	if animateScript then animateScript:Destroy() end

	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Load idle tracks
	local idleAnim1 = Instance.new("Animation")
	idleAnim1.AnimationId = ANIM_IDS.Idle1
	local idleTrack = animator:LoadAnimation(idleAnim1)
	idleTrack.Priority = Enum.AnimationPriority.Idle
	idleTrack.Looped = true

	-- Load walk track — play at reduced speed for a casual stroll
	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = ANIM_IDS.Walk
	local walkTrack = animator:LoadAnimation(walkAnim)
	walkTrack.Priority = Enum.AnimationPriority.Movement
	walkTrack.Looped = true

	-- Load gesture tracks (for conversations)
	local gestureTracks = {}
	for _, id in GESTURE_IDS do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		table.insert(gestureTracks, track)
	end

	-- Start with idle
	idleTrack:Play(0.3)

	-- Switch between idle and walk based on movement
	-- Keep idle always playing for natural body sway; layer walk on top at
	-- low weight (0.4) so strides are subtle, not exaggerated prancing.
	-- Speed is scaled to match ground movement so feet don't slide.
	idleTrack:Play(0.3)
	humanoid.Running:Connect(function(speed)
		if speed > 0.5 then
			if not walkTrack.IsPlaying then
				walkTrack:Play(0.3, 0.4) -- weight 0.4 = softened strides
			end
			walkTrack:AdjustSpeed(speed / 16)
			walkTrack:AdjustWeight(0.4)
		else
			if walkTrack.IsPlaying then walkTrack:Stop(0.3) end
		end
	end)

	local state: AnimState = {
		animator = animator,
		idleTrack = idleTrack,
		walkTrack = walkTrack,
		gestureTracks = gestureTracks,
		playGesture = function()
			local track = gestureTracks[math.random(1, #gestureTracks)]
			if not track.IsPlaying then
				track:Play(0.2, 1, 0.8)
			end
		end,
		stopAll = function()
			idleTrack:Stop(0)
			walkTrack:Stop(0)
			for _, t in gestureTracks do t:Stop(0) end
		end,
	}

	return state
end

-- Smoothly turn an NPC to face a target position (horizontal only)
local function faceTarget(rootPart: BasePart, targetPos: Vector3)
	local dir = (targetPos - rootPart.Position) * Vector3.new(1, 0, 1)
	if dir.Magnitude > 0.1 then
		rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + dir)
	end
end

-- Run a conversation between two NPCs
local function doConversation(npcA, animA: AnimState, npcB, animB: AnimState)
	local rootA = npcA.PrimaryPart
	local rootB = npcB.PrimaryPart
	if not rootA or not rootB then return end

	inConversation[npcA] = true
	inConversation[npcB] = true

	-- Face each other
	faceTarget(rootA, rootB.Position)
	faceTarget(rootB, rootA.Position)

	-- Conversation lasts 6-14 seconds with alternating gestures
	local duration = math.random(6, 14)
	local elapsed = 0
	while elapsed < duration and npcA.Parent and npcB.Parent do
		-- One NPC gestures, the other listens
		local speaker = math.random(1, 2)
		if speaker == 1 then
			animA.playGesture()
		else
			animB.playGesture()
		end

		-- Re-face each other (in case of drift)
		faceTarget(rootA, rootB.Position)
		faceTarget(rootB, rootA.Position)

		local pause = math.random() * 2 + 1.5 -- 1.5-3.5s between gestures
		task.wait(pause)
		elapsed += pause
	end

	inConversation[npcA] = nil
	inConversation[npcB] = nil
end

local SCREEN_RANGE = 18
local WATCH_TIME_MIN = 4
local WATCH_TIME_MAX = 12
local SIT_CHANCE = 0.25 -- 25% chance to try sitting after reaching a waypoint
local SIT_TIME_MIN = 6
local SIT_TIME_MAX = 15
local SEAT_RANGE = 20
local SCREEN_NAMES = { "MainScreen", "ScreenPanel_", "StairScreen_", "ArcadeScreen", "KioskDisplay" }

-- Cached interactable parts (populated in spawn())
local screenParts: { BasePart } = {}
local seatParts: { Seat } = {}

local function cacheInteractables()
	screenParts = {}
	seatParts = {}
	local hub = workspace:FindFirstChild(Constants.HubName)
	if not hub then return end
	for _, part in hub:GetDescendants() do
		if part:IsA("Seat") then
			table.insert(seatParts, part)
		elseif part:IsA("BasePart") then
			for _, prefix in SCREEN_NAMES do
				if part.Name:sub(1, #prefix) == prefix then
					table.insert(screenParts, part)
					break
				end
			end
		end
	end
end

local function findNearbyScreen(pos: Vector3): BasePart?
	local best, bestDist = nil, SCREEN_RANGE
	for _, screen in screenParts do
		local dist = (screen.Position - pos).Magnitude
		if dist < bestDist then
			best = screen
			bestDist = dist
		end
	end
	return best
end

-- Find an empty seat nearby
local function findEmptySeat(pos: Vector3): Seat?
	local best, bestDist = nil, SEAT_RANGE
	for _, seat in seatParts do
		if seat.Occupant then continue end -- already taken
		local dist = (seat.Position - pos).Magnitude
		if dist < bestDist then
			best = seat
			bestDist = dist
		end
	end
	return best
end

-- All spawned NPC data for conversation pairing
local allNPCs: { { model: Model, anim: AnimState } } = {}
local CONVO_RANGE = 25   -- max distance to find a conversation partner
local CONVO_CHANCE = 0.15 -- 15% chance to try chatting after reaching a waypoint

-- Find a nearby NPC not currently in a conversation
local function findConvoPartner(model: Model, rootPos: Vector3): ({ model: Model, anim: AnimState })?
	local best, bestDist = nil, CONVO_RANGE
	for _, npcData in allNPCs do
		if npcData.model == model then continue end
		if inConversation[npcData.model] then continue end
		if not npcData.model.Parent then continue end
		local otherRoot = npcData.model.PrimaryPart
		if not otherRoot then continue end
		local dist = (otherRoot.Position - rootPos).Magnitude
		if dist < bestDist then
			best = npcData
			bestDist = dist
		end
	end
	return best
end

local NPC_MIN_DIST = 12 -- minimum distance NPCs try to keep from each other

-- Pick a nav target that isn't too close to other NPCs
local function pickSpreadTarget(model: Model, anchors: { Vector3 }): Vector3
	for _ = 1, 5 do -- try up to 5 times to find a non-crowded spot
		local base = anchors[math.random(1, #anchors)]
		local candidate = base + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
		local tooClose = false
		for _, npcData in allNPCs do
			if npcData.model == model then continue end
			local otherRoot = npcData.model.PrimaryPart
			if not otherRoot then continue end
			if (otherRoot.Position - candidate).Magnitude < NPC_MIN_DIST then
				tooClose = true
				break
			end
		end
		if not tooClose then return candidate end
	end
	-- Fallback: just pick a random point with a wide offset
	local base = anchors[math.random(1, #anchors)]
	return base + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
end

local function wander(model, anchors, animState: AnimState)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	local rootPart = model.PrimaryPart
	if not humanoid or not rootPart then return end

	local alive = true
	model.Destroying:Connect(function()
		alive = false
		inConversation[model] = nil
	end)

	task.spawn(function()
		while alive and model.Parent do
			-- Skip turn if already pulled into a conversation by another NPC
			if inConversation[model] then
				task.wait(1)
				continue
			end

			-- Walk to a spread-out nav point (avoids clustering)
			local target = pickSpreadTarget(model, anchors)
			humanoid:MoveTo(target)
			humanoid.MoveToFinished:Wait()
			if not alive then break end

			-- Try to start a conversation with a nearby NPC (35% chance)
			if math.random() < CONVO_CHANCE then
				local partner = findConvoPartner(model, rootPart.Position)
				if partner then
					doConversation(model, animState, partner.model, partner.anim)
					if not alive then break end
					-- After chatting, pause briefly then continue wandering
					task.wait(math.random() * 2 + 1)
					continue
				end
			end

			-- Try to sit in a nearby chair (25% chance)
			if math.random() < SIT_CHANCE then
				local seat = findEmptySeat(rootPart.Position)
				if seat then
					humanoid:MoveTo(seat.Position)
					humanoid.MoveToFinished:Wait()
					if not alive then break end
					seat:Sit(humanoid)
					task.wait(math.random(SIT_TIME_MIN, SIT_TIME_MAX))
					if not alive then break end
					humanoid.Jump = true
					task.wait(0.5)
					continue
				end
			end

			-- Check for a nearby screen to watch
			local screen = findNearbyScreen(rootPart.Position)
			if screen then
				faceTarget(rootPart, screen.Position)
				task.wait(math.random(WATCH_TIME_MIN, WATCH_TIME_MAX))
			else
				-- Just pause and idle for a moment
				task.wait(math.random(3, 7))
			end
		end
	end)
end

function NPCSpawner.spawn(config)
	local info = config or { navPoints = { Vector3.new(0, 3, 0) } }
	local count = Constants.NPC.Count
	cacheInteractables()
	FirebaseLogger.log("npc", "spawn_start", { targetCount = count, screenCount = #screenParts, seatCount = #seatParts })

	local container = workspace:FindFirstChild("NPCs")
	if container then container:Destroy() end
	container = Instance.new("Folder")
	container.Name = "NPCs"
	container.Parent = workspace

	local failCount = 0
	if not rigTemplate then
		warn("[NPCSpawner] No rig template — skipping NPC spawn")
		return
	end

	-- Reset NPC registry for conversation pairing
	allNPCs = {}

	for i = 1, count do
		task.defer(function()
			local ok, err = pcall(function()
				local rig = rigTemplate:Clone()
				rig.Name = `PlazaNPC_{i}`
				applyCollisionGroup(rig)

				local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
				humanoid.DisplayName = DISPLAY_NAMES[math.random(1, #DISPLAY_NAMES)]
				humanoid.WalkSpeed = 6 + math.random() * 2 -- casual stroll (6-8)

				-- Disable states that cause ragdoll/falling issues for NPCs
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

				local anchor = info.navPoints[math.random(1, #info.navPoints)]
				local offset = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
				rig:PivotTo(CFrame.new(anchor + offset + Vector3.new(0, 3, 0)))
				rig.Parent = container

				local animState = setupAnimations(rig)
				if animState then
					table.insert(allNPCs, { model = rig, anim = animState })
					wander(rig, info.navPoints, animState)
				end
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
