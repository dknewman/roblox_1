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

-- Cache config at startup so we don't re-read Constants on every log call
local cfg = Constants.Firebase or {}
local enabled = cfg.Enabled ~= false and cfg.DatabaseUrl ~= nil and cfg.DatabaseUrl ~= ""
local baseUrl = enabled and cfg.DatabaseUrl:gsub("/$", "") or "" -- strip trailing slash
local serverId = game.JobId ~= "" and game.JobId or "studio"

function FirebaseLogger.log(category: string, event: string, data: { [string]: any }?)
	if not enabled then return end

	local now = os.time()
	local entry = {
		timestamp = now,
		isoTime = os.date("!%Y-%m-%dT%H:%M:%SZ", now),
		category = category,
		event = event,
		data = data or {},
		serverId = serverId,
		placeId = game.PlaceId,
		placeVersion = game.PlaceVersion,
	}

	task.spawn(function()
		local ok, err = pcall(function()
			local url = baseUrl .. "/logs/" .. category .. ".json"
			HttpService:PostAsync(url, HttpService:JSONEncode(entry), Enum.HttpContentType.ApplicationJson)
		end)
		if not ok then
			warn(`[FirebaseLogger] {category}/{event} failed: {err}`)
		end
	end)
end

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
