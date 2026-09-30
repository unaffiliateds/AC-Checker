--[[
    AC-Checker
    LoaderServer.lua

    Main entry point.

    Expected Roblox hierarchy:

    ServerScriptService
        AC-Checker
            LoaderServer
            src
                ScannerCore
                LoopScanner
                JumpScanner
                Logs
]]

local ReplicatedStorage =
	game:GetService(
		"ReplicatedStorage"
	)

local ServerScriptService =
	game:GetService(
		"ServerScriptService"
	)

local root =
	script.Parent

local src =
	root:WaitForChild("src")

local ScannerCore =
	require(
		src:WaitForChild(
			"ScannerCore"
		)
	)

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local CONFIG = {

	Enabled = true,

	-- Normal movement speed.
	BaseSpeed = 18,

	-- Sprint movement speed.
	SprintSpeed = 21,

	-- Added to the movement limit to reduce
	-- false positives caused by network/physics.
	SpeedTolerance = 1.25,

	-- Seconds between movement samples.
	SampleInterval = 0.15,

	-- Number of consecutive over-limit samples
	-- required before creating a detection.
	RequiredViolations = 3,

	-- How long consecutive violations remain valid.
	ViolationWindow = 1.0,

	-- IMPORTANT:
	-- true = everyone can see the GUI while testing.
	-- Change to false for an admin-only GUI.
	ShowGuiToAll = true,

	-- Used when ShowGuiToAll = false.
	AdminUserIds = {
		-- Put Roblox UserIds here.
		-- Example:
		-- 123456789,
	},
}

--------------------------------------------------
-- CREATE SCANNER
--------------------------------------------------

local Scanner =
	ScannerCore.new(
		CONFIG
	)

--------------------------------------------------
-- START
--------------------------------------------------

Scanner:Start()

print(
	"[AC-Checker] LoaderServer initialized."
)
