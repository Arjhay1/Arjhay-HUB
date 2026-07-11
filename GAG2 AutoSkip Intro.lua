-- GAG2 AutoSkip Intro
-- When "Click to skip!" appears, wait 3 seconds then auto-press Space.
-- Stops pressing Space entirely 15 seconds after the script starts.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

local KEY_TO_PRESS = Enum.KeyCode.Space
local DELAY_BEFORE_SKIP = 3
local CHECK_INTERVAL = 0.15
local SKIP_TEXT_PATTERN = "skip"
local STOP_AFTER = 50 -- seconds after script start; stop pressing Space after this

local START_TIME = tick()
local pendingSkip = false
local lastSkipAt = 0

local function isSkipPromptVisible()
	-- Check PlayerGui first
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end

	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			if obj.Visible and obj.Text and string.find(string.lower(obj.Text), SKIP_TEXT_PATTERN, 1, true) then
				return true
			end
		end
	end

	return false
end

local function pressSkipKey()
	-- Simulate keyboard press/release
	VirtualInputManager:SendKeyEvent(true, KEY_TO_PRESS, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, KEY_TO_PRESS, false, game)
end

task.spawn(function()
	while true do
		task.wait(CHECK_INTERVAL)

		-- Stop entirely once STOP_AFTER seconds have passed since start
		if tick() - START_TIME >= STOP_AFTER then
			print("[AutoSkip] Time limit reached (" .. STOP_AFTER .. "s). Stopping.")
			break
		end

		if isSkipPromptVisible() and not pendingSkip then
			pendingSkip = true

			task.spawn(function()
				task.wait(DELAY_BEFORE_SKIP)

				-- check again after delay to avoid false trigger,
				-- and make sure we're still within the time limit
				if isSkipPromptVisible() and (tick() - START_TIME < STOP_AFTER) then
					pressSkipKey()
					lastSkipAt = tick()
				end

				pendingSkip = false
			end)
		end
	end
end)

print("[AutoSkip] Loaded. Waiting for skip prompt (stops after " .. STOP_AFTER .. "s)...")
