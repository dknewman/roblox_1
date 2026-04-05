--[[
	Client entry point - Social Spotlight Plaza
	Sets up camera perspective and optional ambient UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Client log helper: fires events to server → Firebase
local logEvent = ReplicatedStorage:WaitForChild("FirebaseLogEvent", 10)
local function logToServer(event: string, data: { [string]: any }?)
	if logEvent then
		logEvent:FireServer(event, data or {})
	end
end

-- Give the player a nice initial camera view of the plaza
local function setupInitialView()
	-- Brief cinematic overview before handing control to player
	task.spawn(function()
		task.wait(0.5)
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			-- Show a sweeping view while character loads
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.new(0, 80, 90) * CFrame.Angles(math.rad(-35), 0, 0)

			-- Smooth transition down to player level
			local startCF = camera.CFrame
			local elapsed = 0
			local duration = 2.5

			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				elapsed += dt
				if elapsed >= duration then
					conn:Disconnect()
					camera.CameraType = Enum.CameraType.Custom
					return
				end
				local alpha = elapsed / duration
				-- Ease out
				alpha = 1 - (1 - alpha) ^ 3
				local targetCF = CFrame.new(0, 25, 50) * CFrame.Angles(math.rad(-15), 0, 0)
				camera.CFrame = startCF:Lerp(targetCF, alpha)
			end)

			-- Safety: ensure camera returns to player after character loads
			player.CharacterAdded:Wait()
			task.wait(0.5)
			if conn and conn.Connected then
				conn:Disconnect()
			end
			camera.CameraType = Enum.CameraType.Custom
			logToServer("camera_intro_complete")
		end
	end)
end

setupInitialView()

logToServer("ready")
print("Social Spotlight Plaza client ready!")
