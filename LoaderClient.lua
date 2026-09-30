--[[
    AC-Checker
    LoaderClient.lua

    Entry point.

    The loader is responsible for wiring the modules together.

    It does NOT contain scanner logic or GUI logic.
]]

local root =
	script.Parent

local src =
	root:WaitForChild(
		"src"
	)

--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

local ScannerCore =
	require(
		src:WaitForChild(
			"ScannerCore"
		)
	)

local LoopScanner =
	require(
		src:WaitForChild(
			"LoopScanner"
		)
	)

local JumpScanner =
	require(
		src:WaitForChild(
			"JumpScanner"
		)
	)

local Logs =
	require(
		src:WaitForChild(
			"Logs"
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

	-- Physics/network allowance.
	SpeedTolerance = 1.25,

	-- Movement sampling.
	SampleInterval = 0.15,

	-- Consecutive violations required.
	RequiredViolations = 3,

	-- Maximum gap between violations.
	ViolationWindow = 1,

	-- Development mode.
	--
	-- Set false later and put your UserId
	-- into AdminUserIds.
	ShowGuiToAll = true,

	AdminUserIds = {
		-- 123456789,
	},
}

--------------------------------------------------
-- CREATE CORE
--------------------------------------------------

local Scanner =
	ScannerCore.new(
		CONFIG,
		{
			LoopScanner =
				LoopScanner,

			JumpScanner =
				JumpScanner,

			Logs =
				Logs,
		}
	)

--------------------------------------------------
-- START EVERYTHING
--------------------------------------------------

Scanner:Start()

print(
	"[AC-Checker] LoaderClient initialized."
)

print(
	"[AC-Checker] Modules loaded:"
)

print(
	"  ScannerCore"
)

print(
	"  LoopScanner"
)

print(
	"  JumpScanner"
)

print(
	"  Logs"
)
