--[[
	Server entry point - Social Spotlight Plaza
	Orchestrates environment building, lighting, and NPC spawning.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script:WaitForChild("Modules")
local MapBuilder = require(Modules:WaitForChild("MapBuilder"))
local LightingController = require(Modules:WaitForChild("LightingController"))
local NPCSpawner = require(Modules:WaitForChild("NPCSpawner"))
local FirebaseLogger = require(Modules:WaitForChild("FirebaseLogger"))

FirebaseLogger.log("server", "startup_begin")

-- Phase 1: Build the environment
local result = MapBuilder.build()

-- Phase 2: Apply atmospheric lighting
LightingController.apply()

-- Phase 3: Spawn NPC crowd
NPCSpawner.spawn({ navPoints = result.navPoints })

FirebaseLogger.log("server", "startup_complete")
print("Social Spotlight Plaza is live!")

-- Player join / leave logging
local playerSessions: { [number]: number } = {}

Players.PlayerAdded:Connect(function(player)
	playerSessions[player.UserId] = os.time()
	FirebaseLogger.log("player", "joined", {
		userId = player.UserId,
		displayName = player.DisplayName,
		playerCount = #Players:GetPlayers(),
	})
end)

Players.PlayerRemoving:Connect(function(player)
	local joinTime = playerSessions[player.UserId]
	local sessionSeconds = joinTime and (os.time() - joinTime) or 0
	playerSessions[player.UserId] = nil
	FirebaseLogger.log("player", "left", {
		userId = player.UserId,
		displayName = player.DisplayName,
		sessionSeconds = sessionSeconds,
		playerCount = #Players:GetPlayers() - 1,
	})
end)

-- RemoteEvent for client-side log forwarding
local logEvent = Instance.new("RemoteEvent")
logEvent.Name = "FirebaseLogEvent"
logEvent.Parent = ReplicatedStorage

logEvent.OnServerEvent:Connect(function(player, event: string, data: { [string]: any }?)
	if type(event) ~= "string" or #event > 64 then return end
	local payload = type(data) == "table" and data or {}
	payload.userId = player.UserId
	payload.displayName = player.DisplayName
	FirebaseLogger.log("client", event, payload)
end)
