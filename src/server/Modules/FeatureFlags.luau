--[[
	FeatureFlags - Remote feature flags via Firebase Realtime Database.
	Fetches flags from the rbxFlags Cloud Function on startup, falls back
	to Constants.FeatureFlags defaults if the function is unreachable.

	Config lives in src/server/Modules/FirebaseConfig.luau (server-only).

	Usage:
	  local FeatureFlags = require(...)
	  if FeatureFlags.get("NewPlayer") then ... end
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local FirebaseConfig = require(script.Parent.FirebaseConfig)

local FeatureFlags = {}

-- Start with defaults from Constants
local flags: { [string]: any } = {}
for k, v in Constants.FeatureFlags do
	flags[k] = v
end

-- Fetch remote overrides via the rbxFlags Cloud Function
local function fetchRemote()
	if FirebaseConfig.Enabled == false
		or not FirebaseConfig.FunctionsBaseUrl
		or FirebaseConfig.FunctionsBaseUrl == ""
		or not FirebaseConfig.RobloxSecret
		or FirebaseConfig.RobloxSecret == ""
		or FirebaseConfig.RobloxSecret == "PASTE_YOUR_SECRET_HERE"
	then
		return
	end

	local url = FirebaseConfig.FunctionsBaseUrl:gsub("/$", "") .. "/rbxFlags"
	local ok, result = pcall(function()
		return HttpService:GetAsync(
			url,
			false,
			{ ["x-roblox-secret"] = FirebaseConfig.RobloxSecret }
		)
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

-- Poll interval (seconds) — how often to check Firebase for flag changes
local POLL_INTERVAL = 30

-- Track previous flag state to detect changes
local function snapshotFlags(): { [string]: any }
	local snap = {}
	for k, v in flags do
		snap[k] = v
	end
	return snap
end

-- Callbacks for flag changes
local changeCallbacks: { (name: string, newValue: any, oldValue: any) -> () } = {}

function FeatureFlags.onChanged(callback: (name: string, newValue: any, oldValue: any) -> ())
	table.insert(changeCallbacks, callback)
end

-- Poll loop: fetch remote flags periodically and fire change callbacks
local function startPolling()
	task.spawn(function()
		while true do
			task.wait(POLL_INTERVAL)
			local before = snapshotFlags()
			fetchRemote()
			-- Detect changes and notify
			for k, v in flags do
				if before[k] ~= v then
					for _, cb in changeCallbacks do
						task.spawn(cb, k, v, before[k])
					end
				end
			end
			syncToClients()
		end
	end)
end

-- Initialize: fetch remote, sync to clients, start polling
fetchRemote()
syncToClients()
startPolling()

return FeatureFlags
