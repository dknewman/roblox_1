--[[
	Client entry point - Baddies: Play to Slay!
	Shows intro screen, then spawns player and runs camera intro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local player = Players.LocalPlayer

-- Read feature flags synced from server (StringValues in ReplicatedStorage/FeatureFlags)
local function getFlag(name: string): boolean
	local folder = ReplicatedStorage:FindFirstChild("FeatureFlags")
	if folder then
		local val = folder:FindFirstChild(name)
		if val then
			return val.Value == "true"
		end
	end
	-- Fall back to Constants defaults
	local default = Constants.FeatureFlags and Constants.FeatureFlags[name]
	return default ~= false
end
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
-- GENDER SELECTION SCREEN
--------------------------------------------------------------------------------

local function createGenderSelectScreen(): string
	local chosen: string? = nil

	local gui = Instance.new("ScreenGui")
	gui.Name = "GenderSelectScreen"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Galaxy background (same as intro)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 0
	fill.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 15, 100)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 25, 130)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(140, 40, 160)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 170)),
	})
	gradient.Parent = fill

	-- Sparkle dots
	local sparkles = {}
	for i = 1, 30 do
		local dot = Instance.new("Frame")
		dot.BackgroundColor3 = Color3.fromHSV(0.75 + math.random() * 0.2, 0.2 + math.random() * 0.3, 0.9 + math.random() * 0.1)
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

	-- Center panel
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 400, 0, 300)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(50, 20, 60)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.ZIndex = 5
	panel.Parent = gui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(255, 100, 200)
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Look"
	title.TextColor3 = Color3.fromRGB(255, 200, 240)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 6
	title.Parent = panel

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0, 20, 0, 75)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "You can change this later!"
	subtitle.TextColor3 = Color3.fromRGB(200, 170, 220)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.ZIndex = 6
	subtitle.Parent = panel

	-- Button helper
	local function makeGenderButton(text: string, xPos: number, color: Color3): TextButton
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 150, 0, 120)
		btn.AnchorPoint = Vector2.new(0.5, 0)
		btn.Position = UDim2.new(xPos, 0, 0, 130)
		btn.BackgroundColor3 = color
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 24
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 6
		btn.Parent = panel

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 0
		stroke.Parent = btn

		btn.MouseEnter:Connect(function()
			stroke.Thickness = 2
			stroke.Color = Color3.new(1, 1, 1)
		end)
		btn.MouseLeave:Connect(function()
			stroke.Thickness = 0
		end)

		return btn
	end

	local femaleBtn = makeGenderButton("Female", 0.3, Color3.fromRGB(255, 80, 180))
	local maleBtn = makeGenderButton("Male", 0.7, Color3.fromRGB(180, 80, 255))

	femaleBtn.MouseButton1Click:Connect(function()
		chosen = "Female"
	end)
	maleBtn.MouseButton1Click:Connect(function()
		chosen = "Male"
	end)

	-- Yield until a choice is made
	while chosen == nil do
		task.wait(0.1)
	end

	gui:Destroy()
	return chosen
end

--------------------------------------------------------------------------------
-- CAMERA INTRO (runs after Play is pressed)
--------------------------------------------------------------------------------

local function cameraIntro()
	-- Immediately hand camera to the player — no slow pan
	camera.CameraType = Enum.CameraType.Custom
	logToServer("camera_intro_complete")
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
if getFlag("MusicEnabled") then
	music:Play()
end

--------------------------------------------------------------------------------
-- SETTINGS MENU (persistent gear icon, top-right — visible on intro + in-game)
--------------------------------------------------------------------------------

local Lighting = game:GetService("Lighting")

local settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "SettingsGui"
settingsGui.IgnoreGuiInset = true
settingsGui.DisplayOrder = 110
settingsGui.ResetOnSpawn = false
settingsGui.Parent = playerGui

-- Gear icon button (top-right)
local gearBtn = Instance.new("TextButton")
gearBtn.Name = "GearButton"
gearBtn.Size = UDim2.new(0, 40, 0, 40)
gearBtn.Position = UDim2.new(1, -55, 0, 15)
gearBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 40)
gearBtn.BackgroundTransparency = 0.4
gearBtn.Text = "\u{2699}"
gearBtn.TextColor3 = Color3.fromRGB(220, 200, 240)
gearBtn.TextSize = 28
gearBtn.Font = Enum.Font.GothamBold
gearBtn.ZIndex = 20
gearBtn.Parent = settingsGui

local gearCorner = Instance.new("UICorner")
gearCorner.CornerRadius = UDim.new(0, 10)
gearCorner.Parent = gearBtn

-- Settings panel
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0, 260, 0, 220)
panel.Position = UDim2.new(1, -275, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(30, 12, 45)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 20
panel.Parent = settingsGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(180, 80, 200)
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

-- Title
local panelTitle = Instance.new("TextLabel")
panelTitle.Name = "Title"
panelTitle.Size = UDim2.new(1, 0, 0, 36)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "Settings"
panelTitle.TextColor3 = Color3.fromRGB(255, 180, 230)
panelTitle.TextSize = 20
panelTitle.Font = Enum.Font.GothamBold
panelTitle.ZIndex = 21
panelTitle.Parent = panel

-- Helper: create a slider row
local function makeSlider(name, label, yPos, initial, onChange)
	local row = Instance.new("Frame")
	row.Name = name
	row.Size = UDim2.new(1, -30, 0, 60)
	row.Position = UDim2.new(0, 15, 0, yPos)
	row.BackgroundTransparency = 1
	row.ZIndex = 21
	row.Parent = panel

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.5, 0, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(210, 190, 230)
	lbl.TextSize = 14
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 22
	lbl.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.5, 0, 0, 20)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(math.floor(initial * 100)) .. "%"
	valueLabel.TextColor3 = Color3.fromRGB(255, 150, 220)
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 22
	valueLabel.Parent = row

	-- Track
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, 8)
	track.Position = UDim2.new(0, 0, 0, 30)
	track.BackgroundColor3 = Color3.fromRGB(60, 30, 80)
	track.BorderSizePixel = 0
	track.ZIndex = 22
	track.Parent = row

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	-- Fill
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(initial, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
	fill.BorderSizePixel = 0
	fill.ZIndex = 23
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	-- Thumb
	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.Position = UDim2.new(initial, -8, 0.5, -8)
	thumb.BackgroundColor3 = Color3.new(1, 1, 1)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 24
	thumb.Parent = track

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb

	-- Drag interaction
	local dragging = false
	local inputBtn = Instance.new("TextButton")
	inputBtn.Size = UDim2.new(1, 0, 0, 24)
	inputBtn.Position = UDim2.new(0, 0, 0, 24)
	inputBtn.BackgroundTransparency = 1
	inputBtn.Text = ""
	inputBtn.ZIndex = 25
	inputBtn.Parent = row

	local function updateSlider(inputX)
		local trackAbsPos = track.AbsolutePosition.X
		local trackAbsSize = track.AbsoluteSize.X
		local pct = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -8, 0.5, -8)
		valueLabel.Text = tostring(math.floor(pct * 100)) .. "%"
		onChange(pct)
	end

	inputBtn.MouseButton1Down:Connect(function()
		dragging = true
	end)

	inputBtn.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)

	inputBtn.MouseButton1Up:Connect(function()
		dragging = false
	end)

	inputBtn.MouseButton1Click:Connect(function(x)
		local absX = inputBtn.AbsolutePosition.X
		local relX = game:GetService("UserInputService"):GetMouseLocation().X
		updateSlider(relX)
	end)
end

-- Volume slider
makeSlider("Volume", "Volume", 45, Constants.Music.Volume, function(pct)
	music.Volume = pct
end)

-- Brightness slider
local baseBrightness = Lighting.Brightness
makeSlider("Brightness", "Brightness", 120, 0.5, function(pct)
	Lighting.Brightness = pct * 2 -- 0% = 0, 50% = 1.0 (default), 100% = 2.0
end)

-- Toggle panel
gearBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

--------------------------------------------------------------------------------
-- INTRO SCREEN + CHARACTER CREATION + SPAWN
--------------------------------------------------------------------------------

-- Keep camera locked during entire flow
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(0, 80, 90) * CFrame.Angles(math.rad(-35), 0, 0)

-- Show intro screen (if enabled) and wait for Play
if getFlag("IntroScreenEnabled") then
	local introGui = createIntroScreen()
	logToServer("intro_shown")

	-- Wait until the intro screen is destroyed (Play was pressed)
	introGui.Destroying:Wait()
end

-- Check if player needs character creation
print("[Client] Waiting for CharacterCreated BoolValue...")
local createdVal = player:WaitForChild("CharacterCreated", 10)
if createdVal then
	print(`[Client] CharacterCreated found, value = {createdVal.Value}`)
else
	print("[Client] CharacterCreated NOT FOUND (timeout)")
end
local needsCreation = not (createdVal and createdVal.Value)

-- NewPlayer flag = true: always show gender selection (even for returning players)
if not needsCreation and getFlag("NewPlayer") then
	needsCreation = true
end

if needsCreation then
	print("[Client] Showing gender selection...")
	local gender = createGenderSelectScreen()
	print(`[Client] Gender chosen: {gender}`)
	logToServer("gender_selected", { gender = gender })

	-- Tell server to save gender and spawn character
	local genderEvent = ReplicatedStorage:WaitForChild("GenderSelected", 10)
	if genderEvent then
		print("[Client] Firing GenderSelected to server...")
		genderEvent:FireServer(gender)
	else
		warn("[Client] GenderSelected RemoteEvent not found!")
	end

	-- Wait for character to actually spawn before camera intro
	print("[Client] Waiting for character to spawn...")
	player.CharacterAdded:Wait()
	task.wait(0.5)
else
	-- Returning player — just spawn
	print("[Client] Returning player, firing PlayerReady...")
	local readyEvent = ReplicatedStorage:WaitForChild("PlayerReady", 10)
	if readyEvent then
		readyEvent:FireServer()
	end
	player.CharacterAdded:Wait()
	task.wait(0.5)
end

-- Run camera intro after character exists
print("[Client] Running camera intro...")
cameraIntro()

logToServer("ready")
print("Social Spotlight Plaza client ready!")
