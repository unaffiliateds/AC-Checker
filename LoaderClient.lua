--[[
    AC-Checker
    LoaderClient.lua

    GitHub bootstrap loader.
]]

local BASE_URL =
    "https://raw.githubusercontent.com/unaffiliateds/AC-Checker/main/"

local CONFIG = {
    Enabled = true,

    BaseSpeed = 18,
    SprintSpeed = 21,

    SpeedTolerance = 1.25,

    SampleInterval = 0.15,

    RequiredViolations = 3,
    ViolationWindow = 1,

    ShowGuiToAll = true,

    AdminUserIds = {},
}

local function fail(message)
    error("[AC-Checker] " .. message, 2)
end

local function download(path)
    local url = BASE_URL .. path

    if type(game.HttpGet) ~= "function" then
        fail("game:HttpGet is unavailable in this environment.")
    end

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        fail(
            "Failed to download " ..
            path ..
            "\n" ..
            tostring(result)
        )
    end

    if type(result) ~= "string" or #result == 0 then
        fail("GitHub returned empty source for " .. path)
    end

    return result
end

local function loadModule(path)
    local source = download(path)

    if type(loadstring) ~= "function" then
        fail("loadstring is unavailable.")
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
            "\n" ..
            tostring(compileError)
        )
    end

    local success, result =
        pcall(chunk)

    if not success then
        fail(
            "Module failed while loading: " ..
            path ..
            "\n" ..
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

print("[AC-Checker] Loading modules from GitHub...")

local Logs =
    loadModule("src/Logs.lua")

local LoopScanner =
    loadModule("src/LoopScanner.lua")

local JumpScanner =
    loadModule("src/JumpScanner.lua")

local ScannerCore =
    loadModule("src/ScannerCore.lua")

if type(Logs) ~= "table"
    or type(Logs.new) ~= "function" then

    fail("Invalid Logs module.")
end

if type(LoopScanner) ~= "table"
    or type(LoopScanner.new) ~= "function" then

    fail("Invalid LoopScanner module.")
end

if type(JumpScanner) ~= "table"
    or type(JumpScanner.new) ~= "function" then

    fail("Invalid JumpScanner module.")
end

if type(ScannerCore) ~= "table"
    or type(ScannerCore.new) ~= "function" then

    fail("Invalid ScannerCore module.")
end

local Players =
    game:GetService("Players")

local LocalPlayer =
    Players.LocalPlayer

if not LocalPlayer then
    fail("LocalPlayer was not available.")
end

LocalPlayer:WaitForChild("PlayerGui")

local Scanner =
    ScannerCore.new(
        CONFIG,
        {
            Logs = Logs,
            LoopScanner = LoopScanner,
            JumpScanner = JumpScanner,
        }
    )

Scanner:Start()

print("[AC-Checker] All modules loaded.")
print("[AC-Checker] AC-Checker is running.")
