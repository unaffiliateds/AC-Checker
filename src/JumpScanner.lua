--[[
    AC-Checker
    JumpScanner.lua

    Jump detection will be implemented after the movement
    scanner has been tested.

    Planned checks:

    - Maximum jump height
    - Upward velocity
    - Repeated abnormal jumps
    - Roblox physics/legitimate modifiers
]]

local JumpScanner = {}
JumpScanner.__index = JumpScanner

function JumpScanner.new(config)
	local self = setmetatable({}, JumpScanner)

	self.Config = config or {}
	self.Running = false

	return self
end

function JumpScanner:Start()
	if self.Running then
		return
	end

	self.Running = true

	print("[AC-Checker] JumpScanner started (placeholder).")
end

function JumpScanner:Stop()
	if not self.Running then
		return
	end

	self.Running = false

	print("[AC-Checker] JumpScanner stopped.")
end

return JumpScanner
