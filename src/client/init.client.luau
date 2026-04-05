--[[
	Client entry point - Baddies: Play to Slay!
	Shows intro screen, then spawns player and runs camera intro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Client log helper (non-blocking — resolves the remote in the background)
local logEvent: RemoteEvent? = nil
task.spawn(function()
	logEvent = ReplicatedStorage:WaitForChild("FirebaseLogEvent", 30)
end)
local function logToServer(event: string, data: { [string]: any }?)
	if logEvent then
		logEvent:FireServer(event, data or {})
	end
end

--------------------------------------------------------------------------------
-- INTRO SCREEN
--------------------------------------------------------------------------------

local function createIntroScreen()
	local gui = Instance.new("ScreenGui")
	gui.Name = "IntroScreen"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Lock camera to a static view during intro
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(0, 80, 90) * CFrame.Angles(math.rad(-35), 0, 0)

	-- Galaxy/sparkle background fill
	local fill = Instance.new("Frame")
	fill.Name = "BackgroundFill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.ZIndex = 0
	fill.Parent = gui

	-- Animated rotating gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 15, 100)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 25, 130)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(140, 40, 160)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 170)),
	})
	gradient.Rotation = 0
	gradient.Parent = fill

	-- Scatter sparkle dots
	local sparkles = {}
	for i = 1, 50 do
		local dot = Instance.new("Frame")
		dot.Name = `Sparkle_{i}`
		dot.BackgroundColor3 = Color3.fromHSV(
			0.75 + math.random() * 0.2, -- purple to pink hue
			0.2 + math.random() * 0.3,
			0.9 + math.random() * 0.1
		)
		local sz = math.random(2, 5)
		dot.Size = UDim2.new(0, sz, 0, sz)
		dot.Position = UDim2.new(math.random() * 0.98, 0, math.random() * 0.98, 0)
		dot.BackgroundTransparency = math.random() * 0.5
		dot.BorderSizePixel = 0
		dot.ZIndex = 1
		dot.Parent = fill

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot

		sparkles[i] = { dot = dot, speed = 0.5 + math.random() * 2, phase = math.random() * math.pi * 2 }
	end

	-- Animate gradient rotation + sparkle twinkle
	task.spawn(function()
		while fill.Parent do
			local t = tick()
			gradient.Rotation = (t * 8) % 360
			for _, s in sparkles do
				s.dot.BackgroundTransparency = 0.3 + 0.6 * math.abs(math.sin(t * s.speed + s.phase))
			end
			RunService.RenderStepped:Wait()
		end
	end)

	-- Centered image container that preserves 1:1 aspect ratio
	local bg = Instance.new("ImageLabel")
	bg.Name = "Background"
	bg.Image = Constants.IntroScreen.ImageId
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.BackgroundTransparency = 1
	bg.ScaleType = Enum.ScaleType.Fit
	bg.BorderSizePixel = 0
	bg.Parent = gui

	-- Lock aspect ratio so buttons stay aligned on all screens
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.AspectType = Enum.AspectType.ScaleWithParentSize
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = bg

	-- Invisible buttons aligned over the image's built-in buttons
	-- Positions are relative to the image (not the screen), so they stay accurate
	local buttonDefs = {
		{ name = "Play",      pos = UDim2.new(0.53, 0, 0.44, 0), size = UDim2.new(0.40, 0, 0.09, 0), action = "play" },
		{ name = "Customize", pos = UDim2.new(0.53, 0, 0.56, 0), size = UDim2.new(0.40, 0, 0.09, 0), action = "coming_soon" },
		{ name = "Shop",      pos = UDim2.new(0.53, 0, 0.68, 0), size = UDim2.new(0.40, 0, 0.09, 0), action = "coming_soon" },
	}

	-- "Coming Soon!" popup
	local popup = Instance.new("Frame")
	popup.Name = "ComingSoonPopup"
	popup.Size = UDim2.new(0, 300, 0, 160)
	popup.Position = UDim2.new(0.5, -150, 0.5, -80)
	popup.BackgroundColor3 = Color3.fromRGB(50, 20, 60)
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.ZIndex = 10
	popup.Parent = gui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 16)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Color3.fromRGB(255, 100, 200)
	popupStroke.Thickness = 2
	popupStroke.Parent = popup

	local popupText = Instance.new("TextLabel")
	popupText.Name = "Message"
	popupText.Size = UDim2.new(1, 0, 0.55, 0)
	popupText.Position = UDim2.new(0, 0, 0.05, 0)
	popupText.BackgroundTransparency = 1
	popupText.Text = "Coming Soon!"
	popupText.TextColor3 = Color3.fromRGB(255, 200, 240)
	popupText.TextScaled = true
	popupText.Font = Enum.Font.GothamBold
	popupText.ZIndex = 11
	popupText.Parent = popup

	local dismissBtn = Instance.new("TextButton")
	dismissBtn.Name = "Dismiss"
	dismissBtn.Size = UDim2.new(0.5, 0, 0, 36)
	dismissBtn.Position = UDim2.new(0.25, 0, 1, -50)
	dismissBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 180)
	dismissBtn.Text = "OK"
	dismissBtn.TextColor3 = Color3.new(1, 1, 1)
	dismissBtn.TextScaled = true
	dismissBtn.Font = Enum.Font.GothamBold
	dismissBtn.ZIndex = 11
	dismissBtn.Parent = popup

	local dismissCorner = Instance.new("UICorner")
	dismissCorner.CornerRadius = UDim.new(0, 10)
	dismissCorner.Parent = dismissBtn

	dismissBtn.MouseButton1Click:Connect(function()
		popup.Visible = false
	end)

	-- Invisible clickable regions over the image's buttons
	for _, def in ipairs(buttonDefs) do
		local btn = Instance.new("TextButton")
		btn.Name = def.name
		btn.Size = def.size
		btn.Position = def.pos
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 5
		btn.Parent = bg

		if def.action == "play" then
			btn.MouseButton1Click:Connect(function()
				logToServer("play_pressed")
				gui:Destroy()
				-- Tell server to spawn our character
				local readyEvent = ReplicatedStorage:WaitForChild("PlayerReady", 10)
				if readyEvent then
					readyEvent:FireServer()
				end
			end)
		else
			btn.MouseButton1Click:Connect(function()
				popup.Visible = true
			end)
		end
	end

	return gui
end

--------------------------------------------------------------------------------
-- CAMERA INTRO (runs after Play is pressed)
--------------------------------------------------------------------------------

local function cameraIntro()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(0, 80, 90) * CFrame.Angles(math.rad(-35), 0, 0)

	local startCF = camera.CFrame
	local targetCF = CFrame.new(0, 25, 50) * CFrame.Angles(math.rad(-15), 0, 0)
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
		local alpha = 1 - (1 - elapsed / duration) ^ 3
		camera.CFrame = startCF:Lerp(targetCF, alpha)
	end)

	-- Safety: hand back camera after character loads
	task.spawn(function()
		player.CharacterAdded:Wait()
		task.wait(0.5)
		if conn and conn.Connected then
			conn:Disconnect()
		end
		camera.CameraType = Enum.CameraType.Custom
		logToServer("camera_intro_complete")
	end)
end

--------------------------------------------------------------------------------
-- MAIN FLOW
--------------------------------------------------------------------------------

-- Start background music (loops forever, parented to PlayerGui so it persists)
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.SoundId = Constants.Music.SoundId
music.Volume = Constants.Music.Volume
music.Looped = true
music.Parent = playerGui
music:Play()

-- Show intro screen and wait for it to be dismissed (Play clicked)
local introGui = createIntroScreen()
logToServer("intro_shown")

-- Wait until the intro screen is destroyed (Play was pressed)
introGui.Destroying:Wait()

-- Run camera intro while character loads
cameraIntro()

logToServer("ready")
print("Social Spotlight Plaza client ready!")
