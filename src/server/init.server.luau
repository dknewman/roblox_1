--[[
	Server entry point - Social Spotlight Plaza
	Orchestrates environment building, lighting, and NPC spawning.
]]

local Players = game:GetService("Players")
local ScriptContext = game:GetService("ScriptContext")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script:WaitForChild("Modules")
local MapBuilder = require(Modules:WaitForChild("MapBuilder"))
local LightingController = require(Modules:WaitForChild("LightingController"))
local NPCSpawner = require(Modules:WaitForChild("NPCSpawner"))
local FirebaseLogger = require(Modules:WaitForChild("FirebaseLogger"))
local FeatureFlags = require(Modules:WaitForChild("FeatureFlags"))

-- Global error logging — captures all unhandled script errors
ScriptContext.Error:Connect(function(message, stackTrace, script)
	FirebaseLogger.log("error", "script_error", {
		message = message,
		stack = stackTrace,
		script = script and script:GetFullName() or "unknown",
	})
end)

FirebaseLogger.log("server", "startup_begin")

-- Phase 1: Build the environment
local result = MapBuilder.build()

-- Phase 2: Apply atmospheric lighting
LightingController.apply()

-- Phase 3: Spawn NPC crowd (if enabled)
if FeatureFlags.get("NPCsEnabled") ~= false then
	NPCSpawner.spawn({ navPoints = result.navPoints })
else
	print("[Server] NPCs disabled via feature flag")
end

FirebaseLogger.log("server", "startup_complete")

-- Maintenance mode — kick everyone and block new joins
if FeatureFlags.get("Maintenance") then
	local MESSAGE = "Server is under maintenance. Please try again later!"
	FirebaseLogger.log("server", "maintenance_mode_active")
	for _, p in Players:GetPlayers() do
		p:Kick(MESSAGE)
	end
	Players.PlayerAdded:Connect(function(p)
		p:Kick(MESSAGE)
	end)
	warn("[Server] Maintenance mode is ON — all players will be kicked")
	return -- stop server init here
end

print("Social Spotlight Plaza is live!")

-- Hold players at intro screen until they click Play
Players.CharacterAutoLoads = false

local playerReady = Instance.new("RemoteEvent")
playerReady.Name = "PlayerReady"
playerReady.Parent = ReplicatedStorage

local spawnedPlayers: { [number]: true } = {}
playerReady.OnServerEvent:Connect(function(player)
	if spawnedPlayers[player.UserId] then return end -- prevent double-spawn
	spawnedPlayers[player.UserId] = true
	player:LoadCharacter()
	FirebaseLogger.log("player", "play_pressed", {
		userId = player.UserId,
		displayName = player.DisplayName,
	})
end)

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
