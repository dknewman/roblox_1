--[[
	FirebaseLogger - Sends structured log events to Firebase Realtime Database
	via a Cloud Function proxy. All calls are fire-and-forget (async, pcall-wrapped).

	Usage:
	  FirebaseLogger.log("category", "event_name", { key = value })

	Config lives in src/server/Modules/FirebaseConfig.luau (server-only, never
	replicated to clients). Set FunctionsBaseUrl, RobloxSecret, and Enabled there.

	HttpService.HttpEnabled must be true in Studio (Game Settings → Security).
]]

local HttpService = game:GetService("HttpService")

local FirebaseConfig = require(script.Parent.FirebaseConfig)

local FirebaseLogger = {}

-- Cache config at startup
local function isConfigured()
	return FirebaseConfig.Enabled ~= false
		and FirebaseConfig.FunctionsBaseUrl ~= nil
		and FirebaseConfig.FunctionsBaseUrl ~= ""
		and FirebaseConfig.RobloxSecret ~= nil
		and FirebaseConfig.RobloxSecret ~= ""
		and FirebaseConfig.RobloxSecret ~= "PASTE_YOUR_SECRET_HERE"
end

local enabled  = isConfigured()
local logUrl   = enabled and (FirebaseConfig.FunctionsBaseUrl:gsub("/$", "") .. "/rbxLog") or ""
local secret   = enabled and FirebaseConfig.RobloxSecret or ""
local serverId = game.JobId ~= "" and game.JobId or "studio"

function FirebaseLogger.log(category: string, event: string, data: { [string]: any }?)
	if not enabled then return end

	local now = os.time()
	local body = HttpService:JSONEncode({
		category = category,
		entry    = {
			timestamp   = now,
			isoTime     = os.date("!%Y-%m-%dT%H:%M:%SZ", now),
			category    = category,
			event       = event,
			data        = data or {},
			serverId    = serverId,
			placeId     = game.PlaceId,
			placeVersion = game.PlaceVersion,
		},
	})

	task.spawn(function()
		local ok, err = pcall(function()
			HttpService:PostAsync(
				logUrl,
				body,
				Enum.HttpContentType.ApplicationJson,
				false,
				{ ["x-roblox-secret"] = secret }
			)
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
