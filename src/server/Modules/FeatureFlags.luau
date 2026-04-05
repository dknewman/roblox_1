--[[
	FeatureFlags - Remote feature flags via Firebase Realtime Database.
	Fetches from /config/featureFlags.json on startup, falls back to
	Constants.FeatureFlags defaults if Firebase is unreachable.

	Usage:
	  local FeatureFlags = require(...)
	  if FeatureFlags.get("NewPlayer") then ... end
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local FeatureFlags = {}

-- Start with defaults from Constants
local flags: { [string]: any } = {}
for k, v in Constants.FeatureFlags do
	flags[k] = v
end

-- Fetch remote overrides from Firebase
local function fetchRemote()
	local cfg = Constants.Firebase or {}
	if cfg.Enabled == false or not cfg.DatabaseUrl or cfg.DatabaseUrl == "" then
		return
	end

	local url = cfg.DatabaseUrl:gsub("/$", "") .. "/config/featureFlags.json"
	local ok, result = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if ok and result and result ~= "null" then
		local decoded = HttpService:JSONDecode(result)
		if type(decoded) == "table" then
			local overrideCount = 0
			for k, v in decoded do
				flags[k] = v
				overrideCount += 1
			end
			print(`[FeatureFlags] Loaded {overrideCount} remote flag(s)`)
		end
	else
		warn(`[FeatureFlags] Could not fetch remote flags, using defaults: {result or "no response"}`)
	end
end

-- Get a flag value
function FeatureFlags.get(name: string): any
	return flags[name]
end

-- Get all flags (read-only copy)
function FeatureFlags.getAll(): { [string]: any }
	local copy = {}
	for k, v in flags do
		copy[k] = v
	end
	return copy
end

-- Sync flags to clients via a StringValue in ReplicatedStorage
-- (clients can read this without needing HttpService)
local function syncToClients()
	local store = ReplicatedStorage:FindFirstChild("FeatureFlags")
	if not store then
		store = Instance.new("Folder")
		store.Name = "FeatureFlags"
		store.Parent = ReplicatedStorage
	end

	for k, v in flags do
		local existing = store:FindFirstChild(k)
		if existing then
			existing.Value = tostring(v)
		else
			local val = Instance.new("StringValue")
			val.Name = k
			val.Value = tostring(v)
			val.Parent = store
		end
	end
end

-- Initialize: fetch remote, then sync to clients
fetchRemote()
syncToClients()

return FeatureFlags
