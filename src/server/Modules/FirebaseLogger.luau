--[[
	FirebaseLogger - Sends structured log events to Firebase Realtime Database
	via the REST API. All calls are fire-and-forget (async, pcall-wrapped).

	Usage:
	  FirebaseLogger.log("category", "event_name", { key = value })

	Configure your database URL in src/shared/Constants.luau:
	  Constants.Firebase.DatabaseUrl = "https://<project-id>-default-rtdb.firebaseio.com"

	HttpService.HttpEnabled must be true in Studio (Game Settings → Security).
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local FirebaseLogger = {}

local function getConfig()
	return Constants.Firebase or {}
end

local function isEnabled()
	local cfg = getConfig()
	if cfg.Enabled == false then
		return false
	end
	local url = cfg.DatabaseUrl
	return url ~= nil and url ~= ""
end

--[[
	Post a log entry to Firebase Realtime Database.
	Runs in a detached thread so it never blocks the caller.

	@param category  string   Grouping key (e.g. "server", "map", "npc", "player", "client")
	@param event     string   Event name (e.g. "startup_begin", "build_complete")
	@param data      table?   Arbitrary payload merged into the log entry
]]
function FirebaseLogger.log(category: string, event: string, data: { [string]: any }?)
	if not isEnabled() then
		return
	end

	local entry = {
		timestamp = os.time(),
		isoTime = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
		category = category,
		event = event,
		data = data or {},
		serverId = game.JobId ~= "" and game.JobId or "studio",
		placeId = game.PlaceId,
		placeVersion = game.PlaceVersion,
	}

	task.spawn(function()
		local ok, err = pcall(function()
			local cfg = getConfig()
			local url = cfg.DatabaseUrl .. "/logs/" .. category .. ".json"
			local body = HttpService:JSONEncode(entry)
			HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
		end)
		if not ok then
			warn(`[FirebaseLogger] {category}/{event} failed: {err}`)
		end
	end)
end

--[[
	Convenience: log with automatic timing.
	Returns a function — call it when the operation finishes to post
	the elapsed time in milliseconds.

	local done = FirebaseLogger.startTimer("map", "build")
	-- ... do work ...
	done({ instanceCount = 500 })   -- merges extra data into the log
]]
function FirebaseLogger.startTimer(category: string, event: string): (data: { [string]: any }?) -> ()
	local start = os.clock()
	return function(data)
		local elapsed = math.floor((os.clock() - start) * 1000)
		local payload = data or {}
		payload.elapsedMs = elapsed
		FirebaseLogger.log(category, event .. "_complete", payload)
	end
end

return FirebaseLogger
