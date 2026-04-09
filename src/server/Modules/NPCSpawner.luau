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

local function wander(model, anchors)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	local rootPart = model.PrimaryPart
	if not humanoid or not rootPart then return end

	local alive = true
	model.Destroying:Connect(function()
		alive = false
	end)

	task.spawn(function()
		while alive and model.Parent do
			-- Walk to a random nav point
			local target = anchors[math.random(1, #anchors)]
			local offset = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
			humanoid:MoveTo(target + offset)
			humanoid.MoveToFinished:Wait()
			if not alive then break end

			-- Try to sit in a nearby chair (25% chance)
			if math.random() < SIT_CHANCE then
				local seat = findEmptySeat(rootPart.Position)
				if seat then
					-- Walk to the seat, then sit
					humanoid:MoveTo(seat.Position)
					humanoid.MoveToFinished:Wait()
					if not alive then break end
					seat:Sit(humanoid)
					task.wait(math.random(SIT_TIME_MIN, SIT_TIME_MAX))
					if not alive then break end
					humanoid.Jump = true -- stand up
					task.wait(0.5)
					continue
				end
			end

			-- Check for a nearby screen to watch
			local screen = findNearbyScreen(rootPart.Position)
			if screen then
				local lookDir = (screen.Position - rootPart.Position) * Vector3.new(1, 0, 1)
				if lookDir.Magnitude > 0.1 then
					rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDir)
				end
				task.wait(math.random(WATCH_TIME_MIN, WATCH_TIME_MAX))
			else
				task.wait(math.random(2, 6))
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

	for i = 1, count do
		task.defer(function()
			local ok, err = pcall(function()
				local rig = rigTemplate:Clone()
				rig.Name = `PlazaNPC_{i}`
				applyCollisionGroup(rig)

				local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
				humanoid.DisplayName = DISPLAY_NAMES[math.random(1, #DISPLAY_NAMES)]
				humanoid.WalkSpeed = 7 + math.random() * 5

				-- Disable states that cause ragdoll/falling issues for NPCs
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

				local anchor = info.navPoints[math.random(1, #info.navPoints)]
				local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
				rig:PivotTo(CFrame.new(anchor + offset + Vector3.new(0, 3, 0)))
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
