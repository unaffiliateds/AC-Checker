--[[
    AC-Checker
    LoaderClient.lua

    Client-side entry point.

    Expected runtime layout:

    AC-Checker
    ├── LoaderClient
    └── src
        ├── ScannerCore
        ├── LoopScanner
        ├── JumpScanner
        └── Logs
]]

local parent = script.Parent

if not parent then
	error(
		"[AC-Checker] LoaderClient has no parent."
	)
end

local src = parent:FindFirstChild("src")

if not src then
	error(
		"[AC-Checker] Could not find 'src' beside LoaderClient. " ..
		"Expected AC-Checker/LoaderClient and AC-Checker/src."
	)
end

local ScannerCore = require(
	src:WaitForChild("ScannerCore")
)

local Scanner = ScannerCore.new({

	Enabled = true,

	-- Normal movement
	BaseSpeed = 18,

	-- Sprint movement
	SprintSpeed = 21,

	-- Allowance for normal client/network variance
	SpeedTolerance = 1.25,

	SampleInterval = 0.15,

	-- Consecutive samples required
	RequiredViolations = 3,

	ViolationWindow = 1.0,

	-- Development mode
	ShowGuiToAll = true,

	AdminUserIds = {},
})

Scanner:Start()

print(
	"[AC-Checker] LoaderClient initialized."
)
