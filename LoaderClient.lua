--[[
    AC-Checker
    LoaderClient.lua

    GitHub bootstrap loader.

    This is the ONLY file you execute directly.

    It downloads the existing modules from:

    https://github.com/unaffiliateds/AC-Checker

    and loads:

        src/Logs.lua
        src/LoopScanner.lua
        src/JumpScanner.lua
        src/ScannerCore.lua

    Nothing else is added.
]]

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local BASE_URL =
	"https://raw.githubusercontent.com/unaffiliateds/AC-Checker/main/"

local CONFIG = {

	Enabled = true,

	-- Normal movement limit.
	BaseSpeed = 18,

	-- Sprint movement limit.
	SprintSpeed = 21,

	-- Small allowance for normal physics/network variance.
	SpeedTolerance = 1.25,

	-- Movement sampling interval.
	SampleInterval = 0.15,

	-- Consecutive violations required.
	RequiredViolations = 3,

	-- Maximum time between violations in a streak.
	ViolationWindow = 1,

	-- Development mode.
	--
	-- true = GUI is visible to the local player.
	-- Later this can be changed to an admin-only setup.
	ShowGuiToAll = true,

	AdminUserIds = {
		-- Your UserId goes here later.
	},
}


--------------------------------------------------
-- ERROR HANDLING
--------------------------------------------------

local function fail(message)

	error(
		"[AC-Checker] " .. message,
		2
	)

end


--------------------------------------------------
-- DOWNLOAD SOURCE
--------------------------------------------------

local function download(path)

	local url =
		BASE_URL .. path

	if type(game.HttpGet) ~= "function" then

		fail(
			"game:HttpGet is unavailable. " ..
			"This loader requires a client environment " ..
			"that can retrieve the GitHub source."
		)

	end

	local success, result =
		pcall(
			function()

				return game:HttpGet(
					url
				)

			end
		)

	if not success then

		fail(
			"Failed to download " ..
			path ..
			".\n" ..
			tostring(result)
		)

	end

	if type(result) ~= "string"
		or #result == 0 then

		fail(
			"GitHub returned empty source for " ..
			path
		)

	end

	return result

end


--------------------------------------------------
-- COMPILE + LOAD SOURCE
--------------------------------------------------

local function loadModule(path)

	local source =
		download(path)

	if type(loadstring) ~= "function" then

		fail(
			"loadstring is unavailable. " ..
			"The downloaded GitHub modules cannot be compiled."
		)

	end

	local chunk, compileError =
		loadstring(
			source,
			"@AC-Checker/" .. path
		)

	if not chunk then

		fail(
			"Failed to compile " ..
			path ..
			".\n" ..
			tostring(compileError)
		)

	end

	local success, result =
		pcall(chunk)

	if not success then

		fail(
			"Module failed while loading: " ..
			path ..
			".\n" ..
			tostring(result)
		)

	end

	if result == nil then

		fail(
			"Module did not return a value: " ..
			path
		)

	end

	return result

end


--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

print(
	"[AC-Checker] Downloading source from GitHub..."
)

-- Independent module.
local Logs =
	loadModule(
		"src/Logs.lua"
	)

-- Movement scanner.
local LoopScanner =
	loadModule(
		"src/LoopScanner.lua"
	)

-- Jump scanner placeholder.
local JumpScanner =
	loadModule(
		"src/JumpScanner.lua"
	)

-- Core depends on the three modules above,
-- so it is loaded last.
local ScannerCore =
	loadModule(
		"src/ScannerCore.lua"
	)


--------------------------------------------------
-- VALIDATE MODULES
--------------------------------------------------

if type(Logs) ~= "table"
	or type(Logs.new) ~= "function" then

	fail(
		"Logs.lua loaded, but did not return a valid Logs module."
	)

end

if type(LoopScanner) ~= "table"
	or type(LoopScanner.new) ~= "function" then

	fail(
		"LoopScanner.lua loaded, but did not return a valid LoopScanner module."
	)

end

if type(JumpScanner) ~= "table"
	or type(JumpScanner.new) ~= "function" then

	fail(
		"JumpScanner.lua loaded, but did not return a valid JumpScanner module."
	)

end

if type(ScannerCore) ~= "table"
	or type(ScannerCore.new) ~= "function" then

	fail(
		"ScannerCore.lua loaded, but did not return a valid ScannerCore module."
	)

end


--------------------------------------------------
-- WAIT FOR LOCAL PLAYER
--------------------------------------------------

local Players =
	game:GetService(
		"Players"
	)

local LocalPlayer =
	Players.LocalPlayer

if not LocalPlayer then

	fail(
		"LocalPlayer was not available."
	)

end

-- Make sure PlayerGui exists before ScannerCore
-- attempts to build the GUI.
local PlayerGui =
	LocalPlayer:WaitForChild(
		"PlayerGui"
	)


--------------------------------------------------
-- CREATE SCANNER
--------------------------------------------------

local Scanner =
	ScannerCore.new(
		CONFIG,
		{

			Logs =
				Logs,

			LoopScanner =
				LoopScanner,

			JumpScanner =
				JumpScanner,
		}
	)


--------------------------------------------------
-- START
--------------------------------------------------

Scanner:Start()


--------------------------------------------------
-- STARTUP CONFIRMATION
--------------------------------------------------

print(
	"[AC-Checker] GitHub modules loaded successfully."
)

print(
	"[AC-Checker] ScannerCore loaded."
)

print(
	"[AC-Checker] LoopScanner loaded."
)

print(
	"[AC-Checker] JumpScanner loaded."
)

print(
	"[AC-Checker] Logs loaded."
)

print(
	"[AC-Checker] PlayerGui found."
)

print(
	"[AC-Checker] AC-Checker is running."
)
